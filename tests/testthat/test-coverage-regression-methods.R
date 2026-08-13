# Parametrized sweep across every regression engine. The purpose is to exercise
# the dispatch branches, the optional-backend guards and the prediction adapter
# for all methods with one specification, not to re-check the numerical results
# already validated against each backend elsewhere.

reg_data <- function(seed = 771, n_level = 8L, rep = 6L) {
  set.seed(seed)
  d <- data.frame(dose = rep(seq_len(n_level), each = rep))
  d$block <- factor(rep(seq_len(rep), times = n_level))
  d$yield <- 20 + 7 * d$dose - 0.55 * d$dose^2 + rnorm(nrow(d), 0, 1)
  d
}

# method -> (package required, extra arguments)
reg_specs <- list(
  auto              = list(pkg = NULL,       args = list()),
  theil_sen         = list(pkg = "mblm",     args = list()),
  siegel            = list(pkg = "mblm",     args = list()),
  quantile          = list(pkg = "quantreg", args = list(tau = 0.5)),
  loess             = list(pkg = NULL,       args = list()),
  smoothing_spline  = list(pkg = NULL,       args = list()),
  kernel            = list(pkg = "np",       args = list()),
  gam               = list(pkg = "mgcv",     args = list()),
  scam              = list(pkg = "scam",     args = list(shape = "concave")),
  cobs              = list(pkg = "cobs",     args = list(shape = "concave")),
  isotonic          = list(pkg = NULL,       args = list(shape = "increasing")),
  discrete_kernel   = list(pkg = "np",       args = list(predictor_support = "observed_integer")),
  unimodal_isotonic = list(pkg = "Iso",      args = list(predictor_support = "observed_integer")),
  umbrella          = list(pkg = "cgam",     args = list(predictor_support = "observed_integer")),
  integer_grid      = list(pkg = NULL,       args = list(predictor_support = "observed_integer",
                                                         integer_base_method = "smoothing_spline"))
)

test_that("every regression engine fits, prints and predicts on its own support", {
  d <- reg_data()
  for (m in names(reg_specs)) {
    spec <- reg_specs[[m]]
    if (!is.null(spec$pkg) && !requireNamespace(spec$pkg, quietly = TRUE)) next

    fit <- do.call(agri_np_regression,
                   c(list(yield ~ dose, d, method = m), spec$args))

    expect_s3_class(fit, "agri_np_reg_fit")
    expect_true(is.character(fit$method) && nzchar(fit$method))
    expect_output(print(fit), regexp = ".", info = m)

    pr <- if (identical(m, "integer_grid") ||
              !is.null(spec$args$predictor_support)) {
      agri_integer_predict(fit)
    } else {
      agri_np_predict(fit)
    }
    expect_true(NROW(pr) > 0L, info = m)
    fitted_col <- if (is.data.frame(pr)) pr[[intersect(c("fit", "fitted"), names(pr))[1]]] else pr
    expect_true(all(is.finite(as.numeric(fitted_col))), info = m)
  }
})

test_that("prediction intervals and derivatives are available where implemented", {
  d <- reg_data()
  skip_if_not_installed("mgcv")
  fit <- agri_np_regression(yield ~ dose, d, method = "gam")

  ci <- agri_np_predict(fit, interval = "confidence")
  expect_true(all(c("fit", "lower", "upper") %in% names(as.data.frame(ci))))
  expect_true(all(ci$lower <= ci$fit & ci$fit <= ci$upper))

  dv <- agri_np_derivative(fit)
  expect_true(NROW(dv) > 0L)

  op <- agri_np_optimum(fit)
  expect_true(!is.null(op))

  expect_s3_class(agri_np_plot(fit, type = "fit"), "ggplot")
  expect_s3_class(agri_np_plot(fit, type = "residuals"), "ggplot")
  expect_s3_class(agri_np_plot(fit, type = "derivative"), "ggplot")

  expect_true(is.list(agri_np_diagnostics(fit)) || is.data.frame(agri_np_diagnostics(fit)))
})

test_that("block-aware engines accept a declared block and refuse the ones that ignore it", {
  d <- reg_data()
  skip_if_not_installed("mgcv")
  fb <- agri_np_regression(yield ~ dose, d, method = "gam", block = block)
  expect_identical(fb$block, "block")

  for (m in c("loess", "smoothing_spline", "isotonic", "unimodal_isotonic", "theil_sen")) {
    expect_error(
      agri_np_regression(yield ~ dose, d, method = m, block = block,
                         shape = if (m %in% c("isotonic")) "increasing" else "none"),
      regexp = "block", info = m
    )
  }
})

test_that("shape constraints are honored or refused explicitly", {
  d <- reg_data()
  skip_if_not_installed("scam")
  fs <- agri_np_regression(yield ~ dose, d, method = "scam", shape = "concave")
  expect_s3_class(fs, "agri_np_reg_fit")

  expect_error(agri_np_regression(yield ~ dose, d, method = "loess", shape = "increasing"),
               regexp = "shape")
  expect_error(agri_np_regression(yield ~ dose, d, method = "isotonic", shape = "none"),
               regexp = "direction")
  expect_error(agri_np_regression(yield ~ dose, d, method = "umbrella", shape = "increasing"),
               regexp = "shape|umbrella")
})

test_that("weights are either used or refused, never silently dropped", {
  d <- reg_data()
  w <- runif(nrow(d), 0.5, 1.5)
  skip_if_not_installed("mgcv")
  expect_s3_class(agri_np_regression(yield ~ dose, d, method = "gam", weights = w),
                  "agri_np_reg_fit")
  expect_error(agri_np_regression(yield ~ dose, d, method = "theil_sen", weights = w),
               regexp = "weights")
  expect_error(agri_np_regression(yield ~ dose, d, method = "gam", weights = w[-1]),
               regexp = "one value per input row")
})

test_that("missing data must be declared, not silently discarded", {
  d <- reg_data()
  d$yield[c(3, 10)] <- NA
  expect_error(agri_np_regression(yield ~ dose, d, method = "smoothing_spline"),
               regexp = "incomplete")
  expect_warning(
    f <- agri_np_regression(yield ~ dose, d, method = "smoothing_spline",
                            na_action = "complete"),
    regexp = "omitting"
  )
  expect_s3_class(f, "agri_np_reg_fit")
})

test_that("model comparison and specification workflows run across engines", {
  d <- reg_data()
  skip_if_not_installed("mgcv")
  cmp <- agri_np_compare(yield ~ dose, d,
                         methods = c("smoothing_spline", "loess", "gam"),
                         kfold = 3L, seed = 5)
  expect_true(NROW(cmp$table %||% cmp) >= 3L)

  fit <- agri_np_regression(yield ~ dose, d, method = "gam")
  bs <- agri_np_bootstrap(fit, B = 49L, seed = 7)
  expect_true(!is.null(bs))
})
