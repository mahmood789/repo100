# INSTALL_AND_EXPAND.R
# Install missing meta-analysis packages then run expansion to 300 datasets

cat("\n")
cat("============================================================\n")
cat("  Installing Missing Packages & Expanding to 300 Datasets\n")
cat("============================================================\n\n")

setwd("C:/Users/user/OneDrive - NHS/Documents/repo100")

# Set CRAN mirror
options(repos = c(CRAN = "https://cloud.r-project.org"))
Sys.unsetenv("RSPM")

# ---- STEP 1: Install ALL meta-analysis packages ----
cat("STEP 1: Installing Meta-Analysis Packages\n")
cat("-------------------------------------------\n")

meta_packages <- c(
  "metadat", "metafor", "meta", "metaSEM", "psymetadata", "dmetar",
  "MAd", "metaplus", "rmeta", "metamisc", "clubSandwich", "robumeta",
  "weightr", "PublicationBias", "metaBMA", "RoBMA"
)

cat("Packages to check/install (16 total):\n")
cat("  ", paste(meta_packages, collapse = ", "), "\n\n")

installed_count <- 0
failed_count <- 0
failed_packages <- c()

for (pkg in meta_packages) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    cat("  ✓", pkg, "- already installed\n")
    installed_count <- installed_count + 1
  } else {
    cat("  ⏳", pkg, "- installing...\n")
    result <- tryCatch({
      install.packages(pkg, quiet = TRUE)
      if (requireNamespace(pkg, quietly = TRUE)) {
        cat("    ✓ Successfully installed\n")
        installed_count <- installed_count + 1
        TRUE
      } else {
        cat("    ✗ Installation failed\n")
        failed_count <- failed_count + 1
        failed_packages <- c(failed_packages, pkg)
        FALSE
      }
    }, error = function(e) {
      cat("    ✗ Error:", e$message, "\n")
      failed_count <- failed_count + 1
      failed_packages <- c(failed_packages, pkg)
      FALSE
    })
  }
}

cat("\n")
cat("Installation Summary:\n")
cat("  ✓ Available:", installed_count, "/", length(meta_packages), "\n")
if (failed_count > 0) {
  cat("  ✗ Failed:", failed_count, "-", paste(failed_packages, collapse = ", "), "\n")
  cat("  (These will be skipped during expansion)\n")
}
cat("\n")

# Pause to review
cat("Press [Enter] to continue to expansion...")
readline()

# ---- STEP 2: Run Expansion ----
cat("\n")
cat("============================================================\n")
cat("STEP 2: Running Expansion to 300 Datasets\n")
cat("============================================================\n")
cat("This will scan all installed packages and add datasets...\n")
cat("Expected time: 5-20 minutes\n\n")

source("scripts/expand_to_300_real.R")

# ---- STEP 3: Final Summary ----
cat("\n")
cat("============================================================\n")
cat("FINAL SUMMARY\n")
cat("============================================================\n\n")

library(readr)
library(dplyr)

manifest <- read_csv("inst/extdata/metareg/_manifest.csv", show_col_types = FALSE)

# Count complete entries
complete <- manifest %>% filter(!is.na(source_pkg))
incomplete <- manifest %>% filter(is.na(source_pkg))

cat("Total manifest entries:", nrow(manifest), "\n")
cat("  Complete:", nrow(complete), "\n")
cat("  Incomplete:", nrow(incomplete), "\n\n")

if (nrow(complete) >= 300) {
  cat("🎉🎉🎉 SUCCESS! Reached", nrow(complete), "datasets! 🎉🎉🎉\n\n")
} else {
  cat("Progress:", nrow(complete), "/ 300 datasets\n")
  cat("Still need:", 300 - nrow(complete), "more\n\n")
}

# Show what was added
cran_summary <- complete %>%
  filter(source == "CRAN") %>%
  count(source_pkg, sort = TRUE)

cat("CRAN datasets by package:\n")
print(cran_summary, n = 20)

cat("\n")
cat("============================================================\n")
cat("Process Complete!\n")
cat("============================================================\n\n")
