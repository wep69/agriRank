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
# A positive derivative means the next kilogram of nitrogen still pays.

# Example 2: a finer evaluation grid
d50 <- agri_np_derivative(f, n = 50)
head(d50)

# Example 3: `h` is the step of the finite difference. A larger step smooths
# the derivative and can hide a local change of slope, so it should be chosen
# on the scale of the treatment, not by trial and error.
h_small <- agri_np_derivative(f, n = 25, h = 0.5)
h_large <- agri_np_derivative(f, n = 25, h = 20)
range(h_small$derivative)
range(h_large$derivative)
```
