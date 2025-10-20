#' Meta-regression dataset helpers
#'
#' Lightweight helpers to discover and load the curated meta-regression
#' datasets shipped with this package (CSV files in `inst/extdata/metareg/`).
#'
#' During development (without installing the package), you can point these
#' helpers at your local export folder via:
#'
#' options(metahub.metareg_dir = "metahub/inst/derived/metareg")
#' 
#' @keywords data
#' @name metareg-helpers
#' @examplesIf FALSE
#' m <- metareg_manifest()
#' head(m)
#' @examplesIf interactive()
#' m <- metareg_manifest()
#' head(m)
NULL

# internal: safe file name mapping used by the harvester
.metareg_safe_file <- function(x) gsub("[^A-Za-z0-9._-]", "_", x)

# internal: where the CSVs live; prefers dev option, else installed path
.metareg_root <- function() {
  dev <- getOption("metahub.metareg_dir")
  if (!is.null(dev) && dir.exists(dev))
    return(normalizePath(dev, winslash = "/"))
  pkg <- tryCatch(utils::packageName(), error = function(e) NULL)
  if (is.null(pkg)) pkg <- "repo100"
  p <- system.file("extdata", "metareg", package = pkg, mustWork = FALSE)
  if (!nzchar(p) || !dir.exists(p))
    stop("metareg directory not found. Install the package or set ",
         "options(metahub.metareg_dir = \"<path>\").", call. = FALSE)
  normalizePath(p, winslash = "/")
}

#' List the meta-regression manifest
#'
#' @return A data.frame with one row per dataset (id, source, k, measure, etc.).
#' @examples
#' m <- metareg_manifest()
#' head(m[, c("dataset_id","k","measure","n_mods")])
#' @export
metareg_manifest <- function() {
  root <- .metareg_root()
  man  <- file.path(root, "_manifest.csv")
  if (!file.exists(man)) stop("Manifest not found at: ", man, call. = FALSE)
  utils::read.csv(man, stringsAsFactors = FALSE)
}

#' List available dataset ids
#'
#' @return Character vector of dataset ids.
#' @examples
#' head(metareg_datasets(), 10)
#' @export
metareg_datasets <- function() {
  m <- metareg_manifest()
  unique(m$dataset_id)
}

#' Read a specific meta-regression dataset by id
#'
#' @param id Dataset id as shown in \code{metareg_manifest()}.
#' @return A data.frame with columns including \code{yi}, \code{vi}, \code{measure}
#'   and the available moderators.
#' @details
#' This function automatically handles datasets that have been split into multiple
#' parts to comply with GitHub's file size limits. If a dataset is split into
#' \code{id_part1.csv}, \code{id_part2.csv}, etc., all parts will be read and
#' combined automatically.
#'
#' @examples
#' #'   ids <- metareg_datasets()
#'   dat <- metareg_read(ids[1])
#'   str(dat)
#'
#' @export
metareg_read <- function(id) {
  stopifnot(length(id) == 1, nchar(id) > 0)
  root <- .metareg_root()
  safe_id <- .metareg_safe_file(id)
  f    <- file.path(root, paste0(safe_id, ".csv"))

  # Check if file exists as a single file
  if (file.exists(f)) {
    return(utils::read.csv(f, stringsAsFactors = FALSE))
  }

  # Check if file is split into parts (for large files > GitHub limit)
  part1 <- file.path(root, paste0(safe_id, "_part1.csv"))
  if (file.exists(part1)) {
    # Find all parts
    all_files <- list.files(root, pattern = paste0("^", gsub("([.|()\\^{}+$*?])", "\\\\\\1", safe_id), "_part[0-9]+\\.csv$"), full.names = TRUE)

    if (length(all_files) == 0) {
      stop("Dataset not found: ", id, "\nExpected file: ", f, call. = FALSE)
    }

    # Sort files by part number to ensure correct order
    part_numbers <- as.integer(sub(".*_part([0-9]+)\\.csv$", "\\1", all_files))
    all_files <- all_files[order(part_numbers)]

    # Read all parts
    parts <- lapply(all_files, function(file) utils::read.csv(file, stringsAsFactors = FALSE))

    # Combine all parts
    combined <- do.call(rbind, parts)

    return(combined)
  }

  # File not found
  stop("Dataset not found: ", id, "\nExpected file: ", f, call. = FALSE)
}
