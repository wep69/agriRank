# Planning, trends and covariate adjustment -------------------------------

#' Simulation-based power for the actual analysis workflow
#' @param generator Function of exactly one argument, the simulation index `i`,
#'   returning one simulated data frame. A generator written as `function()`
#'   fails with `unused argument (i)`, which is why the expected signature is
#'   stated here rather than implied.
#' @param analyzer Function receiving one simulated data frame and returning either a p-value or an agri_rank_fit.
#' @export
agri_power <- function(generator, analyzer, nsim = 1000, alpha = 0.05, seed = 1) {
  if (!is.function(generator) || !is.function(analyzer)) .agri_stop("`generator` and `analyzer` must be functions.")
  p <- .seed_eval(seed, vapply(seq_len(nsim), function(i) {
    dat <- generator(i); z <- tryCatch(analyzer(dat), error = function(e) NA_real_)
    if (is.numeric(z) && length(z) == 1L) return(z)
    if (inherits(z, "agri_rank_fit")) {
      tab <- z$omnibus; pc <- grep("p", tolower(names(tab)), value = TRUE)
      if (length(pc)) return(as.numeric(tab[[pc[length(pc)]]][1L]))
    }
    NA_real_
  }, numeric(1)))
  ok <- is.finite(p); phat <- mean(p[ok] < alpha)
  se <- sqrt(phat * (1 - phat) / sum(ok))
  structure(list(power = phat, mc_se = se, nsim_requested = nsim, nsim_success = sum(ok), alpha = alpha, p_values = p, seed = seed), class = "agri_power")
}

#' Ordered-treatment trend test using permutation of rank association
#' @param scores Optional numeric scores. When unnamed, they are taken in the
#'   order of `levels()` of the treatment, which is the behaviour of
#'   `stats::contr.poly()` and of most of base R.
#' @export
agri_trend <- function(design, treatment = NULL, scores = NULL, B = 4999, seed = 1) {
  if (!inherits(design, "agri_design")) .agri_stop("agri_design required.")
  texpr <- substitute(treatment)
  treatment <- if (identical(texpr, quote(NULL))) NULL else .capture_names(texpr, names(design$data))
  treatment <- treatment %||% design$quantitative[1L] %||% design$predictors[1L]
  if (is.null(treatment)) .agri_stop("A treatment variable is required.")
  y <- design$data[[design$response[1L]]]; tr <- design$data[[treatment]]
  trf <- .safe_factor(tr)
  lev <- levels(trf)
  s <- if (is.null(scores)) {
    if (is.numeric(tr)) tr else as.numeric(trf)
  } else {
    sc <- as.numeric(scores)
    # `as.numeric()` drops the names, so the names are read from the argument
    # itself and carried onto the converted vector. Losing them here sent a
    # correctly named `scores` down the unnamed branch and refused it.
    nm <- names(scores)
    if (is.null(nm)) {
      # Accept the vector in the order of levels(), which is how the scale is
      # naturally written, instead of failing inside stats::cor().
      if (length(sc) != length(lev))
        .agri_stop(sprintf("`scores` must have one value per level of `%s` (%d levels: %s), or names matching those levels.",
                           treatment, length(lev), paste(lev, collapse = ", ")))
      nm <- lev
    }
    names(sc) <- nm
    sc[match(as.character(trf), nm)]
  }
  if (anyNA(s)) .agri_stop(sprintf("`scores` has no value for every level of `%s`; supply names matching %s.",
                                   treatment, paste(lev, collapse = ", ")))
  stat_fun <- function(yy, ss) suppressWarnings(stats::cor(rank(yy, na.last = "keep"), ss, method = "pearson", use = "complete.obs"))
  obs <- stat_fun(y, s)
  dat <- design$data
  boot <- .seed_eval(seed, replicate(B, {
    sp <- s
    if (length(design$block)) {
      for (b in unique(dat[[design$block[1L]]])) {
        ii <- which(dat[[design$block[1L]]] == b); sp[ii] <- sample(sp[ii])
      }
    } else sp <- sample(sp)
    stat_fun(y, sp)
  }))
  p <- (1 + sum(abs(boot) >= abs(obs), na.rm = TRUE)) / (sum(is.finite(boot)) + 1)
  structure(list(design = design, method = "permutation rank trend", statistic = obs, p_value = p, B = B, treatment = treatment, seed = seed,
       note = if (length(design$block)) "Scores permuted within blocks." else "Scores permuted across independent units."), class = "agri_trend")
}

#' Permutation ANCOVA adapter
#'
#' Covariates are treated as nuisance/adjustment variables in a permutation
#' linear-model analysis. `rank_response=TRUE` analyzes response mid-ranks;
#' set FALSE for a classical Freedman-Lane permutation ANCOVA on the original scale.
#' @param nperm Number of permutations. The former name `np` is kept as a
#'   deprecated alias, because in a nonparametric package `np` reads as a
#'   switch rather than as a count.
#' @export
agri_ancova <- function(formula, data, covariates, block = NULL, nperm = 4999, seed = 1, rank_response = TRUE, np = NULL, ...) {
  if (!is.null(np)) {
    .agri_warn("`np` was renamed to `nperm`: it is the number of permutations, not a switch for nonparametric analysis.")
    nperm <- np
  }
  if (!is.numeric(nperm) || length(nperm) != 1L || !is.finite(nperm) || nperm < 1)
    .agri_stop("`nperm` must be a single positive number of permutations, e.g. nperm = 4999.")
  nperm <- as.integer(round(nperm))
  .require_pkg("permuco", "permutation ANCOVA")
  covars <- .capture_names(substitute(covariates), names(data))
  response <- .response_names(formula)[1L]
  terms0 <- .term_labels(formula)
  bexpr <- substitute(block)
  block_nm <- if (identical(bexpr, quote(NULL))) NULL else .capture_names(bexpr, names(data))
  .check_vars(unique(c(response, all.vars(formula[[3L]]), covars, block_nm)), data)
  dat <- data
  yname <- response
  if (rank_response) {
    yname <- ".agri_rank_y"
    dat[[yname]] <- rank(dat[[response]], na.last = "keep", ties.method = "average")
  }
  rhs <- unique(c(block_nm, covars, terms0))
  f <- stats::as.formula(paste(yname, "~", paste(rhs, collapse = " + ")))
  z <- .seed_eval(seed, permuco::aovperm(f, data = dat, np = nperm, method = "freedman_lane", ...))
  structure(list(method = if (rank_response) "Freedman-Lane permutation ANCOVA on response mid-ranks" else "Freedman-Lane permutation ANCOVA",
       formula = f, covariates = covars, block = block_nm, response = response, seed = seed,
       nperm = nperm,
       # permuco splits the p-value into parametric and resampled and reports a
       # Residuals row; the canonical columns make fit$omnibus$p_value answer the
       # same way here as in agri_rank(). See finding 7.
       omnibus = .agri_omnibus_standardize(tryCatch(as.data.frame(z$table), error = function(e) NULL),
                                           statistic = "F"),
       raw = z, call = match.call()),
       class = "agri_ancova_fit")
}
