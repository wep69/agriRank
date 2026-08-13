\name{validate_agri_design}
\alias{validate_agri_design}
\title{Validate an agricultural experimental design}
\description{Checks missing design variables, all-missing responses, empty factorial cells, duplicated repeated cells, numeric block coding, and other structural problems before inference.}
\usage{
validate_agri_design(x, error = TRUE)
}
\arguments{
  \item{x}{An agriRank design or fitted object as documented for the function.}
  \item{error}{Logical; if `TRUE`, fatal design-validation problems stop execution.}
}
\details{Fatal structural errors can stop execution; warnings preserve information that may affect estimability or interpretation. The vignette suite documents the experimental-design logic, estimand, hypothesis, resampling structure, missing/unbalanced-data behavior, and backend-specific limitations in greater depth.}
\value{An `agri_validation` list with `ok` and a table of problems.}
\references{
Pauly M, Brunner E, Konietschke F (2015), DOI: 10.1111/rssb.12073. Brunner E, Konietschke F, Pauly M, Puri ML (2017), DOI: 10.1111/rssb.12222. Konietschke F, Brunner E (2023), DOI: 10.32614/RJ-2023-029. See the package vignettes and `inst/references/agriRank-methods-verified.ris` for engine-specific verified references.
}
\examples{
# Example 1
validate_agri_design(agri_design(yield ~ treatment, simulate_agri("crd"), "crd"), error = FALSE)

# Example 2
x <- simulate_agri("factorial");
x <- subset(x, !(A=="A2" & B=="B3"));
validate_agri_design(agri_design(yield~A*B,x,"factorial"), error=FALSE)

# Example 3
x <- simulate_agri("repeated");
x <- rbind(x,x[1,]);
validate_agri_design(agri_design(height ~ treatment * time, x, "repeated", 
    subject = subject, within = time), error = FALSE)
}
\seealso{\code{agri_design}, \code{agri_rank}, \code{agri_effects}, \code{agri_report}}
