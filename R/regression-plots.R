# Plot methods for the result objects of the regression module ------------
#
# Until now these objects could only be printed. A decision expressed as a
# probability mass over admissible integers is far easier to read as a figure
# than as a table, so each of them gets a plot method.

#' @export
plot.agri_np_bootstrap <- function(x, ...) {
  d <- as.data.frame(x)
  lev <- attr(x, "level") %||% 0.95
  band <- attr(x, "band") %||% "pointwise"

  if (identical(attr(x, "target"), "coefficients")) {
    d$term <- factor(d$term, levels = rev(d$term))
    return(ggplot2::ggplot(d, ggplot2::aes(x = estimate, y = term)) +
      ggplot2::geom_vline(xintercept = 0, linetype = 2) +
      ggplot2::geom_errorbar(ggplot2::aes(xmin = lower, xmax = upper),
                             orientation = "y", width = 0.15) +
      ggplot2::geom_point(size = 2) +
      ggplot2::labs(x = sprintf("Estimate with %.0f%% bootstrap interval", 100 * lev),
                    y = NULL) +
      agri_theme())
  }

  xv <- attr(x, "predictor") %||% names(d)[1L]
  d$.x <- d[[xv]]
  ggplot2::ggplot(d, ggplot2::aes(x = .x, y = fit)) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = lower, ymax = upper), alpha = 0.2) +
    ggplot2::geom_line() +
    ggplot2::labs(x = xv, y = attr(x, "response") %||% "Fitted response",
                  subtitle = sprintf("%.0f%% %s bootstrap band, B = %s",
                                     100 * lev, band, attr(x, "B") %||% NA)) +
    agri_theme()
}

#' @export
plot.agri_integer_bootstrap <- function(x, level = NULL, ...) {
  p <- as.data.frame(x$probabilities)
  xv <- names(p)[1L]
  p$.x <- p[[xv]]
  p$.in_set <- TRUE
  sub <- sprintf("B = %d successful refits, %d failures", x$successful, x$failures)
  if (!is.null(level)) {
    cs <- agri_integer_confset(x, level = level)
    p$.in_set <- p$.x %in% cs$values
    sub <- paste0(sub, sprintf(" | %.0f%% set: {%s}", 100 * level,
                               paste(cs$values, collapse = ", ")))
  }
  ggplot2::ggplot(p, ggplot2::aes(x = .x, y = probability, alpha = .in_set)) +
    ggplot2::geom_col(width = 0.6) +
    ggplot2::scale_alpha_manual(values = c(`FALSE` = 0.30, `TRUE` = 1), guide = "none") +
    ggplot2::scale_x_continuous(breaks = p$.x) +
    ggplot2::labs(x = x$predictor, y = "Bootstrap probability of being optimal",
                  subtitle = sub) +
    agri_theme()
}

#' @export
plot.agri_integer_confset <- function(x, ...) {
  p <- as.data.frame(x$probabilities)
  xv <- names(p)[1L]
  p$.x <- p[[xv]]
  p$.in_set <- p$.x %in% x$values
  ggplot2::ggplot(p, ggplot2::aes(x = .x, y = probability, alpha = .in_set)) +
    ggplot2::geom_col(width = 0.6) +
    ggplot2::scale_alpha_manual(values = c(`FALSE` = 0.30, `TRUE` = 1), guide = "none") +
    ggplot2::scale_x_continuous(breaks = p$.x) +
    ggplot2::labs(x = x$predictor, y = "Bootstrap probability of being optimal",
                  subtitle = sprintf("%.0f%% set: {%s}, mass %.3f",
                                     100 * x$level, paste(x$values, collapse = ", "),
                                     x$probability_mass)) +
    agri_theme()
}

#' @export
plot.agri_np_compare <- function(x, ...) {
  d <- as.data.frame(x)
  metric <- attr(x, "metric") %||% names(d)[2L]
  d$method <- factor(d$method, levels = rev(d$method))
  d$.y <- d[[metric]]
  ggplot2::ggplot(d, ggplot2::aes(x = .y, y = method)) +
    ggplot2::geom_col(width = 0.6) +
    ggplot2::labs(x = paste("Cross-validated", metric), y = NULL,
                  subtitle = "Predictive error only. It does not test a hypothesis and must not be used to choose an inferential method.") +
    agri_theme()
}

#' Overlay the fitted curves of several regression engines
#'
#' @param formula Regression formula.
#' @param data Data frame.
#' @param methods Engines to overlay.
#' @param block Optional agronomic block adjustment applied to every engine.
#' @param n Grid resolution.
#' @param ... Passed to `agri_np_regression()`.
#' @export
agri_np_curves <- function(formula, data, methods = c("smoothing_spline", "loess", "gam"),
                           block = NULL, n = 200L, ...) {
  .require_pkg("ggplot2", "regression graphics")
  block_nm <- if (is.character(block)) block else NULL
  fits <- list()
  for (m in methods) {
    f <- tryCatch(agri_np_regression(formula, data, method = m, block = block_nm, ...),
                  error = function(e) NULL)
    if (!is.null(f)) fits[[m]] <- f
  }
  if (!length(fits)) .agri_stop("No requested engine could be fitted to these data.")
  pred <- lapply(names(fits), function(m) {
    f <- fits[[m]]
    g <- .np_prediction_grid(f, n = n)
    pp <- agri_np_predict(f, g)
    if (is.matrix(pp)) pp <- pp[, 1L]
    if (is.data.frame(pp)) pp <- pp[[intersect(c("fit", "fitted"), names(pp))[1L]]]
    data.frame(x = g[[f$primary_predictor]], fit = as.numeric(pp), method = m,
               stringsAsFactors = FALSE)
  })
  dd <- do.call(rbind, pred)
  f1 <- fits[[1L]]
  raw <- data.frame(x = f1$data[[f1$primary_predictor]], y = f1$data[[f1$response]])
  ggplot2::ggplot(raw, ggplot2::aes(x = x, y = y)) +
    ggplot2::geom_point(alpha = 0.55) +
    ggplot2::geom_line(data = dd, ggplot2::aes(x = x, y = fit, linetype = method,
                                               colour = method), inherit.aes = FALSE) +
    ggplot2::labs(x = f1$primary_predictor, y = f1$response,
                  linetype = "Engine", colour = "Engine",
                  subtitle = "Engines that differ by a fraction of the residual scale are not agronomically distinguishable.") +
    agri_theme()
}
