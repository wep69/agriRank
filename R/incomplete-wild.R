# Native incomplete repeated-measures rank wild bootstrap ----------------
# Implements the quadratic-form framework and Rademacher wild bootstrap
# described by Amro, Konietschke & Pauly (2024), Biometrical Journal 66:e70008.
# The inferential theory is MCAR-based. This implementation is marked
# experimental until independently benchmarked against the authors' reference code.

.prepare_incomplete_rm <- function(design, response = NULL) {
  if (length(design$block)) {
    .agri_stop("The native incomplete repeated-measures wild-rank engine currently does not support an RCBD/block nuisance stratum. This is rejected rather than silently ignoring the block. For complete blocked repeated measures use the permuco backend; for incomplete blocked repeated measures a validated block-aware extension is still required.")
  }
  if (!inherits(design, "agri_design")) .agri_stop("`design` must be an agri_design object.")
  if (!design$design %in% c("repeated", "longitudinal"))
    .agri_stop("The native incomplete repeated-measures engine requires design='repeated' or 'longitudinal'.")
  response <- response %||% design$response[1L]
  dat <- design$data
  between <- setdiff(design$predictors, design$within)
  within <- design$within
  subject <- design$subject
  if (!length(within)) .agri_stop("At least one within-subject factor is required.")

  # Force categorical representation for the rank-factorial engine.
  work <- dat
  for (v in unique(c(between, within))) work[[v]] <- .safe_factor(work[[v]])
  gkey <- .interaction_key(work, between)
  wkey <- .interaction_key(work, within)
  # A subject label is made group-specific to prevent accidental ID reuse across groups.
  skey_raw <- .interaction_key(work, subject)
  skey <- interaction(gkey, skey_raw, drop = TRUE, lex.order = TRUE, sep = "@@")

  group_levels <- levels(gkey)
  within_levels <- levels(wkey)
  a <- length(group_levels)
  d <- length(within_levels)
  if (length(between)) {
    expected_groups <- prod(vapply(work[between], function(z) length(unique(z)), integer(1)))
    if (a != expected_groups) .agri_stop("The native repeated wild-rank engine requires all between-subject factorial treatment combinations to be represented. Empty between-subject cells are not estimable by this engine.")
  }
  if (length(within)) {
    expected_within <- prod(vapply(work[within], function(z) length(unique(z)), integer(1)))
    if (d != expected_within) .agri_stop("The native repeated wild-rank engine requires the declared within-factor combination grid to be represented in the dataset. Individual measurements may be missing, but an entire declared within cell cannot be absent globally.")
  }
  groups <- vector("list", a)
  cell_rows <- vector("list", a * d)
  cell_pos <- 1L

  for (gi in seq_len(a)) {
    idxg <- which(gkey == group_levels[gi])
    subjects_g <- unique(as.character(skey[idxg]))
    Y <- matrix(NA_real_, nrow = length(subjects_g), ncol = d,
                dimnames = list(subjects_g, within_levels))
    row_between <- if (length(between)) work[idxg[1L], between, drop = FALSE] else data.frame(.group = "all")
    for (ii in idxg) {
      si <- match(as.character(skey[ii]), subjects_g)
      wi <- match(as.character(wkey[ii]), within_levels)
      Y[si, wi] <- work[[response]][ii]
    }
    # within cell metadata follows Y columns
    within_meta <- lapply(within_levels, function(wl) {
      ii <- idxg[match(wl, as.character(wkey[idxg]))]
      if (is.na(ii)) {
        # recover level components from any global row with this within key
        ii <- match(wl, as.character(wkey))
      }
      work[ii, within, drop = FALSE]
    })
    within_meta <- do.call(rbind, within_meta)
    for (wj in seq_len(d)) {
      cr <- cbind(row_between[rep(1L, 1L), , drop = FALSE], within_meta[wj, , drop = FALSE])
      cell_rows[[cell_pos]] <- cr
      cell_pos <- cell_pos + 1L
    }
    groups[[gi]] <- list(Y = Y, n = nrow(Y), level = group_levels[gi])
  }
  cell_grid <- droplevels(do.call(rbind, cell_rows))
  rownames(cell_grid) <- NULL
  list(groups = groups, cell_grid = cell_grid, between = between, within = within,
       all_factors = c(between, within), a = a, d = d, response = response)
}

.rank_rm_components <- function(prep) {
  groups <- prep$groups
  observed <- unlist(lapply(groups, function(g) as.vector(g$Y)), use.names = FALSE)
  observed <- observed[!is.na(observed)]
  N <- length(observed)
  if (N < 3L) .agri_stop("Too few observed repeated measurements.")
  # Global mid-ranks across all observed dependent and independent observations.
  all_vals <- unlist(lapply(groups, function(g) as.vector(g$Y)), use.names = FALSE)
  ranks_all <- rep(NA_real_, length(all_vals))
  ranks_all[!is.na(all_vals)] <- rank(all_vals[!is.na(all_vals)], ties.method = "average")
  pos <- 1L
  n_total_subjects <- sum(vapply(groups, `[[`, integer(1), "n"))
  p_list <- vector("list", length(groups))
  V_list <- vector("list", length(groups))
  R_list <- vector("list", length(groups))
  lambda_list <- vector("list", length(groups))
  meanR_list <- vector("list", length(groups))

  for (i in seq_along(groups)) {
    Y <- groups[[i]]$Y
    len <- length(Y)
    R <- matrix(ranks_all[pos:(pos + len - 1L)], nrow = nrow(Y), ncol = ncol(Y), dimnames = dimnames(Y))
    pos <- pos + len
    L <- !is.na(Y)
    lambda <- colSums(L)
    if (any(lambda < 2L)) .agri_stop(sprintf("Each group-by-within cell needs at least two observed measurements; group %s has insufficient data.", groups[[i]]$level))
    meanR <- vapply(seq_len(ncol(R)), function(j) mean(R[L[, j], j]), numeric(1))
    p <- vapply(seq_len(ncol(R)), function(j) mean((R[L[, j], j] - 0.5) / N), numeric(1))
    ni <- nrow(Y)
    Vi <- matrix(0, ncol(Y), ncol(Y))
    for (j in seq_len(ncol(Y))) {
      num <- ni * sum((R[L[, j], j] - meanR[j])^2)
      den <- N^2 * lambda[j] * (lambda[j] - 1)
      Vi[j, j] <- num / den
    }
    if (ncol(Y) > 1L) {
      for (j in seq_len(ncol(Y) - 1L)) for (jp in (j + 1L):ncol(Y)) {
        both <- L[, j] & L[, jp]
        Delta <- sum(both)
        den_core <- (lambda[j] - 1) * (lambda[jp] - 1) + Delta - 1
        if (den_core <= 0) {
          val <- NA_real_
        } else {
          num <- ni * sum((R[both, j] - meanR[j]) * (R[both, jp] - meanR[jp]))
          val <- num / (N^2 * den_core)
        }
        Vi[j, jp] <- Vi[jp, j] <- val
      }
    }
    p_list[[i]] <- p
    V_list[[i]] <- Vi
    R_list[[i]] <- R
    lambda_list[[i]] <- lambda
    meanR_list[[i]] <- meanR
  }
  if (any(!is.finite(unlist(V_list)))) .agri_stop("The covariance estimator is undefined for at least one cell pair; more observed subjects per repeated cell are required.")
  Vn <- .blockdiag(Map(function(V, g) (n_total_subjects / g$n) * V, V_list, groups))
  list(p = unlist(p_list, use.names = FALSE), Vn = Vn, V_list = V_list,
       R_list = R_list, lambda_list = lambda_list, meanR_list = meanR_list,
       N = N, n = n_total_subjects)
}

.qf_stats <- function(p, Vn, C, n) {
  C <- as.matrix(C)
  if (!nrow(C) || !ncol(C)) return(c(WTS = NA_real_, ATS = NA_real_, MATS = NA_real_, ATS_df = NA_real_))
  Tproj <- t(C) %*% .agri_ginv(C %*% t(C)) %*% C
  CV <- C %*% Vn %*% t(C)
  wts <- as.numeric(n * t(p) %*% t(C) %*% .agri_ginv(CV) %*% C %*% p)
  trTV <- .trace(Tproj %*% Vn)
  ats <- if (is.finite(trTV) && trTV > 0) as.numeric(n * t(p) %*% Tproj %*% p / trTV) else NA_real_
  denom_df <- .trace(Tproj %*% Vn %*% Tproj %*% Vn)
  fhat <- if (denom_df > 0) trTV^2 / denom_df else NA_real_
  Dn <- diag(diag(Vn), nrow(Vn))
  mats <- as.numeric(n * t(p) %*% t(C) %*% .agri_ginv(C %*% Dn %*% t(C)) %*% C %*% p)
  c(WTS = wts, ATS = ats, MATS = mats, ATS_df = fhat)
}

.wild_one <- function(prep, comp, C, weights = c("rademacher", "mammen", "normal", "poisson")) {
  weights <- match.arg(weights)
  rW <- function(n) switch(weights,
    rademacher = sample(c(-1, 1), n, replace = TRUE),
    mammen = {
      s5 <- sqrt(5); a <- -(s5 - 1) / 2; b <- (s5 + 1) / 2
      pr_a <- (s5 + 1) / (2 * s5)
      sample(c(a, b), n, replace = TRUE, prob = c(pr_a, 1 - pr_a))
    },
    normal = rnorm(n),
    poisson = rpois(n, 1) - 1
  )
  pstar_list <- vector("list", length(prep$groups))
  Vstar_list <- vector("list", length(prep$groups))
  for (i in seq_along(prep$groups)) {
    R <- comp$R_list[[i]]
    L <- !is.na(prep$groups[[i]]$Y)
    meanR <- comp$meanR_list[[i]]
    lambda <- comp$lambda_list[[i]]
    ni <- nrow(R)
    W <- rW(ni) # same subject multiplier across repeated coordinates
    Z <- sweep(R, 2L, meanR, "-")
    Zstar <- Z * W
    Zstar[!L] <- NA_real_
    meanZ <- vapply(seq_len(ncol(R)), function(j) mean(Zstar[L[, j], j]), numeric(1))
    pstar <- vapply(seq_len(ncol(R)), function(j) mean(Zstar[L[, j], j] / comp$N), numeric(1))
    Vi <- matrix(0, ncol(R), ncol(R))
    for (j in seq_len(ncol(R))) {
      num <- ni * sum((Zstar[L[, j], j] - meanZ[j])^2)
      den <- comp$N^2 * lambda[j] * (lambda[j] - 1)
      Vi[j, j] <- num / den
    }
    if (ncol(R) > 1L) {
      for (j in seq_len(ncol(R) - 1L)) for (jp in (j + 1L):ncol(R)) {
        both <- L[, j] & L[, jp]
        Delta <- sum(both)
        den_core <- (lambda[j] - 1) * (lambda[jp] - 1) + Delta - 1
        if (den_core <= 0) val <- NA_real_ else {
          num <- ni * sum((Zstar[both, j] - meanZ[j]) * (Zstar[both, jp] - meanZ[jp]))
          val <- num / (comp$N^2 * den_core)
        }
        Vi[j, jp] <- Vi[jp, j] <- val
      }
    }
    pstar_list[[i]] <- pstar
    Vstar_list[[i]] <- Vi
  }
  if (any(!is.finite(unlist(Vstar_list)))) return(c(WTS = NA, ATS = NA, MATS = NA, ATS_df = NA))
  Vstar <- .blockdiag(Map(function(V, g) (comp$n / g$n) * V, Vstar_list, prep$groups))
  .qf_stats(unlist(pstar_list, use.names = FALSE), Vstar, C, comp$n)
}

.term_contrasts_rm <- function(prep, terms = NULL) {
  all_f <- prep$all_factors
  if (!length(all_f)) return(list())
  if (is.null(terms)) {
    terms <- all_f
    if (length(all_f) > 1L) {
      for (k in 2:min(length(all_f), 3L)) {
        terms <- c(terms, apply(combn(all_f, k), 2L, paste, collapse = ":"))
      }
    }
  }
  out <- list()
  for (term in terms) {
    fs <- strsplit(term, ":", fixed = TRUE)[[1L]]
    if (!all(fs %in% all_f)) next
    C <- .effect_basis(prep$cell_grid, fs, all_f)
    if (nrow(C)) out[[term]] <- C
  }
  out
}

#' Wild-bootstrap rank inference for incomplete repeated measurements
#'
#' Implements WTS, ATS and MATS quadratic-form statistics with subject-level
#' Rademacher wild multipliers. The primary theory assumes MCAR. The default
#' reported bootstrap test is ATS because this procedure showed the best overall
#' small-sample behavior in the reference study. The implementation is marked
#' experimental pending independent numerical benchmarking against the authors'
#' reference implementation.
#'
#' @param design Repeated/longitudinal agri_design.
#' @param response Optional response name.
#' @param B Number of wild bootstrap replicates.
#' @param statistic ATS, WTS or MATS.
#' @param weights Wild multiplier distribution; Rademacher is recommended.
#' @param seed Reproducibility seed.
#' @param missing_assumption Declared missingness assumption.
#' @param correction Use (b+1)/(B+1) Monte Carlo correction.
#' @export
incomplete_wild_rank_test <- function(design, response = NULL, B = 1999,
                                      statistic = c("ATS", "WTS", "MATS"),
                                      weights = c("rademacher", "mammen", "normal", "poisson"),
                                      seed = 1, missing_assumption = c("unspecified", "MCAR", "MAR-sensitivity"),
                                      correction = TRUE, terms = NULL) {
  statistic <- match.arg(statistic)
  weights <- match.arg(weights)
  missing_assumption <- match.arg(missing_assumption)
  if (B < 199) .agri_warn("B < 199 gives coarse Monte Carlo p-values; use >= 999 for analysis and >= 4999 for final work when feasible.")
  prep <- .prepare_incomplete_rm(design, response)
  comp <- .rank_rm_components(prep)
  C_list <- .term_contrasts_rm(prep, terms %||% design$terms)
  if (!length(C_list)) .agri_stop("No estimable repeated-measures effects were identified.")
  miss_report <- agri_missing_report(design, response = response %||% design$response[1L])
  if (miss_report$n_missing > 0 && missing_assumption == "unspecified")
    .agri_warn("Incomplete repeated measurements detected. The native wild-rank engine is theoretically justified under MCAR; the missingness mechanism was not declared. Results are returned with this limitation recorded.")

  results <- vector("list", length(C_list)); names(results) <- names(C_list)
  boot_store <- vector("list", length(C_list)); names(boot_store) <- names(C_list)
  .seed_eval(seed, {
    for (nm in names(C_list)) {
      C <- C_list[[nm]]
      obs <- .qf_stats(comp$p, comp$Vn, C, comp$n)
      boot <- replicate(B, .wild_one(prep, comp, C, weights), simplify = "matrix")
      sb <- boot[statistic, ]
      p_boot <- .mc_p(sb, obs[statistic], correction = correction)
      results[[nm]] <- data.frame(
        effect = nm,
        statistic = statistic,
        value = unname(obs[statistic]),
        df = if (statistic == "WTS") qr(C)$rank else if (statistic == "ATS") unname(obs["ATS_df"]) else NA_real_,
        p_boot = p_boot,
        p_asymptotic = if (statistic == "WTS") stats::pchisq(obs["WTS"], df = qr(C)$rank, lower.tail = FALSE)
                       else if (statistic == "ATS") stats::pf(obs["ATS"], df1 = obs["ATS_df"], df2 = Inf, lower.tail = FALSE)
                       else NA_real_,
        stringsAsFactors = FALSE
      )
      boot_store[[nm]] <- sb
    }
  })
  out <- list(
    method = "incomplete repeated-measures rank wild bootstrap",
    statistic = statistic,
    weights = weights,
    B = B,
    seed = seed,
    missing_assumption = missing_assumption,
    omnibus = do.call(rbind, results),
    effects = data.frame(cell = seq_along(comp$p), prep$cell_grid,
                         relative_marginal_effect = comp$p, stringsAsFactors = FALSE),
    covariance = comp$Vn,
    p_vector = comp$p,
    contrasts = C_list,
    boot_statistics = boot_store,
    missing = miss_report,
    prep = prep,
    components = comp,
    reference = "Amro L, Konietschke F, Pauly M (2024). Biometrical Journal 66:e70008. doi:10.1002/bimj.70008",
    status = "experimental: formula-level implementation requires independent benchmark validation before confirmatory use"
  )
  class(out) <- c("agri_incomplete_wild", "agri_engine_fit")
  out
}

.wild_contrast_maxT <- function(engine, C, B = NULL, seed = NULL, weights = NULL, correction = TRUE, level = 0.95) {
  prep <- engine$prep; comp <- engine$components
  C <- as.matrix(C)
  est <- as.numeric(C %*% comp$p)
  var_est <- diag(C %*% comp$Vn %*% t(C)) / comp$n
  se <- sqrt(pmax(var_est, 0))
  z <- est / se
  B <- B %||% engine$B
  seed <- seed %||% engine$seed
  weights <- weights %||% engine$weights
  zstar <- matrix(NA_real_, nrow(C), B)
  .seed_eval(seed, {
    for (b in seq_len(B)) {
      # Generate p* and V* by using a dummy C that spans all requested contrasts.
      # We reproduce the internals because studentization is contrast-specific.
      groups <- prep$groups
      pstar_list <- vector("list", length(groups)); Vstar_list <- vector("list", length(groups))
      rW <- function(n) if (weights == "rademacher") sample(c(-1,1), n, TRUE) else if (weights == "normal") rnorm(n) else if (weights == "poisson") rpois(n,1)-1 else {
        s5 <- sqrt(5); a <- -(s5-1)/2; bb <- (s5+1)/2; pr <- (s5+1)/(2*s5); sample(c(a,bb),n,TRUE,prob=c(pr,1-pr))
      }
      for (i in seq_along(groups)) {
        R <- comp$R_list[[i]]; L <- !is.na(groups[[i]]$Y); meanR <- comp$meanR_list[[i]]; lambda <- comp$lambda_list[[i]]; ni <- nrow(R)
        W <- rW(ni); Z <- sweep(R, 2L, meanR, "-"); Zs <- Z * W; Zs[!L] <- NA_real_
        mz <- vapply(seq_len(ncol(R)), function(j) mean(Zs[L[,j],j]), numeric(1))
        ps <- vapply(seq_len(ncol(R)), function(j) mean(Zs[L[,j],j]/comp$N), numeric(1))
        Vi <- matrix(0,ncol(R),ncol(R))
        for(j in seq_len(ncol(R))) Vi[j,j] <- ni*sum((Zs[L[,j],j]-mz[j])^2)/(comp$N^2*lambda[j]*(lambda[j]-1))
        if(ncol(R)>1L) for(j in seq_len(ncol(R)-1L)) for(jp in (j+1L):ncol(R)){
          both <- L[,j]&L[,jp]; Delta <- sum(both); den <- (lambda[j]-1)*(lambda[jp]-1)+Delta-1
          Vi[j,jp] <- Vi[jp,j] <- if(den<=0) NA_real_ else ni*sum((Zs[both,j]-mz[j])*(Zs[both,jp]-mz[jp]))/(comp$N^2*den)
        }
        pstar_list[[i]] <- ps; Vstar_list[[i]] <- Vi
      }
      if (any(!is.finite(unlist(Vstar_list)))) next
      Vs <- .blockdiag(Map(function(V,g)(comp$n/g$n)*V,Vstar_list,groups)); ps <- unlist(pstar_list,use.names=FALSE)
      ses <- sqrt(pmax(diag(C %*% Vs %*% t(C))/comp$n,0)); zstar[,b] <- as.numeric(C%*%ps)/ses
    }
  })
  maxstar <- apply(abs(zstar), 2L, max, na.rm = TRUE)
  maxstar <- maxstar[is.finite(maxstar)]
  if (!length(maxstar)) .agri_stop("All wild-bootstrap contrast replicates failed studentization; inspect sparse repeated cells.")
  crit <- stats::quantile(maxstar, level, names = FALSE, type = 8)
  padj <- vapply(abs(z), function(v) .mc_p(maxstar, v, correction), numeric(1))
  data.frame(contrast = rownames(C) %||% paste0("C", seq_len(nrow(C))), estimate = est, SE = se,
             statistic = z, p_adjusted_maxT = padj,
             lower = est - crit * se, upper = est + crit * se, stringsAsFactors = FALSE)
}
