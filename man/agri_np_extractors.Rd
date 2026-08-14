\name{agri_np_extractors}
\alias{coef.agri_np_reg_fit}
\alias{confint.agri_np_reg_fit}
\alias{fitted.agri_np_reg_fit}
\alias{residuals.agri_np_reg_fit}
\title{Standard extractors for agriRank regression fits}
\usage{
\method{coef}{agri_np_reg_fit}(object, ...)

\method{confint}{agri_np_reg_fit}(
  object,
  parm = NULL,
  level = 0.95,
  method = c("auto", "backend", "bootstrap"),
  B = 999L,
  seed = 1,
  ...
)

\method{fitted}{agri_np_reg_fit}(object, ...)

\method{residuals}{agri_np_reg_fit}(object, ...)
}
\arguments{
  \item{object}{An \code{agri_np_reg_fit}.}
  \item{parm}{Optional subset of coefficient names.}
  \item{level}{Confidence level.}
  \item{method}{\code{"backend"} uses the interval exposed by the fitting package, \code{"bootstrap"} resamples the data, and \code{"auto"} tries the backend first.}
  \item{B}{Bootstrap replicates when resampling is used.}
  \item{seed}{Random seed for the bootstrap.}
  \item{...}{Unused.}
}
\description{
Fitted values, residuals, coefficients and coefficient confidence intervals for
a fitted regression.
}
\details{
A fitted curve always has fitted values and residuals, so \code{fitted()} and
\code{residuals()} work for every engine.

Coefficients are different. They exist only when the engine defines a finite
parameter vector with an interpretation, which here means \code{theil_sen},
\code{siegel} and \code{quantile}. For a smoothing spline, a LOESS or a GAM,
\code{coef()} fails on purpose: returning basis coefficients as if they were
agronomic slopes would invite a reading the model does not support. Describe
those fits with \code{\link{agri_np_predict}},
\code{\link{agri_np_derivative}} or \code{\link{agri_np_optimum}} instead.

\code{confint()} prefers the interval published by the backend and falls back
to the cluster-aware bootstrap of \code{\link{agri_np_bootstrap}}. The two
usually differ, and the difference is informative: the backend interval relies
on the asymptotic theory of that estimator, while the bootstrap interval only
assumes that resampling the experimental units is legitimate.

For a fit with qualitative predictors, \code{coef()} returns one coefficient
per non-reference level of each factor, beside the intercept and the numeric
slopes; \code{\link{agri_np_forest}} displays those coefficients with
bootstrap intervals one level per row. For a block-adjusted fit, the bootstrap
route reports the scientific coefficients of the declared formula: block
adjustment terms are nuisance parameters and are excluded from the resampled
target.
}
\value{
\code{coef()} a named numeric vector; \code{confint()} a data frame with term,
estimate, lower, upper and the method used; \code{fitted()} and
\code{residuals()} named numeric vectors.
}
\seealso{\code{\link{agri_np_regression}}, \code{\link{agri_np_bootstrap}}, \code{\link{agri_np_diagnostics}}}
\examples{
data(agri_dose)

# Example 1: a rank-robust slope, in Mg/ha per kg/ha of nitrogen
if (requireNamespace("mblm", quietly = TRUE)) {
  ts <- agri_np_regression(yield ~ dose, agri_dose, method = "theil_sen")
  coef(ts)
  confint(ts, method = "backend")
}

# Example 2: the same slope with a bootstrap interval, which makes fewer
# assumptions and is usually wider
if (requireNamespace("mblm", quietly = TRUE)) {
  confint(ts, method = "bootstrap", B = 199, seed = 1)
}

# Example 3: a smoothing spline has no slope to report, and says so
ss <- agri_np_regression(yield ~ dose, agri_dose, method = "smoothing_spline")
length(fitted(ss))
length(residuals(ss))
try(coef(ss))
}
