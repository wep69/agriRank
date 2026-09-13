# Several responses to one gradient, with a joint region for their optima

Fits one curve per response over the same gradient and reports the
optima with a **shared** cluster bootstrap, so that the correlation
between them survives into the joint region.

## Usage

``` r
agri_np_multiresponse(formula, data, block = NULL, objective = "max",
                      B = 499L, level = 0.95, seed = 1, n = 100L,
                      method = "gam", cluster = NULL, parallel = FALSE, ...)
```

## Arguments

- formula:

  A formula whose left-hand side names two or more responses, as
  `cbind(yield, protein) ~ rate`.

- data:

  Data frame.

- block:

  Optional block, which becomes the resampling unit.

- objective:

  One of `"max"` or `"min"`, recycled over the responses, or a vector
  with one entry per response. Yield is usually maximised and lodging
  minimised, so a single value is often wrong.

- B:

  Bootstrap replicates.

- level:

  Confidence level.

- seed:

  Random seed.

- n:

  Grid size.

- method:

  Engine, passed to
  [`agri_np_regression`](https://wep69.github.io/agriRank/reference/agri_np_regression.md).

- cluster:

  Resampling unit. Defaults to the declared block.

- parallel:

  Distribute the replicates over a `future` plan.

- ...:

  Passed to
  [`agri_np_regression`](https://wep69.github.io/agriRank/reference/agri_np_regression.md).

## Details

Nitrogen raises yield and lowers grain protein concentration, or raises
both but with optima far apart. Fitting two curves separately answers
each question and leaves the joint one untouched, because the two optima
are estimated from the same plots and their errors are correlated. Two
marginal intervals cannot express that: they describe a rectangle, and
the truth is usually a diagonal.

Every response is refitted on the same resampled blocks within a
replicate. Doing otherwise, which is what calling
[`agri_np_optimum_test`](https://wep69.github.io/agriRank/reference/agri_np_optimum_test.md)
twice amounts to, would give each response its own resampled experiment
and destroy exactly the dependence the joint question turns on.

The output carries three things a pair of separate analyses cannot:
`rank_correlation` between the resampled optima, `region`, the convex
hull of the replicate pairs when there are exactly two responses, and
the resampling distribution itself in `$replicates`.

**A joint region is not a compromise rate.** Choosing one rate for two
responses is a decision about their relative value, not a statistical
question, and this function deliberately does not make it. What it
supplies is how far apart the two optima are and how well that distance
is determined. Combine it with
[`agri_np_optimum_economic`](https://wep69.github.io/agriRank/reference/agri_np_optimum_economic.md)
on each response when prices are what decide.

## Value

An object of class `agri_np_multiresponse`.

## See also

[`agri_np_optimum_test`](https://wep69.github.io/agriRank/reference/agri_np_optimum_test.md),
[`agri_np_optimum_surface`](https://wep69.github.io/agriRank/reference/agri_np_optimum_surface.md)
for two predictors rather than two responses,
[`agri_multivariate`](https://wep69.github.io/agriRank/reference/agri_multivariate.md)
for the rank-based multivariate test.

## Examples

``` r
if (requireNamespace("mgcv", quietly = TRUE)) {
  set.seed(41)
  d <- expand.grid(N = seq(0, 200, 50), block = factor(1:5))
  d$yield   <- 3 + 0.040 * d$N - 0.00020 * d$N^2 +
    as.numeric(d$block) * 0.2 + rnorm(nrow(d), 0, 0.15)
  d$protein <- 9 + 0.026 * d$N - 0.00009 * d$N^2 +
    as.numeric(d$block) * 0.1 + rnorm(nrow(d), 0, 0.15)

  # Example 1: the two optima and, above all, the distance between them
  mr <- agri_np_multiresponse(cbind(yield, protein) ~ N, d, block = block,
                              B = 49, seed = 1, n = 60, k = 4)
  mr
  # The two rates differ by about 37 kg/ha. That difference, not either
  # optimum on its own, is what a joint recommendation has to face.

  # Example 2: the joint region, which is not the rectangle of the two
  # intervals printed above
  head(mr$region)

  # Example 3: one response maximised and one minimised, which a single
  # objective would get wrong
  d$lodging <- 20 + 0.10 * d$N + rnorm(nrow(d), 0, 2)
  agri_np_multiresponse(cbind(yield, lodging) ~ N, d, block = block,
                        objective = c("max", "min"), B = 49, seed = 1,
                        n = 40, k = 4)
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
#> Optima of several responses to N, from one shared bootstrap
#>   Resampling unit: whole levels of `block`   B = 49   level = 0.95
#> 
#>  response objective optimum lower upper replicates
#>     yield       max   97.44 97.44 102.6         28
#>   lodging       min    0.00  0.00   0.0         28
#> 
#>   Only 57% of replicates were usable. Resampling whole blocks
#>   sometimes omits one, and a refit that never saw a block cannot predict
#>   for it. Raise B to keep the same effective number of replicates.
#> 
#> Distance between optima, both from the same resampled experiment:
#> 
#>         contrast difference lower upper p_value rank_correlation replicates
#>  yield - lodging      97.44 97.44 102.6 0.06897               NA         28
#> 
#>   A joint region is not a compromise rate. Choosing one rate for two
#>   responses is a decision about their relative value, not a statistical
#>   question, and this function does not make it.
```
