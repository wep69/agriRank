\name{agri_np_regression}
\alias{agri_np_regression}
\title{Fit nonparametric and semiparametric regression models for agronomic data}
\usage{
agri_np_regression(formula, data = NULL, method = c("auto", 
    "theil_sen", "siegel", "quantile", "loess", "smoothing_spline", 
    "kernel", "gam", "scam", "cobs", "isotonic", "discrete_kernel", 
    "unimodal_isotonic", "umbrella", "integer_grid"), 
    tau = 0.5, family = stats::gaussian(), shape = c("none", 
        "increasing", "decreasing", "convex", "concave", 
        "increasing_convex", "increasing_concave", 
        "decreasing_convex", "decreasing_concave"), 
    block = NULL, weights = NULL, na_action = c("fail", 
        "complete"), span = 0.75, degree = 2L, k = 10L, 
    gam_structure = c("additive", "tensor"), kernel_regtype = c("ll", 
        "lc"), bwmethod = "cv.aic", predictor_support = c("continuous", 
        "observed_integer", "integer_range", "custom_integer"), 
    integer_predictor = NULL, integer_range = NULL, 
    integer_values = NULL, integer_kernel = c("wangvanryzin", 
        "liracine"), integer_base_method = c("gam", 
        "scam", "kernel", "quantile", "loess", "smoothing_spline", 
        "cobs"), ...)
}
\arguments{
  \item{formula}{Regression formula with one response, or an \code{agri_design} object.}
  \item{data}{Data frame; optional when an \code{agri_design} object is supplied.}
  \item{method}{Regression engine.}
  \item{tau}{Conditional quantile for quantile or COBS regression.}
  \item{family}{Response family for GAM/SCAM.}
  \item{shape}{Optional monotonicity or curvature constraint.}
  \item{block}{Optional agronomic block variable. Engines that cannot adjust for blocks are rejected when this is supplied.}
  \item{weights}{Optional observation weights. Unsupported weight-method combinations fail explicitly.}
  \item{na_action}{Missing-data handling. \code{"fail"} (default) prevents silent row deletion; \code{"complete"} explicitly uses complete modeled rows and records how many were omitted.}
  \item{span}{LOESS span.}
  \item{degree}{LOESS or COBS polynomial degree where applicable.}
  \item{k}{Basis dimension used in automatically generated GAM/SCAM smooths.}
  \item{gam_structure}{Use separate additive smooths or a tensor-product smooth for the first two numeric predictors in automatically generated GAM formulas.}
  \item{kernel_regtype}{Use local-linear (\code{"ll"}, default) or local-constant (\code{"lc"}) kernel regression with \pkg{np}.}
  \item{bwmethod}{Bandwidth-selection method for \pkg{np}.}
  \item{predictor_support}{Decision support for integer-valued predictors: observed tested integers, all integers in a range, or a custom set.}
  \item{integer_predictor}{Optional name of the focal integer-valued predictor.}
  \item{integer_range}{Two integer bounds when \code{predictor_support = "integer_range"}.}
  \item{integer_values}{Explicit admissible integer values when \code{predictor_support = "custom_integer"}.}
  \item{integer_kernel}{Ordered-discrete kernel used by \code{method = "discrete_kernel"}.}
  \item{integer_base_method}{Latent flexible regression engine used by \code{method = "integer_grid"}.}
  \item{...}{Additional backend arguments.}
}
\description{
Unified agronomic regression workflow containing strictly nonparametric smoothers, rank-robust estimators, conditional-quantile models, and modern semiparametric smoothers.
}
\details{
Strictly nonparametric engines are \code{"loess"}, \code{"smoothing_spline"}, \code{"kernel"}, \code{"isotonic"}, \code{"cobs"}, \code{"discrete_kernel"}, and \code{"unimodal_isotonic"}. The \code{"umbrella"} pathway is a constrained generalized additive/order-restricted model, while \code{"integer_grid"} fits a selected flexible latent model but projects every public prediction and decision onto an admissible integer support. Rank-robust or semiparametric companions are \code{"theil_sen"}, \code{"siegel"}, \code{"quantile"}, \code{"gam"}, and \code{"scam"}.

For integer-valued agronomic inputs, agriRank does not round a continuous optimum after fitting. It evaluates the fitted response directly over a declared set \eqn{\mathcal{X}_I} of admissible integers and defines the optimum as \eqn{x^* = \arg\max_{x\in\mathcal{X}_I} \hat m(x)} (or the corresponding minimum). With \code{predictor_support = "observed_integer"}, untested integer treatments are not interpolated. \code{"integer_range"} explicitly permits interpolation to every integer between the chosen bounds.

The \code{"auto"} rule uses the predictor structure, family and an explicitly requested shape constraint. It does not inspect significance tests or choose the model yielding the smallest p-value. Declared blocks are retained as adjustment terms for kernel, quantile, GAM and SCAM workflows; unsupported block-method combinations fail explicitly. Regression objects created from an \code{agri_design} inherit its block and quantitative-treatment declaration. Repeated/longitudinal design objects are currently rejected because subject dependence requires a validated subject-aware regression adapter. Missing values in the modeled response, predictors, block, or weights stop the fit by default. Complete-row regression is available only through explicit \code{na_action = "complete"}; it is not an imputation procedure or a substitute for a missing-data model.

Qualitative predictors such as cultivar, soil class or management system are handled explicitly. A character column is read as the factor it is, and a factor needs at least two levels to enter a model, because a single level carries no contrast against the response. Engines \code{"quantile"}, \code{"kernel"}, \code{"gam"} and \code{"scam"} keep qualitative factors as adjustment terms; curve-only engines (\code{"theil_sen"}, \code{"siegel"}, \code{"smoothing_spline"}, \code{"cobs"}, \code{"isotonic"}, \code{"unimodal_isotonic"} and \code{"loess"}) refuse them by name instead of silently dropping them. For engines with interpretable coefficients, each non-reference level of a factor enters as one coefficient, whose bootstrap interval can be displayed with \code{\link{agri_np_forest}}.
}
\value{An object of class \code{agri_np_reg_fit} containing the selected method, backend fit, training data, the numeric and qualitative predictor sets, fitted values, residuals and predictive-error summaries.}
\references{
Hayfield, T. and Racine, J. S. (2008). Nonparametric Econometrics: The np Package. \emph{Journal of Statistical Software}, 27(5). doi:10.18637/jss.v027.i05.

Pya, N. and Wood, S. N. (2015). Shape constrained additive models. \emph{Statistics and Computing}, 25, 543-559. doi:10.1007/s11222-013-9448-7.

Sen, P. K. (1968). Estimates of the Regression Coefficient Based on Kendall's Tau. \emph{Journal of the American Statistical Association}, 63, 1379-1389. doi:10.1080/01621459.1968.10480934.

Racine, J. and Li, Q. (2004). Nonparametric estimation of regression functions with both categorical and continuous data. \emph{Journal of Econometrics}, 119, 99-130. doi:10.1016/S0304-4076(03)00157-X.

Turner, T. R. and Wollan, P. C. (1997). Locating a maximum using isotonic regression. \emph{Computational Statistics & Data Analysis}, 25, 305-320. doi:10.1016/S0167-9473(97)00009-1.

Liao, X. and Meyer, M. C. (2019). cgam: An R Package for the Constrained Generalized Additive Model. \emph{Journal of Statistical Software}, 89(5). doi:10.18637/jss.v089.i05.
}
\seealso{\code{\link{agri_np_predict}}, \code{\link{agri_integer_predict}}, \code{\link{agri_integer_optimum}}, \code{\link{agri_integer_difference}}, \code{\link{agri_integer_bootstrap}}, \code{\link{agri_np_compare}}, \code{\link{agri_np_plot}}}
\examples{
# All examples use the exported data sets, so the fitted objects stay in the
# session and can be explored further. Yield is in Mg/ha, nitrogen in kg/ha and
# plant density in plants per hill.

# Example 1: smoothing spline over a nitrogen gradient
data(agri_dose)
fit1 <- agri_np_regression(yield ~ dose, agri_dose, method = "smoothing_spline")
fit1
# The response flattens beyond roughly 200 kg/ha: no parametric quadratic
# reproduces both the rising part and the plateau.

# Example 2: LOESS on the same gradient, for comparison of smoothers
fit2 <- agri_np_regression(yield ~ dose, agri_dose, method = "loess", span = 0.6)
summary(fit2)

# Example 3: block-adjusted GAM, the design-aware choice for this trial
if (requireNamespace("mgcv", quietly = TRUE)) {
  fit3 <- agri_np_regression(yield ~ dose, agri_dose, method = "gam", block = block)
  summary(fit3)
  # Adjusting for block removes soil-fertility variation from the residual.
}

# Example 4: direct transition from a declared quantitative RCBD
if (requireNamespace("mgcv", quietly = TRUE)) {
  des <- agri_design(yield ~ dose, agri_dose, design = "rcbd",
                     block = block, quantitative = dose)
  fit4 <- agri_np_regression(des, method = "gam")
  fit4
  # The block declared in the design is carried into the regression.
}

# Example 5: ordered-discrete kernel regression on an integer treatment
data(agri_density)
if (requireNamespace("np", quietly = TRUE)) {
  fit5 <- agri_np_regression(yield ~ plants, agri_density,
                             method = "discrete_kernel",
                             predictor_support = "observed_integer")
  agri_integer_predict(fit5)
}

# Example 6: unimodal isotonic plant-density response
if (requireNamespace("Iso", quietly = TRUE)) {
  fit6 <- agri_np_regression(yield ~ plants, agri_density,
                             method = "unimodal_isotonic",
                             predictor_support = "observed_integer")
  agri_integer_optimum(fit6)
  # Density responses rise and then fall through competition, so an
  # increase-then-decrease constraint is scientifically justified here.
}

# Example 7: continuous latent spline, integer-only decisions
fit7 <- agri_np_regression(yield ~ plants, agri_density, method = "integer_grid",
                           integer_base_method = "smoothing_spline",
                           predictor_support = "observed_integer")
agri_integer_difference(fit7, order = 1)
# Each row is the yield gain, in Mg/ha, of adding one more plant per hill.

# Example 8: umbrella-order regression with an RCBD block adjustment
if (requireNamespace("cgam", quietly = TRUE)) {
  fit8 <- agri_np_regression(yield ~ plants, agri_density, method = "umbrella",
                             block = block, predictor_support = "observed_integer")
  agri_integer_optimum(fit8)
}

# Example 9: two interacting gradients
data(agri_surface)
if (requireNamespace("mgcv", quietly = TRUE)) {
  fit9 <- agri_np_regression(yield ~ nitrogen + water, agri_surface,
                             method = "gam", gam_structure = "tensor")
  agri_np_predict(fit9, newdata = data.frame(nitrogen = 160, water = c(0.6, 1.0)))
  # The return to 160 kg/ha of nitrogen depends on irrigation depth.
}

# Example 10: a qualitative factor alongside the nitrogen gradient
if (requireNamespace("quantreg", quietly = TRUE)) {
  dzc <- agri_dose
  dzc$cultivar <- factor(rep(c("Ana", "Bela"), length.out = nrow(dzc)))
  dzc$yield <- dzc$yield + ifelse(dzc$cultivar == "Bela", 0.9, 0)
  fit10 <- agri_np_regression(yield ~ dose + cultivar, dzc, method = "quantile")
  coef(fit10)
  # Cultivar Bela adds about 0.9 Mg/ha at every nitrogen rate; the dose slope
  # is shared by both cultivars. Plot the intervals with agri_np_forest().
}

}
