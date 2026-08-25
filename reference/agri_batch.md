# Analyze multiple responses under one design

Fits the same declared design to several response columns, optionally
adjusting p-values across responses.

## Usage

``` r
agri_batch(design, responses = NULL, method = "auto", adjust_across = c("none", 
    "BH", "holm"), ...)
```

## Arguments

- design:

  A declared design type or an \`agri_design\` object, depending on
  context.

- responses:

  Response column names for batch analysis.

- method:

  Inferential engine name or \`"auto"\` for conservative design-based
  routing.

- adjust_across:

  Optional p-value adjustment across responses/effects in a batch table.

- ...:

  Additional arguments passed to the selected backend or downstream
  method.

## Details

Across-response multiplicity adjustment is explicit rather than
automatic. The vignette suite documents the experimental-design logic,
estimand, hypothesis, resampling structure, missing/unbalanced-data
behavior, and backend-specific limitations in greater depth.

## Value

An \`agri_batch\` object.

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
x<-simulate_agri("crd");
x$biomass<-x$yield+rnorm(nrow(x));
d<-agri_design(yield~treatment,x,"crd");
agri_batch(d,c("yield","biomass"))
#> $design
#> agriRank experimental design
#>   Design:   crd
#>   Response: yield
#>   Factors:  treatment
#>   Rows:     24
#> 
#> $fits
#> $fits$yield
#> agriRank fit
#>   Design: crd
#>   Method: Kruskal-Wallis
#>   Response: yield
#>      effect statistic df   p_value
#> 1 treatment  1.646667  3 0.6488554
#> 
#> $fits$biomass
#> agriRank fit
#>   Design: crd
#>   Method: Kruskal-Wallis
#>   Response: biomass
#>      effect statistic df   p_value
#> 1 treatment 0.3266667  3 0.9549376
#> 
#> 
#> $summary
#>   response    effect   p_value status
#> 1    yield treatment 0.6488554     ok
#> 2  biomass treatment 0.9549376     ok
#> 
#> $adjust_across
#> [1] "none"
#> 
#> attr(,"class")
#> [1] "agri_batch"

# Example 2
x<-simulate_agri("crd");
x$biomass<-x$yield+rnorm(nrow(x));
d<-agri_design(yield~treatment,x,"crd");
agri_batch(d,c("yield","biomass"),adjust_across="BH")
#> $design
#> agriRank experimental design
#>   Design:   crd
#>   Response: yield
#>   Factors:  treatment
#>   Rows:     24
#> 
#> $fits
#> $fits$yield
#> agriRank fit
#>   Design: crd
#>   Method: Kruskal-Wallis
#>   Response: yield
#>      effect statistic df   p_value
#> 1 treatment  1.646667  3 0.6488554
#> 
#> $fits$biomass
#> agriRank fit
#>   Design: crd
#>   Method: Kruskal-Wallis
#>   Response: biomass
#>      effect statistic df   p_value
#> 1 treatment  1.313333  3 0.7259694
#> 
#> 
#> $summary
#>   response    effect   p_value status p_across_adjusted
#> 1    yield treatment 0.6488554     ok         0.7259694
#> 2  biomass treatment 0.7259694     ok         0.7259694
#> 
#> $adjust_across
#> [1] "BH"
#> 
#> attr(,"class")
#> [1] "agri_batch"

# Example 3
x<-simulate_agri("crd");
x$biomass<-x$yield+rnorm(nrow(x));
x$spad<-30+x$yield+rnorm(nrow(x));
d<-agri_design(yield~treatment,x,"crd");
agri_batch(d,c("yield","biomass","spad"),adjust_across="holm")
#> $design
#> agriRank experimental design
#>   Design:   crd
#>   Response: yield
#>   Factors:  treatment
#>   Rows:     24
#> 
#> $fits
#> $fits$yield
#> agriRank fit
#>   Design: crd
#>   Method: Kruskal-Wallis
#>   Response: yield
#>      effect statistic df   p_value
#> 1 treatment  1.646667  3 0.6488554
#> 
#> $fits$biomass
#> agriRank fit
#>   Design: crd
#>   Method: Kruskal-Wallis
#>   Response: biomass
#>      effect statistic df   p_value
#> 1 treatment 0.3533333  3 0.9497047
#> 
#> $fits$spad
#> agriRank fit
#>   Design: crd
#>   Method: Kruskal-Wallis
#>   Response: spad
#>      effect statistic df   p_value
#> 1 treatment      2.18  3 0.5358985
#> 
#> 
#> $summary
#>   response    effect   p_value status p_across_adjusted
#> 1    yield treatment 0.6488554     ok                 1
#> 2  biomass treatment 0.9497047     ok                 1
#> 3     spad treatment 0.5358985     ok                 1
#> 
#> $adjust_across
#> [1] "holm"
#> 
#> attr(,"class")
#> [1] "agri_batch"
```
