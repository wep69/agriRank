# Fit nonparametric and semiparametric regression models for agronomic data

Unified agronomic regression workflow containing strictly nonparametric
smoothers, rank-robust estimators, conditional-quantile models, and
modern semiparametric smoothers.

## Usage

``` r
agri_np_regression(formula, data = NULL, method = c("auto", 
    "theil_sen", "siegel", "quantile", "loess", "smoothing_spline", 
    "kernel", "gam", "scam", "cobs", "isotonic", "discrete_kernel", 
    "unimodal_isotonic", "umbrella", "integer_grid", 
    "smooth_quantile"), 
    tau = 0.5, family = stats::gaussian(), shape = c("none", 
        "increasing", "decreasing", "convex", "concave", 
        "increasing_convex", "increasing_concave", 
        "decreasing_convex", "decreasing_concave"), 
    block = NULL, block_effect = c("fixed", "shrunk"), 
    spatial = c("none", "smooth_xy", "row_col"), coords = NULL, 
    weights = NULL, na_action = c("fail", 
        "complete"), span = 0.75, degree = 2L, k = 10L, 
    gam_structure = c("additive", "tensor", "varying"), kernel_regtype = c("ll", 
        "lc"), bwmethod = "cv.aic", predictor_support = c("continuous", 
        "observed_integer", "integer_range", "custom_integer"), 
    integer_predictor = NULL, integer_range = NULL, 
    integer_values = NULL, integer_kernel = c("wangvanryzin", 
        "liracine"), integer_base_method = c("gam", 
        "scam", "kernel", "quantile", "loess", "smoothing_spline", 
        "cobs"), ...)
```

## Arguments

- formula:

  Regression formula with one response, or an `agri_design` object.

- data:

  Data frame; optional when an `agri_design` object is supplied.

- method:

  Regression engine.

- tau:

  Conditional quantile for quantile or COBS regression.

- family:

  Response family for GAM/SCAM.

- shape:

  Optional monotonicity or curvature constraint.

- block:

  Optional agronomic block variable. Engines that cannot adjust for
  blocks are rejected when this is supplied.

- block_effect:

  How the declared block enters the model. `"fixed"`, the default,
  estimates one free effect per block and assumes nothing about how
  blocks relate to each other, but those effects exist only for the
  blocks that were observed. `"shrunk"` replaces them by a penalized
  term whose effects are pulled towards their common mean by an amount
  the data choose, which is what makes prediction into an unobserved
  field or year possible. Available for `"gam"`, `"scam"` and
  `"smooth_quantile"`. The response curve stays nonparametric either
  way; this argument concerns only the nuisance structure. See
  [`agri_np_block_effects`](https://wep69.github.io/agriRank/reference/agri_np_block_effects.md)
  for the comparison and
  [`agri_np_conformal`](https://wep69.github.io/agriRank/reference/agri_np_conformal.md)
  with `scope = "new_block"` for the assumption-free route to the same
  prediction.

- spatial:

  Nuisance structure for the position of the plot in the field. `"none"`
  is the default. `"smooth_xy"` adds a two-dimensional smooth of the
  coordinates, `s(row, col)`, which absorbs a continuous fertility
  gradient of any orientation. `"row_col"` adds additive row and column
  factors, which is cheaper and right when the layout is a lattice and
  the trend follows it.

  Blocking is a coarse instrument: it was invented for a field whose
  fertility varies in patches the size of a block, and it does nothing
  about a gradient that runs continuously across the trial, which is the
  common case. Available for the penalised additive engines, `gam`,
  `scam` and `smooth_quantile`; requested for another engine it is
  refused rather than silently dropped.

- coords:

  The two variables giving the position of each plot, for example
  `c("row", "col")`. Required whenever `spatial` is not `"none"`. They
  are nuisance terms, not predictors: prediction grids hold them at
  their reference value, so a reported curve refers to a plot of average
  position.

- weights:

  Optional observation weights. Unsupported weight-method combinations
  fail explicitly.

- na_action:

  Missing-data handling. `"fail"` (default) prevents silent row
  deletion; `"complete"` explicitly uses complete modeled rows and
  records how many were omitted.

- span:

  LOESS span.

- degree:

  LOESS or COBS polynomial degree where applicable.

- k:

  Basis dimension used in automatically generated GAM/SCAM smooths.

- gam_structure:

  Shape of the automatically generated GAM formula. `"additive"` fits
  one smooth per numeric predictor and adjusts additively for
  qualitative ones, which forces the curves of different levels to be
  parallel. `"tensor"` fits a tensor-product smooth over the first two
  numeric predictors, for a response surface. `"varying"` fits one
  smooth of the focal numeric predictor per level of a single
  qualitative predictor, so the shape of the response may differ between
  cultivars, seasons or sites and each level can have its own optimum.
  Use `"varying"` before comparing optima with
  [`agri_np_optimum_test`](https://wep69.github.io/agriRank/reference/agri_np_optimum_test.md),
  because parallel curves share one optimum by construction.

- kernel_regtype:

  Use local-linear (`"ll"`, default) or local-constant (`"lc"`) kernel
  regression with np.

- bwmethod:

  Bandwidth-selection method for np.

- predictor_support:

  Decision support for integer-valued predictors: observed tested
  integers, all integers in a range, or a custom set.

- integer_predictor:

  Optional name of the focal integer-valued predictor.

- integer_range:

  Two integer bounds when `predictor_support = "integer_range"`.

- integer_values:

  Explicit admissible integer values when
  `predictor_support = "custom_integer"`.

- integer_kernel:

  Ordered-discrete kernel used by `method = "discrete_kernel"`.

- integer_base_method:

  Latent flexible regression engine used by `method = "integer_grid"`.

- ...:

  Additional backend arguments.

## Details

Strictly nonparametric engines are `"loess"`, `"smoothing_spline"`,
`"kernel"`, `"isotonic"`, `"cobs"`, `"discrete_kernel"`, and
`"unimodal_isotonic"`. The `"umbrella"` pathway is a constrained
generalized additive/order-restricted model, while `"integer_grid"` fits
a selected flexible latent model but projects every public prediction
and decision onto an admissible integer support. Rank-robust or
semiparametric companions are `"theil_sen"`, `"siegel"`, `"quantile"`,
`"gam"`, `"scam"` and `"smooth_quantile"`.

`"smooth_quantile"` fits a calibrated additive quantile regression, a
smooth of a conditional quantile rather than of the mean. The agronomic
point is that a fertilizer, a cultivar or an irrigation schedule can
lift the good plots without lifting the poor ones: the mean rises either
way, and a recommendation built on it will disappoint exactly the
growers whose fields resemble the poor plots. The fit is defined by the
pinball loss, so nothing is assumed about the shape of the response
distribution, only about the smoothness of the curve. Use
[`agri_np_quantile_curves`](https://wep69.github.io/agriRank/reference/agri_np_quantile_curves.md)
for a set of quantiles at once.

For integer-valued agronomic inputs, agriRank does not round a
continuous optimum after fitting. It evaluates the fitted response
directly over a declared set \\\mathcal{X}\_I\\ of admissible integers
and defines the optimum as \\x^\* = \arg\max\_{x\in\mathcal{X}\_I} \hat
m(x)\\ (or the corresponding minimum). With
`predictor_support = "observed_integer"`, untested integer treatments
are not interpolated. `"integer_range"` explicitly permits interpolation
to every integer between the chosen bounds.

The `"auto"` rule uses the predictor structure, family and an explicitly
requested shape constraint. It does not inspect significance tests or
choose the model yielding the smallest p-value. Declared blocks are
retained as adjustment terms for kernel, quantile, GAM and SCAM
workflows; unsupported block-method combinations fail explicitly.
Regression objects created from an `agri_design` inherit its block and
quantitative-treatment declaration. Repeated/longitudinal design objects
are currently rejected because subject dependence requires a validated
subject-aware regression adapter. Missing values in the modeled
response, predictors, block, or weights stop the fit by default.
Complete-row regression is available only through explicit
`na_action = "complete"`; it is not an imputation procedure or a
substitute for a missing-data model.

Qualitative predictors such as cultivar, soil class or management system
are handled explicitly. A character column is read as the factor it is,
and a factor needs at least two levels to enter a model, because a
single level carries no contrast against the response. Engines
`"quantile"`, `"kernel"`, `"gam"` and `"scam"` keep qualitative factors
as adjustment terms; curve-only engines (`"theil_sen"`, `"siegel"`,
`"smoothing_spline"`, `"cobs"`, `"isotonic"`, `"unimodal_isotonic"` and
`"loess"`) refuse them by name instead of silently dropping them. For
engines with interpretable coefficients, each non-reference level of a
factor enters as one coefficient, whose bootstrap interval can be
displayed with
[`agri_np_forest`](https://wep69.github.io/agriRank/reference/agri_np_forest.md).

## Value

An object of class `agri_np_reg_fit` containing the selected method,
backend fit, training data, the numeric and qualitative predictor sets,
fitted values, residuals and predictive-error summaries.

## References

Hayfield, T. and Racine, J. S. (2008). Nonparametric Econometrics: The
np Package. *Journal of Statistical Software*, 27(5).
doi:10.18637/jss.v027.i05.

Pya, N. and Wood, S. N. (2015). Shape constrained additive models.
*Statistics and Computing*, 25, 543-559. doi:10.1007/s11222-013-9448-7.

Sen, P. K. (1968). Estimates of the Regression Coefficient Based on
Kendall's Tau. *Journal of the American Statistical Association*, 63,
1379-1389. doi:10.1080/01621459.1968.10480934.

Racine, J. and Li, Q. (2004). Nonparametric estimation of regression
functions with both categorical and continuous data. *Journal of
Econometrics*, 119, 99-130. doi:10.1016/S0304-4076(03)00157-X.

Turner, T. R. and Wollan, P. C. (1997). Locating a maximum using
isotonic regression. *Computational Statistics & Data Analysis*, 25,
305-320. doi:10.1016/S0167-9473(97)00009-1.

Liao, X. and Meyer, M. C. (2019). cgam: An R Package for the Constrained
Generalized Additive Model. *Journal of Statistical Software*, 89(5).
doi:10.18637/jss.v089.i05.

## See also

[`agri_np_predict`](https://wep69.github.io/agriRank/reference/agri_np_predict.md),
[`agri_integer_predict`](https://wep69.github.io/agriRank/reference/agri_integer_predict.md),
[`agri_integer_optimum`](https://wep69.github.io/agriRank/reference/agri_integer_optimum.md),
[`agri_integer_difference`](https://wep69.github.io/agriRank/reference/agri_integer_difference.md),
[`agri_integer_bootstrap`](https://wep69.github.io/agriRank/reference/agri_integer_bootstrap.md),
[`agri_np_compare`](https://wep69.github.io/agriRank/reference/agri_np_compare.md),
[`agri_np_plot`](https://wep69.github.io/agriRank/reference/agri_np_plot.md)

## Examples

``` r
# All examples use the exported data sets, so the fitted objects stay in the
# session and can be explored further. Yield is in Mg/ha, nitrogen in kg/ha and
# plant density in plants per hill.

# Example 1: smoothing spline over a nitrogen gradient
data(agri_dose)
fit1 <- agri_np_regression(yield ~ dose, agri_dose, method = "smoothing_spline")
fit1
#> agriRank nonparametric regression
#>   Method: smoothing_spline
#>   Response: yield
#>   Predictors: dose
# The response flattens beyond roughly 200 kg/ha: no parametric quadratic
# reproduces both the rising part and the plateau.

# Example 2: LOESS on the same gradient, for comparison of smoothers
fit2 <- agri_np_regression(yield ~ dose, agri_dose, method = "loess", span = 0.6)
summary(fit2)
#> agriRank nonparametric regression summary
#> Method: loess
#> 
#>   n     RMSE       MAE    MedAE         bias  Spearman
#>  40 0.352558 0.3036027 0.307143 -0.008741923 0.8724666
#> 
#> Backend summary:
#> Call:
#> stats::loess(formula = formula, data = dat, weights = weights, 
#>     span = span, degree = degree)
#> 
#> Number of Observations: 40 
#> Equivalent Number of Parameters: 6.48 
#> Residual Standard Error: 0.3931 
#> Trace of smoother matrix: 7.15  (exact)
#> 
#> Control settings:
#>   span     :  0.6 
#>   degree   :  2 
#>   family   :  gaussian
#>   surface  :  interpolate      cell = 0.2
#>   normalize:  TRUE
#>  parametric:  FALSE
#> drop.square:  FALSE 

# Example 3: block-adjusted GAM, the design-aware choice for this trial
if (requireNamespace("mgcv", quietly = TRUE)) {
  fit3 <- agri_np_regression(yield ~ dose, agri_dose, method = "gam", block = block)
  summary(fit3)
  # Adjusting for block removes soil-fertility variation from the residual.
}
#> agriRank nonparametric regression summary
#> Method: gam
#> 
#>   n      RMSE       MAE     MedAE         bias  Spearman
#>  40 0.1849693 0.1451067 0.1100682 6.439268e-16 0.9534218
#> 
#> Backend summary:
#> 
#> Family: gaussian 
#> Link function: identity 
#> 
#> Formula:
#> yield ~ s(dose, k = 7) + block
#> 
#> Parametric coefficients:
#>             Estimate Std. Error t value Pr(>|t|)    
#> (Intercept)  4.22575    0.07412  57.010  < 2e-16 ***
#> blockB2      0.04150    0.10483   0.396   0.6949    
#> blockB3      0.34637    0.10483   3.304   0.0024 ** 
#> blockB4      0.68200    0.10483   6.506 2.87e-07 ***
#> blockB5      0.71650    0.10483   6.835 1.14e-07 ***
#> ---
#> Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1
#> 
#> Approximate significance of smooth terms:
#>           edf Ref.df     F p-value    
#> s(dose) 3.864  4.634 122.1  <2e-16 ***
#> ---
#> Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1
#> 
#> R-sq.(adj) =  0.943   Deviance explained = 95.5%
#> -REML = 5.6206  Scale est. = 0.043954  n = 40

# Example 4: direct transition from a declared quantitative RCBD
if (requireNamespace("mgcv", quietly = TRUE)) {
  des <- agri_design(yield ~ dose, agri_dose, design = "rcbd",
                     block = block, quantitative = dose)
  fit4 <- agri_np_regression(des, method = "gam")
  fit4
  # The block declared in the design is carried into the regression.
}
#> agriRank nonparametric regression
#>   Method: gam
#>   Response: yield
#>   Predictors: dose
#>   Block adjustment: block

# Example 5: ordered-discrete kernel regression on an integer treatment
data(agri_density)
if (requireNamespace("np", quietly = TRUE)) {
  fit5 <- agri_np_regression(yield ~ plants, agri_density,
                             method = "discrete_kernel",
                             predictor_support = "observed_integer")
  agri_integer_predict(fit5)
}
#>   plants      fit
#> 1      1 3.350963
#> 2      2 4.285799
#> 3      3 4.794360
#> 4      4 5.323503
#> 5      5 5.599586
#> 6      6 5.675249
#> 7      7 5.400202
#> 8      8 5.067453
#> 9      9 5.057671

# Example 6: unimodal isotonic plant-density response
if (requireNamespace("Iso", quietly = TRUE)) {
  fit6 <- agri_np_regression(yield ~ plants, agri_density,
                             method = "unimodal_isotonic",
                             predictor_support = "observed_integer")
  agri_integer_optimum(fit6)
  # Density responses rise and then fall through competition, so an
  # increase-then-decrease constraint is scientifically justified here.
}
#> agriRank integer-support optimum
#>   Objective: max
#>   Admissible support: {1, 2, 3, 4, 5, 6, 7, 8, 9}
#>   Optimal integer value(s): 6
#>   Fitted response: 5.72267

# Example 7: continuous latent spline, integer-only decisions
fit7 <- agri_np_regression(yield ~ plants, agri_density, method = "integer_grid",
                           integer_base_method = "smoothing_spline",
                           predictor_support = "observed_integer")
agri_integer_difference(fit7, order = 1)
#>   from to delta_x fit_from   fit_to  difference difference_per_integer
#> 1    1  2       1 3.303982 4.201545  0.89756344             0.89756344
#> 2    2  3       1 4.201545 4.858834  0.65728887             0.65728887
#> 3    3  4       1 4.858834 5.348576  0.48974195             0.48974195
#> 4    4  5       1 5.348576 5.633219  0.28464302             0.28464302
#> 5    5  6       1 5.633219 5.653211  0.01999178             0.01999178
#> 6    6  7       1 5.653211 5.409864 -0.24334647            -0.24334647
#> 7    7  8       1 5.409864 5.130370 -0.27949453            -0.27949453
#> 8    8  9       1 5.130370 5.004565 -0.12580537            -0.12580537
# Each row is the yield gain, in Mg/ha, of adding one more plant per hill.

# Example 8: umbrella-order regression with an RCBD block adjustment
if (requireNamespace("cgam", quietly = TRUE)) {
  fit8 <- agri_np_regression(yield ~ plants, agri_density, method = "umbrella",
                             block = block, predictor_support = "observed_integer")
  agri_integer_optimum(fit8)
}
#> agriRank integer-support optimum
#>   Objective: max
#>   Admissible support: {1, 2, 3, 4, 5, 6, 7, 8, 9}
#>   Optimal integer value(s): 5, 6
#>   Fitted response: 5.32609

# Example 9: two interacting gradients
data(agri_surface)
if (requireNamespace("mgcv", quietly = TRUE)) {
  fit9 <- agri_np_regression(yield ~ nitrogen + water, agri_surface,
                             method = "gam", gam_structure = "tensor")
  agri_np_predict(fit9, newdata = data.frame(nitrogen = 160, water = c(0.6, 1.0)))
  # The return to 160 kg/ha of nitrogen depends on irrigation depth.
}
#> [1] 5.360970 5.764386

# Example 10: a qualitative factor alongside the nitrogen gradient
if (requireNamespace("quantreg", quietly = TRUE)) {
  dzc <- agri_dose
  dzc$cultivar <- factor(rep(c("Ana", "Bela"), length.out = nrow(dzc)))
  dzc$yield <- dzc$yield + ifelse(dzc$cultivar == "Bela", 0.9, 0)
  fit10 <- agri_np_regression(yield ~ dose + cultivar, dzc, method = "quantile")
  coef(fit10)
  # Cultivar Bela adds about 0.9 Mg/ha at every nitrogen rate; the dose slope
  # is shared by both cultivars. Plot the intervals with agri_np_forest().
}
#> Warning: Solution may be nonunique
#>  (Intercept)         dose cultivarBela 
#>   3.30700000   0.00785625   1.05575000 
```
