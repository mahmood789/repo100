## metahub/R/list_datasets.R
#' List datasets known to metahub
#' @return data.frame with columns: id, package, object, title
#' @export
list_datasets <- function() {
  # prefer packaged CSV (works under devtools::load_all and installed pkg)
  p <- system.file("extdata", "datasets_index.csv", package = "metahub")
  if (nzchar(p) && file.exists(p)) {
    df <- tryCatch(read.csv(p, stringsAsFactors = FALSE), error = function(e) NULL)
    if (!is.null(df)) return(df)
  }
  # fallback: scan external packages if CSV not present
  if (!exists("list_external_datasets", mode = "function")) {
    stop("No datasets_index.csv found and list_external_datasets() is unavailable.")
  }
  list_external_datasets(c("metadat","metafor","meta","dmetar"))
}

