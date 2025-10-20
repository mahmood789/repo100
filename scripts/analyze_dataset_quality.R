# analyze_dataset_quality.R
# Analyze how many datasets are actually suitable for meta-regression
# and how many are real vs synthetic

library(readr)
library(dplyr)
library(stringr)

manifest <- read_csv("inst/extdata/metareg/_manifest.csv", show_col_types = FALSE)

# Remove incomplete rows
manifest <- manifest %>% filter(!is.na(k))

cat("=== Dataset Quality Analysis ===\n\n")

# 1. Meta-REGRESSION suitability (has moderators)
metareg_suitable <- manifest %>% filter(!is.na(n_mods) & n_mods > 0)
cat("META-REGRESSION DATASETS (with moderators):\n")
cat("  Total with n_mods > 0: ", nrow(metareg_suitable), "/", nrow(manifest), "\n")
cat("  Percentage: ", round(100*nrow(metareg_suitable)/nrow(manifest), 1), "%\n\n")

# Distribution by moderator count
cat("Distribution by number of moderators:\n")
mod_dist <- manifest %>%
  filter(!is.na(n_mods)) %>%
  mutate(mod_group = case_when(
    n_mods == 0 ~ "0 (no moderators)",
    n_mods <= 3 ~ "1-3",
    n_mods <= 6 ~ "4-6",
    n_mods <= 10 ~ "7-10",
    n_mods <= 20 ~ "11-20",
    TRUE ~ "20+"
  )) %>%
  count(mod_group, sort = TRUE)
print(mod_dist, n = 20)

# 2. Identify TOY/SYNTHETIC/SIMULATED datasets
cat("\n\nTOY/SYNTHETIC/SIMULATED DATASETS:\n")
synthetic_keywords <- c("toy", "simulated", "synthetic", "example", "demo")

synthetic_datasets <- manifest %>%
  filter(str_detect(tolower(source_title), paste(synthetic_keywords, collapse = "|")))

cat("  Found ", nrow(synthetic_datasets), " datasets with synthetic indicators:\n")
if (nrow(synthetic_datasets) > 0) {
  synthetic_datasets %>%
    select(dataset_id, source_title, k, n_mods) %>%
    print(n = 50)
}

# 3. Identify GWAS/Model Output datasets (not traditional meta-analyses)
cat("\n\nGWAS / MODEL OUTPUT DATASETS:\n")
gwas_keywords <- c("gwas", "signals", "farmcpu", "glm_signals", "model\\d+", "paramests",
                   "loo_table", "elpd", "contrasts", "posthoc", "emmeans")

gwas_datasets <- manifest %>%
  filter(str_detect(tolower(dataset_id), paste(gwas_keywords, collapse = "|")) |
         str_detect(tolower(source_title), "gwas|parameter|model output|estimates|contrasts"))

cat("  Found ", nrow(gwas_datasets), " datasets that appear to be GWAS/model outputs:\n")
if (nrow(gwas_datasets) > 0) {
  gwas_datasets %>%
    select(dataset_id, source_title, k, n_mods) %>%
    head(20) %>%
    print(n = 20)
}

# 4. REAL META-ANALYSES (from established packages)
cat("\n\nREAL CLINICAL/RESEARCH META-ANALYSES:\n")
real_metaanalyses <- manifest %>%
  filter(source == "CRAN",
         source_pkg %in% c("metadat", "psymetadata", "meta", "metaSEM"),
         !str_detect(tolower(source_title), paste(synthetic_keywords, collapse = "|")))

cat("  From established packages (metadat, psymetadata, meta, metaSEM): ",
    nrow(real_metaanalyses), "\n")

# Count by package
real_by_pkg <- real_metaanalyses %>%
  count(source_pkg, name = "n_datasets") %>%
  arrange(desc(n_datasets))
cat("\n  By package:\n")
print(real_by_pkg)

# 5. Summary by source
cat("\n\nBY SOURCE:\n")
source_summary <- manifest %>%
  group_by(source) %>%
  summarize(
    n_datasets = n(),
    n_with_mods = sum(!is.na(n_mods) & n_mods > 0),
    pct_with_mods = round(100 * n_with_mods / n_datasets, 1),
    median_k = median(k, na.rm = TRUE),
    median_mods = median(n_mods, na.rm = TRUE)
  )
print(source_summary)

# 6. FINAL RECOMMENDATIONS
cat("\n\n=== SUMMARY & RECOMMENDATIONS ===\n\n")

real_metareg <- real_metaanalyses %>% filter(!is.na(n_mods) & n_mods > 0)
cat("✓ REAL meta-regression datasets: ", nrow(real_metareg), "\n")
cat("  (From CRAN packages, with moderators, not toy datasets)\n\n")

questionable <- nrow(synthetic_datasets) + nrow(gwas_datasets)
cat("⚠ Questionable datasets: ", questionable, "\n")
cat("  - ", nrow(synthetic_datasets), " toy/simulated\n")
cat("  - ", nrow(gwas_datasets), " GWAS/model outputs\n\n")

# Calculate how many more REAL datasets needed for 300
target <- 300
current_real <- nrow(real_metareg)
needed <- target - current_real

cat("TARGET: 300 real meta-regression datasets\n")
cat("CURRENT: ", current_real, " real meta-regression datasets\n")
cat("NEEDED: ", needed, " more datasets\n\n")

cat("RECOMMENDATION:\n")
if (needed > 0) {
  cat("- Filter out GWAS and toy datasets\n")
  cat("- Focus on CRAN packages (metadat, psymetadata) for expansion\n")
  cat("- Need ~", needed, " more from established sources\n")
  cat("- Consider adding datasets from: metafor, meta, cochrane\n")
} else {
  cat("- Already have sufficient real meta-regression datasets!\n")
  cat("- Focus on quality over quantity\n")
}

# Save analysis
write_csv(synthetic_datasets, "scripts/analysis_synthetic_datasets.csv")
write_csv(gwas_datasets, "scripts/analysis_gwas_datasets.csv")
write_csv(real_metareg, "scripts/analysis_real_metaregression.csv")

cat("\n✓ Analysis saved to scripts/analysis_*.csv\n")
