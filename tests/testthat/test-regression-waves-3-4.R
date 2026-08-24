# Regression module, waves 3 and 4 of the 0.14.0 improvement plan:
# economic optimum, parallel resampling, broom methods, spatial structure and
# the joint optimum of a surface.

.w34_curve <- function(seed = 11L) {
  set.seed(seed)
  d <- expand.grid(N = seq(0, 200, by = 50), block = factor(1:4), rep = 1:2,
                   KEEP.OUT.ATTRS = FALSE)
  d$yield <- 3 + 0.030 * d$N - 0.00009 * d$N^2 +
    as.numeric(d$block) * 0.3 + stats::rnorm(nrow(d), 0, 0.25)
  d
}
.w34_fit <- function(...) {
  d <- .w34_curve()
  agri_np_regression(yield ~ N, d, method = "gam", block = block, k = 5, ...)
}
.w34_field <- function(seed = 3L) {
  set.seed(seed)
  s <- expand.grid(row = 1:8, col = 1:6, KEEP.OUT.ATTRS = FALSE)
  s$N <- rep(seq(0, 200, by = 50), length.out = nrow(s))
  s$block <- factor(ceiling(s$row / 2))
  s$yield <- 3 + 0.03 * s$N - 0.00009 * s$N^2 +
    0.25 * s$row + 0.15 * s$col + stats::rnorm(nrow(s), 0, 0.2)
  s
}
.w34_surface <- function(seed = 5L) {
  set.seed(seed)
  t2 <- expand.grid(N = seq(0, 200, 50), P = seq(0, 60, 15), block = factor(1:3),
                    KEEP.OUT.ATTRS = FALSE)
  t2$yield <- 3 + 0.030 * t2$N - 0.00013 * t2$N^2 + 0.070 * t2$P -
    0.0009 * t2$P^2 - 0.00010 * t2$N * t2$P +
    as.numeric(t2$block) * 0.2 + stats::rnorm(nrow(t2), 0, 0.15)
  t2
}

# ---- B1, economic optimum ----------------------------------------------------

test_that("the economic optimum lies below the agronomic one", {
  skip_on_cran()
  skip_if_not_installed("mgcv")
  fit <- .w34_fit()
  ag <- agri_np_optimum(fit)
  ec <- suppressWarnings(agri_np_optimum_economic(
    fit, price_ratio = 0.006, B = 49, seed = 1, n = 80))
  expect_lt(ec$optimum$optimum, ag$optimum)
  expect_lte(ec$optimum$lower, ec$optimum$optimum)
  expect_gte(ec$optimum$upper, ec$optimum$optimum)
})

test_that("a zero price ratio reproduces the agronomic optimum", {
  # The check that the root solver and the argmax agree where they must.
  skip_on_cran()
  skip_if_not_installed("mgcv")
  fit <- .w34_fit()
  ag <- agri_np_optimum(fit, n = 200)
  ec <- suppressWarnings(agri_np_optimum_economic(
    fit, price_ratio = 0, B = 19, seed = 1, n = 200))
  rg <- diff(range(fit$data$N))
  expect_lt(abs(ec$optimum$optimum - ag$optimum), 0.02 * rg)
})

test_that("the optimum falls as the input becomes more expensive", {
  skip_on_cran()
  skip_if_not_installed("mgcv")
  fit <- .w34_fit()
  ev <- suppressWarnings(agri_np_optimum_economic(
    fit, price_ratio = c(0, 0.004, 0.008, 0.02), B = 19, seed = 1, n = 80))
  expect_identical(nrow(ev$optimum), 4L)
  expect_true(all(diff(ev$optimum$optimum) <= 0))
})

test_that("an impossible price ratio is refused", {
  skip_if_not_installed("mgcv")
  fit <- .w34_fit()
  expect_error(agri_np_optimum_economic(fit, price_ratio = -1, B = 19),
               "negative")
  expect_error(agri_np_optimum_economic(fit, price_ratio = NA, B = 19),
               "finite")
})

# ---- B3, spatial structure ---------------------------------------------------

test_that("a field trend term enters the formula and absorbs the trend", {
  skip_on_cran()
  skip_if_not_installed("mgcv")
  s <- .w34_field()
  f0 <- agri_np_regression(yield ~ N, s, method = "gam", block = block, k = 4)
  fx <- agri_np_regression(yield ~ N, s, method = "gam", block = block, k = 4,
                           spatial = "smooth_xy", coords = c("row", "col"))
  fr <- agri_np_regression(yield ~ N, s, method = "gam", block = block, k = 4,
                           spatial = "row_col", coords = c("row", "col"))
  expect_match(deparse(fx$formula_used), "s\\(row, col")
  expect_match(paste(deparse(fr$formula_used), collapse = " "), "factor\\(row\\)")
  # The data carry a real gradient, so the term must earn its place.
  expect_lt(fx$metrics$RMSE, f0$metrics$RMSE)
  expect_lt(fr$metrics$RMSE, f0$metrics$RMSE)
  expect_identical(fx$spatial, "smooth_xy")
  expect_identical(fx$coords, c("row", "col"))
})

test_that("prediction still works when coordinates are in the model", {
  # The coordinates are nuisance terms rather than predictors, so a prediction
  # grid that forgot them would fail on an unresolved symbol.
  skip_on_cran()
  skip_if_not_installed("mgcv")
  s <- .w34_field()
  fx <- agri_np_regression(yield ~ N, s, method = "gam", block = block, k = 4,
                           spatial = "smooth_xy", coords = c("row", "col"))
  p <- agri_np_predict(fx)
  expect_true(length(p) > 0L)
  expect_false(anyNA(as.numeric(if (is.data.frame(p)) p$fit else p)))
  expect_no_error(agri_np_optimum(fx, n = 30))
})

test_that("spatial is refused where no term can carry it", {
  s <- .w34_field()
  expect_error(
    agri_np_regression(yield ~ N, s, method = "loess", spatial = "smooth_xy",
                       coords = c("row", "col")),
    "penalised additive engines")
  expect_error(
    agri_np_regression(yield ~ N, s, method = "gam", spatial = "smooth_xy"),
    "needs `coords`")
})

test_that("update carries the spatial declaration", {
  skip_on_cran()
  skip_if_not_installed("mgcv")
  s <- .w34_field()
  fx <- agri_np_regression(yield ~ N, s, method = "gam", block = block, k = 4,
                           spatial = "smooth_xy", coords = c("row", "col"))
  f2 <- update(fx, k = 5)
  expect_identical(f2$spatial, "smooth_xy")
  expect_identical(f2$coords, c("row", "col"))
})

# ---- B2, joint optimum of a surface ------------------------------------------

test_that("the joint optimum is found and its region is not the box", {
  skip_on_cran()
  skip_if_not_installed("mgcv")
  t2 <- .w34_surface()
  ft <- agri_np_regression(yield ~ N + P, t2, method = "gam", block = block,
                           k = 4, gam_structure = "tensor")
  os <- suppressWarnings(agri_np_optimum_surface(ft, B = 60, seed = 1, n = 20))
  expect_identical(nrow(os$optimum), 2L)
  expect_true(all(os$optimum$optimum > os$optimum$searched_lower))
  expect_true(all(os$optimum$optimum < os$optimum$searched_upper))
  expect_true(os$identified)
  # The region is a hull of replicates, so every vertex must be one of them.
  if (!is.null(os$region)) {
    expect_true(all(names(os$region) == attr(os, "predictors")))
    expect_gte(nrow(os$region), 2L)
  }
  expect_output(print(os), "NOT the confidence region")
})

test_that("an additive surface is refused a joint optimum", {
  # Additive means the optimum in one input is the same at every level of the
  # other, so a joint optimum would describe the model rather than the trial.
  skip_on_cran()
  skip_if_not_installed("mgcv")
  t2 <- .w34_surface()
  fa <- agri_np_regression(yield ~ N + P, t2, method = "gam", block = block, k = 4)
  expect_error(agri_np_optimum_surface(fa, B = 19, n = 12), "additive")
})

# ---- C2, parallel resampling -------------------------------------------------

test_that("parallel resampling returns exactly the sequential answer", {
  # This is the whole point of the substreams added in wave 2: an interval must
  # not depend on how many cores computed it.
  skip_on_cran()
  skip_if_not_installed("mgcv")
  fit <- .w34_fit()
  a <- suppressWarnings(agri_np_bootstrap(fit, B = 30, seed = 7, n = 15))
  b <- suppressWarnings(agri_np_bootstrap(fit, B = 30, seed = 7, n = 15,
                                          parallel = TRUE))
  expect_equal(as.data.frame(a)$lower, as.data.frame(b)$lower)
  expect_equal(as.data.frame(a)$upper, as.data.frame(b)$upper)
})

test_that("parallel resampling with real workers matches the sequential answer", {
  skip_on_cran()
  skip_if_not_installed("mgcv")
  skip_if_not_installed("future")
  skip_if_not_installed("future.apply")
  fit <- .w34_fit()
  a <- suppressWarnings(agri_np_bootstrap(fit, B = 30, seed = 7, n = 15))
  old <- future::plan(future::multisession, workers = 2)
  on.exit(future::plan(old), add = TRUE)
  b <- suppressWarnings(agri_np_bootstrap(fit, B = 30, seed = 7, n = 15,
                                          parallel = TRUE))
  expect_equal(as.data.frame(a)$lower, as.data.frame(b)$lower)
})

# ---- D2, broom ---------------------------------------------------------------

test_that("agri_tidy returns the curve, not an invented coefficient table", {
  skip_on_cran()
  skip_if_not_installed("mgcv")
  fit <- .w34_fit()
  tt <- agri_tidy(fit, n = 20)
  expect_identical(nrow(tt), 20L)
  expect_true(all(c("term", "x", "estimate") %in% names(tt)))
  # No test was performed, so no p-value is offered.
  expect_false("p.value" %in% names(tt))
})

test_that("agri_glance and agri_augment describe the fit and its rows", {
  skip_on_cran()
  skip_if_not_installed("mgcv")
  fit <- .w34_fit()
  g <- agri_glance(fit)
  expect_identical(nrow(g), 1L)
  expect_identical(g$method, "gam")
  expect_identical(g$n, nrow(fit$data))
  au <- agri_augment(fit)
  expect_true(all(c(".fitted", ".resid") %in% names(au)))
  expect_identical(nrow(au), nrow(fit$data))
})

test_that("the rank side tidies to one row per term with a p-value", {
  skip_on_cran()
  skip_if_not_installed("ARTool")
  set.seed(2)
  r <- data.frame(block = factor(rep(1:4, each = 6)),
                  trt = factor(rep(rep(c("a", "b", "c"), each = 2), 4)))
  r$y <- stats::rnorm(24) + as.numeric(r$trt) * 0.8
  des <- agri_design(y ~ trt, r, design = "rcbd", block = "block")
  rf <- agri_rank(des, method = "ART")
  tt <- agri_tidy(rf)
  expect_true(all(c("term", "p.value") %in% names(tt)))
  expect_gte(nrow(tt), 1L)
  expect_identical(nrow(agri_glance(rf)), 1L)
  expect_error(agri_augment(rf), "no per-row fitted value")
})

test_that("broom generics are registered when broom is installed", {
  skip_if_not_installed("broom")
  skip_on_cran()
  skip_if_not_installed("mgcv")
  fit <- .w34_fit()
  expect_identical(nrow(broom::tidy(fit, n = 5)), 5L)
  expect_identical(nrow(broom::glance(fit)), 1L)
})
