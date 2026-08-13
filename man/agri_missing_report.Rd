\name{agri_missing_report}
\alias{agri_missing_report}
\title{Characterize missing response observations}
\description{Summarizes missingness overall and, for repeated data, by subject, occasion, pattern, and monotone-dropout structure.}
\usage{
agri_missing_report(x, response = NULL, subject = NULL, within = NULL)
}
\arguments{
  \item{x}{An agriRank design or fitted object as documented for the function.}
  \item{response}{Optional response column name when a design contains more than one response.}
  \item{subject}{Experimental-unit identifier for repeated or multivariate observations.}
  \item{within}{Within-subject factor(s), usually time or measurement occasion.}
}
\details{The missingness mechanism cannot be established from observed data alone. The vignette suite documents the experimental-design logic, estimand, hypothesis, resampling structure, missing/unbalanced-data behavior, and backend-specific limitations in greater depth.}
\value{An `agri_missing_report` list.}
\references{
Pauly M, Brunner E, Konietschke F (2015), DOI: 10.1111/rssb.12073. Brunner E, Konietschke F, Pauly M, Puri ML (2017), DOI: 10.1111/rssb.12222. Konietschke F, Brunner E (2023), DOI: 10.32614/RJ-2023-029. See the package vignettes and `inst/references/agriRank-methods-verified.ris` for engine-specific verified references.
}
\examples{
# Example 1
x<-simulate_agri("repeated_missing");
d<-agri_design(height~treatment*time,x,"repeated",subject=subject,within=time);
agri_missing_report(d)

# Example 2
x<-simulate_agri("repeated_missing",missing_rate=.25);
agri_missing_report(x,"height","subject","time")

# Example 3
x<-simulate_agri("crd"); x$yield[1:2]<-NA; agri_missing_report(x,"yield")
}
\seealso{\code{agri_design}, \code{agri_rank}, \code{agri_effects}, \code{agri_report}}
