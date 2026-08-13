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
# The candidate model must be fitted with x = TRUE, y = TRUE so that the
# adapter can recover the design matrix and the response.
# B = 19 keeps the examples fast. Use B >= 999 for any reported test.
data(agri_dose)

# Example 1: is a straight line enough for a fertilizer response?
if (requireNamespace("np", quietly = TRUE)) {
  m1 <- lm(yield ~ dose, data = agri_dose, x = TRUE, y = TRUE)
  agri_np_specification(m1, B = 19)
  # A small p-value means the linear form is too restrictive: the data hold
  # curvature that the straight line cannot represent.
}

# Example 2: and is the quadratic enough?
if (requireNamespace("np", quietly = TRUE)) {
  m2 <- lm(yield ~ dose + I(dose^2), data = agri_dose, x = TRUE, y = TRUE)
  agri_np_specification(m2, B = 19)
  # These data plateau beyond 200 kg/ha, a shape no single quadratic
  # reproduces, so rejection here is agronomically meaningful.
}

# Example 3: with the agronomic block kept as a nuisance term
if (requireNamespace("np", quietly = TRUE)) {
  mb <- lm(yield ~ block + dose + I(dose^2), data = agri_dose, x = TRUE, y = TRUE)
  agri_np_specification(mb, B = 19)
  # Failing to reject is not proof that the parametric form is correct; it
  # only means this sample gives no evidence against it.
}
}
\seealso{\code{\link{agri_np_regression}}, \code{\link{agri_np_significance}}, \code{\link{agri_np_diagnostics}}}
