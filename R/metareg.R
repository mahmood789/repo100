#' Meta-regression dataset helpers
#'
#' Lightweight helpers to discover and load the curated meta-regression
#' datasets shipped with this package (CSV files in `inst/extdata/metareg/`).
#'
#' During development (without installing the package), you can point these
#' helpers at your local export folder via:
#'
#' \dontrun{options(metahub.metareg_dir = "metahub/inst/derived/metareg")}
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
#' @examples
#' \dontrun{
#'   ids <- metareg_datasets()
#'   dat <- metareg_read(ids[1])
#'   str(dat)
#' }
#' @export
metareg_read <- function(id) {
  stopifnot(length(id) == 1, nchar(id) > 0)
  root <- .metareg_root()
  f    <- file.path(root, paste0(.metareg_safe_file(id), ".csv"))
  if (!file.exists(f)) stop("Dataset not found: ", id, "\nExpected file: ", f, call. = FALSE)
  utils::read.csv(f, stringsAsFactors = FALSE)
}
