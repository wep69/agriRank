# List available inferential domains and engines

Provides a compact registry of implemented and adapter-backed methods.

## Usage

``` r
agri_methods()
```

## Details

Availability of optional engines still depends on installed Suggested
packages. The vignette suite documents the experimental-design logic,
estimand, hypothesis, resampling structure, missing/unbalanced-data
behavior, and backend-specific limitations in greater depth.

## Value

A data frame.

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
agri_methods()
#>                      domain
#> 1                   one-way
#> 2                      RCBD
#> 3                 factorial
#> 4      multiple comparisons
#> 5                split-plot
#> 6               split-split
#> 7                strip-plot
#> 8                  repeated
#> 9          repeated+missing
#> 10             multivariate
#> 11        multi-environment
#> 12                   ANCOVA
#> 13 nonparametric regression
#> 14       robust sensitivity
#>                                                                                             method
#> 1                                                                            Kruskal / permutation
#> 2                                                                Friedman / restricted permutation
#> 3                                                                    rankFD / ARTool / permutation
#> 4                                                                        Wilcoxon / Conover / maxT
#> 5                                                                                           ARTool
#> 6                                                                       ARTool hierarchical strata
#> 7                                                              ARTool strip-specific random strata
#> 8                                                                 nparLD / MANOVA.RM / native wild
#> 9                                                                         native wild ATS/WTS/MATS
#> 10                                                         MANOVA.RM MANOVA / MANOVA.wide / multRM
#> 11                                             rankFD / ARTool / permuco with environment enforced
#> 12                                                                                         permuco
#> 13 spline / LOESS / kernel / isotonic / COBS / Theil-Sen / quantile / GAM / SCAM / integer-support
#> 14                                                                      WRS2 / alternative engines
#>                      status
#> 1               implemented
#> 2               implemented
#> 3       adapter+implemented
#> 4       implemented+adapter
#> 5                   adapter
#> 6                   adapter
#> 7                   adapter
#> 8       adapter+implemented
#> 9  implemented-experimental
#> 10       adapter+integrated
#> 11       adapter+integrated
#> 12                  adapter
#> 13      implemented+adapter
#> 14                  adapter

# Example 2
subset(agri_methods(), grepl("repeated", domain))
#>             domain                           method                   status
#> 8         repeated nparLD / MANOVA.RM / native wild      adapter+implemented
#> 9 repeated+missing         native wild ATS/WTS/MATS implemented-experimental

# Example 3
subset(agri_methods(), grepl("implemented", status))
#>                      domain
#> 1                   one-way
#> 2                      RCBD
#> 3                 factorial
#> 4      multiple comparisons
#> 8                  repeated
#> 9          repeated+missing
#> 13 nonparametric regression
#>                                                                                             method
#> 1                                                                            Kruskal / permutation
#> 2                                                                Friedman / restricted permutation
#> 3                                                                    rankFD / ARTool / permutation
#> 4                                                                        Wilcoxon / Conover / maxT
#> 8                                                                 nparLD / MANOVA.RM / native wild
#> 9                                                                         native wild ATS/WTS/MATS
#> 13 spline / LOESS / kernel / isotonic / COBS / Theil-Sen / quantile / GAM / SCAM / integer-support
#>                      status
#> 1               implemented
#> 2               implemented
#> 3       adapter+implemented
#> 4       implemented+adapter
#> 8       adapter+implemented
#> 9  implemented-experimental
#> 13      implemented+adapter
```
