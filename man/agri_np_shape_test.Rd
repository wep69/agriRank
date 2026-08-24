\name{agri_np_shape_test}
\alias{agri_np_shape_test}
\alias{print.agri_np_shape_test}
\title{Is a declared shape compatible with the data}
\usage{
agri_np_shape_test(object, shape = NULL, free_method = "gam",
                   B = 999L, seed = 1, cluster = NULL, parallel = FALSE)
}
\arguments{
\item{object}{An \code{agri_np_reg_fit}. Either the constrained fit or the free
one; the missing side is fitted internally.}
\item{shape}{The constraint to test. Defaults to the one already declared in
\code{object}, and is required when \code{object} is unconstrained.}
\item{free_method}{Engine used for the unconstrained comparison. Defaults to
\code{"gam"}, which is the closest free counterpart of \code{scam}.}
\item{B}{Bootstrap replicates.}
\item{seed}{Random seed.}
\item{cluster}{Resampling unit. Defaults to the declared block.}
\item{parallel}{Distribute the replicates over a \code{future} plan.}
}
\description{Tests whether imposing a monotonicity or curvature constraint
distorts the fit more than resampling alone would.}
\details{
Imposing a shape buys precision when the shape is true and biases the curve when
it is not, and nothing in \code{\link{agri_np_regression}} checks which case
applies. This function does.

The statistic is the mean squared distance between the constrained and the free
fit. Its null distribution is generated from the \strong{constrained} fit,
because the null is that the constraint holds: replicate responses are the
constrained fitted values plus the residuals multiplied by random signs drawn
once per block.

A large p-value does not prove the shape. It says the data do not contradict it,
which is the most a test of this kind can say, and with few blocks that is a
weak statement. Read it together with \code{\link{agri_np_sizer}}, which shows
where the free fit actually changes direction.

If the constrained fit has the smaller RMSE, which cannot happen by
optimisation, the two engines differ in more than the constraint and the printed
output says so. Compare like with like before reading the p-value.
}
\value{An object of class \code{agri_np_shape_test}.}
\seealso{\code{\link{agri_np_effect_test}}, \code{\link{agri_np_sizer}},
\code{\link{agri_np_regression}} for the \code{shape} argument itself.}
\examples{
if (requireNamespace("mgcv", quietly = TRUE) &&
    requireNamespace("scam", quietly = TRUE)) {
  set.seed(21)
  d <- expand.grid(N = seq(0, 200, by = 50), block = factor(1:5), rep = 1:2)
  d$yield <- 3 + 0.030 * d$N - 0.00009 * d$N^2 +
    as.numeric(d$block) * 0.3 + rnorm(nrow(d), 0, 0.3)
  fit <- agri_np_regression(yield ~ N, d, method = "gam", block = block, k = 5)

  # Example 1: is the response compatible with rising and decelerating, which
  # is what agronomy expects of a nutrient? B small here for speed.
  agri_np_shape_test(fit, shape = "increasing_concave", B = 49, seed = 1)

  # Example 2: a constraint the data should contradict, since the response
  # turns over inside the tested range
  agri_np_shape_test(fit, shape = "increasing", B = 49, seed = 1)

  # Example 3: read it beside the SiZer, which shows where the free fit changes
  # direction rather than summarising the whole curve in one number
  if (requireNamespace("SiZer", quietly = TRUE)) {
    agri_np_significant_slope(agri_np_sizer(fit))
  }
}
}
