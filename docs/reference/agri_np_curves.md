# Overlay the fitted curves of several regression engines

Fits several regression engines to the same data and draws their fitted
curves on one figure, over the observed points.

## Usage

``` r
agri_np_curves(
  formula,
  data,
  methods = c("smoothing_spline", "loess", "gam"),
  block = NULL,
  n = 200L,
  ...
)
```

## Arguments

- formula:

  Regression formula with one response and one numeric predictor.

- data:

  Data frame.

- methods:

  Engines to overlay. Engines that fail to fit are skipped.

- block:

  Optional agronomic block, given as a character name, applied to every
  engine.

- n:

  Grid resolution.

- ...:

  Passed to
  [`agri_np_regression`](https://wep69.github.io/agriRank/reference/agri_np_regression.md).

## Details

The figure answers a question that a table of cross-validated errors
answers poorly: how different are these engines where it matters, on the
scale of the response? Engines that differ by a fraction of the residual
scale are not agronomically distinguishable, however their error metrics
are ordered.

Use it together with
[`agri_np_compare`](https://wep69.github.io/agriRank/reference/agri_np_compare.md),
which quantifies predictive error, and remember that neither is a way of
choosing an inferential method.

## Value

A `ggplot` object.

## See also

[`agri_np_compare`](https://wep69.github.io/agriRank/reference/agri_np_compare.md),
[`agri_np_plot`](https://wep69.github.io/agriRank/reference/agri_np_plot.md)

## Examples

``` r
data(agri_dose)

# Example 1: three smoothers on a nitrogen response
agri_np_curves(yield ~ dose, agri_dose,
               methods = c("smoothing_spline", "loess"))


# Example 2: adding a rank-robust straight line makes the contrast explicit
if (requireNamespace("mblm", quietly = TRUE)) {
  agri_np_curves(yield ~ dose, agri_dose,
                 methods = c("smoothing_spline", "loess", "theil_sen"))
  # The straight line cannot follow the plateau, which is visible at a glance.
}


# Example 3: every engine adjusted for the same declared block
if (requireNamespace("mgcv", quietly = TRUE)) {
  agri_np_curves(yield ~ dose, agri_dose, methods = c("gam", "quantile"),
                 block = "block")
}
#> Warning: Solution may be nonunique
```
