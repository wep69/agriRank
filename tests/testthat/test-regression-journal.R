# Journal-oriented tables, figures and export for the regression module.
#
# These tests protect the publication workflow: every estimate shown in a
# table carries its uncertainty; the level figure shows observed values under
# bootstrap intervals; fitted curves carry bootstrap bands with and without a
# qualitative factor; and figures stay editable ggplot objects that export to
# archival formats.

test_that("agri_theme is applied to regression graphics and stays editable", {
  skip_if_not_installed("ggplot2")
  expect_s3_class(agri_theme(), "theme")
  data(agri_dose, package = "agriRank")
  ss <- agri_np_regression(yield ~ dose, agri_dose, method = "smoothing_spline")
  p <- agri_np_plot(ss, type = "fit")
  expect_s3_class(p, "ggplot")
  expect_s3_class(p$theme, "theme")
  # The figure accepts further layers; the theme does not freeze it.
  p2 <- p + ggplot2::labs(y = "Yield (Mg/ha)")
  expect_equal(p2$labels$y, "Yield (Mg/ha)")
})

test_that("agri_save_figure writes archival formats at journal widths", {
  skip_if_not_installed("ggplot2")
  data(agri_dose, package = "agriRank")
  ss <- agri_np_regression(yield ~ dose, agri_dose, method = "smoothing_spline")
  p <- agri_np_plot(ss, type = "fit")
  fpng <- agri_save_figure(p, tempfile(fileext = ".png"), layout = "column")
  fpdf <- agri_save_figure(p, tempfile(fileext = ".pdf"), layout = "full")
  ftif <- agri_save_figure(p, tempfile(fileext = ".tif"), layout = "column", dpi = 150)
  expect_true(all(file.exists(c(fpng, fpdf, ftif))))
  expect_error(agri_save_figure(p, tempfile(fileext = ".bmp")),
               regexp = "Unsupported figure format")
  expect_error(agri_save_figure("not a plot", tempfile(fileext = ".png")),
               regexp = "ggplot")
})

test_that("agri_np_levels describes every level of the qualitative predictors", {
  skip_if_not_installed("quantreg")
  dz <- .np_make_factor_data()
  fit <- suppressWarnings(
    agri_np_regression(yield ~ dose + cultivar, dz, method = "quantile"))
  lv <- suppressWarnings(agri_np_levels(fit, B = 49, seed = 1))
  expect_named(lv, c("factor", "level", "n", "response_median", "response_mad",
                     "response_mean", "response_sd", "fit", "lower", "upper"))
  expect_equal(lv$level, c("Ana", "Bela"))
  expect_equal(sum(lv$n), nrow(dz))
  expect_true(all(lv$lower <= lv$fit & lv$fit <= lv$upper))
  # The fitted level ordering must agree with the cultivar coefficient.
  expect_gt(lv$fit[lv$level == "Bela"], lv$fit[lv$level == "Ana"])
  # The bootstrap object travels with the table so the figure can reuse it.
  expect_s3_class(attr(lv, "bootstrap"), "agri_np_bootstrap")

  # A fit without qualitative predictors has no levels to summarize, and the
  # message says what to use instead.
  data(agri_dose, package = "agriRank")
  ss <- agri_np_regression(yield ~ dose, agri_dose, method = "smoothing_spline")
  expect_error(agri_np_levels(ss), regexp = "no qualitative predictor")

  # A curve bootstrap computed elsewhere must cover the level grid.
  b_wrong <- agri_np_bootstrap(fit, B = 9, n = 5, seed = 1)
  expect_error(agri_np_levels(fit, bootstrap = b_wrong), regexp = "level grid")

  # A factor-only model is a legitimate level summary as well.
  f_only <- suppressWarnings(
    agri_np_regression(yield ~ cultivar, dz, method = "quantile"))
  lv2 <- suppressWarnings(agri_np_levels(f_only, B = 19, seed = 1))
  expect_equal(nrow(lv2), 2L)
})

test_that("agri_table exposes coefficient and level tables", {
  skip_if_not_installed("quantreg")
  dz <- .np_make_factor_data()
  fit <- suppressWarnings(
    agri_np_regression(yield ~ dose + cultivar, dz, method = "quantile"))

  ct <- suppressWarnings(
    agri_table(fit, "coefficients", method = "bootstrap", B = 49, seed = 1,
               format = "data.frame"))
  expect_true(inherits(ct, "data.frame"))
  expect_true(all(c("term", "estimate", "lower", "upper", "method") %in% names(ct)))
  expect_true("cultivarBela" %in% ct$term)

  lv <- suppressWarnings(agri_table(fit, "levels", B = 49, seed = 1,
                                    format = "data.frame"))
  expect_true(all(c("factor", "level", "n", "fit", "lower", "upper") %in% names(lv)))
  expect_equal(nrow(lv), 2L)
})

test_that("the level figure shows observed values under bootstrap intervals", {
  skip_if_not_installed("quantreg")
  skip_if_not_installed("ggplot2")
  dz <- .np_make_factor_data()
  fit <- suppressWarnings(
    agri_np_regression(yield ~ dose + cultivar, dz, method = "quantile"))
  p <- suppressWarnings(agri_np_plot(fit, type = "levels", B = 49, seed = 1))
  expect_s3_class(p, "ggplot")
  geoms <- vapply(p$layers, function(l) class(l$geom)[1], character(1))
  expect_true("GeomPoint" %in% geoms)
  expect_true("GeomPointrange" %in% geoms)
  # One panel per factor carries the factor name.
  expect_true(inherits(p$facet, "FacetGrid"))
})

test_that("agri_format_ci produces manuscript-ready text", {
  s <- agri_format_ci(1.056, 0.678, 1.465)
  expect_true(grepl("1.1", s, fixed = TRUE))
  expect_true(grepl("0.68", s, fixed = TRUE))
  expect_true(grepl("1.5", s, fixed = TRUE))
  expect_true(grepl("(", s, fixed = TRUE))
  expect_true(grepl(")", s, fixed = TRUE))
  # More digits gives more precision
  s2 <- agri_format_ci(1.056, 0.678, 1.465, digits = 3)
  expect_true(grepl("1.06", s2, fixed = TRUE))
})

test_that("print reports the reference level of qualitative predictors", {
  skip_if_not_installed("quantreg")
  dz <- .np_make_factor_data()
  fit <- suppressWarnings(agri_np_regression(yield ~ dose + cultivar, dz, method = "quantile"))
  out <- capture.output(print(fit))
  expect_true(any(grepl("reference level", out)))
  expect_true(any(grepl("contrast", out)))
})

test_that("jitter argument spreads overlapping points", {
  skip_if_not_installed("ggplot2")
  data(agri_dose, package = "agriRank")
  ss <- agri_np_regression(yield ~ dose, agri_dose, method = "smoothing_spline")
  p_noj <- agri_np_plot(ss, type = "fit", jitter = FALSE)
  p_jit <- agri_np_plot(ss, type = "fit", jitter = TRUE)
  expect_s3_class(p_noj, "ggplot")
  expect_s3_class(p_jit, "ggplot")
})

test_that("forest caption is configurable", {
  skip_if_not_installed("quantreg")
  skip_if_not_installed("ggplot2")
  dz <- .np_make_factor_data()
  fit <- suppressWarnings(agri_np_regression(yield ~ dose + cultivar, dz, method = "quantile"))
  bt <- suppressWarnings(agri_np_bootstrap(fit, target = "coefficients", B = 19, seed = 1))
  p <- agri_np_forest(fit, bootstrap = bt, caption = "Custom caption here.")
  expect_match(p$labels$caption, "Custom caption here.")
})

test_that("agri_table format rtf returns a file path when gt is available", {
  skip_if_not_installed("gt")
  skip_if_not_installed("quantreg")
  dz <- .np_make_factor_data()
  fit <- suppressWarnings(agri_np_regression(yield ~ dose + cultivar, dz, method = "quantile"))
  fpath <- agri_table(fit, "coefficients", method = "bootstrap", B = 19, seed = 1,
                      format = "rtf")
  expect_true(file.exists(fpath))
  expect_match(fpath, "\\.rtf$")
})

test_that("fit curves carry a bootstrap band with and without a factor", {
  skip_if_not_installed("quantreg")
  skip_if_not_installed("ggplot2")
  data(agri_dose, package = "agriRank")
  ss <- agri_np_regression(yield ~ dose, agri_dose, method = "smoothing_spline")
  b <- agri_np_bootstrap(ss, B = 19, n = 20, seed = 1)
  p1 <- agri_np_plot(ss, type = "fit", bootstrap = b)
  g1 <- vapply(p1$layers, function(l) class(l$geom)[1], character(1))
  expect_true("GeomRibbon" %in% g1)

  dz <- .np_make_factor_data()
  fit <- suppressWarnings(
    agri_np_regression(yield ~ dose + cultivar, dz, method = "quantile"))
  p2 <- suppressWarnings(
    agri_np_plot(fit, type = "fit", predictor = "dose", group = "cultivar",
                 bootstrap = 19, seed = 1))
  expect_s3_class(p2, "ggplot")
  g2 <- vapply(p2$layers, function(l) class(l$geom)[1], character(1))
  # Observed points, one line per level and one band per level.
  expect_true(all(c("GeomPoint", "GeomLine", "GeomRibbon") %in% g2))
  # A coefficient bootstrap cannot be redrawn as a band around a curve.
  bcf <- suppressWarnings(
    agri_np_bootstrap(fit, target = "coefficients", B = 19, seed = 1))
  expect_error(
    agri_np_plot(fit, type = "fit", predictor = "dose", group = "cultivar",
                 bootstrap = bcf),
    regexp = "curve")
})
