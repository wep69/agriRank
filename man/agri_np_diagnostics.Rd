\name{agri_np_diagnostics}
\alias{agri_np_diagnostics}
\title{Diagnostics for nonparametric regression}
\usage{agri_np_diagnostics(object, cv = FALSE, kfold = 5L, seed = 1)}
\arguments{
  \item{object}{An \code{agri_np_reg_fit}.}
  \item{cv}{If \code{TRUE}, the cross-validated coefficient of determination is computed, which requires refitting the engine \code{kfold} times.}
  \item{kfold}{Number of folds used when \code{cv = TRUE}.}
  \item{seed}{Random seed for the fold assignment.}
}
\description{Summarizes residual behavior, predictive error, explained variation, missing responses, and engine-specific smoothing information.}
\details{The diagnostics are descriptive. They should not be used as an automatic significance-driven model-selection rule.

The \code{r2} component reports three explained-variation indices, because they
answer different questions and can disagree:

\describe{
  \item{\code{pseudo_r2}}{\eqn{1 - SSE/SST} computed on the fitted values. It always improves when the smoother is made more flexible, so it must be read next to \code{effective_df}.}
  \item{\code{cv_r2}}{The same quantity computed from out-of-fold predictions. It does not improve through flexibility alone and is the honest index for comparing engines. Only computed when \code{cv = TRUE}.}
  \item{\code{spearman_r2}}{The squared rank correlation between observed and fitted values, coherent with the rank-based estimands used elsewhere in the package.}
}

None of them is the least-squares \eqn{R^2} of a linear model, and none should be
reported as if it were. A LOESS fit will typically show a higher
\code{pseudo_r2} and a lower \code{cv_r2} than a smoothing spline on the same
data, which is exactly the trade-off the two indices are meant to expose.}
\value{A list containing error metrics, the \code{r2} table with effective degrees of freedom, residual summaries, residual-fitted rank association and method-specific details.}
\examples{
data(agri_dose)

# Example 1: smoothing spline
f1 <- agri_np_regression(yield ~ dose, agri_dose, method = "smoothing_spline")
agri_np_diagnostics(f1)
# RMSE and MAE are in Mg/ha, the same unit as the response.

# Example 2: LOESS on the same data, for comparison
f2 <- agri_np_regression(yield ~ dose, agri_dose, method = "loess")
agri_np_diagnostics(f2)

# Example 3: a monotone constraint, which this response violates beyond the
# plateau. The diagnostics are descriptive: a larger residual error here is
# evidence that the declared shape does not match the agronomy, not a licence
# to select the engine by error alone.
f3 <- agri_np_regression(yield ~ dose, agri_dose, method = "isotonic",
                         shape = "increasing")
agri_np_diagnostics(f3)

# Example 4: the three explained-variation indices side by side
agri_np_diagnostics(f1, cv = TRUE, kfold = 5, seed = 1)$r2

# Example 5: flexibility inflates the fitted index but not the honest one
rbind(
  spline = agri_np_diagnostics(f1, cv = TRUE, seed = 1)$r2,
  loess  = agri_np_diagnostics(f2, cv = TRUE, seed = 1)$r2
)
# LOESS usually shows the larger pseudo_r2 and the larger effective_df, while
# cv_r2 tells which engine actually predicts an unseen plot better.
}
