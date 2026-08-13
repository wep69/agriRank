# Tables and reports -------------------------------------------------------

#' Standardized analysis tables
#' @export
agri_table <- function(x, what = c("omnibus", "effects", "pairs", "missing",
                                   "metrics", "predictions", "derivative", "optimum",
                                   "integer_predictions", "integer_optimum", "integer_efficiency"), ...) {
  what_missing <- missing(what)
  if (inherits(x, "agri_np_reg_fit")) {
    if (what_missing) what <- "metrics" else what <- match.arg(what)
    tab <- switch(what,
      metrics = x$metrics,
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
      .agri_stop("For regression fits, choose metrics, predictions, derivative, optimum, integer_predictions, integer_optimum, or integer_efficiency.")
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
  if (requireNamespace("gt", quietly = TRUE)) return(gt::gt(tab))
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
    "## Interpretation boundary",
    "- Cross-validation and residual diagnostics evaluate predictive behavior; they do not select a confirmatory method by the smallest p-value.",
    "- A fitted maximum/minimum is descriptive unless an economic or mechanistic objective was specified independently.",
    "- Integer-support fits never convert a continuous optimum to a decision by rounding; decisions are evaluated directly on the admissible lattice.",
    "- Shape constraints should be scientifically justified before examining the fitted response.", "",
    "## Reproducibility",
    sprintf("- R: %s", R.version.string),
    sprintf("- agriRank regression method: %s", x$method),
    sprintf("- Backend class: %s", paste(class(x$engine), collapse = ", "))
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
