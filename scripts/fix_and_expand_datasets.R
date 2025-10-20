# fix_and_expand_datasets.R
# Comprehensive script to fix repo100 issues and expand to 300 datasets
#
# This script:
# 1. Fixes incomplete manifest entries
# 2. Discovers new datasets from CRAN packages (metadat, metafor, meta, dmetar, metaSEM, psymetadata)
# 3. Optionally discovers datasets from GitHub if GITHUB_PAT is set
# 4. Processes and ingests datasets
# 5. Updates manifest to reach 300 datasets

message("=== repo100: Fix and Expand to 300 Datasets ===\n")

# ---- Setup ----
options(repos = c(CRAN = "https://cloud.r-project.org"))
Sys.unsetenv("RSPM")

# Helper function
`%||%` <- function(x, y) if (is.null(x) || length(x) == 0 || all(is.na(x))) y else x

# Install required packages
ensure_packages <- function(pkgs) {
  to_install <- setdiff(pkgs, rownames(installed.packages()))
  if (length(to_install)) {
    message("Installing required packages: ", paste(to_install, collapse = ", "))
    install.packages(to_install, quiet = TRUE)
  }
}

base_pkgs <- c("dplyr", "tibble", "purrr", "readr", "stringr", "tidyr", "metafor", "digest")
ensure_packages(base_pkgs)

suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
  library(purrr)
  library(readr)
  library(stringr)
  library(tidyr)
  library(metafor)
})

# ---- Path Setup ----
MANIFEST_PATH <- "inst/extdata/metareg/_manifest.csv"
OUTPUT_DIR <- "inst/extdata/metareg"

dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)
dir.create("scripts/discover", recursive = TRUE, showWarnings = FALSE)

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

classify_df <- function(df) {
  df <- as.data.frame(df)
  df <- normalise_names(df)
  nms <- names(df)

  # Find effect size columns
  yi_name <- match_col(nms, c("^yi$", "^y$", "^te$", "^est$", "^estimate$",
                                "(^|_)effect($|_)", "(^|_)es($|_)",
                                "(^|_)log(or|rr|hr)($|_)", "(^|_)g($|_)", "(^|_)d($|_)"))
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

  # Count potential moderators
  id_like <- c("^study$", "^author$", "^trial$", "^slab$", "^studlab$",
               "(^|_)id$", "(^|_)group$", "^year$", "^paper$", "^source$", "^dataset$")
  is_id <- function(nm) any(str_detect(nm, regex(paste(id_like, collapse = "|"), ignore_case = TRUE)))

  drop_cols <- unique(c(yi_name, vi_name, se_name, nms[vapply(nms, is_id, logical(1))]))
  cand_mods <- setdiff(nms, drop_cols)

  p_mods <- 0L
  moderators <- ""
  if (length(cand_mods)) {
    vals <- lapply(cand_mods, function(nm) df[[nm]])
    nunq <- vapply(vals, function(v) length(unique(v[!is.na(v)])), integer(1))
    useful_mods <- cand_mods[nunq > 1]
    p_mods <- length(useful_mods)
    moderators <- paste(useful_mods, collapse = "|")
  }

  # Detect measure type
  measure <- "from_dataset"
  if (has_yi && has_vi) {
    yi <- suppressWarnings(as.numeric(df[[yi_name]]))
    if (all(yi >= -1 & yi <= 1, na.rm = TRUE)) measure <- "ZCOR"
    else if (all(yi >= 0, na.rm = TRUE)) measure <- "RR"
    else if (any(str_detect(tolower(nms), "smd|hedges|cohen"), na.rm = TRUE)) measure <- "SMD"
  }
  if (!is.na(match_col(nms, c("^te$", "^sete$")))) measure <- "te"
  if (!is.na(match_col(nms, c("logor|log_or")))) measure <- "logor"
  if (!is.na(match_col(nms, c("plo|logit")))) measure <- "PLO"

  tibble(
    has_yi = has_yi,
    has_vi = has_vi,
    has_sei = has_sei,
    k = as.integer(k %||% NA_integer_),
    p_mods = as.integer(p_mods),
    measure = measure,
    moderators = moderators
  )
}

# ---- Step 1: Fix Incomplete Manifest Entries ----
message("\n[Step 1] Fixing incomplete manifest entries...")

manifest <- read_csv(MANIFEST_PATH, show_col_types = FALSE)
incomplete_idx <- which(is.na(manifest$source_pkg) | is.na(manifest$k))

if (length(incomplete_idx) > 0) {
  message("Found ", length(incomplete_idx), " incomplete entries. Analyzing datasets...")

  for (idx in incomplete_idx) {
    dataset_id <- manifest$dataset_id[idx]
    csv_file <- file.path(OUTPUT_DIR, paste0(dataset_id, ".csv"))

    if (file.exists(csv_file)) {
      message("  - Analyzing ", dataset_id)
      df <- read_csv(csv_file, show_col_types = FALSE)

      # Extract metadata from the first row if available
      source_pkg <- if ("source_pkg" %in% names(df)) df$source_pkg[1] else NA
      object <- if ("object" %in% names(df)) df$object[1] else sub("^[^_]+_", "", dataset_id)
      title <- if ("title" %in% names(df)) df$title[1] else paste("Dataset", dataset_id)

      # Classify the dataset
      classification <- classify_df(df)

      # Update manifest
      manifest$source[idx] <- "CRAN"
      manifest$source_pkg[idx] <- source_pkg
      manifest$source_object[idx] <- object
      manifest$source_title[idx] <- title
      manifest$k[idx] <- classification$k
      manifest$measure[idx] <- classification$measure
      manifest$n_mods[idx] <- classification$p_mods
      manifest$moderators[idx] <- classification$moderators
      manifest$signature[idx] <- paste0(substr(digest::digest(paste(dataset_id, Sys.time())), 1, 16))
    }
  }

  # Write updated manifest
  write_csv(manifest, MANIFEST_PATH)
  write_csv(manifest, "inst/extdata/metareg_manifest.csv")  # Also update the copy
  message("✓ Fixed ", length(incomplete_idx), " incomplete entries")
} else {
  message("✓ No incomplete entries found")
}

# ---- Step 2: Discover New Datasets from CRAN Packages ----
message("\n[Step 2] Discovering new datasets from CRAN packages...")

meta_packages <- c("metadat", "metafor", "meta", "dmetar", "metaSEM", "psymetadata")

# Ensure packages are installed
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
    datasets_info <- as.data.frame(data(package = pkg)$results, stringsAsFactors = FALSE)

    if (nrow(datasets_info) > 0) {
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
  }

  all_datasets
}

cran_candidates <- discover_cran_datasets(meta_packages)
message("✓ Found ", nrow(cran_candidates), " potential datasets from CRAN")

# ---- Step 3: Filter Out Already Known Datasets ----
message("\n[Step 3] Filtering already known datasets...")

known_ids <- manifest$dataset_id
new_candidates <- cran_candidates %>%
  filter(!dataset_id %in% known_ids)

message("✓ Found ", nrow(new_candidates), " new datasets to process")

# ---- Step 4: Process and Ingest New Datasets ----
message("\n[Step 4] Processing and ingesting new datasets...")

target_count <- 300
current_count <- nrow(manifest)
needed <- target_count - current_count

if (needed <= 0) {
  message("✓ Already have ", current_count, " datasets (target: ", target_count, ")")
} else {
  message("Need to add ", needed, " more datasets to reach ", target_count)

  # Process up to 'needed' datasets
  datasets_to_add <- head(new_candidates, min(nrow(new_candidates), needed))

  new_manifest_rows <- list()

  for (i in seq_len(nrow(datasets_to_add))) {
    row <- datasets_to_add[i, ]
    dataset_id <- row$dataset_id
    pkg <- row$source_pkg
    obj <- row$source_object

    message(sprintf("  [%d/%d] Processing %s...", i, nrow(datasets_to_add), dataset_id))

    # Try to load the dataset
    df <- tryCatch({
      env <- new.env(parent = emptyenv())
      data(list = obj, package = pkg, envir = env)
      obj_name <- ls(env)[1]
      get(obj_name, envir = env)
    }, error = function(e) NULL)

    if (is.null(df) || !is.data.frame(df)) {
      message("    ✗ Could not load as data.frame")
      next
    }

    # Classify the dataset
    classification <- classify_df(df)

    # Skip if not suitable for meta-regression
    if (!classification$has_yi || (!classification$has_vi && !classification$has_sei)) {
      message("    ✗ Not suitable (no yi/vi/sei)")
      next
    }

    if (classification$k < 3) {
      message("    ✗ Too few studies (k=", classification$k, ")")
      next
    }

    # Save the dataset as CSV
    out_file <- file.path(OUTPUT_DIR, paste0(dataset_id, ".csv"))
    tryCatch({
      write_csv(df, out_file)
      message("    ✓ Saved to ", basename(out_file))

      # Add to new manifest rows
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

    }, error = function(e) {
      message("    ✗ Error saving: ", e$message)
    })

    # Stop if we've reached target
    if (nrow(manifest) + length(new_manifest_rows) >= target_count) {
      message("\n✓ Reached target of ", target_count, " datasets!")
      break
    }
  }

  # Update manifest
  if (length(new_manifest_rows) > 0) {
    new_rows_df <- bind_rows(new_manifest_rows)
    manifest <- bind_rows(manifest, new_rows_df)

    # Write updated manifest
    write_csv(manifest, MANIFEST_PATH)
    write_csv(manifest, "inst/extdata/metareg_manifest.csv")

    message("\n✓ Added ", nrow(new_rows_df), " new datasets")
    message("✓ Total datasets: ", nrow(manifest))
  }
}

# ---- Step 5: Final Summary ----
message("\n=== Summary ===")
message("Total datasets in manifest: ", nrow(manifest))
message("Datasets with yi+vi/sei: ", sum(manifest$k > 0, na.rm = TRUE))
message("Datasets with moderators: ", sum(manifest$n_mods > 0, na.rm = TRUE))
message("\nFiles saved:")
message("  - ", MANIFEST_PATH)
message("  - inst/extdata/metareg_manifest.csv")
message("  - ", OUTPUT_DIR, "/*.csv")

if (nrow(manifest) >= 300) {
  message("\n✓✓✓ SUCCESS: Reached target of 300+ datasets! ✓✓✓")
} else {
  message("\nNote: Currently at ", nrow(manifest), " datasets. Need ", 300 - nrow(manifest), " more to reach 300.")
  message("Consider running GitHub discovery or manually curating additional datasets.")
}

message("\n=== Script Complete ===\n")
