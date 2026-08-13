\name{np_repeated}
\alias{np_repeated}
\title{Analyze repeated measurements}
\description{Convenience wrapper that declares subject and within-subject factors before fitting repeated-measures inference.}
\usage{
np_repeated(formula, data, subject, within, block = NULL, method = "auto", ...)
}
\arguments{
  \item{formula}{A model formula defining the scientific treatment structure.}
  \item{data}{A data frame, preferably in long format.}
  \item{subject}{Experimental-unit identifier for repeated or multivariate observations.}
  \item{within}{Within-subject factor(s), usually time or measurement occasion.}
  \item{block}{Blocking variable(s) identifying the RCBD or nuisance randomization stratum.}
  \item{method}{Inferential engine name or `"auto"` for conservative design-based routing.}
  \item{...}{Additional arguments passed to the selected backend or downstream method.}
}
\details{Repeated observations from one subject are dependent. The vignette suite documents the experimental-design logic, estimand, hypothesis, resampling structure, missing/unbalanced-data behavior, and backend-specific limitations in greater depth.}
\value{An `agri_rank_fit`.}
\references{
Pauly M, Brunner E, Konietschke F (2015), DOI: 10.1111/rssb.12073. Brunner E, Konietschke F, Pauly M, Puri ML (2017), DOI: 10.1111/rssb.12222. Konietschke F, Brunner E (2023), DOI: 10.32614/RJ-2023-029. See the package vignettes and `inst/references/agriRank-methods-verified.ris` for engine-specific verified references.
}
\examples{
# Example 1
x<-simulate_agri("repeated"); np_repeated(height~treatment*time,x,subject,time)

# Example 2
x<-simulate_agri("repeated");
if (requireNamespace("nparLD", quietly = TRUE)) np_repeated(height ~ treatment * 
    time, x, subject, time, method = "nparLD")

# Example 3
x<-simulate_agri("repeated_missing");
np_repeated(height ~ treatment * time, x, subject, time, method = "incomplete_wild", 
    B = 299, missing_assumption = "MCAR")
}
\seealso{\code{agri_design}, \code{agri_rank}, \code{agri_effects}, \code{agri_report}}
