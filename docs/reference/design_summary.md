# Summarize a declared agricultural design

Returns a compact machine-readable summary of the randomization and data
structure.

## Usage

``` r
design_summary(x)
```

## Arguments

- x:

  An agriRank design or fitted object as documented for the function.

## Details

Useful for reports and quality-control pipelines. The vignette suite
documents the experimental-design logic, estimand, hypothesis,
resampling structure, missing/unbalanced-data behavior, and
backend-specific limitations in greater depth.

## Value

A list.

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
design_summary(agri_design(yield~treatment,simulate_agri("crd"),"crd"))
#> $design
#> [1] "crd"
#> 
#> $responses
#> [1] "yield"
#> 
#> $treatments
#> [1] "treatment"
#> 
#> $blocks
#> NULL
#> 
#> $subjects
#> NULL
#> 
#> $within
#> NULL
#> 
#> $whole_plot
#> NULL
#> 
#> $subplot
#> NULL
#> 
#> $subsubplot
#> NULL
#> 
#> $strip_a
#> NULL
#> 
#> $strip_b
#> NULL
#> 
#> $environment
#> NULL
#> 
#> $n_rows
#> [1] 24
#> 
#> $n_treatment_cells_observed
#> [1] 4
#> 
#> $missing_response
#> yield 
#>     0 
#> 
#> $randomization
#> [1] "Treatment assignments are exchangeable across experimental units, subject to the declared treatment structure."
#> 
#> $validation
#> $ok
#> [1] TRUE
#> 
#> $problems
#> [1] severity code     message 
#> <0 rows> (or 0-length row.names)
#> 
#> attr(,"class")
#> [1] "agri_validation"
#> 

# Example 2
x<-simulate_agri("rcbd"); design_summary(agri_design(yield~treatment,x,"rcbd",block=block))
#> $design
#> [1] "rcbd"
#> 
#> $responses
#> [1] "yield"
#> 
#> $treatments
#> [1] "treatment"
#> 
#> $blocks
#> [1] "block"
#> 
#> $subjects
#> NULL
#> 
#> $within
#> NULL
#> 
#> $whole_plot
#> NULL
#> 
#> $subplot
#> NULL
#> 
#> $subsubplot
#> NULL
#> 
#> $strip_a
#> NULL
#> 
#> $strip_b
#> NULL
#> 
#> $environment
#> NULL
#> 
#> $n_rows
#> [1] 24
#> 
#> $n_treatment_cells_observed
#> [1] 4
#> 
#> $missing_response
#> yield 
#>     0 
#> 
#> $randomization
#> [1] "Treatment combinations are randomized within blocks; block labels are not exchangeable with treatments."
#> 
#> $validation
#> $ok
#> [1] TRUE
#> 
#> $problems
#> [1] severity code     message 
#> <0 rows> (or 0-length row.names)
#> 
#> attr(,"class")
#> [1] "agri_validation"
#> 

# Example 3
x<-simulate_agri("repeated");
design_summary(agri_design(height~treatment*time,x,"repeated",subject=subject,within=time))
#> $design
#> [1] "repeated"
#> 
#> $responses
#> [1] "height"
#> 
#> $treatments
#> [1] "treatment" "time"     
#> 
#> $blocks
#> NULL
#> 
#> $subjects
#> [1] "subject"
#> 
#> $within
#> [1] "time"
#> 
#> $whole_plot
#> NULL
#> 
#> $subplot
#> NULL
#> 
#> $subsubplot
#> NULL
#> 
#> $strip_a
#> NULL
#> 
#> $strip_b
#> NULL
#> 
#> $environment
#> NULL
#> 
#> $n_rows
#> [1] 48
#> 
#> $n_treatment_cells_observed
#> [1] 8
#> 
#> $missing_response
#> height 
#>      0 
#> 
#> $randomization
#> [1] "Between-subject treatments are assigned to subjects/experimental units; within-subject factors index repeated observations on the same subject."
#> 
#> $validation
#> $ok
#> [1] TRUE
#> 
#> $problems
#> [1] severity code     message 
#> <0 rows> (or 0-length row.names)
#> 
#> attr(,"class")
#> [1] "agri_validation"
#> 
```
