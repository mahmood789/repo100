# DIAGNOSE.R
# Figure out why expansion only added 3 datasets

cat("\n=== DIAGNOSIS: Why Did Expansion Stop? ===\n\n")

setwd("C:/Users/user/OneDrive - NHS/Documents/repo100")

library(dplyr)
library(readr)

# 1. Check current manifest
cat("1. Current Manifest Status:\n")
manifest <- read_csv("inst/extdata/metareg/_manifest.csv", show_col_types = FALSE)
cat("   Total entries:", nrow(manifest), "\n")
cat("   Complete:", sum(!is.na(manifest$source_pkg)), "\n")
cat("   Incomplete:", sum(is.na(manifest$source_pkg)), "\n\n")

# 2. Check which packages are installed
cat("2. Installed Meta-Analysis Packages:\n")
meta_packages <- c(
  "metadat", "metafor", "meta", "metaSEM", "psymetadata", "dmetar",
  "MAd", "metaplus", "rmeta", "metamisc", "clubSandwich", "robumeta",
  "weightr", "PublicationBias", "metaBMA", "RoBMA"
)

for (pkg in meta_packages) {
  is_installed <- requireNamespace(pkg, quietly = TRUE)
  cat("   ", pkg, ":", if(is_installed) "✓ INSTALLED" else "✗ NOT INSTALLED", "\n")
}
cat("\n")

# 3. Check what datasets are available from installed packages
cat("3. Available Datasets from Installed Packages:\n")
total_available <- 0
for (pkg in meta_packages) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    datasets_info <- tryCatch({
      data(package = pkg)$results
    }, error = function(e) NULL)

    if (!is.null(datasets_info) && nrow(datasets_info) > 0) {
      n_datasets <- nrow(datasets_info)
      total_available <- total_available + n_datasets
      cat("   ", pkg, ":", n_datasets, "datasets\n")
    } else {
      cat("   ", pkg, ": 0 datasets\n")
    }
  }
}
cat("\n   TOTAL AVAILABLE:", total_available, "datasets\n\n")

# 4. Check how many are already in manifest
cat("4. Already in Manifest:\n")
known_ids <- manifest$dataset_id
cat("   Known dataset IDs:", length(known_ids), "\n\n")

# 5. Simulate discovery to see candidates
cat("5. Simulating Discovery Process:\n")
cat("   (This shows what SHOULD have been found)\n\n")

discover_cran_datasets <- function(packages) {
  all_datasets <- tibble::tibble()

  for (pkg in packages) {
    if (!requireNamespace(pkg, quietly = TRUE)) next

    datasets_info <- tryCatch({
      as.data.frame(data(package = pkg)$results, stringsAsFactors = FALSE)
    }, error = function(e) NULL)

    if (is.null(datasets_info) || nrow(datasets_info) == 0) next

    datasets_info <- datasets_info %>%
      mutate(
        dataset_id = paste0(pkg, "_", Item),
        source_pkg = pkg
      )

    all_datasets <- bind_rows(all_datasets, datasets_info[,c("dataset_id", "source_pkg")])
  }

  all_datasets
}

candidates <- discover_cran_datasets(meta_packages)
cat("   Total candidates found:", nrow(candidates), "\n")

new_candidates <- candidates %>%
  filter(!dataset_id %in% known_ids)
cat("   New candidates (not in manifest):", nrow(new_candidates), "\n\n")

# 6. Show breakdown by package
if (nrow(new_candidates) > 0) {
  cat("6. New Candidates by Package:\n")
  new_summary <- new_candidates %>%
    count(source_pkg, sort = TRUE) %>%
    print(n = 20)

  cat("\n   Sample new candidates:\n")
  new_candidates %>%
    head(20) %>%
    print(n = 20)
}

# 7. Recommendation
cat("\n=== RECOMMENDATION ===\n")
if (nrow(new_candidates) >= 150) {
  cat("✓ Good news! Found", nrow(new_candidates), "new candidate datasets\n")
  cat("  The expansion script should work if run again.\n")
  cat("\n  Next step: Run the expansion script again:\n")
  cat("    source('scripts/expand_to_300_real.R')\n\n")
} else {
  cat("⚠ Only found", nrow(new_candidates), "new candidates\n")
  cat("  May not reach 300 with current packages.\n")
  cat("  Consider adding more GitHub datasets or relaxing filters.\n\n")
}
