# Fit a permutation ANCOVA adapter

Uses \`permuco\` Freedman-Lane permutation ANCOVA, optionally on
response mid-ranks.

## Usage

``` r
agri_ancova(formula, data, covariates, block = NULL, nperm = 4999, seed = 1, 
    rank_response = TRUE, np = NULL, ...)
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

- nperm:

  Number of permutations passed to `permuco`. It must be a single
  positive number; the p-value cannot fall below `1/(nperm + 1)`.

- seed:

  Random seed used for reproducible resampling.

- rank_response:

  Logical; if \`TRUE\`, apply Freedman-Lane ANCOVA to response
  mid-ranks.

- np:

  Deprecated name of `nperm`. In a nonparametric package `np` reads as a
  switch while being a count, so the argument was renamed; this alias
  warns and forwards.

- ...:

  Additional arguments passed to the selected backend or downstream
  method.

## Details

This function is not the 2026 resampling NANCOVA method; that remains a
future engine. The examples below use the deprecated `np` name on
purpose, because that is how the argument appeared in the released
0.14.0 and the alias must keep them working. The vignette suite
documents the experimental-design logic, estimand, hypothesis,
resampling structure, missing/unbalanced-data behavior, and
backend-specific limitations in greater depth.

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

# Example 2
if(requireNamespace("permuco",quietly=TRUE)){x<-simulate_agri("crd");
x$base<-rnorm(nrow(x));
agri_ancova(yield~treatment,x,covariates=base,np=299,rank_response=FALSE)}

# Example 3
if(requireNamespace("permuco",quietly=TRUE)){x<-simulate_agri("rcbd");
x$base<-rnorm(nrow(x));
agri_ancova(yield~treatment,x,covariates=base,block=block,np=299)}
```
