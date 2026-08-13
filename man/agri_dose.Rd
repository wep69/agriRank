\name{agri_dose}
\alias{agri_dose}
\docType{data}
\title{Nitrogen response in a randomized complete block design}
\description{
A simulated fertilizer trial with eight nitrogen rates evaluated in five
complete blocks. The response follows a quadratic-plateau shape, which is the
classical form of a fertilizer response curve: yield rises with the rate,
the increment shrinks, and beyond a plateau further nitrogen adds nothing.

The data set exists so that the regression examples of \pkg{agriRank} share a
single, agronomically interpretable experiment instead of creating a different
throwaway data frame on every help page.
}
\usage{agri_dose}
\format{
A data frame with 40 rows and 3 variables:
\describe{
  \item{block}{Factor with 5 levels, \code{B1} to \code{B5}. Complete block.}
  \item{dose}{Numeric. Nitrogen rate in kg ha\eqn{^{-1}}, from 0 to 280 in steps of 40.}
  \item{yield}{Numeric. Grain yield in Mg ha\eqn{^{-1}}.}
}
}
\details{
The generating model is
\deqn{y = 3.1 + 0.0182\,\min(d, 200) - 0.0000362\,\min(d, 200)^2 + b + \varepsilon,}
with block effects \eqn{b} between -0.45 and 0.35 Mg ha\eqn{^{-1}} and
\eqn{\varepsilon \sim N(0, 0.24^2)}. The plateau at 200 kg ha\eqn{^{-1}} means
that no parametric quadratic is correct over the whole range, which is exactly
the situation the nonparametric regression module is meant for.

The generating script is installed as \code{data-raw/make_datasets.R} in the
package sources.
}
\source{Simulated for the package. Not a real experiment.}
\seealso{\code{\link{agri_density}}, \code{\link{agri_surface}}, \code{\link{agri_np_regression}}}
\examples{
# Example 1: the layout
data(agri_dose)
str(agri_dose)
with(agri_dose, table(block, dose))

# Example 2: block-adjusted smooth response and its optimum
if (requireNamespace("mgcv", quietly = TRUE)) {
  fit <- agri_np_regression(yield ~ dose, agri_dose, method = "gam", block = block)
  agri_np_optimum(fit)
}

# Example 3: declared as a quantitative RCBD, then analyzed
des <- agri_design(yield ~ dose, agri_dose, design = "rcbd",
                   block = block, quantitative = dose)
design_summary(des)
}
\keyword{datasets}
