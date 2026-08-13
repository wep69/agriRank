\name{np_splitplot}
\alias{np_splitplot}
\title{Analyze a split-plot experiment}
\description{Declares whole-plot and subplot strata before dispatching to a compatible backend.}
\usage{
np_splitplot(formula, data, block, whole_plot, subplot, method = "auto", ...)
}
\arguments{
  \item{formula}{A model formula defining the scientific treatment structure.}
  \item{data}{A data frame, preferably in long format.}
  \item{block}{Blocking variable(s) identifying the RCBD or nuisance randomization stratum.}
  \item{whole_plot}{Whole-plot treatment factor(s).}
  \item{subplot}{Subplot treatment factor(s).}
  \item{method}{Inferential engine name or `"auto"` for conservative design-based routing.}
  \item{...}{Additional arguments passed to the selected backend or downstream method.}
}
\details{A split-plot design contains hierarchical randomization and must not be analyzed as a simple CRD. The vignette suite documents the experimental-design logic, estimand, hypothesis, resampling structure, missing/unbalanced-data behavior, and backend-specific limitations in greater depth.}
\value{An `agri_rank_fit`.}
\references{
Pauly M, Brunner E, Konietschke F (2015), DOI: 10.1111/rssb.12073. Brunner E, Konietschke F, Pauly M, Puri ML (2017), DOI: 10.1111/rssb.12222. Konietschke F, Brunner E (2023), DOI: 10.32614/RJ-2023-029. See the package vignettes and `inst/references/agriRank-methods-verified.ris` for engine-specific verified references.
}
\examples{
# Example 1
x<-simulate_agri("split_plot");
if (requireNamespace("permuco", quietly = TRUE)) np_splitplot(yield ~ irrigation * 
    cultivar, x, block, irrigation, cultivar, "permuco")

# Example 2
x<-simulate_agri("split_plot");
if (requireNamespace("ARTool", quietly = TRUE)) np_splitplot(yield ~ irrigation * 
    cultivar, x, block, irrigation, cultivar, "ART")

# Example 3
x<-simulate_agri("split_plot");
if (requireNamespace("permuco", quietly = TRUE) || requireNamespace("ARTool", 
    quietly = TRUE)) np_splitplot(yield ~ irrigation * cultivar, x, block, 
    irrigation, cultivar)
}
\seealso{\code{agri_design}, \code{agri_rank}, \code{agri_effects}, \code{agri_report}}
