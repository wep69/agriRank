\name{agri_np_significance}
\alias{agri_np_significance}
\title{Test predictor significance in mixed-data kernel regression}
\description{Applies the bootstrap significance test implemented by \code{np::npsigtest()} to an \code{agriRank} continuous/mixed-data or ordered-discrete kernel regression. Continuous, ordered and unordered predictors can be tested individually or jointly.}
\usage{
agri_np_significance(
  object,
  variables = NULL,
  joint = FALSE,
  B = 399L,
  boot_method = c("wild-rademacher", "wild", "iid", "pairwise"),
  boot_type = c("II", "I"),
  pivot = TRUE,
  seed = 42L,
  ...
)
}
\arguments{
  \item{object}{An \code{agri_np_reg_fit} fitted with \code{method = "kernel"} or \code{method = "discrete_kernel"}.}
  \item{variables}{Character vector of scientific predictors to test. By default, predictors in the original formula are tested and a separately declared block remains only in the conditioning set.}
  \item{joint}{If \code{TRUE}, test the selected predictors jointly.}
  \item{B}{Number of bootstrap replications.}
  \item{boot_method}{Bootstrap method accepted by \code{np::npsigtest()}.}
  \item{boot_type}{Type-II or Type-I bootstrap calibration. Type II is more computationally intensive.}
  \item{pivot}{Use the pivotal statistic.}
  \item{seed}{Reproducible bootstrap seed.}
  \item{...}{Additional arguments passed to \code{np::npsigtest()}.}
}
\details{
This function tests the relevance of predictors within a nonparametric kernel regression; it is not a field-randomization test. A declared agronomic block is retained in the fitted kernel model as a categorical adjustment variable but is excluded from the default set of scientific predictors being tested.

The default Type-II calibration is deliberately conservative computationally because the \pkg{np} documentation notes that Type I can be somewhat oversized in modest samples in some settings. Small bootstrap counts used in examples are for speed only.
}
\value{The \pkg{np} significance-test object, with attributes recording the tested variables, block adjustment and an interpretation note.}
\references{
Racine JS, Hart J, Li Q (2006). Testing the Significance of Categorical Predictor Variables in Nonparametric Regression Models. \emph{Econometric Reviews}, 25(4), 523--544. doi:10.1080/07474930600972590.

Hayfield T, Racine JS (2008). Nonparametric Econometrics: The np Package. \emph{Journal of Statistical Software}, 27(5). doi:10.18637/jss.v027.i05.
}
\examples{
# Example 1: one continuous predictor
if (requireNamespace("np", quietly = TRUE)) {
  set.seed(91)
  d <- data.frame(dose = runif(35, 0, 180))
  d$yield <- 5 + .06*d$dose - .00018*d$dose^2 + rnorm(35, 0, .5)
  f <- agri_np_regression(yield ~ dose, d, method = "kernel")
  agri_np_significance(f, B = 19, boot_type = "I")
}

# Example 2: test one variable from a mixed-predictor kernel model
if (requireNamespace("np", quietly = TRUE)) {
  set.seed(92)
  d2 <- data.frame(dose = runif(40, 0, 150), cultivar = factor(rep(c("A", "B"), 20)))
  d2$yield <- 4 + .05*d2$dose + ifelse(d2$cultivar == "B", 1, 0) + rnorm(40, 0, .5)
  f2 <- agri_np_regression(yield ~ dose + cultivar, d2, method = "kernel")
  agri_np_significance(f2, variables = "cultivar", B = 19, boot_type = "I")
}

# Example 3: joint significance while retaining an RCBD block adjustment
if (requireNamespace("np", quietly = TRUE)) {
  set.seed(93)
d3 <- expand.grid(block = factor(1:4), dose = seq(0, 120, length.out = 8), 
    cultivar = factor(c("A", "B")))
d3$yield <- 5 + 0.05 * d3$dose + as.numeric(d3$block)/5 + ifelse(d3$cultivar == 
    "B", 0.8, 0) + rnorm(nrow(d3), 0, 0.45)
  f3 <- agri_np_regression(yield ~ dose + cultivar, d3, method = "kernel", block = block)
  agri_np_significance(f3, variables = c("dose", "cultivar"), joint = TRUE, B = 19, boot_type = "I")
}
}
\seealso{\code{\link{agri_np_regression}}, \code{\link{agri_np_specification}}, \code{\link{agri_np_compare}}}
