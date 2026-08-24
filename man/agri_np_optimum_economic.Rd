\name{agri_np_optimum_economic}
\alias{agri_np_optimum_economic}
\alias{print.agri_np_optimum_economic}
\title{Economic optimum of a fitted response curve}
\usage{
agri_np_optimum_economic(object, price_ratio, by = NULL,
                         B = 999L, level = 0.95, seed = 1,
                         n = 200L, fixed = list(), range = NULL,
                         cluster = NULL,
                         adjust = c("holm", "none", "BH", "bonferroni",
                                    "hochberg", "hommel", "BY"),
                         parallel = FALSE)
}
\arguments{
\item{object}{An \code{agri_np_reg_fit} from \code{\link{agri_np_regression}}.}

\item{price_ratio}{The price of one unit of input divided by the price of one
unit of produce, in the units of the fitted model. If nitrogen costs 1.20
currency units per kg and grain sells for 0.30 per kg, the ratio is 4, and the
optimum is where the last kilogram of nitrogen returns four kilograms of grain.
\code{price_ratio = 0} reduces to the agronomic optimum, which is a useful
check rather than a recommendation. A vector is accepted and read as a
sensitivity analysis.}

\item{by}{Optional qualitative predictor whose levels are compared, as a name
or a string. The model must let the shape differ between levels.}

\item{B}{Bootstrap replicates. Use at least 999 for anything reported.}

\item{level}{Confidence level of the interval for the optimum.}

\item{seed}{Random seed.}

\item{n}{Grid size on which the root is located.}

\item{fixed}{Values at which other covariates are held.}

\item{range}{Optional two-element range of the predictor to search within.}

\item{cluster}{Resampling unit. Defaults to the declared block, which keeps
whole blocks together. Pass \code{NA} to resample individual rows, which is
only legitimate for a completely randomized layout.}

\item{adjust}{Multiplicity adjustment across the pairwise contrasts produced by
\code{by}, applied within each price ratio.}

\item{parallel}{Distribute the replicates over a \code{future} plan. The answer
does not depend on it.}
}
\description{Locates the input rate at which the marginal physical product,
valued at the price of the produce, equals the price of the input, and reports a
cluster-bootstrap interval for that location.}
\details{
\code{\link{agri_np_optimum}} returns the top of the curve. That is the
agronomic optimum, and it is almost never the rate to apply: the last increments
of input buy less produce than they cost. The economic optimum solves
\deqn{\frac{\partial y}{\partial x} = r,}
where \eqn{r} is the price ratio. It always lies below the agronomic optimum on
a concave response, and the difference between them is frequently the whole
margin of the field.

The root is taken at the first crossing from above, because up to that point
another unit of input still pays for itself.

What is resampled is the \strong{location} of that root, not the height of the
curve, and the two are very different quantities: a response that flattens has a
well estimated curve and a root that wanders over a wide stretch of the
gradient. \code{p_boundary} reports the share of replicates whose root lands on
an end of the searched range, and \code{identified} turns \code{FALSE} when that
share reaches one half, at which point there is no rate to report.

The price ratio is treated as known. It is not: prices move, and the sensitivity
of the recommendation to the ratio is usually larger than its statistical
uncertainty. Supplying a vector of ratios and reading the table as a sensitivity
analysis is the honest use.
}
\value{An object of class \code{agri_np_optimum_economic}, a list with
\code{optimum}, \code{contrasts}, \code{curve}, \code{agronomic} and
\code{replicates}.}
\seealso{\code{\link{agri_np_optimum}} for the agronomic optimum,
\code{\link{agri_np_optimum_test}} for its interval,
\code{\link{agri_np_derivative}} for the marginal product itself,
\code{\link{agri_integer_threshold}} when the decision is an integer.}
\references{
Cerrato, M. E. and Blackmer, A. M. (1990). Comparison of models for describing
corn yield response to nitrogen fertilizer. \emph{Agronomy Journal}, 82(1),
138-143.
}
\examples{
data(agri_dose)
if (requireNamespace("mgcv", quietly = TRUE)) {
  fit <- agri_np_regression(yield ~ dose, agri_dose, method = "gam",
                            block = block, k = 5)

  # Example 1: the agronomic optimum, for comparison. It is the top of the
  # curve, and applying it means paying for input that does not return its cost.
  agri_np_optimum(fit)

  # Example 2: the economic optimum at one price ratio. B is small here for
  # speed; use at least 999 for anything reported.
  agri_np_optimum_economic(fit, price_ratio = 0.006, B = 99, seed = 1)

  # Example 3: prices move more than the resampling interval does. Read this as
  # the sensitivity analysis it is, not as four separate recommendations.
  agri_np_optimum_economic(fit, price_ratio = c(0.002, 0.006, 0.012),
                           B = 99, seed = 1)

  # Example 4: with price_ratio = 0 the function must return the agronomic
  # optimum. It is a check on the solver, not a recommendation.
  agri_np_optimum_economic(fit, price_ratio = 0, B = 99, seed = 1)$optimum
}
}
