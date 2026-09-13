# Practical thresholds on an integer agronomic support

Finds the smallest admissible integer satisfying a prespecified
biological or operational criterion.

## Usage

``` r
agri_integer_threshold(object,
  criterion = c("fraction_of_maximum", "gain_from_baseline", "marginal_gain"),
  value = 0.95, baseline = NULL, fixed = list())
```

## Arguments

- object:

  An integer-support regression fit.

- criterion:

  Practical threshold definition.

- value:

  Criterion-specific target.

- baseline:

  Baseline integer for gain-from-baseline inference.

- fixed:

  Named values for other covariates.

## Details

For the fraction-of-maximum criterion,
\$\$x\_\rho=\min\\x\in\mathcal{X}\_I:\hat m(x)\ge
\rho\max\_{s\in\mathcal{X}\_I}\hat m(s)\\.\$\$ The other criteria use an
absolute gain from a declared baseline or the first marginal gain no
larger than a chosen threshold.

## Value

A one-row data frame containing the selected integer decision when the
criterion is attained.

## Examples

``` r
data(agri_density)
fit <- agri_np_regression(yield ~ plants, agri_density, method = "integer_grid",
                          integer_base_method = "smoothing_spline",
                          predictor_support = "observed_integer")

# Example 1: the smallest density reaching 95 percent of the fitted maximum
agri_integer_threshold(fit, "fraction_of_maximum", value = 0.95)
#>             criterion target integer_value fitted_response threshold_response
#> 1 fraction_of_maximum   0.95             5        5.633219            5.37055

# Example 2: the density recovering 90 percent of the total gain available
# above the lowest tested density
agri_integer_threshold(fit, "gain_from_baseline", value = 0.90, baseline = 1)
#>            criterion target baseline integer_value fitted_response
#> 1 gain_from_baseline    0.9        1             3        4.858834
#>   achieved_gain
#> 1      1.554852

# Example 3: the density beyond which one more plant adds less than
# 0.10 Mg/ha, a criterion stated in the unit of the response
agri_integer_threshold(fit, "marginal_gain", value = 0.10)
#>       criterion target integer_value marginal_gain_per_integer
#> 1 marginal_gain    0.1             6                0.01999178

# Example 4: the three criteria answer different agronomic questions and can
# select different densities. Each returns the columns that make sense for it,
# so compare the selected decision rather than binding the tables.
data.frame(
  criterion = c("fraction_of_maximum", "gain_from_baseline", "marginal_gain"),
  plants = c(
    agri_integer_threshold(fit, "fraction_of_maximum", value = 0.95)$integer_value,
    agri_integer_threshold(fit, "gain_from_baseline", value = 0.90, baseline = 1)$integer_value,
    agri_integer_threshold(fit, "marginal_gain", value = 0.10)$integer_value
  )
)
#>             criterion plants
#> 1 fraction_of_maximum      5
#> 2  gain_from_baseline      3
#> 3       marginal_gain      6
# The choice among them belongs to the agronomist and must be stated before
# looking at the data.
```
