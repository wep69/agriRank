# Locate a descriptive optimum on a fitted nonparametric curve

Searches the fitted response surface along one predictor and reports the
grid maximum or minimum.

## Usage

``` r
agri_np_optimum(object, predictor = NULL, objective = c("max", 
    "min"), n = 500L, fixed = list(), range = NULL)
```

## Arguments

- object:

  An `agri_np_reg_fit`.

- predictor:

  Numeric predictor.

- objective:

  Search for maximum or minimum.

- n:

  Search-grid size.

- fixed:

  Values for other covariates.

- range:

  Optional search range.

## Details

This is a descriptive optimum of the chosen smoother. It is not an
economic optimum and should not replace a prespecified mechanistic or
parametric dose-response model when that model is scientifically
required. A boundary flag is returned.

## Value

One-row data frame with predictor, optimum, fitted response, objective
and boundary indicator.

## Examples

``` r
data(agri_dose)
f <- agri_np_regression(yield ~ dose, agri_dose, method = "smoothing_spline")

# Example 1: descriptive optimum over the observed nitrogen range
agri_np_optimum(f)
#>   predictor optimum fitted_response objective at_boundary    support
#> 1      dose     280        5.413311       max        TRUE continuous

# Example 2: restricted to an operationally feasible range
agri_np_optimum(f, range = c(40, 220))
#>   predictor optimum fitted_response objective at_boundary    support
#> 1      dose     220        5.249311       max        TRUE continuous

# Example 3: the minimum, useful when the response is a cost or a damage score
agri_np_optimum(f, objective = "min")
#>   predictor optimum fitted_response objective at_boundary    support
#> 1      dose       0        3.096659       min        TRUE continuous

# Example 4: an optimum without uncertainty is not a recommendation.
# Pair it with the bootstrap and report the interval, not only the point.
b <- agri_np_bootstrap(f, B = 199, seed = 1)   # use B >= 999 in analysis
opt <- agri_np_optimum(f)
opt
#>   predictor optimum fitted_response objective at_boundary    support
#> 1      dose     280        5.413311       max        TRUE continuous
utils::head(b)
#>       dose      fit    lower    upper
#> 1 0.000000 3.096659 2.732830 3.323162
#> 2 1.407035 3.119147 2.775147 3.340955
#> 3 2.814070 3.141631 2.809803 3.358746
#> 4 4.221106 3.164107 2.842988 3.376564
#> 5 5.628141 3.186571 2.876212 3.394476
#> 6 7.035176 3.209020 2.916603 3.412490
```
