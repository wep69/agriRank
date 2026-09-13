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

# Example 2
x<-simulate_agri("rcbd"); design_summary(agri_design(yield~treatment,x,"rcbd",block=block))

# Example 3
x<-simulate_agri("repeated");
design_summary(agri_design(height~treatment*time,x,"repeated",subject=subject,within=time))
```
