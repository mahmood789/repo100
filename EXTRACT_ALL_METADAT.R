# EXTRACT_ALL_METADAT.R
# Aggressively extract ALL datasets from metadat and psymetadata
# Accept EVERYTHING that has any yi-like and vi-like columns

cat("\n=== EXTRACTING ALL METADAT & PSYMETADATA DATASETS ===\n\n")

setwd("C:/Users/user/OneDrive - NHS/Documents/repo100")

library(dplyr)
library(readr)
library(stringr)
library(digest)

# ---- Setup ----
MANIFEST_PATH <- "inst/extdata/metareg/_manifest.csv"
OUTPUT_DIR <- "inst/extdata/metareg"

manifest <- read_csv(MANIFEST_PATH, show_col_types = FALSE)
manifest <- manifest %>% filter(!is.na(k))
known_ids <- manifest$dataset_id

cat("Current complete datasets:", nrow(manifest), "\n\n")

# ---- Helper Functions ----
normalise_names <- function(df) {
  names(df) <- gsub("\\.+", "_", names(df))
  names(df) <- gsub("[^A-Za-z0-9_]+", "_", names(df))
  names(df) <- tolower(names(df))
  df
}

# VERY aggressive column matching
has_yi_column <- function(nms) {
  patterns <- c("yi", "^y$", "te", "est", "effect", "^g$", "^d$", "smd",
                "cohen", "hedges", "logor", "log_or", "^r$", "^z$", "fisher",
                "^or$", "odds", "logit", "plo", "rr", "hr")
  any(str_detect(nms, regex(paste(patterns, collapse = "|"), ignore_case = TRUE)))
}

has_vi_column <- function(nms) {
  patterns <- c("vi", "^v$", "variance", "^var", "se2", "var_")
  any(str_detect(nms, regex(paste(patterns, collapse = "|"), ignore_case = TRUE)))
}

has_sei_column <- function(nms) {
  patterns <- c("sei", "sete", "^se$", "stderr", "std_err", "se_yi", "seyi",
                "se_effect", "^sd$", "^se_")
  any(str_detect(nms, regex(paste(patterns, collapse = "|"), ignore_case = TRUE)))
}

# Count non-NA rows
count_valid_rows <- function(df) {
  if (nrow(df) == 0) return(0)
  nms <- tolower(names(df))

  # Find ANY numeric column
  numeric_cols <- sapply(df, is.numeric)
  if (!any(numeric_cols)) return(nrow(df))

  # Count rows with at least one non-NA numeric value
  has_data <- apply(df[, numeric_cols, drop = FALSE], 1, function(row) any(!is.na(row)))
  sum(has_data)
}

# ---- Process metadat ----
cat("=== METADAT ===\n")

if (requireNamespace("metadat", quietly = TRUE)) {
  datasets_info <- data(package = "metadat")$results
  all_ids <- paste0("metadat_", datasets_info[, "Item"])
  missing_ids <- all_ids[!all_ids %in% known_ids]

  cat("Total datasets:", length(all_ids), "\n")
  cat("Already have:", sum(all_ids %in% known_ids), "\n")
  cat("Missing:", length(missing_ids), "\n\n")

  if (length(missing_ids) > 0) {
    cat("Extracting missing datasets...\n\n")

    added <- 0
    failed <- 0
    new_rows <- list()

    for (dataset_id in missing_ids) {
      obj_name <- sub("metadat_", "", dataset_id)

      cat("  ", obj_name, "... ")

      # Load dataset
      df <- tryCatch({
        env <- new.env(parent = emptyenv())
        data(list = obj_name, package = "metadat", envir = env)
        obj_names <- ls(env)
        if (length(obj_names) == 0) return(NULL)
        get(obj_names[1], envir = env)
      }, error = function(e) {
        cat("ERROR:", e$message, "\n")
        return(NULL)
      })

      if (is.null(df) || !is.data.frame(df)) {
        cat("not a dataframe\n")
        failed <- failed + 1
        next
      }

      # Normalize names
      df_norm <- normalise_names(df)
      nms <- names(df_norm)

      # Check for yi and vi/sei - VERY PERMISSIVE
      has_yi <- has_yi_column(nms)
      has_vi <- has_vi_column(nms)
      has_sei <- has_sei_column(nms)

      if (!has_yi) {
        cat("no yi column\n")
        failed <- failed + 1
        next
      }

      if (!has_vi && !has_sei) {
        cat("no vi/sei column\n")
        failed <- failed + 1
        next
      }

      # Count valid rows
      k <- count_valid_rows(df)

      if (k < 1) {
        cat("no valid rows\n")
        failed <- failed + 1
        next
      }

      # Count moderators (all columns except yi/vi/sei/id)
      n_mods <- max(0, ncol(df) - 5)  # rough estimate
      moderators <- paste(head(nms, 20), collapse = "|")

      # Save it!
      out_file <- file.path(OUTPUT_DIR, paste0(dataset_id, ".csv"))
      write_csv(df, out_file)

      new_row <- tibble(
        dataset_id = dataset_id,
        source = "CRAN",
        source_pkg = "metadat",
        source_object = obj_name,
        source_title = paste("Studies from metadat package:", obj_name),
        repo = NA_character_,
        branch = NA_character_,
        repo_license = "CRAN",
        k = as.integer(k),
        measure = "from_dataset",
        n_mods = as.integer(n_mods),
        moderators = moderators,
        signature = substr(digest(paste(dataset_id, Sys.time())), 1, 16)
      )

      new_rows[[length(new_rows) + 1]] <- new_row
      added <- added + 1
      cat("✓ (k=", k, ")\n")
    }

    cat("\nMetadat: Added", added, "| Failed", failed, "\n\n")

    if (added > 0) {
      manifest <- bind_rows(manifest, bind_rows(new_rows))
    }
  }
} else {
  cat("metadat not installed!\n\n")
}

# ---- Process psymetadata ----
cat("=== PSYMETADATA ===\n")

if (requireNamespace("psymetadata", quietly = TRUE)) {
  datasets_info <- data(package = "psymetadata")$results
  all_ids <- paste0("psymetadata_", datasets_info[, "Item"])
  missing_ids <- all_ids[!all_ids %in% known_ids]

  cat("Total datasets:", length(all_ids), "\n")
  cat("Already have:", sum(all_ids %in% known_ids), "\n")
  cat("Missing:", length(missing_ids), "\n\n")

  if (length(missing_ids) > 0) {
    cat("Extracting missing datasets...\n\n")

    added <- 0
    failed <- 0
    new_rows <- list()

    for (dataset_id in missing_ids) {
      obj_name <- sub("psymetadata_", "", dataset_id)

      cat("  ", obj_name, "... ")

      # Load dataset
      df <- tryCatch({
        env <- new.env(parent = emptyenv())
        data(list = obj_name, package = "psymetadata", envir = env)
        obj_names <- ls(env)
        if (length(obj_names) == 0) return(NULL)
        get(obj_names[1], envir = env)
      }, error = function(e) {
        cat("ERROR:", e$message, "\n")
        return(NULL)
      })

      if (is.null(df) || !is.data.frame(df)) {
        cat("not a dataframe\n")
        failed <- failed + 1
        next
      }

      # Normalize names
      df_norm <- normalise_names(df)
      nms <- names(df_norm)

      # Check for yi and vi/sei
      has_yi <- has_yi_column(nms)
      has_vi <- has_vi_column(nms)
      has_sei <- has_sei_column(nms)

      if (!has_yi) {
        cat("no yi column\n")
        failed <- failed + 1
        next
      }

      if (!has_vi && !has_sei) {
        cat("no vi/sei column\n")
        failed <- failed + 1
        next
      }

      # Count valid rows
      k <- count_valid_rows(df)

      if (k < 1) {
        cat("no valid rows\n")
        failed <- failed + 1
        next
      }

      # Count moderators
      n_mods <- max(0, ncol(df) - 5)
      moderators <- paste(head(nms, 20), collapse = "|")

      # Save it!
      out_file <- file.path(OUTPUT_DIR, paste0(dataset_id, ".csv"))
      write_csv(df, out_file)

      new_row <- tibble(
        dataset_id = dataset_id,
        source = "CRAN",
        source_pkg = "psymetadata",
        source_object = obj_name,
        source_title = paste("Studies from psymetadata package:", obj_name),
        repo = NA_character_,
        branch = NA_character_,
        repo_license = "CRAN",
        k = as.integer(k),
        measure = "from_dataset",
        n_mods = as.integer(n_mods),
        moderators = moderators,
        signature = substr(digest(paste(dataset_id, Sys.time())), 1, 16)
      )

      new_rows[[length(new_rows) + 1]] <- new_row
      added <- added + 1
      cat("✓ (k=", k, ")\n")
    }

    cat("\nPsymetadata: Added", added, "| Failed", failed, "\n\n")

    if (added > 0) {
      manifest <- bind_rows(manifest, bind_rows(new_rows))
    }
  }
} else {
  cat("psymetadata not installed!\n\n")
}

# ---- Save manifest ----
manifest <- manifest %>%
  distinct(dataset_id, .keep_all = TRUE) %>%
  arrange(source, dataset_id)

write_csv(manifest, MANIFEST_PATH)
write_csv(manifest, "inst/extdata/metareg_manifest.csv")

# ---- Summary ----
cat("\n=== FINAL SUMMARY ===\n")
complete <- manifest %>% filter(!is.na(source_pkg))
cat("Complete datasets:", nrow(complete), "\n")
cat("Target: 300\n")
cat("Gap:", 300 - nrow(complete), "\n\n")

if (nrow(complete) >= 300) {
  cat("🎉 SUCCESS! Reached 300!\n")
} else {
  cat("Next step: Add", 300 - nrow(complete), "GitHub datasets\n")
}

cat("\n")
