# Simulation-based residual diagnostics ---------------------------------------
#
# The classical QQ-plot asks whether residuals look normal. For a package that
# refuses to assume a distribution, that is the wrong question asked of the
# wrong quantity. Simulation-based quantile residuals ask a better one: given
# the fitted model, where does each observation fall inside its own predictive
# distribution? Under a correct model those positions are uniform on [0,1],
# whatever the response distribution is.
#
# When DHARMa is installed and the engine is one it understands, its machinery
# is used. Otherwise agriRank simulates from the fitted engine itself, which
# keeps the diagnostic available for smoothers that DHARMa does not know.

.simdiag_simulate <- function(object, nsim = 250L, seed = 1) {
  fit <- as.numeric(object$fitted)
  res <- as.numeric(object$residuals)
  ok <- is.finite(fit) & is.finite(res)
  n <- length(fit)
  # Residual resampling: the reference distribution comes from the data, not
  # from an assumed family. This is the distribution-free analogue of the
  # parametric simulation DHARMa performs for GLMMs.
  .seed_eval(seed, {
    sims <- matrix(NA_real_, n, nsim)
    pool <- res[ok]
    for (b in seq_len(nsim)) sims[, b] <- fit + sample(pool, n, replace = TRUE)
    sims
  })
}

.simdiag_quantile <- function(y, sims) {
  n <- length(y)
  q <- rep(NA_real_, n)
  for (i in seq_len(n)) {
    s <- sims[i, ]
    s <- s[is.finite(s)]
    if (!length(s) || !is.finite(y[i])) next
    # Randomized rank inside the simulated predictive distribution, so that
    # ties do not pile the residuals onto 0 or 1.
    below <- mean(s < y[i]); equal <- mean(s == y[i])
    q[i] <- below + stats::runif(1) * equal
  }
  q
}

#' Simulation-based quantile residuals
#'
#' @description
#' Scaled residuals obtained by locating each observation inside its own
#' simulated predictive distribution. Under a correct model they are uniform on
#' the unit interval, whatever the distribution of the response.
#'
#' @param object An `agri_np_reg_fit`.
#' @param nsim Number of simulations.
#' @param seed Random seed.
#' @param engine `"auto"` uses \pkg{DHARMa} when it is installed and understands
#'   the backend, otherwise the internal residual-resampling simulator.
#'   `"agriRank"` forces the internal one.
#' @details
#' A normal QQ-plot asks whether the residuals look Gaussian. For a package
#' whose whole premise is to avoid assuming a distribution, that is the wrong
#' question asked of the wrong quantity. Quantile residuals ask where each
#' observation falls inside the predictive distribution the model implies, and
#' uniformity of those positions is the property a correct model must have.
#'
#' The diagnostic is descriptive. A departure from uniformity indicates that the
#' fitted mean, the dispersion, or both, do not describe the data. It is not a
#' test to be used for selecting an inferential method, which the package
#' refuses on principle.
#' @return An object of class `agri_np_simdiag` with the scaled residuals, a
#'   uniformity test, and the predictor values for plotting.
#' @references
#' Dunn, P. K. and Smyth, G. K. (1996). Randomized quantile residuals.
#' \emph{Journal of Computational and Graphical Statistics}, 5(3), 236-244.
#' \doi{10.1080/10618600.1996.10474708}
#'
#' Hartig, F. \pkg{DHARMa}: Residual Diagnostics for Hierarchical Regression
#' Models. CRAN.
#' @export
agri_np_simdiag <- function(object, nsim = 250L, seed = 1,
                            engine = c("auto", "agriRank")) {
  if (!inherits(object, "agri_np_reg_fit")) .agri_stop("`object` must be an agri_np_reg_fit.")
  engine <- match.arg(engine)
  y <- object$data[[object$response]]
  used <- "agriRank residual resampling"
  # agriRank always supplies the simulations, which keeps the reference
  # distribution empirical rather than assumed and works for every engine.
  # When DHARMa is installed its scaling machinery is used on those same
  # simulations through createDHARMa(), which avoids the extra backend
  # dependencies that simulateResiduals() requires for smooth models.
  sims <- .simdiag_simulate(object, nsim = nsim, seed = seed)
  scaled <- NULL
  if (identical(engine, "auto") && requireNamespace("DHARMa", quietly = TRUE)) {
    z <- tryCatch(
      DHARMa::createDHARMa(simulatedResponse = sims, observedResponse = y,
                           fittedPredictedResponse = as.numeric(object$fitted),
                           integerResponse = FALSE),
      error = function(e) NULL)
    if (!is.null(z)) {
      scaled <- as.numeric(z$scaledResiduals)
      used <- "agriRank simulation, DHARMa scaling"
    }
  }
  if (is.null(scaled)) scaled <- .seed_eval(seed, .simdiag_quantile(y, sims))

  ok <- is.finite(scaled)
  ks <- if (sum(ok) >= 5L)
    suppressWarnings(stats::ks.test(scaled[ok], "punif")) else NULL
  px <- object$primary_predictor
  structure(list(
    scaled_residuals = scaled,
    fitted = as.numeric(object$fitted),
    predictor = px,
    predictor_values = if (!is.null(px)) object$data[[px]] else seq_along(scaled),
    response = object$response,
    method = object$method,
    engine_used = used,
    nsim = nsim,
    uniformity = if (is.null(ks)) NULL else
      data.frame(statistic = unname(ks$statistic), p_value = ks$p.value,
                 test = "Kolmogorov-Smirnov against uniform",
                 stringsAsFactors = FALSE),
    checks = .simdiag_checks(scaled, if (!is.null(px)) object$data[[px]] else NULL, ks)),
    class = "agri_np_simdiag")
}

# Three questions, three tests. The overall uniformity test has little power
# against a mean that is wrong in a systematic way, because the reference
# distribution is built from the residuals themselves. The trend check has that
# power: if the fitted curve is too low at high rates, those observations sit
# high inside their own predictive distribution and the residuals drift upward
# along the gradient.
.simdiag_checks <- function(scaled, xv, ks) {
  ok <- is.finite(scaled)
  rows <- list()
  if (!is.null(ks))
    rows[[length(rows) + 1L]] <- data.frame(
      check = "uniformity",
      question = "Are the scaled residuals uniform overall?",
      statistic = unname(ks$statistic), p_value = ks$p.value,
      stringsAsFactors = FALSE)
  if (!is.null(xv) && is.numeric(xv) && sum(ok) >= 12L) {
    # Bins rather than a monotone correlation. A curve fitted with the wrong
    # shape is typically too low at the ends and too high in the middle, or the
    # reverse. That pattern is not monotone, so a rank correlation with the
    # gradient has no power against it, while a comparison across bins does.
    r <- scaled[ok]; x <- xv[ok]
    u <- sort(unique(x))
    bin <- if (length(u) <= 8L) {
      # A designed experiment applies a handful of levels, and those levels are
      # the natural bins. Quantile breaks would collide on them and fail.
      factor(x, levels = u)
    } else {
      nb <- max(3L, min(5L, floor(length(r) / 6L)))
      br <- unique(stats::quantile(x, probs = seq(0, 1, length.out = nb + 1L),
                                   names = FALSE))
      if (length(br) < 4L) factor(x, levels = u)
      else cut(x, breaks = br, include.lowest = TRUE)
    }
    if (nlevels(droplevels(bin)) >= 3L) {
      kw <- suppressWarnings(stats::kruskal.test(r, droplevels(bin)))
      rows[[length(rows) + 1L]] <- data.frame(
        check = "location along the gradient",
        question = "Is the fitted mean systematically off in some part of the range?",
        statistic = unname(kw$statistic), p_value = kw$p.value,
        stringsAsFactors = FALSE)
      kd <- suppressWarnings(stats::kruskal.test(abs(r - 0.5), droplevels(bin)))
      rows[[length(rows) + 1L]] <- data.frame(
        check = "dispersion along the gradient",
        question = "Does the spread change along the gradient?",
        statistic = unname(kd$statistic), p_value = kd$p.value,
        stringsAsFactors = FALSE)
    }
  }
  out <- do.call(rbind, rows)
  if (!is.null(out)) rownames(out) <- NULL
  out
}

#' @export
print.agri_np_simdiag <- function(x, ...) {
  cat("agriRank simulation-based residual diagnostics\n")
  cat("  Engine:", x$method, " Simulator:", x$engine_used, "\n")
  cat("  Simulations:", x$nsim, " n =", sum(is.finite(x$scaled_residuals)), "\n")
  q <- stats::quantile(x$scaled_residuals, c(0, .25, .5, .75, 1), na.rm = TRUE)
  cat("  Scaled residual quartiles:", paste(format(q, digits = 3), collapse = "  "), "\n")
  cat("  Expected under a correct model: 0.00  0.25  0.50  0.75  1.00\n\n")
  if (!is.null(x$checks)) print(x$checks, row.names = FALSE, digits = 4)
  cat("\nDescriptive. The overall uniformity check has little power against a mean\nthat is wrong in a systematic way; the location check along the gradient is\nthe one that detects it. Neither is a rule for choosing an inferential test.\n")
  invisible(x)
}

#' @export
plot.agri_np_simdiag <- function(x, type = c("uniform_qq", "residual_predictor"), ...) {
  .require_pkg("ggplot2", "regression graphics")
  type <- match.arg(type)
  r <- x$scaled_residuals
  ok <- is.finite(r)
  if (type == "uniform_qq") {
    n <- sum(ok)
    d <- data.frame(theoretical = stats::ppoints(n), sample = sort(r[ok]))
    return(ggplot2::ggplot(d, ggplot2::aes(x = theoretical, y = sample)) +
      ggplot2::geom_abline(slope = 1, intercept = 0, linetype = 2) +
      ggplot2::geom_point(size = 1.6) +
      ggplot2::labs(x = "Expected quantile under a correct model",
                    y = "Observed scaled residual",
                    caption = "Points on the dashed line indicate residuals uniform on the unit interval.") +
      .agri_theme_or_minimal())
  }
  d <- data.frame(x = x$predictor_values[ok], r = r[ok])
  ggplot2::ggplot(d, ggplot2::aes(x = x, y = r)) +
    ggplot2::geom_hline(yintercept = c(0.25, 0.5, 0.75), linetype = 3) +
    ggplot2::geom_point(size = 1.6, alpha = 0.75) +
    ggplot2::scale_y_continuous(limits = c(0, 1)) +
    ggplot2::labs(x = x$predictor %||% "Observation",
                  y = "Scaled residual",
                  caption = "A trend in the cloud, or a change in its vertical spread, indicates lack of fit along the gradient.") +
    .agri_theme_or_minimal()
}
