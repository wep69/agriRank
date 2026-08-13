test_that("integer_grid restricts all public decisions to integer support", {
  set.seed(501)
  d <- expand.grid(plants = 1:9, rep = 1:5)
  d$yield <- 50 + 8*d$plants - 0.65*d$plants^2 + rnorm(nrow(d), 0, 1.5)

  fit <- agri_np_regression(
    yield ~ plants, d,
    method = "integer_grid",
    integer_base_method = "smoothing_spline",
    predictor_support = "observed_integer"
  )

  expect_equal(fit$integer_support, 1:9)
  pr <- agri_integer_predict(fit)
  expect_true(all(pr$plants == as.integer(pr$plants)))
  expect_error(agri_np_predict(fit, data.frame(plants = 4.5)), "integer")
  expect_error(agri_np_predict(fit, data.frame(plants = 10)), "support")

  op <- agri_integer_optimum(fit)
  expect_true(all(op$optima$plants %in% 1:9))
})

test_that("integer_range supports unit finite differences and thresholds", {
  set.seed(502)
  d <- data.frame(insects = rep(c(0, 2, 4, 6, 8, 10), each = 5))
  d$damage <- 3 + 1.8*d$insects + rnorm(nrow(d), 0, 1)

  fit <- agri_np_regression(
    damage ~ insects, d,
    method = "integer_grid",
    integer_base_method = "smoothing_spline",
    predictor_support = "integer_range",
    integer_range = c(0, 10)
  )

  expect_equal(fit$integer_support, 0:10)
  d1 <- agri_integer_difference(fit, order = 1)
  expect_true(all(d1$delta_x == 1))
  d2 <- agri_integer_difference(fit, order = 2)
  expect_equal(nrow(d2), 9)

  th <- agri_integer_threshold(fit, criterion = "gain_from_baseline",
                               value = 5, baseline = 0)
  expect_true(is.na(th$integer_value) || th$integer_value %in% 0:10)
})

test_that("observed_integer support does not interpolate untested integer treatments", {
  d <- data.frame(plants = rep(c(1, 3, 5, 7, 9), each = 4))
  d$yield <- 20 + 5*d$plants - .4*d$plants^2 + rnorm(nrow(d))

  fit <- agri_np_regression(
    yield ~ plants, d,
    method = "integer_grid",
    integer_base_method = "smoothing_spline",
    predictor_support = "observed_integer"
  )
  expect_equal(fit$integer_support, c(1L,3L,5L,7L,9L))
  expect_error(agri_np_predict(fit, data.frame(plants = 4)), "support")
  expect_error(agri_integer_difference(fit, order = 2), "consecutive")
})

test_that("integer optimum bootstrap returns a discrete probability distribution", {
  set.seed(503)
  d <- expand.grid(plants = 1:8, rep = 1:8)
  d$yield <- 30 + 7*d$plants - .6*d$plants^2 + rnorm(nrow(d), 0, 1)

  fit <- agri_np_regression(
    yield ~ plants, d,
    method = "integer_grid",
    integer_base_method = "smoothing_spline",
    predictor_support = "integer_range"
  )
  bt <- agri_integer_bootstrap(fit, B = 19, seed = 77)
  expect_s3_class(bt, "agri_integer_bootstrap")
  expect_true(bt$successful > 0)
  expect_equal(sum(bt$probabilities$probability, na.rm = TRUE), 1, tolerance = 1e-8)

  cs <- agri_integer_confset(bt, level = .80)
  expect_s3_class(cs, "agri_integer_confset")
  expect_true(all(cs$values %in% 1:8))
  expect_gte(cs$probability_mass, .80)
})

test_that("discrete_kernel uses ordered integer support when np is available", {
  skip_if_not_installed("np")
  set.seed(504)
  d <- data.frame(insects = rep(0:7, each = 6))
  d$damage <- 5 + 2*d$insects + rnorm(nrow(d), 0, 1.2)

  fit <- agri_np_regression(
    damage ~ insects, d,
    method = "discrete_kernel",
    predictor_support = "observed_integer",
    integer_kernel = "wangvanryzin"
  )
  expect_equal(fit$integer_support, 0:7)
  expect_true(is.ordered(fit$model_data$insects))
  expect_true(all(is.finite(agri_integer_predict(fit)$fit)))
})

test_that("unimodal isotonic optimum is an admissible observed integer", {
  skip_if_not_installed("Iso")
  set.seed(505)
  d <- data.frame(plants = rep(1:9, each = 6))
  d$yield <- 40 + 10*pmin(d$plants, 5) - 6*pmax(d$plants - 5, 0) + rnorm(nrow(d), 0, 2)

  fit <- agri_np_regression(
    yield ~ plants, d,
    method = "unimodal_isotonic",
    predictor_support = "observed_integer"
  )
  expect_true(fit$unimodal_mode %in% 1:9)
  op <- agri_integer_optimum(fit)
  expect_true(all(op$optima$plants %in% 1:9))
})

test_that("umbrella regression preserves block as a parametric adjustment", {
  skip_if_not_installed("cgam")
  set.seed(506)
  d <- expand.grid(block = factor(1:4), plants = 1:8)
  d$yield <- 25 + 9*pmin(d$plants, 5) - 5*pmax(d$plants - 5, 0) +
    as.numeric(d$block) + rnorm(nrow(d), 0, 1.5)

  fit <- agri_np_regression(
    yield ~ plants, d,
    method = "umbrella",
    block = block,
    predictor_support = "observed_integer"
  )
  expect_equal(fit$block, "block")
  expect_true(all(agri_integer_predict(fit)$plants %in% 1:8))
})

test_that("integer efficiency remains on the declared support", {
  d <- data.frame(plants = rep(1:7, each = 5))
  d$yield <- 10 + 6*d$plants - .45*d$plants^2 + rnorm(nrow(d), 0, .5)
  fit <- agri_np_regression(
    yield ~ plants, d, method = "integer_grid",
    integer_base_method = "smoothing_spline",
    predictor_support = "observed_integer"
  )
  ef <- agri_integer_efficiency(fit)
  expect_equal(ef$plants, 1:7)
  expect_true(all(ef$plants == as.integer(ef$plants)))
})
