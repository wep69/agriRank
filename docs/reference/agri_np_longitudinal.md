# Regression along a gradient measured repeatedly on the same units

Fits a response curve when each experimental unit is measured more than
once, entering the unit as a penalised random effect and making it the
resampling cluster for everything downstream.

## Usage

``` r
agri_np_longitudinal(formula, data, subject, time,
                     time_effect = c("smooth", "varying"), k = 10L, ...)
```

## Arguments

- formula:

  Regression formula, response on the left and the gradient plus any
  other predictors on the right. Do not put the time variable here; give
  it to `time`.

- data:

  Data frame in long form, one row per unit and occasion.

- subject:

  The unit measured repeatedly, as a name or a string: the plot, the
  pot, the animal.

- time:

  The occasion, as a name or a string.

- time_effect:

  How time enters. `"smooth"` gives it its own smooth, so the level of
  the response drifts over time but its shape does not. `"varying"` lets
  the shape of the gradient response differ between occasions, which is
  the interesting case and needs time to be a factor with enough
  observations per level.

- k:

  Basis dimension for the smooths.

- ...:

  Passed to
  [`agri_np_regression`](https://wep69.github.io/agriRank/reference/agri_np_regression.md).

## Details

A trial that measures the same plots at four dates has four rows per
plot, and analysing them as four independent observations inflates the
apparent replication fourfold. That is the error the repeated-measures
side of the package exists to prevent, and until 0.14.0 the regression
side had no equivalent.

The returned object is an ordinary `agri_np_reg_fit` whose `block` is
the subject. That is not a trick: the subject **is** the unit of
resampling, so every tool in the module then does the right thing
without knowing anything about repeated measurement.
[`agri_np_bootstrap`](https://wep69.github.io/agriRank/reference/agri_np_bootstrap.md)
resamples whole subjects,
[`agri_np_conformal`](https://wep69.github.io/agriRank/reference/agri_np_conformal.md)
splits by subject, and
[`agri_np_compare`](https://wep69.github.io/agriRank/reference/agri_np_compare.md)
with `cv_scope = "new_block"` holds out whole subjects, which is the
honest question: how well is a plot predicted that was never measured.

`block_effect = "shrunk"` is used, so subject effects are penalised
towards their common mean. With fixed subject effects a model with many
plots and few occasions each would spend most of its degrees of freedom
on nuisance.

**This is not a GAMM with a modelled within-subject correlation.**
Nothing here estimates an autocorrelation over time. The dependence is
handled by resampling whole subjects, which assumes nothing about its
form and, in exchange, cannot recover the efficiency that a correct
correlation model would. If the occasions are many and closely spaced,
say a weekly series over a season, a model that represents the
correlation is the better tool and this one will be conservative.

## Value

An `agri_np_reg_fit` with an extra `$longitudinal` component describing
the structure.

## See also

[`agri_repeated`](https://wep69.github.io/agriRank/reference/agri_repeated.md)
for the rank-based repeated-measures side,
[`agri_np_regression`](https://wep69.github.io/agriRank/reference/agri_np_regression.md),
[`agri_np_conformal`](https://wep69.github.io/agriRank/reference/agri_np_conformal.md).

## Examples

``` r
if (requireNamespace("mgcv", quietly = TRUE)) {
  set.seed(31)
  d <- expand.grid(N = seq(0, 200, 50), plot = factor(1:12), time = factor(1:3))
  d$yield <- 3 + 0.03 * d$N - 0.00009 * d$N^2 +
    as.numeric(d$plot) * 0.15 + as.numeric(d$time) * 0.4 + rnorm(nrow(d), 0, 0.25)

  # Example 1: the level drifts between occasions, the shape does not
  fit <- agri_np_longitudinal(yield ~ N, d, subject = plot, time = time, k = 4)
  fit

  # Example 2: every interval downstream now resamples whole plots, without
  # being told anything about repeated measurement
  agri_np_bootstrap(fit, B = 49, n = 25, seed = 1)

  # Example 3: the shape itself allowed to differ between occasions, which is
  # the question a multi-harvest trial usually asks
  agri_np_longitudinal(yield ~ N, d, subject = plot, time = time,
                       time_effect = "varying", k = 4)

  # Example 4: data that are not repeated measurements are refused rather than
  # given a random effect with one observation per level
  d1 <- d[!duplicated(d$plot), ]
  try(agri_np_longitudinal(yield ~ N, d1, subject = plot, time = time))
}
#> Warning: factor levels 1 not in original fit
#> Warning: factor levels 1 not in original fit
#> Warning: factor levels 1 not in original fit
#> Warning: factor levels 1 not in original fit
#> Warning: factor levels 1 not in original fit
#> Warning: factor levels 1 not in original fit
#> Warning: factor levels 1 not in original fit
#> Warning: factor levels 1 not in original fit
#> Warning: factor levels 1 not in original fit
#> Warning: factor levels 1 not in original fit
#> Warning: factor levels 1 not in original fit
#> Warning: factor levels 1 not in original fit
#> Warning: factor levels 1 not in original fit
#> Warning: factor levels 1 not in original fit
#> Warning: factor levels 1 not in original fit
#> Warning: factor levels 1 not in original fit
#> Warning: factor levels 1 not in original fit
#> Error : Every level of `plot` appears once, so these data are not repeated measurements. Use agri_np_regression() directly.
```
