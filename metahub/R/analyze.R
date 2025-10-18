#' Fit a meta-analysis model using metafor
#'
#' @param x A `metadset` or data.frame with `yi`, `vi` (and optional moderators).
#' @param model Method for tau^2 (e.g., "REML").
#' @param moderators One-sided formula for moderators (e.g., `~ x1 + x2`) or NULL.
#' @param ... Passed through to [metafor::rma.uni()].
#' @return A list of class `metafit` with elements `fit` (the `rma.uni` object) and `data` (rows used).
#' @export
meta_run <- function(x, model = "REML", moderators = NULL, ...) {
  dat <- if (inherits(x, "metadset")) x$data else tibble::as_tibble(x)
  if (is.null(moderators)) {
    fit <- metafor::rma.uni(yi, vi, data = dat, method = model, ...)
    return(structure(list(fit = fit, data = dat), class = "metafit"))
  }
  mf <- stats::model.frame(moderators, dat, na.action = stats::na.pass)
  mm <- stats::model.matrix(moderators, mf, na.action = stats::na.pass)
  if (ncol(mm) > 0) mm <- mm[, -1, drop = FALSE]
  keep <- stats::complete.cases(dat$yi, dat$vi, mm)
  dat2 <- dat[keep, , drop = FALSE]
  mm2  <- if (is.null(dim(mm))) NULL else mm[keep, , drop = FALSE]
  if (!is.null(mm2) && nrow(mm2) == 0L) mm2 <- NULL
  fit <- metafor::rma.uni(yi, vi, mods = mm2, data = dat2, method = model, ...)
  structure(list(fit = fit, data = dat2), class = "metafit")
}

#' Forest plot for a meta-analysis fit
#' @param fit A `metafit` object or a `metafor::rma.uni` object.
#' @param ... Passed to [metafor::forest()].
#' @export
meta_forest <- function(fit, ...) {
  if (inherits(fit, "metafit")) fit <- fit$fit
  metafor::forest(fit, ...); invisible(fit)
}

#' Funnel plot for a meta-analysis fit
#' @param fit A `metafit` object or a `metafor::rma.uni` object.
#' @param ... Passed to [metafor::funnel()].
#' @export
meta_funnel <- function(fit, ...) {
  if (inherits(fit, "metafit")) fit <- fit$fit
  metafor::funnel(fit, ...); invisible(fit)
}

#' Leave-one-out diagnostics for a meta-analysis fit
#' @param fit A `metafit` object or a `metafor::rma.uni` object.
#' @param ... Passed to [metafor::leave1out()].
#' @export
meta_loo <- function(fit, ...) {
  if (inherits(fit, "metafit")) fit <- fit$fit
  metafor::leave1out(fit, ...)
}
