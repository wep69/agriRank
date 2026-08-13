\name{agri_integer_optimum}
\alias{agri_integer_optimum}
\title{Maximum or minimum on an integer decision support}
\usage{agri_integer_optimum(object, objective = c("max", "min"),
  fixed = list(), tolerance = sqrt(.Machine$double.eps))}
\arguments{
\item{object}{An integer-support regression fit.}
\item{objective}{Search for the fitted maximum or minimum.}
\item{fixed}{Named values for other covariates.}
\item{tolerance}{Numerical tolerance for tied optima.}
}
\description{Finds all fitted optima directly on the admissible integer support.}
\details{
For support \eqn{\mathcal{X}_I}, the maximizer is
\deqn{x_I^*=\arg\max_{x\in\mathcal{X}_I}\hat m(x),}
with the analogous definition for a minimum. This is not obtained by rounding a continuous optimum.
}
\value{An object of class \code{agri_integer_optimum} with all tied optimal integers, the fitted best response, support, and boundary flag.}
\examples{
set.seed(303)
d <- data.frame(plants = rep(1:9, each = 5))
d$yield <- 25 + 8*d$plants - .65*d$plants^2 + rnorm(nrow(d))
fit <- agri_np_regression(yield ~ plants, d, method = "integer_grid",
  integer_base_method = "smoothing_spline")
agri_integer_optimum(fit)

agri_integer_optimum(fit, objective = "min")

if (requireNamespace("Iso", quietly = TRUE)) {
  fu <- agri_np_regression(yield ~ plants, d, method = "unimodal_isotonic")
  agri_integer_optimum(fu)
}
}
