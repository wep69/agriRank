# From a Curve to a Decision

## 1. Why this vignette exists

A fitted curve is not a recommendation. Between the two lie four
questions that the earlier regression vignettes did not answer, and that
this one does.

**What does the interval cover?** An interval around a curve covers the
mean response. A grower does not sow the mean, they sow one plot, and
the interval that covers one plot is wider. Reporting the first where
the second was meant understates the uncertainty, sometimes by a factor
of three.

**How well does the model predict where nothing was measured?**
Cross-validated error can answer two different questions, and the
flattering one is the default almost everywhere. Whether a plot in an
observed block is predicted well, and whether an unobserved block is
predicted well, are not the same, and only the second is what a
recommendation claims.

**What rate should be applied?** The top of the curve is the agronomic
optimum. It is almost never the rate to apply, because the last
increments of input buy less produce than they cost.

**What if the field itself has a gradient?** Blocking was invented for a
field whose fertility varies in patches the size of a block. It does
nothing about a slope, an old road, a drainage line, and those are the
common case.

### 1.1 What else is here

| If you want | Read |
|----|----|
| the engines and how a curve is fitted | *Nonparametric and Shape-Aware Regression* |
| where the response is still changing | *Distribution-Free Uncertainty and Model Checking* |
| whether the model’s assumptions survive | *Testing What a Model Assumes* |
| the design side, before any of this | *Design Foundations, CRD, and RCBD* |

## 2. Learning objectives

By the end you should be able to:

1.  tell a confidence interval from a prediction interval, and say which
    one a recommendation needs;
2.  choose between the two cross-validation scopes, and say which
    question each answers;
3.  report an economic optimum with its interval, and read it as a
    function of the price ratio rather than as a single number;
4.  find the joint optimum of two rates, and explain why the rectangle
    of two marginal intervals is not its confidence region;
5.  add a field-position term and say what it absorbed;
6.  recognise when a prediction leaves the support of the data.

## 3. The module map

| Question | Function | Added in |
|----|----|----|
| what covers the next plot | `agri_np_predict(interval = "prediction")` | 0.14.0 |
| is this request inside the data | `agri_np_predict(extrapolation = )` | 0.14.0 |
| which prediction error | `cv_scope` in [`agri_np_compare()`](https://wep69.github.io/agriRank/reference/agri_np_compare.md) and [`agri_np_diagnostics()`](https://wep69.github.io/agriRank/reference/agri_np_diagnostics.md) | 0.14.0 |
| what rate pays | [`agri_np_optimum_economic()`](https://wep69.github.io/agriRank/reference/agri_np_optimum_economic.md) | 0.14.0 |
| what pair of rates pays | [`agri_np_optimum_surface()`](https://wep69.github.io/agriRank/reference/agri_np_optimum_surface.md) | 0.14.0 |
| what the field position hides | `spatial =` in [`agri_np_regression()`](https://wep69.github.io/agriRank/reference/agri_np_regression.md) | 0.14.0 |
| refit changing one thing | [`update()`](https://rdrr.io/r/stats/update.html) | 0.14.0 |
| into a report | [`agri_tidy()`](https://wep69.github.io/agriRank/reference/agri_broom.md), [`agri_glance()`](https://wep69.github.io/agriRank/reference/agri_broom.md), [`agri_augment()`](https://wep69.github.io/agriRank/reference/agri_broom.md) | 0.14.0 |

------------------------------------------------------------------------

## Part I. What the interval covers

## 4. The trial

``` r

d <- expand.grid(N = seq(0, 200, by = 50), block = factor(1:5), rep = 1:2)
d$yield <- 3 + 0.030 * d$N - 0.00009 * d$N^2 +
  as.numeric(d$block) * 0.30 + rnorm(nrow(d), 0, 0.30)
str(d)
#> 'data.frame':    50 obs. of  4 variables:
#>  $ N    : num  0 50 100 150 200 0 50 100 150 200 ...
#>  $ block: Factor w/ 5 levels "1","2","3","4",..: 1 1 1 1 1 2 2 2 2 2 ...
#>  $ rep  : int  1 1 1 1 1 1 1 1 1 1 ...
#>  $ yield: num  3.46 4.25 5.44 5.75 5.5 ...
#>  - attr(*, "out.attrs")=List of 2
#>   ..$ dim     : Named int [1:3] 5 5 2
#>   .. ..- attr(*, "names")= chr [1:3] "N" "block" "rep"
#>   ..$ dimnames:List of 3
#>   .. ..$ N    : chr [1:5] "N=  0" "N= 50" "N=100" "N=150" ...
#>   .. ..$ block: chr [1:5] "block=1" "block=2" "block=3" "block=4" ...
#>   .. ..$ rep  : chr [1:2] "rep=1" "rep=2"
```

Five blocks, five nitrogen rates, two plots per rate per block. The
response rises and turns over inside the tested range, which is the case
where a recommendation is possible at all.

``` r

fit <- agri_np_regression(yield ~ N, d, method = "gam", block = block, k = 5)
fit
#> agriRank nonparametric regression
#>   Method: gam
#>   Response: yield
#>   Predictors: N
#>   Block adjustment: block
```

### 4.1 Two intervals, two questions

``` r

nd <- data.frame(N = c(50, 100, 150),
                 block = factor("1", levels = levels(d$block)))

ci <- agri_np_predict(fit, nd, interval = "confidence")
pi <- agri_np_predict(fit, nd, interval = "prediction",
                      scope = "within_block", seed = 1)

data.frame(N = nd$N,
           confidence_width = round(ci$upper - ci$lower, 3),
           prediction_width = round(pi$upper - pi$lower, 3))
#>     N confidence_width prediction_width
#> 1  50            0.448            1.606
#> 2 100            0.420            1.606
#> 3 150            0.448            1.606
```

### 4.2 Interpretation

The prediction interval is wider, and it must be. The confidence
interval covers the average yield of plots at that rate; the prediction
interval covers the yield of **one** plot, which carries the
plot-to-plot variation on top of the uncertainty about the average.

A recommendation is about a plot. If a methods section reports the
narrow interval and the discussion talks about what a grower will
harvest, the two do not refer to the same quantity.

The prediction interval comes from split conformal prediction, so its
coverage is a finite-sample guarantee rather than a consequence of an
assumed error distribution. Nothing about normality is used.

### 4.3 Which plot, in which block

``` r

pw <- agri_np_predict(fit, nd, interval = "prediction",
                      scope = "within_block", seed = 1)
pn <- agri_np_predict(fit, nd, interval = "prediction",
                      scope = "new_block", seed = 1)

data.frame(N = nd$N,
           within_block = round(pw$upper - pw$lower, 3),
           new_block = round(pn$upper - pn$lower, 3))
#>     N within_block new_block
#> 1  50        1.606     2.505
#> 2 100        1.606     2.505
#> 3 150        1.606     2.505
```

`within_block` covers a new plot in a block already measured.
`new_block` covers a plot in a field, or a year, not yet seen. The
second is the one a recommendation to other growers implies, and it is
the one nobody reports.

The argument is required, without a default, when the fit declares a
block. Guessing on the user’s behalf would understate the interval half
the time.

### 4.4 The error that this invites

``` r

# Reported as if it covered a plot, this is too narrow by a factor of about
round((pi$upper - pi$lower) / (ci$upper - ci$lower), 2)
#> [1] 3.59 3.82 3.59
```

## 5. Asking beyond the data

``` r

# The trial went to 200 kg/ha. What happens at 400?
agri_np_predict(fit, data.frame(N = 400,
                                block = factor("1", levels = levels(d$block))),
                extrapolation = "error")
#> Error:
#> ! `newdata` leaves the range of the data the smoother was fitted to: N outside [0, 200]. A nonparametric fit carries no information beyond its support, so a value returned there describes the basis rather than the experiment. The request exceeds `extrapolation_tol` = 0.1. Use `extrapolation = "warn"` to obtain it anyway, and do not report it as an estimate.
```

### 5.1 Interpretation

Outside the range of the data a smoother has no information. Whatever
number comes back describes the spline basis, not the experiment. This
is different in kind from a parametric model, where extrapolation is at
least an extrapolation of a stated functional form; here there is no
form to extrapolate.

The default is `"warn"`, which returns the value and flags the offending
rows:

``` r

p <- agri_np_predict(fit, data.frame(N = c(100, 400),
                                     block = factor("1", levels = levels(d$block))))
#> Warning: `newdata` leaves the range of the data the smoother was fitted to: N
#> outside [0, 200]. A nonparametric fit carries no information beyond its
#> support, so a value returned there describes the basis rather than the
#> experiment.
attr(p, "extrapolated") %||% p$extrapolated
#> [1] FALSE  TRUE
```

Cross-validation and bootstrap loops are exempt from the check, because
held-out folds and resampled replicates leave the training range by
construction.

------------------------------------------------------------------------

## Part II. Which prediction error

## 6. Two scopes, two questions

``` r

w <- agri_np_diagnostics(fit, cv = TRUE, kfold = 5, seed = 1,
                         cv_scope = "within_block")
n <- agri_np_diagnostics(fit, cv = TRUE, kfold = 5, seed = 1,
                         cv_scope = "new_block")

data.frame(scope = c("within_block", "new_block"),
           cv_r2 = round(c(w$r2$cv_r2, n$r2$cv_r2), 4))
#>          scope  cv_r2
#> 1 within_block 0.8973
#> 2    new_block 0.6415
```

### 6.1 Interpretation

`within_block` stratifies the folds, so every block appears in training.
Plot mates therefore sit on both sides of the split, and the estimate
answers “how well is another plot in **this** block predicted”. That is
the optimistic question.

`new_block` holds out whole blocks. It answers “how well is a block
never measured predicted”, which is what a recommendation to a different
field claims. The number is always worse, and it is the honest one.

### 6.2 A substantive consequence

Under `new_block` the block term is **dropped** from the fold models. A
block that was held out has no estimated effect, so a model carrying it
could only return `NA` for every held-out row. Dropping it makes the
validated error refer to a block of average fertility, which is the only
thing an unobserved block can mean.

That is not a workaround. It is the statement that you cannot predict a
specific new block, only an average one, and any procedure that appears
to do otherwise is estimating something it has no data for.

### 6.3 The incoherence this fixed

Before 0.14.0
[`agri_np_compare()`](https://wep69.github.io/agriRank/reference/agri_np_compare.md)
stratified its folds by block while the routine behind
`agri_np_diagnostics(cv = TRUE)` assigned rows at random. The same model
reported two different validated errors depending on which function was
asked, and nothing said so. Both now share one fold rule and one
argument.

------------------------------------------------------------------------

## Part III. What rate pays

## 7. The agronomic optimum is not the recommendation

``` r

agri_np_optimum(fit)
#>   predictor  optimum fitted_response objective at_boundary    support
#> 1         N 160.3206        5.912491       max       FALSE continuous
```

The top of the curve. Applying it means paying for the last increments
of nitrogen that return less grain than they cost.

## 8. The economic optimum

``` r

ec <- agri_np_optimum_economic(fit, price_ratio = 0.006, B = 99, seed = 1)
#> Warning: B < 999 is a speed device for examples and vignettes; final inference
#> needs B >= 999. Silence this note with options(agriRank.quiet_small_B = TRUE).
ec
#> Economic optimum of yield over N
#>   Marginal product equals the price ratio, dy/dx = r
#>   Resampling unit: whole levels of `block`   B = 99   level = 0.95
#> 
#>  price_ratio level optimum lower upper fitted_response p_boundary replicates
#>        0.006   all   130.5 124.8 138.4           5.826          0         59
#>  identified
#>        TRUE
#> 
#> Agronomic optimum, the top of the curve, for comparison: 160.8
#>   The economic optimum lies below it, as it must on a concave response.
#>   The distance between the two is the input that would be applied
#>   at a loss.
```

### 8.1 What the price ratio is

The price of one unit of input divided by the price of one unit of
produce, in the units of the fitted model. If nitrogen costs 1.20 per kg
and grain sells for 0.30 per kg, the ratio is 4, and the optimum is
where the last kilogram of nitrogen returns four kilograms of grain.

The function solves

``` math
\frac{\partial y}{\partial x} = r
```

and takes the root at the first crossing from above, because up to that
point another unit of input still pays for itself.

### 8.2 The check that the solver is right

``` r

agri_np_optimum_economic(fit, price_ratio = 0, B = 99, seed = 1)$optimum$optimum
#> [1] 160.4993
agri_np_optimum(fit, n = 200)$optimum
#> [1] 160.804
```

With a price ratio of zero the economic optimum must be the agronomic
one, because the input is free. It is, to within the grid spacing. This
is not a recommendation, it is a check.

### 8.3 The ratio moves the answer more than the data do

``` r

ev <- agri_np_optimum_economic(fit, price_ratio = c(0.002, 0.006, 0.012, 0.020),
                               B = 99, seed = 1)
ev$optimum[, c("price_ratio", "optimum", "lower", "upper", "identified")]
#>   price_ratio   optimum     lower     upper identified
#> 1       0.002 149.63713 143.75493 159.15215       TRUE
#> 2       0.006 130.46460 124.78123 138.36431       TRUE
#> 3       0.012 102.83483  94.88794 111.43529       TRUE
#> 4       0.020  58.43123   0.00000  65.96416       TRUE
```

### 8.4 Interpretation

Read that table as a sensitivity analysis, not as four recommendations.
The price ratio is treated as known and it is not: prices move between
the trial and the season in which the recommendation is used, and they
usually move the answer further than the resampling interval does.

Compare the width of any single interval with the spread across ratios.
If the second is larger, and it usually is, then the honest limitation
of the recommendation is economic rather than statistical, and the
methods section should say which price ratio was assumed.

### 8.5 When there is no rate to report

`p_boundary` is the share of replicates whose root lands on an end of
the searched range, and `identified` turns `FALSE` at one half. At that
point the trial does not contain the answer: either the response never
stops paying inside the tested range, or it never starts. Reporting a
rate anyway would be reporting the edge of the design.

## 9. Two rates at once

``` r

s <- expand.grid(N = seq(0, 200, 50), P = seq(0, 60, 15), block = factor(1:3))
s$yield <- 3 + 0.030 * s$N - 0.00013 * s$N^2 + 0.070 * s$P -
  0.0009 * s$P^2 - 0.00010 * s$N * s$P +
  as.numeric(s$block) * 0.2 + rnorm(nrow(s), 0, 0.15)
```

### 9.1 The model must let them interact

``` r

fa <- agri_np_regression(yield ~ N + P, s, method = "gam", block = block, k = 4)
agri_np_optimum_surface(fa, B = 49, n = 12)
#> Error:
#> ! The fitted surface is additive in `N` and `P`, so the optimum in each is the same at every level of the other and the joint optimum carries no information the two separate optima do not. Refit with `gam_structure = "tensor"`, which lets the two interact, or use agri_np_optimum() on each predictor and say that the surface was assumed additive.
```

An additive surface has an optimum in each input that is the same at
every level of the other. A joint optimum would then carry no
information the two separate optima do not, and reporting a joint region
for it would describe the model rather than the trial. The function
refuses.

``` r

ft <- agri_np_regression(yield ~ N + P, s, method = "gam", block = block,
                         k = 4, gam_structure = "tensor")
os <- agri_np_optimum_surface(ft, B = 99, seed = 1, n = 20)
os
#> Joint maximum of yield over N and P
#>   Resampling unit: whole levels of `block`   B = 99   level = 0.95
#> 
#>  predictor optimum box_lower box_upper searched_lower searched_upper
#>          N  105.26    105.26    115.79              0            200
#>          P   34.74     34.74     34.74              0             60
#> 
#> Fitted response at the joint optimum: 5.9538
#> 
#>   box_lower and box_upper are the two marginal intervals. Together
#>   they form a rectangle, and the rectangle is NOT the confidence region
#>   for the pair: it admits corners no replicate visited.
#>   `$region` is NULL: too few replicates were retained to describe a
#>   region. Raise B.
```

### 9.2 The rectangle is not the region

``` r

head(os$region)
#> NULL
```

`box_lower` and `box_upper` are the two marginal intervals. Together
they form a rectangle, and **the rectangle is not the confidence region
for the pair**. When the surface has a ridge, more of one input
compensating for less of the other, the cloud of resampled optima lies
along a diagonal and the rectangle admits corners that no replicate ever
visited.

The rank correlation between the two coordinates across replicates is
printed for that reason. A value far from zero is the signature of a
ridge.

### 9.3 Interpretation

Report the pair, the region, and the correlation. A reader who sees only
two marginal intervals will imagine a rectangle, and will conclude that
the two rates can be chosen independently, which on a ridge they cannot.

------------------------------------------------------------------------

## Part IV. What the field position hides

## 10. Blocking is a coarse instrument

``` r

f <- expand.grid(row = 1:8, col = 1:6)
f$N <- rep(seq(0, 200, by = 50), length.out = nrow(f))
f$block <- factor(ceiling(f$row / 2))
# A gradient that runs continuously across the whole trial, which no block can
# absorb: a slope, an old road, a drainage line.
f$yield <- 3 + 0.03 * f$N - 0.00009 * f$N^2 +
  0.25 * f$row + 0.15 * f$col + rnorm(nrow(f), 0, 0.20)
```

``` r

f0 <- agri_np_regression(yield ~ N, f, method = "gam", block = block, k = 4)
fx <- agri_np_regression(yield ~ N, f, method = "gam", block = block, k = 4,
                         spatial = "smooth_xy", coords = c("row", "col"))
fr <- agri_np_regression(yield ~ N, f, method = "gam", block = block, k = 4,
                         spatial = "row_col", coords = c("row", "col"))

data.frame(model = c("block only", "block + s(row, col)", "block + row + col"),
           RMSE = round(c(f0$metrics$RMSE, fx$metrics$RMSE, fr$metrics$RMSE), 4))
#>                 model   RMSE
#> 1          block only 0.2942
#> 2 block + s(row, col) 0.1386
#> 3   block + row + col 0.1323
```

### 10.1 What each does

``` r

deparse(f0$formula_used)
#> [1] "yield ~ s(N, k = 4) + block"
deparse(fx$formula_used)
#> [1] "yield ~ s(N, k = 4) + block + s(row, col, k = 12)"
deparse(fr$formula_used)
#> [1] "yield ~ s(N, k = 4) + block + factor(row) + factor(col)"
```

`smooth_xy` adds a two-dimensional thin-plate smooth of the coordinates,
which absorbs a continuous trend of any orientation and costs the
effective degrees of freedom that the fitting method selects for it.
`row_col` adds additive row and column factors, which is cheaper and
right when the layout is a lattice and the trend follows it.

### 10.2 Interpretation

The residual fell by more than half. That variation was in the trial all
along, the block could not absorb it because it crosses blocks, and it
was inflating every interval and every p-value computed from that
residual.

The coordinates are nuisance terms, not predictors. Prediction grids
hold them at their reference value, so a reported curve refers to a plot
of average position, which is the right default.

### 10.3 The engines that can carry it

``` r

agri_np_regression(yield ~ N, f, method = "loess",
                   spatial = "smooth_xy", coords = c("row", "col"))
#> Error:
#> ! `spatial = "smooth_xy"` is available for the penalised additive engines, `gam`, `scam` and `smooth_quantile`, which estimate the field trend jointly with the response curve. `loess` has no term to carry it, and dropping it silently would leave the trend in the residual while the output suggested otherwise.
```

Only the penalised additive engines have a term to hold a field trend.
Asked of another engine the request is refused, because dropping it
silently would leave the trend in the residual while the output
suggested otherwise.

------------------------------------------------------------------------

## Part V. Working with the objects

## 11. Changing one thing

``` r

f_k7 <- update(fx, k = 7)
c(original_k = fx$settings$k, updated_k = f_k7$settings$k)
#> original_k  updated_k 
#>          4          7
c(spatial_preserved = f_k7$spatial)
#> spatial_preserved 
#>       "smooth_xy"
```

Comparing two engines or trying a shape constraint no longer means
retyping the whole call, which is where a predictor or a block quietly
goes missing between the two versions being compared. The refit uses the
rows stored in the fit, so the two models are fitted to the same data.

All the guards still apply:

``` r

update(fit, method = "loess")
#> Error:
#> ! Method `loess` does not adjust for the declared block in agriRank. Use kernel, quantile, GAM or SCAM, or omit block only when scientifically justified.
```

## 12. Into a report

``` r

head(agri_tidy(fit, n = 8))
#>   term         x estimate
#> 1    N   0.00000 3.532741
#> 2    N  28.57143 4.205320
#> 3    N  57.14286 4.825328
#> 4    N  85.71429 5.340515
#> 5    N 114.28571 5.700510
#> 6    N 142.85714 5.883783
agri_glance(fit)
#>   method response  n n_omitted pseudo_r2 spearman_r2 effective_df      RMSE
#> 1    gam    yield 50         0 0.9312705   0.9065331      2.80715 0.2715656
#>        MAE block spatial
#> 1 0.224531 block    none
head(agri_augment(fit), 3)
#>     N block rep    yield  .fitted      .resid
#> 1   0     1   1 3.456177 3.532741 -0.07656443
#> 2  50     1   1 4.251093 4.678128 -0.42703515
#> 3 100     1   1 5.441771 5.542665 -0.10089320
```

### 12.1 Why `agri_tidy()` returns a curve

Most of the sixteen engines have no coefficients, and those that do have
them for a spline basis rather than for any quantity worth reporting. So
the tidied object is the **fitted curve**, one row per grid point.

There is no `p.value` column, because no test was performed. The
rank-based side does return one row per term with a p-value, because
there one was.

## 13. Resampling faster

``` r

# Requires future.apply and a plan set by the user
future::plan(future::multisession, workers = 4)
agri_np_optimum_economic(fit, price_ratio = 0.006, B = 999, seed = 1,
                         parallel = TRUE)
future::plan(future::sequential)
```

The answer does not depend on it. Each replicate is drawn from its own
L’Ecuyer-CMRG substream, so replicate `b` is the same object whichever
worker computes it and in whatever order, and a run on four cores
returns the same interval as a run on one. Below a few hundred
replicates the workers cost more than they save, which is why the
default is sequential.

------------------------------------------------------------------------

## Part VI. Common mistakes, and the function that prevents each

## 14. Reporting a confidence interval as if it covered a plot

**The mistake.** Quoting `interval = "confidence"` in a sentence about
what a grower will harvest.

**Why it is wrong.** The two cover different quantities and differ by a
factor of two or three. The narrower one is about the average of many
plots.

**What prevents it.** `interval = "prediction"` exists and is one
argument away.

## 15. Reporting the flattering cross-validation

**The mistake.** Quoting a validated error obtained with stratified
folds as evidence that the model predicts new fields well.

**Why it is wrong.** Plot mates sat on both sides of the split, so the
estimate describes prediction inside an observed block.

**What prevents it.** `cv_scope = "new_block"`, and the note printed
with the result names which question was answered.

## 16. Recommending the top of the curve

**The mistake.** Reporting
[`agri_np_optimum()`](https://wep69.github.io/agriRank/reference/agri_np_optimum.md)
as the rate to apply.

**Why it is wrong.** It ignores the price of the input entirely. On a
decelerating response the economic optimum is always lower, often by a
third.

**What prevents it.**
[`agri_np_optimum_economic()`](https://wep69.github.io/agriRank/reference/agri_np_optimum_economic.md),
and the printed comparison against the agronomic optimum that comes with
it.

## 17. Treating the price ratio as known

**The mistake.** Reporting one economic optimum without saying what
ratio was assumed.

**Why it is wrong.** Prices move between the trial and the season in
which the recommendation is used, usually further than the resampling
interval.

**What prevents it.** `price_ratio` accepts a vector, and the printed
output says to read the table as a sensitivity analysis.

## 18. Reading the rectangle as the joint region

**The mistake.** Taking the two marginal intervals of a joint optimum as
a confidence region for the pair.

**Why it is wrong.** On a ridge the resampled optima lie along a
diagonal, and the rectangle admits corners no replicate visited.

**What prevents it.** `$region` and the printed rank correlation, and
the labelling of `box_lower` and `box_upper` as what they are.

## 19. Optimising two inputs one at a time

**The mistake.** Running
[`agri_np_optimum()`](https://wep69.github.io/agriRank/reference/agri_np_optimum.md)
on N with P fixed, then on P with N fixed, and reporting the pair.

**Why it is wrong.** That is the top of the surface only if the two act
additively, which is what a factorial rate trial exists to test.

**What prevents it.**
[`agri_np_optimum_surface()`](https://wep69.github.io/agriRank/reference/agri_np_optimum_surface.md),
which refuses an additive fit.

## 20. Leaving a field gradient in the residual

**The mistake.** Blocking and stopping there, in a trial that runs
across a slope.

**Why it is wrong.** A gradient that crosses blocks is not absorbed by
them. It stays in the residual, inflating every interval and every
p-value.

**What prevents it.** `spatial =` with `coords =`, and the refusal to
accept it for an engine that cannot carry it.

## 21. Extrapolating a smoother

**The mistake.** Predicting at a rate beyond the largest one tested.

**Why it is wrong.** A nonparametric fit carries no information outside
its support. The value returned describes the basis.

**What prevents it.** `extrapolation = "warn"` by default and `"error"`
on request, plus the `extrapolated` flag on the returned rows.

------------------------------------------------------------------------

## Part VII. Selection guide

## 22. Choose the interval by the sentence you are writing

| The sentence is about | Use |
|----|----|
| the average response at a rate | `interval = "confidence"` |
| what one plot in this trial will yield | `interval = "prediction"`, `scope = "within_block"` |
| what a plot in another field will yield | `interval = "prediction"`, `scope = "new_block"` |
| the shape of the whole curve | `agri_np_bootstrap(band = "simultaneous")` |

## 23. Choose the optimum by the decision

| The decision | Use |
|----|----|
| where the response peaks | [`agri_np_optimum()`](https://wep69.github.io/agriRank/reference/agri_np_optimum.md) |
| how well that peak is located | [`agri_np_optimum_test()`](https://wep69.github.io/agriRank/reference/agri_np_optimum_test.md) |
| what rate pays, given prices | [`agri_np_optimum_economic()`](https://wep69.github.io/agriRank/reference/agri_np_optimum_economic.md) |
| what pair of rates pays | [`agri_np_optimum_surface()`](https://wep69.github.io/agriRank/reference/agri_np_optimum_surface.md) |
| how many plants, sprays, irrigations | [`agri_integer_optimum()`](https://wep69.github.io/agriRank/reference/agri_integer_optimum.md) |
| whether an optimum exists at all | [`agri_np_significant_slope()`](https://wep69.github.io/agriRank/reference/agri_np_sizer.md) |

------------------------------------------------------------------------

## Part VIII. Minimum reporting checklist

## 24. What the methods section must contain

1.  the engine, and whether a shape was imposed;
2.  how the block entered, fixed or shrunk;
3.  whether a field-position term was fitted, and which kind;
4.  for an interval: confidence or prediction, and for a prediction
    interval, the scope;
5.  for a validated error: the cross-validation scope;
6.  for an economic optimum: the price ratio assumed, and the range
    explored;
7.  for a joint optimum: that the region is a hull of resampled optima
    and not the rectangle of the marginal intervals;
8.  the number of resampling replicates and the seed.

## 25. A worked methods paragraph

> Yield response to nitrogen was fitted by a penalised additive model
> with the block as a fixed effect and a two-dimensional smooth of row
> and column position to absorb the field gradient (agriRank 0.14.0).
> The agronomic optimum was 158 kg/ha. At a nitrogen to grain price
> ratio of 0.006 the economic optimum was 119 kg/ha, with a 95%
> cluster-bootstrap interval of 117 to 124 kg/ha from 999 replicates
> resampling whole blocks (seed 1). Across the price ratios 0.002 to
> 0.020 the economic optimum ranged from 200 to 62 kg/ha, so the
> recommendation is more sensitive to price than to sampling error.
> Prediction intervals for individual plots were obtained by split
> conformal prediction with `scope = "new_block"`, which refers to a
> field not represented in the trial.

## 26. Where to go next

| If you now want | Read |
|----|----|
| whether the predictors and the shape survive a test | *Testing What a Model Assumes* |
| repeated measurements, several responses, missing plots | *Testing What a Model Assumes*, Part III |
| where the response is still changing | *Distribution-Free Uncertainty and Model Checking* |
| the whole workflow on one experiment | *Integrated Agronomic Case Study* |

------------------------------------------------------------------------

## Glossary

| Term | Meaning here |
|----|----|
| **confidence interval** | covers the mean response at a covariate setting |
| **prediction interval** | covers the next individual plot; always wider |
| **scope** | which plot the prediction interval refers to, in an observed block or a new one |
| **cross-validation scope** | which question the validated error answers, the same distinction applied to folds |
| **agronomic optimum** | the rate at which the response peaks |
| **economic optimum** | the rate at which the marginal product equals the price ratio |
| **price ratio** | price of a unit of input divided by price of a unit of produce |
| **joint optimum** | the pair of rates that optimises the surface, not the two separate optima |
| **ridge** | a surface along which one input compensates for the other |
| **field trend** | continuous fertility variation that crosses blocks |
| **extrapolation** | prediction outside the range of the observed predictor |
| **substream** | an independent random number stream, one per replicate |

## Selected references

- Cerrato, M. E. and Blackmer, A. M. (1990). Comparison of models for
  describing corn yield response to nitrogen fertilizer. *Agronomy
  Journal*, 82(1), 138-143.
- Lawless, C., Semenov, M. A. and Jamieson, P. D. (2008). Quantifying
  the effect of uncertainty in soil moisture characteristics on plant
  growth. *Field Crops Research*, 106(2), 138-147.
- Lei, J., G’Sell, M., Rinaldo, A., Tibshirani, R. J. and Wasserman, L.
  (2018). Distribution-free predictive inference for regression.
  *Journal of the American Statistical Association*, 113(523),
  1094-1111.
- L’Ecuyer, P., Simard, R., Chen, E. J. and Kelton, W. D. (2002). An
  object-oriented random-number package with many long streams and
  substreams. *Operations Research*, 50(6), 1073-1075.
- Wood, S. N. (2017). *Generalized Additive Models: An Introduction with
  R*, 2nd edition. Chapman and Hall.
