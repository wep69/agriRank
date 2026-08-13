# Compact letter displays derived from Conover comparisons. Letters must agree
# with the adjusted p-values they summarize, and must never merge treatments
# that belong to different simple-effect strata.

skip_if_no_cld <- function() {
  skip_if_not_installed("PMCMRplus")
  skip_if_not_installed("multcompView")
}

test_that("letters can be attached to a Conover table or derived from it", {
  skip_if_no_cld()
  set.seed(951)
  d <- data.frame(treatment = factor(rep(LETTERS[1:4], each = 8)),
                  yield = c(rgamma(8, 5, 1), rgamma(8, 6, 1),
                            rgamma(8, 7, 1), rgamma(8, 9, 1)))
  fit <- np_crd(yield ~ treatment, d, method = "kruskal")

  cv <- agri_conover(fit, adjust = "holm")
  a <- agri_cld(cv)
  b <- attr(agri_conover(fit, adjust = "holm", cld = TRUE), "cld")

  expect_true(is.data.frame(a))
  expect_identical(a, b)
  expect_setequal(a$group, levels(d$treatment))
  expect_true(all(nzchar(a$letter)))
  expect_false("stratum" %in% names(a))
  expect_null(attr(agri_conover(fit, adjust = "holm"), "cld"))
})

test_that("letters agree with the adjusted p-values they summarize", {
  skip_if_no_cld()
  set.seed(952)
  d <- data.frame(treatment = factor(rep(LETTERS[1:4], each = 10)))
  d$yield <- c(rnorm(10, 10), rnorm(10, 10.2), rnorm(10, 16), rnorm(10, 16.3))
  fit <- np_crd(yield ~ treatment, d, method = "kruskal")
  cv <- agri_conover(fit, adjust = "holm")
  cld <- agri_cld(cv, alpha = 0.05)

  share <- function(g1, g2) {
    l1 <- strsplit(cld$letter[cld$group == g1], "")[[1]]
    l2 <- strsplit(cld$letter[cld$group == g2], "")[[1]]
    length(intersect(l1, l2)) > 0L
  }
  for (i in seq_len(nrow(cv))) {
    p <- cv$p_adjusted[i]
    if (!is.finite(p)) next
    # Two groups share a letter if and only if they were not separated.
    expect_equal(share(cv$group1[i], cv$group2[i]), p > 0.05,
                 info = paste(cv$group1[i], cv$group2[i], signif(p, 3)))
  }
})

test_that("a stricter alpha never separates more than a looser one", {
  skip_if_no_cld()
  set.seed(953)
  d <- data.frame(treatment = factor(rep(LETTERS[1:4], each = 10)))
  d$yield <- c(rnorm(10, 10), rnorm(10, 11.5), rnorm(10, 13), rnorm(10, 14.5))
  cv <- agri_conover(np_crd(yield ~ treatment, d, method = "kruskal"), adjust = "holm")
  n_letters <- function(a) length(unique(unlist(strsplit(agri_cld(cv, alpha = a)$letter, ""))))
  expect_true(n_letters(0.01) <= n_letters(0.10))
})

test_that("letters are computed within each simple-effect stratum", {
  skip_if_no_cld()
  skip_if_not_installed("ARTool")
  set.seed(954)
  d <- expand.grid(cultivar = factor(c("C1", "C2", "C3")),
                   salinity = factor(c("S1", "S2")), rep = 1:6)
  d$biomass <- 20 + 3 * as.numeric(d$cultivar) - 2 * as.numeric(d$salinity) +
    rnorm(nrow(d), 0, 0.8)
  fit <- agri_rank(agri_design(biomass ~ cultivar * salinity, d, design = "factorial"),
                   method = "ART")

  cv <- agri_conover(fit, by = "salinity", factor = "cultivar", cld = TRUE)
  cld <- attr(cv, "cld")

  expect_true("stratum" %in% names(cld))
  expect_setequal(unique(cld$stratum), levels(d$salinity))
  # Every cultivar receives a letter inside every salinity stratum.
  for (st in levels(d$salinity)) {
    expect_setequal(cld$group[cld$stratum == st], levels(d$cultivar))
  }
  expect_identical(cld, agri_cld(cv))
  expect_identical(cld, agri_cld(fit, method = "conover", by = "salinity",
                                 factor = "cultivar"))
})

test_that("blocked RCBD letters come from the Friedman-type procedure", {
  skip_if_no_cld()
  set.seed(955)
  d <- expand.grid(block = factor(1:8), treatment = factor(LETTERS[1:4]))
  d$yield <- 30 + as.numeric(d$treatment) * 2.5 + as.numeric(d$block) + rnorm(nrow(d), 0, 2)
  fit <- np_rcbd(yield ~ treatment, d, block = block, method = "friedman")
  cv <- agri_conover(fit, adjust = "bonferroni", cld = TRUE)

  expect_true(all(grepl("Friedman", cv$method)))
  expect_true(all(cv$paired_by_block))
  cld <- attr(cv, "cld")
  expect_setequal(cld$group, levels(d$treatment))
})

test_that("perfect block concordance is reported instead of crashing", {
  skip_if_no_cld()
  # Identical ranking in every block leaves the Friedman-type Conover statistic
  # undefined: the within-block residual variation is exactly zero.
  d <- expand.grid(block = factor(1:8), treatment = factor(LETTERS[1:4]))
  d$yield <- 30 + as.numeric(d$treatment) * 2.5 + as.numeric(d$block)
  fit <- np_rcbd(yield ~ treatment, d, block = block, method = "friedman")

  expect_warning(cv <- agri_conover(fit, adjust = "bonferroni"),
                 regexp = "undefined|agree perfectly")
  expect_equal(nrow(cv), 0L)
})

test_that("the letter display refuses tables it cannot summarize", {
  skip_if_no_cld()
  expect_error(agri_cld(data.frame(a = 1, b = 2)),
               regexp = "pairwise group comparisons")
  expect_error(agri_cld(data.frame(group1 = "A", group2 = "B", p_adjusted = NA_real_)),
               regexp = "finite adjusted p-value")
})
