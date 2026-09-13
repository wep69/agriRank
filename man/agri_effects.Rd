\name{agri_effects}
\alias{agri_effects}
\title{Extract treatment effect summaries}
\description{Estimates of the effect declared in \code{agri_rank(estimand = )}. The descriptive block (\code{cell}, \code{n}, \code{median}, \code{mean_rank}) is always reported and the estimator of the declared estimand is added beside it, so the declaration changes the numbers and not only the label.}
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
\details{The added estimator follows \code{fit$estimand}. For \code{"relative_effect"} it is the Brunner-Munzel relative effect of each cell against the pooled sample, \code{p_i = (Rbar_i - (n_i + 1)/2) / N}, which is a function of the mean rank already reported and is the quantity the rank-based omnibus test is about. For \code{"location_shift"} it is the Hodges-Lehmann shift of each cell against the first level, which is named in the \code{reference} column, because a location shift is a paired statement. For \code{"distribution"} the descriptive block stands alone, because the target is the whole distribution and not a single summary number.

Before 0.14.1 the three values returned exactly the same table, so a user who declared a relative-effect analysis received medians without being told. When the selected engine estimates effects itself, as nparLD and the native wild bootstrap do, those engine estimates are returned and \code{fit$estimand_source} records that the engine answered the declaration. The vignette suite documents the experimental-design logic, estimand, hypothesis, resampling structure, missing/unbalanced-data behavior, and backend-specific limitations in greater depth.}
\value{A data frame with one row per treatment cell.}
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

# Example 4, the declaration selects the estimator
d<-agri_design(yield~treatment,simulate_agri("crd"),"crd");
agri_effects(agri_rank(d,estimand="relative_effect"))
agri_effects(agri_rank(d,estimand="location_shift"))
}
\seealso{\code{agri_design}, \code{agri_rank}, \code{agri_effects}, \code{agri_p}, \code{agri_report}}
