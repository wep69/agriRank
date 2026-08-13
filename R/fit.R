# Main fitting API ---------------------------------------------------------

#' Fit design-aware nonparametric/rank-based inference
#' @param design agri_design object.
#' @param method auto or explicit engine/method.
#' @param response Optional response for multi-response designs.
#' @param estimand Target effect representation.
#' @param B Resampling replicates for native wild engine.
#' @param seed Seed.
#' @param missing_assumption Missingness assumption label.
#' @export
agri_rank <- function(design, method = "auto", response = NULL,
                      estimand = c("relative_effect", "distribution", "location_shift"),
                      B = 1999, seed = 1,
                      missing_assumption = c("unspecified", "MCAR", "MAR-sensitivity"), ...) {
  if (!inherits(design, "agri_design")) .agri_stop("`design` must be created by agri_design().")
  if (identical(design$design, "multivariate"))
    .agri_stop("Use `agri_multivariate()` for multivariate inference; `agri_rank()` analyzes one response at a time and will not silently reduce a multivariate design to its first response.")
  validate_agri_design(design, error = TRUE)
  estimand <- match.arg(estimand)
  missing_assumption <- match.arg(missing_assumption)
  response <- response %||% design$response[1L]
  miss <- anyNA(design$data[[response]])

  selected <- method
  if (identical(method, "auto")) {
    if (design$design %in% c("repeated", "longitudinal")) {
      has_block <- length(design$block) > 0L
      if (miss && has_block) {
        .agri_stop("Incomplete repeated measures with an additional agronomic block stratum are not assigned to an unvalidated automatic method. The native incomplete wild-rank procedure deliberately rejects this case.")
      }
      if (has_block) {
        selected <- if (requireNamespace("permuco", quietly = TRUE)) "permuco" else .agri_stop("Complete blocked repeated measures require the optional `permuco` backend in automatic mode.")
      } else if (miss) selected <- "incomplete_wild"
      else if (requireNamespace("nparLD", quietly = TRUE)) selected <- "nparLD"
      else if (requireNamespace("MANOVA.RM", quietly = TRUE)) selected <- "MANOVA.RM"
      else selected <- "incomplete_wild"
    } else if (design$design == "crd" && length(design$predictors) == 1L) selected <- "kruskal"
    else if (design$design == "rcbd" && length(design$predictors) == 1L && !miss) selected <- "friedman"
    else if (design$design %in% c("split_plot", "split_split")) {
      selected <- if (requireNamespace("permuco", quietly = TRUE)) "permuco" else if (requireNamespace("ARTool", quietly = TRUE)) "ART" else .agri_stop("Split-plot/split-split inference requires `permuco` or `ARTool`.")
    } else if (design$design == "strip_plot") {
      selected <- if (requireNamespace("ARTool", quietly = TRUE)) "ART" else if (requireNamespace("permuco", quietly = TRUE)) "permuco" else .agri_stop("Strip-plot inference requires `ARTool` or `permuco`.")
    } else if (design$design == "multienv") {
      env <- design$environment[1L]
      has_env_interaction <- any(vapply(.term_labels(design$formula), function(tt) {
        vars <- all.vars(stats::as.formula(paste("~", tt)))
        env %in% vars && length(setdiff(vars, env)) > 0L
      }, logical(1)))
      if (!has_env_interaction && length(setdiff(design$predictors, env))) {
        selected <- if (requireNamespace("permuco", quietly = TRUE)) "permuco" else .agri_stop("A multi-environment main-effect-only model requires the optional `permuco` backend; rankFD and ARTool require an interaction structure for multifactor inference.")
      } else if (length(design$block)) {
        selected <- if (requireNamespace("ARTool", quietly = TRUE)) "ART" else if (requireNamespace("permuco", quietly = TRUE)) "permuco" else .agri_stop("Blocked multi-environment inference requires `ARTool` or `permuco`.")
      } else {
        selected <- if (requireNamespace("rankFD", quietly = TRUE)) "rankFD" else if (requireNamespace("ARTool", quietly = TRUE)) "ART" else if (requireNamespace("permuco", quietly = TRUE)) "permuco" else .agri_stop("Multi-environment factorial inference requires `rankFD`, `ARTool`, or `permuco`.")
      }
    } else if (length(design$predictors) > 1L && is.null(design$block)) {
      selected <- if (requireNamespace("rankFD", quietly = TRUE)) "rankFD" else if (requireNamespace("ARTool", quietly = TRUE)) "ART" else "permuco"
    } else if (length(design$block)) {
      selected <- if (requireNamespace("ARTool", quietly = TRUE)) "ART" else "permuco"
    } else selected <- "kruskal"
  }

  if (length(design$block) && tolower(selected) %in% c("kruskal", "rankfd"))
    .agri_stop(sprintf("Method `%s` is not allowed when a block is declared because this adapter would analyze observations as independent and discard the randomization structure. Use a block-aware engine such as Friedman (one-way complete RCBD), ART, or permuco as appropriate.", selected))

  if (design$design %in% c("repeated", "longitudinal") && length(design$block)) {
    if (miss) .agri_stop("No confirmatory incomplete repeated-measures engine in this build supports an additional agronomic block stratum without discarding design information.")
    if (tolower(selected) %in% c("incomplete_wild", "native_wild", "nparld", "manova.rm"))
      .agri_stop(sprintf("Method `%s` is not allowed for blocked repeated measures in agriRank because the current adapter would not honor the declared block semantics. Use `permuco` for complete data.", selected))
  }

  engine <- switch(tolower(selected),
    kruskal = .engine_kruskal(design, response),
    friedman = .engine_friedman(design, response),
    rankfd = .engine_rankfd(design, response, ...),
    art = .engine_art(design, response, ...),
    permuco = .engine_permuco(design, response, seed = seed, ...),
    nparld = .engine_nparld(design, response, ...),
    manova.rm = .engine_manovarm_rm(design, response, seed = seed, ...),
    incomplete_wild = incomplete_wild_rank_test(design, response, B = B, seed = seed,
                                                missing_assumption = missing_assumption, ...),
    native_wild = incomplete_wild_rank_test(design, response, B = B, seed = seed,
                                            missing_assumption = missing_assumption, ...),
    .agri_stop(sprintf("Unknown method `%s`.", selected))
  )

  out <- list(
    design = design,
    response = response,
    method = selected,
    estimand = estimand,
    engine = engine,
    omnibus = engine$omnibus,
    effects = engine$effects %||% NULL,
    missing = agri_missing_report(design, response = response),
    seed = seed,
    call = match.call()
  )
  class(out) <- "agri_rank_fit"
  out
}

#' @export
print.agri_rank_fit <- function(x, ...) {
  cat("agriRank fit\n")
  cat("  Design: ", x$design$design, "\n", sep = "")
  cat("  Method: ", x$engine$method %||% x$method, "\n", sep = "")
  cat("  Response: ", x$response, "\n", sep = "")
  if (!is.null(x$omnibus)) print(x$omnibus)
  invisible(x)
}

#' @export
summary.agri_rank_fit <- function(object, ...) {
  list(design = design_summary(object$design), method = object$engine$method %||% object$method,
       estimand = object$estimand, omnibus = object$omnibus, effects = object$effects,
       missing = object$missing)
}

#' @export
anova.agri_rank_fit <- function(object, ...) object$omnibus

#' @export
confint.agri_rank_fit <- function(object, parm, level = 0.95, ...) {
  eff <- agri_effects(object, ci = TRUE, level = level)
  if (!all(c("lower", "upper") %in% names(eff)))
    .agri_stop("Confidence intervals are not standardized for this backend through agriRank. Use an engine-specific interval procedure or a supported contrast method.")
  eff[, c(setdiff(names(eff), c("lower", "upper")), "lower", "upper"), drop = FALSE]
}

# Convenience wrappers ----------------------------------------------------
#' @export
np_crd <- function(formula, data, method = "auto", ...) {
  d <- agri_design(formula, data, design = "crd")
  agri_rank(d, method = method, ...)
}
#' @export
np_rcbd <- function(formula, data, block, method = "auto", ...) {
  b <- .capture_names(substitute(block), names(data))
  d <- do.call(agri_design, list(formula = formula, data = data, design = "rcbd", block = b))
  agri_rank(d, method = method, ...)
}
#' @export
np_factorial <- function(formula, data, block = NULL, method = "auto", ...) {
  b <- .capture_names(substitute(block), names(data))
  if (is.null(b)) d <- agri_design(formula, data, design = "factorial")
  else d <- do.call(agri_design, list(formula = formula, data = data, design = "rcbd", block = b))
  agri_rank(d, method = method, ...)
}
#' @export
np_splitplot <- function(formula, data, block, whole_plot, subplot, method = "auto", ...) {
  b <- .capture_names(substitute(block), names(data)); w <- .capture_names(substitute(whole_plot), names(data)); s <- .capture_names(substitute(subplot), names(data))
  d <- do.call(agri_design, list(formula = formula, data = data, design = "split_plot", block = b, whole_plot = w, subplot = s))
  agri_rank(d, method = method, ...)
}

#' Split-split-plot nonparametric workflow
#' @export
np_splitsplit <- function(formula, data, block, whole_plot, subplot, subsubplot, method = "auto", ...) {
  b <- .capture_names(substitute(block), names(data))
  w <- .capture_names(substitute(whole_plot), names(data))
  s <- .capture_names(substitute(subplot), names(data))
  ss <- .capture_names(substitute(subsubplot), names(data))
  d <- do.call(agri_design, list(formula = formula, data = data, design = "split_split",
                                  block = b, whole_plot = w, subplot = s, subsubplot = ss))
  agri_rank(d, method = method, ...)
}

#' Strip-plot nonparametric workflow
#' @export
np_stripplot <- function(formula, data, block, strip_a, strip_b, method = "auto", ...) {
  b <- .capture_names(substitute(block), names(data))
  a <- .capture_names(substitute(strip_a), names(data))
  bb <- .capture_names(substitute(strip_b), names(data))
  d <- do.call(agri_design, list(formula = formula, data = data, design = "strip_plot",
                                  block = b, strip_a = a, strip_b = bb))
  agri_rank(d, method = method, ...)
}
#' @export
np_repeated <- function(formula, data, subject, within, block = NULL, method = "auto", ...) {
  cap <- function(e) tryCatch({
    z <- .capture_names(e, names(data)); z[nzchar(z)]
  }, error = function(err) character(0))
  s <- cap(substitute(subject)); w <- cap(substitute(within))
  b <- .capture_names(substitute(block), names(data))
  # Fail with the scientific reason rather than with a data-frame subscript error.
  if (!length(s)) .agri_stop("`np_repeated()` requires `subject=`: repeated measurements are not exchangeable across subjects.")
  if (!length(w)) .agri_stop("`np_repeated()` requires at least one `within=` factor.")
  args <- list(formula = formula, data = data, design = "repeated", subject = s, within = w)
  if (!is.null(b)) args$block <- b
  d <- do.call(agri_design, args)
  agri_rank(d, method = method, ...)
}
