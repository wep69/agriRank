# Export an agriRank analysis bundle

Batch, inferential-sensitivity, and missing-data characterization
objects are also supported by the common table/report/export layer.
Stores the scientifically relevant components of supported agriRank
analysis results in an RDS bundle for reproducibility and downstream
archiving.

## Usage

``` r
export_results(x, file = "agriRank-results.rds")
```

## Arguments

- x:

  An agriRank result object, including `agri_rank_fit`,
  `agri_np_reg_fit`, `agri_multivariate_fit`, `agri_ancova_fit`,
  `agri_trend`, `agri_power`, `agri_batch`, `agri_sensitivity`, or
  `agri_missing_report`.

- file:

  Output RDS path.

## Details

Experimental-design bundles include the declared design, omnibus
inference, effect information when available, missingness, method, seed
and session metadata. Regression bundles include the original and fitted
formulas, response, predictors, block adjustment, method, shape
constraint, quantile, predictive metrics, fitted values, residuals,
backend class and session metadata. Integer-support bundles also record
the support mode, focal integer predictor, admissible values, observed
integer values, and latent/base engine when applicable.

## Value

The normalized path of the RDS file.

## See also

[`agri_report`](https://wep69.github.io/agriRank/reference/agri_report.md),
[`agri_dashboard`](https://wep69.github.io/agriRank/reference/agri_dashboard.md),
[`agri_np_regression`](https://wep69.github.io/agriRank/reference/agri_np_regression.md)

## Examples

``` r
# Example 1: export a CRD analysis
f <- np_crd(yield ~ treatment, simulate_agri("crd"))
export_results(f, tempfile(fileext = ".rds"))

# Example 2: inspect a regression bundle
set.seed(84)
d <- data.frame(x = seq(0, 10, length.out = 30))
d$y <- sin(d$x/2) + rnorm(30, 0, .15)
r <- agri_np_regression(y ~ x, d, method = "loess")
z <- tempfile(fileext = ".rds")
export_results(r, z)
names(readRDS(z))

# Example 3: export a repeated incomplete fit
x <- simulate_agri("repeated_missing")
des <- agri_design(height ~ treatment*time, x, "repeated", subject = subject, within = time)
fr <- agri_rank(des, "incomplete_wild", B = 99, missing_assumption = "MCAR")
export_results(fr, tempfile(fileext = ".rds"))
```
