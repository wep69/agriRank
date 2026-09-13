# Plant density response with an integer treatment

A simulated spacing trial with one to nine plants per hill evaluated in
six complete blocks. The treatment is a count: half a plant cannot be
sown, so the admissible decisions form an integer support rather than a
continuous range.

This is the reference data set for the integer-support workflow of
agriRank, from
[`agri_integer_predict`](https://wep69.github.io/agriRank/reference/agri_integer_predict.md)
to
[`agri_integer_confset`](https://wep69.github.io/agriRank/reference/agri_integer_confset.md).

## Usage

``` r
agri_density
```

## Format

A data frame with 54 rows and 3 variables:

- block:

  Factor with 6 levels, `B1` to `B6`. Complete block.

- plants:

  Integer. Plants per hill, from 1 to 9.

- yield:

  Numeric. Grain yield in Mg ha\\^{-1}\\.

## Details

The response increases up to six plants per hill and decreases
afterwards through intraspecific competition, so the curve is unimodal.
The generating model is \$\$y = 2.4 + 1.05\\\min(p, 6) - 0.082\\\min(p,
6)^2 - 0.28\\\max(p - 6, 0) + b + \varepsilon,\$\$ with block effects
\\b\\ between -0.30 and 0.28 Mg ha\\^{-1}\\ and \\\varepsilon \sim N(0,
0.21^2)\\.

The true continuous maximum does not fall on an integer. That is
deliberate: it shows why the discrete optimum must be obtained by
evaluating the admissible support instead of rounding a continuous
optimum.

The generating script is installed as `data-raw/make_datasets.R` in the
package sources.

## Source

Simulated for the package. Not a real experiment.

## See also

[`agri_dose`](https://wep69.github.io/agriRank/reference/agri_dose.md),
[`agri_surface`](https://wep69.github.io/agriRank/reference/agri_surface.md),
[`agri_integer_optimum`](https://wep69.github.io/agriRank/reference/agri_integer_optimum.md)

## Examples

``` r
# Example 1: the layout, and the integer nature of the treatment
data(agri_density)
str(agri_density)
#> 'data.frame':    54 obs. of  3 variables:
#>  $ block : Factor w/ 6 levels "B1","B2","B3",..: 1 1 1 1 1 1 1 1 1 2 ...
#>  $ plants: int  1 2 3 4 5 6 7 8 9 1 ...
#>  $ yield : num  2.63 4 4.6 5.08 5.24 ...
all(agri_density$plants == round(agri_density$plants))
#> [1] TRUE

# Example 2: the admissible decision support and the discrete optimum
fit <- agri_np_regression(yield ~ plants, agri_density, method = "integer_grid",
                          integer_base_method = "smoothing_spline",
                          predictor_support = "observed_integer")
fit$integer_support
#> [1] 1 2 3 4 5 6 7 8 9
agri_integer_optimum(fit)
#> agriRank integer-support optimum
#>   Objective: max
#>   Admissible support: {1, 2, 3, 4, 5, 6, 7, 8, 9}
#>   Optimal integer value(s): 6
#>   Fitted response: 5.65321

# Example 3: a unimodal engine on the same data
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
```
