\name{agri_np_predict}
\alias{agri_np_predict}
\title{Predict from an agriRank nonparametric regression}
\usage{
agri_np_predict(object, newdata = NULL, interval = c("none", 
    "confidence"), level = 0.95)
}
\arguments{
  \item{object}{An \code{agri_np_reg_fit}.}
  \item{newdata}{Prediction data; training data by default.}
  \item{interval}{Whether to request a model-based confidence interval when supported.}
  \item{level}{Confidence level.}
}
\description{Provides a common prediction interface across all regression engines.}
\details{Standardized analytic confidence intervals are currently exposed for GAM, SCAM and COBS. For other engines, use \code{agri_np_bootstrap()} for resampling-based uncertainty.}
\value{A numeric vector, matrix, or data frame with fitted values and, when supported, confidence limits.}
\examples{
data(agri_dose)
fit <- agri_np_regression(yield ~ dose, agri_dose, method = "smoothing_spline")

# Example 1: the default prediction grid over the observed range
head(agri_np_predict(fit))

# Example 2: yield, in Mg/ha, at nitrogen rates a grower would consider
agri_np_predict(fit, data.frame(dose = c(0, 80, 160, 240)))

# Example 3: with a confidence interval, which is what a recommendation needs.
# The fit adjusts for block, so the prediction data must state the block at
# which the prediction is intended.
if (requireNamespace("mgcv", quietly = TRUE)) {
  g <- agri_np_regression(yield ~ dose, agri_dose, method = "gam", block = block)
  nd <- data.frame(dose = c(80, 160, 240),
                   block = factor("B3", levels = levels(agri_dose$block)))
  agri_np_predict(g, nd, interval = "confidence")
  # If the intervals at 160 and 240 kg/ha overlap, the data do not separate
  # those two rates, whatever the point estimates suggest.
}

# Example 4: omitting the block is refused, with the variable named
if (requireNamespace("mgcv", quietly = TRUE)) {
  try(agri_np_predict(g, data.frame(dose = 160)))
}
}
