# Create standardized agriRank analysis tables

Batch, inferential-sensitivity, and missing-data characterization
objects are also supported by the common table/report/export layer.
Creates publication-oriented tables from experimental-design,
regression, multivariate, ANCOVA, ordered-trend, or simulation-power
results. When gt is installed, the returned data are upgraded to a
`gt_tbl`.

## Usage

``` r
agri_table(
  x,
  what = c("omnibus", "effects", "pairs", "missing", "metrics",
    "coefficients", "levels", "predictions", "derivative", "optimum",
    "integer_predictions", "integer_optimum", "integer_efficiency"),
  ...,
  format = c("auto", "data.frame", "gt", "rtf")
)
```

## Arguments

- x:

  An agriRank result object, including `agri_rank_fit`,
  `agri_np_reg_fit`, `agri_multivariate_fit`, `agri_ancova_fit`,
  `agri_trend`, `agri_power`, `agri_batch`, `agri_sensitivity`, or
  `agri_missing_report`.

- what:

  For experimental-design fits: `"omnibus"`, `"effects"`, `"pairs"`, or
  `"missing"`. For regression fits: `"metrics"`, `"coefficients"`,
  `"levels"`, `"predictions"`, `"derivative"`, `"optimum"`,
  `"integer_predictions"`, `"integer_optimum"`, or
  `"integer_efficiency"`. If omitted for a regression fit, `"metrics"`
  is used.

- ...:

  Additional arguments passed to the selected component, such as the
  focal predictor for derivative or optimum calculations, or `method`,
  `B`, `seed`, `cluster` and `fixed` for the coefficient and level
  tables.

- format:

  `"data.frame"` returns a plain editable data frame, the form a
  manuscript table needs; `"gt"` upgrades to a `gt_tbl` when the package
  is installed; `"rtf"` writes an RTF file via
  [`gt::gtsave()`](https://gt.rstudio.com/reference/gtsave.html) for
  direct import into Word or LibreOffice; `"auto"` uses gt when
  available.

## Details

Tables never change the fitted statistical model. Regression prediction
tables contain observed, fitted and residual values at the training
observations. The `"coefficients"` table reports each coefficient with
its confidence interval via
[`confint.agri_np_reg_fit`](https://wep69.github.io/agriRank/reference/agri_np_extractors.md),
because an estimate without uncertainty invites an exactness the model
does not have. The `"levels"` table, computed by
[`agri_np_levels`](https://wep69.github.io/agriRank/reference/agri_np_levels.md),
describes the response at each level of the qualitative predictors: the
observed location and spread beside the fitted marginal response with a
pointwise bootstrap interval. Derivative and optimum tables are derived
from the fitted regression surface and inherit the interpretive limits
documented in
[`agri_np_derivative()`](https://wep69.github.io/agriRank/reference/agri_np_derivative.md)
and
[`agri_np_optimum()`](https://wep69.github.io/agriRank/reference/agri_np_optimum.md).
Integer-support tables evaluate only the declared admissible support;
they never obtain an operational optimum by rounding a continuous
optimum.

## Value

A data frame or, when gt is available, a `gt_tbl`.

## References

Konietschke F, Brunner E (2023). rankFD: An R Software Package for
Nonparametric Analysis of General Factorial Designs. *The R Journal*,
15, 142–158. doi:10.32614/RJ-2023-029.

Hayfield T, Racine JS (2008). Nonparametric Econometrics: The np
Package. *Journal of Statistical Software*, 27(5).
doi:10.18637/jss.v027.i05.

## See also

[`agri_report`](https://wep69.github.io/agriRank/reference/agri_report.md),
[`agri_np_regression`](https://wep69.github.io/agriRank/reference/agri_np_regression.md),
[`agri_np_levels`](https://wep69.github.io/agriRank/reference/agri_np_levels.md),
[`confint.agri_np_reg_fit`](https://wep69.github.io/agriRank/reference/agri_np_extractors.md),
[`agri_np_derivative`](https://wep69.github.io/agriRank/reference/agri_np_derivative.md),
[`agri_np_optimum`](https://wep69.github.io/agriRank/reference/agri_np_optimum.md),
[`agri_integer_optimum`](https://wep69.github.io/agriRank/reference/agri_integer_optimum.md)

## Examples

``` r
# Example 1: omnibus table from a CRD
f1 <- np_crd(yield ~ treatment, simulate_agri("crd"))
agri_table(f1, "omnibus")


  

effect
```
