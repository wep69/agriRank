\name{np_factorial}
\alias{np_factorial}
\title{Analyze a nonparametric factorial experiment}
\description{Convenience wrapper for factorial treatment structures with or without blocks.}
\usage{
np_factorial(formula, data, block = NULL, method = "auto", ...)
}
\arguments{
  \item{formula}{A model formula defining the scientific treatment structure.}
  \item{data}{A data frame, preferably in long format.}
  \item{block}{Blocking variable(s) identifying the RCBD or nuisance randomization stratum.}
  \item{method}{Inferential engine name or `"auto"` for conservative design-based routing.}
  \item{...}{Additional arguments passed to the selected backend or downstream method.}
}
\details{For unbalanced independent factorial designs, pseudo-rank methods are generally preferable when unweighted relative effects are the estimand. The vignette suite documents the experimental-design logic, estimand, hypothesis, resampling structure, missing/unbalanced-data behavior, and backend-specific limitations in greater depth.}
\value{An `agri_rank_fit`.}
\references{
Pauly M, Brunner E, Konietschke F (2015), DOI: 10.1111/rssb.12073. Brunner E, Konietschke F, Pauly M, Puri ML (2017), DOI: 10.1111/rssb.12222. Konietschke F, Brunner E (2023), DOI: 10.32614/RJ-2023-029. See the package vignettes and `inst/references/agriRank-methods-verified.ris` for engine-specific verified references.
}
\examples{
# Example 1
x<-simulate_agri("factorial"); np_factorial(yield~A*B,x)

# Example 2
x<-simulate_agri("factorial");
if(requireNamespace("rankFD",quietly=TRUE)) np_factorial(yield~A*B,x,method="rankFD")

# Example 3
x<-simulate_agri("factorial");
if(requireNamespace("ARTool",quietly=TRUE)) np_factorial(yield~A*B,x,method="ART")
}
\seealso{\code{agri_design}, \code{agri_rank}, \code{agri_effects}, \code{agri_report}}
