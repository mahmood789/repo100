#' Get a dataset from common meta-analysis packages
#' 
#' @param name Dataset object name (e.g., "dat.bcg").
#' @param package One of c("metadat","metafor","meta","dmetar").
#' @return The dataset object.
#' @export
get_dataset <- function(name, package = c("metadat","metafor","meta","dmetar")) {
  package <- match.arg(package)
  env <- new.env(parent = emptyenv())
  ok <- suppressWarnings(utils::data(list = name, package = package, envir = env))
  obj <- get0(name, envir = env, inherits = FALSE)
  if (length(ok) == 0L || is.null(obj)) {
    stop(sprintf("Dataset %s not found in package %s", name, package), call. = FALSE)
  }
  obj
}

#' List datasets from external meta-analysis packages
#' 
#' Note: Your package already has `list_datasets()`. This helper uses a
#' different name to avoid clashes.
#' 
#' @param packages Character vector of packages to scan.
#' @return Data frame with columns Package, Item, Title.
#' @export
list_external_datasets <- function(packages = c("metadat","metafor","meta","dmetar")) {
  out <- lapply(packages, function(p) {
    if (!requireNamespace(p, quietly = TRUE)) return(NULL)
    as.data.frame(utils::data(package = p)$results, stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, Filter(Negate(is.null), out))
  if (is.null(out)) return(data.frame(Package=character(), Item=character(), Title=character()))
  out[, c("Package","Item","Title")]
}

#' Load a dataset using the `id` column from `metahub::list_datasets()`
#' 
#' E.g., id = "metadat_dat.bcg" -> package "metadat", object "dat.bcg".
#' 
#' @param id A single id string from metahub::list_datasets()$id
#' @return The dataset object.
#' @export
load_dataset_by_id <- function(id) {
  stopifnot(length(id) == 1L, is.character(id))
  pkg <- sub("^([^_]+)_.*$", "\\1", id)
  obj <- sub("^[^_]+_", "", id)
  get_dataset(obj, package = pkg)
}

