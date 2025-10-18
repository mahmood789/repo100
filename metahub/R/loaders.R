
#' Load a dataset by registry id
#' @param id Registry identifier (e.g., "metadat_dat.bcg")
#' @return A `metadset` with standardized columns
#' @export
load_dataset <- function(id) {
  reg <- registry_load()
  hits <- Filter(function(x) identical(x$id, id), reg)
  if (!length(hits)) stop("Registry id not found: ", id)
  rec <- hits[[1]]
  src <- rec$source

  if (identical(src$type, "CRAN")) {
    # Try namespace first
    df <- NULL
    if (requireNamespace(src$package, quietly = TRUE)) {
      if (exists(src$object, envir = asNamespace(src$package), inherits = FALSE)) {
        obj <- get(src$object, envir = asNamespace(src$package))
        df  <- if (is.function(obj)) obj() else obj
      }
    } else {
      stop("Package not installed: ", src$package)
    }
    # Fallback to data() for data-only objects (common in {metadat})
    if (is.null(df)) {
      e <- new.env(parent = emptyenv())
      utils::data(list = src$object, package = src$package, envir = e)
      if (!exists(src$object, envir = e))
        stop("Object not found in package data(): ", src$package, "::", src$object)
      df <- get(src$object, envir = e)
      if (is.function(df)) df <- df()
    }
  } else if (identical(src$type, "local")) {
    path <- src$path
    if (!file.exists(path)) stop("Local source not found: ", path)
    ext <- tolower(tools::file_ext(path))
    if (ext %in% c("csv","tsv")) {
      delim <- if (ext == "csv") "," else "\t"
      df <- readr::read_delim(path, delim = delim, show_col_types = FALSE)
    } else if (ext == "rds") {
      df <- readRDS(path)
    } else stop("Unsupported local file extension: ", ext)
  } else {
    stop("Unsupported source type: ", src$type)
  }

  std  <- standardize_columns(df, rec$map)
  meta <- rec
  new_metadset(std, meta = meta, id = id)
}
