# Testing What a Model Assumes, and Data That Resist

## 1. Why this vignette exists

Every previous regression vignette took the model as given and asked
what it said. This one asks the model to justify itself, and then takes
on three kinds of data that the module could not previously handle at
all.

Two questions about the model:

**Does this predictor earn its place?** The regression module fits a
curve and reports an interval around it, but until 0.14.0 it had no test
that the predictor mattered at all, except for two of the sixteen
engines through a route that ignored the block.

**Is the shape I imposed compatible with the data?**
`shape = "increasing"` buys precision when the response really is
increasing and biases the curve when it is not. Nothing checked which
case applied.

Three kinds of data:

**Repeated measurements.** Four harvests on the same plots are four rows
per plot, not four independent observations.

**Several responses.** Nitrogen raises yield and moves protein. The two
optima come from the same plots, so their errors are correlated, and
separate analyses cannot say how far apart they are.

**Missing plots.** The plot that was lost is often the flooded one.

### 1.1 The single device behind Part I

The two tests share one machine, the **cluster wild bootstrap**: refit
under the null, then build replicate responses from the null fitted
values plus the residuals multiplied by random signs drawn **once per
block** rather than once per plot.

Signing plots independently would treat the plots of a block as
independent, which is the error this whole package exists to prevent.
Signing whole blocks leaves the within-block dependence intact whatever
its form. Only the null model differs between the two tests.

## 2. Learning objectives

By the end you should be able to:

1.  test whether a predictor contributes, for any engine, respecting the
    block;
2.  read the limit that the number of blocks places on any such p-value;
3.  test a shape constraint and say what a large p-value does and does
    not mean;
4.  fit a curve to repeated measurements without inflating the
    replication;
5.  report two optima with the distance between them, not two separate
    intervals;
6.  use multiple imputation as a sensitivity analysis rather than as an
    answer.

## 3. The module map

| Question | Function | Null or structure |
|----|----|----|
| does this term matter | [`agri_np_effect_test()`](https://wep69.github.io/agriRank/reference/agri_np_effect_test.md) | the model without it |
| is this shape compatible | [`agri_np_shape_test()`](https://wep69.github.io/agriRank/reference/agri_np_shape_test.md) | the constrained fit |
| repeated measurements | [`agri_np_longitudinal()`](https://wep69.github.io/agriRank/reference/agri_np_longitudinal.md) | subject shrunk, subject resampled |
| several responses | [`agri_np_multiresponse()`](https://wep69.github.io/agriRank/reference/agri_np_multiresponse.md) | one shared bootstrap |
| missing plots | [`agri_np_impute()`](https://wep69.github.io/agriRank/reference/agri_np_impute.md) | MAR, reported beside complete case |

------------------------------------------------------------------------

## Part I. Making the model justify itself

## 4. The trial, with a predictor that does nothing

``` r

d <- expand.grid(N = seq(0, 200, by = 50), block = factor(1:5), rep = 1:2)
d$noise <- rnorm(nrow(d))            # a covariate with no effect at all
d$yield <- 3 + 0.030 * d$N - 0.00009 * d$N^2 +
  as.numeric(d$block) * 0.30 + rnorm(nrow(d), 0, 0.30)

fit <- agri_np_regression(yield ~ N + noise, d, method = "gam",
                          block = block, k = 5)
```

`noise` was generated independently of yield. A test worth having should
be able to tell it from nitrogen.

### 4.1 The test

``` r

et <- agri_np_effect_test(fit, B = 99, seed = 1)
#> Warning: B < 999 is a speed device for examples and vignettes; final inference
#> needs B >= 999. Silence this note with options(agriRank.quiet_small_B = TRUE).
et
#> Cluster wild-bootstrap test of predictor contribution
#>   Response: yield   engine: gam   B = 99
#>   Signs drawn once per level of `block`, so the within-block dependence survives
#> 
#>   term statistic p_value replicates note p_adjusted
#>      N    1.7541    0.06         99            0.12
#>  noise    0.0068    0.58         99            0.58
#> 
#>   With 5 blocks there are only 2^5 = 32 distinct sign patterns,
#>   so no p-value below about 0.031 can be produced however large B is.
#>   That is a limit of the design, not of the resampling: more blocks
#>   is the remedy, more replicates is not.
#> 
#>   The null is that the term does not enter the response at all, not
#>   that its effect is linear or small. A term that is not rejected has
#>   not been shown to be absent.
```

### 4.2 Interpretation

Look at the **statistic** before the p-value. Nitrogen and the noise
variable differ by three orders of magnitude, which is the
discrimination the test actually achieved.

The p-values are much closer together, and the printed note explains
why: with five blocks there are only $`2^5 = 32`$ distinct sign
patterns, so no p-value below about 0.03 can be produced however large
`B` is. That is a limit of the **design**, not of the resampling. More
blocks is the remedy; more replicates is not.

This is worth stating plainly because it is easy to misread a p-value of
0.08 from five blocks as weak evidence, when in fact the test had almost
no room to produce anything smaller.

### 4.3 What the null actually is

The null is that the term does not enter the response **at all**, not
that its effect is linear or small. A term that is not rejected has not
been shown to be absent, and with five blocks that statement is very
weak indeed.

### 4.4 It works where the old test could not

``` r

fs <- agri_np_regression(yield ~ N, d, method = "smoothing_spline")
agri_np_effect_test(fs, B = 99, seed = 1, cluster = NA)$table
#>   term statistic p_value replicates note p_adjusted
#> 1    N 0.8685237    0.01         99            0.01
```

A smoothing spline has no coefficients to test and is outside the reach
of
[`agri_np_significance()`](https://wep69.github.io/agriRank/reference/agri_np_significance.md),
which calls
[`np::npsigtest()`](https://rdrr.io/pkg/np/man/np.sigtest.html) and
works only for the kernel engines. This test looks only at fitted values
and residuals, so it works for all sixteen.

Note `cluster = NA` here, because this fit declares no block. Signing
rows independently is legitimate only for a completely randomized
layout, and the printed header says which assumption was made.

### 4.5 The asymmetry this removed

Before 0.14.0 every **interval** in the regression module resampled
whole blocks, while the only **p-value** available resampled rows. A
p-value and an interval from the same fit therefore rested on different
assumptions, and nothing in the output said so. That is now visible in
both directions:
[`agri_np_significance()`](https://wep69.github.io/agriRank/reference/agri_np_significance.md)
prints its caveat, and
[`agri_np_effect_test()`](https://wep69.github.io/agriRank/reference/agri_np_effect_test.md)
exists.

## 5. Is the shape I imposed compatible with the data

``` r

f1 <- agri_np_regression(yield ~ N, d, method = "gam", block = block, k = 5)
```

### 5.1 A shape agronomy expects

``` r

agri_np_shape_test(f1, shape = "increasing_concave", B = 99, seed = 1)
#> Cluster wild-bootstrap test of a shape constraint
#>   Response: yield   free comparison: gam   B = 99
#>   Signs drawn once per level of `block`
#> 
#>               shape statistic p_value replicates constrained_RMSE free_RMSE
#>  increasing_concave  0.001981    0.23         99            0.294     0.294
#> 
#>   The null is that the constraint holds. A large p-value does not
#>   prove the shape; it says these data do not contradict it, which with
#>   few blocks is a weak statement. Read it beside agri_np_sizer(),
#>   which shows where the free fit actually changes direction.
```

### 5.2 A shape the data should contradict

``` r

agri_np_shape_test(f1, shape = "increasing", B = 99, seed = 1)
#> Cluster wild-bootstrap test of a shape constraint
#>   Response: yield   free comparison: gam   B = 99
#>   Signs drawn once per level of `block`
#> 
#>       shape statistic p_value replicates constrained_RMSE free_RMSE
#>  increasing 0.0008028    0.77         99           0.2928     0.294
#> 
#>   The null is that the constraint holds. A large p-value does not
#>   prove the shape; it says these data do not contradict it, which with
#>   few blocks is a weak statement. Read it beside agri_np_sizer(),
#>   which shows where the free fit actually changes direction.
#> 
#>   The constrained fit has the smaller RMSE, which cannot happen by
#>   optimisation and means the two engines differ in more than the
#>   constraint. Compare like with like before reading the p-value.
```

### 5.3 Interpretation

The response rises and then turns over inside the tested range, so a
purely increasing constraint has to distort the fit near the top, and
the second test should see more distortion than the first.

**A large p-value does not prove the shape.** It says these data do not
contradict it, which is the most a test of this kind can say, and with
five blocks it is a weak statement for the reason given in section 4.2.

### 5.4 Read it beside the SiZer

``` r

agri_np_significant_slope(agri_np_sizer(f1), stability = 0.8)
#>   predictor stability increase_from increase_to stops_increasing_at
#> 1         N       0.8             0         110                 115
#>   decrease_from decrease_to
#> 1            NA          NA
```

A shape test compresses the whole curve into one number. The SiZer says
**where** the free fit changes direction, across a column of bandwidths,
and that is usually the more useful statement. Use the test to decide
whether to impose the constraint and the SiZer to describe the response.

### 5.5 A diagnostic the print method performs for you

If the constrained fit has the smaller RMSE, which cannot happen by
optimisation, the two engines differ in more than the constraint and the
printed output says so. Compare like with like before reading the
p-value.

------------------------------------------------------------------------

## Part II. Repeated measurements

## 6. Four harvests on the same plots

``` r

lg <- expand.grid(N = seq(0, 200, 50), plot = factor(1:12), time = factor(1:3))
lg$yield <- 3 + 0.03 * lg$N - 0.00009 * lg$N^2 +
  as.numeric(lg$plot) * 0.15 + as.numeric(lg$time) * 0.40 +
  rnorm(nrow(lg), 0, 0.25)
nrow(lg)
#> [1] 180
```

### 6.1 The error this invites

Fitting `yield ~ N` to these 180 rows treats them as 180 independent
observations. There are twelve plots. The apparent replication is
inflated threefold, and every interval is too narrow by roughly the
square root of that.

### 6.2 The fit

``` r

lf <- agri_np_longitudinal(yield ~ N, lg, subject = plot, time = time, k = 4)
lf
#> agriRank longitudinal regression
#>   Subject: plot   12 units
#>   Time: time   3 occasions   balanced
#>   Time enters as: smooth, so the level drifts but the shape does not
#>   Subject effects are shrunk, and the subject is the resampling unit
#>   for every interval, conformal split and cross-validation fold
#>   downstream.
#> 
#> agriRank nonparametric regression
#>   Method: gam
#>   Response: yield
#>   Predictors: N, time
#>   Qualitative predictors: time
#>   Note: reference level of time is "1". Coefficients are contrasts against the reference.
#>   Block adjustment: plot
#> 
#>   The within-subject dependence is handled by resampling whole
#>   subjects, not by a modelled correlation over time. That assumes
#>   nothing about its form and, in exchange, is conservative when the
#>   occasions are many and closely spaced.
```

### 6.3 What happened structurally

The subject became the **block**. That is not a trick: the subject *is*
the unit of resampling, so every tool in the module then does the right
thing without knowing anything about repeated measurement.

``` r

b <- agri_np_bootstrap(lf, B = 99, n = 25, seed = 1)
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
attr(b, "cluster")
#> [1] "plot"
```

The bootstrap resamples whole plots.
[`agri_np_conformal()`](https://wep69.github.io/agriRank/reference/agri_np_conformal.md)
splits by plot. `agri_np_compare(cv_scope = "new_block")` holds out
whole plots, which is the honest question: how well is a plot predicted
that was never measured.

### 6.4 Letting the shape change over time

``` r

lv <- agri_np_longitudinal(yield ~ N, lg, subject = plot, time = time,
                           time_effect = "varying", k = 4)
deparse(lv$formula_used)
#> [1] "yield ~ time + s(N, by = time, k = 4) + s(plot, bs = \"re\")"
```

`"smooth"` lets the level drift between occasions while the shape stays
the same. `"varying"` lets the shape itself differ, which is what a
multi-harvest trial usually asks: does the response to nitrogen change
as the season advances.

### 6.5 What this is not

**It is not a GAMM with a modelled within-subject correlation.** Nothing
here estimates an autocorrelation over time. The dependence is handled
by resampling whole subjects, which assumes nothing about its form and,
in exchange, cannot recover the efficiency that a correct correlation
model would.

If the occasions are many and closely spaced, a weekly series over a
season say, a model that represents the correlation is the better tool
and this one will be conservative. Say which you used.

### 6.6 Data that are not repeated measurements

``` r

lg1 <- lg[!duplicated(lg$plot), ]
agri_np_longitudinal(yield ~ N, lg1, subject = plot, time = time)
#> Error:
#> ! Every level of `plot` appears once, so these data are not repeated measurements. Use agri_np_regression() directly.
```

------------------------------------------------------------------------

## Part III. Several responses to one gradient

## 7. Yield and protein

``` r

mv <- expand.grid(N = seq(0, 200, 50), block = factor(1:5))
mv$yield   <- 3 + 0.040 * mv$N - 0.00020 * mv$N^2 +
  as.numeric(mv$block) * 0.2 + rnorm(nrow(mv), 0, 0.15)
mv$protein <- 9 + 0.026 * mv$N - 0.00009 * mv$N^2 +
  as.numeric(mv$block) * 0.1 + rnorm(nrow(mv), 0, 0.15)
```

### 7.1 The analysis

``` r

mr <- agri_np_multiresponse(cbind(yield, protein) ~ N, mv, block = block,
                            B = 99, seed = 1, n = 60, k = 4)
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
mr
#> Optima of several responses to N, from one shared bootstrap
#>   Resampling unit: whole levels of `block`   B = 99   level = 0.95
#> 
#>  response objective optimum  lower upper replicates
#>     yield       max   105.1  98.31 105.1         59
#>   protein       max   142.4 135.59 145.8         59
#> 
#>   Only 60% of replicates were usable. Resampling whole blocks
#>   sometimes omits one, and a refit that never saw a block cannot predict
#>   for it. Raise B to keep the same effective number of replicates.
#> 
#> Distance between optima, both from the same resampled experiment:
#> 
#>         contrast difference  lower  upper p_value rank_correlation replicates
#>  yield - protein     -37.29 -44.07 -30.51 0.03333          -0.2109         59
#> 
#>   `$region` holds the joint region for the pair, 6 vertices. It is not
#>   the rectangle formed by the two intervals above.
#> 
#>   A joint region is not a compromise rate. Choosing one rate for two
#>   responses is a decision about their relative value, not a statistical
#>   question, and this function does not make it.
```

### 7.2 What the shared bootstrap buys

Every response is refitted on the **same** resampled blocks within a
replicate. Calling
[`agri_np_optimum_test()`](https://wep69.github.io/agriRank/reference/agri_np_optimum_test.md)
twice would give each response its own resampled experiment and destroy
exactly the dependence the joint question turns on.

The consequence is the row that separate analyses cannot produce: the
**distance** between the two optima, with its own interval and p-value.
That distance, not either optimum on its own, is what a joint
recommendation has to face.

### 7.3 The joint region

``` r

head(mr$region)
#>       yield  protein
#> 1 105.08475 135.5932
#> 2 101.69492 135.5932
#> 3  98.30508 138.9831
#> 4  98.30508 142.3729
#> 5 101.69492 145.7627
#> 6 105.08475 145.7627
```

For two responses the region is the convex hull of the replicate pairs.
It is not the rectangle formed by the two marginal intervals printed
above, for the same reason as in the two-predictor case: the pairs may
lie along a diagonal, and the rectangle admits corners that no replicate
visited.

### 7.4 One maximised, one minimised

``` r

mv$lodging <- 20 + 0.10 * mv$N + rnorm(nrow(mv), 0, 2)
agri_np_multiresponse(cbind(yield, lodging) ~ N, mv, block = block,
                      objective = c("max", "min"), B = 99, seed = 1,
                      n = 40, k = 4)$optima
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#> Warning in predict.gam(eng, newdata = newdata, type = "response"): factor
#> levels 1 not in original fit
#>   response objective  optimum   lower    upper replicates
#> 1    yield       max 102.5641 97.4359 102.5641         59
#> 2  lodging       min   0.0000  0.0000   0.0000         59
```

A single `objective` would have been wrong here. Yield is maximised and
lodging minimised, and the function accepts one entry per response for
that reason.

### 7.5 Interpretation, and what the function refuses to do

**A joint region is not a compromise rate.** Choosing one rate for two
responses is a decision about their relative value, an economic and
agronomic judgement, not a statistical question. This function supplies
how far apart the optima are and how well that distance is determined,
and stops there.

When prices are what decide, run
[`agri_np_optimum_economic()`](https://wep69.github.io/agriRank/reference/agri_np_optimum_economic.md)
on each response with its own price ratio, and read the two together.

------------------------------------------------------------------------

## Part IV. Missing plots

## 8. The plot that was lost is often the flooded one

``` r

mi <- d[, c("N", "block", "yield")]
mi$yield[sample(nrow(mi), 8)] <- NA
sum(is.na(mi$yield))
#> [1] 8
```

### 8.1 What the module did before

Complete-case analysis, with `na_action = "fail"` as the default so that
rows were never dropped silently. That default is right and stays. But
complete-case analysis is unbiased only when the missingness is
unrelated to the response, and in a field trial it usually is not.

### 8.2 Multiple imputation, always beside the complete case

``` r

im <- agri_np_impute(yield ~ N, mi, block = block, m = 5, B = 99,
                     seed = 1, n = 40, k = 4)
im
#> Multiple imputation for a nonparametric regression
#>   Response: yield   gradient: N
#>   Rows: 50 total, 42 complete   imputations: 5   method: pmm
#> 
#>  variable n_missing
#>     yield         8
#> 
#> Optimum:
#> 
#>             source optimum lower upper
#>      complete case   179.5    NA    NA
#>             pooled   184.6    NA    NA
#>  imputation spread      NA 164.1   200
#> 
#>   The complete-case and pooled optima differ by 5.13, which is 2.6% of the tested range.
#>   That is small, so the missingness is not driving the conclusion and
#>   the complete-case analysis can be reported as the primary one.
#> 
#>   Largest fraction of missing information along the curve: 0.722.
#> 
#>   This is the one place in agriRank that assumes a missingness
#>   mechanism. Imputation is valid when the data are missing at random
#>   given what was observed, which is an assumption about why the plots
#>   were lost and not a property these data can confirm. Report both
#>   analyses, not only this one.
```

### 8.3 Interpretation

**This is the one place in the package that assumes a missingness
mechanism.** Multiple imputation is valid when the data are missing at
random given the observed variables, and that is an assumption about
*why* the plots were lost, not a property these data can confirm.

Everything else in agriRank avoids such assumptions. This function makes
one deliberately, and never returns only the imputed answer: the
complete-case fit is always computed and printed beside it, and the gap
between the two optima is reported as a percentage of the tested range.

Read the two together:

- if they agree, the missingness is not driving the conclusion and the
  complete-case analysis can be reported as the primary one;
- if they disagree, **that disagreement is the finding**. The conclusion
  depends on what was assumed about the plots that were lost, and the
  methods section has to say so.

### 8.4 How much the imputation is doing

``` r

head(im$curve[, c("x", "complete_case", "pooled", "fmi")])
#>           x complete_case   pooled       fmi
#> 1  0.000000      3.202606 3.429936 0.7155015
#> 2  5.128205      3.358022 3.553241 0.7154320
#> 3 10.256410      3.512708 3.676117 0.7147441
#> 4 15.384615      3.665936 3.798136 0.7127255
#> 5 20.512821      3.816976 3.918870 0.7073945
#> 6 25.641026      3.965100 4.037888 0.6925015
```

`fmi` is the fraction of missing information at each point of the curve.
Where it is near zero the imputation changed nothing there; where it is
large the pooled answer rests mostly on the assumption.

### 8.5 The pooling

The pooled variance at each grid point is the average within-imputation
bootstrap variance plus $`(1 + 1/m)`$ times the variance of the $`m`$
point estimates, which is Rubin’s rule. The **block survives into the
within part**, because that part uses the package’s own cluster
bootstrap rather than a model-based standard error.

### 8.6 With nothing missing

``` r

agri_np_impute(yield ~ N, mi[!is.na(mi$yield), ], block = block, m = 3)
#> Error:
#> ! There is nothing missing among the modelled variables, so imputation would only add noise. Use agri_np_regression().
```

------------------------------------------------------------------------

## Part V. Common mistakes, and the function that prevents each

## 9. Quoting a p-value that the design could not have produced

**The mistake.** Reporting p = 0.08 from five blocks as weak evidence of
no effect.

**Why it is wrong.** With five blocks the cluster wild bootstrap has 32
possible outcomes and cannot produce anything below about 0.03. The test
had almost no room.

**What prevents it.**
[`agri_np_effect_test()`](https://wep69.github.io/agriRank/reference/agri_np_effect_test.md)
prints the $`2^G`$ limit when the number of blocks is small, and says
that more blocks, not more replicates, is the remedy.

## 10. Reading a large shape-test p-value as proof of the shape

**The mistake.** “The monotonicity test was not significant, so the
response is monotone.”

**Why it is wrong.** Failing to reject is not evidence for the null,
especially with few blocks.

**What prevents it.** The printed note says exactly this, and points to
[`agri_np_sizer()`](https://wep69.github.io/agriRank/reference/agri_np_sizer.md)
for the statement that can actually be made.

## 11. Treating repeated measurements as replicates

**The mistake.** Fitting `yield ~ N` to a long-format table with four
harvests per plot.

**Why it is wrong.** The replication is inflated by the number of
occasions and every interval is too narrow.

**What prevents it.**
[`agri_np_longitudinal()`](https://wep69.github.io/agriRank/reference/agri_np_longitudinal.md),
which also refuses data in which units are measured only once.

## 12. Analysing two responses separately and comparing their intervals

**The mistake.** Running
[`agri_np_optimum_test()`](https://wep69.github.io/agriRank/reference/agri_np_optimum_test.md)
on yield and on protein, then saying the optima differ because the
intervals do not overlap.

**Why it is wrong.** The two optima come from the same plots. Their
errors are correlated, so the overlap of marginal intervals is not the
test of their difference.

**What prevents it.**
[`agri_np_multiresponse()`](https://wep69.github.io/agriRank/reference/agri_np_multiresponse.md),
whose shared bootstrap gives the difference its own interval and
p-value.

## 13. Reporting only the imputed analysis

**The mistake.** Running multiple imputation and reporting the pooled
curve as the result.

**Why it is wrong.** The pooled curve rests on an untestable assumption
about why the plots were lost.

**What prevents it.**
[`agri_np_impute()`](https://wep69.github.io/agriRank/reference/agri_np_impute.md)
always computes and prints the complete-case fit beside it, and
quantifies the gap.

## 14. Using imputation to rescue an underpowered trial

**The mistake.** Imputing a large fraction of the response and reporting
the narrower pooled interval.

**Why it is wrong.** Imputation propagates uncertainty, it does not
create information. A high `fmi` says most of the answer at that point
is assumption.

**What prevents it.** The `fmi` column, and the largest value along the
curve printed with the result.

------------------------------------------------------------------------

## Part VI. Selection guide

## 15. Choose the test by the question

| The question | Use |
|----|----|
| does this term contribute at all | [`agri_np_effect_test()`](https://wep69.github.io/agriRank/reference/agri_np_effect_test.md) |
| is the constraint I imposed compatible | [`agri_np_shape_test()`](https://wep69.github.io/agriRank/reference/agri_np_shape_test.md) |
| where is the response still changing | [`agri_np_sizer()`](https://wep69.github.io/agriRank/reference/agri_np_sizer.md) |
| how well is the optimum located | [`agri_np_optimum_test()`](https://wep69.github.io/agriRank/reference/agri_np_optimum_test.md) |
| kernel engine, and I want the standard route | [`agri_np_significance()`](https://wep69.github.io/agriRank/reference/agri_np_significance.md) |

## 16. Choose the structure by the data

| The data | Use |
|----|----|
| one measurement per plot | [`agri_np_regression()`](https://wep69.github.io/agriRank/reference/agri_np_regression.md) |
| several occasions per plot | [`agri_np_longitudinal()`](https://wep69.github.io/agriRank/reference/agri_np_longitudinal.md) |
| several responses per plot | [`agri_np_multiresponse()`](https://wep69.github.io/agriRank/reference/agri_np_multiresponse.md) |
| plots missing | [`agri_np_impute()`](https://wep69.github.io/agriRank/reference/agri_np_impute.md), beside complete case |
| plots missing, ranks rather than a curve | [`agri_missing_sensitivity()`](https://wep69.github.io/agriRank/reference/agri_missing_sensitivity.md) |

------------------------------------------------------------------------

## Part VII. Minimum reporting checklist

## 17. What the methods section must contain

1.  for any test here: the resampling unit, and that signs were drawn
    per block;
2.  the number of blocks, since it bounds the attainable p-value;
3.  the number of replicates and the seed;
4.  for a shape test: which constraint, and which free engine it was
    compared to;
5.  for longitudinal data: the subject, the number of occasions, whether
    the design is balanced, and that dependence was handled by
    resampling subjects rather than by a modelled correlation;
6.  for several responses: that one shared bootstrap was used, and the
    distance between optima with its interval;
7.  for imputation: the mechanism assumed, the number of imputations,
    the imputation method, the fraction of missing information, and
    **both** the pooled and complete-case results.

## 18. A worked methods paragraph

> The contribution of each predictor was assessed by a cluster wild
> bootstrap with Rademacher signs drawn once per block, 999 replicates,
> seed 1 (agriRank 0.14.0). With five blocks this procedure admits 32
> distinct sign patterns, so no p-value below 0.031 is attainable and
> the statistic is reported alongside. The assumption that the response
> is increasing and concave was tested against an unconstrained additive
> fit by the same device and was not contradicted (p = 0.52), which we
> read as compatibility rather than as evidence for the constraint.
> Yield and grain protein were analysed jointly with a single shared
> bootstrap, so that the correlation between their optima is preserved;
> the two optima differed by 37 kg/ha (95% interval 33 to 47). Eight
> plots were lost. Results are reported for the complete cases, with a
> multiple-imputation sensitivity analysis (m = 5, predictive mean
> matching) that moved the optimum by less than 2% of the tested range.

## 19. Where to go next

| If you now want | Read |
|----|----|
| the economic and joint optima | *From a Curve to a Decision* |
| the engines themselves | *Nonparametric and Shape-Aware Regression* |
| conformal intervals and simulated residuals | *Distribution-Free Uncertainty and Model Checking* |
| the rank-based repeated-measures side | *Repeated Measures and Missing Longitudinal Data* |
| the whole workflow on one experiment | *Integrated Agronomic Case Study* |

------------------------------------------------------------------------

## Glossary

| Term | Meaning here |
|----|----|
| **cluster wild bootstrap** | replicate responses built from null fitted values plus residuals times random signs, drawn once per cluster |
| **Rademacher signs** | random values of $`-1`$ or $`+1`$ |
| **null model** | the fit under the hypothesis being tested: without the term, or with the constraint |
| **$`2^G`$ limit** | with $`G`$ blocks only $`2^G`$ sign patterns exist, bounding the smallest attainable p-value |
| **shape constraint** | monotonicity or curvature imposed on the fitted curve |
| **subject** | the unit measured more than once |
| **shared bootstrap** | one resample of blocks per replicate, reused for every response |
| **MAR** | missing at random given the observed variables |
| **fmi** | fraction of missing information, how much of the pooled variance comes from the imputation |
| **Rubin’s rules** | pooling of estimates and variances across imputations |

## Selected references

- Cameron, A. C., Gelbach, J. B. and Miller, D. L. (2008).
  Bootstrap-based improvements for inference with clustered errors. *The
  Review of Economics and Statistics*, 90(3), 414-427.
- Haerdle, W. and Mammen, E. (1993). Comparing nonparametric versus
  parametric regression fits. *The Annals of Statistics*, 21(4),
  1926-1947.
- Webb, M. D. (2023). Reworking wild bootstrap-based inference for
  clustered errors. *Canadian Journal of Economics*, 56(3), 1113-1141.
- Rubin, D. B. (1987). *Multiple Imputation for Nonresponse in Surveys*.
  Wiley.
- van Buuren, S. and Groothuis-Oudshoorn, K. (2011). mice: Multivariate
  imputation by chained equations in R. *Journal of Statistical
  Software*, 45(3), 1-67.
- Wood, S. N. (2017). *Generalized Additive Models: An Introduction with
  R*, 2nd edition. Chapman and Hall.
