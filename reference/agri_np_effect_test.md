# Does a predictor earn its place in the model

Tests whether dropping a predictor changes the fitted response more than
resampling alone would, by a cluster wild bootstrap under the null.
Valid for every engine in
[`agri_np_regression`](https://wep69.github.io/agriRank/reference/agri_np_regression.md),
because it looks only at fitted values and residuals rather than inside
the engine.

## Usage

``` r
agri_np_effect_test(object, terms = NULL, B = 999L, seed = 1,
                    cluster = NULL,
                    adjust = c("holm", "none", "BH", "bonferroni",
                               "hochberg", "hommel", "BY"),
                    parallel = FALSE)
```

## Arguments

- object:

  An `agri_np_reg_fit`.

- terms:

  The predictor or predictors to test, as names or strings. Each is
  tested on its own. Defaults to every predictor of the model.

- B:

  Bootstrap replicates. Use at least 999 for anything reported.

- seed:

  Random seed.

- cluster:

  Resampling unit. Defaults to the declared block, which is what makes
  the test respect the randomization. Pass `NA` to sign each row
  independently, which is legitimate only for a completely randomized
  layout.

- adjust:

  Multiplicity adjustment across the terms tested.

- parallel:

  Distribute the replicates over a `future` plan.

## Details

Until 0.14.0 the only significance test in the regression module was
[`agri_np_significance`](https://wep69.github.io/agriRank/reference/agri_np_significance.md),
which works for two of the sixteen engines and resamples rows, ignoring
the declared randomization, while every interval in the module resampled
whole blocks. A p-value and an interval from the same fit therefore
rested on different assumptions. This function removes that asymmetry.

The statistic is the mean squared distance between the fitted values of
the full model and those of the model without the term, scaled by the
residual spread so that it does not depend on the units of the response.
Its null distribution is obtained by refitting on replicate responses
built from the reduced fit plus its residuals multiplied by random
signs.

**The signs are drawn once per block, not once per plot.** Signing plots
independently would treat the plots of a block as independent, which is
the error the rest of this package exists to prevent. Signing whole
blocks leaves the within-block dependence intact whatever its form.

**With \\G\\ blocks there are only \\2^G\\ distinct sign vectors**, so
the test has at most that many distinct outcomes however large `B` is.
With five blocks that is 32 and no p-value below about 0.03 can be
produced. This is a limit of the design rather than of the resampling:
more blocks is the remedy, more replicates is not, and the printed
output says so when it applies.

A term whose removal makes the model unfittable is reported with an `NA`
p-value and a note rather than silently dropped.

## Value

An object of class `agri_np_effect_test`.

## See also

[`agri_np_shape_test`](https://wep69.github.io/agriRank/reference/agri_np_shape_test.md)
for the shape rather than the term,
[`agri_np_optimum_test`](https://wep69.github.io/agriRank/reference/agri_np_optimum_test.md)
for the location of the optimum,
[`agri_np_significance`](https://wep69.github.io/agriRank/reference/agri_np_significance.md)
for the kernel-specific alternative.

## References

Cameron, A. C., Gelbach, J. B. and Miller, D. L. (2008). Bootstrap-based
improvements for inference with clustered errors. *The Review of
Economics and Statistics*, 90(3), 414-427.

Haerdle, W. and Mammen, E. (1993). Comparing nonparametric versus
parametric regression fits. *The Annals of Statistics*, 21(4),
1926-1947.

## Examples

``` r
if (requireNamespace("mgcv", quietly = TRUE)) {
  set.seed(21)
  d <- expand.grid(N = seq(0, 200, by = 50), block = factor(1:5), rep = 1:2)
  d$noise <- rnorm(nrow(d))
  d$yield <- 3 + 0.030 * d$N - 0.00009 * d$N^2 +
    as.numeric(d$block) * 0.3 + rnorm(nrow(d), 0, 0.3)
  fit <- agri_np_regression(yield ~ N + noise, d, method = "gam",
                            block = block, k = 5)

  # Example 1: both predictors tested, signs drawn once per block.
  # B is small here for speed; use at least 999 for anything reported.
  agri_np_effect_test(fit, B = 49, seed = 1)
  # The statistic separates the two by three orders of magnitude even where the
  # p-values cannot, because five blocks allow only 32 sign patterns.

  # Example 2: one term only, and no multiplicity adjustment because the
  # contrast was chosen before seeing the data
  agri_np_effect_test(fit, terms = N, B = 49, seed = 1, adjust = "none")

  # Example 3: an engine with no coefficients at all, which the kernel-based
  # agri_np_significance() cannot test
  fs <- agri_np_regression(yield ~ N, d, method = "smoothing_spline")
  agri_np_effect_test(fs, B = 49, seed = 1, cluster = NA)
}
#> Cluster wild-bootstrap test of predictor contribution
#>   Response: yield   engine: smoothing_spline   B = 49
#>   Signs drawn once per row, which assumes complete randomization
#> 
#>  term statistic p_value replicates note p_adjusted
#>     N    0.7871    0.02         49            0.02
#> 
#>   A p_value of 0.02 is the floor of 49 replicates,
#>   not a measurement. Raise B before quoting it.
#> 
#>   The null is that the term does not enter the response at all, not
#>   that its effect is linear or small. A term that is not rejected has
#>   not been shown to be absent.
```
