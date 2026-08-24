# Regression module, waves 1 and 2 of the 0.14.0 improvement plan.
#
# Four of these items are corrections of internal incoherence found by reading
# the code rather than the documentation, so each test states the incoherence it
# prevents from returning.

.w12_data <- function(seed = 7L) {
  set.seed(seed)
  d <- expand.grid(N = seq(0, 160, by = 40), block = factor(1:4), rep = 1:2,
                   KEEP.OUT.ATTRS = FALSE)
  d$cultivar <- factor(rep(c("a", "b"), length.out = nrow(d)))
  d$yield <- 30 + 0.25 * d$N - 0.0009 * d$N^2 +
    as.numeric(d$block) * 1.5 + stats::rnorm(nrow(d), 0, 1.5)
  d
}
.w12_fit <- function(...) {
  d <- .w12_data()
  agri_np_regression(yield ~ N, d, method = "gam", block = block, k = 5, ...)
}

# ---- A4, support guard -------------------------------------------------------

test_that("prediction outside the fitted range warns and is flagged", {
  fit <- .w12_fit()
  nd <- data.frame(N = c(80, 400),
                   block = factor(1, levels = levels(fit$data$block)))
  expect_warning(p <- agri_np_predict(fit, nd), "leaves the range")
  fl <- if (is.data.frame(p)) p$extrapolated else attr(p, "extrapolated")
  expect_equal(fl, c(FALSE, TRUE))
})

test_that("the support guard survives tryCatch and withCallingHandlers", {
  # The first implementation detected internal calls by walking the call stack.
  # It went silent under exactly these two wrappers, which is how users write
  # scripts and how testthat wraps expectations, so the guard failed where it
  # was most needed. This test exists to keep that from coming back.
  fit <- .w12_fit()
  nd <- data.frame(N = 400, block = factor(1, levels = levels(fit$data$block)))
  seen <- FALSE
  withCallingHandlers(agri_np_predict(fit, nd),
    warning = function(w) { seen <<- TRUE; invokeRestart("muffleWarning") })
  expect_true(seen)
  expect_error(
    tryCatch(agri_np_predict(fit, nd, extrapolation = "error"),
             warning = function(w) invokeRestart("muffleWarning")),
    "extrapolation_tol")
})

test_that("the support guard respects its tolerance and can be switched off", {
  fit <- .w12_fit()
  near <- data.frame(N = 165, block = factor(1, levels = levels(fit$data$block)))
  expect_no_error(suppressWarnings(
    agri_np_predict(fit, near, extrapolation = "error")))
  far <- data.frame(N = 400, block = factor(1, levels = levels(fit$data$block)))
  expect_no_warning(agri_np_predict(fit, far, extrapolation = "allow"))
})

test_that("the support guard is silent inside cross-validation", {
  # Held-out folds leave the training range by construction. Warning there would
  # emit the notice once per fold for something perfectly legitimate.
  d <- .w12_data()
  n <- 0L
  withCallingHandlers(
    agri_np_compare(yield ~ N, d, methods = "gam", block = block, kfold = 4),
    warning = function(w) {
      if (grepl("leaves the range", conditionMessage(w))) n <<- n + 1L
      invokeRestart("muffleWarning")
    })
  expect_identical(n, 0L)
})

# ---- D1, prediction intervals ------------------------------------------------

test_that("prediction intervals require a scope when a block is declared", {
  fit <- .w12_fit()
  nd <- data.frame(N = 80, block = factor(1, levels = levels(fit$data$block)))
  expect_error(agri_np_predict(fit, nd, interval = "prediction"), "scope")
})

test_that("a prediction interval is wider than a confidence interval", {
  fit <- .w12_fit()
  nd <- data.frame(N = c(40, 120),
                   block = factor(1, levels = levels(fit$data$block)))
  ci <- agri_np_predict(fit, nd, interval = "confidence")
  pi <- agri_np_predict(fit, nd, interval = "prediction",
                        scope = "within_block", seed = 1)
  expect_true(all(pi$upper - pi$lower > ci$upper - ci$lower))
  expect_s3_class(pi, "agri_np_conformal")
  expect_identical(attr(pi, "interval"), "prediction")
})

# ---- A3, multiplicity --------------------------------------------------------

test_that("pairwise optimum contrasts carry an adjusted p-value", {
  skip_on_cran()
  d <- .w12_data()
  fv <- agri_np_regression(yield ~ N + cultivar, d, method = "gam",
                           block = block, k = 5, gam_structure = "varying")
  ot <- suppressWarnings(agri_np_optimum_test(
    fv, by = cultivar, B = 49, seed = 1, n = 30, external = FALSE))
  expect_true("p_adjusted" %in% names(ot$contrasts))
  expect_identical(attr(ot, "adjust"), "holm")
  expect_true(all(ot$contrasts$p_adjusted >= ot$contrasts$p_value))
  expect_output(print(ot), "adjusted by holm")
})

# ---- A1, cross-validation scope ---------------------------------------------

test_that("the two cross-validation routines share one fold rule", {
  # Before 0.14.0 agri_np_compare() stratified within blocks while .np_cv_r2()
  # assigned rows at random, so the same model reported two validated errors
  # depending on which function was asked.
  d <- .w12_data()
  a <- agriRank:::.np_cv_folds(d, "block", 4L, 1L, "within_block")
  b <- agriRank:::.np_cv_folds(d, "block", 4L, 1L, "within_block")
  expect_identical(a, b)
  # within_block keeps every block in training; new_block does not
  expect_true(all(table(d$block, a) > 0))
  g <- agriRank:::.np_cv_folds(d, "block", 4L, 1L, "new_block")
  expect_true(all(rowSums(table(d$block, g) > 0) == 1L))
})

test_that("holding out whole blocks gives a more pessimistic error", {
  skip_on_cran()
  fit <- .w12_fit()
  w <- agri_np_diagnostics(fit, cv = TRUE, kfold = 4, seed = 1,
                           cv_scope = "within_block")
  n <- agri_np_diagnostics(fit, cv = TRUE, kfold = 4, seed = 1,
                           cv_scope = "new_block")
  expect_true(is.finite(n$r2$cv_r2))
  expect_lt(n$r2$cv_r2, w$r2$cv_r2)
  expect_identical(attr(n$r2, "cv_scope"), "new_block")
})

test_that("new_block is refused without a block", {
  d <- .w12_data()
  expect_error(
    agri_np_compare(yield ~ N, d, methods = "gam", kfold = 4,
                    cv_scope = "new_block"),
    "needs a declared block")
})

# ---- D3, update --------------------------------------------------------------

test_that("update changes only what is named", {
  fit <- .w12_fit()
  f2 <- update(fit, k = 7)
  expect_identical(f2$method, fit$method)
  expect_identical(f2$block, fit$block)
  expect_identical(f2$settings$k, 7)
  expect_identical(nrow(f2$data), nrow(fit$data))
  expect_error(update(fit, not_an_argument = 1), "Not an argument")
})

test_that("update inherits the guards of agri_np_regression", {
  fit <- .w12_fit()
  expect_error(update(fit, method = "loess"), "does not adjust for the declared block")
})

# ---- A2, the significance test says how it treats the design ----------------

test_that("the kernel significance test prints its randomization caveat", {
  skip_if_not_installed("np")
  skip_on_cran()
  d <- .w12_data()
  fk <- agri_np_regression(yield ~ N, d, method = "kernel", block = block)
  sg <- agri_np_significance(fk, B = 49)
  expect_s3_class(sg, "agri_np_significance")
  out <- utils::capture.output(print(sg))
  expect_true(any(grepl("How this p-value treats the design", out)))
  expect_true(any(grepl("adjusts for the block", out)))
})

# ---- C1, reproducible substreams --------------------------------------------

test_that("substreams make a replicate independent of the order it was drawn", {
  st <- agriRank:::.agri_substreams(99L, 5L)
  expect_length(st, 5L)
  draw <- function(i) agriRank:::.agri_on_stream(st[[i]], stats::runif(3))
  forward <- lapply(1:5, draw)
  backward <- rev(lapply(5:1, draw))
  expect_equal(forward, backward)
  expect_length(unique(vapply(forward, `[`, numeric(1), 1L)), 5L)
})

test_that("resampling leaves the user's RNG state and kind untouched", {
  fit <- .w12_fit()
  set.seed(4242); before <- stats::runif(1)
  set.seed(4242); invisible(suppressWarnings(
    agri_np_bootstrap(fit, B = 10, seed = 5, n = 10)))
  after <- stats::runif(1)
  expect_equal(before, after)
  expect_identical(RNGkind()[1], "Mersenne-Twister")
})

test_that("the bootstrap is reproducible from its seed", {
  fit <- .w12_fit()
  a <- suppressWarnings(agri_np_bootstrap(fit, B = 20, seed = 99, n = 15))
  b <- suppressWarnings(agri_np_bootstrap(fit, B = 20, seed = 99, n = 15))
  expect_equal(as.data.frame(a)$lower, as.data.frame(b)$lower)
  c3 <- suppressWarnings(agri_np_bootstrap(fit, B = 20, seed = 100, n = 15))
  expect_false(isTRUE(all.equal(as.data.frame(a)$lower,
                                as.data.frame(c3)$lower)))
})
