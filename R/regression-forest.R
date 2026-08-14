# Coefficient forest plots ---------------------------------------------------
#
# A coefficient vector is read one term at a time: estimate, interval, and the
# zero line that separates positive from negative effects. For qualitative
# predictors the dummy coefficients are stacked one level per row inside the
# factor's own panel, and the reference level is drawn at zero, so every level
# of the factor appears in the figure instead of only the k - 1 contrasts.

# Map each factor-level dummy coefficient to the factor and level it
# represents. The mapping is read off the model matrix of each factor, which
# reproduces the backend's dummy naming instead of guessing it from labels.
.np_factor_term_map <- function(object) {
  fpred <- object$factor_predictors
  out <- data.frame(term = character(), factor = character(), level = character(),
                    is_reference = logical(), stringsAsFactors = FALSE)
  if (!length(fpred)) return(out)
  for (f in fpred) {
    x <- object$data[[f]]
    if (!is.factor(x)) next
    mm <- tryCatch(
      stats::model.matrix(~., data = stats::setNames(list(x), f)),
      error = function(e) NULL
    )
    if (is.null(mm)) next
    levs <- levels(x)
    out <- rbind(out, data.frame(term = NA_character_, factor = f, level = levs[1L],
                                 is_reference = TRUE, stringsAsFactors = FALSE))
    cn <- colnames(mm)
    for (j in seq_along(cn)[-1L]) {
      # Under treatment contrasts a dummy column is active in exactly one
      # level; if the contrasts ever differ, fall back to the term name
      # instead of inventing a level.
      lev <- unique(as.character(x[mm[, j] != 0]))
      out <- rbind(out, data.frame(term = cn[j], factor = f,
                                   level = if (length(lev) == 1L) lev else cn[j],
                                   is_reference = FALSE, stringsAsFactors = FALSE))
    }
  }
  out
}

#' Forest plot of bootstrap intervals for regression coefficients
#'
#' @description
#' Draws one row per regression coefficient with its bootstrap confidence
#' interval around the zero line, for the engines that define interpretable
#' coefficients (`theil_sen`, `siegel`, `quantile`). When the model contains
#' qualitative predictors, `by_factor` stacks the coefficients of each factor
#' one level per row inside the factor's own panel and draws the reference
#' level at zero, so every level of the factor appears in the figure instead
#' of only the k - 1 dummy contrasts. Block adjustment terms never enter the
#' figure: they are nuisance parameters excluded from the coefficient
#' bootstrap target.
#'
#' @param object An `agri_np_reg_fit` whose engine defines interpretable
#'   coefficients.
#' @param bootstrap Optional `agri_np_bootstrap` object computed with
#'   `target = "coefficients"`. When absent, one is computed here.
#' @param B Number of bootstrap replications when `bootstrap` is not supplied.
#' @param level Confidence level.
#' @param seed Reproducible seed.
#' @param cluster Optional cluster variable passed to `agri_np_bootstrap()`;
#'   defaults to the declared agronomic block.
#' @param by_factor Stack the coefficients of qualitative predictors one row
#'   per level, grouped by factor, with the reference level drawn at zero.
#' @param include_intercept Keep the intercept in the figure. By default it is
#'   excluded: it is a location parameter reported by the coefficient table,
#'   and on the figure's axis it would dominate slopes and contrasts.
#' @return A ggplot object.
#' @examples
#' data(agri_dose)
#' dz <- agri_dose
#' # A qualitative companion for the nitrogen gradient: two cultivars that
#' # share the dose response but differ in baseline yield (Mg/ha).
#' dz$cultivar <- factor(rep(c("Ana", "Bela"), length.out = nrow(dz)))
#' dz$yield <- dz$yield + ifelse(dz$cultivar == "Bela", 0.9, 0)
#' if (requireNamespace("quantreg", quietly = TRUE)) {
#'   fit <- agri_np_regression(yield ~ dose + cultivar, dz, method = "quantile")
#'   coef(fit)
#'   # B = 19 keeps this example fast; a real analysis needs B >= 999.
#'   bt <- agri_np_bootstrap(fit, target = "coefficients", B = 19, seed = 1)
#'   agri_np_forest(fit, bootstrap = bt)
#'   # Cultivar Bela shifts the whole dose-response curve upward by about
#'   # 0.9 Mg/ha; reading its interval against the zero line is the point
#'   # of the figure.
#' }
#' @export
agri_np_forest <- function(object, bootstrap = NULL, B = 499L, level = 0.95, seed = 1,
                           cluster = NULL, by_factor = TRUE, include_intercept = FALSE,
                           palette = c("color", "grey"),
                           annotate_values = FALSE, digits = 2,
                           order_by = c("model", "effect"), ref_line = 0,
                           caption = "Reference level drawn at zero; intervals show where the zero line is excluded.") {
  if (!inherits(object, "agri_np_reg_fit")) .agri_stop("`object` must be an agri_np_reg_fit.")
  palette <- match.arg(palette)
  order_by <- match.arg(order_by)
  forest_colors <- switch(palette,
    color = c(`FALSE` = "#0072B2", `TRUE` = "grey55"),
    grey  = c(`FALSE` = "grey25", `TRUE` = "grey55"))
  if (is.null(bootstrap)) {
    cexpr <- substitute(cluster)
    cval <- tryCatch(cluster, error = function(e) NULL)
    cluster_nm <- .np_resolve_cluster(object, cexpr, cval)
    bargs <- list(object = object, target = "coefficients", B = B,
                  level = level, seed = seed)
    if (length(cluster_nm)) bargs$cluster <- cluster_nm
    bootstrap <- do.call(agri_np_bootstrap, bargs)
  } else if (!inherits(bootstrap, "agri_np_bootstrap") ||
             !identical(attr(bootstrap, "target"), "coefficients")) {
    .agri_stop("`bootstrap` must come from agri_np_bootstrap() with target = \"coefficients\".")
  }
  lev <- attr(bootstrap, "level") %||% level
  d <- as.data.frame(bootstrap)
  map <- .np_factor_term_map(object)
  d$panel <- "Coefficients"
  d$label <- d$term
  d$is_reference <- FALSE
  if (isTRUE(by_factor) && nrow(map)) {
    m <- match(d$term, map$term)
    hit <- !is.na(m)
    if (any(hit)) {
      d$panel[hit] <- map$factor[m[hit]]
      d$label[hit] <- map$level[m[hit]]
      refs <- map[map$is_reference, , drop = FALSE]
      d <- rbind(
        d,
        data.frame(term = paste0(refs$factor, ":", refs$level),
                   estimate = 0, lower = 0, upper = 0,
                   panel = refs$factor, label = refs$level,
                   is_reference = TRUE, stringsAsFactors = FALSE)
      )
      d$panel <- factor(d$panel, levels = c("Coefficients", unique(map$factor)))
    }
  }
  if (is.character(d$panel)) d$panel <- factor(d$panel)
  # The intercept is a location parameter: it belongs in the coefficient
  # table, and on a shared axis it would crush the slopes and contrasts the
  # figure exists to show. Keep it on request.
  if (!isTRUE(include_intercept))
    d <- d[!(d$term == "(Intercept)" & !d$is_reference), , drop = FALSE]
  # Row order: the model order preserves the term structure; effect order
  # places the largest absolute effect at the top of each panel.
  if (identical(order_by, "effect")) {
    ord <- unlist(lapply(levels(d$panel), function(pn) {
      rows <- which(d$panel == pn)
      if (length(rows) <= 1L) return(rows)
      vals <- abs(d$estimate[rows])
      rows[order(vals, decreasing = TRUE)]
    }))
    d <- d[ord, , drop = FALSE]
  } else if (nlevels(d$panel) > 1L) {
    ord <- integer()
    for (pn in levels(d$panel)) {
      rows <- which(d$panel == pn)
      if (pn == "Coefficients") { ord <- c(ord, rows); next }
      wanted <- c(map$level[map$factor == pn & map$is_reference],
                  map$level[map$factor == pn & !map$is_reference])
      ord <- c(ord, rows[order(match(d$label[rows], wanted))])
    }
    d <- d[ord, , drop = FALSE]
  }
  d$.y <- factor(seq_len(nrow(d)), levels = rev(seq_len(nrow(d))))
  # Annotation text: estimate and interval to the right of each bar, the form
  # journals expect when a figure must carry its own numerical information.
  d$.annot <- NA_character_
  if (isTRUE(annotate_values)) {
    nn <- !d$is_reference
    d$.annot[nn] <- sprintf(
      paste0("%.", digits, "f [%.", digits, "f; %.", digits, "f]"),
      d$estimate[nn], d$lower[nn], d$upper[nn])
  }
  sub <- sprintf("%s | %.0f%% bootstrap | B = %s", object$method, 100 * lev,
                 attr(bootstrap, "B") %||% B)
  p <- ggplot2::ggplot(d, ggplot2::aes(x = estimate, y = .y)) +
    ggplot2::geom_vline(xintercept = ref_line, linetype = 2) +
    ggplot2::geom_errorbar(ggplot2::aes(xmin = lower, xmax = upper),
                           orientation = "y", width = 0.15) +
    ggplot2::geom_point(ggplot2::aes(shape = is_reference, colour = is_reference), size = 2.2) +
    ggplot2::scale_shape_manual(
      values = c(`FALSE` = 16, `TRUE` = 18),
      labels = c(`FALSE` = "Coefficient", `TRUE` = "Reference level"),
      name = NULL) +
    ggplot2::scale_colour_manual(
      values = forest_colors,
      labels = c(`FALSE` = "Coefficient", `TRUE` = "Reference level"),
      name = NULL) +
    ggplot2::scale_y_discrete(labels = stats::setNames(as.character(d$label),
                                                       as.character(seq_len(nrow(d))))) +
    ggplot2::scale_x_continuous(labels = function(x) format(x, digits = digits),
                                n.breaks = 3) +
    ggplot2::labs(x = "Coefficient value", y = NULL, subtitle = sub, caption = caption) +
    agri_theme()
  # Each panel carries its own axes: an intercept, a slope per kg/ha and a
  # cultivar contrast live on different scales, and a single shared axis would
  # leave only the largest of them readable.
  if (nlevels(d$panel) > 1L)
    p <- p + ggplot2::facet_wrap(~ panel, ncol = 1, scales = "free")
  # Annotations: write the interval to the right of each bar so the figure is
  # self-contained and does not require the reader to cross-reference a table.
  if (isTRUE(annotate_values) && any(!is.na(d$.annot))) {
    p <- p + ggplot2::coord_cartesian(clip = "off") +
      ggplot2::geom_text(
        data = d[!is.na(d$.annot), , drop = FALSE],
        ggplot2::aes(x = upper, label = .annot),
        hjust = -0.05, size = ggplot2::rel(2.8), colour = "grey20") +
      ggplot2::theme(plot.margin = ggplot2::margin(5.5, 60, 5.5, 5.5))
  }
  p
}
