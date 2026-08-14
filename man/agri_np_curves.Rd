\name{agri_np_curves}
\alias{agri_np_curves}
\title{Overlay the fitted curves of several regression engines}
\usage{
agri_np_curves(
  formula,
  data,
  methods = c("smoothing_spline", "loess", "gam"),
  block = NULL,
  n = 200L,
  ...
)
}
\arguments{
  \item{formula}{Regression formula with one response and one numeric predictor.}
  \item{data}{Data frame.}
  \item{methods}{Engines to overlay. Engines that fail to fit are skipped.}
  \item{block}{Optional agronomic block, given as a character name, applied to every engine.}
  \item{n}{Grid resolution.}
  \item{...}{Passed to \code{\link{agri_np_regression}}.}
}
\description{
Fits several regression engines to the same data and draws their fitted curves
on one figure, over the observed points.
}
\details{
The figure answers a question that a table of cross-validated errors answers
poorly: how different are these engines where it matters, on the scale of the
response? Engines that differ by a fraction of the residual scale are not
agronomically distinguishable, however their error metrics are ordered.

Use it together with \code{\link{agri_np_compare}}, which quantifies predictive
error, and remember that neither is a way of choosing an inferential method.
}
\value{A \code{ggplot} object.}
\seealso{\code{\link{agri_np_compare}}, \code{\link{agri_np_plot}}}
\examples{
data(agri_dose)

# Example 1: three smoothers on a nitrogen response
agri_np_curves(yield ~ dose, agri_dose,
               methods = c("smoothing_spline", "loess"))

# Example 2: adding a rank-robust straight line makes the contrast explicit
if (requireNamespace("mblm", quietly = TRUE)) {
  agri_np_curves(yield ~ dose, agri_dose,
                 methods = c("smoothing_spline", "loess", "theil_sen"))
  # The straight line cannot follow the plateau, which is visible at a glance.
}

# Example 3: every engine adjusted for the same declared block
if (requireNamespace("mgcv", quietly = TRUE)) {
  agri_np_curves(yield ~ dose, agri_dose, methods = c("gam", "quantile"),
                 block = "block")
}
}
