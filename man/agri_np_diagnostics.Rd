\name{agri_np_diagnostics}
\alias{agri_np_diagnostics}
\title{Diagnostics for nonparametric regression}
\usage{agri_np_diagnostics(object)}
\arguments{\item{object}{An \code{agri_np_reg_fit}.}}
\description{Summarizes residual behavior, predictive error, missing responses, and engine-specific smoothing information.}
\details{The diagnostics are descriptive. They should not be used as an automatic significance-driven model-selection rule.}
\value{A list containing error metrics, residual summaries, residual-fitted rank association and method-specific details.}
\examples{
set.seed(32)
d <- data.frame(dose = 1:40); d$y <- log1p(d$dose) + rnorm(40, 0, .15)
# Example 1
f1 <- agri_np_regression(y ~ dose, d, method = "smoothing_spline")
agri_np_diagnostics(f1)
# Example 2
f2 <- agri_np_regression(y ~ dose, d, method = "loess")
agri_np_diagnostics(f2)
# Example 3
f3 <- agri_np_regression(y ~ dose, d, method = "isotonic", shape = "increasing")
agri_np_diagnostics(f3)
}
