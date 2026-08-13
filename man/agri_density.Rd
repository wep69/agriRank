\name{agri_density}
\alias{agri_density}
\docType{data}
\title{Plant density response with an integer treatment}
\description{
A simulated spacing trial with one to nine plants per hill evaluated in six
complete blocks. The treatment is a count: half a plant cannot be sown, so the
admissible decisions form an integer support rather than a continuous range.

This is the reference data set for the integer-support workflow of
\pkg{agriRank}, from \code{\link{agri_integer_predict}} to
\code{\link{agri_integer_confset}}.
}
\usage{agri_density}
\format{
A data frame with 54 rows and 3 variables:
\describe{
  \item{block}{Factor with 6 levels, \code{B1} to \code{B6}. Complete block.}
  \item{plants}{Integer. Plants per hill, from 1 to 9.}
  \item{yield}{Numeric. Grain yield in Mg ha\eqn{^{-1}}.}
}
}
\details{
The response increases up to six plants per hill and decreases afterwards
through intraspecific competition, so the curve is unimodal. The generating
model is
\deqn{y = 2.4 + 1.05\,\min(p, 6) - 0.082\,\min(p, 6)^2 - 0.28\,\max(p - 6, 0) + b + \varepsilon,}
with block effects \eqn{b} between -0.30 and 0.28 Mg ha\eqn{^{-1}} and
\eqn{\varepsilon \sim N(0, 0.21^2)}.

The true continuous maximum does not fall on an integer. That is deliberate: it
shows why the discrete optimum must be obtained by evaluating the admissible
support instead of rounding a continuous optimum.

The generating script is installed as \code{data-raw/make_datasets.R} in the
package sources.
}
\source{Simulated for the package. Not a real experiment.}
\seealso{\code{\link{agri_dose}}, \code{\link{agri_surface}}, \code{\link{agri_integer_optimum}}}
\examples{
# Example 1: the layout, and the integer nature of the treatment
data(agri_density)
str(agri_density)
all(agri_density$plants == round(agri_density$plants))

# Example 2: the admissible decision support and the discrete optimum
fit <- agri_np_regression(yield ~ plants, agri_density, method = "integer_grid",
                          integer_base_method = "smoothing_spline",
                          predictor_support = "observed_integer")
fit$integer_support
agri_integer_optimum(fit)

# Example 3: a unimodal engine on the same data
if (requireNamespace("Iso", quietly = TRUE)) {
  fu <- agri_np_regression(yield ~ plants, agri_density,
                           method = "unimodal_isotonic",
                           predictor_support = "observed_integer")
  agri_integer_optimum(fu)
}
}
\keyword{datasets}
