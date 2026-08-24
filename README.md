# agriRank

**Design-aware rank-based, permutation and robust inference for agricultural experiments**

Development version **0.13.0**.

`agriRank` represents the experimental design explicitly and connects that declaration to nonparametric, rank-based, permutation, resampling, effect-estimation, visualization, and reporting workflows. The package is intended for agricultural experiments in which the analyst needs more than a one-off Kruskal-Wallis or Friedman test.

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

The package contains **13 English vignettes**, reorganized so that each one owns
one coherent analytical block rather than one function. Every exported function
has a dedicated reference page and at least **three examples**.

| # | Vignette | Owns |
|---|---|---|
| 01 | Design foundations, CRD and RCBD | declaring and validating the randomization |
| 02 | Effects, Conover comparisons and factorials | post-hoc comparisons and compact letter displays |
| 03 | Hierarchical designs, trends, ANCOVA and power | split-plot, split-split, strip-plot, trend, covariance |
| 04 | Repeated measures and missing data | subject dependence and incompleteness |
| 05 | Multivariate, multi-environment, batch and sensitivity | several responses, several sites, many analyses |
| 06 | Nonparametric and shape-aware regression | fitting curves to agronomic gradients |
| 07 | Integer-support regression | decisions that can only take whole values |
| 08 | Graphics, tables, reports and reproducibility | publication-ready output |
| 09 | Integrated agronomic case study | the whole workflow on one experiment |
| 10 | Theory, state of the art and common mistakes | background and pitfalls |
| 11 | Distribution-free uncertainty and model checking | SiZer, conformal prediction, simulation diagnostics |
| 12 | Optima, quantiles and block structure | what rate to recommend, for whom, and how the block enters |
| 13 | Time-to-event and ranking data | germination counted in intervals, and on-farm trials whose datum is an order |


- Long-form manual: `inst/manual/REFERENCE_MANUAL.md`
- Documentation coverage: `inst/manual/DOCUMENTATION_COVERAGE.md`
- Reference verification audit: `inst/references/REFERENCE_VERIFICATION.md`
- Verified RIS: `inst/references/agriRank-methods-verified.ris`

## Installing without rebuilding the vignettes

Every code chunk in the 13 vignettes is executed when the package is built.
Rebuilding them takes about **three minutes**, and that cost belongs to whoever
runs `R CMD build`, not to whoever installs the result.

Two installation routes therefore behave very differently.

**Recommended: the released tarball.** It already contains the built vignettes
in `inst/doc`, so installation takes about ten seconds and nothing is
recompiled:

```r
install.packages(
  "https://github.com/wep69/agriRank/releases/download/v0.14.0/agriRank_0.14.0.tar.gz",
  repos = NULL, type = "source"
)
browseVignettes("agriRank")
```

**From the repository source.** `install_github()` builds from the sources,
where `inst/doc` does not exist, so the vignettes are either skipped or rebuilt
on your machine:

```r
# Fast, but installs no vignettes at all.
remotes::install_github("wep69/agriRank")

# Installs the vignettes, and pays the full rebuild locally.
remotes::install_github("wep69/agriRank", build_vignettes = TRUE)
```

Use the release tarball unless you are developing the package.

During development, skip the rebuild while iterating and run the complete check
only before a release:

```sh
R CMD check --as-cran --no-build-vignettes agriRank_0.14.0.tar.gz
```

## Statistical principles

1. Analyze the design that was randomized.
2. Define the estimand before interpreting a test.
3. Do not choose a method solely from a normality-test p-value.
4. Preserve blocking, whole-plot, subject, and repeated-measures dependence.
5. Prefer effect estimates and uncertainty over letter displays alone.
6. Treat missingness assumptions as scientific assumptions, not as conclusions from a diagnostic test.
7. Use sensitivity analysis to assess stability, never to choose the smallest p-value.

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

See `vignettes/v07-integer-support-regression.Rmd`.

## Distribution-free uncertainty and model checking

Version 0.14 adds the three tools that turn a fitted curve into a defensible
recommendation. All are distribution free and all refuse to answer a question
the data cannot support.

```r
fit <- agri_np_regression(yield ~ dose, agri_dose, method = "gam", block = block)

# Where is the response still rising, whatever the smoothing?
sz <- agri_np_sizer(fit)
agri_np_significant_slope(sz, stability = 0.8)
plot(sz, type = "map")

# What interval covers the NEXT plot, not the fitted curve?
cf <- agri_np_conformal(fit, newdata = agri_dose, level = 0.90)
agri_np_coverage(cf, data = agri_dose)

# Does the model describe the data, without assuming normality?
agri_np_simdiag(fit, nsim = 300, seed = 1)
```

`agri_np_sizer()` is the honest alternative to `agri_np_optimum()` whenever the
fitted maximum lands on the boundary of the tested range, which is what happens
every time a response plateaus. `agri_np_conformal()` carries a finite-sample
marginal coverage guarantee under exchangeability alone, and splits by block
because plots in different blocks are not exchangeable; `scope = "new_block"`
states the stronger claim for a field or year that was not observed.
`agri_np_simdiag()` reports simulation-based quantile residuals with three
checks, of which the location check along the gradient is the one with power
against a wrong curve shape.

See `vignettes/v11-distribution-free-uncertainty-and-diagnostics.Rmd`, which
repeats the whole workflow on a real precision-agriculture maize trial from
`agridat`.

## From a curve to a recommendation

```r
# A rate is a location, and locations have intervals. This resamples the
# argmax, not the height of the curve, keeping whole blocks together.
ot <- agri_np_optimum_test(fit, B = 999, seed = 1)
ot          # reports p_boundary and refuses to name a rate when none exists

# Comparing cultivars needs curves that may differ in SHAPE. An additive
# adjustment forces parallel curves, which share one optimum by construction.
f2 <- agri_np_regression(yield ~ dose + cultivar, d, method = "gam",
                         block = block, gam_structure = "varying")
agri_np_optimum_test(f2, by = cultivar, B = 999)

# The median describes the typical plot. The 10th percentile describes the
# plot a grower meets in a bad year.
qc <- agri_np_quantile_curves(yield ~ dose, d, block = block)
plot(qc, type = "fan")
plot(qc, type = "spread")

# How the block enters decides whether the model can speak about a new field.
fs <- agri_np_regression(yield ~ dose, d, method = "gam", block = block,
                         block_effect = "shrunk")
agri_np_block_effects(fs)
```

`agri_np_optimum_test()` exists because `agri_np_optimum()` returns a point with
no uncertainty, and because a curve can be estimated precisely while the
position of its maximum wanders widely. `agri_np_quantile_curves()` exists
because a treatment can lift the good plots without lifting the poor ones, and a
mean curve cannot tell the difference. `block_effect = "shrunk"` is the
model-based route to a prediction for an unobserved field, and should be
reported next to `agri_np_conformal(scope = "new_block")`, which is the
assumption-free route to the same prediction.

See `vignettes/v12-optima-quantiles-and-block-structure.Rmd`.

## When the datum is not a measurement

Two agronomic experiments do not produce a measurement, and forcing them into
methods built for one reports quantities the data do not contain.

```r
# Germination is counted inside intervals, and seeds that never germinate are
# observations censored at the end of the trial, not missing values.
tte <- agri_np_timetoevent(nSeeds ~ timeBef + timeAf, verbascum,
                           by = Species, units = Dish)
tte$summary   # capacity and speed, reported separately
plot(tte, type = "cdf")

# On-farm trials return an order, not a measurement.
r <- agri_rankings(position ~ variety, tricot, block = farm, ranked = TRUE)
r$completeness   # incomplete designs make rank sums non-comparable
r$pairwise       # which survives, because each comparison is inside one block
```

`agri_np_timetoevent()` keeps a seed lot's two properties apart, because one
number cannot carry both: **capacity**, the share that germinates at all, and
**speed**, the quantiles among those that do. The whole-lot median is `NA` for a
lot that never reaches half, and that `NA` is the result. Curves are compared by
permutation at the level of the dish or tray, since seeds sharing a dish are not
independent.

`agri_rankings()` shows the within-block ranks that Friedman and Conover already
use internally, and bridges to tricot data. Where the design is incomplete it
withholds rank sums, because an item allocated to favourable farms collects
flattering ranks for the wrong reason, and keeps the pairwise record, which is
made inside blocks. Plackett-Luce worth is offered as a labelled model-based
companion when that package is installed.

See `vignettes/v13-time-to-event-and-ranking-data.Rmd`.

### Conover comparisons

```r
fit <- np_crd(yield ~ treatment, dat)
agri_pairs(fit, method = "conover")
# or explicitly
agri_conover(fit)
```

For a complete unreplicated RCBD, the same interface automatically uses the Friedman-type Conover all-pairs procedure while retaining blocks.
