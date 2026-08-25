# Analyze multi-environment treatment data with enforced environment structure

Declares environment and optional within-environment block information
before fitting a rank/permutation workflow.

## Usage

``` r
agri_multienv(formula, data, environment, block = NULL, 
    method = "auto", environment_interaction = TRUE, ...)
```

## Arguments

- formula:

  Treatment formula. Environment may be omitted because it is enforced
  by this wrapper.

- data:

  Data frame.

- environment:

  One environment/site/year factor.

- block:

  Optional block factor; repeated block labels are namespaced within
  environment by block-aware engines.

- method:

  Inferential backend or \`"auto"\`.

- environment_interaction:

  If TRUE and environment is missing from the formula, add
  treatment-by-environment interactions. If FALSE, add the environment
  main effect only. An explicitly supplied environment formula is
  respected.

- ...:

  Additional backend arguments.

## Details

Direct `agri_design(..., design="multienv")` declarations require
environment to be in the formula. `agri_multienv()` is the convenience
layer that injects it when absent, preventing accidental pooled
genotype-only inference. When `environment_interaction = FALSE` creates
an additive multi-environment model, automatic routing uses permuco; the
ARTool adapter is reserved for factorial fixed-effect structures that
include the relevant interactions.

## Value

An \`agri_rank_fit\` with environment enforcement metadata.

## See also

`agri_design`, `agri_multivariate`, `agri_rank`

## Examples

``` r
x<-simulate_agri("multienv");
if (requireNamespace("ARTool", quietly = TRUE) || requireNamespace("permuco", 
    quietly = TRUE)) agri_multienv(yield ~ genotype, x, environment, block)
#> boundary (singular) fit: see help('isSingular')
#> boundary (singular) fit: see help('isSingular')
#> boundary (singular) fit: see help('isSingular')
#> agriRank fit
#>   Design: multienv
#>   Method: Aligned Rank Transform
#>   Response: yield
#>                   Term         F Df Df.res       Pr(>F)               effect
#> 1             genotype 6.8838985  3     45 0.0006496793             genotype
#> 2          environment 2.1474913  2     15 0.1513043770          environment
#> 3 genotype:environment 0.6783333  6     45 0.6677714985 genotype:environment
x<-simulate_agri("multienv");
if (requireNamespace("ARTool", quietly = TRUE)) agri_multienv(yield ~ genotype * 
    environment, x, environment, block, method = "ART")
#> boundary (singular) fit: see help('isSingular')
#> boundary (singular) fit: see help('isSingular')
#> boundary (singular) fit: see help('isSingular')
#> agriRank fit
#>   Design: multienv
#>   Method: Aligned Rank Transform
#>   Response: yield
#>                   Term         F Df Df.res       Pr(>F)               effect
#> 1             genotype 6.8838985  3     45 0.0006496793             genotype
#> 2          environment 2.1474913  2     15 0.1513043770          environment
#> 3 genotype:environment 0.6783333  6     45 0.6677714985 genotype:environment
x<-simulate_agri("multienv");
if (requireNamespace("permuco", quietly = TRUE)) agri_multienv(yield ~ 
    genotype, x, environment, block, method = "permuco", environment_interaction = FALSE, 
    np = 99)
#> Warning: The number of permutations is below 2000, p-values might be unreliable.
#> Warning: the distribution of  .agri_env_block, genotype, environment  may be discrete.
#> agriRank fit
#>   Design: multienv
#>   Method: permuco permutation ANOVA on mid-ranks
#>   Response: yield
#>                           SS df           F parametric P(>F) resampled P(>F)
#> .agri_env_block 2.959250e+03 17 0.457771978      0.960519785      0.94949495
#> genotype        7.147111e+03  3 6.265067420      0.001055334      0.01010101
#> environment     7.641286e-01  2 0.001004738      0.998995786      0.34343434
#> Residuals       1.939339e+04 51          NA               NA              NA
```
