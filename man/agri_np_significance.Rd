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
# B = 19 keeps the examples fast. Use B >= 999 for any reported test.

# Example 1: does nitrogen matter at all?
data(agri_dose)
if (requireNamespace("np", quietly = TRUE)) {
  f <- agri_np_regression(yield ~ dose, agri_dose, method = "kernel")
  agri_np_significance(f, B = 19, boot_type = "I")
  # A small p-value says the response is not flat. It does not say the
  # relationship is linear, nor where the optimum is.
}

# Example 2: one gradient in the presence of another
data(agri_surface)
if (requireNamespace("np", quietly = TRUE)) {
  f2 <- agri_np_regression(yield ~ nitrogen + water, agri_surface, method = "kernel")
  agri_np_significance(f2, variables = "water", B = 19, boot_type = "I")
}

# Example 3: joint significance while retaining the block adjustment
if (requireNamespace("np", quietly = TRUE)) {
  f3 <- agri_np_regression(yield ~ nitrogen + water, agri_surface,
                           method = "kernel", block = block)
  agri_np_significance(f3, variables = c("nitrogen", "water"), joint = TRUE,
                       B = 19, boot_type = "I")
  # The joint test asks whether the two gradients together explain the
  # response, which is the right question when they interact.
}
}
\seealso{\code{\link{agri_np_regression}}, \code{\link{agri_np_specification}}, \code{\link{agri_np_compare}}}
