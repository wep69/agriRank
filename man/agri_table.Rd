\name{agri_table}
\alias{agri_table}
\title{Create standardized agriRank analysis tables}
\description{Batch, inferential-sensitivity, and missing-data characterization objects are also supported by the common table/report/export layer. Creates publication-oriented tables from experimental-design, regression, multivariate, ANCOVA, ordered-trend, or simulation-power results. When \pkg{gt} is installed, the returned data are upgraded to a \code{gt_tbl}.}
\usage{
agri_table(
  x,
  what = c("omnibus", "effects", "pairs", "missing", "metrics",
    "coefficients", "levels", "predictions", "derivative", "optimum",
    "integer_predictions", "integer_optimum", "integer_efficiency"),
  ...,
  format = c("auto", "data.frame", "gt", "rtf")
)
}
\arguments{
  \item{x}{An agriRank result object, including \code{agri_rank_fit}, \code{agri_np_reg_fit}, \code{agri_multivariate_fit}, \code{agri_ancova_fit}, \code{agri_trend}, \code{agri_power}, \code{agri_batch}, \code{agri_sensitivity}, or \code{agri_missing_report}.}
  \item{what}{For experimental-design fits: \code{"omnibus"}, \code{"effects"}, \code{"pairs"}, or \code{"missing"}. For regression fits: \code{"metrics"}, \code{"coefficients"}, \code{"levels"}, \code{"predictions"}, \code{"derivative"}, \code{"optimum"}, \code{"integer_predictions"}, \code{"integer_optimum"}, or \code{"integer_efficiency"}. If omitted for a regression fit, \code{"metrics"} is used.}
  \item{...}{Additional arguments passed to the selected component, such as the focal predictor for derivative or optimum calculations, or \code{method}, \code{B}, \code{seed}, \code{cluster} and \code{fixed} for the coefficient and level tables.}
  \item{format}{\code{"data.frame"} returns a plain editable data frame, the form a manuscript table needs; \code{"gt"} upgrades to a \code{gt_tbl} when the package is installed; \code{"rtf"} writes an RTF file via \code{gt::gtsave()} for direct import into Word or LibreOffice; \code{"auto"} uses \pkg{gt} when available.}
}
\details{
Tables never change the fitted statistical model. Regression prediction tables contain observed, fitted and residual values at the training observations. The \code{"coefficients"} table reports each coefficient with its confidence interval via \code{\link{confint.agri_np_reg_fit}}, because an estimate without uncertainty invites an exactness the model does not have. The \code{"levels"} table, computed by \code{\link{agri_np_levels}}, describes the response at each level of the qualitative predictors: the observed location and spread beside the fitted marginal response with a pointwise bootstrap interval. Derivative and optimum tables are derived from the fitted regression surface and inherit the interpretive limits documented in \code{agri_np_derivative()} and \code{agri_np_optimum()}. Integer-support tables evaluate only the declared admissible support; they never obtain an operational optimum by rounding a continuous optimum.
}
\value{A data frame or, when \pkg{gt} is available, a \code{gt_tbl}.}
\references{
Konietschke F, Brunner E (2023). rankFD: An R Software Package for Nonparametric Analysis of General Factorial Designs. \emph{The R Journal}, 15, 142--158. doi:10.32614/RJ-2023-029.

Hayfield T, Racine JS (2008). Nonparametric Econometrics: The np Package. \emph{Journal of Statistical Software}, 27(5). doi:10.18637/jss.v027.i05.
}
\examples{
# Example 1: omnibus table from a CRD
f1 <- np_crd(yield ~ treatment, simulate_agri("crd"))
agri_table(f1, "omnibus")

# Example 2: regression diagnostics table
set.seed(81)
d <- data.frame(dose = seq(0, 160, length.out = 30))
d$yield <- 5 + .07*d$dose - .00025*d$dose^2 + rnorm(30, 0, .35)
r <- agri_np_regression(yield ~ dose, d, method = "smoothing_spline")
agri_table(r, "metrics")

# Example 3: integer-support decision table
di <- data.frame(plants = rep(1:8, each = 5))
di$yield <- 20 + 7*di$plants - .55*di$plants^2 + rnorm(nrow(di))
ri <- agri_np_regression(yield ~ plants, di, method = "integer_grid",
  integer_base_method = "smoothing_spline")
agri_table(ri, "integer_optimum")

# Example 4: coefficient and level tables for a model with a qualitative factor
if (requireNamespace("quantreg", quietly = TRUE)) {
  data(agri_dose)
  dz <- agri_dose
  dz$cultivar <- factor(rep(c("Ana", "Bela"), length.out = nrow(dz)))
  dz$yield <- dz$yield + ifelse(dz$cultivar == "Bela", 0.9, 0)
  fm <- agri_np_regression(yield ~ dose + cultivar, dz, method = "quantile")
  # B = 19 keeps the example fast; a real analysis needs B >= 999.
  agri_table(fm, "coefficients", method = "bootstrap", B = 19, seed = 1)
  agri_table(fm, "levels", B = 19, seed = 1)
}
}
\seealso{\code{\link{agri_report}}, \code{\link{agri_np_regression}}, \code{\link{agri_np_levels}}, \code{\link{confint.agri_np_reg_fit}}, \code{\link{agri_np_derivative}}, \code{\link{agri_np_optimum}}, \code{\link{agri_integer_optimum}}}
