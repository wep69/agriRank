\name{agri_np_bootstrap}
\alias{agri_np_bootstrap}
\title{Cluster-aware bootstrap confidence bands for agronomic regression}
\usage{
agri_np_bootstrap(object, newdata = NULL, predictor = NULL, B = 499L, level = 0.95,
  seed = 1, cluster = NULL, n = 200L, fixed = list())
}
\arguments{
  \item{object}{An \code{agri_np_reg_fit}.}
  \item{newdata}{Prediction grid; generated automatically if omitted.}
  \item{predictor}{Numeric focal predictor.}
  \item{B}{Bootstrap replicates.}
  \item{level}{Interval level.}
  \item{seed}{Random seed.}
  \item{cluster}{Optional resampling cluster. The declared block is used by default when available.}
  \item{n}{Automatic grid size.}
  \item{fixed}{Values for other covariates.}
}
\description{Refits the selected regression engine under row or cluster resampling and returns pointwise percentile bands.}
\details{When a block or cluster is supplied, whole clusters are resampled. The resulting intervals are pointwise percentile intervals, not simultaneous bands. Large \code{B} should be used for final inference.}
\value{A data frame containing the prediction grid, original fitted curve, lower and upper bootstrap limits, with bootstrap metadata as attributes.}
\examples{
# B = 19 keeps these examples fast. It is far too small for analysis: use
# B >= 999 for reporting and B >= 4999 for final work whenever feasible.
data(agri_dose)
f <- agri_np_regression(yield ~ dose, agri_dose, method = "smoothing_spline")

# Example 1: resampled uncertainty of the fitted curve
b1 <- agri_np_bootstrap(f, B = 19, n = 30)
head(b1)

# Example 2: uncertainty exactly at the rates under discussion
b2 <- agri_np_bootstrap(f, newdata = data.frame(dose = c(80, 160, 240)), B = 19)
b2
# The width of each interval, in Mg/ha, is what separates a recommendation
# from a point estimate.

# Example 3: block-aware bootstrap, which resamples whole blocks
if (requireNamespace("mgcv", quietly = TRUE)) {
  fb <- agri_np_regression(yield ~ dose, agri_dose, method = "gam", block = block)
  head(agri_np_bootstrap(fb, B = 19, n = 20))
  # Resampling complete blocks preserves the randomization structure of the
  # trial; resampling individual plots would not.
}
}
