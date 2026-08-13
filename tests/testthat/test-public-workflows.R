test_that("design summaries and method registry are public and coherent", {
  d <- simulate_agri("rcbd", seed = 1301, n = 4)
  des <- agri_design(yield ~ treatment, d, design = "rcbd", block = block)
  expect_true(validate_agri_design(des)$ok)
  sm <- design_summary(des)
  expect_identical(sm$design, "rcbd")
  expect_identical(sm$blocks, "block")
  mm <- agri_methods()
  expect_true(is.data.frame(mm))
  expect_true(all(c("split-split", "strip-plot", "multivariate", "multi-environment") %in% mm$domain))
})

test_that("effects, pairwise comparisons, plotting and dashboards integrate for CRD fits", {
  d <- simulate_agri("crd", seed = 1302, n = 5)
  fit <- np_crd(yield ~ treatment, d, method = "kruskal")
  ef <- agri_effects(fit)
  pr <- agri_pairs(fit, adjust = "holm")
  expect_true(is.data.frame(ef) && nrow(ef) == 4L)
  expect_true(is.data.frame(pr) && nrow(pr) == 6L)
  expect_s3_class(agri_plot(fit, type = "data"), "ggplot")
  expect_s3_class(agri_plot(fit, type = "effects"), "ggplot")
  q <- tempfile(fileext = ".qmd")
  expect_true(file.exists(agri_dashboard(fit, q)))
  if (requireNamespace("plotly", quietly = TRUE))
    expect_s3_class(agri_interactive(fit, type = "data"), "plotly")
  if (requireNamespace("multcompView", quietly = TRUE)) {
    cl <- agri_cld(fit)
    expect_true(is.data.frame(cl) && nrow(cl) == 4L)
  }
})

test_that("batch and sensitivity objects participate in table, report and export workflows", {
  d <- simulate_agri("crd", seed = 1303, n = 5)
  d$biomass <- d$yield + stats::rnorm(nrow(d), 0, 0.5)
  des <- agri_design(yield ~ treatment, d, design = "crd")

  bt <- agri_batch(des, responses = c("yield", "biomass"), method = "kruskal", adjust_across = "BH")
  expect_s3_class(bt, "agri_batch")
  expect_true(is.data.frame(bt$summary))
  expect_true(inherits(agri_table(bt), "data.frame") || inherits(agri_table(bt), "gt_tbl"))
  expect_true(file.exists(agri_report(bt, tempfile(fileext = ".md"), format = "md")))
  expect_true(file.exists(export_results(bt, tempfile(fileext = ".rds"))))

  sn <- agri_sensitivity(des, methods = "primary")
  expect_s3_class(sn, "agri_sensitivity")
  expect_true(is.data.frame(sn$table))
  expect_true(inherits(agri_table(sn), "data.frame") || inherits(agri_table(sn), "gt_tbl"))
  expect_true(file.exists(agri_report(sn, tempfile(fileext = ".md"), format = "md")))
  expect_true(file.exists(export_results(sn, tempfile(fileext = ".rds"))))
})

test_that("repeated missing-data characterization and native sensitivity are integrated", {
  d <- simulate_agri("repeated_missing", seed = 1304, n = 5, missing_rate = 0.12)
  # Guarantee at least one incomplete but not entirely empty subject for a deterministic test.
  d$height[1L] <- NA_real_
  des <- agri_design(height ~ treatment * time, d, design = "repeated",
                     subject = subject, within = time)
  mr <- agri_missing_report(des)
  expect_s3_class(mr, "agri_missing_report")
  expect_gt(mr$n_missing, 0L)
  expect_true(inherits(agri_table(mr), "data.frame") || inherits(agri_table(mr), "gt_tbl"))
  expect_true(file.exists(agri_report(mr, tempfile(fileext = ".md"), format = "md")))
  expect_true(file.exists(export_results(mr, tempfile(fileext = ".rds"))))

  fit <- agri_repeated(des, backend = "native_wild", B = 19, seed = 4,
                       missing_assumption = "MCAR")
  expect_s3_class(fit, "agri_rank_fit")
  C <- matrix(0, nrow = 1L, ncol = length(fit$engine$p_vector))
  C[1L, 1L] <- 1
  C[1L, 2L] <- -1
  ct <- agri_contrast(fit, C, labels = "cell1-cell2", B = 19, seed = 4)
  expect_true(is.data.frame(ct) || is.list(ct))
  ss <- agri_missing_sensitivity(des, B = 19, seed = 5)
  expect_true(is.list(ss))
  expect_true(all(c("all_available", "complete_subjects") %in% names(ss)))
})

test_that("factorial, split-plot and repeated convenience wrappers preserve design metadata", {
  if (requireNamespace("rankFD", quietly = TRUE) || requireNamespace("ARTool", quietly = TRUE) || requireNamespace("permuco", quietly = TRUE)) {
    f <- simulate_agri("factorial", seed = 1305, n = 3)
    ff <- np_factorial(yield ~ A * B, f, method = "auto")
    expect_s3_class(ff, "agri_rank_fit")
    expect_true(all(c("A", "B") %in% ff$design$predictors))
  }

  if (requireNamespace("ARTool", quietly = TRUE) || requireNamespace("permuco", quietly = TRUE)) {
    s <- simulate_agri("split_plot", seed = 1306, n = 3)
    fs <- np_splitplot(yield ~ irrigation * cultivar, s, block, irrigation, cultivar, method = "auto")
    expect_s3_class(fs, "agri_rank_fit")
    expect_identical(fs$design$whole_plot, "irrigation")
    expect_identical(fs$design$subplot, "cultivar")
  }

  r <- simulate_agri("repeated", seed = 1307, n = 4)
  fr <- np_repeated(height ~ treatment * time, r, subject, time,
                    method = "incomplete_wild", B = 19, seed = 6,
                    missing_assumption = "MCAR")
  expect_s3_class(fr, "agri_rank_fit")
  expect_identical(fr$design$subject, "subject")
})

test_that("ANCOVA integrates with table, report and export when permuco is available", {
  skip_if_not_installed("permuco")
  d <- simulate_agri("crd", seed = 1308, n = 5)
  d$initial <- stats::rnorm(nrow(d))
  z <- agri_ancova(yield ~ treatment, d, covariates = initial, np = 19, seed = 7)
  expect_s3_class(z, "agri_ancova_fit")
  expect_true(inherits(agri_table(z), "data.frame") || inherits(agri_table(z), "gt_tbl"))
  expect_true(file.exists(agri_report(z, tempfile(fileext = ".md"), format = "md")))
  expect_true(file.exists(export_results(z, tempfile(fileext = ".rds"))))
})
