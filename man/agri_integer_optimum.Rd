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
data(agri_density)
fit <- agri_np_regression(yield ~ plants, agri_density, method = "integer_grid",
                          integer_base_method = "smoothing_spline",
                          predictor_support = "observed_integer")

# Example 1: the recommended density, obtained by evaluating every admissible
# integer, not by rounding a continuous optimum
agri_integer_optimum(fit)

# Example 2: the minimum, for responses where less is better, such as a
# disease score or a damage index
agri_integer_optimum(fit, objective = "min")

# Example 3: a shape-constrained engine on the same data. Two engines that
# agree on the decision give more confidence than either alone.
if (requireNamespace("Iso", quietly = TRUE)) {
  fu <- agri_np_regression(yield ~ plants, agri_density,
                           method = "unimodal_isotonic",
                           predictor_support = "observed_integer")
  agri_integer_optimum(fu)
}

# Example 4: a point optimum is not a recommendation. Report the bootstrap
# confidence set alongside it.
bt <- agri_integer_bootstrap(fit, B = 199, seed = 1)  # use B >= 999 in analysis
agri_integer_confset(bt, level = 0.95)
}
