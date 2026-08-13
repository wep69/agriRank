\name{agri_np_bootstrap}
\alias{agri_np_bootstrap}
\title{Cluster-aware bootstrap confidence bands for agronomic regression}
\usage{
agri_np_bootstrap(object, newdata = NULL, predictor = NULL, B = 499L, level = 0.95,
  seed = 1, cluster = NULL, n = 200L, fixed = list())
}
\arguments{
  \item{object}{An \code{agri_np_reg_fit}.}
  \item{newdata}{Prediction grid; generated automatically if omitted.}
  \item{predictor}{Numeric focal predictor.}
  \item{B}{Bootstrap replicates.}
  \item{level}{Interval level.}
  \item{seed}{Random seed.}
  \item{cluster}{Optional resampling cluster. The declared block is used by default when available.}
  \item{n}{Automatic grid size.}
  \item{fixed}{Values for other covariates.}
}
\description{Refits the selected regression engine under row or cluster resampling and returns pointwise percentile bands.}
\details{When a block or cluster is supplied, whole clusters are resampled. The resulting intervals are pointwise percentile intervals, not simultaneous bands. Large \code{B} should be used for final inference.}
\value{A data frame containing the prediction grid, original fitted curve, lower and upper bootstrap limits, with bootstrap metadata as attributes.}
\examples{
set.seed(36)
d <- data.frame(x = seq(0, 10, length.out = 35)); d$y <- sin(d$x/2) + rnorm(35, 0, .25)
f <- agri_np_regression(y ~ x, d, method = "smoothing_spline")
# Example 1: small teaching bootstrap
b1 <- agri_np_bootstrap(f, B = 19, n = 30)
head(b1)
# Example 2: user-defined prediction grid
b2 <- agri_np_bootstrap(f, newdata = data.frame(x = seq(1, 9, length.out = 20)), B = 19)
head(b2)
# Example 3: block-aware bootstrap with a block-adjustable engine
if (requireNamespace("mgcv", quietly = TRUE)) {
  db <- expand.grid(block = factor(1:4), x = seq(0, 10, length.out = 10))
  db$y <- 5 + sin(db$x/2) + as.numeric(db$block)/4 + rnorm(nrow(db), 0, .2)
  fb <- agri_np_regression(y ~ x, db, method = "gam", block = block)
  head(agri_np_bootstrap(fb, B = 19, n = 20))
}
}
