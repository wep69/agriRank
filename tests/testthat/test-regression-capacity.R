# Extractors, coefficient bootstrap, explained-variation indices and the
# graphics of the regression module.

test_that("fitted and residuals exist for every engine, coefficients only where defined", {
  data(agri_dose, package = "agriRank")
  ss <- agri_np_regression(yield ~ dose, agri_dose, method = "smoothing_spline")

  expect_length(fitted(ss), nrow(agri_dose))
  expect_length(residuals(ss), nrow(agri_dose))
  # residual = observed - fitted, to numerical precision
  expect_equal(unname(residuals(ss)), agri_dose$yield - unname(fitted(ss)), tolerance = 1e-8)

  # A smoother has no interpretable coefficient vector, and says so.
  expect_error(coef(ss), regexp = "does not define interpretable")

  skip_if_not_installed("mblm")
  ts <- agri_np_regression(yield ~ dose, agri_dose, method = "theil_sen")
  cf <- coef(ts)
  expect_length(cf, 2L)
  expect_true(all(is.finite(cf)))
  expect_equal(unname(cf), unname(stats::coef(ts$engine)))
})

test_that("confint uses the backend when available and the bootstrap otherwise", {
  skip_if_not_installed("mblm")
  data(agri_dose, package = "agriRank")
  ts <- agri_np_regression(yield ~ dose, agri_dose, method = "theil_sen")

  cb <- confint(ts, method = "backend")
  expect_named(cb, c("term", "estimate", "lower", "upper", "method"))
  expect_true(all(cb$lower <= cb$estimate & cb$estimate <= cb$upper))
  expect_true(all(cb$method == "backend"))

  bs <- confint(ts, method = "bootstrap", B = 49, seed = 1)
  expect_true(all(bs$method == "bootstrap"))
  expect_true(all(bs$lower <= bs$estimate & bs$estimate <= bs$upper))
  expect_equal(bs$estimate, cb$estimate, tolerance = 1e-8)

  ss <- agri_np_regression(yield ~ dose, agri_dose, method = "smoothing_spline")
  expect_error(confint(ss), regexp = "does not define interpretable")
})

test_that("the bootstrap resamples coefficients, keeps replicates and widens simultaneously", {
  data(agri_dose, package = "agriRank")
  ss <- agri_np_regression(yield ~ dose, agri_dose, method = "smoothing_spline")

  bp <- agri_np_bootstrap(ss, B = 49, n = 10, seed = 1, band = "pointwise")
  bsim <- agri_np_bootstrap(ss, B = 49, n = 10, seed = 1, band = "simultaneous")
  expect_identical(attr(bp, "band"), "pointwise")
  expect_identical(attr(bsim, "band"), "simultaneous")
  # A band that must cover the whole curve cannot be narrower than one that
  # covers each point separately.
  expect_gt(mean(bsim$upper - bsim$lower), mean(bp$upper - bp$lower))

  kr <- agri_np_bootstrap(ss, B = 49, n = 10, seed = 1, keep_replicates = TRUE)
  expect_equal(dim(attr(kr, "replicates")), c(10L, 49L))
  expect_null(attr(bp, "replicates"))

  skip_if_not_installed("mblm")
  ts <- agri_np_regression(yield ~ dose, agri_dose, method = "theil_sen")
  bc <- agri_np_bootstrap(ts, target = "coefficients", B = 49, seed = 1)
  expect_named(as.data.frame(bc), c("term", "estimate", "lower", "upper"))
  expect_equal(nrow(bc), 2L)
  expect_true(all(bc$lower <= bc$estimate & bc$estimate <= bc$upper))
  expect_error(agri_np_bootstrap(ss, target = "coefficients", B = 9),
               regexp = "does not define interpretable")
})

test_that("the diagnostics report three explained-variation indices", {
  data(agri_dose, package = "agriRank")
  ss <- agri_np_regression(yield ~ dose, agri_dose, method = "smoothing_spline")
  dg <- agri_np_diagnostics(ss, cv = TRUE, kfold = 4, seed = 1)

  expect_named(dg$r2, c("pseudo_r2", "cv_r2", "spearman_r2", "effective_df", "n"))
  expect_true(dg$r2$pseudo_r2 > 0 && dg$r2$pseudo_r2 <= 1)
  expect_true(dg$r2$spearman_r2 >= 0 && dg$r2$spearman_r2 <= 1)
  expect_true(is.finite(dg$r2$effective_df))

  # The fitted index is computed on the same data used to fit, so it cannot be
  # smaller than the out-of-fold one except by resampling noise.
  expect_gte(dg$r2$pseudo_r2, dg$r2$cv_r2 - 0.05)

  # 1 - SSE/SST, verified independently.
  manual <- 1 - sum(residuals(ss)^2) /
    sum((agri_dose$yield - mean(agri_dose$yield))^2)
  expect_equal(dg$r2$pseudo_r2, manual, tolerance = 1e-8)

  # Without the request the cross-validated index is not computed.
  expect_true(is.na(agri_np_diagnostics(ss)$r2$cv_r2))
})

test_that("every graphical output builds", {
  skip_if_not_installed("ggplot2")
  data(agri_dose, package = "agriRank")
  data(agri_density, package = "agriRank")
  ss <- agri_np_regression(yield ~ dose, agri_dose, method = "smoothing_spline")

  for (ty in c("fit", "residuals", "derivative", "qq", "scale_location", "order")) {
    expect_s3_class(agri_np_plot(ss, type = ty), "ggplot")
  }

  b <- agri_np_bootstrap(ss, B = 19, n = 10, seed = 1)
  expect_s3_class(agri_np_plot(ss, bootstrap = b), "ggplot")
  expect_s3_class(plot(b), "ggplot")

  fi <- agri_np_regression(yield ~ plants, agri_density, method = "integer_grid",
                           integer_base_method = "smoothing_spline",
                           predictor_support = "observed_integer")
  for (ty in c("fit", "efficiency", "difference", "derivative")) {
    expect_s3_class(agri_np_plot(fi, type = ty), "ggplot")
  }
  # The integer fit must not be drawn as a continuous line.
  geoms <- vapply(agri_np_plot(fi, type = "fit")$layers,
                  function(l) class(l$geom)[1], character(1))
  expect_true("GeomStep" %in% geoms)
  expect_false("GeomLine" %in% geoms)

  # Decision figures are refused for a fit without an integer support.
  expect_error(agri_np_plot(ss, type = "efficiency"), regexp = "integer decision support")

  bt <- agri_integer_bootstrap(fi, B = 19, seed = 1)
  expect_s3_class(plot(bt), "ggplot")
  expect_s3_class(plot(bt, level = 0.9), "ggplot")
  expect_s3_class(plot(agri_integer_confset(bt, 0.9)), "ggplot")

  cmp <- agri_np_compare(yield ~ dose, agri_dose, kfold = 3, seed = 1,
                         methods = c("smoothing_spline", "loess"))
  expect_s3_class(cmp, "agri_np_compare")
  expect_s3_class(plot(cmp), "ggplot")

  expect_s3_class(agri_np_curves(yield ~ dose, agri_dose,
                                 methods = c("smoothing_spline", "loess")), "ggplot")
})
