# DEEP_DIAGNOSE.R
# Deep dive into why expansion didn't add datasets

cat("\n=== DEEP DIAGNOSIS: Why No New Datasets? ===\n\n")

setwd("C:/Users/user/OneDrive - NHS/Documents/repo100")

library(dplyr)
library(readr)
library(stringr)

# Load manifest
manifest <- read_csv("inst/extdata/metareg/_manifest.csv", show_col_types = FALSE)
known_ids <- manifest$dataset_id

cat("Current Status:\n")
cat("  Total entries:", nrow(manifest), "\n")
cat("  Complete:", sum(!is.na(manifest$source_pkg)), "\n")
cat("  Incomplete:", sum(is.na(manifest$source_pkg)), "\n\n")

# Check all 16 packages
meta_packages <- c(
  "metadat", "metafor", "meta", "metaSEM", "psymetadata", "dmetar",
  "MAd", "metaplus", "rmeta", "metamisc", "clubSandwich", "robumeta",
  "weightr", "PublicationBias", "metaBMA", "RoBMA"
)

cat("=== CHECKING EACH PACKAGE ===\n\n")

all_candidates <- list()
total_new <- 0

for (pkg in meta_packages) {
  cat("Package:", pkg, "\n")

  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat("  ✗ NOT INSTALLED - skipping\n\n")
    next
  }

  cat("  ✓ Installed\n")

  # Get datasets
  datasets_info <- tryCatch({
    data(package = pkg)$results
  }, error = function(e) {
    cat("  ✗ Error getting datasets:", e$message, "\n\n")
    return(NULL)
  })

  if (is.null(datasets_info) || nrow(datasets_info) == 0) {
    cat("  ℹ No datasets available\n\n")
    next
  }

  cat("  Found", nrow(datasets_info), "datasets\n")

  # Create dataset IDs
  dataset_ids <- paste0(pkg, "_", datasets_info[, "Item"])

  # Check which are new
  new_ids <- dataset_ids[!dataset_ids %in% known_ids]

  if (length(new_ids) == 0) {
    cat("  ℹ All datasets already in manifest\n\n")
  } else {
    cat("  ✓", length(new_ids), "NEW datasets available:\n")
    for (id in head(new_ids, 10)) {
      cat("    -", id, "\n")
    }
    if (length(new_ids) > 10) {
      cat("    ... and", length(new_ids) - 10, "more\n")
    }
    cat("\n")

    all_candidates[[pkg]] <- new_ids
    total_new <- total_new + length(new_ids)
  }
}

cat("\n=== SUMMARY ===\n")
cat("Total NEW candidate datasets found:", total_new, "\n\n")

if (total_new == 0) {
  cat("❌ PROBLEM: No new datasets available from any package!\n\n")
  cat("This means:\n")
  cat("  - All datasets from installed packages are already in the manifest\n")
  cat("  - OR the newly installed packages don't have datasets\n\n")
  cat("SOLUTION: We need to look at OTHER sources:\n")
  cat("  1. Keep the 141 datasets you have\n")
  cat("  2. Accept we can't reach 300 from CRAN packages alone\n")
  cat("  3. OR lower the quality filters (accept k<3, etc.)\n\n")
} else {
  cat("✓ Found", total_new, "new candidates\n\n")
  cat("Let's test WHY they weren't added...\n\n")

  # Test a few candidates to see why they fail
  cat("=== TESTING SAMPLE DATASETS ===\n\n")

  test_count <- 0
  for (pkg in names(all_candidates)) {
    if (test_count >= 5) break

    ids <- all_candidates[[pkg]]
    for (dataset_id in head(ids, 3)) {
      if (test_count >= 5) break
      test_count <- test_count + 1

      obj_name <- sub(paste0(pkg, "_"), "", dataset_id)

      cat(test_count, ".", pkg, "/", obj_name, "\n")

      # Try to load it
      df <- tryCatch({
        env <- new.env(parent = emptyenv())
        data(list = obj_name, package = pkg, envir = env)
        obj_names <- ls(env)
        if (length(obj_names) == 0) return(NULL)
        get(obj_names[1], envir = env)
      }, error = function(e) {
        cat("   ✗ Error loading:", e$message, "\n")
        return(NULL)
      })

      if (is.null(df)) {
        cat("   ✗ NULL result\n\n")
        next
      }

      if (!is.data.frame(df)) {
        cat("   ✗ Not a data.frame (it's a", class(df)[1], ")\n\n")
        next
      }

      cat("   ✓ Loaded (", nrow(df), "rows,", ncol(df), "cols)\n")

      # Check for yi/vi/sei columns
      nms <- tolower(names(df))
      has_yi <- any(grepl("^yi$|^y$|^te$|^est|effect|^g$|^d$", nms))
      has_vi <- any(grepl("^vi$|^v$|variance|^var$", nms))
      has_sei <- any(grepl("^sei$|^sete$|^se$|stderr", nms))

      cat("   Has yi?", has_yi, "| Has vi?", has_vi, "| Has sei?", has_sei, "\n")

      if (!has_yi) {
        cat("   ✗ REJECTED: No effect size column (yi)\n\n")
      } else if (!has_vi && !has_sei) {
        cat("   ✗ REJECTED: No variance/SE column\n\n")
      } else {
        cat("   ✓ SHOULD BE ADDED!\n\n")
      }
    }
  }
}

cat("\n=== RECOMMENDATION ===\n\n")

if (total_new == 0) {
  cat("Since no new datasets are available from CRAN packages:\n")
  cat("1. Accept 141 datasets as your collection\n")
  cat("2. OR relax quality filters (minimum k, allow datasets without moderators)\n")
  cat("3. OR add GitHub datasets (you already have 76)\n")
  cat("4. OR manually add datasets from other sources\n\n")
  cat("REALISTIC TARGET: ~150-200 real meta-regression datasets from CRAN\n")
} else {
  cat("New datasets ARE available but being filtered out.\n")
  cat("The expansion script has bugs. We need to fix the script.\n")
  cat("\nNext: I'll create a FIXED expansion script.\n")
}

cat("\n")
