\name{agri_integer_predict}
\alias{agri_integer_predict}
\title{Predict on an admissible integer decision support}
\usage{agri_integer_predict(object, support = NULL, fixed = list(),
  interval = c("none", "confidence"), level = 0.95)}
\arguments{
\item{object}{An integer-support \code{agri_np_reg_fit}.}
\item{support}{Optional subset of the fitted integer support.}
\item{fixed}{Named values for other covariates.}
\item{interval}{Prediction output; model-based confidence intervals are returned only by supported backends.}
\item{level}{Confidence level.}
}
\description{Evaluates a fitted regression only at admissible integer values. Fractional values and integers outside the declared support are rejected.}
\details{The function operationalizes the decision lattice \eqn{\mathcal{X}_I}. It never rounds a continuous prediction request to the nearest integer.}
\value{A data frame containing the integer predictor and fitted response, with confidence limits when available.}
\examples{
data(agri_density)

# Example 1: predicted yield, in Mg/ha, at every admissible plant density
f1 <- agri_np_regression(yield ~ plants, agri_density, method = "integer_grid",
                         integer_base_method = "smoothing_spline",
                         predictor_support = "observed_integer")
agri_integer_predict(f1)
# One row per decision the grower can actually take. No fractional plant
# appears, because half a plant cannot be sown.

# Example 2: restricted to the densities under discussion
agri_integer_predict(f1, support = 4:7)

# Example 3: a support extended beyond what was tested. Extrapolating to 10
# plants per hill must be justified agronomically, never by convenience.
f2 <- agri_np_regression(yield ~ plants, agri_density, method = "integer_grid",
                         integer_base_method = "smoothing_spline",
                         predictor_support = "integer_range",
                         integer_range = c(1, 12))
agri_integer_predict(f2, support = 10:12)
}
