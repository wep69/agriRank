# SiZer: where is the response actually changing? -----------------------------
#
# A fitted optimum answers "where is the maximum of this particular smooth".
# It does not answer the question a grower asks, which is "from which rate on
# is there no longer evidence that yield still rises". Those differ because a
# single smooth depends on one bandwidth, and the optimum moves when the
# bandwidth moves.
#
# SiZer, Chaudhuri and Marron (1999), removes that dependence by classifying
# the sign of the derivative across a whole range of bandwidths. The reading
# that survives every reasonable amount of smoothing is the defensible one.

.sizer_states <- c("increasing", "flat", "decreasing", "sparse")

# The SiZer backend codes the map as 1 increasing, 0 possibly zero,
# -1 decreasing and 2 not enough data.
.sizer_decode <- function(z) {
  out <- rep(NA_character_, length(z))
  out[z == 1] <- "increasing"
  out[z == 0] <- "flat"
  out[z == -1] <- "decreasing"
  out[z == 2] <- "sparse"
  factor(out, levels = .sizer_states)
}

# Collapse a vector of states along x into contiguous runs, which is what a
# reader wants in a table: "from 0 to 160 the response increases".
.sizer_runs <- function(x, state) {
  keep <- !is.na(state)
  x <- x[keep]; state <- as.character(state[keep])
  if (!length(x)) return(NULL)
  r <- rle(state)
  end <- cumsum(r$lengths)
  start <- c(1L, utils::head(end, -1L) + 1L)
  data.frame(from = x[start], to = x[end], state = r$values,
             n_grid = r$lengths, stringsAsFactors = FALSE)
}

#' Significant zero crossings of the derivative
#'
#' @description
#' Classifies the slope of the fitted response as significantly increasing,
#' indistinguishable from zero, or significantly decreasing, at every position
#' of the gradient and across a range of smoothing bandwidths.
#'
#' @param object An `agri_np_reg_fit`, or a numeric vector of predictor values.
#' @param y Response values when `object` is a numeric vector.
#' @param predictor Focal numeric predictor when `object` is a fit.
#' @param bandwidths Vector of bandwidths. Chosen from the data range when `NULL`.
#' @param n_grid Number of positions along the gradient.
#' @param derivative Order of the derivative to classify, 1 or 2.
#' @param reference_bandwidth Bandwidth used for the summary table. Defaults to
#'   the geometric middle of the grid, which is the conventional reading.
#' @details
#' The map is not a model selection device. It reports, for each amount of
#' smoothing, where the data support a claim about the direction of the
#' response. A conclusion that holds over the whole column of bandwidths is
#' robust to that choice; one that appears at a single bandwidth is not.
#'
#' Bandwidths are reported on the scale of the predictor, so for a nitrogen
#' gradient they are in kg/ha and can be judged agronomically.
#' @return An object of class `agri_np_sizer` with the full map in long format,
#'   a run-length summary at the reference bandwidth, and the fraction of
#'   bandwidths supporting each state at every position.
#' @references
#' Chaudhuri, P. and Marron, J. S. (1999). SiZer for exploration of structures
#' in curves. \emph{Journal of the American Statistical Association}, 94, 807-823.
#' \doi{10.1080/01621459.1999.10474186}
#' @export
agri_np_sizer <- function(object, y = NULL, predictor = NULL, bandwidths = NULL,
                          n_grid = 41L, derivative = 1L,
                          reference_bandwidth = NULL) {
  .require_pkg("SiZer", "significant zero crossings of the derivative")
  if (inherits(object, "agri_np_reg_fit")) {
    if (!is.null(object$integer_support) && length(object$integer_support))
      .agri_stop("SiZer describes the derivative of a continuous gradient. For an integer decision support use agri_integer_difference(), which reports finite differences between admissible decisions.")
    predictor <- predictor %||% object$primary_predictor
    if (is.null(predictor)) .agri_stop("A numeric focal predictor is required for a SiZer map.")
    xv <- object$data[[predictor]]
    yv <- object$data[[object$response]]
    resp <- object$response
  } else {
    xv <- as.numeric(object)
    if (is.null(y)) .agri_stop("Supply `y` when `object` is a numeric predictor vector.")
    yv <- as.numeric(y)
    predictor <- predictor %||% "x"
    resp <- "y"
  }
  ok <- is.finite(xv) & is.finite(yv)
  xv <- xv[ok]; yv <- yv[ok]
  if (length(unique(xv)) < 5L) .agri_stop("A SiZer map needs at least five distinct predictor values.")
  derivative <- as.integer(derivative)
  if (!derivative %in% c(1L, 2L)) .agri_stop("`derivative` must be 1 or 2.")

  rng <- diff(range(xv))
  if (is.null(bandwidths)) {
    # From a window narrow enough to follow local change to one wide enough to
    # flatten the whole gradient.
    bandwidths <- exp(seq(log(rng / 25), log(rng / 2), length.out = 21L))
  }
  x_grid <- seq(min(xv), max(xv), length.out = as.integer(n_grid))
  z <- SiZer::SiZer(xv, yv, h = bandwidths, x.grid = x_grid,
                    derv = derivative, grid.length = as.integer(n_grid))

  slopes <- z$slopes
  map <- expand.grid(bandwidth = z$h.grid, x = z$x.grid,
                     KEEP.OUT.ATTRS = FALSE)
  map$state <- .sizer_decode(as.vector(t(slopes)))
  map <- map[order(map$bandwidth, map$x), ]
  rownames(map) <- NULL

  href <- reference_bandwidth %||% stats::median(z$h.grid)
  iref <- which.min(abs(z$h.grid - href))
  ref_state <- .sizer_decode(slopes[iref, ])
  runs <- .sizer_runs(z$x.grid, ref_state)
  if (!is.null(runs)) {
    runs$bandwidth <- z$h.grid[iref]
    runs <- runs[, c("from", "to", "state", "n_grid", "bandwidth")]
  }

  # How stable is each position across the bandwidth column? This is the
  # quantity that makes the reading independent of the smoothing choice.
  stab <- do.call(rbind, lapply(seq_along(z$x.grid), function(j) {
    s <- .sizer_decode(slopes[, j])
    s <- s[!is.na(s) & s != "sparse"]
    n <- length(s)
    data.frame(x = z$x.grid[j],
               p_increasing = if (n) mean(s == "increasing") else NA_real_,
               p_flat = if (n) mean(s == "flat") else NA_real_,
               p_decreasing = if (n) mean(s == "decreasing") else NA_real_,
               n_bandwidths = n)
  }))

  structure(list(map = map, summary = runs, stability = stab,
                 x_grid = z$x.grid, bandwidths = z$h.grid,
                 reference_bandwidth = z$h.grid[iref],
                 derivative = derivative, predictor = predictor,
                 response = resp, n = length(xv)),
            class = "agri_np_sizer")
}

#' @export
print.agri_np_sizer <- function(x, ...) {
  cat("agriRank SiZer map\n")
  cat("  Predictor:", x$predictor, " Response:", x$response, " n =", x$n, "\n")
  cat("  Derivative order:", x$derivative, "\n")
  cat("  Bandwidths:", length(x$bandwidths), "from",
      format(min(x$bandwidths), digits = 4), "to",
      format(max(x$bandwidths), digits = 4), "\n")
  cat("  Reference bandwidth:", format(x$reference_bandwidth, digits = 4), "\n\n")
  if (!is.null(x$summary)) {
    cat("Slope classification at the reference bandwidth:\n")
    print(x$summary, row.names = FALSE, digits = 4)
  }
  cat("\nA conclusion that holds across the whole bandwidth column is robust to\nthe amount of smoothing; one that appears at a single bandwidth is not.\n")
  invisible(x)
}

#' @export
summary.agri_np_sizer <- function(object, ...) object$summary

#' @export
plot.agri_np_sizer <- function(x, type = c("map", "stability"), ...) {
  .require_pkg("ggplot2", "regression graphics")
  type <- match.arg(type)
  if (type == "stability") {
    d <- x$stability
    dd <- rbind(
      data.frame(x = d$x, share = d$p_increasing, state = "increasing"),
      data.frame(x = d$x, share = d$p_flat, state = "flat"),
      data.frame(x = d$x, share = d$p_decreasing, state = "decreasing"))
    dd$state <- factor(dd$state, levels = c("increasing", "flat", "decreasing"))
    return(ggplot2::ggplot(dd, ggplot2::aes(x = x, y = share, linetype = state)) +
      ggplot2::geom_line(linewidth = 0.7) +
      ggplot2::scale_y_continuous(limits = c(0, 1)) +
      ggplot2::labs(x = x$predictor,
                    y = "Share of bandwidths supporting the state",
                    linetype = NULL,
                    caption = "A state supported by nearly every bandwidth does not depend on the smoothing choice.") +
      .agri_theme_or_minimal())
  }
  d <- x$map
  d <- d[!is.na(d$state), , drop = FALSE]
  ggplot2::ggplot(d, ggplot2::aes(x = x, y = bandwidth, fill = state)) +
    ggplot2::geom_raster() +
    ggplot2::scale_y_log10() +
    ggplot2::scale_fill_manual(
      values = c(increasing = "#0072B2", flat = "#F0E442",
                 decreasing = "#D55E00", sparse = "grey85"),
      drop = FALSE, na.translate = FALSE) +
    ggplot2::labs(x = x$predictor,
                  y = paste0("Bandwidth (", x$predictor, ", log scale)"),
                  fill = paste0("Derivative ", x$derivative),
                  caption = "Blue: response increases. Yellow: no evidence of change. Orange: response decreases.") +
    .agri_theme_or_minimal()
}

# The package gained a journal theme; fall back gracefully if it is absent.
.agri_theme_or_minimal <- function(base_size = 12) {
  if (exists("agri_theme", envir = asNamespace("agriRank"), inherits = FALSE))
    agri_theme(base_size = base_size) else ggplot2::theme_minimal(base_size = base_size)
}

#' Gradient interval where the response is still changing
#'
#' @description
#' Reduces a SiZer map to the agronomic statement it supports: the interval of
#' the gradient over which the response increases, and the position from which
#' there is no longer evidence of change.
#' @param object An `agri_np_sizer` object or an `agri_np_reg_fit`.
#' @param stability Minimum share of bandwidths that must agree on a state for
#'   it to be reported. The default of 0.8 keeps the reading robust to the
#'   amount of smoothing.
#' @param ... Passed to `agri_np_sizer()` when a fit is supplied.
#' @return A one-row data frame with the interval of significant increase, the
#'   interval of significant decrease, and the first position at which the
#'   response stops increasing.
#' @export
agri_np_significant_slope <- function(object, stability = 0.8, ...) {
  z <- if (inherits(object, "agri_np_sizer")) object else agri_np_sizer(object, ...)
  s <- z$stability
  inc <- s$x[!is.na(s$p_increasing) & s$p_increasing >= stability]
  dec <- s$x[!is.na(s$p_decreasing) & s$p_decreasing >= stability]
  stop_at <- if (length(inc)) {
    after <- s$x[s$x > max(inc)]
    if (length(after)) min(after) else NA_real_
  } else NA_real_
  out <- data.frame(
    predictor = z$predictor,
    stability = stability,
    increase_from = if (length(inc)) min(inc) else NA_real_,
    increase_to = if (length(inc)) max(inc) else NA_real_,
    stops_increasing_at = stop_at,
    decrease_from = if (length(dec)) min(dec) else NA_real_,
    decrease_to = if (length(dec)) max(dec) else NA_real_,
    stringsAsFactors = FALSE
  )
  attr(out, "note") <- "Positions are read from the fraction of bandwidths that agree, so the statement does not depend on a single smoothing choice."
  out
}
