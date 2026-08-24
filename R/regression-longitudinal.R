# A dose-response curve measured more than once on the same plot.
#
# The regression module was cross-sectional: one row, one plot, one measurement.
# A trial that measures the same plots at four dates has four rows per plot, and
# analysing them as four independent observations inflates the apparent
# replication fourfold. That is the same error the repeated-measures side of the
# package exists to prevent, and until now the regression side had no equivalent.
#
# The implementation deliberately does not open a new modelling framework. It
# assembles one out of pieces already validated here:
#
#   the plot becomes the block, entered as a penalised random effect, so each
#     plot has its own level pulled towards the common mean;
#   the time variable enters as its own smooth, or interacts with the gradient
#     when the shape of the response is allowed to change over time;
#   the plot becomes the resampling cluster, so every bootstrap, conformal
#     interval and cross-validation downstream keeps its measurements together.
#
# The last point is what makes the rest of the module correct for these data
# without a single change to it: agri_np_bootstrap(), agri_np_conformal() and
# agri_np_compare() all default their cluster or their folds to object$block.
#
# What this is not: it is not a GAMM with a modelled within-subject correlation
# structure. Nothing here estimates an autocorrelation over time. The dependence
# is handled by resampling whole plots, which is assumption-free about its form
# but cannot recover the efficiency a correct correlation model would.

#' Regression along a gradient measured repeatedly on the same units
#'
#' @description
#' Fits a response curve when each experimental unit is measured more than once,
#' entering the unit as a penalised random effect and making it the resampling
#' cluster for everything downstream.
#' @param formula Regression formula, response on the left and the gradient plus
#'   any other predictors on the right. Do not put the time variable here; give
#'   it to `time`.
#' @param data Data frame in long form, one row per unit and occasion.
#' @param subject The unit measured repeatedly, as a name or a string: the plot,
#'   the pot, the animal.
#' @param time The occasion, as a name or a string.
#' @param time_effect How time enters. `"smooth"` gives it its own smooth, so
#'   the level of the response drifts over time but its shape does not.
#'   `"varying"` lets the shape of the gradient response differ between
#'   occasions, which is the interesting case and needs time to be a factor with
#'   enough observations per level.
#' @param k Basis dimension for the smooths.
#' @param ... Passed to [agri_np_regression()].
#' @details
#' The returned object is an ordinary `agri_np_reg_fit` whose `block` is the
#' subject. That is not a trick: the subject **is** the unit of resampling, so
#' every tool in the module then does the right thing without knowing anything
#' about repeated measurement. [agri_np_bootstrap()] resamples whole subjects,
#' [agri_np_conformal()] splits by subject, and
#' [agri_np_compare()] with `cv_scope = "new_block"` holds out whole subjects,
#' which is the honest question: how well is a plot predicted that was never
#' measured.
#'
#' `block_effect = "shrunk"` is used, so subject effects are penalised towards
#' their common mean. With fixed subject effects a model with many plots and few
#' occasions each would spend most of its degrees of freedom on nuisance.
#'
#' **This is not a GAMM with a modelled within-subject correlation.** Nothing
#' here estimates an autocorrelation over time. The dependence is handled by
#' resampling whole subjects, which assumes nothing about its form and, in
#' exchange, cannot recover the efficiency that a correct correlation model
#' would. If the occasions are many and closely spaced, say a weekly series over
#' a season, a model that represents the correlation is the better tool and this
#' one will be conservative.
#' @return An `agri_np_reg_fit`, with `$longitudinal` describing the structure.
#' @seealso [agri_repeated()] for the rank-based repeated-measures side,
#'   [agri_np_regression()], [agri_np_conformal()].
#' @export
agri_np_longitudinal <- function(formula, data, subject, time,
                                 time_effect = c("smooth", "varying"),
                                 k = 10L, ...) {
  time_effect <- match.arg(time_effect)
  if (!inherits(formula, "formula")) .agri_stop("`formula` must be a formula.")
  if (!is.data.frame(data)) data <- as.data.frame(data)

  sexpr <- substitute(subject); sval <- tryCatch(subject, error = function(e) NULL)
  subj <- if (is.character(sval)) sval else .capture_names(sexpr, names(data))
  texpr <- substitute(time); tval <- tryCatch(time, error = function(e) NULL)
  tim <- if (is.character(tval)) tval else .capture_names(texpr, names(data))
  if (length(subj) != 1L || length(tim) != 1L)
    .agri_stop("`subject` and `time` must each name exactly one variable.")
  .check_vars(c(subj, tim), data)

  # The whole point is that units are measured more than once. If they are not,
  # this is an ordinary regression and saying so is more useful than fitting a
  # random effect with one observation per level.
  reps <- table(as.character(data[[subj]]))
  if (max(reps) < 2L)
    .agri_stop("Every level of `", subj, "` appears once, so these data are ",
               "not repeated measurements. Use agri_np_regression() directly.")
  if (mean(reps >= 2L) < 0.5)
    .agri_warn("Fewer than half the levels of `", subj, "` are measured more ",
               "than once. The random effect will be poorly determined and the ",
               "cluster bootstrap will have little to resample within.")
  if (length(unique(as.character(data[[subj]]))) < 4L)
    .agri_stop("A cluster bootstrap over `", subj, "` needs at least four ",
               "units; this design has ",
               length(unique(as.character(data[[subj]]))), ".")

  resp <- .response_names(formula)[1L]
  preds <- .predictor_names(formula)
  nums <- preds[vapply(data[preds], is.numeric, logical(1))]

  if (identical(time_effect, "varying")) {
    if (!length(nums))
      .agri_stop("`time_effect = \"varying\"` needs a numeric gradient whose ",
                 "shape may change between occasions.")
    if (!is.factor(data[[tim]])) data[[tim]] <- factor(data[[tim]])
    per <- vapply(split(data[[nums[1L]]], data[[tim]]),
                  function(v) length(unique(v[is.finite(v)])), integer(1))
    if (min(per) < 4L)
      .agri_stop("`time_effect = \"varying\"` fits one curve per occasion, ",
                 "which needs at least four distinct values of `", nums[1L],
                 "` within every level of `", tim, "`. The sparsest has ",
                 min(per), ".")
    rhs <- c(paste(preds, collapse = " + "), tim)
    f2 <- stats::as.formula(paste(resp, "~", paste(rhs, collapse = " + ")),
                            env = environment(formula))
    fit <- agri_np_regression(f2, data, method = "gam", block = subj,
                              block_effect = "shrunk",
                              gam_structure = "varying", k = k, ...)
  } else {
    kt <- min(as.integer(k),
              max(3L, length(unique(data[[tim]][!is.na(data[[tim]])])) - 1L))
    tterm <- if (is.factor(data[[tim]]) || kt < 4L) tim
             else sprintf("s(%s, k=%d)", tim, kt)
    f2 <- stats::as.formula(
      paste(resp, "~", paste(c(preds, tterm), collapse = " + ")),
      env = environment(formula))
    fit <- agri_np_regression(f2, data, method = "gam", block = subj,
                              block_effect = "shrunk", k = k, ...)
  }

  fit$longitudinal <- list(
    subject = subj, time = tim, time_effect = time_effect,
    n_subjects = length(unique(as.character(data[[subj]]))),
    occasions = length(unique(as.character(data[[tim]]))),
    measurements_per_subject = as.integer(reps),
    balanced = length(unique(reps)) == 1L)
  class(fit) <- c("agri_np_longitudinal_fit", class(fit))
  fit
}

#' @export
print.agri_np_longitudinal_fit <- function(x, ...) {
  L <- x$longitudinal
  cat("agriRank longitudinal regression\n")
  cat("  Subject: ", L$subject, "   ", L$n_subjects, " units\n", sep = "")
  cat("  Time: ", L$time, "   ", L$occasions, " occasions   ",
      if (L$balanced) "balanced" else "unbalanced", "\n", sep = "")
  cat("  Time enters as: ", L$time_effect,
      if (identical(L$time_effect, "smooth"))
        ", so the level drifts but the shape does not"
      else ", so the shape of the response may differ between occasions",
      "\n", sep = "")
  cat("  Subject effects are shrunk, and the subject is the resampling unit\n",
      "  for every interval, conformal split and cross-validation fold\n",
      "  downstream.\n", sep = "")
  y <- x; class(y) <- setdiff(class(y), "agri_np_longitudinal_fit")
  cat("\n")
  print(y)
  cat("\n  The within-subject dependence is handled by resampling whole\n",
      "  subjects, not by a modelled correlation over time. That assumes\n",
      "  nothing about its form and, in exchange, is conservative when the\n",
      "  occasions are many and closely spaced.\n", sep = "")
  invisible(x)
}
