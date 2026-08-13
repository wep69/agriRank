# Missing-data characterization -------------------------------------------

#' Characterize missing responses without silently imputing or deleting data
#' @param x agri_design or data.frame.
#' @param response Response name when x is a data frame.
#' @param subject Subject name for repeated data.
#' @param within Within-subject factor names.
#' @export
agri_missing_report <- function(x, response = NULL, subject = NULL, within = NULL) {
  between <- NULL
  if (inherits(x, "agri_design")) {
    dat <- x$data
    response <- response %||% x$response[1L]
    subject <- subject %||% x$subject
    within <- within %||% x$within
    between <- unique(c(x$block, setdiff(x$predictors, x$within %||% character())))
  } else {
    dat <- as.data.frame(x)
  }
  if (is.null(response) || !response %in% names(dat)) .agri_stop("A valid `response` is required.")
  miss <- is.na(dat[[response]])
  out <- list(
    response = response,
    n_rows = nrow(dat),
    n_missing = sum(miss),
    missing_rate = mean(miss),
    missing_rows = which(miss),
    assumption_note = "The missingness mechanism cannot be established from observed data alone. MCAR/MAR/MNAR assumptions require scientific justification and sensitivity analysis."
  )

  if (length(subject) && length(within)) {
    .check_vars(c(subject, within), dat)
    sid_raw <- .interaction_key(dat, subject)
    sid <- if (length(between)) interaction(.interaction_key(dat, between), sid_raw, drop = TRUE, lex.order = TRUE, sep = "@@") else sid_raw
    wk <- .interaction_key(dat, within)
    subjects <- levels(sid)
    occasions <- levels(wk)
    M <- matrix(NA, nrow = length(subjects), ncol = length(occasions), dimnames = list(subjects, occasions))
    for (i in seq_len(nrow(dat))) M[as.character(sid[i]), as.character(wk[i])] <- !miss[i]
    M[is.na(M)] <- FALSE
    nobs_subj <- rowSums(M)
    patterns <- apply(M, 1L, function(z) paste(as.integer(z), collapse = ""))
    # Monotone dropout: once missing begins in the declared within-factor order, no later observation returns.
    is_monotone <- if (length(within) == 1L) apply(M, 1L, function(z) {
      if (all(z) || !any(z)) return(TRUE)
      first_miss <- match(FALSE, z)
      !any(z[seq.int(first_miss, length(z))])
    }) else rep(NA, nrow(M))
    out$repeated <- list(
      n_subjects = nrow(M),
      n_occasions = ncol(M),
      complete_subjects = sum(nobs_subj == ncol(M)),
      incomplete_subjects = sum(nobs_subj < ncol(M)),
      subjects_with_no_observed_response = sum(nobs_subj == 0L),
      observed_by_occasion = colSums(M),
      missing_rate_by_occasion = 1 - colMeans(M),
      pattern_counts = sort(table(patterns), decreasing = TRUE),
      monotone_subjects = if (all(is.na(is_monotone))) NA_integer_ else sum(is_monotone, na.rm = TRUE),
      nonmonotone_subjects = if (all(is.na(is_monotone))) NA_integer_ else sum(!is_monotone, na.rm = TRUE),
      observation_matrix = M
    )
  }
  class(out) <- "agri_missing_report"
  out
}
