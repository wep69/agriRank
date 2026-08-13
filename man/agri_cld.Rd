\name{agri_cld}
\alias{agri_cld}
\title{Create a compact letter display}
\description{Summarizes multiplicity-adjusted ordinary pairwise comparisons as letters.}
\usage{
agri_cld(x, adjust = "holm", alpha = 0.05, ...)
}
\arguments{
  \item{x}{An agriRank design or fitted object as documented for the function.}
  \item{adjust}{Multiplicity adjustment method.}
  \item{alpha}{Significance threshold used to derive a compact letter display.}
  \item{...}{Additional arguments passed to the selected backend or downstream method.}
}
\details{CLD is secondary to effect estimates and confidence intervals. The vignette suite documents the experimental-design logic, estimand, hypothesis, resampling structure, missing/unbalanced-data behavior, and backend-specific limitations in greater depth.}
\value{A data frame with groups and letters.}
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
}
\seealso{\code{agri_design}, \code{agri_rank}, \code{agri_effects}, \code{agri_report}}
