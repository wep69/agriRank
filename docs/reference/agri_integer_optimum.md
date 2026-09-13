# Maximum or minimum on an integer decision support

Finds all fitted optima directly on the admissible integer support.

## Usage

``` r
agri_integer_optimum(object, objective = c("max", "min"),
  fixed = list(), tolerance = sqrt(.Machine$double.eps))
```

## Arguments

- object:

  An integer-support regression fit.

- objective:

  Search for the fitted maximum or minimum.

- fixed:

  Named values for other covariates.

- tolerance:

  Numerical tolerance for tied optima.

## Details

For support \\\mathcal{X}\_I\\, the maximizer is
\$\$x_I^\*=\arg\max\_{x\in\mathcal{X}\_I}\hat m(x),\$\$ with the
analogous definition for a minimum. This is not obtained by rounding a
continuous optimum.

## Value

An object of class `agri_integer_optimum` with all tied optimal
integers, the fitted best response, support, and boundary flag.

## Examples

``` r
data(agri_density)
fit <- agri_np_regression(yield ~ plants, agri_density, method = "integer_grid",
                          integer_base_method = "smoothing_spline",
                          predictor_support = "observed_integer")

# Example 1: the recommended density, obtained by evaluating every admissible
# integer, not by rounding a continuous optimum
agri_integer_optimum(fit)
#> agriRank integer-support optimum
#>   Objective: max
#>   Admissible support: {1, 2, 3, 4, 5, 6, 7, 8, 9}
#>   Optimal integer value(s): 6
#>   Fitted response: 5.65321

# Example 2: the minimum, for responses where less is better, such as a
# disease score or a damage index
agri_integer_optimum(fit, objective = "min")
#> agriRank integer-support optimum
#>   Objective: min
#>   Admissible support: {1, 2, 3, 4, 5, 6, 7, 8, 9}
#>   Optimal integer value(s): 1
#>   Fitted response: 3.30398
#>   Note: at least one optimum is at the support boundary.

# Example 3: a shape-constrained engine on the same data. Two engines that
# agree on the decision give more confidence than either alone.
if (requireNamespace("Iso", quietly = TRUE)) {
  fu <- agri_np_regression(yield ~ plants, agri_density,
                           method = "unimodal_isotonic",
                           predictor_support = "observed_integer")
  agri_integer_optimum(fu)
}
#> agriRank integer-support optimum
#>   Objective: max
#>   Admissible support: {1, 2, 3, 4, 5, 6, 7, 8, 9}
#>   Optimal integer value(s): 6
#>   Fitted response: 5.72267

# Example 4: a point optimum is not a recommendation. Report the bootstrap
# confidence set alongside it.
bt <- agri_integer_bootstrap(fit, B = 199, seed = 1)  # use B >= 999 in analysis
agri_integer_confset(bt, level = 0.95)
#> agriRank bootstrap confidence set for an integer optimum
#>   Level: 95%
#>   Set: {5, 6}
#>   Included bootstrap mass: 0.995
```
