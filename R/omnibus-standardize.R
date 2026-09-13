# Canonical omnibus shape and resampling budget ----------------------------
#
# Two findings of the 0.14.0 review live here, because both are about the same
# contract: what agri_rank() promises the caller and what the dispatched backend
# actually does. See RELATORIO-AO-AUTOR.md for the executed reproduction.
#
# Finding 1. `B` is documented as the number of resampling replicates, but it
#   reached only the native engines. The adapted backends were called with their
#   own defaults, so B = 199, B = 999 and B = 4999 returned the same p-value with
#   the same seed, and no warning said so. The aggravation is internal
#   inconsistency: agri_np_bootstrap(), from the same package, does honor the
#   budget it receives. `.agri_B_engines()` is the single list of engines that can
#   honor it, and `.agri_check_B()` refuses a budget too small to support the
#   p-value it will be asked to report.
#
# Finding 7. Each backend named its test table after the package it wraps: the
#   car-style `Pr(>F)`, permuco's two separate p columns, MANOVA.RM's `p-value`.
#   Generic code that reads `fit$omnibus$p_value` therefore received NULL in half
#   of the engines, without an error, and an empty table passed unnoticed inside a
#   long document. `.agri_omnibus_standardize()` adds the canonical columns
#   `effect`, `statistic`, `df` and `p_value` and KEEPS every native column beside
#   them, so no existing reader breaks.

# Engines able to honor the documented budget. `permuco` takes it as `np` and
# MANOVA.RM as `iter`; the native wild bootstrap takes it as `B` itself.
.agri_B_engines <- function() {
  c("incomplete_wild", "native_wild", "permuco", "manova.rm")
}

# The engine vocabulary of `agri_rank()`, in one place, so that a refusal can
# list what it would have accepted instead of only what it did not recognise.
.agri_engine_keys <- function() {
  c("auto", "kruskal", "friedman", "rankFD", "ART", "permuco", "nparLD",
    "MANOVA.RM", "incomplete_wild", "native_wild")
}

# Why an engine cannot honor it. The message must give the statistical reason and
# not only the symptom: "B was ignored" leaves the user unable to decide whether
# the analysis in front of them is still the one they asked for.
.agri_no_resampling_reason <- function(method) {
  switch(tolower(method),
    kruskal = "the Kruskal-Wallis test is an asymptotic rank-sum test and draws no resamples",
    friedman = "the Friedman test is an asymptotic rank-sum test and draws no resamples",
    rankfd = "rankFD computes an asymptotic ANOVA-type statistic and draws no resamples",
    art = "ARTool reports an F test on aligned ranks, which is not a permutation test",
    nparld = "nparLD computes an asymptotic ANOVA-type statistic and draws no resamples",
    sprintf("engine `%s` does not expose a resampling budget", method))
}

# A budget below 999 cannot resolve a p-value under 0.001, because the smallest
# attainable value is 1/(B + 1), and that is exactly the region where confirmatory
# agronomic statements live. A namespace scan for a resampling-related warning
# found none before this check existed.
.agri_check_B <- function(B) {
  if (!is.numeric(B) || length(B) != 1L || !is.finite(B) || B < 1)
    .agri_stop("`B` must be a single positive number of resampling replicates, e.g. B = 1999.")
  B <- as.integer(round(B))
  if (B < 999L)
    .agri_warn(sprintf(paste0("`B` = %d is too small for confirmatory resampling inference: the ",
                              "smallest attainable p-value is 1/(B + 1) = %.5f, so no result below ",
                              "that can be reported and the Monte Carlo error of any p-value near ",
                              "it is large. Use B >= 1999, or state the p floor explicitly when ",
                              "computing time limits the budget."),
                       B, 1 / (B + 1)))
  B
}

# Insert a default into the captured `...` list without overriding an argument the
# caller supplied. The adapted backends name the replicate count themselves, and
# an explicit `np` or `iter` must keep winning over `B`, which is what
# .agri_with_default() guarantees.
.agri_with_default <- function(dots, name, value) {
  if (is.null(dots[[name]])) dots[[name]] <- value
  dots
}

# The canonical reader for the p-values of any omnibus table of this package.
# `.agri_pvalues()` in sensitivity-batch.R keeps a heuristic for foreign tables;
# this one follows the documented contract and is what agri_p() exposes.
.agri_primary_p_col <- function(nms) {
  low <- tolower(nms)
  for (cand in c("p_value", "resampled p(>f)", "p-value", "p.value", "pvalue",
                 "pr(>f)", "p(>f)", "p_boot", "parametric p(>f)", "p_asymptotic")) {
    hit <- which(low == cand)
    if (length(hit)) return(nms[hit[1L]])
  }
  NULL
}

#' Standardize the omnibus table of a backend
#'
#' @description
#' Internal. Adds the canonical columns `effect`, `statistic`, `df` and `p_value`
#' to a backend test table and keeps every native column beside them. When a
#' backend reports more than one p-value, the resampled one is the canonical
#' value, because it is the one the user asked for by choosing a resampling
#' engine; the adapted p-value survives in its own column.
#'
#' Error-stratum rows (`Residuals`) are dropped: `omnibus` holds the tests, not
#' the ANOVA layout. The untouched table remains available in `fit$raw`.
#'
#' @param tab A data frame returned by an engine.
#' @param statistic,df,p_value Optional column names to use for the canonical
#'   columns, for engines whose own naming the heuristics would miss.
#' @return A data frame with the canonical columns first.
#' @noRd
.agri_omnibus_standardize <- function(tab, statistic = NULL, df = NULL, p_value = NULL) {
  if (is.null(tab)) return(NULL)
  tab <- as.data.frame(tab, stringsAsFactors = FALSE)
  if (!nrow(tab)) return(tab)
  nms <- names(tab)
  low <- tolower(nms)

  eff <- if ("effect" %in% nms) as.character(tab[["effect"]]) else .agri_effect_labels(tab)
  if (length(eff) != nrow(tab)) eff <- rep_len(eff, nrow(tab))

  keep <- !grepl("^residual", trimws(tolower(eff)))
  if (any(keep) && !all(keep)) {
    tab <- tab[keep, , drop = FALSE]
    eff <- eff[keep]
  }

  pick <- function(candidates, explicit) {
    if (!is.null(explicit) && explicit %in% nms) return(explicit)
    for (cand in tolower(candidates)) {
      hit <- which(low == cand)
      if (length(hit)) return(nms[hit[1L]])
    }
    NULL
  }

  out <- data.frame(effect = eff, stringsAsFactors = FALSE)
  st <- pick(c("statistic", "f value", "f", "value"), statistic)
  if (!is.null(st)) out$statistic <- suppressWarnings(as.numeric(tab[[st]]))
  dc <- pick(c("df", "df1"), df)
  if (!is.null(dc)) out$df <- suppressWarnings(as.numeric(tab[[dc]]))
  pc <- if (!is.null(p_value) && p_value %in% nms) p_value else .agri_primary_p_col(nms)
  if (is.null(pc)) {
    .agri_warn(sprintf(paste0("The backend returned an omnibus table with no recognizable p-value ",
                              "column (%s), so `p_value` is NA. Read the test from the columns the ",
                              "backend does provide."),
                       paste(nms, collapse = ", ")))
    out$p_value <- NA_real_
  } else {
    out$p_value <- suppressWarnings(as.numeric(tab[[pc]]))
  }
  for (nm in setdiff(names(tab), c("effect", "statistic", "df", "p_value")))
    out[[nm]] <- tab[[nm]]
  rownames(out) <- NULL
  out
}

#' P-values of an agriRank fit
#'
#' @description
#' Reads the p-value of every tested effect without requiring the caller to know
#' which backend produced the fit. Each backend names its own column: the
#' car-style `Pr(>F)`, MANOVA.RM's `p-value`, or permuco's separated
#' `parametric P(>F)` and `resampled P(>F)`. `agri_p()` hides that vocabulary
#' behind one function, so a report does not have to guess a column name.
#'
#' The canonical value is the resampled one whenever the engine resamples, and
#' the asymptotic one otherwise. `which = "parametric"` returns the parametric
#' p-value of a permutation backend, which is useful for showing how far the
#' permutation distribution moved the conclusion away from the F approximation.
#'
#' @param x An `agri_rank_fit`, an `agri_ancova_fit`, or an omnibus data frame.
#' @param which `"primary"` for the canonical p-value column, `"parametric"` for
#'   the parametric p-value of a permutation backend.
#' @return A data frame with columns `effect` and `p_value`.
#' @seealso [agri_rank()], [agri_table()]
#' @examples
#' set.seed(1)
#' d <- data.frame(trat = factor(rep(c("T1", "T2", "T3", "T4"), each = 8)))
#' d$y <- 10 + ifelse(d$trat == "T4", 1.5, 0) + stats::rnorm(nrow(d))
#' dg <- agri_design(y ~ trat, data = d, design = "crd")
#' fit <- agri_rank(dg, method = "kruskal")
#' agri_p(fit)
#' @export
agri_p <- function(x, which = c("primary", "parametric")) {
  which <- match.arg(which)
  tab <- if (is.data.frame(x)) x else x$omnibus
  if (is.null(tab))
    .agri_stop(paste0("This object carries no omnibus table, so it holds no p-value to extract. ",
                      "Permutation and asymptotic engines store one in `fit$omnibus`."))
  tab <- as.data.frame(tab, stringsAsFactors = FALSE)
  out <- data.frame(effect = .agri_effect_labels(tab), stringsAsFactors = FALSE)
  if (identical(which, "primary")) {
    out$p_value <- .agri_pvalues(tab)
    return(out)
  }
  low <- tolower(names(tab))
  hit <- which(low %in% c("parametric p(>f)", "parametric p", "parametric p-value"))
  if (!length(hit)) {
    .agri_warn(paste0("This backend reports a single p-value, so `which = \"parametric\"` returns ",
                      "the same value as `which = \"primary\"`. permuco is the backend that ",
                      "separates the parametric and the resampled p-value."))
    out$p_value <- .agri_pvalues(tab)
    return(out)
  }
  out$p_value <- suppressWarnings(as.numeric(tab[[hit[1L]]]))
  out
}
