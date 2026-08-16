# agriRank 0.13.0

## Regression: uncertainty, explained variation and graphics

* Added the standard extractors `coef()`, `confint()`, `fitted()` and `residuals()` for `agri_np_reg_fit`. Coefficients are returned for `theil_sen`, `siegel` and `quantile`; the smoothers refuse them by name, because reporting spline basis coefficients as agronomic slopes would invite a reading the model does not support.
* `confint()` prefers the interval published by the backend and falls back to the cluster-aware bootstrap. The two usually differ, and the difference is the point: one relies on the asymptotic theory of the estimator, the other only on the legitimacy of resampling experimental units.
* `agri_np_bootstrap()` gains `target = "coefficients"` for intervals of the coefficient vector, `band = "simultaneous"` for a sup-t band that covers the whole curve rather than each point, and `keep_replicates` for the replicate matrix, which allows a histogram of a slope or a cloud of fitted curves.
* `agri_np_diagnostics()` reports three explained-variation indices with the effective degrees of freedom beside them: `pseudo_r2` computed on the fitted values, `cv_r2` computed out of fold and available with `cv = TRUE`, and `spearman_r2` from the ranks. They can disagree, and the disagreement is informative: a LOESS fit typically shows a larger `pseudo_r2`, a larger `effective_df` and a smaller `cv_r2` than a smoothing spline on the same data.
* `agri_np_plot()` gains the residual diagnostics `"qq"`, `"scale_location"` and `"order"`, the integer decision figures `"efficiency"` and `"difference"`, and a `bootstrap` argument that draws a resampling band for engines with no analytic interval.
* Added plot methods for `agri_np_bootstrap`, `agri_np_compare`, `agri_integer_bootstrap` and `agri_integer_confset`, which previously could only be printed. The integer figures show the probability mass over admissible decisions and fade, rather than remove, the decisions outside the confidence set.
* Added `agri_np_curves()`, which overlays the fitted curves of several engines over the observed points.
* An integer-support fit is now drawn as steps and crosses instead of a continuous line, which no longer suggests that a value exists between two admissible decisions.

## Regression: qualitative factors and coefficient forest plots

* `agri_np_regression()` now treats qualitative predictors explicitly: a character column is read as the factor it is, a factor needs at least two levels to enter a model, and the fitted object records its qualitative predictors. Quantile, kernel, GAM and SCAM engines keep a factor as an adjustment term; curve-only engines refuse factors by name instead of silently dropping them.
* The coefficient bootstrap aligns replicates by term name, so a reordered or level-depleted replicate is counted as a failed refit instead of being read in the original order. Block adjustment terms are excluded from the coefficient target because they are nuisance parameters whose meaning changes with every draw of the blocks; a block-adjusted fit therefore reports intervals for the scientific coefficients of the declared formula.
* Added `agri_np_forest()`, a forest plot of bootstrap intervals for regression coefficients. With qualitative predictors it stacks one row per factor level inside the factor's own panel and draws the reference level at zero, so every level appears in the figure instead of only the dummy contrasts. `agri_np_plot()` reaches the same figure through `type = "forest"`.

## Regression: journal-oriented tables, figures and export

* Added `agri_np_levels()` and `agri_np_plot(type = "levels")`: the response at every level of the qualitative predictors, with the observed sample size, median/MAD and mean/sd beside the fitted marginal response and its pointwise bootstrap interval. It is the level-oriented companion of the coefficient forest plot: coefficients state contrasts against the reference level, this summary states what the model predicts at each level itself.
* `agri_table()` gains `"coefficients"` and `"levels"` for regression fits, so a table presented in a manuscript carries the uncertainty of every estimate it reports.
* `agri_np_plot(type = "fit", group = ..., bootstrap = ...)` now draws one resampling band per level of the grouping variable, computed in a single bootstrap loop over the combined grid. Observed values, fitted curves and bands appear together for models with and without qualitative factors.
* Added `agri_theme()`, the common theme of the regression graphics: no minor gridlines, drawn axis lines, readable base size and a compact legend. Figures remain plain ggplot objects, so any layer can still be added or the theme replaced.
* Added `agri_save_figure()`, which writes a figure as TIFF (LZW), PDF, SVG, EPS or PNG at preset journal widths (one column, middle, full), keeping text and lines editable in the vector formats.

## Regression: colour vision, annotation and rich reports

* `agri_np_plot()` gains `palette = "color" | "grey"` for group curves, `x_unit` / `y_unit` to append SI-style units to the default axis labels, and a clean separation between the public wrapper and the internal drawing function. Grouped plots now carry colour-blind-safe Okabe-Ito colour by default, and grey tones safe for black-and-white print when requested.
* `agri_np_forest()` gains `annotate_values` (write the interval as text to the right of each bar), `digits` for annotation and axis formatting, `order_by = "effect"` to sort rows by absolute estimate within each panel, and `ref_line` to move the vertical reference line.
* A warning is raised once per session when `B < 999`, to remind authors that a small number of bootstrap replicates is a speed device and that final inference needs `B >= 999`. Silence with `options(agriRank.quiet_small_B = TRUE)`.
* `agri_report()` now writes a richer markdown regression report: the coefficient table with confidence intervals, the qualitative-factor structure, the level summary, one fit, forest and level figure rendered at 300 dpi alongside the report, and a "How to cite" section with `citation("agriRank")`.

## Regression: small increments

* Added `agri_format_ci()` to format an estimate and its interval as `"1.06 (0.68; 1.47)"` for direct use in manuscript text.
* `agri_np_plot()` gains `jitter = TRUE` to spread overlapping observed values in dose-response plots.
* `agri_np_forest()` gains a `caption` parameter with a default explanation of the reference level.
* `print.agri_np_reg_fit()` now reports the reference level of each qualitative predictor and reminds that coefficients are contrasts against it.
* `agri_table()` gains `format = "rtf"` for direct RTF export via `gt::gtsave()` into Word or LibreOffice.
* Added a Quarto template at `inst/templates/regression-report.qmd` for the regression report.
* Added a brief note in vignette v16 on figure editability: every agriRank figure is a `ggplot` object; every table a data frame.

## Integrated tutorial (English and Portuguese)

* Added vignette `v18-integrated-tutorial`, the English version of the integrated tutorial: qualitative designs (CRD, RCBD, factorial, split-plot with CLD and figures), quantitative regression (fit, bootstrap bands, diagnostics, derivative, optimum, engine comparison), qualitative + quantitative (levels with confidence intervals, forest and grouped curves), and integer ordinal factors (the four integer engines, fit-quality metrics with R-squared/RMSE/MAE/MAD, optimum, thresholds and the bootstrap confidence set of the optimum).
* The Portuguese version ships as a standalone Quarto document in the repository's `cheatsheet/` directory (`agriRank_Tutorial_PT.qmd` and a self-contained HTML rendering), beside the English one (`agriRank_Tutorial_EN.qmd` and HTML) and the existing cheatsheets.
* The tutorial uses `simulate_agri()` throughout with fixed seeds chosen so the effects are real (the CLD letters differ), `B = 1000` in every resampling, integer-only axis breaks for the density factor, and fit-quality tables whose numbers are read from the fitted objects.

## Example data and documentation

* Added three exported data sets: `agri_dose` (nitrogen rates in an RCBD, quadratic-plateau response), `agri_density` (plants per hill, an integer treatment with a unimodal response) and `agri_surface` (nitrogen by irrigation depth with a positive cross term). The generating script is in `data-raw/`.
* Added the quantitative-gradient scenarios `"dose_response"`, `"integer_density"` and `"surface"` to `simulate_agri()`, mirroring the exported data sets for users who need fresh replicates.
* Rewrote the examples of all 18 regression functions to use the exported data, to state units (Mg ha^-1^, kg ha^-1^) and to end in an agronomic reading rather than a bare call. Fitted objects now persist after the examples run.
* Examples with resampling state explicitly that `B = 19` is a speed device and that analysis needs `B >= 999`.
* Compact letter displays are now available on **every** comparison route, not only Conover: `agri_pairs()` and `agri_conover()` gain `cld` and `alpha`, and `agri_cld()` accepts a comparison table produced by either one.
* The simultaneous max-T contrasts of the native repeated wild-rank engine are covered as well. Their labels of the form `"stratum: g1 - g2"` are parsed back into groups, and the adjusted `p_adjusted_maxT` column is used.
* Letters are computed within each simple-effect stratum, because groups compared in different strata were never tested against each other.
* An incomplete family of comparisons, or a user-defined contrast that is not a simple difference between two groups, is refused with an explicit message instead of being summarized into letters that would imply comparisons the analysis never performed.

## Fixes

* `agri_np_predict()` now names the missing variable when `newdata` omits a predictor or the declared block, instead of failing inside the backend with an unresolved symbol.
* The Friedman-type Conover adapter no longer fails with a data-frame subscript error when block rankings agree perfectly; it warns and reports no comparison for that stratum.
* `np_repeated()` without `subject=` and `agri_multienv()` without `environment=` now fail with the scientific reason.
* The rankFD adapter populates the standardized omnibus table, which had been empty and silently disabled `agri_table()`, `agri_sensitivity()` and `agri_batch()` on that route.
* Replaced the deprecated `ggplot2::aes_string()` in the interaction plot.
* Interactive Plotly widgets are no longer auto-printed in examples and vignettes, which avoids a headless-browser dependency and removed about 4 MB from the installed size.
* The `umbrella` adapter now centers the focal predictor before fitting with `cgam`: the umbrella cone construction in `cgam` is translation-sensitive, and with an all-positive covariate its mode search degenerates into a nearly constant fit that loses the increase-then-decrease peak, even on data with an unmistakable one. Centering makes the covariate range straddle zero and restores the intended shape; the shift is stored and re-applied to every prediction grid. The fitted response is unchanged by construction, because the shape term carries its own intercept.

# agriRank 0.12.0.9000

* Added explicit split-split hierarchy through `subsubplot=` and `np_splitsplit()`.
* Added explicit strip-plot declarations through `strip_a=`, `strip_b=` and `np_stripplot()`.
* Added design-specific ARTool/permuco strata for split-split and strip-plot workflows.
* Reworked multivariate analysis into the common `agri_multivariate_fit` class with MANOVA, MANOVA.wide and multRM routing plus table/report/export integration.
* Enforced environment inclusion in multi-environment models; `agri_multienv()` now injects the environment term (and, by default, treatment-by-environment interactions) when omitted.
* Added common reporting/export support for multivariate, ANCOVA, ordered-trend and power objects.
* `confint.agri_rank_fit()` now fails explicitly when an engine-specific confidence interval is unavailable instead of returning non-interval summaries.
* Updated package citation version and local validation runner default.

# agriRank 0.11.0.9000

## Integer-support nonparametric regression

- Added `discrete_kernel`, `unimodal_isotonic`, `umbrella`, and `integer_grid` regression pathways for integer-valued agronomic predictors such as plant counts and insect densities.
- Added explicit decision supports: observed integers, every integer in a range, or a custom set of admissible integers.
- Added `agri_integer_predict()`, `agri_integer_difference()`, `agri_integer_optimum()`, `agri_integer_efficiency()`, `agri_integer_threshold()`, `agri_integer_bootstrap()`, and `agri_integer_confset()`.
- Integer-support fits reject fractional predictions and decisions outside the declared support.
- Instantaneous derivatives are replaced by finite differences for integer-support fits.
- Added ordered-discrete kernels through `np`, unimodal isotonic regression through `Iso`, umbrella-order regression through `cgam`, and integer-grid decision projection for flexible continuous latent models.
- Added a dedicated state-of-the-art vignette, manual section, references, and validation tests for integer-support inference.

# agriRank 0.10.0.9000

## Conover multiple comparisons

- Added `agri_conover()` and `agri_pairs(method = "conover")`.
- Added Kruskal-type Conover all-pairs comparisons for independent one-way/CRD data.
- Added Friedman-type Conover all-pairs comparisons for complete unreplicated RCBD data while preserving blocks.
- Added raw and multiplicity-adjusted p-values to the unified output.
- Added explicit rejection of incomplete or replicated RCBD cells for the classical Friedman-Conover adapter.

## Nonparametric regression for Agronomy

- Added `agri_np_regression()`, `agri_np_predict()`, `agri_np_diagnostics()`, `agri_np_compare()`, `agri_np_derivative()`, `agri_np_optimum()`, `agri_np_bootstrap()`, `agri_np_plot()`, `agri_np_interactive()`, `agri_np_significance()`, and `agri_np_specification()`.
- Added LOESS, smoothing splines, mixed-data kernel regression, isotonic regression, and constrained quantile B-splines as the strict nonparametric core.
- Added Theil-Sen/Siegel median regression, quantile regression, GAM and shape-constrained GAM as explicitly labelled robust/semiparametric companions.
- Added design-aware block adjustment for compatible engines and explicit rejection when a selected engine would discard a declared block.
- Added cross-validated predictive comparison, numerical derivatives, descriptive fitted optima, block/cluster bootstrap bands, grouped curves, two-dimensional response surfaces, ggplot2 graphics and Plotly exploration.
- Added mixed-data kernel predictor significance testing through `np::npsigtest()` and a consistent nonparametric specification test for prespecified Gaussian linear/polynomial models through `np::npcmstest()`.
- Added safeguards preventing silently ignored shape constraints, unsupported observation weights, and automatic regression of repeated/longitudinal `agri_design` objects without a validated subject-dependence adapter.
- Added a 17th English vignette devoted to state-of-the-art nonparametric regression for agronomic gradients.
- Added three or more documented examples for every newly exported function and extended the double-verified reference library.

# agriRank 0.9.1.9000

## Documentation overhaul

- Replaced the initial vignette set with 16 English analytical vignettes.
- Added dedicated state-of-the-art coverage for factorial rank inference, pseudo-ranks, restricted permutation, repeated measurements, wild bootstrap, and incomplete repeated data.
- Added a complete integrated agronomic case study.
- Added one dedicated `.Rd` page and at least three examples for every exported function.
- Added a long-form English reference manual and documentation coverage manifest.
- Added double-verified bibliographic metadata and a verified RIS file.
- Documented the methodological boundary for blocked incomplete repeated measurements and the experimental status of the native wild-rank engine.
- Clarified that `agri_ancova()` currently implements a Freedman-Lane permutation adapter and does not claim the 2026 resampling NANCOVA method.

# agriRank 0.9.0.9000

- Added design-aware objects for CRD, RCBD, factorial, split-plot, repeated/longitudinal, multi-environment and multivariate workflows.
- Added adapters for rankFD, ARTool, permuco, nparLD and MANOVA.RM.
- Added native experimental WTS/ATS/MATS wild-bootstrap rank engine for incomplete repeated measurements following Amro, Konietschke & Pauly (2024).
- Added missingness characterization and all-available versus complete-subject sensitivity analysis.
- Added effect sizes, pairwise comparisons, native repeated max-T contrasts, CLD, batch workflows, simulation-based power, trend tests, ggplot2/Plotly graphics and report generation.
