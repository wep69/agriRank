# Analyze a randomized complete block design

Convenience wrapper for one- or multifactor treatment structures
randomized within blocks.

## Usage

``` r
np_rcbd(formula, data, block, method = "auto", ...)
```

## Arguments

- formula:

  A model formula defining the scientific treatment structure.

- data:

  A data frame, preferably in long format.

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

The block is part of the randomization and must not be discarded because
of a preliminary significance test. The vignette suite documents the
experimental-design logic, estimand, hypothesis, resampling structure,
missing/unbalanced-data behavior, and backend-specific limitations in
greater depth.

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
x<-simulate_agri("rcbd"); np_rcbd(yield~treatment,x,block)
#> agriRank fit
#>   Design: rcbd
#>   Method: Friedman rank-sum
#>   Response: yield
#>      effect statistic df    p_value
#> 1 treatment       8.4  3 0.03842932

# Example 2
x<-simulate_agri("rcbd"); x$score<-round(x$yield); np_rcbd(score~treatment,x,block,"friedman")
#> agriRank fit
#>   Design: rcbd
#>   Method: Friedman rank-sum
#>   Response: score
#>      effect statistic df    p_value
#> 1 treatment  6.980769  3 0.07251325

# Example 3
x<-simulate_agri("rcbd",n=8); np_rcbd(yield~treatment,x,block,"friedman")
#> agriRank fit
#>   Design: rcbd
#>   Method: Friedman rank-sum
#>   Response: yield
#>      effect statistic df     p_value
#> 1 treatment     12.75  3 0.005209652
```
