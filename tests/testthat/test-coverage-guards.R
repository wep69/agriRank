# Defensive guards are scientific rules, not implementation details. Each check
# below documents a rule the package refuses to break silently.

test_that("agri_design refuses incomplete design declarations", {
  fa <- simulate_agri("factorial", seed = 601)
  sp <- simulate_agri("split_plot", seed = 602)
  ss <- simulate_agri("split_split", seed = 603)
  st <- simulate_agri("strip_plot", seed = 604)
  rp <- simulate_agri("repeated", seed = 605)
  me <- simulate_agri("multienv", seed = 606)

  expect_error(agri_design(yield ~ A * B, fa, design = "rcbd"), regexp = "block")
  expect_error(agri_design(yield ~ nonexistent, fa, design = "crd"), regexp = "nonexistent")
  expect_error(agri_design(yield ~ A * B, fa, design = "rcbd", block = missing_block),
               regexp = "missing_block")

  expect_error(agri_design(yield ~ irrigation * cultivar, sp, design = "split_plot",
                           block = block, whole_plot = irrigation),
               regexp = "subplot")
  expect_error(agri_design(yield ~ irrigation * cultivar, sp, design = "split_plot",
                           block = block, subplot = cultivar),
               regexp = "whole")

  expect_error(agri_design(yield ~ irrigation * cultivar * timing, ss,
                           design = "split_split", block = block,
                           whole_plot = irrigation, subplot = cultivar),
               regexp = "subsubplot")

  expect_error(agri_design(yield ~ irrigation * nitrogen, st, design = "strip_plot",
                           block = block, strip_a = irrigation),
               regexp = "strip")

  expect_error(agri_design(height ~ treatment * time, rp, design = "repeated",
                           within = time),
               regexp = "subject")
  expect_error(agri_design(height ~ treatment * time, rp, design = "repeated",
                           subject = subject),
               regexp = "within")

  expect_error(agri_design(yield ~ genotype, me, design = "multienv",
                           environment = environment, block = block),
               regexp = "environment")
})

test_that("agri_design accepts every supported design and reports itself", {
  specs <- list(
    crd         = agri_design(yield ~ treatment, simulate_agri("crd", seed = 611), design = "crd"),
    rcbd        = agri_design(yield ~ treatment, simulate_agri("rcbd", seed = 612),
                              design = "rcbd", block = block),
    factorial   = agri_design(yield ~ A * B, simulate_agri("factorial", seed = 613),
                              design = "factorial")
  )
  for (nm in names(specs)) {
    d <- specs[[nm]]
    expect_s3_class(d, "agri_design")
    expect_output(print(d), regexp = ".", info = nm)
    expect_true(is.data.frame(design_summary(d)) || is.list(design_summary(d)))
    expect_silent(validate_agri_design(d, error = FALSE))
  }
})

test_that("agri_rank refuses engines that would discard the randomization structure", {
  db <- simulate_agri("rcbd", seed = 621)
  desb <- agri_design(yield ~ treatment, db, design = "rcbd", block = block)
  expect_error(agri_rank(desb, method = "kruskal"), regexp = "block")
  expect_error(agri_rank(desb, method = "rankFD"), regexp = "block")

  fa <- simulate_agri("factorial", seed = 622)
  add <- agri_design(yield ~ A + B, fa, design = "factorial")
  expect_error(agri_rank(add, method = "rankFD"), regexp = "interaction")
  expect_error(agri_rank(add, method = "ART"), regexp = "interaction")

  expect_error(agri_rank(desb, method = "engine_that_does_not_exist"),
               regexp = "method|engine|unknown|Unknown")
  expect_error(agri_rank(db), regexp = "agri_design")
})

test_that("repeated-measures wrappers require the subject structure", {
  rp <- simulate_agri("repeated", seed = 631)
  expect_error(np_repeated(height ~ treatment * time, rp, within = time),
               regexp = "subject")
  fit <- np_repeated(height ~ treatment * time, rp, subject = subject, within = time)
  expect_s3_class(fit, "agri_rank_fit")
  expect_output(print(fit), regexp = ".")
})

test_that("integer-support declarations are validated against the observed data", {
  d <- data.frame(plants = rep(1:8, each = 6))
  set.seed(641); d$yield <- 20 + 7 * d$plants - 0.55 * d$plants^2 + rnorm(48, 0, 1)

  expect_error(
    agri_np_regression(yield ~ plants, d, method = "integer_grid",
                       integer_base_method = "smoothing_spline",
                       predictor_support = "custom_integer",
                       integer_values = c(2, 4, 6)),
    regexp = "support"
  )
  d2 <- d; d2$plants <- d2$plants + 0.5
  expect_error(
    agri_np_regression(yield ~ plants, d2, method = "unimodal_isotonic",
                       predictor_support = "observed_integer"),
    regexp = "integer"
  )
  fit <- agri_np_regression(yield ~ plants, d, method = "integer_grid",
                            integer_base_method = "smoothing_spline",
                            predictor_support = "observed_integer")
  expect_error(agri_integer_predict(fit, support = 2.5), regexp = "integer|support")
  expect_error(agri_integer_predict(fit, support = 42L), regexp = "support")
})

test_that("multivariate and multi-environment wrappers validate their arguments", {
  me <- simulate_agri("multienv", seed = 651)
  expect_error(agri_multienv(yield ~ genotype, me, block = block), regexp = "environment")

  set.seed(652)
  mv <- data.frame(subject = factor(1:30),
                   treatment = factor(rep(c("a", "b"), each = 15)))
  mv$y1 <- rnorm(30); mv$y2 <- rnorm(30)
  expect_error(agri_multivariate(y1 ~ treatment, mv), regexp = "response|multivariate|subject")
})
