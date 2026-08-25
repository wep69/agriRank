# Tidy an agriRank fit into a data frame

`tidy()`, `glance()` and `augment()` methods in the sense of the broom
package, so that an agriRank result travels into a report through the
same vocabulary as any other model.

## Usage

``` r
agri_tidy(x, ...)

agri_glance(x, ...)

agri_augment(x, ...)
```

## Arguments

- x:

  An `agri_np_reg_fit` or an `agri_rank_fit`.

- ...:

  For a regression fit: `n`, the grid size for the tidied curve;
  `conf.int`, whether to add a cluster-bootstrap interval, which
  resamples and so is not free; `conf.level`; and for `agri_augment()`,
  `data` or `newdata`. Other arguments reach
  [`agri_np_bootstrap`](https://wep69.github.io/agriRank/reference/agri_np_bootstrap.md)
  or
  [`agri_np_predict`](https://wep69.github.io/agriRank/reference/agri_np_predict.md).

## Details

The broom generics are registered when broom is installed and are absent
otherwise, because broom is a suggestion rather than a dependency. The
`agri_*` functions documented here reach the same code without loading
broom at all.

`agri_tidy()` on a regression fit returns the **fitted curve**, one row
per grid point, not a coefficient table. Most of the sixteen engines
have no coefficients, and those that do have them for a spline basis
rather than for any quantity worth reporting. There is no `p.value`
column for the same reason: no test was performed. For a test use
[`agri_np_optimum_test`](https://wep69.github.io/agriRank/reference/agri_np_optimum_test.md),
[`agri_np_significance`](https://wep69.github.io/agriRank/reference/agri_np_significance.md),
or the rank-based side of the package, whose `agri_tidy()` does return
one row per term with a p-value.

`agri_augment()` without `data` or `newdata` uses the rows stored in the
fit, which is the only choice guaranteed to align with the fitted
values. A rank-based fit has no per-row fitted value to attach, and the
call is refused with a pointer to
[`agri_effects`](https://wep69.github.io/agriRank/reference/agri_effects.md).

## Value

A data frame.

## See also

[`agri_np_diagnostics`](https://wep69.github.io/agriRank/reference/agri_np_diagnostics.md)
for the fuller diagnostic summary,
[`agri_table`](https://wep69.github.io/agriRank/reference/agri_table.md)
and
[`agri_report`](https://wep69.github.io/agriRank/reference/agri_report.md)
for the package's own reporting path.

## Examples

``` r
data(agri_dose)
fit <- agri_np_regression(yield ~ dose, agri_dose, method = "smoothing_spline")

# Example 1: the fitted curve, one row per grid point
head(agri_tidy(fit, n = 25))
#>   term        x estimate
#> 1 dose  0.00000 3.096659
#> 2 dose 11.66667 3.282753
#> 3 dose 23.33333 3.466594
#> 4 dose 35.00000 3.645917
#> 5 dose 46.66667 3.818506
#> 6 dose 58.33333 3.982912

# Example 2: one row describing the whole fit
agri_glance(fit)
#>             method response  n n_omitted pseudo_r2 spearman_r2 effective_df
#> 1 smoothing_spline    yield 40         0 0.8255341   0.7245388     3.490987
#>        RMSE       MAE block spatial
#> 1 0.3623191 0.3128471  <NA>    none

# Example 3: the original rows with fitted values and residuals attached
head(agri_augment(fit))
#>   block dose yield  .fitted     .resid
#> 1    B1    0 2.612 3.096659 -0.4846589
#> 2    B1   40 3.426 3.720827 -0.2948267
#> 3    B1   80 3.797 4.263777 -0.4667765
#> 4    B1  120 4.423 4.688799 -0.2657988
#> 5    B1  160 4.634 4.991988 -0.3579881
#> 6    B1  200 4.947 5.185945 -0.2389450

# Example 4: the rank side tidies to one row per term, with a p-value, because
# there a test was actually performed. Note that the rank engines compare
# levels, so the rate enters as a factor rather than as a number; for the
# quantitative gradient itself, the regression side above is the right tool.
if (requireNamespace("ARTool", quietly = TRUE)) {
  d <- agri_dose
  d$rate <- factor(d$dose)
  des <- agri_design(yield ~ rate, d, design = "rcbd", block = "block")
  agri_tidy(agri_rank(des, method = "ART"))
}
#>   term statistic      p.value
#> 1 rate   38.8874 8.872411e-13
```
