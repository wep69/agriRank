\name{agri_methods}
\alias{agri_methods}
\title{List available inferential domains and engines}
\description{Provides a compact registry of implemented and adapter-backed methods.}
\usage{
agri_methods()
}
\details{Availability of optional engines still depends on installed Suggested packages. The vignette suite documents the experimental-design logic, estimand, hypothesis, resampling structure, missing/unbalanced-data behavior, and backend-specific limitations in greater depth.}
\value{A data frame.}
\references{
Pauly M, Brunner E, Konietschke F (2015), DOI: 10.1111/rssb.12073. Brunner E, Konietschke F, Pauly M, Puri ML (2017), DOI: 10.1111/rssb.12222. Konietschke F, Brunner E (2023), DOI: 10.32614/RJ-2023-029. See the package vignettes and `inst/references/agriRank-methods-verified.ris` for engine-specific verified references.
}
\examples{
# Example 1
agri_methods()

# Example 2
subset(agri_methods(), grepl("repeated", domain))

# Example 3
subset(agri_methods(), grepl("implemented", status))
}
\seealso{\code{agri_design}, \code{agri_rank}, \code{agri_effects}, \code{agri_report}}
