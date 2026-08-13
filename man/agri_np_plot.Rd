\name{agri_np_plot}
\alias{agri_np_plot}
\title{Scientific ggplot2 graphics for nonparametric regression}
\usage{
agri_np_plot(object, type = c("fit", "residuals", "derivative", 
    "surface"), predictor = NULL, n = 200L, fixed = list(), 
    interval = FALSE, group = NULL, surface_predictors = NULL, 
    ...)
}
\arguments{
  \item{object}{An \code{agri_np_reg_fit}.}
  \item{type}{Fit, residual, derivative, or two-dimensional response-surface plot.}
  \item{predictor}{Numeric focal predictor.}
  \item{n}{Grid size.}
  \item{fixed}{Values for other covariates.}
  \item{interval}{Request analytic confidence ribbon when supported.}
  \item{group}{Optional grouping variable for separate fitted curves.}
  \item{surface_predictors}{Two numeric predictors used for a response-surface plot.}
  \item{...}{Reserved for future extensions.}
}
\description{Returns editable \pkg{ggplot2} objects displaying observed agronomic data with fitted smooths, residuals, or numerical derivatives.}
\value{A \code{ggplot} object.}
\examples{
set.seed(37)
d <- data.frame(dose = seq(0, 150, length.out = 45));
d$yield <- 5 + .08*d$dose - .0003*d$dose^2 + rnorm(45, 0, .5)
f <- agri_np_regression(yield ~ dose, d, method = "smoothing_spline")
# Example 1
agri_np_plot(f, type = "fit")
# Example 2
agri_np_plot(f, type = "residuals")
# Example 3
agri_np_plot(f, type = "derivative")

# A two-predictor surface is also available for multivariable engines.
if (requireNamespace("mgcv", quietly = TRUE)) {
  ds <- expand.grid(N = seq(0, 180, length.out = 12), water = seq(0.5, 1.0, length.out = 8))
  ds$yield <- 4 + .07 * ds$N - .0002 * ds$N^2 + 5 * ds$water + rnorm(nrow(ds), 0, .5)
  fs <- agri_np_regression(yield ~ N + water, ds, method = "gam", gam_structure = "tensor")
  agri_np_plot(fs, type = "surface", surface_predictors = c("N", "water"), n = 35)
}
}
