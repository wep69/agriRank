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
data(agri_dose)
f <- agri_np_regression(yield ~ dose, agri_dose, method = "smoothing_spline")

# Example 1: fitted response. The result is a ggplot, so units belong in labs().
agri_np_plot(f, type = "fit") +
  ggplot2::labs(x = expression("Nitrogen rate (kg ha"^-1*")"),
                y = expression("Yield (Mg ha"^-1*")"))

# Example 2: residuals against the fitted values
agri_np_plot(f, type = "residuals")

# Example 3: derivative, the agronomic return per extra unit of nitrogen
agri_np_plot(f, type = "derivative") +
  ggplot2::labs(x = expression("Nitrogen rate (kg ha"^-1*")"),
                y = expression("Marginal yield (Mg ha"^-1*" per kg ha"^-1*")")) +
  ggplot2::geom_hline(yintercept = 0, linetype = 2)
# Where the derivative crosses zero the response stops paying.

# Example 4: response surface over two interacting gradients
data(agri_surface)
if (requireNamespace("mgcv", quietly = TRUE)) {
  fs <- agri_np_regression(yield ~ nitrogen + water, agri_surface,
                           method = "gam", gam_structure = "tensor")
  agri_np_plot(fs, type = "surface",
               surface_predictors = c("nitrogen", "water"), n = 35) +
    ggplot2::labs(x = expression("Nitrogen rate (kg ha"^-1*")"),
                  y = "Irrigation depth (fraction of ETc)")
}
}
