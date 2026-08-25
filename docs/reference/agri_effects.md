# Extract treatment effect summaries

Returns backend-provided effects when available or observed-cell
descriptive rank summaries otherwise.

## Usage

``` r
agri_effects(x, ci = FALSE, level = 0.95, B = if (ci) 999 else 0, seed = 1)
```

## Arguments

- x:

  An agriRank design or fitted object as documented for the function.

- ci:

  Logical; request uncertainty intervals when supported.

- level:

  Confidence level.

- B:

  Number of bootstrap or resampling replicates. Small values are for
  examples only.

- seed:

  Random seed used for reproducible resampling.

## Details

Interpret the returned effect according to the engine and estimand. The
vignette suite documents the experimental-design logic, estimand,
hypothesis, resampling structure, missing/unbalanced-data behavior, and
backend-specific limitations in greater depth.

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
fit<-np_crd(yield~treatment,simulate_agri("crd")); agri_effects(fit)
#>   cell n   median mean_rank
#> 1    A 6 5.990484  12.00000
#> 2    B 6 6.779350  12.50000
#> 3    C 6 6.583064  15.33333
#> 4    D 6 5.165202  10.16667

# Example 2
fit<-np_crd(yield~treatment,simulate_agri("crd")); agri_effects(fit,ci=TRUE,B=199)
#>   cell n   median mean_rank
#> 1    A 6 5.990484  12.00000
#> 2    B 6 6.779350  12.50000
#> 3    C 6 6.583064  15.33333
#> 4    D 6 5.165202  10.16667

# Example 3
x<-simulate_agri("factorial");
if(requireNamespace("rankFD",quietly=TRUE)){fit<-np_factorial(yield~A*B,x,method="rankFD");
agri_effects(fit)}
#>     cell n   median mean_rank
#> 1 A1::B1 6 4.329297  13.16667
#> 2 A1::B2 6 4.706755  12.50000
#> 3 A1::B3 6 5.516125  18.66667
#> 4 A2::B1 6 4.640361  13.66667
#> 5 A2::B2 6 5.503617  20.50000
#> 6 A2::B3 6 7.978105  32.50000
```
