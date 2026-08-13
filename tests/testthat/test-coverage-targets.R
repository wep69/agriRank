# Alternative argument paths that the main suite never reaches: the remaining
# integer decision criteria, stratified pairwise comparisons, the optional
# plotting arguments, every report format, and the alternative repeated and
# multivariate routes.

int_fit <- function(seed = 801) {
  d <- data.frame(plants = rep(1:8, each = 6))
  set.seed(seed)
  d$yield <- 20 + 7 * d$plants - 0.55 * d$plants^2 + rnorm(48, 0, 1)
  agri_np_regression(yield ~ plants, d, method = "integer_grid",
                     integer_base_method = "smoothing_spline",
                     predictor_support = "observed_integer")
}

test_that("all three integer decision criteria return admissible decisions", {
  fit <- int_fit()
  sup <- fit$integer_support

  a <- agri_integer_threshold(fit, criterion = "fraction_of_maximum", value = 0.95)
  b <- agri_integer_threshold(fit, criterion = "gain_from_baseline", value = 0.90,
                              baseline = min(sup))
  cc <- agri_integer_threshold(fit, criterion = "marginal_gain", value = 1.0)

  for (nm in c("a", "b", "cc")) {
    z <- as.data.frame(get(nm))
    expect_true(NROW(z) > 0L, info = nm)
    expect_true(all(z$integer_value %in% sup), info = nm)
    expect_true(all(is.finite(z$fitted_response)), info = nm)
  }
  # A stricter fraction cannot select a smaller decision than a looser one.
  loose <- agri_integer_threshold(fit, criterion = "fraction_of_maximum", value = 0.80)
  expect_true(min(loose$integer_value) <= min(a$integer_value))

  expect_true(NROW(agri_integer_efficiency(fit)) > 0L)
  expect_true(NROW(agri_integer_difference(fit, order = 2L)) > 0L)
})

test_that("pairwise comparisons run within strata and for a chosen factor", {
  skip_if_not_installed("PMCMRplus")
  set.seed(811)
  d <- expand.grid(block = factor(1:5), cultivar = factor(c("C1", "C2", "C3")),
                   salinity = factor(c("S1", "S2")))
  d$biomass <- 20 + as.numeric(d$cultivar) - 2 * as.numeric(d$salinity) + rnorm(nrow(d))
  des <- agri_design(biomass ~ cultivar * salinity, d, design = "factorial")
  fit <- agri_rank(des, method = "ART")

  # Simple effects of cultivar within each salinity level.
  pc <- agri_conover(fit, by = "salinity", factor = "cultivar")
  expect_true(NROW(pc) > 0L)
  expect_true(all(c("group1", "group2") %in% names(as.data.frame(pc))))
  expect_true(length(unique(as.data.frame(pc)$stratum)) >= 2L)

  pw <- agri_pairs(fit, by = "salinity", factor = "cultivar",
                   method = "conover", adjust = "BH")
  expect_true(NROW(pw) > 0L)

  pu <- agri_pairs(fit, factor = "cultivar", method = "wilcoxon", adjust = "holm")
  expect_true(NROW(pu) > 0L)

  # Effects with resampled confidence limits exercise the bootstrap path.
  ef <- agri_effects(fit, ci = TRUE, level = 0.95, B = 99, seed = 4)
  expect_true(NROW(ef) > 0L)
  expect_true(NROW(agri_effects(fit, ci = FALSE)) == NROW(ef))
})

test_that("regression plots accept group, fixed and surface_predictors", {
  skip_if_not_installed("mgcv")
  skip_if_not_installed("ggplot2")
  set.seed(821)
  d <- data.frame(x1 = runif(120, 0, 10), x2 = runif(120, 0, 5),
                  g = factor(rep(c("a", "b"), 60)))
  d$y <- 2 + sin(d$x1) + 0.4 * d$x2 + as.numeric(d$g) + rnorm(120, 0, 0.3)

  f <- agri_np_regression(y ~ x1 + x2 + g, d, method = "gam")

  expect_s3_class(agri_np_plot(f, type = "fit", predictor = "x1",
                               fixed = list(x2 = 2.5, g = "a")), "ggplot")
  expect_s3_class(agri_np_plot(f, type = "fit", predictor = "x1", group = "g"), "ggplot")
  expect_s3_class(agri_np_plot(f, type = "fit", predictor = "x1", n = 50L,
                               interval = TRUE, fixed = list(x2 = 2.5, g = "a")), "ggplot")
  expect_s3_class(agri_np_plot(f, type = "surface",
                               surface_predictors = c("x1", "x2"),
                               fixed = list(g = "a")), "ggplot")
  expect_s3_class(agri_np_plot(f, type = "derivative", predictor = "x1",
                               fixed = list(x2 = 2.5, g = "a")), "ggplot")

  pr <- agri_np_predict(f, newdata = data.frame(x1 = 5, x2 = 2.5, g = factor("a", levels = levels(d$g))))
  expect_true(all(is.finite(as.numeric(unlist(pr[vapply(as.data.frame(pr), is.numeric, logical(1))])))))
})

test_that("agri_report writes every supported format and export_results every object", {
  fa <- simulate_agri("factorial", seed = 831)
  des <- agri_design(yield ~ A * B, fa, design = "factorial")
  fit <- agri_rank(des, method = "ART")

  for (fmt in c("md", "qmd")) {
    f <- agri_report(fit, tempfile(fileext = paste0(".", fmt)), format = fmt)
    expect_true(file.exists(f))
    expect_true(file.size(f) > 0)
  }
  f_pt <- agri_report(fit, tempfile(fileext = ".md"), format = "md", language = "pt")
  expect_true(file.exists(f_pt))

  if (requireNamespace("rmarkdown", quietly = TRUE) &&
      rmarkdown::pandoc_available()) {
    fh <- try(agri_report(fit, tempfile(fileext = ".html"), format = "html"), silent = TRUE)
    if (!inherits(fh, "try-error")) expect_true(file.exists(fh))
  }

  # Every exportable domain: fit, batch, sensitivity, missing report.
  rp <- simulate_agri("repeated_missing", seed = 833, n = 12, missing_rate = 0.15)
  desr <- agri_design(height ~ treatment * time, rp, design = "repeated",
                      subject = subject, within = time)
  objs <- list(fit = fit,
               batch = agri_batch(des, adjust_across = "BH"),
               sensitivity = agri_sensitivity(des),
               missing = agri_missing_report(desr))
  for (nm in names(objs)) {
    p <- tempfile(fileext = ".rds")
    export_results(objs[[nm]], p)
    expect_true(file.exists(p), info = nm)
    expect_true(!is.null(readRDS(p)), info = nm)
    expect_true(file.exists(agri_report(objs[[nm]], tempfile(fileext = ".md"))), info = nm)
  }
  expect_error(export_results(des, tempfile(fileext = ".rds")), regexp = "Unsupported")
  expect_error(agri_report(des, tempfile(fileext = ".md")), regexp = "Unsupported")

  d <- data.frame(plants = rep(1:8, each = 6))
  set.seed(832); d$yield <- 20 + 7 * d$plants - 0.55 * d$plants^2 + rnorm(48, 0, 1)
  reg <- agri_np_regression(yield ~ plants, d, method = "integer_grid",
                            integer_base_method = "smoothing_spline",
                            predictor_support = "observed_integer")
  p <- tempfile(fileext = ".rds"); export_results(reg, p)
  expect_true(file.exists(p))
  expect_true(file.exists(agri_report(reg, tempfile(fileext = ".md"))))
})

test_that("agri_repeated routes to each available backend", {
  rp <- simulate_agri("repeated", seed = 841)
  des <- agri_design(height ~ treatment * time, rp, design = "repeated",
                     subject = subject, within = time)

  backends <- c("auto", "nparLD", "MANOVA.RM", "native_wild")
  for (b in backends) {
    if (b == "nparLD" && !requireNamespace("nparLD", quietly = TRUE)) next
    if (b == "MANOVA.RM" && !requireNamespace("MANOVA.RM", quietly = TRUE)) next
    fit <- suppressWarnings(
      agri_repeated(des, backend = b, B = 199, iter = 199, seed = 3,
                    missing_assumption = "MCAR")
    )
    expect_s3_class(fit, c("agri_rank_fit", "agri_engine_fit"), exact = FALSE)
    expect_output(print(fit), regexp = ".", info = b)
  }
})

test_that("agri_multivariate covers the wide, long and repeated routes with summaries", {
  skip_if_not_installed("MANOVA.RM")
  set.seed(851); n <- 36
  wide <- data.frame(subject = factor(seq_len(n)),
                     treatment = factor(rep(c("a", "b", "c"), each = n / 3)))
  wide$y1 <- rnorm(n, as.numeric(wide$treatment), 1.5)
  wide$y2 <- rnorm(n, 0.5 * as.numeric(wide$treatment), 1.2)

  m1 <- suppressWarnings(agri_multivariate(cbind(y1, y2) ~ treatment, wide, iter = 199, seed = 2))
  expect_s3_class(m1, "agri_multivariate_fit")
  expect_output(print(m1), regexp = ".")
  expect_true(!is.null(summary(m1)))

  lng <- data.frame(subject = factor(rep(seq_len(n), 2)),
                    treatment = factor(rep(wide$treatment, 2)),
                    y = c(wide$y1, wide$y2))
  m2 <- suppressWarnings(agri_multivariate(y ~ treatment, lng, subject = subject,
                                           iter = 199, seed = 2))
  expect_s3_class(m2, "agri_multivariate_fit")
  expect_output(print(m2), regexp = ".")

  rmv <- do.call(rbind, lapply(1:3, function(tt) {
    z <- wide; z$time <- factor(tt); z$y1 <- z$y1 + tt; z$y2 <- z$y2 + 0.5 * tt; z
  }))
  m3 <- suppressWarnings(agri_multivariate(cbind(y1, y2) ~ treatment, rmv,
                                           subject = subject, within = time,
                                           iter = 199, seed = 2))
  expect_s3_class(m3, "agri_multivariate_fit")
  expect_true(!is.null(agri_table(m3)))
  expect_true(file.exists(agri_report(m3, tempfile(fileext = ".md"))))
})
