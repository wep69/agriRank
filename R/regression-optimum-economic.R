# Economic optimum of a fitted response curve.
#
# agri_np_optimum() returns the top of the curve. That is the agronomic
# optimum, and it is almost never the rate a grower should apply, because the
# last increments of input buy less produce than they cost. The economic
# optimum is where the marginal physical product, valued at the price of the
# produce, equals the price of the input:
#
#     dy/dx = price_input / price_output = r
#
# It always lies below the agronomic optimum on a concave curve, and the gap
# between the two is frequently the whole margin of the field. Everything the
# calculation needs already existed in the package: the derivative, and the
# cluster bootstrap of a location rather than of a height. This function joins
# them.
#
# The estimand is the location of a root, not the height of a curve, so it
# inherits the difficulty documented in agri_np_optimum_test(): a plateau makes
# the root wander even when the curve is well estimated. p_boundary and
# identified carry the same meaning here.

# Root of d(x) = r on a grid, taken at the first crossing from above, which is
# the economically meaningful one: before it, another unit of input still pays
# for itself. Linear interpolation between the two bracketing grid points keeps
# the answer from being quantised to the grid.
.econ_root <- function(x, d, r) {
  ok <- is.finite(x) & is.finite(d)
  x <- x[ok]; d <- d[ok]
  if (length(x) < 2L) return(list(x = NA_real_, boundary = NA, side = NA_character_))
  above <- d >= r
  if (all(!above))
    return(list(x = x[1L], boundary = TRUE, side = "lower"))
  if (all(above))
    return(list(x = x[length(x)], boundary = TRUE, side = "upper"))
  k <- which(above[-length(above)] & !above[-1L])[1L]
  if (is.na(k)) {
    # The derivative crosses upward but never downward inside the range: the
    # response is still accelerating at the last tested rate.
    return(list(x = x[length(x)], boundary = TRUE, side = "upper"))
  }
  x0 <- x[k]; x1 <- x[k + 1L]; d0 <- d[k]; d1 <- d[k + 1L]
  xr <- if (isTRUE(all.equal(d0, d1))) x0
        else x0 + (r - d0) * (x1 - x0) / (d1 - d0)
  list(x = xr, boundary = FALSE, side = NA_character_)
}

# Central differences of a curve evaluated on an ordered grid.
.econ_deriv <- function(x, y) {
  n <- length(x)
  if (n < 2L) return(rep(NA_real_, n))
  d <- rep(NA_real_, n)
  d[1L] <- (y[2L] - y[1L]) / (x[2L] - x[1L])
  d[n] <- (y[n] - y[n - 1L]) / (x[n] - x[n - 1L])
  if (n > 2L) {
    i <- 2:(n - 1L)
    d[i] <- (y[i + 1L] - y[i - 1L]) / (x[i + 1L] - x[i - 1L])
  }
  d
}

#' Economic optimum of a fitted response curve
#'
#' @description
#' Locates the input rate at which the marginal physical product, valued at the
#' price of the produce, equals the price of the input, and reports a
#' cluster-bootstrap interval for that location.
#'
#' [agri_np_optimum()] returns the top of the curve. That is the agronomic
#' optimum, and it is almost never the rate to apply: the last increments of
#' input buy less produce than they cost. The economic optimum always lies below
#' the agronomic one on a concave response, and the difference between them is
#' frequently the whole margin of the field.
#' @param object An `agri_np_reg_fit` from [agri_np_regression()].
#' @param price_ratio The price of one unit of input divided by the price of one
#'   unit of produce, in the units of the fitted model. If nitrogen costs 1.20
#'   currency units per kg and grain sells for 0.30 per kg, the ratio is 4, and
#'   the optimum is where the last kilogram of nitrogen returns four kilograms
#'   of grain. `price_ratio = 0` reduces to the agronomic optimum, which is a
#'   useful check rather than a recommendation.
#' @param by Optional qualitative predictor whose levels are to be compared, as
#'   a name or a string. It must already be a predictor of the fitted model, and
#'   the model must let the shape differ between levels.
#' @param B Bootstrap replicates. Use at least 999 for anything reported.
#' @param level Confidence level of the interval for the optimum.
#' @param seed Random seed.
#' @param n Grid size on which the root is located.
#' @param fixed Values at which other covariates are held.
#' @param range Optional two-element range of the predictor to search within.
#' @param cluster Resampling unit. Defaults to the declared block, which keeps
#'   whole blocks together. Pass `NA` to resample individual rows, which is only
#'   legitimate for a completely randomized layout.
#' @param adjust Multiplicity adjustment across the pairwise contrasts produced
#'   by `by`, passed to [stats::p.adjust()].
#' @details
#' The economic optimum solves \eqn{\partial y / \partial x = r}. The root is
#' taken at the first crossing from above, because up to that point another unit
#' of input still pays for itself.
#'
#' What is resampled is the **location** of that root, not the height of the
#' curve, and the two are very different quantities: a response that flattens
#' has a well estimated curve and a root that wanders over a wide stretch of the
#' gradient. `p_boundary` reports the share of replicates whose root lands on an
#' end of the searched range, and `identified` turns `FALSE` when that share
#' reaches one half, at which point there is no rate to report.
#'
#' The price ratio is treated as known. It is not: prices move, and the
#' sensitivity of the recommendation to the ratio is usually larger than its
#' statistical uncertainty. Supply a vector of ratios and read the table as a
#' sensitivity analysis, which is what `price_ratio` accepts.
#' @return An object of class `agri_np_optimum_economic`, a list with `optimum`,
#'   `contrasts`, `curve` and `replicates`.
#' @seealso [agri_np_optimum()] for the agronomic optimum,
#'   [agri_np_optimum_test()] for its interval,
#'   [agri_np_derivative()] for the marginal product itself.
#' @references
#' Cerrato, M. E. and Blackmer, A. M. (1990). Comparison of models for
#' describing corn yield response to nitrogen fertilizer. *Agronomy Journal*,
#' 82(1), 138-143.
#' @export
agri_np_optimum_economic <- function(object, price_ratio, by = NULL,
                                     B = 999L, level = 0.95, seed = 1,
                                     n = 200L, fixed = list(), range = NULL,
                                     cluster = NULL,
                                     adjust = c("holm", "none", "BH",
                                                "bonferroni", "hochberg",
                                                "hommel", "BY"),
                                     parallel = FALSE) {
  if (!inherits(object, "agri_np_reg_fit"))
    .agri_stop("`object` must be an agri_np_reg_fit.")
  adjust <- match.arg(adjust)
  if (missing(price_ratio) || !length(price_ratio) || !all(is.finite(price_ratio)))
    .agri_stop("`price_ratio` must be one or more finite numbers: the price of ",
               "a unit of input divided by the price of a unit of produce.")
  if (any(price_ratio < 0))
    .agri_stop("A negative `price_ratio` would mean the input is paid for by ",
               "using it. Check which price went in the numerator.")
  if (!is.finite(level) || level <= 0 || level >= 1)
    .agri_stop("`level` must lie strictly between 0 and 1.")
  .np_check_B(B)

  if (!is.null(object$integer_support) && length(object$integer_support))
    .agri_stop("This fit declares an integer decision support. Use ",
               "`agri_integer_threshold(criterion = \"marginal_gain\")`, which ",
               "works on the admissible integer lattice instead of a grid.")

  predictor <- object$primary_predictor
  if (is.null(predictor) || !is.numeric(object$data[[predictor]]))
    .agri_stop("An economic optimum needs a numeric focal predictor. The ",
               "fitted model has none.")

  bexpr <- substitute(by)
  bval <- tryCatch(by, error = function(e) NULL)
  by_nm <- if (identical(bexpr, quote(NULL))) NULL
           else if (is.character(bval)) bval
           else .capture_names(bexpr, names(object$data))
  if (length(by_nm) > 1L)
    .agri_stop("`by` must name a single qualitative predictor.")
  if (!is.null(by_nm) && !by_nm %in% object$predictors)
    .agri_stop("`", by_nm, "` is not a predictor of the fitted model. Refit ",
               "including it, so that the levels are compared inside one model.")

  levs <- if (is.null(by_nm)) "all"
          else if (is.factor(object$data[[by_nm]])) levels(object$data[[by_nm]])
          else levels(as.factor(object$data[[by_nm]]))
  nl <- length(levs)

  grids <- lapply(levs, function(l)
    .opt_grid_for_level(object, predictor, by_nm, l, n, fixed, range))
  sizes <- vapply(grids, nrow, integer(1))
  gall <- do.call(rbind, grids)
  idx <- split(seq_len(nrow(gall)), rep(seq_len(nl), sizes))

  cexpr <- substitute(cluster)
  cval <- tryCatch(cluster, error = function(e) NULL)
  cl <- if (identical(cexpr, quote(NULL))) object$block
        else if (length(cval) == 1L && is.na(cval)) NULL
        else if (is.character(cval)) cval
        else .capture_names(cexpr, names(object$data))

  if (nl > 1L) {
    p0 <- agri_np_predict(object, gall)
    if (is.matrix(p0)) p0 <- p0[, 1L]
    p0 <- as.numeric(p0)
    ref <- p0[idx[[1L]]]
    spans <- vapply(seq_len(nl)[-1L], function(i)
      diff(range(p0[idx[[i]]] - ref)), numeric(1))
    tol <- 1e-8 * max(1, stats::sd(object$data[[object$response]], na.rm = TRUE))
    if (all(spans <= tol))
      .agri_stop("The fitted curves for the levels of `", by_nm, "` are ",
                 "parallel, because `", by_nm, "` enters the model as an ",
                 "additive adjustment. Their marginal products are identical ",
                 "by construction, so their economic optima are too, whatever ",
                 "the price ratio. Refit with `gam_structure = \"varying\"`.")
  }

  bt <- suppressWarnings(
    agri_np_bootstrap(object, newdata = gall, B = B, level = level,
                      seed = seed, cluster = cl, keep_replicates = TRUE,
                      parallel = parallel))
  reps <- attr(bt, "replicates")
  if (is.null(reps))
    .agri_stop("The bootstrap did not return replicates, so the location of ",
               "the economic optimum cannot be resampled.")

  point <- as.numeric(as.data.frame(bt)$fit)
  xs <- lapply(seq_len(nl), function(i) gall[[predictor]][idx[[i]]])
  a <- (1 - level) / 2

  rows <- list(); contr <- list()
  for (r in price_ratio) {
    # One row per level, one column per replicate. Both roots of a replicate
    # come from the same resampled experiment, which is what makes the pairwise
    # difference below meaningful.
    rootrep <- matrix(NA_real_, nl, ncol(reps))
    bnd <- matrix(NA, nl, ncol(reps))
    for (i in seq_len(nl)) {
      sub <- reps[idx[[i]], , drop = FALSE]
      xi <- xs[[i]]
      for (b in seq_len(ncol(sub))) {
        v <- sub[, b]
        if (anyNA(v)) next
        z <- .econ_root(xi, .econ_deriv(xi, v), r)
        rootrep[i, b] <- z$x
        bnd[i, b] <- isTRUE(z$boundary)
      }
    }
    pt <- vapply(seq_len(nl), function(i) {
      xi <- xs[[i]]; yi <- point[idx[[i]]]
      .econ_root(xi, .econ_deriv(xi, yi), r)$x
    }, numeric(1))
    fr <- vapply(seq_len(nl), function(i) {
      xi <- xs[[i]]; yi <- point[idx[[i]]]
      if (!is.finite(pt[i])) NA_real_ else stats::approx(xi, yi, xout = pt[i])$y
    }, numeric(1))

    tab <- data.frame(
      price_ratio = r,
      level = levs,
      optimum = pt,
      lower = apply(rootrep, 1L, stats::quantile, probs = a, na.rm = TRUE, names = FALSE),
      upper = apply(rootrep, 1L, stats::quantile, probs = 1 - a, na.rm = TRUE, names = FALSE),
      fitted_response = fr,
      p_boundary = rowMeans(bnd, na.rm = TRUE),
      replicates = rowSums(!is.na(rootrep)),
      row.names = NULL, stringsAsFactors = FALSE)
    tab$identified <- tab$p_boundary < 0.5
    rows[[length(rows) + 1L]] <- tab

    if (nl > 1L) {
      pr <- utils::combn(nl, 2L)
      cc <- do.call(rbind, lapply(seq_len(ncol(pr)), function(j) {
        i1 <- pr[1L, j]; i2 <- pr[2L, j]
        dd <- rootrep[i1, ] - rootrep[i2, ]
        dd <- dd[is.finite(dd)]
        if (!length(dd)) return(NULL)
        p <- 2 * (min(sum(dd <= 0), sum(dd >= 0)) + 1) / (length(dd) + 1)
        data.frame(
          price_ratio = r,
          contrast = paste(levs[i1], "-", levs[i2]),
          difference = pt[i1] - pt[i2],
          lower = unname(stats::quantile(dd, a)),
          upper = unname(stats::quantile(dd, 1 - a)),
          p_value = min(1, p),
          both_identified = tab$identified[i1] && tab$identified[i2],
          replicates = length(dd),
          row.names = NULL, stringsAsFactors = FALSE)
      }))
      if (!is.null(cc) && nrow(cc))
        contr[[length(contr) + 1L]] <- cc
    }
  }

  opt_tab <- do.call(rbind, rows)
  ct <- if (length(contr)) do.call(rbind, contr) else NULL
  if (!is.null(ct) && nrow(ct)) {
    # Adjust within each price ratio: the ratios are a sensitivity analysis of
    # one question, not a family of separate questions.
    ct$p_adjusted <- unsplit(lapply(split(ct$p_value, ct$price_ratio), function(p)
      if (identical(adjust, "none")) p else .p_adjust(p, adjust)), ct$price_ratio)
    attr(ct, "p_floor") <- 2 / (B + 1)
  }

  agro <- agri_np_optimum(object, predictor = predictor, n = n,
                          fixed = fixed, range = range)

  structure(
    list(optimum = opt_tab, contrasts = ct,
         curve = cbind(gall, fit = point,
                       .level = if (is.null(by_nm)) "all" else rep(levs, sizes)),
         agronomic = agro, replicates = reps),
    level = level, B = B, adjust = adjust, price_ratio = price_ratio,
    cluster = cl %||% NA_character_, predictor = predictor,
    response = object$response, by = by_nm,
    class = "agri_np_optimum_economic")
}

#' @export
print.agri_np_optimum_economic <- function(x, ...) {
  cat("Economic optimum of ", attr(x, "response"),
      " over ", attr(x, "predictor"), "\n", sep = "")
  cl <- attr(x, "cluster")
  cat("  Marginal product equals the price ratio, dy/dx = r\n")
  cat("  Resampling unit: ",
      if (is.na(cl)) "individual rows" else paste0("whole levels of `", cl, "`"),
      "   B = ", attr(x, "B"),
      "   level = ", format(attr(x, "level")), "\n\n", sep = "")
  print(x$optimum, row.names = FALSE, digits = 4)

  ag <- x$agronomic
  if (!is.null(ag)) {
    cat("\nAgronomic optimum, the top of the curve, for comparison: ",
        format(ag$optimum, digits = 4), "\n", sep = "")
    gap <- ag$optimum - x$optimum$optimum
    if (any(is.finite(gap) & gap > 0))
      cat("  The economic optimum lies below it, as it must on a concave ",
          "response.\n  The distance between the two is the input that would ",
          "be applied\n  at a loss.\n", sep = "")
  }
  if (any(!x$optimum$identified))
    cat("\nAt least one root sits on the edge of the tested range in most\n",
        "replicates, so it is not identified by these data. At that price the\n",
        "trial does not contain the answer: either the response never stops\n",
        "paying inside the tested range, or it never starts.\n", sep = "")
  if (length(attr(x, "price_ratio")) > 1L)
    cat("\nSeveral price ratios were supplied. Read the table as a sensitivity\n",
        "analysis: the ratio is treated as known here, and prices usually move\n",
        "the recommendation further than the resampling interval does.\n", sep = "")
  if (!is.null(x$contrasts)) {
    adj <- attr(x, "adjust") %||% "none"
    cat("\nDifference between economic optima, same replicate",
        if (identical(adj, "none")) "" else paste0(", p adjusted by ", adj),
        ":\n\n", sep = "")
    print(x$contrasts, row.names = FALSE, digits = 4)
  }
  invisible(x)
}
