# Test an ordered treatment trend

Uses permutation of rank association, restricted within blocks when a
block is declared.

## Usage

``` r
agri_trend(design, treatment = NULL, scores = NULL, B = 4999, seed = 1)
```

## Arguments

- design:

  A declared design type or an \`agri_design\` object, depending on
  context.

- treatment:

  Ordered or quantitative treatment variable for a trend test.

- scores:

  Optional named numeric scores defining the treatment ordering.

- B:

  Number of bootstrap or resampling replicates. Small values are for
  examples only.

- seed:

  Random seed used for reproducible resampling.

## Details

Treatment scores should encode the scientifically meaningful ordering.
The vignette suite documents the experimental-design logic, estimand,
hypothesis, resampling structure, missing/unbalanced-data behavior, and
backend-specific limitations in greater depth.

## Value

An object of class `agri_trend`, accepted by
[`agri_table()`](https://wep69.github.io/agriRank/reference/agri_table.md),
[`agri_report()`](https://wep69.github.io/agriRank/reference/agri_report.md),
and
[`export_results()`](https://wep69.github.io/agriRank/reference/export_results.md).

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
x<-simulate_agri("rcbd");
x$dose<-rep(c(0,50,100,150),times=6);
d<-agri_design(yield~dose,x,"rcbd",block=block,quantitative=dose);
agri_trend(d,B=299)
#> $design
#> agriRank experimental design
#>   Design:   rcbd
#>   Response: yield
#>   Factors:  dose
#>   Block:    block
#>   Rows:     24
#> 
#> $method
#> [1] "permutation rank trend"
#> 
#> $statistic
#> [1] 0.6352906
#> 
#> $p_value
#> [1] 0.003333333
#> 
#> $B
#> [1] 299
#> 
#> $treatment
#> [1] "dose"
#> 
#> $seed
#> [1] 1
#> 
#> $note
#> [1] "Scores permuted within blocks."
#> 
#> attr(,"class")
#> [1] "agri_trend"

# Example 2
x<-simulate_agri("rcbd");
x$dose<-rep(c(0,50,100,150),times=6);
d<-agri_design(yield~dose,x,"rcbd",block=block,quantitative=dose);
agri_trend(d,treatment=dose,B=299)
#> $design
#> agriRank experimental design
#>   Design:   rcbd
#>   Response: yield
#>   Factors:  dose
#>   Block:    block
#>   Rows:     24
#> 
#> $method
#> [1] "permutation rank trend"
#> 
#> $statistic
#> [1] 0.6352906
#> 
#> $p_value
#> [1] 0.003333333
#> 
#> $B
#> [1] 299
#> 
#> $treatment
#> [1] "dose"
#> 
#> $seed
#> [1] 1
#> 
#> $note
#> [1] "Scores permuted within blocks."
#> 
#> attr(,"class")
#> [1] "agri_trend"

# Example 3
x<-simulate_agri("rcbd");
x$dose<-rep(c(0,50,100,150),times=6);
d<-agri_design(yield~dose,x,"rcbd",block=block,quantitative=dose);
agri_trend(d,treatment=dose,scores=c(`0`=0,`50`=1,`100`=3,`150`=6),B=299)
#> $design
#> agriRank experimental design
#>   Design:   rcbd
#>   Response: yield
#>   Factors:  dose
#>   Block:    block
#>   Rows:     24
#> 
#> $method
#> [1] "permutation rank trend"
#> 
#> $statistic
#> [1] 0.6357424
#> 
#> $p_value
#> [1] 0.003333333
#> 
#> $B
#> [1] 299
#> 
#> $treatment
#> [1] "dose"
#> 
#> $seed
#> [1] 1
#> 
#> $note
#> [1] "Scores permuted within blocks."
#> 
#> attr(,"class")
#> [1] "agri_trend"
```
