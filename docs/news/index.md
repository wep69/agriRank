# Changelog

## agriRank 0.14.0

### Regression: making the model justify itself

Two tests, one device. Both refit under the null and then build
replicate responses from the null fitted values plus the residuals
multiplied by random signs drawn **once per block** rather than once per
plot. Signing plots independently would treat the plots of a block as
independent, which is the error the rest of this package exists to
prevent.

- Added
  [`agri_np_effect_test()`](https://wep69.github.io/agriRank/reference/agri_np_effect_test.md).
  Until now the only significance test in the regression module was
  [`agri_np_significance()`](https://wep69.github.io/agriRank/reference/agri_np_significance.md),
  which works for two of the sixteen engines and resamples rows,
  ignoring the declared randomization, while **every interval in the
  module resampled whole blocks**. A p-value and an interval from the
  same fit therefore rested on different assumptions. This test works
  for all sixteen engines, because it looks only at fitted values and
  residuals rather than inside the engine, and it respects the block.
- [`agri_np_effect_test()`](https://wep69.github.io/agriRank/reference/agri_np_effect_test.md)
  reports the limit the design places on the test. With `G` blocks there
  are only `2^G` distinct sign vectors, so with five blocks no p-value
  below about 0.03 can be produced however large `B` is. That is a limit
  of the design, not of the resampling, and raising `B` does not fix it.
  The printed output says so, because a p-value of 0.08 from five blocks
  is easily misread as weak evidence when the test had almost no room to
  produce anything smaller. The statistic is reported alongside for the
  same reason: it separated a real predictor from pure noise by three
  orders of magnitude in a case where the p-values were 0.08 and 0.11.
- Added
  [`agri_np_shape_test()`](https://wep69.github.io/agriRank/reference/agri_np_shape_test.md).
  `shape = "increasing"` buys precision when the response really is
  increasing and biases the curve when it is not, and nothing checked
  which case applied. The null is that the constraint holds, so the
  replicate responses come from the **constrained** fit. A large p-value
  does not prove the shape; the printed note says this, and points to
  [`agri_np_sizer()`](https://wep69.github.io/agriRank/reference/agri_np_sizer.md)
  for the statement that can actually be made about where the free fit
  changes direction.

### Regression: data the cross-sectional module could not hold

- Added
  [`agri_np_longitudinal()`](https://wep69.github.io/agriRank/reference/agri_np_longitudinal.md)
  for a gradient measured repeatedly on the same plots. Four harvests on
  twelve plots are 36 rows and twelve units, and fitting them as 36
  independent observations inflates the replication threefold. The
  implementation opens no new modelling framework: the subject becomes
  the block, entered as a penalised random effect, and therefore becomes
  the resampling unit for every bootstrap, conformal split and
  cross-validation fold downstream, without a single change to any of
  them. `time_effect = "varying"` lets the shape of the response differ
  between occasions rather than only its level.
- [`agri_np_longitudinal()`](https://wep69.github.io/agriRank/reference/agri_np_longitudinal.md)
  is **not** a GAMM with a modelled within-subject correlation. Nothing
  estimates an autocorrelation over time. The dependence is handled by
  resampling whole subjects, which assumes nothing about its form and,
  in exchange, is conservative when the occasions are many and closely
  spaced. The documentation and the print method both say so.
- Added
  [`agri_np_multiresponse()`](https://wep69.github.io/agriRank/reference/agri_np_multiresponse.md)
  for several responses to one gradient, with **one shared bootstrap**.
  Every response is refitted on the same resampled blocks within a
  replicate. Calling
  [`agri_np_optimum_test()`](https://wep69.github.io/agriRank/reference/agri_np_optimum_test.md)
  twice would give each response its own resampled experiment and
  destroy exactly the dependence the joint question turns on. What that
  buys is the row separate analyses cannot produce: the distance between
  the two optima, with its own interval and p-value, which is what a
  joint recommendation actually faces. `objective` takes one entry per
  response, since yield is maximised and lodging minimised.
- A joint region is **not** a compromise rate. Choosing one rate for two
  responses is a decision about their relative value, not a statistical
  question, and the function deliberately does not make it.
- Added
  [`agri_np_impute()`](https://wep69.github.io/agriRank/reference/agri_np_impute.md).
  **This is the one place in the package that assumes a missingness
  mechanism.** Multiple imputation is valid when the data are missing at
  random given the observed variables, and that is an assumption about
  why the plots were lost, not a property the data can confirm. The
  function therefore never returns only the imputed answer: it always
  fits the complete-case model too, prints them side by side, and
  reports the gap between the two optima as a percentage of the tested
  range. If they agree the missingness is not driving the conclusion; if
  they disagree, that disagreement is the finding. Pooling follows
  Rubin, and the block survives into the within-imputation variance
  because that part uses the package’s own cluster bootstrap. `mice` is
  in Suggests.

### Vignettes

- Added *From a Curve to a Decision*, which covers the prediction
  interval and its scope, the extrapolation guard, the two
  cross-validation scopes, the economic optimum and its sensitivity to
  price, the joint optimum of two rates and why the rectangle of two
  marginal intervals is not its confidence region, and the
  field-position term.
- Added *Testing What a Model Assumes, and Data That Resist*, which
  covers the two tests above, the `2^G` limit, and the three kinds of
  data the module could not previously hold.

### Regression: from a curve to a decision

Three additions that close the distance between what the module fitted
and what an agronomist has to decide.

- Added
  [`agri_np_optimum_economic()`](https://wep69.github.io/agriRank/reference/agri_np_optimum_economic.md).
  [`agri_np_optimum()`](https://wep69.github.io/agriRank/reference/agri_np_optimum.md)
  returns the top of the curve, and that is almost never the rate to
  apply, because the last increments of input buy less produce than they
  cost. The economic optimum solves
  `dy/dx = price_input / price_output`, always lies below the agronomic
  optimum on a concave response, and the gap between the two is
  frequently the whole margin of the field. Everything the calculation
  needed already existed here, the derivative and the cluster bootstrap
  of a location rather than a height; this joins them. With
  `price_ratio = 0` it must reproduce
  [`agri_np_optimum()`](https://wep69.github.io/agriRank/reference/agri_np_optimum.md),
  and a test checks that it does.
- [`agri_np_optimum_economic()`](https://wep69.github.io/agriRank/reference/agri_np_optimum_economic.md)
  accepts a **vector** of price ratios and reports one row per ratio,
  because the ratio is treated as known and is not: prices move the
  recommendation further than the resampling interval does, and reading
  the table as a sensitivity analysis is the honest use. `p_boundary`
  and `identified` carry the same meaning as in
  [`agri_np_optimum_test()`](https://wep69.github.io/agriRank/reference/agri_np_optimum_test.md),
  so a price at which the response never stops paying inside the tested
  range is reported as unidentified rather than as a rate.
- Added
  [`agri_np_optimum_surface()`](https://wep69.github.io/agriRank/reference/agri_np_optimum_surface.md)
  for the joint optimum of two rates.
  [`agri_np_optimum()`](https://wep69.github.io/agriRank/reference/agri_np_optimum.md)
  optimises one predictor with the others held fixed, and applied twice
  that is not the top of the surface unless the two inputs act
  additively, which is precisely what a factorial rate trial exists to
  test. A fit the model has forced to be additive is refused, in the
  same spirit as the parallel-curve guard.
- **The confidence region reported by
  [`agri_np_optimum_surface()`](https://wep69.github.io/agriRank/reference/agri_np_optimum_surface.md)
  is not the rectangle of the two marginal intervals.** The rectangle is
  given too, as `box_lower` and `box_upper`, because it is what a reader
  expects, and it is labelled so it is not mistaken for the region. When
  the surface has a ridge the two differ sharply: the cloud of resampled
  optima lies along a diagonal, more of one input compensating for less
  of the other, and the rectangle admits corners no replicate ever
  visited. `$region` holds the convex hull of the retained replicates
  and the rank correlation between the two coordinates is printed for
  the same reason.
- Added `spatial` and `coords` to
  [`agri_np_regression()`](https://wep69.github.io/agriRank/reference/agri_np_regression.md).
  Blocking is a coarse instrument: it was invented for a field whose
  fertility varies in patches the size of a block, and it does nothing
  about a gradient running continuously across the trial, which is the
  common case. `"smooth_xy"` adds `s(row, col)`, a two-dimensional
  smooth that absorbs a trend of any orientation; `"row_col"` adds
  additive row and column factors. Both are nuisance terms estimated
  jointly with the response curve rather than in a first pass, and both
  are available only for the penalised additive engines. Asked of an
  engine with no term to carry it, the request is refused, because
  dropping it silently would leave the trend in the residual while the
  output suggested otherwise.

### Regression: speed and interoperability

- [`agri_np_bootstrap()`](https://wep69.github.io/agriRank/reference/agri_np_bootstrap.md),
  [`agri_np_optimum_test()`](https://wep69.github.io/agriRank/reference/agri_np_optimum_test.md),
  [`agri_np_optimum_economic()`](https://wep69.github.io/agriRank/reference/agri_np_optimum_economic.md)
  and
  [`agri_np_optimum_surface()`](https://wep69.github.io/agriRank/reference/agri_np_optimum_surface.md)
  accept `parallel = TRUE`, which distributes the replicates over a
  `future` plan through `future.apply`, both in Suggests. The default is
  and stays sequential: below a few hundred replicates, starting workers
  and shipping the data costs more than it saves. **The answer does not
  depend on it.** Each replicate is drawn from its own L’Ecuyer-CMRG
  substream, introduced for exactly this purpose, so a run on four cores
  returns the same interval as a run on one. A test asserts it against
  real workers, not just against the sequential fallback.
- Added
  [`agri_tidy()`](https://wep69.github.io/agriRank/reference/agri_broom.md),
  [`agri_glance()`](https://wep69.github.io/agriRank/reference/agri_broom.md)
  and
  [`agri_augment()`](https://wep69.github.io/agriRank/reference/agri_broom.md),
  and the corresponding broom methods registered at load time when broom
  is installed. broom stays a suggestion rather than becoming a
  dependency in all but name.
- [`agri_tidy()`](https://wep69.github.io/agriRank/reference/agri_broom.md)
  on a regression fit returns the **fitted curve**, one row per grid
  point, not an invented coefficient table: most of the sixteen engines
  have no coefficients, and those that do have them for a spline basis
  rather than for any quantity worth reporting. There is no `p.value`
  column, because no test was performed. The rank side does return one
  row per term with a p-value, because there one was.

### Regression: four places where the package disagreed with itself

These are not new features. They are corrections found by reading the
regression source rather than its documentation, looking for four
patterns: `p.adjust`, `fold`, `cluster` and `extrapolat`. The same kind
of sweep is what uncovered the permuco problem recorded below.

- **The two cross-validation routines answered the same question
  differently.**
  [`agri_np_compare()`](https://wep69.github.io/agriRank/reference/agri_np_compare.md)
  stratified its folds within blocks while the routine behind
  `agri_np_diagnostics(cv = TRUE)` assigned rows at random, so the same
  model reported two validated errors depending on which function was
  asked. Both now share one fold rule and one argument, `cv_scope`.
- `cv_scope` makes the choice explicit rather than implicit.
  `"within_block"` stratifies, and estimates the error of predicting
  another plot in a block already observed. `"new_block"` holds out
  whole blocks, and estimates the error of predicting where nothing was
  measured, which is the question a recommendation actually poses. The
  first is always the more flattering. This is the same distinction
  [`agri_np_conformal()`](https://wep69.github.io/agriRank/reference/agri_np_conformal.md)
  has always exposed through its own `scope`, and the wording is now
  identical. Under `"new_block"` the block term is dropped from the fold
  models, because a block that was held out has no estimated effect and
  a model carrying it could only return `NA` for every held-out row.
- **`agri_np_optimum_test(by = )` reported unadjusted p-values.** With
  `k` levels it performs `k(k-1)/2` comparisons. The rank-based side of
  the package has offered multiplicity adjustment since the first
  release; the regression side did not, for the same kind of all-pairs
  comparison. There is now an `adjust` argument, defaulting to Holm, a
  `p_adjusted` column, and a printed note when the resampling floor of
  `2/(B+1)` has been reached, since a p-value sitting on that floor is a
  statement about `B` rather than about the levels.
- **Nothing stopped a prediction from leaving the range of the data.** A
  smoother carries no information beyond its support: outside it the
  returned value describes the chosen basis, not the experiment.
  [`agri_np_predict()`](https://wep69.github.io/agriRank/reference/agri_np_predict.md)
  now takes `extrapolation = c("warn", "error", "allow")`, marks the
  offending rows with an `extrapolated` flag, and refuses under
  `"error"` when the request leaves the observed envelope by more than
  `extrapolation_tol`, default 10% of its width. Cross-validation and
  bootstrap loops are exempt, because held-out folds and resampled
  replicates leave the training range by construction.
- **[`agri_np_significance()`](https://wep69.github.io/agriRank/reference/agri_np_significance.md)
  recorded its limitation where nobody would see it.** The test
  delegates to
  [`np::npsigtest()`](https://rdrr.io/pkg/np/man/np.sigtest.html), which
  resamples rows, while
  [`agri_np_bootstrap()`](https://wep69.github.io/agriRank/reference/agri_np_bootstrap.md),
  [`agri_np_levels()`](https://wep69.github.io/agriRank/reference/agri_np_levels.md),
  [`agri_np_forest()`](https://wep69.github.io/agriRank/reference/agri_np_forest.md)
  and
  [`agri_np_optimum_test()`](https://wep69.github.io/agriRank/reference/agri_np_optimum_test.md)
  all resample whole blocks. The discrepancy was stored in an attribute,
  and attributes are not printed. It is now printed.

### Regression: three additions of convenience

- [`agri_np_predict()`](https://wep69.github.io/agriRank/reference/agri_np_predict.md)
  accepts `interval = "prediction"`, delegating to
  [`agri_np_conformal()`](https://wep69.github.io/agriRank/reference/agri_np_conformal.md).
  A confidence interval covers the mean response; a prediction interval
  covers the next individual plot, which is what a recommendation needs,
  and is always wider. Routing it through
  [`predict()`](https://rdrr.io/r/stats/predict.html) means the user no
  longer has to know that conformal prediction exists in order to obtain
  the right quantity. `scope` is required when a block is declared,
  because `"within_block"` and `"new_block"` answer different questions
  and guessing on the user’s behalf would understate the interval.
- Added [`update()`](https://rdrr.io/r/stats/update.html) for
  `agri_np_reg_fit`. Comparing two engines or trying a shape constraint
  no longer means retyping the whole call, which is where a predictor or
  a block quietly goes missing between the two versions being compared.
  The refit uses the rows stored in the fit, so the two models are
  fitted to the same data.
- Resampling now draws each replicate from its own L’Ecuyer-CMRG
  substream. A loop drawing from a single stream produces replicate `b`
  only after replicates `1` to `b-1` have drawn theirs, so its content
  depends on the order the loop ran. That is harmless while everything
  is serial and stops being harmless the moment any part is distributed
  or resumed, at which point the same seed yields different replicates
  and a published interval becomes irreproducible for a reason the
  reader cannot see. `parallel` is now imported for `nextRNGStream()`.

### Correction: permuco is not admissible for split-plot, split-split and strip-plot

[`permuco::aovperm`](https://rdrr.io/pkg/permuco/man/aovperm.html)
implements the repeated-measures `Error(subject/within)` form, in which
each subject contributes one observation per within-cell. It does not
implement the hierarchical field strata of a split-plot experiment,
where every whole plot carries several sub-units. Applied to
`split_plot`, `split_split` or `strip_plot`, it silently collapses the
strata: the sub-plot stratum is never built, and the terms that belong
to it are tested against the whole-plot mean square, which is ten to
thirteen times larger than the correct one.

**The resulting error is a false negative, not a false positive.** The
p-values are conservative, not anticonservative. This is a small
consolation, because the failure does not invent effects, it erases
them. Anyone re-examining an earlier analysis should re-examine the
terms that came out **non-significant**, not the ones that came out
significant. In a simulation with a true sub-plot effect, base `aov`
returned p = 0.030 while permuco returned p = 0.713 on identical ranks.

[`agri_rank()`](https://wep69.github.io/agriRank/reference/agri_rank.md)
and the shortcut wrappers now refuse permuco for these three designs
with an explicit error message directing the user to ART, which
reproduces the correct strata. The automatic routing for `split_plot`,
`split_split` and `strip_plot` now always selects ARTool. Note that
permuco was previously the **first** automatic choice for split-plot and
split-split, so the default path was affected, not only explicit calls.
This correction may invalidate previously published permuco-based
analyses of these designs.

Verification: 300 calibration replicas under a true null. The permuco
path did not reject the sub-plot or sub-sub-plot factor **once** at
either the 5% or the 10% level, and the smallest p-value observed for
the sub-sub-plot factor across 300 experiments was 0.18, so no dataset
in that design could have produced a claim of significance.
Kolmogorov-Smirnov against the uniform gave D = 0.54 and D = 0.49. ART
is calibrated on all three terms, with one honest caveat: the whole-plot
factor rejects at 0.023 against a nominal 0.05, slightly conservative,
which is expected with only three residual degrees of freedom in that
stratum and is improved by more blocks rather than by another engine.
See `PERMUCO_ISOLAMENTO.md` and `PERMUCO_PENDENCIAS.md`.

The defect survived two releases because no test compared the residual
degrees of freedom of each stratum against `aov`. That test now exists,
in `tests/testthat/test-strata-df.R`.

### Experiments whose datum is not a measurement

Every other module in the package analyses a measurement. These two
cover the agronomic experiments that do not produce one, and in both
cases the usual practice reports a quantity the data do not contain.

- Added
  [`agri_np_timetoevent()`](https://wep69.github.io/agriRank/reference/agri_np_timetoevent.md)
  for germination, emergence and flowering trials. Such data are counted
  inside intervals: a seed that germinated between two inspections is
  known only to have done so somewhere inside that interval, and a seed
  that never germinates is not a missing value but an observation
  censored at the end of the trial. The common route, fitting a curve to
  cumulative germination percentages, assumes at once that the event
  time was observed, that successive cumulative values are independent
  when each contains all the earlier ones, and that the lot eventually
  reaches 100%. The nonparametric maximum likelihood estimator used here
  does none of those: it treats the intervals as intervals, assumes no
  functional form, and leaves probability mass on “never”. Parametric
  germination models are deliberately not offered.
- [`agri_np_timetoevent()`](https://wep69.github.io/agriRank/reference/agri_np_timetoevent.md)
  separates the two properties of a seed lot that a single number cannot
  carry. **Capacity** is `responded`, the share of the lot that responds
  at all. **Speed** is the quantiles, reported twice: `*_responders`
  among the subjects that did respond, which always exists, and `*_lot`
  on the whole lot, which is `NA` when the lot never reaches that share.
  A lot in which 32% of seeds germinate has no median germination time,
  and the `NA` is the result rather than a failure. Omitting the
  censored rows is detected and warned about, because the difference
  between “did not germinate” and “was not recorded” is the whole
  finding.
- The comparison of curves is a permutation test on rank scores, with
  `units =` naming the dish, tray or plot. Seeds sharing a dish share
  its water, temperature and handling, so permuting individual seeds
  would treat 100 seeds as 100 independent replicates. The function
  warns when `units` is omitted rather than quietly returning the
  anticonservative p-value.
- Added
  [`agri_rankings()`](https://wep69.github.io/agriRank/reference/agri_rankings.md),
  the bridge to on-farm and tricot trials, and a window onto the ranks
  that Friedman and Conover already compute internally. It accepts a
  measured blocked experiment or rankings supplied directly, and reports
  mean rank, rank sum, wins, and the pairwise record of which item was
  placed above which, with a sign test on the blocks that separated each
  pair.
- [`agri_rankings()`](https://wep69.github.io/agriRank/reference/agri_rankings.md)
  makes **completeness** decide what is admissible. A classical blocked
  trial is complete, so rank sums are comparable and the Friedman-type
  machinery applies. An on-farm trial is usually incomplete, each farmer
  ranking three varieties out of many, and then an item allocated to
  favourable farms collects flattering ranks for a reason that has
  nothing to do with the item. The function detects this, reports it,
  withholds `rank_sum` and cautions about `mean_rank`. What survives is
  the pairwise record, because each comparison is made inside one block;
  its `blocks` column shows when a comparison rests on one or two farms.
- Plackett-Luce worth is offered as a clearly labelled model-based
  companion when the `PlackettLuce` package is installed, and its
  absence changes nothing else. It is a likelihood model for rankings
  rather than a distribution-free summary, and that assumption is what
  allows incomplete rankings to be combined onto a single scale; where
  it and the pairwise record disagree, the assumption is doing the work.
- Added the vignette *Time-to-Event and Ranking Data*, which owns this
  block.
- Added drcte to Suggests. `PlackettLuce` is used only if present and is
  not declared, because its own dependency chain currently requires a
  Rust toolchain.

### Regression: what to recommend, for whom, and how the block enters

Three additions that sit between a fitted curve and an agronomic
recommendation. All are nonparametric: no response function is assumed,
no plateau model is fitted, and no distribution is claimed for the
response.

- Added
  [`agri_np_optimum_test()`](https://wep69.github.io/agriRank/reference/agri_np_optimum_test.md).
  [`agri_np_optimum()`](https://wep69.github.io/agriRank/reference/agri_np_optimum.md)
  returns a point, and a point is not a recommendation. This function
  resamples the **location** of the optimum rather than the height of
  the curve, which is a different and harder quantity: a curve can be
  estimated precisely while the position of its maximum wanders widely,
  and a plateau is exactly the shape that makes that happen. The
  resampling is the package’s own cluster bootstrap, so whole blocks are
  resampled and the declared randomization is respected. `p_boundary`
  reports the share of replicates whose optimum lands on an end of the
  searched range, and `identified` turns `FALSE` when that share reaches
  one half, at which point the function says there is no rate to report
  and points to
  [`agri_np_significant_slope()`](https://wep69.github.io/agriRank/reference/agri_np_sizer.md)
  instead. With `by =`, every pair of levels is compared through the
  bootstrap distribution of the difference between their optima,
  computed inside the same resampling loop so that both optima of a
  replicate come from the same resampled experiment; the p-value carries
  the Davison and Hinkley correction, so its smallest attainable value
  is `2/(B+1)` rather than a misleading zero. When `npregfast` is
  installed,
  [`npregfast::critical()`](https://rdrr.io/pkg/npregfast/man/critical.html)
  is reported alongside as an independent check, flagged as a comparison
  because it resamples rows and ignores the block.
- [`agri_np_optimum_test()`](https://wep69.github.io/agriRank/reference/agri_np_optimum_test.md)
  refuses to compare optima across curves that the model has forced to
  be parallel. A qualitative predictor entering additively shifts one
  curve above another without changing its shape, so the levels share
  one optimum by construction and a comparison would report a difference
  of exactly zero with a p-value of one, describing the model rather
  than the experiment. The condition is detected from the fitted curves
  themselves, so it works for every engine.
- Added `gam_structure = "varying"` to
  [`agri_np_regression()`](https://wep69.github.io/agriRank/reference/agri_np_regression.md),
  which fits one smooth of the focal numeric predictor per level of a
  qualitative predictor. The **shape** of the response may then differ
  between cultivars, seasons or sites, and each level can have its own
  optimum. The basis dimension is limited by the level with the fewest
  distinct predictor values, not by the whole data set, and the function
  refuses rather than overfits when a level is too sparse.
- Added `method = "smooth_quantile"`, a calibrated additive quantile
  regression through `qgam`. Every other curve in the package describes
  a central tendency, which is a strong restriction on the agronomic
  question it can answer: a treatment can lift the good plots without
  lifting the poor ones, the mean rises either way, and a recommendation
  built on it disappoints exactly the growers whose fields resemble the
  poor plots. The fit is defined by the pinball loss, so nothing is
  assumed about the shape of the response distribution. Analytic
  intervals from this engine are now recognized by
  `agri_np_predict(interval = "confidence")`.
- Added
  [`agri_np_quantile_curves()`](https://wep69.github.io/agriRank/reference/agri_np_quantile_curves.md),
  a fan of smooth conditional quantiles with its own table and two
  figures. The low quantile is the exposure curve, what a grower meets
  in a bad year; the distance between the outer quantiles is the risk,
  and a treatment that widens it is buying its average gain with
  variability. `coverage` and `deviation` check each curve against the
  share of plots that actually fall below it, and `tracking` flags a
  quantile the experiment cannot resolve. Curves are fitted
  independently, so crossings are counted and reported rather than
  silently repaired, because a crossing is evidence that the quantiles
  are not separately identified there. A quantile too far into the tail
  for the replication available is refused.
- Added `block_effect = c("fixed", "shrunk")` to
  [`agri_np_regression()`](https://wep69.github.io/agriRank/reference/agri_np_regression.md),
  for `gam`, `scam` and `smooth_quantile`. Fixed, the default, estimates
  one free effect per block and assumes nothing about how blocks relate
  to each other, but those effects exist only for the blocks that were
  observed. Shrunk replaces them by a penalized term whose effects are
  pulled towards their common mean by an amount the data choose, which
  is what makes prediction into an unobserved field or year possible at
  all. The response curve stays nonparametric under both; the argument
  concerns only the nuisance structure. An engine that cannot carry a
  penalized term says so instead of ignoring the request.
- Added
  [`agri_np_block_effects()`](https://wep69.github.io/agriRank/reference/agri_np_block_effects.md),
  which reports every block effect as estimated both ways, with the raw
  block mean beside them and the proportional `shrinkage` between.
  Effects are computed on the response scale by predicting at one common
  covariate setting and varying only the block, so the result is
  engine-agnostic and does not depend on reading basis coefficients. The
  accompanying figure shows how far each block travels, which is the
  amount of between-block variation the data attribute to noise.
- Added the vignette *Optima, Quantiles, and How the Block Enters the
  Model*, which owns this block. It pairs the shrunk block term, the
  model-based route to a new field, with
  `agri_np_conformal(scope = "new_block")`, the assumption-free route,
  and argues that both should be reported: when they disagree, the
  assumption is doing work the data do not support.
- Added npregfast and qgam to Suggests. Both are optional.

### Regression: distribution-free uncertainty and model checking

This release adds the three tools that the regression module was missing
to support an agronomic recommendation rather than merely produce one.
All three are distribution free, all three return tables and ggplot
figures, and all three refuse to answer questions the data cannot
support instead of returning a number anyway.

- Added
  [`agri_np_sizer()`](https://wep69.github.io/agriRank/reference/agri_np_sizer.md)
  and
  [`agri_np_significant_slope()`](https://wep69.github.io/agriRank/reference/agri_np_sizer.md),
  an adapter to the SiZer map of Chaudhuri and Marron (1999). The
  derivative of the fitted curve is classified as significantly
  increasing, significantly decreasing, indistinguishable from flat, or
  sparse, at every position of the gradient and across a column of
  bandwidths.
  [`agri_np_significant_slope()`](https://wep69.github.io/agriRank/reference/agri_np_sizer.md)
  converts the map into the sentence a manuscript can carry: the
  interval over which the response is still rising, at a stated level of
  agreement across bandwidths. This is the honest alternative to
  [`agri_np_optimum()`](https://wep69.github.io/agriRank/reference/agri_np_optimum.md)
  when the fitted maximum lands on the boundary of the tested range,
  which happens whenever a response plateaus. Bandwidths are reported on
  the scale of the predictor so they can be judged agronomically. An
  integer-support fit is refused by name, pointing to
  [`agri_integer_difference()`](https://wep69.github.io/agriRank/reference/agri_integer_difference.md),
  because a derivative is not an admissible quantity on a discrete
  support.
- Added
  [`agri_np_conformal()`](https://wep69.github.io/agriRank/reference/agri_np_conformal.md)
  and
  [`agri_np_coverage()`](https://wep69.github.io/agriRank/reference/agri_np_conformal.md),
  a native split-conformal predictor. The returned interval covers a
  **future plot**, not the fitted curve, with finite-sample marginal
  coverage under exchangeability alone, for any engine and any response
  distribution. The finite-sample correction is applied explicitly. Two
  scopes are offered because they answer different questions:
  `scope = "within_block"` splits inside blocks and keeps the block
  term, for a future plot in an observed block; `scope = "new_block"`
  holds out whole blocks and refits without the block term, for a future
  plot in a field or year that was not observed. The second is a
  stronger claim and yields a wider interval. `normalize = TRUE`
  redistributes the width along the gradient, wider where the response
  is noisier, without changing what is guaranteed.
  [`agri_np_coverage()`](https://wep69.github.io/agriRank/reference/agri_np_conformal.md)
  reports empirical coverage overall and per block.
- Added
  [`agri_np_simdiag()`](https://wep69.github.io/agriRank/reference/agri_np_simdiag.md),
  simulation-based quantile residuals in the sense of Dunn and Smyth
  (1996). Simulations come from agriRank’s own residual resampling,
  which keeps the reference distribution empirical; when DHARMa is
  installed its scaling machinery is applied to those simulations. Three
  checks are reported with the question each answers: overall
  uniformity, systematic location error along the gradient, and change
  of dispersion along the gradient. The location check uses a binned
  Kruskal-Wallis comparison rather than a rank correlation, because
  misfit from a wrong shape is typically non-monotone and a rank
  correlation has no power against it.
- Added the vignette *Distribution-Free Uncertainty and Model Checking
  for Agronomic Regression*, which owns this block. It contrasts the
  three kinds of interval the package can produce, demonstrates that the
  marginal uniformity check does not distinguish a plateau-following fit
  from a straight line while the location check does, and repeats the
  whole workflow on a real precision-agriculture maize trial from
  `agridat`, where the tools correctly report that no nitrogen rate is
  supported.
- Fixed a ties warning in the normalized conformal interval: the local
  dispersion smooth is now de-duplicated before interpolation, through a
  single shared helper used by both the calibration and the prediction
  side.
- Added SiZer, DHARMa and agridat to Suggests. All three are optional;
  every function degrades to a named message rather than an error when
  its backend is absent.

### Regression: uncertainty, explained variation and graphics

- Added the standard extractors
  [`coef()`](https://rdrr.io/r/stats/coef.html),
  [`confint()`](https://rdrr.io/r/stats/confint.html),
  [`fitted()`](https://rdrr.io/r/stats/fitted.values.html) and
  [`residuals()`](https://rdrr.io/r/stats/residuals.html) for
  `agri_np_reg_fit`. Coefficients are returned for `theil_sen`, `siegel`
  and `quantile`; the smoothers refuse them by name, because reporting
  spline basis coefficients as agronomic slopes would invite a reading
  the model does not support.
- [`confint()`](https://rdrr.io/r/stats/confint.html) prefers the
  interval published by the backend and falls back to the cluster-aware
  bootstrap. The two usually differ, and the difference is the point:
  one relies on the asymptotic theory of the estimator, the other only
  on the legitimacy of resampling experimental units.
- [`agri_np_bootstrap()`](https://wep69.github.io/agriRank/reference/agri_np_bootstrap.md)
  gains `target = "coefficients"` for intervals of the coefficient
  vector, `band = "simultaneous"` for a sup-t band that covers the whole
  curve rather than each point, and `keep_replicates` for the replicate
  matrix, which allows a histogram of a slope or a cloud of fitted
  curves.
- [`agri_np_diagnostics()`](https://wep69.github.io/agriRank/reference/agri_np_diagnostics.md)
  reports three explained-variation indices with the effective degrees
  of freedom beside them: `pseudo_r2` computed on the fitted values,
  `cv_r2` computed out of fold and available with `cv = TRUE`, and
  `spearman_r2` from the ranks. They can disagree, and the disagreement
  is informative: a LOESS fit typically shows a larger `pseudo_r2`, a
  larger `effective_df` and a smaller `cv_r2` than a smoothing spline on
  the same data.
- [`agri_np_plot()`](https://wep69.github.io/agriRank/reference/agri_np_plot.md)
  gains the residual diagnostics `"qq"`, `"scale_location"` and
  `"order"`, the integer decision figures `"efficiency"` and
  `"difference"`, and a `bootstrap` argument that draws a resampling
  band for engines with no analytic interval.
- Added plot methods for `agri_np_bootstrap`, `agri_np_compare`,
  `agri_integer_bootstrap` and `agri_integer_confset`, which previously
  could only be printed. The integer figures show the probability mass
  over admissible decisions and fade, rather than remove, the decisions
  outside the confidence set.
- Added
  [`agri_np_curves()`](https://wep69.github.io/agriRank/reference/agri_np_curves.md),
  which overlays the fitted curves of several engines over the observed
  points.
- An integer-support fit is now drawn as steps and crosses instead of a
  continuous line, which no longer suggests that a value exists between
  two admissible decisions.

### Regression: qualitative factors and coefficient forest plots

- [`agri_np_regression()`](https://wep69.github.io/agriRank/reference/agri_np_regression.md)
  now treats qualitative predictors explicitly: a character column is
  read as the factor it is, a factor needs at least two levels to enter
  a model, and the fitted object records its qualitative predictors.
  Quantile, kernel, GAM and SCAM engines keep a factor as an adjustment
  term; curve-only engines refuse factors by name instead of silently
  dropping them.
- The coefficient bootstrap aligns replicates by term name, so a
  reordered or level-depleted replicate is counted as a failed refit
  instead of being read in the original order. Block adjustment terms
  are excluded from the coefficient target because they are nuisance
  parameters whose meaning changes with every draw of the blocks; a
  block-adjusted fit therefore reports intervals for the scientific
  coefficients of the declared formula.
- Added
  [`agri_np_forest()`](https://wep69.github.io/agriRank/reference/agri_np_forest.md),
  a forest plot of bootstrap intervals for regression coefficients. With
  qualitative predictors it stacks one row per factor level inside the
  factor’s own panel and draws the reference level at zero, so every
  level appears in the figure instead of only the dummy contrasts.
  [`agri_np_plot()`](https://wep69.github.io/agriRank/reference/agri_np_plot.md)
  reaches the same figure through `type = "forest"`.

### Regression: journal-oriented tables, figures and export

- Added
  [`agri_np_levels()`](https://wep69.github.io/agriRank/reference/agri_np_levels.md)
  and `agri_np_plot(type = "levels")`: the response at every level of
  the qualitative predictors, with the observed sample size, median/MAD
  and mean/sd beside the fitted marginal response and its pointwise
  bootstrap interval. It is the level-oriented companion of the
  coefficient forest plot: coefficients state contrasts against the
  reference level, this summary states what the model predicts at each
  level itself.
- [`agri_table()`](https://wep69.github.io/agriRank/reference/agri_table.md)
  gains `"coefficients"` and `"levels"` for regression fits, so a table
  presented in a manuscript carries the uncertainty of every estimate it
  reports.
- `agri_np_plot(type = "fit", group = ..., bootstrap = ...)` now draws
  one resampling band per level of the grouping variable, computed in a
  single bootstrap loop over the combined grid. Observed values, fitted
  curves and bands appear together for models with and without
  qualitative factors.
- Added
  [`agri_theme()`](https://wep69.github.io/agriRank/reference/agri_graphics.md),
  the common theme of the regression graphics: no minor gridlines, drawn
  axis lines, readable base size and a compact legend. Figures remain
  plain ggplot objects, so any layer can still be added or the theme
  replaced.
- Added
  [`agri_save_figure()`](https://wep69.github.io/agriRank/reference/agri_graphics.md),
  which writes a figure as TIFF (LZW), PDF, SVG, EPS or PNG at preset
  journal widths (one column, middle, full), keeping text and lines
  editable in the vector formats.

### Regression: colour vision, annotation and rich reports

- [`agri_np_plot()`](https://wep69.github.io/agriRank/reference/agri_np_plot.md)
  gains `palette = "color" | "grey"` for group curves, `x_unit` /
  `y_unit` to append SI-style units to the default axis labels, and a
  clean separation between the public wrapper and the internal drawing
  function. Grouped plots now carry colour-blind-safe Okabe-Ito colour
  by default, and grey tones safe for black-and-white print when
  requested.
- [`agri_np_forest()`](https://wep69.github.io/agriRank/reference/agri_np_forest.md)
  gains `annotate_values` (write the interval as text to the right of
  each bar), `digits` for annotation and axis formatting,
  `order_by = "effect"` to sort rows by absolute estimate within each
  panel, and `ref_line` to move the vertical reference line.
- A warning is raised once per session when `B < 999`, to remind authors
  that a small number of bootstrap replicates is a speed device and that
  final inference needs `B >= 999`. Silence with
  `options(agriRank.quiet_small_B = TRUE)`.
- [`agri_report()`](https://wep69.github.io/agriRank/reference/agri_report.md)
  now writes a richer markdown regression report: the coefficient table
  with confidence intervals, the qualitative-factor structure, the level
  summary, one fit, forest and level figure rendered at 300 dpi
  alongside the report, and a “How to cite” section with
  `citation("agriRank")`.

### Regression: small increments

- Added
  [`agri_format_ci()`](https://wep69.github.io/agriRank/reference/agri_format_ci.md)
  to format an estimate and its interval as `"1.06 (0.68; 1.47)"` for
  direct use in manuscript text.
- [`agri_np_plot()`](https://wep69.github.io/agriRank/reference/agri_np_plot.md)
  gains `jitter = TRUE` to spread overlapping observed values in
  dose-response plots.
- [`agri_np_forest()`](https://wep69.github.io/agriRank/reference/agri_np_forest.md)
  gains a `caption` parameter with a default explanation of the
  reference level.
- `print.agri_np_reg_fit()` now reports the reference level of each
  qualitative predictor and reminds that coefficients are contrasts
  against it.
- [`agri_table()`](https://wep69.github.io/agriRank/reference/agri_table.md)
  gains `format = "rtf"` for direct RTF export via
  [`gt::gtsave()`](https://gt.rstudio.com/reference/gtsave.html) into
  Word or LibreOffice.
- Added a Quarto template at `inst/templates/regression-report.qmd` for
  the regression report.
- Added a brief note in vignette v16 on figure editability: every
  agriRank figure is a `ggplot` object; every table a data frame.

### Integrated tutorial (English and Portuguese)

- Added vignette `v18-integrated-tutorial`, the English version of the
  integrated tutorial: qualitative designs (CRD, RCBD, factorial,
  split-plot with CLD and figures), quantitative regression (fit,
  bootstrap bands, diagnostics, derivative, optimum, engine comparison),
  qualitative + quantitative (levels with confidence intervals, forest
  and grouped curves), and integer ordinal factors (the four integer
  engines, fit-quality metrics with R-squared/RMSE/MAE/MAD, optimum,
  thresholds and the bootstrap confidence set of the optimum).
- The Portuguese version ships as a standalone Quarto document in the
  repository’s `cheatsheet/` directory (`agriRank_Tutorial_PT.qmd` and a
  self-contained HTML rendering), beside the English one
  (`agriRank_Tutorial_EN.qmd` and HTML) and the existing cheatsheets.
- The tutorial uses
  [`simulate_agri()`](https://wep69.github.io/agriRank/reference/simulate_agri.md)
  throughout with fixed seeds chosen so the effects are real (the CLD
  letters differ), `B = 1000` in every resampling, integer-only axis
  breaks for the density factor, and fit-quality tables whose numbers
  are read from the fitted objects.

### Example data and documentation

- Added three exported data sets: `agri_dose` (nitrogen rates in an
  RCBD, quadratic-plateau response), `agri_density` (plants per hill, an
  integer treatment with a unimodal response) and `agri_surface`
  (nitrogen by irrigation depth with a positive cross term). The
  generating script is in `data-raw/`.
- Added the quantitative-gradient scenarios `"dose_response"`,
  `"integer_density"` and `"surface"` to
  [`simulate_agri()`](https://wep69.github.io/agriRank/reference/simulate_agri.md),
  mirroring the exported data sets for users who need fresh replicates.
- Rewrote the examples of all 18 regression functions to use the
  exported data, to state units (Mg ha⁻¹, kg ha⁻¹) and to end in an
  agronomic reading rather than a bare call. Fitted objects now persist
  after the examples run.
- Examples with resampling state explicitly that `B = 19` is a speed
  device and that analysis needs `B >= 999`.
- Compact letter displays are now available on **every** comparison
  route, not only Conover:
  [`agri_pairs()`](https://wep69.github.io/agriRank/reference/agri_pairs.md)
  and
  [`agri_conover()`](https://wep69.github.io/agriRank/reference/agri_conover.md)
  gain `cld` and `alpha`, and
  [`agri_cld()`](https://wep69.github.io/agriRank/reference/agri_cld.md)
  accepts a comparison table produced by either one.
- The simultaneous max-T contrasts of the native repeated wild-rank
  engine are covered as well. Their labels of the form
  `"stratum: g1 - g2"` are parsed back into groups, and the adjusted
  `p_adjusted_maxT` column is used.
- Letters are computed within each simple-effect stratum, because groups
  compared in different strata were never tested against each other.
- An incomplete family of comparisons, or a user-defined contrast that
  is not a simple difference between two groups, is refused with an
  explicit message instead of being summarized into letters that would
  imply comparisons the analysis never performed.

### Fixes

- [`agri_np_predict()`](https://wep69.github.io/agriRank/reference/agri_np_predict.md)
  now names the missing variable when `newdata` omits a predictor or the
  declared block, instead of failing inside the backend with an
  unresolved symbol.
- The Friedman-type Conover adapter no longer fails with a data-frame
  subscript error when block rankings agree perfectly; it warns and
  reports no comparison for that stratum.
- [`np_repeated()`](https://wep69.github.io/agriRank/reference/np_repeated.md)
  without `subject=` and
  [`agri_multienv()`](https://wep69.github.io/agriRank/reference/agri_multienv.md)
  without `environment=` now fail with the scientific reason.
- The rankFD adapter populates the standardized omnibus table, which had
  been empty and silently disabled
  [`agri_table()`](https://wep69.github.io/agriRank/reference/agri_table.md),
  [`agri_sensitivity()`](https://wep69.github.io/agriRank/reference/agri_sensitivity.md)
  and
  [`agri_batch()`](https://wep69.github.io/agriRank/reference/agri_batch.md)
  on that route.
- Replaced the deprecated
  [`ggplot2::aes_string()`](https://ggplot2.tidyverse.org/reference/aes_.html)
  in the interaction plot.
- Interactive Plotly widgets are no longer auto-printed in examples and
  vignettes, which avoids a headless-browser dependency and removed
  about 4 MB from the installed size.
- The `umbrella` adapter now centers the focal predictor before fitting
  with `cgam`: the umbrella cone construction in `cgam` is
  translation-sensitive, and with an all-positive covariate its mode
  search degenerates into a nearly constant fit that loses the
  increase-then-decrease peak, even on data with an unmistakable one.
  Centering makes the covariate range straddle zero and restores the
  intended shape; the shift is stored and re-applied to every prediction
  grid. The fitted response is unchanged by construction, because the
  shape term carries its own intercept.

## agriRank 0.12.0.9000

- Added explicit split-split hierarchy through `subsubplot=` and
  [`np_splitsplit()`](https://wep69.github.io/agriRank/reference/np_splitsplit.md).
- Added explicit strip-plot declarations through `strip_a=`, `strip_b=`
  and
  [`np_stripplot()`](https://wep69.github.io/agriRank/reference/np_stripplot.md).
- Added design-specific ARTool/permuco strata for split-split and
  strip-plot workflows.
- Reworked multivariate analysis into the common `agri_multivariate_fit`
  class with MANOVA, MANOVA.wide and multRM routing plus
  table/report/export integration.
- Enforced environment inclusion in multi-environment models;
  [`agri_multienv()`](https://wep69.github.io/agriRank/reference/agri_multienv.md)
  now injects the environment term (and, by default,
  treatment-by-environment interactions) when omitted.
- Added common reporting/export support for multivariate, ANCOVA,
  ordered-trend and power objects.
- `confint.agri_rank_fit()` now fails explicitly when an engine-specific
  confidence interval is unavailable instead of returning non-interval
  summaries.
- Updated package citation version and local validation runner default.

## agriRank 0.11.0.9000

### Integer-support nonparametric regression

- Added `discrete_kernel`, `unimodal_isotonic`, `umbrella`, and
  `integer_grid` regression pathways for integer-valued agronomic
  predictors such as plant counts and insect densities.
- Added explicit decision supports: observed integers, every integer in
  a range, or a custom set of admissible integers.
- Added
  [`agri_integer_predict()`](https://wep69.github.io/agriRank/reference/agri_integer_predict.md),
  [`agri_integer_difference()`](https://wep69.github.io/agriRank/reference/agri_integer_difference.md),
  [`agri_integer_optimum()`](https://wep69.github.io/agriRank/reference/agri_integer_optimum.md),
  [`agri_integer_efficiency()`](https://wep69.github.io/agriRank/reference/agri_integer_efficiency.md),
  [`agri_integer_threshold()`](https://wep69.github.io/agriRank/reference/agri_integer_threshold.md),
  [`agri_integer_bootstrap()`](https://wep69.github.io/agriRank/reference/agri_integer_bootstrap.md),
  and
  [`agri_integer_confset()`](https://wep69.github.io/agriRank/reference/agri_integer_confset.md).
- Integer-support fits reject fractional predictions and decisions
  outside the declared support.
- Instantaneous derivatives are replaced by finite differences for
  integer-support fits.
- Added ordered-discrete kernels through `np`, unimodal isotonic
  regression through `Iso`, umbrella-order regression through `cgam`,
  and integer-grid decision projection for flexible continuous latent
  models.
- Added a dedicated state-of-the-art vignette, manual section,
  references, and validation tests for integer-support inference.

## agriRank 0.10.0.9000

### Conover multiple comparisons

- Added
  [`agri_conover()`](https://wep69.github.io/agriRank/reference/agri_conover.md)
  and `agri_pairs(method = "conover")`.
- Added Kruskal-type Conover all-pairs comparisons for independent
  one-way/CRD data.
- Added Friedman-type Conover all-pairs comparisons for complete
  unreplicated RCBD data while preserving blocks.
- Added raw and multiplicity-adjusted p-values to the unified output.
- Added explicit rejection of incomplete or replicated RCBD cells for
  the classical Friedman-Conover adapter.

### Nonparametric regression for Agronomy

- Added
  [`agri_np_regression()`](https://wep69.github.io/agriRank/reference/agri_np_regression.md),
  [`agri_np_predict()`](https://wep69.github.io/agriRank/reference/agri_np_predict.md),
  [`agri_np_diagnostics()`](https://wep69.github.io/agriRank/reference/agri_np_diagnostics.md),
  [`agri_np_compare()`](https://wep69.github.io/agriRank/reference/agri_np_compare.md),
  [`agri_np_derivative()`](https://wep69.github.io/agriRank/reference/agri_np_derivative.md),
  [`agri_np_optimum()`](https://wep69.github.io/agriRank/reference/agri_np_optimum.md),
  [`agri_np_bootstrap()`](https://wep69.github.io/agriRank/reference/agri_np_bootstrap.md),
  [`agri_np_plot()`](https://wep69.github.io/agriRank/reference/agri_np_plot.md),
  [`agri_np_interactive()`](https://wep69.github.io/agriRank/reference/agri_np_interactive.md),
  [`agri_np_significance()`](https://wep69.github.io/agriRank/reference/agri_np_significance.md),
  and
  [`agri_np_specification()`](https://wep69.github.io/agriRank/reference/agri_np_specification.md).
- Added LOESS, smoothing splines, mixed-data kernel regression, isotonic
  regression, and constrained quantile B-splines as the strict
  nonparametric core.
- Added Theil-Sen/Siegel median regression, quantile regression, GAM and
  shape-constrained GAM as explicitly labelled robust/semiparametric
  companions.
- Added design-aware block adjustment for compatible engines and
  explicit rejection when a selected engine would discard a declared
  block.
- Added cross-validated predictive comparison, numerical derivatives,
  descriptive fitted optima, block/cluster bootstrap bands, grouped
  curves, two-dimensional response surfaces, ggplot2 graphics and Plotly
  exploration.
- Added mixed-data kernel predictor significance testing through
  [`np::npsigtest()`](https://rdrr.io/pkg/np/man/np.sigtest.html) and a
  consistent nonparametric specification test for prespecified Gaussian
  linear/polynomial models through
  [`np::npcmstest()`](https://rdrr.io/pkg/np/man/np.cmstest.html).
- Added safeguards preventing silently ignored shape constraints,
  unsupported observation weights, and automatic regression of
  repeated/longitudinal `agri_design` objects without a validated
  subject-dependence adapter.
- Added a 17th English vignette devoted to state-of-the-art
  nonparametric regression for agronomic gradients.
- Added three or more documented examples for every newly exported
  function and extended the double-verified reference library.

## agriRank 0.9.1.9000

### Documentation overhaul

- Replaced the initial vignette set with 16 English analytical
  vignettes.
- Added dedicated state-of-the-art coverage for factorial rank
  inference, pseudo-ranks, restricted permutation, repeated
  measurements, wild bootstrap, and incomplete repeated data.
- Added a complete integrated agronomic case study.
- Added one dedicated `.Rd` page and at least three examples for every
  exported function.
- Added a long-form English reference manual and documentation coverage
  manifest.
- Added double-verified bibliographic metadata and a verified RIS file.
- Documented the methodological boundary for blocked incomplete repeated
  measurements and the experimental status of the native wild-rank
  engine.
- Clarified that
  [`agri_ancova()`](https://wep69.github.io/agriRank/reference/agri_ancova.md)
  currently implements a Freedman-Lane permutation adapter and does not
  claim the 2026 resampling NANCOVA method.

## agriRank 0.9.0.9000

- Added design-aware objects for CRD, RCBD, factorial, split-plot,
  repeated/longitudinal, multi-environment and multivariate workflows.
- Added adapters for rankFD, ARTool, permuco, nparLD and MANOVA.RM.
- Added native experimental WTS/ATS/MATS wild-bootstrap rank engine for
  incomplete repeated measurements following Amro, Konietschke & Pauly
  (2024).
- Added missingness characterization and all-available versus
  complete-subject sensitivity analysis.
- Added effect sizes, pairwise comparisons, native repeated max-T
  contrasts, CLD, batch workflows, simulation-based power, trend tests,
  ggplot2/Plotly graphics and report generation.
