# Create a compact letter display

Summarizes multiplicity-adjusted ordinary pairwise comparisons as
letters.

## Usage

``` r
agri_cld(x, adjust = "holm", alpha = 0.05, ...)
```

## Arguments

- x:

  An `agri_rank_fit` object, or a pairwise comparison table already
  produced by
  [`agri_pairs`](https://wep69.github.io/agriRank/reference/agri_pairs.md)
  or
  [`agri_conover`](https://wep69.github.io/agriRank/reference/agri_conover.md).

- adjust:

  Multiplicity adjustment method. Used only when `x` is a fitted object
  and the pairwise table still has to be computed.

- alpha:

  Significance threshold used to derive a compact letter display.

- ...:

  Additional arguments passed to
  [`agri_pairs`](https://wep69.github.io/agriRank/reference/agri_pairs.md),
  such as `method`, `by` and `factor`.

## Details

CLD is secondary to effect estimates and confidence intervals. The
vignette suite documents the experimental-design logic, estimand,
hypothesis, resampling structure, missing/unbalanced-data behavior, and
backend-specific limitations in greater depth.

When the comparison table contains a `stratum` column, as produced by
`agri_conover(by = ...)` or `agri_pairs(by = ...)`, letters are computed
separately within each stratum. Two treatments evaluated in different
simple-effect strata were never compared with each other, so a single
global display would suggest a comparison the data do not support.

Every comparison route of the package is supported: Wilcoxon
comparisons, design-aware Conover comparisons, and the simultaneous
max-T contrasts of the native repeated wild-rank engine, whose labels of
the form `"stratum: g1 - g2"` are parsed back into groups.

The letter display needs the complete set of pairs. A subset of
comparisons, or a user-defined contrast that is not a simple difference
between two groups, is refused with an explicit message, because letters
derived from an incomplete family would imply comparisons that were
never performed.

## Value

A data frame with groups and letters, plus a `stratum` column when the
comparisons were stratified.

## References

Pauly M, Brunner E, Konietschke F (2015), DOI: 10.1111/rssb.12073.
Brunner E, Konietschke F, Pauly M, Puri ML (2017), DOI:
10.1111/rssb.12222. Konietschke F, Brunner E (2023), DOI:
10.32614/RJ-2023-029. See the package vignettes and
\`inst/references/agriRank-methods-verified.ris\` for engine-specific
verified references.

## See also

`agri_design`, `agri_rank`, `agri_effects`, `agri_report`

## Examples

``` r
# Example 1
fit<-np_crd(yield~treatment,simulate_agri("crd"));
if(requireNamespace("multcompView",quietly=TRUE)) agri_cld(fit)
#>   group letter
#> 1     A      a
#> 2     B      a
#> 3     C      a
#> 4     D      a

# Example 2
fit<-np_crd(yield~treatment,simulate_agri("crd"));
if(requireNamespace("multcompView",quietly=TRUE)) agri_cld(fit,adjust="BH")
#>   group letter
#> 1     A      a
#> 2     B      a
#> 3     C      a
#> 4     D      a

# Example 3
fit<-np_crd(yield~treatment,simulate_agri("crd"));
if(requireNamespace("multcompView",quietly=TRUE)) agri_cld(fit,alpha=.01)
#>   group letter
#> 1     A      a
#> 2     B      a
#> 3     C      a
#> 4     D      a

# Example 4: letters from a Conover table that was already computed
if (requireNamespace("multcompView", quietly = TRUE) &&
    requireNamespace("PMCMRplus", quietly = TRUE)) {
  fit <- np_crd(yield ~ treatment, simulate_agri("crd", seed = 41))
  cv <- agri_conover(fit, adjust = "holm")
  agri_cld(cv)
}
#>   group letter
#> 1     B      a
#> 2     C      a
#> 3     D      a
#> 4     A      a

# Example 5: letters within each simple-effect stratum
if (requireNamespace("multcompView", quietly = TRUE) &&
    requireNamespace("PMCMRplus", quietly = TRUE) &&
    requireNamespace("ARTool", quietly = TRUE)) {
  d <- expand.grid(cultivar = factor(c("C1", "C2", "C3")),
                   salinity = factor(c("S1", "S2")), rep = 1:5)
  set.seed(42)
  d$biomass <- 20 + as.numeric(d$cultivar) - 2 * as.numeric(d$salinity) + rnorm(nrow(d))
  f <- agri_rank(agri_design(biomass ~ cultivar * salinity, d, design = "factorial"),
                 method = "ART")
  agri_cld(f, method = "conover", by = "salinity", factor = "cultivar")
}
#>   stratum group letter
#> 1      S1    C2      a
#> 2      S1    C3      a
#> 3      S1    C1      a
#> 4      S2    C2      a
#> 5      S2    C3      a
#> 6      S2    C1      b
```
