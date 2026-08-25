# Analyze a split-plot experiment

Declares whole-plot and subplot strata before dispatching to a
compatible backend.

## Usage

``` r
np_splitplot(formula, data, block, whole_plot, subplot, method = "auto", ...)
```

## Arguments

- formula:

  A model formula defining the scientific treatment structure.

- data:

  A data frame, preferably in long format.

- block:

  Blocking variable(s) identifying the RCBD or nuisance randomization
  stratum.

- whole_plot:

  Whole-plot treatment factor(s).

- subplot:

  Subplot treatment factor(s).

- method:

  Inferential engine name or \`"auto"\` for conservative design-based
  routing.

- ...:

  Additional arguments passed to the selected backend or downstream
  method.

## Details

A split-plot design contains hierarchical randomization and must not be
analyzed as a simple CRD. The vignette suite documents the
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
# Example 1: the automatic method now selects ART for split-plots
x <- simulate_agri("split_plot")
np_splitplot(yield ~ irrigation * cultivar, x, block, irrigation, cultivar)
#> boundary (singular) fit: see help('isSingular')
#> agriRank fit
#>   Design: split_plot
#>   Method: Aligned Rank Transform
#>   Response: yield
#>                  Term         F Df Df.res     Pr(>F)              effect
#> 1          irrigation 8.1181321  1      5 0.03585593          irrigation
#> 2            cultivar 0.5095211  2     20 0.60837413            cultivar
#> 3 irrigation:cultivar 1.1429826  2     20 0.33883281 irrigation:cultivar

# Example 2: explicitly request ART
x <- simulate_agri("split_plot")
if (requireNamespace("ARTool", quietly = TRUE)) np_splitplot(yield ~ irrigation * 
    cultivar, x, block, irrigation, cultivar, "ART")
#> boundary (singular) fit: see help('isSingular')
#> agriRank fit
#>   Design: split_plot
#>   Method: Aligned Rank Transform
#>   Response: yield
#>                  Term         F Df Df.res     Pr(>F)              effect
#> 1          irrigation 8.1181321  1      5 0.03585593          irrigation
#> 2            cultivar 0.5095211  2     20 0.60837413            cultivar
#> 3 irrigation:cultivar 1.1429826  2     20 0.33883281 irrigation:cultivar
```
