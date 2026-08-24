# Regression module, waves 5 and 6 of the 0.14.0 improvement plan:
# a design-aware significance test valid for every engine, a test of the shape
# constraint, and three kinds of data the cross-sectional module could not hold.

.w56_curve <- function(seed = 21L) {
  set.seed(seed)
  d <- expand.grid(N = seq(0, 200, by = 50), block = factor(1:5), rep = 1:2,
                   KEEP.OUT.ATTRS = FALSE)
  d$noise <- stats::rnorm(nrow(d))
  d$yield <- 3 + 0.030 * d$N - 0.00009 * d$N^2 +
    as.numeric(d$block) * 0.30 + stats::rnorm(nrow(d), 0, 0.30)
  d
}
.w56_long <- function(seed = 31L) {
  set.seed(seed)
  d <- expand.grid(N = seq(0, 200, 50), plot = factor(1:12), time = factor(1:3),
                   KEEP.OUT.ATTRS = FALSE)
  d$yield <- 3 + 0.03 * d$N - 0.00009 * d$N^2 +
    as.numeric(d$plot) * 0.15 + as.numeric(d$time) * 0.40 +
    stats::rnorm(nrow(d), 0, 0.25)
  d
}
.w56_mv <- function(seed = 41L) {
  set.seed(seed)
  d <- expand.grid(N = seq(0, 200, 50), block = factor(1:5),
                   KEEP.OUT.ATTRS = FALSE)
  d$yield   <- 3 + 0.040 * d$N - 0.00020 * d$N^2 +
    as.numeric(d$block) * 0.2 + stats::rnorm(nrow(d), 0, 0.15)
  d$protein <- 9 + 0.026 * d$N - 0.00009 * d$N^2 +
    as.numeric(d$block) * 0.1 + stats::rnorm(nrow(d), 0, 0.15)
  d$lodging <- 20 + 0.10 * d$N + stats::rnorm(nrow(d), 0, 2)
  d
}

# ---- W5.1, cluster wild-bootstrap effect test --------------------------------

test_that("the effect test separates a real predictor from pure noise", {
  skip_on_cran()
  skip_if_not_installed("mgcv")
  d <- .w56_curve()
  fit <- agri_np_regression(yield ~ N + noise, d, method = "gam",
                            block = block, k = 5)
  et <- suppressWarnings(agri_np_effect_test(fit, B = 99, seed = 1))
  expect_identical(nrow(et$table), 2L)
  sN <- et$table$statistic[et$table$term == "N"]
  sZ <- et$table$statistic[et$table$term == "noise"]
  # The p-values cannot separate them with five blocks; the statistic can, and
  # by orders of magnitude. That is the discrimination the test achieved.
  expect_gt(sN, 50 * sZ)
  expect_true(all(et$table$p_value >= 0 & et$table$p_value <= 1))
})

test_that("the effect test reports the 2^G limit the design imposes", {
  skip_on_cran()
  skip_if_not_installed("mgcv")
  d <- .w56_curve()
  fit <- agri_np_regression(yield ~ N, d, method = "gam", block = block, k = 5)
  et <- suppressWarnings(agri_np_effect_test(fit, B = 99, seed = 1))
  expect_identical(attr(et, "n_clusters"), 5L)
  # No p-value below 2^-5 is attainable however large B is.
  expect_gte(attr(et, "p_floor"), 2^-5)
  expect_output(print(et), "sign patterns")
})

test_that("the effect test works for an engine with no coefficients", {
  # A smoothing spline is outside the reach of agri_np_significance(), which
  # calls np::npsigtest() and needs a kernel fit.
  skip_on_cran()
  d <- .w56_curve()
  fs <- agri_np_regression(yield ~ N, d, method = "smoothing_spline")
  et <- suppressWarnings(agri_np_effect_test(fs, B = 99, seed = 1, cluster = NA))
  expect_identical(nrow(et$table), 1L)
  expect_true(is.finite(et$table$p_value))
  expect_output(print(et), "assumes complete randomization")
})

test_that("the effect test signs whole blocks by default", {
  skip_on_cran()
  skip_if_not_installed("mgcv")
  d <- .w56_curve()
  fit <- agri_np_regression(yield ~ N, d, method = "gam", block = block, k = 5)
  et <- suppressWarnings(agri_np_effect_test(fit, B = 49, seed = 1))
  expect_identical(attr(et, "cluster"), "block")
  expect_output(print(et), "within-block dependence survives")
})

test_that("a term that is not a predictor is refused by name", {
  skip_if_not_installed("mgcv")
  d <- .w56_curve()
  fit <- agri_np_regression(yield ~ N, d, method = "gam", block = block, k = 5)
  expect_error(agri_np_effect_test(fit, terms = "rep", B = 19),
               "Not a predictor")
})

# ---- W5.2, shape test --------------------------------------------------------

test_that("the shape test runs and reports both fits", {
  skip_on_cran()
  skip_if_not_installed("mgcv")
  skip_if_not_installed("scam")
  d <- .w56_curve()
  fit <- agri_np_regression(yield ~ N, d, method = "gam", block = block, k = 5)
  st <- suppressWarnings(agri_np_shape_test(fit, shape = "increasing_concave",
                                            B = 49, seed = 1))
  expect_identical(nrow(st$table), 1L)
  expect_true(is.finite(st$table$p_value))
  expect_true(all(c("constrained_RMSE", "free_RMSE") %in% names(st$table)))
  # Matched on a fragment that does not straddle the wrapped line break.
  expect_output(print(st), "The null is that the constraint holds")
})

test_that("the shape test needs a shape", {
  skip_if_not_installed("mgcv")
  d <- .w56_curve()
  fit <- agri_np_regression(yield ~ N, d, method = "gam", block = block, k = 5)
  expect_error(agri_np_shape_test(fit, B = 19), "No shape to test")
})

# ---- W6.1, longitudinal ------------------------------------------------------

test_that("the subject becomes the block and therefore the resampling unit", {
  # This is the whole design of the function: nothing downstream needs to know
  # that the data are repeated measurements.
  skip_on_cran()
  skip_if_not_installed("mgcv")
  d <- .w56_long()
  lf <- agri_np_longitudinal(yield ~ N, d, subject = plot, time = time, k = 4)
  expect_s3_class(lf, "agri_np_longitudinal_fit")
  expect_s3_class(lf, "agri_np_reg_fit")
  expect_identical(lf$block, "plot")
  expect_identical(lf$block_effect, "shrunk")
  expect_identical(lf$longitudinal$n_subjects, 12L)
  b <- suppressWarnings(agri_np_bootstrap(lf, B = 19, n = 15, seed = 1))
  expect_identical(attr(b, "cluster"), "plot")
})

test_that("varying lets the shape differ between occasions", {
  skip_on_cran()
  skip_if_not_installed("mgcv")
  d <- .w56_long()
  lv <- agri_np_longitudinal(yield ~ N, d, subject = plot, time = time,
                             time_effect = "varying", k = 4)
  expect_match(paste(deparse(lv$formula_used), collapse = " "), "by ?= ?time")
})

test_that("data that are not repeated measurements are refused", {
  skip_if_not_installed("mgcv")
  d <- .w56_long()
  d1 <- d[!duplicated(d$plot), ]
  expect_error(agri_np_longitudinal(yield ~ N, d1, subject = plot, time = time),
               "not repeated measurements")
})

test_that("too few subjects for a cluster bootstrap are refused", {
  skip_if_not_installed("mgcv")
  d <- .w56_long()
  d3 <- d[d$plot %in% levels(d$plot)[1:3], ]
  d3$plot <- droplevels(d3$plot)
  expect_error(agri_np_longitudinal(yield ~ N, d3, subject = plot, time = time),
               "at least four")
})

# ---- W6.2, several responses -------------------------------------------------

test_that("the shared bootstrap gives the distance between optima its own row", {
  skip_on_cran()
  skip_if_not_installed("mgcv")
  d <- .w56_mv()
  mr <- suppressWarnings(agri_np_multiresponse(
    cbind(yield, protein) ~ N, d, block = block, B = 60, seed = 1, n = 40, k = 4))
  expect_identical(nrow(mr$optima), 2L)
  expect_identical(nrow(mr$contrasts), 1L)
  expect_true("rank_correlation" %in% names(mr$contrasts))
  # The replicate matrix must have one column per response, from ONE resample.
  expect_identical(ncol(mr$replicates), 2L)
})

test_that("the block is honoured when given as a bare symbol", {
  # A bare symbol naming a column does not resolve in the caller's frame, and
  # reading that failure as "no block" silently sent the bootstrap back to
  # resampling rows. This test keeps that from returning.
  skip_on_cran()
  skip_if_not_installed("mgcv")
  d <- .w56_mv()
  mr <- suppressWarnings(agri_np_multiresponse(
    cbind(yield, protein) ~ N, d, block = block, B = 30, seed = 1, n = 30, k = 4))
  expect_identical(attr(mr, "cluster"), "block")
})

test_that("one objective per response is accepted and one response is refused", {
  skip_on_cran()
  skip_if_not_installed("mgcv")
  d <- .w56_mv()
  mr <- suppressWarnings(agri_np_multiresponse(
    cbind(yield, lodging) ~ N, d, block = block, objective = c("max", "min"),
    B = 30, seed = 1, n = 30, k = 4))
  expect_identical(mr$optima$objective, c("max", "min"))
  expect_error(agri_np_multiresponse(yield ~ N, d, B = 19),
               "two or more responses")
  expect_error(agri_np_multiresponse(cbind(yield, protein) ~ N, d,
                                     objective = c("max", "min", "max"), B = 19),
               "one per response")
})

# ---- W6.3, multiple imputation -----------------------------------------------

test_that("imputation always reports the complete case beside the pooled fit", {
  skip_on_cran()
  skip_if_not_installed("mice")
  skip_if_not_installed("mgcv")
  d <- .w56_curve()[, c("N", "block", "yield")]
  set.seed(51); d$yield[sample(nrow(d), 8)] <- NA
  im <- suppressWarnings(agri_np_impute(yield ~ N, d, block = block, m = 3,
                                        B = 25, seed = 1, n = 30, k = 4))
  expect_true(all(c("complete_case", "pooled", "lower", "upper", "fmi") %in%
                    names(im$curve)))
  expect_identical(nrow(im$optimum), 3L)
  expect_true("complete case" %in% im$optimum$source)
  # The pooled interval must contain the pooled estimate.
  expect_true(all(im$curve$lower <= im$curve$pooled))
  expect_true(all(im$curve$upper >= im$curve$pooled))
  # The fraction of missing information lies in [0, 1].
  f <- im$curve$fmi[is.finite(im$curve$fmi)]
  expect_true(all(f >= 0 & f <= 1))
})

test_that("imputation refuses data with nothing missing", {
  skip_if_not_installed("mice")
  skip_if_not_installed("mgcv")
  d <- .w56_curve()[, c("N", "block", "yield")]
  expect_error(agri_np_impute(yield ~ N, d, block = block, m = 3),
               "nothing missing")
})
