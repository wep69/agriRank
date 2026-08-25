# Analyze repeated measurements with explicit backend selection

Provides a dedicated repeated-measures router for nparLD, MANOVA.RM,
permuco, and the native incomplete wild-rank engine.

## Usage

``` r
agri_repeated(design, backend = c("auto", "native_wild", "nparLD", "MANOVA.RM", 
    "permuco"), B = 1999, iter = 4999, seed = 1, missing_assumption = c("unspecified", 
    "MCAR", "MAR-sensitivity"), ...)
```

## Arguments

- design:

  A declared design type or an \`agri_design\` object, depending on
  context.

- backend:

  Repeated-measures backend.

- B:

  Number of bootstrap or resampling replicates. Small values are for
  examples only.

- iter:

  Number of resampling iterations passed to the selected optional
  backend.

- seed:

  Random seed used for reproducible resampling.

- missing_assumption:

  Label recording the assumed missingness framework; this is not
  inferred from the data.

- ...:

  Additional arguments passed to the selected backend or downstream
  method.

## Details

The current native incomplete engine is unblocked; blocked incomplete
repeated data are not silently simplified. The vignette suite documents
the experimental-design logic, estimand, hypothesis, resampling
structure, missing/unbalanced-data behavior, and backend-specific
limitations in greater depth.

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
x<-simulate_agri("repeated");
d<-agri_design(height~treatment*time,x,"repeated",subject=subject,within=time);
if(requireNamespace("nparLD",quietly=TRUE)) agri_repeated(d,"nparLD")
#>  F1 LD F1 Model 
#>  ----------------------- 
#>  Check that the order of the time and group levels are correct.
#>  Time level:   1 2 3 4 
#>  Group level:   control treated 
#>  If the order is not correct, specify the correct order in time.order or group.order.
#> 
#> agriRank fit
#>   Design: repeated
#>   Method: nparLD ANOVA-type rank inference
#>   Response: height
#>   Statistic       df      p-value         effect
#> 1  1.255810 1.000000 2.624457e-01      treatment
#> 2 10.402598 2.578418 3.603182e-06           time
#> 3  5.676011 2.578418 1.360413e-03 treatment:time

# Example 2
x<-simulate_agri("repeated");
d<-agri_design(height~treatment*time,x,"repeated",subject=subject,within=time);
if(requireNamespace("MANOVA.RM",quietly=TRUE)) agri_repeated(d,"MANOVA.RM",iter=499)
#> agriRank fit
#>   Design: repeated
#>   Method: MANOVA.RM WildBS
#>   Response: height
#>                Test statistic  df1    df2 p-value
#> treatment               0.790 1.00 11.521   0.392
#> time                    9.227 2.48    Inf   0.000
#> treatment:time          4.883 2.48    Inf   0.004

# Example 3
x<-simulate_agri("repeated_missing");
d<-agri_design(height~treatment*time,x,"repeated",subject=subject,within=time);
agri_repeated(d,"native_wild",B=299,missing_assumption="MCAR")
#> agriRank fit
#>   Design: repeated
#>   Method: incomplete repeated-measures rank wild bootstrap
#>   Response: height
#>                        effect statistic    value      df p_boot p_asymptotic
#> treatment           treatment       ATS 2.400622 1.00000   0.14   0.12128701
#> time                     time       ATS 3.768121 1.42395   0.06   0.03710787
#> treatment:time treatment:time       ATS 1.242759 1.42395   0.32   0.27959642
```
