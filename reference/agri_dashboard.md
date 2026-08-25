# Generate a self-contained Quarto dashboard source

Creates an English Quarto dashboard source for an experimental-design
analysis or agronomic nonparametric regression fit. The generated source
uses embedded-resource HTML settings for portable communication.

## Usage

``` r
agri_dashboard(
  x,
  file = tempfile("agriRank-dashboard-", fileext = ".qmd"),
  language = "en"
)
```

## Arguments

- x:

  An `agri_rank_fit` or `agri_np_reg_fit` object.

- file:

  Output QMD path.

- language:

  Report language. Regression dashboard content is currently generated
  in English.

## Details

The function creates the QMD source and does not require Quarto merely
to write it. Rendering is deliberately separated from statistical
fitting. Regression dashboards retain method, predictors, fitted
formula, shape constraint, block adjustment and predictive diagnostics.

## Value

The normalized path of the QMD source.

## See also

[`agri_report`](https://wep69.github.io/agriRank/reference/agri_report.md),
[`agri_np_regression`](https://wep69.github.io/agriRank/reference/agri_np_regression.md),
[`agri_np_plot`](https://wep69.github.io/agriRank/reference/agri_np_plot.md)

## Examples

``` r
# Example 1: CRD dashboard source
f <- np_crd(yield ~ treatment, simulate_agri("crd"))
agri_dashboard(f, tempfile(fileext = ".qmd"))
#> [1] "/tmp/RtmpSbmQ6v/file1b9745c93028.qmd"

# Example 2: smoothing-spline regression dashboard
set.seed(83)
d <- data.frame(dose = seq(0, 180, length.out = 35))
d$yield <- 6 + .06*d$dose - .0002*d$dose^2 + rnorm(35, 0, .4)
r <- agri_np_regression(yield ~ dose, d, method = "smoothing_spline")
agri_dashboard(r, tempfile(fileext = ".qmd"))
#> [1] "/tmp/RtmpSbmQ6v/file1b971f1964bb.qmd"

# Example 3: incomplete repeated-measures analysis
x <- simulate_agri("repeated_missing")
des <- agri_design(height ~ treatment*time, x, "repeated", subject = subject, within = time)
fr <- agri_rank(des, "incomplete_wild", B = 99, missing_assumption = "MCAR")
#> Warning: B < 199 gives coarse Monte Carlo p-values; use >= 999 for analysis and >= 4999 for final work when feasible.
agri_dashboard(fr, tempfile(fileext = ".qmd"))
#> [1] "/tmp/RtmpSbmQ6v/file1b9738df25d5.qmd"
```
