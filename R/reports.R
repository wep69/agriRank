# Tables and reports -------------------------------------------------------

#' Format a coefficient and its confidence interval for manuscript text
#'
#' @description
#' Returns a plain-text string of the form `"1.06 (0.68; 1.47)"` that can be
#' copied directly into a manuscript sentence. This avoids the manual formatting
#' of every reported coefficient and its interval.
#' @param estimate Numeric estimate.
#' @param lower Lower bound of the interval.
#' @param upper Upper bound of the interval.
#' @param digits Significant digits for the estimate and bounds.
#' @param sep Separator between lower and upper.
#' @return A character string.
#' @examples
#' agri_format_ci(1.056, 0.678, 1.465)
#' agri_format_ci(0.0077, 0.0053, 0.0101, digits = 3)
#' @export
agri_format_ci <- function(estimate, lower, upper, digits = 2, sep = "; ") {
  est <- format(estimate, digits = digits)
  lo <- format(lower, digits = digits)
  hi <- format(upper, digits = digits)
  paste0(est, " (", lo, sep, hi, ")")
}

#' Standardized analysis tables
#' @export
agri_table <- function(x, what = c("omnibus", "effects", "pairs", "missing",
                                   "metrics", "coefficients", "levels",
                                   "predictions", "derivative", "optimum",
                                   "integer_predictions", "integer_optimum", "integer_efficiency"),
                       ..., format = c("auto", "data.frame", "gt", "rtf")) {
  what_missing <- missing(what)
  if (inherits(x, "agri_np_reg_fit")) {
    if (what_missing) what <- "metrics" else what <- match.arg(what)
    tab <- switch(what,
      metrics = x$metrics,
      # Coefficients are reported with their interval, because an estimate
      # without uncertainty invites an exactness the model does not have.
      coefficients = stats::confint(x, ...),
      levels = agri_np_levels(x, ...),
      predictions = {
        p <- agri_np_predict(x)
        if (is.matrix(p)) p <- p[, 1L]
        data.frame(observed = x$data[[x$response]], fitted = as.numeric(p), residual = x$data[[x$response]] - as.numeric(p))
      },
      derivative = agri_np_derivative(x, ...),
      optimum = agri_np_optimum(x, ...),
      integer_predictions = agri_integer_predict(x, ...),
      integer_optimum = agri_integer_optimum(x, ...)$optima,
      integer_efficiency = agri_integer_efficiency(x, ...),
      .agri_stop("For regression fits, choose metrics, coefficients, levels, predictions, derivative, optimum, integer_predictions, integer_optimum, or integer_efficiency.")
    )
  } else if (inherits(x, "agri_multivariate_fit")) {
    tab <- x$omnibus %||% data.frame()
  } else if (inherits(x, "agri_ancova_fit")) {
    tab <- x$omnibus %||% data.frame()
  } else if (inherits(x, "agri_trend")) {
    tab <- data.frame(treatment = x$treatment, statistic = x$statistic, p_value = x$p_value, B = x$B, method = x$method)
  } else if (inherits(x, "agri_power")) {
    tab <- data.frame(power = x$power, mc_se = x$mc_se, nsim_requested = x$nsim_requested, nsim_success = x$nsim_success, alpha = x$alpha)
  } else if (inherits(x, "agri_batch")) {
    tab <- x$summary
  } else if (inherits(x, "agri_sensitivity")) {
    tab <- x$table
  } else if (inherits(x, "agri_missing_report")) {
    tab <- data.frame(response = x$response, n_rows = x$n_rows, n_missing = x$n_missing,
                      missing_rate = x$missing_rate,
                      complete_subjects = x$repeated$complete_subjects %||% NA_integer_,
                      incomplete_subjects = x$repeated$incomplete_subjects %||% NA_integer_)
  } else {
    if (!inherits(x, "agri_rank_fit")) .agri_stop("Unsupported object. Use an agri_rank_fit, agri_np_reg_fit, agri_multivariate_fit, agri_ancova_fit, agri_trend, agri_power, agri_batch, agri_sensitivity, or agri_missing_report object.")
    what <- match.arg(what)
    tab <- switch(what,
      omnibus = x$omnibus,
      effects = agri_effects(x, ...),
      pairs = agri_pairs(x, ...),
      missing = {
        m <- x$missing; data.frame(response = m$response, n_rows = m$n_rows, n_missing = m$n_missing, missing_rate = m$missing_rate)
      },
      .agri_stop("For experimental-design fits, `what` must be one of omnibus, effects, pairs, or missing.")
    )
  }
  # A manuscript table must stay editable, so a plain data frame is always
  # reachable with format = "data.frame"; gt is the default presentation only
  # when it is installed. RTF can be written to a file for direct import into
  # Word or LibreOffice.
  format <- match.arg(format)
  if (identical(format, "data.frame")) return(as.data.frame(tab))
  if (requireNamespace("gt", quietly = TRUE)) {
    gt_tbl <- gt::gt(as.data.frame(tab))
    if (identical(format, "rtf")) {
      rtf_file <- attr(tab, "rtf_file") %||% tempfile(fileext = ".rtf")
      gt::gtsave(gt_tbl, rtf_file)
      return(invisible(rtf_file))
    }
    return(gt_tbl)
  }
  if (identical(format, "gt") || identical(format, "rtf"))
    .agri_warn("Package `gt` is not installed; returning a plain data frame.")
  tab
}

.write_report_md <- function(x, file, language = c("en", "pt")) {
  language <- match.arg(language)
  s <- design_summary(x$design)
  om <- capture.output(print(x$omnibus))
  mr <- x$missing
  if (language == "pt") {
    txt <- c("# Relat\u00f3rio agriRank", "", "## Delineamento experimental",
             sprintf("- Delineamento: %s", s$design), sprintf("- Resposta: %s", x$response),
             sprintf("- Fatores: %s", paste(s$treatments, collapse = " \u00d7 ")),
             sprintf("- Estrutura de randomiza\u00e7\u00e3o: %s", s$randomization), "",
             "## Dados ausentes", sprintf("- Observa\u00e7\u00f5es ausentes na resposta: %d (%.2f%%)", mr$n_missing, 100*mr$missing_rate),
             "- O mecanismo de aus\u00eancia n\u00e3o \u00e9 infer\u00edvel apenas dos dados observados; a suposi\u00e7\u00e3o utilizada deve ser declarada.", "",
             "## M\u00e9todo", sprintf("- %s", x$engine$method %||% x$method), "", "## Infer\u00eancia omnibus", "```", om, "```", "",
             "## Reprodutibilidade", sprintf("- Seed: %s", x$seed), sprintf("- R: %s", R.version.string))
  } else {
    txt <- c("# agriRank report", "", "## Experimental design",
             sprintf("- Design: %s", s$design), sprintf("- Response: %s", x$response),
             sprintf("- Factors: %s", paste(s$treatments, collapse = " \u00d7 ")),
             sprintf("- Randomization structure: %s", s$randomization), "",
             "## Missing data", sprintf("- Missing response observations: %d (%.2f%%)", mr$n_missing, 100*mr$missing_rate),
             "- The missingness mechanism cannot be inferred from observed data alone; the analysis assumption must be stated.", "",
             "## Method", sprintf("- %s", x$engine$method %||% x$method), "", "## Omnibus inference", "```", om, "```", "",
             "## Reproducibility", sprintf("- Seed: %s", x$seed), sprintf("- R: %s", R.version.string))
  }
  writeLines(txt, file, useBytes = TRUE)
  normalizePath(file, winslash = "/", mustWork = FALSE)
}

.write_regression_report_md <- function(x, file, language = c("en", "pt")) {
  language <- match.arg(language)
  if (language != "en") .agri_warn("Regression reports are currently generated in English to keep the new module documentation consistent.")
  met <- capture.output(print(x$metrics, row.names = FALSE))
  block_txt <- if (length(x$block)) paste(x$block, collapse = ", ") else "none"
  fam <- x$family$family %||% "not applicable"
  shape <- x$shape %||% "none"

  # Coefficient table — every estimate reported carries its uncertainty.
  coeff_txt <- tryCatch({
    ci <- suppressWarnings(stats::confint(x, method = "bootstrap", B = 199L, seed = 1L))
    capture.output(print(ci, row.names = FALSE))
  }, error = function(e) c("(coefficients unavailable for this engine)"))

  # Factor structure and level summaries.
  fp <- x$factor_predictors %||% character()
  factor_txt <- NULL
  level_txt <- NULL
  if (length(fp)) {
    factor_txt <- c("", "## Qualitative predictors",
      sprintf("- Qualitative predictors: %s", paste(fp, collapse = ", ")),
      sprintf("- Levels: %s", paste(vapply(fp, function(f) sprintf("%s (%d levels)", f, nlevels(x$data[[f]])), character(1)), collapse = "; ")))
    level_txt <- tryCatch({
      lv <- suppressWarnings(agri_np_levels(x, B = 199L, seed = 1L))
      c("", "## Response at each level", "```",
        capture.output(print(lv, row.names = FALSE)), "```")
    }, error = function(e) NULL)
  }

  # Figures — one fit plot, one forest plot (when coefficients exist) and one
  # level plot (when factors exist). The image files are written alongside
  # the report and referenced by relative path.
  fig_dir <- file.path(dirname(file), "figures")
  dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)
  fig_lines <- NULL
  has_coef <- x$method %in% c("theil_sen", "siegel", "quantile")
  tryCatch({
    p_fit <- agri_np_plot(x, type = "fit")
    fit_path <- file.path(fig_dir, "fit_curve.png")
    ggplot2::ggsave(fit_path, p_fit, width = 12, height = 8, units = "cm", dpi = 300)
    fig_lines <- c(fig_lines, "", "## Figures",
                   sprintf("![Fitted curve](figures/%s)", basename(fit_path)))
  }, error = function(e) NULL)
  if (has_coef) {
    tryCatch({
      bt <- suppressWarnings(agri_np_bootstrap(x, target = "coefficients", B = 199L, seed = 1L))
      p_forest <- agri_np_forest(x, bootstrap = bt)
      forest_path <- file.path(fig_dir, "forest_plot.png")
      ggplot2::ggsave(forest_path, p_forest, width = 12, height = 8, units = "cm", dpi = 300)
      fig_lines <- c(fig_lines, sprintf("![Coefficient forest plot](figures/%s)", basename(forest_path)))
    }, error = function(e) NULL)
  }
  if (length(fp)) {
    tryCatch({
      p_levels <- agri_np_plot(x, type = "levels", B = 199L, seed = 1L)
      levels_path <- file.path(fig_dir, "level_plot.png")
      ggplot2::ggsave(levels_path, p_levels, width = 12, height = 8, units = "cm", dpi = 300)
      fig_lines <- c(fig_lines, sprintf("![Response at each level](figures/%s)", basename(levels_path)))
    }, error = function(e) NULL)
  }

  txt <- c(
    "# agriRank nonparametric regression report", "",
    "## Scientific model",
    sprintf("- Response: %s", x$response),
    sprintf("- Predictors: %s", paste(x$predictors, collapse = ", ")),
    sprintf("- Fitted formula: `%s`", paste(deparse(x$formula_used), collapse = " ")),
    sprintf("- Method: %s", x$method),
    sprintf("- Response family: %s", fam),
    sprintf("- Shape constraint: %s", shape),
    sprintf("- Agronomic block adjustment: %s", block_txt),
    if (!is.null(x$integer_support) && length(x$integer_support))
      sprintf("- Integer decision support (%s): {%s}", x$predictor_support, paste(x$integer_support, collapse = ", "))
    else "- Decision support: continuous",
    sprintf("- Input rows: %d", x$n_original %||% nrow(x$data)),
    sprintf("- Explicitly omitted incomplete rows: %d", x$n_omitted %||% 0L),
    sprintf("- Missing-data action: %s", x$na_action %||% "fail"), "",
    "## Predictive diagnostics", "```", met, "```", "",
    "## Coefficients with confidence intervals", "```", coeff_txt, "```", "",
    factor_txt,
    level_txt,
    fig_lines,
    "## Interpretation boundary",
    "- Cross-validation and residual diagnostics evaluate predictive behavior; they do not select a confirmatory method by the smallest p-value.",
    "- A fitted maximum/minimum is descriptive unless an economic or mechanistic objective was specified independently.",
    "- Integer-support fits never convert a continuous optimum to a decision by rounding; decisions are evaluated directly on the admissible lattice.",
    "- Shape constraints should be scientifically justified before examining the fitted response.", "",
    "## Reproducibility",
    sprintf("- R: %s", R.version.string),
    sprintf("- agriRank regression method: %s", x$method),
    sprintf("- Backend class: %s", paste(class(x$engine), collapse = ", ")),
    "",
    "## How to cite",
    "```r",
    "citation(\"agriRank\")",
    "```",
    "Use the output above in your reference list. Include the R version and the package version (`packageVersion(\"agriRank\")`) in the methods section of your manuscript."
  )
  writeLines(txt, file, useBytes = TRUE)
  normalizePath(file, winslash = "/", mustWork = FALSE)
}

.write_aux_report_md <- function(x, file, language = c("en", "pt")) {
  language <- match.arg(language)
  if (language != "en") .agri_warn("This analysis report is currently generated in English.")
  if (inherits(x, "agri_multivariate_fit")) {
    om <- capture.output(print(x$omnibus))
    txt <- c("# agriRank multivariate report", "", "## Design and responses",
             sprintf("- Mode: %s", x$mode), sprintf("- Responses: %s", paste(x$responses, collapse = ", ")),
             sprintf("- Predictors: %s", paste(x$predictors, collapse = ", ")),
             sprintf("- Block adjustment: %s", if (length(x$block)) paste(x$block, collapse = ", ") else "none"), "",
             "## Method", sprintf("- %s", x$method), "", "## Omnibus inference", "```", om, "```", "",
             "## Reproducibility", sprintf("- Seed: %s", x$seed), sprintf("- R: %s", R.version.string))
  } else if (inherits(x, "agri_ancova_fit")) {
    om <- capture.output(print(x$omnibus))
    txt <- c("# agriRank ANCOVA report", "", sprintf("- Method: %s", x$method),
             sprintf("- Covariates: %s", paste(x$covariates, collapse = ", ")),
             sprintf("- Block adjustment: %s", if (length(x$block)) paste(x$block, collapse = ", ") else "none"), "",
             "## Omnibus inference", "```", om, "```", "", "## Reproducibility", sprintf("- Seed: %s", x$seed))
  } else if (inherits(x, "agri_trend")) {
    txt <- c("# agriRank ordered-treatment trend report", "", sprintf("- Treatment: %s", x$treatment),
             sprintf("- Statistic: %.6g", x$statistic), sprintf("- p-value: %.6g", x$p_value),
             sprintf("- Permutations: %s", x$B), sprintf("- Randomization note: %s", x$note))
  } else if (inherits(x, "agri_power")) {
    txt <- c("# agriRank simulation-based power report", "", sprintf("- Estimated power: %.6f", x$power),
             sprintf("- Monte Carlo SE: %.6f", x$mc_se), sprintf("- Successful simulations: %d / %d", x$nsim_success, x$nsim_requested),
             sprintf("- Alpha: %.4f", x$alpha), sprintf("- Seed: %s", x$seed))
  } else if (inherits(x, "agri_batch")) {
    tb <- capture.output(print(x$summary, row.names = FALSE))
    txt <- c("# agriRank batch-analysis report", "", sprintf("- Across-response adjustment: %s", x$adjust_across),
             "", "## Response-level summary", "```", tb, "```", "",
             "## Interpretation boundary", "- Batch fitting does not justify method shopping across responses. Across-response multiplicity control is explicit and optional.")
  } else if (inherits(x, "agri_sensitivity")) {
    tb <- capture.output(print(x$table, row.names = FALSE))
    txt <- c("# agriRank inferential-sensitivity report", "", "## Cross-method comparison", "```", tb, "```", "",
             "## Interpretation boundary", sprintf("- %s", x$interpretation))
  } else if (inherits(x, "agri_missing_report")) {
    txt <- c("# agriRank missing-data characterization", "", sprintf("- Response: %s", x$response),
             sprintf("- Rows: %d", x$n_rows), sprintf("- Missing responses: %d (%.2f%%)", x$n_missing, 100*x$missing_rate),
             if (!is.null(x$repeated)) sprintf("- Complete subjects: %d", x$repeated$complete_subjects) else NULL,
             if (!is.null(x$repeated)) sprintf("- Incomplete subjects: %d", x$repeated$incomplete_subjects) else NULL,
             "", "## Assumption boundary", sprintf("- %s", x$assumption_note))
  } else .agri_stop("Unsupported auxiliary report class.")
  writeLines(txt, file, useBytes = TRUE)
  normalizePath(file, winslash = "/", mustWork = FALSE)
}

#' Generate a reproducible report
#' @export
agri_report <- function(x, file = NULL, format = c("md", "qmd", "html", "docx", "pdf"), language = c("en", "pt"), ...) {
  if (!inherits(x, c("agri_rank_fit", "agri_np_reg_fit", "agri_multivariate_fit", "agri_ancova_fit", "agri_trend", "agri_power", "agri_batch", "agri_sensitivity", "agri_missing_report")))
    .agri_stop("Unsupported agriRank result class for reporting.")
  format <- match.arg(format); language <- match.arg(language)
  if (is.null(file)) file <- tempfile("agriRank-report-", fileext = if (format == "qmd") ".qmd" else ".md")
  md <- if (inherits(x, "agri_np_reg_fit")) {
    .write_regression_report_md(x, file, language)
  } else if (inherits(x, "agri_rank_fit")) {
    .write_report_md(x, file, language)
  } else {
    .write_aux_report_md(x, file, language)
  }
  if (format %in% c("md", "qmd")) return(md)
  if (requireNamespace("rmarkdown", quietly = TRUE) && rmarkdown::pandoc_available()) {
    out <- sub("\\.md$", paste0(".", format), md)
    rmarkdown::render(md, output_format = switch(format, html = "html_document", docx = "word_document", pdf = "pdf_document"), output_file = basename(out), output_dir = dirname(out), quiet = TRUE)
    return(normalizePath(out, winslash = "/", mustWork = FALSE))
  }
  .agri_stop("Rendering to html/docx/pdf requires rmarkdown and Pandoc. The Markdown report was written to: ", md)
}

#' Generate a self-contained dashboard source
#' @export
agri_dashboard <- function(x, file = tempfile("agriRank-dashboard-", fileext = ".qmd"), language = "en") {
  md <- agri_report(x, file = sub("\\.qmd$", ".md", file), format = "md", language = language)
  body <- readLines(md, warn = FALSE)
  ttl <- if (inherits(x, "agri_np_reg_fit")) {
    "agriRank Regression Dashboard"
  } else if (inherits(x, "agri_multivariate_fit")) {
    "agriRank Multivariate Dashboard"
  } else if (inherits(x, "agri_batch")) {
    "agriRank Batch Analysis Dashboard"
  } else if (inherits(x, "agri_sensitivity")) {
    "agriRank Sensitivity Dashboard"
  } else if (inherits(x, "agri_missing_report")) {
    "agriRank Missing-Data Dashboard"
  } else {
    "agriRank Dashboard"
  }
  yaml <- c("---", sprintf("title: \"%s\"", ttl), "format:", "  html:", "    toc: true", "    embed-resources: true", "---", "")
  writeLines(c(yaml, body), file)
  normalizePath(file, winslash = "/", mustWork = FALSE)
}

#' Export core fit components to an RDS bundle
#' @export
export_results <- function(x, file = "agriRank-results.rds") {
  if (inherits(x, "agri_np_reg_fit")) {
    obj <- list(
      domain = "nonparametric_regression",
      formula = x$formula,
      formula_used = x$formula_used,
      response = x$response,
      predictors = x$predictors,
      block = x$block,
      method = x$method,
      shape = x$shape,
      tau = x$tau,
      n_original = x$n_original,
      n_omitted = x$n_omitted,
      na_action = x$na_action,
      predictor_support = x$predictor_support,
      integer_predictor = x$integer_predictor,
      integer_support = x$integer_support,
      base_method = x$base_method,
      metrics = x$metrics,
      fitted = x$fitted,
      residuals = x$residuals,
      backend_class = class(x$engine),
      session = utils::sessionInfo()
    )
  } else if (inherits(x, "agri_multivariate_fit")) {
    obj <- list(domain = "multivariate", design = design_summary(x$design), formula = x$formula,
                responses = x$responses, predictors = x$predictors, method = x$method, mode = x$mode,
                omnibus = x$omnibus, descriptive = x$descriptive, covariance = x$covariance, seed = x$seed,
                backend_class = class(x$engine), session = utils::sessionInfo())
  } else if (inherits(x, "agri_ancova_fit")) {
    obj <- list(domain = "ancova", method = x$method, formula = x$formula, covariates = x$covariates,
                block = x$block, omnibus = x$omnibus, seed = x$seed, session = utils::sessionInfo())
  } else if (inherits(x, "agri_trend")) {
    obj <- c(unclass(x), list(session = utils::sessionInfo()))
  } else if (inherits(x, "agri_power")) {
    obj <- c(unclass(x), list(session = utils::sessionInfo()))
  } else if (inherits(x, "agri_batch")) {
    obj <- list(domain = "batch", design = design_summary(x$design), summary = x$summary,
                adjust_across = x$adjust_across, session = utils::sessionInfo())
  } else if (inherits(x, "agri_sensitivity")) {
    obj <- list(domain = "sensitivity", table = x$table, interpretation = x$interpretation,
                fitted_methods = names(x$fits), session = utils::sessionInfo())
  } else if (inherits(x, "agri_missing_report")) {
    obj <- c(unclass(x), list(domain = "missing_data", session = utils::sessionInfo()))
  } else {
    if (!inherits(x, "agri_rank_fit")) .agri_stop("Unsupported agriRank result class for export.")
    obj <- list(design = design_summary(x$design), omnibus = x$omnibus,
                effects = tryCatch(agri_effects(x), error = function(e) NULL),
                missing = x$missing, method = x$engine$method %||% x$method,
                seed = x$seed, session = utils::sessionInfo())
  }
  saveRDS(obj, file)
  normalizePath(file, winslash = "/", mustWork = FALSE)
}
