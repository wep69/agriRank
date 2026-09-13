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
#> agriRank fit
#>   Design: repeated
#>   Method: nparLD ANOVA-type rank inference
#>   Response: height
#>   Resampling: none (asymptotic test)
#>           effect statistic       df      p_value
#> 1      treatment  1.255810 1.000000 2.624457e-01
#> 2           time 10.402598 2.578418 3.603182e-06
#> 3 treatment:time  5.676011 2.578418 1.360413e-03

# Example 2
x<-simulate_agri("repeated");
if (requireNamespace("nparLD", quietly = TRUE)) np_repeated(height ~ treatment * 
    time, x, subject, time, method = "nparLD")
#> agriRank fit
#>   Design: repeated
#>   Method: nparLD ANOVA-type rank inference
#>   Response: height
#>   Resampling: none (asymptotic test)
#>           effect statistic       df      p_value
#> 1      treatment  1.255810 1.000000 2.624457e-01
#> 2           time 10.402598 2.578418 3.603182e-06
#> 3 treatment:time  5.676011 2.578418 1.360413e-03

# Example 3
x<-simulate_agri("repeated_missing");
np_repeated(height ~ treatment * time, x, subject, time, method = "incomplete_wild", 
    B = 299, missing_assumption = "MCAR")
#> Warning: `B` = 299 is too small for confirmatory resampling inference: the smallest attainable p-value is 1/(B + 1) = 0.00333, so no result below that can be reported and the Monte Carlo error of any p-value near it is large. Use B >= 1999, or state the p floor explicitly when computing time limits the budget.
#> agriRank fit
#>   Design: repeated
#>   Method: incomplete repeated-measures rank wild bootstrap
#>   Response: height
#>   Resampling replicates: 299
#>           effect statistic      df p_value    value p_boot p_asymptotic
#> 1      treatment        NA 1.00000    0.14 2.400622   0.14   0.12128701
#> 2           time        NA 1.42395    0.06 3.768121   0.06   0.03710787
#> 3 treatment:time        NA 1.42395    0.32 1.242759   0.32   0.27959642
```
