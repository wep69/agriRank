\name{agri_conover}
\alias{agri_conover}
\title{Design-aware Conover all-pairs comparisons}
\usage{
agri_conover(x, by = NULL, factor = NULL, adjust = "holm")
}
\arguments{
  \item{x}{An \code{agri_rank_fit} object.}
  \item{by}{Optional character vector of factors that define simple-effect strata.}
  \item{factor}{Optional treatment factor to compare. If omitted, remaining treatment factors are used.}
  \item{adjust}{P-value adjustment supported by \pkg{PMCMRplus}, such as \code{"holm"}, \code{"bonferroni"}, \code{"BH"}, or \code{"single-step"}.}
}
\description{
Performs Conover all-pairs rank comparisons while respecting the declared experimental layout. One-way/CRD data use the Kruskal-type Conover procedure; complete unreplicated RCBD data use the Friedman-type Conover procedure.
}
\details{
The function is an adapter to \code{PMCMRplus::kwAllPairsConoverTest()} and \code{PMCMRplus::frdAllPairsConoverTest()}. For blocked data, every block-by-treatment cell within the requested stratum must contain exactly one observation. The function does not silently discard incomplete blocks.

For factorial experiments, use \code{by} to request scientifically interpretable simple effects rather than indiscriminate comparisons of all treatment cells.
}
\value{A data frame containing treatment pairs, the comparison stratum, test statistic when exposed by the backend, raw and adjusted p-values, block-pairing indicator, and method label.}
\references{
Conover, W. J. (1999). \emph{Practical Nonparametric Statistics}. 3rd ed. Wiley.

Pohlert, T. \pkg{PMCMRplus}: Calculate Pairwise Multiple Comparisons of Mean Rank Sums Extended. CRAN.
}
\seealso{\code{\link{agri_pairs}}, \code{\link{agri_cld}}, \code{\link{np_crd}}, \code{\link{np_rcbd}}}
\examples{
# Example 1: one-way CRD
set.seed(11)
d1 <- data.frame(
  treatment = factor(rep(LETTERS[1:4], each = 8)),
  yield = c(rgamma(8, 5, 1), rgamma(8, 6, 1), rgamma(8, 7, 1), rgamma(8, 8, 1))
)
f1 <- np_crd(yield ~ treatment, d1, method = "kruskal")
if (requireNamespace("PMCMRplus", quietly = TRUE))
  agri_conover(f1, adjust = "holm")

# Example 2: complete RCBD
set.seed(12)
d2 <- expand.grid(block = factor(1:6), treatment = factor(LETTERS[1:4]))
d2$yield <- 30 + as.numeric(d2$treatment) * 2 + as.numeric(d2$block) + rnorm(nrow(d2))
f2 <- np_rcbd(yield ~ treatment, d2, block = block, method = "friedman")
if (requireNamespace("PMCMRplus", quietly = TRUE))
  agri_conover(f2, adjust = "bonferroni")

# Example 3: factorial simple effects
if (requireNamespace("rankFD", quietly = TRUE) && requireNamespace("PMCMRplus", quietly = TRUE)) {
  d3 <- expand.grid(block = factor(1:5), cultivar = factor(c("C1", "C2", "C3")),
                    salinity = factor(c("S1", "S2")))
  set.seed(13)
  d3$biomass <- 20 + as.numeric(d3$cultivar) - 2 * as.numeric(d3$salinity) + rnorm(nrow(d3))
  des3 <- agri_design(biomass ~ cultivar * salinity, d3, design = "factorial")
  fit3 <- agri_rank(des3, method = "rankFD")
  agri_conover(fit3, by = "salinity", factor = "cultivar")
}
}
