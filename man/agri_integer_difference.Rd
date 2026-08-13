\name{agri_integer_difference}
\alias{agri_integer_difference}
\title{Finite differences for integer-valued agronomic decisions}
\usage{agri_integer_difference(object, order = 1L, fixed = list())}
\arguments{
\item{object}{An integer-support regression fit.}
\item{order}{Difference order, 1 or 2.}
\item{fixed}{Named values for other covariates.}
}
\description{Computes finite changes in fitted response rather than an instantaneous derivative that has no direct operational interpretation for counts such as plants or insects.}
\details{
For adjacent admissible values \eqn{x_j<x_{j+1}}, the first finite difference is
\deqn{\Delta \hat m_j = \hat m(x_{j+1})-\hat m(x_j).}
The function also reports the change per integer step. For unit-spaced supports, the second difference is
\deqn{\Delta^2\hat m_j=\hat m(x_{j+1})-2\hat m(x_j)+\hat m(x_{j-1}).}
}
\value{A data frame of first or second finite differences.}
\examples{
d <- data.frame(plants = rep(1:7, each = 4))
set.seed(302); d$yield <- 10 + 7*d$plants - .55*d$plants^2 + rnorm(nrow(d))
fit <- agri_np_regression(yield ~ plants, d, method = "integer_grid",
  integer_base_method = "smoothing_spline", predictor_support = "integer_range")
agri_integer_difference(fit, order = 1)

agri_integer_difference(fit, order = 2)

d2 <- subset(d, plants \%in\% c(1,3,5,7))
fit2 <- agri_np_regression(yield ~ plants, d2, method = "integer_grid",
  integer_base_method = "smoothing_spline", predictor_support = "observed_integer")
agri_integer_difference(fit2, order = 1)
}
