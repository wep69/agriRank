\name{agri_repeated}
\alias{agri_repeated}
\title{Analyze repeated measurements with explicit backend selection}
\description{Provides a dedicated repeated-measures router for nparLD, MANOVA.RM, permuco, and the native incomplete wild-rank engine.}
\usage{
agri_repeated(design, backend = c("auto", "native_wild", "nparLD", "MANOVA.RM", 
    "permuco"), B = 1999, iter = 4999, seed = 1, missing_assumption = c("unspecified", 
    "MCAR", "MAR-sensitivity"), ...)
}
\arguments{
  \item{design}{A declared design type or an `agri_design` object, depending on context.}
  \item{backend}{Repeated-measures backend.}
  \item{B}{Number of bootstrap or resampling replicates. Small values are for examples only.}
  \item{iter}{Number of resampling iterations passed to the selected optional backend.}
  \item{seed}{Random seed used for reproducible resampling.}
  \item{missing_assumption}{Label recording the assumed missingness framework; this is not inferred from the data.}
  \item{...}{Additional arguments passed to the selected backend or downstream method.}
}
\details{The current native incomplete engine is unblocked; blocked incomplete repeated data are not silently simplified. The vignette suite documents the experimental-design logic, estimand, hypothesis, resampling structure, missing/unbalanced-data behavior, and backend-specific limitations in greater depth.}
\value{An `agri_rank_fit`.}
\references{
Pauly M, Brunner E, Konietschke F (2015), DOI: 10.1111/rssb.12073. Brunner E, Konietschke F, Pauly M, Puri ML (2017), DOI: 10.1111/rssb.12222. Konietschke F, Brunner E (2023), DOI: 10.32614/RJ-2023-029. See the package vignettes and `inst/references/agriRank-methods-verified.ris` for engine-specific verified references.
}
\examples{
# Example 1
x<-simulate_agri("repeated");
d<-agri_design(height~treatment*time,x,"repeated",subject=subject,within=time);
if(requireNamespace("nparLD",quietly=TRUE)) agri_repeated(d,"nparLD")

# Example 2
x<-simulate_agri("repeated");
d<-agri_design(height~treatment*time,x,"repeated",subject=subject,within=time);
if(requireNamespace("MANOVA.RM",quietly=TRUE)) agri_repeated(d,"MANOVA.RM",iter=499)

# Example 3
x<-simulate_agri("repeated_missing");
d<-agri_design(height~treatment*time,x,"repeated",subject=subject,within=time);
agri_repeated(d,"native_wild",B=299,missing_assumption="MCAR")
}
\seealso{\code{agri_design}, \code{agri_rank}, \code{agri_effects}, \code{agri_report}}
