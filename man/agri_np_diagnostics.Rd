\name{agri_np_diagnostics}
\alias{agri_np_diagnostics}
\title{Diagnostics for nonparametric regression}
\usage{agri_np_diagnostics(object)}
\arguments{\item{object}{An \code{agri_np_reg_fit}.}}
\description{Summarizes residual behavior, predictive error, missing responses, and engine-specific smoothing information.}
\details{The diagnostics are descriptive. They should not be used as an automatic significance-driven model-selection rule.}
\value{A list containing error metrics, residual summaries, residual-fitted rank association and method-specific details.}
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
}
