\name{np_rcbd}
\alias{np_rcbd}
\title{Analyze a randomized complete block design}
\description{Convenience wrapper for one- or multifactor treatment structures randomized within blocks.}
\usage{
np_rcbd(formula, data, block, method = "auto", ...)
}
\arguments{
  \item{formula}{A model formula defining the scientific treatment structure.}
  \item{data}{A data frame, preferably in long format.}
  \item{block}{Blocking variable(s) identifying the RCBD or nuisance randomization stratum.}
  \item{method}{Inferential engine name or `"auto"` for conservative design-based routing.}
  \item{...}{Additional arguments passed to the selected backend or downstream method.}
}
\details{The block is part of the randomization and must not be discarded because of a preliminary significance test. The vignette suite documents the experimental-design logic, estimand, hypothesis, resampling structure, missing/unbalanced-data behavior, and backend-specific limitations in greater depth.}
\value{An `agri_rank_fit`.}
\references{
Pauly M, Brunner E, Konietschke F (2015), DOI: 10.1111/rssb.12073. Brunner E, Konietschke F, Pauly M, Puri ML (2017), DOI: 10.1111/rssb.12222. Konietschke F, Brunner E (2023), DOI: 10.32614/RJ-2023-029. See the package vignettes and `inst/references/agriRank-methods-verified.ris` for engine-specific verified references.
}
\examples{
# Example 1
x<-simulate_agri("rcbd"); np_rcbd(yield~treatment,x,block)

# Example 2
x<-simulate_agri("rcbd"); x$score<-round(x$yield); np_rcbd(score~treatment,x,block,"friedman")

# Example 3
x<-simulate_agri("rcbd",n=8); np_rcbd(yield~treatment,x,block,"friedman")
}
\seealso{\code{agri_design}, \code{agri_rank}, \code{agri_effects}, \code{agri_report}}
