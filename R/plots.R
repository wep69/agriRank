# Visualization ------------------------------------------------------------

#' ggplot2 visualization for agriRank objects
#' @export
agri_plot <- function(x, type = c("data", "effects", "interaction", "missing", "contrasts"), ...) {
  type <- match.arg(type)
  if (inherits(x, "agri_design")) {
    design <- x; fit <- NULL
  } else if (inherits(x, "agri_rank_fit")) {
    design <- x$design; fit <- x
  } else .agri_stop("agri_design or agri_rank_fit required.")
  dat <- design$data; y <- if (is.null(fit)) design$response[1L] else fit$response

  if (type == "data") {
    cell <- .interaction_key(dat, design$predictors)
    dd <- data.frame(.cell = cell, .y = dat[[y]])
    return(ggplot2::ggplot(dd, ggplot2::aes(x = .cell, y = .y)) +
      ggplot2::geom_violin(trim = FALSE, na.rm = TRUE) +
      ggplot2::geom_boxplot(width = 0.18, outlier.shape = NA, na.rm = TRUE) +
      ggplot2::geom_jitter(width = 0.08, height = 0, alpha = 0.65, na.rm = TRUE) +
      ggplot2::labs(x = paste(design$predictors, collapse = " \u00d7 "), y = y) +
      ggplot2::theme_minimal())
  }
  if (type == "effects") {
    ef <- agri_effects(fit)
    if ("relative_marginal_effect" %in% names(ef)) {
      ef$.label <- apply(ef[intersect(names(ef), design$predictors)], 1L, paste, collapse = " \u00d7 ")
      return(ggplot2::ggplot(ef, ggplot2::aes(x = .label, y = relative_marginal_effect)) + ggplot2::geom_point() +
        ggplot2::geom_hline(yintercept = 0.5, linetype = 2) + ggplot2::labs(x = NULL, y = "Relative marginal effect") + ggplot2::theme_minimal())
    }
    return(ggplot2::ggplot(ef, ggplot2::aes(x = cell, y = median)) + ggplot2::geom_point() + ggplot2::labs(x = NULL, y = paste("Median", y)) + ggplot2::theme_minimal())
  }
  if (type == "interaction") {
    if (length(design$predictors) < 2L) .agri_stop("Interaction plot requires at least two factors.")
    a <- design$predictors[1L]; b <- design$predictors[2L]
    dd <- aggregate(dat[[y]], dat[c(a,b)], stats::median, na.rm = TRUE); names(dd)[ncol(dd)] <- ".median"
    # aes_string() was deprecated in ggplot2 3.0.0. The factor names are known
    # only at run time, so the two factors are renamed to fixed internal columns
    # and the original names are restored in the labels. This keeps the plot
    # free of any additional dependency.
    names(dd)[match(c(a, b), names(dd))] <- c(".a", ".b")
    return(ggplot2::ggplot(dd, ggplot2::aes(x = .b, y = .median, group = .a, shape = .a)) +
             ggplot2::geom_point() + ggplot2::geom_line() +
             ggplot2::labs(x = b, y = paste("Median", y), shape = a) +
             ggplot2::theme_minimal())
  }
  if (type == "missing") {
    mr <- agri_missing_report(design, response = y)
    if (is.null(mr$repeated)) {
      dd <- data.frame(status = c("Observed", "Missing"), n = c(mr$n_rows - mr$n_missing, mr$n_missing))
      return(ggplot2::ggplot(dd, ggplot2::aes(x = status, y = n)) + ggplot2::geom_col() + ggplot2::theme_minimal())
    }
    dd <- data.frame(occasion = names(mr$repeated$missing_rate_by_occasion), missing_rate = as.numeric(mr$repeated$missing_rate_by_occasion))
    return(ggplot2::ggplot(dd, ggplot2::aes(x = occasion, y = missing_rate)) + ggplot2::geom_col() + ggplot2::labs(y = "Missing proportion") + ggplot2::theme_minimal())
  }
  if (type == "contrasts") {
    pr <- agri_pairs(fit, ...)
    if (!all(c("estimate", "lower", "upper") %in% names(pr))) .agri_stop("This fit does not expose interval contrasts through agri_pairs().")
    return(ggplot2::ggplot(pr, ggplot2::aes(x = estimate, y = contrast)) + ggplot2::geom_point() +
      ggplot2::geom_errorbarh(ggplot2::aes(xmin = lower, xmax = upper), height = 0.15) + ggplot2::geom_vline(xintercept = 0, linetype = 2) + ggplot2::theme_minimal())
  }
}

#' @export
plot.agri_rank_fit <- function(x, ...) agri_plot(x, ...)

#' Convert a ggplot from agriRank to Plotly
#' @export
agri_interactive <- function(x, type = "data", ...) {
  .require_pkg("plotly", "interactive graphics")
  plotly::ggplotly(agri_plot(x, type = type, ...))
}
