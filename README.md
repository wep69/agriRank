# agriRank

**Design-aware rank-based, permutation and robust inference for agricultural experiments**

Development version **0.13.0**.

`agriRank` represents the experimental design explicitly and connects that declaration to nonparametric, rank-based, permutation, resampling, effect-estimation, visualization, and reporting workflows. The package is intended for agricultural experiments in which the analyst needs more than a one-off Kruskal-Wallis or Friedman test.

---

## Installation

The package is not on CRAN yet. Install from this repository.

### Without vignettes, fast

This is the usual choice. It installs the package and its help pages in a few
seconds and does not require Pandoc.

```r
# install.packages("remotes")
remotes::install_github("wep69/agriRank")
```

`vignettes("agriRank")` will return nothing after this form of installation.
The vignette sources are still in the repository under `vignettes/`, and the
rendered versions are available in the source tarball of each release.

### With vignettes

All 18 vignettes execute their code when they are built, so this form takes
about a minute and needs Pandoc, which comes with RStudio or with Quarto.

```r
# install.packages("remotes")
remotes::install_github("wep69/agriRank", build_vignettes = TRUE)

browseVignettes("agriRank")
vignette("v16-nonparametric-regression", package = "agriRank")
vignette("v17-integer-support-regression", package = "agriRank")
```

If the build fails for lack of Pandoc, install Quarto or RStudio, or fall back
to the form without vignettes.

### Optional backends

Every statistical engine beyond base R lives in `Suggests`, so the package
installs without them and asks for each one only when the corresponding method
is requested. To install all of them at once:

```r
install.packages(c(
  "ARTool", "cgam", "cobs", "coin", "emmeans", "gt", "Iso", "MANOVA.RM",
  "mblm", "mgcv", "multcompView", "np", "nparcomp", "nparLD", "permuco",
  "permute", "plotly", "PMCMRplus", "quantreg", "quarto", "rankFD", "scam",
  "WRS2"
))
```

### Checking the installation

```r
library(agriRank)
packageVersion("agriRank")
agri_methods()
```

## Example data

Three data sets ship with the package, so every example and vignette works on a
shared, agronomically interpretable experiment instead of a throwaway data frame:

| Data set | Structure | Used for |
|---|---|---|
| `agri_dose` | 8 nitrogen rates, 0 to 280 kg ha⁻¹, in 5 blocks | continuous gradients, quadratic-plateau response |
| `agri_density` | 1 to 9 plants per hill in 6 blocks | the integer decision workflow |
| `agri_surface` | nitrogen by irrigation depth, 2 blocks | response surfaces with interacting gradients |

```r
data(agri_dose)
fit <- agri_np_regression(yield ~ dose, agri_dose, method = "gam", block = block)
agri_np_optimum(fit)
```

Yield is in Mg ha⁻¹ throughout. The generating script is in `data-raw/`, and
`simulate_agri()` produces fresh replicates of the same three structures through
the scenarios `"dose_response"`, `"integer_density"` and `"surface"`.

## Cheat sheet

A two-page reference of the whole workflow, from design declaration to report.

| Language | Download | Size |
|---|---|---|
| Portuguese | [agriRank_Cheatsheet_PT.pdf](https://github.com/wep69/agriRank/raw/main/cheatsheet/agriRank_Cheatsheet_PT.pdf) | 21 MB |
| English | [agriRank_Cheatsheet_EN.pdf](https://github.com/wep69/agriRank/raw/main/cheatsheet/agriRank_Cheatsheet_EN.pdf) | 2.5 MB |

Both are also attached to the
[v0.13.0 release](https://github.com/wep69/agriRank/releases/tag/v0.13.0),
together with the source tarball.

The cheat sheets live in `cheatsheet/` in this repository and are deliberately
kept **outside the R package**: they are listed in `.Rbuildignore`, so they do
not travel inside the tarball and do not count toward the installed size.

---

## Integrated hierarchical and multi-response designs

Version 0.13.0 explicitly represents split-split and strip-plot randomization strata, integrates multivariate MANOVA.RM results into the common table/report/export workflow, and enforces environment inclusion in multi-environment models. Split-split designs declare `block`, `whole_plot`, `subplot`, and `subsubplot`; strip-plot designs declare `block`, `strip_a`, and `strip_b`.

```r
ss <- simulate_agri("split_split")
dss <- agri_design(yield ~ irrigation * cultivar * timing, ss,
                   design = "split_split", block = block,
                   whole_plot = irrigation, subplot = cultivar,
                   subsubplot = timing)

st <- simulate_agri("strip_plot")
dst <- agri_design(yield ~ irrigation * nitrogen, st,
                   design = "strip_plot", block = block,
                   strip_a = irrigation, strip_b = nitrogen)
```

For multi-environment data, `agri_multienv(yield ~ genotype, ...)` now injects environment and, by default, the genotype-by-environment interaction rather than silently fitting a pooled genotype-only model.

## Main analytical domains

- completely randomized designs (CRD);
- randomized complete block designs (RCBD);
- one-way and multifactor experiments;
- split-plot and hierarchical designs;
- repeated/longitudinal measurements;
- incomplete repeated measurements through an experimental wild-rank engine;
- quantitative treatment trends and permutation ANCOVA;
- multivariate responses and multi-environment trials;
- batch analysis and inferential sensitivity;
- ggplot2/Plotly graphics, tables, dashboards, and reproducible reports.

## Core workflow

```r
library(agriRank)

dat <- simulate_agri("rcbd", seed = 101)
des <- agri_design(yield ~ treatment, dat, design = "rcbd", block = block)
validate_agri_design(des)
fit <- agri_rank(des)
summary(fit)
agri_effects(fit)
agri_pairs(fit)
agri_plot(fit)
```

## Repeated measurements with missing observations

```r
dat <- simulate_agri("repeated_missing", seed = 202, n = 10, missing_rate = 0.15)
des <- agri_design(height ~ treatment * time, dat, design = "repeated",
                   subject = subject, within = time)

agri_missing_report(des)
fit <- agri_repeated(des, backend = "native_wild", B = 1999,
                     missing_assumption = "MCAR")
fit$omnibus
agri_missing_sensitivity(des, B = 999)
```

The native incomplete repeated-measures engine is **experimental**. It follows the rank-based wild-bootstrap framework of Amro, Konietschke, and Pauly (2024) and currently rejects an additional agronomic block stratum rather than silently discarding it.

## Documentation

The package contains **18 English vignettes** covering the full analytical workflow, including a dedicated state-of-the-art review and a final integrated agronomic case study. Every exported function has a dedicated reference page and at least **three examples**.

- Vignette map: `vignettes/README.md`
- Long-form manual: `inst/manual/REFERENCE_MANUAL.md`
- Documentation coverage: `inst/manual/DOCUMENTATION_COVERAGE.md`
- Reference verification audit: `inst/references/REFERENCE_VERIFICATION.md`
- Verified RIS: `inst/references/agriRank-methods-verified.ris`

All vignette code chunks are executed when the vignettes are built, so every
figure and table you see was produced by the code shown above it. Building the
18 vignettes takes about 36 seconds with every optional backend installed.
Resampling counts inside teaching chunks are deliberately small; increase them
for scientific analysis.

## Validation status

Honest reporting of what has and has not been verified.

**Verified.**

- `R CMD check --as-cran`: 0 errors, 0 warnings, 2 notes that are local
  environment artifacts. macbuilder, R 4.6.1 on macOS arm64: **Status OK**, no
  errors, warnings or notes.
- Test suite: 486 expectations, 0 failures, 0 skips, with all optional backends
  installed. Line coverage 86.5%.
- Numerical identity against the reference backends: Kruskal-Wallis versus
  `stats::kruskal.test`, Friedman versus `stats::friedman.test`, Conover versus
  `PMCMRplus` at 1e-12 tolerance, ART versus `ARTool::art`, repeated-measures
  statistics versus `nparLD`, kernel versus `np`, unimodal isotonic versus
  `Iso`, umbrella versus `cgam`.
- Regression module: 185 functional checks, all passing, including the integer
  decision workflow. The discrete optimum is obtained by evaluation over the
  admissible support, not by rounding a continuous optimum.

**Not verified yet, and this matters.**

Type-I error calibration is still incomplete. A pilot study of 500 replicates
per scenario is available under `inst/calibration/`, and it already found that
the **`permuco` adapters for split-split-plot and strip-plot reject at a rate
near zero under the null hypothesis**. A test that never rejects under H0 also
has almost no power under H1. Until this is resolved, do not use
`method = "permuco"` for confirmatory inference in those two designs; prefer
ART.

The full calibration requires at least 10000 replicates per scenario:

```
Rscript inst/calibration/run-calibration.R --R=10000 --cores=8
```

The native incomplete repeated-measures engine keeps its **experimental** label
until that plan is complete.

## Statistical principles

1. Analyze the design that was randomized.
2. Define the estimand before interpreting a test.
3. Do not choose a method solely from a normality-test p-value.
4. Preserve blocking, whole-plot, subject, and repeated-measures dependence.
5. Prefer effect estimates and uncertainty over letter displays alone.
6. Treat missingness assumptions as scientific assumptions, not as conclusions from a diagnostic test.
7. Use sensitivity analysis to assess stability, never to choose the smallest p-value.

## Citation

```r
citation("agriRank")
```

Pereira, W. E., & Pereira Martinez, M. H. (2026). *agriRank: Design-Aware
Rank-Based, Permutation and Robust Inference for Agricultural Experiments*.
R package version 0.13.0.

## Authors

- Walter Esfrain Pereira, author, creator, copyright holder
  ([ORCID 0000-0003-1085-0191](https://orcid.org/0000-0003-1085-0191))
- Magali Haidee Pereira Martinez, author
  ([ORCID 0009-0009-5419-959X](https://orcid.org/0009-0009-5419-959X))

## License

GPL-3.

## Issues

Bug reports and method requests are welcome at
<https://github.com/wep69/agriRank/issues>. When reporting a numerical problem,
please include the output of `sessionInfo()` and a reproducible example built
with `simulate_agri()` whenever possible.

## Bibliographic metadata

Core references were double-checked against the publisher/journal or CRAN and an independent bibliographic source. See the verification audit and RIS file included with the package.

## Nonparametric regression for agronomic gradients

Version 0.10 adds a unified regression module for fertilizer dose, salinity, irrigation, time, environmental gradients and continuous soil/plant covariates.

```r
fit <- agri_np_regression(yield ~ dose, data = dat, method = "smoothing_spline")
agri_np_diagnostics(fit)
agri_np_plot(fit)
agri_np_derivative(fit)
agri_np_optimum(fit)
# Optional interactive layer
if (requireNamespace("plotly", quietly = TRUE)) agri_np_interactive(fit)
```

Available engines include LOESS, smoothing splines, mixed-data kernel regression (`np`), isotonic regression, constrained quantile B-splines (`cobs`), Theil-Sen and Siegel median regression (`mblm`), quantile regression (`quantreg`), GAM (`mgcv`) and shape-constrained GAM (`scam`). The package distinguishes strictly nonparametric methods from rank-robust and semiparametric companions in its documentation.

For blocked agronomic data, `agriRank` refuses regression engines that cannot preserve the declared block adjustment. Cross-validation is used for predictive comparison only, not for choosing the smallest inferential p-value.

Kernel fits additionally support `agri_np_significance()` for bootstrap tests of individual or joint continuous/categorical predictors. `agri_np_specification()` tests whether a prespecified Gaussian linear or polynomial response equation is too restrictive relative to a mixed-data nonparametric alternative. These answer inferential questions that are distinct from predictive cross-validation. Repeated/longitudinal `agri_design` objects are not silently converted to ordinary regression because subject dependence requires a validated subject-aware adapter.


## Integer-support regression for agronomic decisions

Version 0.11 adds a dedicated workflow for quantitative predictors whose admissible values are integers, such as plants, insects, fruits, irrigation events, sprays, shoots, branches, traps, or animals per experimental unit. The decision support is part of the estimand rather than a printing convention.

```r
fit_i <- agri_np_regression(
  yield ~ plants,
  data = dat_integer,
  method = "integer_grid",
  predictor_support = "observed_integer",
  integer_base_method = "smoothing_spline"
)

agri_integer_predict(fit_i)
agri_integer_difference(fit_i)
agri_integer_optimum(fit_i)
agri_integer_efficiency(fit_i)
```

Four complementary strategies are available: `discrete_kernel` for ordered-discrete kernel regression, `unimodal_isotonic` for a single increase-then-decrease response, `umbrella` for constrained umbrella ordering with compatible covariate/block adjustment, and `integer_grid` for projecting a flexible latent regression onto a declared integer decision lattice. Public prediction rejects fractional or out-of-support values once integer support has been declared. Bootstrap uncertainty is summarized as probability mass over admissible integer optima and can be converted to a discrete confidence set.

See `vignettes/v17-integer-support-regression.Rmd`.

### Conover comparisons

```r
fit <- np_crd(yield ~ treatment, dat)
agri_pairs(fit, method = "conover")
# or explicitly
agri_conover(fit)
```

For a complete unreplicated RCBD, the same interface automatically uses the Friedman-type Conover all-pairs procedure while retaining blocks.
