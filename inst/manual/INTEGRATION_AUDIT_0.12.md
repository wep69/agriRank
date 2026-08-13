# agriRank 0.12.0.9000 integration audit

## Scope

Version 0.12.0.9000 closes the four principal structural gaps identified in the 0.11 audit and also extends common result/report integration where this could be done without an R runtime.

## Structural corrections

### Split-split-plot

`agri_design()` now requires and records `subsubplot=` for `design = "split_split"`. The declared hierarchy is:

`block -> whole plot -> subplot -> sub-subplot`.

`np_splitsplit()` is a dedicated public wrapper. The ARTool adapter creates block, whole-plot-unit and subplot-unit grouping terms. The permuco adapter creates `Error(block/whole_plot/subplot)`-style strata using hidden design-safe factor names. Final numerical calibration remains a runtime validation gate.

### Strip-plot

`agri_design()` now requires `strip_a=` and `strip_b=` for `design = "strip_plot"`. `np_stripplot()` is a dedicated public wrapper. The ARTool adapter represents block, block-by-strip-A and block-by-strip-B grouping units. The permuco adapter constructs the corresponding classical error strata while leaving the strip-A by strip-B intersection in the remaining stratum. Final numerical calibration remains a runtime validation gate.

### Multivariate inference

`agri_rank()` no longer silently reduces a multivariate declaration to the first response. Users are directed to `agri_multivariate()`.

`agri_multivariate()` now returns a common `agri_multivariate_fit` class and routes among the MANOVA.RM wide, long and multivariate-repeated workflows according to the response layout and declared within-subject structure. The result is accepted by `agri_table()`, `agri_report()`, `agri_dashboard()` and `export_results()`.

A declared block is retained as an explicit adjustment factor in the MANOVA.RM formula when it is not already present. This is an adjustment term, not a claim that MANOVA.RM is fitting a random block effect.

### Multi-environment enforcement

Direct `agri_design(..., design = "multienv")` declarations now require the declared environment to appear in the formula.

`agri_multienv()` enforces the environment automatically. If it is missing from the supplied formula, the default adds the treatment-by-environment structure; `environment_interaction = FALSE` adds the environment main effect only. When block labels repeat across environments, the ART/permutation adapters namespace block units within environment.

## Additional integration completed

- `agri_trend()`, `agri_power()` and `agri_ancova()` have explicit result classes compatible with the common table/report/export layer where applicable.
- `agri_batch`, `agri_sensitivity`, and `agri_missing_report` are accepted by `agri_table()`, `agri_report()`, `agri_dashboard()`, and `export_results()`.
- `confint.agri_rank_fit()` now fails explicitly when a backend does not expose a standardized confidence interval rather than returning a non-interval effect summary.
- The RCBD vignette includes executable design-aware Conover examples.
- The Linux/Debian validation runner default archive name is updated to 0.12.0.9000.
- `inst/CITATION` version strings are synchronized with 0.12.0.9000.
- The standalone offline dependency and validation scripts were updated outside the source package so they do not add non-package runtime dependencies to CRAN checks.

## Static audit result

The final source-tree audit found:

- 53 exported functions;
- 53/53 exported functions with source definitions;
- 53/53 exported functions with dedicated Rd aliases;
- all exported functions with at least three documented example code lines;
- 18 R Markdown vignettes;
- 8 `testthat` files;
- 53/53 exported functions referenced directly in the unit-test suite;
- 17 registered S3 methods, all with definitions;
- no undeclared external packages used through `pkg::fun()`;
- no detected delimiter imbalance in R/test files;
- no detected Rd brace imbalance;
- no detected R Markdown code-fence imbalance.

## Runtime validation still mandatory

R and Rscript are not mounted in the environment used to make these source-level corrections. Therefore the following claims are deliberately not made yet:

- that `R CMD check --as-cran` is clean;
- that every optional backend API accepts the generated formulas under the installed package versions;
- that split-split and strip-plot p-values have the desired finite-sample calibration;
- that MANOVA.RM routing is numerically identical to direct backend calls;
- that all vignettes execute successfully with computation enabled.

Those items remain mandatory local-PC gates in `VALIDATION_PLAN.md` and the supplied validation scripts.

## Release metadata not inferable in this environment

The package still uses a development-team author/maintainer placeholder because a verified maintainer email and final author list were not supplied to this build environment. These values must be replaced before CRAN submission; no personal email or authorship metadata should be invented automatically.

## Formula-fidelity safeguards added during the final integration pass

The final audit also corrected model-term propagation across backends. `rankFD`, ARTool, permuco, nparLD and MANOVA.RM adapters now preserve the declared model terms appropriate to their interfaces instead of reconstructing models only from predictor names. This prevents both omission of declared factorial interactions and accidental creation of an interaction that the user intentionally excluded.

`agri_batch()` now changes only the response while preserving the original right-hand-side formula. Explicit `kruskal` and `rankFD` requests are rejected when a block has been declared, because those adapters would otherwise discard the block randomization semantics.
