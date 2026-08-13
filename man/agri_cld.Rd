\name{agri_cld}
\alias{agri_cld}
\title{Create a compact letter display}
\description{Summarizes multiplicity-adjusted ordinary pairwise comparisons as letters.}
\usage{
agri_cld(x, adjust = "holm", alpha = 0.05, ...)
}
\arguments{
  \item{x}{An \code{agri_rank_fit} object, or a pairwise comparison table already produced by \code{\link{agri_pairs}} or \code{\link{agri_conover}}.}
  \item{adjust}{Multiplicity adjustment method. Used only when \code{x} is a fitted object and the pairwise table still has to be computed.}
  \item{alpha}{Significance threshold used to derive a compact letter display.}
  \item{...}{Additional arguments passed to \code{\link{agri_pairs}}, such as \code{method}, \code{by} and \code{factor}.}
}
\details{CLD is secondary to effect estimates and confidence intervals. The vignette suite documents the experimental-design logic, estimand, hypothesis, resampling structure, missing/unbalanced-data behavior, and backend-specific limitations in greater depth.

When the comparison table contains a \code{stratum} column, as produced by
\code{agri_conover(by = ...)} or \code{agri_pairs(by = ...)}, letters are
computed separately within each stratum. Two treatments evaluated in different
simple-effect strata were never compared with each other, so a single global
display would suggest a comparison the data do not support.}
\value{A data frame with groups and letters, plus a \code{stratum} column when the comparisons were stratified.}
\references{
Pauly M, Brunner E, Konietschke F (2015), DOI: 10.1111/rssb.12073. Brunner E, Konietschke F, Pauly M, Puri ML (2017), DOI: 10.1111/rssb.12222. Konietschke F, Brunner E (2023), DOI: 10.32614/RJ-2023-029. See the package vignettes and `inst/references/agriRank-methods-verified.ris` for engine-specific verified references.
}
\examples{
# Example 1
fit<-np_crd(yield~treatment,simulate_agri("crd"));
if(requireNamespace("multcompView",quietly=TRUE)) agri_cld(fit)

# Example 2
fit<-np_crd(yield~treatment,simulate_agri("crd"));
if(requireNamespace("multcompView",quietly=TRUE)) agri_cld(fit,adjust="BH")

# Example 3
fit<-np_crd(yield~treatment,simulate_agri("crd"));
if(requireNamespace("multcompView",quietly=TRUE)) agri_cld(fit,alpha=.01)

# Example 4: letters from a Conover table that was already computed
if (requireNamespace("multcompView", quietly = TRUE) &&
    requireNamespace("PMCMRplus", quietly = TRUE)) {
  fit <- np_crd(yield ~ treatment, simulate_agri("crd", seed = 41))
  cv <- agri_conover(fit, adjust = "holm")
  agri_cld(cv)
}

# Example 5: letters within each simple-effect stratum
if (requireNamespace("multcompView", quietly = TRUE) &&
    requireNamespace("PMCMRplus", quietly = TRUE) &&
    requireNamespace("ARTool", quietly = TRUE)) {
  d <- expand.grid(cultivar = factor(c("C1", "C2", "C3")),
                   salinity = factor(c("S1", "S2")), rep = 1:5)
  set.seed(42)
  d$biomass <- 20 + as.numeric(d$cultivar) - 2 * as.numeric(d$salinity) + rnorm(nrow(d))
  f <- agri_rank(agri_design(biomass ~ cultivar * salinity, d, design = "factorial"),
                 method = "ART")
  agri_cld(f, method = "conover", by = "salinity", factor = "cultivar")
}
}
\seealso{\code{agri_design}, \code{agri_rank}, \code{agri_effects}, \code{agri_report}}
