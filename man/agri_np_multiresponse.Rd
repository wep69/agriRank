\name{agri_np_multiresponse}
\alias{agri_np_multiresponse}
\alias{print.agri_np_multiresponse}
\title{Several responses to one gradient, with a joint region for their optima}
\usage{
agri_np_multiresponse(formula, data, block = NULL, objective = "max",
                      B = 499L, level = 0.95, seed = 1, n = 100L,
                      method = "gam", cluster = NULL, parallel = FALSE, ...)
}
\arguments{
\item{formula}{A formula whose left-hand side names two or more responses, as
\code{cbind(yield, protein) ~ rate}.}
\item{data}{Data frame.}
\item{block}{Optional block, which becomes the resampling unit.}
\item{objective}{One of \code{"max"} or \code{"min"}, recycled over the
responses, or a vector with one entry per response. Yield is usually maximised
and lodging minimised, so a single value is often wrong.}
\item{B}{Bootstrap replicates.}
\item{level}{Confidence level.}
\item{seed}{Random seed.}
\item{n}{Grid size.}
\item{method}{Engine, passed to \code{\link{agri_np_regression}}.}
\item{cluster}{Resampling unit. Defaults to the declared block.}
\item{parallel}{Distribute the replicates over a \code{future} plan.}
\item{...}{Passed to \code{\link{agri_np_regression}}.}
}
\description{Fits one curve per response over the same gradient and reports the
optima with a \strong{shared} cluster bootstrap, so that the correlation between
them survives into the joint region.}
\details{
Nitrogen raises yield and lowers grain protein concentration, or raises both but
with optima far apart. Fitting two curves separately answers each question and
leaves the joint one untouched, because the two optima are estimated from the
same plots and their errors are correlated. Two marginal intervals cannot
express that: they describe a rectangle, and the truth is usually a diagonal.

Every response is refitted on the same resampled blocks within a replicate.
Doing otherwise, which is what calling \code{\link{agri_np_optimum_test}} twice
amounts to, would give each response its own resampled experiment and destroy
exactly the dependence the joint question turns on.

The output carries three things a pair of separate analyses cannot:
\code{rank_correlation} between the resampled optima, \code{region}, the convex
hull of the replicate pairs when there are exactly two responses, and the
resampling distribution itself in \code{$replicates}.

\strong{A joint region is not a compromise rate.} Choosing one rate for two
responses is a decision about their relative value, not a statistical question,
and this function deliberately does not make it. What it supplies is how far
apart the two optima are and how well that distance is determined. Combine it
with \code{\link{agri_np_optimum_economic}} on each response when prices are
what decide.
}
\value{An object of class \code{agri_np_multiresponse}.}
\seealso{\code{\link{agri_np_optimum_test}},
\code{\link{agri_np_optimum_surface}} for two predictors rather than two
responses, \code{\link{agri_multivariate}} for the rank-based multivariate
test.}
\examples{
if (requireNamespace("mgcv", quietly = TRUE)) {
  set.seed(41)
  d <- expand.grid(N = seq(0, 200, 50), block = factor(1:5))
  d$yield   <- 3 + 0.040 * d$N - 0.00020 * d$N^2 +
    as.numeric(d$block) * 0.2 + rnorm(nrow(d), 0, 0.15)
  d$protein <- 9 + 0.026 * d$N - 0.00009 * d$N^2 +
    as.numeric(d$block) * 0.1 + rnorm(nrow(d), 0, 0.15)

  # Example 1: the two optima and, above all, the distance between them
  mr <- agri_np_multiresponse(cbind(yield, protein) ~ N, d, block = block,
                              B = 49, seed = 1, n = 60, k = 4)
  mr
  # The two rates differ by about 37 kg/ha. That difference, not either
  # optimum on its own, is what a joint recommendation has to face.

  # Example 2: the joint region, which is not the rectangle of the two
  # intervals printed above
  head(mr$region)

  # Example 3: one response maximised and one minimised, which a single
  # objective would get wrong
  d$lodging <- 20 + 0.10 * d$N + rnorm(nrow(d), 0, 2)
  agri_np_multiresponse(cbind(yield, lodging) ~ N, d, block = block,
                        objective = c("max", "min"), B = 49, seed = 1,
                        n = 40, k = 4)
}
}
