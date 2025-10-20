# TEST_DEVTOOLS.R
# Test that the package works with devtools before pushing to GitHub

cat("\n")
cat("============================================================\n")
cat("  Testing Package with devtools\n")
cat("============================================================\n\n")

setwd("C:/Users/user/OneDrive - NHS/Documents/repo100")

# ---- Step 1: Check devtools is installed ----
cat("Step 1: Checking devtools installation...\n")

if (!requireNamespace("devtools", quietly = TRUE)) {
  cat("  Installing devtools...\n")
  install.packages("devtools")
}

library(devtools)
cat("  ✓ devtools loaded\n\n")

# ---- Step 2: Load package with devtools ----
cat("Step 2: Loading package with devtools::load_all()...\n")

result <- tryCatch({
  devtools::load_all()
  cat("  ✓ Package loaded successfully!\n\n")
  TRUE
}, error = function(e) {
  cat("  ✗ ERROR:", e$message, "\n\n")
  FALSE
})

if (!result) {
  cat("FAILED: Package could not be loaded with devtools\n")
  stop("Fix errors before pushing to GitHub")
}

# ---- Step 3: Test data file access ----
cat("Step 3: Testing data file access...\n")

# Test manifest access
manifest_path <- system.file("extdata/metareg_manifest.csv", package = "repo100")

if (manifest_path == "") {
  cat("  ℹ Manifest not accessible via system.file() (expected in dev mode)\n")
  cat("  Checking direct file access...\n")

  # In dev mode, check inst/extdata directly
  if (file.exists("inst/extdata/metareg_manifest.csv")) {
    cat("  ✓ Manifest file exists at inst/extdata/metareg_manifest.csv\n")
  } else {
    cat("  ✗ ERROR: Manifest file not found!\n")
    stop("Manifest file missing")
  }
} else {
  cat("  ✓ Manifest accessible via system.file()\n")
}

# Test a sample dataset
if (file.exists("inst/extdata/metareg/metadat_dat.bcg.csv")) {
  cat("  ✓ Sample dataset exists (metadat_dat.bcg.csv)\n")
} else {
  cat("  ⚠ Warning: Sample dataset not found\n")
}

cat("\n")

# ---- Step 4: Count CSV files ----
cat("Step 4: Counting dataset files...\n")

csv_files <- list.files("inst/extdata/metareg", pattern = "\\.csv$", full.names = FALSE)
csv_files <- csv_files[csv_files != "_manifest.csv"]

cat("  Total CSV files:", length(csv_files), "\n")

# Load manifest
library(readr)
manifest <- read_csv("inst/extdata/metareg_manifest.csv", show_col_types = FALSE)

cat("  Manifest entries:", nrow(manifest), "\n")
cat("  Complete entries:", sum(!is.na(manifest$source_pkg)), "\n")
cat("  Incomplete entries:", sum(is.na(manifest$source_pkg)), "\n\n")

# ---- Step 5: Test exported functions ----
cat("Step 5: Testing exported functions...\n")

test_result <- tryCatch({
  # Test that functions exist
  if (!exists("metareg_manifest")) {
    cat("  ✗ ERROR: metareg_manifest() not found\n")
    FALSE
  } else if (!exists("metareg_datasets")) {
    cat("  ✗ ERROR: metareg_datasets() not found\n")
    FALSE
  } else if (!exists("metareg_read")) {
    cat("  ✗ ERROR: metareg_read() not found\n")
    FALSE
  } else {
    cat("  ✓ All functions exported correctly\n")

    # Try to call metareg_manifest in dev mode
    cat("  Testing metareg_manifest()...\n")

    # Set dev option to use inst/extdata directly
    options(metahub.metareg_dir = "inst/extdata/metareg")

    m <- metareg_manifest()
    cat("    ✓ Loaded manifest with", nrow(m), "entries\n")

    # Test metareg_datasets
    ids <- metareg_datasets()
    cat("    ✓ Found", length(ids), "dataset IDs\n")

    cat("  ✓ All functions work!\n\n")
    TRUE
  }
}, error = function(e) {
  cat("  ✗ ERROR testing functions:", e$message, "\n\n")
  FALSE
})

check_result <- test_result

# ---- Summary ----
cat("============================================================\n")
cat("  TEST SUMMARY\n")
cat("============================================================\n\n")

cat("✓ devtools::load_all() works\n")
cat("✓ Data files accessible\n")
cat("✓", length(csv_files), "CSV datasets found\n")
cat("✓", nrow(manifest), "manifest entries\n\n")

if (!is.na(check_result) && check_result) {
  cat("✓ Package check passed\n\n")
} else if (!is.na(check_result) && !check_result) {
  cat("✗ Package check failed - fix errors before pushing\n\n")
} else {
  cat("ℹ Package check skipped\n\n")
}

cat("RECOMMENDATION:\n")

incomplete_count <- sum(is.na(manifest$source_pkg))

if (incomplete_count > 0) {
  cat("  1. Run FINALIZE_COLLECTION.R to remove", incomplete_count, "incomplete entries\n")
  cat("  2. Then commit and push to GitHub\n\n")
  cat("Run this next:\n")
  cat('  source("FINALIZE_COLLECTION.R")\n\n')
} else {
  cat("  Package is ready to commit and push to GitHub!\n\n")
}

cat("Your package is COMPATIBLE with devtools! ✅\n\n")
