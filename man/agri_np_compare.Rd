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
set.seed(33)
d <- data.frame(x = seq(0, 12, length.out = 48)); d$y <- 3 + sin(d$x/2) + rnorm(48, 0, .3)
# Example 1
agri_np_compare(y ~ x, d, methods = c("smoothing_spline", "loess"), kfold = 4)
# Example 2
agri_np_compare(y ~ x, d, methods = c("smoothing_spline", "loess"), kfold = 4, metric = "MAE")
# Example 3: stratified by agronomic block
b <- transform(expand.grid(block = factor(1:4), x = seq(0, 10, length.out = 12)),
               y = 4 + sin(x/2) + as.numeric(block)/5 + rnorm(48, 0, .25))
if (requireNamespace("mgcv", quietly = TRUE))
  agri_np_compare(y ~ x, b, methods = c("gam"), block = block, kfold = 3)
}
