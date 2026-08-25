# Fit a permutation ANCOVA adapter

Uses \`permuco\` Freedman-Lane permutation ANCOVA, optionally on
response mid-ranks.

## Usage

``` r
agri_ancova(formula, data, covariates, block = NULL, np = 4999, seed = 1, 
    rank_response = TRUE, ...)
```

## Arguments

- formula:

  A model formula defining the scientific treatment structure.

- data:

  A data frame, preferably in long format.

- covariates:

  Covariate column name(s) used as nuisance adjustment variables.

- block:

  Blocking variable(s) identifying the RCBD or nuisance randomization
  stratum.

- np:

  Number of permutations passed to \`permuco\`.

- seed:

  Random seed used for reproducible resampling.

- rank_response:

  Logical; if \`TRUE\`, apply Freedman-Lane ANCOVA to response
  mid-ranks.

- ...:

  Additional arguments passed to the selected backend or downstream
  method.

## Details

This function is not the 2026 resampling NANCOVA method; that remains a
future engine. The vignette suite documents the experimental-design
logic, estimand, hypothesis, resampling structure,
missing/unbalanced-data behavior, and backend-specific limitations in
greater depth.

## Value

An object of class `agri_ancova_fit`, accepted by
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
if(requireNamespace("permuco",quietly=TRUE)){x<-simulate_agri("crd");
x$base<-rnorm(nrow(x));
agri_ancova(yield~treatment,x,covariates=base,np=299)}
#> Warning: The number of permutations is below 2000, p-values might be unreliable.
#> $method
#> [1] "Freedman-Lane permutation ANCOVA on response mid-ranks"
#> 
#> $formula
#> .agri_rank_y ~ base + treatment
#> <environment: 0x55fd838665a0>
#> 
#> $covariates
#> [1] "base"
#> 
#> $block
#> NULL
#> 
#> $response
#> [1] "yield"
#> 
#> $seed
#> [1] 1
#> 
#> $omnibus
#>                   SS df         F parametric P(>F) resampled P(>F)
#> base        50.91219  1 0.9513916        0.3416214       0.3678930
#> treatment   91.28192  3 0.5685924        0.6424474       0.6120401
#> Residuals 1016.75448 19        NA               NA              NA
#> 
#> $raw
#> Anova Table
#> Resampling test using freedman_lane to handle nuisance variables and 299 permutations.
#>                SS df      F parametric P(>F) resampled P(>F)
#> base        50.91  1 0.9514           0.3416          0.3679
#> treatment   91.28  3 0.5686           0.6424          0.6120
#> Residuals 1016.75 19                                        
#> 
#> $call
#> agri_ancova(formula = yield ~ treatment, data = x, covariates = base, 
#>     np = 299)
#> 
#> attr(,"class")
#> [1] "agri_ancova_fit"

# Example 2
if(requireNamespace("permuco",quietly=TRUE)){x<-simulate_agri("crd");
x$base<-rnorm(nrow(x));
agri_ancova(yield~treatment,x,covariates=base,np=299,rank_response=FALSE)}
#> Warning: The number of permutations is below 2000, p-values might be unreliable.
#> $method
#> [1] "Freedman-Lane permutation ANCOVA"
#> 
#> $formula
#> yield ~ base + treatment
#> <environment: 0x55fd82b5d848>
#> 
#> $covariates
#> [1] "base"
#> 
#> $block
#> NULL
#> 
#> $response
#> [1] "yield"
#> 
#> $seed
#> [1] 1
#> 
#> $omnibus
#>                   SS df         F parametric P(>F) resampled P(>F)
#> base        2.288271  1 0.2539565        0.6200962       0.5852843
#> treatment   9.036498  3 0.3342956        0.8006775       0.7792642
#> Residuals 171.199235 19        NA               NA              NA
#> 
#> $raw
#> Anova Table
#> Resampling test using freedman_lane to handle nuisance variables and 299 permutations.
#>                SS df      F parametric P(>F) resampled P(>F)
#> base        2.288  1 0.2540           0.6201          0.5853
#> treatment   9.036  3 0.3343           0.8007          0.7793
#> Residuals 171.199 19                                        
#> 
#> $call
#> agri_ancova(formula = yield ~ treatment, data = x, covariates = base, 
#>     np = 299, rank_response = FALSE)
#> 
#> attr(,"class")
#> [1] "agri_ancova_fit"

# Example 3
if(requireNamespace("permuco",quietly=TRUE)){x<-simulate_agri("rcbd");
x$base<-rnorm(nrow(x));
agri_ancova(yield~treatment,x,covariates=base,block=block,np=299)}
#> Warning: The number of permutations is below 2000, p-values might be unreliable.
#> $method
#> [1] "Freedman-Lane permutation ANCOVA on response mid-ranks"
#> 
#> $formula
#> .agri_rank_y ~ block + base + treatment
#> <environment: 0x55fd823d83e8>
#> 
#> $covariates
#> [1] "base"
#> 
#> $block
#> [1] "block"
#> 
#> $response
#> [1] "yield"
#> 
#> $seed
#> [1] 1
#> 
#> $omnibus
#>                  SS df        F parametric P(>F) resampled P(>F)
#> block     181.47586  5 1.125320       0.39161224      0.40802676
#> base       57.28844  1 1.776209       0.20390063      0.25752508
#> treatment 537.37321  3 5.553693       0.01006666      0.01672241
#> Residuals 451.54489 14       NA               NA              NA
#> 
#> $raw
#> Anova Table
#> Resampling test using freedman_lane to handle nuisance variables and 299 permutations.
#>               SS df     F parametric P(>F) resampled P(>F)
#> block     181.48  5 1.125          0.39161         0.40803
#> base       57.29  1 1.776          0.20390         0.25753
#> treatment 537.37  3 5.554          0.01007         0.01672
#> Residuals 451.54 14                                       
#> 
#> $call
#> agri_ancova(formula = yield ~ treatment, data = x, covariates = base, 
#>     block = block, np = 299)
#> 
#> attr(,"class")
#> [1] "agri_ancova_fit"
```
