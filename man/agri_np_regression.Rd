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
}
\value{An object of class \code{agri_np_reg_fit} containing the selected method, backend fit, training data, fitted values, residuals and predictive-error summaries.}
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
# Example 1: smoothing spline for a fertilizer gradient
set.seed(21)
d <- data.frame(dose = seq(0, 200, length.out = 40))
d$yield <- 5 + 0.055 * d$dose - 0.00016 * d$dose^2 + rnorm(40, sd = 0.8)
fit1 <- agri_np_regression(yield ~ dose, d, method = "smoothing_spline")
fit1

# Example 2: LOESS for a nonlinear salinity response
set.seed(22)
d2 <- data.frame(ec = seq(0.5, 6, length.out = 50))
d2$biomass <- 25 * exp(-0.13 * d2$ec^1.5) + rnorm(50, 0, 1)
fit2 <- agri_np_regression(biomass ~ ec, d2, method = "loess", span = 0.6)
summary(fit2)

# Example 3: block-adjusted GAM
if (requireNamespace("mgcv", quietly = TRUE)) {
  set.seed(23)
  d3 <- expand.grid(block = factor(1:5), dose = seq(0, 180, length.out = 12))
  d3$yield <- 8 + 0.07 * d3$dose - 0.00022 * d3$dose^2 +
    as.numeric(d3$block) + rnorm(nrow(d3))
  fit3 <- agri_np_regression(yield ~ dose, d3, method = "gam", block = block)
  summary(fit3)
}
# Example 4: direct transition from a declared quantitative RCBD
if (requireNamespace("mgcv", quietly = TRUE)) {
  dd <- expand.grid(block = factor(1:4), dose = seq(0, 150, length.out = 10))
  set.seed(24);
dd$yield <- 5 + .08*dd$dose - .0003*dd$dose^2 + as.numeric(dd$block)/4 + rnorm(nrow(dd), 0, .4)
  des <- agri_design(yield ~ dose, dd, design = "rcbd", block = block, quantitative = dose)
  fit4 <- agri_np_regression(des, method = "gam")
  fit4
}


# Example 5: ordered-discrete kernel regression
if (requireNamespace("np", quietly = TRUE)) {
  set.seed(25)
  d5 <- data.frame(insects = rep(0:8, each = 6))
  d5$damage <- 4 + 1.7*d5$insects + rnorm(nrow(d5), 0, 1.2)
  fit5 <- agri_np_regression(damage ~ insects, d5, method = "discrete_kernel",
                             predictor_support = "observed_integer")
  agri_integer_predict(fit5)
}

# Example 6: unimodal isotonic plant-density response
if (requireNamespace("Iso", quietly = TRUE)) {
  set.seed(26)
  d6 <- data.frame(plants = rep(1:9, each = 5))
  d6$yield <- 30 + 8*pmin(d6$plants, 5) - 5*pmax(d6$plants - 5, 0) +
    rnorm(nrow(d6), 0, 1.5)
  fit6 <- agri_np_regression(yield ~ plants, d6, method = "unimodal_isotonic")
  agri_integer_optimum(fit6)
}

# Example 7: continuous latent spline, integer-only decisions
set.seed(27)
d7 <- data.frame(plants = rep(1:10, each = 5))
d7$yield <- 25 + 7*d7$plants - .45*d7$plants^2 + rnorm(nrow(d7))
fit7 <- agri_np_regression(yield ~ plants, d7, method = "integer_grid",
                           integer_base_method = "smoothing_spline",
                           predictor_support = "integer_range")
agri_integer_difference(fit7)

# Example 8: umbrella-order regression with an RCBD block adjustment
if (requireNamespace("cgam", quietly = TRUE)) {
  set.seed(28)
  d8 <- expand.grid(block = factor(1:4), plants = 1:8)
  d8$yield <- 24 + 8*pmin(d8$plants, 5) - 5*pmax(d8$plants - 5, 0) +
    as.numeric(d8$block)/2 + rnorm(nrow(d8), 0, 1.2)
  fit8 <- agri_np_regression(yield ~ plants, d8, method = "umbrella",
                             block = block, predictor_support = "observed_integer")
  agri_integer_optimum(fit8)
}

}
