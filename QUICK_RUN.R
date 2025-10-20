# QUICK_RUN.R
# Run this directly in R or RStudio to expand the dataset collection
# This will install packages and scan for meta-analysis datasets

message("===================================================")
message("Quick Run: Expanding to 300 Real Datasets")
message("===================================================\n")

# Set working directory to repo root
if (basename(getwd()) == "scripts") {
  setwd("..")
}

message("Working directory: ", getwd())
message("Running expansion script...\n")

# Source the main expansion script
source("scripts/expand_to_300_real.R")

message("\n===================================================")
message("Expansion Complete!")
message("Check inst/extdata/metareg/_manifest.csv for results")
message("===================================================")
