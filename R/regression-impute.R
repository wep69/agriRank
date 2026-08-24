# Missing plots, and the only honest way to use an imputation here.
#
# The regression module offered complete-case analysis and nothing else, with
# na_action = "fail" as the default so that rows were never dropped silently.
# That default is right and stays. But complete-case analysis is unbiased only
# when the missingness is unrelated to the response, and in a field trial it
# usually is not: the plot that was lost is often the flooded one, the grazed
# one, the one at the end of the row.
#
# Multiple imputation addresses that, at a price the rest of this package
# refuses to pay everywhere else. It requires a model for the variables with
# gaps, and it assumes the data are missing at random given what was observed.
# Neither is checkable from the data at hand. So the function below is built to
# be used as a SENSITIVITY ANALYSIS rather than as a replacement:
#
#   it always fits the complete-case model too, and prints them side by side;
#   it reports how far the curve and the optimum move between the two;
#   it never returns only the imputed answer.
#
# Pooling follows Rubin: the pooled curve is the average of the m fitted curves,
# and its variance is the within-imputation variance plus (1 + 1/m) times the
# between-imputation variance. The within part comes from the package's own
# cluster bootstrap, so the block structure survives into the pooled interval.

#' Multiple imputation for a regression with missing plots
#'
#' @description
#' Refits the regression on `m` imputed data sets, pools the curve by Rubin's
#' rules, and always reports the complete-case fit beside it so that the two can
#' be compared. Requires the `mice` package.
#' @param formula Regression formula.
#' @param data Data frame, with gaps.
#' @param block Optional block, which becomes the resampling unit.
#' @param m Number of imputations. Five is the classical default and ten is
#'   safer when the fraction of missing information is appreciable.
#' @param B Bootstrap replicates used for the within-imputation variance. This
#'   is `m * B` refits in total, so it is the expensive argument.
#' @param level Confidence level.
#' @param seed Random seed.
#' @param n Grid size.
#' @param method Engine, passed to [agri_np_regression()].
#' @param mice_method Imputation method passed to `mice::mice()`. Predictive
#'   mean matching, the default, draws replacement values from observed ones and
#'   so cannot invent a yield outside the range that was actually seen.
#' @param parallel Distribute the bootstrap replicates over a `future` plan.
#' @param ... Passed to [agri_np_regression()].
#' @details
#' **This is the one place in the package that assumes a missingness
#' mechanism.** Multiple imputation is valid when the data are missing at random
#' given the observed variables, and that is an assumption about why the plots
#' were lost, not a property the data can confirm. Everything else in agriRank
#' avoids such assumptions; this function makes one deliberately, and reports
#' the complete-case answer alongside so that the reader can see what the
#' assumption bought.
#'
#' Read the two together. If the imputed and complete-case curves agree, the
#' missingness is not driving the conclusion and the simpler analysis can be
#' reported. If they disagree, that disagreement is the finding: it means the
#' conclusion depends on what was assumed about the plots that were lost, and
#' the methods section has to say so.
#'
#' The pooled variance at each grid point is the average within-imputation
#' bootstrap variance plus `(1 + 1/m)` times the variance of the `m` point
#' estimates. The block survives into the within part because that part uses the
#' package's cluster bootstrap.
#' @return An object of class `agri_np_impute`.
#' @seealso [agri_missing_report()] and [agri_missing_sensitivity()] for the
#'   rank-based side, [agri_np_regression()] with `na_action = "complete"` for
#'   the explicit complete-case route.
#' @references
#' Rubin, D. B. (1987). *Multiple Imputation for Nonresponse in Surveys*. Wiley.
#'
#' van Buuren, S. and Groothuis-Oudshoorn, K. (2011). mice: Multivariate
#' imputation by chained equations in R. *Journal of Statistical Software*,
#' 45(3), 1-67.
#' @export
agri_np_impute <- function(formula, data, block = NULL, m = 5L, B = 199L,
                           level = 0.95, seed = 1, n = 100L, method = "gam",
                           mice_method = "pmm", parallel = FALSE, ...) {
  .require_pkg("mice", "multiple imputation")
  if (!inherits(formula, "formula")) .agri_stop("`formula` must be a formula.")
  if (!is.data.frame(data)) data <- as.data.frame(data)
  m <- max(2L, as.integer(m))
  .np_check_B(B)

  # See agri_np_multiresponse(): a bare symbol naming a column fails to evaluate
  # in the caller's frame, and that failure means "column name", not "no block".
  bexpr <- substitute(block)
  .bok <- TRUE
  bval <- tryCatch(block, error = function(e) { .bok <<- FALSE; NULL })
  bnm <- if (identical(bexpr, quote(NULL)) || (.bok && is.null(bval))) NULL
         else if (is.character(bval)) bval else .capture_names(bexpr, names(data))

  resp <- .response_names(formula)[1L]
  preds <- .predictor_names(formula)
  vars <- unique(c(resp, preds, bnm))
  .check_vars(vars, data)

  miss <- colSums(is.na(data[, vars, drop = FALSE]))
  if (!sum(miss))
    .agri_stop("There is nothing missing among the modelled variables, so ",
               "imputation would only add noise. Use agri_np_regression().")

  cc <- stats::complete.cases(data[, vars, drop = FALSE])
  if (sum(cc) < 6L)
    .agri_stop("Only ", sum(cc), " complete rows remain, which is too few for ",
               "the complete-case comparison this function insists on ",
               "reporting.")

  complete_fit <- agri_np_regression(formula, data[cc, , drop = FALSE],
                                     method = method, block = bnm,
                                     na_action = "fail", ...)
  grid <- .np_prediction_grid(complete_fit, n = as.integer(n))
  px <- complete_fit$primary_predictor
  cc_curve <- as.numeric({
    p <- agri_np_predict(complete_fit, grid); if (is.matrix(p)) p[, 1L] else p
  })

  imp <- .seed_eval(seed, mice::mice(data[, vars, drop = FALSE], m = m,
                                     method = mice_method, printFlag = FALSE))
  per <- vector("list", m)
  for (i in seq_len(m)) {
    di <- mice::complete(imp, i)
    fi <- tryCatch(agri_np_regression(formula, di, method = method,
                                      block = bnm, na_action = "fail", ...),
                   error = function(e) NULL)
    if (is.null(fi)) next
    pi_ <- tryCatch(agri_np_predict(fi, grid), error = function(e) NULL)
    if (is.null(pi_)) next
    if (is.matrix(pi_)) pi_ <- pi_[, 1L]
    bi <- suppressWarnings(
      agri_np_bootstrap(fi, newdata = grid, B = B, level = level,
                        seed = seed + i, parallel = parallel,
                        keep_replicates = TRUE))
    per[[i]] <- list(fit = as.numeric(pi_),
                     var = apply(attr(bi, "replicates"), 1L, stats::var,
                                 na.rm = TRUE),
                     optimum = grid[[px]][which.max(as.numeric(pi_))])
  }
  per <- Filter(Negate(is.null), per)
  if (length(per) < 2L)
    .agri_stop("Fewer than two imputations produced a usable fit, so nothing ",
               "can be pooled. Inspect the imputation model.")

  Q <- do.call(cbind, lapply(per, `[[`, "fit"))
  U <- do.call(cbind, lapply(per, `[[`, "var"))
  mm <- ncol(Q)
  qbar <- rowMeans(Q)
  ubar <- rowMeans(U, na.rm = TRUE)
  bvar <- apply(Q, 1L, stats::var)
  total <- ubar + (1 + 1 / mm) * bvar
  z <- stats::qnorm(1 - (1 - level) / 2)
  se <- sqrt(pmax(total, 0))

  # Fraction of missing information, the quantity that says how much the
  # imputation is actually doing at each point of the curve.
  fmi <- ifelse(total > 0, ((1 + 1 / mm) * bvar) / total, NA_real_)

  curve <- data.frame(
    x = grid[[px]],
    complete_case = cc_curve,
    pooled = qbar,
    lower = qbar - z * se,
    upper = qbar + z * se,
    fmi = fmi,
    row.names = NULL)

  opt_cc <- grid[[px]][which.max(cc_curve)]
  opt_pool <- grid[[px]][which.max(qbar)]
  opt_each <- vapply(per, `[[`, numeric(1), "optimum")

  structure(
    list(curve = curve,
         optimum = data.frame(
           source = c("complete case", "pooled", "imputation spread"),
           optimum = c(opt_cc, opt_pool, NA_real_),
           lower = c(NA_real_, NA_real_, min(opt_each)),
           upper = c(NA_real_, NA_real_, max(opt_each)),
           row.names = NULL, stringsAsFactors = FALSE),
         missing = data.frame(variable = names(miss),
                              n_missing = as.integer(miss),
                              row.names = NULL, stringsAsFactors = FALSE),
         complete_fit = complete_fit, imputations = mm),
    level = level, B = B, m = mm, predictor = px, response = resp,
    n_complete = sum(cc), n_total = nrow(data),
    mice_method = mice_method,
    class = "agri_np_impute")
}

#' @export
print.agri_np_impute <- function(x, ...) {
  cat("Multiple imputation for a nonparametric regression\n")
  cat("  Response: ", attr(x, "response"),
      "   gradient: ", attr(x, "predictor"), "\n", sep = "")
  cat("  Rows: ", attr(x, "n_total"), " total, ", attr(x, "n_complete"),
      " complete   imputations: ", attr(x, "m"),
      "   method: ", attr(x, "mice_method"), "\n\n", sep = "")
  print(x$missing[x$missing$n_missing > 0, ], row.names = FALSE)

  cat("\nOptimum:\n\n")
  print(x$optimum, row.names = FALSE, digits = 4)
  d <- abs(x$optimum$optimum[2L] - x$optimum$optimum[1L])
  rg <- diff(range(x$curve$x))
  cat("\n  The complete-case and pooled optima differ by ",
      format(d, digits = 3), ", which is ",
      format(round(100 * d / rg, 1)), "% of the tested range.\n", sep = "")
  if (is.finite(d / rg) && d / rg > 0.05)
    cat("  That is not small. The conclusion depends on what was assumed about\n",
        "  the plots that were lost, and the methods section has to say so.\n",
        sep = "")
  else
    cat("  That is small, so the missingness is not driving the conclusion and\n",
        "  the complete-case analysis can be reported as the primary one.\n",
        sep = "")

  f <- suppressWarnings(max(x$curve$fmi, na.rm = TRUE))
  if (is.finite(f))
    cat("\n  Largest fraction of missing information along the curve: ",
        format(round(f, 3)), ".\n", sep = "")
  cat("\n  This is the one place in agriRank that assumes a missingness\n",
      "  mechanism. Imputation is valid when the data are missing at random\n",
      "  given what was observed, which is an assumption about why the plots\n",
      "  were lost and not a property these data can confirm. Report both\n",
      "  analyses, not only this one.\n", sep = "")
  invisible(x)
}
