\name{agri_np_conformal}
\alias{agri_np_conformal}
\alias{agri_np_coverage}
\alias{print.agri_np_conformal}
\alias{plot.agri_np_conformal}
\title{Distribution-free prediction intervals by split conformal inference}
\usage{
agri_np_conformal(
  object,
  newdata = NULL,
  level = 0.95,
  split_by = NULL,
  scope = c("within_block", "new_block"),
  prop = 0.5,
  seed = 1,
  n = 100L,
  fixed = list(),
  normalize = FALSE
)

agri_np_coverage(object, data = NULL, ...)
}
\arguments{
  \item{object}{An \code{agri_np_reg_fit}, or an \code{agri_np_conformal} result for \code{agri_np_coverage()}.}
  \item{newdata}{Prediction data. Defaults to a grid over the observed range.}
  \item{level}{Target coverage.}
  \item{split_by}{Variable defining exchangeable groups for the calibration split. Defaults to the block declared in the fit.}
  \item{scope}{Whether the future observation belongs to an observed block or to a block that was not observed. See details.}
  \item{prop}{Share of groups, or of rows within group, used to refit the model. The rest calibrates.}
  \item{seed}{Random seed for the split.}
  \item{n}{Grid size when \code{newdata} is omitted.}
  \item{fixed}{Values at which other covariates are held.}
  \item{normalize}{If \code{TRUE}, residuals are scaled by a local dispersion estimate.}
  \item{data}{Data with observed responses, for \code{agri_np_coverage()}.}
  \item{...}{Passed to \code{agri_np_conformal()}.}
}
\description{
Prediction intervals with finite-sample marginal coverage that does not depend
on the response distribution nor on the regression engine, with a calibration
split that respects the declared block.
}
\details{
The bootstrap bands of \code{\link{agri_np_bootstrap}} describe where the fitted
\emph{curve} lies. They say nothing, with guarantee, about where the \emph{next
plot} will fall. Split conformal prediction does: for exchangeable data the
interval satisfies \eqn{P(Y_{new} \in \Gamma) \ge 1 - \alpha} in finite samples,
for any engine and any response distribution.

The procedure refits the engine on one part of the data, computes absolute
residuals on the held-out part, and adds the appropriate empirical quantile of
those residuals to the prediction. The quantile uses the finite-sample
correction \eqn{\lceil (n_{cal}+1)(1-\alpha)\rceil / n_{cal}}, which is what
turns an empirical quantile into a guarantee.

\strong{Exchangeability is the whole question, and it is where the declared
design enters.} Two scopes are available, and they answer different questions:

\describe{
  \item{\code{"within_block"}}{The future plot belongs to a block that was observed. Randomization happened inside blocks, so plots within a block are exchangeable. The split is stratified, every block contributes to both parts, and the block term stays in the model.}
  \item{\code{"new_block"}}{The future plot belongs to a block, field or season that was not observed. Exchangeability is then claimed at block level, whole blocks are held out, and the block term must leave the model because a block-specific effect is not estimable outside the observed blocks. The interval is wider, and it should be: it now carries the between-block variation.}
}

Passing \code{split_by = NULL} asserts that individual plots are exchangeable,
which a declared block denies. It is allowed, because the analyst may have a
reason, but it is a scientific claim and not a default.

Coverage is \emph{marginal}, averaged over the gradient. It does not promise the
stated coverage separately at every rate. \code{normalize = TRUE} redistributes
the width across the gradient, wider where the response is noisier, without
changing what is guaranteed.
}
\value{
\code{agri_np_conformal()} returns a data frame of class
\code{agri_np_conformal} with the grid, the prediction and the conformal limits.
\code{agri_np_coverage()} returns a list with the target and empirical coverage,
coverage by block, and the mean interval width.
}
\references{
Vovk, V., Gammerman, A. and Shafer, G. (2005). \emph{Algorithmic Learning in a
Random World}. Springer.

Lei, J., G'Sell, M., Rinaldo, A., Tibshirani, R. J. and Wasserman, L. (2018).
Distribution-free predictive inference for regression. \emph{Journal of the
American Statistical Association}, 113(523), 1094-1111.
\doi{10.1080/01621459.2017.1307116}
}
\seealso{\code{\link{agri_np_bootstrap}}, \code{\link{agri_np_predict}}}
\examples{
data(agri_dose)

# Example 1: an interval for a future plot in one of the observed blocks
if (requireNamespace("mgcv", quietly = TRUE)) {
  f <- agri_np_regression(yield ~ dose, agri_dose, method = "gam", block = block)
  cf <- agri_np_conformal(f, newdata = agri_dose, level = 0.90, seed = 1)
  cf
}

# Example 2: empirical coverage, overall and by block
if (requireNamespace("mgcv", quietly = TRUE)) {
  cv <- agri_np_coverage(cf, data = agri_dose)
  c(target = cv$target, empirical = cv$empirical, width = cv$mean_width)
  cv$by_block
}

# Example 3: the same field, or a field never visited? The second question
# carries between-block variation and the interval widens accordingly.
if (requireNamespace("mgcv", quietly = TRUE)) {
  cw <- agri_np_conformal(f, newdata = agri_dose, level = 0.90, seed = 1,
                          scope = "within_block")
  cn <- agri_np_conformal(f, newdata = agri_dose, level = 0.90, seed = 1,
                          scope = "new_block")
  c(observed_block = mean(cw$upper - cw$lower),
    new_block = mean(cn$upper - cn$lower))
}

# Example 4: three kinds of uncertainty at three nitrogen rates. The first two
# describe the fitted curve; only the conformal one describes a future plot.
if (requireNamespace("mgcv", quietly = TRUE)) {
  nd <- data.frame(dose = c(80, 160, 240),
                   block = factor("B3", levels = levels(agri_dose$block)))
  an <- as.data.frame(agri_np_predict(f, nd, interval = "confidence"))
  bo <- as.data.frame(agri_np_bootstrap(f, newdata = nd, B = 199, seed = 2))
  co <- as.data.frame(agri_np_conformal(f, newdata = nd, level = 0.95, seed = 1))
  data.frame(dose = nd$dose,
             analytic = an$upper - an$lower,
             bootstrap = bo$upper - bo$lower,
             conformal = co$upper - co$lower)
}

# Example 5: locally scaled width, and the figure
if (requireNamespace("mgcv", quietly = TRUE) &&
    requireNamespace("ggplot2", quietly = TRUE)) {
  cn2 <- agri_np_conformal(f, level = 0.90, seed = 1, normalize = TRUE)
  plot(cn2)
}
}
