# Analyze repeated measurements

Convenience wrapper that declares subject and within-subject factors
before fitting repeated-measures inference.

## Usage

``` r
np_repeated(formula, data, subject, within, block = NULL, method = "auto", ...)
```

## Arguments

- formula:

  A model formula defining the scientific treatment structure.

- data:

  A data frame, preferably in long format.

- subject:

  Experimental-unit identifier for repeated or multivariate
  observations.

- within:

  Within-subject factor(s), usually time or measurement occasion.

- block:

  Blocking variable(s) identifying the RCBD or nuisance randomization
  stratum.

- method:

  Inferential engine name or \`"auto"\` for conservative design-based
  routing.

- ...:

  Additional arguments passed to the selected backend or downstream
  method.

## Details

Repeated observations from one subject are dependent. The vignette suite
documents the experimental-design logic, estimand, hypothesis,
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
x<-simulate_agri("repeated"); np_repeated(height~treatment*time,x,subject,time)
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
if (requireNamespace("nparLD", quietly = TRUE)) np_repeated(height ~ treatment * 
    time, x, subject, time, method = "nparLD")
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

# Example 3
x<-simulate_agri("repeated_missing");
np_repeated(height ~ treatment * time, x, subject, time, method = "incomplete_wild", 
    B = 299, missing_assumption = "MCAR")
#> agriRank fit
#>   Design: repeated
#>   Method: incomplete repeated-measures rank wild bootstrap
#>   Response: height
#>                        effect statistic    value      df p_boot p_asymptotic
#> treatment           treatment       ATS 2.400622 1.00000   0.14   0.12128701
#> time                     time       ATS 3.768121 1.42395   0.06   0.03710787
#> treatment:time treatment:time       ATS 1.242759 1.42395   0.32   0.27959642
```
