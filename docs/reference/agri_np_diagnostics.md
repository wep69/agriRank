# Diagnostics for nonparametric regression

Summarizes residual behavior, predictive error, explained variation,
missing responses, and engine-specific smoothing information.

## Usage

``` r
agri_np_diagnostics(object, cv = FALSE, kfold = 5L, seed = 1,
                    cv_scope = c("within_block", "new_block"))
```

## Arguments

- object:

  An `agri_np_reg_fit`.

- cv:

  If `TRUE`, the cross-validated coefficient of determination is
  computed, which requires refitting the engine `kfold` times.

- kfold:

  Number of folds used when `cv = TRUE`.

- seed:

  Random seed for the fold assignment.

- cv_scope:

  With a declared block, which question `cv_r2` answers.
  `"within_block"` stratifies the folds and reports the error of
  predicting another plot in a block already observed; `"new_block"`
  holds out whole blocks and reports the error of predicting a block
  never seen. Identical in meaning and in wording to the argument of
  [`agri_np_compare`](https://wep69.github.io/agriRank/reference/agri_np_compare.md),
  so that the two cross-validation routines of the package answer the
  same question.

## Details

The diagnostics are descriptive. They should not be used as an automatic
significance-driven model-selection rule.

The `r2` component reports three explained-variation indices, because
they answer different questions and can disagree:

- `pseudo_r2`:

  \\1 - SSE/SST\\ computed on the fitted values. It always improves when
  the smoother is made more flexible, so it must be read next to
  `effective_df`.

- `cv_r2`:

  The same quantity computed from out-of-fold predictions. It does not
  improve through flexibility alone and is the honest index for
  comparing engines. Only computed when `cv = TRUE`.

- `spearman_r2`:

  The squared rank correlation between observed and fitted values,
  coherent with the rank-based estimands used elsewhere in the package.

None of them is the least-squares \\R^2\\ of a linear model, and none
should be reported as if it were. A LOESS fit will typically show a
higher `pseudo_r2` and a lower `cv_r2` than a smoothing spline on the
same data, which is exactly the trade-off the two indices are meant to
expose.

## Value

A list containing error metrics, the `r2` table with effective degrees
of freedom, residual summaries, residual-fitted rank association and
method-specific details.

## Examples

``` r
data(agri_dose)

# Example 1: smoothing spline
f1 <- agri_np_regression(yield ~ dose, agri_dose, method = "smoothing_spline")
agri_np_diagnostics(f1)
#> $method
#> [1] "smoothing_spline"
#> 
#> $metrics
#>    n      RMSE       MAE MedAE          bias  Spearman
#> 1 40 0.3623191 0.3128471 0.279 -1.432245e-15 0.8511985
#> 
#> $r2
#>   pseudo_r2 cv_r2 spearman_r2 effective_df  n
#> 1 0.8255341    NA   0.7245388     3.490987 40
#> 
#> $residual_median
#> [1] 0.04663906
#> 
#> $residual_MAD
#> [1] 0.4650825
#> 
#> $residual_fitted_spearman
#> [1] 0.03780826
#> 
#> $n_missing_response
#> [1] 0
#> 
#> $n_original
#> [1] 40
#> 
#> $n_omitted
#> [1] 0
#> 
#> $na_action
#> [1] "fail"
#> 
#> $details
#> $details$df
#> [1] 3.490987
#> 
#> $details$spar
#> [1] 0.4681114
#> 
#> 
# RMSE and MAE are in Mg/ha, the same unit as the response.

# Example 2: LOESS on the same data, for comparison
f2 <- agri_np_regression(yield ~ dose, agri_dose, method = "loess")
agri_np_diagnostics(f2)
#> $method
#> [1] "loess"
#> 
#> $metrics
#>    n     RMSE       MAE  MedAE         bias  Spearman
#> 1 40 0.358102 0.3093197 0.3055 -0.002435239 0.8511985
#> 
#> $r2
#>   pseudo_r2 cv_r2 spearman_r2 effective_df  n
#> 1 0.8295718    NA   0.7245388     4.449117 40
#> 
#> $residual_median
#> [1] 0.03307717
#> 
#> $residual_MAD
#> [1] 0.4245535
#> 
#> $residual_fitted_spearman
#> [1] -0.01134248
#> 
#> $n_missing_response
#> [1] 0
#> 
#> $n_original
#> [1] 40
#> 
#> $n_omitted
#> [1] 0
#> 
#> $na_action
#> [1] "fail"
#> 
#> $details
#> $details$enp
#> [1] 4.449117
#> 
#> $details$trace_hat
#> [1] 4.868615
#> 
#> 

# Example 3: a monotone constraint, which this response violates beyond the
# plateau. The diagnostics are descriptive: a larger residual error here is
# evidence that the declared shape does not match the agronomy, not a licence
# to select the engine by error alone.
f3 <- agri_np_regression(yield ~ dose, agri_dose, method = "isotonic",
                         shape = "increasing")
agri_np_diagnostics(f3)
#> $method
#> [1] "isotonic"
#> 
#> $metrics
#>    n      RMSE      MAE  MedAE         bias  Spearman
#> 1 40 0.3522095 0.305075 0.2975 -8.21623e-16 0.8670088
#> 
#> $r2
#>   pseudo_r2 cv_r2 spearman_r2 effective_df  n
#> 1 0.8351344    NA   0.7517042            7 40
#> 
#> $residual_median
#> [1] 0.0138
#> 
#> $residual_MAD
#> [1] 0.4570856
#> 
#> $residual_fitted_spearman
#> [1] 0.007607069
#> 
#> $n_missing_response
#> [1] 0
#> 
#> $n_original
#> [1] 40
#> 
#> $n_omitted
#> [1] 0
#> 
#> $na_action
#> [1] "fail"
#> 
#> $details
#> list()
#> 

# Example 4: the three explained-variation indices side by side
agri_np_diagnostics(f1, cv = TRUE, kfold = 5, seed = 1)$r2
#>   pseudo_r2     cv_r2 spearman_r2 effective_df  n
#> 1 0.8255341 0.7982628   0.7245388     3.490987 40

# Example 5: flexibility inflates the fitted index but not the honest one
rbind(
  spline = agri_np_diagnostics(f1, cv = TRUE, seed = 1)$r2,
  loess  = agri_np_diagnostics(f2, cv = TRUE, seed = 1)$r2
)
#>        pseudo_r2     cv_r2 spearman_r2 effective_df  n
#> spline 0.8255341 0.7982628   0.7245388     3.490987 40
#> loess  0.8295718 0.7931386   0.7245388     4.449117 40
# LOESS usually shows the larger pseudo_r2 and the larger effective_df, while
# cv_r2 tells which engine actually predicts an unseen plot better.
```
