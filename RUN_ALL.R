# RUN_ALL.R
# Complete workflow: Cleanup + Expansion to 300 datasets
#
# INSTRUCTIONS:
# 1. Open R or RStudio
# 2. Copy and paste this entire file into the R console
# 3. Or run: source("C:/Users/user/OneDrive - NHS/Documents/repo100/RUN_ALL.R")

cat("\n")
cat("============================================================\n")
cat("  repo100 Dataset Expansion to 300 Real Datasets\n")
cat("============================================================\n\n")

# Set working directory
tryCatch({
  setwd("C:/Users/user/OneDrive - NHS/Documents/repo100")
  cat("✓ Working directory set to:", getwd(), "\n\n")
}, error = function(e) {
  cat("ERROR: Could not set working directory\n")
  cat("Please manually run: setwd('C:/Users/user/OneDrive - NHS/Documents/repo100')\n")
  stop(e)
})

# ---- STEP 1: CLEANUP ----
cat("============================================================\n")
cat("STEP 1: Cleanup - Remove toy datasets and incomplete entries\n")
cat("============================================================\n\n")

tryCatch({
  source("scripts/cleanup_manifest.R")
  cat("\n✓ Cleanup completed successfully\n\n")
}, error = function(e) {
  cat("ERROR during cleanup:\n")
  print(e)
  cat("\nContinuing to expansion...\n\n")
})

# Pause to review cleanup results
cat("Press [Enter] to continue to expansion step...")
readline()

# ---- STEP 2: EXPANSION ----
cat("\n")
cat("============================================================\n")
cat("STEP 2: Expansion - Discover and add datasets to reach 300\n")
cat("============================================================\n")
cat("This will scan 16 meta-analysis packages.\n")
cat("Expected runtime: 10-30 minutes\n")
cat("Installing packages as needed...\n\n")

tryCatch({
  source("scripts/expand_to_300_real.R")
  cat("\n✓ Expansion completed successfully\n\n")
}, error = function(e) {
  cat("ERROR during expansion:\n")
  print(e)
})

# ---- STEP 3: VERIFICATION ----
cat("\n")
cat("============================================================\n")
cat("STEP 3: Verification\n")
cat("============================================================\n\n")

library(readr)
library(dplyr)

manifest <- read_csv("inst/extdata/metareg/_manifest.csv", show_col_types = FALSE)

cat("Final dataset count:", nrow(manifest), "\n")
cat("Target: 300\n")

if (nrow(manifest) >= 300) {
  cat("\n🎉 SUCCESS! Reached target of 300 datasets! 🎉\n\n")
} else {
  cat("\nProgress:", nrow(manifest), "/ 300\n")
  cat("Still need:", 300 - nrow(manifest), "more datasets\n\n")
}

# Show breakdown by package
cat("\nDatasets by package:\n")
pkg_summary <- manifest %>%
  count(source_pkg, sort = TRUE) %>%
  print(n = 20)

cat("\n============================================================\n")
cat("All steps completed!\n")
cat("============================================================\n\n")
