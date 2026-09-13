# Standard extractors for agriRank regression fits

Fitted values, residuals, coefficients and coefficient confidence
intervals for a fitted regression.

## Usage

``` r
# S3 method for class 'agri_np_reg_fit'
coef(object, ...)

# S3 method for class 'agri_np_reg_fit'
confint(
  object,
  parm = NULL,
  level = 0.95,
  method = c("auto", "backend", "bootstrap"),
  B = 999L,
  seed = 1,
  ...
)

# S3 method for class 'agri_np_reg_fit'
fitted(object, ...)

# S3 method for class 'agri_np_reg_fit'
residuals(object, ...)
```

## Arguments

- object:

  An `agri_np_reg_fit`.

- parm:

  Optional subset of coefficient names.

- level:

  Confidence level.

- method:

  `"backend"` uses the interval exposed by the fitting package,
  `"bootstrap"` resamples the data, and `"auto"` tries the backend
  first.

- B:

  Bootstrap replicates when resampling is used.

- seed:

  Random seed for the bootstrap.

- ...:

  Unused.

## Details

A fitted curve always has fitted values and residuals, so
[`fitted()`](https://rdrr.io/r/stats/fitted.values.html) and
[`residuals()`](https://rdrr.io/r/stats/residuals.html) work for every
engine.

Coefficients are different. They exist only when the engine defines a
finite parameter vector with an interpretation, which here means
`theil_sen`, `siegel` and `quantile`. For a smoothing spline, a LOESS or
a GAM, [`coef()`](https://rdrr.io/r/stats/coef.html) fails on purpose:
returning basis coefficients as if they were agronomic slopes would
invite a reading the model does not support. Describe those fits with
[`agri_np_predict`](https://wep69.github.io/agriRank/reference/agri_np_predict.md),
[`agri_np_derivative`](https://wep69.github.io/agriRank/reference/agri_np_derivative.md)
or
[`agri_np_optimum`](https://wep69.github.io/agriRank/reference/agri_np_optimum.md)
instead.

[`confint()`](https://rdrr.io/r/stats/confint.html) prefers the interval
published by the backend and falls back to the cluster-aware bootstrap
of
[`agri_np_bootstrap`](https://wep69.github.io/agriRank/reference/agri_np_bootstrap.md).
The two usually differ, and the difference is informative: the backend
interval relies on the asymptotic theory of that estimator, while the
bootstrap interval only assumes that resampling the experimental units
is legitimate.

For a fit with qualitative predictors,
[`coef()`](https://rdrr.io/r/stats/coef.html) returns one coefficient
per non-reference level of each factor, beside the intercept and the
numeric slopes;
[`agri_np_forest`](https://wep69.github.io/agriRank/reference/agri_np_forest.md)
displays those coefficients with bootstrap intervals one level per row.
For a block-adjusted fit, the bootstrap route reports the scientific
coefficients of the declared formula: block adjustment terms are
nuisance parameters and are excluded from the resampled target.

## Value

[`coef()`](https://rdrr.io/r/stats/coef.html) a named numeric vector;
[`confint()`](https://rdrr.io/r/stats/confint.html) a data frame with
term, estimate, lower, upper and the method used;
[`fitted()`](https://rdrr.io/r/stats/fitted.values.html) and
[`residuals()`](https://rdrr.io/r/stats/residuals.html) named numeric
vectors.

## See also

[`agri_np_regression`](https://wep69.github.io/agriRank/reference/agri_np_regression.md),
[`agri_np_bootstrap`](https://wep69.github.io/agriRank/reference/agri_np_bootstrap.md),
[`agri_np_diagnostics`](https://wep69.github.io/agriRank/reference/agri_np_diagnostics.md)

## Examples

``` r
data(agri_dose)

# Example 1: a rank-robust slope, in Mg/ha per kg/ha of nitrogen
if (requireNamespace("mblm", quietly = TRUE)) {
  ts <- agri_np_regression(yield ~ dose, agri_dose, method = "theil_sen")
  coef(ts)
  confint(ts, method = "backend")
}
#>          term    estimate       lower       upper  method
#> 1 (Intercept) 3.382166667 3.301833333 3.610166667 backend
#> 2        dose 0.008008333 0.007473584 0.008547857 backend

# Example 2: the same slope with a bootstrap interval, which makes fewer
# assumptions and is usually wider
if (requireNamespace("mblm", quietly = TRUE)) {
  confint(ts, method = "bootstrap", B = 199, seed = 1)
}
#>          term    estimate       lower       upper    method
#> 1 (Intercept) 3.382166667 3.176962500 3.873296429 bootstrap
#> 2        dose 0.008008333 0.005879042 0.009230208 bootstrap

# Example 3: a smoothing spline has no slope to report, and says so
ss <- agri_np_regression(yield ~ dose, agri_dose, method = "smoothing_spline")
length(fitted(ss))
#> [1] 40
length(residuals(ss))
#> [1] 40
try(coef(ss))
#> Error : Method `smoothing_spline` does not define interpretable regression coefficients. It estimates a curve, not a finite parameter vector. Use agri_np_predict(), agri_np_derivative() or agri_np_optimum() to describe the fitted response, and coef() only with theil_sen, siegel, quantile.
```
