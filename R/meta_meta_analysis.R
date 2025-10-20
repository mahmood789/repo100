#' Meta-Meta-Analysis of All Datasets
#'
#' Performs a comprehensive meta-meta-analysis across all datasets in the
#' collection, extracting effect sizes, analyzing moderators, and creating
#' summary reports and visualizations.
#'
#' @param output_dir Directory to save output files. If NULL (default), files
#'   are saved to the current working directory.
#' @param save_plots Logical. If TRUE (default), saves visualization plots as PNG files.
#' @param save_reports Logical. If TRUE (default), saves summary reports as CSV files.
#' @param verbose Logical. If TRUE (default), prints progress messages.
#'
#' @return A list containing:
#'   \itemize{
#'     \item \code{all_effects} - Data frame of all extracted effect sizes
#'     \item \code{manifest} - Full manifest data
#'     \item \code{summary_stats} - Summary statistics
#'     \item \code{source_analysis} - Analysis by source
#'     \item \code{moderator_freq} - Moderator frequency table
#'   }
#'
#' @examples
#' \dontrun{
#' # Run full analysis
#' results <- metareg_meta_analysis()
#'
#' # Run without saving files
#' results <- metareg_meta_analysis(save_plots = FALSE, save_reports = FALSE)
#'
#' # Save to specific directory
#' results <- metareg_meta_analysis(output_dir = "output/meta_meta")
#' }
#'
#' @export
metareg_meta_analysis <- function(output_dir = NULL,
                                   save_plots = TRUE,
                                   save_reports = TRUE,
                                   verbose = TRUE) {

  if (verbose) {
    cat("\n")
    cat("============================================================\n")
    cat("  META-META-ANALYSIS OF ENTIRE COLLECTION\n")
    cat("============================================================\n\n")
  }

  # Load manifest using package function
  if (verbose) cat("Loading manifest...\n")
  manifest <- metareg_manifest()

  if (verbose) {
    cat("  Total datasets:", nrow(manifest), "\n")
    cat("  Total studies (k):", sum(manifest$k, na.rm = TRUE), "\n\n")
  }

  # Load all datasets
  if (verbose) cat("Loading all datasets (this may take a minute)...\n\n")

  all_data <- list()
  load_errors <- character()

  for (i in seq_len(nrow(manifest))) {
    if (verbose && i %% 50 == 0) cat("  Loaded", i, "datasets...\n")

    dataset_id <- manifest$dataset_id[i]

    df <- tryCatch({
      metareg_read(dataset_id)
    }, error = function(e) {
      load_errors <- c(load_errors, dataset_id)
      NULL
    })

    if (!is.null(df)) {
      # Add metadata
      df$dataset_id <- dataset_id
      df$source <- manifest$source[i]
      df$dataset_k <- manifest$k[i]

      all_data[[length(all_data) + 1]] <- df
    }
  }

  if (verbose) {
    cat("\n")
    if (length(load_errors) > 0) {
      cat("  Warning: Failed to load", length(load_errors), "datasets\n\n")
    } else {
      cat("  Successfully loaded all", length(all_data), "datasets\n\n")
    }
  }

  # Extract effect sizes
  if (verbose) cat("Extracting effect sizes from all datasets...\n")

  effect_sizes <- .extract_all_effect_sizes(all_data, verbose = verbose)

  if (verbose) {
    cat("\n")
    if (effect_sizes$errors > 0) {
      cat("  Warning: Extraction errors:", effect_sizes$errors, "datasets\n")
    }
    cat("  Successfully extracted from", length(effect_sizes$data), "datasets\n\n")
  }

  # Combine all effect sizes
  if (verbose) cat("Combining all effect sizes...\n")
  all_effects <- dplyr::bind_rows(effect_sizes$data)

  if (verbose) {
    cat("  Total studies extracted:", nrow(all_effects), "\n")
    cat("  From", length(unique(all_effects$dataset_id)), "datasets\n\n")
  }

  # Summary statistics
  summary_stats <- .compute_summary_stats(all_effects, manifest, verbose = verbose)

  # Source analysis
  source_analysis <- .analyze_by_source(manifest)

  # Moderator analysis
  moderator_freq <- .analyze_moderators(manifest, verbose = verbose)

  # Save reports if requested
  if (save_reports) {
    .save_reports(all_effects, manifest, source_analysis, moderator_freq,
                  output_dir = output_dir, verbose = verbose)
  }

  # Create visualizations if requested
  if (save_plots) {
    .create_visualizations(all_effects, manifest, source_analysis,
                          output_dir = output_dir, verbose = verbose)
  }

  # Final summary
  if (verbose) {
    cat("============================================================\n")
    cat("  META-META-ANALYSIS COMPLETE\n")
    cat("============================================================\n\n")

    cat("COLLECTION OVERVIEW:\n")
    cat("  Total datasets:", nrow(manifest), "\n")
    cat("  Total studies:", sum(manifest$k, na.rm = TRUE), "\n")
    cat("  Total effect sizes extracted:", nrow(all_effects), "\n")
    cat("  Datasets with moderators:", sum(manifest$n_mods > 0, na.rm = TRUE), "\n\n")

    cat("KEY FINDINGS:\n")
    cat("  - Average", round(mean(manifest$k, na.rm = TRUE), 1), "studies per dataset\n")
    cat("  - Mean effect size:", round(mean(all_effects$yi, na.rm = TRUE), 3), "\n")
    cat("  - Average", round(mean(manifest$n_mods, na.rm = TRUE), 1), "moderators per dataset\n")
    cat("  - Data from", nrow(source_analysis), "different sources\n\n")

    if (save_reports || save_plots) {
      cat("FILES CREATED:\n")
      if (save_reports) {
        cat("  CSV Reports:\n")
        cat("    - META_META_all_effect_sizes.csv\n")
        cat("    - META_META_dataset_summary.csv\n")
        cat("    - META_META_moderator_frequency.csv\n")
        cat("    - META_META_source_analysis.csv\n\n")
      }
      if (save_plots) {
        cat("  Visualizations:\n")
        cat("    - META_META_effect_size_distribution.png\n")
        cat("    - META_META_dataset_size_distribution.png\n")
        cat("    - META_META_moderators_distribution.png\n")
        cat("    - META_META_datasets_by_source.png\n\n")
      }
    }

    cat("Done!\n\n")
  }

  # Return results invisibly
  invisible(list(
    all_effects = all_effects,
    manifest = manifest,
    summary_stats = summary_stats,
    source_analysis = source_analysis,
    moderator_freq = moderator_freq
  ))
}

# Internal helper functions ----

.normalise_names <- function(df) {
  names(df) <- tolower(gsub("[^A-Za-z0-9_]", "_", names(df)))
  df
}

.find_yi_col <- function(nms) {
  patterns <- c("yi", "^y$", "te", "est", "effect", "^g$", "^d$", "smd",
                "cohen", "hedges", "logor", "log_or", "lor", "lnor",
                "^r$", "^z$", "fisher", "^or$", "odds", "logit", "plo",
                "rr", "hr", "^es$", "eff", "beta", "coef")

  for (pat in patterns) {
    matches <- grep(pat, nms, ignore.case = TRUE, value = TRUE)
    if (length(matches) > 0) return(matches[1])
  }
  return(NA)
}

.find_vi_col <- function(nms) {
  patterns <- c("vi", "^v$", "variance", "^var$", "se2", "var_")

  for (pat in patterns) {
    matches <- grep(pat, nms, ignore.case = TRUE, value = TRUE)
    if (length(matches) > 0) return(matches[1])
  }
  return(NA)
}

.find_sei_col <- function(nms) {
  patterns <- c("sei", "sete", "^se$", "stderr", "std_err", "se_yi",
                "se_effect", "^sd$", "^se_", "se_lor", "selorg", "se_or")

  for (pat in patterns) {
    matches <- grep(pat, nms, ignore.case = TRUE, value = TRUE)
    if (length(matches) > 0) return(matches[1])
  }
  return(NA)
}

.extract_all_effect_sizes <- function(all_data, verbose = TRUE) {
  effect_sizes <- list()
  extraction_errors <- 0

  for (i in seq_along(all_data)) {
    if (verbose && i %% 50 == 0) {
      cat("  Extracted effect sizes from", i, "datasets...\n")
    }

    df <- all_data[[i]]
    df_norm <- .normalise_names(df)
    nms <- names(df_norm)

    yi_col <- .find_yi_col(nms)
    vi_col <- .find_vi_col(nms)
    sei_col <- .find_sei_col(nms)

    if (!is.na(yi_col)) {
      tryCatch({
        # Suppress warnings about NAs introduced by coercion (expected behavior)
        suppressWarnings({
          yi_vals <- as.numeric(df_norm[[yi_col]])

          # Get variance
          if (!is.na(vi_col)) {
            vi_vals <- as.numeric(df_norm[[vi_col]])
          } else if (!is.na(sei_col)) {
            vi_vals <- as.numeric(df_norm[[sei_col]])^2
          } else {
            vi_vals <- rep(NA, length(yi_vals))
          }
        })

        # Create data frame
        es_df <- data.frame(
          dataset_id = df$dataset_id[1],
          source = df$source[1],
          yi = yi_vals,
          vi = vi_vals,
          stringsAsFactors = FALSE
        )

        # Filter finite values
        es_df <- dplyr::filter(es_df, is.finite(yi), is.finite(vi))

        if (nrow(es_df) > 0) {
          effect_sizes[[length(effect_sizes) + 1]] <- es_df
        }
      }, error = function(e) {
        extraction_errors <<- extraction_errors + 1
      })
    }
  }

  list(data = effect_sizes, errors = extraction_errors)
}

.compute_summary_stats <- function(all_effects, manifest, verbose = TRUE) {
  if (verbose) {
    cat("============================================================\n")
    cat("  COLLECTION SUMMARY STATISTICS\n")
    cat("============================================================\n\n")

    cat("DATASET LEVEL:\n")
    cat("  Total datasets:", nrow(manifest), "\n")
    cat("  Total studies (k):", sum(manifest$k, na.rm = TRUE), "\n")
    cat("  Average studies per dataset:", round(mean(manifest$k, na.rm = TRUE), 1), "\n")
    cat("  Median studies per dataset:", median(manifest$k, na.rm = TRUE), "\n")
    cat("  Range:", min(manifest$k, na.rm = TRUE), "-", max(manifest$k, na.rm = TRUE), "\n\n")

    cat("EFFECT SIZE LEVEL:\n")
    cat("  Total effect sizes extracted:", nrow(all_effects), "\n")
    cat("  Mean effect size (yi):", round(mean(all_effects$yi, na.rm = TRUE), 3), "\n")
    cat("  Median effect size (yi):", round(median(all_effects$yi, na.rm = TRUE), 3), "\n")
    cat("  SD effect size:", round(sd(all_effects$yi, na.rm = TRUE), 3), "\n")
    cat("  Range:", round(min(all_effects$yi, na.rm = TRUE), 3), "to",
        round(max(all_effects$yi, na.rm = TRUE), 3), "\n\n")

    cat("EFFECT SIZES BY SOURCE:\n")
  }

  es_by_source <- all_effects %>%
    dplyr::group_by(source) %>%
    dplyr::summarise(
      n_effects = dplyr::n(),
      mean_yi = round(mean(yi, na.rm = TRUE), 3),
      median_yi = round(median(yi, na.rm = TRUE), 3),
      sd_yi = round(sd(yi, na.rm = TRUE), 3),
      .groups = "drop"
    ) %>%
    dplyr::arrange(dplyr::desc(n_effects))

  if (verbose) {
    print(es_by_source)
    cat("\n")
  }

  list(
    dataset_stats = list(
      n = nrow(manifest),
      total_k = sum(manifest$k, na.rm = TRUE),
      mean_k = mean(manifest$k, na.rm = TRUE),
      median_k = median(manifest$k, na.rm = TRUE)
    ),
    effect_size_stats = list(
      n = nrow(all_effects),
      mean_yi = mean(all_effects$yi, na.rm = TRUE),
      median_yi = median(all_effects$yi, na.rm = TRUE),
      sd_yi = sd(all_effects$yi, na.rm = TRUE)
    ),
    by_source = es_by_source
  )
}

.analyze_by_source <- function(manifest) {
  manifest %>%
    dplyr::group_by(source) %>%
    dplyr::summarise(
      datasets = dplyr::n(),
      total_studies = sum(k, na.rm = TRUE),
      avg_k = round(mean(k, na.rm = TRUE), 1),
      avg_mods = round(mean(n_mods, na.rm = TRUE), 1),
      .groups = "drop"
    ) %>%
    dplyr::arrange(dplyr::desc(datasets))
}

.analyze_moderators <- function(manifest, verbose = TRUE) {
  if (verbose) {
    cat("============================================================\n")
    cat("  MODERATOR ANALYSIS\n")
    cat("============================================================\n\n")

    cat("MODERATOR COVERAGE:\n")
    cat("  Datasets with 0 moderators:", sum(manifest$n_mods == 0, na.rm = TRUE), "\n")
    cat("  Datasets with 1-2 moderators:", sum(manifest$n_mods >= 1 & manifest$n_mods < 3, na.rm = TRUE), "\n")
    cat("  Datasets with 3-5 moderators:", sum(manifest$n_mods >= 3 & manifest$n_mods < 6, na.rm = TRUE), "\n")
    cat("  Datasets with 6-10 moderators:", sum(manifest$n_mods >= 6 & manifest$n_mods <= 10, na.rm = TRUE), "\n")
    cat("  Datasets with 10+ moderators:", sum(manifest$n_mods > 10, na.rm = TRUE), "\n\n")

    cat("  Average moderators per dataset:", round(mean(manifest$n_mods, na.rm = TRUE), 1), "\n")
    cat("  Median moderators per dataset:", median(manifest$n_mods, na.rm = TRUE), "\n\n")
  }

  # Extract common moderator names
  all_moderators <- unlist(strsplit(manifest$moderators, "\\|"))
  all_moderators <- tolower(all_moderators)
  all_moderators <- all_moderators[!is.na(all_moderators) & all_moderators != ""]

  # Count frequency
  mod_table <- sort(table(all_moderators), decreasing = TRUE)

  if (verbose) {
    cat("COMMON MODERATOR TYPES:\n")
    cat("  Top 20 most common moderators:\n")
    for (i in 1:min(20, length(mod_table))) {
      cat(sprintf("    %2d. %-30s %4d datasets\n", i, names(mod_table)[i], mod_table[i]))
    }
    cat("\n")
  }

  data.frame(
    moderator = names(mod_table),
    frequency = as.integer(mod_table),
    stringsAsFactors = FALSE
  )
}

.save_reports <- function(all_effects, manifest, source_analysis, moderator_freq,
                          output_dir = NULL, verbose = TRUE) {

  if (verbose) cat("Saving detailed reports...\n")

  # Set output directory
  if (!is.null(output_dir)) {
    if (!dir.exists(output_dir)) {
      dir.create(output_dir, recursive = TRUE)
    }
    out_path <- function(x) file.path(output_dir, x)
  } else {
    out_path <- function(x) x
  }

  # Report 1: Effect size summary
  readr::write_csv(all_effects, out_path("META_META_all_effect_sizes.csv"))
  if (verbose) cat("  ✓ META_META_all_effect_sizes.csv (", nrow(all_effects), " effect sizes)\n", sep = "")

  # Report 2: Dataset summary
  dataset_summary <- manifest %>%
    dplyr::select(dataset_id, source, k, measure, n_mods) %>%
    dplyr::arrange(source, dataset_id)

  readr::write_csv(dataset_summary, out_path("META_META_dataset_summary.csv"))
  if (verbose) cat("  ✓ META_META_dataset_summary.csv\n")

  # Report 3: Moderator frequency
  readr::write_csv(moderator_freq, out_path("META_META_moderator_frequency.csv"))
  if (verbose) cat("  ✓ META_META_moderator_frequency.csv\n")

  # Report 4: Source summary
  readr::write_csv(source_analysis, out_path("META_META_source_analysis.csv"))
  if (verbose) cat("  ✓ META_META_source_analysis.csv\n\n")
}

.create_visualizations <- function(all_effects, manifest, source_analysis,
                                   output_dir = NULL, verbose = TRUE) {

  if (verbose) cat("Creating visualizations...\n")

  # Set output directory
  if (!is.null(output_dir)) {
    out_path <- function(x) file.path(output_dir, x)
  } else {
    out_path <- function(x) x
  }

  # Plot 1: Effect size distribution
  tryCatch({
    p1 <- ggplot2::ggplot(all_effects, ggplot2::aes(x = yi)) +
      ggplot2::geom_histogram(bins = 50, fill = "steelblue", alpha = 0.7) +
      ggplot2::theme_minimal() +
      ggplot2::labs(title = "Distribution of All Effect Sizes",
                    x = "Effect Size (yi)",
                    y = "Frequency") +
      ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0.5))

    ggplot2::ggsave(out_path("META_META_effect_size_distribution.png"),
                    p1, width = 8, height = 6, dpi = 300)
    if (verbose) cat("  ✓ META_META_effect_size_distribution.png\n")
  }, error = function(e) {
    if (verbose) cat("  ✗ Error creating effect size distribution plot\n")
  })

  # Plot 2: Dataset size distribution
  tryCatch({
    p2 <- ggplot2::ggplot(manifest, ggplot2::aes(x = k)) +
      ggplot2::geom_histogram(bins = 30, fill = "darkgreen", alpha = 0.7) +
      ggplot2::theme_minimal() +
      ggplot2::labs(title = "Distribution of Dataset Sizes (k)",
                    x = "Number of Studies (k)",
                    y = "Number of Datasets") +
      ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0.5))

    ggplot2::ggsave(out_path("META_META_dataset_size_distribution.png"),
                    p2, width = 8, height = 6, dpi = 300)
    if (verbose) cat("  ✓ META_META_dataset_size_distribution.png\n")
  }, error = function(e) {
    if (verbose) cat("  ✗ Error creating dataset size distribution plot\n")
  })

  # Plot 3: Moderators per dataset
  tryCatch({
    p3 <- ggplot2::ggplot(manifest, ggplot2::aes(x = n_mods)) +
      ggplot2::geom_histogram(bins = 20, fill = "coral", alpha = 0.7) +
      ggplot2::theme_minimal() +
      ggplot2::labs(title = "Distribution of Moderators per Dataset",
                    x = "Number of Moderators",
                    y = "Number of Datasets") +
      ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0.5))

    ggplot2::ggsave(out_path("META_META_moderators_distribution.png"),
                    p3, width = 8, height = 6, dpi = 300)
    if (verbose) cat("  ✓ META_META_moderators_distribution.png\n")
  }, error = function(e) {
    if (verbose) cat("  ✗ Error creating moderators distribution plot\n")
  })

  # Plot 4: Datasets by source
  tryCatch({
    source_for_plot <- source_analysis %>% utils::head(10)

    p4 <- ggplot2::ggplot(source_for_plot,
                          ggplot2::aes(x = reorder(source, datasets), y = datasets)) +
      ggplot2::geom_bar(stat = "identity", fill = "purple", alpha = 0.7) +
      ggplot2::coord_flip() +
      ggplot2::theme_minimal() +
      ggplot2::labs(title = "Top 10 Data Sources",
                    x = "Source",
                    y = "Number of Datasets") +
      ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0.5))

    ggplot2::ggsave(out_path("META_META_datasets_by_source.png"),
                    p4, width = 8, height = 6, dpi = 300)
    if (verbose) cat("  ✓ META_META_datasets_by_source.png\n\n")
  }, error = function(e) {
    if (verbose) cat("  ✗ Error creating datasets by source plot\n\n")
  })
}
