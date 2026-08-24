# broom methods.
#
# broom is the vocabulary in which R results travel into a report: one row per
# term for tidy(), one row for the whole model for glance(), and the original
# data plus fitted quantities for augment(). Supplying them means an agriRank
# result can be piped into the same tables and plots as anything else, instead
# of needing a bespoke extraction step that the user writes and gets subtly
# wrong.
#
# Two decisions worth stating.
#
# First, the generics are registered at load time rather than declared in
# NAMESPACE. broom is in Suggests: the package must work without it, and
# S3method(tidy, agri_np_reg_fit) in NAMESPACE would make broom a hard
# dependency in all but name.
#
# Second, tidy() on a nonparametric fit does NOT invent a coefficient table.
# Most of these engines have no coefficients, and the ones that do have them for
# a basis rather than for a quantity anyone wants to report. What is tidied is
# the set of quantities the package actually stands behind: the fitted curve at
# a grid of the focal predictor, or the effects per level. A p-value column is
# deliberately absent, because there is no test here to report; use
# agri_np_optimum_test(), agri_np_significance() or the rank-based side for
# that.

.agri_tidy_np_reg <- function(x, n = 100L, conf.int = FALSE, conf.level = 0.95,
                              ...) {
  grid <- .np_prediction_grid(x, n = as.integer(n))
  px <- x$primary_predictor
  fit <- agri_np_predict(x, grid)
  if (is.matrix(fit)) fit <- fit[, 1L]
  out <- data.frame(term = px,
                    x = grid[[px]],
                    estimate = as.numeric(fit),
                    row.names = NULL, stringsAsFactors = FALSE)
  if (isTRUE(conf.int)) {
    b <- suppressWarnings(agri_np_bootstrap(x, newdata = grid, level = conf.level,
                                            ...))
    bd <- as.data.frame(b)
    out$conf.low <- bd$lower
    out$conf.high <- bd$upper
    attr(out, "interval") <- "cluster bootstrap, pointwise"
  }
  out
}

.agri_glance_np_reg <- function(x, ...) {
  d <- agri_np_diagnostics(x)
  data.frame(
    method = x$method,
    response = x$response,
    n = nrow(x$data),
    n_omitted = x$n_omitted %||% 0L,
    pseudo_r2 = d$r2$pseudo_r2,
    spearman_r2 = d$r2$spearman_r2,
    effective_df = d$r2$effective_df,
    RMSE = x$metrics$RMSE,
    MAE = x$metrics$MAE,
    block = x$block %||% NA_character_,
    spatial = x$spatial %||% "none",
    row.names = NULL, stringsAsFactors = FALSE)
}

.agri_augment_np_reg <- function(x, data = NULL, newdata = NULL, ...) {
  if (!is.null(newdata)) {
    p <- agri_np_predict(x, newdata, ...)
    if (is.matrix(p)) p <- p[, 1L]
    out <- as.data.frame(newdata)
    out$.fitted <- as.numeric(p)
    return(out)
  }
  out <- data %||% x$data
  out <- as.data.frame(out)
  if (nrow(out) != length(x$fitted))
    .agri_stop("`data` must have the rows the model was fitted to; the fit has ",
               length(x$fitted), " and this has ", nrow(out), ". The fit stores ",
               "its own rows, so calling augment() without `data` is safest.")
  out$.fitted <- x$fitted
  out$.resid <- x$residuals
  out
}

.agri_tidy_rank <- function(x, ...) {
  tab <- x$omnibus
  if (is.null(tab)) .agri_stop("This fit carries no standardized omnibus table.")
  tab <- as.data.frame(tab)
  data.frame(
    term = .agri_effect_labels(tab),
    statistic = {
      s <- intersect(c("F", "statistic", "Statistic", "F value"), names(tab))
      if (length(s)) as.numeric(tab[[s[1L]]]) else NA_real_
    },
    p.value = .agri_pvalues(tab),
    row.names = NULL, stringsAsFactors = FALSE)
}

.agri_glance_rank <- function(x, ...) {
  data.frame(
    method = x$method,
    design = x$design$design %||% NA_character_,
    response = x$design$response[1L] %||% NA_character_,
    n = nrow(x$design$data),
    n_terms = if (is.null(x$omnibus)) NA_integer_ else nrow(as.data.frame(x$omnibus)),
    row.names = NULL, stringsAsFactors = FALSE)
}

# Registration happens in .onLoad so that broom stays a suggestion.
.agri_register_broom <- function() {
  if (!requireNamespace("broom", quietly = TRUE)) return(invisible(FALSE))
  reg <- function(gen, cls, fun) {
    tryCatch(registerS3method(gen, cls, fun, envir = asNamespace("broom")),
             error = function(e) invisible(NULL))
  }
  reg("tidy", "agri_np_reg_fit", .agri_tidy_np_reg)
  reg("glance", "agri_np_reg_fit", .agri_glance_np_reg)
  reg("augment", "agri_np_reg_fit", .agri_augment_np_reg)
  reg("tidy", "agri_rank_fit", .agri_tidy_rank)
  reg("glance", "agri_rank_fit", .agri_glance_rank)
  invisible(TRUE)
}

#' Tidy an agriRank fit into a data frame
#'
#' @description
#' `tidy()`, `glance()` and `augment()` methods for `agri_np_reg_fit` and
#' `agri_rank_fit`, in the sense of the broom package, so that an agriRank
#' result travels into a report through the same vocabulary as any other model.
#' The methods are registered when broom is installed and are absent otherwise;
#' broom is a suggestion, not a dependency.
#'
#' Use [agri_tidy()], [agri_glance()] and [agri_augment()] to reach them without
#' loading broom at all.
#' @param x An `agri_np_reg_fit` or an `agri_rank_fit`.
#' @param n Grid size for the tidied curve.
#' @param conf.int Add a cluster-bootstrap interval to the tidied curve. This
#'   resamples, so it is not free.
#' @param conf.level Confidence level for that interval.
#' @param data,newdata For `agri_augment()`: the rows to attach fitted values
#'   to. Without either, the rows stored in the fit are used, which is the only
#'   choice guaranteed to align.
#' @param ... Passed to [agri_np_bootstrap()] or [agri_np_predict()].
#' @details
#' `agri_tidy()` on a regression fit returns the **fitted curve**, one row per
#' grid point, not a coefficient table. Most of the sixteen engines have no
#' coefficients, and those that do have them for a spline basis rather than for
#' any quantity worth reporting. There is no `p.value` column for the same
#' reason: no test was performed. For a test use [agri_np_optimum_test()],
#' [agri_np_significance()], or the rank-based side of the package, whose
#' `agri_tidy()` does return one row per term with a p-value.
#' @return A data frame.
#' @examples
#' data(agri_dose)
#' fit <- agri_np_regression(yield ~ dose, agri_dose, method = "smoothing_spline")
#' head(agri_tidy(fit))
#' agri_glance(fit)
#' head(agri_augment(fit))
#' @name agri_broom
NULL

#' @rdname agri_broom
#' @export
agri_tidy <- function(x, ...) {
  if (inherits(x, "agri_np_reg_fit")) return(.agri_tidy_np_reg(x, ...))
  if (inherits(x, "agri_rank_fit")) return(.agri_tidy_rank(x, ...))
  .agri_stop("agri_tidy() supports agri_np_reg_fit and agri_rank_fit objects.")
}

#' @rdname agri_broom
#' @export
agri_glance <- function(x, ...) {
  if (inherits(x, "agri_np_reg_fit")) return(.agri_glance_np_reg(x, ...))
  if (inherits(x, "agri_rank_fit")) return(.agri_glance_rank(x, ...))
  .agri_stop("agri_glance() supports agri_np_reg_fit and agri_rank_fit objects.")
}

#' @rdname agri_broom
#' @export
agri_augment <- function(x, ...) {
  if (inherits(x, "agri_np_reg_fit")) return(.agri_augment_np_reg(x, ...))
  .agri_stop("agri_augment() supports agri_np_reg_fit objects. A rank-based fit ",
             "has no per-row fitted value to attach; use agri_effects() for the ",
             "estimated effects instead.")
}
