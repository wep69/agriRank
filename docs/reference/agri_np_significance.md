# Test predictor significance in mixed-data kernel regression

Applies the bootstrap significance test implemented by
[`np::npsigtest()`](https://rdrr.io/pkg/np/man/np.sigtest.html) to an
`agriRank` continuous/mixed-data or ordered-discrete kernel regression.
Continuous, ordered and unordered predictors can be tested individually
or jointly.

## Usage

``` r
agri_np_significance(
  object,
  variables = NULL,
  joint = FALSE,
  B = 399L,
  boot_method = c("wild-rademacher", "wild", "iid", "pairwise"),
  boot_type = c("II", "I"),
  pivot = TRUE,
  seed = 42L,
  ...
)
```

## Arguments

- object:

  An `agri_np_reg_fit` fitted with `method = "kernel"` or
  `method = "discrete_kernel"`.

- variables:

  Character vector of scientific predictors to test. By default,
  predictors in the original formula are tested and a separately
  declared block remains only in the conditioning set.

- joint:

  If `TRUE`, test the selected predictors jointly.

- B:

  Number of bootstrap replications.

- boot_method:

  Bootstrap method accepted by
  [`np::npsigtest()`](https://rdrr.io/pkg/np/man/np.sigtest.html).

- boot_type:

  Type-II or Type-I bootstrap calibration. Type II is more
  computationally intensive.

- pivot:

  Use the pivotal statistic.

- seed:

  Reproducible bootstrap seed.

- ...:

  Additional arguments passed to
  [`np::npsigtest()`](https://rdrr.io/pkg/np/man/np.sigtest.html).

## Details

This function tests the relevance of predictors within a nonparametric
kernel regression; it is not a field-randomization test. A declared
agronomic block is retained in the fitted kernel model as a categorical
adjustment variable but is excluded from the default set of scientific
predictors being tested.

The default Type-II calibration is deliberately conservative
computationally because the np documentation notes that Type I can be
somewhat oversized in modest samples in some settings. Small bootstrap
counts used in examples are for speed only.

## Value

The np significance-test object, with attributes recording the tested
variables, block adjustment and an interpretation note.

## References

Racine JS, Hart J, Li Q (2006). Testing the Significance of Categorical
Predictor Variables in Nonparametric Regression Models. *Econometric
Reviews*, 25(4), 523–544. doi:10.1080/07474930600972590.

Hayfield T, Racine JS (2008). Nonparametric Econometrics: The np
Package. *Journal of Statistical Software*, 27(5).
doi:10.18637/jss.v027.i05.

## See also

[`agri_np_regression`](https://wep69.github.io/agriRank/reference/agri_np_regression.md),
[`agri_np_specification`](https://wep69.github.io/agriRank/reference/agri_np_specification.md),
[`agri_np_compare`](https://wep69.github.io/agriRank/reference/agri_np_compare.md)

## Examples

``` r
# B = 19 keeps the examples fast. Use B >= 999 for any reported test.

# Example 1: does nitrogen matter at all?
data(agri_dose)
if (requireNamespace("np", quietly = TRUE)) {
  f <- agri_np_regression(yield ~ dose, agri_dose, method = "kernel")
  agri_np_significance(f, B = 19, boot_type = "I")
  # A small p-value says the response is not flat. It does not say the
  # relationship is linear, nor where the optimum is.
}
#> 
#> Kernel Regression Significance Test
#> Type I Test with Rademacher Wild Bootstrap (19 replications, Pivot = TRUE, joint = FALSE)
#> Explanatory variables tested for significance:
#> dose (1)
#> 
#>                   dose
#> Bandwidth(s): 51.51631
#> 
#> Individual Significance Tests
#> P Value: 
#> dose < 2.22e-16 ***
#> ---
#> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
#> 
#> 
#> How this p-value treats the design
#>   The bootstrap here resamples rows. It is a model-based test of the
#>   kernel fit, not a randomization test derived from how the treatments
#>   were allocated in the field.

# Example 2: one gradient in the presence of another
data(agri_surface)
if (requireNamespace("np", quietly = TRUE)) {
  f2 <- agri_np_regression(yield ~ nitrogen + water, agri_surface, method = "kernel")
  agri_np_significance(f2, variables = "water", B = 19, boot_type = "I")
}
#> 
#> Kernel Regression Significance Test
#> Type I Test with Rademacher Wild Bootstrap (19 replications, Pivot = TRUE, joint = FALSE)
#> Explanatory variables tested for significance:
#> water (2)
#> 
#>               nitrogen     water
#> Bandwidth(s): 37.57901 0.2490973
#> 
#> Individual Significance Tests
#> P Value: 
#> water < 2.22e-16 ***
#> ---
#> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
#> 
#> 
#> How this p-value treats the design
#>   The bootstrap here resamples rows. It is a model-based test of the
#>   kernel fit, not a randomization test derived from how the treatments
#>   were allocated in the field.

# Example 3: joint significance while retaining the block adjustment
if (requireNamespace("np", quietly = TRUE)) {
  f3 <- agri_np_regression(yield ~ nitrogen + water, agri_surface,
                           method = "kernel", block = block)
  agri_np_significance(f3, variables = c("nitrogen", "water"), joint = TRUE,
                       B = 19, boot_type = "I")
  # The joint test asks whether the two gradients together explain the
  # response, which is the right question when they interact.
}
#> 
#> Kernel Regression Significance Test
#> Type I Test with Rademacher Wild Bootstrap (19 replications, Pivot = TRUE, joint = TRUE)
#> Explanatory variables tested for significance:
#> nitrogen (1), water (2)
#> 
#>               nitrogen     water     block
#> Bandwidth(s): 38.23568 0.2724512 0.4361795
#> 
#> Joint Significance Test
#> P Value:  < 2.22e-16 ***
#> ---
#> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
#> 
#> 
#> How this p-value treats the design
#>   The bootstrap here resamples rows. It is a model-based test of the
#>   kernel fit, not a randomization test derived from how the treatments
#>   were allocated in the field.
#>   This fit adjusts for the block `block`, and the block is in
#>   the model, but whole blocks are not kept together when resampling.
#>   The intervals from agri_np_bootstrap(), agri_np_levels() and
#>   agri_np_optimum_test() do keep them together, so they and this
#>   p-value do not rest on the same assumption. Report the difference.
```
