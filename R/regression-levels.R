# Level summaries for qualitative predictors ---------------------------------
#
# A regression coefficient of a qualitative factor is a contrast against the
# reference level. Manuscripts, however, usually report the response AT each
# level: the fitted marginal response with its uncertainty, beside the
# observed values. This file computes that summary and the plot verb draws it.

# One prediction row per level of every qualitative predictor, with all other
# covariates held at their reference values. Numeric predictors sit at their
# median; an integer-support predictor is held at the admissible support value
# closest to the median, because values between support points do not exist.
.np_level_grid <- function(object) {
  fp <- object$factor_predictors
  if (!length(fp))
    .agri_stop("This fit has no qualitative predictor. Level summaries describe the response at each level of a factor; for a numeric gradient, predict over a grid with agri_np_predict() instead.")
  vars <- unique(c(object$predictors, object$block %||% character()))
  int_pred <- if (!is.null(object$integer_support) && length(object$integer_support))
    object$integer_predictor %||% object$primary_predictor
  .ref <- function(v) {
    x <- object$data[[v]]
    if (!is.null(int_pred) && identical(v, int_pred)) {
      med <- stats::median(x, na.rm = TRUE)
      return(object$integer_support[which.min(abs(object$integer_support - med))])
    }
    .np_reference_value(x)
  }
  pieces <- lapply(fp, function(f) {
    levs <- levels(object$data[[f]])
    n <- length(levs)
    out <- as.data.frame(
      setNames(lapply(vars, function(v) rep(.ref(v), n)), vars),
      stringsAsFactors = FALSE)
    for (v in vars) {
      if (is.factor(object$data[[v]])) out[[v]] <- factor(out[[v]], levels = levels(object$data[[v]]))
    }
    out[[f]] <- factor(levs, levels = levels(object$data[[f]]))
    out$.factor <- f
    out$.level <- levs
    out
  })
  grid <- do.call(rbind, pieces)
  rownames(grid) <- NULL
  grid
}

#' Response summaries at each level of the qualitative predictors
#'
#' @description
#' Describes the response at every level of every qualitative predictor of a
#' regression fit: the number of observations, the location and spread of the
#' observed response, and the fitted marginal response with a bootstrap
#' interval, holding the other covariates at their reference values. This is
#' the level-oriented companion of the coefficient-oriented
#' `agri_np_forest()`: coefficients are contrasts against a reference level,
#' while this summary states what the model predicts at each level itself.
#'
#' @param object An `agri_np_reg_fit` with at least one qualitative predictor.
#' @param level Confidence level of the bootstrap intervals.
#' @param B Number of bootstrap replications when `bootstrap` is not supplied.
#' @param seed Reproducible seed.
#' @param bootstrap Optional `agri_np_bootstrap` object computed with
#'   `target = "curve"` on the level grid. When absent, one is computed here.
#' @param cluster Optional cluster variable passed to `agri_np_bootstrap()`;
#'   defaults to the declared agronomic block.
#' @param fixed Named values for other covariates, replacing the reference
#'   values used for the prediction.
#' @return A data frame with one row per factor level: `factor`, `level`,
#'   `n`, the observed `response_median`, `response_mad`, `response_mean` and
#'   `response_sd`, and the fitted `fit` with pointwise bootstrap `lower` and
#'   `upper` limits.
#' @examples
#' data(agri_dose)
#' dz <- agri_dose
#' dz$cultivar <- factor(rep(c("Ana", "Bela"), length.out = nrow(dz)))
#' dz$yield <- dz$yield + ifelse(dz$cultivar == "Bela", 0.9, 0)
#' if (requireNamespace("quantreg", quietly = TRUE)) {
#'   fit <- agri_np_regression(yield ~ dose + cultivar, dz, method = "quantile")
#'   # B = 19 keeps this example fast; a real analysis needs B >= 999.
#'   agri_np_levels(fit, B = 19, seed = 1)
#'   # Bela's fitted median yield sits about 0.9 Mg/ha above Ana's at the
#'   # median nitrogen rate, matching the cultivar coefficient.
#' }
#' @export
agri_np_levels <- function(object, level = 0.95, B = 499L, seed = 1,
                           bootstrap = NULL, cluster = NULL, fixed = list()) {
  cexpr <- substitute(cluster)
  cval <- tryCatch(cluster, error = function(e) NULL)
  .np_levels_impl(object, level = level, B = B, seed = seed, bootstrap = bootstrap,
                  cluster_nm = .np_resolve_cluster(object, cexpr, cval), fixed = fixed)
}

.np_levels_impl <- function(object, level = 0.95, B = 499L, seed = 1,
                            bootstrap = NULL, cluster_nm = NULL, fixed = list()) {
  if (!inherits(object, "agri_np_reg_fit")) .agri_stop("`object` must be an agri_np_reg_fit.")
  grid <- .np_level_grid(object)
  if (length(fixed)) {
    bad <- setdiff(names(fixed), names(grid))
    if (length(bad)) .agri_stop("Unknown fixed prediction variable(s): ", paste(bad, collapse = ", "))
    for (v in names(fixed)) {
      val <- fixed[[v]]
      if (is.factor(object$data[[v]])) grid[[v]] <- factor(rep(val, nrow(grid)), levels = levels(object$data[[v]]))
      else grid[[v]] <- rep(val, nrow(grid))
    }
  }
  if (is.null(bootstrap)) {
    bargs <- list(object = object, newdata = grid, B = B, level = level, seed = seed)
    if (length(cluster_nm)) bargs$cluster <- cluster_nm
    bootstrap <- do.call(agri_np_bootstrap, bargs)
  } else {
    if (!inherits(bootstrap, "agri_np_bootstrap") ||
        !identical(attr(bootstrap, "target"), "curve") ||
        !all(c(".factor", ".level") %in% names(bootstrap)))
      .agri_stop("`bootstrap` must come from agri_np_bootstrap(target = \"curve\") computed on the level grid, for example by letting agri_np_levels() compute it once and reusing the result.")
  }
  bd <- as.data.frame(bootstrap)
  key_grid <- paste(grid$.factor, grid$.level)
  key_boot <- paste(bd$.factor, bd$.level)
  m <- match(key_grid, key_boot)
  if (any(is.na(m)))
    .agri_stop("The supplied bootstrap object does not cover every factor level of this fit.")
  desc <- do.call(rbind, lapply(object$factor_predictors, function(f) {
    y <- object$data[[object$response]]
    fac <- object$data[[f]]
    levs <- levels(fac)
    data.frame(
      factor = f, level = levs,
      n = as.integer(tabulate(fac, nbins = length(levs))),
      response_median = vapply(levs, function(l) stats::median(y[fac == l], na.rm = TRUE), numeric(1)),
      response_mad = vapply(levs, function(l) stats::mad(y[fac == l], na.rm = TRUE), numeric(1)),
      response_mean = vapply(levs, function(l) mean(y[fac == l], na.rm = TRUE), numeric(1)),
      response_sd = vapply(levs, function(l) stats::sd(y[fac == l], na.rm = TRUE), numeric(1)),
      row.names = NULL, stringsAsFactors = FALSE
    )
  }))
  out <- data.frame(
    desc,
    fit = bd$fit[m], lower = bd$lower[m], upper = bd$upper[m],
    row.names = NULL, stringsAsFactors = FALSE
  )
  attr(out, "level") <- attr(bootstrap, "level") %||% level
  attr(out, "B") <- attr(bootstrap, "B") %||% B
  attr(out, "failures") <- attr(bootstrap, "failures") %||% 0L
  attr(out, "response") <- object$response
  # The bootstrap object is carried along so a figure can reuse it instead of
  # refitting the whole loop: agri_np_plot(fit, type = "levels",
  # bootstrap = attr(lv, "bootstrap")).
  attr(out, "bootstrap") <- bootstrap
  attr(out, "note") <- "fit/lower/upper are predictions at the reference values of the other covariates; intervals are pointwise bootstrap percentile limits."
  out
}

# The level summary drawn as a figure: observed values, jittered around their
# level, beneath the fitted marginal response with its bootstrap interval.
# The figure states what the model predicts AT each level, which is the
# question manuscripts usually ask; the coefficient forest plot states the
# contrast AGAINST the reference level. Both readings are legitimate and the
# package keeps them as separate figures.
.np_level_plot <- function(object, bootstrap = NULL, level = 0.95, B = 499L,
                           seed = 1, cluster = NULL, fixed = list()) {
  cexpr <- substitute(cluster)
  cval <- tryCatch(cluster, error = function(e) NULL)
  lv <- .np_levels_impl(object, level = level, B = B, seed = seed,
                        bootstrap = bootstrap,
                        cluster_nm = .np_resolve_cluster(object, cexpr, cval),
                        fixed = fixed)
  fp <- object$factor_predictors
  lv$factor <- factor(lv$factor, levels = fp)
  lab <- setNames(paste0(lv$level, " (n = ", lv$n, ")"),
                  paste(lv$factor, lv$level))
  lv$.lab <- unname(lab[paste(lv$factor, lv$level)])
  raw <- do.call(rbind, lapply(fp, function(f) {
    data.frame(factor = f, level = as.character(object$data[[f]]),
               value = object$data[[object$response]],
               stringsAsFactors = FALSE)
  }))
  raw$.lab <- unname(lab[paste(raw$factor, raw$level)])
  sub <- sprintf("Pointwise %.0f%% bootstrap | B = %s | covariates at reference values",
                 100 * (attr(lv, "level") %||% level),
                 attr(lv, "B") %||% B)
  ggplot2::ggplot(lv, ggplot2::aes(x = .lab, y = fit)) +
    ggplot2::geom_point(data = raw, ggplot2::aes(x = .lab, y = value),
                        inherit.aes = FALSE, alpha = 0.30, colour = "grey45",
                        position = ggplot2::position_jitter(width = 0.12, seed = 1)) +
    ggplot2::geom_pointrange(ggplot2::aes(ymin = lower, ymax = upper)) +
    ggplot2::facet_grid(factor ~ ., scales = "free_x", space = "free_x") +
    ggplot2::labs(x = NULL, y = object$response, subtitle = sub) +
    agri_theme()
}
