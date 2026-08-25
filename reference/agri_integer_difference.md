# Finite differences for integer-valued agronomic decisions

Computes finite changes in fitted response rather than an instantaneous
derivative that has no direct operational interpretation for counts such
as plants or insects.

## Usage

``` r
agri_integer_difference(object, order = 1L, fixed = list())
```

## Arguments

- object:

  An integer-support regression fit.

- order:

  Difference order, 1 or 2.

- fixed:

  Named values for other covariates.

## Details

For adjacent admissible values \\x_j\<x\_{j+1}\\, the first finite
difference is \$\$\Delta \hat m_j = \hat m(x\_{j+1})-\hat m(x_j).\$\$
The function also reports the change per integer step. For unit-spaced
supports, the second difference is \$\$\Delta^2\hat m_j=\hat
m(x\_{j+1})-2\hat m(x_j)+\hat m(x\_{j-1}).\$\$

## Value

A data frame of first or second finite differences.

## Examples

``` r
data(agri_density)
fit <- agri_np_regression(yield ~ plants, agri_density, method = "integer_grid",
                          integer_base_method = "smoothing_spline",
                          predictor_support = "observed_integer")

# Example 1: the yield gain, in Mg/ha, of adding one more plant per hill
agri_integer_difference(fit, order = 1)
#>   from to delta_x fit_from   fit_to  difference difference_per_integer
#> 1    1  2       1 3.303982 4.201545  0.89756344             0.89756344
#> 2    2  3       1 4.201545 4.858834  0.65728887             0.65728887
#> 3    3  4       1 4.858834 5.348576  0.48974195             0.48974195
#> 4    4  5       1 5.348576 5.633219  0.28464302             0.28464302
#> 5    5  6       1 5.633219 5.653211  0.01999178             0.01999178
#> 6    6  7       1 5.653211 5.409864 -0.24334647            -0.24334647
#> 7    7  8       1 5.409864 5.130370 -0.27949453            -0.27949453
#> 8    8  9       1 5.130370 5.004565 -0.12580537            -0.12580537
# The row where the difference turns negative marks the density beyond which
# competition costs more than the extra plant contributes.

# Example 2: second differences, the rate at which that gain shrinks
agri_integer_difference(fit, order = 2)
#>   center fit_left fit_center fit_right second_difference
#> 1      2 3.303982   4.201545  4.858834       -0.24027457
#> 2      3 4.201545   4.858834  5.348576       -0.16754693
#> 3      4 4.858834   5.348576  5.633219       -0.20509892
#> 4      5 5.348576   5.633219  5.653211       -0.26465124
#> 5      6 5.633219   5.653211  5.409864       -0.26333825
#> 6      7 5.653211   5.409864  5.130370       -0.03614806
#> 7      8 5.409864   5.130370  5.004565        0.15368916
# Consistently negative second differences describe a concave response.

# Example 3: when only alternate densities were tested, `delta_x` is 2 and
# `difference_per_integer` rescales the gain to a single plant.
d2 <- subset(agri_density, plants %in% c(1, 3, 5, 7, 9))
fit2 <- agri_np_regression(yield ~ plants, d2, method = "integer_grid",
                           integer_base_method = "smoothing_spline",
                           predictor_support = "observed_integer")
agri_integer_difference(fit2, order = 1)
#>   from to delta_x fit_from   fit_to difference difference_per_integer
#> 1    1  3       2 3.282990 4.769071  1.4860811             0.74304054
#> 2    3  5       2 4.769071 5.556309  0.7872374             0.39361869
#> 3    5  7       2 5.556309 5.453706 -0.1026028            -0.05130141
#> 4    7  9       2 5.453706 5.062256 -0.3914496            -0.19572479
```
