\name{agri_pairs}
\alias{agri_pairs}
\title{Compute pairwise treatment comparisons}
\description{Provides ordinary pairwise Wilcoxon comparisons, design-aware Conover comparisons, or simultaneous maxT comparisons for the native repeated wild-rank engine.}
\usage{
agri_pairs(
  x,
  by = NULL,
  factor = NULL,
  method = c("wilcoxon", "conover"),
  adjust = "holm",
  B = NULL,
  seed = NULL,
  level = 0.95,
  cld = FALSE,
  alpha = 0.05
)
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
  \item{cld}{If \code{TRUE}, a compact letter display is computed from the multiplicity-adjusted p-values and attached to the result as the \code{"cld"} attribute. Requires \pkg{multcompView}.}
  \item{alpha}{Significance level used by the letter display.}
}
\details{
For \code{method = "conover"}, one-way/CRD comparisons are routed to the Kruskal-type Conover test and complete unreplicated RCBD comparisons are routed to the Friedman-type Conover test. In factorial experiments, use \code{by} to obtain scientifically meaningful simple effects where appropriate.

A compact letter display is available for every route of this function: the
Wilcoxon comparisons, the Conover comparisons, and the simultaneous max-T
contrasts of the native repeated wild-rank engine. Set \code{cld = TRUE}, or
pass the returned table to \code{\link{agri_cld}}. Letters are computed within
each stratum, because groups compared in different simple-effect strata were
never tested against each other.

The letter display requires the complete set of pairs. A subset of comparisons,
or a user-defined contrast that is not a simple difference between two groups,
is refused rather than summarized into letters that would imply comparisons the
analysis never performed.
}
\value{A data frame containing the relevant treatment contrasts and multiplicity-adjusted inference. When \code{cld = TRUE}, the \code{"cld"} attribute holds the letter display.}
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

# Example 4: letters attached to the comparison table
if (requireNamespace("multcompView", quietly = TRUE)) {
  p <- agri_pairs(fit, cld = TRUE)
  attr(p, "cld")
}

# Example 5: letters within each simple-effect stratum
if (requireNamespace("rankFD", quietly = TRUE) &&
    requireNamespace("multcompView", quietly = TRUE)) {
  attr(agri_pairs(f, by = "B", cld = TRUE), "cld")
}

# Example 6: the native repeated wild-rank engine, whose simultaneous max-T
# contrasts also support a letter display
if (requireNamespace("multcompView", quietly = TRUE)) {
  rp <- simulate_agri("repeated_missing", seed = 61, n = 12, missing_rate = 0.15)
  dr <- agri_design(height ~ treatment * time, rp, design = "repeated",
                    subject = subject, within = time)
  fw <- agri_repeated(dr, backend = "native_wild", B = 99, seed = 1,
                      missing_assumption = "MCAR")
  attr(agri_pairs(fw, B = 99, seed = 1, cld = TRUE), "cld")
}
}
\seealso{\code{\link{agri_conover}}, \code{\link{agri_cld}}, \code{\link{agri_effects}}, \code{\link{agri_rank}}}
