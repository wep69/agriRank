# Joint optimum of a response surface in two predictors.
#
# agri_np_optimum() takes one predictor and holds the others at a fixed value.
# A nitrogen by phosphorus trial has a joint optimum, and maximising in N with P
# held, then in P with N held, does not return the top of the surface unless the
# two act additively. Additivity is exactly what such a trial exists to test, so
# assuming it in order to find the optimum is circular.
#
# Two things here need care and are the reason this is not a loop over
# agri_np_optimum():
#
#   1. The confidence region for a point in two dimensions is not the rectangle
#      formed by the two marginal intervals. The rectangle both over-covers,
#      because it admits corners the bootstrap never visited, and misleads,
#      because it hides the correlation between the two coordinates: when the
#      surface has a ridge, more N compensates for less P and the cloud of
#      resampled optima lies along a diagonal. The rectangle is reported as
#      `box_*`, clearly labelled, and the honest summary is the convex hull of
#      the retained replicates plus the correlation.
#
#   2. A surface fitted additively has an optimum whose coordinates are
#      separately determined and whose interaction is zero by construction. That
#      is a statement about the model. The function refuses it, in the same
#      spirit as the parallel-curve guard of agri_np_optimum_test().

# Highest posterior-free density region of a 2-d point cloud, by peeling to the
# requested mass with a simple Mahalanobis ordering, then reporting the convex
# hull of what is kept. Distribution-free and adequate for a bootstrap cloud.
.surf_region <- function(x, y, level) {
  ok <- is.finite(x) & is.finite(y)
  x <- x[ok]; y <- y[ok]
  n <- length(x)
  if (n < 8L) return(NULL)
  m <- cbind(x, y)
  S <- stats::cov(m)
  d <- tryCatch(
    if (all(is.finite(S)) && det(S) > .Machine$double.eps)
      stats::mahalanobis(m, colMeans(m), S)
    else rowSums(scale(m)^2),
    error = function(e) rep(NA_real_, nrow(m)))
  # A degenerate cloud, all replicates landing on the same grid point, gives a
  # singular covariance and non-finite distances. There is then no region to
  # describe, and returning NULL is the honest answer rather than a hull of one
  # point pretending to be an interval.
  if (!any(is.finite(d))) return(NULL)
  keep <- is.finite(d) & d <= stats::quantile(d, probs = level, na.rm = TRUE)
  if (sum(keep) < 3L) return(NULL)
  h <- grDevices::chull(m[keep, , drop = FALSE])
  data.frame(x = m[keep, 1L][h], y = m[keep, 2L][h], row.names = NULL)
}

#' Joint optimum of a response surface in two predictors
#'
#' @description
#' Locates the pair of rates that jointly optimises the fitted surface, and
#' reports a bootstrap confidence region for that pair.
#'
#' [agri_np_optimum()] optimises one predictor with the others held fixed.
#' Applied twice that is not the top of the surface unless the two inputs act
#' additively, which is what a factorial rate trial exists to test.
#' @param object An `agri_np_reg_fit` whose model contains both predictors, most
#'   naturally one fitted with `gam_structure = "tensor"`.
#' @param predictors Character vector of length two naming the numeric
#'   predictors to optimise jointly. Defaults to the first two numeric
#'   predictors of the model.
#' @param objective `"max"` or `"min"`.
#' @param B Bootstrap replicates. Use at least 999 for anything reported.
#' @param level Confidence level of the region.
#' @param seed Random seed.
#' @param n Grid size per axis. The surface is evaluated on `n * n` points, so
#'   this is quadratic in cost; 40 is usually enough to locate a smooth optimum.
#' @param fixed Values at which other covariates are held.
#' @param ranges Optional named list of two-element ranges, one per predictor.
#' @param cluster Resampling unit. Defaults to the declared block.
#' @details
#' The reported region is the convex hull of the retained bootstrap optima, not
#' the rectangle of the two marginal intervals. The rectangle is also reported,
#' as `box_lower_*` and `box_upper_*`, because it is what a reader expects to
#' see, and it is labelled so that it is not mistaken for the region. When the
#' surface has a ridge the two differ sharply: the cloud of resampled optima
#' lies along a diagonal, more of one input compensating for less of the other,
#' and the rectangle admits corners that no replicate ever visited. The
#' correlation between the two coordinates across replicates is reported for the
#' same reason.
#'
#' `p_boundary` is the share of replicates whose optimum lands on an edge of the
#' searched rectangle, and `identified` turns `FALSE` at one half, exactly as in
#' [agri_np_optimum_test()].
#' @return An object of class `agri_np_optimum_surface`, a list with `optimum`,
#'   `region`, `replicates` and `surface`.
#' @seealso [agri_np_optimum_test()] for one predictor,
#'   [agri_np_optimum_economic()] for the price-aware rate,
#'   [agri_np_plot()] with `type = "surface"` for the picture.
#' @export
agri_np_optimum_surface <- function(object, predictors = NULL,
                                    objective = c("max", "min"),
                                    B = 499L, level = 0.95, seed = 1,
                                    n = 40L, fixed = list(), ranges = NULL,
                                    cluster = NULL, parallel = FALSE) {
  if (!inherits(object, "agri_np_reg_fit"))
    .agri_stop("`object` must be an agri_np_reg_fit.")
  objective <- match.arg(objective)
  if (!is.finite(level) || level <= 0 || level >= 1)
    .agri_stop("`level` must lie strictly between 0 and 1.")
  .np_check_B(B)
  n <- max(8L, as.integer(n))

  if (!is.null(object$integer_support) && length(object$integer_support))
    .agri_stop("This fit declares an integer decision support, for which the ",
               "admissible set is a lattice rather than a surface. Use ",
               "`agri_integer_optimum()` on each factor with the other fixed, ",
               "and report that this is what was done.")

  num <- object$numeric_predictors
  pp <- predictors %||% num[1:2]
  if (length(pp) != 2L)
    .agri_stop("`predictors` must name exactly two numeric predictors. The ",
               "model has ", length(num), ": ", paste(num, collapse = ", "), ".")
  bad <- setdiff(pp, num)
  if (length(bad))
    .agri_stop("Not a numeric predictor of the fitted model: ",
               paste(bad, collapse = ", "), ".")

  cexpr <- substitute(cluster)
  cval <- tryCatch(cluster, error = function(e) NULL)
  cl <- if (identical(cexpr, quote(NULL))) object$block
        else if (length(cval) == 1L && is.na(cval)) NULL
        else if (is.character(cval)) cval
        else .capture_names(cexpr, names(object$data))

  rg <- lapply(pp, function(v) {
    r <- if (!is.null(ranges) && !is.null(ranges[[v]])) ranges[[v]]
         else base::range(object$data[[v]], na.rm = TRUE)
    if (length(r) != 2L || !all(is.finite(r)))
      .agri_stop("Cannot determine a finite range for `", v, "`.")
    r
  })
  names(rg) <- pp

  ax <- lapply(pp, function(v) seq(rg[[v]][1L], rg[[v]][2L], length.out = n))
  names(ax) <- pp
  g2 <- expand.grid(ax, KEEP.OUT.ATTRS = FALSE)

  # Start from the package's own one-dimensional grid so that factors, the block
  # and the reference values of untouched covariates are filled in the usual
  # way, then overwrite the two axes.
  base_row <- .np_prediction_grid(object, predictor = pp[1L], n = 1L,
                                  fixed = fixed)
  grid <- base_row[rep(1L, nrow(g2)), , drop = FALSE]
  rownames(grid) <- NULL
  for (v in pp) grid[[v]] <- g2[[v]]

  # An additive surface has an optimum whose coordinates are separately
  # determined: the location in one input does not depend on the level of the
  # other. Reporting a joint optimum and a joint region for it would describe
  # the model rather than the experiment.
  p0 <- agri_np_predict(object, grid)
  if (is.matrix(p0)) p0 <- p0[, 1L]
  p0 <- as.numeric(p0)
  M <- matrix(p0, nrow = n, ncol = n)
  add <- outer(rowMeans(M), colMeans(M), "+") - mean(M)
  tol <- 1e-6 * max(1, stats::sd(object$data[[object$response]], na.rm = TRUE))
  if (max(abs(M - add), na.rm = TRUE) <= tol)
    .agri_stop("The fitted surface is additive in `", pp[1L], "` and `", pp[2L],
               "`, so the optimum in each is the same at every level of the ",
               "other and the joint optimum carries no information the two ",
               "separate optima do not. Refit with ",
               "`gam_structure = \"tensor\"`, which lets the two interact, or ",
               "use agri_np_optimum() on each predictor and say that the ",
               "surface was assumed additive.")

  bt <- suppressWarnings(
    agri_np_bootstrap(object, newdata = grid, B = B, level = level,
                      seed = seed, cluster = cl, keep_replicates = TRUE,
                      parallel = parallel))
  reps <- attr(bt, "replicates")
  if (is.null(reps))
    .agri_stop("The bootstrap did not return replicates, so the joint optimum ",
               "cannot be resampled.")

  pick <- function(v) if (objective == "max") which.max(v) else which.min(v)
  on_edge <- function(k) {
    i <- ((k - 1L) %% n) + 1L
    j <- ((k - 1L) %/% n) + 1L
    i %in% c(1L, n) || j %in% c(1L, n)
  }

  k0 <- pick(p0)
  ox <- rep(NA_real_, ncol(reps)); oy <- ox; bnd <- rep(NA, ncol(reps))
  for (b in seq_len(ncol(reps))) {
    v <- reps[, b]
    if (all(is.na(v))) next
    k <- pick(v)
    if (!length(k) || is.na(k)) next
    ox[b] <- grid[[pp[1L]]][k]
    oy[b] <- grid[[pp[2L]]][k]
    bnd[b] <- on_edge(k)
  }

  a <- (1 - level) / 2
  keep <- is.finite(ox) & is.finite(oy)
  rho <- if (sum(keep) >= 4L)
           suppressWarnings(stats::cor(ox[keep], oy[keep], method = "spearman"))
         else NA_real_

  opt <- data.frame(
    predictor = pp,
    optimum = c(grid[[pp[1L]]][k0], grid[[pp[2L]]][k0]),
    box_lower = c(stats::quantile(ox, a, na.rm = TRUE, names = FALSE),
                  stats::quantile(oy, a, na.rm = TRUE, names = FALSE)),
    box_upper = c(stats::quantile(ox, 1 - a, na.rm = TRUE, names = FALSE),
                  stats::quantile(oy, 1 - a, na.rm = TRUE, names = FALSE)),
    searched_lower = c(rg[[1L]][1L], rg[[2L]][1L]),
    searched_upper = c(rg[[1L]][2L], rg[[2L]][2L]),
    row.names = NULL, stringsAsFactors = FALSE)

  region <- .surf_region(ox, oy, level)
  if (!is.null(region)) names(region) <- pp

  structure(
    list(optimum = opt,
         region = region,
         fitted_response = p0[k0],
         p_boundary = mean(bnd, na.rm = TRUE),
         identified = isTRUE(mean(bnd, na.rm = TRUE) < 0.5),
         rank_correlation = rho,
         replicates = data.frame(setNames(list(ox, oy), pp), boundary = bnd),
         surface = cbind(grid[, pp, drop = FALSE], fit = p0)),
    objective = objective, level = level, B = B,
    cluster = cl %||% NA_character_, predictors = pp,
    response = object$response,
    class = "agri_np_optimum_surface")
}

#' @export
print.agri_np_optimum_surface <- function(x, ...) {
  pp <- attr(x, "predictors")
  cat("Joint ", attr(x, "objective"), "imum of ", attr(x, "response"),
      " over ", pp[1L], " and ", pp[2L], "\n", sep = "")
  cl <- attr(x, "cluster")
  cat("  Resampling unit: ",
      if (is.na(cl)) "individual rows" else paste0("whole levels of `", cl, "`"),
      "   B = ", attr(x, "B"),
      "   level = ", format(attr(x, "level")), "\n\n", sep = "")
  print(x$optimum, row.names = FALSE, digits = 4)
  cat("\nFitted response at the joint optimum: ",
      format(x$fitted_response, digits = 5), "\n", sep = "")

  cat("\n  box_lower and box_upper are the two marginal intervals. Together\n",
      "  they form a rectangle, and the rectangle is NOT the confidence region\n",
      "  for the pair: it admits corners no replicate visited.\n", sep = "")
  if (is.finite(x$rank_correlation)) {
    cat("  Rank correlation between the two coordinates across replicates: ",
        format(round(x$rank_correlation, 3)), "\n", sep = "")
    if (abs(x$rank_correlation) > 0.4)
      cat("  That is substantial, so the surface has a ridge: more of one input\n",
          "  compensates for less of the other, and the pair is far better\n",
          "  determined along the ridge than across it. Use `$region`.\n", sep = "")
  }
  if (!is.null(x$region))
    cat("  `$region` holds the convex hull of the retained replicates, with ",
        nrow(x$region), " vertices.\n", sep = "")
  else
    cat("  `$region` is NULL: too few replicates were retained to describe a\n",
        "  region. Raise B.\n", sep = "")

  if (!isTRUE(x$identified))
    cat("\nThe joint optimum lands on an edge of the searched rectangle in ",
        format(round(100 * x$p_boundary)), "% of\nreplicates, so it is not ",
        "identified by these data. The surface does not turn\nover inside the ",
        "rates that were tested.\n", sep = "")
  invisible(x)
}
