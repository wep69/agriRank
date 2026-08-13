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
data(agri_density)
fit <- agri_np_regression(yield ~ plants, agri_density, method = "integer_grid",
                          integer_base_method = "smoothing_spline",
                          predictor_support = "observed_integer")

# Example 1: the smallest density reaching 95 percent of the fitted maximum
agri_integer_threshold(fit, "fraction_of_maximum", value = 0.95)

# Example 2: the density recovering 90 percent of the total gain available
# above the lowest tested density
agri_integer_threshold(fit, "gain_from_baseline", value = 0.90, baseline = 1)

# Example 3: the density beyond which one more plant adds less than
# 0.10 Mg/ha, a criterion stated in the unit of the response
agri_integer_threshold(fit, "marginal_gain", value = 0.10)

# Example 4: the three criteria answer different agronomic questions and can
# select different densities. Each returns the columns that make sense for it,
# so compare the selected decision rather than binding the tables.
data.frame(
  criterion = c("fraction_of_maximum", "gain_from_baseline", "marginal_gain"),
  plants = c(
    agri_integer_threshold(fit, "fraction_of_maximum", value = 0.95)$integer_value,
    agri_integer_threshold(fit, "gain_from_baseline", value = 0.90, baseline = 1)$integer_value,
    agri_integer_threshold(fit, "marginal_gain", value = 0.10)$integer_value
  )
)
# The choice among them belongs to the agronomist and must be stated before
# looking at the data.
}
