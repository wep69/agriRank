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

# Example 2
x<-simulate_agri("crd");
x$biomass<-x$yield+rnorm(nrow(x));
d<-agri_design(yield~treatment,x,"crd");
agri_batch(d,c("yield","biomass"),adjust_across="BH")

# Example 3
x<-simulate_agri("crd");
x$biomass<-x$yield+rnorm(nrow(x));
x$spad<-30+x$yield+rnorm(nrow(x));
d<-agri_design(yield~treatment,x,"crd");
agri_batch(d,c("yield","biomass","spad"),adjust_across="holm")
```
