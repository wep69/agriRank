test_that("the optimum test detects a boundary optimum and refuses to name a rate", {
  skip_if_not_installed("mgcv")
  data(agri_dose, package = "agriRank")
  fit <- agri_np_regression(yield ~ dose, agri_dose, method = "gam", block = block)

  ot <- agri_np_optimum_test(fit, B = 99, seed = 1, n = 60, external = FALSE)
  expect_s3_class(ot, "agri_np_optimum_test")
  expect_equal(nrow(ot$optimum), 1L)
  expect_null(ot$contrasts)

  # agri_dose plateaus, so the maximum is on the upper edge in every replicate.
  expect_gt(ot$optimum$p_boundary, 0.5)
  expect_false(ot$optimum$identified)
  expect_output(print(ot), "not identified by these data")

  # The interval must bracket the point estimate and lie inside the grid.
  expect_lte(ot$optimum$lower, ot$optimum$optimum)
  expect_gte(ot$optimum$upper, ot$optimum$optimum)
  expect_gte(ot$optimum$lower, min(agri_dose$dose))
  expect_lte(ot$optimum$upper, max(agri_dose$dose))

  # The declared block is the resampling unit unless told otherwise.
  expect_identical(attr(ot, "cluster"), "block")
  expect_equal(agri_np_optimum_test(fit, B = 99, seed = 1, n = 60,
                                    external = FALSE)$optimum$lower,
               ot$optimum$lower)
})

test_that("an interior optimum is identified and levels can be compared", {
  skip_if_not_installed("mgcv")
  data(agri_dose, package = "agriRank")
  set.seed(7)
  a <- agri_dose; a$cultivar <- "late"
  b <- agri_dose; b$cultivar <- "early"
  b$yield <- b$yield - 0.000045 * (b$dose - 160)^2 + rnorm(nrow(b), 0, 0.15)
  d2 <- rbind(a, b)
  d2$cultivar <- factor(d2$cultivar, levels = c("early", "late"))

  fit2 <- agri_np_regression(yield ~ dose + cultivar, d2, method = "gam",
                             block = block, gam_structure = "varying")
  expect_match(deparse1(fit2$formula_used), "by = cultivar", fixed = TRUE)

  ot <- agri_np_optimum_test(fit2, by = cultivar, B = 99, seed = 1, n = 60,
                             external = FALSE)
  expect_equal(nrow(ot$optimum), 2L)
  expect_true("early" %in% ot$optimum$level)

  # 'early' turns over inside the range, 'late' does not.
  e <- ot$optimum[ot$optimum$level == "early", ]
  l <- ot$optimum[ot$optimum$level == "late", ]
  expect_true(e$identified)
  expect_false(l$identified)
  expect_lt(e$optimum, l$optimum)

  expect_equal(nrow(ot$contrasts), 1L)
  expect_lt(ot$contrasts$p_value, 0.10)
  expect_false(ot$contrasts$both_identified)
  # The resampling p-value cannot be smaller than 2/(replicates + 1).
  expect_gte(ot$contrasts$p_value, 2 / (ot$contrasts$replicates + 1))
})

test_that("comparing optima across parallel curves is refused", {
  skip_if_not_installed("mgcv")
  data(agri_dose, package = "agriRank")
  d2 <- rbind(transform(agri_dose, cultivar = "a"),
              transform(agri_dose, cultivar = "b", yield = agri_dose$yield + 1))
  d2$cultivar <- factor(d2$cultivar)
  fa <- agri_np_regression(yield ~ dose + cultivar, d2, method = "gam",
                           block = block)
  expect_error(agri_np_optimum_test(fa, by = cultivar, B = 19), "parallel")
})

test_that("optimum-test guards fire", {
  skip_if_not_installed("mgcv")
  data(agri_dose, package = "agriRank")
  fit <- agri_np_regression(yield ~ dose, agri_dose, method = "gam", block = block)
  expect_error(agri_np_optimum_test(fit, level = 1), "level")
  expect_error(agri_np_optimum_test(agri_dose), "agri_np_reg_fit")
  expect_error(agri_np_optimum_test(fit, by = nowhere), "not a predictor")

  data(agri_density, package = "agriRank")
  fi <- agri_np_regression(yield ~ plants, agri_density, method = "integer_grid",
                           integer_base_method = "smoothing_spline",
                           predictor_support = "observed_integer")
  expect_error(agri_np_optimum_test(fi), "agri_integer_optimum")
})

test_that("optimum-test figures build", {
  skip_if_not_installed("mgcv")
  skip_if_not_installed("ggplot2")
  data(agri_dose, package = "agriRank")
  fit <- agri_np_regression(yield ~ dose, agri_dose, method = "gam", block = block)
  ot <- agri_np_optimum_test(fit, B = 49, seed = 1, n = 40, external = FALSE)
  expect_s3_class(plot(ot, type = "curve"), "ggplot")
  expect_s3_class(plot(ot, type = "distribution"), "ggplot")
})

test_that("a varying smooth needs both a numeric and a qualitative predictor", {
  skip_if_not_installed("mgcv")
  data(agri_dose, package = "agriRank")
  expect_error(
    agri_np_regression(yield ~ dose, agri_dose, method = "gam",
                       gam_structure = "varying"),
    "qualitative predictor")
})

test_that("smooth quantile regression fits and orders sensibly", {
  skip_if_not_installed("qgam")
  data(agri_dose, package = "agriRank")
  q10 <- agri_np_regression(yield ~ dose, agri_dose, method = "smooth_quantile",
                            tau = 0.10, block = block)
  q50 <- agri_np_regression(yield ~ dose, agri_dose, method = "smooth_quantile",
                            tau = 0.50, block = block)
  expect_s3_class(q10, "agri_np_reg_fit")
  expect_identical(q10$method, "smooth_quantile")

  nd <- data.frame(dose = c(80, 160, 240),
                   block = factor("B3", levels = levels(agri_dose$block)))
  p10 <- as.numeric(agri_np_predict(q10, nd))
  p50 <- as.numeric(agri_np_predict(q50, nd))
  expect_true(all(p10 < p50))

  # The analytic interval path must also work for this engine.
  ci <- as.data.frame(agri_np_predict(q50, nd, interval = "confidence"))
  expect_true(all(ci$lower <= ci$fit & ci$fit <= ci$upper))

  expect_error(agri_np_regression(yield ~ dose, agri_dose,
                                  method = "smooth_quantile", tau = c(0.1, 0.9)),
               "one quantile at a time")
  expect_error(agri_np_regression(yield ~ dose, agri_dose,
                                  method = "smooth_quantile", tau = 1.5),
               "strictly between 0 and 1")
})

test_that("the quantile fan tracks and reports its own limits", {
  skip_if_not_installed("qgam")
  data(agri_dose, package = "agriRank")
  set.seed(11)
  d <- do.call(rbind, lapply(1:12, function(bk) {
    z <- agri_dose[agri_dose$block == "B1", c("dose", "yield")]
    z$block <- factor(paste0("B", bk), levels = paste0("B", 1:12))
    z$yield <- z$yield + rnorm(nrow(z), 0, 0.10 + 0.006 * z$dose)
    z
  }))

  qc <- suppressWarnings(agri_np_quantile_curves(yield ~ dose, d, block = block,
                                                 n = 40))
  expect_s3_class(qc, "agri_np_quantile_curves")
  expect_equal(nrow(qc$summary), 5L)
  expect_true(all(qc$summary$tracking))
  # Coverage must be monotone in the quantile.
  expect_false(is.unsorted(qc$summary$coverage))
  # The data were built with variability growing in the rate.
  expect_gt(qc$spread$spread[nrow(qc$spread)], qc$spread$spread[1L])
  expect_equal(qc$crossings$n_grid, 40L)

  expect_error(agri_np_quantile_curves(yield ~ dose, d, quantiles = 0.5),
               "At least two quantiles")
  expect_error(agri_np_quantile_curves(yield ~ dose, d, quantiles = c(0.001, 0.999)),
               "in its tail")
  expect_error(agri_np_quantile_curves(yield ~ dose, d, quantiles = c(0, 0.5)),
               "strictly between 0 and 1")

  skip_if_not_installed("ggplot2")
  expect_s3_class(plot(qc, type = "fan"), "ggplot")
  expect_s3_class(plot(qc, type = "spread"), "ggplot")
  expect_output(print(qc), "coverage")
})

test_that("a shrunk block is a penalized term and stays usable downstream", {
  skip_if_not_installed("mgcv")
  data(agri_dose, package = "agriRank")
  ff <- agri_np_regression(yield ~ dose, agri_dose, method = "gam", block = block)
  fs <- agri_np_regression(yield ~ dose, agri_dose, method = "gam", block = block,
                           block_effect = "shrunk")
  expect_match(deparse1(fs$formula_used), 're"', fixed = TRUE)
  expect_identical(fs$block_effect, "shrunk")
  expect_identical(ff$block_effect, "fixed")

  # An engine with no penalized term must say so rather than ignore the request.
  expect_error(agri_np_regression(yield ~ dose, agri_dose, method = "loess",
                                  block = block, block_effect = "shrunk"),
               "penalized term")

  # Downstream machinery must accept the shrunk fit.
  dg <- agri_np_diagnostics(fs, cv = TRUE, seed = 1)
  expect_true(is.list(dg))
  expect_true(all(is.finite(dg$r2$pseudo_r2)))
  cf <- agri_np_conformal(fs, newdata = agri_dose, level = 0.90, seed = 1)
  expect_gte(agri_np_coverage(cf, data = agri_dose)$empirical, 0.80)
})

test_that("block effects are reported with the shrinkage made visible", {
  skip_if_not_installed("mgcv")
  data(agri_dose, package = "agriRank")
  fit <- agri_np_regression(yield ~ dose, agri_dose, method = "gam", block = block)

  be <- agri_np_block_effects(fit)
  expect_s3_class(be, "agri_np_block_effects")
  expect_equal(nrow(be), nlevels(agri_dose$block))
  expect_true(all(c("raw", "fixed", "shrunk", "shrinkage") %in% names(be)))
  # Effects are centred, and shrinking moves estimates towards zero.
  expect_lt(abs(sum(be$fixed)), 1e-6)
  expect_true(all(abs(be$shrunk) <= abs(be$fixed) + 1e-8))
  expect_true(all(be$shrinkage >= -1e-8))
  expect_output(print(be), "shrinkage|Shrunk")

  f3 <- agri_np_regression(yield ~ dose, agri_dose, method = "gam")
  expect_error(agri_np_block_effects(f3), "declares no block")

  skip_if_not_installed("ggplot2")
  expect_s3_class(plot(be), "ggplot")
  expect_error(plot(agri_np_block_effects(fit, compare = FALSE)), "Both columns")
})
