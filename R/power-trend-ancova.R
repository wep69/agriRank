# Planning, trends and covariate adjustment -------------------------------

#' Simulation-based power for the actual analysis workflow
#' @param generator Function with one argument `i` returning a simulated data frame.
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
#' @export
agri_trend <- function(design, treatment = NULL, scores = NULL, B = 4999, seed = 1) {
  if (!inherits(design, "agri_design")) .agri_stop("agri_design required.")
  texpr <- substitute(treatment)
  treatment <- if (identical(texpr, quote(NULL))) NULL else .capture_names(texpr, names(design$data))
  treatment <- treatment %||% design$quantitative[1L] %||% design$predictors[1L]
  if (is.null(treatment)) .agri_stop("A treatment variable is required.")
  y <- design$data[[design$response[1L]]]; tr <- design$data[[treatment]]
  s <- if (is.null(scores)) {
    if (is.numeric(tr)) tr else as.numeric(.safe_factor(tr))
  } else scores[match(as.character(tr), names(scores))]
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
#' @export
agri_ancova <- function(formula, data, covariates, block = NULL, np = 4999, seed = 1, rank_response = TRUE, ...) {
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
  z <- .seed_eval(seed, permuco::aovperm(f, data = dat, np = np, method = "freedman_lane", ...))
  structure(list(method = if (rank_response) "Freedman-Lane permutation ANCOVA on response mid-ranks" else "Freedman-Lane permutation ANCOVA",
       formula = f, covariates = covars, block = block_nm, response = response, seed = seed,
       omnibus = tryCatch(as.data.frame(z$table), error = function(e) NULL), raw = z, call = match.call()),
       class = "agri_ancova_fit")
}
