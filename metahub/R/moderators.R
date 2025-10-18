
#' Candidate moderator columns in a standardized meta-analysis dataset
#'
#' Excludes core columns and effect-size ingredients; keeps variables that vary
#' (>= 2 unique non-NA values).
#' @param x A `metadset` or data.frame (already standardized)
#' @return Character vector of moderator column names (can be empty)
#' @export
suggest_moderators <- function(x) {
  dat <- if (inherits(x, "metadset")) x$data else tibble::as_tibble(x)
  bad <- c("study_id","yi","vi","sei","ai","bi","ci","di",
           "tpos","tneg","cpos","cneg","m1i","m2i","sd1i","sd2i",
           "n1i","n2i","event.e","event.c","events.e","events.c",
           "n.e","n.c","e1","e0","N1","N0","ntreat","nctrl",
           "total_treat","total_ctrl")
  keep <- setdiff(names(dat), intersect(bad, names(dat)))
  ok <- keep[vapply(dat[keep], function(col) {
    u <- unique(col[!is.na(col)]); length(u) >= 2
  }, logical(1))]
  ok
}

#' List datasets in the registry that support meta-regression
#'
#' Tries loading each dataset, then counts candidate moderators.
#' @param min_mods Minimum number of moderator columns (default 1)
#' @param min_k    Minimum number of studies (default 5)
#' @param real_only Drop simulated/toy/example-ish by id/title (default TRUE)
#' @param pattern   Optional regex on id/title to pre-filter registry
#' @return tibble with id, title, k, n_mods, and a short mods preview
#' @export
list_metareg_datasets <- function(min_mods = 1, min_k = 5, real_only = TRUE, pattern = NULL) {
  reg <- registry_load()
  df  <- tibble::tibble(
    id    = vapply(reg, `[[`, "", "id"),
    title = vapply(reg, function(x) x$title %||% NA_character_, NA_character_)
  )
  if (!is.null(pattern)) {
    df <- dplyr::filter(df, grepl(pattern, id) | grepl(pattern, title))
  }
  if (real_only) {
    drop_rx <- "(sim|simulation|toy|example|illustrat|demo|synt(h|etic))"
    keep <- !(grepl(drop_rx, df$id, ignore.case = TRUE) |
              grepl(drop_rx, df$title, ignore.case = TRUE))
    df <- df[keep, , drop = FALSE]
  }

  res <- lapply(seq_len(nrow(df)), function(i) {
    rid <- df$id[i]; ttl <- df$title[i]
    obj <- try(load_dataset(rid), silent = TRUE)
    if (inherits(obj, "try-error")) {
      return(tibble::tibble(id = rid, title = ttl, k = NA_integer_, n_mods = NA_integer_, mods = NA_character_))
    }
    dat  <- obj$data
    k    <- nrow(dat)
    mods <- suggest_moderators(obj)
    tibble::tibble(
      id = rid, title = ttl, k = k,
      n_mods = length(mods),
      mods = if (length(mods)) paste(utils::head(mods, 8), collapse = ", ") else NA_character_
    )
  })

  out <- dplyr::bind_rows(res)
  dplyr::arrange(dplyr::filter(out, !is.na(n_mods), k >= min_k, n_mods >= min_mods),
                 dplyr::desc(n_mods), dplyr::desc(k))
}

#' Prune the on-disk registry to *only* datasets that support meta-regression
#'
#' Writes a timestamped backup then overwrites inst/extdata/registry.yml.
#' Works from a dev tree or an installed package.
#' @inheritParams list_metareg_datasets
#' @export
prune_registry_to_metareg_only <- function(min_mods = 1, min_k = 5, real_only = TRUE, pattern = NULL) {
  # prefer dev tree
  dev_reg <- file.path(getwd(), "metahub", "inst", "extdata", "registry.yml")
  src_reg <- if (file.exists(dev_reg)) dev_reg else {
    p <- system.file("extdata", "registry.yml", package = "metahub")
    if (!nzchar(p)) stop("registry.yml not found in inst/extdata")
    p
  }

  keep_tbl <- list_metareg_datasets(min_mods = min_mods, min_k = min_k, real_only = real_only, pattern = pattern)
  keep_ids <- keep_tbl$id
  if (!length(keep_ids)) stop("No datasets met the criteria. Will not modify registry.")

  reg <- yaml::read_yaml(src_reg)
  reg <- Filter(function(x) x$id %in% keep_ids, reg)

  bak <- paste0(src_reg, ".", format(Sys.time(), "%Y%m%d_%H%M%S"), ".bak")
  file.copy(src_reg, bak, overwrite = TRUE)
  yaml::write_yaml(reg, src_reg)
  message("Pruned registry to ", length(reg), " datasets. Backup at: ", bak)
}

