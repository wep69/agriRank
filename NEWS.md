# agriRank 0.13.0

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
