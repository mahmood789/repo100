# expand_to_300_real.R
# Expand to 300 REAL meta-regression datasets
# - No toy/simulated datasets
# - No duplicates
# - Accept basic moderators (author, year, etc.)

message("=== Expanding to 300 Real Meta-Regression Datasets ===\n")

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

# Check if dataset is toy/simulated
is_toy_dataset <- function(title, obj_name) {
  if (is.na(title)) title <- ""
  if (is.na(obj_name)) obj_name <- ""

  toy_patterns <- c(
    "\\btoy\\b", "simulated", "synthetic", "example data",
    "demo", "illustration", "hypothetical", "artificial"
  )

  combined <- paste(tolower(title), tolower(obj_name))
  any(str_detect(combined, toy_patterns))
}

# Classify dataset
classify_df <- function(df) {
  df <- as.data.frame(df)
  df <- normalise_names(df)
  nms <- names(df)

  # Find effect size columns
  yi_name <- match_col(nms, c("^yi$", "^y$", "^te$", "^est$", "^estimate$",
                                "(^|_)effect($|_)", "(^|_)es($|_)",
                                "(^|_)log(or|rr|hr)($|_)", "(^|_)g($|_)", "(^|_)d($|_)",
                                "^smd$", "^cohen", "^hedges"))
  vi_name <- match_col(nms, c("^vi$", "(^|_)v$", "(^|_)variance($|_)", "(^|_)var($|_)"))
  se_name <- match_col(nms, c("^sei$", "^sete$", "(^|_)se($|_)", "std(_|)err",
                                "(^|_)se_yi($|_)", "(^|_)seyi($|_)", "(^|_)se_effect($|_)"))

  has_yi <- !is.na(yi_name)
  has_vi <- !is.na(vi_name)
  has_sei <- !is.na(se_name)

  k <- NA_integer_
  if (has_yi && (has_vi || has_sei)) {
    yi <- suppressWarnings(as.numeric(df[[yi_name]]))
    vv <- if (has_vi) suppressWarnings(as.numeric(df[[vi_name]])) else NA_real_
    ss <- if (has_sei) suppressWarnings(as.numeric(df[[se_name]])) else NA_real_
    ok <- !is.na(yi) & ((!is.na(vv) & vv > 0) | (!is.na(ss) & ss > 0))
    k <- sum(ok)
  }

  # Count moderators (including basic ones like author, year)
  id_like <- c("^study$", "^trial$", "^slab$", "^studlab$", "^id$", "^obs$", "^row", "^x$", "^x1$")
  is_id <- function(nm) any(str_detect(nm, regex(paste(id_like, collapse = "|"), ignore_case = TRUE)))

  drop_cols <- unique(c(yi_name, vi_name, se_name, nms[vapply(nms, is_id, logical(1))]))
  cand_mods <- setdiff(nms, drop_cols)

  p_mods <- 0L
  moderators <- ""
  if (length(cand_mods)) {
    vals <- lapply(cand_mods, function(nm) df[[nm]])
    nunq <- vapply(vals, function(v) length(unique(v[!is.na(v)])), integer(1))
    # Accept moderators with at least 1 unique value (includes author, year, etc.)
    useful_mods <- cand_mods[nunq >= 1]
    p_mods <- length(useful_mods)
    moderators <- paste(head(useful_mods, 50), collapse = "|")  # Limit to 50 for storage
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

# Install packages if needed
for (pkg in meta_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    message("  Installing ", pkg, "...")
    install.packages(pkg, quiet = TRUE)
  }
}

discover_cran_datasets <- function(packages) {
  all_datasets <- tibble()

  for (pkg in packages) {
    if (!requireNamespace(pkg, quietly = TRUE)) next

    message("  Scanning ", pkg, "...")
    datasets_info <- tryCatch({
      as.data.frame(data(package = pkg)$results, stringsAsFactors = FALSE)
    }, error = function(e) NULL)

    if (is.null(datasets_info) || nrow(datasets_info) == 0) next

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

if (needed <= 0) {
  message("✓ Already have ", current_count, " datasets!")
} else {
  new_manifest_rows <- list()
  processed <- 0
  skipped <- 0

  for (i in seq_len(nrow(new_candidates))) {
    if (length(new_manifest_rows) >= needed) break

    row <- new_candidates[i, ]
    dataset_id <- row$dataset_id
    pkg <- row$source_pkg
    obj <- row$source_object

    message(sprintf("  [%d/%d] %s...", i, min(nrow(new_candidates), needed + 50), dataset_id))

    # Load dataset
    df <- tryCatch({
      env <- new.env(parent = emptyenv())
      data(list = obj, package = pkg, envir = env)
      obj_names <- ls(env)
      if (length(obj_names) == 0) return(NULL)
      get(obj_names[1], envir = env)
    }, error = function(e) NULL)

    if (is.null(df) || !is.data.frame(df)) {
      message("    ✗ Not a data.frame")
      skipped <- skipped + 1
      next
    }

    # Classify
    classification <- classify_df(df)

    # Quality checks
    if (!classification$has_yi || (!classification$has_vi && !classification$has_sei)) {
      message("    ✗ No yi/vi/sei")
      skipped <- skipped + 1
      next
    }

    if (classification$k < 3) {
      message("    ✗ Too few studies (k=", classification$k, ")")
      skipped <- skipped + 1
      next
    }

    # Accept datasets even with basic moderators (author, year)
    # p_mods will be >= 0 now

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
      message("    ✓ Added (k=", classification$k, ", mods=", classification$p_mods, ")")

    }, error = function(e) {
      message("    ✗ Error: ", e$message)
      skipped <- skipped + 1
    })
  }

  # Update manifest
  if (length(new_manifest_rows) > 0) {
    new_rows_df <- bind_rows(new_manifest_rows)
    manifest <- bind_rows(manifest, new_rows_df)

    # Remove any duplicates by dataset_id
    manifest <- manifest %>%
      distinct(dataset_id, .keep_all = TRUE) %>%
      arrange(source, dataset_id)

    # Write manifests
    write_csv(manifest, MANIFEST_PATH)
    write_csv(manifest, "inst/extdata/metareg_manifest.csv")

    message("\n✓ Added ", nrow(new_rows_df), " new datasets")
    message("✓ Processed: ", processed, " | Skipped: ", skipped)
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

# Check for duplicates
dups <- manifest %>%
  group_by(dataset_id) %>%
  filter(n() > 1)
if (nrow(dups) > 0) {
  message("\n⚠ WARNING: ", nrow(dups), " duplicate dataset_ids found!")
} else {
  message("\n✓ No duplicates")
}

# Check for toy datasets
toys <- manifest %>%
  rowwise() %>%
  filter(is_toy_dataset(source_title, source_object)) %>%
  ungroup()
if (nrow(toys) > 0) {
  message("\n⚠ WARNING: ", nrow(toys), " potential toy datasets:")
  print(toys %>% select(dataset_id, source_title))
} else {
  message("\n✓ No toy datasets detected")
}

if (nrow(manifest) >= 300) {
  message("\n🎉🎉🎉 SUCCESS: Reached ", nrow(manifest), " datasets! 🎉🎉🎉")
} else {
  message("\n📊 Progress: ", nrow(manifest), "/300 datasets")
  message("   Need ", 300 - nrow(manifest), " more")
  message("\nTip: Try installing more meta-analysis packages:")
  message("  - install.packages('MAd')")
  message("  - install.packages('metaplus')")
  message("  - install.packages('rmeta')")
}

message("\n=== Complete ===\n")
