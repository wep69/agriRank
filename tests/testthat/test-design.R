test_that("CRD design is declared and validated", {
  d <- simulate_agri("crd", seed = 1)
  x <- agri_design(yield ~ treatment, d, design = "crd")
  expect_s3_class(x, "agri_design")
  expect_true(x$validation$ok)
  expect_equal(x$predictors, "treatment")
})

test_that("repeated duplicate cells are rejected", {
  d <- simulate_agri("repeated", seed = 1)
  d <- rbind(d, d[1,])
  x <- agri_design(height ~ treatment*time, d, design="repeated", subject=subject, within=time)
  expect_false(x$validation$ok)
})

test_that("reused subject labels across treatment groups are namespaced", {
  d <- simulate_agri("repeated", seed = 11, n = 6)
  # Re-label subjects 1..n independently inside each treatment group.
  d$subject <- ave(seq_len(nrow(d)), d$treatment,
                   FUN = function(i) rep(seq_len(length(i) / length(unique(d$time))),
                                         each = length(unique(d$time))))
  x <- agri_design(height ~ treatment*time, d, design="repeated", subject=subject, within=time)
  expect_true(x$validation$ok)
})

test_that("blocked incomplete repeated measures are rejected by native engine", {
  d <- simulate_agri("repeated_missing", seed = 15, n = 8, missing_rate = .1)
  # Construct a declared block nuisance stratum only to verify the guardrail.
  ids <- unique(d$subject)
  bmap <- setNames(rep(LETTERS[1:4], length.out = length(ids)), ids)
  d$block <- unname(bmap[as.character(d$subject)])
  x <- agri_design(height ~ treatment*time, d, design="repeated",
                   subject=subject, within=time, block=block)
  expect_error(incomplete_wild_rank_test(x, B=99, seed=1, missing_assumption="MCAR"),
               "does not support an RCBD/block")
})
