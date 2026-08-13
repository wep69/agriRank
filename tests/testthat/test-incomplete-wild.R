test_that("native incomplete repeated engine retains incomplete subjects", {
  d <- simulate_agri("repeated_missing", seed = 8, n = 8, missing_rate = .1)
  x <- agri_design(height ~ treatment*time, d, design="repeated", subject=subject, within=time)
  # Small B only for package unit tests; substantive analyses should use >=999.
  z <- incomplete_wild_rank_test(x, B = 199, seed = 9, missing_assumption = "MCAR")
  expect_s3_class(z, "agri_incomplete_wild")
  expect_true(all(z$omnibus$p_boot >= 0 & z$omnibus$p_boot <= 1))
  expect_true(nrow(z$effects) == length(z$p_vector))
})

test_that("row order does not change native point effects", {
  d <- simulate_agri("repeated_missing", seed = 12, n = 8, missing_rate = .08)
  x1 <- agri_design(height ~ treatment*time, d, design="repeated", subject=subject, within=time)
  d2 <- d[sample.int(nrow(d)),]
  x2 <- agri_design(height ~ treatment*time, d2, design="repeated", subject=subject, within=time)
  z1 <- incomplete_wild_rank_test(x1, B=199, seed=4, missing_assumption="MCAR")
  z2 <- incomplete_wild_rank_test(x2, B=199, seed=4, missing_assumption="MCAR")
  expect_equal(sort(z1$p_vector), sort(z2$p_vector), tolerance=1e-12)
})
