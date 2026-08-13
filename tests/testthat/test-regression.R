test_that("base nonparametric regression engines fit and predict", {
  set.seed(102)
  d <- data.frame(x = seq(0, 10, length.out = 40))
  d$y <- 3 + sin(d$x/2) + rnorm(40, 0, .2)

  ss <- agri_np_regression(y ~ x, d, method = "smoothing_spline")
  expect_s3_class(ss, "agri_np_reg_fit")
  expect_length(agri_np_predict(ss, data.frame(x = c(2, 4, 6))), 3)

  lo <- agri_np_regression(y ~ x, d, method = "loess")
  expect_s3_class(lo, "agri_np_reg_fit")
  expect_true(is.data.frame(agri_np_diagnostics(lo)$metrics))

  iso <- agri_np_regression(y ~ x, d, method = "isotonic", shape = "increasing")
  pp <- agri_np_predict(iso, data.frame(x = seq(0, 10, length.out = 20)))
  expect_true(all(diff(pp) >= -1e-10))
})

test_that("derivative optimum compare and bootstrap work", {
  set.seed(103)
  d <- data.frame(x = seq(0, 12, length.out = 45))
  d$y <- 2 + .8*d$x - .06*d$x^2 + rnorm(45, 0, .25)
  f <- agri_np_regression(y ~ x, d, method = "smoothing_spline")
  der <- agri_np_derivative(f, n = 30)
  expect_equal(nrow(der), 30)
  op <- agri_np_optimum(f, n = 100)
  expect_equal(nrow(op), 1)
  cmp <- agri_np_compare(y ~ x, d, methods = c("smoothing_spline", "loess"), kfold = 3)
  expect_equal(nrow(cmp), 2)
  bb <- agri_np_bootstrap(f, B = 9, n = 15)
  expect_equal(nrow(bb), 15)
})

test_that("regression plotting supports a two-dimensional surface", {
  set.seed(405)
  d <- expand.grid(x = seq(0, 8, length.out = 8), z = seq(0, 5, length.out = 7))
  d$y <- sin(d$x/2) + 0.3 * d$z + rnorm(nrow(d), 0, .15)
  f <- agri_np_regression(y ~ x + z, d, method = "loess", span = .8)
  p <- agri_np_plot(f, type = "surface", surface_predictors = c("x", "z"), n = 25)
  expect_s3_class(p, "ggplot")
})

test_that("auto regression does not use p-values for method selection", {
  set.seed(406)
  d <- data.frame(x = seq(0, 10, length.out = 30), y = rnorm(30))
  f <- agri_np_regression(y ~ x, d, method = "auto")
  expect_identical(f$method, "smoothing_spline")
})

test_that("interactive regression is an optional Plotly layer", {
  skip_if_not_installed("plotly")
  set.seed(407)
  d <- data.frame(x = 1:25, y = log1p(1:25) + rnorm(25, 0, .1))
  f <- agri_np_regression(y ~ x, d, method = "smoothing_spline")
  p <- agri_np_interactive(f)
  expect_true(inherits(p, "plotly"))
})

test_that("regression integrates with tables, reports and exports", {
  set.seed(408)
  d <- data.frame(x = seq(0, 10, length.out = 30), y = sin(seq(0, 10, length.out = 30)/2) + rnorm(30, 0, .15))
  f <- agri_np_regression(y ~ x, d, method = "smoothing_spline")
  tb <- agri_table(f, what = "metrics")
  expect_true(inherits(tb, "data.frame") || inherits(tb, "gt_tbl"))
  fn <- tempfile(fileext = ".md")
  expect_true(file.exists(agri_report(f, fn, format = "md")))
  rds <- tempfile(fileext = ".rds")
  expect_true(file.exists(export_results(f, rds)))
})

test_that("regression can inherit block and quantitative predictor from agri_design", {
  skip_if_not_installed("mgcv")
  set.seed(409)
  d <- expand.grid(block = factor(1:4), dose = seq(0, 100, length.out = 8))
  d$yield <- 4 + .05*d$dose + as.numeric(d$block)/3 + rnorm(nrow(d), 0, .2)
  des <- agri_design(yield ~ dose, d, design = "rcbd", block = block, quantitative = dose)
  f <- agri_np_regression(des, method = "gam")
  expect_identical(f$block, "block")
  expect_identical(f$primary_predictor, "dose")
  expect_true(inherits(f$design, "agri_design"))
})

test_that("kernel significance adapter preserves scientific predictor selection", {
  skip_if_not_installed("np")
  set.seed(410)
  d <- data.frame(x = runif(30), g = factor(rep(c("A", "B"), 15)))
  d$y <- 2 + sin(2*pi*d$x) + ifelse(d$g == "B", .5, 0) + rnorm(30, 0, .25)
  f <- agri_np_regression(y ~ x + g, d, method = "kernel")
  z <- agri_np_significance(f, variables = "g", B = 9, boot_type = "I")
  expect_identical(attr(z, "agriRank_variables"), "g")
})

test_that("specification test requires a Gaussian model retaining x and y", {
  skip_if_not_installed("np")
  set.seed(411)
  d <- data.frame(x = seq(0, 1, length.out = 28))
  d$y <- 1 + d$x + .8*d$x^2 + rnorm(28, 0, .1)
  bad <- lm(y ~ x, d)
  expect_error(agri_np_specification(bad, B = 9), "x = TRUE, y = TRUE")
  good <- lm(y ~ x, d, x = TRUE, y = TRUE)
  z <- agri_np_specification(good, B = 9)
  expect_true(inherits(z, "cmstest"))
})

test_that("regression safeguards do not silently ignore shape, weights, or subject dependence", {
  set.seed(412)
  d <- data.frame(x = 1:20, y = rnorm(20), w = runif(20, .5, 1.5))
  expect_error(agri_np_regression(y ~ x, d, method = "loess", shape = "increasing"), "shape constraint")
  expect_error(agri_np_regression(y ~ x, d, method = "isotonic"), "explicit scientific direction")
  expect_error(agri_np_regression(y ~ x, d, method = "isotonic", shape = "increasing", weights = d$w), "not implemented")

  dr <- expand.grid(subject = factor(1:8), time = factor(1:3), treatment = factor(c("A", "B")))
  dr$y <- rnorm(nrow(dr))
  des <- agri_design(y ~ treatment*time, dr, design = "repeated", subject = subject, within = time)
  expect_error(agri_np_regression(des, method = "gam"), "subject dependence")
})

test_that("regression missing-data handling is explicit", {
  d <- data.frame(x = 1:20, y = sin((1:20)/4))
  d$y[5] <- NA
  expect_error(agri_np_regression(y ~ x, d, method = "smoothing_spline"), "incomplete/non-finite")
  expect_warning(f <- agri_np_regression(y ~ x, d, method = "smoothing_spline", na_action = "complete"), "explicitly omitting")
  expect_equal(f$n_original, 20)
  expect_equal(f$n_omitted, 1)
  expect_equal(nrow(f$data), 19)
})
