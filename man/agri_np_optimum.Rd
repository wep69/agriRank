\name{agri_np_optimum}
\alias{agri_np_optimum}
\title{Locate a descriptive optimum on a fitted nonparametric curve}
\usage{
agri_np_optimum(object, predictor = NULL, objective = c("max", 
    "min"), n = 500L, fixed = list(), range = NULL)
}
\arguments{
  \item{object}{An \code{agri_np_reg_fit}.}
  \item{predictor}{Numeric predictor.}
  \item{objective}{Search for maximum or minimum.}
  \item{n}{Search-grid size.}
  \item{fixed}{Values for other covariates.}
  \item{range}{Optional search range.}
}
\description{Searches the fitted response surface along one predictor and reports the grid maximum or minimum.}
\details{This is a descriptive optimum of the chosen smoother. It is not an economic optimum and should not replace a prespecified mechanistic or parametric dose-response model when that model is scientifically required. A boundary flag is returned.}
\value{One-row data frame with predictor, optimum, fitted response, objective and boundary indicator.}
\examples{
data(agri_dose)
f <- agri_np_regression(yield ~ dose, agri_dose, method = "smoothing_spline")

# Example 1: descriptive optimum over the observed nitrogen range
agri_np_optimum(f)

# Example 2: restricted to an operationally feasible range
agri_np_optimum(f, range = c(40, 220))

# Example 3: the minimum, useful when the response is a cost or a damage score
agri_np_optimum(f, objective = "min")

# Example 4: an optimum without uncertainty is not a recommendation.
# Pair it with the bootstrap and report the interval, not only the point.
b <- agri_np_bootstrap(f, B = 199, seed = 1)   # use B >= 999 in analysis
opt <- agri_np_optimum(f)
opt
utils::head(b)
}
