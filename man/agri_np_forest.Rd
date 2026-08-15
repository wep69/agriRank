\name{agri_np_forest}
\alias{agri_np_forest}
\title{Forest plot of bootstrap intervals for regression coefficients}
\usage{
agri_np_forest(
  object,
  bootstrap = NULL,
  B = 499L,
  level = 0.95,
  seed = 1,
  cluster = NULL,
  by_factor = TRUE,
  include_intercept = FALSE,
  palette = c("color", "grey"),
  annotate_values = FALSE,
  digits = 2,
  order_by = c("model", "effect"),
  ref_line = 0,
  caption = "Reference level at zero; intervals show where the zero line is excluded."
)
}
\arguments{
  \item{object}{An \code{agri_np_reg_fit} whose engine defines interpretable coefficients.}
  \item{bootstrap}{Optional \code{agri_np_bootstrap} object computed with \code{target = "coefficients"}. When absent, one is computed here.}
  \item{B}{Number of bootstrap replications when \code{bootstrap} is not supplied.}
  \item{level}{Confidence level.}
  \item{seed}{Random seed.}
  \item{cluster}{Optional cluster variable passed to \code{\link{agri_np_bootstrap}}; the declared agronomic block is used by default when available.}
  \item{by_factor}{Stack the coefficients of qualitative predictors one row per level, grouped by factor, with the reference level drawn at zero.}
  \item{include_intercept}{Keep the intercept in the figure. By default it is excluded: it is a location parameter reported by the coefficient table, and on the figure's axis it would dominate slopes and contrasts.}
  \item{palette}{Discrete colour palette: \code{"color"} uses the colour-blind-safe Okabe-Ito palette; \code{"grey"} uses grey tones safe for black-and-white print.}
  \item{annotate_values}{If \code{TRUE}, write the estimate and interval as text to the right of each bar, so the figure is self-contained and does not require the reader to cross-reference a table.}
  \item{digits}{Significant digits for annotation text and axis tick labels.}
  \item{order_by}{\code{"model"} preserves the coefficient order; \code{"effect"} sorts rows by absolute estimate within each panel.}
  \item{ref_line}{Numeric position of the vertical reference line. Zero is the default, indicating no effect.}
  \item{caption}{Optional caption below the figure, explaining the reading.}
}
\description{
Draws one row per regression coefficient with its bootstrap confidence interval around the zero line, for the engines that define interpretable coefficients (\code{theil_sen}, \code{siegel} and \code{quantile}).
}
\details{
Each row shows the coefficient estimate as a point and the bootstrap percentile interval as a horizontal bar, against the vertical zero line that separates positive from negative effects. The intervals come from \code{\link{agri_np_bootstrap}} with \code{target = "coefficients"}, which aligns replicates by term name, so a reordered or level-depleted replicate is counted as a failed refit instead of being read in the original order.

When the model contains qualitative predictors, \code{by_factor = TRUE} stacks the coefficients of each factor one level per row inside the factor's own panel and draws the reference level at zero, so every level of the factor appears in the figure instead of only the \eqn{k - 1} dummy contrasts. The reference row is a visual anchor, not an estimate.

Block adjustment terms never enter the figure: they are nuisance parameters whose meaning changes with every draw of the blocks under cluster resampling, and the coefficient bootstrap excludes them from its target for that reason.

A forest plot displays uncertainty in coefficients; it does not test hypotheses and must not be used to search over models for the smallest interval.
}
\value{A \code{ggplot} object.}
\seealso{\code{\link{agri_np_bootstrap}}, \code{\link{agri_np_plot}}, \code{\link{coef.agri_np_reg_fit}}, \code{\link{confint.agri_np_reg_fit}}}
\examples{
data(agri_dose)
dz <- agri_dose
# A qualitative companion for the nitrogen gradient: two cultivars that share
# the dose response but differ in baseline yield (Mg/ha).
dz$cultivar <- factor(rep(c("Ana", "Bela"), length.out = nrow(dz)))
dz$yield <- dz$yield + ifelse(dz$cultivar == "Bela", 0.9, 0)

if (requireNamespace("quantreg", quietly = TRUE)) {
  fit <- agri_np_regression(yield ~ dose + cultivar, dz, method = "quantile")
  coef(fit)

  # B = 19 keeps this example fast; a real analysis needs B >= 999.
  bt <- agri_np_bootstrap(fit, target = "coefficients", B = 19, seed = 1)
  agri_np_forest(fit, bootstrap = bt)
  # Cultivar Bela shifts the whole dose-response curve upward by about
  # 0.9 Mg/ha; reading its interval against the zero line is the point of
  # the figure.
}
}
