# Format a coefficient and its confidence interval for manuscript text

Returns a plain-text string of the form `"1.06 (0.68; 1.47)"` that can
be copied directly into a manuscript sentence, avoiding manual
formatting of every reported coefficient and its interval.

## Usage

``` r
agri_format_ci(estimate, lower, upper, digits = 2, sep = "; ")
```

## Arguments

- estimate:

  Numeric estimate.

- lower:

  Lower bound of the interval.

- upper:

  Upper bound of the interval.

- digits:

  Significant digits for the estimate and bounds.

- sep:

  Separator between lower and upper.

## Value

A character string.

## See also

[`confint.agri_np_reg_fit`](https://wep69.github.io/agriRank/reference/agri_np_extractors.md),
[`agri_np_forest`](https://wep69.github.io/agriRank/reference/agri_np_forest.md),
[`agri_table`](https://wep69.github.io/agriRank/reference/agri_table.md)

## Examples

``` r
# Pronto para colar no manuscrito: estimativa e intervalo em uma string.
agri_format_ci(1.056, 0.678, 1.465)

# Mais digitos para coeficientes pequenos, como a inclinacao de uma dose
# em Mg/ha por kg/ha.
agri_format_ci(0.0076875, 0.0053125, 0.0086167, digits = 3)

# O mesmo texto que a floresta de coeficientes mostra graficamente.
if (requireNamespace("quantreg", quietly = TRUE)) {
  data(agri_dose)
  dz <- agri_dose
  dz$cultivar <- factor(rep(c("Ana", "Bela"), length.out = nrow(dz)))
  dz$yield <- dz$yield + ifelse(dz$cultivar == "Bela", 0.9, 0)
  fit <- agri_np_regression(yield ~ dose + cultivar, dz, method = "quantile")
  # B = 19 mantem o exemplo rapido; analise final usa B >= 999.
  ci <- confint(fit, method = "bootstrap", B = 19, seed = 1)
  apply(ci, 1, function(r) agri_format_ci(r["estimate"], r["lower"], r["upper"]))
}
```
