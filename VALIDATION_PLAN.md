# agriRank statistical validation plan

## Gate 1: package execution

Run `R CMD build`, `R CMD check --as-cran` and the full `testthat` suite on R-release, R-oldrel and R-devel under Windows, Linux and macOS.

## Gate 2: backend identity tests

For frozen datasets, compare wrapper outputs against direct calls to `stats::kruskal.test`, `stats::friedman.test`, `rankFD::rankFD`, `nparLD::nparLD`, `MANOVA.RM::RM`, `permuco::aovperm` and `ARTool::art`. Test p-values, statistics, degrees of freedom, ordering and factor-label invariance.

## Gate 3: native incomplete repeated engine

Benchmark all intermediate quantities against the reference implementation accompanying Amro, Konietschke & Pauly (2024): global mid-ranks, cell observation counts, relative marginal effects, covariance blocks, WTS, ATS, MATS and bootstrap p-values using frozen Rademacher sequences. Acceptance tolerance should be documented before testing.

## Gate 4: simulation calibration

At minimum 10,000 simulated experiments per major scenario for Type-I error; at least 999 wild/permutation replicates during development and 4,999 or more for final benchmark runs where computationally feasible. Cross distributions (normal, t, lognormal, gamma, ordinal), covariance structures, balanced/unbalanced allocations, ties, 0-60% missingness, MCAR and prespecified MAR stress scenarios.

Record empirical Type-I error, power, Monte Carlo standard error, CI coverage, failure rate and runtime. Do not select methods by observed p-value.

## Gate 5: randomization semantics

Verify treatment-label and row-order invariance, block-label invariance, correct subject-level multiplier reuse across repeated coordinates, correct whole-plot error strata, and rejection of duplicated repeated subject-by-within cells.

## Gate 6: publication outputs

Validate tables and plots against underlying fit objects. Every reported p-value must be traceable to its engine, resampling count, seed and multiplicity method. Reports must state the missingness assumption and experimental status when the native incomplete engine is used.

## Nonparametric regression validation (0.10.x)

The regression module requires validation separately for prediction, inferential uncertainty, shape constraints, and design preservation.

### Engines

Compare `agriRank` outputs against direct calls to `stats::loess`, `stats::smooth.spline`, `stats::isoreg`, `mblm::mblm`, `quantreg::rq`, `np::npreg`, `mgcv::gam`, `scam::scam`, and `cobs::cobs` using frozen data and seeds.

### Simulation factors

- curve shape: linear, quadratic, plateau, sigmoid, monotone decreasing, convex, multimodal;
- predictor density: regular and irregular;
- n: 20, 40, 80, 160;
- noise: Gaussian, t(3), lognormal, heteroscedastic, 5% and 10% contamination;
- mixed predictors: continuous + unordered factor + ordered factor;
- blocks: none, 4, 6, and 10 blocks;
- missing response: 0, 10%, 25%;
- boundary optimum vs interior optimum.

### Metrics

- integrated squared error and pointwise bias;
- RMSE/MAE and repeated K-fold prediction error;
- empirical coverage of bootstrap bands;
- monotonicity/convexity violation count for constrained engines;
- derivative sign recovery;
- optimum location bias and boundary-detection rate;
- failure/convergence rate and runtime.

### Design safeguards

Tests must verify that engines unable to represent a declared block stop with an informative error; block-aware engines must retain block variables after cross-validation and cluster bootstrap.

### Conover validation

For fixed datasets, compare `agri_conover()` exactly against `PMCMRplus::kwAllPairsConoverTest()` for CRD and `PMCMRplus::frdAllPairsConoverTest()` for complete unreplicated RCBD, including p-value adjustment, factor relabeling, row-order invariance, and rejection of incomplete/replicated RCBD cells.

### Regression significance and specification diagnostics

- Compare `agri_np_significance()` to direct `np::npsigtest()` calls under continuous-only and mixed continuous/categorical predictor structures, including individual and joint tests.
- Compare `agri_np_specification()` to direct `np::npcmstest()` calls for correctly specified and misspecified Gaussian linear/polynomial candidates.
- Simulate null and nonlinear alternatives to evaluate empirical size and power under the documented bootstrap calibrations.
- Verify that a declared block remains in the conditioning model but is excluded from the default scientific predictor test set.
- Verify explicit failure when a regression method would ignore a requested shape constraint, unsupported weights, or repeated-subject dependence.


## Integer-support regression validation (0.11.x)

### Support invariants

For every integer-support engine, verify that public prediction, optimum/minimum searches, efficiency summaries, threshold rules, bootstrap decisions, plots and reports use only the declared admissible support. Fractional values and integer values outside the support must fail explicitly. Distinguish `observed_integer`, `integer_range` and `custom_integer` supports in tests.

### Ordered-discrete kernel

Compare `method = "discrete_kernel"` to direct `np::npregbw()`/`np::npreg()` calls after encoding the focal predictor as an ordered factor with identical support levels. Validate Wang--van Ryzin and the other exposed ordered kernels, mixed predictors, block adjustment, row/factor-label invariance, and bandwidth reproducibility.

### Unimodal isotonic regression

Compare fitted values, selected mode and weighted residual criterion to direct `Iso::ufit()` calls on aggregated integer support points. Simulate known unimodal, flat-top and misspecified multimodal curves. Record mode recovery, fitted-response error and boundary-mode frequency.

### Umbrella ordering

Compare fitted values and admissible optimum sets to direct `cgam::cgam()` umbrella fits. Verify increase-then-decrease ordering, plateau/tie behavior, block/covariate retention and explicit failure for unsupported structures.

### Integer-grid projection

For each supported base engine (`gam`, `scam`, `kernel`, `quantile`, `loess`, `smoothing_spline`, `cobs`), compare latent fits to their ordinary regression counterparts but require all decision outputs to equal direct evaluation on the fixed integer lattice. Explicitly test that rounding the latent continuous optimum can disagree with the support-restricted argmax and that `agriRank` returns the latter.

### Finite differences and practical decisions

Verify first differences against `m(x_{j+1})-m(x_j)` and second differences against `m(k+1)-2m(k)+m(k-1)` on unit-spaced supports. Validate fraction-of-maximum, gain-from-baseline and marginal-gain thresholds on analytically controlled curves.

### Bootstrap optimum distribution

Refit the entire model in every bootstrap replicate while keeping the original decision lattice fixed. Confirm that probability mass sums to one over successful replicates, ties divide replicate mass exactly, block resampling preserves whole blocks, and the discrete confidence set is the smallest highest-probability support set reaching the requested cumulative probability under the documented rule. Assess optimum-set coverage and probability calibration in simulation.


## Hierarchical and multivariate integration validation (0.12.x)

### Split-split

- Verify that `subsubplot=` is mandatory and appears in the formula.
- Compare the generated permuco formula against `Error(block/whole_plot/subplot)`.
- Compare the ARTool randomization terms against block, block-by-whole-plot, and block-by-whole-plot-by-subplot units.
- Simulate null effects separately at whole-plot, subplot, sub-subplot, and interaction strata and verify type-I error control.
- Verify invariance to relabeling blocks and experimental-unit identifiers.

### Strip-plot

- Verify that `strip_a=` and `strip_b=` are mandatory and appear in the formula.
- Confirm the classical strip random structure: block, block-by-strip-A, block-by-strip-B, with the A-by-B intersection evaluated in the remaining stratum.
- Compare ARTool and permuco adapters under balanced simulated strip plots.
- Verify that ordinary factorial analysis is never selected automatically for a declared strip plot.

### Multivariate

- Verify `MANOVA.wide` routing for `cbind()` wide responses.
- Verify long-format `MANOVA` routing when a single response and `subject=` identify the multivariate vector.
- Verify `multRM` routing for multiple responses plus `within=`.
- Compare WTS/MATS/resampling results against direct MANOVA.RM calls.
- Verify `agri_table`, `agri_report`, `agri_dashboard`, and `export_results` on `agri_multivariate_fit`.

### Multi-environment

- Verify that direct `agri_design(..., design = "multienv")` rejects formulas that omit the declared environment.
- Verify that `agri_multienv(yield ~ genotype, ...)` injects `environment` and `genotype:environment` by default.
- Verify `environment_interaction = FALSE` adds environment as a main effect only.
- Verify blocks with repeated labels across environments are treated as environment-specific units.

## Cross-backend formula-fidelity validation (0.12.x)

- Confirm that `rankFD`, ARTool, permuco, nparLD and MANOVA.RM adapters receive the treatment/interactions declared by the user rather than a reconstructed additive or fully crossed surrogate.
- For `yield ~ A * B`, verify that the interaction is present in every applicable backend formula and omnibus table.
- For multi-environment `environment_interaction = FALSE`, verify that the fitted permuco formula contains genotype and environment main effects but no GxE term.
- Verify that ARTool is rejected for a multi-environment additive main-effect-only specification because its factorial transform requires the relevant fixed-effect interactions.
- Verify that `agri_batch()` preserves the complete right-hand-side term structure while replacing only the response.
- Verify that explicit Kruskal/rankFD requests are rejected when a block is declared rather than discarding the block structure.
