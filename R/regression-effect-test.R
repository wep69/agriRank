# Does a predictor earn its place, and is a declared shape compatible with the
# data? Two questions, one machine.
#
# Until 0.14.0 the only significance test in the regression module was
# agri_np_significance(), which works for two of the sixteen engines and
# resamples rows, ignoring the declared randomization. Meanwhile every interval
# in the module resamples whole blocks. That asymmetry meant a p-value and an
# interval from the same fit rested on different assumptions.
#
# What follows removes it. The device is the cluster wild bootstrap: refit the
# model under the null, then generate replicate responses by multiplying the
# null residuals by random signs drawn ONCE PER BLOCK rather than once per plot.
# Signing by plot would treat the plots of a block as independent, which is the
# same error the whole package exists to avoid; signing by block leaves the
# within-block dependence intact, whatever its form.
#
# The null model differs between the two functions and nothing else does:
#
#   agri_np_effect_test()  H0: the predictor does not enter. Null model = the
#                          fit without it.
#   agri_np_shape_test()   H0: the declared shape holds. Null model = the fit
#                          with the constraint imposed.
#
# Both are valid for every engine, because neither looks inside the engine: all
# they need is a fitted value and a residual.

# Rademacher weights, one draw per cluster, recycled over the rows of that
# cluster. With no cluster this reduces to one draw per row, which is the
# ordinary wild bootstrap and is correct only for a completely randomized
# layout.
.wild_weights <- function(cluster_values) {
  if (is.null(cluster_values)) return(NULL)
  lv <- unique(as.character(cluster_values))
  s <- sample(c(-1, 1), length(lv), replace = TRUE)
  s[match(as.character(cluster_values), lv)]
}

# Refit `object` on a replacement response, keeping every setting.
.np_refit_y <- function(object, y, override = list()) {
  d <- object$data
  d[[object$response]] <- y
  s <- object$settings %||% list()
  args <- list(
    formula = object$formula, data = d, method = object$method,
    tau = object$tau, family = object$family, shape = object$shape,
    block = object$block %||% NULL,
    block_effect = object$block_effect %||% s$block_effect %||% "fixed",
    spatial = object$spatial %||% s$spatial %||% "none",
    coords = object$coords %||% s$coords,
    na_action = "fail",
    span = s$span, degree = s$degree, k = s$k,
    gam_structure = s$gam_structure %||% "additive",
    kernel_regtype = s$kernel_regtype %||% "ll",
    bwmethod = s$bwmethod,
    predictor_support = s$predictor_support %||% "continuous",
    integer_predictor = s$integer_predictor,
    integer_values = s$integer_values,
    integer_base_method = s$integer_base_method %||% "gam")
  args[names(override)] <- override
  args <- args[!vapply(args, is.null, logical(1))]
  tryCatch(do.call(agri_np_regression, args), error = function(e) NULL)
}

# Distance between two sets of fitted values, scaled by the residual scale of
# the null fit so that the statistic is free of the units of the response.
.np_fit_distance <- function(f1, f0) {
  a <- f1; b <- f0
  ok <- is.finite(a) & is.finite(b)
  if (sum(ok) < 3L) return(NA_real_)
  s <- stats::mad(f0[ok] - mean(f0[ok], na.rm = TRUE), na.rm = TRUE)
  if (!is.finite(s) || s <= 0) s <- 1
  mean((a[ok] - b[ok])^2) / s^2
}

.np_wild_null <- function(object, null_fit, cluster_nm, B, seed, parallel,
                          statistic_fun) {
  res0 <- object$data[[object$response]] - null_fit$fitted
  cl <- if (length(cluster_nm)) object$data[[cluster_nm]] else NULL
  streams <- .agri_substreams(seed, B)
  one <- function(b) {
    w <- .agri_on_stream(streams[[b]], .wild_weights(cl) %||%
                           sample(c(-1, 1), length(res0), replace = TRUE))
    ystar <- null_fit$fitted + res0 * w
    statistic_fun(ystar)
  }
  unlist(.np_quiet_support(.seed_eval(seed,
    .agri_lapply(seq_len(B), one, parallel = parallel))), use.names = FALSE)
}

.np_resolve_cluster_arg <- function(object, cexpr, cval) {
  if (identical(cexpr, quote(NULL))) return(object$block)
  if (length(cval) == 1L && !is.null(cval) && is.na(cval)) return(NULL)
  if (is.character(cval)) return(cval)
  .capture_names(cexpr, names(object$data))
}

#' Does a predictor earn its place in the model
#'
#' @description
#' Tests whether dropping a predictor changes the fitted response more than
#' resampling alone would, by a cluster wild bootstrap under the null. Valid for
#' every engine in [agri_np_regression()], because it looks only at fitted
#' values and residuals rather than inside the engine.
#' @param object An `agri_np_reg_fit`.
#' @param terms The predictor or predictors to test, as names or strings. Each
#'   is tested on its own. Defaults to every predictor of the model.
#' @param B Bootstrap replicates. Use at least 999 for anything reported.
#' @param seed Random seed.
#' @param cluster Resampling unit. Defaults to the declared block, which is what
#'   makes the test respect the randomization. Pass `NA` to sign each row
#'   independently, which is legitimate only for a completely randomized layout.
#' @param adjust Multiplicity adjustment across the terms tested, passed to
#'   [stats::p.adjust()].
#' @param parallel Distribute the replicates over a `future` plan.
#' @details
#' The statistic is the mean squared distance between the fitted values of the
#' full model and those of the model without the term, scaled by the residual
#' spread so that it does not depend on the units of the response. Its null
#' distribution is obtained by refitting on replicate responses built from the
#' reduced fit plus its residuals multiplied by random signs.
#'
#' **The signs are drawn once per block, not once per plot.** Signing plots
#' independently would treat the plots of a block as independent, which is the
#' error the rest of this package exists to prevent. Signing whole blocks leaves
#' the within-block dependence intact whatever its form, which is what makes the
#' test design-aware.
#'
#' This complements rather than replaces [agri_np_significance()], which calls
#' `np::npsigtest()` for the kernel engines and resamples rows. Where the two
#' disagree, the difference is the randomization, and it should be reported.
#'
#' A term whose removal makes the model unfittable, for example the only
#' predictor of a one-predictor model with some engines, is reported with an
#' `NA` p-value and a note rather than silently dropped.
#' @return An object of class `agri_np_effect_test`.
#' @seealso [agri_np_shape_test()] for the shape rather than the term,
#'   [agri_np_optimum_test()] for the location of the optimum,
#'   [agri_np_significance()] for the kernel-specific alternative.
#' @references
#' Cameron, A. C., Gelbach, J. B. and Miller, D. L. (2008). Bootstrap-based
#' improvements for inference with clustered errors. *The Review of Economics
#' and Statistics*, 90(3), 414-427.
#'
#' Haerdle, W. and Mammen, E. (1993). Comparing nonparametric versus parametric
#' regression fits. *The Annals of Statistics*, 21(4), 1926-1947.
#' @export
agri_np_effect_test <- function(object, terms = NULL, B = 999L, seed = 1,
                                cluster = NULL,
                                adjust = c("holm", "none", "BH", "bonferroni",
                                           "hochberg", "hommel", "BY"),
                                parallel = FALSE) {
  if (!inherits(object, "agri_np_reg_fit"))
    .agri_stop("`object` must be an agri_np_reg_fit.")
  adjust <- match.arg(adjust)
  .np_check_B(B)

  texpr <- substitute(terms)
  tval <- tryCatch(terms, error = function(e) NULL)
  tt <- if (identical(texpr, quote(NULL))) object$predictors
        else if (is.character(tval)) tval
        else .capture_names(texpr, names(object$data))
  bad <- setdiff(tt, object$predictors)
  if (length(bad))
    .agri_stop("Not a predictor of the fitted model: ",
               paste(bad, collapse = ", "), ".")

  cexpr <- substitute(cluster)
  cval <- tryCatch(cluster, error = function(e) NULL)
  cl <- .np_resolve_cluster_arg(object, cexpr, cval)

  full <- object$fitted
  rows <- lapply(tt, function(v) {
    keep <- setdiff(object$predictors, v)
    if (!length(keep)) {
      # Nothing left to fit. The comparison is then against a constant, which is
      # still a legitimate null: does the response depend on anything at all.
      f0 <- stats::as.formula(paste(object$response, "~ 1"),
                              env = environment(object$formula))
    } else {
      f0 <- stats::as.formula(
        paste(object$response, "~", paste(keep, collapse = " + ")),
        env = environment(object$formula))
    }
    null_fit <- if (!length(keep))
      list(fitted = rep(mean(object$data[[object$response]], na.rm = TRUE),
                        nrow(object$data)))
    else .np_refit_y(object, object$data[[object$response]],
                     override = list(formula = f0))
    if (is.null(null_fit))
      return(data.frame(term = v, statistic = NA_real_, p_value = NA_real_,
                        replicates = 0L,
                        note = "the model without this term could not be fitted",
                        row.names = NULL, stringsAsFactors = FALSE))

    t_obs <- .np_fit_distance(full, null_fit$fitted)
    stat_fun <- function(ystar) {
      f1s <- .np_refit_y(object, ystar)
      if (is.null(f1s)) return(NA_real_)
      f0s <- if (!length(keep))
        list(fitted = rep(mean(ystar, na.rm = TRUE), length(ystar)))
      else .np_refit_y(object, ystar, override = list(formula = f0))
      if (is.null(f0s)) return(NA_real_)
      .np_fit_distance(f1s$fitted, f0s$fitted)
    }
    tstar <- .np_wild_null(object, null_fit, cl, B, seed + match(v, tt),
                           parallel, stat_fun)
    tstar <- tstar[is.finite(tstar)]
    p <- if (!length(tstar)) NA_real_
         else (1 + sum(tstar >= t_obs)) / (length(tstar) + 1)
    data.frame(term = v, statistic = t_obs, p_value = p,
               replicates = length(tstar), note = "",
               row.names = NULL, stringsAsFactors = FALSE)
  })

  tab <- do.call(rbind, rows)
  tab$p_adjusted <- if (identical(adjust, "none") || nrow(tab) < 2L) tab$p_value
                    else .p_adjust(tab$p_value, adjust)

  # With G clusters there are only 2^G distinct Rademacher sign vectors, so the
  # test has at most that many distinct outcomes however large B is. With five
  # blocks that is 32, and the smallest attainable p-value is about 0.03. This
  # is a property of the design, not of B, and raising B does not fix it.
  ng <- if (length(cl)) length(unique(as.character(object$data[[cl]])))
        else nrow(object$data)
  structure(list(table = tab, method = object$method),
            B = B, adjust = adjust, cluster = cl %||% NA_character_,
            response = object$response, engine = object$method,
            p_floor = max(1 / (B + 1), 2^(-ng)), n_clusters = ng,
            class = "agri_np_effect_test")
}

#' @export
print.agri_np_effect_test <- function(x, ...) {
  cat("Cluster wild-bootstrap test of predictor contribution\n")
  cat("  Response: ", attr(x, "response"),
      "   engine: ", attr(x, "engine"),
      "   B = ", attr(x, "B"), "\n", sep = "")
  cl <- attr(x, "cluster")
  cat("  Signs drawn once per ",
      if (is.na(cl)) "row, which assumes complete randomization"
      else paste0("level of `", cl, "`, so the within-block dependence survives"),
      "\n\n", sep = "")
  print(x$table, row.names = FALSE, digits = 4)
  ng <- attr(x, "n_clusters")
  fl <- attr(x, "p_floor")
  if (is.finite(ng) && ng <= 8L && !is.na(cl))
    cat("\n  With ", ng, " blocks there are only 2^", ng, " = ", 2^ng,
        " distinct sign patterns,\n  so no p-value below about ",
        format(2^(-ng), digits = 2), " can be produced however large B is.\n",
        "  That is a limit of the design, not of the resampling: more blocks\n",
        "  is the remedy, more replicates is not.\n", sep = "")
  else if (any(x$table$p_value <= fl + 1e-12, na.rm = TRUE))
    cat("\n  A p_value of ", format(fl, digits = 3), " is the floor of ",
        attr(x, "B"), " replicates,\n  not a measurement. Raise B before ",
        "quoting it.\n", sep = "")
  if (any(nzchar(x$table$note)))
    cat("\n  Some terms could not be tested; see the note column.\n")
  cat("\n  The null is that the term does not enter the response at all, not\n",
      "  that its effect is linear or small. A term that is not rejected has\n",
      "  not been shown to be absent.\n", sep = "")
  invisible(x)
}

#' Is a declared shape compatible with the data
#'
#' @description
#' Tests whether imposing a monotonicity or curvature constraint distorts the
#' fit more than resampling alone would. Imposing a shape buys precision when
#' the shape is true and biases the curve when it is not, and nothing in
#' [agri_np_regression()] checks which case applies.
#' @param object An `agri_np_reg_fit`. Either the constrained fit or the free
#'   one; the missing side is fitted internally.
#' @param shape The constraint to test. Defaults to the one already declared in
#'   `object`, and is required when `object` is unconstrained.
#' @param free_method Engine used for the unconstrained comparison. Defaults to
#'   `"gam"`, which is the closest free counterpart of `scam`.
#' @param B Bootstrap replicates.
#' @param seed Random seed.
#' @param cluster Resampling unit. Defaults to the declared block.
#' @param parallel Distribute the replicates over a `future` plan.
#' @details
#' The statistic is the mean squared distance between the constrained and the
#' free fit. Its null distribution is generated from the **constrained** fit,
#' because the null is that the constraint holds: replicate responses are the
#' constrained fitted values plus the residuals multiplied by random signs drawn
#' once per block.
#'
#' A large p-value does not prove the shape. It says the data do not contradict
#' it, which is the most a test of this kind can say, and with few blocks that is
#' a weak statement. Read it together with [agri_np_sizer()], which shows where
#' the free fit actually changes direction.
#' @return An object of class `agri_np_shape_test`.
#' @seealso [agri_np_effect_test()], [agri_np_sizer()],
#'   [agri_np_regression()] for the `shape` argument itself.
#' @export
agri_np_shape_test <- function(object, shape = NULL, free_method = "gam",
                               B = 999L, seed = 1, cluster = NULL,
                               parallel = FALSE) {
  if (!inherits(object, "agri_np_reg_fit"))
    .agri_stop("`object` must be an agri_np_reg_fit.")
  .np_check_B(B)
  shape <- shape %||% object$shape
  if (is.null(shape) || identical(shape, "none"))
    .agri_stop("No shape to test. Either fit with `shape =` or name the ",
               "constraint here, for example shape = \"increasing_concave\".")

  cexpr <- substitute(cluster)
  cval <- tryCatch(cluster, error = function(e) NULL)
  cl <- .np_resolve_cluster_arg(object, cexpr, cval)

  y <- object$data[[object$response]]
  con <- if (identical(object$shape, shape) && object$method %in% c("scam", "cobs", "isotonic"))
           object
         else .np_refit_y(object, y, override = list(method = "scam", shape = shape))
  if (is.null(con))
    .agri_stop("The constrained fit could not be obtained. `scam` is required ",
               "for a shape test on this model.")
  fre <- .np_refit_y(object, y, override = list(method = free_method,
                                                shape = "none"))
  if (is.null(fre))
    .agri_stop("The unconstrained comparison fit could not be obtained with ",
               "`free_method = \"", free_method, "\"`.")

  t_obs <- .np_fit_distance(fre$fitted, con$fitted)
  stat_fun <- function(ystar) {
    cs <- .np_refit_y(object, ystar, override = list(method = con$method,
                                                     shape = shape))
    fs <- .np_refit_y(object, ystar, override = list(method = free_method,
                                                     shape = "none"))
    if (is.null(cs) || is.null(fs)) return(NA_real_)
    .np_fit_distance(fs$fitted, cs$fitted)
  }
  tstar <- .np_wild_null(object, con, cl, B, seed, parallel, stat_fun)
  tstar <- tstar[is.finite(tstar)]
  p <- if (!length(tstar)) NA_real_
       else (1 + sum(tstar >= t_obs)) / (length(tstar) + 1)

  structure(
    list(table = data.frame(shape = shape, statistic = t_obs, p_value = p,
                            replicates = length(tstar),
                            constrained_RMSE = con$metrics$RMSE,
                            free_RMSE = fre$metrics$RMSE,
                            row.names = NULL, stringsAsFactors = FALSE),
         constrained = con, free = fre),
    B = B, cluster = cl %||% NA_character_, response = object$response,
    free_method = free_method, p_floor = 1 / (B + 1),
    class = "agri_np_shape_test")
}

#' @export
print.agri_np_shape_test <- function(x, ...) {
  cat("Cluster wild-bootstrap test of a shape constraint\n")
  cat("  Response: ", attr(x, "response"),
      "   free comparison: ", attr(x, "free_method"),
      "   B = ", attr(x, "B"), "\n", sep = "")
  cl <- attr(x, "cluster")
  cat("  Signs drawn once per ",
      if (is.na(cl)) "row" else paste0("level of `", cl, "`"), "\n\n", sep = "")
  print(x$table, row.names = FALSE, digits = 4)
  cat("\n  The null is that the constraint holds. A large p-value does not\n",
      "  prove the shape; it says these data do not contradict it, which with\n",
      "  few blocks is a weak statement. Read it beside agri_np_sizer(),\n",
      "  which shows where the free fit actually changes direction.\n", sep = "")
  if (isTRUE(x$table$constrained_RMSE < x$table$free_RMSE))
    cat("\n  The constrained fit has the smaller RMSE, which cannot happen by\n",
        "  optimisation and means the two engines differ in more than the\n",
        "  constraint. Compare like with like before reading the p-value.\n",
        sep = "")
  invisible(x)
}
