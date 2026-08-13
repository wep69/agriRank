test_that("Conover is design-aware for CRD and RCBD", {
  skip_if_not_installed("PMCMRplus")
  set.seed(101)
  d1 <- data.frame(trt = factor(rep(LETTERS[1:3], each = 6)), y = rgamma(18, rep(4:6, each = 6), 1))
  f1 <- np_crd(y ~ trt, d1, method = "kruskal")
  z1 <- agri_conover(f1)
  expect_true(all(c("group1", "group2", "p_adjusted") %in% names(z1)))
  expect_false(any(z1$paired_by_block))

  d2 <- expand.grid(block = factor(1:5), trt = factor(LETTERS[1:3]))
  d2$y <- 10 + as.numeric(d2$trt) + as.numeric(d2$block) + rnorm(nrow(d2))
  f2 <- np_rcbd(y ~ trt, d2, block = block, method = "friedman")
  z2 <- agri_conover(f2)
  expect_true(all(z2$paired_by_block))
})

test_that("Conover refuses incomplete classical RCBD cells", {
  skip_if_not_installed("PMCMRplus")
  d <- expand.grid(block = factor(1:5), trt = factor(LETTERS[1:3]))
  d$y <- seq_len(nrow(d))
  des <- agri_design(y ~ trt, d[-1, ], design = "rcbd", block = block)
  # Fit through an ART/permutation engine is not required to test the post-hoc guard;
  # create a minimal compatible fit carrying the validated design.
  fit <- structure(list(design = des, response = "y", engine = list(method = "test"), method = "test"), class = "agri_rank_fit")
  expect_error(agri_conover(fit), "complete unreplicated")
})

test_that("Conover exposes raw and adjusted p-values", {
  skip_if_not_installed("PMCMRplus")
  set.seed(404)
  d <- data.frame(trt = factor(rep(LETTERS[1:4], each = 8)),
                  y = rgamma(32, shape = rep(4:7, each = 8)))
  f <- np_crd(y ~ trt, d, method = "kruskal")
  z <- agri_conover(f, adjust = "holm")
  expect_true(all(c("p_value", "p_adjusted", "group1", "group2") %in% names(z)))
  expect_true(any(is.finite(z$p_value)))
  expect_true(any(is.finite(z$p_adjusted)))
})


test_that("Conover p-values match PMCMRplus backends exactly", {
  skip_if_not_installed("PMCMRplus")
  set.seed(413)
  d1 <- data.frame(trt = factor(rep(LETTERS[1:4], each = 7)),
                   y = rgamma(28, shape = rep(c(4, 5, 6, 7), each = 7)))
  f1 <- np_crd(y ~ trt, d1, method = "kruskal")
  z1 <- agri_conover(f1, adjust = "holm")
  ref1 <- PMCMRplus::kwAllPairsConoverTest(d1$y, d1$trt, p.adjust.method = "holm")
  expect_equal(sort(z1$p_adjusted), sort(as.numeric(stats::na.omit(as.vector(ref1$p.value)))), tolerance = 1e-12)

  d2 <- expand.grid(block = factor(1:6), trt = factor(LETTERS[1:4]))
  d2$y <- 20 + as.numeric(d2$trt) + as.numeric(d2$block)/2 + rnorm(nrow(d2), 0, .3)
  f2 <- np_rcbd(y ~ trt, d2, block = block, method = "friedman")
  z2 <- agri_conover(f2, adjust = "holm")
  ref2 <- PMCMRplus::frdAllPairsConoverTest(d2$y, d2$trt, d2$block, p.adjust.method = "holm")
  expect_equal(sort(z2$p_adjusted), sort(as.numeric(stats::na.omit(as.vector(ref2$p.value)))), tolerance = 1e-12)
})
