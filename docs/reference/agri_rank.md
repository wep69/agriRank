# Fit design-aware rank-based or permutation inference

Routes a declared design to an explicit or automatically selected
admissible engine.

## Usage

``` r
agri_rank(design, method = "auto", response = NULL, 
    estimand = c("relative_effect", "distribution", 
        "location_shift"), B = 1999, seed = 1, missing_assumption = c("unspecified", 
        "MCAR", "MAR-sensitivity"), ...)
```

## Arguments

- design:

  A declared design type or an \`agri_design\` object, depending on
  context.

- method:

  Inferential engine name or \`"auto"\` for conservative design-based
  routing.

- response:

  Optional response column name when a design contains more than one
  response.

- estimand:

  Target effect representation used to label and interpret the analysis.

- B:

  Number of bootstrap or resampling replicates. Small values are for
  examples only.

- seed:

  Random seed used for reproducible resampling.

- missing_assumption:

  Label recording the assumed missingness framework; this is not
  inferred from the data.

- ...:

  Additional arguments passed to the selected backend or downstream
  method.

## Details

Automatic routing is design-driven; it does not select a method from a
preliminary normality p-value. Blocked incomplete repeated measures are
deliberately rejected in the current build. The vignette suite documents
the experimental-design logic, estimand, hypothesis, resampling
structure, missing/unbalanced-data behavior, and backend-specific
limitations in greater depth.

## Value

An \`agri_rank_fit\` object.

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
d<-agri_design(yield~treatment,simulate_agri("crd"),"crd"); agri_rank(d)
#> agriRank fit
#>   Design: crd
#>   Method: Kruskal-Wallis
#>   Response: yield
#>      effect statistic df   p_value
#> 1 treatment  1.646667  3 0.6488554

# Example 2
x<-simulate_agri("factorial");
d<-agri_design(yield~A*B,x,"factorial");
if(requireNamespace("rankFD",quietly=TRUE)) agri_rank(d,"rankFD")
#> agriRank fit
#>   Design: factorial
#>   Method: rankFD pseudo-rank factorial inference
#>   Response: yield
#>   effect statistic    df1     df2 p_value
#> 1      A    6.9339 1.0000 22.8596  0.0149
#> 2      B    6.6740 1.9702 22.8596  0.0054
#> 3    A:B    1.8632 1.9702 22.8596  0.1784

# Example 3
x<-simulate_agri("repeated_missing");
d<-agri_design(height~treatment*time,x,"repeated",subject=subject,within=time);
agri_rank(d,"incomplete_wild",B=299,missing_assumption="MCAR")
#> agriRank fit
#>   Design: repeated
#>   Method: incomplete repeated-measures rank wild bootstrap
#>   Response: height
#>                        effect statistic    value      df p_boot p_asymptotic
#> treatment           treatment       ATS 2.400622 1.00000   0.14   0.12128701
#> time                     time       ATS 3.768121 1.42395   0.06   0.03710787
#> treatment:time treatment:time       ATS 1.242759 1.42395   0.32   0.27959642
```
