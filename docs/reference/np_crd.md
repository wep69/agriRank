# Analyze a completely randomized design

Convenience wrapper around \`agri_design()\` and \`agri_rank()\` for CRD
data.

## Usage

``` r
np_crd(formula, data, method = "auto", ...)
```

## Arguments

- formula:

  A model formula defining the scientific treatment structure.

- data:

  A data frame, preferably in long format.

- method:

  Inferential engine name or \`"auto"\` for conservative design-based
  routing.

- ...:

  Additional arguments passed to the selected backend or downstream
  method.

## Details

Use the full API when explicit design metadata are needed. The vignette
suite documents the experimental-design logic, estimand, hypothesis,
resampling structure, missing/unbalanced-data behavior, and
backend-specific limitations in greater depth.

## Value

An \`agri_rank_fit\`.

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
np_crd(yield~treatment,simulate_agri("crd"))
#> agriRank fit
#>   Design: crd
#>   Method: Kruskal-Wallis
#>   Response: yield
#>      effect statistic df   p_value
#> 1 treatment  1.646667  3 0.6488554

# Example 2
x<-simulate_agri("crd"); x$score<-round(x$yield); np_crd(score~treatment,x,"kruskal")
#> agriRank fit
#>   Design: crd
#>   Method: Kruskal-Wallis
#>   Response: score
#>      effect statistic df   p_value
#> 1 treatment   1.52551  3 0.6763952

# Example 3
x<-simulate_agri("crd"); np_crd(yield~treatment,x[-c(1,2),])
#> agriRank fit
#>   Design: crd
#>   Method: Kruskal-Wallis
#>   Response: yield
#>      effect statistic df   p_value
#> 1 treatment    1.6917  3 0.6387807
```
