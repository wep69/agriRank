# Package index

## Declare the design

Every analysis starts from an explicit randomization structure.

- [`agri_design()`](https://wep69.github.io/agriRank/reference/agri_design.md)
  : Declare an agricultural experimental design
- [`validate_agri_design()`](https://wep69.github.io/agriRank/reference/validate_agri_design.md)
  : Validate an agricultural experimental design
- [`design_summary()`](https://wep69.github.io/agriRank/reference/design_summary.md)
  : Summarize a declared agricultural design
- [`simulate_agri()`](https://wep69.github.io/agriRank/reference/simulate_agri.md)
  : Simulate representative agricultural experiments

## Design-aware inference

- [`agri_rank()`](https://wep69.github.io/agriRank/reference/agri_rank.md)
  : Fit design-aware rank-based or permutation inference
- [`agri_repeated()`](https://wep69.github.io/agriRank/reference/agri_repeated.md)
  : Analyze repeated measurements with explicit backend selection
- [`agri_multivariate()`](https://wep69.github.io/agriRank/reference/agri_multivariate.md)
  : Integrated multivariate resampling inference
- [`agri_multienv()`](https://wep69.github.io/agriRank/reference/agri_multienv.md)
  : Analyze multi-environment treatment data with enforced environment
  structure
- [`np_crd()`](https://wep69.github.io/agriRank/reference/np_crd.md) :
  Analyze a completely randomized design
- [`np_rcbd()`](https://wep69.github.io/agriRank/reference/np_rcbd.md) :
  Analyze a randomized complete block design
- [`np_factorial()`](https://wep69.github.io/agriRank/reference/np_factorial.md)
  : Analyze a nonparametric factorial experiment
- [`np_splitplot()`](https://wep69.github.io/agriRank/reference/np_splitplot.md)
  : Analyze a split-plot experiment
- [`np_splitsplit()`](https://wep69.github.io/agriRank/reference/np_splitsplit.md)
  : Design-aware nonparametric split-split-plot workflow
- [`np_stripplot()`](https://wep69.github.io/agriRank/reference/np_stripplot.md)
  : Design-aware nonparametric strip-plot workflow
- [`np_repeated()`](https://wep69.github.io/agriRank/reference/np_repeated.md)
  : Analyze repeated measurements
- [`incomplete_wild_rank_test()`](https://wep69.github.io/agriRank/reference/incomplete_wild_rank_test.md)
  : Wild-bootstrap rank inference for incomplete repeated measurements

## Effects, comparisons and contrasts

- [`agri_effects()`](https://wep69.github.io/agriRank/reference/agri_effects.md)
  : Extract treatment effect summaries
- [`agri_pairs()`](https://wep69.github.io/agriRank/reference/agri_pairs.md)
  : Compute pairwise treatment comparisons
- [`agri_conover()`](https://wep69.github.io/agriRank/reference/agri_conover.md)
  : Design-aware Conover all-pairs comparisons
- [`agri_cld()`](https://wep69.github.io/agriRank/reference/agri_cld.md)
  : Create a compact letter display
- [`agri_contrast()`](https://wep69.github.io/agriRank/reference/agri_contrast.md)
  : Test user-defined contrasts

## Regression for quantitative gradients

Continuous smoothers, shape constraints and rank-robust slopes for
fertilizer rates, salinity, irrigation and other agronomic gradients.

- [`agri_np_regression()`](https://wep69.github.io/agriRank/reference/agri_np_regression.md)
  : Fit nonparametric and semiparametric regression models for agronomic
  data
- [`agri_np_predict()`](https://wep69.github.io/agriRank/reference/agri_np_predict.md)
  : Predict from an agriRank nonparametric regression
- [`agri_np_plot()`](https://wep69.github.io/agriRank/reference/agri_np_plot.md)
  : Scientific ggplot2 graphics for nonparametric regression
- [`agri_np_derivative()`](https://wep69.github.io/agriRank/reference/agri_np_derivative.md)
  : Estimate the derivative of a fitted agronomic response curve
- [`agri_np_optimum()`](https://wep69.github.io/agriRank/reference/agri_np_optimum.md)
  : Locate a descriptive optimum on a fitted nonparametric curve
- [`agri_np_bootstrap()`](https://wep69.github.io/agriRank/reference/agri_np_bootstrap.md)
  : Cluster-aware bootstrap confidence bands for agronomic regression
- [`agri_np_compare()`](https://wep69.github.io/agriRank/reference/agri_np_compare.md)
  : Cross-validated comparison of agronomic regression engines
- [`agri_np_diagnostics()`](https://wep69.github.io/agriRank/reference/agri_np_diagnostics.md)
  : Diagnostics for nonparametric regression
- [`agri_np_significance()`](https://wep69.github.io/agriRank/reference/agri_np_significance.md)
  : Test predictor significance in mixed-data kernel regression
- [`agri_np_specification()`](https://wep69.github.io/agriRank/reference/agri_np_specification.md)
  : Test a prespecified Gaussian regression against a nonparametric
  alternative
- [`agri_np_interactive()`](https://wep69.github.io/agriRank/reference/agri_np_interactive.md)
  : Interactive Plotly graphics for agronomic nonparametric regression
- [`coef(`*`<agri_np_reg_fit>`*`)`](https://wep69.github.io/agriRank/reference/agri_np_extractors.md)
  [`confint(`*`<agri_np_reg_fit>`*`)`](https://wep69.github.io/agriRank/reference/agri_np_extractors.md)
  [`fitted(`*`<agri_np_reg_fit>`*`)`](https://wep69.github.io/agriRank/reference/agri_np_extractors.md)
  [`residuals(`*`<agri_np_reg_fit>`*`)`](https://wep69.github.io/agriRank/reference/agri_np_extractors.md)
  : Standard extractors for agriRank regression fits
- [`agri_np_curves()`](https://wep69.github.io/agriRank/reference/agri_np_curves.md)
  : Overlay the fitted curves of several regression engines
- [`plot(`*`<agri_np_bootstrap>`*`)`](https://wep69.github.io/agriRank/reference/agri_np_regression_plots.md)
  [`plot(`*`<agri_np_compare>`*`)`](https://wep69.github.io/agriRank/reference/agri_np_regression_plots.md)
  [`plot(`*`<agri_integer_bootstrap>`*`)`](https://wep69.github.io/agriRank/reference/agri_np_regression_plots.md)
  [`plot(`*`<agri_integer_confset>`*`)`](https://wep69.github.io/agriRank/reference/agri_np_regression_plots.md)
  : Plot methods for regression result objects
- [`agri_np_forest()`](https://wep69.github.io/agriRank/reference/agri_np_forest.md)
  : Forest plot of bootstrap intervals for regression coefficients
- [`agri_np_levels()`](https://wep69.github.io/agriRank/reference/agri_np_levels.md)
  : Response summaries at each level of the qualitative predictors

## Distribution-free uncertainty and model checking

Where the response is really changing, what interval covers the next
plot, and whether the fit describes the data, all without a
distributional assumption.

- [`agri_np_sizer()`](https://wep69.github.io/agriRank/reference/agri_np_sizer.md)
  [`agri_np_significant_slope()`](https://wep69.github.io/agriRank/reference/agri_np_sizer.md)
  [`plot(`*`<agri_np_sizer>`*`)`](https://wep69.github.io/agriRank/reference/agri_np_sizer.md)
  : Significant zero crossings of the derivative
- [`agri_np_conformal()`](https://wep69.github.io/agriRank/reference/agri_np_conformal.md)
  [`agri_np_coverage()`](https://wep69.github.io/agriRank/reference/agri_np_conformal.md)
  : Distribution-free prediction intervals by split conformal inference
- [`agri_np_simdiag()`](https://wep69.github.io/agriRank/reference/agri_np_simdiag.md)
  [`plot(`*`<agri_np_simdiag>`*`)`](https://wep69.github.io/agriRank/reference/agri_np_simdiag.md)
  : Simulation-based quantile residuals
- [`agri_np_effect_test()`](https://wep69.github.io/agriRank/reference/agri_np_effect_test.md)
  : Does a predictor earn its place in the model
- [`agri_np_shape_test()`](https://wep69.github.io/agriRank/reference/agri_np_shape_test.md)
  : Is a declared shape compatible with the data

## Data the cross-sectional module cannot hold

Plots measured more than once, several responses to the same gradient,
and plots that were lost.

- [`agri_np_longitudinal()`](https://wep69.github.io/agriRank/reference/agri_np_longitudinal.md)
  : Regression along a gradient measured repeatedly on the same units
- [`agri_np_multiresponse()`](https://wep69.github.io/agriRank/reference/agri_np_multiresponse.md)
  : Several responses to one gradient, with a joint region for their
  optima
- [`agri_np_impute()`](https://wep69.github.io/agriRank/reference/agri_np_impute.md)
  : Multiple imputation for a regression with missing plots

## From a curve to a recommendation

What rate to recommend and with what interval, whether an optimum exists
at all, what the poor plots do rather than the average one, and how the
declared block enters the model.

- [`agri_np_optimum_test()`](https://wep69.github.io/agriRank/reference/agri_np_optimum_test.md)
  : Confidence interval and tests for the location of an optimum
- [`agri_np_optimum_economic()`](https://wep69.github.io/agriRank/reference/agri_np_optimum_economic.md)
  : Economic optimum of a fitted response curve
- [`agri_np_optimum_surface()`](https://wep69.github.io/agriRank/reference/agri_np_optimum_surface.md)
  : Joint optimum of a response surface in two predictors
- [`agri_np_quantile_curves()`](https://wep69.github.io/agriRank/reference/agri_np_quantile_curves.md)
  : Smooth conditional quantile curves
- [`agri_np_block_effects()`](https://wep69.github.io/agriRank/reference/agri_np_block_effects.md)
  : Fixed and shrunk block effects side by side

## When the datum is not a measurement

Germination and emergence, counted inside intervals and censored at the
end of the trial, and on-farm trials in which the datum is an order
rather than a measurement.

- [`agri_np_timetoevent()`](https://wep69.github.io/agriRank/reference/agri_np_timetoevent.md)
  : Nonparametric time-to-event analysis for germination and emergence
- [`agri_rankings()`](https://wep69.github.io/agriRank/reference/agri_rankings.md)
  : Within-block rankings and the on-farm ranking bridge

## Integer decision support

Treatments that can only take whole values, such as plants per hill,
irrigation events or sprays.

- [`agri_integer_predict()`](https://wep69.github.io/agriRank/reference/agri_integer_predict.md)
  : Predict on an admissible integer decision support
- [`agri_integer_optimum()`](https://wep69.github.io/agriRank/reference/agri_integer_optimum.md)
  : Maximum or minimum on an integer decision support
- [`agri_integer_difference()`](https://wep69.github.io/agriRank/reference/agri_integer_difference.md)
  : Finite differences for integer-valued agronomic decisions
- [`agri_integer_threshold()`](https://wep69.github.io/agriRank/reference/agri_integer_threshold.md)
  : Practical thresholds on an integer agronomic support
- [`agri_integer_efficiency()`](https://wep69.github.io/agriRank/reference/agri_integer_efficiency.md)
  : Discrete fitted-response and marginal-efficiency table
- [`agri_integer_bootstrap()`](https://wep69.github.io/agriRank/reference/agri_integer_bootstrap.md)
  : Bootstrap distribution of an integer optimum
- [`agri_integer_confset()`](https://wep69.github.io/agriRank/reference/agri_integer_confset.md)
  : Bootstrap confidence set for an integer optimum

## Missing data and sensitivity

- [`agri_missing_report()`](https://wep69.github.io/agriRank/reference/agri_missing_report.md)
  : Characterize missing response observations
- [`agri_missing_sensitivity()`](https://wep69.github.io/agriRank/reference/agri_missing_sensitivity.md)
  : Compare all-available and complete-subject repeated analyses
- [`agri_sensitivity()`](https://wep69.github.io/agriRank/reference/agri_sensitivity.md)
  : Compare admissible inferential paradigms
- [`agri_batch()`](https://wep69.github.io/agriRank/reference/agri_batch.md)
  : Analyze multiple responses under one design

## Trend, covariance and power

- [`agri_trend()`](https://wep69.github.io/agriRank/reference/agri_trend.md)
  : Test an ordered treatment trend
- [`agri_ancova()`](https://wep69.github.io/agriRank/reference/agri_ancova.md)
  : Fit a permutation ANCOVA adapter
- [`agri_power()`](https://wep69.github.io/agriRank/reference/agri_power.md)
  : Estimate power by simulation

## Graphics, tables and reports

- [`agri_plot()`](https://wep69.github.io/agriRank/reference/agri_plot.md)
  : Create publication-oriented ggplot graphics
- [`agri_interactive()`](https://wep69.github.io/agriRank/reference/agri_interactive.md)
  : Convert an agriRank plot to Plotly
- [`agri_table()`](https://wep69.github.io/agriRank/reference/agri_table.md)
  : Create standardized agriRank analysis tables
- [`agri_dashboard()`](https://wep69.github.io/agriRank/reference/agri_dashboard.md)
  : Generate a self-contained Quarto dashboard source
- [`agri_report()`](https://wep69.github.io/agriRank/reference/agri_report.md)
  : Generate a reproducible agriRank analysis report
- [`export_results()`](https://wep69.github.io/agriRank/reference/export_results.md)
  : Export an agriRank analysis bundle
- [`agri_methods()`](https://wep69.github.io/agriRank/reference/agri_methods.md)
  : List available inferential domains and engines
- [`agri_theme()`](https://wep69.github.io/agriRank/reference/agri_graphics.md)
  [`agri_save_figure()`](https://wep69.github.io/agriRank/reference/agri_graphics.md)
  : Journal-oriented graphics: theme and archival export
- [`agri_format_ci()`](https://wep69.github.io/agriRank/reference/agri_format_ci.md)
  : Format a coefficient and its confidence interval for manuscript text
- [`agri_tidy()`](https://wep69.github.io/agriRank/reference/agri_broom.md)
  [`agri_glance()`](https://wep69.github.io/agriRank/reference/agri_broom.md)
  [`agri_augment()`](https://wep69.github.io/agriRank/reference/agri_broom.md)
  : Tidy an agriRank fit into a data frame

## Package and methods

- [`agriRank-package`](https://wep69.github.io/agriRank/reference/agriRank-package.md)
  [`agriRank`](https://wep69.github.io/agriRank/reference/agriRank-package.md)
  : agriRank: Design-Aware Rank-Based, Permutation and Robust Inference
  for Agricultural Experiments
- [`update(`*`<agri_np_reg_fit>`*`)`](https://wep69.github.io/agriRank/reference/update.agri_np_reg_fit.md)
  : Refit a nonparametric regression changing only what is named

## Example data

Shared data sets used across the examples and vignettes.

- [`agri_dose`](https://wep69.github.io/agriRank/reference/agri_dose.md)
  : Nitrogen response in a randomized complete block design
- [`agri_density`](https://wep69.github.io/agriRank/reference/agri_density.md)
  : Plant density response with an integer treatment
- [`agri_surface`](https://wep69.github.io/agriRank/reference/agri_surface.md)
  : Two-gradient response surface, nitrogen and irrigation depth
