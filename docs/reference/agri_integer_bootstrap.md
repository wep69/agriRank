# Bootstrap distribution of an integer optimum

Refits the regression in each bootstrap sample and searches only the
original admissible integer support.

## Usage

``` r
agri_integer_bootstrap(object, objective = c("max", "min"),
  B = 499L, seed = 1, cluster = NULL, fixed = list(),
  tolerance = sqrt(.Machine$double.eps))
```

## Arguments

- object:

  An integer-support regression fit.

- objective:

  Maximum or minimum.

- B:

  Bootstrap replications.

- seed:

  Reproducible seed.

- cluster:

  Optional cluster variable; defaults to the declared block.

- fixed:

  Named values for other covariates.

- tolerance:

  Tolerance for tied optima.

## Details

If replicate \\b\\ has fitted optimum
\$\$x_b^\*=\arg\max\_{x\in\mathcal{X}\_I}\hat m_b(x),\$\$ the empirical
bootstrap probabilities summarize uncertainty over actual admissible
decisions. When several integers tie in a replicate, its probability
mass is divided equally among them. Blocked fits use whole-block
resampling by default.

## Value

An object of class `agri_integer_bootstrap` containing probability mass
over the integer support and refit diagnostics.

## Examples

``` r
# B = 19 keeps the examples fast. Use B >= 999 for any reported decision.
data(agri_density)
fit <- agri_np_regression(yield ~ plants, agri_density, method = "integer_grid",
                          integer_base_method = "smoothing_spline",
                          predictor_support = "observed_integer")

# Example 1: probability mass over the admissible densities
boot_max <- agri_integer_bootstrap(fit, B = 19, seed = 1)
boot_max
#> agriRank bootstrap distribution of the integer optimum
#>   Objective: max
#>   Successful refits: 19 / 19
#>  plants probability
#>       1   0.0000000
#>       2   0.0000000
#>       3   0.0000000
#>       4   0.0000000
#>       5   0.1578947
#>       6   0.8421053
#>       7   0.0000000
#>       8   0.0000000
#>       9   0.0000000
# Each probability is the share of bootstrap refits in which that density was
# optimal. The mass sums to one over the admissible support.

# Example 2: the mass converted into a discrete confidence set
agri_integer_confset(boot_max, level = 0.80)
#> agriRank bootstrap confidence set for an integer optimum
#>   Level: 80%
#>   Set: {6}
#>   Included bootstrap mass: 0.8421

# Example 3: the minimum, for a response where less is better
boot_min <- agri_integer_bootstrap(fit, objective = "min", B = 19, seed = 2)
boot_min$probabilities
#>   plants probability
#> 1      1           1
#> 2      2           0
#> 3      3           0
#> 4      4           0
#> 5      5           0
#> 6      6           0
#> 7      7           0
#> 8      8           0
#> 9      9           0

# Example 4: resampling whole blocks, which preserves the randomization
# structure of the trial
boot_block <- agri_integer_bootstrap(fit, B = 19, seed = 3, cluster = "block")
boot_block$failures
#> [1] 0
```
