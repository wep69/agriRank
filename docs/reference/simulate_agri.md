# Simulate representative agricultural experiments

Generates reproducible teaching data for CRD, RCBD, factorial,
split-plot, split-split, strip-plot, repeated, incomplete repeated, and
multi-environment workflows, and for the three quantitative-gradient
scenarios used by the regression module.

## Usage

``` r
simulate_agri(
  design = c("crd", "rcbd", "factorial", "split_plot",
    "split_split", "strip_plot", "repeated",
    "repeated_missing", "multienv", "dose_response",
    "integer_density", "surface"),
  seed = 123,
  n = 6,
  missing_rate = 0.2
)
```

## Arguments

- design:

  A declared design type or an \`agri_design\` object, depending on
  context.

- seed:

  Random seed used for reproducible resampling.

- n:

  Replication or block count used by the selected synthetic-data
  generator.

- missing_rate:

  Probability used to introduce missing responses in the synthetic
  repeated-data generator.

## Details

These are synthetic teaching data, not evidence from real experiments.
The vignette suite documents the experimental-design logic, estimand,
hypothesis, resampling structure, missing/unbalanced-data behavior, and
backend-specific limitations in greater depth.

The quantitative-gradient scenarios mirror the exported data sets and
are meant for the regression module:

- `"dose_response"`:

  Nitrogen rate in kg ha\\^{-1}\\ from 0 to 280 in `n` blocks, with a
  quadratic-plateau response. Compare
  [`agri_dose`](https://wep69.github.io/agriRank/reference/agri_dose.md).

- `"integer_density"`:

  Plants per hill from 1 to 9 in `n` blocks, with a unimodal response.
  Compare
  [`agri_density`](https://wep69.github.io/agriRank/reference/agri_density.md).

- `"surface"`:

  Nitrogen by irrigation depth with a positive cross term. Compare
  [`agri_surface`](https://wep69.github.io/agriRank/reference/agri_surface.md).

Use the exported data sets when a fixed, citable example is wanted, and
these generators when a fresh replicate of the same structure is wanted.

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
simulate_agri("crd",seed=1)

# Example 2
simulate_agri("repeated_missing",seed=2,n=8,missing_rate=.15)

# Example 3
simulate_agri("multienv",seed=3,n=5)

# Example 4: a fresh replicate of the nitrogen-rate structure
head(simulate_agri("dose_response", seed = 4, n = 4))

# Example 5: an integer treatment for the discrete-decision workflow
head(simulate_agri("integer_density", seed = 5, n = 4))

# Example 6: two interacting quantitative gradients
head(simulate_agri("surface", seed = 6, n = 6))
```
