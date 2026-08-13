test_that("Kruskal engine returns omnibus p", {
  d <- simulate_agri("crd", seed = 3)
  z <- np_crd(yield ~ treatment, d, method = "kruskal")
  expect_s3_class(z, "agri_rank_fit")
  expect_true(is.finite(z$omnibus$p_value))
})

test_that("Friedman engine respects complete block structure", {
  d <- simulate_agri("rcbd", seed = 3)
  z <- np_rcbd(yield ~ treatment, d, block = block, method = "friedman")
  expect_true(is.finite(z$omnibus$p_value))
})
