# Cluster-aware bootstrap confidence bands for agronomic regression

Refits the selected regression engine under row or cluster resampling
and returns pointwise percentile bands.

## Usage

``` r
agri_np_bootstrap(object, newdata = NULL, predictor = NULL, B = 499L, level = 0.95,
  seed = 1, cluster = NULL, n = 200L, fixed = list(),
  target = c("curve", "coefficients"),
  band = c("pointwise", "simultaneous"),
  keep_replicates = FALSE, parallel = FALSE)
```

## Arguments

- object:

  An `agri_np_reg_fit`.

- newdata:

  Prediction grid; generated automatically if omitted.

- predictor:

  Numeric focal predictor.

- B:

  Bootstrap replicates.

- level:

  Interval level.

- seed:

  Random seed.

- cluster:

  Optional resampling cluster. The declared block is used by default
  when available.

- n:

  Automatic grid size.

- fixed:

  Values for other covariates.

- parallel:

  Distribute the replicates over a `future` plan. Defaults to `FALSE`,
  and the default should stay `FALSE` for small problems: starting
  workers and shipping the data costs more than it saves below a few
  hundred replicates. Requires the future.apply package and a plan set
  by the user, for example `future::plan(future::multisession)`.

  The result does not depend on it. Each replicate is drawn from its own
  L'Ecuyer-CMRG substream, so replicate `b` is the same object whichever
  worker computes it and in whatever order, and a run with four cores
  gives the same interval as a run with one.

- target:

  `"curve"` resamples the fitted response over a grid; `"coefficients"`
  resamples the coefficient vector and is available only for the engines
  that define one.

- band:

  `"pointwise"` gives percentile limits at each grid point;
  `"simultaneous"` gives a sup-t band that covers the whole curve at the
  nominal level.

- keep_replicates:

  If `TRUE`, the matrix of replicates is stored in the `"replicates"`
  attribute, which allows a histogram of a slope, a cloud of fitted
  curves, or a custom band.

## Details

When a block or cluster is supplied, whole clusters are resampled, which
preserves the randomization structure of the trial. Large `B` should be
used for final inference.

By default the limits are *pointwise*: each grid point is covered at the
nominal level, but the probability that the whole curve lies inside the
band is lower. With `band = "simultaneous"` a sup-t band is returned,
which covers the entire curve at the nominal level and is therefore
wider. Report the pointwise band when a statement refers to one nitrogen
rate, and the simultaneous band when the statement refers to the shape
of the response.

With `target = "coefficients"` the resampled quantity is the coefficient
vector rather than the curve. This is available for `theil_sen`,
`siegel` and `quantile`; the other engines have no coefficients to
resample and are refused by
[`coef.agri_np_reg_fit`](https://wep69.github.io/agriRank/reference/agri_np_extractors.md).
Replicates are aligned by term name, so a replicate whose coefficient
vector is reordered or depleted , for example when a bootstrap sample
loses one level of a qualitative factor , is counted as a failed refit
instead of being read in the original order. Block adjustment terms are
excluded from the target: they are nuisance parameters whose meaning
changes with every draw of the blocks under cluster resampling, so a
block-adjusted fit reports intervals for the scientific coefficients of
the declared formula. See
[`agri_np_forest`](https://wep69.github.io/agriRank/reference/agri_np_forest.md)
for the corresponding figure.

## Value

For `target = "curve"`, a data frame with the prediction grid, the
original fitted curve and the bootstrap limits. For
`target = "coefficients"`, a data frame with term, estimate, lower and
upper. Bootstrap metadata is stored in attributes, and
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) draws the
result.

## Examples

``` r
# B = 19 keeps these examples fast. It is far too small for analysis: use
# B >= 999 for reporting and B >= 4999 for final work whenever feasible.
data(agri_dose)
f <- agri_np_regression(yield ~ dose, agri_dose, method = "smoothing_spline")

# Example 1: resampled uncertainty of the fitted curve
b1 <- agri_np_bootstrap(f, B = 19, n = 30)
head(b1)

# Example 2: uncertainty exactly at the rates under discussion
b2 <- agri_np_bootstrap(f, newdata = data.frame(dose = c(80, 160, 240)), B = 19)
b2
# The width of each interval, in Mg/ha, is what separates a recommendation
# from a point estimate.

# Example 3: block-aware bootstrap, which resamples whole blocks
if (requireNamespace("mgcv", quietly = TRUE)) {
  fb <- agri_np_regression(yield ~ dose, agri_dose, method = "gam", block = block)
  head(agri_np_bootstrap(fb, B = 19, n = 20))
  # Resampling complete blocks preserves the randomization structure of the
  # trial; resampling individual plots would not.
}

# Example 4: pointwise against simultaneous. The simultaneous band is wider
# because it must contain the whole curve, not each point separately.
bp <- agri_np_bootstrap(f, B = 19, n = 12, band = "pointwise")
bs <- agri_np_bootstrap(f, B = 19, n = 12, band = "simultaneous")
c(pointwise = mean(bp$upper - bp$lower), simultaneous = mean(bs$upper - bs$lower))

# Example 5: a bootstrap interval for a rank-robust slope
if (requireNamespace("mblm", quietly = TRUE)) {
  ts <- agri_np_regression(yield ~ dose, agri_dose, method = "theil_sen")
  agri_np_bootstrap(ts, target = "coefficients", B = 19, seed = 1)
}

# Example 6: keeping the replicates allows a histogram of the slope
if (requireNamespace("mblm", quietly = TRUE)) {
  bt <- agri_np_bootstrap(ts, target = "coefficients", B = 19, seed = 1,
                          keep_replicates = TRUE)
  slope <- attr(bt, "replicates")[2, ]
  summary(slope)
}

# Example 7: the band drawn as a figure
plot(bp)
```
