# Discrete fitted-response and marginal-efficiency table

Summarizes fitted response, response relative to the fitted maximum, and
marginal gains between adjacent integer decisions.

## Usage

``` r
agri_integer_efficiency(object, fixed = list())
```

## Arguments

- object:

  An integer-support regression fit.

- fixed:

  Named values for other covariates.

## Details

The output is descriptive. Economic efficiency requires explicit prices
or costs and should not be inferred from biological response alone.

## Value

A data frame on the declared integer support.

## Examples

``` r
data(agri_density)
fit <- agri_np_regression(yield ~ plants, agri_density, method = "integer_grid",
                          integer_base_method = "smoothing_spline",
                          predictor_support = "observed_integer")

# Example 1: each admissible density as a fraction of the fitted maximum
agri_integer_efficiency(fit)
#>   plants fitted_response relative_to_fitted_maximum marginal_gain_from_previous
#> 1      1        3.303982                  0.5844434                          NA
#> 2      2        4.201545                  0.7432140                  0.89756344
#> 3      3        4.858834                  0.8594822                  0.65728887
#> 4      4        5.348576                  0.9461130                  0.48974195
#> 5      5        5.633219                  0.9964636                  0.28464302
#> 6      6        5.653211                  1.0000000                  0.01999178
#> 7      7        5.409864                  0.9569543                 -0.24334647
#> 8      8        5.130370                  0.9075143                 -0.27949453
#> 9      9        5.004565                  0.8852605                 -0.12580537
#>   gain_per_integer_from_previous marginal_gain_to_next gain_per_integer_to_next
#> 1                             NA            0.89756344               0.89756344
#> 2                     0.89756344            0.65728887               0.65728887
#> 3                     0.65728887            0.48974195               0.48974195
#> 4                     0.48974195            0.28464302               0.28464302
#> 5                     0.28464302            0.01999178               0.01999178
#> 6                     0.01999178           -0.24334647              -0.24334647
#> 7                    -0.24334647           -0.27949453              -0.27949453
#> 8                    -0.27949453           -0.12580537              -0.12580537
#> 9                    -0.12580537                    NA                       NA

# Example 2: the densest options
tail(agri_integer_efficiency(fit), 3)
#>   plants fitted_response relative_to_fitted_maximum marginal_gain_from_previous
#> 7      7        5.409864                  0.9569543                  -0.2433465
#> 8      8        5.130370                  0.9075143                  -0.2794945
#> 9      9        5.004565                  0.8852605                  -0.1258054
#>   gain_per_integer_from_previous marginal_gain_to_next gain_per_integer_to_next
#> 7                     -0.2433465            -0.2794945               -0.2794945
#> 8                     -0.2794945            -0.1258054               -0.1258054
#> 9                     -0.1258054                    NA                       NA

# Example 3: every density within 5 percent of the maximum. When several
# qualify, the cheapest to establish is a defensible operational choice.
subset(agri_integer_efficiency(fit), relative_to_fitted_maximum >= 0.95)
#>   plants fitted_response relative_to_fitted_maximum marginal_gain_from_previous
#> 5      5        5.633219                  0.9964636                  0.28464302
#> 6      6        5.653211                  1.0000000                  0.01999178
#> 7      7        5.409864                  0.9569543                 -0.24334647
#>   gain_per_integer_from_previous marginal_gain_to_next gain_per_integer_to_next
#> 5                     0.28464302            0.01999178               0.01999178
#> 6                     0.01999178           -0.24334647              -0.24334647
#> 7                    -0.24334647           -0.27949453              -0.27949453
```
