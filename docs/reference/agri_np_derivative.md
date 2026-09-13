# Estimate the derivative of a fitted agronomic response curve

Computes a numerical first derivative of the fitted conditional-response
curve.

## Usage

``` r
agri_np_derivative(object, predictor = NULL, n = 200L, fixed = list(), h = NULL)
```

## Arguments

- object:

  An `agri_np_reg_fit`.

- predictor:

  Numeric focal predictor.

- n:

  Grid size.

- fixed:

  Named values at which other covariates are held.

- h:

  Finite-difference step; automatically selected by default.

## Details

Derivative estimates near boundaries use the available one-sided span.
Derivatives inherit all limitations of the fitted smoother and should be
interpreted with uncertainty, especially near sparse regions.

## Value

A data frame containing predictor values and estimated derivatives.

## Examples

``` r
data(agri_dose)
f <- agri_np_regression(yield ~ dose, agri_dose, method = "smoothing_spline")

# Example 1: marginal yield, in Mg/ha per kg/ha of nitrogen
head(agri_np_derivative(f))
#>   predictor        x derivative
#> 1      dose 0.000000 0.01598281
#> 2      dose 1.407035 0.01598149
#> 3      dose 2.814070 0.01597737
#> 4      dose 4.221106 0.01597042
#> 5      dose 5.628141 0.01596065
#> 6      dose 7.035176 0.01594805
# A positive derivative means the next kilogram of nitrogen still pays.

# Example 2: a finer evaluation grid
d50 <- agri_np_derivative(f, n = 50)
head(d50)
#>   predictor         x derivative
#> 1      dose  0.000000 0.01598281
#> 2      dose  5.714286 0.01595996
#> 3      dose 11.428571 0.01589057
#> 4      dose 17.142857 0.01577464
#> 5      dose 22.857143 0.01561215
#> 6      dose 28.571429 0.01540312

# Example 3: `h` is the step of the finite difference. A larger step smooths
# the derivative and can hide a local change of slope, so it should be chosen
# on the scale of the treatment, not by trial and error.
h_small <- agri_np_derivative(f, n = 25, h = 0.5)
h_large <- agri_np_derivative(f, n = 25, h = 20)
range(h_small$derivative)
#> [1] 0.002633966 0.015982775
range(h_large$derivative)
#> [1] 0.002702336 0.015888541
```
