\name{agri_pairs}
\alias{agri_pairs}
\title{Compute pairwise treatment comparisons}
\description{Provides ordinary pairwise Wilcoxon comparisons, design-aware Conover comparisons, or simultaneous maxT comparisons for the native repeated wild-rank engine.}
\usage{
agri_pairs(x, by = NULL, factor = NULL, method = c("wilcoxon", "conover"),
  adjust = "holm", B = NULL, seed = NULL, level = 0.95)
}
\arguments{
  \item{x}{An \code{agri_rank_fit}.}
  \item{by}{Factor(s) conditioning simple pairwise comparisons.}
  \item{factor}{Factor to compare in native repeated wild-rank or Conover simple-effect contrasts.}
  \item{method}{Pairwise engine: \code{"wilcoxon"} or design-aware \code{"conover"}.}
  \item{adjust}{Multiplicity adjustment method.}
  \item{B}{Number of bootstrap or resampling replicates for the native repeated wild-rank engine.}
  \item{seed}{Random seed used for reproducible resampling.}
  \item{level}{Confidence level.}
}
\details{
For \code{method = "conover"}, one-way/CRD comparisons are routed to the Kruskal-type Conover test and complete unreplicated RCBD comparisons are routed to the Friedman-type Conover test. In factorial experiments, use \code{by} to obtain scientifically meaningful simple effects where appropriate.
}
\value{A data frame containing the relevant treatment contrasts and multiplicity-adjusted inference.}
\references{
Conover, W. J. (1999). \emph{Practical Nonparametric Statistics}. 3rd ed. Wiley.

Konietschke, F. and Brunner, E. (2023). rankFD: An R Software Package for Nonparametric Analysis of General Factorial Designs. \emph{The R Journal}. doi:10.32614/RJ-2023-029.
}
\examples{
# Example 1: default pairwise workflow
fit <- np_crd(yield ~ treatment, simulate_agri("crd"))
agri_pairs(fit)

# Example 2: factorial simple effects
if (requireNamespace("rankFD", quietly = TRUE)) {
  x <- simulate_agri("factorial")
  f <- np_factorial(yield ~ A * B, x, method = "rankFD")
  agri_pairs(f, by = "B")
}

# Example 3: Conover through the same interface
if (requireNamespace("PMCMRplus", quietly = TRUE)) {
  set.seed(91)
  dc <- data.frame(trt = factor(rep(LETTERS[1:3], each = 7)),
                   y = rgamma(21, shape = rep(4:6, each = 7)))
  fc <- np_crd(y ~ trt, dc, method = "kruskal")
  agri_pairs(fc, method = "conover")
}
}
\seealso{\code{\link{agri_conover}}, \code{\link{agri_cld}}, \code{\link{agri_effects}}, \code{\link{agri_rank}}}
