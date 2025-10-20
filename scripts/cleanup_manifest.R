# cleanup_manifest.R
# Clean up the manifest by:
# 1. Removing toy/simulated datasets
# 2. Fixing incomplete entries
# 3. Removing duplicates

library(dplyr)
library(readr)
library(stringr)

message("=== Cleaning Manifest ===\n")

MANIFEST_PATH <- "inst/extdata/metareg/_manifest.csv"

# Load manifest
manifest <- read_csv(MANIFEST_PATH, show_col_types = FALSE)
initial_count <- nrow(manifest)
message("Initial dataset count: ", initial_count)

# 1. Remove incomplete rows (NA in critical columns)
manifest_complete <- manifest %>%
  filter(!is.na(k), !is.na(source_pkg) | source == "GitHub")

removed_incomplete <- initial_count - nrow(manifest_complete)
message("\nRemoved ", removed_incomplete, " incomplete entries")

# 2. Identify and remove toy datasets
toy_patterns <- c("\\btoy\\b", "simulated", "synthetic", "example data",
                  "demo", "illustration", "hypothetical", "artificial")

is_toy_dataset <- function(title, obj_name) {
  if (is.na(title)) title <- ""
  if (is.na(obj_name)) obj_name <- ""

  combined <- paste(tolower(title), tolower(obj_name))
  any(str_detect(combined, toy_patterns))
}

toys <- manifest_complete %>%
  rowwise() %>%
  filter(is_toy_dataset(source_title, source_object)) %>%
  ungroup()

if (nrow(toys) > 0) {
  message("\nFound ", nrow(toys), " toy datasets:")
  toys %>%
    select(dataset_id, source_title) %>%
    print(n = Inf)

  # Remove toy datasets
  manifest_clean <- manifest_complete %>%
    rowwise() %>%
    filter(!is_toy_dataset(source_title, source_object)) %>%
    ungroup()

  message("\nRemoved ", nrow(toys), " toy datasets")
} else {
  manifest_clean <- manifest_complete
  message("\n✓ No toy datasets found")
}

# 3. Remove duplicates
dups_before <- manifest_clean %>%
  group_by(dataset_id) %>%
  filter(n() > 1) %>%
  ungroup()

if (nrow(dups_before) > 0) {
  message("\nFound ", nrow(dups_before), " duplicate entries")
  manifest_clean <- manifest_clean %>%
    distinct(dataset_id, .keep_all = TRUE)
  message("Removed duplicates")
} else {
  message("\n✓ No duplicates found")
}

# 4. Sort by source and dataset_id
manifest_clean <- manifest_clean %>%
  arrange(source, dataset_id)

# 5. Save cleaned manifest
write_csv(manifest_clean, MANIFEST_PATH)
write_csv(manifest_clean, "inst/extdata/metareg_manifest.csv")

# Summary
message("\n=== SUMMARY ===")
message("Initial count: ", initial_count)
message("Final count: ", nrow(manifest_clean))
message("Removed: ", initial_count - nrow(manifest_clean), " datasets")
message("  - ", removed_incomplete, " incomplete")
message("  - ", nrow(toys), " toy datasets")
message("  - ", nrow(dups_before), " duplicates")

message("\n✓ Manifest cleaned and saved")
message("  - inst/extdata/metareg/_manifest.csv")
message("  - inst/extdata/metareg_manifest.csv")
