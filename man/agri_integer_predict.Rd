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
set.seed(301)
d <- data.frame(plants = rep(1:8, each = 5))
d$yield <- 20 + 6*d$plants - .4*d$plants^2 + rnorm(nrow(d))
f1 <- agri_np_regression(yield ~ plants, d, method = "integer_grid",
  integer_base_method = "smoothing_spline")
agri_integer_predict(f1)

agri_integer_predict(f1, support = c(3, 4, 5, 6))

f2 <- agri_np_regression(yield ~ plants, d, method = "integer_grid",
  integer_base_method = "smoothing_spline",
  predictor_support = "integer_range", integer_range = c(1, 10))
agri_integer_predict(f2, support = 8:10)
}
