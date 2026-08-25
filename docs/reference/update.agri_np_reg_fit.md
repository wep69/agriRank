# Refit a nonparametric regression changing only what is named

Refits the model with the arguments given in `...` replacing the ones
used originally, leaving everything else as it was.

## Usage

``` r
# S3 method for class 'agri_np_reg_fit'
update(object, formula = NULL, ...)
```

## Arguments

- object:

  An `agri_np_reg_fit`.

- formula:

  Optional replacement formula.

- ...:

  Arguments of
  [`agri_np_regression`](https://wep69.github.io/agriRank/reference/agri_np_regression.md)
  to change, for example `method`, `shape`, `k`, `span`, `block_effect`
  or `gam_structure`. An argument that is not a formal of
  `agri_np_regression` is refused by name rather than silently ignored.

## Details

Comparing two engines or trying a shape constraint otherwise means
retyping the whole call, which is where a predictor or a block quietly
goes missing between the two versions being compared.

The refit uses the data stored in the fit, that is, the data after the
declared `na_action` was applied. This is deliberate: it guarantees that
the two models are fitted to the same rows, which is the point of
comparing them. If the original data frame has since changed, refit from
it explicitly rather than through this method.

All the guards of
[`agri_np_regression`](https://wep69.github.io/agriRank/reference/agri_np_regression.md)
still apply. Asking for an engine that cannot adjust for a declared
block fails here exactly as it would in a fresh call.

## Value

A new `agri_np_reg_fit`.

## See also

[`agri_np_regression`](https://wep69.github.io/agriRank/reference/agri_np_regression.md),
[`agri_np_compare`](https://wep69.github.io/agriRank/reference/agri_np_compare.md)
for comparing engines by predictive error.

## Examples

``` r
data(agri_dose)
f1 <- agri_np_regression(yield ~ dose, agri_dose, method = "smoothing_spline")

# Example 1: change the engine, keep everything else
f2 <- update(f1, method = "loess")
c(f1$method, f2$method)
#> [1] "smoothing_spline" "loess"           

# Example 2: change the smoothing parameter only
f3 <- update(f1, method = "gam", k = 8)
f3$settings$k
#> [1] 8

# Example 3: impose a shape the agronomy guarantees, and compare
if (requireNamespace("scam", quietly = TRUE)) {
  f4 <- update(f1, method = "scam", shape = "increasing_concave")
  c(free = f1$metrics$RMSE, constrained = f4$metrics$RMSE)
  # The constrained fit cannot beat the free one on RMSE. It buys precision
  # where the constraint is true, not a better fit to these data.
}
#>        free constrained 
#>   0.3623191   0.3619582 

# Example 4: an argument that does not exist is named rather than ignored
try(update(f1, smoothing = 3))
#> Error : Not an argument of agri_np_regression(): smoothing.
```
