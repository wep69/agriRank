\name{agri_np_optimum_surface}
\alias{agri_np_optimum_surface}
\alias{print.agri_np_optimum_surface}
\title{Joint optimum of a response surface in two predictors}
\usage{
agri_np_optimum_surface(object, predictors = NULL,
                        objective = c("max", "min"),
                        B = 499L, level = 0.95, seed = 1,
                        n = 40L, fixed = list(), ranges = NULL,
                        cluster = NULL, parallel = FALSE)
}
\arguments{
\item{object}{An \code{agri_np_reg_fit} whose model contains both predictors,
most naturally one fitted with \code{gam_structure = "tensor"}.}

\item{predictors}{Character vector of length two naming the numeric predictors
to optimise jointly. Defaults to the first two numeric predictors.}

\item{objective}{\code{"max"} or \code{"min"}.}

\item{B}{Bootstrap replicates. Use at least 999 for anything reported.}

\item{level}{Confidence level of the region.}

\item{seed}{Random seed.}

\item{n}{Grid size per axis. The surface is evaluated on \code{n * n} points, so
the cost is quadratic; 40 is usually enough to locate a smooth optimum.}

\item{fixed}{Values at which other covariates are held.}

\item{ranges}{Optional named list of two-element ranges, one per predictor.}

\item{cluster}{Resampling unit. Defaults to the declared block.}

\item{parallel}{Distribute the replicates over a \code{future} plan.}
}
\description{Locates the pair of rates that jointly optimises the fitted
surface, and reports a bootstrap confidence region for that pair.}
\details{
\code{\link{agri_np_optimum}} optimises one predictor with the others held
fixed. Applied twice that is not the top of the surface unless the two inputs
act additively, which is precisely what a factorial rate trial exists to test.
Assuming additivity in order to find the optimum is therefore circular, and a
surface the model has forced to be additive is refused with an explanation.

\strong{The reported region is not the rectangle of the two marginal intervals.}
The rectangle is also given, as \code{box_lower} and \code{box_upper}, because
it is what a reader expects to see, and it is labelled so that it is not
mistaken for the region. When the surface has a ridge the two differ sharply:
the cloud of resampled optima lies along a diagonal, more of one input
compensating for less of the other, and the rectangle admits corners that no
replicate ever visited. The rank correlation between the two coordinates across
replicates is reported for the same reason, and \code{$region} holds the convex
hull of the retained replicates.

\code{p_boundary} is the share of replicates whose optimum lands on an edge of
the searched rectangle, and \code{identified} turns \code{FALSE} at one half,
exactly as in \code{\link{agri_np_optimum_test}}.
}
\value{An object of class \code{agri_np_optimum_surface}, a list with
\code{optimum}, \code{region}, \code{fitted_response}, \code{p_boundary},
\code{identified}, \code{rank_correlation}, \code{replicates} and
\code{surface}.}
\seealso{\code{\link{agri_np_optimum_test}} for one predictor,
\code{\link{agri_np_optimum_economic}} for the price-aware rate,
\code{\link{agri_np_plot}} with \code{type = "surface"} for the picture.}
\examples{
if (requireNamespace("mgcv", quietly = TRUE)) {
  set.seed(5)
  d <- expand.grid(N = seq(0, 200, 50), P = seq(0, 60, 15), block = factor(1:3))
  d$yield <- 3 + 0.030 * d$N - 0.00013 * d$N^2 + 0.070 * d$P -
    0.0009 * d$P^2 - 0.00010 * d$N * d$P +
    as.numeric(d$block) * 0.2 + rnorm(nrow(d), 0, 0.15)

  # Example 1: the two inputs must be allowed to interact, or the joint optimum
  # carries no information the two separate optima do not.
  ft <- agri_np_regression(yield ~ N + P, d, method = "gam", block = block,
                           k = 4, gam_structure = "tensor")
  os <- agri_np_optimum_surface(ft, B = 99, seed = 1, n = 20)
  os

  # Example 2: the region, which is a hull of resampled optima rather than the
  # rectangle printed above it.
  head(os$region)

  # Example 3: an additive fit is refused, with the reason given.
  fa <- agri_np_regression(yield ~ N + P, d, method = "gam", block = block, k = 4)
  try(agri_np_optimum_surface(fa, B = 49, n = 12))
}
}
