# Confidence interval and tests for the location of an optimum

Resamples the location of the fitted optimum, rather than the fitted
curve, so that a recommended rate can be reported with the uncertainty
it actually carries. Optionally compares the optimum between levels of a
qualitative predictor.

## Usage

``` r
agri_np_optimum_test(object, by = NULL, objective = c("max", "min"),
                     B = 999L, level = 0.95, seed = 1, n = 200L,
                     fixed = list(), range = NULL, cluster = NULL,
                     adjust = c("holm", "none", "BH", "bonferroni",
                                "hochberg", "hommel", "BY"),
                     external = TRUE, parallel = FALSE)
```

## Arguments

- object:

  An `agri_np_reg_fit` from
  [`agri_np_regression`](https://wep69.github.io/agriRank/reference/agri_np_regression.md).

- by:

  Optional qualitative predictor whose levels are to be compared, as a
  name or a string. It must already be a predictor of the fitted model.

- objective:

  `"max"` or `"min"`.

- B:

  Bootstrap replicates. Use at least 999 for anything reported.

- level:

  Confidence level of the interval for the optimum.

- seed:

  Random seed.

- n:

  Grid size on which the optimum is located.

- fixed:

  Values at which other covariates are held.

- range:

  Optional two-element range of the predictor to search within.

- cluster:

  Resampling unit. Defaults to the declared block, which keeps whole
  blocks together. Pass `NA` to resample individual rows, which is only
  legitimate for a completely randomized layout.

- adjust:

  Multiplicity adjustment applied across the pairwise contrasts produced
  by `by`, passed to
  [`p.adjust`](https://rdrr.io/r/stats/p.adjust.html). Defaults to
  `"holm"`. With `k` levels there are `k(k-1)/2` comparisons and the
  family-wise error rate grows accordingly. Use `"none"` only when a
  single contrast was specified in advance.

- external:

  Cross-check against
  [`npregfast::critical()`](https://rdrr.io/pkg/npregfast/man/critical.html)
  when that package is installed.

- parallel:

  Distribute the replicates over a `future` plan, through future.apply.
  The answer does not depend on it: each replicate is drawn from its own
  L'Ecuyer-CMRG substream, so a run on four cores returns the same
  interval as a run on one.

## Details

[`agri_np_optimum`](https://wep69.github.io/agriRank/reference/agri_np_optimum.md)
returns a point, and a point is not a recommendation. Two questions have
to be answered first.

How precisely is the location determined? A response that plateaus has a
maximum that wanders over a wide stretch of the gradient from one
resampled experiment to the next, even when the curve itself is well
estimated.

Is the maximum interior at all? An optimum reported at the edge of the
tested range is usually an artefact: a maximum has to land somewhere,
and if the response never turns over it lands on the boundary.
`p_boundary` is the share of replicates whose optimum falls on an end of
the searched range, and `identified` is `FALSE` when that share reaches
one half. In that situation the honest report is not a rate but the
statement produced by
[`agri_np_significant_slope`](https://wep69.github.io/agriRank/reference/agri_np_sizer.md).

The resampling is the package's own cluster bootstrap, so whole blocks
are resampled and the declared randomization is respected. With `by`,
every pair of levels is compared through the bootstrap distribution of
the difference between their optima, computed inside the same resampling
loop so that the two optima of a replicate come from the same resampled
experiment. The p-value is the resampling p-value with the Davison and
Hinkley correction, so its smallest attainable value is `2/(B + 1)`
rather than zero.

Comparing optima requires a model in which the curves may have different
shapes. A qualitative predictor entering additively forces parallel
curves and therefore one common optimum, so the function detects that
and refuses instead of reporting a difference of exactly zero. Fit with
`gam_structure = "varying"`, which gives one smooth per level.

Nothing here assumes a distribution for the response and nothing fits a
parametric response function. The optimum is located by evaluation on a
grid, exactly as in
[`agri_np_optimum`](https://wep69.github.io/agriRank/reference/agri_np_optimum.md).

## Value

An object of class `agri_np_optimum_test`, a list with components
`optimum`, `contrasts`, `replicates`, `curves` and `external`.

## References

Davison, A. C. and Hinkley, D. V. (1997). *Bootstrap Methods and their
Application*. Cambridge University Press.

Sperlich, S., Gonzalez-Manteiga, W. and Roca-Pardinas, J. (2013).
Bootstrap inference for nonparametric regression.

## See also

[`agri_np_optimum`](https://wep69.github.io/agriRank/reference/agri_np_optimum.md)
for the point estimate,
[`agri_np_sizer`](https://wep69.github.io/agriRank/reference/agri_np_sizer.md)
for where the response is still changing,
[`agri_integer_optimum`](https://wep69.github.io/agriRank/reference/agri_integer_optimum.md)
when the decision is an integer.

## Examples

``` r
data(agri_dose)

# Example 1. A nitrogen response that plateaus. The fitted maximum sits on the
# boundary, and resampling shows it is there in every replicate, so no rate is
# identified. B is small here for speed.
fit <- agri_np_regression(yield ~ dose, agri_dose, method = "gam", block = block)
ot <- agri_np_optimum_test(fit, B = 39, seed = 1, n = 40, external = FALSE)
ot$optimum
#>   level  n optimum lower upper fitted_response p_boundary replicates identified
#> 1   all 40     280   280   280        5.035595          1         21      FALSE

# Example 2. The distribution of the resampled optimum. Mass piled against an
# end of the range is the visual form of the same conclusion.
p <- plot(ot, type = "distribution")
class(p)
#> [1] "ggplot2::ggplot" "ggplot"          "ggplot2::gg"     "S7_object"      
#> [5] "gg"             

# Example 3. Comparing two cultivars needs a model whose curves may differ in
# shape, so the qualitative predictor must enter through a varying smooth.
set.seed(7)
a <- agri_dose; a$cultivar <- "late"
b <- agri_dose; b$cultivar <- "early"
b$yield <- b$yield - 0.000045 * (b$dose - 160)^2 + rnorm(nrow(b), 0, 0.15)
d2 <- rbind(a, b)
d2$cultivar <- factor(d2$cultivar, levels = c("early", "late"))

fit2 <- agri_np_regression(yield ~ dose + cultivar, d2, method = "gam",
                           block = block, gam_structure = "varying")
ot2 <- agri_np_optimum_test(fit2, by = cultivar, B = 39, seed = 1, n = 40,
                            external = FALSE)
ot2$optimum
#>   level  n  optimum    lower    upper fitted_response p_boundary replicates
#> 1 early 40 186.6667 172.3077 204.6154        4.771614          0         21
#> 2  late 40 280.0000 280.0000 280.0000        5.001628          1         21
#>   identified
#> 1       TRUE
#> 2      FALSE
ot2$contrasts
#>       contrast difference     lower     upper    p_value both_identified
#> 1 early - late  -93.33333 -107.6923 -75.38462 0.09090909           FALSE
#>   replicates p_adjusted
#> 1         21 0.09090909

# Example 4. An additive adjustment forces parallel curves, so the comparison
# is refused rather than answered with a difference of zero.
fit_add <- agri_np_regression(yield ~ dose + cultivar, d2, method = "gam",
                              block = block)
res <- tryCatch(agri_np_optimum_test(fit_add, by = cultivar, B = 19),
                error = function(e) conditionMessage(e))
cat(res, "\n")
#> The fitted curves for the levels of `cultivar` are parallel, because `cultivar` enters the model as an additive adjustment. Their optima are therefore identical by construction and comparing them would describe the model, not the experiment. Refit allowing the shape to differ, with `gam_structure = "varying"`, which fits one smooth of dose per level of cultivar. 

# Example 5. An integer decision is not located on a continuous grid, so the
# function points to the integer machinery instead.
data(agri_density)
fi <- agri_np_regression(yield ~ plants, agri_density, method = "integer_grid",
                         integer_base_method = "smoothing_spline",
                         predictor_support = "observed_integer")
res2 <- tryCatch(agri_np_optimum_test(fi), error = function(e) conditionMessage(e))
cat(res2, "\n")
#> This fit declares an integer decision support. Use `agri_integer_optimum()` and `agri_integer_confset()`, which work on the admissible integer lattice instead of a grid. 
```
