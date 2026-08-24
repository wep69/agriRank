# Split conformal prediction, block aware --------------------------------------
#
# The bootstrap bands of agri_np_bootstrap() describe where the fitted *curve*
# lies. They say nothing, with guarantee, about where the *next plot* will fall.
# Split conformal prediction does: for exchangeable data it returns an interval
# with finite-sample marginal coverage P(Y in interval) >= 1 - alpha, with no
# distributional assumption and no assumption about the fitted engine.
#
# The catch, and the reason this belongs in agriRank rather than in a generic
# package, is exchangeability. Plots in different blocks are not exchangeable:
# that is precisely what declaring a block asserts. So the calibration split is
# taken over whole blocks, never over individual plots, and the guarantee is
# stated at the level at which the randomization actually holds.

# Linear interpolation of a de-duplicated smooth onto arbitrary predictor
# values, clamped at the ends. Kept separate so that both the calibration and
# the prediction side use exactly the same rule.
.conformal_interp <- function(sm, xout) {
  if (length(sm$x) < 2L) return(rep(sm$y[1L], length(xout)))
  stats::approx(sm$x, sm$y, xout = xout, rule = 2)$y
}

# Two scopes, two scientific questions.
#
# "within_block": the future plot belongs to a block that was observed.
#   Randomization happened inside blocks, so plots within a block are
#   exchangeable. The split is stratified, every block contributes to both
#   parts, and the block term stays in the model.
#
# "new_block": the future plot belongs to a block, field or year that was not
#   observed. Exchangeability is then claimed at the block level, whole blocks
#   are held out, and the block term must leave the model, because a
#   block-specific effect is not estimable outside the observed blocks. The
#   resulting interval is wider, and it should be: it now carries the
#   between-block variation as well.
.conformal_split <- function(n, groups = NULL, prop = 0.5, seed = 1,
                             scope = "within_block") {
  .seed_eval(seed, {
    if (is.null(groups)) {
      idx <- sample.int(n)
      n_fit <- max(2L, floor(prop * n))
      return(list(fit = idx[seq_len(n_fit)], cal = idx[-seq_len(n_fit)]))
    }
    g <- as.character(groups)
    lev <- unique(g)
    if (identical(scope, "new_block")) {
      if (length(lev) < 3L)
        .agri_stop("Holding out whole blocks needs at least three blocks. With fewer, use scope = \"within_block\", which states that the future plot belongs to an observed block.")
      k <- max(1L, floor(prop * length(lev)))
      k <- min(k, length(lev) - 1L)
      sel <- sample(lev, k)
      return(list(fit = which(g %in% sel), cal = which(!g %in% sel),
                  blocks_fit = sel))
    }
    # Stratified split inside each block.
    fit <- integer(0)
    for (l in lev) {
      i <- which(g == l)
      if (length(i) < 2L) { fit <- c(fit, i); next }
      k <- max(1L, floor(prop * length(i)))
      k <- min(k, length(i) - 1L)
      fit <- c(fit, sample(i, k))
    }
    list(fit = fit, cal = setdiff(seq_len(n), fit))
  })
}

#' Distribution-free prediction intervals by split conformal inference
#'
#' @description
#' Returns prediction intervals with finite-sample marginal coverage that does
#' not depend on the response distribution nor on the regression engine. The
#' calibration split respects the declared block, so the guarantee is stated at
#' the level at which exchangeability actually holds.
#'
#' @param object An `agri_np_reg_fit`.
#' @param newdata Prediction data. Defaults to a grid over the observed range.
#' @param level Target coverage.
#' @param split_by Variable defining exchangeable groups for the calibration
#'   split. Defaults to the block declared in the fit. Use `NULL` only when
#'   individual observations are genuinely exchangeable.
#' @param prop Share of groups, or of rows, used to refit the model. The rest
#'   calibrates.
#' @param seed Random seed for the split.
#' @param n Grid size when `newdata` is omitted.
#' @param fixed Values at which other covariates are held.
#' @param normalize If `TRUE`, residuals are scaled by a local dispersion
#'   estimate, which widens the interval where the response is noisier and
#'   narrows it where it is quiet. Coverage remains marginal either way.
#' @details
#' The procedure refits the engine on one part of the data, computes absolute
#' residuals on the held-out part, takes the appropriate empirical quantile of
#' those residuals, and adds it to the prediction. The quantile uses the
#' finite-sample correction \eqn{\lceil (n_{cal}+1)(1-\alpha) \rceil / n_{cal}},
#' which is what turns an empirical quantile into a coverage guarantee.
#'
#' Two properties matter agronomically. The interval covers a **future plot**,
#' not the fitted curve, so it is the object to quote when recommending a rate.
#' And the guarantee is marginal, that is, averaged over the gradient: it does
#' not promise the stated coverage separately at every nitrogen rate. Setting
#' `normalize = TRUE` distributes the width more sensibly across the gradient
#' without changing what is guaranteed.
#'
#' Compare with `agri_np_bootstrap()`, which describes uncertainty of the fitted
#' curve, and with the analytic interval of `agri_np_predict()`, which relies on
#' the asymptotic theory of the engine.
#' @return A data frame with the prediction grid, the point prediction and the
#'   conformal limits, of class `agri_np_conformal`.
#' @references
#' Vovk, V., Gammerman, A. and Shafer, G. (2005). \emph{Algorithmic Learning in
#' a Random World}. Springer.
#'
#' Lei, J., G'Sell, M., Rinaldo, A., Tibshirani, R. J. and Wasserman, L. (2018).
#' Distribution-free predictive inference for regression. \emph{Journal of the
#' American Statistical Association}, 113(523), 1094-1111.
#' \doi{10.1080/01621459.2017.1307116}
#' @export
agri_np_conformal <- function(object, newdata = NULL, level = 0.95,
                              split_by = NULL, scope = c("within_block", "new_block"),
                              prop = 0.5, seed = 1,
                              n = 100L, fixed = list(), normalize = FALSE) {
  if (!inherits(object, "agri_np_reg_fit")) .agri_stop("`object` must be an agri_np_reg_fit.")
  scope <- match.arg(scope)
  if (!is.finite(level) || level <= 0 || level >= 1)
    .agri_stop("`level` must lie strictly between 0 and 1.")
  d <- object$data
  # The declared block is the default exchangeable unit. Passing NULL is an
  # explicit statement that plots are exchangeable, which is a scientific claim.
  by <- if (missing(split_by)) (object$block %||% NULL) else split_by
  groups <- if (is.null(by)) NULL else {
    if (!by %in% names(d)) .agri_stop("Unknown grouping variable `", by, "` for the conformal split.")
    d[[by]]
  }
  # Predicting into an unobserved block requires a model without a
  # block-specific term, because that effect is not estimable there.
  block_in_model <- if (identical(scope, "new_block")) NULL else object$block
  if (identical(scope, "new_block") && !is.null(object$block)) {
    object <- tryCatch(
      agri_np_regression(object$formula, d, method = object$method, tau = object$tau,
                         family = object$family, shape = object$shape, block = NULL,
                         na_action = "fail", span = object$settings$span,
                         degree = object$settings$degree, k = object$settings$k,
                         gam_structure = object$settings$gam_structure %||% "additive",
                         kernel_regtype = object$settings$kernel_regtype %||% "ll",
                         bwmethod = object$settings$bwmethod),
      error = function(e) NULL)
    if (is.null(object))
      .agri_stop("The engine could not be refitted without the block term, which scope = \"new_block\" requires. Use scope = \"within_block\" or an engine that fits without a block.")
  }
  sp <- .conformal_split(nrow(d), groups = groups, prop = prop, seed = seed, scope = scope)
  if (length(sp$cal) < 5L)
    .agri_stop("The calibration part has fewer than five observations. Reduce `prop` or supply more blocks.")

  refit <- tryCatch(
    agri_np_regression(object$formula, d[sp$fit, , drop = FALSE],
                       method = object$method, tau = object$tau,
                       family = object$family, shape = object$shape,
                       block = block_in_model, na_action = "fail",
                       span = object$settings$span, degree = object$settings$degree,
                       k = object$settings$k,
                       gam_structure = object$settings$gam_structure, block_effect = object$settings$block_effect %||% "fixed" %||% "additive",
                       kernel_regtype = object$settings$kernel_regtype %||% "ll",
                       bwmethod = object$settings$bwmethod,
                       predictor_support = if (!is.null(object$integer_support)) "custom_integer" else "continuous",
                       integer_predictor = object$integer_predictor,
                       integer_values = object$integer_support,
                       integer_base_method = object$base_method %||% "gam"),
    error = function(e) NULL)
  if (is.null(refit))
    .agri_stop("The engine could not be refitted on the calibration split. A smaller `prop` or a simpler engine may be required.")

  .num <- function(z) {
    if (is.matrix(z)) z <- z[, 1L]
    if (is.data.frame(z)) z <- z[[intersect(c("fit", "fitted"), names(z))[1L]]]
    as.numeric(z)
  }
  cal <- d[sp$cal, , drop = FALSE]
  res <- abs(cal[[object$response]] - .num(agri_np_predict(refit, cal)))

  scale_cal <- rep(1, length(res)); scale_new <- NULL
  if (isTRUE(normalize)) {
    # Local dispersion from the calibration residuals themselves, smoothed
    # against the focal predictor. Keeps the method engine-agnostic.
    px <- object$primary_predictor
    if (!is.null(px) && is.numeric(cal[[px]])) {
      sm <- tryCatch(suppressWarnings(stats::lowess(cal[[px]], res, f = 0.6)),
                     error = function(e) NULL)
      if (!is.null(sm)) {
        # lowess repeats tied predictor values; collapse them so that the
        # interpolation below is well defined and silent.
        keep <- !duplicated(sm$x)
        sm <- list(x = sm$x[keep], y = sm$y[keep])
        scale_cal <- .conformal_interp(sm, cal[[px]])
        scale_cal[!is.finite(scale_cal) | scale_cal <= 0] <- stats::median(res[res > 0], na.rm = TRUE)
        attr(scale_cal, "sm") <- sm
      }
    }
  }
  score <- res / scale_cal
  score <- score[is.finite(score)]
  n_cal <- length(score)
  # Finite-sample correction: this is what makes the quantile a guarantee.
  q_index <- ceiling((n_cal + 1) * level) / n_cal
  qhat <- if (q_index > 1) Inf else stats::quantile(score, probs = q_index, names = FALSE, type = 1)

  if (is.null(newdata))
    newdata <- .np_prediction_grid(object, n = n, fixed = fixed)
  pred <- .num(agri_np_predict(object, newdata))
  if (isTRUE(normalize) && !is.null(attr(scale_cal, "sm"))) {
    sm <- attr(scale_cal, "sm")
    scale_new <- .conformal_interp(sm, newdata[[object$primary_predictor]])
    scale_new[!is.finite(scale_new) | scale_new <= 0] <- stats::median(res[res > 0], na.rm = TRUE)
  }
  if (is.null(scale_new)) scale_new <- rep(1, length(pred))

  out <- cbind(newdata,
               fit = pred,
               lower = pred - qhat * scale_new,
               upper = pred + qhat * scale_new)
  attr(out, "level") <- level
  attr(out, "split_by") <- by
  attr(out, "scope") <- scope
  attr(out, "n_fit") <- length(sp$fit)
  attr(out, "n_calibration") <- n_cal
  attr(out, "blocks_fit") <- sp$blocks_fit
  attr(out, "quantile") <- qhat
  attr(out, "normalized") <- isTRUE(normalize)
  attr(out, "predictor") <- object$primary_predictor
  attr(out, "response") <- object$response
  class(out) <- c("agri_np_conformal", class(out))
  out
}

#' @export
print.agri_np_conformal <- function(x, ...) {
  cat("agriRank split-conformal prediction intervals\n")
  cat("  Target coverage:", sprintf("%.0f%%", 100 * attr(x, "level")), "\n")
  cat("  Split unit:", attr(x, "split_by") %||% "individual observations", "\n")
  cat("  Scope:", switch(attr(x, "scope") %||% "within_block",
                         within_block = "a future plot in an observed block",
                         new_block = "a future plot in a block that was not observed"), "\n")
  cat("  Fitting rows:", attr(x, "n_fit"),
      " Calibration rows:", attr(x, "n_calibration"), "\n")
  cat("  Conformal quantile:", format(attr(x, "quantile"), digits = 4),
      if (isTRUE(attr(x, "normalized"))) "(locally scaled)" else "", "\n\n")
  print(utils::head(as.data.frame(x)), row.names = FALSE, digits = 4)
  if (nrow(x) > 6L) cat("  ... ", nrow(x) - 6L, "more rows\n")
  cat("\nThe interval covers a future plot, not the fitted curve, and the coverage\nis marginal over the gradient rather than guaranteed at each single rate.\n")
  invisible(x)
}

#' @export
plot.agri_np_conformal <- function(x, ...) {
  .require_pkg("ggplot2", "regression graphics")
  d <- as.data.frame(x)
  xv <- attr(x, "predictor") %||% names(d)[1L]
  d$.x <- d[[xv]]
  ggplot2::ggplot(d, ggplot2::aes(x = .x, y = fit)) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = lower, ymax = upper), alpha = 0.18) +
    ggplot2::geom_line(linewidth = 0.7) +
    ggplot2::labs(x = xv, y = attr(x, "response") %||% "Predicted response",
                  subtitle = sprintf("%.0f%% split-conformal interval for a future plot, split by %s",
                                     100 * attr(x, "level"),
                                     attr(x, "split_by") %||% "observation"),
                  caption = "Distribution-free and finite-sample. Coverage is marginal over the gradient.") +
    .agri_theme_or_minimal()
}

#' Empirical coverage of a prediction interval
#'
#' @description
#' Checks how often observed responses fall inside an interval, overall and by
#' block. A method that promises 95% coverage should be held to it.
#' @param object An `agri_np_conformal` object, or an `agri_np_reg_fit` for
#'   which the intervals are computed on the observed data.
#' @param data Data with observed responses. Defaults to the fitting data.
#' @param ... Passed to `agri_np_conformal()` when a fit is supplied.
#' @details
#' On the fitting data this is optimistic, because those rows helped build the
#' interval. Its purpose is teaching and diagnosis, not validation. For an
#' honest figure use the calibration study in `inst/calibration`.
#' @return A list with the overall empirical coverage, coverage by block, and
#'   the mean interval width.
#' @export
agri_np_coverage <- function(object, data = NULL, ...) {
  cf <- if (inherits(object, "agri_np_conformal")) object else NULL
  fit <- if (inherits(object, "agri_np_reg_fit")) object else NULL
  if (is.null(cf) && is.null(fit))
    .agri_stop("`object` must be an agri_np_conformal result or an agri_np_reg_fit.")
  if (is.null(fit) && is.null(data))
    .agri_stop("Supply `data` with observed responses when passing a conformal table.")
  if (is.null(cf)) {
    data <- data %||% fit$data
    cf <- agri_np_conformal(fit, newdata = data, ...)
  }
  resp <- attr(cf, "response")
  data <- data %||% fit$data
  if (!resp %in% names(data)) .agri_stop("The response `", resp, "` is not present in `data`.")
  d <- as.data.frame(cf)
  y <- data[[resp]]
  if (length(y) != nrow(d))
    .agri_stop("The conformal table and `data` must refer to the same rows. Pass `newdata = data` when building the intervals.")
  inside <- y >= d$lower & y <= d$upper
  by <- attr(cf, "split_by")
  by_block <- if (!is.null(by) && by %in% names(data)) {
    z <- stats::aggregate(list(coverage = inside), by = list(block = data[[by]]), FUN = mean)
    z$n <- as.numeric(table(data[[by]])[as.character(z$block)])
    z
  } else NULL
  list(target = attr(cf, "level"),
       empirical = mean(inside, na.rm = TRUE),
       mean_width = mean(d$upper - d$lower, na.rm = TRUE),
       by_block = by_block,
       n = sum(is.finite(inside)))
}
