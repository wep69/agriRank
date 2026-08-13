# Repeated measures public workflow --------------------------------------

#' Analyze repeated measures with explicit backend selection
#' @param design Repeated agri_design.
#' @param backend auto, native_wild, nparLD, MANOVA.RM, or permuco.
#' @export
agri_repeated <- function(design, backend = c("auto", "native_wild", "nparLD", "MANOVA.RM", "permuco"),
                          B = 1999, iter = 4999, seed = 1,
                          missing_assumption = c("unspecified", "MCAR", "MAR-sensitivity"), ...) {
  backend <- match.arg(backend)
  missing_assumption <- match.arg(missing_assumption)
  if (!inherits(design, "agri_design") || !design$design %in% c("repeated", "longitudinal"))
    .agri_stop("`design` must be a repeated/longitudinal agri_design.")
  miss <- anyNA(design$data[[design$response[1L]]])
  has_block <- length(design$block) > 0L
  if (backend == "auto") {
    if (miss && has_block) {
      .agri_stop("Incomplete repeated measures with an RCBD/block stratum are not routed to an unvalidated method. The native 2024-style wild-rank engine models incomplete repeated factorial data without an additional agronomic block nuisance stratum. Complete blocked repeated measures can use `backend = 'permuco'`.")
    }
    if (has_block && !miss) {
      if (requireNamespace("permuco", quietly = TRUE)) backend <- "permuco"
      else .agri_stop("Complete blocked repeated measures require the optional `permuco` backend in automatic mode. Install `permuco` or select and justify another backend explicitly.")
    } else {
      backend <- if (miss) "native_wild" else if (requireNamespace("nparLD", quietly = TRUE)) "nparLD" else if (requireNamespace("MANOVA.RM", quietly = TRUE)) "MANOVA.RM" else "native_wild"
    }
  }
  if (backend == "native_wild" && has_block) {
    .agri_stop("`native_wild` deliberately rejects an additional block stratum; silently ignoring blocks would violate the declared randomization. Use `permuco` for complete blocked repeated measures.")
  }
  if (has_block && backend %in% c("nparLD", "MANOVA.RM")) {
    .agri_stop(sprintf("Backend `%s` is disabled for blocked repeated measures in agriRank because this adapter does not encode the agronomic block as the declared nuisance/randomization stratum. Use `permuco` for complete data.", backend))
  }
  if (miss && backend == "permuco") {
    .agri_stop("`permuco` is not used here as an all-available incomplete repeated-measures method. Use the native wild-rank engine only for unblocked incomplete repeated designs; blocked incomplete repeated designs require further validated methodology.")
  }
  switch(backend,
    native_wild = agri_rank(design, method = "incomplete_wild", B = B, seed = seed, missing_assumption = missing_assumption, ...),
    nparLD = agri_rank(design, method = "nparLD", seed = seed, ...),
    MANOVA.RM = {
      eng <- .engine_manovarm_rm(design, iter = iter, seed = seed, ...)
      out <- list(design = design, response = design$response[1L], method = "MANOVA.RM", estimand = "mean-based semiparametric", engine = eng, omnibus = eng$omnibus, effects = NULL, missing = agri_missing_report(design), seed = seed, call = match.call()); class(out) <- "agri_rank_fit"; out
    },
    permuco = {
      eng <- .engine_permuco(design, np = iter, seed = seed, ...)
      out <- list(design = design, response = design$response[1L], method = "permuco", estimand = "permutation rank", engine = eng, omnibus = eng$omnibus, effects = NULL, missing = agri_missing_report(design), seed = seed, call = match.call()); class(out) <- "agri_rank_fit"; out
    }
  )
}

#' Sensitivity analysis for incomplete repeated measurements
#'
#' Compares all-available native wild-rank inference with a complete-subject
#' analysis using the same engine. This does not identify the missingness
#' mechanism; it quantifies how much conclusions depend on retaining incomplete
#' subjects.
#' @export
agri_missing_sensitivity <- function(x, B = 999, seed = 1, statistic = "ATS") {
  design <- if (inherits(x, "agri_rank_fit")) x$design else x
  if (!inherits(design, "agri_design") || !design$design %in% c("repeated", "longitudinal"))
    .agri_stop("Repeated/longitudinal agri_design required.")
  mr <- agri_missing_report(design)
  if (mr$n_missing == 0L) return(list(message = "No missing response values detected.", missing = mr))
  all_fit <- incomplete_wild_rank_test(design, B = B, seed = seed, statistic = statistic, missing_assumption = "MCAR")
  M <- mr$repeated$observation_matrix
  complete_ids <- rownames(M)[rowSums(M) == ncol(M)]
  dat <- design$data
  gkey <- .interaction_key(dat, setdiff(design$predictors, design$within))
  skey <- .interaction_key(dat, design$subject)
  comb <- interaction(gkey, skey, drop = TRUE, lex.order = TRUE, sep = "@@")
  keep <- as.character(comb) %in% complete_ids
  d2 <- design; d2$data <- dat[keep, , drop = FALSE]; d2$validation <- validate_agri_design(d2, error = FALSE)
  cc_fit <- incomplete_wild_rank_test(d2, B = B, seed = seed, statistic = statistic, missing_assumption = "MCAR")
  a <- all_fit$omnibus; b <- cc_fit$omnibus
  cmp <- merge(a[, c("effect", "value", "p_boot")], b[, c("effect", "value", "p_boot")], by = "effect", suffixes = c("_all_available", "_complete_subjects"), all = TRUE)
  list(comparison = cmp, all_available = all_fit, complete_subjects = cc_fit,
       note = "A discrepancy is a sensitivity signal, not evidence for MCAR, MAR or MNAR.")
}
