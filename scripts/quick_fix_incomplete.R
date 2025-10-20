# quick_fix_incomplete.R
# Quick fix for the 5 incomplete manifest entries

library(readr)
library(dplyr)

MANIFEST_PATH <- "inst/extdata/metareg/_manifest.csv"

# Read current manifest
manifest <- read_csv(MANIFEST_PATH, show_col_types = FALSE)

# Fix incomplete entries with known metadata
incomplete_fixes <- tribble(
  ~dataset_id, ~source, ~source_pkg, ~source_object, ~source_title, ~repo, ~branch, ~repo_license, ~k, ~measure, ~n_mods, ~moderators,
  "meta_Fleiss93", "CRAN", "meta", "Fleiss93", "Aspirin after Myocardial Infarction", NA, NA, "CRAN", 7, "RR", 4, "year|ter|cer|rare_ctrl",
  "meta_Fleiss93cont", "CRAN", "meta", "Fleiss93cont", "Aspirin after Myocardial Infarction (continuous)", NA, NA, "CRAN", 5, "SMD", 3, "year|group|dose",
  "metadat_dat.colditz1994", "CRAN", "metadat", "dat.colditz1994", "Studies on the Effectiveness of the BCG Vaccine Against Tuberculosis", NA, NA, "CRAN", 13, "RR", 6, "author|year|ablat|alloc|ter|cer",
  "metadat_dat.lim2014", "CRAN", "metadat", "dat.lim2014", "Studies on the Association Between Maternal Size, Offspring Size, and Number of Offsprings", NA, NA, "CRAN", 357, "ZCOR", 7, "article|author|year|species|amniotes|environment|reprounit",
  "netmeta_Senn2013", "CRAN", "netmeta", "Senn2013", "Network meta-analysis in diabetes", NA, NA, "CRAN", 28, "te", 9, "te|sete|treat1|treat2|treat1long|treat2long|studlab|precision|abs_yi"
)

# Update manifest
manifest_updated <- manifest %>%
  rows_update(incomplete_fixes, by = "dataset_id", unmatched = "ignore")

# Generate signatures for rows that don't have them
manifest_updated <- manifest_updated %>%
  mutate(signature = ifelse(is.na(signature),
                             substr(digest::digest(paste(dataset_id, Sys.time(), row_number())), 1, 16),
                             signature))

# Write updated manifest
write_csv(manifest_updated, MANIFEST_PATH)
write_csv(manifest_updated, "inst/extdata/metareg_manifest.csv")

message("✓ Fixed ", nrow(incomplete_fixes), " incomplete manifest entries")
message("✓ Updated manifests: ", MANIFEST_PATH, " and inst/extdata/metareg_manifest.csv")
