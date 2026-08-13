\name{agri_dashboard}
\alias{agri_dashboard}
\title{Generate a self-contained Quarto dashboard source}
\description{Creates an English Quarto dashboard source for an experimental-design analysis or agronomic nonparametric regression fit. The generated source uses embedded-resource HTML settings for portable communication.}
\usage{
agri_dashboard(
  x,
  file = tempfile("agriRank-dashboard-", fileext = ".qmd"),
  language = "en"
)
}
\arguments{
  \item{x}{An \code{agri_rank_fit} or \code{agri_np_reg_fit} object.}
  \item{file}{Output QMD path.}
  \item{language}{Report language. Regression dashboard content is currently generated in English.}
}
\details{
The function creates the QMD source and does not require Quarto merely to write it. Rendering is deliberately separated from statistical fitting. Regression dashboards retain method, predictors, fitted formula, shape constraint, block adjustment and predictive diagnostics.
}
\value{The normalized path of the QMD source.}
\examples{
# Example 1: CRD dashboard source
f <- np_crd(yield ~ treatment, simulate_agri("crd"))
agri_dashboard(f, tempfile(fileext = ".qmd"))

# Example 2: smoothing-spline regression dashboard
set.seed(83)
d <- data.frame(dose = seq(0, 180, length.out = 35))
d$yield <- 6 + .06*d$dose - .0002*d$dose^2 + rnorm(35, 0, .4)
r <- agri_np_regression(yield ~ dose, d, method = "smoothing_spline")
agri_dashboard(r, tempfile(fileext = ".qmd"))

# Example 3: incomplete repeated-measures analysis
x <- simulate_agri("repeated_missing")
des <- agri_design(height ~ treatment*time, x, "repeated", subject = subject, within = time)
fr <- agri_rank(des, "incomplete_wild", B = 99, missing_assumption = "MCAR")
agri_dashboard(fr, tempfile(fileext = ".qmd"))
}
\seealso{\code{\link{agri_report}}, \code{\link{agri_np_regression}}, \code{\link{agri_np_plot}}}
