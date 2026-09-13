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
x<-simulate_agri("multienv");
if (requireNamespace("ARTool", quietly = TRUE)) agri_multienv(yield ~ genotype * 
    environment, x, environment, block, method = "ART")
x<-simulate_agri("multienv");
if (requireNamespace("permuco", quietly = TRUE)) agri_multienv(yield ~ 
    genotype, x, environment, block, method = "permuco", environment_interaction = FALSE, 
    np = 99)
```
