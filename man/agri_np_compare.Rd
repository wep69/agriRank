\name{agri_np_compare}
\alias{agri_np_compare}
\title{Cross-validated comparison of agronomic regression engines}
\usage{
agri_np_compare(formula, data, methods = c("smoothing_spline", "loess", "kernel", "gam"),
  block = NULL, kfold = 5L, seed = 1, metric = c("RMSE", "MAE", "MedAE"), ...)
}
\arguments{
  \item{formula}{Regression formula.}
  \item{data}{Data frame.}
  \item{methods}{Character vector of regression engines.}
  \item{block}{Optional block variable used to stratify folds.}
  \item{kfold}{Number of folds.}
  \item{seed}{Random seed.}
  \item{metric}{Primary predictive-error metric.}
  \item{...}{Arguments passed to \code{agri_np_regression()}.}
}
\description{Compares predictive accuracy by cross-validation without selecting an inferential method by p-value.}
\details{When blocks are supplied, fold assignment is stratified within block so each block remains represented in training data. Results rank predictive error only and do not establish that one method has a more appropriate estimand or inferential null hypothesis.}
\value{A data frame ordered by the requested error metric.}
\examples{
# Cross-validation compares predictive error. It does not test a hypothesis and
# must not be used to pick the engine with the smallest p-value.
data(agri_dose)

# Example 1: four engines on the nitrogen gradient, RMSE in Mg/ha
if (requireNamespace("mgcv", quietly = TRUE)) {
  agri_np_compare(yield ~ dose, agri_dose, kfold = 4, seed = 1,
                  methods = c("smoothing_spline", "loess", "gam", "quantile"))
}

# Example 2: median absolute error, less sensitive to a single bad plot
agri_np_compare(yield ~ dose, agri_dose, kfold = 4, seed = 1,
                methods = c("smoothing_spline", "loess"), metric = "MedAE")

# Example 3: keeping the agronomic block in every candidate model
if (requireNamespace("mgcv", quietly = TRUE)) {
  agri_np_compare(yield ~ dose, agri_dose, methods = c("gam", "quantile"),
                  block = block, kfold = 3, seed = 2)
  # A difference of a few hundredths of a Mg/ha between engines is not
  # agronomic evidence; prefer the engine justified by the design.
}
}
