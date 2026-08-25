# Is a declared shape compatible with the data

Tests whether imposing a monotonicity or curvature constraint distorts
the fit more than resampling alone would.

## Usage

``` r
agri_np_shape_test(object, shape = NULL, free_method = "gam",
                   B = 999L, seed = 1, cluster = NULL, parallel = FALSE)
```

## Arguments

- object:

  An `agri_np_reg_fit`. Either the constrained fit or the free one; the
  missing side is fitted internally.

- shape:

  The constraint to test. Defaults to the one already declared in
  `object`, and is required when `object` is unconstrained.

- free_method:

  Engine used for the unconstrained comparison. Defaults to `"gam"`,
  which is the closest free counterpart of `scam`.

- B:

  Bootstrap replicates.

- seed:

  Random seed.

- cluster:

  Resampling unit. Defaults to the declared block.

- parallel:

  Distribute the replicates over a `future` plan.

## Details

Imposing a shape buys precision when the shape is true and biases the
curve when it is not, and nothing in
[`agri_np_regression`](https://wep69.github.io/agriRank/reference/agri_np_regression.md)
checks which case applies. This function does.

The statistic is the mean squared distance between the constrained and
the free fit. Its null distribution is generated from the
**constrained** fit, because the null is that the constraint holds:
replicate responses are the constrained fitted values plus the residuals
multiplied by random signs drawn once per block.

A large p-value does not prove the shape. It says the data do not
contradict it, which is the most a test of this kind can say, and with
few blocks that is a weak statement. Read it together with
[`agri_np_sizer`](https://wep69.github.io/agriRank/reference/agri_np_sizer.md),
which shows where the free fit actually changes direction.

If the constrained fit has the smaller RMSE, which cannot happen by
optimisation, the two engines differ in more than the constraint and the
printed output says so. Compare like with like before reading the
p-value.

## Value

An object of class `agri_np_shape_test`.

## See also

[`agri_np_effect_test`](https://wep69.github.io/agriRank/reference/agri_np_effect_test.md),
[`agri_np_sizer`](https://wep69.github.io/agriRank/reference/agri_np_sizer.md),
[`agri_np_regression`](https://wep69.github.io/agriRank/reference/agri_np_regression.md)
for the `shape` argument itself.

## Examples

``` r
if (requireNamespace("mgcv", quietly = TRUE) &&
    requireNamespace("scam", quietly = TRUE)) {
  set.seed(21)
  d <- expand.grid(N = seq(0, 200, by = 50), block = factor(1:5), rep = 1:2)
  d$yield <- 3 + 0.030 * d$N - 0.00009 * d$N^2 +
    as.numeric(d$block) * 0.3 + rnorm(nrow(d), 0, 0.3)
  fit <- agri_np_regression(yield ~ N, d, method = "gam", block = block, k = 5)

  # Example 1: is the response compatible with rising and decelerating, which
  # is what agronomy expects of a nutrient? B small here for speed.
  agri_np_shape_test(fit, shape = "increasing_concave", B = 49, seed = 1)

  # Example 2: a constraint the data should contradict, since the response
  # turns over inside the tested range
  agri_np_shape_test(fit, shape = "increasing", B = 49, seed = 1)

  # Example 3: read it beside the SiZer, which shows where the free fit changes
  # direction rather than summarising the whole curve in one number
  if (requireNamespace("SiZer", quietly = TRUE)) {
    agri_np_significant_slope(agri_np_sizer(fit))
  }
}
#>   predictor stability increase_from increase_to stops_increasing_at
#> 1         N       0.8             0         110                 115
#>   decrease_from decrease_to
#> 1            NA          NA
```
