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
set.seed(31)
d <- data.frame(x = seq(0, 10, length.out = 35)); d$y <- sin(d$x/2) + rnorm(35, 0, .2)
fit <- agri_np_regression(y ~ x, d, method = "smoothing_spline")
# Example 1
head(agri_np_predict(fit))
# Example 2
agri_np_predict(fit, data.frame(x = c(2, 4, 6, 8)))
# Example 3
if (requireNamespace("mgcv", quietly = TRUE)) {
  g <- agri_np_regression(y ~ x, d, method = "gam")
  head(agri_np_predict(g, data.frame(x = seq(1, 9, length.out = 6)), interval = "confidence"))
}
}
