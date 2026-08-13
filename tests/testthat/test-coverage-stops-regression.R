# Defensive guards of the regression module. Each expectation is one rule the
# package refuses to break, and the message is part of the contract.

reg_d <- function(seed = 901) {
  d <- data.frame(dose = rep(1:8, each = 6), g = factor(rep(c("a", "b"), 24)))
  set.seed(seed)
  d$block <- factor(rep(1:6, times = 8))
  d$yield <- 20 + 7 * d$dose - 0.55 * d$dose^2 + rnorm(48, 0, 1)
  d
}
int_grid <- function(d = reg_d()) {
  agri_np_regression(yield ~ dose, d, method = "integer_grid",
                     integer_base_method = "smoothing_spline",
                     predictor_support = "observed_integer")
}

test_that("integer support declarations are validated", {
  d <- reg_d()
  expect_error(agri_np_regression(yield ~ dose, d, method = "integer_grid",
                                  integer_base_method = "smoothing_spline",
                                  predictor_support = "integer_range",
                                  integer_range = c(1, NA)),
               regexp = "integer_range")
  expect_error(agri_np_regression(yield ~ dose, d, method = "integer_grid",
                                  integer_base_method = "smoothing_spline",
                                  predictor_support = "custom_integer"),
               regexp = "integer_values")
  expect_error(agri_np_regression(yield ~ dose, d, method = "integer_grid",
                                  integer_base_method = "smoothing_spline",
                                  predictor_support = "custom_integer",
                                  integer_values = c(1, Inf)),
               regexp = "integer_values")
  expect_error(agri_np_regression(yield ~ dose + g, d, method = "gam",
                                  integer_predictor = "g",
                                  predictor_support = "observed_integer"),
               regexp = "numeric")
  expect_error(agri_np_regression(yield ~ dose, d, method = "gam",
                                  integer_predictor = "not_a_predictor",
                                  predictor_support = "observed_integer"),
               regexp = "modeled predictors")
  d2 <- d; d2$dose <- d2$dose + 0.25
  expect_error(agri_np_regression(yield ~ dose, d2, method = "unimodal_isotonic",
                                  predictor_support = "observed_integer"),
               regexp = "integer")
})

test_that("integer prediction and decision helpers reject inadmissible input", {
  fit <- int_grid()
  cont <- agri_np_regression(yield ~ dose, reg_d(), method = "smoothing_spline")

  expect_error(agri_integer_predict(cont), regexp = "integer decision support")
  expect_error(agri_integer_optimum(cont), regexp = "integer")
  expect_error(agri_integer_predict(fit, fixed = list(nope = 1)),
               regexp = "fixed prediction variable")
  expect_error(agri_integer_predict(fit, support = c(NA, NA)), regexp = "support|integer")
  expect_error(agri_integer_difference(fit, order = 3L), regexp = "order")
  expect_error(agri_integer_threshold(fit, criterion = "fraction_of_maximum", value = 1.5),
               regexp = "value")
  expect_error(agri_integer_threshold(fit, criterion = "gain_from_baseline",
                                      value = 0.5, baseline = 999),
               regexp = "baseline")
  bs <- agri_integer_bootstrap(fit, B = 49L, seed = 2)
  expect_error(agri_integer_confset(bs, level = 1.2), regexp = "level")
  expect_error(agri_integer_confset(bs, level = 0), regexp = "level")
})

test_that("engine-specific preconditions are enforced", {
  d <- reg_d()
  skip_if_not_installed("scam")
  expect_error(agri_np_regression(yield ~ dose, d, method = "scam", shape = "none"),
               regexp = "shape")
  skip_if_not_installed("cobs")
  expect_error(agri_np_regression(yield ~ dose, d, method = "cobs",
                                  shape = "increasing", tau = c(0.25, 0.75)),
               regexp = "tau")
  expect_error(agri_np_regression(yield ~ dose + g, d, method = "loess"),
               regexp = "numeric")
  expect_error(agri_np_regression(yield ~ dose + g, d, method = "smoothing_spline"),
               regexp = "one numeric predictor")
})

test_that("formula and data contracts are enforced", {
  d <- reg_d()
  expect_error(agri_np_regression("not a formula", d), regexp = "formula")
  expect_error(agri_np_regression(yield ~ dose), regexp = "data")
  expect_error(agri_np_regression(yield ~ 1, d, method = "loess"), regexp = "predictor")
  expect_error(agri_np_regression(yield ~ dose, d, method = "gam",
                                  block = c("block", "g")),
               regexp = "one agronomic block")

  des <- agri_design(yield ~ dose, d, design = "rcbd", block = block)
  expect_s3_class(agri_np_regression(des, method = "gam"), "agri_np_reg_fit")

  rp <- simulate_agri("repeated", seed = 902)
  desr <- agri_design(height ~ treatment * time, rp, design = "repeated",
                      subject = subject, within = time)
  expect_error(agri_np_regression(desr, method = "gam"), regexp = "repeated|subject")
})

test_that("post-fit accessors reject objects of the wrong class", {
  d <- reg_d()
  notafit <- list(a = 1)
  expect_error(agri_np_predict(notafit), regexp = "agri_np_reg_fit")
  expect_error(agri_np_diagnostics(notafit), regexp = "agri_np_reg_fit")
  expect_error(agri_np_optimum(notafit), regexp = "agri_np_reg_fit")
  expect_error(agri_np_derivative(notafit), regexp = "agri_np_reg_fit")
  expect_error(agri_np_bootstrap(notafit), regexp = "agri_np_reg_fit")
  expect_error(agri_np_plot(notafit), regexp = "agri_np_reg_fit")
  expect_error(agri_np_significance(notafit), regexp = "agri_np_reg_fit")
})

test_that("plot, grid and cross-validation arguments are validated", {
  skip_if_not_installed("mgcv")
  d <- reg_d()
  f <- agri_np_regression(yield ~ dose, d, method = "gam")
  expect_error(agri_np_plot(f, type = "fit", group = "nope"), regexp = "grouping")
  expect_error(agri_np_plot(f, type = "surface"), regexp = "two numeric predictors")
  expect_error(agri_np_predict(f, newdata = data.frame(wrong = 1)), regexp = "dose|newdata|variable")

  expect_error(agri_np_compare(yield ~ dose, d, methods = c("gam", "loess"),
                               block = c("block", "g")),
               regexp = "one agronomic block")
  expect_error(agri_np_compare(yield ~ dose, d[1:4, ], methods = c("gam", "loess")),
               regexp = "six observations")

  expect_error(agri_np_bootstrap(f, cluster = c("block", "g")), regexp = "cluster")
  fi <- int_grid()
  expect_error(agri_integer_bootstrap(fi, cluster = c("block", "g")), regexp = "cluster")
})

test_that("kernel significance and specification adapters state their restrictions", {
  skip_if_not_installed("np")
  d <- reg_d()
  f_gam <- agri_np_regression(yield ~ dose, d, method = "gam")
  expect_error(agri_np_significance(f_gam), regexp = "kernel")

  f_k <- agri_np_regression(yield ~ dose, d, method = "kernel")
  expect_error(agri_np_significance(f_k, variables = "nope"), regexp = "Unknown predictor")

  expect_error(agri_np_specification("not a model"), regexp = "lm or glm")
  m <- stats::glm(g ~ dose, data = d, family = stats::binomial())
  expect_error(agri_np_specification(m), regexp = "Gaussian|continuous")
})
