\name{agri_report}
\alias{agri_report}
\title{Generate a reproducible agriRank analysis report}
\description{Batch, inferential-sensitivity, and missing-data characterization objects are also supported by the common table/report/export layer. Writes a reproducible report for experimental-design, regression, multivariate, ANCOVA, ordered-trend, or simulation-power results. Markdown and Quarto source can be produced directly; HTML, Word and PDF rendering uses \pkg{rmarkdown} and Pandoc when available.}
\usage{
agri_report(
  x,
  file = NULL,
  format = c("md", "qmd", "html", "docx", "pdf"),
  language = c("en", "pt"),
  ...
)
}
\arguments{
  \item{x}{An agriRank result object, including \code{agri_rank_fit}, \code{agri_np_reg_fit}, \code{agri_multivariate_fit}, \code{agri_ancova_fit}, \code{agri_trend}, \code{agri_power}, \code{agri_batch}, \code{agri_sensitivity}, or \code{agri_missing_report}.}
  \item{file}{Output file path. When omitted, a temporary file is created.}
  \item{format}{Output format.}
  \item{language}{Report language. The regression module and all package documentation are authored in English; regression reports currently remain English.}
  \item{...}{Reserved for downstream reporting extensions.}
}
\details{
For experimental-design fits, the report records design, randomization, missingness, inferential method and reproducibility metadata. For regression fits, it records the response, predictors, fitted formula, method family, shape constraint, agronomic block adjustment, predictive diagnostics and explicit interpretation boundaries for fitted optima and model comparison. Integer-support fits additionally report the focal integer predictor, the admissible support, the latent/base engine when applicable, and the rule that decisions are evaluated on that support rather than rounded from a continuous optimum.

The report describes the analysis that was actually fitted; it does not silently substitute another engine or select a method by the smallest p-value.
}
\value{The normalized path of the generated report.}
\references{
Brunner E, Konietschke F, Pauly M, Puri ML (2017). Rank-based procedures in factorial designs: hypotheses about non-parametric treatment effects. \emph{Journal of the Royal Statistical Society: Series B}, 79, 1463--1485. doi:10.1111/rssb.12222.

Wood SN (2025). Generalized Additive Models and Their Applications. \emph{Annual Review of Statistics and Its Application}, 12, 497--526. doi:10.1146/annurev-statistics-112723-034249.
}
\examples{
# Example 1: experimental-design report
f <- np_crd(yield ~ treatment, simulate_agri("crd"))
agri_report(f, tempfile(fileext = ".md"), format = "md", language = "en")

# Example 2: regression report
set.seed(82)
d <- data.frame(salinity = seq(.5, 6, length.out = 35))
d$biomass <- 24*exp(-.12*d$salinity^1.5) + rnorm(35, 0, .7)
r <- agri_np_regression(biomass ~ salinity, d, method = "loess")
agri_report(r, tempfile(fileext = ".md"), format = "md")

# Example 3: integer-support regression report
di <- data.frame(plants = rep(1:8, each = 4))
di$yield <- 20 + 7*di$plants - .55*di$plants^2 + rnorm(nrow(di))
ri <- agri_np_regression(yield ~ plants, di, method = "integer_grid",
  integer_base_method = "smoothing_spline")
agri_report(ri, tempfile(fileext = ".md"), format = "md")
}
\seealso{\code{\link{agri_dashboard}}, \code{\link{agri_table}}, \code{\link{export_results}}, \code{\link{agri_np_regression}}}
