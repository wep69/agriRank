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
set.seed(35)
d <- data.frame(N = seq(0, 240, length.out = 60));
d$yield <- 4 + .08*d$N - .00022*d$N^2 + rnorm(60, 0, .6)
f <- agri_np_regression(yield ~ N, d, method = "smoothing_spline")
# Example 1
agri_np_optimum(f)
# Example 2
agri_np_optimum(f, range = c(40, 220))
# Example 3
agri_np_optimum(f, objective = "min")
}
