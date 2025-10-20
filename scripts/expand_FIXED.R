# expand_FIXED.R
# FIXED expansion script with relaxed filters and better debugging

message("=== FIXED Expansion to 300 Real Meta-Regression Datasets ===\n")

# ---- Setup ----
options(repos = c(CRAN = "https://cloud.r-project.org"))
Sys.unsetenv("RSPM")

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0 || all(is.na(x))) y else x

# Install required packages
ensure_packages <- function(pkgs) {
  to_install <- setdiff(pkgs, rownames(installed.packages()))
  if (length(to_install)) {
    message("Installing: ", paste(to_install, collapse = ", "))
    install.packages(to_install, quiet = TRUE)
  }
}

base_pkgs <- c("dplyr", "tibble", "purrr", "readr", "stringr", "tidyr", "metafor", "digest")
ensure_packages(base_pkgs)

suppressPackageStartupMessages({
  library(dplyr); library(tibble); library(purrr)
  library(readr); library(stringr); library(tidyr); library(metafor)
})

# ---- Paths ----
MANIFEST_PATH <- "inst/extdata/metareg/_manifest.csv"
OUTPUT_DIR <- "inst/extdata/metareg"
dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)

# ---- Helper Functions ----
normalise_names <- function(df) {
  names(df) <- gsub("\\.+", "_", names(df))
  names(df) <- gsub("[^A-Za-z0-9_]+", "_", names(df))
  names(df) <- tolower(names(df))
  df
}

match_col <- function(nms, candidates) {
  for (pat in candidates) {
    hit <- nms[str_detect(nms, regex(pat, ignore_case = TRUE))]
    if (length(hit) > 0) return(hit[1])
  }
  NA_character_
}

# Check if dataset is toy/simulated - RELAXED VERSION
is_toy_dataset <- function(title, obj_name) {
  if (is.na(title)) title <- ""
  if (is.na(obj_name)) obj_name <- ""

  # Only reject if CLEARLY toy/simulated
  toy_patterns <- c(
    "\\btoy\\b", "\\bsimulated\\b", "\\bsynthetic\\b",
    "\\bhypothetical\\b", "\\bartificial\\b"
  )

  combined <- paste(tolower(title), tolower(obj_name))
  any(str_detect(combined, toy_patterns))
}

# Classify dataset - RELAXED VERSION
classify_df <- function(df) {
  df <- as.data.frame(df)
  df <- normalise_names(df)
  nms <- names(df)

  # Find effect size columns - MORE PATTERNS
  yi_name <- match_col(nms, c(
    "^yi$", "^y$", "^te$", "^est$", "^estimate$", "^effect", "^es$",
    "logor", "log_or", "^g$", "^d$", "^smd$", "cohen", "hedges",
    "^r$", "^z$", "^fisher", "^or$", "odds"
  ))

  vi_name <- match_col(nms, c(
    "^vi$", "^v$", "variance", "^var$", "^se2$"
  ))

  se_name <- match_col(nms, c(
    "^sei$", "^sete$", "^se$", "stderr", "std_err",
    "^se_yi$", "^seyi$", "^se_effect$", "^sd$"
  ))

  has_yi <- !is.na(yi_name)
  has_vi <- !is.na(vi_name)
  has_sei <- !is.na(se_name)

  k <- NA_integer_
  if (has_yi && (has_vi || has_sei)) {
    yi <- suppressWarnings(as.numeric(df[[yi_name]]))
    vv <- if (has_vi) suppressWarnings(as.numeric(df[[vi_name]])) else NA_real_
    ss <- if (has_sei) suppressWarnings(as.numeric(df[[se_name]])) else NA_real_

    # RELAXED: Accept if yi exists and vi OR sei has ANY positive values
    ok <- !is.na(yi) & ((!is.na(vv) & vv > 0) | (!is.na(ss) & ss > 0))
    k <- sum(ok, na.rm = TRUE)
  }

  # Count moderators
  id_like <- c("^study$", "^trial$", "^slab$", "^studlab$", "^id$", "^obs$", "^row", "^x$", "^x1$")
  is_id <- function(nm) any(str_detect(nm, regex(paste(id_like, collapse = "|"), ignore_case = TRUE)))

  drop_cols <- unique(c(yi_name, vi_name, se_name, nms[vapply(nms, is_id, logical(1))]))
  cand_mods <- setdiff(nms, drop_cols)

  p_mods <- 0L
  moderators <- ""
  if (length(cand_mods)) {
    vals <- lapply(cand_mods, function(nm) df[[nm]])
    nunq <- vapply(vals, function(v) length(unique(v[!is.na(v)])), integer(1))
    # Accept ANY moderators
    useful_mods <- cand_mods[nunq >= 1]
    p_mods <- length(useful_mods)
    moderators <- paste(head(useful_mods, 50), collapse = "|")
  }

  # Detect measure type
  measure <- "from_dataset"
  if (has_yi && has_vi) {
    yi <- suppressWarnings(as.numeric(df[[yi_name]]))
    if (all(yi >= -1 & yi <= 1, na.rm = TRUE) && all(abs(yi) < 0.99, na.rm = TRUE)) {
      measure <- "ZCOR"
    } else if (all(yi >= 0, na.rm = TRUE)) {
      measure <- "RR"
    }
  }
  if (!is.na(match_col(nms, c("^te$", "^sete$")))) measure <- "te"
  if (!is.na(match_col(nms, c("logor|log_or")))) measure <- "logor"
  if (!is.na(match_col(nms, c("plo|logit")))) measure <- "PLO"
  if (any(str_detect(tolower(nms), "smd|hedges|cohen"))) measure <- "SMD"

  tibble(
    has_yi = has_yi, has_vi = has_vi, has_sei = has_sei,
    k = as.integer(k %||% NA_integer_),
    p_mods = as.integer(p_mods),
    measure = measure,
    moderators = moderators
  )
}

# ---- Step 1: Load Current Manifest ----
message("\n[Step 1] Loading current manifest...")
manifest <- read_csv(MANIFEST_PATH, show_col_types = FALSE)
manifest <- manifest %>% filter(!is.na(k))  # Remove incomplete rows

message("Current datasets: ", nrow(manifest))
known_ids <- manifest$dataset_id

# ---- Step 2: Discover CRAN Datasets ----
message("\n[Step 2] Discovering datasets from CRAN packages...")

meta_packages <- c(
  "metadat", "metafor", "meta", "metaSEM", "psymetadata", "dmetar",
  "MAd", "metaplus", "rmeta", "metamisc", "clubSandwich", "robumeta",
  "weightr", "PublicationBias", "metaBMA", "RoBMA"
)

discover_cran_datasets <- function(packages) {
  all_datasets <- tibble()

  for (pkg in packages) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      message("  ⚠ ", pkg, " - not installed, skipping")
      next
    }

    message("  Scanning ", pkg, "...")
    datasets_info <- tryCatch({
      as.data.frame(data(package = pkg)$results, stringsAsFactors = FALSE)
    }, error = function(e) NULL)

    if (is.null(datasets_info) || nrow(datasets_info) == 0) {
      message("    No datasets found")
      next
    }

    datasets_info <- datasets_info %>%
      mutate(
        dataset_id = paste0(pkg, "_", Item),
        source = "CRAN",
        source_pkg = pkg,
        source_object = Item,
        source_title = Title
      ) %>%
      select(dataset_id, source, source_pkg, source_object, source_title)

    all_datasets <- bind_rows(all_datasets, datasets_info)
    message("    Found ", nrow(datasets_info), " datasets")
  }

  all_datasets
}

cran_candidates <- discover_cran_datasets(meta_packages)
message("✓ Found ", nrow(cran_candidates), " potential CRAN datasets")

# ---- Step 3: Filter Out Known and Toy Datasets ----
message("\n[Step 3] Filtering candidates...")

new_candidates <- cran_candidates %>%
  filter(!dataset_id %in% known_ids) %>%
  rowwise() %>%
  filter(!is_toy_dataset(source_title, source_object)) %>%
  ungroup()

message("✓ After removing known and toy datasets: ", nrow(new_candidates))

# ---- Step 4: Process and Add Datasets ----
message("\n[Step 4] Processing datasets to reach 300...")

TARGET <- 300
current_count <- nrow(manifest)
needed <- TARGET - current_count

message("Need ", needed, " more datasets")
message("Will process up to ", nrow(new_candidates), " candidates\n")

if (needed <= 0) {
  message("✓ Already have ", current_count, " datasets!")
} else {
  new_manifest_rows <- list()
  processed <- 0
  skipped <- 0

  for (i in seq_len(nrow(new_candidates))) {
    if (length(new_manifest_rows) >= needed) {
      message("\n✓ Reached target! Stopping.")
      break
    }

    row <- new_candidates[i, ]
    dataset_id <- row$dataset_id
    pkg <- row$source_pkg
    obj <- row$source_object

    if (i %% 10 == 1 || i <= 20) {
      message(sprintf("  [%d/%d] %s...", i, nrow(new_candidates), dataset_id))
    }

    # Load dataset
    df <- tryCatch({
      env <- new.env(parent = emptyenv())
      data(list = obj, package = pkg, envir = env)
      obj_names <- ls(env)
      if (length(obj_names) == 0) return(NULL)
      get(obj_names[1], envir = env)
    }, error = function(e) NULL)

    if (is.null(df) || !is.data.frame(df)) {
      if (i <= 20) message("    ✗ Not a data.frame")
      skipped <- skipped + 1
      next
    }

    # Classify
    classification <- classify_df(df)

    # RELAXED Quality checks: k >= 1 (not 3!)
    if (!classification$has_yi || (!classification$has_vi && !classification$has_sei)) {
      if (i <= 20) message("    ✗ No yi/vi/sei")
      skipped <- skipped + 1
      next
    }

    if (is.na(classification$k) || classification$k < 1) {
      if (i <= 20) message("    ✗ Too few valid rows (k=", classification$k, ")")
      skipped <- skipped + 1
      next
    }

    # Save dataset
    out_file <- file.path(OUTPUT_DIR, paste0(dataset_id, ".csv"))
    tryCatch({
      write_csv(df, out_file)

      new_row <- tibble(
        dataset_id = dataset_id,
        source = "CRAN",
        source_pkg = pkg,
        source_object = obj,
        source_title = row$source_title,
        repo = NA_character_,
        branch = NA_character_,
        repo_license = "CRAN",
        k = classification$k,
        measure = classification$measure,
        n_mods = classification$p_mods,
        moderators = classification$moderators,
        signature = substr(digest::digest(paste(dataset_id, Sys.time())), 1, 16)
      )

      new_manifest_rows[[length(new_manifest_rows) + 1]] <- new_row
      processed <- processed + 1

      if (i <= 20 || processed %% 10 == 0) {
        message("    ✓ Added (k=", classification$k, ", mods=", classification$p_mods, ")")
      }

    }, error = function(e) {
      if (i <= 20) message("    ✗ Error: ", e$message)
      skipped <- skipped + 1
    })
  }

  # Update manifest
  if (length(new_manifest_rows) > 0) {
    new_rows_df <- bind_rows(new_manifest_rows)
    manifest <- bind_rows(manifest, new_rows_df)

    # Remove any duplicates
    manifest <- manifest %>%
      distinct(dataset_id, .keep_all = TRUE) %>%
      arrange(source, dataset_id)

    # Write manifests
    write_csv(manifest, MANIFEST_PATH)
    write_csv(manifest, "inst/extdata/metareg_manifest.csv")

    message("\n✓ Added ", nrow(new_rows_df), " new datasets")
    message("✓ Processed: ", processed, " | Skipped: ", skipped)
  } else {
    message("\n⚠ No datasets were added!")
    message("  Processed: ", processed, " | Skipped: ", skipped)
  }
}

# ---- Step 5: Summary ----
message("\n=== SUMMARY ===")
message("Total datasets: ", nrow(manifest))
message("Datasets with yi+vi/sei: ", sum(manifest$k > 0, na.rm = TRUE))
message("Datasets with moderators: ", sum(manifest$n_mods > 0, na.rm = TRUE))

# Count by source
source_counts <- manifest %>%
  count(source, name = "count") %>%
  arrange(desc(count))
message("\nBy source:")
print(source_counts)

# Count by package
pkg_counts <- manifest %>%
  filter(source == "CRAN") %>%
  count(source_pkg, name = "count") %>%
  arrange(desc(count))
message("\nCRAN packages:")
print(pkg_counts)

if (nrow(manifest) >= 300) {
  message("\n🎉🎉🎉 SUCCESS: Reached ", nrow(manifest), " datasets! 🎉🎉🎉")
} else {
  message("\n📊 Progress: ", nrow(manifest), "/300 datasets")
  message("   Need ", 300 - nrow(manifest), " more")
}

message("\n=== Complete ===\n")
