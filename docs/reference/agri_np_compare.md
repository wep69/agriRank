# Cross-validated comparison of agronomic regression engines

Compares predictive accuracy by cross-validation without selecting an
inferential method by p-value.

## Usage

``` r
agri_np_compare(formula, data, methods = c("smoothing_spline", "loess", "kernel", "gam"),
  block = NULL, kfold = 5L, seed = 1, metric = c("RMSE", "MAE", "MedAE"),
  cv_scope = c("within_block", "new_block"), ...)
```

## Arguments

- formula:

  Regression formula.

- data:

  Data frame.

- methods:

  Character vector of regression engines.

- block:

  Optional block variable used to stratify folds.

- kfold:

  Number of folds.

- seed:

  Random seed.

- metric:

  Primary predictive-error metric.

- cv_scope:

  With a declared block, which question the validated error answers.
  `"within_block"` stratifies the folds, so every block appears in
  training and the estimate refers to another plot in a block already
  observed. `"new_block"` holds out whole blocks, which is the error of
  predicting where nothing was measured and the relevant one for a
  recommendation. The first is always the more flattering. Under
  `"new_block"` the block term is dropped from the fold models, since a
  block that was held out has no estimated effect and a model carrying
  it could only return `NA` for every held-out row.

- ...:

  Arguments passed to
  [`agri_np_regression()`](https://wep69.github.io/agriRank/reference/agri_np_regression.md).

## Details

With a declared block, `cv_scope` decides how the folds are formed, and
the two options answer different questions rather than one being more
accurate than the other. Stratified folds ask how well a plot in an
observed block is predicted; grouped folds ask how well an unobserved
block is predicted. This is the same distinction
[`agri_np_conformal`](https://wep69.github.io/agriRank/reference/agri_np_conformal.md)
exposes through its own `scope`.

The same fold rule is used by
[`agri_np_diagnostics`](https://wep69.github.io/agriRank/reference/agri_np_diagnostics.md)
when `cv = TRUE`, so the two cross-validation routines of the package
cannot report different validated errors for the same model.

Results rank predictive error only and do not establish that one method
has a more appropriate estimand or inferential null hypothesis.

## Value

A data frame ordered by the requested error metric.

## Examples

``` r
# Cross-validation compares predictive error. It does not test a hypothesis and
# must not be used to pick the engine with the smallest p-value.
data(agri_dose)

# Example 1: four engines on the nitrogen gradient, RMSE in Mg/ha
if (requireNamespace("mgcv", quietly = TRUE)) {
  agri_np_compare(yield ~ dose, agri_dose, kfold = 4, seed = 1,
                  methods = c("smoothing_spline", "loess", "gam", "quantile"))
}

# Example 2: median absolute error, less sensitive to a single bad plot
agri_np_compare(yield ~ dose, agri_dose, kfold = 4, seed = 1,
                methods = c("smoothing_spline", "loess"), metric = "MedAE")

# Example 3: keeping the agronomic block in every candidate model
if (requireNamespace("mgcv", quietly = TRUE)) {
  agri_np_compare(yield ~ dose, agri_dose, methods = c("gam", "quantile"),
                  block = block, kfold = 3, seed = 2)
  # A difference of a few hundredths of a Mg/ha between engines is not
  # agronomic evidence; prefer the engine justified by the design.
}
```
