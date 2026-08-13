\name{agri_integer_efficiency}
\alias{agri_integer_efficiency}
\title{Discrete fitted-response and marginal-efficiency table}
\usage{agri_integer_efficiency(object, fixed = list())}
\arguments{
\item{object}{An integer-support regression fit.}
\item{fixed}{Named values for other covariates.}
}
\description{Summarizes fitted response, response relative to the fitted maximum, and marginal gains between adjacent integer decisions.}
\details{The output is descriptive. Economic efficiency requires explicit prices or costs and should not be inferred from biological response alone.}
\value{A data frame on the declared integer support.}
\examples{
data(agri_density)
fit <- agri_np_regression(yield ~ plants, agri_density, method = "integer_grid",
                          integer_base_method = "smoothing_spline",
                          predictor_support = "observed_integer")

# Example 1: each admissible density as a fraction of the fitted maximum
agri_integer_efficiency(fit)

# Example 2: the densest options
tail(agri_integer_efficiency(fit), 3)

# Example 3: every density within 5 percent of the maximum. When several
# qualify, the cheapest to establish is a defensible operational choice.
subset(agri_integer_efficiency(fit), relative_to_fitted_maximum >= 0.95)
}
