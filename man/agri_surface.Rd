\name{agri_surface}
\alias{agri_surface}
\docType{data}
\title{Two-gradient response surface, nitrogen and irrigation depth}
\description{
A simulated factorial of seven nitrogen rates by five irrigation depths in two
blocks. Both factors are quantitative, and they interact: the return to
nitrogen depends on how much water is available.

This is the reference data set for the response-surface and multi-predictor
examples of \pkg{agriRank}.
}
\usage{agri_surface}
\format{
A data frame with 70 rows and 4 variables:
\describe{
  \item{block}{Factor with 2 levels, \code{B1} and \code{B2}.}
  \item{nitrogen}{Numeric. Nitrogen rate in kg ha\eqn{^{-1}}, from 0 to 240 in steps of 40.}
  \item{water}{Numeric. Irrigation depth as a fraction of crop evapotranspiration, from 0.4 to 1.2.}
  \item{yield}{Numeric. Grain yield in Mg ha\eqn{^{-1}}.}
}
}
\details{
The generating model is
\deqn{y = 2.0 + 0.0165\,N - 0.0000402\,N^2 + 3.10\,W - 1.55\,W^2 + 0.0042\,NW + b + \varepsilon,}
with \eqn{\varepsilon \sim N(0, 0.20^2)}. The positive cross term is the
agronomic point of the data set: nitrogen pays more under adequate irrigation,
so the two gradients cannot be interpreted separately.

The generating script is installed as \code{data-raw/make_datasets.R} in the
package sources.
}
\source{Simulated for the package. Not a real experiment.}
\seealso{\code{\link{agri_dose}}, \code{\link{agri_density}}, \code{\link{agri_np_plot}}}
\examples{
# Example 1: the factorial layout of the two gradients
data(agri_surface)
str(agri_surface)
with(agri_surface, table(nitrogen, water))

# Example 2: tensor-product surface
if (requireNamespace("mgcv", quietly = TRUE)) {
  fs <- agri_np_regression(yield ~ nitrogen + water, agri_surface,
                           method = "gam", gam_structure = "tensor")
  agri_np_diagnostics(fs)
}

# Example 3: nitrogen response at a fixed irrigation depth
if (requireNamespace("mgcv", quietly = TRUE)) {
  agri_np_predict(fs, newdata = data.frame(nitrogen = c(0, 80, 160, 240),
                                           water = 1.0))
}
}
\keyword{datasets}
