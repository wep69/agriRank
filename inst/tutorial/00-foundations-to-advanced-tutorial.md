# agriRank: From Experimental Design to Advanced Nonparametric Agronomic Workflows

**Additional instructional vignette**  
**Package:** `agriRank`  
**Version targeted:** `0.12.0.9000`  
**Format:** Markdown source only  
**Purpose:** a high-value starting point for students, agronomists, statisticians, reviewers, and researchers who need to move from classical nonparametric analyses to design-aware rank, permutation, repeated-measures, multivariate, multi-environment, and nonparametric regression workflows.

> This document is intentionally supplied as `.md`. It is not a rebuilt or compiled package vignette. Code is designed to be run locally with `agriRank` and the relevant optional backends installed.

---

## 1. Why this tutorial exists

Nonparametric analysis in agricultural experiments is often taught as a short decision tree:

1. run a normality test;
2. if normality is rejected, replace ANOVA by Kruskal-Wallis or Friedman;
3. run a post-hoc procedure;
4. report groups of letters.

That workflow is too narrow for modern experiments.

The main inferential problem is usually not whether the response is exactly Gaussian. The central questions are instead:

- What was randomized?
- What is the experimental unit?
- Which observations are independent?
- Is there blocking, nesting, repeated observation, or a plot hierarchy?
- Is the scientific target a location shift, a relative treatment effect, a trend, a curve, an optimum, or a multivariate effect?
- Does the analysis preserve the design when data are unbalanced or incomplete?
- Are treatment comparisons compatible with the omnibus analysis?
- Does the reported optimum belong to the set of treatments that can actually be implemented?

`agriRank` is organized around these questions.

Its central rule is:

**Declare the experiment first. Let the experimental structure restrict the admissible inference. Then communicate effects, contrasts, uncertainty, and limitations.**

The package therefore combines classical rank procedures with pseudo-ranks, aligned-rank methods, permutation inference, wild bootstrap procedures, multivariate resampling, nonparametric regression, integer-support decisions, graphics, reporting, and sensitivity analysis.

This tutorial introduces the package progressively. It begins with DIC/CRD and DBC/RCBD, then moves to factorial and hierarchical designs, repeated measurements, missing data, multivariate and multi-environment analyses, and finally the general and integer-support regression modules.

---

## 2. Learning objectives

After working through this tutorial, the reader should be able to:

1. declare and validate an agricultural experiment before fitting an inferential model;
2. distinguish CRD, RCBD, factorial, split-plot, split-split, strip-plot, repeated-measures, multivariate, and multi-environment structures;
3. understand why Kruskal-Wallis and Friedman are useful but insufficient for many modern experiments;
4. use design-aware post-hoc comparisons, including Conover procedures appropriate to CRD and complete RCBD layouts;
5. interpret relative effects, pairwise superiority measures, adjusted p-values, and compact-letter displays without reducing the analysis to letters;
6. preserve interactions and error strata in factorial and hierarchical designs;
7. use `nparLD`, `MANOVA.RM`, `permuco`, or the experimental native wild-rank engine for repeated data according to the experimental structure;
8. characterize missing repeated observations and distinguish sensitivity analysis from assumptions about MCAR, MAR, or MNAR;
9. perform multivariate and multi-environment analyses without silently dropping responses or environments;
10. analyze several responses under the same experimental structure with `agri_batch()`;
11. compare inferential paradigms with `agri_sensitivity()` without selecting the smallest p-value;
12. fit flexible nonparametric regressions for continuous agronomic gradients;
13. fit integer-support regression when the decision variable is a number of plants, insects, fruits, applications, irrigations, or other count-valued treatment;
14. estimate finite differences, discrete optima, efficiency thresholds, bootstrap distributions of the optimum, and discrete confidence sets;
15. generate publication-oriented figures, tables, Markdown reports, dashboards, and reproducible exports;
16. build a complete design-to-report workflow that can be adapted to real agronomic datasets.

---

# Part I. The package in one map

## 3. Analytical blocks

The package can be understood as a sequence of connected analytical blocks rather than as a list of unrelated functions.

| Block | Scientific purpose | Main functions | Typical backends |
|---|---|---|---|
| Design declaration | Encode the randomization and experimental unit | `agri_design()`, `validate_agri_design()`, `design_summary()`, `agri_methods()` | native |
| DIC / CRD | Independent treatment groups | `np_crd()`, `agri_rank()` | Kruskal-Wallis, rank/permutation engines |
| DBC / RCBD | Complete blocks | `np_rcbd()`, `agri_rank()` | Friedman, design-aware alternatives |
| Factorial | Main effects and interactions | `np_factorial()` | `rankFD`, `ARTool`, `permuco` |
| Split-plot | Whole-plot and subplot strata | `np_splitplot()` | `permuco`, `ARTool` |
| Split-split | Whole plot, subplot, sub-subplot | `np_splitsplit()` | `permuco`, `ARTool` |
| Strip-plot | Two perpendicular strip factors | `np_stripplot()` | `ARTool`, `permuco` |
| Repeated measures | Dependent observations over time/conditions | `np_repeated()`, `agri_repeated()` | `nparLD`, `MANOVA.RM`, `permuco`, native wild-rank |
| Missing repeated data | Incomplete longitudinal observations | `agri_missing_report()`, `incomplete_wild_rank_test()`, `agri_missing_sensitivity()` | native experimental wild bootstrap |
| Effects and comparisons | Quantify and localize treatment differences | `agri_effects()`, `agri_pairs()`, `agri_conover()`, `agri_contrast()`, `agri_cld()` | native, `PMCMRplus`, backend-specific |
| Trend / ANCOVA / power | Ordered treatments, covariate adjustment, planning | `agri_trend()`, `agri_ancova()`, `agri_power()` | native permutation, `permuco` |
| Multivariate | Multiple responses jointly | `agri_multivariate()` | `MANOVA.RM` |
| Multi-environment | Treatment/genotype across environments | `agri_multienv()` | `rankFD`, `ARTool`, `permuco` |
| Batch analysis | Many responses under one design | `agri_batch()` | same engine as each response |
| Sensitivity analysis | Compare admissible inferential paradigms | `agri_sensitivity()` | primary, ART, permutation |
| Nonparametric regression | Flexible continuous relationships | `agri_np_regression()` and helpers | spline, LOESS, `np`, `mgcv`, `scam`, `cobs`, `quantreg`, `mblm` |
| Integer-support regression | Flexible model with discrete decisions | integer-support methods and helpers | `np`, `Iso`, `cgam`, flexible integer-grid backends |
| Communication | Figures, tables, reports, dashboards, export | `agri_plot()`, `agri_table()`, `agri_report()`, `agri_dashboard()`, `export_results()` | `ggplot2`, `plotly`, `rmarkdown`, `gt` when available |

### 3.1 Inspect the package programmatically

```r
library(agriRank)

# Complete registry of domains and implemented/adapted methods.
agri_methods()

# Focus on repeated-measures components.
subset(
  agri_methods(),
  grepl("repeated", domain)
)

# Focus on regression-related components.
subset(
  agri_methods(),
  grepl("regression", domain)
)
```

### Interpretation

The `status` column matters. Some procedures are native implementations; others are adapters to established R packages. The package is intentionally an orchestration layer in several modules. This is scientifically useful because it allows a common design-aware workflow without pretending that one package should reimplement every established estimator.

---

## 4. Teaching datasets and simulation helpers

`simulate_agri()` creates reproducible datasets for instructional workflows.

```r
simulate_agri("crd", seed = 101)
simulate_agri("rcbd", seed = 102)
simulate_agri("factorial", seed = 103)
simulate_agri("split_plot", seed = 104)
simulate_agri("split_split", seed = 105)
simulate_agri("strip_plot", seed = 106)
simulate_agri("repeated", seed = 107)
simulate_agri("repeated_missing", seed = 108, missing_rate = 0.15)
simulate_agri("multienv", seed = 109)
```

The simulated datasets deliberately include non-Gaussian errors, treatment effects, block effects, plot-level random variation, and repeated dependence patterns. They are teaching data. They are not field evidence.

A useful first inspection is:

```r
x <- simulate_agri("rcbd", seed = 120)
str(x)
head(x)
aggregate(yield ~ treatment, x, median)
aggregate(yield ~ block, x, median)
```

For scientific analyses, replace the simulated data with the real dataset but retain the same design-first sequence.

---

# Part II. Declare the experiment before analyzing it

## 5. `agri_design()` as the central object

### 5.1 Completely randomized design

```r
crd <- simulate_agri("crd", seed = 201)

des_crd <- agri_design(
  yield ~ treatment,
  data = crd,
  design = "crd"
)

des_crd
design_summary(des_crd)
```

The object records:

- response;
- treatment variables;
- factor type;
- block, if declared;
- subject and within factors, if repeated;
- whole-plot/subplot hierarchy, if present;
- environment, if multi-environment;
- randomization description;
- validation results.

### 5.2 Factorial RCBD

```r
set.seed(202)
rcbd_f <- expand.grid(
  block = factor(1:5),
  cultivar = factor(c("C1", "C2", "C3")),
  phosphorus = factor(c("P0", "P1", "P2"))
)

rcbd_f$yield <-
  6 +
  0.7 * as.numeric(rcbd_f$cultivar) +
  0.5 * as.numeric(rcbd_f$phosphorus) +
  0.3 * (rcbd_f$cultivar == "C3" & rcbd_f$phosphorus == "P2") +
  0.2 * as.numeric(rcbd_f$block) +
  rt(nrow(rcbd_f), df = 5)

des_rcbd_f <- agri_design(
  yield ~ cultivar * phosphorus,
  data = rcbd_f,
  design = "rcbd",
  block = block
)

design_summary(des_rcbd_f)
```

### 5.3 Repeated measures

```r
rm <- simulate_agri("repeated", seed = 203)

des_rm <- agri_design(
  height ~ treatment * time,
  data = rm,
  design = "repeated",
  subject = subject,
  within = time
)

design_summary(des_rm)
```

### 5.4 Split-plot

```r
sp <- simulate_agri("split_plot", seed = 204)

des_sp <- agri_design(
  yield ~ irrigation * cultivar,
  data = sp,
  design = "split_plot",
  block = block,
  whole_plot = irrigation,
  subplot = cultivar
)
```

### 5.5 Split-split plot

```r
ssp <- simulate_agri("split_split", seed = 205)

des_ssp <- agri_design(
  yield ~ irrigation * cultivar * timing,
  data = ssp,
  design = "split_split",
  block = block,
  whole_plot = irrigation,
  subplot = cultivar,
  subsubplot = timing
)
```

### 5.6 Strip-plot

```r
strip <- simulate_agri("strip_plot", seed = 206)

des_strip <- agri_design(
  yield ~ irrigation * nitrogen,
  data = strip,
  design = "strip_plot",
  block = block,
  strip_a = irrigation,
  strip_b = nitrogen
)
```

### What to interpret

The design object is not a decorative metadata container. It protects the inferential workflow. A method that would discard an explicitly declared block can be rejected. A split-split analysis cannot proceed without all required plot levels. A repeated-measures analysis cannot be silently converted into an independent-groups analysis.

---

## 6. Validate before fitting

```r
validate_agri_design(des_crd, error = FALSE)
validate_agri_design(des_rcbd_f, error = FALSE)
validate_agri_design(des_rm, error = FALSE)
```

### 6.1 Empty factorial cell

```r
fac <- simulate_agri("factorial", seed = 211)
fac_bad <- subset(fac, !(A == "A2" & B == "B3"))

des_fac_bad <- agri_design(
  yield ~ A * B,
  data = fac_bad,
  design = "factorial"
)

validate_agri_design(des_fac_bad, error = FALSE)
```

An empty treatment combination can make effects non-estimable or alter the meaning of marginal comparisons. The correct response is not to silently collapse factors.

### 6.2 Duplicated repeated cell

```r
rm_dup <- rbind(rm, rm[1, ])

des_dup <- agri_design(
  height ~ treatment * time,
  data = rm_dup,
  design = "repeated",
  subject = subject,
  within = time
)

validate_agri_design(des_dup, error = FALSE)
```

If two rows represent technical replicates at the same subject-time cell, aggregate them explicitly using a scientifically justified rule before analysis. Do not let the inferential method decide accidentally what a replicate means.

### 6.3 Numeric block warning

```r
rnum <- simulate_agri("rcbd", seed = 212)
rnum$block_num <- as.numeric(rnum$block)

des_numblock <- agri_design(
  yield ~ treatment,
  rnum,
  design = "rcbd",
  block = block_num
)

des_numblock$validation
```

A block identifier can be numerically coded but conceptually categorical. The warning exists because treating block number as a continuous trend would imply a different scientific model.

---

# Part III. DIC / CRD and DBC / RCBD

## 7. CRD: classical rank inference as a starting point

```r
crd <- simulate_agri("crd", seed = 301, n = 8)

fit_crd <- np_crd(
  yield ~ treatment,
  data = crd,
  method = "auto"
)

fit_crd
anova(fit_crd)
```

For a one-factor CRD, automatic routing can use Kruskal-Wallis.

### 7.1 Kruskal-Wallis statistic

For groups with rank sums \(R_j\), sample sizes \(n_j\), and total size \(N\), the familiar statistic is

\[
H = \frac{12}{N(N+1)}
\sum_{j=1}^{k}\frac{R_j^2}{n_j}
-3(N+1).
\]

Under standard large-sample conditions, \(H\) is compared with a \(\chi^2\) reference distribution with \(k-1\) degrees of freedom.

### 7.2 Visualize observed data

```r
p_crd <- agri_plot(
  fit_crd,
  type = "data"
)

p_crd
```

A useful default graphic shows observed data rather than only treatment means.

### 7.3 Effects

```r
eff_crd <- agri_effects(
  fit_crd,
  ci = TRUE,
  B = 999,
  seed = 301
)

eff_crd
```

The exact effect output depends on the fitted engine. When a backend does not provide a standardized inferential interval, `agriRank` does not manufacture one.

### Interpretation

The omnibus test answers whether the distributions are compatible with a common treatment distribution under the rank-based hypothesis. It does not tell which treatments differ. Pairwise or planned contrasts are a second inferential step.

---

## 8. RCBD: preserve the block

```r
rcbd <- simulate_agri("rcbd", seed = 302, n = 6)

fit_rcbd <- np_rcbd(
  yield ~ treatment,
  data = rcbd,
  block = block,
  method = "friedman"
)

fit_rcbd
anova(fit_rcbd)
```

The classical Friedman analysis is appropriate for a complete unreplicated block-by-treatment layout.

### 8.1 Friedman statistic

With \(b\) blocks and \(k\) treatments, using treatment rank sums \(R_j\), a common form is

\[
\chi_F^2 =
\frac{12}{bk(k+1)}
\sum_{j=1}^{k} R_j^2
-3b(k+1).
\]

The test uses within-block ranks. Therefore, ignoring block destroys the logic of the procedure.

### 8.2 A deliberate safeguard

```r
# This should be rejected because Kruskal-Wallis would discard the block.
try(
  agri_rank(
    agri_design(
      yield ~ treatment,
      rcbd,
      design = "rcbd",
      block = block
    ),
    method = "kruskal"
  )
)
```

This failure is desirable. A method that is valid for independent groups is not automatically valid in a blocked experiment.

---

# Part IV. Effects, Conover, contrasts, and letters

## 9. Pairwise comparisons are design-dependent

### 9.1 Conover after a CRD analysis

```r
if (requireNamespace("PMCMRplus", quietly = TRUE)) {
  con_crd <- agri_conover(
    fit_crd,
    adjust = "holm"
  )

  con_crd
}
```

For an independent one-way design, the adapter uses the Kruskal-type all-pairs Conover procedure.

### 9.2 Conover in a complete RCBD

```r
if (requireNamespace("PMCMRplus", quietly = TRUE)) {
  con_rcbd <- agri_conover(
    fit_rcbd,
    adjust = "holm"
  )

  con_rcbd
}
```

For a complete unreplicated RCBD, the adapter uses the Friedman-type Conover procedure and preserves pairing by block.

### 9.3 Why incomplete RCBD is different

Remove one observation:

```r
rcbd_incomplete <- rcbd[-1, ]

des_rcbd_incomplete <- agri_design(
  yield ~ treatment,
  rcbd_incomplete,
  design = "rcbd",
  block = block
)

# Classical Friedman-type Conover should not be forced on this layout.
if (requireNamespace("PMCMRplus", quietly = TRUE)) {
  try(
    agri_conover(
      agri_rank(des_rcbd_incomplete, method = "auto")
    )
  )
}
```

The important lesson is not that missing one cell makes all analysis impossible. It means the classical complete-block Conover procedure is no longer automatically the right post-hoc method.

---

## 10. Generic pairwise comparisons

```r
pairs_crd <- agri_pairs(
  fit_crd,
  method = "wilcoxon",
  adjust = "holm"
)

pairs_crd
```

The output can include:

- `group1` and `group2`;
- whether pairing by block was used;
- probability-of-superiority-type effect `A` where available;
- Cliff-type effect;
- Hodges-Lehmann location shift where available;
- raw p-value;
- multiplicity-adjusted p-value.

### Probability of superiority

For independent samples \(Y_i\) and \(Y_j\), a useful effect can be written as

\[
A_{ij}
=
P(Y_i>Y_j)
+
\frac{1}{2}P(Y_i=Y_j).
\]

An empirical estimator is

\[
\widehat A_{ij}
=
\frac{
\#(Y_i>Y_j)+0.5\#(Y_i=Y_j)
}{n_i n_j}.
\]

Values near 0.5 indicate strong overlap. Values farther from 0.5 indicate increasing stochastic separation.

---

## 11. Compact letter display with caution

```r
if (requireNamespace("multcompView", quietly = TRUE)) {
  letters_crd <- agri_cld(
    fit_crd,
    adjust = "holm",
    alpha = 0.05
  )

  letters_crd
}
```

A compact-letter display is useful for communication, but it is secondary to estimates and contrasts.

For example:

| Treatment | Group |
|---|---|
| A | a |
| B | ab |
| C | b |

does **not** mean that A and B are equivalent. It means the selected multiplicity-adjusted comparison did not separate them at the specified threshold.

A stronger presentation combines:

1. observed data;
2. effect estimates;
3. intervals when valid;
4. adjusted pairwise inference;
5. letters only as a compact visual aid.

---

# Part V. Factorial experiments

## 12. Why Kruskal-Wallis is not a factorial analysis

Consider two factors:

```r
fac <- simulate_agri("factorial", seed = 401, n = 7)

des_fac <- agri_design(
  yield ~ A * B,
  fac,
  design = "factorial"
)
```

The scientific questions are:

1. Is there an effect of A?
2. Is there an effect of B?
3. Does the effect of A depend on B?

A one-way Kruskal-Wallis test on the six A-by-B cells cannot replace this decomposition without changing the questions.

### 12.1 Pseudo-rank factorial analysis

```r
if (requireNamespace("rankFD", quietly = TRUE)) {
  fit_rankfd <- agri_rank(
    des_fac,
    method = "rankFD"
  )

  fit_rankfd
  anova(fit_rankfd)
}
```

Pseudo-ranks are particularly important in unbalanced designs because ordinary ranks can induce sample-size-dependent effects that are not the intended nonparametric treatment effects.

### 12.2 Aligned Rank Transform

```r
if (requireNamespace("ARTool", quietly = TRUE)) {
  fit_art <- agri_rank(
    des_fac,
    method = "ART"
  )

  anova(fit_art)
}
```

ART is useful for factorial hypotheses and interactions. Contrasts after ART require careful alignment; ART-C is preferable for multifactor contrasts when available through the corresponding backend workflow.

### 12.3 Permutation route

```r
if (requireNamespace("permuco", quietly = TRUE)) {
  fit_perm <- agri_rank(
    des_fac,
    method = "permuco",
    B = 999,
    seed = 401
  )

  anova(fit_perm)
}
```

### 12.4 Sensitivity across admissible methods

```r
sens_fac <- agri_sensitivity(
  des_fac,
  methods = c("primary", "ART", "permuco"),
  seed = 401
)

sens_fac$table
```

### Interpretation

Sensitivity analysis is not a tournament for p-values. It asks whether substantive conclusions are stable across reasonable inferential paradigms.

A useful reporting sentence is:

> The treatment-by-factor interaction was examined with a design-compatible primary rank-based analysis and compared with aligned-rank and permutation alternatives as a sensitivity analysis. Differences among methods were interpreted as model dependence rather than as a basis for selecting the smallest p-value.

---

## 13. Simple effects when interaction matters

Suppose an A-by-B interaction is scientifically important. A marginal comparison of A averaged over B may be misleading.

```r
if (exists("fit_rankfd")) {
  simple_A <- agri_pairs(
    fit_rankfd,
    factor = "A",
    by = "B",
    adjust = "holm"
  )

  simple_A
}
```

Likewise:

```r
if (exists("fit_rankfd") && requireNamespace("PMCMRplus", quietly = TRUE)) {
  simple_A_conover <- agri_conover(
    fit_rankfd,
    factor = "A",
    by = "B",
    adjust = "holm"
  )

  simple_A_conover
}
```

Use simple effects only when they answer the biological question. Do not generate all possible comparisons merely because the software can.

---

# Part VI. Hierarchical plot designs

## 14. Split-plot

```r
sp <- simulate_agri("split_plot", seed = 501, n = 5)

fit_sp <- np_splitplot(
  yield ~ irrigation * cultivar,
  data = sp,
  block = block,
  whole_plot = irrigation,
  subplot = cultivar,
  method = "auto"
)

fit_sp
```

The randomization hierarchy is:

```text
Block
└── whole plot: irrigation
    └── subplot: cultivar
```

The whole-plot factor and subplot factor do not share the same experimental error.

### Visualize the interaction

```r
agri_plot(
  fit_sp,
  type = "interaction"
)
```

### Interpretation

If the irrigation-by-cultivar interaction is important, compare cultivar within irrigation or irrigation within cultivar. Avoid interpreting a marginal main effect as if the interaction were absent.

---

## 15. Split-split plot

```r
ssp <- simulate_agri("split_split", seed = 502, n = 4)

fit_ssp <- np_splitsplit(
  yield ~ irrigation * cultivar * timing,
  data = ssp,
  block = block,
  whole_plot = irrigation,
  subplot = cultivar,
  subsubplot = timing,
  method = "auto"
)

fit_ssp
```

The hierarchy is:

```text
Block
└── irrigation whole plot
    └── cultivar subplot
        └── timing sub-subplot
```

Each factor is randomized at a different level. The hierarchy should be explained in the Methods section of any manuscript using this design.

---

## 16. Strip-plot

```r
strip <- simulate_agri("strip_plot", seed = 503, n = 5)

fit_strip <- np_stripplot(
  yield ~ irrigation * nitrogen,
  data = strip,
  block = block,
  strip_a = irrigation,
  strip_b = nitrogen,
  method = "auto"
)

fit_strip
```

Conceptually, strip A and strip B are randomized in perpendicular directions. Their intersections generate the combined treatment cells.

The design carries separate block-by-strip structures. Treating the data as a simple two-factor CRD would ignore these error strata.

---

# Part VII. Ordered treatment trends, ANCOVA, and power

## 17. Ordered treatments

Create a quantitative fertilizer treatment in RCBD.

```r
set.seed(601)
trend_dat <- expand.grid(
  block = factor(1:6),
  dose = c(0, 40, 80, 120, 160)
)

trend_dat$yield <-
  4.5 +
  0.045 * trend_dat$dose -
  0.00012 * trend_dat$dose^2 +
  0.15 * as.numeric(trend_dat$block) +
  rt(nrow(trend_dat), df = 5)

des_trend <- agri_design(
  yield ~ dose,
  trend_dat,
  design = "rcbd",
  block = block,
  quantitative = dose
)
```

Permutation rank trend:

```r
tr <- agri_trend(
  des_trend,
  treatment = dose,
  B = 1999,
  seed = 601
)

tr
```

Because a block was declared, treatment scores are permuted within blocks.

### Interpretation

A significant monotonic rank association does not imply a linear response. It only supports an ordered tendency. If the biological objective is a response curve or optimum, use the regression module later in this tutorial.

---

## 18. Permutation ANCOVA

Suppose initial plant biomass is an adjustment covariate.

```r
set.seed(602)
anc <- expand.grid(
  block = factor(1:6),
  treatment = factor(c("control", "bio", "chemical")),
  rep = 1:2
)

anc$initial_biomass <- runif(nrow(anc), 8, 15)
anc$final_biomass <-
  10 +
  1.6 * anc$initial_biomass +
  c(control = 0, bio = 2, chemical = 4)[anc$treatment] +
  0.3 * as.numeric(anc$block) +
  rt(nrow(anc), 5)

if (requireNamespace("permuco", quietly = TRUE)) {
  anc_fit <- agri_ancova(
    final_biomass ~ treatment,
    data = anc,
    covariates = initial_biomass,
    block = block,
    np = 1999,
    seed = 602,
    rank_response = TRUE
  )

  anc_fit$omnibus
}
```

The current `agri_ancova()` adapter uses Freedman-Lane permutation logic through `permuco`. With `rank_response = TRUE`, the response is converted to mid-ranks before the permutation analysis.

This is distinct from the more recent resampling NANCOVA methodology in the literature. Do not label the current adapter as implementing that newer method.

---

## 19. Power by simulating the actual analysis workflow

A useful principle is that power should be evaluated for the method actually intended for analysis.

```r
generator <- function(i) {
  simulate_agri(
    "rcbd",
    seed = 8000 + i,
    n = 6
  )
}

analyzer <- function(dat) {
  fit <- np_rcbd(
    yield ~ treatment,
    dat,
    block = block,
    method = "friedman"
  )

  fit
}

pwr_demo <- agri_power(
  generator = generator,
  analyzer = analyzer,
  nsim = 100,
  alpha = 0.05,
  seed = 603
)

pwr_demo
```

Use a small number such as `nsim = 100` only for learning syntax. A final power study should use enough simulations to make Monte Carlo error acceptably small.

`agri_power()` reports both estimated power and Monte Carlo standard error.

---

# Part VIII. Repeated measures

## 20. Why repeated observations require a different workflow

```r
rm <- simulate_agri(
  "repeated",
  seed = 701,
  n = 10
)

des_rm <- agri_design(
  height ~ treatment * time,
  rm,
  design = "repeated",
  subject = subject,
  within = time
)
```

The same subject is observed at several times. Treating the four records from one subject as four independent experimental units inflates the apparent amount of information.

The main hypotheses are commonly:

- treatment effect;
- time effect;
- treatment-by-time interaction.

---

## 21. Automatic repeated-measures routing

```r
fit_rm <- agri_repeated(
  des_rm,
  backend = "auto",
  B = 999,
  iter = 999,
  seed = 701
)

fit_rm
```

The automatic choice depends on installed backends and design structure.

Potential routes include:

- `nparLD` for complete unblocked longitudinal rank-based analysis;
- `MANOVA.RM` for resampling-based repeated-measures analysis;
- `permuco` for blocked repeated structures when the declared block must be preserved;
- native wild-rank procedures for incomplete unblocked repeated data.

### Explicit `nparLD`

```r
if (requireNamespace("nparLD", quietly = TRUE)) {
  fit_nparld <- agri_repeated(
    des_rm,
    backend = "nparLD",
    seed = 701
  )

  fit_nparld
}
```

### Explicit `MANOVA.RM`

```r
if (requireNamespace("MANOVA.RM", quietly = TRUE)) {
  fit_mrm <- agri_repeated(
    des_rm,
    backend = "MANOVA.RM",
    iter = 999,
    seed = 701
  )

  fit_mrm
}
```

### Interpretation

Do not treat the backend names as interchangeable labels. They differ in test statistics, resampling schemes, assumptions, and standardized outputs. The experimental question should remain the same while the sensitivity to inferential implementation is evaluated transparently.

---

# Part IX. Missing data in repeated measurements

## 22. Characterize missingness before fitting

```r
rm_miss <- simulate_agri(
  "repeated_missing",
  seed = 801,
  n = 12,
  missing_rate = 0.15
)

des_miss <- agri_design(
  height ~ treatment * time,
  rm_miss,
  design = "repeated",
  subject = subject,
  within = time
)

miss_report <- agri_missing_report(des_miss)
miss_report
```

The report can summarize:

- total missing responses;
- missing fraction;
- complete versus incomplete subjects;
- missing pattern by occasion;
- dropout-like patterns where identifiable.

### Figure: missingness pattern

```r
agri_plot(
  agri_rank(
    des_miss,
    method = "incomplete_wild",
    B = 299,
    seed = 801,
    missing_assumption = "MCAR"
  ),
  type = "missing"
)
```

---

## 23. Native incomplete wild-rank procedure

The current native engine implements rank-based quadratic-form inference for incompletely observed repeated measurements.

A simplified notation is:

\[
Y_{ijk},
\]

where \(i\) indexes between-subject treatment group, \(j\) indexes repeated occasion, and \(k\) indexes subjects.

Relative marginal effects are estimated from observed mid-ranks, and bootstrap samples are generated with subject-level multipliers so that dependence across repeated observations within the same subject is preserved.

```r
fit_miss <- incomplete_wild_rank_test(
  des_miss,
  B = 1999,
  seed = 801,
  statistic = "ATS",
  missing_assumption = "MCAR"
)

fit_miss
```

Available quadratic-form summaries include ATS, WTS, and MATS in the native implementation.

### Important boundary

The procedure is experimental in `agriRank`. It should remain explicitly identified as such until the local simulation validation plan confirms calibration, coverage, invariance, and agreement with reference implementations.

---

## 24. Missing-data sensitivity

```r
sens_miss <- agri_missing_sensitivity(
  des_miss,
  B = 999,
  seed = 802,
  statistic = "ATS"
)

sens_miss
```

This compares an all-available strategy with complete subjects under a common inferential framing.

### What the analysis does not establish

It does not prove that the missingness mechanism is MCAR.

MCAR, MAR, and MNAR are assumptions or data-generating mechanisms, not labels that can generally be established from one p-value. The sensitivity comparison answers a different question: whether the substantive conclusion changes materially when incomplete subjects are excluded.

---

## 25. A blocked incomplete repeated design should stop

Suppose the repeated experiment also has an agronomic block stratum. The current native incomplete procedure does not claim a validated block-aware extension.

A scientifically safe package should therefore refuse to discard block silently.

```r
blocked_rm <- rm_miss
blocked_rm$block <- factor(rep(1:4, length.out = nrow(blocked_rm)))

blocked_des <- agri_design(
  height ~ treatment * time,
  blocked_rm,
  design = "repeated",
  subject = subject,
  within = time,
  block = block
)

try(
  agri_rank(
    blocked_des,
    method = "auto"
  )
)
```

A failure here protects the analysis from a false sense of validity.

---

# Part X. Multivariate and multi-environment inference

## 26. Multivariate responses

Agronomic experiments often measure several endpoints on the same experimental units, for example:

- biomass;
- SPAD;
- leaf area;
- root mass;
- yield.

Create a small teaching dataset:

```r
set.seed(901)
mv <- expand.grid(
  block = factor(1:5),
  treatment = factor(c("control", "bio", "chemical"))
)

u <- rnorm(nrow(mv), 0, 1)

mv$biomass <-
  20 +
  c(control = 0, bio = 2.5, chemical = 4)[mv$treatment] +
  0.5 * as.numeric(mv$block) +
  u + rnorm(nrow(mv), 0, 1.2)

mv$spad <-
  35 +
  c(control = 0, bio = 3, chemical = 5)[mv$treatment] +
  0.7 * u + rnorm(nrow(mv), 0, 1.5)

mv$root_mass <-
  8 +
  c(control = 0, bio = 1.5, chemical = 2.2)[mv$treatment] +
  0.4 * u + rnorm(nrow(mv), 0, 0.8)
```

Fit a multivariate analysis:

```r
if (requireNamespace("MANOVA.RM", quietly = TRUE)) {
  mv_fit <- agri_multivariate(
    cbind(biomass, spad, root_mass) ~ treatment,
    data = mv,
    block = block,
    resampling = "paramBS",
    iter = 999,
    seed = 901
  )

  mv_fit
  summary(mv_fit)
}
```

The integrated object is class `agri_multivariate_fit`, which can be tabulated, reported, dashboarded, and exported.

### Interpretation

A global multivariate effect asks whether the response vector differs among treatments. It does not imply that every response differs individually. Follow-up response-specific analyses should be planned and multiplicity handled transparently.

---

## 27. Multi-environment experiments

```r
met <- simulate_agri(
  "multienv",
  seed = 902,
  n = 5
)
```

### 27.1 Environment enforced automatically

```r
met_fit <- agri_multienv(
  yield ~ genotype,
  data = met,
  environment = environment,
  block = block,
  method = "auto",
  environment_interaction = TRUE
)

met_fit
```

If the user supplies `yield ~ genotype` and declares the environment, `agri_multienv()` can enforce the environment term and, by default, the genotype-by-environment interaction.

Conceptually the fitted scientific structure becomes

\[
\text{yield}
\sim
\text{genotype}
*
\text{environment}.
\]

### 27.2 Main-effect-only environment

```r
met_additive <- agri_multienv(
  yield ~ genotype,
  data = met,
  environment = environment,
  block = block,
  environment_interaction = FALSE,
  method = "auto"
)
```

This represents genotype and environment main effects without forcing GxE.

### 27.3 Environment-specific blocks

Block labels such as `1`, `2`, `3` often repeat at every location. The package namespaces block within environment so that block 1 in E1 is not treated as the same experimental unit as block 1 in E2.

### Interpretation

A multi-environment workflow should report:

1. how environment is defined: location, year, season, or their combination;
2. whether GxE is included;
3. how blocks are nested within environment;
4. whether genotype rankings change across environments;
5. whether the inferential conclusion is stable across admissible methods.

---

# Part XI. Batch and sensitivity analysis

## 28. Several responses under the same experimental design

Create three responses under one RCBD.

```r
set.seed(1001)
batch_dat <- expand.grid(
  block = factor(1:6),
  treatment = factor(c("T1", "T2", "T3", "T4"))
)

trt_eff <- c(T1 = 0, T2 = 1, T3 = 1.7, T4 = 2.1)

batch_dat$yield <-
  5 + trt_eff[batch_dat$treatment] +
  0.2 * as.numeric(batch_dat$block) +
  rt(nrow(batch_dat), 5)

batch_dat$biomass <-
  20 + 2 * trt_eff[batch_dat$treatment] +
  rlnorm(nrow(batch_dat), 0, 0.2)

batch_dat$spad <-
  30 + 1.5 * trt_eff[batch_dat$treatment] +
  rnorm(nrow(batch_dat), 0, 2)
```

Declare the first response, then reuse the design structure:

```r
batch_des <- agri_design(
  yield ~ treatment,
  batch_dat,
  design = "rcbd",
  block = block
)

batch_fit <- agri_batch(
  batch_des,
  responses = c("yield", "biomass", "spad"),
  method = "friedman",
  adjust_across = "BH"
)

batch_fit$summary
```

### Interpretation

Across-response multiplicity adjustment is optional and explicit. There is no single universally correct family definition for multiple agronomic endpoints. The analyst should define the inferential family before inspecting results.

---

## 29. Sensitivity analysis without method shopping

```r
fac <- simulate_agri("factorial", seed = 1002)
fac_des <- agri_design(
  yield ~ A * B,
  fac,
  design = "factorial"
)

sens <- agri_sensitivity(
  fac_des,
  methods = c("primary", "ART", "permuco"),
  seed = 1002
)

sens$table
```

A useful figure can be built from the sensitivity table:

```r
library(ggplot2)

ggplot(
  sens$table,
  aes(x = effect, y = p_value, shape = method)
) +
  geom_point(size = 3, position = position_dodge(width = 0.3)) +
  geom_hline(yintercept = 0.05, linetype = 2) +
  coord_flip() +
  labs(
    x = NULL,
    y = "p-value",
    title = "Sensitivity of factorial inference across admissible methods"
  ) +
  theme_bw()
```

Do not use this graph to choose the method with the smallest p-value. Use it to identify conclusions that are model-sensitive.

---

# Part XII. General nonparametric regression

## 30. Why regression belongs in an agronomic nonparametric workflow

Many treatments are quantitative rather than categorical:

- nitrogen dose;
- irrigation depth;
- salinity;
- plant density;
- insect pressure;
- temperature;
- soil moisture;
- rainfall;
- days after emergence.

If the scientific treatment has quantitative meaning, comparing every level as an unrelated category can be inefficient and biologically uninformative.

A generic nonparametric regression writes

\[
Y = f(X) + \varepsilon,
\]

where \(f\) is not restricted to a fixed linear or quadratic form.

---

## 31. Smoothing spline

```r
set.seed(1101)
nit <- data.frame(
  N = seq(0, 220, length.out = 70)
)

nit$yield <-
  4.5 +
  0.065 * nit$N -
  0.00018 * nit$N^2 +
  rnorm(nrow(nit), 0, 0.6)

fit_ss <- agri_np_regression(
  yield ~ N,
  nit,
  method = "smoothing_spline"
)

fit_ss
summary(fit_ss)
```

Prediction:

```r
pred_ss <- agri_np_predict(
  fit_ss,
  data.frame(N = seq(0, 220, by = 10)),
  interval = "confidence"
)

pred_ss
```

Figure:

```r
agri_np_plot(
  fit_ss,
  type = "fit"
)
```

---

## 32. LOESS

```r
fit_loess <- agri_np_regression(
  yield ~ N,
  nit,
  method = "loess",
  span = 0.65,
  degree = 2
)

agri_np_plot(fit_loess)
```

LOESS is flexible for exploratory local structure but can be unstable near boundaries or sparse regions. Avoid extrapolation beyond the observed treatment domain.

---

## 33. Kernel regression with mixed predictors

Kernel regression becomes especially valuable when predictors have mixed types.

```r
if (requireNamespace("np", quietly = TRUE)) {
  set.seed(1102)

  kdat <- expand.grid(
    N = seq(0, 200, by = 20),
    cultivar = factor(c("C1", "C2", "C3")),
    rep = 1:4
  )

  kdat$yield <-
    5 +
    0.055 * kdat$N -
    0.00014 * kdat$N^2 +
    c(C1 = 0, C2 = 0.7, C3 = 1.1)[kdat$cultivar] +
    rnorm(nrow(kdat), 0, 0.7)

  fit_kernel <- agri_np_regression(
    yield ~ N + cultivar,
    kdat,
    method = "kernel",
    kernel_regtype = "ll"
  )

  fit_kernel
}
```

The `np` framework can combine continuous, unordered categorical, and ordered categorical predictors using type-specific kernels and data-driven bandwidth selection.

---

## 34. Shape-constrained regression

### 34.1 Monotonic isotonic response

```r
set.seed(1103)
water <- data.frame(
  irrigation = seq(20, 120, by = 5)
)
water$biomass <- 10 + 18 * (1 - exp(-water$irrigation / 55)) + rnorm(nrow(water), 0, 0.7)

fit_iso <- agri_np_regression(
  biomass ~ irrigation,
  water,
  method = "isotonic",
  shape = "increasing"
)

agri_np_plot(fit_iso)
```

### 34.2 SCAM

```r
if (requireNamespace("scam", quietly = TRUE)) {
  fit_scam <- agri_np_regression(
    biomass ~ irrigation,
    water,
    method = "scam",
    shape = "increasing"
  )

  agri_np_plot(fit_scam)
}
```

Shape constraints should be declared because of biological knowledge, not because a constrained curve gives a more attractive figure.

---

## 35. Quantile regression

Mean response is not always the target.

```r
if (requireNamespace("quantreg", quietly = TRUE)) {
  fit_q50 <- agri_np_regression(
    yield ~ N,
    nit,
    method = "quantile",
    tau = 0.50
  )

  fit_q90 <- agri_np_regression(
    yield ~ N,
    nit,
    method = "quantile",
    tau = 0.90
  )
}
```

Conditional quantiles are written as

\[
Q_\tau(Y\mid X=x),
\qquad 0<\tau<1.
\]

The median regression at \(\tau=0.5\) and upper quantile regression at \(\tau=0.9\) answer different scientific questions.

---

## 36. GAM response surface

```r
if (requireNamespace("mgcv", quietly = TRUE)) {
  set.seed(1104)

  surf <- expand.grid(
    N = seq(0, 200, length.out = 15),
    water = seq(0.5, 1.0, length.out = 10)
  )

  surf$yield <-
    5 +
    0.060 * surf$N -
    0.00016 * surf$N^2 +
    4.2 * surf$water +
    0.015 * surf$N * surf$water +
    rnorm(nrow(surf), 0, 0.6)

  fit_surface <- agri_np_regression(
    yield ~ N + water,
    surf,
    method = "gam",
    gam_structure = "tensor"
  )

  agri_np_plot(
    fit_surface,
    type = "surface",
    surface_predictors = c("N", "water"),
    n = 50
  )
}
```

The surface should remain inside the observed experimental domain. Smooth appearance does not create information in sparse corners of a design.

---

## 37. Compare flexible methods by predictive behavior

```r
cmp <- agri_np_compare(
  yield ~ N,
  data = nit,
  methods = c(
    "loess",
    "smoothing_spline",
    "gam"
  ),
  kfold = 5,
  seed = 1105
)

cmp
```

Cross-validation can compare predictive error without using the smallest inferential p-value as a model-selection criterion.

### Diagnostics

```r
agri_np_diagnostics(fit_ss)
```

### Bootstrap uncertainty

```r
boot_ss <- agri_np_bootstrap(
  fit_ss,
  predictor = "N",
  B = 499,
  seed = 1106
)

boot_ss
```

### Numerical derivative

```r
der_ss <- agri_np_derivative(
  fit_ss,
  predictor = "N"
)

head(der_ss)
```

### Fitted optimum

```r
opt_ss <- agri_np_optimum(
  fit_ss,
  predictor = "N",
  objective = "max",
  range = c(0, 220)
)

opt_ss
```

The fitted maximum is model-dependent and restricted to the search domain. It is not automatically an economic optimum.

---

## 38. Kernel predictor significance and specification tests

When `np` is available, predictor significance and model-specification tools can be used with the kernel engine.

```r
if (requireNamespace("np", quietly = TRUE) && exists("fit_kernel")) {
  sig <- agri_np_significance(
    fit_kernel,
    variables = c("N", "cultivar"),
    B = 399,
    seed = 1107
  )

  sig
}
```

A specification test can compare a proposed parametric model with a flexible nonparametric alternative.

```r
if (requireNamespace("np", quietly = TRUE)) {
  m_quad <- lm(
    yield ~ N + I(N^2),
    data = nit,
    x = TRUE,
    y = TRUE
  )

  spec <- agri_np_specification(
    m_quad,
    B = 399,
    seed = 1108
  )

  spec
}
```

A rejected parametric specification suggests that the proposed functional form may be too restrictive. It does not identify the correct biological model automatically.

---

# Part XIII. Integer-support nonparametric regression

## 39. When the predictor is quantitative but decisions must be integer

Examples include:

- number of plants per plot;
- insects per sampling unit;
- fruits retained per plant;
- irrigation events;
- spray applications;
- branches;
- traps;
- animals per pen.

Define an admissible support

\[
\mathcal X_I
=
\{x_1,x_2,\ldots,x_K\}
\subset \mathbb Z.
\]

The fitted optimum is

\[
x_I^*
=
\arg\max_{x\in\mathcal X_I}
\widehat m(x).
\]

The package does **not** fit a continuous optimum and round it. It evaluates the fitted response directly over the admissible lattice.

---

## 40. Ordered-discrete kernel regression

```r
if (requireNamespace("np", quietly = TRUE)) {
  set.seed(1201)

  insects <- data.frame(
    insects = rep(0:10, each = 7)
  )

  insects$damage <-
    3.5 +
    1.25 * insects$insects +
    0.08 * insects$insects^2 +
    rnorm(nrow(insects), 0, 1.4)

  fit_dk <- agri_np_regression(
    damage ~ insects,
    insects,
    method = "discrete_kernel",
    predictor_support = "observed_integer",
    integer_predictor = "insects",
    integer_kernel = "wangvanryzin"
  )

  agri_integer_predict(fit_dk)
}
```

Fractional prediction is rejected:

```r
if (exists("fit_dk")) {
  try(
    agri_np_predict(
      fit_dk,
      data.frame(insects = 4.5)
    )
  )
}
```

This restriction protects the scientific estimand, not only the display format.

---

## 41. Unimodal isotonic regression

Many density-response relationships are expected to increase to one optimum and then decrease.

\[
\theta_1
\le \cdots \le
\theta_m
\ge \cdots \ge
\theta_K.
\]

```r
if (requireNamespace("Iso", quietly = TRUE)) {
  set.seed(1202)

  density <- data.frame(
    plants = rep(1:10, each = 6)
  )

  density$yield <-
    28 +
    8.5 * pmin(density$plants, 6) -
    5.2 * pmax(density$plants - 6, 0) +
    rnorm(nrow(density), 0, 2)

  fit_ui <- agri_np_regression(
    yield ~ plants,
    density,
    method = "unimodal_isotonic",
    predictor_support = "observed_integer",
    integer_predictor = "plants"
  )

  agri_integer_predict(fit_ui)
  agri_integer_optimum(fit_ui)
}
```

The optimum itself belongs to the observed integer support.

---

## 42. Umbrella-order regression with block adjustment

```r
if (requireNamespace("cgam", quietly = TRUE)) {
  set.seed(1203)

  udat <- expand.grid(
    block = factor(1:5),
    plants = 1:9
  )

  udat$yield <-
    32 +
    9 * pmin(udat$plants, 6) -
    5.5 * pmax(udat$plants - 6, 0) +
    0.7 * as.numeric(udat$block) +
    rnorm(nrow(udat), 0, 1.8)

  fit_umb <- agri_np_regression(
    yield ~ plants,
    udat,
    method = "umbrella",
    block = block,
    predictor_support = "observed_integer",
    integer_predictor = "plants"
  )

  agri_integer_optimum(fit_umb)
  agri_np_plot(fit_umb)
}
```

The block remains part of the model. A method that cannot represent the declared block is not allowed to ignore it silently.

---

## 43. Integer-grid decision from a smooth latent curve

The underlying biological relationship may be smooth even when the action is discrete.

```r
set.seed(1204)
igrid <- expand.grid(
  plants = 1:12,
  rep = 1:5
)

igrid$yield <-
  35 +
  9.5 * igrid$plants -
  0.72 * igrid$plants^2 +
  rnorm(nrow(igrid), 0, 2)

fit_igrid <- agri_np_regression(
  yield ~ plants,
  igrid,
  method = "integer_grid",
  integer_base_method = "smoothing_spline",
  predictor_support = "observed_integer",
  integer_predictor = "plants"
)

agri_integer_predict(fit_igrid)
agri_integer_optimum(fit_igrid)
```

Even if the latent spline has a mathematical maximum at 6.4, the decision is computed by comparing fitted values at admissible integers.

---

## 44. Finite differences instead of derivatives

For an integer predictor, a scientifically natural marginal effect is

\[
\Delta \widehat m(k)
=
\widehat m(k+1)-\widehat m(k).
\]

Second difference:

\[
\Delta^2\widehat m(k)
=
\widehat m(k+1)
-2\widehat m(k)
+\widehat m(k-1).
\]

Compute them:

```r
fd1 <- agri_integer_difference(
  fit_igrid,
  order = 1
)

fd2 <- agri_integer_difference(
  fit_igrid,
  order = 2
)

fd1
fd2
```

### Agronomic interpretation

The first difference can answer:

> What is the expected gain in yield from increasing the treatment from 5 to 6 plants per plot?

This is usually more meaningful than the instantaneous derivative at an impossible value such as 5.37 plants.

---

## 45. Relative efficiency and practical thresholds

```r
eff_i <- agri_integer_efficiency(fit_igrid)
eff_i
```

A practical decision may target 95% of the fitted maximum rather than the exact maximum.

```r
thr95 <- agri_integer_threshold(
  fit_igrid,
  criterion = "fraction_of_maximum",
  value = 0.95
)

thr95
```

Or the minimum gain from a baseline:

```r
thr_gain <- agri_integer_threshold(
  fit_igrid,
  criterion = "gain_from_baseline",
  baseline = 1,
  value = 10
)

thr_gain
```

Or a marginal-gain threshold:

```r
thr_marginal <- agri_integer_threshold(
  fit_igrid,
  criterion = "marginal_gain",
  value = 1
)

thr_marginal
```

These thresholds can be more useful than the absolute maximum when costs or operational simplicity matter, although a true economic optimum requires an explicit economic objective.

---

## 46. Bootstrap distribution of the integer optimum

```r
boot_i <- agri_integer_bootstrap(
  fit_igrid,
  objective = "max",
  B = 999,
  seed = 1205
)

boot_i
```

The output estimates the empirical probability that each admissible integer is selected as the optimum across bootstrap refits.

A useful visualization:

```r
library(ggplot2)

ggplot(
  boot_i$probabilities,
  aes(x = factor(value), y = probability)
) +
  geom_col() +
  labs(
    x = "Admissible integer treatment",
    y = "Bootstrap probability",
    title = "Bootstrap distribution of the fitted integer optimum"
  ) +
  theme_bw()
```

---

## 47. Discrete confidence set

```r
conf_i <- agri_integer_confset(
  boot_i,
  level = 0.95
)

conf_i
```

Instead of reporting a continuous interval such as

```text
5.38 to 6.71 plants
```

the package can report an admissible set such as

```text
{5, 6, 7}
```

when those integers accumulate the target bootstrap probability.

This is a more coherent operational statement for a discrete decision variable.

---

# Part XIV. Graphics, tables, reports, and reproducibility

## 48. Experimental-design figures

Raw data:

```r
agri_plot(
  fit_crd,
  type = "data"
)
```

Interaction:

```r
agri_plot(
  fit_sp,
  type = "interaction"
)
```

Missingness:

```r
agri_plot(
  agri_rank(
    des_miss,
    method = "incomplete_wild",
    B = 299,
    seed = 1301,
    missing_assumption = "MCAR"
  ),
  type = "missing"
)
```

### Figure principle

A scientific plot should distinguish:

- observed data;
- fitted summary;
- interval or uncertainty;
- grouping structure when relevant;
- extrapolated versus observed domain.

Avoid an isolated bar chart of means for continuous responses when the observations or distributions can be shown.

---

## 49. Regression figures

```r
agri_np_plot(
  fit_ss,
  type = "fit"
)
```

Residuals:

```r
agri_np_plot(
  fit_ss,
  type = "residuals"
)
```

Derivative:

```r
agri_np_plot(
  fit_ss,
  type = "derivative"
)
```

Interactive layer:

```r
if (requireNamespace("plotly", quietly = TRUE)) {
  agri_np_interactive(
    fit_ss,
    type = "fit"
  )
}
```

Interactivity is an exploratory layer. It does not change the fitted model.

---

## 50. Tables

Omnibus table:

```r
agri_table(
  fit_crd,
  what = "omnibus"
)
```

Effects:

```r
agri_table(
  fit_crd,
  what = "effects"
)
```

Pairs:

```r
agri_table(
  fit_crd,
  what = "pairs"
)
```

Regression metrics:

```r
agri_table(fit_ss)
```

The exact table type depends on the result class. The numerical result object remains authoritative; formatting should never change estimates.

---

## 51. Markdown report

```r
report_file <- agri_report(
  fit_crd,
  file = "agrirank_crd_report.md",
  format = "md",
  language = "en"
)

report_file
```

Regression:

```r
agri_report(
  fit_ss,
  file = "agrirank_regression_report.md",
  format = "md",
  language = "en"
)
```

The package can render HTML, DOCX, or PDF when `rmarkdown` and Pandoc are available. This tutorial itself remains Markdown only.

---

## 52. Dashboard source

```r
dag <- agri_dashboard(
  fit_crd,
  file = "agrirank_dashboard.qmd",
  language = "en"
)

dag
```

The dashboard source is intended as a reproducible summary, not as a replacement for the underlying analysis object.

---

## 53. Reproducible export

```r
out <- export_results(
  fit_crd,
  file = "agrirank_results.rds"
)

out
```

For regression:

```r
export_results(
  fit_igrid,
  file = "agrirank_integer_regression_results.rds"
)
```

The RDS export includes key results and session information, allowing downstream inspection without parsing formatted tables.

---

# Part XV. Integrated case study

## 54. Scientific problem

A researcher evaluates three bean cultivars under four salinity levels in a randomized complete block design with five blocks.

Two outcomes are of interest:

1. final dry biomass, measured once;
2. SPAD, measured repeatedly at four times.

The main scientific questions are:

- Do cultivars differ in biomass?
- Does salinity modify biomass?
- Is there cultivar-by-salinity interaction?
- How does SPAD change over time?
- Does the time trajectory depend on cultivar and salinity?
- What happens if some repeated SPAD measurements are missing?
- Can salinity be analyzed as a quantitative gradient as a complementary model?

This example demonstrates how `agriRank` connects factorial RCBD inference, repeated measures, missing-data safeguards, sensitivity analysis, graphics, and reporting.

---

## 55. Simulate a realistic teaching dataset

```r
set.seed(1501)

base <- expand.grid(
  block = factor(1:5),
  cultivar = factor(c("C1", "C2", "C3")),
  salinity = c(0, 2, 4, 6)
)

base$salinity_f <- factor(base$salinity)

cult_eff <- c(C1 = 0.0, C2 = 1.2, C3 = 0.6)

base$biomass <-
  18 +
  cult_eff[base$cultivar] -
  1.15 * base$salinity -
  0.10 * base$salinity^2 +
  0.55 * (base$cultivar == "C2") * base$salinity +
  0.25 * as.numeric(base$block) +
  rt(nrow(base), df = 5)
```

Inspect:

```r
head(base)
aggregate(
  biomass ~ cultivar + salinity,
  base,
  median
)
```

### Figure: observed biomass

```r
library(ggplot2)

ggplot(
  base,
  aes(
    x = factor(salinity),
    y = biomass,
    group = cultivar,
    shape = cultivar
  )
) +
  geom_point(position = position_jitter(width = 0.08), alpha = 0.75) +
  stat_summary(
    fun = median,
    geom = "line",
    aes(linetype = cultivar)
  ) +
  labs(
    x = "Salinity level",
    y = "Dry biomass",
    title = "Observed biomass by cultivar and salinity"
  ) +
  theme_bw()
```

Do not interpret the descriptive medians as block-adjusted inferential estimates.

---

## 56. Declare the factorial RCBD

```r
biomass_design <- agri_design(
  biomass ~ cultivar * salinity_f,
  data = base,
  design = "rcbd",
  block = block
)

design_summary(biomass_design)
validate_agri_design(
  biomass_design,
  error = FALSE
)
```

### Interpretation

The analysis must preserve block. Because the experiment is factorial, the formula must preserve the cultivar-by-salinity interaction.

---

## 57. Factorial nonparametric inference

Blocked factorial inference can route to ART or permutation-based procedures depending on installed engines.

```r
biomass_fit <- agri_rank(
  biomass_design,
  method = "auto",
  seed = 1501
)

biomass_fit
anova(biomass_fit)
```

### Basic interpretation sequence

1. inspect the cultivar-by-salinity interaction first;
2. if interaction is scientifically important, emphasize simple effects;
3. if interaction is weak and the design supports marginal interpretation, summarize main effects;
4. report the selected engine and why it preserves block;
5. accompany p-values with pairwise effects or other estimands when available.

---

## 58. Simple effects

```r
cultivar_within_salinity <- agri_pairs(
  biomass_fit,
  factor = "cultivar",
  by = "salinity_f",
  adjust = "holm"
)

cultivar_within_salinity
```

If Conover is scientifically and structurally admissible for the specific stratum:

```r
if (requireNamespace("PMCMRplus", quietly = TRUE)) {
  cultivar_conover <- try(
    agri_conover(
      biomass_fit,
      factor = "cultivar",
      by = "salinity_f",
      adjust = "holm"
    )
  )

  cultivar_conover
}
```

The analyst should verify whether the conditional stratum retains the required complete block structure before interpreting a Friedman-type post-hoc comparison.

---

## 59. Sensitivity of the factorial conclusion

```r
biomass_sens <- agri_sensitivity(
  biomass_design,
  methods = c("primary", "ART", "permuco"),
  seed = 1502
)

biomass_sens$table
```

### Interpretation

If all admissible methods support the same biological story, the conclusion is method-stable. If one effect changes materially across methods, report that sensitivity rather than hiding it.

---

## 60. Complementary quantitative salinity analysis

Salinity is naturally quantitative. A factorial analysis treats the four levels as categories; a regression treats the numeric scale as meaningful. These are complementary scientific questions.

Create a design marking salinity as quantitative:

```r
sal_design <- agri_design(
  biomass ~ salinity + cultivar,
  data = base,
  design = "rcbd",
  block = block,
  quantitative = salinity
)
```

A flexible block-adjusted GAM can be fitted when `mgcv` is available:

```r
if (requireNamespace("mgcv", quietly = TRUE)) {
  sal_gam <- agri_np_regression(
    biomass ~ salinity + cultivar,
    data = base,
    method = "gam",
    block = block
  )

  agri_np_diagnostics(sal_gam)
  agri_np_plot(sal_gam)
}
```

### Interpretation

The factorial and regression analyses should not be mixed casually. The factorial model asks about the evaluated treatment levels. The regression model asks about the response along a quantitative gradient and depends on assumptions about smoothness between levels.

---

## 61. Generate repeated SPAD measurements

```r
set.seed(1503)

spad <- merge(
  base[c("block", "cultivar", "salinity", "salinity_f")],
  data.frame(time = ordered(c(1, 2, 3, 4))),
  by = NULL
)

spad$subject <- interaction(
  spad$block,
  spad$cultivar,
  spad$salinity_f,
  drop = TRUE
)

subject_re <- rnorm(nlevels(spad$subject), 0, 1.8)

spad$SPAD <-
  34 +
  1.6 * as.numeric(spad$time) +
  c(C1 = 0, C2 = 2, C3 = 1)[spad$cultivar] -
  1.1 * spad$salinity -
  0.35 * spad$salinity * as.numeric(spad$time) +
  subject_re[spad$subject] +
  rt(nrow(spad), df = 5)
```

Descriptive trajectory:

```r
ggplot(
  spad,
  aes(
    x = as.numeric(time),
    y = SPAD,
    group = cultivar,
    linetype = cultivar
  )
) +
  stat_summary(fun = median, geom = "line") +
  stat_summary(fun = median, geom = "point") +
  facet_wrap(~ salinity_f) +
  labs(
    x = "Time",
    y = "SPAD",
    title = "Observed SPAD trajectories by salinity"
  ) +
  theme_bw()
```

---

## 62. Complete repeated-measures analysis

The block and repeated subject structures are both scientifically meaningful.

```r
spad_design <- agri_design(
  SPAD ~ cultivar * salinity_f * time,
  data = spad,
  design = "repeated",
  block = block,
  subject = subject,
  within = time
)
```

For complete blocked repeated data, automatic routing uses a block-compatible backend when available.

```r
if (requireNamespace("permuco", quietly = TRUE)) {
  spad_fit <- agri_repeated(
    spad_design,
    backend = "auto",
    iter = 999,
    seed = 1504
  )

  spad_fit
}
```

### Interpretation

The most biologically informative term may be salinity-by-time or cultivar-by-salinity-by-time. A main effect of time averaged over all salinity levels may have little biological value when stress changes the temporal trajectory.

---

## 63. Introduce missing SPAD observations

```r
set.seed(1505)
spad_miss <- spad
miss_id <- sample(
  seq_len(nrow(spad_miss)),
  size = round(0.12 * nrow(spad_miss))
)
spad_miss$SPAD[miss_id] <- NA_real_

spad_miss_design <- agri_design(
  SPAD ~ cultivar * salinity_f * time,
  data = spad_miss,
  design = "repeated",
  block = block,
  subject = subject,
  within = time
)

agri_missing_report(spad_miss_design)
```

### Expected safeguard

Because this is an incomplete repeated-measures design with an additional block stratum, the current native incomplete wild-rank engine should not pretend that block can be ignored.

```r
try(
  agri_rank(
    spad_miss_design,
    method = "auto"
  )
)
```

This is a valuable instructional outcome. A package that stops for an unsupported design is safer than one that produces a plausible-looking p-value from an invalid randomization structure.

---

## 64. An admissible incomplete repeated example

For teaching the native incomplete engine itself, use an unblocked repeated experiment.

```r
rm_teach <- simulate_agri(
  "repeated_missing",
  seed = 1506,
  n = 12,
  missing_rate = 0.12
)

rm_teach_design <- agri_design(
  height ~ treatment * time,
  rm_teach,
  design = "repeated",
  subject = subject,
  within = time
)

rm_teach_fit <- incomplete_wild_rank_test(
  rm_teach_design,
  B = 1999,
  statistic = "ATS",
  seed = 1506,
  missing_assumption = "MCAR"
)

rm_teach_fit
```

Sensitivity:

```r
agri_missing_sensitivity(
  rm_teach_design,
  B = 999,
  statistic = "ATS",
  seed = 1507
)
```

---

## 65. Produce scientific outputs

Biomass table:

```r
agri_table(
  biomass_fit,
  what = "omnibus"
)
```

Biomass observed-data figure:

```r
agri_plot(
  biomass_fit,
  type = "data"
)
```

Report:

```r
agri_report(
  biomass_fit,
  file = "bean_salinity_biomass.md",
  format = "md",
  language = "en"
)
```

Sensitivity report:

```r
agri_report(
  biomass_sens,
  file = "bean_salinity_sensitivity.md",
  format = "md",
  language = "en"
)
```

Export:

```r
export_results(
  biomass_fit,
  "bean_salinity_results.rds"
)
```

### Integrated interpretation template

A defensible Results paragraph should address the questions in this order:

1. **Design:** The experiment was analyzed as a factorial RCBD with block preserved as the randomization stratum.
2. **Interaction:** State whether cultivar response depended on salinity.
3. **Simple effects:** If interaction mattered, summarize cultivar differences within salinity or salinity differences within cultivar.
4. **Effect magnitude:** Report rank-based or pairwise effect information where available.
5. **Sensitivity:** State whether ART/permutation alternatives changed the substantive conclusion.
6. **Quantitative interpretation:** If salinity was also treated as a numeric gradient, distinguish the regression estimand from the factorial estimand.
7. **Repeated outcome:** Explain subject dependence and the repeated-measures engine used for SPAD.
8. **Missingness:** Characterize missing observations and state whether the available incomplete-data method was applicable to the declared block structure.
9. **Limitations:** State when an engine remained experimental or when a desired design extension was deliberately rejected.

---

# Part XVI. State of the art and methodological perspective

## 66. Why pseudo-ranks matter

Rank procedures are often described as assumption-free replacements for parametric ANOVA. That description is misleading.

In unbalanced factorial designs, ordinary ranks can induce effects that depend on sample allocation. Pseudo-ranks were developed to target nonparametric treatment effects in a way that is not driven by unequal cell sizes.

The package therefore prefers pseudo-rank-based factorial procedures when their estimand matches the scientific question and the backend is available.

Core references include Brunner et al. (2017), Happ et al. (2020), Brunner et al. (2021), and Konietschke and Brunner (2023).

---

## 67. Permutation is not simply “shuffle the data”

A permutation test is valid only when the exchangeability or randomization scheme matches the design.

In a CRD, unrestricted exchangeability may be reasonable under the corresponding null.

In an RCBD, treatment assignments are exchangeable **within blocks**, not across the entire dataset.

In split-plot designs, whole-plot and subplot randomizations occur at different levels.

In repeated measurements, entire within-subject vectors cannot be treated as independent observations.

Studentized permutation procedures and design-restricted resampling are therefore more defensible than indiscriminate label shuffling.

Methodological anchors include Pauly, Brunner and Konietschke (2015), Umlauft, Konietschke and Pauly (2017), Frossard and Renaud (2021), and Hothorn et al. (2008).

---

## 68. ART and ART-C

Aligned Rank Transform methods provide a practical factorial framework for main effects and interactions. ART is not equivalent to ranking the response once and running an ordinary ANOVA. Alignment is effect-specific.

For multifactor contrasts, the ART-C procedure was developed because ordinary contrasts applied naively to an ART fit can be inappropriate.

`agriRank` uses ART as one admissible factorial engine and warns users that contrast interpretation should follow ART-compatible methods.

References: Wobbrock et al. (2011) and Elkin et al. (2021).

---

## 69. Repeated measurements and wild bootstrap

Nonparametric repeated-measures methods estimate effects on marginal distributions or relative treatment effects while accounting for within-subject dependence.

`nparLD` provides established rank-based longitudinal procedures. `MANOVA.RM` offers resampling-based repeated and multivariate inference. Wild-bootstrap rank procedures extend this family to repeated factorial hypotheses and multiple comparisons.

The incomplete-data engine in `agriRank` is based on the recent methodology for incompletely observed nonparametric factorial repeated-measures designs, while remaining explicitly experimental until independent runtime validation is completed.

Key references: Noguchi et al. (2012), Friedrich et al. (2017), Umlauft et al. (2019), Friedrich et al. (2019), and Amro et al. (2024).

---

## 70. Conover belongs to a design-specific context

There is not one universal “Conover test” for every experiment.

The package distinguishes:

- the Kruskal-type Conover all-pairs procedure for independent one-way data;
- the Friedman-type Conover all-pairs procedure for complete unreplicated block designs.

This distinction is central in Agronomy because the same treatment set may be analyzed in a CRD or an RCBD, and the post-hoc procedure must preserve the experimental structure.

---

## 71. Modern nonparametric regression is broader than LOESS

The regression module combines several complementary approaches:

| Method | Main idea | Agronomic use |
|---|---|---|
| LOESS | local polynomial smoothing | exploratory local response |
| Smoothing spline | penalized smooth curve | flexible one-dimensional response |
| Kernel regression | local weighting with data-driven bandwidth | mixed continuous/categorical predictors |
| Isotonic | monotonicity constraint | known increasing/decreasing response |
| COBS | constrained quantile smoothing spline | robust shape-constrained quantiles |
| Theil-Sen / Siegel | rank-robust linear tendency | approximately linear relationship with outliers |
| Quantile regression | conditional quantiles | lower/median/upper response envelopes |
| GAM | additive smooth components | multiple nonlinear predictors |
| SCAM | shape-constrained GAM | biologically justified monotonicity/convexity |
| Integer-support methods | discrete ordered decision support | plants, insects, fruits, events, applications |

The package deliberately distinguishes strictly nonparametric smoothers from robust or semiparametric companions rather than labeling every flexible model “nonparametric.”

---

## 72. Integer support changes the estimand

When the treatment can only be integer-valued, reporting a continuous optimum and rounding it is statistically and operationally different from defining the optimum directly on the admissible set.

Integer-support inference therefore changes:

- prediction domain;
- optimum definition;
- marginal effect definition;
- bootstrap distribution;
- uncertainty set;
- decision threshold.

This is especially relevant for agronomic decisions that are physically indivisible.

Methodological references include Wang and van Ryzin (1981), Racine and Li (2004), Turner and Wollan (1997), Stout (2008), Geng and Shi (1990), and Liao and Meyer (2019).

---

# Part XVII. Common mistakes and their remedies

## 73. “Shapiro significant, therefore Kruskal”

**Problem:** a preliminary normality test does not define the experimental unit, repeated dependence, interaction, or target estimand.

**Use instead:**

```r
agri_design()
validate_agri_design()
agri_methods()
agri_rank(method = "auto")
```

---

## 74. Ignoring block because it is not significant

**Problem:** block is part of randomization, not a nuisance term selected by p-value.

**Use instead:** preserve `block=` in the design and choose a design-aware method.

---

## 75. Using Kruskal-Wallis for a factorial interaction

**Problem:** one-way ranking of treatment cells does not decompose A, B, and A×B as the intended factorial hypotheses.

**Use instead:**

```r
np_factorial()
agri_rank(method = "rankFD")
agri_rank(method = "ART")
agri_rank(method = "permuco")
```

---

## 76. Reporting only letters

**Problem:** letters hide direction, magnitude, uncertainty, and the actual comparisons.

**Use instead:**

```r
agri_effects()
agri_pairs()
agri_conover()
agri_cld()
```

with CLD as a secondary summary.

---

## 77. Treating repeated observations as replicates

**Problem:** subject-time observations are dependent.

**Use instead:**

```r
agri_design(..., subject = subject, within = time)
agri_repeated()
agri_missing_report()
```

---

## 78. Removing incomplete subjects automatically

**Problem:** complete-case deletion changes the analyzed population and may waste information.

**Use instead:** characterize missingness, use an admissible incomplete-data method, and perform sensitivity analysis.

---

## 79. Imputing missing values with the mean

**Problem:** mean imputation distorts variance and dependence and is not a valid generic solution.

`agriRank` does not silently perform it.

---

## 80. Treating a quantitative dose as unrelated categories only

**Problem:** the numeric ordering and spacing carry scientific information.

**Use instead:** factorial comparisons when categorical estimands are desired, and `agri_np_regression()` or `agri_trend()` when the quantitative response pattern is the scientific target.

---

## 81. Rounding a continuous optimum for an integer treatment

**Problem:** rounding does not solve the discrete optimization problem.

**Use instead:**

```r
agri_integer_optimum()
agri_integer_bootstrap()
agri_integer_confset()
```

---

## 82. Choosing a model by the smallest p-value

**Problem:** model shopping invalidates confirmatory interpretation.

**Use instead:** define the primary analysis before inspecting results; use `agri_sensitivity()` and `agri_np_compare()` to study robustness and predictive behavior.

---

# Part XVIII. Compact function-selection guide

## 83. Experimental inference

| Question | Start with | Continue with |
|---|---|---|
| What is the design? | `agri_design()` | `validate_agri_design()`, `design_summary()` |
| One-factor CRD? | `np_crd()` | `agri_effects()`, `agri_conover()` |
| Complete RCBD? | `np_rcbd()` | Friedman, RCBD Conover |
| Factorial independent experiment? | `np_factorial()` | `rankFD`, ART, permutation |
| Split-plot? | `np_splitplot()` | interaction/simple effects |
| Split-split? | `np_splitsplit()` | hierarchical ART/permutation |
| Strip-plot? | `np_stripplot()` | strip-specific ART/permutation |
| Repeated complete? | `agri_repeated()` | `nparLD`, `MANOVA.RM`, `permuco` |
| Repeated incomplete? | `agri_missing_report()` | native wild-rank when admissible |
| Multiple responses? | `agri_multivariate()` | response-specific follow-up |
| Multiple environments? | `agri_multienv()` | G×E interpretation |
| Many endpoints? | `agri_batch()` | across-response multiplicity |
| Method sensitivity? | `agri_sensitivity()` | report model dependence |

## 84. Regression and decision support

| Question | Start with | Continue with |
|---|---|---|
| Flexible one-dimensional curve? | `agri_np_regression(..., method="smoothing_spline")` | prediction/bootstrap |
| Local exploratory curve? | `method="loess"` | diagnostics |
| Mixed numeric and factor predictors? | `method="kernel"` or GAM | significance/specification |
| Known monotonic response? | isotonic / SCAM / COBS | shape-constrained interpretation |
| Conditional median/quantile? | `method="quantile"` | compare quantiles |
| Two quantitative gradients? | GAM tensor surface | `agri_np_plot(type="surface")` |
| Integer treatment? | `discrete_kernel`, `unimodal_isotonic`, `umbrella`, `integer_grid` | discrete optimum/threshold/bootstrap |
| Practical threshold? | `agri_integer_threshold()` | efficiency table |
| Uncertainty in discrete optimum? | `agri_integer_bootstrap()` | `agri_integer_confset()` |

---

# Part XIX. Minimum reporting checklist

Before a result leaves an analysis notebook, thesis, technical report, or manuscript, document:

- [ ] experimental unit;
- [ ] randomization;
- [ ] block structure;
- [ ] whole-plot/subplot hierarchy where relevant;
- [ ] subject and within-subject factors for repeated data;
- [ ] environment definition for multi-environment analyses;
- [ ] response scale and whether ordinal/discrete/continuous;
- [ ] target estimand;
- [ ] selected primary inferential method;
- [ ] backend package and version;
- [ ] reason the method is compatible with the design;
- [ ] missing-data pattern;
- [ ] missingness assumption where required;
- [ ] resampling type and number of replicates;
- [ ] random seed;
- [ ] omnibus hypotheses;
- [ ] planned/simple-effect comparisons;
- [ ] multiplicity adjustment;
- [ ] effect estimates and uncertainty when available;
- [ ] compact letters only as a secondary summary;
- [ ] observed data displayed with model summaries when practical;
- [ ] sensitivity analysis when conclusions depend on modeling choice;
- [ ] support of quantitative predictors;
- [ ] integer decision set when applicable;
- [ ] limits on interpolation and extrapolation;
- [ ] software versions and session information;
- [ ] experimental status of any module that has not completed numerical validation.

---

# Part XX. Suggested reading sequence inside the package

After this tutorial, use the focused vignettes approximately in this order:

1. `v01-design-crd-rcbd.Rmd`
2. `v02-effects-conover-factorials.Rmd`
3. `v03-hierarchical-designs-trends-ancova-power.Rmd`
4. `v04-repeated-measures-and-missing-data.Rmd`
5. `v05-multivariate-multienvironment-batch-sensitivity.Rmd`
6. `v06-nonparametric-regression.Rmd`
7. `v07-integer-support-regression.Rmd`
8. `v11-distribution-free-uncertainty-and-diagnostics.Rmd`
9. `v12-optima-quantiles-and-block-structure.Rmd`
10. `v13-time-to-event-and-ranking-data.Rmd`
11. `v08-graphics-reporting-reproducibility.Rmd`
12. `v10-theory-state-of-art-common-mistakes.Rmd`
13. `v09-integrated-agronomic-case-study.Rmd`

This additional tutorial is intentionally broader than the focused vignettes. Its role is to give the reader a complete mental map before specializing.

---

# Appendix A. Main public API by purpose

## Design

```text
agri_design()
validate_agri_design()
design_summary()
agri_methods()
simulate_agri()
```

## Main inference

```text
agri_rank()
np_crd()
np_rcbd()
np_factorial()
np_splitplot()
np_splitsplit()
np_stripplot()
np_repeated()
agri_repeated()
```

## Missing repeated data

```text
agri_missing_report()
incomplete_wild_rank_test()
agri_missing_sensitivity()
```

## Effects and comparisons

```text
agri_effects()
agri_pairs()
agri_conover()
agri_contrast()
agri_cld()
```

## Planning and complementary inference

```text
agri_trend()
agri_ancova()
agri_power()
agri_sensitivity()
agri_batch()
```

## Multivariate and multi-environment

```text
agri_multivariate()
agri_multienv()
```

## General nonparametric regression

```text
agri_np_regression()
agri_np_predict()
agri_np_diagnostics()
agri_np_compare()
agri_np_derivative()
agri_np_optimum()
agri_np_bootstrap()
agri_np_plot()
agri_np_interactive()
agri_np_significance()
agri_np_specification()
```

## Integer-support regression

```text
agri_integer_predict()
agri_integer_difference()
agri_integer_optimum()
agri_integer_efficiency()
agri_integer_threshold()
agri_integer_bootstrap()
agri_integer_confset()
```

## Communication and reproducibility

```text
agri_plot()
agri_interactive()
agri_table()
agri_report()
agri_dashboard()
export_results()
```

---

# Appendix B. A single starter script

The following script is intentionally compact and can serve as a first local file after installing the package.

```r
library(agriRank)

# ------------------------------------------------------------
# 1. Inspect available methods.
# ------------------------------------------------------------
agri_methods()

# ------------------------------------------------------------
# 2. Simulate a complete RCBD.
# ------------------------------------------------------------
dat <- simulate_agri(
  "rcbd",
  seed = 20260820,
  n = 6
)

# ------------------------------------------------------------
# 3. Declare and validate.
# ------------------------------------------------------------
des <- agri_design(
  yield ~ treatment,
  dat,
  design = "rcbd",
  block = block
)

print(des)
print(
  validate_agri_design(
    des,
    error = FALSE
  )
)

# ------------------------------------------------------------
# 4. Primary inference.
# ------------------------------------------------------------
fit <- agri_rank(
  des,
  method = "auto",
  seed = 20260820
)

print(fit)
print(anova(fit))

# ------------------------------------------------------------
# 5. Effects and comparisons.
# ------------------------------------------------------------
print(
  agri_effects(fit)
)

print(
  agri_pairs(
    fit,
    adjust = "holm"
  )
)

if (requireNamespace("PMCMRplus", quietly = TRUE)) {
  print(
    agri_conover(
      fit,
      adjust = "holm"
    )
  )
}

# ------------------------------------------------------------
# 6. Scientific figure.
# ------------------------------------------------------------
print(
  agri_plot(
    fit,
    type = "data"
  )
)

# ------------------------------------------------------------
# 7. Report and export.
# ------------------------------------------------------------
agri_report(
  fit,
  file = "starter_agriRank_report.md",
  format = "md",
  language = "en"
)

export_results(
  fit,
  "starter_agriRank_results.rds"
)
```

---

# Appendix C. Reproducible advanced regression starter

```r
library(agriRank)

set.seed(20260820)

dat <- expand.grid(
  block = factor(1:5),
  plants = 1:10
)

dat$yield <-
  30 +
  8 * pmin(dat$plants, 6) -
  4.5 * pmax(dat$plants - 6, 0) +
  0.5 * as.numeric(dat$block) +
  rnorm(nrow(dat), 0, 1.5)

# Choose a method that can retain block.
if (requireNamespace("cgam", quietly = TRUE)) {
  fit <- agri_np_regression(
    yield ~ plants,
    data = dat,
    method = "umbrella",
    block = block,
    predictor_support = "observed_integer",
    integer_predictor = "plants"
  )

  print(fit)
  print(agri_integer_predict(fit))
  print(agri_integer_difference(fit, order = 1))
  print(agri_integer_efficiency(fit))
  print(agri_integer_optimum(fit))

  boot <- agri_integer_bootstrap(
    fit,
    B = 999,
    seed = 20260820
  )

  print(boot)
  print(agri_integer_confset(boot, level = 0.95))
  print(agri_np_plot(fit))

  agri_report(
    fit,
    "integer_support_report.md",
    format = "md",
    language = "en"
  )
}
```

---

# Appendix D. Selected methodological references

The references below correspond to the methodological literature already used in the `agriRank` documentation. The package repository contains a double-verification audit and a verified RIS library under `inst/references/`.

1. Pauly, M., Brunner, E., & Konietschke, F. (2015). Asymptotic permutation tests in general factorial designs. *Journal of the Royal Statistical Society: Series B*, 77(2), 461-473. https://doi.org/10.1111/rssb.12073
2. Brunner, E., Konietschke, F., Pauly, M., & Puri, M. L. (2017). Rank-based procedures in factorial designs: hypotheses about non-parametric treatment effects. *Journal of the Royal Statistical Society: Series B*, 79(5), 1463-1485. https://doi.org/10.1111/rssb.12222
3. Umlauft, M., Konietschke, F., & Pauly, M. (2017). Rank-based permutation approaches for non-parametric factorial designs. *British Journal of Mathematical and Statistical Psychology*, 70(3), 368-390. https://doi.org/10.1111/bmsp.12089
4. Friedrich, S., Konietschke, F., & Pauly, M. (2017). A wild bootstrap approach for nonparametric repeated measurements. *Computational Statistics & Data Analysis*, 113, 38-52. https://doi.org/10.1016/j.csda.2016.06.016
5. Umlauft, M., Placzek, M., Konietschke, F., & Pauly, M. (2019). Wild bootstrapping rank-based procedures: multiple testing in nonparametric factorial repeated measures designs. *Journal of Multivariate Analysis*, 171, 176-192. https://doi.org/10.1016/j.jmva.2018.12.005
6. Noguchi, K., Gel, Y. R., Brunner, E., & Konietschke, F. (2012). nparLD: An R software package for the nonparametric analysis of longitudinal data in factorial experiments. *Journal of Statistical Software*, 50(12), 1-23. https://doi.org/10.18637/jss.v050.i12
7. Friedrich, S., Konietschke, F., & Pauly, M. (2019). Resampling-based analysis of multivariate data and repeated measures designs with the R package MANOVA.RM. *The R Journal*, 11(2), 380-400. https://doi.org/10.32614/RJ-2019-051
8. Frossard, J., & Renaud, O. (2021). Permutation tests for regression, ANOVA, and comparison of signals: the permuco package. *Journal of Statistical Software*, 99(15). https://doi.org/10.18637/jss.v099.i15
9. Hothorn, T., Hornik, K., van de Wiel, M. A., & Zeileis, A. (2008). Implementing a class of permutation tests: the coin package. *Journal of Statistical Software*, 28(8), 1-23. https://doi.org/10.18637/jss.v028.i08
10. Happ, M., Zimmermann, G., Brunner, E., & Bathke, A. C. (2020). Pseudo-ranks: How to calculate them efficiently in R. *Journal of Statistical Software*, 95, Code Snippet 1, 1-22. https://doi.org/10.18637/jss.v095.c01
11. Brunner, E., Konietschke, F., Bathke, A. C., & Pauly, M. (2021). Ranks and pseudo-ranks: surprising results of certain rank tests in unbalanced designs. *International Statistical Review*, 89(2), 349-366. https://doi.org/10.1111/insr.12418
12. Konietschke, F., & Brunner, E. (2023). rankFD: An R software package for nonparametric analysis of general factorial designs. *The R Journal*, 15(1), 142-158. https://doi.org/10.32614/RJ-2023-029
13. Amro, L., Konietschke, F., & Pauly, M. (2024). Incompletely observed nonparametric factorial designs with repeated measurements: a wild bootstrap approach. *Biometrical Journal*, 66(8), e70008. https://doi.org/10.1002/bimj.70008
14. Jan, S.-L., & Shieh, G. (2025). An improved nonparametric test and sample size procedures for the randomized complete block designs. *Sankhya B*, 87, 686-711. https://doi.org/10.1007/s13571-025-00362-2
15. Thiel, K. E., Sattler, P., Bathke, A. C., & Zimmermann, G. (2026). Resampling NANCOVA: Nonparametric analysis of covariance in small samples. *Computational Statistics & Data Analysis*, 215, 108290. https://doi.org/10.1016/j.csda.2025.108290
16. Wobbrock, J. O., Findlater, L., Gergle, D., & Higgins, J. J. (2011). The aligned rank transform for nonparametric factorial analyses using only ANOVA procedures. *Proceedings of CHI 2011*, 143-146. https://doi.org/10.1145/1978942.1978963
17. Elkin, L. A., Kay, M., Higgins, J. J., & Wobbrock, J. O. (2021). An aligned rank transform procedure for multifactor contrast tests. *Proceedings of UIST 2021*, 754-768. https://doi.org/10.1145/3472749.3474784
18. Hayfield, T., & Racine, J. S. (2008). Nonparametric econometrics: The np package. *Journal of Statistical Software*, 27(5). https://doi.org/10.18637/jss.v027.i05
19. Pya, N., & Wood, S. N. (2015). Shape constrained additive models. *Statistics and Computing*, 25(3), 543-559. https://doi.org/10.1007/s11222-013-9448-7
20. Sen, P. K. (1968). Estimates of the regression coefficient based on Kendall's tau. *Journal of the American Statistical Association*, 63(324), 1379-1389. https://doi.org/10.1080/01621459.1968.10480934
21. Wood, S. N. (2025). Generalized additive models. *Annual Review of Statistics and Its Application*, 12, 497-526. https://doi.org/10.1146/annurev-statistics-112723-034249
22. Ng, P., & Maechler, M. (2007). A fast and efficient implementation of qualitatively constrained quantile smoothing splines. *Statistical Modelling*, 7(4), 315-328. https://doi.org/10.1177/1471082X0700700403
23. Koenker, R., & Bassett, G., Jr. (1978). Regression quantiles. *Econometrica*, 46(1), 33-50. https://doi.org/10.2307/1913643
24. Racine, J. S., Hart, J., & Li, Q. (2006). Testing the significance of categorical predictor variables in nonparametric regression models. *Econometric Reviews*, 25(4), 523-544. https://doi.org/10.1080/07474930600972590
25. Hsiao, C., Li, Q., & Racine, J. S. (2007). A consistent model specification test with mixed discrete and continuous data. *Journal of Econometrics*, 140(2), 802-826. https://doi.org/10.1016/j.jeconom.2006.07.015
26. Wang, M.-C., & van Ryzin, J. (1981). A class of smooth estimators for discrete distributions. *Biometrika*, 68(1), 301-309. https://doi.org/10.1093/biomet/68.1.301
27. Racine, J. S., & Li, Q. (2004). Nonparametric estimation of regression functions with both categorical and continuous data. *Journal of Econometrics*, 119(1), 99-130. https://doi.org/10.1016/S0304-4076(03)00157-X
28. Turner, T. R., & Wollan, P. C. (1997). Locating a maximum using isotonic regression. *Computational Statistics & Data Analysis*, 25(3), 305-320. https://doi.org/10.1016/S0167-9473(97)00009-1
29. Stout, Q. F. (2008). Unimodal regression via prefix isotonic regression. *Computational Statistics & Data Analysis*, 53(2), 289-297. https://doi.org/10.1016/j.csda.2008.08.005
30. Geng, Z., & Shi, N.-Z. (1990). Isotonic regression for umbrella orderings. *Journal of the Royal Statistical Society Series C: Applied Statistics*, 39(3), 397-402. https://doi.org/10.2307/2347399
31. Liao, X., & Meyer, M. C. (2019). cgam: An R package for the constrained generalized additive model. *Journal of Statistical Software*, 89(5). https://doi.org/10.18637/jss.v089.i05

---

# Final perspective

The most important contribution of `agriRank` is not a single test.

Its value lies in connecting the full analytical sequence:

**experimental design -> admissible inference -> effect estimation -> contrasts -> sensitivity -> visualization -> report -> reproducibility.**

For a beginner, the recommended route is:

**declare the design -> validate -> fit the simplest design-compatible analysis -> inspect effects and contrasts -> plot observed data -> report.**

For an advanced analyst, the route expands to:

**declare the design -> define the estimand -> compare rank/permutation/resampling paradigms -> preserve repeated or hierarchical dependence -> characterize missingness -> model multiple responses or environments -> analyze quantitative gradients -> quantify decision uncertainty -> report method sensitivity and limitations.**

The package is therefore best understood as one progressive analysis grammar. Classical Kruskal-Wallis and Friedman tests remain useful components, but they sit inside a broader framework that also respects factorial interactions, plot hierarchies, repeated dependence, incomplete observations, multivariate structure, multi-environment trials, flexible regression, and discrete operational decisions.

The strongest analysis is not the one with the most advanced method. It is the one whose estimand, resampling structure, uncertainty statement, and interpretation remain faithful to the experiment that was actually conducted.
