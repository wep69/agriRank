# Two-gradient response surface, nitrogen and irrigation depth

A simulated factorial of seven nitrogen rates by five irrigation depths
in two blocks. Both factors are quantitative, and they interact: the
return to nitrogen depends on how much water is available.

This is the reference data set for the response-surface and
multi-predictor examples of agriRank.

## Usage

``` r
agri_surface
```

## Format

A data frame with 70 rows and 4 variables:

- block:

  Factor with 2 levels, `B1` and `B2`.

- nitrogen:

  Numeric. Nitrogen rate in kg ha\\^{-1}\\, from 0 to 240 in steps of
  40.

- water:

  Numeric. Irrigation depth as a fraction of crop evapotranspiration,
  from 0.4 to 1.2.

- yield:

  Numeric. Grain yield in Mg ha\\^{-1}\\.

## Details

The generating model is \$\$y = 2.0 + 0.0165\\N - 0.0000402\\N^2 +
3.10\\W - 1.55\\W^2 + 0.0042\\NW + b + \varepsilon,\$\$ with
\\\varepsilon \sim N(0, 0.20^2)\\. The positive cross term is the
agronomic point of the data set: nitrogen pays more under adequate
irrigation, so the two gradients cannot be interpreted separately.

The generating script is installed as `data-raw/make_datasets.R` in the
package sources.

## Source

Simulated for the package. Not a real experiment.

## See also

[`agri_dose`](https://wep69.github.io/agriRank/reference/agri_dose.md),
[`agri_density`](https://wep69.github.io/agriRank/reference/agri_density.md),
[`agri_np_plot`](https://wep69.github.io/agriRank/reference/agri_np_plot.md)

## Examples

``` r
# Example 1: the factorial layout of the two gradients
data(agri_surface)
str(agri_surface)
#> 'data.frame':    70 obs. of  4 variables:
#>  $ block   : Factor w/ 2 levels "B1","B2": 1 1 1 1 1 1 1 1 1 1 ...
#>  $ nitrogen: num  0 0 0 0 0 40 40 40 40 40 ...
#>  $ water   : num  0.4 0.6 0.8 1 1.2 0.4 0.6 0.8 1 1.2 ...
#>  $ yield   : num  2.97 3.06 3.26 4.18 3.16 ...
with(agri_surface, table(nitrogen, water))
#>         water
#> nitrogen 0.4 0.6 0.8 1 1.2
#>      0     2   2   2 2   2
#>      40    2   2   2 2   2
#>      80    2   2   2 2   2
#>      120   2   2   2 2   2
#>      160   2   2   2 2   2
#>      200   2   2   2 2   2
#>      240   2   2   2 2   2

# Example 2: tensor-product surface
if (requireNamespace("mgcv", quietly = TRUE)) {
  fs <- agri_np_regression(yield ~ nitrogen + water, agri_surface,
                           method = "gam", gam_structure = "tensor")
  agri_np_diagnostics(fs)
}
#> $method
#> [1] "gam"
#> 
#> $metrics
#>    n      RMSE       MAE     MedAE         bias  Spearman
#> 1 70 0.1954774 0.1521025 0.1091312 2.245829e-15 0.9763116
#> 
#> $r2
#>   pseudo_r2 cv_r2 spearman_r2 effective_df  n
#> 1 0.9571312    NA   0.9531843     12.49079 70
#> 
#> $residual_median
#> [1] -0.02001611
#> 
#> $residual_MAD
#> [1] 0.1526794
#> 
#> $residual_fitted_spearman
#> [1] 0.05047473
#> 
#> $n_missing_response
#> [1] 0
#> 
#> $n_original
#> [1] 70
#> 
#> $n_omitted
#> [1] 0
#> 
#> $na_action
#> [1] "fail"
#> 
#> $details
#> $details$edf
#> [1] 12.49079
#> 
#> 

# Example 3: nitrogen response at a fixed irrigation depth
if (requireNamespace("mgcv", quietly = TRUE)) {
  agri_np_predict(fs, newdata = data.frame(nitrogen = c(0, 80, 160, 240),
                                           water = 1.0))
}
#> [1] 3.679993 4.942073 5.764386 6.292117
```
