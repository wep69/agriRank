test_that("split-split requires and records the third randomization stratum", {
  d <- simulate_agri("split_split", seed = 1201, n = 3)
  expect_error(
    agri_design(yield ~ irrigation * cultivar * timing, d, design = "split_split",
                block = block, whole_plot = irrigation, subplot = cultivar),
    "subsubplot"
  )
  des <- agri_design(yield ~ irrigation * cultivar * timing, d, design = "split_split",
                     block = block, whole_plot = irrigation, subplot = cultivar,
                     subsubplot = timing)
  expect_identical(des$subsubplot, "timing")
  expect_match(des$randomization, "sub-subplot")
})

test_that("strip-plot requires two perpendicular strip declarations", {
  d <- simulate_agri("strip_plot", seed = 1202, n = 3)
  expect_error(
    agri_design(yield ~ irrigation * nitrogen, d, design = "strip_plot",
                block = block, strip_a = irrigation),
    "strip_b"
  )
  des <- agri_design(yield ~ irrigation * nitrogen, d, design = "strip_plot",
                     block = block, strip_a = irrigation, strip_b = nitrogen)
  expect_identical(des$strip_a, "irrigation")
  expect_identical(des$strip_b, "nitrogen")
  expect_match(des$randomization, "perpendicular")
})

test_that("split-split and strip-plot ART adapters preserve declared strata", {
  skip_if_not_installed("ARTool")

  ss <- simulate_agri("split_split", seed = 1203, n = 3)
  fss <- np_splitsplit(yield ~ irrigation * cultivar * timing, ss,
                       block, irrigation, cultivar, timing, method = "ART")
  expect_s3_class(fss, "agri_rank_fit")
  expect_true(all(c("(1|.agri_block)", "(1|.agri_wp_unit)", "(1|.agri_sp_unit)") %in%
                    fss$engine$randomization_terms))

  st <- simulate_agri("strip_plot", seed = 1204, n = 3)
  fst <- np_stripplot(yield ~ irrigation * nitrogen, st,
                      block, irrigation, nitrogen, method = "ART")
  expect_s3_class(fst, "agri_rank_fit")
  expect_true(all(c("(1|.agri_block)", "(1|.agri_strip_a_unit)", "(1|.agri_strip_b_unit)") %in%
                    fst$engine$randomization_terms))
})

test_that("permuco adapters are refused for nested field strata", {
  skip_if_not_installed("permuco")

  # split_split: the guard refuses permuco with an explanatory message.
  ss <- simulate_agri("split_split", seed = 1205, n = 3)
  expect_error(
    np_splitsplit(yield ~ irrigation * cultivar * timing, ss,
                  block, irrigation, cultivar, timing,
                  method = "permuco", np = 19, seed = 9),
    regexp = "not admissible"
  )

  # strip_plot: the guard refuses permuco with an explanatory message.
  st <- simulate_agri("strip_plot", seed = 1206, n = 3)
  expect_error(
    np_stripplot(yield ~ irrigation * nitrogen, st,
                 block, irrigation, nitrogen,
                 method = "permuco", np = 19, seed = 9),
    regexp = "not admissible"
  )
})

test_that("direct multi-environment design cannot omit environment", {
  d <- simulate_agri("multienv", seed = 1207, n = 3)
  expect_error(
    agri_design(yield ~ genotype, d, design = "multienv",
                environment = environment, block = block),
    "must also appear"
  )
})

test_that("agri_multienv enforces environment and GxE by default", {
  if (!requireNamespace("ARTool", quietly = TRUE) && !requireNamespace("permuco", quietly = TRUE))
    skip("ARTool or permuco required")
  d <- simulate_agri("multienv", seed = 1208, n = 3)
  z <- agri_multienv(yield ~ genotype, d, environment = environment,
                     block = block, method = "auto")
  expect_true("environment" %in% z$design$predictors)
  expect_true(any(grepl("genotype:environment|environment:genotype", z$design$terms)))
  expect_true(isTRUE(z$environment_enforced))
})

test_that("agri_multivariate returns the common result class", {
  skip_if_not_installed("MANOVA.RM")
  set.seed(1209)
  d <- data.frame(
    treatment = factor(rep(LETTERS[1:3], each = 8)),
    y1 = rnorm(24),
    y2 = rnorm(24)
  )
  z <- agri_multivariate(cbind(y1, y2) ~ treatment, d,
                         resampling = "WildBS", iter = 19, seed = 3)
  expect_s3_class(z, "agri_multivariate_fit")
  expect_identical(z$mode, "MANOVA.wide")
  expect_true(inherits(agri_table(z), "data.frame") || inherits(agri_table(z), "gt_tbl"))
  f <- tempfile(fileext = ".md")
  expect_true(file.exists(agri_report(z, f, format = "md")))
  rr <- tempfile(fileext = ".rds")
  expect_true(file.exists(export_results(z, rr)))
})

test_that("agri_rank refuses silent reduction of a multivariate declaration", {
  d <- data.frame(treatment = factor(rep(LETTERS[1:2], each = 6)),
                  y1 = rnorm(12), y2 = rnorm(12))
  des <- agri_design(cbind(y1, y2) ~ treatment, d, design = "multivariate")
  expect_error(agri_rank(des), "agri_multivariate")
})

test_that("trend and power objects integrate with table/report/export", {
  d <- simulate_agri("crd", seed = 1210)
  d$dose <- rep(1:4, each = nrow(d) / 4)
  des <- agri_design(yield ~ dose, d, design = "crd", quantitative = dose)
  tr <- agri_trend(des, B = 19, seed = 2)
  expect_s3_class(tr, "agri_trend")
  tb <- agri_table(tr)
  expect_true(is.data.frame(tb) || inherits(tb, "gt_tbl"))
  expect_true(file.exists(agri_report(tr, tempfile(fileext = ".md"), format = "md")))

  pw <- agri_power(function(i) simulate_agri("crd", seed = i),
                   function(x) np_crd(yield ~ treatment, x, method = "kruskal"),
                   nsim = 5, seed = 2)
  expect_s3_class(pw, "agri_power")
  expect_true(file.exists(agri_report(pw, tempfile(fileext = ".md"), format = "md")))
})

test_that("unsupported generic confidence intervals fail explicitly", {
  d <- simulate_agri("crd", seed = 1211)
  z <- np_crd(yield ~ treatment, d, method = "kruskal")
  expect_error(confint(z), "not standardized")
})

test_that("multi-environment main-effect-only injection and environment-specific blocks are explicit", {
  skip_if_not_installed("permuco")
  d <- simulate_agri("multienv", seed = 1212, n = 3)
  z <- agri_multienv(yield ~ genotype, d, environment = environment,
                     block = block, method = "auto", environment_interaction = FALSE)
  expect_true("environment" %in% z$design$predictors)
  expect_false(any(grepl("genotype:environment|environment:genotype", z$design$terms)))
  expect_false(isTRUE(z$environment_interaction_requested))
  if (tolower(z$method) == "art") {
    expect_true("(1|.agri_env_block)" %in% z$engine$randomization_terms)
  } else if (tolower(z$method) == "permuco") {
    expect_match(paste(deparse(z$engine$formula), collapse = " "), ".agri_env_block")
  }
})

test_that("multivariate repeated responses route to multRM when MANOVA.RM is available", {
  skip_if_not_installed("MANOVA.RM")
  set.seed(1213)
  d <- expand.grid(subject = factor(seq_len(10)), time = factor(c("T1", "T2")))
  d$treatment <- factor(ifelse(as.integer(d$subject) <= 5, "A", "B"))
  base <- stats::rnorm(10)
  d$y1 <- base[as.integer(d$subject)] + .4 * (d$time == "T2") + stats::rnorm(nrow(d), 0, .2)
  d$y2 <- .5 * base[as.integer(d$subject)] + .6 * (d$treatment == "B") + stats::rnorm(nrow(d), 0, .2)
  z <- agri_multivariate(cbind(y1, y2) ~ treatment, d, subject = subject,
                         within = time, resampling = "WildBS", iter = 19, seed = 8)
  expect_s3_class(z, "agri_multivariate_fit")
  expect_identical(z$mode, "multRM")
  expect_identical(z$within, "time")
  expect_true("time" %in% z$predictors)
  expect_true(any(grepl("treatment:time|time:treatment", z$design$terms)))
})

test_that("factorial backend adapters preserve declared interaction terms", {
  d <- simulate_agri("factorial", seed = 1214, n = 3)
  des <- agri_design(yield ~ A * B, d, design = "factorial")
  if (requireNamespace("rankFD", quietly = TRUE)) {
    z <- agri_rank(des, method = "rankFD")
    expect_match(paste(deparse(z$engine$formula), collapse = " "), "A \\* B|A:B")
  }
  if (requireNamespace("permuco", quietly = TRUE)) {
    z <- agri_rank(des, method = "permuco", np = 19, seed = 11)
    expect_match(paste(deparse(z$engine$formula), collapse = " "), "A:B")
  }
  if (requireNamespace("ARTool", quietly = TRUE)) {
    z <- agri_rank(des, method = "ART")
    expect_match(paste(deparse(z$engine$formula), collapse = " "), "A:B")
  }
})

test_that("nparLD repeated adapter preserves treatment-by-time interaction", {
  skip_if_not_installed("nparLD")
  d <- simulate_agri("repeated", seed = 1215, n = 4)
  des <- agri_design(height ~ treatment * time, d, design = "repeated",
                     subject = subject, within = time)
  z <- agri_rank(des, method = "nparLD")
  expect_match(paste(deparse(z$engine$formula), collapse = " "), "treatment \\* time|treatment:time")
})

test_that("blocked designs reject independent-observation engines", {
  d <- simulate_agri("rcbd", seed = 1216, n = 4)
  des <- agri_design(yield ~ treatment, d, design = "rcbd", block = block)
  expect_error(agri_rank(des, method = "kruskal"), "block is declared")
  if (requireNamespace("rankFD", quietly = TRUE))
    expect_error(agri_rank(des, method = "rankFD"), "block is declared")
})

test_that("batch analysis preserves factorial interaction structure", {
  if (!requireNamespace("ARTool", quietly = TRUE) && !requireNamespace("permuco", quietly = TRUE) && !requireNamespace("rankFD", quietly = TRUE))
    skip("A factorial backend is required")
  d <- simulate_agri("factorial", seed = 1217, n = 3)
  d$biomass <- d$yield + stats::rnorm(nrow(d), 0, .2)
  des <- agri_design(yield ~ A * B, d, design = "factorial")
  bt <- agri_batch(des, responses = c("yield", "biomass"), method = "auto")
  ok <- bt$fits[!vapply(bt$fits, inherits, logical(1), what = "error")]
  expect_gt(length(ok), 0L)
  expect_true(all(vapply(ok, function(z) any(grepl("A:B|B:A", z$design$terms)), logical(1))))
})

test_that("unblocked additive multi-environment models route to permuco", {
  skip_if_not_installed("permuco")
  d <- simulate_agri("multienv", seed = 1218, n = 3)
  z <- agri_multienv(yield ~ genotype, d, environment = environment,
                     environment_interaction = FALSE, method = "auto", np = 19, seed = 12)
  expect_identical(tolower(z$method), "permuco")
  ff <- paste(deparse(z$engine$formula), collapse = " ")
  expect_match(ff, "genotype")
  expect_match(ff, "environment")
  expect_false(grepl("genotype:environment|environment:genotype", ff))
})

test_that("additive multifactor formulas reject interaction-requiring backends", {
  d <- expand.grid(A = factor(c("A1", "A2")), B = factor(c("B1", "B2")), rep = 1:4)
  set.seed(1219); d$y <- stats::rnorm(nrow(d))
  des <- agri_design(y ~ A + B, d, design = "factorial")
  if (requireNamespace("rankFD", quietly = TRUE))
    expect_error(agri_rank(des, method = "rankFD"), "interaction term")
  if (requireNamespace("ARTool", quietly = TRUE))
    expect_error(agri_rank(des, method = "ART"), "interaction-containing")
  if (requireNamespace("permuco", quietly = TRUE)) {
    z <- agri_rank(des, method = "permuco", np = 19, seed = 13)
    ff <- paste(deparse(z$engine$formula), collapse = " ")
    expect_false(grepl("A:B|B:A", ff))
  }
})
