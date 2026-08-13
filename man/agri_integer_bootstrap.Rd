\name{agri_integer_bootstrap}
\alias{agri_integer_bootstrap}
\title{Bootstrap distribution of an integer optimum}
\usage{agri_integer_bootstrap(object, objective = c("max", "min"),
  B = 499L, seed = 1, cluster = NULL, fixed = list(),
  tolerance = sqrt(.Machine$double.eps))}
\arguments{
\item{object}{An integer-support regression fit.}
\item{objective}{Maximum or minimum.}
\item{B}{Bootstrap replications.}
\item{seed}{Reproducible seed.}
\item{cluster}{Optional cluster variable; defaults to the declared block.}
\item{fixed}{Named values for other covariates.}
\item{tolerance}{Tolerance for tied optima.}
}
\description{Refits the regression in each bootstrap sample and searches only the original admissible integer support.}
\details{
If replicate \eqn{b} has fitted optimum
\deqn{x_b^*=\arg\max_{x\in\mathcal{X}_I}\hat m_b(x),}
the empirical bootstrap probabilities summarize uncertainty over actual admissible decisions. When several integers tie in a replicate, its probability mass is divided equally among them. Blocked fits use whole-block resampling by default.
}
\value{An object of class \code{agri_integer_bootstrap} containing probability mass over the integer support and refit diagnostics.}
\examples{
# B = 19 keeps the examples fast. Use B >= 999 for any reported decision.
data(agri_density)
fit <- agri_np_regression(yield ~ plants, agri_density, method = "integer_grid",
                          integer_base_method = "smoothing_spline",
                          predictor_support = "observed_integer")

# Example 1: probability mass over the admissible densities
boot_max <- agri_integer_bootstrap(fit, B = 19, seed = 1)
boot_max
# Each probability is the share of bootstrap refits in which that density was
# optimal. The mass sums to one over the admissible support.

# Example 2: the mass converted into a discrete confidence set
agri_integer_confset(boot_max, level = 0.80)

# Example 3: the minimum, for a response where less is better
boot_min <- agri_integer_bootstrap(fit, objective = "min", B = 19, seed = 2)
boot_min$probabilities

# Example 4: resampling whole blocks, which preserves the randomization
# structure of the trial
boot_block <- agri_integer_bootstrap(fit, B = 19, seed = 3, cluster = "block")
boot_block$failures
}
