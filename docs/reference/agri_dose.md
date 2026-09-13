# Nitrogen response in a randomized complete block design

A simulated fertilizer trial with eight nitrogen rates evaluated in five
complete blocks. The response follows a quadratic-plateau shape, which
is the classical form of a fertilizer response curve: yield rises with
the rate, the increment shrinks, and beyond a plateau further nitrogen
adds nothing.

The data set exists so that the regression examples of agriRank share a
single, agronomically interpretable experiment instead of creating a
different throwaway data frame on every help page.

## Usage

``` r
agri_dose
```

## Format

A data frame with 40 rows and 3 variables:

- block:

  Factor with 5 levels, `B1` to `B5`. Complete block.

- dose:

  Numeric. Nitrogen rate in kg ha\\^{-1}\\, from 0 to 280 in steps of
  40.

- yield:

  Numeric. Grain yield in Mg ha\\^{-1}\\.

## Details

The generating model is \$\$y = 3.1 + 0.0182\\\min(d, 200) -
0.0000362\\\min(d, 200)^2 + b + \varepsilon,\$\$ with block effects
\\b\\ between -0.45 and 0.35 Mg ha\\^{-1}\\ and \\\varepsilon \sim N(0,
0.24^2)\\. The plateau at 200 kg ha\\^{-1}\\ means that no parametric
quadratic is correct over the whole range, which is exactly the
situation the nonparametric regression module is meant for.

The generating script is installed as `data-raw/make_datasets.R` in the
package sources.

## Source

Simulated for the package. Not a real experiment.

## See also

[`agri_density`](https://wep69.github.io/agriRank/reference/agri_density.md),
[`agri_surface`](https://wep69.github.io/agriRank/reference/agri_surface.md),
[`agri_np_regression`](https://wep69.github.io/agriRank/reference/agri_np_regression.md)

## Examples

``` r
# Example 1: the layout
data(agri_dose)
str(agri_dose)
#> 'data.frame':    40 obs. of  3 variables:
#>  $ block: Factor w/ 5 levels "B1","B2","B3",..: 1 1 1 1 1 1 1 1 2 2 ...
#>  $ dose : num  0 40 80 120 160 200 240 280 0 40 ...
#>  $ yield: num  2.61 3.43 3.8 4.42 4.63 ...
with(agri_dose, table(block, dose))
#>      dose
#> block 0 40 80 120 160 200 240 280
#>    B1 1  1  1   1   1   1   1   1
#>    B2 1  1  1   1   1   1   1   1
#>    B3 1  1  1   1   1   1   1   1
#>    B4 1  1  1   1   1   1   1   1
#>    B5 1  1  1   1   1   1   1   1

# Example 2: block-adjusted smooth response and its optimum
if (requireNamespace("mgcv", quietly = TRUE)) {
  fit <- agri_np_regression(yield ~ dose, agri_dose, method = "gam", block = block)
  agri_np_optimum(fit)
}
#>   predictor optimum fitted_response objective at_boundary    support
#> 1      dose     280        5.035595       max        TRUE continuous

# Example 3: declared as a quantitative RCBD, then analyzed
des <- agri_design(yield ~ dose, agri_dose, design = "rcbd",
                   block = block, quantitative = dose)
design_summary(des)
#> $design
#> [1] "rcbd"
#> 
#> $responses
#> [1] "yield"
#> 
#> $treatments
#> [1] "dose"
#> 
#> $blocks
#> [1] "block"
#> 
#> $subjects
#> NULL
#> 
#> $within
#> NULL
#> 
#> $whole_plot
#> NULL
#> 
#> $subplot
#> NULL
#> 
#> $subsubplot
#> NULL
#> 
#> $strip_a
#> NULL
#> 
#> $strip_b
#> NULL
#> 
#> $environment
#> NULL
#> 
#> $n_rows
#> [1] 40
#> 
#> $n_treatment_cells_observed
#> [1] 8
#> 
#> $missing_response
#> yield 
#>     0 
#> 
#> $randomization
#> [1] "Treatment combinations are randomized within blocks; block labels are not exchangeable with treatments."
#> 
#> $validation
#> $ok
#> [1] TRUE
#> 
#> $problems
#> [1] severity code     message 
#> <0 rows> (or 0-length row.names)
#> 
#> attr(,"class")
#> [1] "agri_validation"
#> 
```
