# Test a prespecified Gaussian regression against a nonparametric alternative

Uses [`np::npcmstest()`](https://rdrr.io/pkg/np/man/np.cmstest.html) to
assess whether a prespecified linear or polynomial Gaussian regression
is too restrictive relative to a mixed-data nonparametric
conditional-mean model.

## Usage

``` r
agri_np_specification(
  model,
  data = NULL,
  B = 399L,
  distribution = c("bootstrap", "asymptotic"),
  boot_method = c("wild-rademacher", "wild", "iid"),
  pivot = TRUE,
  density_weighted = TRUE,
  seed = 42L,
  ...
)
```

## Arguments

- model:

  An `lm` or Gaussian `glm` fitted with `x = TRUE, y = TRUE`.

- data:

  Optional original model data. If omitted, the model frame is used when
  possible.

- B:

  Number of bootstrap replications.

- distribution:

  Bootstrap or asymptotic reference distribution.

- boot_method:

  Bootstrap method accepted by
  [`np::npcmstest()`](https://rdrr.io/pkg/np/man/np.cmstest.html).

- pivot:

  Use the pivotal statistic.

- density_weighted:

  Weight the statistic by the predictor density.

- seed:

  Reproducible bootstrap seed.

- ...:

  Additional kernel and bandwidth arguments passed to
  [`np::npcmstest()`](https://rdrr.io/pkg/np/man/np.cmstest.html).

## Details

The test is a specification diagnostic. A small p-value is evidence that
the candidate parametric functional form is inadequate; it does not
establish that any particular smoother is uniquely correct. The adapter
is intentionally restricted to continuous Gaussian outcomes because the
backend relies on residual bootstrapping.

Use the exact data used to fit the candidate model after missing-data
handling. When the original predictors cannot be reconstructed, the
function falls back to stored model-matrix columns and warns because
mixed-data classes may be lost.

## Value

An np `cmstest` object with an additional agriRank interpretation
attribute.

## References

Hsiao C, Li Q, Racine JS (2007). A consistent model specification test
with mixed discrete and continuous data. *Journal of Econometrics*,
140(2), 802–826. doi:10.1016/j.jeconom.2006.07.015.

Hayfield T, Racine JS (2008). Nonparametric Econometrics: The np
Package. *Journal of Statistical Software*, 27(5).
doi:10.18637/jss.v027.i05.

## See also

[`agri_np_regression`](https://wep69.github.io/agriRank/reference/agri_np_regression.md),
[`agri_np_significance`](https://wep69.github.io/agriRank/reference/agri_np_significance.md),
[`agri_np_diagnostics`](https://wep69.github.io/agriRank/reference/agri_np_diagnostics.md)

## Examples

``` r
# The candidate model must be fitted with x = TRUE, y = TRUE so that the
# adapter can recover the design matrix and the response.
# B = 19 keeps the examples fast. Use B >= 999 for any reported test.
data(agri_dose)

# Example 1: is a straight line enough for a fertilizer response?
if (requireNamespace("np", quietly = TRUE)) {
  m1 <- lm(yield ~ dose, data = agri_dose, x = TRUE, y = TRUE)
  agri_np_specification(m1, B = 19)
  # A small p-value means the linear form is too restrictive: the data hold
  # curvature that the straight line cannot represent.
}
#> 
#> Consistent Model Specification Test
#> Parametric null model: lm(formula = yield ~ dose, data = agri_dose, x = TRUE, y
#>                           = TRUE)
#> Number of regressors: 1
#> Rademacher Wild Bootstrap (19 replications)
#> 
#> Test Statistic 'Jn': 2.937034    P Value: < 2.22e-16 ***
#> ---
#> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
#> Null of correct specification is rejected at the 0.1% level
#> 

# Example 2: and is the quadratic enough?
if (requireNamespace("np", quietly = TRUE)) {
  m2 <- lm(yield ~ dose + I(dose^2), data = agri_dose, x = TRUE, y = TRUE)
  agri_np_specification(m2, B = 19)
  # These data plateau beyond 200 kg/ha, a shape no single quadratic
  # reproduces, so rejection here is agronomically meaningful.
}
#> 
#> Consistent Model Specification Test
#> Parametric null model: lm(formula = yield ~ dose + I(dose^2), data = agri_dose,
#>                           x = TRUE, y = TRUE)
#> Number of regressors: 1
#> Rademacher Wild Bootstrap (19 replications)
#> 
#> Test Statistic 'Jn': -1.502519   P Value: 0.84211  
#> ---
#> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
#> Fail to reject the null of correct specification at the 10% level
#> 

# Example 3: with the agronomic block kept as a nuisance term
if (requireNamespace("np", quietly = TRUE)) {
  mb <- lm(yield ~ block + dose + I(dose^2), data = agri_dose, x = TRUE, y = TRUE)
  agri_np_specification(mb, B = 19)
  # Failing to reject is not proof that the parametric form is correct; it
  # only means this sample gives no evidence against it.
}
#> 
#> Consistent Model Specification Test
#> Parametric null model: lm(formula = yield ~ block + dose + I(dose^2), data =
#>                           agri_dose, x = TRUE, y = TRUE)
#> Number of regressors: 2
#> Rademacher Wild Bootstrap (19 replications)
#> 
#> Test Statistic 'Jn': -1.576065   P Value: 0.57895  
#> ---
#> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
#> Fail to reject the null of correct specification at the 10% level
#> 
```
