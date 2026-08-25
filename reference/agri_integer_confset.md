# Bootstrap confidence set for an integer optimum

Constructs a highest-probability set made only of admissible integer
decisions.

## Usage

``` r
agri_integer_confset(bootstrap, level = 0.95)
```

## Arguments

- bootstrap:

  An `agri_integer_bootstrap` object.

- level:

  Requested bootstrap probability level.

## Details

Support points are ordered by bootstrap probability and added until the
requested cumulative mass is reached. The result is a discrete decision
set rather than a fractional confidence interval.

## Value

An object of class `agri_integer_confset`.

## Examples

``` r
# B = 19 keeps the examples fast. Use B >= 999 for any reported decision.
data(agri_density)
fit <- agri_np_regression(yield ~ plants, agri_density, method = "integer_grid",
                          integer_base_method = "smoothing_spline",
                          predictor_support = "observed_integer")
bt <- agri_integer_bootstrap(fit, B = 19, seed = 5)

# Example 1: the densities that together carry at least 80 percent of the
# bootstrap mass
agri_integer_confset(bt, level = 0.80)
#> agriRank bootstrap confidence set for an integer optimum
#>   Level: 80%
#>   Set: {5, 6}
#>   Included bootstrap mass: 1

# Example 2: a higher level admits more densities, exactly as a wider
# confidence interval covers more values
agri_integer_confset(bt, level = 0.90)
#> agriRank bootstrap confidence set for an integer optimum
#>   Level: 90%
#>   Set: {5, 6}
#>   Included bootstrap mass: 1

# Example 3: `hull` is the closed interval spanning the selected densities.
# It is convenient to report, but it may include an intermediate density that
# is not itself in the set, so the set remains the primary result.
cs <- agri_integer_confset(bt, level = 0.80)
cs$values
#> [1] 5 6
cs$hull
#> [1] 5 6
cs$probability_mass
#> [1] 1
```
