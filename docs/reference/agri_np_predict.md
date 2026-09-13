# Predict from an agriRank nonparametric regression

Provides a common prediction interface across all regression engines.

## Usage

``` r
agri_np_predict(object, newdata = NULL,
                interval = c("none", "confidence", "prediction"),
                level = 0.95, scope = NULL,
                extrapolation = c("warn", "error", "allow"),
                extrapolation_tol = 0.1, ...)
```

## Arguments

- object:

  An `agri_np_reg_fit`.

- newdata:

  Prediction data; training data by default.

- interval:

  One of `"none"`, `"confidence"` or `"prediction"`. A confidence
  interval covers the mean response at a covariate setting. A prediction
  interval covers the next individual plot, which is what a
  recommendation needs, and is always wider; it is produced by split
  conformal prediction through
  [`agri_np_conformal`](https://wep69.github.io/agriRank/reference/agri_np_conformal.md)
  and so carries a finite-sample marginal coverage guarantee rather than
  a distributional assumption.

- level:

  Confidence level.

- scope:

  Required when `interval = "prediction"` and the fit declares a block.
  `"within_block"` covers a new plot in a block already observed;
  `"new_block"` covers a plot in a block not seen before, and is wider.
  The two answer different questions, so there is no default worth
  guessing on the user's behalf.

- extrapolation:

  One of `"warn"`, `"error"` or `"allow"`. A smoother carries no
  information beyond the range of the data it saw: outside its support
  the returned value describes the chosen basis, not the experiment.
  With `"warn"` the prediction is returned together with a warning and
  an `extrapolated` flag; with `"error"` a request that leaves the
  observed envelope by more than `extrapolation_tol` of its width is
  refused.

- extrapolation_tol:

  Fraction of the observed range of a numeric predictor that a request
  may fall outside before `"error"` refuses it. Defaults to 0.1.

- ...:

  Passed to
  [`agri_np_conformal`](https://wep69.github.io/agriRank/reference/agri_np_conformal.md)
  when `interval = "prediction"`.

## Details

Standardized analytic confidence intervals are currently exposed for
GAM, SCAM, COBS, umbrella and smooth-quantile engines. For the others,
use
[`agri_np_bootstrap`](https://wep69.github.io/agriRank/reference/agri_np_bootstrap.md)
for resampling-based uncertainty.

Rows that leave the fitted range are flagged in an `extrapolated` column
when the return is a data frame, and in an attribute of the same name
when the engine returns a bare numeric vector. Cross-validation and
bootstrap loops are exempt from the check, because held-out folds and
resampled replicates leave the training range by construction.

## Value

A numeric vector, matrix, or data frame with fitted values and, when
requested, interval limits. With `interval = "prediction"` the return is
an `agri_np_conformal` object, which carries the calibration size and
the achieved quantile as attributes.

## See also

[`agri_np_conformal`](https://wep69.github.io/agriRank/reference/agri_np_conformal.md)
for the prediction interval on its own terms,
[`agri_np_bootstrap`](https://wep69.github.io/agriRank/reference/agri_np_bootstrap.md)
for resampling-based bands.

## Examples

``` r
data(agri_dose)
fit <- agri_np_regression(yield ~ dose, agri_dose, method = "smoothing_spline")

# Example 1: the default prediction grid over the observed range
head(agri_np_predict(fit))
#> [1] 3.096659 3.720827 4.263777 4.688799 4.991988 5.185945

# Example 2: yield, in Mg/ha, at nitrogen rates a grower would consider
agri_np_predict(fit, data.frame(dose = c(0, 80, 160, 240)))
#> [1] 3.096659 4.263777 4.991988 5.302895

# Example 3: with a confidence interval, which covers the mean response.
# The fit adjusts for block, so the prediction data must state the block at
# which the prediction is intended.
if (requireNamespace("mgcv", quietly = TRUE)) {
  g <- agri_np_regression(yield ~ dose, agri_dose, method = "gam", block = block)
  nd <- data.frame(dose = c(80, 160, 240),
                   block = factor("B3", levels = levels(agri_dose$block)))
  agri_np_predict(g, nd, interval = "confidence")
  # If the intervals at 160 and 240 kg/ha overlap, the data do not separate
  # those two rates, whatever the point estimates suggest.
}
#>        fit    lower    upper
#> 1 4.307779 4.122521 4.493038
#> 2 5.019002 4.835799 5.202206
#> 3 5.243916 5.056318 5.431513

# Example 4: a prediction interval, which covers the next plot rather than the
# mean, and is the quantity a recommendation needs. It is always wider.
if (requireNamespace("mgcv", quietly = TRUE)) {
  agri_np_predict(g, nd, interval = "prediction", scope = "within_block",
                  seed = 1)
}
#> agriRank split-conformal prediction intervals
#>   Target coverage: 95% 
#>   Split unit: block 
#>   Scope: a future plot in an observed block 
#>   Fitting rows: 20  Calibration rows: 20 
#>   Conformal quantile: 0.4667  
#> 
#>  dose block   fit lower upper
#>    80    B3 4.308 3.841 4.774
#>   160    B3 5.019 4.552 5.486
#>   240    B3 5.244 4.777 5.711
#> 
#> The interval covers a future plot, not the fitted curve, and the coverage
#> is marginal over the gradient rather than guaranteed at each single rate.

# Example 5: omitting the block is refused, with the variable named
if (requireNamespace("mgcv", quietly = TRUE)) {
  try(agri_np_predict(g, data.frame(dose = 160)))
}
#> Error : `newdata` is missing the variable(s) used by the fitted model: block. Supply a value for each, for example the block level at which the prediction is intended.

# Example 6: asking beyond the tested range is refused rather than answered.
# The trial went to 240 kg/ha; 600 is not an estimate, it is the basis talking.
try(agri_np_predict(fit, data.frame(dose = 600), extrapolation = "error"))
#> Error : `newdata` leaves the range of the data the smoother was fitted to: dose outside [0, 280]. A nonparametric fit carries no information beyond its support, so a value returned there describes the basis rather than the experiment. The request exceeds `extrapolation_tol` = 0.1. Use `extrapolation = "warn"` to obtain it anyway, and do not report it as an estimate.
```
