# Documentation architecture

The package documentation consists of 13 analytical vignettes, one dedicated `.Rd` page for every exported function, a long-form reference manual, a double-verified reference audit, and an integrated agronomic case study.

## Vignette sequence

1. `v01-design-crd-rcbd.Rmd` — Design Foundations, CRD, and RCBD
2. `v02-effects-conover-factorials.Rmd` — Effects, Conover, Contrasts, and Factorial Inference
3. `v03-hierarchical-designs-trends-ancova-power.Rmd` — Hierarchical Plot Designs, Trends, ANCOVA, and Power. Owns split-plot, split-split-plot and strip-plot, and the reasoning behind refusing an engine for those strata
4. `v04-repeated-measures-and-missing-data.Rmd` — Repeated Measures and Missing Longitudinal Data
5. `v05-multivariate-multienvironment-batch-sensitivity.Rmd` — Multivariate, Multi-Environment, Batch, and Sensitivity Workflows
6. `v06-nonparametric-regression.Rmd` — Nonparametric and Shape-Aware Regression for Agronomic Gradients
7. `v07-integer-support-regression.Rmd` — Integer-Support Nonparametric Regression for Agronomy
8. `v08-graphics-reporting-reproducibility.Rmd` — Graphics, Tables, Reports, and Reproducibility
9. `v09-integrated-agronomic-case-study.Rmd` — Integrated Agronomic Case Study: Design to Report
10. `v10-theory-state-of-art-common-mistakes.Rmd` — Methodological Foundations, State of the Art, and Common Mistakes
11. `v11-distribution-free-uncertainty-and-diagnostics.Rmd` — Distribution-Free Uncertainty and Model Checking for Agronomic Regression
12. `v12-optima-quantiles-and-block-structure.Rmd` — Optima, Quantiles, and How the Block Enters the Model
13. `v13-time-to-event-and-ranking-data.Rmd` — Time-to-Event and Ranking Data

The `v` prefix is not decorative. R requires a vignette file name to begin with a
letter, and the numbering must stay unique, since two files sharing a prefix
produce ambiguous cross-references that no check reports.

## Example policy

Every exported function has at least three examples. Optional-package examples are guarded with `requireNamespace()`. Resampling examples use deliberately small teaching values and explicitly instruct users to increase them for scientific work.

## State-of-the-art policy

Methodological claims are separated into: (1) established statistical methods, (2) adapters to established R packages, and (3) experimental agriRank integrations. The native incomplete repeated-measures wild-rank engine is explicitly marked experimental until independently benchmarked.

## Metadata policy

Core bibliographic metadata are stored in `inst/references/agriRank-methods-verified.ris` and audited in `inst/references/REFERENCE_VERIFICATION.md`. Each core record was checked against a publisher/journal/CRAN source and a second independent bibliographic source.
