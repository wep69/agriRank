# Predict on an admissible integer decision support

Evaluates a fitted regression only at admissible integer values.
Fractional values and integers outside the declared support are
rejected.

## Usage

``` r
agri_integer_predict(object, support = NULL, fixed = list(),
  interval = c("none", "confidence"), level = 0.95)
```

## Arguments

- object:

  An integer-support `agri_np_reg_fit`.

- support:

  Optional subset of the fitted integer support.

- fixed:

  Named values for other covariates.

- interval:

  Prediction output; model-based confidence intervals are returned only
  by supported backends.

- level:

  Confidence level.

## Details

The function operationalizes the decision lattice \\\mathcal{X}\_I\\. It
never rounds a continuous prediction request to the nearest integer.

## Value

A data frame containing the integer predictor and fitted response, with
confidence limits when available.

## Examples

``` r
data(agri_density)

# Example 1: predicted yield, in Mg/ha, at every admissible plant density
f1 <- agri_np_regression(yield ~ plants, agri_density, method = "integer_grid",
                         integer_base_method = "smoothing_spline",
                         predictor_support = "observed_integer")
agri_integer_predict(f1)
# One row per decision the grower can actually take. No fractional plant
# appears, because half a plant cannot be sown.

# Example 2: restricted to the densities under discussion
agri_integer_predict(f1, support = 4:7)

# Example 3: a support extended beyond what was tested. Extrapolating to 10
# plants per hill must be justified agronomically, never by convenience.
f2 <- agri_np_regression(yield ~ plants, agri_density, method = "integer_grid",
                         integer_base_method = "smoothing_spline",
                         predictor_support = "integer_range",
                         integer_range = c(1, 12))
agri_integer_predict(f2, support = 10:12)
```
