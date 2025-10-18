
`%||%` <- function(x, y) if (is.null(x)) y else x

.registry_path <- function() {
  system.file("extdata", "registry.yml", package = utils::packageName())
}

#' Load the dataset registry
#' @return List of registry records
#' @export
registry_load <- function() {
  path <- .registry_path()
  if (!nzchar(path)) stop("Registry not found in inst/extdata/registry.yml")
  yaml::read_yaml(path)
}

#' List available datasets from the registry
#' @param pattern Optional regex to filter by id or title
#' @export
list_datasets <- function(pattern = NULL) {
  reg <- registry_load()
  tib <- tibble::tibble(
    id          = vapply(reg, `[[`, "", "id"),
    title       = vapply(reg, function(x) x$title %||% NA_character_, NA_character_),
    source_type = vapply(reg, function(x) x$source$type %||% NA_character_, NA_character_),
    package     = vapply(reg, function(x) x$source$package %||% NA_character_, NA_character_),
    object      = vapply(reg, function(x) x$source$object %||% NA_character_, NA_character_)
  )
  if (!is.null(pattern)) {
    tib <- dplyr::filter(tib, grepl(pattern, id) | grepl(pattern, title))
  }
  tib
}

