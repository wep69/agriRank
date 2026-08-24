# Ranking data and the bridge to on-farm trials ------------------------------
#
# Two kinds of agronomic experiment produce rankings, and they meet here.
#
# The first is the ordinary blocked trial. Every rank-based test in this package
# already works on within-block ranks: Friedman and the Conover comparisons
# convert the measured response into ranks inside each block and never look at
# the measurements again. The ranks are therefore not a summary of the analysis,
# they *are* the analysis, and it is worth being able to see them.
#
# The second is the on-farm or tricot trial, in which each farmer receives a
# small subset of the varieties and returns an order rather than a measurement.
# Nothing was weighed, so there is no response to analyse; the order is the
# datum.
#
# The two differ in one respect that decides which methods are admissible.
# A blocked trial is *complete*: every variety appears in every block. A tricot
# trial is *incomplete*: each farmer ranks three varieties out of thirty. Rank
# sums and Friedman-type tests assume completeness, because a variety that
# appears only in easy blocks would otherwise collect flattering ranks for a
# reason that has nothing to do with the variety. This module checks
# completeness and refuses the tests that require it, rather than returning a
# number that quietly assumes it.
#
# What survives incompleteness is the pairwise record: how often variety i was
# placed above variety j among the blocks that contained both. That comparison
# is made within a block, so it is immune to differences between blocks, and it
# is purely combinatorial.

.rk_matrix <- function(data, item, block, value, direction) {
  sgn <- if (identical(direction, "higher_is_better")) -1 else 1
  sp <- split(seq_len(nrow(data)), data[[block]], drop = TRUE)
  out <- do.call(rbind, lapply(names(sp), function(b) {
    i <- sp[[b]]
    v <- sgn * as.numeric(data[[value]][i])
    ok <- is.finite(v)
    if (!any(ok)) return(NULL)
    data.frame(block = b,
               item = as.character(data[[item]][i][ok]),
               value = as.numeric(data[[value]][i][ok]),
               rank = rank(v[ok], ties.method = "average"),
               row.names = NULL, stringsAsFactors = FALSE)
  }))
  out
}

.rk_pairwise <- function(rk) {
  items <- sort(unique(rk$item))
  if (length(items) < 2L) return(NULL)
  sp <- split(rk, rk$block)
  pr <- utils::combn(items, 2L)
  do.call(rbind, lapply(seq_len(ncol(pr)), function(j) {
    a <- pr[1L, j]; b <- pr[2L, j]
    wa <- 0L; wb <- 0L; ti <- 0L
    for (z in sp) {
      ra <- z$rank[z$item == a]; rb <- z$rank[z$item == b]
      if (!length(ra) || !length(rb)) next
      if (ra[1L] < rb[1L]) wa <- wa + 1L
      else if (ra[1L] > rb[1L]) wb <- wb + 1L
      else ti <- ti + 1L
    }
    n <- wa + wb + ti
    if (!n) return(NULL)
    # Sign test on the blocks that separated the pair. Ties carry no
    # directional information and are excluded from the test but reported.
    m <- wa + wb
    p <- if (m > 0) stats::binom.test(wa, m, 0.5)$p.value else NA_real_
    data.frame(item_a = a, item_b = b, blocks = n,
               a_above_b = wa, b_above_a = wb, ties = ti,
               share_a = if (m > 0) wa / m else NA_real_,
               p_value = p,
               row.names = NULL, stringsAsFactors = FALSE)
  }))
}

#' Within-block rankings and the on-farm ranking bridge
#'
#' @description
#' Builds the within-block rankings that every rank-based test in the package
#' already computes internally, summarises them by item, and reports the
#' pairwise record of which item was placed above which. Accepts a measured
#' blocked experiment or rankings supplied directly, as from an on-farm or
#' tricot trial.
#'
#' @param formula `response ~ item`, where `response` is the measurement or, with
#'   `ranked = TRUE`, the rank already assigned within the block.
#' @param data Data frame in long format, one row per item per block.
#' @param block The block, farm, plot or judge inside which the ordering was
#'   made, as a name or a string.
#' @param direction `"higher_is_better"` when a larger measurement is a better
#'   result, `"lower_is_better"` otherwise. Ignored when `ranked = TRUE`.
#' @param ranked The response is already a rank inside its block, with 1 the
#'   best.
#' @param worth Fit a Plackett-Luce model as a model-based companion when the
#'   `PlackettLuce` package is installed. See details.
#' @details
#' The item summary is distribution free. `mean_rank` and `rank_sum` describe
#' position, `wins` counts the blocks in which the item came first, and
#' `pairwise` reports, for each pair, how many blocks placed one above the other
#' among those that contained both, with a sign-test p-value on the blocks that
#' separated them.
#'
#' **Completeness decides which methods are admissible.** A classical blocked
#' trial is complete: every item appears in every block, so rank sums are
#' comparable and the Friedman-type machinery of [agri_rank()] and
#' [agri_conover()] applies. An on-farm trial is usually incomplete: each farmer
#' ranks three varieties out of many. Rank sums are then not comparable, because
#' an item that happened to appear in favourable blocks collects flattering
#' ranks for a reason that has nothing to do with the item. This function
#' detects incompleteness, reports it, and declines to present rank sums as if
#' they were comparable. The pairwise record survives, because each comparison is
#' made inside a block.
#'
#' `worth = TRUE` adds Plackett-Luce worth estimates when that package is
#' available. This is reported separately and labelled, because it is a
#' likelihood model for rankings rather than a distribution-free summary: it
#' assumes the rankings arise from one common worth per item, which is what
#' allows it to combine incomplete rankings into a single scale. Where the
#' distribution-free summary and the worth estimates disagree, the assumption is
#' doing the work.
#' @return An object of class `agri_rankings`, a list with `summary`,
#'   `pairwise`, `rankings`, `worth` and `completeness`.
#' @references
#' Turner, H. L., van Etten, J., Firth, D. and Kosmidis, I. (2020). Modelling
#' rankings in R: the PlackettLuce package. *Computational Statistics*, 35,
#' 1027-1057. \doi{10.1007/s00180-020-00959-3}
#'
#' van Etten, J., Beza, E., Calderer, L. et al. (2019). First experiences with a
#' novel farmer citizen science approach. *Experimental Agriculture*, 55(S1),
#' 275-296. \doi{10.1017/S0014479716000739}
#' @seealso [agri_conover()] and [agri_cld()] for the formal comparison of a
#'   complete blocked trial, [agri_rank()] for the omnibus test.
#' @export
agri_rankings <- function(formula, data, block,
                          direction = c("higher_is_better", "lower_is_better"),
                          ranked = FALSE, worth = TRUE) {
  direction <- match.arg(direction)
  if (!inherits(formula, "formula"))
    .agri_stop("`formula` must be of the form response ~ item.")
  if (!is.data.frame(data)) data <- as.data.frame(data)

  resp <- .response_names(formula)[1L]
  item <- .predictor_names(formula)
  if (length(item) != 1L)
    .agri_stop("`formula` needs exactly one item variable, as response ~ item. ",
               "A ranking is an order among items inside one block.")
  if (missing(block))
    .agri_stop("`block =` is required: the farm, plot or judge inside which ",
               "the ordering was made. Without it there is no unit within ",
               "which the items were compared, and ranking the whole data set ",
               "at once would compare items across blocks, which is what ",
               "blocking exists to avoid.")
  bexpr <- substitute(block)
  bval <- tryCatch(block, error = function(e) NULL)
  block_nm <- if (is.character(bval)) bval else .capture_names(bexpr, names(data))
  if (length(block_nm) != 1L)
    .agri_stop("`block =` must name a single variable.")
  .check_vars(c(resp, item, block_nm), data)

  if (isTRUE(ranked)) {
    v <- data[[resp]]
    if (!is.numeric(v)) .agri_stop("With `ranked = TRUE` the response must be numeric.")
    if (any(v < 1, na.rm = TRUE))
      .agri_stop("Ranks must start at 1, where 1 is the best item in its block.")
    rk <- data.frame(block = as.character(data[[block_nm]]),
                     item = as.character(data[[item]]),
                     value = as.numeric(v), rank = as.numeric(v),
                     row.names = NULL, stringsAsFactors = FALSE)
    rk <- rk[is.finite(rk$rank), , drop = FALSE]
  } else {
    if (!is.numeric(data[[resp]]))
      .agri_stop("The response must be numeric to be ranked. If it is already ",
                 "a rank, pass `ranked = TRUE`.")
    rk <- .rk_matrix(data, item, block_nm, resp, direction)
  }
  if (is.null(rk) || !nrow(rk))
    .agri_stop("No block contained a usable ordering.")

  items <- sort(unique(rk$item))
  blocks <- unique(rk$block)
  tab <- table(rk$block, rk$item)
  complete <- all(tab == 1L)
  n_expected <- length(blocks) * length(items)

  smry <- do.call(rbind, lapply(items, function(it) {
    z <- rk[rk$item == it, , drop = FALSE]
    best <- vapply(split(rk$rank, rk$block)[z$block], min, numeric(1))
    data.frame(item = it, blocks = nrow(z),
               mean_rank = mean(z$rank),
               rank_sum = sum(z$rank),
               wins = sum(z$rank == best),
               win_share = mean(z$rank == best),
               row.names = NULL, stringsAsFactors = FALSE)
  }))
  smry <- smry[order(smry$mean_rank), , drop = FALSE]
  rownames(smry) <- NULL
  if (!complete) smry$rank_sum <- NA_real_

  pw <- .rk_pairwise(rk)

  wt <- NULL
  if (isTRUE(worth) && requireNamespace("PlackettLuce", quietly = TRUE))
    wt <- .rk_worth(rk, items)

  structure(
    list(summary = smry, pairwise = pw, rankings = rk, worth = wt,
         completeness = data.frame(
           blocks = length(blocks), items = length(items),
           observations = nrow(rk), expected_if_complete = n_expected,
           complete = complete, row.names = NULL)),
    response = resp, item = item, block = block_nm,
    direction = if (isTRUE(ranked)) "supplied ranks" else direction,
    ranked = isTRUE(ranked),
    class = "agri_rankings"
  )
}

# Plackett-Luce worth, a model-based companion. Kept in its own helper so that
# its absence changes nothing else.
.rk_worth <- function(rk, items) {
  ord <- lapply(split(rk, rk$block), function(z) {
    z <- z[order(z$rank), , drop = FALSE]
    z$item
  })
  R <- tryCatch(
    PlackettLuce::rankings(
      do.call(rbind, lapply(ord, function(o) {
        v <- rep(NA_integer_, length(items))
        names(v) <- items
        v[o] <- seq_along(o)
        v
      })), input = "rankings"),
    error = function(e) NULL)
  if (is.null(R)) return(NULL)
  m <- tryCatch(PlackettLuce::PlackettLuce(R), error = function(e) NULL)
  if (is.null(m)) return(NULL)
  cf <- tryCatch(stats::coef(m, log = FALSE), error = function(e) NULL)
  if (is.null(cf)) return(NULL)
  data.frame(item = names(cf), worth = as.numeric(cf) / sum(as.numeric(cf)),
             row.names = NULL, stringsAsFactors = FALSE)
}

#' @export
print.agri_rankings <- function(x, ...) {
  cat("Within-block rankings of `", attr(x, "item"), "` by `",
      attr(x, "response"), "` inside `", attr(x, "block"), "`\n", sep = "")
  cat("  Ordering: ", attr(x, "direction"), "\n", sep = "")
  cp <- x$completeness
  cat("  ", cp$blocks, " blocks, ", cp$items, " items, ", cp$observations,
      " orderings", sep = "")
  cat(if (cp$complete) "   (complete)" else
      sprintf("   (INCOMPLETE: %d of %d possible)", cp$observations,
              cp$expected_if_complete), "\n\n", sep = "")

  print(x$summary, row.names = FALSE, digits = 4)

  if (!cp$complete)
    cat("\nThe design is incomplete, so `rank_sum` is withheld: an item that\n",
        "appeared in favourable blocks would collect flattering ranks for a\n",
        "reason that has nothing to do with the item. `mean_rank` carries the\n",
        "same caution. The pairwise record below does not, because each\n",
        "comparison is made inside one block.\n", sep = "")
  else
    cat("\nEvery item appears in every block, so rank sums are comparable and\n",
        "the Friedman-type machinery applies. Use agri_conover() on the same\n",
        "data for the formal comparison with compact letters.\n", sep = "")

  if (!is.null(x$pairwise)) {
    cat("\nPairwise record, blocks containing both items:\n\n")
    p <- x$pairwise
    print(utils::head(p, 10), row.names = FALSE, digits = 4)
    if (nrow(p) > 10L) cat("  ... ", nrow(p) - 10L, "more pairs\n")
    cat("\n  `p_value` is a sign test on the blocks that separated the pair.\n",
        "  It is one comparison; adjust for multiplicity before reporting a\n",
        "  set of them.\n", sep = "")
  }

  if (!is.null(x$worth)) {
    cat("\nPlackett-Luce worth (model-based companion):\n\n")
    print(x$worth[order(-x$worth$worth), ], row.names = FALSE, digits = 4)
    cat("\n  This is a likelihood model for rankings, not a distribution-free\n",
        "  summary. It assumes one common worth per item, which is what lets\n",
        "  it combine incomplete rankings onto a single scale. Where it and\n",
        "  the table above disagree, the assumption is doing the work.\n",
        sep = "")
  } else if (!requireNamespace("PlackettLuce", quietly = TRUE)) {
    cat("\nPlackett-Luce worth not computed: the PlackettLuce package is not\n",
        "installed. Everything above is distribution free and does not need it.\n",
        sep = "")
  }
  invisible(x)
}

#' @export
plot.agri_rankings <- function(x, type = c("items", "pairwise"), ...) {
  .require_pkg("ggplot2", "ranking graphics")
  type <- match.arg(type)

  if (identical(type, "pairwise")) {
    if (is.null(x$pairwise))
      .agri_stop("There is no pair to display: at least two items are needed.")
    p <- x$pairwise
    d <- rbind(
      data.frame(a = p$item_a, b = p$item_b, share = p$share_a, n = p$blocks),
      data.frame(a = p$item_b, b = p$item_a, share = 1 - p$share_a, n = p$blocks))
    ord <- x$summary$item
    d$a <- factor(d$a, levels = ord); d$b <- factor(d$b, levels = rev(ord))
    return(
      ggplot2::ggplot(d, ggplot2::aes(x = a, y = b, fill = share)) +
        ggplot2::geom_tile(colour = "white") +
        ggplot2::scale_fill_gradient2(midpoint = 0.5, limits = c(0, 1),
                                      low = "#D55E00", mid = "grey92",
                                      high = "#0072B2") +
        ggplot2::labs(x = NULL, y = NULL, fill = "Share of\nblocks won",
                      title = "Who was placed above whom",
                      caption = "Each cell uses only the blocks that contained both items, so it is immune to differences between blocks.") +
        .agri_theme_or_minimal())
  }

  d <- data.frame(g = factor(x$summary$item, levels = rev(x$summary$item)),
                  x = x$summary$mean_rank, w = x$summary$win_share)
  ggplot2::ggplot(d, ggplot2::aes(x = x, y = g)) +
    ggplot2::geom_col(width = 0.6, fill = "grey35") +
    ggplot2::labs(x = "Mean rank within block (1 is best)",
                  y = attr(x, "item"),
                  title = "Position of each item inside its block",
                  caption = if (!x$completeness$complete)
                    "The design is incomplete; read this together with the pairwise record."
                  else "Complete design: mean ranks are directly comparable.") +
    .agri_theme_or_minimal()
}
