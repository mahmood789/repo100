#' Create a standardized meta-analysis dataset object
#'
#' @param data A data.frame/tibble with columns `study_id`, `yi`, `vi`.
#' @param meta A named list with metadata (source, citation, license, tags, etc.)
#' @param id   Optional registry id
#' @param schema_version Schema version
#' @return An object of class `metadset`
#' @export
new_metadset <- function(data, meta = list(), id = NULL, schema_version = "1.0.0") {
  stopifnot(is.data.frame(data))
  req <- c("study_id","yi","vi")
  miss <- setdiff(req, names(data))
  if (length(miss)) stop("Missing required columns: ", paste(miss, collapse = ", "))
  data <- tibble::as_tibble(data)
  structure(list(data = data, meta = meta, id = id, schema_version = schema_version), class = "metadset")
}

#' Validate a metadset
#' @param x A `metadset`
#' @return The input (invisibly) if valid; otherwise errors.
#' @export
validate_metadset <- function(x) {
  stopifnot(inherits(x, "metadset"))
  req <- c("study_id","yi","vi")
  miss <- setdiff(req, names(x$data))
  if (length(miss)) stop("Invalid metadset: missing ", paste(miss, collapse = ", "))
  invisible(x)
}

#' Coerce a `metadset` to tibble
#'
#' Returns the standardized study-level data.
#'
#' @param x A `metadset`.
#' @param ... Ignored.
#' @return A tibble with at least `study_id`, `yi`, `vi`.
#' @method as_tibble metadset
#' @export
as_tibble.metadset <- function(x, ...) {
  validate_metadset(x)
  tibble::as_tibble(x$data)
}
