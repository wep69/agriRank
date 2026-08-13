# Documentation architecture

The package documentation consists of 18 analytical vignettes, one dedicated `.Rd` page for every exported function, a long-form reference manual, a double-verified reference audit, and an integrated agronomic case study.

## Vignette sequence

1. `00-overview.Rmd` — Design-aware nonparametric inference for agricultural experiments
2. `01-design-validation.Rmd` — Declaring and validating agricultural experiments
3. `02-crd-oneway.Rmd` — Completely randomized designs and one-way inference
4. `03-rcbd.Rmd` — Randomized complete block designs
5. `04-factorial.Rmd` — Nonparametric factorial experiments
6. `05-effects-contrasts.Rmd` — Effect estimation, contrasts and multiple comparisons
7. `06-splitplot.Rmd` — Split-plot experiments and hierarchical randomization
8. `07-repeated-measures.Rmd` — Rank-based repeated-measures inference
9. `08-missing-repeated.Rmd` — Missing data in repeated-measures experiments
10. `09-trend-ancova-power.Rmd` — Quantitative treatments, covariate adjustment and power
11. `10-multivariate-multienv.Rmd` — Multivariate responses and multi-environment experiments
12. `11-batch-sensitivity.Rmd` — Batch workflows and inferential sensitivity
13. `12-graphics.Rmd` — Scientific graphics and interactive exploration
14. `13-reporting.Rmd` — Tables, reports and reproducibility
15. `14-theory-state-of-art.Rmd` — Statistical foundations and state of the art
16. `15-integrated-agronomic-case.Rmd` — From experimental design to a reproducible agronomic report
17. `16-nonparametric-regression.Rmd` — Nonparametric and shape-aware regression for agronomic gradients
18. `17-integer-support-regression.Rmd` — Integer-support nonparametric regression and discrete agronomic decisions

## Example policy

Every exported function has at least three examples. Optional-package examples are guarded with `requireNamespace()`. Resampling examples use deliberately small teaching values and explicitly instruct users to increase them for scientific work.

## State-of-the-art policy

Methodological claims are separated into: (1) established statistical methods, (2) adapters to established R packages, and (3) experimental agriRank integrations. The native incomplete repeated-measures wild-rank engine is explicitly marked experimental until independently benchmarked.

## Metadata policy

Core bibliographic metadata are stored in `inst/references/agriRank-methods-verified.ris` and audited in `inst/references/REFERENCE_VERIFICATION.md`. Each core record was checked against a publisher/journal/CRAN source and a second independent bibliographic source.
