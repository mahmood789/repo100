# RUN_FIXED.R
# Run the FIXED expansion script

cat("\n")
cat("============================================================\n")
cat("  Running FIXED Expansion Script\n")
cat("  (Relaxed filters - k>=1 instead of k>=3)\n")
cat("============================================================\n\n")

setwd("C:/Users/user/OneDrive - NHS/Documents/repo100")

# Run the fixed expansion
source("scripts/expand_FIXED.R")

# Show final results
cat("\n")
cat("============================================================\n")
cat("  FINAL RESULTS\n")
cat("============================================================\n\n")

library(readr)
manifest <- read_csv("inst/extdata/metareg/_manifest.csv", show_col_types = FALSE)

cat("Total datasets:", nrow(manifest), "\n")
cat("Complete:", sum(!is.na(manifest$source_pkg)), "\n")
cat("Target: 300\n\n")

if (sum(!is.na(manifest$source_pkg)) >= 300) {
  cat("🎉 SUCCESS! Reached 300+ datasets!\n")
} else {
  cat("Progress:", sum(!is.na(manifest$source_pkg)), "/ 300\n")
  cat("Need:", 300 - sum(!is.na(manifest$source_pkg)), "more\n")
}

cat("\n")
