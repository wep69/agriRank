test_that("agri_np_sizer classifies a known plateau and refuses integer support", {
  skip_if_not_installed("SiZer")
  skip_if_not_installed("mgcv")
  data(agri_dose, package = "agriRank")
  fit <- agri_np_regression(yield ~ dose, agri_dose, method = "gam", block = block)

  sz <- agri_np_sizer(fit)
  expect_s3_class(sz, "agri_np_sizer")
  expect_true(all(c("map", "summary", "stability") %in% names(sz)))
  expect_true(all(sz$map$state %in%
                    c("increasing", "decreasing", "flat", "sparse")))

  # The generating process rises then plateaus, so both states must appear and
  # the increasing run must come first.
  st <- summary(sz)
  expect_true(all(c("increasing", "flat") %in% st$state))
  expect_equal(st$state[1L], "increasing")

  # The stability shares are a partition of the bandwidths that carried data.
  tot <- rowSums(sz$stability[, c("p_increasing", "p_flat", "p_decreasing"),
                              drop = FALSE])
  expect_true(all(abs(tot - 1) < 1e-8))
  expect_true(all(sz$stability$n_bandwidths > 0))

  st8 <- agri_np_significant_slope(sz, stability = 0.8)
  expect_true(is.finite(st8$increase_to))
  # A stricter requirement can never claim more of the axis than a looser one.
  st5 <- agri_np_significant_slope(sz, stability = 0.5)
  expect_true(st8$increase_to <= st5$increase_to)
})

test_that("agri_np_sizer rejects a derivative on integer support", {
  skip_if_not_installed("SiZer")
  data(agri_density, package = "agriRank")
  fi <- agri_np_regression(yield ~ plants, agri_density, method = "integer_grid",
                           integer_base_method = "smoothing_spline",
                           predictor_support = "observed_integer")
  expect_error(agri_np_sizer(fi), "agri_integer_difference")
})

test_that("split conformal reaches nominal coverage and respects the design", {
  skip_if_not_installed("mgcv")
  data(agri_dose, package = "agriRank")
  fit <- agri_np_regression(yield ~ dose, agri_dose, method = "gam", block = block)

  cw <- agri_np_conformal(fit, newdata = agri_dose, level = 0.90, seed = 1)
  expect_s3_class(cw, "agri_np_conformal")
  expect_true(all(cw$lower <= cw$upper))
  expect_identical(attr(cw, "scope"), "within_block")

  cov <- agri_np_coverage(cw, data = agri_dose)
  expect_equal(cov$target, 0.90)
  expect_gte(cov$empirical, 0.80)
  expect_equal(sum(cov$by_block$n), nrow(agri_dose))

  # A higher level can only widen the interval.
  c95 <- agri_np_conformal(fit, newdata = agri_dose, level = 0.95, seed = 1)
  expect_gte(mean(c95$upper - c95$lower), mean(cw$upper - cw$lower))

  # Predicting into an unobserved block is a stronger claim, hence wider.
  cn <- agri_np_conformal(fit, newdata = agri_dose, level = 0.90, seed = 1,
                          scope = "new_block")
  expect_identical(attr(cn, "scope"), "new_block")
  expect_gt(mean(cn$upper - cn$lower), mean(cw$upper - cw$lower))

  # The same seed must reproduce the split exactly.
  expect_equal(agri_np_conformal(fit, newdata = agri_dose, level = 0.90, seed = 1)$upper,
               cw$upper)
})

test_that("conformal covers a future plot more widely than the curve", {
  skip_if_not_installed("mgcv")
  data(agri_dose, package = "agriRank")
  fit <- agri_np_regression(yield ~ dose, agri_dose, method = "gam", block = block)
  nd <- data.frame(dose = c(80, 160, 240),
                   block = factor("B3", levels = levels(agri_dose$block)))

  an <- as.data.frame(agri_np_predict(fit, nd, interval = "confidence"))
  co <- as.data.frame(agri_np_conformal(fit, newdata = nd, level = 0.95, seed = 1))
  expect_true(all(co$upper - co$lower > an$upper - an$lower))
})

test_that("normalized conformal redistributes width without losing coverage", {
  skip_if_not_installed("mgcv")
  data(agri_dose, package = "agriRank")
  fit <- agri_np_regression(yield ~ dose, agri_dose, method = "gam", block = block)

  flat <- agri_np_conformal(fit, newdata = agri_dose, level = 0.90, seed = 1)
  # Interpolating a de-duplicated smooth must not raise a ties warning.
  expect_silent(
    sc <- agri_np_conformal(fit, newdata = agri_dose, level = 0.90, seed = 1,
                            normalize = TRUE)
  )
  expect_equal(length(unique(round(flat$upper - flat$lower, 8))), 1L)
  expect_gt(length(unique(round(sc$upper - sc$lower, 8))), 1L)
  expect_gte(agri_np_coverage(sc, data = agri_dose)$empirical, 0.80)
})

test_that("conformal input guards fire", {
  skip_if_not_installed("mgcv")
  data(agri_dose, package = "agriRank")
  fit <- agri_np_regression(yield ~ dose, agri_dose, method = "gam", block = block)
  expect_error(agri_np_conformal(fit, level = 0), "level")
  expect_error(agri_np_conformal(fit, level = 1), "level")
  expect_error(agri_np_conformal(agri_dose), "agri_np_reg_fit")
})

test_that("simulation diagnostics run and the location check has power", {
  skip_if_not_installed("mgcv")
  data(agri_dose, package = "agriRank")
  fit <- agri_np_regression(yield ~ dose, agri_dose, method = "gam", block = block)

  sd_fit <- agri_np_simdiag(fit, nsim = 120, seed = 1)
  expect_s3_class(sd_fit, "agri_np_simdiag")
  expect_equal(nrow(sd_fit$checks), 3L)
  expect_true(all(sd_fit$checks$p_value >= 0 & sd_fit$checks$p_value <= 1))
  expect_true(all(sd_fit$scaled >= 0 & sd_fit$scaled <= 1))

  # Same seed, same answer.
  expect_equal(agri_np_simdiag(fit, nsim = 120, seed = 1)$checks$p_value,
               sd_fit$checks$p_value)

  # A straight line cannot follow the built-in plateau. The location check is
  # the one that must notice, and the marginal uniformity check is the one that
  # must not be trusted to.
  fit_line <- agri_np_regression(yield ~ dose, agri_dose, method = "theil_sen")
  bad <- agri_np_simdiag(fit_line, nsim = 300, seed = 1)$checks
  good <- agri_np_simdiag(fit, nsim = 300, seed = 1)$checks
  loc <- "location along the gradient"
  expect_lt(bad$p_value[bad$check == loc], good$p_value[good$check == loc])
  expect_lt(bad$p_value[bad$check == loc], 0.10)
})

test_that("new uncertainty methods have printers and plots", {
  skip_if_not_installed("mgcv")
  skip_if_not_installed("ggplot2")
  data(agri_dose, package = "agriRank")
  fit <- agri_np_regression(yield ~ dose, agri_dose, method = "gam", block = block)

  cf <- agri_np_conformal(fit, newdata = agri_dose, level = 0.90, seed = 1)
  expect_output(print(cf), "future plot")
  expect_s3_class(plot(cf), "ggplot")

  sd_fit <- agri_np_simdiag(fit, nsim = 60, seed = 1)
  expect_output(print(sd_fit), "uniform")
  expect_s3_class(plot(sd_fit, type = "uniform_qq"), "ggplot")
  expect_s3_class(plot(sd_fit, type = "residual_predictor"), "ggplot")

  skip_if_not_installed("SiZer")
  sz <- agri_np_sizer(fit)
  expect_output(print(sz), "increasing|flat")
  expect_s3_class(plot(sz, type = "map"), "ggplot")
  expect_s3_class(plot(sz, type = "stability"), "ggplot")
})
