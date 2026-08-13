\name{agri_effects}
\alias{agri_effects}
\title{Extract treatment effect summaries}
\description{Returns backend-provided effects when available or observed-cell descriptive rank summaries otherwise.}
\usage{
agri_effects(x, ci = FALSE, level = 0.95, B = if (ci) 999 else 0, seed = 1)
}
\arguments{
  \item{x}{An agriRank design or fitted object as documented for the function.}
  \item{ci}{Logical; request uncertainty intervals when supported.}
  \item{level}{Confidence level.}
  \item{B}{Number of bootstrap or resampling replicates. Small values are for examples only.}
  \item{seed}{Random seed used for reproducible resampling.}
}
\details{Interpret the returned effect according to the engine and estimand. The vignette suite documents the experimental-design logic, estimand, hypothesis, resampling structure, missing/unbalanced-data behavior, and backend-specific limitations in greater depth.}
\value{A data frame.}
\references{
Pauly M, Brunner E, Konietschke F (2015), DOI: 10.1111/rssb.12073. Brunner E, Konietschke F, Pauly M, Puri ML (2017), DOI: 10.1111/rssb.12222. Konietschke F, Brunner E (2023), DOI: 10.32614/RJ-2023-029. See the package vignettes and `inst/references/agriRank-methods-verified.ris` for engine-specific verified references.
}
\examples{
# Example 1
fit<-np_crd(yield~treatment,simulate_agri("crd")); agri_effects(fit)

# Example 2
fit<-np_crd(yield~treatment,simulate_agri("crd")); agri_effects(fit,ci=TRUE,B=199)

# Example 3
x<-simulate_agri("factorial");
if(requireNamespace("rankFD",quietly=TRUE)){fit<-np_factorial(yield~A*B,x,method="rankFD");
agri_effects(fit)}
}
\seealso{\code{agri_design}, \code{agri_rank}, \code{agri_effects}, \code{agri_report}}
