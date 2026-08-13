\name{agri_np_derivative}
\alias{agri_np_derivative}
\title{Estimate the derivative of a fitted agronomic response curve}
\usage{agri_np_derivative(object, predictor = NULL, n = 200L, fixed = list(), h = NULL)}
\arguments{
  \item{object}{An \code{agri_np_reg_fit}.}
  \item{predictor}{Numeric focal predictor.}
  \item{n}{Grid size.}
  \item{fixed}{Named values at which other covariates are held.}
  \item{h}{Finite-difference step; automatically selected by default.}
}
\description{Computes a numerical first derivative of the fitted conditional-response curve.}
\details{Derivative estimates near boundaries use the available one-sided span. Derivatives inherit all limitations of the fitted smoother and should be interpreted with uncertainty, especially near sparse regions.}
\value{A data frame containing predictor values and estimated derivatives.}
\examples{
set.seed(34)
d <- data.frame(dose = seq(0, 200, length.out = 50));
d$yield <- 6 + .06*d$dose - .0002*d$dose^2 + rnorm(50, 0, .4)
f <- agri_np_regression(yield ~ dose, d, method = "smoothing_spline")
# Example 1
head(agri_np_derivative(f))
# Example 2
agri_np_derivative(f, n = 50)
# Example 3
agri_np_derivative(f, h = 0.5)
}
