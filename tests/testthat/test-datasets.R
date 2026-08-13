# The exported data sets are part of the documented interface: their structure
# is referenced by every regression example, so a silent change would break the
# documentation without breaking any function.

test_that("agri_dose has the documented structure", {
  data(agri_dose, package = "agriRank")
  expect_s3_class(agri_dose, "data.frame")
  expect_equal(dim(agri_dose), c(40L, 3L))
  expect_named(agri_dose, c("block", "dose", "yield"))
  expect_s3_class(agri_dose$block, "factor")
  expect_equal(nlevels(agri_dose$block), 5L)
  expect_equal(sort(unique(agri_dose$dose)), seq(0, 280, by = 40))
  # Complete and balanced: one plot per block-by-rate cell.
  expect_true(all(table(agri_dose$block, agri_dose$dose) == 1L))
  expect_true(all(is.finite(agri_dose$yield)))
})

test_that("agri_density is an integer treatment with a unimodal response", {
  data(agri_density, package = "agriRank")
  expect_equal(dim(agri_density), c(54L, 3L))
  expect_named(agri_density, c("block", "plants", "yield"))
  expect_equal(nlevels(agri_density$block), 6L)
  expect_equal(sort(unique(agri_density$plants)), 1:9)
  expect_true(all(agri_density$plants == round(agri_density$plants)))
  expect_true(all(table(agri_density$block, agri_density$plants) == 1L))

  # The block means must rise and then fall, otherwise the data set no longer
  # illustrates what the integer workflow is for.
  m <- tapply(agri_density$yield, agri_density$plants, mean)
  peak <- which.max(m)
  expect_true(peak > 1L && peak < length(m))
  expect_true(all(diff(m[seq_len(peak)]) > 0))
  expect_true(m[length(m)] < m[peak])
})

test_that("agri_surface carries two crossed quantitative gradients", {
  data(agri_surface, package = "agriRank")
  expect_equal(dim(agri_surface), c(70L, 4L))
  expect_named(agri_surface, c("block", "nitrogen", "water", "yield"))
  expect_equal(sort(unique(agri_surface$nitrogen)), seq(0, 240, by = 40))
  expect_equal(sort(unique(agri_surface$water)), seq(0.4, 1.2, by = 0.2))
  expect_true(all(table(agri_surface$nitrogen, agri_surface$water) == 2L))
})

test_that("the exported data sets drive the documented regression workflow", {
  data(agri_dose, package = "agriRank")
  data(agri_density, package = "agriRank")

  fit <- agri_np_regression(yield ~ dose, agri_dose, method = "smoothing_spline")
  expect_s3_class(fit, "agri_np_reg_fit")
  # Engines without analytic intervals return a plain numeric vector.
  expect_true(all(is.finite(as.numeric(unlist(agri_np_predict(fit))))))

  fi <- agri_np_regression(yield ~ plants, agri_density, method = "integer_grid",
                           integer_base_method = "smoothing_spline",
                           predictor_support = "observed_integer")
  expect_equal(fi$integer_support, 1:9)
  opt <- agri_integer_optimum(fi)$optima$plants
  expect_true(all(opt %in% 1:9))
})

test_that("the gradient scenarios of simulate_agri match the exported structures", {
  d1 <- simulate_agri("dose_response", seed = 11, n = 5)
  expect_named(d1, c("block", "dose", "yield"))
  expect_equal(sort(unique(d1$dose)), seq(0, 280, by = 40))
  expect_equal(nlevels(d1$block), 5L)

  d2 <- simulate_agri("integer_density", seed = 12, n = 6)
  expect_named(d2, c("block", "plants", "yield"))
  expect_equal(sort(unique(d2$plants)), 1:9)
  expect_true(all(d2$plants == round(d2$plants)))

  d3 <- simulate_agri("surface", seed = 13, n = 6)
  expect_named(d3, c("block", "nitrogen", "water", "yield"))
  expect_equal(sort(unique(d3$water)), seq(0.4, 1.2, by = 0.2))

  # Same seed, same data: the generators are reproducible.
  expect_identical(simulate_agri("dose_response", seed = 11, n = 5), d1)
})
