# Interactive Plotly graphics for agronomic nonparametric regression

Converts an editable ggplot2 regression graphic to an interactive Plotly
object for exploratory inspection and HTML reporting.

## Usage

``` r
agri_np_interactive(object, type = c("fit", "residuals", 
    "derivative", "surface"), ...)
```

## Arguments

- object:

  An `agri_np_reg_fit`.

- type:

  Fit, residual, derivative, or response-surface plot.

- ...:

  Arguments passed to
  [`agri_np_plot()`](https://wep69.github.io/agriRank/reference/agri_np_plot.md),
  including `predictor`, `fixed`, `group`, and `surface_predictors`.

## Details

The interactive layer does not refit the model, change the estimand, or
alter inferential results. Static ggplot2 figures remain the primary
publication graphics.

## Value

A Plotly htmlwidget.

## See also

[`agri_np_plot`](https://wep69.github.io/agriRank/reference/agri_np_plot.md),
[`agri_np_regression`](https://wep69.github.io/agriRank/reference/agri_np_regression.md)

## Examples

``` r
# The examples build the widget and report its class. They deliberately do not
# print it: rendering an htmlwidget outside an interactive session can launch a
# headless browser, which is unavailable in many check and documentation
# environments. Print the object in an interactive session to see the graphic.
data(agri_dose)
f <- agri_np_regression(yield ~ dose, agri_dose, method = "smoothing_spline")

# Example 1: interactive fitted response
if (requireNamespace("plotly", quietly = TRUE)) {
  w1 <- agri_np_interactive(f)
  class(w1)
}
#> [1] "plotly"     "htmlwidget"

# Example 2: interactive derivative
if (requireNamespace("plotly", quietly = TRUE)) {
  w2 <- agri_np_interactive(f, type = "derivative")
  class(w2)
}
#> [1] "plotly"     "htmlwidget"

# Example 3: interactive response surface over two gradients
data(agri_surface)
if (requireNamespace("plotly", quietly = TRUE) && requireNamespace("mgcv", quietly = TRUE)) {
  fs <- agri_np_regression(yield ~ nitrogen + water, agri_surface,
                           method = "gam", gam_structure = "tensor")
  w3 <- agri_np_interactive(fs, type = "surface",
                            surface_predictors = c("nitrogen", "water"), n = 30)
  class(w3)
}
#> [1] "plotly"     "htmlwidget"
```
