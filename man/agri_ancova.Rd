\name{agri_ancova}
\alias{agri_ancova}
\title{Fit a permutation ANCOVA adapter}
\description{Uses `permuco` Freedman-Lane permutation ANCOVA, optionally on response mid-ranks.}
\usage{
agri_ancova(formula, data, covariates, block = NULL, np = 4999, seed = 1, 
    rank_response = TRUE, ...)
}
\arguments{
  \item{formula}{A model formula defining the scientific treatment structure.}
  \item{data}{A data frame, preferably in long format.}
  \item{covariates}{Covariate column name(s) used as nuisance adjustment variables.}
  \item{block}{Blocking variable(s) identifying the RCBD or nuisance randomization stratum.}
  \item{np}{Number of permutations passed to `permuco`.}
  \item{seed}{Random seed used for reproducible resampling.}
  \item{rank_response}{Logical; if `TRUE`, apply Freedman-Lane ANCOVA to response mid-ranks.}
  \item{...}{Additional arguments passed to the selected backend or downstream method.}
}
\details{This function is not the 2026 resampling NANCOVA method; that remains a future engine. The vignette suite documents the experimental-design logic, estimand, hypothesis, resampling structure, missing/unbalanced-data behavior, and backend-specific limitations in greater depth.}
\value{An object of class \code{agri_ancova_fit}, accepted by \code{agri_table()}, \code{agri_report()}, and \code{export_results()}.}
\references{
Pauly M, Brunner E, Konietschke F (2015), DOI: 10.1111/rssb.12073. Brunner E, Konietschke F, Pauly M, Puri ML (2017), DOI: 10.1111/rssb.12222. Konietschke F, Brunner E (2023), DOI: 10.32614/RJ-2023-029. See the package vignettes and `inst/references/agriRank-methods-verified.ris` for engine-specific verified references.
}
\examples{
# Example 1
if(requireNamespace("permuco",quietly=TRUE)){x<-simulate_agri("crd");
x$base<-rnorm(nrow(x));
agri_ancova(yield~treatment,x,covariates=base,np=299)}

# Example 2
if(requireNamespace("permuco",quietly=TRUE)){x<-simulate_agri("crd");
x$base<-rnorm(nrow(x));
agri_ancova(yield~treatment,x,covariates=base,np=299,rank_response=FALSE)}

# Example 3
if(requireNamespace("permuco",quietly=TRUE)){x<-simulate_agri("rcbd");
x$base<-rnorm(nrow(x));
agri_ancova(yield~treatment,x,covariates=base,block=block,np=299)}
}
\seealso{\code{agri_design}, \code{agri_rank}, \code{agri_effects}, \code{agri_report}}
