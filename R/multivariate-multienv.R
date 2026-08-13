# Multivariate and multi-environment helpers -------------------------------

.stack_backend_tables <- function(tables) {
  tables <- tables[!vapply(tables, is.null, logical(1))]
  if (!length(tables)) return(NULL)
  dfs <- lapply(names(tables), function(nm) {
    z <- tryCatch(as.data.frame(tables[[nm]]), error = function(e) NULL)
    if (is.null(z)) return(NULL)
    if (!nrow(z)) return(NULL)
    z$statistic_family <- nm
    if (is.null(z$effect)) {
      rn <- rownames(z)
      if (!is.null(rn) && any(nzchar(rn))) z$effect <- rn
    }
    rownames(z) <- NULL
    z
  })
  dfs <- dfs[!vapply(dfs, is.null, logical(1))]
  if (!length(dfs)) return(NULL)
  alln <- unique(unlist(lapply(dfs, names), use.names = FALSE))
  dfs <- lapply(dfs, function(z) {
    miss <- setdiff(alln, names(z)); for (m in miss) z[[m]] <- NA
    z[alln]
  })
  do.call(rbind, dfs)
}

#' Multivariate resampling inference with a common agriRank result class
#'
#' @param formula Multivariate model. Use `cbind(y1, y2, ...) ~ ...` for wide
#'   multivariate data. A single response in long format can be used with
#'   `subject=`. When `within=` is supplied together with multiple responses,
#'   `MANOVA.RM::multRM()` is used.
#' @param data Data frame.
#' @param subject Optional subject identifier. Required for long-format MANOVA
#'   and multivariate repeated measures.
#' @param within Optional within-subject factor(s) for multivariate repeated measures.
#' @param block Optional agronomic block. If absent from the model formula it is
#'   added as an adjustment factor and is therefore also visible in the omnibus table.
#' @param resampling Resampling method passed to MANOVA.RM.
#' @param iter Number of resampling iterations.
#' @param seed Reproducible seed.
#' @export
agri_multivariate <- function(formula, data, subject = NULL, within = NULL, block = NULL,
                              resampling = "WildBS", iter = 4999, seed = 1, ...) {
  .require_pkg("MANOVA.RM", "multivariate resampling inference")
  if (!is.data.frame(data)) data <- as.data.frame(data)
  sexpr <- substitute(subject); wexpr <- substitute(within); bexpr <- substitute(block)
  subject_nm <- if (identical(sexpr, quote(NULL))) NULL else .capture_names(sexpr, names(data))
  within_nm <- if (identical(wexpr, quote(NULL))) NULL else .capture_names(wexpr, names(data))
  block_nm <- if (identical(bexpr, quote(NULL))) NULL else .capture_names(bexpr, names(data))
  responses <- .response_names(formula)
  predictors <- .predictor_names(formula)
  .check_vars(unique(c(responses, predictors, subject_nm, within_nm, block_nm)), data)
  if (anyNA(data[, unique(c(responses, predictors, subject_nm, within_nm, block_nm)), drop = FALSE]))
    .agri_stop("MANOVA.RM multivariate engines in agriRank require complete values in all modeled response/design variables.")

  # Canonicalize the MANOVA.RM formula. For multRM, official MANOVA.RM
  # semantics require within-subject factors to appear in the formula and to be
  # specified after the between-subject factors. If `within=` is declared,
  # agriRank therefore constructs a full factorial between-by-within scientific
  # structure and keeps any agronomic block as an additive adjustment factor.
  f <- formula
  lhs <- paste(deparse(formula[[2L]]), collapse = "")
  if (length(within_nm)) {
    between_nm <- setdiff(predictors, c(within_nm, block_nm))
    scientific <- unique(c(between_nm, within_nm))
    if (!length(scientific)) .agri_stop("At least one between- or within-subject factor is required for multivariate repeated measures.")
    rhs_scientific <- paste(scientific, collapse = " * ")
    rhs <- if (length(block_nm)) paste(paste(block_nm, collapse = " + "), rhs_scientific, sep = " + ") else rhs_scientific
    f <- stats::as.formula(paste(lhs, "~", rhs), env = environment(formula))
  } else if (length(block_nm) && !all(block_nm %in% predictors)) {
    rhs <- paste(c(block_nm, .term_labels(formula)), collapse = " + ")
    f <- stats::as.formula(paste(lhs, "~", rhs), env = environment(formula))
  }

  design <- do.call(agri_design, list(formula = f, data = data, design = "multivariate",
                                      block = block_nm, subject = subject_nm, within = within_nm))
  dat <- data
  mode <- NULL
  if (length(responses) > 1L && length(within_nm)) {
    if (!length(subject_nm)) .agri_stop("Multivariate repeated measures require `subject=` when `within=` is supplied.")
    dat$.agri_subject <- .subject_namespace(dat, design)
    z <- .seed_eval(seed, MANOVA.RM::multRM(f, data = dat, subject = ".agri_subject",
                                            within = within_nm, resampling = resampling,
                                            iter = iter, seed = seed, ...))
    mode <- "multRM"
  } else if (length(responses) > 1L) {
    z <- .seed_eval(seed, MANOVA.RM::MANOVA.wide(f, data = dat,
                                                 resampling = resampling, iter = iter,
                                                 seed = seed, ...))
    mode <- "MANOVA.wide"
  } else {
    if (!length(subject_nm)) .agri_stop("Long-format MANOVA.RM analysis with a single response requires `subject=`.")
    dat$.agri_subject <- .subject_namespace(dat, design)
    z <- .seed_eval(seed, MANOVA.RM::MANOVA(f, data = dat, subject = ".agri_subject",
                                            resampling = resampling, iter = iter,
                                            seed = seed, ...))
    mode <- "MANOVA"
  }

  omnibus <- .stack_backend_tables(list(WTS = z$WTS, MATS = z$MATS, resampling = z$resampling))
  out <- list(
    design = design, formula = f, responses = responses, predictors = .predictor_names(f),
    block = block_nm, subject = subject_nm, within = within_nm,
    method = paste0("MANOVA.RM::", mode, " (", resampling, ")"), mode = mode,
    resampling = resampling, iter = iter, seed = seed,
    omnibus = omnibus, descriptive = z$Descriptive %||% NULL,
    covariance = z$Covariance %||% NULL, engine = z, call = match.call()
  )
  class(out) <- "agri_multivariate_fit"
  out
}

#' @export
print.agri_multivariate_fit <- function(x, ...) {
  cat("agriRank multivariate fit\n")
  cat("  Mode: ", x$mode, "\n", sep = "")
  cat("  Method: ", x$method, "\n", sep = "")
  cat("  Responses: ", paste(x$responses, collapse = ", "), "\n", sep = "")
  if (length(x$block)) cat("  Block adjustment: ", paste(x$block, collapse = ", "), "\n", sep = "")
  if (!is.null(x$omnibus)) print(x$omnibus)
  invisible(x)
}

#' @export
summary.agri_multivariate_fit <- function(object, ...) {
  list(design = design_summary(object$design), mode = object$mode,
       method = object$method, responses = object$responses,
       omnibus = object$omnibus, descriptive = object$descriptive)
}

.ensure_multienv_formula <- function(formula, env_name, interaction = TRUE) {
  preds <- .predictor_names(formula)
  if (env_name %in% preds) return(formula)
  lhs <- paste(deparse(formula[[2L]]), collapse = "")
  rhs <- paste(deparse(formula[[3L]]), collapse = "")
  rhs2 <- if (isTRUE(interaction) && length(preds)) paste0("(", rhs, ") * ", env_name) else paste(rhs, "+", env_name)
  stats::as.formula(paste(lhs, "~", rhs2), env = environment(formula))
}

#' Multi-environment rank workflow
#'
#' @param environment_interaction If `TRUE` (default), a missing environment
#'   term is injected as an interaction with the existing treatment structure.
#'   If `FALSE`, environment is injected as a main effect only. If environment
#'   is already present in the supplied formula, the formula is respected.
#' @export
agri_multienv <- function(formula, data, environment, block = NULL, method = "auto",
                          environment_interaction = TRUE, ...) {
  env <- tryCatch(.capture_names(substitute(environment), names(data)),
                  error = function(e) character(0))
  env <- env[nzchar(env)]
  if (length(env) != 1L) .agri_stop("`environment=` currently requires one environment/site/year factor.")
  bexpr <- substitute(block)
  b <- if (identical(bexpr, quote(NULL))) NULL else .capture_names(bexpr, names(data))
  f <- .ensure_multienv_formula(formula, env[1L], interaction = environment_interaction)
  if (!env[1L] %in% .predictor_names(f)) .agri_stop("Environment enforcement failed; the environment factor must be part of the fitted formula.")
  d <- do.call(agri_design, list(formula = f, data = data, design = "multienv", environment = env, block = b))
  fit <- agri_rank(d, method = method, ...)
  fit$environment_enforced <- !env[1L] %in% .predictor_names(formula)
  fit$environment_interaction_requested <- isTRUE(environment_interaction)
  fit
}
