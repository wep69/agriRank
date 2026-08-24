# Two responses to the same gradient, and the recommendation that has to satisfy
# both.
#
# Nitrogen raises yield and lowers grain protein concentration, or raises both
# but with optima far apart. Fitting two curves separately answers each question
# and leaves the joint one untouched, because the two optima are estimated from
# THE SAME plots and their errors are correlated. Two marginal intervals cannot
# express that: they describe a rectangle, and the truth is usually a diagonal.
#
# The device is one shared bootstrap. Replicate b resamples a set of blocks once
# and refits every response on that same resampled experiment, so the joint
# distribution of the optima is preserved rather than assumed. That is the only
# structural difference from calling agri_np_optimum_test() twice, and it is the
# whole point.
#
# What this does not do: it does not model the covariance between responses, and
# it does not test a multivariate null. For a rank-based multivariate test of
# treatment effects see agri_multivariate().

#' Several responses to one gradient, with a joint region for their optima
#'
#' @description
#' Fits one curve per response over the same gradient and reports the optima
#' with a **shared** cluster bootstrap, so that the correlation between them
#' survives into the joint region.
#' @param formula A formula whose left-hand side names two or more responses,
#'   as `cbind(yield, protein) ~ rate` or `yield + protein ~ rate`.
#' @param data Data frame.
#' @param block Optional block, which becomes the resampling unit.
#' @param objective One of `"max"` or `"min"`, recycled over the responses, or a
#'   vector with one entry per response. Yield is usually maximised and lodging
#'   minimised, so a single value is often wrong.
#' @param B Bootstrap replicates.
#' @param level Confidence level.
#' @param seed Random seed.
#' @param n Grid size.
#' @param method Engine, passed to [agri_np_regression()].
#' @param cluster Resampling unit. Defaults to the declared block.
#' @param parallel Distribute the replicates over a `future` plan.
#' @param ... Passed to [agri_np_regression()].
#' @details
#' Every response is refitted on the same resampled blocks within a replicate.
#' Doing otherwise, which is what calling [agri_np_optimum_test()] twice
#' amounts to, would give each response its own resampled experiment and destroy
#' exactly the dependence the joint question turns on.
#'
#' The output carries three things a pair of separate analyses cannot:
#' `rank_correlation` between the resampled optima, `region`, the convex hull of
#' the replicate pairs when there are exactly two responses, and `agreement`,
#' the share of replicates in which the two optima fall within `tolerance` of
#' each other.
#'
#' **A joint region is not a compromise rate.** Choosing one rate for two
#' responses is a decision about their relative value, not a statistical
#' question, and this function deliberately does not make it. What it supplies
#' is how far apart the two optima are and how well that distance is determined.
#' Combine it with [agri_np_optimum_economic()] on each response when prices
#' are what decide.
#' @return An object of class `agri_np_multiresponse`.
#' @seealso [agri_np_optimum_test()], [agri_np_optimum_surface()] for two
#'   predictors rather than two responses, [agri_multivariate()] for the
#'   rank-based multivariate test.
#' @export
agri_np_multiresponse <- function(formula, data, block = NULL,
                                  objective = "max", B = 499L, level = 0.95,
                                  seed = 1, n = 100L, method = "gam",
                                  cluster = NULL, parallel = FALSE, ...) {
  if (!inherits(formula, "formula")) .agri_stop("`formula` must be a formula.")
  if (!is.data.frame(data)) data <- as.data.frame(data)
  .np_check_B(B)

  lhs <- formula[[2L]]
  resp <- if (is.call(lhs) && identical(as.character(lhs[[1L]]), "cbind"))
            vapply(as.list(lhs)[-1L], deparse, character(1))
          else all.vars(lhs)
  if (length(resp) < 2L)
    .agri_stop("`agri_np_multiresponse()` needs two or more responses, as ",
               "cbind(yield, protein) ~ rate. With one response use ",
               "agri_np_optimum_test().")
  .check_vars(resp, data)

  # A bare symbol naming a column does not resolve in the caller's frame, so an
  # evaluation error means "this is a column name", not "there is no block".
  # Conflating the two silently dropped the block and sent the bootstrap back to
  # resampling rows, which is the one thing this function must not do.
  bexpr <- substitute(block)
  .bok <- TRUE
  bval <- tryCatch(block, error = function(e) { .bok <<- FALSE; NULL })
  bnm <- if (identical(bexpr, quote(NULL)) || (.bok && is.null(bval))) NULL
         else if (is.character(bval)) bval else .capture_names(bexpr, names(data))
  cexpr <- substitute(cluster); cval <- tryCatch(cluster, error = function(e) NULL)
  cl <- if (identical(cexpr, quote(NULL))) bnm
        else if (length(cval) == 1L && !is.null(cval) && is.na(cval)) NULL
        else if (is.character(cval)) cval else .capture_names(cexpr, names(data))

  obj <- if (length(objective) == 1L) rep(objective, length(resp)) else objective
  if (length(obj) != length(resp))
    .agri_stop("`objective` must have one entry, or one per response.")
  if (!all(obj %in% c("max", "min")))
    .agri_stop("`objective` entries must be \"max\" or \"min\".")

  rhs <- paste(deparse(formula[[3L]]), collapse = "")
  fits <- lapply(resp, function(r) {
    f <- stats::as.formula(paste(r, "~", rhs), env = environment(formula))
    agri_np_regression(f, data, method = method, block = bnm, ...)
  })
  names(fits) <- resp
  px <- fits[[1L]]$primary_predictor
  if (is.null(px) || !is.numeric(data[[px]]))
    .agri_stop("A joint optimum needs a numeric gradient; the model has none.")

  grid <- .np_prediction_grid(fits[[1L]], predictor = px, n = as.integer(n))
  xs <- grid[[px]]
  point <- vapply(seq_along(resp), function(i) {
    p <- agri_np_predict(fits[[i]], grid)
    if (is.matrix(p)) p <- p[, 1L]
    xs[.opt_index(as.numeric(p), obj[i])]
  }, numeric(1))

  # One shared resample per replicate. This is the whole structural difference
  # from analysing the responses separately.
  streams <- .agri_substreams(seed, B)
  one <- function(b) {
    db <- .agri_on_stream(streams[[b]],
            .bootstrap_sample(data, cluster = cl, relabel = FALSE))
    vapply(seq_along(resp), function(i) {
      f <- stats::as.formula(paste(resp[i], "~", rhs), env = environment(formula))
      z <- tryCatch(agri_np_regression(f, db, method = method, block = bnm, ...),
                    error = function(e) NULL)
      if (is.null(z)) return(NA_real_)
      p <- tryCatch(agri_np_predict(z, grid), error = function(e) NULL)
      if (is.null(p)) return(NA_real_)
      if (is.matrix(p)) p <- p[, 1L]
      p <- as.numeric(p)
      if (anyNA(p)) return(NA_real_)
      xs[.opt_index(p, obj[i])]
    }, numeric(1))
  }
  reps <- .np_quiet_support(.seed_eval(seed,
    .agri_lapply(seq_len(B), one, parallel = parallel)))
  M <- do.call(rbind, reps)
  colnames(M) <- resp

  a <- (1 - level) / 2
  tab <- data.frame(
    response = resp, objective = obj, optimum = point,
    lower = apply(M, 2L, stats::quantile, probs = a, na.rm = TRUE, names = FALSE),
    upper = apply(M, 2L, stats::quantile, probs = 1 - a, na.rm = TRUE, names = FALSE),
    replicates = colSums(is.finite(M)),
    row.names = NULL, stringsAsFactors = FALSE)

  pairs <- NULL; region <- NULL; rho <- NA_real_
  if (length(resp) >= 2L) {
    pr <- utils::combn(length(resp), 2L)
    pairs <- do.call(rbind, lapply(seq_len(ncol(pr)), function(j) {
      i1 <- pr[1L, j]; i2 <- pr[2L, j]
      dd <- M[, i1] - M[, i2]; dd <- dd[is.finite(dd)]
      if (!length(dd)) return(NULL)
      p <- 2 * (min(sum(dd <= 0), sum(dd >= 0)) + 1) / (length(dd) + 1)
      ok <- is.finite(M[, i1]) & is.finite(M[, i2])
      data.frame(
        contrast = paste(resp[i1], "-", resp[i2]),
        difference = point[i1] - point[i2],
        lower = unname(stats::quantile(dd, a)),
        upper = unname(stats::quantile(dd, 1 - a)),
        p_value = min(1, p),
        rank_correlation = if (sum(ok) >= 4L)
          suppressWarnings(stats::cor(M[ok, i1], M[ok, i2], method = "spearman"))
        else NA_real_,
        replicates = length(dd),
        row.names = NULL, stringsAsFactors = FALSE)
    }))
    if (length(resp) == 2L) {
      region <- .surf_region(M[, 1L], M[, 2L], level)
      if (!is.null(region)) names(region) <- resp
      rho <- pairs$rank_correlation[1L]
    }
  }

  structure(
    list(optima = tab, contrasts = pairs, region = region, fits = fits,
         replicates = as.data.frame(M)),
    level = level, B = B, cluster = cl %||% NA_character_, predictor = px,
    responses = resp, rank_correlation = rho,
    class = "agri_np_multiresponse")
}

#' @export
print.agri_np_multiresponse <- function(x, ...) {
  cat("Optima of several responses to ", attr(x, "predictor"),
      ", from one shared bootstrap\n", sep = "")
  cl <- attr(x, "cluster")
  cat("  Resampling unit: ",
      if (is.na(cl)) "individual rows" else paste0("whole levels of `", cl, "`"),
      "   B = ", attr(x, "B"),
      "   level = ", format(attr(x, "level")), "\n\n", sep = "")
  print(x$optima, row.names = FALSE, digits = 4)
  ret <- max(x$optima$replicates) / attr(x, "B")
  if (ret < 0.8)
    cat("\n  Only ", format(round(100 * ret)), "% of replicates were usable. ",
        "Resampling whole blocks\n  sometimes omits one, and a refit that never ",
        "saw a block cannot predict\n  for it. Raise B to keep the same ",
        "effective number of replicates.\n", sep = "")
  if (!is.null(x$contrasts)) {
    cat("\nDistance between optima, both from the same resampled experiment:\n\n")
    print(x$contrasts, row.names = FALSE, digits = 4)
    r <- attr(x, "rank_correlation")
    if (is.finite(r) && abs(r) > 0.3)
      cat("\n  The two optima move together across replicates, correlation ",
          format(round(r, 3)), ".\n  Their marginal intervals therefore ",
          "overstate how uncertain the DIFFERENCE\n  between them is, which is ",
          "the quantity a joint recommendation turns on.\n", sep = "")
  }
  if (!is.null(x$region))
    cat("\n  `$region` holds the joint region for the pair, ", nrow(x$region),
        " vertices. It is not\n  the rectangle formed by the two intervals ",
        "above.\n", sep = "")
  cat("\n  A joint region is not a compromise rate. Choosing one rate for two\n",
      "  responses is a decision about their relative value, not a statistical\n",
      "  question, and this function does not make it.\n", sep = "")
  invisible(x)
}
