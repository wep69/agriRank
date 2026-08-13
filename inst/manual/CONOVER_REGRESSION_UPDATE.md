# agriRank 0.10.0.9000: Conover and Nonparametric Regression Update

## Conover audit and implementation

The pre-0.10 package mentioned Conover in planning documents but did not expose a Conover implementation. `agri_pairs()` used ordinary Wilcoxon comparisons outside the native repeated wild-rank path.

Version 0.10.0.9000 adds:

- `agri_conover()`;
- `agri_pairs(method = "conover")`;
- Kruskal-type Conover all-pairs comparisons for independent one-way/CRD layouts via `PMCMRplus::kwAllPairsConoverTest()`;
- Friedman-type Conover all-pairs comparisons for complete unreplicated RCBD layouts via `PMCMRplus::frdAllPairsConoverTest()`;
- factorial simple-effect comparisons through `by` and `factor`;
- raw and multiplicity-adjusted p-values;
- rejection of incomplete or replicated RCBD cells rather than silently applying the complete-block procedure;
- backend identity tests against direct PMCMRplus calls.

Balanced incomplete block designs are not yet a declared `agri_design` class. PMCMRplus provides a Conover-Iman/Durbin all-pairs procedure for BIBD, but agriRank intentionally does not route an object declared as RCBD to that method. A BIBD design class should be added before exposing that adapter.

## Comprehensive regression module

### Strictly nonparametric core

- LOESS/local polynomial regression;
- smoothing splines;
- mixed-data kernel regression (`np`), local-linear or local-constant;
- isotonic regression with explicitly declared increasing/decreasing direction;
- constrained quantile B-splines (`cobs`).

### Rank-robust and semiparametric companions

- Theil-Sen regression;
- Siegel repeated-median regression;
- conditional quantile regression (`quantreg`);
- generalized additive models (`mgcv`);
- shape-constrained additive models (`scam`).

These families are deliberately labelled rather than all being described as strictly nonparametric.

## Unified regression API

- `agri_np_regression()`
- `agri_np_predict()`
- `agri_np_diagnostics()`
- `agri_np_compare()`
- `agri_np_derivative()`
- `agri_np_optimum()`
- `agri_np_bootstrap()`
- `agri_np_plot()`
- `agri_np_interactive()`
- `agri_np_significance()`
- `agri_np_specification()`

## Agronomic design safeguards

- compatible engines preserve a declared block as a categorical nuisance adjustment;
- engines that cannot represent the block stop rather than dropping it;
- repeated/longitudinal `agri_design` objects stop because subject dependence is not yet represented by a validated regression adapter;
- unsupported observation weights stop rather than being ignored;
- shape constraints stop when the chosen engine would not enforce them;
- missing/non-finite modeled rows stop by default;
- `na_action = "complete"` is explicit complete-row analysis, records the omitted count, and is not described as imputation or a missing-data model.

## Agronomic response-curve outputs

- editable ggplot2 curves with observed data;
- residual plots;
- numerical first derivatives;
- descriptive fitted maxima/minima with boundary flags;
- bootstrap pointwise bands, using whole-block resampling by default when a block is declared;
- grouped conditional curves;
- two-dimensional response surfaces;
- Plotly conversion without refitting;
- tables, Markdown/Quarto reports, dashboards, and RDS reproducibility bundles.

## Inferential additions

### Kernel predictor significance

`agri_np_significance()` wraps `np::npsigtest()` for individual or joint significance of continuous, ordered, or unordered predictors. A declared block remains in the conditioning model by default and is not treated as a scientific target variable.

### Parametric functional-form specification

`agri_np_specification()` wraps `np::npcmstest()` for continuous Gaussian candidate models fitted with stored model matrices. It evaluates whether a prespecified linear/polynomial functional form is too restrictive relative to a flexible mixed-data alternative. Rejection does not identify a uniquely correct smoother.

## Documentation and tests

The package contains 17 English vignettes. The regression vignette covers state of the art, three integrated agronomic examples, kernel significance, specification testing, missing-row safeguards, response surfaces, grouped curves, block-aware workflows, reporting, and verified references.

Every exported function has a dedicated `.Rd` page and at least three documented examples. New tests cover Conover routing, backend identity, regression base engines, derivatives, optima, cross-validation, bootstrap, graphics, reporting, block inheritance, kernel significance, specification testing, missing-data behavior, and safeguards against ignored shape/weight/dependence structure.

## Runtime validation status

Static source, delimiter, vignette-fence, export-definition, alias, and documentation-coverage audits pass in the current environment. R/Rscript is not mounted in the current runtime, so numerical execution of `testthat`, `R CMD check --as-cran`, examples, vignettes, and backend equality tests remains pending until the Debian 13 R 4.6.1 runtime is re-uploaded.
