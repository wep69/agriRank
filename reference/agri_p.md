# Extract the omnibus p-values of a fit

Reads the p-value of every tested effect without requiring the caller to
know which backend produced the fit. Each backend names its own column:
the car-style `Pr(>F)`, the `p-value` of MANOVA.RM, or the separated
`parametric P(>F)` and `resampled P(>F)` of permuco. Generic report code
that guesses the column name receives `NULL` instead of an error, which
is how an empty table passes unnoticed inside a long document.

## Usage

``` r
agri_p(x, which = c("primary", "parametric"))
```

## Arguments

- x:

  An `agri_rank_fit`, an `agri_ancova_fit`, or an omnibus data frame.

- which:

  `"primary"` for the canonical `p_value` column, `"parametric"` for the
  parametric p-value of a permutation backend.

## Details

The canonical column `p_value` holds the resampled p-value when the
engine resamples and the asymptotic p-value otherwise, because a
permutation engine was chosen for its permutation distribution.
`which = "parametric"` returns the parametric value that permuco reports
beside it, which shows how far the permutation distribution moved the
conclusion away from the F approximation. A backend that reports a
single p-value answers both requests with that value and says so in a
warning.

## Value

A data frame with columns `effect` and `p_value`.

## See also

`agri_rank`, `agri_table`, `agri_effects`

## Examples

``` r
set.seed(1)
d <- data.frame(trat = factor(rep(c("T1", "T2", "T3", "T4"), each = 8)))
d$y <- 10 + ifelse(d$trat == "T4", 1.5, 0) + stats::rnorm(nrow(d))
dg <- agri_design(y ~ trat, data = d, design = "crd")
fit <- agri_rank(dg, method = "kruskal")
agri_p(fit)
#>   effect   p_value
#> 1   trat 0.0169713

if (requireNamespace("permuco", quietly = TRUE)) {
  fp <- agri_rank(dg, method = "permuco", B = 999, seed = 1)
  agri_p(fp)
  agri_p(fp, which = "parametric")
}
#> Warning: The number of permutations is below 2000, p-values might be unreliable.
#>   effect     p_value
#> 1   trat 0.009941774
```
