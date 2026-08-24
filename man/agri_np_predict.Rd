\name{agri_np_predict}
\alias{agri_np_predict}
\title{Predict from an agriRank nonparametric regression}
\usage{
agri_np_predict(object, newdata = NULL,
                interval = c("none", "confidence", "prediction"),
                level = 0.95, scope = NULL,
                extrapolation = c("warn", "error", "allow"),
                extrapolation_tol = 0.1, ...)
}
\arguments{
  \item{object}{An \code{agri_np_reg_fit}.}
  \item{newdata}{Prediction data; training data by default.}
  \item{interval}{One of \code{"none"}, \code{"confidence"} or
    \code{"prediction"}. A confidence interval covers the mean response at a
    covariate setting. A prediction interval covers the next individual plot,
    which is what a recommendation needs, and is always wider; it is produced by
    split conformal prediction through \code{\link{agri_np_conformal}} and so
    carries a finite-sample marginal coverage guarantee rather than a
    distributional assumption.}
  \item{level}{Confidence level.}
  \item{scope}{Required when \code{interval = "prediction"} and the fit declares
    a block. \code{"within_block"} covers a new plot in a block already
    observed; \code{"new_block"} covers a plot in a block not seen before, and
    is wider. The two answer different questions, so there is no default worth
    guessing on the user's behalf.}
  \item{extrapolation}{One of \code{"warn"}, \code{"error"} or \code{"allow"}.
    A smoother carries no information beyond the range of the data it saw:
    outside its support the returned value describes the chosen basis, not the
    experiment. With \code{"warn"} the prediction is returned together with a
    warning and an \code{extrapolated} flag; with \code{"error"} a request that
    leaves the observed envelope by more than \code{extrapolation_tol} of its
    width is refused.}
  \item{extrapolation_tol}{Fraction of the observed range of a numeric predictor
    that a request may fall outside before \code{"error"} refuses it. Defaults
    to 0.1.}
  \item{...}{Passed to \code{\link{agri_np_conformal}} when
    \code{interval = "prediction"}.}
}
\description{Provides a common prediction interface across all regression engines.}
\details{Standardized analytic confidence intervals are currently exposed for
GAM, SCAM, COBS, umbrella and smooth-quantile engines. For the others, use
\code{\link{agri_np_bootstrap}} for resampling-based uncertainty.

Rows that leave the fitted range are flagged in an \code{extrapolated} column
when the return is a data frame, and in an attribute of the same name when the
engine returns a bare numeric vector. Cross-validation and bootstrap loops are
exempt from the check, because held-out folds and resampled replicates leave the
training range by construction.}
\value{A numeric vector, matrix, or data frame with fitted values and, when
requested, interval limits. With \code{interval = "prediction"} the return is an
\code{agri_np_conformal} object, which carries the calibration size and the
achieved quantile as attributes.}
\seealso{\code{\link{agri_np_conformal}} for the prediction interval on its own
terms, \code{\link{agri_np_bootstrap}} for resampling-based bands.}
\examples{
data(agri_dose)
fit <- agri_np_regression(yield ~ dose, agri_dose, method = "smoothing_spline")

# Example 1: the default prediction grid over the observed range
head(agri_np_predict(fit))

# Example 2: yield, in Mg/ha, at nitrogen rates a grower would consider
agri_np_predict(fit, data.frame(dose = c(0, 80, 160, 240)))

# Example 3: with a confidence interval, which covers the mean response.
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

# Example 4: a prediction interval, which covers the next plot rather than the
# mean, and is the quantity a recommendation needs. It is always wider.
if (requireNamespace("mgcv", quietly = TRUE)) {
  agri_np_predict(g, nd, interval = "prediction", scope = "within_block",
                  seed = 1)
}

# Example 5: omitting the block is refused, with the variable named
if (requireNamespace("mgcv", quietly = TRUE)) {
  try(agri_np_predict(g, data.frame(dose = 160)))
}

# Example 6: asking beyond the tested range is refused rather than answered.
# The trial went to 240 kg/ha; 600 is not an estimate, it is the basis talking.
try(agri_np_predict(fit, data.frame(dose = 600), extrapolation = "error"))
}
