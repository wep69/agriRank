\name{agri_integer_confset}
\alias{agri_integer_confset}
\title{Bootstrap confidence set for an integer optimum}
\usage{agri_integer_confset(bootstrap, level = 0.95)}
\arguments{
\item{bootstrap}{An \code{agri_integer_bootstrap} object.}
\item{level}{Requested bootstrap probability level.}
}
\description{Constructs a highest-probability set made only of admissible integer decisions.}
\details{Support points are ordered by bootstrap probability and added until the requested cumulative mass is reached. The result is a discrete decision set rather than a fractional confidence interval.}
\value{An object of class \code{agri_integer_confset}.}
\examples{
set.seed(307)
d <- data.frame(plants = rep(1:8, each = 6))
d$yield <- 20 + 7*d$plants - .55*d$plants^2 + rnorm(nrow(d))
fit <- agri_np_regression(yield ~ plants, d, method = "integer_grid",
  integer_base_method = "smoothing_spline")
bt <- agri_integer_bootstrap(fit, B = 19, seed = 5)
agri_integer_confset(bt, level = .80)

agri_integer_confset(bt, level = .90)

cs <- agri_integer_confset(bt, level = .80)
cs$hull
}
