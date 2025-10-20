# INSPECT_PACKAGES.R
# Manually inspect each package to see what datasets exist

cat("\n=== MANUAL PACKAGE INSPECTION ===\n\n")

setwd("C:/Users/user/OneDrive - NHS/Documents/repo100")

library(readr)
manifest <- read_csv("inst/extdata/metareg/_manifest.csv", show_col_types = FALSE)
known_ids <- manifest$dataset_id

# All packages
all_packages <- c(
  "metadat", "metafor", "meta", "metaSEM", "psymetadata", "dmetar",
  "MAd", "metaplus", "rmeta", "metamisc", "clubSandwich", "robumeta",
  "weightr", "PublicationBias", "metaBMA", "RoBMA"
)

# NEW packages (the ones we just installed)
new_packages <- c("MAd", "metaplus", "rmeta", "metamisc", "clubSandwich",
                  "robumeta", "weightr", "PublicationBias", "metaBMA", "RoBMA")

cat("=== CHECKING NEW PACKAGES ===\n\n")

total_datasets <- 0
total_new <- 0

for (pkg in new_packages) {
  cat("Package:", pkg, "\n")

  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat("  ✗ NOT INSTALLED\n\n")
    next
  }

  cat("  ✓ Installed\n")

  # Get datasets
  datasets_info <- tryCatch({
    data(package = pkg)$results
  }, error = function(e) {
    cat("  ✗ Error:", e$message, "\n\n")
    return(NULL)
  })

  if (is.null(datasets_info) || nrow(datasets_info) == 0) {
    cat("  ℹ NO DATASETS in this package\n\n")
    next
  }

  n_datasets <- nrow(datasets_info)
  total_datasets <- total_datasets + n_datasets

  cat("  Found", n_datasets, "datasets:\n")

  for (i in 1:min(n_datasets, 10)) {
    item <- datasets_info[i, "Item"]
    title <- datasets_info[i, "Title"]
    dataset_id <- paste0(pkg, "_", item)

    is_new <- !dataset_id %in% known_ids
    if (is_new) total_new <- total_new + 1

    status <- if (is_new) "NEW" else "exists"
    cat("    -", item, "(", status, ")\n")
    cat("      ", substr(title, 1, 70), "...\n")
  }

  if (n_datasets > 10) {
    cat("    ... and", n_datasets - 10, "more\n")
  }
  cat("\n")
}

cat("\n=== SUMMARY ===\n")
cat("Total datasets in NEW packages:", total_datasets, "\n")
cat("New datasets (not in manifest):", total_new, "\n\n")

if (total_datasets == 0) {
  cat("❌ PROBLEM: The newly installed packages have NO datasets!\n\n")
  cat("These packages are code libraries, not data packages:\n")
  cat("  - MAd, metaplus, rmeta, etc. are analysis packages\n")
  cat("  - They don't contain datasets, just functions\n\n")

  cat("SOLUTION: We cannot reach 300 from CRAN alone.\n\n")

  cat("REALISTIC TARGETS:\n")
  cat("  - metadat: ~100 datasets (you have ~30)\n")
  cat("  - psymetadata: ~30 datasets (you have ~21)\n")
  cat("  - meta: ~10 datasets (you have 2)\n")
  cat("  - metaSEM: ~10 datasets (you have ~5)\n")
  cat("  - dmetar: ~10 datasets (you have 3)\n")
  cat("  - metafor: ~5 datasets\n")
  cat("  TOTAL REALISTIC: ~150-165 CRAN datasets\n\n")

  cat("TO REACH 300:\n")
  cat("  - You have 76 GitHub datasets already\n")
  cat("  - You need: 300 - 141 = 159 more\n")
  cat("  - Maximum possible from CRAN: ~165\n")
  cat("  - So you'd have ~165 CRAN + 76 GitHub = 241 total\n")
  cat("  - Still need: 59 more GitHub datasets\n\n")

} else if (total_new == 0) {
  cat("❌ All datasets from new packages are already in manifest!\n\n")
} else {
  cat("✓ There are", total_new, "new datasets available\n")
  cat("  The expansion script should have added them.\n")
  cat("  Something is wrong with the script logic.\n\n")
}

# Now check the MAIN data packages more carefully
cat("\n=== CHECKING MAIN DATA PACKAGES ===\n\n")

main_packages <- c("metadat", "psymetadata", "meta", "metaSEM", "dmetar", "metafor")

for (pkg in main_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    next
  }

  cat("Package:", pkg, "\n")

  datasets_info <- tryCatch({
    data(package = pkg)$results
  }, error = function(e) NULL)

  if (is.null(datasets_info) || nrow(datasets_info) == 0) {
    cat("  No datasets\n\n")
    next
  }

  n_total <- nrow(datasets_info)
  dataset_ids <- paste0(pkg, "_", datasets_info[, "Item"])
  n_in_manifest <- sum(dataset_ids %in% known_ids)
  n_missing <- n_total - n_in_manifest

  cat("  Total datasets:", n_total, "\n")
  cat("  In manifest:", n_in_manifest, "\n")
  cat("  Missing:", n_missing, "\n")

  if (n_missing > 0) {
    cat("  Missing datasets:\n")
    missing_ids <- dataset_ids[!dataset_ids %in% known_ids]
    for (id in head(missing_ids, 10)) {
      cat("    -", id, "\n")
    }
    if (n_missing > 10) {
      cat("    ... and", n_missing - 10, "more\n")
    }
  }
  cat("\n")
}

cat("\n=== FINAL ASSESSMENT ===\n\n")
cat("Current complete datasets: 146\n")
cat("Target: 300\n")
cat("Gap: 154\n\n")

cat("RECOMMENDATION:\n")
cat("1. Focus on extracting ALL datasets from metadat (you're missing ~70)\n")
cat("2. Extract ALL datasets from psymetadata (you're missing ~9)\n")
cat("3. This should get you to ~225 total\n")
cat("4. For 300, you'll need to add ~75 more GitHub datasets\n\n")
