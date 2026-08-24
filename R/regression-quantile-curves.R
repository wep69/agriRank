# Smooth quantile curves ----------------------------------------------------
#
# Every other curve in this package describes a central tendency. That is a
# strong restriction on the agronomic question it can answer.
#
# A fertilizer, a cultivar or an irrigation schedule can lift the good plots
# without lifting the poor ones. The mean response then rises, and a
# recommendation based on it will disappoint exactly the growers whose fields
# resemble the poor plots. A set of conditional quantile curves shows whether
# the whole distribution moves or only its upper part, which is the difference
# between raising yield and raising the spread of yield.
#
# Two agronomic readings follow directly from the fan:
#   - the low quantile is the exposure curve, what a grower meets in a bad year;
#   - the width between quantiles is the risk, and a treatment that widens it
#     is buying its average gain with variability.
#
# Nothing here assumes a distribution for the response. The pinball loss defines
# the quantile directly and the smoothness of each curve is chosen by the data.

#' Smooth conditional quantile curves
#'
#' @description
#' Fits one smooth curve per requested quantile of the response, and reports the
#' curves, their spread and how the spread changes along the gradient.
#'
#' @param formula Regression formula, or an `agri_np_reg_fit` whose formula,
#'   data, block and settings are reused.
#' @param data Data frame. Not needed when `formula` is a fitted object.
#' @param quantiles Quantiles to fit. Defaults to the lower decile, the
#'   quartiles, the median and the upper decile.
#' @param block Optional block variable, as in [agri_np_regression()].
#' @param block_effect `"fixed"` or `"shrunk"`, as in [agri_np_regression()].
#' @param k Basis dimension for each smooth.
#' @param n Grid size for the reported curves.
#' @param fixed Values at which other covariates are held.
#' @param gam_structure Passed to [agri_np_regression()].
#' @details
#' Each quantile is fitted independently, so the curves can in principle cross
#' where the data are thin. Crossings are counted and reported rather than
#' silently repaired, because a crossing is evidence that the requested
#' quantiles are not separately identified in that part of the gradient.
#'
#' `spread` is the distance between the outermost requested quantiles at each
#' point of the gradient, an assumption-free measure of how variable the
#' response is there. It is the quantity to read when asking whether a treatment
#' buys its average gain with variability.
#' @return An object of class `agri_np_quantile_curves`, a list with `curves`,
#'   `summary`, `spread`, `crossings` and `fits`.
#' @seealso [agri_np_regression()] with `method = "smooth_quantile"` for a
#'   single quantile, [agri_np_conformal()] for an interval covering a future
#'   plot.
#' @references
#' Fasiolo, M., Wood, S. N., Zaffran, M., Nedellec, R. and Goude, Y. (2021).
#' Fast calibrated additive quantile regression. *Journal of the American
#' Statistical Association*, 116(535), 1402-1412.
#' \doi{10.1080/01621459.2020.1725521}
#'
#' Koenker, R. (2005). *Quantile Regression*. Cambridge University Press.
#' @export
agri_np_quantile_curves <- function(formula, data = NULL,
                                    quantiles = c(0.1, 0.25, 0.5, 0.75, 0.9),
                                    block = NULL, block_effect = c("fixed", "shrunk"),
                                    k = 10L, n = 100L, fixed = list(),
                                    gam_structure = c("additive", "tensor", "varying")) {
  .require_pkg("qgam", "smooth quantile regression")
  block_effect <- match.arg(block_effect)
  gam_structure <- match.arg(gam_structure)

  if (inherits(formula, "agri_np_reg_fit")) {
    o <- formula
    data <- o$data
    block_nm <- o$block
    block_effect <- o$block_effect %||% o$settings$block_effect %||% block_effect
    gam_structure <- o$settings$gam_structure %||% gam_structure
    k <- o$settings$k %||% k
    formula <- o$formula
  } else {
    bexpr <- substitute(block)
    bval <- tryCatch(block, error = function(e) NULL)
    block_nm <- if (identical(bexpr, quote(NULL))) NULL
                else if (is.character(bval)) bval
                else .capture_names(bexpr, names(data))
  }
  if (is.null(data)) .agri_stop("`data` is required.")
  if (!is.data.frame(data)) data <- as.data.frame(data)

  quantiles <- sort(unique(as.numeric(quantiles)))
  if (!length(quantiles) || any(!is.finite(quantiles)) ||
      any(quantiles <= 0) || any(quantiles >= 1))
    .agri_stop("`quantiles` must lie strictly between 0 and 1.")
  if (length(quantiles) < 2L)
    .agri_stop("At least two quantiles are needed for a fan. For one quantile ",
               "use `agri_np_regression(method = \"smooth_quantile\", tau = )`.")

  # A quantile far into a tail is not estimable from a small experiment. The
  # curve borrows strength along the gradient, so the tail count is not the
  # whole story, but below a handful of observations it is decisive. Refuse at
  # three, warn up to ten, and say what the number means either way.
  nmin <- min(quantiles * nrow(data), (1 - quantiles) * nrow(data))
  if (nmin < 3)
    .agri_stop("The most extreme quantile requested leaves about ",
               format(round(nmin, 1)), " observations in its tail across ",
               nrow(data), " plots, so the curve would be determined by two or ",
               "three values. Ask for less extreme quantiles or replicate ",
               "further.")
  if (nmin < 10)
    .agri_warn("The most extreme quantile leaves about ", format(round(nmin, 1)),
               " observations in its tail across ", nrow(data), " plots. The ",
               "smooth borrows strength along the gradient, so the fit is not ",
               "driven by those observations alone, but read that curve as ",
               "indicative rather than as an estimate to quote.")

  fits <- lapply(quantiles, function(q)
    agri_np_regression(formula, data, method = "smooth_quantile", tau = q,
                       block = block_nm, block_effect = block_effect,
                       k = k, gam_structure = gam_structure, na_action = "fail"))
  names(fits) <- format(quantiles)

  predictor <- fits[[1L]]$primary_predictor
  grid <- .np_prediction_grid(fits[[1L]], n = n, fixed = fixed)

  curves <- do.call(rbind, lapply(seq_along(fits), function(i) {
    p <- agri_np_predict(fits[[i]], grid)
    if (is.matrix(p)) p <- p[, 1L]
    cbind(grid, quantile = quantiles[i], fit = as.numeric(p))
  }))
  rownames(curves) <- NULL

  m <- matrix(curves$fit, nrow = nrow(grid), ncol = length(quantiles))
  # Independently fitted quantiles may cross where the data are thin. Count the
  # crossings instead of reordering them, so the reader sees the evidence.
  cross <- rowSums(t(apply(m, 1L, diff)) < 0)
  crossings <- data.frame(
    n_grid = nrow(grid),
    n_crossing = sum(cross > 0),
    share = mean(cross > 0),
    row.names = NULL
  )

  spread <- data.frame(
    x = grid[[predictor]],
    lower = m[, 1L],
    upper = m[, ncol(m)],
    spread = m[, ncol(m)] - m[, 1L],
    row.names = NULL
  )
  names(spread)[1L] <- predictor

  y <- data[[fits[[1L]]$response]]
  smry <- data.frame(
    quantile = quantiles,
    fitted_min = apply(m, 2L, min),
    fitted_max = apply(m, 2L, max),
    range = apply(m, 2L, function(v) diff(range(v))),
    coverage = vapply(seq_along(quantiles), function(i) {
      p <- agri_np_predict(fits[[i]], data)
      if (is.matrix(p)) p <- p[, 1L]
      mean(y <= as.numeric(p), na.rm = TRUE)
    }, numeric(1)),
    row.names = NULL
  )
  # The share of plots below a fitted quantile curve should sit near the
  # quantile itself. It is computed on the fitting data, so it is optimistic,
  # which makes a large gap all the more telling: the curve is not tracking that
  # part of the distribution at all.
  smry$deviation <- smry$coverage - smry$quantile
  smry$tracking <- abs(smry$deviation) <= 0.1

  structure(
    list(curves = curves, summary = smry, spread = spread,
         crossings = crossings, fits = fits),
    quantiles = quantiles, predictor = predictor,
    response = fits[[1L]]$response, block = block_nm,
    block_effect = block_effect, n = nrow(data),
    class = "agri_np_quantile_curves"
  )
}

#' @export
print.agri_np_quantile_curves <- function(x, ...) {
  cat("Smooth conditional quantiles of ", attr(x, "response"),
      " over ", attr(x, "predictor"), "\n", sep = "")
  cat("  Quantiles: ", paste(format(attr(x, "quantiles")), collapse = ", "),
      "   n = ", attr(x, "n"), sep = "")
  if (!is.null(attr(x, "block")))
    cat("   block = `", attr(x, "block"), "` (", attr(x, "block_effect"), ")",
        sep = "")
  cat("\n\n")
  print(x$summary, row.names = FALSE, digits = 4)
  cat("\n`coverage` is the share of observed plots at or below each fitted\n",
      "curve. It should sit near the quantile itself, and `deviation` is the\n",
      "gap. This is measured on the fitting data, so it is optimistic.\n",
      sep = "")
  if (any(!x$summary$tracking)) {
    bad <- x$summary$quantile[!x$summary$tracking]
    cat("\nQuantile(s) ", paste(format(bad), collapse = ", "),
        " are off by more than 0.1 even on the data they were fitted to.\n",
        "That is not a tail this experiment can resolve. Report the quantiles\n",
        "that track, or replicate further.\n", sep = "")
  }

  s <- x$spread
  cat("\nSpread between the outer quantiles: ",
      format(round(min(s$spread), 3)), " to ", format(round(max(s$spread), 3)),
      ", widest at ", attr(x, "predictor"), " = ",
      format(s[[1L]][which.max(s$spread)], digits = 4), "\n", sep = "")

  if (x$crossings$n_crossing > 0)
    cat("\nThe curves cross at ", format(round(100 * x$crossings$share, 1)),
        "% of the grid. Quantiles are fitted independently, so a crossing is\n",
        "evidence that they are not separately identified there, not a bug.\n",
        sep = "")
  invisible(x)
}

#' @export
plot.agri_np_quantile_curves <- function(x, type = c("fan", "spread"), ...) {
  .require_pkg("ggplot2", "regression graphics")
  type <- match.arg(type)
  px <- attr(x, "predictor"); py <- attr(x, "response")

  if (identical(type, "spread")) {
    d <- data.frame(x = x$spread[[px]], y = x$spread$spread)
    return(
      ggplot2::ggplot(d, ggplot2::aes(x = x, y = y)) +
        ggplot2::geom_line(linewidth = 0.9) +
        ggplot2::labs(x = px,
                      y = paste0("Spread between the outer quantiles (", py, ")"),
                      title = "How variable the response is along the gradient",
                      caption = "A treatment that widens this curve buys its average gain with variability.") +
        .agri_theme_or_minimal())
  }

  d <- data.frame(x = x$curves[[px]], y = x$curves$fit,
                  g = factor(format(x$curves$quantile),
                             levels = format(attr(x, "quantiles"))))
  obs <- x$fits[[1L]]$data
  po <- data.frame(x = obs[[px]], y = obs[[py]])
  ggplot2::ggplot(d, ggplot2::aes(x = x, y = y, colour = g)) +
    ggplot2::geom_point(data = po, ggplot2::aes(x = x, y = y),
                        inherit.aes = FALSE, alpha = 0.35, size = 1.5) +
    ggplot2::geom_line(linewidth = 0.9) +
    ggplot2::scale_colour_viridis_d(option = "D", end = 0.9) +
    ggplot2::labs(x = px, y = py, colour = "Quantile",
                  title = "Smooth conditional quantiles",
                  caption = "Curves that fan out mean the treatment changes the spread, not only the level.") +
    .agri_theme_or_minimal()
}
