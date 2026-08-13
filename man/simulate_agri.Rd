\name{simulate_agri}
\alias{simulate_agri}
\title{Simulate representative agricultural experiments}
\description{Generates reproducible teaching data for CRD, RCBD, factorial, split-plot, split-split, strip-plot, repeated, incomplete repeated, and multi-environment workflows.}
\usage{
simulate_agri(design = c("crd", "rcbd", "factorial", "split_plot", "split_split", 
    "strip_plot", "repeated", "repeated_missing", "multienv"), seed = 123, 
    n = 6, missing_rate = 0.2)
}
\arguments{
  \item{design}{A declared design type or an `agri_design` object, depending on context.}
  \item{seed}{Random seed used for reproducible resampling.}
  \item{n}{Replication or block count used by the selected synthetic-data generator.}
  \item{missing_rate}{Probability used to introduce missing responses in the synthetic repeated-data generator.}
}
\details{These are synthetic teaching data, not evidence from real experiments. The vignette suite documents the experimental-design logic, estimand, hypothesis, resampling structure, missing/unbalanced-data behavior, and backend-specific limitations in greater depth.}
\value{A data frame.}
\references{
Pauly M, Brunner E, Konietschke F (2015), DOI: 10.1111/rssb.12073. Brunner E, Konietschke F, Pauly M, Puri ML (2017), DOI: 10.1111/rssb.12222. Konietschke F, Brunner E (2023), DOI: 10.32614/RJ-2023-029. See the package vignettes and `inst/references/agriRank-methods-verified.ris` for engine-specific verified references.
}
\examples{
# Example 1
simulate_agri("crd",seed=1)

# Example 2
simulate_agri("repeated_missing",seed=2,n=8,missing_rate=.15)

# Example 3
simulate_agri("multienv",seed=3,n=5)
}
\seealso{\code{agri_design}, \code{agri_rank}, \code{agri_effects}, \code{agri_report}}
