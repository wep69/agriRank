# Analyze a nonparametric factorial experiment

Convenience wrapper for factorial treatment structures with or without
blocks.

## Usage

``` r
np_factorial(formula, data, block = NULL, method = "auto", ...)
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

For unbalanced independent factorial designs, pseudo-rank methods are
generally preferable when unweighted relative effects are the estimand.
The vignette suite documents the experimental-design logic, estimand,
hypothesis, resampling structure, missing/unbalanced-data behavior, and
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
x<-simulate_agri("factorial"); np_factorial(yield~A*B,x)
#> agriRank fit
#>   Design: factorial
#>   Method: rankFD pseudo-rank factorial inference
#>   Response: yield
#>   effect statistic    df1     df2 p_value
#> 1      A    6.9339 1.0000 22.8596  0.0149
#> 2      B    6.6740 1.9702 22.8596  0.0054
#> 3    A:B    1.8632 1.9702 22.8596  0.1784

# Example 2
x<-simulate_agri("factorial");
if(requireNamespace("rankFD",quietly=TRUE)) np_factorial(yield~A*B,x,method="rankFD")
#> agriRank fit
#>   Design: factorial
#>   Method: rankFD pseudo-rank factorial inference
#>   Response: yield
#>   effect statistic    df1     df2 p_value
#> 1      A    6.9339 1.0000 22.8596  0.0149
#> 2      B    6.6740 1.9702 22.8596  0.0054
#> 3    A:B    1.8632 1.9702 22.8596  0.1784

# Example 3
x<-simulate_agri("factorial");
if(requireNamespace("ARTool",quietly=TRUE)) np_factorial(yield~A*B,x,method="ART")
#> agriRank fit
#>   Design: factorial
#>   Method: Aligned Rank Transform
#>   Response: yield
#>   Term Df Df.res    Sum Sq Sum Sq.res  F value       Pr(>F) effect
#> 1    A  1     30  802.7778   3074.333 7.833677 0.0088775925      A
#> 2    B  2     30 1441.5000   2416.333 8.948476 0.0008957788      B
#> 3  A:B  2     30  786.0556   3079.000 3.829436 0.0330224447    A:B
```
