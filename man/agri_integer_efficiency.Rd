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
d <- data.frame(plants = rep(1:7, each = 4))
set.seed(304); d$yield <- 15 + 5*d$plants - .35*d$plants^2 + rnorm(nrow(d))
fit <- agri_np_regression(yield ~ plants, d, method = "integer_grid",
  integer_base_method = "smoothing_spline")
agri_integer_efficiency(fit)

tail(agri_integer_efficiency(fit), 3)

subset(agri_integer_efficiency(fit), relative_to_fitted_maximum >= .95)
}
