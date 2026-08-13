\name{agri_design}
\alias{agri_design}
\title{Declare an agricultural experimental design}
\description{Creates the design object that records the treatment formula, randomization strata, repeated-measures identifiers, quantitative treatments, and structural validation information.}
\usage{
agri_design(formula, data, design = c("crd", "rcbd", 
    "factorial", "split_plot", "split_split", "strip_plot", 
    "repeated", "longitudinal", "multienv", "multivariate"), 
    block = NULL, subject = NULL, within = NULL, whole_plot = NULL, 
    subplot = NULL, subsubplot = NULL, strip_a = NULL, 
    strip_b = NULL, environment = NULL, quantitative = NULL, 
    id = NULL)
}
\arguments{
  \item{formula}{A model formula defining the scientific treatment structure.}
  \item{data}{A data frame, preferably in long format.}
  \item{design}{A declared design type or an `agri_design` object, depending on context.}
  \item{block}{Blocking variable(s) identifying the RCBD or nuisance randomization stratum.}
  \item{subject}{Experimental-unit identifier for repeated or multivariate observations.}
  \item{within}{Within-subject factor(s), usually time or measurement occasion.}
  \item{whole_plot}{Whole-plot treatment factor(s).}
  \item{subplot}{Subplot treatment factor(s).}
  \item{subsubplot}{Sub-subplot treatment factor(s) for split-split experiments.}
  \item{strip_a}{First perpendicular strip treatment factor(s) for strip-plot experiments.}
  \item{strip_b}{Second perpendicular strip treatment factor(s) for strip-plot experiments.}
  \item{environment}{Environment/site/year factor in a multi-environment workflow.}
  \item{quantitative}{Treatment variables that should retain quantitative ordering rather than be treated only as categories.}
  \item{id}{Optional row or experimental-unit identifier used for validation.}
}
\details{Design declaration itself performs no treatment test. Split-split designs require block, whole-plot, subplot and sub-subplot declarations. Strip plots require block plus both perpendicular strip factors. Multi-environment declarations require the environment to be present in the fitted formula. The object is the contract used by downstream analysis functions. The vignette suite documents the experimental-design logic, estimand, hypothesis, resampling structure, missing/unbalanced-data behavior, and backend-specific limitations in greater depth.}
\value{An object of class `agri_design`.}
\references{
Pauly M, Brunner E, Konietschke F (2015), DOI: 10.1111/rssb.12073. Brunner E, Konietschke F, Pauly M, Puri ML (2017), DOI: 10.1111/rssb.12222. Konietschke F, Brunner E (2023), DOI: 10.32614/RJ-2023-029. See the package vignettes and `inst/references/agriRank-methods-verified.ris` for engine-specific verified references.
}
\examples{
# Example 1
d <- agri_design(yield ~ treatment, simulate_agri("crd"), design = "crd")

# Example 2
x <- simulate_agri("rcbd"); d <- agri_design(yield ~ treatment, x, design = "rcbd", block = block)

# Example 3
x <- simulate_agri("split_split");
d <- agri_design(yield ~ irrigation * cultivar * timing, x, design = "split_split", 
    block = block, whole_plot = irrigation, subplot = cultivar, subsubplot = timing)
}
\seealso{\code{agri_design}, \code{agri_rank}, \code{agri_effects}, \code{agri_report}}
