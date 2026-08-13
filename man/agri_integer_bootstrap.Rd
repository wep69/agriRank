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
set.seed(306)
d <- data.frame(plants = rep(1:8, each = 7))
d$yield <- 20 + 7*d$plants - .55*d$plants^2 + rnorm(nrow(d))
fit <- agri_np_regression(yield ~ plants, d, method = "integer_grid",
  integer_base_method = "smoothing_spline")
b1 <- agri_integer_bootstrap(fit, B = 19, seed = 1)
b1

agri_integer_confset(b1, level = .80)

# Example 2: inspect a second bootstrap object at a higher confidence target
b80 <- agri_integer_bootstrap(fit, B = 19, seed = 11)
agri_integer_confset(b80, level = .90)

# Example 3: minimum instead of maximum
b2 <- agri_integer_bootstrap(fit, objective = "min", B = 19, seed = 2)
b2$probabilities
}
