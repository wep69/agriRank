\name{np_crd}
\alias{np_crd}
\title{Analyze a completely randomized design}
\description{Convenience wrapper around `agri_design()` and `agri_rank()` for CRD data.}
\usage{
np_crd(formula, data, method = "auto", ...)
}
\arguments{
  \item{formula}{A model formula defining the scientific treatment structure.}
  \item{data}{A data frame, preferably in long format.}
  \item{method}{Inferential engine name or `"auto"` for conservative design-based routing.}
  \item{...}{Additional arguments passed to the selected backend or downstream method.}
}
\details{Use the full API when explicit design metadata are needed. The vignette suite documents the experimental-design logic, estimand, hypothesis, resampling structure, missing/unbalanced-data behavior, and backend-specific limitations in greater depth.}
\value{An `agri_rank_fit`.}
\references{
Pauly M, Brunner E, Konietschke F (2015), DOI: 10.1111/rssb.12073. Brunner E, Konietschke F, Pauly M, Puri ML (2017), DOI: 10.1111/rssb.12222. Konietschke F, Brunner E (2023), DOI: 10.32614/RJ-2023-029. See the package vignettes and `inst/references/agriRank-methods-verified.ris` for engine-specific verified references.
}
\examples{
# Example 1
np_crd(yield~treatment,simulate_agri("crd"))

# Example 2
x<-simulate_agri("crd"); x$score<-round(x$yield); np_crd(score~treatment,x,"kruskal")

# Example 3
x<-simulate_agri("crd"); np_crd(yield~treatment,x[-c(1,2),])
}
\seealso{\code{agri_design}, \code{agri_rank}, \code{agri_effects}, \code{agri_report}}
