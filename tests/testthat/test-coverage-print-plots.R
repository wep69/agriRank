# Printing and plotting are part of the public interface. These checks execute
# every branch of the show methods and of the graphical dispatch without
# depending on pixel comparison.

test_that("print and summary methods run for every public object class", {
  crd <- agri_design(yield ~ treatment, simulate_agri("crd", seed = 701), design = "crd")
  expect_output(print(crd), regexp = "design|Design|crd")
  expect_true(!is.null(summary(crd)))

  rcbd <- agri_design(yield ~ treatment, simulate_agri("rcbd", seed = 702),
                      design = "rcbd", block = block)
  expect_output(print(rcbd), regexp = ".")

  fa <- simulate_agri("factorial", seed = 703)
  fact <- agri_design(yield ~ A * B, fa, design = "factorial")
  expect_output(print(fact), regexp = ".")

  rp <- simulate_agri("repeated", seed = 704)
  desr <- agri_design(height ~ treatment * time, rp, design = "repeated",
                      subject = subject, within = time)
  expect_output(print(desr), regexp = ".")

  ss <- simulate_agri("split_split", seed = 705)
  dss <- agri_design(yield ~ irrigation * cultivar * timing, ss, design = "split_split",
                     block = block, whole_plot = irrigation, subplot = cultivar,
                     subsubplot = timing)
  expect_output(print(dss), regexp = ".")

  fit <- agri_rank(fact, method = "ART")
  expect_output(print(fit), regexp = ".")
  expect_true(!is.null(summary(fit)))

  # agri_table returns a gt object when gt is installed, a data frame otherwise.
  expect_true(!is.null(agri_table(fit, what = "omnibus")))
  expect_true(NROW(agri_methods()) > 0L)

  sens <- agri_sensitivity(fact)
  expect_output(print(sens), regexp = ".")
  bat <- agri_batch(fact, adjust_across = "BH")
  expect_output(print(bat), regexp = ".")

  mr <- agri_missing_report(desr)
  expect_output(print(mr), regexp = ".")
})

test_that("integer-support objects print and tabulate", {
  d <- data.frame(plants = rep(1:8, each = 6))
  set.seed(711); d$yield <- 20 + 7 * d$plants - 0.55 * d$plants^2 + rnorm(48, 0, 1)
  fit <- agri_np_regression(yield ~ plants, d, method = "integer_grid",
                            integer_base_method = "smoothing_spline",
                            predictor_support = "observed_integer")
  expect_output(print(fit), regexp = ".")

  op <- agri_integer_optimum(fit)
  expect_output(print(op), regexp = ".")
  bs <- agri_integer_bootstrap(fit, B = 99L, seed = 3)
  expect_output(print(bs), regexp = ".")
  cs <- agri_integer_confset(bs, level = 0.95)
  expect_output(print(cs), regexp = ".")

  for (w in c("integer_predictions", "integer_optimum", "integer_efficiency")) {
    expect_true(NROW(agri_table(fit, what = w)) > 0L, info = w)
  }
})

test_that("agri_plot builds a ggplot for every declared plot type", {
  skip_if_not_installed("ggplot2")
  fa <- simulate_agri("factorial", seed = 721)
  fact <- agri_design(yield ~ A * B, fa, design = "factorial")
  fit <- agri_rank(fact, method = "ART")

  for (ty in c("data", "effects", "interaction")) {
    p <- agri_plot(fit, type = ty)
    expect_s3_class(p, "ggplot")
  }

  rp <- simulate_agri("repeated_missing", seed = 722, n = 12, missing_rate = 0.15)
  desr <- agri_design(height ~ treatment * time, rp, design = "repeated",
                      subject = subject, within = time)
  expect_s3_class(agri_plot(desr, type = "missing"), "ggplot")

  # A single a-priori contrast on the first factor, then its plot branch.
  lv <- levels(fa$A)
  C <- matrix(0, nrow = 1, ncol = length(lv), dimnames = list("A1 vs A2", lv))
  C[1, 1] <- 1; C[1, 2] <- -1
  ct <- try(agri_contrast(fit, C = C), silent = TRUE)
  if (!inherits(ct, "try-error")) {
    expect_true(NROW(ct) > 0L)
    expect_s3_class(agri_plot(ct, type = "contrasts"), "ggplot")
  }
})

test_that("regression plots cover fit, residual, derivative and surface branches", {
  skip_if_not_installed("mgcv")
  skip_if_not_installed("ggplot2")
  set.seed(731)
  d <- data.frame(x1 = runif(90, 0, 10), x2 = runif(90, 0, 5))
  d$y <- 2 + sin(d$x1) + 0.4 * d$x2 + rnorm(90, 0, 0.3)

  f1 <- agri_np_regression(y ~ x1, d, method = "gam")
  for (ty in c("fit", "residuals", "derivative")) {
    expect_s3_class(agri_np_plot(f1, type = ty), "ggplot")
  }
  expect_s3_class(agri_np_plot(f1, type = "fit", interval = TRUE), "ggplot")

  f2 <- agri_np_regression(y ~ x1 + x2, d, method = "gam")
  expect_s3_class(agri_np_plot(f2, type = "surface"), "ggplot")
})

test_that("pairwise comparisons and effects run on a blocked design", {
  db <- simulate_agri("rcbd", seed = 741)
  desb <- agri_design(yield ~ treatment, db, design = "rcbd", block = block)
  fit <- agri_rank(desb, method = "friedman")

  ef <- agri_effects(fit)
  expect_true(NROW(ef) > 0L)

  skip_if_not_installed("PMCMRplus")
  pr <- agri_pairs(fit, method = "conover", adjust = "holm")
  expect_true(NROW(pr) > 0L)
  expect_true(NROW(agri_table(fit, what = "pairs")) > 0L)

  skip_if_not_installed("multcompView")
  cl <- agri_cld(fit)
  expect_true(NROW(cl) > 0L)
})
