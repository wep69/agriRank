\name{export_results}
\alias{export_results}
\title{Export an agriRank analysis bundle}
\description{Batch, inferential-sensitivity, and missing-data characterization objects are also supported by the common table/report/export layer. Stores the scientifically relevant components of supported agriRank analysis results in an RDS bundle for reproducibility and downstream archiving.}
\usage{
export_results(x, file = "agriRank-results.rds")
}
\arguments{
  \item{x}{An agriRank result object, including \code{agri_rank_fit}, \code{agri_np_reg_fit}, \code{agri_multivariate_fit}, \code{agri_ancova_fit}, \code{agri_trend}, \code{agri_power}, \code{agri_batch}, \code{agri_sensitivity}, or \code{agri_missing_report}.}
  \item{file}{Output RDS path.}
}
\details{
Experimental-design bundles include the declared design, omnibus inference, effect information when available, missingness, method, seed and session metadata. Regression bundles include the original and fitted formulas, response, predictors, block adjustment, method, shape constraint, quantile, predictive metrics, fitted values, residuals, backend class and session metadata. Integer-support bundles also record the support mode, focal integer predictor, admissible values, observed integer values, and latent/base engine when applicable.
}
\value{The normalized path of the RDS file.}
\examples{
# Example 1: export a CRD analysis
f <- np_crd(yield ~ treatment, simulate_agri("crd"))
export_results(f, tempfile(fileext = ".rds"))

# Example 2: inspect a regression bundle
set.seed(84)
d <- data.frame(x = seq(0, 10, length.out = 30))
d$y <- sin(d$x/2) + rnorm(30, 0, .15)
r <- agri_np_regression(y ~ x, d, method = "loess")
z <- tempfile(fileext = ".rds")
export_results(r, z)
names(readRDS(z))

# Example 3: export a repeated incomplete fit
x <- simulate_agri("repeated_missing")
des <- agri_design(height ~ treatment*time, x, "repeated", subject = subject, within = time)
fr <- agri_rank(des, "incomplete_wild", B = 99, missing_assumption = "MCAR")
export_results(fr, tempfile(fileext = ".rds"))
}
\seealso{\code{\link{agri_report}}, \code{\link{agri_dashboard}}, \code{\link{agri_np_regression}}}
