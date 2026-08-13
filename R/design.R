#' Declare an agricultural experimental design
#'
#' @param formula Model formula for the scientific treatment structure.
#' @param data Data frame in long format.
#' @param design One of crd, rcbd, factorial, split_plot, split_split,
#'   strip_plot, repeated, longitudinal, multienv or multivariate.
#' @param block Optional blocking variable.
#' @param subject Subject/experimental-unit identifier for repeated data.
#' @param within Within-subject factor(s).
#' @param whole_plot Whole-plot treatment factor(s).
#' @param subplot Subplot factor(s).
#' @param subsubplot Sub-subplot treatment factor(s) for split-split designs.
#' @param strip_a First perpendicular strip treatment factor(s) for strip-plot designs.
#' @param strip_b Second perpendicular strip treatment factor(s) for strip-plot designs.
#' @param environment Environment factor for multi-environment trials.
#' @param quantitative Treatment variables that should retain quantitative meaning.
#' @return An object of class agri_design.
#' @export
agri_design <- function(formula, data,
                        design = c("crd", "rcbd", "factorial", "split_plot",
                                   "split_split", "strip_plot", "repeated",
                                   "longitudinal", "multienv", "multivariate"),
                        block = NULL, subject = NULL, within = NULL,
                        whole_plot = NULL, subplot = NULL, subsubplot = NULL,
                        strip_a = NULL, strip_b = NULL, environment = NULL,
                        quantitative = NULL, id = NULL) {
  design <- match.arg(design)
  if (!is.data.frame(data)) data <- as.data.frame(data)

  block_nm <- .capture_names(substitute(block), names(data))
  subject_nm <- .capture_names(substitute(subject), names(data))
  within_nm <- .capture_names(substitute(within), names(data))
  whole_nm <- .capture_names(substitute(whole_plot), names(data))
  subplot_nm <- .capture_names(substitute(subplot), names(data))
  subsubplot_nm <- .capture_names(substitute(subsubplot), names(data))
  strip_a_nm <- .capture_names(substitute(strip_a), names(data))
  strip_b_nm <- .capture_names(substitute(strip_b), names(data))
  env_nm <- .capture_names(substitute(environment), names(data))
  quant_nm <- .capture_names(substitute(quantitative), names(data))
  id_nm <- .capture_names(substitute(id), names(data))

  response <- .response_names(formula)
  predictors <- .predictor_names(formula)
  all_needed <- unique(c(response, predictors, block_nm, subject_nm, within_nm,
                         whole_nm, subplot_nm, subsubplot_nm, strip_a_nm, strip_b_nm, env_nm, quant_nm, id_nm))
  .check_vars(all_needed, data)

  if (length(response) < 1L) .agri_stop("The formula must contain a response.")
  if (design %in% c("repeated", "longitudinal") && is.null(subject_nm))
    .agri_stop("Repeated/longitudinal designs require `subject=`.")
  if (design %in% c("repeated", "longitudinal") && is.null(within_nm))
    .agri_stop("Repeated/longitudinal designs require at least one `within=` factor.")
  if (design == "rcbd" && is.null(block_nm)) .agri_stop("RCBD requires `block=`.")
  if (design == "split_plot" && (is.null(block_nm) || is.null(whole_nm) || is.null(subplot_nm)))
    .agri_stop("Split-plot designs require `block=`, `whole_plot=`, and `subplot=`.")
  if (design == "split_split" && (is.null(block_nm) || is.null(whole_nm) || is.null(subplot_nm) || is.null(subsubplot_nm)))
    .agri_stop("Split-split designs require `block=`, `whole_plot=`, `subplot=`, and `subsubplot=`.")
  if (design == "strip_plot" && (is.null(block_nm) || is.null(strip_a_nm) || is.null(strip_b_nm)))
    .agri_stop("Strip-plot designs require `block=`, `strip_a=`, and `strip_b=`.")
  if (design == "multienv" && is.null(env_nm))
    .agri_stop("Multi-environment designs require `environment=`.")

  special <- switch(design,
    split_plot = unique(c(whole_nm, subplot_nm)),
    split_split = unique(c(whole_nm, subplot_nm, subsubplot_nm)),
    strip_plot = unique(c(strip_a_nm, strip_b_nm)),
    multienv = env_nm,
    character())
  missing_special <- setdiff(special, predictors)
  if (length(missing_special))
    .agri_stop(sprintf("The declared %s design variable(s) must also appear in the model formula: %s",
                       design, paste(missing_special, collapse = ", ")))

  factor_type <- setNames(rep("qualitative", length(predictors)), predictors)
  factor_type[intersect(quant_nm, predictors)] <- "quantitative"

  obj <- list(
    formula = formula,
    data = data,
    design = design,
    response = response,
    predictors = predictors,
    terms = .term_labels(formula),
    block = block_nm,
    subject = subject_nm,
    within = within_nm,
    whole_plot = whole_nm,
    subplot = subplot_nm,
    subsubplot = subsubplot_nm,
    strip_a = strip_a_nm,
    strip_b = strip_b_nm,
    environment = env_nm,
    id = id_nm,
    quantitative = quant_nm,
    factor_type = factor_type,
    call = match.call()
  )
  class(obj) <- "agri_design"
  obj$validation <- validate_agri_design(obj, error = FALSE)
  obj$randomization <- .describe_randomization(obj)
  obj
}

.describe_randomization <- function(x) {
  switch(x$design,
    crd = "Treatment assignments are exchangeable across experimental units, subject to the declared treatment structure.",
    factorial = "Factorial treatment combinations are assigned to independent experimental units.",
    rcbd = "Treatment combinations are randomized within blocks; block labels are not exchangeable with treatments.",
    split_plot = "Whole-plot treatments are randomized at the whole-plot stratum; subplot treatments are randomized within whole plots.",
    split_split = "Randomization is hierarchical across whole-plot, subplot and sub-subplot strata.",
    strip_plot = "Two treatment sets are randomized in perpendicular strips; their intersection defines the interaction stratum.",
    repeated = "Between-subject treatments are assigned to subjects/experimental units; within-subject factors index repeated observations on the same subject.",
    longitudinal = "Subjects are independent experimental units and repeated observations within subject are dependent.",
    multienv = "Treatment/genotype effects are evaluated across declared environments; blocking is environment-specific when declared.",
    multivariate = "Multiple responses share the same declared experimental-unit structure.",
    "Declared randomization structure"
  )
}

#' Validate a declared agricultural design
#' @param x agri_design object.
#' @param error Stop for fatal validation failures.
#' @export
validate_agri_design <- function(x, error = TRUE) {
  if (!inherits(x, "agri_design")) .agri_stop("`x` must be an agri_design object.")
  dat <- x$data
  problems <- data.frame(severity = character(), code = character(), message = character(), stringsAsFactors = FALSE)
  add <- function(sev, code, msg) {
    problems <<- rbind(problems, data.frame(severity = sev, code = code, message = msg, stringsAsFactors = FALSE))
  }

  for (r in x$response) {
    if (all(is.na(dat[[r]]))) add("error", "all_response_missing", sprintf("Response `%s` is entirely missing.", r))
    if (anyNA(dat[[r]])) add("warning", "response_missing", sprintf("Response `%s` contains %d missing observation(s).", r, sum(is.na(dat[[r]]))))
  }
  for (v in unique(c(x$predictors, x$block, x$subject, x$within, x$whole_plot, x$subplot, x$subsubplot, x$strip_a, x$strip_b, x$environment))) {
    if (anyNA(dat[[v]])) add("error", "design_variable_missing", sprintf("Design variable `%s` contains missing values.", v))
  }

  if (!is.null(x$id) && anyDuplicated(dat[[x$id]])) add("warning", "duplicate_id", "The declared row/unit id is not unique.")

  if (!is.null(x$block)) {
    for (b in x$block) if (is.numeric(dat[[b]]) && length(unique(dat[[b]])) < nrow(dat) / 2)
      add("warning", "numeric_block", sprintf("Block `%s` is numeric; verify that it should be treated as a categorical blocking factor.", b))
  }

  if (length(x$predictors)) {
    tab <- do.call(table, c(lapply(dat[x$predictors], .safe_factor), list(useNA = "no")))
    if (any(tab == 0L)) add("warning", "empty_factorial_cell", "At least one factorial treatment cell is empty; some effects may be non-estimable.")
  }

  if (!is.null(x$subject)) {
    sid <- .subject_namespace(dat, x)
    if (anyNA(sid)) add("error", "subject_missing", "Subject identifiers may not be missing.")
    if (length(x$within)) {
      wk <- .interaction_key(dat, x$within)
      dup <- duplicated(data.frame(sid = sid, wk = wk))
      if (any(dup)) add("error", "duplicate_repeated_cell", "A subject has more than one observation for the same within-subject cell within its between-subject treatment group. Aggregate technical replicates explicitly before analysis.")
    }
  }

  fatal <- problems$severity == "error"
  if (error && any(fatal)) .agri_stop(paste(problems$message[fatal], collapse = "\n"))
  structure(list(ok = !any(fatal), problems = problems), class = "agri_validation")
}

#' Summarize design structure
#' @export
design_summary <- function(x) {
  if (!inherits(x, "agri_design")) .agri_stop("`x` must be an agri_design object.")
  dat <- x$data
  n_cells <- if (length(x$predictors)) nrow(unique(dat[x$predictors])) else 1L
  list(
    design = x$design,
    responses = x$response,
    treatments = x$predictors,
    blocks = x$block,
    subjects = x$subject,
    within = x$within,
    whole_plot = x$whole_plot,
    subplot = x$subplot,
    subsubplot = x$subsubplot,
    strip_a = x$strip_a,
    strip_b = x$strip_b,
    environment = x$environment,
    n_rows = nrow(dat),
    n_treatment_cells_observed = n_cells,
    missing_response = vapply(x$response, function(r) sum(is.na(dat[[r]])), integer(1)),
    randomization = x$randomization,
    validation = x$validation
  )
}

#' @export
print.agri_design <- function(x, ...) {
  s <- design_summary(x)
  cat("agriRank experimental design\n")
  cat("  Design:   ", s$design, "\n", sep = "")
  cat("  Response: ", paste(s$responses, collapse = ", "), "\n", sep = "")
  cat("  Factors:  ", paste(s$treatments, collapse = " * "), "\n", sep = "")
  if (length(s$blocks)) cat("  Block:    ", paste(s$blocks, collapse = ", "), "\n", sep = "")
  if (length(s$subjects)) cat("  Subject:  ", paste(s$subjects, collapse = ", "), "\n", sep = "")
  if (length(s$within)) cat("  Within:   ", paste(s$within, collapse = ", "), "\n", sep = "")
  if (length(s$whole_plot)) cat("  Whole plot: ", paste(s$whole_plot, collapse = ", "), "\n", sep = "")
  if (length(s$subplot)) cat("  Subplot:  ", paste(s$subplot, collapse = ", "), "\n", sep = "")
  if (length(s$subsubplot)) cat("  Sub-subplot: ", paste(s$subsubplot, collapse = ", "), "\n", sep = "")
  if (length(s$strip_a)) cat("  Strip A:  ", paste(s$strip_a, collapse = ", "), "\n", sep = "")
  if (length(s$strip_b)) cat("  Strip B:  ", paste(s$strip_b, collapse = ", "), "\n", sep = "")
  if (length(s$environment)) cat("  Environment: ", paste(s$environment, collapse = ", "), "\n", sep = "")
  cat("  Rows:     ", s$n_rows, "\n", sep = "")
  if (nrow(x$validation$problems)) cat("  Validation messages: ", nrow(x$validation$problems), "\n", sep = "")
  invisible(x)
}

#' @export
summary.agri_design <- function(object, ...) design_summary(object)

#' List implemented and adapter-backed methods
#' @export
agri_methods <- function() {
  data.frame(
    domain = c("one-way", "RCBD", "factorial", "multiple comparisons",
               "split-plot", "split-split", "strip-plot", "repeated",
               "repeated+missing", "multivariate", "multi-environment",
               "ANCOVA", "nonparametric regression", "robust sensitivity"),
    method = c("Kruskal / permutation", "Friedman / restricted permutation",
               "rankFD / ARTool / permutation", "Wilcoxon / Conover / maxT",
               "permuco / ARTool", "permuco / ARTool hierarchical strata",
               "ARTool strip-specific random strata / permuco Error strata",
               "nparLD / MANOVA.RM / native wild", "native wild ATS/WTS/MATS",
               "MANOVA.RM MANOVA / MANOVA.wide / multRM",
               "rankFD / ARTool / permuco with environment enforced",
               "permuco",
               "spline / LOESS / kernel / isotonic / COBS / Theil-Sen / quantile / GAM / SCAM / integer-support",
               "WRS2 / alternative engines"),
    status = c("implemented", "implemented", "adapter+implemented", "implemented+adapter",
               "adapter", "adapter", "adapter", "adapter+implemented",
               "implemented-experimental", "adapter+integrated", "adapter+integrated",
               "adapter", "implemented+adapter", "adapter"),
    stringsAsFactors = FALSE
  )
}
