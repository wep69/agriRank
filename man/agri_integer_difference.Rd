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
data(agri_density)
fit <- agri_np_regression(yield ~ plants, agri_density, method = "integer_grid",
                          integer_base_method = "smoothing_spline",
                          predictor_support = "observed_integer")

# Example 1: the yield gain, in Mg/ha, of adding one more plant per hill
agri_integer_difference(fit, order = 1)
# The row where the difference turns negative marks the density beyond which
# competition costs more than the extra plant contributes.

# Example 2: second differences, the rate at which that gain shrinks
agri_integer_difference(fit, order = 2)
# Consistently negative second differences describe a concave response.

# Example 3: when only alternate densities were tested, `delta_x` is 2 and
# `difference_per_integer` rescales the gain to a single plant.
d2 <- subset(agri_density, plants \%in\% c(1, 3, 5, 7, 9))
fit2 <- agri_np_regression(yield ~ plants, d2, method = "integer_grid",
                           integer_base_method = "smoothing_spline",
                           predictor_support = "observed_integer")
agri_integer_difference(fit2, order = 1)
}
