# Regression test for the defect fixed in 0.14.0.
#
# permuco::aovperm was the first automatic choice for split-plot and split-split.
# It implements the repeated-measures Error(subject/within) form and never builds
# the sub-plot stratum of a field design, so every term was tested against the
# whole-plot mean square. No test compared the residual degrees of freedom of each
# stratum against aov, which is why the defect survived two releases. That is what
# these tests do, and the expected values are taken from aov rather than written
# by hand, so they stay valid if the generators change size.

.sd_split_plot <- function(nb = 4L, seed = 424242L) {
  set.seed(seed)
  d <- expand.grid(cultivar = factor(c("c1", "c2", "c3")),
                   irrigation = factor(c("dry", "irrigated")),
                   block = factor(seq_len(nb)),
                   KEEP.OUT.ATTRS = FALSE)
  b <- stats::rnorm(nb)
  wp <- stats::rnorm(nb * 2L)
  wid <- as.integer(interaction(d$block, d$irrigation, drop = TRUE))
  d$yield <- 10 + b[as.integer(d$block)] + wp[wid] + stats::rnorm(nrow(d))
  d
}

.sd_aov_df <- function(d) {
  d$.r <- rank(d$yield, ties.method = "average")
  s <- summary(stats::aov(.r ~ irrigation * cultivar + Error(block / irrigation),
                          data = d))
  # stratum 2 is block:irrigation (whole-plot error), stratum 3 is Within
  wp <- s[[2L]][[1L]]
  wi <- s[[3L]][[1L]]
  c(whole = wp[["Df"]][nrow(wp)], within = wi[["Df"]][nrow(wi)])
}

test_that("split-plot strata reproduce the aov residual degrees of freedom", {
  skip_if_not_installed("ARTool")
  d <- .sd_split_plot()
  ref <- .sd_aov_df(d)

  a <- np_splitplot(yield ~ irrigation * cultivar, d, block = block,
                    whole_plot = irrigation, subplot = cultivar)
  tab <- a$omnibus
  expect_true(all(c("Term", "Df.res") %in% names(tab)))

  got <- function(term) tab$Df.res[match(term, tab$Term)]
  # the whole-plot factor belongs to the block:irrigation stratum
  expect_equal(got("irrigation"), as.numeric(ref[["whole"]]))
  # the sub-plot factor and its interaction belong to the Within stratum
  expect_equal(got("cultivar"), as.numeric(ref[["within"]]))
  expect_equal(got("irrigation:cultivar"), as.numeric(ref[["within"]]))
  # the two strata must differ; collapsing them was the defect
  expect_false(identical(got("irrigation"), got("cultivar")))
})

test_that("automatic mode does not route nested field designs to permuco", {
  skip_if_not_installed("ARTool")
  d <- .sd_split_plot()
  a <- np_splitplot(yield ~ irrigation * cultivar, d, block = block,
                    whole_plot = irrigation, subplot = cultivar)
  expect_false(grepl("permuco", a$method, ignore.case = TRUE))
  expect_match(a$method, "ART|Aligned Rank Transform")
})

test_that("permuco is refused for every design with nested field strata", {
  skip_if_not_installed("permuco")
  d <- .sd_split_plot()

  expect_error(
    np_splitplot(yield ~ irrigation * cultivar, d, block = block,
                 whole_plot = irrigation, subplot = cultivar, method = "permuco"),
    "not admissible")

  set.seed(11L)
  ss <- expand.grid(timing = factor(c("t1", "t2")),
                    cultivar = factor(c("c1", "c2", "c3")),
                    irrigation = factor(c("dry", "irrigated")),
                    block = factor(1:4), KEEP.OUT.ATTRS = FALSE)
  ss$yield <- 10 + stats::rnorm(nrow(ss))
  expect_error(
    np_splitsplit(yield ~ irrigation * cultivar * timing, ss, block = block,
                  whole_plot = irrigation, subplot = cultivar,
                  subsubplot = timing, method = "permuco"),
    "not admissible")

  set.seed(12L)
  st <- expand.grid(sa = factor(c("a1", "a2", "a3")), sb = factor(c("b1", "b2")),
                    block = factor(1:4), KEEP.OUT.ATTRS = FALSE)
  st$yield <- 10 + stats::rnorm(nrow(st))
  expect_error(
    np_stripplot(yield ~ sa * sb, st, block = block, strip_a = sa,
                 strip_b = sb, method = "permuco"),
    "not admissible")
})

test_that("permuco remains available where its Error() form is the right one", {
  skip_if_not_installed("permuco")
  set.seed(99L)
  d <- data.frame(block = factor(rep(1:4, each = 6L)),
                  trt = factor(rep(rep(c("a", "b", "c"), each = 2L), 4L)))
  d$y <- stats::rnorm(nrow(d))
  des <- agri_design(y ~ trt, d, design = "rcbd", block = "block")
  fit <- agri_rank(des, method = "permuco", np = 199L)
  expect_s3_class(fit, "agri_rank_fit")
  expect_true(nrow(fit$omnibus) >= 1L)
})

test_that("agri_sensitivity records the refusal instead of failing", {
  skip_if_not_installed("permuco")
  skip_if_not_installed("ARTool")
  d <- .sd_split_plot()
  des <- agri_design(yield ~ irrigation * cultivar, d, design = "split_plot",
                     block = "block", whole_plot = "irrigation",
                     subplot = "cultivar")
  s <- agri_sensitivity(des, methods = c("primary", "permuco"))
  expect_s3_class(s, "agri_sensitivity")
  note <- s$table$note[s$table$method == "permuco"]
  expect_true(any(grepl("not admissible", note, fixed = TRUE)))
})

test_that("agri_methods no longer advertises permuco for nested field designs", {
  m <- agri_methods()
  rows <- m$method[m$domain %in% c("split-plot", "split-split", "strip-plot")]
  expect_length(rows, 3L)
  expect_false(any(grepl("permuco", rows, fixed = TRUE)))
})
