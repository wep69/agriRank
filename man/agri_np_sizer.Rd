\name{agri_np_sizer}
\alias{agri_np_sizer}
\alias{agri_np_significant_slope}
\alias{print.agri_np_sizer}
\alias{summary.agri_np_sizer}
\alias{plot.agri_np_sizer}
\title{Significant zero crossings of the derivative}
\usage{
agri_np_sizer(
  object,
  y = NULL,
  predictor = NULL,
  bandwidths = NULL,
  n_grid = 41L,
  derivative = 1L,
  reference_bandwidth = NULL
)

agri_np_significant_slope(object, stability = 0.8, ...)

\method{plot}{agri_np_sizer}(x, type = c("map", "stability"), ...)
}
\arguments{
  \item{object}{An \code{agri_np_reg_fit}, or a numeric vector of predictor values.}
  \item{y}{Response values when \code{object} is a numeric vector.}
  \item{predictor}{Focal numeric predictor when \code{object} is a fit.}
  \item{bandwidths}{Vector of bandwidths, on the scale of the predictor. Chosen from the data range when \code{NULL}.}
  \item{n_grid}{Number of positions along the gradient.}
  \item{derivative}{Order of the derivative to classify, 1 or 2.}
  \item{reference_bandwidth}{Bandwidth used for the summary table.}
  \item{stability}{Minimum share of bandwidths that must agree on a state for it to be reported.}
  \item{x}{An \code{agri_np_sizer} object.}
  \item{type}{\code{"map"} for the SiZer map, \code{"stability"} for the share of bandwidths supporting each state.}
  \item{...}{Passed to \code{agri_np_sizer()} when a fit is supplied.}
}
\description{
Classifies the slope of the fitted response as significantly increasing,
indistinguishable from zero, or significantly decreasing, at every position of
the gradient and across a range of smoothing bandwidths.
}
\details{
\code{\link{agri_np_optimum}} answers a narrow question: where is the maximum of
this particular smooth. It does not answer the question a grower asks, which is
from which rate on there is no longer evidence that yield still rises. The two
differ because a single smooth depends on one bandwidth, and the estimated
optimum moves when the bandwidth moves.

SiZer removes that dependence by classifying the sign of the derivative across a
whole column of bandwidths. A conclusion that survives every reasonable amount
of smoothing is defensible; one that appears at a single bandwidth is not.

\code{agri_np_significant_slope()} reduces the map to the statement it supports:
the interval over which the response increases and the position from which it
stops increasing, using only positions where a stated share of bandwidths agree.

Bandwidths are reported on the scale of the predictor, so for a nitrogen
gradient they are in kg ha\eqn{^{-1}} and can be judged agronomically.

The method describes a continuous gradient. For an integer decision support the
function refuses and points to \code{\link{agri_integer_difference}}, because a
derivative is not an admissible quantity between whole plants.
}
\value{
\code{agri_np_sizer()} returns an object of class \code{agri_np_sizer} with the
map in long format, a run-length summary at the reference bandwidth, and the
share of bandwidths supporting each state at every position.
\code{agri_np_significant_slope()} returns a one-row data frame.
\code{plot()} returns a \code{ggplot}.
}
\references{
Chaudhuri, P. and Marron, J. S. (1999). SiZer for exploration of structures in
curves. \emph{Journal of the American Statistical Association}, 94(447),
807-823. \doi{10.1080/01621459.1999.10474186}

Sonderegger, D. \pkg{SiZer}: Significant Zero Crossings. CRAN.
}
\seealso{\code{\link{agri_np_derivative}}, \code{\link{agri_np_optimum}}, \code{\link{agri_np_regression}}}
\examples{
data(agri_dose)
f <- agri_np_regression(yield ~ dose, agri_dose, method = "smoothing_spline")

# Example 1: where is the nitrogen response still rising?
if (requireNamespace("SiZer", quietly = TRUE)) {
  sz <- agri_np_sizer(f)
  sz
}

# Example 2: the agronomic statement, robust to the smoothing choice
if (requireNamespace("SiZer", quietly = TRUE)) {
  agri_np_significant_slope(sz)
  # Compare with the pointwise optimum, which sits at the boundary of the
  # tested range. The optimum answers a different, weaker question.
  agri_np_optimum(f)
}

# Example 3: the map and the stability profile
if (requireNamespace("SiZer", quietly = TRUE) &&
    requireNamespace("ggplot2", quietly = TRUE)) {
  plot(sz, type = "map")
  plot(sz, type = "stability")
}

# Example 4: curvature instead of slope
if (requireNamespace("SiZer", quietly = TRUE)) {
  summary(agri_np_sizer(f, derivative = 2))
}

# Example 5: an integer decision support is refused, with the alternative named
data(agri_density)
fi <- agri_np_regression(yield ~ plants, agri_density, method = "integer_grid",
                         integer_base_method = "smoothing_spline",
                         predictor_support = "observed_integer")
if (requireNamespace("SiZer", quietly = TRUE)) try(agri_np_sizer(fi))
}
