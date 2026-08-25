# Nonparametric time-to-event analysis for germination and emergence

Estimates the time-to-event distribution of a germination, emergence or
flowering trial without assuming a functional form for the curve, using
the intervals between inspections as intervals and keeping the subjects
that never had the event.

## Usage

``` r
agri_np_timetoevent(formula, data, by = NULL, units = NULL,
                    probs = c(0.1, 0.5, 0.9), B = 199L, seed = 1,
                    scores = c("wmw", "logrank1", "logrank2"),
                    method = c("npmle", "kde"))
```

## Arguments

- formula:

  Interval-censored counts, as `count ~ start + end`. `start` is the
  last inspection at which the subject had not yet responded and `end`
  the first at which it had; `end = Inf` marks a subject that never
  responded.

- data:

  Data frame.

- by:

  Optional treatment, cultivar, lot or species whose curves are to be
  compared.

- units:

  Experimental unit, typically the dish, tray or plot. Seeds in one dish
  share its water, its temperature and its handling, so they are not
  independent, and the permutation test resamples whole units rather
  than individual seeds.

- probs:

  Quantiles of the time-to-event distribution to report.

- B:

  Permutation replicates for the comparison of curves.

- seed:

  Random seed.

- scores:

  Rank scores for the permutation test.

- method:

  `"npmle"` for the nonparametric maximum likelihood estimator, `"kde"`
  for a kernel estimator of the same distribution.

## Details

Germination data are counted, not measured. A tray is inspected on day
3, day 5, day 7; a seed that germinated between two inspections is known
only to have done so somewhere inside that interval, and a seed that
never germinates is not a missing value but an observation censored at
the end of the trial.

The routine practice is to convert the counts into cumulative
percentages and fit a curve to them as if they were measurements. That
treats an interval-censored event time as observed, treats successive
cumulative percentages as independent when each contains all the earlier
ones, and either drops the ungerminated seeds or forces the curve to
100%, which invents a germination time for seeds that never had one.

The estimator used here does none of those things. It uses the intervals
as intervals, assumes no functional form, and leaves mass on "never".

Two properties of a seed lot follow, and a single number cannot carry
both. **Capacity** is how much of the lot responds at all, reported as
`responded`. **Speed** is how quickly the responding part gets there,
reported as the quantiles.

Quantiles are given twice. `*_responders` is computed among the subjects
that did respond and always exists. `*_lot` is computed on the whole lot
and is `NA` when the lot never reaches that fraction: a lot in which 32%
of seeds germinate has no median germination time, and reporting one
would require inventing germination for seeds that never germinated. The
`NA` is the answer, not a failure.

The comparison of curves is a permutation test on rank scores, so it
assumes no distribution. With `units`, whole dishes are permuted, which
is the level at which the randomization actually happened.

## Value

An object of class `agri_np_tte`, a list with `summary`, `test`,
`curve`, `intervals` and `fit`.

## References

Onofri, A., Mesgaran, M. B. and Ritz, C. (2022). A unified framework for
the analysis of germination, emergence, and other time-to-event data in
weed science. *Weed Science*, 70(3), 259-271.
[doi:10.1017/wsc.2022.8](https://doi.org/10.1017/wsc.2022.8)

Turnbull, B. W. (1976). The empirical distribution function with
arbitrarily grouped, censored and truncated data. *Journal of the Royal
Statistical Society Series B*, 38(3), 290-295.

## See also

[`agri_np_regression`](https://wep69.github.io/agriRank/reference/agri_np_regression.md)
for a measured response over a gradient,
[`agri_rank`](https://wep69.github.io/agriRank/reference/agri_rank.md)
for a measured response in a declared design.

## Examples

``` r
if (requireNamespace("drcte", quietly = TRUE)) {

data(verbascum, package = "drcte")

# Example 1. Three species inspected daily, with seeds that never germinated
# recorded as end = Inf. Capacity and speed are reported separately.
tte <- agri_np_timetoevent(nSeeds ~ timeBef + timeAf, verbascum,
                           by = Species, units = Dish, B = 99, seed = 1)
tte$summary[, c("level", "subjects", "responded")]

# Example 2. The whole-lot median is NA for a lot that never reaches half.
# That NA is the result: such a lot has no median germination time.
tte$summary[, c("level", "t50_responders", "t50_lot")]

# Example 3. The curves are compared by permutation, resampling whole dishes
# because seeds sharing a dish are not independent.
tte$test

# Example 4. The estimate is a step function, not a smooth curve fitted
# through cumulative percentages. A curve that stops below one is a lot that
# does not fully germinate.
p <- plot(tte, type = "cdf")
class(p)

# Example 5. A single lot needs no `by`.
one <- verbascum[verbascum$Species == "creticum", ]
agri_np_timetoevent(nSeeds ~ timeBef + timeAf, one)$summary

}
#>   level subjects responded t10_responders t10_lot t50_responders  t50_lot
#> 1   all      100      0.97       2.293939 2.30303       3.281818 3.309091
#>   t90_responders  t90_lot
#> 1       3.987273 4.222222
```
