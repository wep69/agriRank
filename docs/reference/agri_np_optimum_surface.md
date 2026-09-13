# Joint optimum of a response surface in two predictors

Locates the pair of rates that jointly optimises the fitted surface, and
reports a bootstrap confidence region for that pair.

## Usage

``` r
agri_np_optimum_surface(object, predictors = NULL,
                        objective = c("max", "min"),
                        B = 499L, level = 0.95, seed = 1,
                        n = 40L, fixed = list(), ranges = NULL,
                        cluster = NULL, parallel = FALSE)
```

## Arguments

- object:

  An `agri_np_reg_fit` whose model contains both predictors, most
  naturally one fitted with `gam_structure = "tensor"`.

- predictors:

  Character vector of length two naming the numeric predictors to
  optimise jointly. Defaults to the first two numeric predictors.

- objective:

  `"max"` or `"min"`.

- B:

  Bootstrap replicates. Use at least 999 for anything reported.

- level:

  Confidence level of the region.

- seed:

  Random seed.

- n:

  Grid size per axis. The surface is evaluated on `n * n` points, so the
  cost is quadratic; 40 is usually enough to locate a smooth optimum.

- fixed:

  Values at which other covariates are held.

- ranges:

  Optional named list of two-element ranges, one per predictor.

- cluster:

  Resampling unit. Defaults to the declared block.

- parallel:

  Distribute the replicates over a `future` plan.

## Details

[`agri_np_optimum`](https://wep69.github.io/agriRank/reference/agri_np_optimum.md)
optimises one predictor with the others held fixed. Applied twice that
is not the top of the surface unless the two inputs act additively,
which is precisely what a factorial rate trial exists to test. Assuming
additivity in order to find the optimum is therefore circular, and a
surface the model has forced to be additive is refused with an
explanation.

**The reported region is not the rectangle of the two marginal
intervals.** The rectangle is also given, as `box_lower` and
`box_upper`, because it is what a reader expects to see, and it is
labelled so that it is not mistaken for the region. When the surface has
a ridge the two differ sharply: the cloud of resampled optima lies along
a diagonal, more of one input compensating for less of the other, and
the rectangle admits corners that no replicate ever visited. The rank
correlation between the two coordinates across replicates is reported
for the same reason, and `$region` holds the convex hull of the retained
replicates.

`p_boundary` is the share of replicates whose optimum lands on an edge
of the searched rectangle, and `identified` turns `FALSE` at one half,
exactly as in
[`agri_np_optimum_test`](https://wep69.github.io/agriRank/reference/agri_np_optimum_test.md).

## Value

An object of class `agri_np_optimum_surface`, a list with `optimum`,
`region`, `fitted_response`, `p_boundary`, `identified`,
`rank_correlation`, `replicates` and `surface`.

## See also

[`agri_np_optimum_test`](https://wep69.github.io/agriRank/reference/agri_np_optimum_test.md)
for one predictor,
[`agri_np_optimum_economic`](https://wep69.github.io/agriRank/reference/agri_np_optimum_economic.md)
for the price-aware rate,
[`agri_np_plot`](https://wep69.github.io/agriRank/reference/agri_np_plot.md)
with `type = "surface"` for the picture.

## Examples

``` r
if (requireNamespace("mgcv", quietly = TRUE)) {
  set.seed(5)
  d <- expand.grid(N = seq(0, 200, 50), P = seq(0, 60, 15), block = factor(1:3))
  d$yield <- 3 + 0.030 * d$N - 0.00013 * d$N^2 + 0.070 * d$P -
    0.0009 * d$P^2 - 0.00010 * d$N * d$P +
    as.numeric(d$block) * 0.2 + rnorm(nrow(d), 0, 0.15)

  # Example 1: the two inputs must be allowed to interact, or the joint optimum
  # carries no information the two separate optima do not.
  ft <- agri_np_regression(yield ~ N + P, d, method = "gam", block = block,
                           k = 4, gam_structure = "tensor")
  os <- agri_np_optimum_surface(ft, B = 99, seed = 1, n = 20)
  os

  # Example 2: the region, which is a hull of resampled optima rather than the
  # rectangle printed above it.
  head(os$region)

  # Example 3: an additive fit is refused, with the reason given.
  fa <- agri_np_regression(yield ~ N + P, d, method = "gam", block = block, k = 4)
  try(agri_np_optimum_surface(fa, B = 49, n = 12))
}
#> Error : The fitted surface is additive in `N` and `P`, so the optimum in each is the same at every level of the other and the joint optimum carries no information the two separate optima do not. Refit with `gam_structure = "tensor"`, which lets the two interact, or use agri_np_optimum() on each predictor and say that the surface was assumed additive.
```
