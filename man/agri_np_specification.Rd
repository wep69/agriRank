\name{agri_np_specification}
\alias{agri_np_specification}
\title{Test a prespecified Gaussian regression against a nonparametric alternative}
\description{Uses \code{np::npcmstest()} to assess whether a prespecified linear or polynomial Gaussian regression is too restrictive relative to a mixed-data nonparametric conditional-mean model.}
\usage{
agri_np_specification(
  model,
  data = NULL,
  B = 399L,
  distribution = c("bootstrap", "asymptotic"),
  boot_method = c("wild-rademacher", "wild", "iid"),
  pivot = TRUE,
  density_weighted = TRUE,
  seed = 42L,
  ...
)
}
\arguments{
  \item{model}{An \code{lm} or Gaussian \code{glm} fitted with \code{x = TRUE, y = TRUE}.}
  \item{data}{Optional original model data. If omitted, the model frame is used when possible.}
  \item{B}{Number of bootstrap replications.}
  \item{distribution}{Bootstrap or asymptotic reference distribution.}
  \item{boot_method}{Bootstrap method accepted by \code{np::npcmstest()}.}
  \item{pivot}{Use the pivotal statistic.}
  \item{density_weighted}{Weight the statistic by the predictor density.}
  \item{seed}{Reproducible bootstrap seed.}
  \item{...}{Additional kernel and bandwidth arguments passed to \code{np::npcmstest()}.}
}
\details{
The test is a specification diagnostic. A small p-value is evidence that the candidate parametric functional form is inadequate; it does not establish that any particular smoother is uniquely correct. The adapter is intentionally restricted to continuous Gaussian outcomes because the backend relies on residual bootstrapping.

Use the exact data used to fit the candidate model after missing-data handling. When the original predictors cannot be reconstructed, the function falls back to stored model-matrix columns and warns because mixed-data classes may be lost.
}
\value{An \pkg{np} \code{cmstest} object with an additional agriRank interpretation attribute.}
\references{
Hsiao C, Li Q, Racine JS (2007). A consistent model specification test with mixed discrete and continuous data. \emph{Journal of Econometrics}, 140(2), 802--826. doi:10.1016/j.jeconom.2006.07.015.

Hayfield T, Racine JS (2008). Nonparametric Econometrics: The np Package. \emph{Journal of Statistical Software}, 27(5). doi:10.18637/jss.v027.i05.
}
\examples{
# Example 1: test a linear fertilizer response
if (requireNamespace("np", quietly = TRUE)) {
  set.seed(94)
  d <- data.frame(dose = seq(0, 160, length.out = 35))
  d$yield <- 5 + .06*d$dose - .00025*d$dose^2 + rnorm(35, 0, .4)
  m1 <- lm(yield ~ dose, data = d, x = TRUE, y = TRUE)
  agri_np_specification(m1, B = 19)
}

# Example 2: assess a prespecified quadratic candidate
if (requireNamespace("np", quietly = TRUE)) {
  m2 <- lm(yield ~ dose + I(dose^2), data = d, x = TRUE, y = TRUE)
  agri_np_specification(m2, B = 19)
}

# Example 3: include an agronomic block as a nuisance predictor in the candidate
if (requireNamespace("np", quietly = TRUE)) {
  set.seed(95)
  db <- expand.grid(block = factor(1:4), dose = seq(0, 140, length.out = 8))
  db$yield <- 5 + .07*db$dose - .0003*db$dose^2 + as.numeric(db$block)/3 + rnorm(nrow(db), 0, .4)
  mb <- lm(yield ~ block + dose + I(dose^2), data = db, x = TRUE, y = TRUE)
  agri_np_specification(mb, B = 19)
}
}
\seealso{\code{\link{agri_np_regression}}, \code{\link{agri_np_significance}}, \code{\link{agri_np_diagnostics}}}
