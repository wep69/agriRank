# agriRank 0.9.0.9000: definitive statistical scope implemented

This document maps the 20 design and statistical decisions of the definitive scope to code. The package is intentionally modular: specialized, mature methods are called through adapters, while design semantics, validation, reporting and the incomplete repeated-measures wild-rank engine are maintained in `agriRank`.

## 1. Positioning

Implemented as an R workflow for design-aware rank-based, permutation and robust inference in agricultural experiments. `agriRank` does not claim novelty for individual legacy tests; novelty is sought in the design-to-inference integration and in reproducible agricultural workflow semantics.

## 2. Statistical scope

Declared design types: CRD/DIC, RCBD/DBC, factorial, split-plot, split-split, strip-plot, repeated/longitudinal, multi-environment and multivariate. Core inference is most mature for CRD, RCBD, factorial and repeated measurements. Split-split/strip-plot are represented in the design object and require specialist adapters for confirmatory analysis.

## 3. API

Core functions: `agri_design()`, `agri_rank()`, `agri_effects()`, `agri_pairs()`, `agri_contrast()`, `agri_plot()`, `agri_report()`. Pedagogical wrappers: `np_crd()`, `np_rcbd()`, `np_factorial()`, `np_splitplot()`, `np_repeated()`.

## 4. S3 classes

Implemented: `agri_design`, `agri_rank_fit`, `agri_incomplete_wild`, `agri_batch`, `agri_sensitivity`, `agri_power`, and missing-data report objects. Print, summary, ANOVA, plot and confidence-interval methods are supplied where applicable.

## 5. `agri_design()` as the package core

Stores formula, response(s), factors, factor type, block, subject, within factors, whole-plot/subplot variables, environment, row/unit identifiers, randomization description and validation results. The design object is passed to all subsequent inference functions.

## 6. Automatic design validation

Implemented checks include missing design variables, completely missing responses, missing response counts, duplicate repeated cells, numeric block warnings, empty factorial cells, repeated subject/occasion duplication and structural requirements for RCBD, split-plot and repeated designs. Technical replicates are not silently averaged.

## 7. Statistical engine layer

Adapters are implemented for `rankFD`, `ARTool`, `permuco`, `nparLD` and `MANOVA.RM`, plus native Kruskal-Wallis, Friedman and incomplete repeated-measures wild-rank engines. Optional dependencies are kept in `Suggests` and fail with explicit installation messages.

## 8. CRD/DIC one-way

Implemented Kruskal-Wallis compatibility analysis, effect summaries, Wilcoxon pairwise comparisons with multiplicity adjustment and probabilistic effect-size summaries. General factorial CRD routes preferentially to `rankFD`, then ART/permutation adapters.

## 9. RCBD/DBC

Implemented classical Friedman analysis for complete one-observation-per-block-by-treatment layouts. Pairwise comparisons preserve pairing by block when the compared cells have unique observations per block. Factorial RCBD routes to mixed ART or permutation adapters rather than pretending that ordinary Kruskal-Wallis represents the block/factorial structure.

## 10. Permutation engine

`permuco` is integrated for fixed/repeated error structures and nuisance-variable handling. `agri_trend()` implements a native randomization trend test that permutes scores within blocks for RCBD. The package does not label unrestricted shuffling as a blocked randomization test.

## 11. General factorial effects

Factorial main effects and interactions are represented by formula terms. Independent factorial designs use `rankFD` when available. ART and permutation adapters are alternatives/sensitivity methods. Native repeated-measures contrast construction uses orthogonal Helmert bases and equal weighting over nuisance factor levels.

## 12. Estimands

`agri_rank()` records the requested estimand: relative effect, distributional hypothesis or location shift. Backend methods retain their native estimand interpretation instead of translating all procedures into a generic mean comparison.

## 13. Relative effects

The native incomplete repeated engine estimates relative marginal effects from normalized global mid-ranks using all observed repeated measurements. `nparLD` relative-treatment-effect output is retained directly when that backend is used.

## 14. Effect sizes

Implemented probability of superiority/Vargha-Delaney A, Cliff-type delta and Hodges-Lehmann location shift for independent cell comparisons, plus native relative marginal effects for the incomplete repeated engine. Effect reporting is separated from p-values.

## 15. Multiple comparisons

Implemented ordinary pairwise Wilcoxon comparisons with multiplicity adjustment; block-paired comparisons when an RCBD pairing exists; and, for the native repeated engine, arbitrary linear contrasts with a subject-level wild-bootstrap max-T calibration, adjusted p-values and simultaneous confidence intervals.

## 16. Compact letter display

`agri_cld()` is available through `multcompView` for pairwise group comparisons. CLD is intentionally downstream of estimates, intervals and adjusted pairwise inference, not the primary result.

## 17. Interaction-first workflow

Factorial interaction terms remain explicit in omnibus output. `agri_pairs(..., by=)` supports simple-effect style comparisons for ordinary designs. Native repeated contrasts can be conditioned by other cell factors. ART users are warned that ART-C is preferred for multifactor contrasts.

## 18. Split-plot

`agri_design(..., design="split_plot")` represents block, whole-plot and subplot factors explicitly. `np_splitplot()` routes to `permuco` when available and otherwise to ARTool. These backends preserve error/random-effect semantics better than a one-way rank test. Split-split/strip-plot representation is present but must be independently validated before a CRAN 1.0 confirmatory claim.

## 19. Repeated measures

This module is implemented at three levels:

1. **`nparLD` adapter** for rank-based longitudinal factorial designs. It retains ATS/WTS and relative-treatment-effect output.
2. **`MANOVA.RM` adapter** for semi-parametric repeated-measures WTS/ATS with permutation, parametric bootstrap or Rademacher wild bootstrap.
3. **Native wild-rank engine** for complete or incomplete repeated measurements. Between-subject factor combinations become independent groups; within-factor combinations become repeated coordinates. Subject-specific labels are made group-specific to prevent accidental cross-group ID collisions. Effect contrasts are built from the declared factorial structure rather than hard-coded treatment/time names.

The native engine calculates WTS, ATS and MATS, with ATS as default. Rademacher weights are default, with Mammen, normal and centered-Poisson multipliers available for methodological sensitivity. The same multiplier is applied to all repeated coordinates of a subject in a bootstrap replicate, preserving the within-subject dependence pattern.

### Block-aware repeated-measures guardrail

For repeated/longitudinal designs with an additional agronomic block stratum, complete data are routed to `permuco` in automatic mode so the block is retained as a nuisance term together with the repeated `Error()` structure. The native incomplete-data wild-rank engine **refuses** blocked incomplete repeated measures rather than silently discarding blocks. A confirmatory block-aware extension of the 2024 incomplete repeated-measures method requires separate methodological validation and is intentionally not fabricated here.

## 20. Missing data

Missingness is a first-class analysis module, not a preprocessing side effect.

### Characterization

`agri_missing_report()` returns total missingness, per-occasion missing rates, complete/incomplete subject counts, observed-pattern frequencies, monotone/nonmonotone pattern counts and an observation matrix. It explicitly states that MCAR/MAR/MNAR cannot be established from observed data alone.

### Native all-available inference

`incomplete_wild_rank_test()` implements the published incomplete repeated-measures rank framework of Amro, Konietschke & Pauly (2024):

- observation indicators are retained;
- global normalized mid-ranks are computed over all observed coordinates;
- relative marginal effects use the observed-cell denominators;
- within-group covariance estimators use observed-pair counts;
- WTS, ATS and MATS quadratic forms are calculated;
- subject-level wild multipliers generate bootstrap rank vectors;
- bootstrap covariance matrices are recalculated on every replicate;
- bootstrap WTS/ATS/MATS calibrate effect-specific null tests.

The theoretical assumption is recorded with the fit. The main theory is MCAR-based. An `unspecified` setting is allowed for exploratory computation but emits an explicit warning; it is not silently relabeled MCAR. `MAR-sensitivity` is a label for sensitivity work, not a claim of general MAR validity.

### Sensitivity analysis

`agri_missing_sensitivity()` compares the all-available native analysis against a complete-subject analysis using the same inferential engine. Differences are reported as sensitivity evidence only; they do not diagnose the missingness mechanism.

### No silent data alteration

The package performs no automatic mean imputation, no automatic multiple imputation, and no automatic complete-case deletion for incomplete repeated-measures inference.

## Additional implemented workflow components

- `agri_sensitivity()`: cross-engine sensitivity without p-value shopping.
- `agri_batch()`: multiple response variables under one design.
- `agri_power()`: simulation-based power using the actual user-supplied generator and analysis pipeline.
- `agri_trend()`: ordered-treatment permutation trend, block-restricted when blocks exist.
- `agri_ancova()`: permutation ANCOVA adapter through `permuco`.
- `agri_multivariate()`: `MANOVA.RM` multivariate adapter.
- `agri_multienv()`: multi-environment design wrapper.
- `agri_plot()`: raw distributions, effects, interactions, contrasts and missingness with `ggplot2`.
- `agri_interactive()`: Plotly conversion.
- `agri_table()`: data frame or `gt` table output.
- `agri_report()` / `agri_dashboard()`: reproducible Markdown/Quarto and optional rendered reports.
- `simulate_agri()`: deterministic example generators for CRD, RCBD, factorial, split-plot, repeated, repeated-missing and multi-environment data.

## Current validation status

The package source has undergone static delimiter/string checks in the present build environment. An R interpreter is not available in that environment, therefore `R CMD check`, execution of `testthat`, numerical comparison against CRAN backends and benchmarking against the authors' supporting code remain mandatory before claiming CRAN-readiness or confirmatory validation. The native incomplete wild-rank engine is explicitly marked experimental for this reason.

## 21. Design-aware Conover multiple comparisons

Implemented through `agri_conover()` and `agri_pairs(method = "conover")`.

- CRD/independent one-way: Conover all-pairs procedure following Kruskal-type ranking via `PMCMRplus::kwAllPairsConoverTest()`.
- complete unreplicated RCBD: block-preserving Friedman-type Conover via `PMCMRplus::frdAllPairsConoverTest()`.
- factorial simple effects: `by` and `factor` arguments define the scientifically relevant comparison strata.
- incomplete or replicated RCBD cells are rejected by the classical Friedman-Conover adapter rather than silently analyzed under the wrong exchangeability structure.

## 22. Comprehensive nonparametric regression for Agronomy

Implemented as a unified `agri_np_reg_fit` workflow.

### Strict nonparametric core

- LOESS/local polynomial smoothing;
- smoothing splines;
- mixed-data kernel regression through `np`;
- isotonic monotone regression;
- constrained quantile B-splines through `cobs`.

### Robust/semiparametric companions

- Theil-Sen regression;
- Siegel repeated-median regression;
- conditional quantile regression;
- generalized additive models (`mgcv`);
- shape-constrained additive models (`scam`).

### Agronomic workflow

- structural `method = "auto"` selection without p-value-driven model shopping;
- explicit block preservation for compatible engines;
- cross-validated predictive comparison;
- derivatives and descriptive fitted optima;
- cluster/block bootstrap bands;
- ggplot2 fit, residual, and derivative plots;
- response-family support through GAM/SCAM;
- shape constraints for monotonic, convex, and concave biological response curves.

### Regression inference and specification diagnostics

The regression module also implements:

- `agri_np_significance()`: bootstrap significance testing for continuous, ordered or unordered predictors in mixed-data kernel regression via `np::npsigtest()`. Scientific predictors are tested by default while a declared block remains in the conditioning set. The result is explicitly labeled model-based rather than a randomization test.
- `agri_np_specification()`: a consistent nonparametric specification test for a prespecified continuous Gaussian `lm`/`glm` candidate via `np::npcmstest()`. The function asks whether the chosen functional form is too restrictive; it does not select a unique smoother.
- explicit errors when a requested shape constraint would be ignored by the selected engine, when unsupported observation weights would be discarded, or when a repeated/longitudinal `agri_design` would lose its subject-dependence structure.

The current regression block treatment is a categorical nuisance adjustment for compatible engines, not a random-effect GAMM representation. A subject-aware GAMM/nonparametric longitudinal regression adapter remains a future validation target.


## 23. Integer-support nonparametric regression

Implemented in version 0.12.0.9000 for ordered quantitative predictors that admit only integer agronomic decisions. The module includes:

- ordered-discrete kernel regression (`discrete_kernel`) with `np` and ordered kernels;
- unimodal isotonic regression (`unimodal_isotonic`) with an admissible integer mode;
- umbrella-order constrained regression (`umbrella`) with compatible block/covariate adjustment through `cgam`;
- flexible latent regression projected onto an integer lattice (`integer_grid`);
- observed, complete-range, and custom integer supports;
- finite first and second differences instead of continuous derivatives for integer decisions;
- support-restricted maxima/minima, marginal efficiency, practical thresholds, bootstrap optimum distributions, and discrete confidence sets;
- strict rejection of fractional/out-of-support public predictions;
- reporting/export integration and a dedicated vignette.

Integer support is treated as part of the estimand. The package does not obtain an operational decision by rounding a continuous optimum.


## 24. Hierarchical and multi-response integration (0.12.x)

The design layer now encodes a third randomization stratum for split-split experiments through `subsubplot=`, and two perpendicular strip factors for strip-plot experiments through `strip_a=` and `strip_b=`. The ARTool adapter represents split-split whole-plot/subplot units and strip-specific block-by-strip random strata explicitly; the permuco adapter uses corresponding `Error()` strata.

`agri_multivariate()` returns an `agri_multivariate_fit` object and routes among `MANOVA.RM::MANOVA()`, `MANOVA.RM::MANOVA.wide()`, and `MANOVA.RM::multRM()` according to response layout and within-subject structure. The object is accepted by `agri_table()`, `agri_report()`, `agri_dashboard()`, and `export_results()`.

`agri_multienv()` enforces inclusion of the declared environment. If environment is omitted from the user formula, the default behavior adds the treatment-by-environment structure; `environment_interaction = FALSE` adds only the environment main effect. Repeated block labels are namespaced within environment before block-adjusted ART/permutation fitting.
