\name{agri_sensitivity}
\alias{agri_sensitivity}
\title{Compare admissible inferential paradigms}
\description{Fits selected alternative engines and tabulates their effect-level p-values without choosing the smallest one.}
\usage{
agri_sensitivity(x, methods = c("primary", "ART", "permuco"), seed = 1, ...)
}
\arguments{
  \item{x}{An agriRank design or fitted object as documented for the function.}
  \item{methods}{Vector of admissible alternative engines included in sensitivity analysis.}
  \item{seed}{Random seed used for reproducible resampling.}
  \item{...}{Additional arguments passed to the selected backend or downstream method.}
}
\details{Use to assess conclusion stability, not for method shopping. The vignette suite documents the experimental-design logic, estimand, hypothesis, resampling structure, missing/unbalanced-data behavior, and backend-specific limitations in greater depth.}
\value{An `agri_sensitivity` object.}
\references{
Pauly M, Brunner E, Konietschke F (2015), DOI: 10.1111/rssb.12073. Brunner E, Konietschke F, Pauly M, Puri ML (2017), DOI: 10.1111/rssb.12222. Konietschke F, Brunner E (2023), DOI: 10.32614/RJ-2023-029. See the package vignettes and `inst/references/agriRank-methods-verified.ris` for engine-specific verified references.
}
\examples{
# Example 1
x<-simulate_agri("factorial"); d<-agri_design(yield~A*B,x,"factorial"); agri_sensitivity(d)

# Example 2
x<-simulate_agri("factorial");
d<-agri_design(yield~A*B,x,"factorial");
f<-agri_rank(d);
agri_sensitivity(f,c("primary","ART"))

# Example 3
x<-simulate_agri("factorial");
d<-agri_design(yield~A*B,x,"factorial");
agri_sensitivity(d,c("primary","ART","permuco"))
}
\seealso{\code{agri_design}, \code{agri_rank}, \code{agri_effects}, \code{agri_report}}
