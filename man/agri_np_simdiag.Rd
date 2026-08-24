\name{agri_np_simdiag}
\alias{agri_np_simdiag}
\alias{print.agri_np_simdiag}
\alias{plot.agri_np_simdiag}
\title{Simulation-based quantile residuals}
\usage{
agri_np_simdiag(object, nsim = 250L, seed = 1, engine = c("auto", "agriRank"))

\method{plot}{agri_np_simdiag}(x, type = c("uniform_qq", "residual_predictor"), ...)
}
\arguments{
  \item{object}{An \code{agri_np_reg_fit}.}
  \item{nsim}{Number of simulations.}
  \item{seed}{Random seed.}
  \item{engine}{\code{"auto"} uses \pkg{DHARMa} when it is installed and understands the backend, otherwise the internal residual-resampling simulator. \code{"agriRank"} forces the internal one.}
  \item{x}{An \code{agri_np_simdiag} object.}
  \item{type}{\code{"uniform_qq"} against the uniform reference, or \code{"residual_predictor"} against the gradient.}
  \item{...}{Unused.}
}
\description{
Scaled residuals obtained by locating each observation inside its own simulated
predictive distribution. Under a correct model they are uniform on the unit
interval, whatever the distribution of the response.
}
\details{
A normal QQ-plot asks whether the residuals look Gaussian. For a package whose
premise is to avoid assuming a distribution, that is the wrong question asked of
the wrong quantity. Quantile residuals ask where each observation falls inside
the predictive distribution the model implies, and uniformity of those positions
is the property a correct model must have, regardless of the response
distribution.

When \pkg{DHARMa} is installed and the backend is one it understands, its
machinery is used. Otherwise \pkg{agriRank} simulates by resampling the fitted
residuals, which keeps the diagnostic available for the smoothers DHARMa does
not know, and keeps the reference distribution empirical rather than assumed.

The diagnostic is descriptive. A departure from uniformity indicates that the
fitted mean, the dispersion, or both, do not describe the data. It is never a
rule for selecting an inferential method.
}
\value{An object of class \code{agri_np_simdiag} with the scaled residuals, a uniformity test, and the values needed for the figures.}
\references{
Dunn, P. K. and Smyth, G. K. (1996). Randomized quantile residuals.
\emph{Journal of Computational and Graphical Statistics}, 5(3), 236-244.
\doi{10.1080/10618600.1996.10474708}

Hartig, F. \pkg{DHARMa}: Residual Diagnostics for Hierarchical (Multi-Level /
Mixed) Regression Models. CRAN.
}
\seealso{\code{\link{agri_np_diagnostics}}, \code{\link{agri_np_plot}}}
\examples{
data(agri_dose)
f <- agri_np_regression(yield ~ dose, agri_dose, method = "smoothing_spline")

# Example 1: scaled residuals and their uniformity
sd1 <- agri_np_simdiag(f, nsim = 150, seed = 1)
sd1

# Example 2: the two figures
if (requireNamespace("ggplot2", quietly = TRUE)) {
  plot(sd1, type = "uniform_qq")
  plot(sd1, type = "residual_predictor")
}

# Example 3: a deliberately wrong shape. Forcing a monotone increase on a
# response that plateaus should leave a visible signature in the residuals.
f_wrong <- agri_np_regression(yield ~ dose, agri_dose, method = "isotonic",
                              shape = "increasing")
agri_np_simdiag(f_wrong, nsim = 150, seed = 1)$uniformity
}
