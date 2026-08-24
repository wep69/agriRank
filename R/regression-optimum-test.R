# Inference for the location of an agronomic optimum ------------------------
#
# agri_np_optimum() answers "where is the maximum of this fitted curve". That
# is a point with no uncertainty attached, and a point is not a recommendation.
# Two questions have to be answered before a rate can be recommended:
#
#   1. How precisely is that location determined? A response that plateaus has
#      a maximum that wanders over a wide stretch of the gradient from one
#      resampled experiment to the next, even when the curve itself is well
#      estimated.
#   2. Is the maximum interior at all? An optimum reported at the edge of the
#      tested range is usually an artefact: a maximum has to land somewhere,
#      and if the response never turns over it lands on the boundary.
#
# Both are answered by resampling the argmax, not the curve. The resampling is
# the package's own cluster bootstrap, so whole blocks are resampled and the
# declared randomization is respected. npregfast, when installed, is used as an
# independent second opinion rather than as the engine.

.opt_index <- function(v, objective) {
  if (identical(objective, "max")) which.max(v) else which.min(v)
}

.opt_grid_for_level <- function(object, predictor, by, lev, n, fixed, range) {
  fx <- fixed
  if (!is.null(by)) fx[[by]] <- lev
  .np_prediction_grid(object, predictor = predictor, n = n, fixed = fx,
                      range = range)
}

#' Confidence interval and tests for the location of an optimum
#'
#' Resamples the location of the fitted optimum, rather than the fitted curve,
#' so that a recommended rate can be reported with the uncertainty it actually
#' carries. Optionally compares the optimum between levels of a qualitative
#' predictor.
#'
#' @param object An `agri_np_reg_fit` from [agri_np_regression()].
#' @param by Optional qualitative predictor whose levels are to be compared.
#'   Given as a name or a string. It must already be a predictor of the fitted
#'   model, because the comparison is made between curves of one model rather
#'   than between separately fitted models.
#' @param objective `"max"` or `"min"`.
#' @param B Bootstrap replicates. Use at least 999 for anything reported.
#' @param level Confidence level of the interval for the optimum.
#' @param seed Random seed.
#' @param n Grid size on which the optimum is located.
#' @param fixed Values at which other covariates are held.
#' @param range Optional two-element range of the predictor to search within.
#' @param cluster Resampling unit. Defaults to the declared block, which keeps
#'   whole blocks together. Pass `NA` to resample individual rows, which is only
#'   legitimate for a completely randomized layout.
#' @param adjust Multiplicity adjustment applied across the pairwise contrasts
#'   produced by `by`, passed to [stats::p.adjust()]. Defaults to `"holm"`.
#'   With `k` levels there are `k(k-1)/2` comparisons, and the family-wise error
#'   rate grows accordingly. Use `"none"` only when a single contrast was
#'   specified in advance.
#' @param external Cross-check the interval against `npregfast::critical()` when
#'   that package is installed. The two use different machinery, so agreement is
#'   evidence and disagreement is a reason to look closer.
#' @details
#' The interval is a percentile interval of the bootstrap distribution of the
#' argmax. `p_boundary` is the share of replicates whose optimum falls on an end
#' of the searched range; a large value means the response does not turn over
#' inside the tested range and no interior optimum is identified. In that
#' situation the honest report is not a rate but the statement produced by
#' [agri_np_significant_slope()], namely the point beyond which there is no
#' longer evidence that the response rises.
#'
#' With `by`, every pair of levels is compared through the bootstrap
#' distribution of the difference between their optima, computed inside the same
#' resampling loop so that the two optima of a replicate come from the same
#' resampled experiment. The reported p-value is the usual two-sided percentile
#' p-value, twice the smaller tail proportion, capped at one.
#'
#' Nothing here assumes a distribution for the response, and nothing here fits a
#' parametric response function. The optimum is located by evaluation on a grid,
#' exactly as in [agri_np_optimum()].
#' @return An object of class `agri_np_optimum_test`, a list with `optimum`,
#'   `contrasts`, `replicates`, `curves` and `external`.
#' @seealso [agri_np_optimum()] for the point estimate,
#'   [agri_np_sizer()] for where the response is still changing,
#'   [agri_integer_optimum()] when the decision is an integer.
#' @references
#' Sperlich, S., Gonzalez-Manteiga, W. and Roca-Pardinas, J. (2013). Bootstrap
#' inference for nonparametric regression. In: *Advances in Directional and
#' Linear Statistics*.
#' @export
agri_np_optimum_test <- function(object, by = NULL, objective = c("max", "min"),
                                 B = 999L, level = 0.95, seed = 1, n = 200L,
                                 fixed = list(), range = NULL, cluster = NULL,
                                 adjust = c("holm", "none", "BH", "bonferroni",
                                            "hochberg", "hommel", "BY"),
                                 external = TRUE, parallel = FALSE) {
  if (!inherits(object, "agri_np_reg_fit"))
    .agri_stop("`object` must be an agri_np_reg_fit.")
  objective <- match.arg(objective)
  adjust <- match.arg(adjust)
  if (!is.finite(level) || level <= 0 || level >= 1)
    .agri_stop("`level` must lie strictly between 0 and 1.")
  .np_check_B(B)

  if (!is.null(object$integer_support) && length(object$integer_support))
    .agri_stop("This fit declares an integer decision support. Use ",
               "`agri_integer_optimum()` and `agri_integer_confset()`, which ",
               "work on the admissible integer lattice instead of a grid.")

  predictor <- object$primary_predictor
  if (is.null(predictor) || !is.numeric(object$data[[predictor]]))
    .agri_stop("An optimum needs a numeric focal predictor. The fitted model ",
               "has none.")

  bexpr <- substitute(by)
  bval <- tryCatch(by, error = function(e) NULL)
  by_nm <- if (identical(bexpr, quote(NULL))) NULL
           else if (is.character(bval)) bval
           else .capture_names(bexpr, names(object$data))
  if (length(by_nm) > 1L)
    .agri_stop("`by` must name a single qualitative predictor.")
  if (!is.null(by_nm)) {
    if (!by_nm %in% object$predictors)
      .agri_stop("`", by_nm, "` is not a predictor of the fitted model. ",
                 "Refit including it, so that the levels are compared inside ",
                 "one model rather than across separately fitted models.")
    if (!is.factor(object$data[[by_nm]]) && !is.character(object$data[[by_nm]]))
      .agri_stop("`", by_nm, "` must be qualitative to compare optima between ",
                 "its levels.")
  }

  levs <- if (is.null(by_nm)) NA_character_
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

  # A model that adjusts for `by` additively produces parallel curves, so its
  # levels share one optimum by construction and any comparison of optima would
  # be an artefact of the model rather than a finding about the crop. Detect
  # that from the fitted curves themselves, which works for every engine, and
  # refuse instead of returning a difference of exactly zero with p = 1.
  if (nl > 1L) {
    p0 <- agri_np_predict(object, gall)
    if (is.matrix(p0)) p0 <- p0[, 1L]
    p0 <- as.numeric(p0)
    ref <- p0[idx[[1L]]]
    spans <- vapply(seq_len(nl)[-1L], function(i) {
      dif <- p0[idx[[i]]] - ref
      diff(range(dif))
    }, numeric(1))
    tol <- 1e-8 * max(1, stats::sd(object$data[[object$response]], na.rm = TRUE))
    if (all(spans <= tol))
      .agri_stop("The fitted curves for the levels of `", by_nm, "` are ",
                 "parallel, because `", by_nm, "` enters the model as an ",
                 "additive adjustment. Their optima are therefore identical by ",
                 "construction and comparing them would describe the model, ",
                 "not the experiment. Refit allowing the shape to differ, with ",
                 "`gam_structure = \"varying\"`, which fits one smooth of ",
                 predictor, " per level of ", by_nm, ".")
  }

  # Resampling whole blocks with replacement will sometimes omit a block, and a
  # refit that has never seen that level cannot predict for it. Those replicates
  # are discarded and counted, which is the correct behaviour; the accompanying
  # warnings are a predictable consequence of the design, not new information,
  # so they are muted here and the retention is reported in the table instead.
  bt <- suppressWarnings(
    agri_np_bootstrap(object, newdata = gall, B = B, level = level,
                      seed = seed, cluster = cl, keep_replicates = TRUE,
                      parallel = parallel))
  reps <- attr(bt, "replicates")
  if (is.null(reps))
    .agri_stop("The bootstrap did not return replicates, so the location of ",
               "the optimum cannot be resampled.")

  point <- as.numeric(as.data.frame(bt)$fit)
  xs <- lapply(seq_len(nl), function(i) gall[[predictor]][idx[[i]]])

  # One row per level, one column per replicate. Both optima of a replicate
  # come from the same resampled experiment, which is what makes the pairwise
  # difference below meaningful.
  optrep <- matrix(NA_real_, nl, ncol(reps))
  bnd <- matrix(NA, nl, ncol(reps))
  for (i in seq_len(nl)) {
    sub <- reps[idx[[i]], , drop = FALSE]
    for (b in seq_len(ncol(sub))) {
      v <- sub[, b]
      if (anyNA(v)) next
      k <- .opt_index(v, objective)
      optrep[i, b] <- xs[[i]][k]
      bnd[i, b] <- k %in% c(1L, length(v))
    }
  }

  a <- (1 - level) / 2
  opt_tab <- data.frame(
    level = if (is.null(by_nm)) "all" else levs,
    n = vapply(seq_len(nl), function(i)
      if (is.null(by_nm)) nrow(object$data)
      else sum(as.character(object$data[[by_nm]]) == levs[i]), integer(1)),
    optimum = vapply(seq_len(nl), function(i)
      xs[[i]][.opt_index(point[idx[[i]]], objective)], numeric(1)),
    lower = apply(optrep, 1L, stats::quantile, probs = a, na.rm = TRUE,
                  names = FALSE),
    upper = apply(optrep, 1L, stats::quantile, probs = 1 - a, na.rm = TRUE,
                  names = FALSE),
    fitted_response = vapply(seq_len(nl), function(i) {
      p <- point[idx[[i]]]; p[.opt_index(p, objective)]
    }, numeric(1)),
    p_boundary = rowMeans(bnd, na.rm = TRUE),
    replicates = rowSums(!is.na(optrep)),
    row.names = NULL, stringsAsFactors = FALSE
  )
  opt_tab$identified <- opt_tab$p_boundary < 0.5

  contr <- NULL
  if (nl > 1L) {
    pr <- utils::combn(nl, 2L)
    contr <- do.call(rbind, lapply(seq_len(ncol(pr)), function(j) {
      i1 <- pr[1L, j]; i2 <- pr[2L, j]
      dd <- optrep[i1, ] - optrep[i2, ]
      dd <- dd[is.finite(dd)]
      if (!length(dd)) return(NULL)
      # Resampling p-value with the Davison and Hinkley correction. Without the
      # added one a percentile p-value can print as exactly zero, which claims
      # more precision than a finite number of replicates can deliver: the
      # smallest attainable value is 2/(B+1).
      p <- 2 * (min(sum(dd <= 0), sum(dd >= 0)) + 1) / (length(dd) + 1)
      data.frame(
        contrast = paste(levs[i1], "-", levs[i2]),
        difference = opt_tab$optimum[i1] - opt_tab$optimum[i2],
        lower = unname(stats::quantile(dd, a)),
        upper = unname(stats::quantile(dd, 1 - a)),
        p_value = min(1, p),
        both_identified = opt_tab$identified[i1] && opt_tab$identified[i2],
        replicates = length(dd),
        row.names = NULL, stringsAsFactors = FALSE
      )
    }))
    # Every pair of levels is tested, so the family-wise error rate grows with
    # the number of levels. The rank-based side of the package has offered this
    # since the first release; there is no reason for the regression side to
    # report unadjusted p-values for the same kind of all-pairs comparison.
    # The adjustment is applied across the contrasts of this call only.
    if (!is.null(contr) && nrow(contr)) {
      contr$p_adjusted <- if (identical(adjust, "none")) contr$p_value
                          else .p_adjust(contr$p_value, adjust)
      # A percentile p-value cannot fall below 2/(B+1); after adjustment the
      # floor rises, and a p_adjusted sitting exactly on it means the resampling
      # was too small to separate the levels, not that they are equal.
      attr(contr, "p_floor") <- 2 / (B + 1)
    }
  }

  curves <- cbind(gall, fit = point,
                  lower = as.data.frame(bt)$lower,
                  upper = as.data.frame(bt)$upper)
  if (!is.null(by_nm)) curves$.level <- rep(levs, sizes) else curves$.level <- "all"

  ext <- if (isTRUE(external)) .opt_external(object, predictor, by_nm, level)
         else NULL

  structure(
    list(optimum = opt_tab, contrasts = contr, replicates = optrep,
         curves = curves, external = ext),
    objective = objective, level = level, B = B, adjust = adjust,
    cluster = cl %||% NA_character_, predictor = predictor,
    response = object$response, by = by_nm,
    class = "agri_np_optimum_test"
  )
}

# Independent cross-check. npregfast locates critical points with its own
# bootstrap of a local polynomial fit, which shares no code with the above.
# It resamples rows, so with a declared block it is reported as a comparison
# only, never as the interval to quote.
.opt_external <- function(object, predictor, by_nm, level) {
  if (!requireNamespace("npregfast", quietly = TRUE)) return(NULL)
  d <- object$data
  rhs <- if (is.null(by_nm)) predictor else paste(predictor, ":", by_nm)
  f <- stats::as.formula(paste(object$response, "~", rhs))
  m <- tryCatch(npregfast::frfast(f, data = d, model = "np", smooth = "kernel",
                                  nboot = 200, seed = 1, cluster = FALSE),
                error = function(e) NULL)
  if (is.null(m)) return(NULL)
  cr <- tryCatch(npregfast::critical(m), error = function(e) NULL)
  if (is.null(cr) || is.null(cr$Estimation)) return(NULL)
  e <- as.data.frame(cr$Estimation)
  out <- data.frame(
    level = if (is.null(by_nm)) "all" else sub("^Level ", "", rownames(e)),
    optimum = as.numeric(e[["Critical"]]),
    lower = as.numeric(e[["Lwr"]]),
    upper = as.numeric(e[["Upr"]]),
    row.names = NULL, stringsAsFactors = FALSE
  )
  attr(out, "block_aware") <- is.null(object$block)
  out
}

#' @export
print.agri_np_optimum_test <- function(x, ...) {
  obj <- attr(x, "objective")
  cat("Location of the ", obj, "imum of ", attr(x, "response"),
      " over ", attr(x, "predictor"), "\n", sep = "")
  cl <- attr(x, "cluster")
  cat("  Resampling unit: ",
      if (is.na(cl)) "individual rows" else paste0("whole levels of `", cl, "`"),
      "   B = ", attr(x, "B"),
      "   level = ", format(attr(x, "level")), "\n\n", sep = "")
  print(x$optimum, row.names = FALSE, digits = 4)
  ret <- max(x$optimum$replicates) / attr(x, "B")
  if (ret < 0.8)
    cat("\nOnly ", format(round(100 * ret)), "% of replicates were usable. ",
        "Resampling whole blocks\nsometimes omits one, and a refit that never ",
        "saw a block cannot predict for\nit. Raise B to keep the same effective ",
        "number of replicates.\n", sep = "")
  if (any(!x$optimum$identified)) {
    cat("\nAt least one optimum sits on the edge of the tested range in most\n",
        "replicates, so it is not identified by these data. Report the range\n",
        "over which the response still changes, from agri_np_significant_slope(),\n",
        "rather than a rate.\n", sep = "")
  }
  if (!is.null(x$contrasts)) {
    adj <- attr(x, "adjust") %||% "none"
    cat("\nDifference between optima, same replicate",
        if (identical(adj, "none")) "" else paste0(", p adjusted by ", adj),
        ":\n\n", sep = "")
    print(x$contrasts, row.names = FALSE, digits = 4)
    if (identical(adj, "none") && nrow(x$contrasts) > 1L)
      cat("\n  ", nrow(x$contrasts), " comparisons are reported without any ",
          "multiplicity adjustment.\n  Set `adjust` unless the contrast was ",
          "chosen before seeing the data.\n", sep = "")
    fl <- attr(x$contrasts, "p_floor")
    if (!is.null(fl) && any(x$contrasts$p_value <= fl + 1e-12))
      cat("\n  A p_value equal to ", format(fl, digits = 3),
          " is the floor of ", attr(x, "B"), " replicates, not a\n",
          "  measurement. Raise B before quoting it.\n", sep = "")
    if (any(!x$contrasts$both_identified))
      cat("\n  A contrast marked both_identified = FALSE compares an optimum\n",
          "  with a boundary artefact. Read it as a statement that the two\n",
          "  levels behave differently, not as a difference between two rates.\n",
          sep = "")
  }
  if (!is.null(x$external)) {
    cat("\nIndependent check, npregfast::critical():\n\n")
    print(x$external, row.names = FALSE, digits = 4)
    if (!isTRUE(attr(x$external, "block_aware")))
      cat("  This check resamples rows and ignores the declared block, so it\n",
          "  is a comparison only. Quote the interval above.\n", sep = "")
  }
  invisible(x)
}

#' @export
plot.agri_np_optimum_test <- function(x, type = c("curve", "distribution"), ...) {
  .require_pkg("ggplot2", "regression graphics")
  type <- match.arg(type)
  px <- attr(x, "predictor"); py <- attr(x, "response")
  by_nm <- attr(x, "by")
  grouped <- !is.null(by_nm)

  if (identical(type, "curve")) {
    # Columns are renamed to fixed symbols so that the aesthetics do not need
    # to be built from strings, and the real names are restored in labs().
    cv <- x$curves
    cv <- data.frame(x = cv[[px]], fit = cv$fit, lower = cv$lower,
                     upper = cv$upper, g = factor(cv$.level))
    o <- x$optimum
    o <- data.frame(x = o$optimum, y = o$fitted_response,
                    lower = o$lower, upper = o$upper,
                    g = factor(o$level, levels = levels(cv$g)))
    p <- ggplot2::ggplot(cv, ggplot2::aes(x = x, y = fit))
    if (grouped) {
      p <- p +
        ggplot2::geom_ribbon(ggplot2::aes(ymin = lower, ymax = upper, fill = g),
                             alpha = 0.15, colour = NA) +
        ggplot2::geom_line(ggplot2::aes(colour = g), linewidth = 0.9)
    } else {
      p <- p +
        ggplot2::geom_ribbon(ggplot2::aes(ymin = lower, ymax = upper),
                             alpha = 0.15, fill = "grey40") +
        ggplot2::geom_line(linewidth = 0.9)
    }
    p +
      ggplot2::geom_segment(
        data = o, ggplot2::aes(x = lower, xend = upper, y = y, yend = y),
        inherit.aes = FALSE, linewidth = 1.1, alpha = 0.85) +
      ggplot2::geom_point(data = o, ggplot2::aes(x = x, y = y),
                          inherit.aes = FALSE, size = 2.6) +
      ggplot2::labs(x = px, y = py, colour = by_nm, fill = by_nm,
                    title = "Fitted response with the resampled optimum",
                    caption = paste0("Horizontal bar: ",
                                     format(100 * attr(x, "level")),
                                     "% interval for the location of the optimum, ",
                                     "not for the height of the curve.")) +
      .agri_theme_or_minimal()
  } else {
    rr <- x$replicates
    df <- data.frame(g = rep(x$optimum$level, times = ncol(rr)),
                     x = as.numeric(rr))
    df <- df[is.finite(df$x), , drop = FALSE]
    p <- ggplot2::ggplot(df, ggplot2::aes(x = x)) +
      ggplot2::geom_histogram(bins = 30, fill = "grey35", colour = "white") +
      ggplot2::labs(x = paste0("Location of the optimum (", px, ")"),
                    y = "Bootstrap replicates",
                    title = "Where the optimum lands across resampled experiments",
                    caption = "Mass piled against an end of the range means no interior optimum is identified.") +
      .agri_theme_or_minimal()
    if (grouped) p <- p + ggplot2::facet_wrap(~ g)
    p
  }
}
