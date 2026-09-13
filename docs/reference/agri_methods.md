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

# Example 2
subset(agri_methods(), grepl("repeated", domain))

# Example 3
subset(agri_methods(), grepl("implemented", status))
```
