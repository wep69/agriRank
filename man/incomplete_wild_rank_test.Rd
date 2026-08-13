\name{incomplete_wild_rank_test}
\alias{incomplete_wild_rank_test}
\title{Wild-bootstrap rank inference for incomplete repeated measurements}
\description{Implements an experimental rank-based quadratic-form procedure with ATS, WTS, or MATS and subject-level wild multipliers for incompletely observed unblocked repeated factorial designs.}
\usage{
incomplete_wild_rank_test(design, response = NULL, B = 1999, statistic = c("ATS", 
    "WTS", "MATS"), weights = c("rademacher", "mammen", "normal", "poisson"), 
    seed = 1, missing_assumption = c("unspecified", "MCAR", "MAR-sensitivity"), 
    correction = TRUE, terms = NULL)
}
\arguments{
  \item{design}{A declared design type or an `agri_design` object, depending on context.}
  \item{response}{Optional response column name when a design contains more than one response.}
  \item{B}{Number of bootstrap or resampling replicates. Small values are for examples only.}
  \item{statistic}{Quadratic-form statistic, one of ATS, WTS, or MATS where supported.}
  \item{weights}{Wild-bootstrap multiplier distribution.}
  \item{seed}{Random seed used for reproducible resampling.}
  \item{missing_assumption}{Label recording the assumed missingness framework; this is not inferred from the data.}
  \item{correction}{Logical; use the Monte Carlo correction for bootstrap p-values.}
  \item{terms}{Optional subset of repeated-measures model terms to test.}
}
\details{The theoretical reference framework is primarily MCAR. The implementation remains experimental until independent numerical benchmarking is complete; blocked incomplete repeated designs are rejected. The vignette suite documents the experimental-design logic, estimand, hypothesis, resampling structure, missing/unbalanced-data behavior, and backend-specific limitations in greater depth.}
\value{An `agri_incomplete_wild` object.}
\references{
Pauly M, Brunner E, Konietschke F (2015), DOI: 10.1111/rssb.12073. Brunner E, Konietschke F, Pauly M, Puri ML (2017), DOI: 10.1111/rssb.12222. Konietschke F, Brunner E (2023), DOI: 10.32614/RJ-2023-029. See the package vignettes and `inst/references/agriRank-methods-verified.ris` for engine-specific verified references.
}
\examples{
# Example 1
x<-simulate_agri("repeated_missing");
d<-agri_design(height~treatment*time,x,"repeated",subject=subject,within=time);
incomplete_wild_rank_test(d,B=299,statistic="ATS",missing_assumption="MCAR")

# Example 2
x<-simulate_agri("repeated_missing");
d<-agri_design(height~treatment*time,x,"repeated",subject=subject,within=time);
incomplete_wild_rank_test(d,B=299,statistic="WTS",weights="mammen",missing_assumption="MCAR")

# Example 3
x<-simulate_agri("repeated_missing");
d<-agri_design(height~treatment*time,x,"repeated",subject=subject,within=time);
incomplete_wild_rank_test(d, B = 299, statistic = "MATS", weights = "normal", 
    missing_assumption = "MAR-sensitivity")
}
\seealso{\code{agri_design}, \code{agri_rank}, \code{agri_effects}, \code{agri_report}}
