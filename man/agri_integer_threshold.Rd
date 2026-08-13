\name{agri_integer_threshold}
\alias{agri_integer_threshold}
\title{Practical thresholds on an integer agronomic support}
\usage{agri_integer_threshold(object,
  criterion = c("fraction_of_maximum", "gain_from_baseline", "marginal_gain"),
  value = 0.95, baseline = NULL, fixed = list())}
\arguments{
\item{object}{An integer-support regression fit.}
\item{criterion}{Practical threshold definition.}
\item{value}{Criterion-specific target.}
\item{baseline}{Baseline integer for gain-from-baseline inference.}
\item{fixed}{Named values for other covariates.}
}
\description{Finds the smallest admissible integer satisfying a prespecified biological or operational criterion.}
\details{
For the fraction-of-maximum criterion,
\deqn{x_\rho=\min\{x\in\mathcal{X}_I:\hat m(x)\ge \rho\max_{s\in\mathcal{X}_I}\hat m(s)\}.}
The other criteria use an absolute gain from a declared baseline or the first marginal gain no larger than a chosen threshold.
}
\value{A one-row data frame containing the selected integer decision when the criterion is attained.}
\examples{
d <- data.frame(plants = rep(1:9, each = 5))
set.seed(305); d$yield <- 18 + 7*d$plants - .5*d$plants^2 + rnorm(nrow(d))
fit <- agri_np_regression(yield ~ plants, d, method = "integer_grid",
  integer_base_method = "smoothing_spline", predictor_support = "integer_range")
agri_integer_threshold(fit, "fraction_of_maximum", value = .95)

agri_integer_threshold(fit, "gain_from_baseline", value = 10, baseline = 1)

agri_integer_threshold(fit, "marginal_gain", value = 1)
}
