# Extract treatment effect summaries

Estimates of the effect declared in `agri_rank(estimand = )`. The
descriptive block (`cell`, `n`, `median`, `mean_rank`) is always
reported and the estimator of the declared estimand is added beside it,
so the declaration changes the numbers and not only the label.

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

The added estimator follows `fit$estimand`. For `"relative_effect"` it
is the Brunner-Munzel relative effect of each cell against the pooled
sample, `p_i = (Rbar_i - (n_i + 1)/2) / N`, which is a function of the
mean rank already reported and is the quantity the rank-based omnibus
test is about. For `"location_shift"` it is the Hodges-Lehmann shift of
each cell against the first level, which is named in the `reference`
column, because a location shift is a paired statement. For
`"distribution"` the descriptive block stands alone, because the target
is the whole distribution and not a single summary number.

Before 0.14.1 the three values returned exactly the same table, so a
user who declared a relative-effect analysis received medians without
being told. When the selected engine estimates effects itself, as nparLD
and the native wild bootstrap do, those engine estimates are returned
and `fit$estimand_source` records that the engine answered the
declaration. The vignette suite documents the experimental-design logic,
estimand, hypothesis, resampling structure, missing/unbalanced-data
behavior, and backend-specific limitations in greater depth.

## Value

A data frame with one row per treatment cell.

## References

Pauly M, Brunner E, Konietschke F (2015), DOI: 10.1111/rssb.12073.
Brunner E, Konietschke F, Pauly M, Puri ML (2017), DOI:
10.1111/rssb.12222. Konietschke F, Brunner E (2023), DOI:
10.32614/RJ-2023-029. See the package vignettes and
\`inst/references/agriRank-methods-verified.ris\` for engine-specific
verified references.

## See also

`agri_design`, `agri_rank`, `agri_effects`, `agri_p`, `agri_report`

## Examples

``` r
# Example 1
fit<-np_crd(yield~treatment,simulate_agri("crd")); agri_effects(fit)
#>   cell n   median mean_rank relative_effect
#> 1    A 6 5.990484  12.00000       0.3541667
#> 2    B 6 6.779350  12.50000       0.3750000
#> 3    C 6 6.583064  15.33333       0.4930556
#> 4    D 6 5.165202  10.16667       0.2777778

# Example 2
fit<-np_crd(yield~treatment,simulate_agri("crd")); agri_effects(fit,ci=TRUE,B=199)
#>   cell n   median mean_rank relative_effect
#> 1    A 6 5.990484  12.00000       0.3541667
#> 2    B 6 6.779350  12.50000       0.3750000
#> 3    C 6 6.583064  15.33333       0.4930556
#> 4    D 6 5.165202  10.16667       0.2777778

# Example 3
x<-simulate_agri("factorial");
if(requireNamespace("rankFD",quietly=TRUE)){fit<-np_factorial(yield~A*B,x,method="rankFD");
agri_effects(fit)}
#>     cell n   median mean_rank relative_effect
#> 1 A1::B1 6 4.329297  13.16667       0.2685185
#> 2 A1::B2 6 4.706755  12.50000       0.2500000
#> 3 A1::B3 6 5.516125  18.66667       0.4212963
#> 4 A2::B1 6 4.640361  13.66667       0.2824074
#> 5 A2::B2 6 5.503617  20.50000       0.4722222
#> 6 A2::B3 6 7.978105  32.50000       0.8055556

# Example 4, the declaration selects the estimator
d<-agri_design(yield~treatment,simulate_agri("crd"),"crd");
agri_effects(agri_rank(d,estimand="relative_effect"))
#>   cell n   median mean_rank relative_effect
#> 1    A 6 5.990484  12.00000       0.3541667
#> 2    B 6 6.779350  12.50000       0.3750000
#> 3    C 6 6.583064  15.33333       0.4930556
#> 4    D 6 5.165202  10.16667       0.2777778
agri_effects(agri_rank(d,estimand="location_shift"))
#>   cell n   median mean_rank reference hodges_lehmann
#> 1    A 6 5.990484  12.00000         A      0.0000000
#> 2    B 6 6.779350  12.50000         A      0.2155826
#> 3    C 6 6.583064  15.33333         A      1.1658629
#> 4    D 6 5.165202  10.16667         A     -0.3961795
```
