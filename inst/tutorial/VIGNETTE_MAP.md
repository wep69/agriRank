# agriRank vignette map

The vignette suite is intentionally organized by analytical decision rather than
by function name. Thirteen vignettes, each owning one decision so that no topic
is stated in two places and free to drift.

## Designs, from the randomization outward

- `v01-design-crd-rcbd.Rmd` — **Design Foundations, CRD, and RCBD**
- `v03-hierarchical-designs-trends-ancova-power.Rmd` — **Hierarchical Plot Designs, Trends, ANCOVA, and Power.** Owns split-plot, split-split-plot and strip-plot, the degrees of freedom of each stratum, and the reasoning behind refusing an engine whose `Error()` form does not match field strata
- `v04-repeated-measures-and-missing-data.Rmd` — **Repeated Measures and Missing Longitudinal Data**
- `v05-multivariate-multienvironment-batch-sensitivity.Rmd` — **Multivariate, Multi-Environment, Batch, and Sensitivity Workflows**

## Effects and comparisons

- `v02-effects-conover-factorials.Rmd` — **Effects, Conover, Contrasts, and Factorial Inference**

## Regression for quantitative gradients

- `v06-nonparametric-regression.Rmd` — **Nonparametric and Shape-Aware Regression for Agronomic Gradients**
- `v07-integer-support-regression.Rmd` — **Integer-Support Nonparametric Regression for Agronomy**
- `v11-distribution-free-uncertainty-and-diagnostics.Rmd` — **Distribution-Free Uncertainty and Model Checking for Agronomic Regression**
- `v12-optima-quantiles-and-block-structure.Rmd` — **Optima, Quantiles, and How the Block Enters the Model**

## Data that are not measurements

- `v13-time-to-event-and-ranking-data.Rmd` — **Time-to-Event and Ranking Data**

## Reporting and background

- `v08-graphics-reporting-reproducibility.Rmd` — **Graphics, Tables, Reports, and Reproducibility**
- `v09-integrated-agronomic-case-study.Rmd` — **Integrated Agronomic Case Study: Design to Report**
- `v10-theory-state-of-art-common-mistakes.Rmd` — **Methodological Foundations, State of the Art, and Common Mistakes**

## On the numbering

The `v` prefix exists because R requires a vignette file name to begin with a
letter. The numbers must stay unique: two files sharing a prefix render fine and
pass `R CMD check`, but produce ambiguous cross-references. The order above is
topical, not numerical, and the two need not coincide.
