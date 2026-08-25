# Design-aware Conover all-pairs comparisons

Performs Conover all-pairs rank comparisons while respecting the
declared experimental layout. One-way/CRD data use the Kruskal-type
Conover procedure; complete unreplicated RCBD data use the Friedman-type
Conover procedure.

## Usage

``` r
agri_conover(
  x,
  by = NULL,
  factor = NULL,
  adjust = "holm",
  cld = FALSE,
  alpha = 0.05
)
```

## Arguments

- x:

  An `agri_rank_fit` object.

- by:

  Optional character vector of factors that define simple-effect strata.

- factor:

  Optional treatment factor to compare. If omitted, remaining treatment
  factors are used.

- adjust:

  P-value adjustment supported by PMCMRplus, such as `"holm"`,
  `"bonferroni"`, `"BH"`, or `"single-step"`.

- cld:

  If `TRUE`, a compact letter display is computed from the adjusted
  p-values and attached to the result as the `"cld"` attribute. Requires
  multcompView.

- alpha:

  Significance level used by the letter display.

## Details

The function is an adapter to
[`PMCMRplus::kwAllPairsConoverTest()`](https://rdrr.io/pkg/PMCMRplus/man/kwAllPairsConoverTest.html)
and
[`PMCMRplus::frdAllPairsConoverTest()`](https://rdrr.io/pkg/PMCMRplus/man/frdAllPairsConoverTest.html).
For blocked data, every block-by-treatment cell within the requested
stratum must contain exactly one observation. The function does not
silently discard incomplete blocks.

For factorial experiments, use `by` to request scientifically
interpretable simple effects rather than indiscriminate comparisons of
all treatment cells.

A compact letter display can be obtained in two equivalent ways: by
setting `cld = TRUE`, which attaches the letters to the returned table,
or by passing the returned table to
[`agri_cld`](https://wep69.github.io/agriRank/reference/agri_cld.md).
Letters are computed *within each stratum*, because two treatments
evaluated in different simple-effect strata were never compared with
each other and a single global display would suggest a comparison the
data do not support.

Letters summarize the same adjusted p-values already present in the
table. They compress information and lose the magnitude of the
differences, so they should accompany effect estimates rather than
replace them.

## Value

A data frame containing treatment pairs, the comparison stratum, test
statistic when exposed by the backend, raw and adjusted p-values,
block-pairing indicator, and method label. When `cld = TRUE`, the
`"cld"` attribute holds a data frame with the stratum, the group, and
its letter.

## References

Conover, W. J. (1999). *Practical Nonparametric Statistics*. 3rd ed.
Wiley.

Pohlert, T. PMCMRplus: Calculate Pairwise Multiple Comparisons of Mean
Rank Sums Extended. CRAN.

## See also

[`agri_pairs`](https://wep69.github.io/agriRank/reference/agri_pairs.md),
[`agri_cld`](https://wep69.github.io/agriRank/reference/agri_cld.md),
[`np_crd`](https://wep69.github.io/agriRank/reference/np_crd.md),
[`np_rcbd`](https://wep69.github.io/agriRank/reference/np_rcbd.md)

## Examples

``` r
# Example 1: one-way CRD
set.seed(11)
d1 <- data.frame(
  treatment = factor(rep(LETTERS[1:4], each = 8)),
  yield = c(rgamma(8, 5, 1), rgamma(8, 6, 1), rgamma(8, 7, 1), rgamma(8, 8, 1))
)
f1 <- np_crd(yield ~ treatment, d1, method = "kruskal")
if (requireNamespace("PMCMRplus", quietly = TRUE))
  agri_conover(f1, adjust = "holm")
#>   stratum group1 group2 paired_by_block statistic     p_value p_adjusted
#> 1     all      B      A           FALSE 0.6915478 0.494915924 0.98983185
#> 2     all      C      A           FALSE 2.4053838 0.023008388 0.11504194
#> 3     all      C      B           FALSE 1.7138359 0.097610655 0.29283196
#> 4     all      D      A           FALSE 2.9165278 0.006898468 0.04139081
#> 5     all      D      B           FALSE 2.2249800 0.034315288 0.13726115
#> 6     all      D      C           FALSE 0.5111441 0.613257377 0.98983185
#>                                         method
#> 1 Conover all-pairs after Kruskal-type ranking
#> 2 Conover all-pairs after Kruskal-type ranking
#> 3 Conover all-pairs after Kruskal-type ranking
#> 4 Conover all-pairs after Kruskal-type ranking
#> 5 Conover all-pairs after Kruskal-type ranking
#> 6 Conover all-pairs after Kruskal-type ranking

# Example 2: complete RCBD
set.seed(12)
d2 <- expand.grid(block = factor(1:6), treatment = factor(LETTERS[1:4]))
d2$yield <- 30 + as.numeric(d2$treatment) * 2 + as.numeric(d2$block) + rnorm(nrow(d2))
f2 <- np_rcbd(yield ~ treatment, d2, block = block, method = "friedman")
if (requireNamespace("PMCMRplus", quietly = TRUE))
  agri_conover(f2, adjust = "bonferroni")
#>   stratum group1 group2 paired_by_block  statistic      p_value   p_adjusted
#> 1     all      B      A            TRUE  -3.464102 3.469960e-03 2.081976e-02
#> 2     all      C      A            TRUE  -9.526279 9.425922e-08 5.655553e-07
#> 3     all      C      B            TRUE  -6.062178 2.174797e-05 1.304878e-04
#> 4     all      D      A            TRUE -14.722432 2.526247e-10 1.515748e-09
#> 5     all      D      B            TRUE -11.258330 1.028566e-08 6.171394e-08
#> 6     all      D      C            TRUE  -5.196152 1.085497e-04 6.512983e-04
#>                                          method
#> 1 Conover all-pairs after Friedman-type ranking
#> 2 Conover all-pairs after Friedman-type ranking
#> 3 Conover all-pairs after Friedman-type ranking
#> 4 Conover all-pairs after Friedman-type ranking
#> 5 Conover all-pairs after Friedman-type ranking
#> 6 Conover all-pairs after Friedman-type ranking

# Example 3: factorial simple effects
if (requireNamespace("rankFD", quietly = TRUE) && requireNamespace("PMCMRplus", quietly = TRUE)) {
  d3 <- expand.grid(block = factor(1:5), cultivar = factor(c("C1", "C2", "C3")),
                    salinity = factor(c("S1", "S2")))
  set.seed(13)
  d3$biomass <- 20 + as.numeric(d3$cultivar) - 2 * as.numeric(d3$salinity) + rnorm(nrow(d3))
  des3 <- agri_design(biomass ~ cultivar * salinity, d3, design = "factorial")
  fit3 <- agri_rank(des3, method = "rankFD")
  agri_conover(fit3, by = "salinity", factor = "cultivar")
}
#>   stratum group1 group2 paired_by_block  statistic   p_value p_adjusted
#> 1      S1     C2     C1           FALSE  1.6730038 0.1201737  0.3605210
#> 2      S1     C3     C1           FALSE  0.9456109 0.3629992  0.7259985
#> 3      S1     C3     C2           FALSE -0.7273930 0.4809367  0.7259985
#> 4      S2     C2     C1           FALSE  1.7677030 0.1025043  0.3075129
#> 5      S2     C3     C1           FALSE  1.1048144 0.2909001  0.5818002
#> 6      S2     C3     C2           FALSE -0.6628886 0.5199321  0.5818002
#>                                         method
#> 1 Conover all-pairs after Kruskal-type ranking
#> 2 Conover all-pairs after Kruskal-type ranking
#> 3 Conover all-pairs after Kruskal-type ranking
#> 4 Conover all-pairs after Kruskal-type ranking
#> 5 Conover all-pairs after Kruskal-type ranking
#> 6 Conover all-pairs after Kruskal-type ranking

# Example 4: compact letter display attached to the comparison table
if (requireNamespace("PMCMRplus", quietly = TRUE) &&
    requireNamespace("multcompView", quietly = TRUE)) {
  cv <- agri_conover(f1, adjust = "holm", cld = TRUE)
  attr(cv, "cld")
}
#>   group letter
#> 1     B     ab
#> 2     C     ab
#> 3     D      a
#> 4     A      b

# Example 5: the same letters obtained from the table itself
if (requireNamespace("PMCMRplus", quietly = TRUE) &&
    requireNamespace("multcompView", quietly = TRUE)) {
  agri_cld(agri_conover(f2, adjust = "bonferroni"))
}
#>   group letter
#> 1     B      a
#> 2     C      b
#> 3     D      c
#> 4     A      d

# Example 6: letters computed within each simple-effect stratum
if (requireNamespace("rankFD", quietly = TRUE) &&
    requireNamespace("PMCMRplus", quietly = TRUE) &&
    requireNamespace("multcompView", quietly = TRUE)) {
  cv3 <- agri_conover(fit3, by = "salinity", factor = "cultivar", cld = TRUE)
  attr(cv3, "cld")
}
#>   stratum group letter
#> 1      S1    C2      a
#> 2      S1    C3      a
#> 3      S1    C1      a
#> 4      S2    C2      a
#> 5      S2    C3      a
#> 6      S2    C1      a
```
