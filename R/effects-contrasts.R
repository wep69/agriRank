# Effects and contrasts ----------------------------------------------------

.pair_effect <- function(x, y, conf.level = 0.95, B = 0, seed = NULL) {
  x <- x[is.finite(x)]; y <- y[is.finite(y)]
  nx <- length(x); ny <- length(y)
  if (!nx || !ny) return(c(A = NA, cliff_delta = NA, hodges_lehmann = NA, lower = NA, upper = NA))
  r <- rank(c(x, y), ties.method = "average")
  U <- sum(r[seq_len(nx)]) - nx * (nx + 1) / 2
  A <- U / (nx * ny)
  diffs_n <- nx * ny
  if (diffs_n <= 1e6) hl <- stats::median(as.vector(outer(x, y, "-"))) else {
    hl <- .seed_eval(seed %||% 1, stats::median(x[sample.int(nx, 2000, TRUE)] - y[sample.int(ny, 2000, TRUE)]))
  }
  lo <- hi <- NA_real_
  if (B > 0) {
    Ab <- .seed_eval(seed %||% 1, replicate(B, {
      xb <- sample(x, nx, TRUE); yb <- sample(y, ny, TRUE); rr <- rank(c(xb, yb)); (sum(rr[seq_len(nx)]) - nx*(nx+1)/2)/(nx*ny)
    }))
    al <- 1 - conf.level
    ci <- stats::quantile(Ab, c(al/2, 1-al/2), na.rm = TRUE, names = FALSE)
    lo <- ci[1]; hi <- ci[2]
  }
  c(A = A, cliff_delta = 2*A - 1, hodges_lehmann = hl, lower = lo, upper = hi)
}

#' Effect estimates
#' @export
agri_effects <- function(x, ci = FALSE, level = 0.95, B = if (ci) 999 else 0, seed = 1) {
  if (!inherits(x, "agri_rank_fit")) .agri_stop("`x` must be an agri_rank_fit.")
  if (!is.null(x$engine$effects)) return(x$engine$effects)
  dat <- x$design$data; y <- x$response; trt <- x$design$predictors
  if (!length(trt)) return(data.frame())
  cell <- .interaction_key(dat, trt)
  lev <- levels(cell)
  out <- lapply(lev, function(g) {
    z <- dat[[y]][cell == g]; z <- z[!is.na(z)]
    data.frame(cell = g, n = length(z), median = stats::median(z), mean_rank = mean(rank(dat[[y]], na.last = "keep")[cell == g], na.rm = TRUE), stringsAsFactors = FALSE)
  })
  do.call(rbind, out)
}

.make_pairwise_C <- function(engine, by = NULL, factor = NULL) {
  grid <- engine$prep$cell_grid
  p <- engine$p_vector
  if (is.null(factor)) factor <- tail(engine$prep$within, 1L)
  if (!factor %in% names(grid)) .agri_stop("Requested contrast factor is not represented in repeated-measures cell grid.")
  strata_vars <- by %||% setdiff(names(grid), factor)
  if (!length(strata_vars)) strata <- factor(rep("all", nrow(grid))) else strata <- .interaction_key(grid, strata_vars)
  rows <- list(); labs <- character(); z <- 1L
  for (s in levels(strata)) {
    idx <- which(strata == s)
    vals <- unique(as.character(grid[[factor]][idx]))
    if (length(vals) < 2L) next
    cmb <- combn(vals, 2L, simplify = FALSE)
    for (cc in cmb) {
      i1 <- idx[as.character(grid[[factor]][idx]) == cc[1L]][1L]
      i2 <- idx[as.character(grid[[factor]][idx]) == cc[2L]][1L]
      r <- numeric(length(p)); r[i1] <- 1; r[i2] <- -1
      rows[[z]] <- r; labs[z] <- paste0(if (s == "all") "" else paste0(s, ": "), cc[1L], " - ", cc[2L]); z <- z + 1L
    }
  }
  C <- do.call(rbind, rows); rownames(C) <- labs; C
}

#' Pairwise comparisons
#' @param x agri_rank_fit.
#' @param by Conditioning factor(s). For ordinary independent/block designs,
#'   comparisons are formed within levels of `by`; for native repeated wild fits,
#'   `by` defines repeated-measures strata.
#' @param factor Factor to compare for native repeated wild fits.
#' @param adjust Multiplicity method for ordinary comparisons.
#' @export
agri_pairs <- function(x, by = NULL, factor = NULL, method = c("wilcoxon", "conover"), adjust = "holm", B = NULL, seed = NULL, level = 0.95, cld = FALSE, alpha = 0.05) {
  if (!inherits(x, "agri_rank_fit")) .agri_stop("`x` must be an agri_rank_fit.")
  method <- match.arg(method)
  # Letters summarize whichever comparison table this call produces, so the
  # request is simply forwarded to the route that builds it.
  if (identical(method, "conover"))
    return(agri_conover(x, by = by, factor = factor, adjust = adjust,
                        cld = cld, alpha = alpha))
  if (inherits(x$engine, "agri_incomplete_wild")) {
    C <- .make_pairwise_C(x$engine, by = by, factor = factor)
    out <- .wild_contrast_maxT(x$engine, C, B = B, seed = seed, level = level)
    if (isTRUE(cld)) {
      attr(out, "cld") <- .cld_from_pairs(out, alpha = alpha)
      attr(out, "cld_alpha") <- alpha
    }
    return(out)
  }
  if (tolower(x$method) == "art" && requireNamespace("emmeans", quietly = TRUE)) {
    .agri_warn("For multifactor ART contrasts, ARTool's ART-C procedure is preferred. The generic comparisons below operate on observed treatment cells and preserve blocks when a complete paired block comparison is available.")
  }
  dat <- x$design$data; y <- x$response
  compare_vars <- setdiff(x$design$predictors, by %||% character())
  if (length(compare_vars) != 1L && is.null(by)) {
    # Treat factorial combinations as treatment cells. The user can request
    # scientifically clearer simple effects with `by=`.
    cell <- .interaction_key(dat, x$design$predictors)
    dat$.agri_cell <- cell; compare_var <- ".agri_cell"
  } else if (length(compare_vars) == 1L) compare_var <- compare_vars
  else {
    cell <- .interaction_key(dat, compare_vars)
    dat$.agri_cell <- cell; compare_var <- ".agri_cell"
  }
  strata <- if (is.null(by) || !length(by)) factor(rep("all", nrow(dat))) else .interaction_key(dat, by)
  ans <- list(); z <- 1L
  for (st in levels(strata)) {
    ds <- dat[strata == st, , drop = FALSE]
    grp <- .safe_factor(ds[[compare_var]])
    vals <- levels(grp)
    if (length(vals) < 2L) next
    cmb <- combn(vals, 2L, simplify = FALSE)
    for (cc in cmb) {
      d1 <- ds[grp == cc[1L], , drop = FALSE]; d2 <- ds[grp == cc[2L], , drop = FALSE]
      paired <- FALSE; wt <- NULL; ef <- c(A=NA, cliff_delta=NA, hodges_lehmann=NA)
      if (length(x$design$block) == 1L) {
        b <- x$design$block[1L]
        # Pair only when each block contributes at most one observation to each compared cell.
        if (!anyDuplicated(d1[[b]]) && !anyDuplicated(d2[[b]])) {
          m <- merge(d1[c(b, y)], d2[c(b, y)], by = b, suffixes = c(".1", ".2"))
          m <- m[stats::complete.cases(m), , drop = FALSE]
          if (nrow(m) >= 2L) {
            paired <- TRUE
            wt <- tryCatch(stats::wilcox.test(m[[paste0(y,".1")]], m[[paste0(y,".2")]], paired = TRUE, exact = FALSE, conf.int = FALSE), error = function(e) NULL)
            dif <- m[[paste0(y,".1")]] - m[[paste0(y,".2")]]
            ef["hodges_lehmann"] <- stats::median(dif)
          }
        }
      }
      if (!paired) {
        x1 <- d1[[y]]; x2 <- d2[[y]]
        wt <- tryCatch(stats::wilcox.test(x1, x2, exact = FALSE), error = function(e) NULL)
        ef <- .pair_effect(x1, x2)
      }
      ans[[z]] <- data.frame(
        stratum = st, group1 = cc[1L], group2 = cc[2L], paired_by_block = paired,
        A = unname(ef["A"]), cliff_delta = unname(ef["cliff_delta"]),
        hodges_lehmann = unname(ef["hodges_lehmann"]),
        p_value = if (is.null(wt)) NA_real_ else wt$p.value,
        stringsAsFactors = FALSE
      )
      z <- z + 1L
    }
  }
  if (!length(ans)) return(data.frame())
  ans <- do.call(rbind, ans); ans$p_adjusted <- .p_adjust(ans$p_value, adjust)
  if (isTRUE(cld)) {
    attr(ans, "cld") <- .cld_from_pairs(ans, alpha = alpha)
    attr(ans, "cld_alpha") <- alpha
  }
  ans
}


.pmcmr_matrix_long <- function(z, stratum = "all", blocked = FALSE) {
  pmat <- z$p.value
  if (is.null(pmat)) .agri_stop("PMCMRplus result did not expose a p-value matrix.")
  smat <- z$statistic %||% matrix(NA_real_, nrow(pmat), ncol(pmat), dimnames = dimnames(pmat))
  rows <- list(); k <- 1L
  for (i in seq_len(nrow(pmat))) {
    for (j in seq_len(ncol(pmat))) {
      pv <- pmat[i, j]
      if (!is.na(pv)) {
        rows[[k]] <- data.frame(
          stratum = stratum,
          group1 = rownames(pmat)[i], group2 = colnames(pmat)[j],
          paired_by_block = blocked,
          statistic = if (all(dim(smat) == dim(pmat))) smat[i, j] else NA_real_,
          p_value = NA_real_, p_adjusted = as.numeric(pv),
          stringsAsFactors = FALSE
        )
        k <- k + 1L
      }
    }
  }
  if (!length(rows)) return(data.frame())
  do.call(rbind, rows)
}

#' Conover all-pairs comparisons
#'
#' @description
#' Performs Conover all-pairs rank comparisons using the official PMCMRplus
#' implementations. For one-way/CRD data, the Kruskal-type Conover procedure is
#' used. For a complete unreplicated RCBD, the Friedman-type Conover procedure
#' is used so block pairing is preserved. Factorial simple effects can be
#' requested through `by`.
#' @param x agri_rank_fit.
#' @param by Optional conditioning factor(s) for simple effects.
#' @param factor Optional factor to compare. If omitted, the non-conditioning
#'   treatment factor is used; factorial cells are compared when necessary.
#' @param adjust PMCMRplus p-value adjustment method.
#' @export
agri_conover <- function(x, by = NULL, factor = NULL, adjust = "holm", cld = FALSE,
                         alpha = 0.05) {
  if (!inherits(x, "agri_rank_fit")) .agri_stop("`x` must be an agri_rank_fit.")
  .require_pkg("PMCMRplus", "Conover multiple comparisons")
  if (inherits(x$engine, "agri_incomplete_wild")) .agri_stop("Conover comparisons are not defined for the native incomplete repeated-measures engine.")
  dat <- x$design$data; y <- x$response
  by <- by %||% character()
  compare_vars <- if (!is.null(factor)) factor else setdiff(x$design$predictors, by)
  if (!length(compare_vars)) .agri_stop("No treatment factor remains to compare after conditioning by `by`.")
  # Name the offending variable instead of failing inside a data-frame subscript.
  bad <- setdiff(c(compare_vars, by), names(dat))
  if (length(bad))
    .agri_stop("Unknown variable(s) requested for Conover comparisons: ", paste(bad, collapse = ", "))
  if (length(compare_vars) > 1L) {
    dat$.agri_cell <- .interaction_key(dat, compare_vars)
    compare_var <- ".agri_cell"
  } else compare_var <- compare_vars[1L]
  strata <- if (!length(by)) factor(rep("all", nrow(dat))) else .interaction_key(dat, by)
  ans <- list(); z <- 1L
  for (st in levels(strata)) {
    ds <- dat[strata == st, , drop = FALSE]
    keep <- stats::complete.cases(ds[, unique(c(y, compare_var, x$design$block)), drop = FALSE])
    ds <- ds[keep, , drop = FALSE]
    grp <- droplevels(.safe_factor(ds[[compare_var]]))
    if (nlevels(grp) < 2L) next
    if (!length(x$design$block)) {
      raw <- PMCMRplus::kwAllPairsConoverTest(x = ds[[y]], g = grp, p.adjust.method = "none")
      adj <- if (identical(adjust, "none")) raw else PMCMRplus::kwAllPairsConoverTest(x = ds[[y]], g = grp, p.adjust.method = adjust)
      tab <- .pmcmr_matrix_long(adj, stratum = st, blocked = FALSE)
      rawtab <- .pmcmr_matrix_long(raw, stratum = st, blocked = FALSE)
      key <- paste(rawtab$group1, rawtab$group2, sep = "\r")
      tab$p_value <- rawtab$p_adjusted[match(paste(tab$group1, tab$group2, sep = "\r"), key)]
      tab$method <- "Conover all-pairs after Kruskal-type ranking"
    } else if (length(x$design$block) == 1L) {
      b <- x$design$block[1L]
      tb <- table(ds[[b]], grp)
      if (!length(tb) || any(tb != 1L)) {
        .agri_stop("Friedman-type Conover requires a complete unreplicated block layout within each requested stratum. Use another design-aware contrast method for incomplete or replicated block cells.")
      }
      bl <- droplevels(.safe_factor(ds[[b]]))
      raw <- PMCMRplus::frdAllPairsConoverTest(y = ds[[y]], groups = grp, blocks = bl, p.adjust.method = "none")
      adj <- if (identical(adjust, "none")) raw else PMCMRplus::frdAllPairsConoverTest(y = ds[[y]], groups = grp, blocks = bl, p.adjust.method = adjust)
      tab <- .pmcmr_matrix_long(adj, stratum = st, blocked = TRUE)
      rawtab <- .pmcmr_matrix_long(raw, stratum = st, blocked = TRUE)
      if (!nrow(tab)) {
        # Perfectly concordant blocks leave the Friedman-type Conover statistic
        # undefined, because the within-block residual variation is zero.
        .agri_warn(sprintf("Stratum '%s': the Friedman-type Conover statistic is undefined because the block rankings agree perfectly. No pairwise comparison is reported for this stratum.", st))
        next
      }
      key <- paste(rawtab$group1, rawtab$group2, sep = "\r")
      tab$p_value <- rawtab$p_adjusted[match(paste(tab$group1, tab$group2, sep = "\r"), key)]
      tab$method <- "Conover all-pairs after Friedman-type ranking"
    } else .agri_stop("Conover adapter currently supports zero or one declared block factor.")
    if (nrow(tab)) { ans[[z]] <- tab; z <- z + 1L }
  }
  if (!length(ans)) return(data.frame())
  out <- do.call(rbind, ans); rownames(out) <- NULL
  attr(out, "adjust") <- adjust
  if (isTRUE(cld)) {
    # Letters summarize the same adjusted p-values, computed within each
    # stratum. They are an aid to reading the table, not a replacement for it.
    attr(out, "cld") <- .cld_from_pairs(out, alpha = alpha)
    attr(out, "cld_alpha") <- alpha
  }
  out
}

#' User-defined contrasts
#' @export
agri_contrast <- function(x, C, labels = NULL, B = NULL, seed = NULL, adjust = "holm", level = 0.95) {
  if (!inherits(x, "agri_rank_fit")) .agri_stop("`x` must be an agri_rank_fit.")
  C <- as.matrix(C)
  if (!is.null(labels)) rownames(C) <- labels
  if (inherits(x$engine, "agri_incomplete_wild")) return(.wild_contrast_maxT(x$engine, C, B = B, seed = seed, level = level))
  .agri_stop("General user-defined contrasts are currently implemented for the native repeated wild-rank engine. Use the backend object for other engines.")
}

# Letters are only interpretable within a stratum: two treatments compared in
# different simple-effect strata were never tested against each other, so a
# single global display would invite a comparison the data do not support.
.cld_from_pairs <- function(pr, alpha = 0.05) {
  .require_pkg("multcompView", "compact letter displays")
  pr <- as.data.frame(pr)

  # Contrast tables from the native wild-rank engine label each comparison as
  # "stratum: g1 - g2" instead of carrying group columns. Recover the groups so
  # that the same letter display serves every engine.
  if (!all(c("group1", "group2") %in% names(pr)) && "contrast" %in% names(pr)) {
    lab <- as.character(pr$contrast)
    has_st <- grepl(":", lab, fixed = TRUE)
    st <- ifelse(has_st, trimws(sub(":.*$", "", lab)), "all")
    rest <- ifelse(has_st, trimws(sub("^[^:]*:", "", lab)), lab)
    parts <- strsplit(rest, "\\s+-\\s+")
    if (any(lengths(parts) != 2L))
      .agri_stop("CLD requires all-pairs comparisons. This table holds contrasts that are not simple pairwise differences, so a letter display would misrepresent them.")
    pr$stratum <- st
    pr$group1 <- vapply(parts, `[`, character(1), 1L)
    pr$group2 <- vapply(parts, `[`, character(1), 2L)
  }
  if (!all(c("group1", "group2") %in% names(pr)))
    .agri_stop("CLD currently requires ordinary pairwise group comparisons.")

  # A letter display is only interpretable when every pair of the compared
  # groups was actually tested. A user-defined subset of contrasts would give
  # letters that suggest comparisons the analysis never made.
  strata0 <- if ("stratum" %in% names(pr)) as.character(pr$stratum) else rep("all", nrow(pr))
  for (st in unique(strata0)) {
    s <- pr[strata0 == st, , drop = FALSE]
    g <- unique(c(s$group1, s$group2))
    if (nrow(s) != choose(length(g), 2L))
      .agri_stop(sprintf("Stratum '%s' has %d comparison(s) among %d groups, but a letter display needs all %d pairs. Use the comparison table directly.",
                         st, nrow(s), length(g), choose(length(g), 2L)))
  }

  strata <- strata0
  out <- lapply(unique(strata), function(st) {
    s <- pr[strata == st, , drop = FALSE]
    # Multiplicity-adjusted p-values first: the max-T column of the native
    # engine is already simultaneous over the pairwise family.
    pv <- s$p_adjusted %||% s$p_adjusted_maxT %||% s$p_value
    keep <- is.finite(pv)
    if (!any(keep)) return(NULL)
    pv <- pv[keep]
    names(pv) <- paste(s$group1[keep], s$group2[keep], sep = "-")
    lt <- multcompView::multcompLetters(pv, threshold = alpha)$Letters
    data.frame(stratum = st, group = names(lt), letter = unname(lt),
               stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, out[!vapply(out, is.null, logical(1))])
  if (is.null(out)) .agri_stop("No finite adjusted p-value is available for a letter display.")
  if (all(out$stratum == "all")) out$stratum <- NULL
  rownames(out) <- NULL
  attr(out, "alpha") <- alpha
  out
}

#' Compact letter display
#' @export
agri_cld <- function(x, adjust = "holm", alpha = 0.05, ...) {
  # Accept either a fitted model, in which case the pairwise table is computed
  # here, or a table already produced by agri_pairs() or agri_conover().
  pr <- if (is.data.frame(x)) x else agri_pairs(x, adjust = adjust, ...)
  .cld_from_pairs(pr, alpha = alpha)
}
