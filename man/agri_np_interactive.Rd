\name{agri_np_interactive}
\alias{agri_np_interactive}
\title{Interactive Plotly graphics for agronomic nonparametric regression}
\usage{
agri_np_interactive(object, type = c("fit", "residuals", 
    "derivative", "surface"), ...)
}
\arguments{
  \item{object}{An \code{agri_np_reg_fit}.}
  \item{type}{Fit, residual, derivative, or response-surface plot.}
  \item{...}{Arguments passed to \code{agri_np_plot()}, including \code{predictor}, \code{fixed}, \code{group}, and \code{surface_predictors}.}
}
\description{Converts an editable ggplot2 regression graphic to an interactive Plotly object for exploratory inspection and HTML reporting.}
\details{The interactive layer does not refit the model, change the estimand, or alter inferential results. Static ggplot2 figures remain the primary publication graphics.}
\value{A Plotly htmlwidget.}
\seealso{\code{\link{agri_np_plot}}, \code{\link{agri_np_regression}}}
\examples{
set.seed(38)
d <- data.frame(dose = seq(0, 150, length.out = 40))
d$yield <- 5 + .08*d$dose - .0003*d$dose^2 + rnorm(40, 0, .5)
f <- agri_np_regression(yield ~ dose, d, method = "smoothing_spline")
# Example 1
if (requireNamespace("plotly", quietly = TRUE)) agri_np_interactive(f)
# Example 2
if (requireNamespace("plotly", quietly = TRUE)) agri_np_interactive(f, type = "derivative")
# Example 3: response surface
if (requireNamespace("plotly", quietly = TRUE) && requireNamespace("mgcv", quietly = TRUE)) {
  ds <- expand.grid(N = seq(0, 180, length.out = 10), water = seq(.5, 1, length.out = 7))
  ds$yield <- 4 + .07*ds$N - .0002*ds$N^2 + 4*ds$water + rnorm(nrow(ds), 0, .4)
  fs <- agri_np_regression(yield ~ N + water, ds, method = "gam", gam_structure = "tensor")
  agri_np_interactive(fs, type = "surface", surface_predictors = c("N", "water"), n = 30)
}
}
