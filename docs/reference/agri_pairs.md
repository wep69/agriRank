# Compute pairwise treatment comparisons

Provides ordinary pairwise Wilcoxon comparisons, design-aware Conover
comparisons, or simultaneous maxT comparisons for the native repeated
wild-rank engine.

## Usage

``` r
agri_pairs(
  x,
  by = NULL,
  factor = NULL,
  method = c("wilcoxon", "conover"),
  adjust = "holm",
  B = NULL,
  seed = NULL,
  level = 0.95,
  cld = FALSE,
  alpha = 0.05
)
```

## Arguments

- x:

  An `agri_rank_fit`.

- by:

  Factor(s) conditioning simple pairwise comparisons.

- factor:

  Factor to compare in native repeated wild-rank or Conover
  simple-effect contrasts.

- method:

  Pairwise engine: `"wilcoxon"` or design-aware `"conover"`.

- adjust:

  Multiplicity adjustment method.

- B:

  Number of bootstrap or resampling replicates for the native repeated
  wild-rank engine.

- seed:

  Random seed used for reproducible resampling.

- level:

  Confidence level.

- cld:

  If `TRUE`, a compact letter display is computed from the
  multiplicity-adjusted p-values and attached to the result as the
  `"cld"` attribute. Requires multcompView.

- alpha:

  Significance level used by the letter display.

## Details

For `method = "conover"`, one-way/CRD comparisons are routed to the
Kruskal-type Conover test and complete unreplicated RCBD comparisons are
routed to the Friedman-type Conover test. In factorial experiments, use
`by` to obtain scientifically meaningful simple effects where
appropriate.

A compact letter display is available for every route of this function:
the Wilcoxon comparisons, the Conover comparisons, and the simultaneous
max-T contrasts of the native repeated wild-rank engine. Set
`cld = TRUE`, or pass the returned table to
[`agri_cld`](https://wep69.github.io/agriRank/reference/agri_cld.md).
Letters are computed within each stratum, because groups compared in
different simple-effect strata were never tested against each other.

The letter display requires the complete set of pairs. A subset of
comparisons, or a user-defined contrast that is not a simple difference
between two groups, is refused rather than summarized into letters that
would imply comparisons the analysis never performed.

## Value

A data frame containing the relevant treatment contrasts and
multiplicity-adjusted inference. When `cld = TRUE`, the `"cld"`
attribute holds the letter display.

## References

Conover, W. J. (1999). *Practical Nonparametric Statistics*. 3rd ed.
Wiley.

Konietschke, F. and Brunner, E. (2023). rankFD: An R Software Package
for Nonparametric Analysis of General Factorial Designs. *The R
Journal*. doi:10.32614/RJ-2023-029.

## See also

[`agri_conover`](https://wep69.github.io/agriRank/reference/agri_conover.md),
[`agri_cld`](https://wep69.github.io/agriRank/reference/agri_cld.md),
[`agri_effects`](https://wep69.github.io/agriRank/reference/agri_effects.md),
[`agri_rank`](https://wep69.github.io/agriRank/reference/agri_rank.md)

## Examples

``` r
# Example 1: default pairwise workflow
fit <- np_crd(yield ~ treatment, simulate_agri("crd"))
agri_pairs(fit)
#>   stratum group1 group2 paired_by_block         A cliff_delta hodges_lehmann
#> 1     all      A      B           FALSE 0.5000000   0.0000000     -0.2155826
#> 2     all      A      C           FALSE 0.3611111  -0.2777778     -1.1658629
#> 3     all      A      D           FALSE 0.5555556   0.1111111      0.3961795
#> 4     all      B      C           FALSE 0.4444444  -0.1111111     -1.9547864
#> 5     all      B      D           FALSE 0.5555556   0.1111111      0.6914259
#> 6     all      C      D           FALSE 0.7777778   0.5555556      1.4375976
#>     p_value p_adjusted
#> 1 1.0000000  1.0000000
#> 2 0.4711700  1.0000000
#> 3 0.8101812  1.0000000
#> 4 0.8101812  1.0000000
#> 5 0.8101812  1.0000000
#> 6 0.1282053  0.7692317

# Example 2: factorial simple effects
if (requireNamespace("rankFD", quietly = TRUE)) {
  x <- simulate_agri("factorial")
  f <- np_factorial(yield ~ A * B, x, method = "rankFD")
  agri_pairs(f, by = "B")
}
#>   stratum group1 group2 paired_by_block          A cliff_delta hodges_lehmann
#> 1      B1     A1     A2           FALSE 0.41666667  -0.1666667     -0.2644787
#> 2      B2     A1     A2           FALSE 0.27777778  -0.4444444     -0.7968625
#> 3      B3     A1     A2           FALSE 0.08333333  -0.8333333     -2.3781495
#>      p_value p_adjusted
#> 1 0.68892056 0.68892056
#> 2 0.22976627 0.45953254
#> 3 0.02024057 0.06072171

# Example 3: Conover through the same interface
if (requireNamespace("PMCMRplus", quietly = TRUE)) {
  set.seed(91)
  dc <- data.frame(trt = factor(rep(LETTERS[1:3], each = 7)),
                   y = rgamma(21, shape = rep(4:6, each = 7)))
  fc <- np_crd(y ~ trt, dc, method = "kruskal")
  agri_pairs(fc, method = "conover")
}
#>   stratum group1 group2 paired_by_block statistic   p_value p_adjusted
#> 1     all      B      A           FALSE 0.4223258 0.6777889  1.0000000
#> 2     all      C      A           FALSE 1.0980471 0.2866556  0.8599668
#> 3     all      C      B           FALSE 0.6757213 0.5078068  1.0000000
#>                                         method
#> 1 Conover all-pairs after Kruskal-type ranking
#> 2 Conover all-pairs after Kruskal-type ranking
#> 3 Conover all-pairs after Kruskal-type ranking

# Example 4: letters attached to the comparison table
if (requireNamespace("multcompView", quietly = TRUE)) {
  p <- agri_pairs(fit, cld = TRUE)
  attr(p, "cld")
}
#>   group letter
#> 1     A      a
#> 2     B      a
#> 3     C      a
#> 4     D      a

# Example 5: letters within each simple-effect stratum
if (requireNamespace("rankFD", quietly = TRUE) &&
    requireNamespace("multcompView", quietly = TRUE)) {
  attr(agri_pairs(f, by = "B", cld = TRUE), "cld")
}
#>   stratum group letter
#> 1      B1    A1      a
#> 2      B1    A2      a
#> 3      B2    A1      a
#> 4      B2    A2      a
#> 5      B3    A1      a
#> 6      B3    A2      a

# Example 6: the native repeated wild-rank engine, whose simultaneous max-T
# contrasts also support a letter display
if (requireNamespace("multcompView", quietly = TRUE)) {
  rp <- simulate_agri("repeated_missing", seed = 61, n = 12, missing_rate = 0.15)
  dr <- agri_design(height ~ treatment * time, rp, design = "repeated",
                    subject = subject, within = time)
  fw <- agri_repeated(dr, backend = "native_wild", B = 99, seed = 1,
                      missing_assumption = "MCAR")
  attr(agri_pairs(fw, B = 99, seed = 1, cld = TRUE), "cld")
}
#> Warning: B < 199 gives coarse Monte Carlo p-values; use >= 999 for analysis and >= 4999 for final work when feasible.
#>   stratum group letter
#> 1 control     1      a
#> 2 control     2      a
#> 3 control     3      a
#> 4 control     4      a
#> 5 treated     1      a
#> 6 treated     2     ab
#> 7 treated     3      b
#> 8 treated     4      b
```
