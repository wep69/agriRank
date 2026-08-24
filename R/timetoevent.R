# Nonparametric time-to-event for germination and emergence ------------------
#
# Germination and emergence data are counted, not measured. A tray is inspected
# on day 3, day 5, day 7; a seed that germinated between two inspections is
# known only to have done so somewhere inside that interval, and a seed that
# never germinates is not a missing value but an observation: it is censored at
# the end of the trial.
#
# The routine practice is to convert the counts into cumulative percentages and
# fit a curve to them as if they were measurements. That does three things at
# once, all of them wrong:
#
#   - it treats an interval-censored event time as if it had been observed;
#   - it treats successive cumulative percentages as independent, when each one
#     contains all the earlier ones;
#   - it either drops the seeds that never germinated or forces the curve up to
#     100%, which invents a germination time for seeds that never had one.
#
# The nonparametric maximum likelihood estimator of the time-to-event
# distribution handles all three. It uses the intervals as intervals, it does
# not assume a functional form for the germination curve, and it leaves mass on
# "never", which is where the ungerminated seeds belong.
#
# The agronomic consequence is that a seed lot has two separate properties, and
# a single number cannot carry both: how much of the lot germinates at all,
# which is capacity, and how fast the germinating part gets there, which is
# vigour. This module reports them separately and refuses to report a median
# germination time for a lot that never reaches half.

.tte_parse_turnbull <- function(fit, levels_expected) {
  # The backend computes a naive standard error as sqrt(p(1-p)) and warns when
  # the final interval has p = 1. That is the censored mass, which has no such
  # standard error by construction, so the warning carries no information here.
  s <- suppressWarnings(summary(fit))
  cf <- s$coefficients
  if (is.null(cf) || !nrow(cf)) return(NULL)
  rn <- rownames(cf)
  # Row names look like "creticum.(3,4]" or, with one curve, "(3,4]".
  has_lev <- length(levels_expected) > 1L ||
    any(vapply(levels_expected, function(l) any(startsWith(rn, paste0(l, "."))),
               logical(1)))
  lev <- rep(levels_expected[1L], length(rn))
  itv <- rn
  if (has_lev) {
    for (l in levels_expected) {
      k <- startsWith(rn, paste0(l, "."))
      lev[k] <- l
      itv[k] <- substring(rn[k], nchar(l) + 2L)
    }
  }
  num <- gsub("[]()]", "", itv)
  parts <- strsplit(num, ",", fixed = TRUE)
  lo <- suppressWarnings(as.numeric(vapply(parts, `[`, character(1), 1L)))
  hi <- suppressWarnings(as.numeric(vapply(parts, `[`, character(1), 2L)))
  data.frame(level = lev, start = lo, end = hi,
             count = as.numeric(cf[, "count"]),
             mass = as.numeric(cf[, "pdf"]),
             cdf = as.numeric(cf[, "cdf"]),
             row.names = NULL, stringsAsFactors = FALSE)
}

.tte_quantiles <- function(fit, probs, restricted) {
  q <- tryCatch(suppressWarnings(
    stats::quantile(fit, probs = probs, restricted = restricted,
                    display = FALSE)), error = function(e) NULL)
  if (is.null(q)) return(NULL)
  q <- as.data.frame(q)
  data.frame(label = rownames(q), value = as.numeric(q[, 1L]),
             row.names = NULL, stringsAsFactors = FALSE)
}

.tte_pick <- function(qd, lev, p) {
  if (is.null(qd)) return(NA_real_)
  tag <- paste0(format(100 * p, trim = TRUE), "%")
  i <- match(paste0(lev, ".", tag), qd$label)
  if (is.na(i)) i <- match(tag, qd$label)
  if (is.na(i)) NA_real_ else qd$value[i]
}

#' Nonparametric time-to-event analysis for germination and emergence
#'
#' @description
#' Estimates the time-to-event distribution of a germination, emergence or
#' flowering trial without assuming a functional form for the curve, using the
#' intervals between inspections as intervals and keeping the subjects that
#' never had the event.
#'
#' @param formula Interval-censored counts, as `count ~ start + end`. `start` is
#'   the last inspection at which the subject had not yet responded and `end`
#'   the first at which it had; `end = Inf` marks a subject that never
#'   responded.
#' @param data Data frame.
#' @param by Optional treatment, cultivar, lot or species whose curves are to be
#'   compared, as a name or a string.
#' @param units Experimental unit, typically the dish, tray or plot. Seeds in
#'   one dish share its water, its temperature and its handling, so they are not
#'   independent, and the permutation test below resamples whole units rather
#'   than individual seeds. Omitting it is possible but rarely correct.
#' @param probs Quantiles of the time-to-event distribution to report.
#' @param B Permutation replicates for the comparison of curves.
#' @param seed Random seed.
#' @param scores Rank scores for the permutation test: `"wmw"` for a
#'   Wilcoxon-type score, `"logrank1"` or `"logrank2"` for log-rank types.
#' @param method `"npmle"` for the nonparametric maximum likelihood estimator,
#'   `"kde"` for a kernel estimator of the same distribution. Parametric
#'   germination models are deliberately not offered here.
#' @details
#' Two properties of a seed lot are routinely collapsed into one number and
#' should not be. **Capacity** is how much of the lot responds at all, reported
#' here as `responded`, one minus the mass the estimator leaves on "never".
#' **Speed** is how quickly the responding part gets there, reported as the
#' quantiles.
#'
#' Quantiles are given twice. `t50_of_responders` is computed among the subjects
#' that did respond and always exists. `t50_of_lot` is computed on the whole lot
#' and is `NA` when the lot never reaches that fraction: a lot in which 32% of
#' seeds germinate has no median germination time, and reporting one would
#' require inventing germination for seeds that never germinated. The `NA` is the
#' answer, not a failure.
#'
#' The comparison of curves is a permutation test on rank scores, so it assumes
#' no distribution. With `units`, whole dishes are permuted, which is the level
#' at which the randomization actually happened.
#' @return An object of class `agri_np_tte`, a list with `summary`, `test`,
#'   `curve`, `intervals` and `fit`.
#' @references
#' Onofri, A., Mesgaran, M. B. and Ritz, C. (2022). A unified framework for the
#' analysis of germination, emergence, and other time-to-event data in weed
#' science. *Weed Science*, 70(3), 259-271. \doi{10.1017/wsc.2022.8}
#'
#' Turnbull, B. W. (1976). The empirical distribution function with arbitrarily
#' grouped, censored and truncated data. *Journal of the Royal Statistical
#' Society Series B*, 38(3), 290-295.
#' @seealso [agri_np_regression()] for a measured response over a gradient,
#'   [agri_rank()] for a measured response in a declared design.
#' @export
agri_np_timetoevent <- function(formula, data, by = NULL, units = NULL,
                                probs = c(0.1, 0.5, 0.9), B = 199L, seed = 1,
                                scores = c("wmw", "logrank1", "logrank2"),
                                method = c("npmle", "kde")) {
  .require_pkg("drcte", "nonparametric time-to-event analysis")
  scores <- match.arg(scores)
  method <- match.arg(method)
  if (!inherits(formula, "formula"))
    .agri_stop("`formula` must be a formula of the form count ~ start + end.")
  if (!is.data.frame(data)) data <- as.data.frame(data)

  cnt <- .response_names(formula)[1L]
  tm <- .predictor_names(formula)
  if (length(tm) != 2L)
    .agri_stop("`formula` needs exactly two time variables, as ",
               "count ~ start + end. `start` is the last inspection at which ",
               "the subject had not responded and `end` the first at which it ",
               "had; use Inf for a subject that never responded.")
  .check_vars(c(cnt, tm), data)

  bexpr <- substitute(by)
  bval <- tryCatch(by, error = function(e) NULL)
  by_nm <- if (identical(bexpr, quote(NULL))) NULL
           else if (is.character(bval)) bval else .capture_names(bexpr, names(data))
  uexpr <- substitute(units)
  uval <- tryCatch(units, error = function(e) NULL)
  un_nm <- if (identical(uexpr, quote(NULL))) NULL
           else if (is.character(uval)) uval else .capture_names(uexpr, names(data))
  if (length(by_nm) > 1L) .agri_stop("`by` must name a single variable.")
  if (length(un_nm) > 1L) .agri_stop("`units` must name a single variable.")
  .check_vars(c(by_nm, un_nm), data)

  s <- data[[tm[1L]]]; e <- data[[tm[2L]]]
  if (!is.numeric(s) || !is.numeric(e))
    .agri_stop("Both time variables must be numeric.")
  if (any(e <= s, na.rm = TRUE))
    .agri_stop("Every interval must have `end` strictly greater than `start`. ",
               "An inspection that records the same instant twice carries no ",
               "information about when the event happened.")
  if (any(data[[cnt]] < 0, na.rm = TRUE))
    .agri_stop("Counts cannot be negative.")
  if (!any(is.infinite(e)))
    .agri_warn("No row has `end = Inf`, so every subject is recorded as having ",
               "responded. If some seeds never germinated they must appear ",
               "with `end = Inf`, otherwise the lot is treated as fully ",
               "germinable and its capacity is overstated.")

  # drcte labels a single unnamed curve "1" in its row names, so the label used
  # to read its output is not always the label shown to the user.
  levs <- if (is.null(by_nm)) "all" else levels(as.factor(data[[by_nm]]))
  dlevs <- if (is.null(by_nm)) "1" else levs
  multi <- length(levs) > 1L

  # drmte() captures both `curveid` and `fct` unevaluated. `curveid` is looked
  # up inside `data`, and `fct` is identified by deparsing the call and matching
  # the literal text "NPMLE(" or "KDE(", so a namespace-qualified
  # `drcte::NPMLE()` is not recognized and the fit silently falls through to the
  # parametric machinery. The call therefore has to carry the bare names, which
  # are bound here in a small local environment together with the data.
  fct_call <- if (identical(method, "npmle")) quote(NPMLE()) else quote(KDE())
  env <- new.env(parent = environment(formula) %||% parent.frame())
  assign(".agri_tte_data", data, envir = env)
  assign("NPMLE", drcte::NPMLE, envir = env)
  assign("KDE", drcte::KDE, envir = env)
  cl <- if (is.null(by_nm))
    substitute(drcte::drmte(FORM, data = .agri_tte_data, fct = FCT),
               list(FORM = formula, FCT = fct_call))
  else
    substitute(drcte::drmte(FORM, curveid = CID, data = .agri_tte_data,
                            fct = FCT),
               list(FORM = formula, CID = as.name(by_nm), FCT = fct_call))
  fit <- tryCatch(eval(cl, envir = env), error = function(e) e)
  if (inherits(fit, "error"))
    .agri_stop("The nonparametric time-to-event estimator failed: ",
               conditionMessage(fit))
  # compCDF() re-evaluates the stored call to rebuild the design under each
  # permutation. The call still refers to the temporary binding used above,
  # which will not exist by then, so the data are embedded in it directly.
  fit$call$data <- data

  itv <- .tte_parse_turnbull(fit, dlevs)
  if (!is.null(itv)) itv$level <- levs[match(itv$level, dlevs)]
  qr <- .tte_quantiles(fit, probs, restricted = TRUE)
  qu <- .tte_quantiles(fit, probs, restricted = FALSE)

  smry <- do.call(rbind, lapply(seq_along(levs), function(i) {
    l <- levs[i]
    sub <- if (is.null(by_nm)) data
           else data[as.character(data[[by_nm]]) == l, , drop = FALSE]
    n <- sum(sub[[cnt]], na.rm = TRUE)
    never <- sum(sub[[cnt]][is.infinite(sub[[tm[2L]]])], na.rm = TRUE)
    row <- data.frame(level = l, subjects = n,
                      responded = if (n > 0) 1 - never / n else NA_real_,
                      row.names = NULL, stringsAsFactors = FALSE)
    for (p in probs) {
      tag <- format(100 * p, trim = TRUE)
      row[[paste0("t", tag, "_responders")]] <- .tte_pick(qr, dlevs[i], p)
      row[[paste0("t", tag, "_lot")]] <- .tte_pick(qu, dlevs[i], p)
    }
    row
  }))

  test <- NULL
  if (multi) {
    if (is.null(un_nm))
      .agri_warn("No `units` given, so the permutation test treats every seed ",
                 "as an independent subject. Seeds sharing a dish share its ",
                 "water, temperature and handling, so the test will be ",
                 "anticonservative. Pass `units =` naming the dish, tray or ",
                 "plot.")
    # Called directly rather than through do.call: compCDF() inspects its own
    # call, and a deparsed fitted object defeats that.
    cc <- .seed_eval(seed, tryCatch(suppressWarnings(
      if (is.null(un_nm))
        drcte::compCDF(fit, scores = scores, B = as.integer(B),
                       type = "permutation", display = FALSE)
      else
        drcte::compCDF(fit, scores = scores, B = as.integer(B),
                       type = "permutation", units = data[[un_nm]],
                       display = FALSE)),
      error = function(e) e))
    if (inherits(cc, "error"))
      .agri_warn("The permutation comparison of the curves failed: ",
                 conditionMessage(cc))
    if (!inherits(cc, "error"))
      test <- data.frame(
        comparison = paste("equality of the", length(levs), "time-to-event curves"),
        scores = scores,
        statistic = as.numeric(cc$val0),
        p_value = as.numeric(cc$pvalb),
        permutations = as.integer(B),
        clustered_by = un_nm %||% NA_character_,
        row.names = NULL, stringsAsFactors = FALSE
      )
  }

  curve <- NULL
  if (!is.null(itv)) {
    curve <- do.call(rbind, lapply(levs, function(l) {
      z <- itv[itv$level == l, , drop = FALSE]
      z <- z[order(z$start), , drop = FALSE]
      fin <- is.finite(z$end)
      data.frame(level = l,
                 time = c(min(z$start, na.rm = TRUE), z$end[fin]),
                 cdf = c(0, z$cdf[fin]),
                 row.names = NULL, stringsAsFactors = FALSE)
    }))
  }

  structure(
    list(summary = smry, test = test, curve = curve, intervals = itv, fit = fit),
    by = by_nm, units = un_nm, count = cnt, times = tm,
    probs = probs, method = method,
    class = "agri_np_tte"
  )
}

#' @export
print.agri_np_tte <- function(x, ...) {
  cat("Nonparametric time-to-event, ",
      if (identical(attr(x, "method"), "npmle"))
        "NPML estimator under interval censoring" else
        "kernel estimator under interval censoring", "\n", sep = "")
  by_nm <- attr(x, "by")
  cat("  Counts: `", attr(x, "count"), "`   Interval: `",
      paste(attr(x, "times"), collapse = "` to `"), "`", sep = "")
  if (!is.null(by_nm)) cat("   Curves by: `", by_nm, "`", sep = "")
  if (!is.null(attr(x, "units"))) cat("   Units: `", attr(x, "units"), "`", sep = "")
  cat("\n\n")
  print(x$summary, row.names = FALSE, digits = 4)

  cat("\n`responded` is capacity, the share of the lot that ever responds.\n",
      "`*_responders` is speed among those that did respond and always exists.\n",
      "`*_lot` is measured on the whole lot and is NA when the lot never\n",
      "reaches that share: such a lot has no median time, and reporting one\n",
      "would invent a response for subjects that never had one.\n", sep = "")

  lot <- grep("_lot$", names(x$summary), value = TRUE)
  if (length(lot) && any(is.na(unlist(x$summary[lot]))))
    cat("\nAt least one whole-lot quantile is NA. Report the capacity and the\n",
        "speed of the responders separately; one number cannot carry both.\n",
        sep = "")

  if (!is.null(x$test)) {
    cat("\nPermutation test:\n\n")
    print(x$test, row.names = FALSE, digits = 4)
    if (is.na(x$test$clustered_by))
      cat("\n  Seeds were permuted individually. If they shared dishes, this\n",
          "  p-value is anticonservative.\n", sep = "")
  }
  invisible(x)
}

#' @export
plot.agri_np_tte <- function(x, type = c("cdf", "capacity"), ...) {
  .require_pkg("ggplot2", "time-to-event graphics")
  type <- match.arg(type)
  by_nm <- attr(x, "by")

  if (identical(type, "capacity")) {
    d <- data.frame(g = factor(x$summary$level, levels = x$summary$level),
                    x = x$summary$responded)
    return(
      ggplot2::ggplot(d, ggplot2::aes(x = x, y = g)) +
        ggplot2::geom_col(width = 0.6, fill = "grey35") +
        ggplot2::scale_x_continuous(limits = c(0, 1)) +
        ggplot2::labs(x = "Share of the lot that ever responds", y = by_nm,
                      title = "Capacity, which is not speed",
                      caption = "A lot that responds slowly and a lot that never responds are different problems.") +
        .agri_theme_or_minimal())
  }

  if (is.null(x$curve))
    .agri_stop("The estimated distribution could not be tabulated, so no curve ",
               "can be drawn.")
  d <- data.frame(x = x$curve$time, y = x$curve$cdf,
                  g = factor(x$curve$level, levels = unique(x$curve$level)))
  p <- ggplot2::ggplot(d, ggplot2::aes(x = x, y = y))
  p <- if (length(levels(d$g)) > 1L)
    p + ggplot2::geom_step(ggplot2::aes(colour = g), linewidth = 0.9)
  else p + ggplot2::geom_step(linewidth = 0.9)
  p +
    ggplot2::scale_y_continuous(limits = c(0, 1)) +
    ggplot2::labs(x = paste0("Time (", attr(x, "times")[2L], ")"),
                  y = "Cumulative share responded", colour = by_nm,
                  title = "Estimated time-to-event distribution",
                  caption = "The step function is the estimate itself, not a smooth fitted through it. A curve that stops below one is a lot that does not fully respond.") +
    .agri_theme_or_minimal()
}
