# Qualitative factors in regression models and coefficient forest plots.
#
# These tests protect three scientific requirements: a factor must contrast at
# least two levels to enter a model; bootstrap replicates of a coefficient
# vector must be compared term by term, never position by position; and a
# forest plot must show every level of a qualitative factor, including the
# reference level drawn at zero.
#
# The shared factor data builder lives in helper-regression-data.R.

test_that("a qualitative predictor needs at least two levels to enter a model", {
  skip_if_not_installed("quantreg")
  data(agri_dose, package = "agriRank")
  dz <- agri_dose
  dz$cultivar <- factor("Ana")
  # One level carries no contrast against the response; a model-matrix column
  # of zeros would only pretend to estimate it.
  expect_error(
    agri_np_regression(yield ~ dose + cultivar, dz, method = "quantile"),
    regexp = "fewer than two levels"
  )
})

test_that("character predictors are read as qualitative factors", {
  skip_if_not_installed("quantreg")
  dz <- .np_make_factor_data()
  dz$cultivar <- as.character(dz$cultivar)
  fit <- agri_np_regression(yield ~ dose + cultivar, dz, method = "quantile")
  expect_true(is.factor(fit$data$cultivar))
  expect_equal(fit$factor_predictors, "cultivar")
  expect_named(coef(fit), c("(Intercept)", "dose", "cultivarBela"))
})

test_that("quantile regression keeps a qualitative factor as an adjustment term", {
  skip_if_not_installed("quantreg")
  dz <- .np_make_factor_data()
  fit <- agri_np_regression(yield ~ dose + cultivar, dz, method = "quantile")
  expect_equal(fit$factor_predictors, "cultivar")
  expect_named(coef(fit), c("(Intercept)", "dose", "cultivarBela"))
  # The cultivar shift must be visible in predictions at the same dose.
  nd <- data.frame(
    dose = c(120, 120),
    cultivar = factor(c("Ana", "Bela"), levels = levels(dz$cultivar))
  )
  pp <- as.numeric(agri_np_predict(fit, nd))
  expect_length(pp, 2L)
  expect_equal(unname(pp[2] - pp[1]), unname(coef(fit)["cultivarBela"]),
               tolerance = 1e-8)
  # The printed object names the qualitative predictor.
  expect_output(print(fit), "Qualitative predictors: cultivar")
})

test_that("block-adjusted quantile regression retains factor coefficients", {
  skip_if_not_installed("quantreg")
  dz <- .np_make_factor_data()
  fit <- agri_np_regression(yield ~ dose + cultivar, dz, method = "quantile",
                            block = block)
  cf <- coef(fit)
  expect_true(all(c("(Intercept)", "dose", "cultivarBela") %in% names(cf)))
  expect_true(any(grepl("^block", names(cf))))
})

test_that("engines without qualitative adjustment refuse factors by name", {
  skip_if_not_installed("mblm")
  dz <- .np_make_factor_data()
  expect_error(
    agri_np_regression(yield ~ dose + cultivar, dz, method = "theil_sen"),
    regexp = "qualitative"
  )
  expect_error(
    agri_np_regression(yield ~ dose + cultivar, dz, method = "loess"),
    regexp = "qualitative"
  )
})

test_that("GAM and kernel engines accept qualitative factors", {
  dz <- .np_make_factor_data()
  nd <- data.frame(
    dose = c(60, 180),
    cultivar = factor(c("Ana", "Bela"), levels = levels(dz$cultivar))
  )
  skip_if_not_installed("mgcv")
  fg <- agri_np_regression(yield ~ dose + cultivar, dz, method = "gam")
  expect_length(as.numeric(agri_np_predict(fg, nd)), 2L)
  skip_if_not_installed("np")
  fk <- agri_np_regression(yield ~ dose + cultivar, dz, method = "kernel")
  expect_length(as.numeric(agri_np_predict(fk, nd)), 2L)
})

test_that("coefficient bootstrap aligns replicates by term name", {
  original <- c("(Intercept)" = 1, dose = 2, cultivarBela = 3)
  # A depleted replicate does not estimate the same parameter vector.
  expect_null(agriRank:::.np_align_coefficients(
    original, c("(Intercept)" = 1, dose = 2)))
  # A replicate that lost a level and gained another parameter is not the
  # same model either.
  expect_null(agriRank:::.np_align_coefficients(
    original, c(dose = 2, cultivarBela = 3, block2 = 4)))
  # A reordered replicate must be read back in the original order.
  shuffled <- c(cultivarBela = 3, "(Intercept)" = 1, dose = 2)
  expect_equal(agriRank:::.np_align_coefficients(original, shuffled), original)
})

test_that("the coefficient bootstrap of a factor model reproduces coef()", {
  skip_if_not_installed("quantreg")
  dz <- .np_make_factor_data()
  fit <- agri_np_regression(yield ~ dose + cultivar, dz, method = "quantile")
  bt <- agri_np_bootstrap(fit, target = "coefficients", B = 49, seed = 1)
  expect_equal(bt$term, names(coef(fit)))
  expect_equal(bt$estimate, unname(coef(fit)), tolerance = 1e-8)
  expect_true(all(bt$lower <= bt$estimate & bt$estimate <= bt$upper))
})

test_that("the coefficient bootstrap excludes block adjustment terms", {
  skip_if_not_installed("quantreg")
  dz <- .np_make_factor_data()
  fit <- agri_np_regression(yield ~ dose + cultivar, dz, method = "quantile",
                            block = block)
  bt <- agri_np_bootstrap(fit, target = "coefficients", B = 49, seed = 1)
  # Block dummies are nuisance parameters under cluster resampling; only the
  # scientific coefficients of the declared formula are reported.
  expect_equal(bt$term, c("(Intercept)", "dose", "cultivarBela"))
  expect_equal(bt$estimate, unname(coef(fit)[bt$term]), tolerance = 1e-8)
  expect_true(all(bt$lower <= bt$estimate & bt$estimate <= bt$upper))
})

test_that("agri_np_forest stacks every level of a qualitative factor", {
  skip_if_not_installed("quantreg")
  skip_if_not_installed("ggplot2")
  dz <- .np_make_factor_data()
  fit <- agri_np_regression(yield ~ dose + cultivar, dz, method = "quantile")
  bt <- agri_np_bootstrap(fit, target = "coefficients", B = 49, seed = 1)

  p <- agri_np_forest(fit, bootstrap = bt)
  expect_s3_class(p, "ggplot")
  pd <- p$data
  # The intercept stays in the table, not in the figure: slope plus the two
  # factor levels (reference included).
  expect_equal(nrow(pd), length(coef(fit)))
  ref <- pd[pd$is_reference, , drop = FALSE]
  expect_equal(nrow(ref), 1L)
  expect_equal(ref$estimate, 0)
  expect_equal(ref$label, "Ana")
  expect_true("Bela" %in% pd$label)
  expect_false("(Intercept)" %in% pd$term)
  # With a factor panel the figure carries one panel per group of terms.
  expect_true(inherits(p$facet, "FacetWrap"))
  # The intercept can be kept on request.
  expect_equal(nrow(agri_np_forest(fit, bootstrap = bt, include_intercept = TRUE)$data),
               length(coef(fit)) + 1L)

  # Without grouping every non-intercept coefficient is exactly one row and
  # nothing is invented.
  p2 <- agri_np_forest(fit, bootstrap = bt, by_factor = FALSE)
  expect_equal(nrow(p2$data), length(coef(fit)) - 1L)
  expect_false(any(p2$data$is_reference))

  # The same figure is reachable through the unified plot verb.
  expect_s3_class(agri_np_plot(fit, type = "forest", bootstrap = bt), "ggplot")

  # When no bootstrap is supplied one is computed on the spot.
  expect_s3_class(agri_np_forest(fit, B = 19, seed = 1), "ggplot")
})

test_that("agri_np_forest refuses objects without interpretable coefficients", {
  skip_if_not_installed("ggplot2")
  data(agri_dose, package = "agriRank")
  ss <- agri_np_regression(yield ~ dose, agri_dose, method = "smoothing_spline")
  # A smoother estimates a curve, not a finite parameter vector.
  expect_error(agri_np_forest(ss), regexp = "does not define interpretable")
  # A curve bootstrap cannot be redrawn as coefficient intervals.
  bc <- agri_np_bootstrap(ss, B = 9, n = 5, seed = 1)
  expect_error(agri_np_forest(ss, bootstrap = bc), regexp = "coefficients")
})
