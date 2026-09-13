# Economic optimum of a fitted response curve

Locates the input rate at which the marginal physical product, valued at
the price of the produce, equals the price of the input, and reports a
cluster-bootstrap interval for that location.

## Usage

``` r
agri_np_optimum_economic(object, price_ratio, by = NULL,
                         B = 999L, level = 0.95, seed = 1,
                         n = 200L, fixed = list(), range = NULL,
                         cluster = NULL,
                         adjust = c("holm", "none", "BH", "bonferroni",
                                    "hochberg", "hommel", "BY"),
                         parallel = FALSE)
```

## Arguments

- object:

  An `agri_np_reg_fit` from
  [`agri_np_regression`](https://wep69.github.io/agriRank/reference/agri_np_regression.md).

- price_ratio:

  The price of one unit of input divided by the price of one unit of
  produce, in the units of the fitted model. If nitrogen costs 1.20
  currency units per kg and grain sells for 0.30 per kg, the ratio is 4,
  and the optimum is where the last kilogram of nitrogen returns four
  kilograms of grain. `price_ratio = 0` reduces to the agronomic
  optimum, which is a useful check rather than a recommendation. A
  vector is accepted and read as a sensitivity analysis.

- by:

  Optional qualitative predictor whose levels are compared, as a name or
  a string. The model must let the shape differ between levels.

- B:

  Bootstrap replicates. Use at least 999 for anything reported.

- level:

  Confidence level of the interval for the optimum.

- seed:

  Random seed.

- n:

  Grid size on which the root is located.

- fixed:

  Values at which other covariates are held.

- range:

  Optional two-element range of the predictor to search within.

- cluster:

  Resampling unit. Defaults to the declared block, which keeps whole
  blocks together. Pass `NA` to resample individual rows, which is only
  legitimate for a completely randomized layout.

- adjust:

  Multiplicity adjustment across the pairwise contrasts produced by
  `by`, applied within each price ratio.

- parallel:

  Distribute the replicates over a `future` plan. The answer does not
  depend on it.

## Details

[`agri_np_optimum`](https://wep69.github.io/agriRank/reference/agri_np_optimum.md)
returns the top of the curve. That is the agronomic optimum, and it is
almost never the rate to apply: the last increments of input buy less
produce than they cost. The economic optimum solves \$\$\frac{\partial
y}{\partial x} = r,\$\$ where \\r\\ is the price ratio. It always lies
below the agronomic optimum on a concave response, and the difference
between them is frequently the whole margin of the field.

The root is taken at the first crossing from above, because up to that
point another unit of input still pays for itself.

What is resampled is the **location** of that root, not the height of
the curve, and the two are very different quantities: a response that
flattens has a well estimated curve and a root that wanders over a wide
stretch of the gradient. `p_boundary` reports the share of replicates
whose root lands on an end of the searched range, and `identified` turns
`FALSE` when that share reaches one half, at which point there is no
rate to report.

The price ratio is treated as known. It is not: prices move, and the
sensitivity of the recommendation to the ratio is usually larger than
its statistical uncertainty. Supplying a vector of ratios and reading
the table as a sensitivity analysis is the honest use.

## Value

An object of class `agri_np_optimum_economic`, a list with `optimum`,
`contrasts`, `curve`, `agronomic` and `replicates`.

## See also

[`agri_np_optimum`](https://wep69.github.io/agriRank/reference/agri_np_optimum.md)
for the agronomic optimum,
[`agri_np_optimum_test`](https://wep69.github.io/agriRank/reference/agri_np_optimum_test.md)
for its interval,
[`agri_np_derivative`](https://wep69.github.io/agriRank/reference/agri_np_derivative.md)
for the marginal product itself,
[`agri_integer_threshold`](https://wep69.github.io/agriRank/reference/agri_integer_threshold.md)
when the decision is an integer.

## References

Cerrato, M. E. and Blackmer, A. M. (1990). Comparison of models for
describing corn yield response to nitrogen fertilizer. *Agronomy
Journal*, 82(1), 138-143.

## Examples

``` r
data(agri_dose)
if (requireNamespace("mgcv", quietly = TRUE)) {
  fit <- agri_np_regression(yield ~ dose, agri_dose, method = "gam",
                            block = block, k = 5)

  # Example 1: the agronomic optimum, for comparison. It is the top of the
  # curve, and applying it means paying for input that does not return its cost.
  agri_np_optimum(fit)

  # Example 2: the economic optimum at one price ratio. B is small here for
  # speed; use at least 999 for anything reported.
  agri_np_optimum_economic(fit, price_ratio = 0.006, B = 99, seed = 1)

  # Example 3: prices move more than the resampling interval does. Read this as
  # the sensitivity analysis it is, not as four separate recommendations.
  agri_np_optimum_economic(fit, price_ratio = c(0.002, 0.006, 0.012),
                           B = 99, seed = 1)

  # Example 4: with price_ratio = 0 the function must return the agronomic
  # optimum. It is a check on the solver, not a recommendation.
  agri_np_optimum_economic(fit, price_ratio = 0, B = 99, seed = 1)$optimum
}
#>   price_ratio level optimum    lower upper fitted_response p_boundary
#> 1           0   all     280 250.6849   280        5.023068  0.9322034
#>   replicates identified
#> 1         59      FALSE
```
