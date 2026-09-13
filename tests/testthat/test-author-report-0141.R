# Regression tests for every finding of the author report of 0.14.0
# (RELATORIO-AO-AUTOR.md and the technical note 99-nota-tecnica.qmd), fixed in
# 0.14.1.
#
# The defects of that report share one shape: the package never crashed. It
# returned a well-formed object that answered a different question from the one
# that was asked, so the user had no way to notice. Each test below therefore
# states what was silently wrong, because a future change that reintroduces the
# behaviour would pass any test that only checks the return type.

.arb_warnings <- function(expr) {
  acc <- character(0)
  withCallingHandlers(force(expr), warning = function(cnd) {
    acc <<- c(acc, conditionMessage(cnd))
    invokeRestart("muffleWarning")
  })
  acc
}

# The reduced shift is deliberate, as in the report: with a full signal the
# resampled p sits on the floor 1/(B + 1) and a p on the floor does not move with
# anything, which would hide whether B arrived at the engine.
.arb_crd <- function(shift = 0.55, seed = 3031) {
  set.seed(seed)
  d <- data.frame(trat = factor(rep(c("T1", "T2", "T3", "T4"), each = 8)))
  d$y <- 10 + ifelse(d$trat == "T4", shift, 0) + stats::rnorm(nrow(d))
  agri_design(y ~ trat, data = d, design = "crd")
}

.arb_rcbd <- function(seed = 2026) {
  set.seed(seed)
  d <- expand.grid(bloco = factor(paste0("B", 1:5)), dose = seq(0, 280, by = 40))
  d$trat <- factor(d$dose)
  d$yield <- 2.4 + 3.6 * (1 - exp(-0.011 * d$dose)) +
    as.numeric(d$bloco) * 0.12 + stats::rnorm(nrow(d), 0, 0.22)
  d
}

test_that("B reaches the permuco engine and the fit records what ran", {
  skip_if_not_installed("permuco")
  dg <- .arb_crd()
  # The report executed three budgets with one seed and received one p-value,
  # because the adapted backend kept its own default and `B` stopped at
  # agri_rank(). A p-value that cannot move with the replicate count is not the
  # analysis that was requested.
  f999 <- suppressWarnings(agri_rank(dg, method = "permuco", B = 999, seed = 1))
  f2999 <- suppressWarnings(agri_rank(dg, method = "permuco", B = 2999, seed = 1))
  expect_false(identical(f999$omnibus$p_value, f2999$omnibus$p_value))
  # (k + 1)/(B + 1) can never fall below the floor the budget allows
  expect_gte(f999$omnibus$p_value, 1 / 1000)
  expect_identical(f999$resampling, 999)
  expect_true(f999$resampling_used)
  expect_identical(f999$B, 999L)
})

test_that("an explicit engine argument outranks the generic budget and says it did", {
  skip_if_not_installed("permuco")
  dg <- .arb_crd()
  # Passing both must not reach the backend as the same formal twice, which is
  # why the engine argument wins instead of being forwarded alongside `B`.
  w <- .arb_warnings(f <- agri_rank(dg, method = "permuco", B = 999, np = 199, seed = 1))
  expect_true(any(grepl("takes precedence", w)))
  expect_identical(f$resampling, 199)
})

test_that("an engine that cannot use B warns instead of accepting it in silence", {
  dg <- .arb_crd()
  # agri_np_bootstrap(), from the same package, honors the budget it receives.
  # Two sister functions treating the same argument in opposite ways, with
  # nothing in the returned object to tell them apart, was the aggravation the
  # report named.
  w <- .arb_warnings(f <- agri_rank(dg, method = "kruskal", B = 999))
  expect_true(any(grepl("had no effect", w)))
  expect_false(f$resampling_used)
  expect_true(is.na(f$resampling))
  # The default is not a caller's request, so a default call must stay quiet.
  expect_silent(agri_rank(dg, method = "kruskal"))
})

test_that("a resampling budget too small to support its p-value warns", {
  dg <- .arb_crd()
  # The smallest attainable p-value is 1/(B + 1), so B = 199 cannot report
  # 0.001 whatever the data say. A namespace scan found no such warning anywhere
  # in 0.14.0.
  w <- .arb_warnings(agri_rank(dg, method = "kruskal", B = 199))
  expect_true(any(grepl("smallest attainable p-value", w)))
  expect_error(agri_rank(dg, method = "kruskal", B = 0), "positive number of resampling")
  expect_error(agri_rank(dg, method = "kruskal", B = c(10, 20)), "single positive number")
})

test_that("the declared estimand selects the estimator that agri_effects() reports", {
  dg <- .arb_crd(shift = 1.8, seed = 1)
  # All three declarations returned the same table in 0.14.0, so a user who
  # declared a relative-effect analysis received medians without being told.
  fr <- agri_rank(dg, estimand = "relative_effect")
  fd <- agri_rank(dg, estimand = "distribution")
  fl <- agri_rank(dg, estimand = "location_shift")
  expect_true("relative_effect" %in% names(agri_effects(fr)))
  expect_false("relative_effect" %in% names(agri_effects(fd)))
  expect_true("hodges_lehmann" %in% names(agri_effects(fl)))
  expect_false(isTRUE(all.equal(agri_effects(fr), agri_effects(fd))))
  expect_false(isTRUE(all.equal(agri_effects(fr), agri_effects(fl))))
  expect_identical(fr$estimand_source, "agri_effects")
})

test_that("the relative effect is the Brunner-Munzel estimator of the mean rank", {
  dg <- .arb_crd(shift = 1.8, seed = 1)
  # The estimator is checked against its own definition rather than against a
  # stored constant, so it stays valid if the generator changes size.
  eff <- agri_effects(agri_rank(dg, estimand = "relative_effect"))
  y <- dg$data$y
  tr <- dg$data$trat
  rr <- rank(y, ties.method = "average")
  mr <- vapply(levels(tr), function(g) mean(rr[tr == g]), numeric(1))
  ni <- vapply(levels(tr), function(g) sum(tr == g), numeric(1))
  expect_equal(eff$relative_effect, unname((mr - (ni + 1) / 2) / length(y)),
               tolerance = 1e-12)
})

test_that("the location shift is the Hodges-Lehmann shift against the first level", {
  dg <- .arb_crd(shift = 1.8, seed = 1)
  eff <- agri_effects(agri_rank(dg, estimand = "location_shift"))
  ref <- levels(dg$data$trat)[1L]
  expect_identical(unique(eff$reference), ref)
  xr <- dg$data$y[dg$data$trat == ref]
  hl <- vapply(levels(dg$data$trat), function(g) {
    if (identical(g, ref)) return(0)
    stats::median(as.vector(outer(dg$data$y[dg$data$trat == g], xr, "-")))
  }, numeric(1))
  # A location shift is a paired statement, so the reference row is its own zero.
  expect_equal(eff$hodges_lehmann, unname(hl), tolerance = 1e-12)
})

test_that("np_repeated returns a filled omnibus", {
  skip_if_not_installed("nparLD")
  set.seed(4041)
  d <- expand.grid(sujeito = factor(paste0("S", 1:14)),
                   tempo = factor(c("t1", "t2", "t3", "t4")))
  d$trat <- factor(ifelse(as.integer(d$sujeito) <= 7, "controle", "tratado"))
  d$altura <- 12 + 2.1 * as.integer(d$tempo) +
    ifelse(d$trat == "tratado", 1.4 * as.integer(d$tempo), 0) +
    stats::rnorm(nrow(d), 0, 1.5)
  fit <- np_repeated(altura ~ trat * tempo, data = d, subject = "sujeito",
                     within = "tempo", method = "auto")
  # A zero-row table prints exactly like a fit with nothing to report, which is
  # how an adapter that read one version's table name out of two survived a
  # release. The complete result was sitting in fit$engine$raw the whole time.
  expect_gt(nrow(fit$omnibus), 0L)
  expect_true(all(c("effect", "statistic", "df", "p_value") %in% names(fit$omnibus)))
  expect_true(all(is.finite(fit$omnibus$p_value)))
})

test_that("every engine constructor returns a non-empty standardized omnibus", {
  # This defect is of the kind that reappears in another adapter, so the check
  # walks every constructor instead of the one that failed.
  dg <- .arb_crd()
  dr <- .arb_rcbd()
  drc <- agri_design(yield ~ trat, data = dr, design = "rcbd", block = "bloco")
  fits <- list(kruskal = agri_rank(dg, method = "kruskal"),
               friedman = agri_rank(drc, method = "friedman"))
  if (requireNamespace("rankFD", quietly = TRUE))
    fits$rankfd <- agri_rank(dg, method = "rankFD")
  if (requireNamespace("ARTool", quietly = TRUE))
    fits$art <- agri_rank(drc, method = "ART")
  if (requireNamespace("permuco", quietly = TRUE))
    fits$permuco <- suppressWarnings(agri_rank(dg, method = "permuco", B = 999, seed = 1))
  if (requireNamespace("nparLD", quietly = TRUE)) {
    d <- simulate_agri("repeated", seed = 4050, n = 4)
    des <- agri_design(height ~ treatment * time, d, design = "repeated",
                       subject = subject, within = time)
    fits$nparLD <- agri_rank(des, method = "nparLD")
  }
  expect_gte(length(fits), 4L)
  for (nm in names(fits)) {
    tab <- fits[[nm]]$omnibus
    expect_true(all(c("effect", "statistic", "df", "p_value") %in% names(tab)), info = nm)
    expect_gt(nrow(tab), 0L)
    expect_true(all(tab$p_value >= 0 & tab$p_value <= 1), info = nm)
    expect_false(any(is.na(tab$effect)), info = nm)
  }
})

test_that("agri_sensitivity refuses vocabulary that is not part of the method list", {
  drc <- agri_design(yield ~ trat, data = .arb_rcbd(), design = "rcbd", block = "bloco")
  fit <- agri_rank(drc, method = "friedman")
  # Accepting "xxx" and returning an empty table invites the reader to conclude
  # that the engines agree when none of them ran.
  expect_error(agri_sensitivity(fit, methods = "xxx", seed = 1), "permuco")
  # The vocabulary is accepted in any case, because the names are typed by hand.
  s <- suppressWarnings(agri_sensitivity(fit, methods = "art", seed = 1))
  expect_s3_class(s, "agri_sensitivity")
  expect_true("ART" %in% s$table$method)
})

test_that("agri_pairs keeps the effect sizes on the paired path", {
  drc <- agri_design(yield ~ trat, data = .arb_rcbd(), design = "rcbd", block = "bloco")
  fit <- agri_rank(drc, method = "friedman")
  pr <- agri_pairs(fit, method = "wilcoxon")
  # The paired path dropped A, cliff_delta and hodges_lehmann, so the two routes
  # of the same function answered with different columns.
  expect_true(all(c("A", "cliff_delta", "hodges_lehmann") %in% names(pr)))
  expect_false(anyNA(pr$A))
  expect_false(anyNA(pr$cliff_delta))
  # The package's own convention: Cliff's delta is the rescaled concordance.
  expect_equal(pr$cliff_delta, 2 * pr$A - 1, tolerance = 1e-12)
  expect_true(all(pr$A >= 0 & pr$A <= 1))
})

test_that("worth = TRUE either fits the companion model or says why it could not", {
  set.seed(7)
  d <- expand.grid(bloco = factor(paste0("B", 1:5)), trat = factor(paste0("T", 1:5)))
  d$yield <- as.numeric(d$trat) + stats::rnorm(nrow(d), 0, 0.2)
  if (requireNamespace("PlackettLuce", quietly = TRUE)) {
    # The matrix entry point became as.rankings() and the older rankings()
    # gained a mandatory `id`, so the fit failed inside the helper, the error was
    # swallowed into NULL, and the user saw a null component with the package
    # installed and working.
    rk <- agri_rankings(yield ~ trat, data = d, block = "bloco",
                        direction = "high", worth = TRUE)
    expect_false(is.null(rk$worth))
    expect_true(all(c("item", "worth") %in% names(rk$worth)))
    expect_equal(sum(rk$worth$worth), 1, tolerance = 1e-8)
  } else {
    w <- .arb_warnings(rk <- agri_rankings(yield ~ trat, data = d, block = "bloco",
                                           direction = "high", worth = TRUE))
    expect_true(any(grepl("PlackettLuce", w)))
    expect_null(rk$worth)
  }
})

test_that("the canonical p_value is the resampled one and agri_p() reads both", {
  skip_if_not_installed("permuco")
  dg <- .arb_crd(shift = 1.8, seed = 1)
  fp <- suppressWarnings(agri_rank(dg, method = "permuco", B = 999, seed = 1))
  # permuco reports two p-values and names neither of them p_value, so generic
  # code received NULL from exactly the engine that resamples.
  expect_true(all(c("resampled P(>F)", "parametric P(>F)") %in% names(fp$omnibus)))
  expect_equal(fp$omnibus$p_value, fp$omnibus[["resampled P(>F)"]])
  # The Residuals row is an error stratum, not a test, and it stays in the raw
  # backend object, where a reader looking for the ANOVA layout will go.
  expect_false(any(grepl("residual", fp$omnibus$effect, ignore.case = TRUE)))
  expect_true(any(grepl("residual", rownames(fp$engine$raw$table), ignore.case = TRUE)))
  expect_equal(agri_p(fp)$p_value, fp$omnibus$p_value)
  expect_equal(suppressWarnings(agri_p(fp, which = "parametric"))$p_value,
               fp$omnibus[["parametric P(>F)"]])
})

test_that("a single-p explanation is given when a backend separates no p-values", {
  dg <- .arb_crd(shift = 1.8, seed = 1)
  fit <- agri_rank(dg, method = "kruskal")
  expect_equal(agri_p(fit)$p_value, fit$omnibus$p_value)
  w <- .arb_warnings(pp <- agri_p(fit, which = "parametric"))
  expect_true(any(grepl("single p-value", w)))
  expect_equal(pp$p_value, fit$omnibus$p_value)
})

test_that("agri_ancova names the permutation count and refuses a switch-like np", {
  skip_if_not_installed("permuco")
  d <- .arb_rcbd()
  d$stand <- 40 + stats::rnorm(nrow(d), 0, 4)
  d$yield <- d$yield + 0.03 * d$stand
  # `np` reads as a switch in a nonparametric package while being a count, and
  # the two ways the name invites a user to write it failed with errors raised
  # inside stats, which name the symptom and not the mistake.
  expect_error(suppressWarnings(agri_ancova(yield ~ trat, data = d, covariates = "stand",
                                           np = TRUE, seed = 1)),
               "positive number of permutations")
  expect_error(suppressWarnings(agri_ancova(yield ~ trat, data = d, covariates = "stand",
                                           np = FALSE, seed = 1)),
               "positive number of permutations")
  w <- .arb_warnings(a <- agri_ancova(yield ~ trat, data = d, covariates = "stand",
                                      np = 19, seed = 1))
  expect_true(any(grepl("renamed to `nperm`", w)))
  expect_identical(a$nperm, 19L)
  # The ANCOVA omnibus now answers to the same canonical names as agri_rank().
  expect_true(all(c("effect", "statistic", "df", "p_value") %in% names(a$omnibus)))
  expect_true(all(is.finite(a$omnibus$p_value)))
})

test_that("agri_cld declares the comparison route it forwards", {
  drc <- agri_design(yield ~ trat, data = .arb_rcbd(), design = "rcbd", block = "bloco")
  fit <- agri_rank(drc, method = "friedman")
  # The argument reached a function through `...` while deciding every letter, so
  # it did not appear in the signature and a typo was silently ignored.
  expect_true("method" %in% names(formals(agri_cld)))
  expect_error(agri_cld(fit, method = "xxx"), "wilcoxon")
  cld <- agri_cld(fit, method = "wilcoxon", alpha = 0.05)
  expect_true(is.data.frame(cld))
  expect_true(all(c("group", "letter") %in% names(cld)))
  expect_gt(nrow(cld), 0L)
})

test_that("agri_trend accepts unnamed scores in levels() order", {
  drc <- agri_design(yield ~ trat, data = .arb_rcbd(), design = "rcbd", block = "bloco")
  lev <- levels(drc$data$trat)
  # Scores were matched by name only, so the natural call failed inside
  # stats::cor with a message about pairs and complete observations, which
  # points nowhere near the cause.
  tr <- agri_trend(drc, treatment = "trat", scores = as.numeric(lev), B = 199, seed = 1)
  expect_s3_class(tr, "agri_trend")
  expect_true(is.finite(tr$p_value))
  # A named vector must survive the conversion to numeric, which drops names.
  # Losing them sent a correctly named `scores` down the unnamed branch and
  # refused it, and the two spellings of the same scale must agree exactly.
  sc <- stats::setNames(as.numeric(lev), lev)
  trn <- agri_trend(drc, treatment = "trat", scores = sc, B = 199, seed = 1)
  expect_s3_class(trn, "agri_trend")
  expect_equal(trn$statistic, tr$statistic, tolerance = 1e-12)
  expect_error(agri_trend(drc, treatment = "trat", scores = c(1, 2), B = 199),
               "one value per level")
  expect_error(agri_trend(drc, treatment = "trat", scores = c(a = 1, b = 2), B = 199),
               "no value for every level")
})
