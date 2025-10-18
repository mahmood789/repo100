#' Standardize raw dataset columns into (study_id, yi, vi)
#' @param df Raw data.frame
#' @param map Named list mapping raw columns to standard names.
#'   Recognized: study_id, yi, vi, sei, escalc (list of args for metafor::escalc)
#' @return Tibble with standardized columns
#' @export
standardize_columns <- function(df, map) {
  `%||%` <- function(x, y) if (is.null(x)) y else x
  stopifnot(is.list(map))
  out <- tibble::as_tibble(df)
  .ensure_study_id <- function(x) {
    if ("study_id" %in% names(x)) return(x)
    cand <- c("study","Study","trial","Trial","author","Author","id","ID","studyid","StudyID","TrialID")
    hit <- intersect(cand, names(x))
    if (length(hit)) {
      names(x)[names(x) == hit[1]] <- "study_id"
    } else {
      x$study_id <- seq_len(nrow(x))
    }
    x
  }
  rn <- c(study_id = map$study_id %||% NA_character_,
          yi       = map$yi %||% NA_character_,
          vi       = map$vi %||% NA_character_,
          sei      = map$sei %||% NA_character_)
  for (nm in names(rn)) {
    val <- rn[[nm]]
    if (!is.na(val) && val %in% names(out) && nm != val) names(out)[names(out) == val] <- nm
  }
  out <- .ensure_study_id(out)
  if (!"vi" %in% names(out) && "sei" %in% names(out)) out$vi <- out$sei^2
  if ((!all(c("yi","vi") %in% names(out))) && !is.null(map$escalc)) {
    args <- map$escalc; if (is.null(args$measure)) stop("map$escalc must include a `measure`")
    call_args <- list(measure = args$measure, data = out)
    for (nm in setdiff(names(args), "measure")) {
      col <- args[[nm]]; if (!col %in% names(out)) stop("EsCalc mapping column not found: ", nm, " -> ", col)
      call_args[[nm]] <- as.name(col)
    }
    es <- do.call(metafor::escalc, call_args)
    out$yi <- es$yi; out$vi <- es$vi
  }
  if (!all(c("yi","vi") %in% names(out))) {
    nn <- names(out)
    has_abcd <- all(c("ai","bi","ci","di") %in% nn)
    has_tcbc <- all(c("tpos","tneg","cpos","cneg") %in% nn)
    ev_t <- intersect(c("event.e","events.e","e1","tpos"), nn)
    n_t  <- intersect(c("n.e","n1","N1"), nn)
    ev_c <- intersect(c("event.c","events.c","e0","cpos"), nn)
    n_c  <- intersect(c("n.c","n0","N0"), nn)
    has_ev_tot <- (length(ev_t) == 1 && length(n_t) == 1 && length(ev_c) == 1 && length(n_c) == 1)
    if (has_tcbc) {
      out$ai <- out$tpos; out$bi <- out$tneg; out$ci <- out$cpos; out$di <- out$cneg
    } else if (has_ev_tot) {
      et <- ev_t[1]; nt <- n_t[1]; ec <- ev_c[1]; nc <- n_c[1]
      out$ai <- out[[et]]; out$bi <- out[[nt]] - out[[et]]
      out$ci <- out[[ec]]; out$di <- out[[nc]] - out[[ec]]
    }
    if (has_abcd || has_tcbc || has_ev_tot) {
      es <- metafor::escalc(measure = "RR", ai = ai, bi = bi, ci = ci, di = di, data = out)
      out$yi <- es$yi; out$vi <- es$vi
    }
  }
  req <- c("study_id","yi","vi")
  miss <- setdiff(req, names(out)); if (length(miss)) stop("Could not produce required columns: ", paste(miss, collapse = ", "))
  out
}
