# Defensive guards outside the regression module: design validation, engines,
# routing, effects and contrasts, repeated measures, reports and utilities.

test_that("class contracts of the public accessors are enforced", {
  notadesign <- list(a = 1)
  notafit <- structure(list(a = 1), class = "not_agriRank")

  expect_error(validate_agri_design(notadesign), regexp = "agri_design")
  expect_error(design_summary(notadesign), regexp = "agri_design")
  expect_error(agri_effects(notafit), regexp = "agri_rank_fit")
  expect_error(agri_pairs(notafit), regexp = "agri_rank_fit")
  expect_error(agri_conover(notafit), regexp = "agri_rank_fit")
  expect_error(agri_contrast(notafit, C = matrix(1)), regexp = "agri_rank_fit")
  expect_error(agri_sensitivity(notafit), regexp = "agri_design|agri_rank_fit")
  expect_error(agri_batch(notadesign), regexp = "agri_design")
  expect_error(agri_repeated(notadesign), regexp = "agri_design|repeated")
  expect_error(agri_missing_sensitivity(notadesign), regexp = "agri_design|repeated")
  expect_error(incomplete_wild_rank_test(notadesign), regexp = "agri_design")
  expect_error(agri_plot(notadesign), regexp = "agri_design|agri_rank_fit")
  expect_error(agri_report(notafit), regexp = "Unsupported")
  expect_error(export_results(notafit), regexp = "Unsupported")
})

test_that("variable capture rejects specifications that are not names", {
  fa <- simulate_agri("factorial", seed = 921)
  expect_error(agri_design(yield ~ A * B, fa, design = "rcbd", block = 1 + 1),
               regexp = "bare names|character")
  me <- simulate_agri("multienv", seed = 9211)
  expect_error(agri_design(yield ~ genotype, me, design = "multienv", block = block),
               regexp = "environment")
})

test_that("classical engines state their structural requirements", {
  fa <- simulate_agri("factorial", seed = 922)
  desf <- agri_design(yield ~ A * B, fa, design = "factorial")
  expect_error(agri_rank(desf, method = "kruskal"), regexp = "one treatment factor")

  db <- simulate_agri("rcbd", seed = 923)
  # Replicated block-by-treatment cells break the classical Friedman assumption.
  dbl <- rbind(db, db)
  desd <- agri_design(yield ~ treatment, dbl, design = "rcbd", block = block)
  expect_error(agri_rank(desd, method = "friedman"), regexp = "exactly one observation")

  expect_error(agri_rank(agri_design(yield ~ treatment, db, design = "rcbd", block = block),
                         method = "no_such_engine"),
               regexp = "method|engine|nknown")
})

test_that("contrast and comparison adapters validate their arguments", {
  skip_if_not_installed("PMCMRplus")
  set.seed(924)
  d <- expand.grid(block = factor(1:5), cultivar = factor(c("C1", "C2", "C3")),
                   salinity = factor(c("S1", "S2")))
  d$biomass <- 20 + as.numeric(d$cultivar) + rnorm(nrow(d))
  fit <- agri_rank(agri_design(biomass ~ cultivar * salinity, d, design = "factorial"),
                   method = "ART")

  expect_error(agri_conover(fit, by = "cultivar", factor = "nope"),
               regexp = "Unknown variable")
  expect_error(agri_conover(fit, by = c("cultivar", "salinity")),
               regexp = "No treatment factor remains")
  expect_error(agri_contrast(fit, C = matrix(1, nrow = 1, ncol = 99)),
               regexp = "contrast|column|cell")
})

test_that("the native wild engine refuses designs it cannot support", {
  fa <- simulate_agri("factorial", seed = 925)
  desf <- agri_design(yield ~ A * B, fa, design = "factorial")
  expect_error(incomplete_wild_rank_test(desf), regexp = "repeated|longitudinal")

  rp <- simulate_agri("repeated_missing", seed = 926, n = 12, missing_rate = 0.6)
  desr <- agri_design(height ~ treatment * time, rp, design = "repeated",
                      subject = subject, within = time)
  # With very heavy loss some cell will be too sparse; either it errors with the
  # documented message or it succeeds, both are acceptable, silence is not.
  res <- tryCatch(suppressWarnings(incomplete_wild_rank_test(desr, B = 99L, seed = 1)),
                  error = function(e) conditionMessage(e))
  expect_true(inherits(res, "agri_incomplete_wild") ||
                grepl("observed|cell|covariance|Too few", res))
})

test_that("repeated-measures routing refuses unvalidated combinations", {
  rp <- simulate_agri("repeated_missing", seed = 927, n = 16, missing_rate = 0.15)
  rp$blk <- factor(rep(1:2, length.out = nrow(rp)))
  desb <- agri_design(height ~ treatment * time, rp, design = "repeated",
                      subject = subject, within = time, block = blk)
  expect_error(suppressWarnings(agri_repeated(desb, backend = "native_wild")),
               regexp = "block")

  # permuco is refused as an all-available method for INCOMPLETE repeated data.
  rpi <- simulate_agri("repeated_missing", seed = 928, n = 14, missing_rate = 0.2)
  desi <- agri_design(height ~ treatment * time, rpi, design = "repeated",
                      subject = subject, within = time)
  expect_error(suppressWarnings(agri_repeated(desi, backend = "permuco")),
               regexp = "permuco|incomplete|all-available")
})

test_that("multivariate guards cover missing values, factors and subject", {
  skip_if_not_installed("MANOVA.RM")
  set.seed(929); n <- 30
  d <- data.frame(subject = factor(seq_len(n)),
                  treatment = factor(rep(c("a", "b"), each = n / 2)))
  d$y1 <- rnorm(n); d$y2 <- rnorm(n)

  dna <- d; dna$y1[3] <- NA
  expect_error(agri_multivariate(cbind(y1, y2) ~ treatment, dna),
               regexp = "complete values")

  dt <- do.call(rbind, lapply(1:2, function(tt) { z <- d; z$time <- factor(tt); z }))
  expect_error(agri_multivariate(cbind(y1, y2) ~ treatment, dt, within = time),
               regexp = "subject")
})

test_that("plot guards state what a plot type requires", {
  skip_if_not_installed("ggplot2")
  crd <- simulate_agri("crd", seed = 930)
  des1 <- agri_design(yield ~ treatment, crd, design = "crd")
  expect_error(agri_plot(des1, type = "interaction"), regexp = "two factors")

  fit <- agri_rank(des1, method = "kruskal")
  expect_error(agri_plot(fit, type = "contrasts"), regexp = "interval contrasts|contrast")
})

test_that("power and trend helpers validate their inputs", {
  expect_error(agri_power(generator = "not a function", analyzer = function(x) x),
               regexp = "functions")
  crd <- simulate_agri("crd", seed = 931)
  expect_error(agri_trend(crd), regexp = "agri_design")
  des <- agri_design(yield ~ treatment, crd, design = "crd")
  tr <- suppressWarnings(agri_trend(des, B = 99, seed = 2))
  expect_true(NROW(tr) > 0L)
})

test_that("auxiliary report and missing-data helpers reject wrong input", {
  crd <- simulate_agri("crd", seed = 932)
  des <- agri_design(yield ~ treatment, crd, design = "crd")
  expect_error(agri_missing_report(des, response = "no_such_column"),
               regexp = "response|no_such_column")
})
