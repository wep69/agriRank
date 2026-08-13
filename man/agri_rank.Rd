\name{agri_rank}
\alias{agri_rank}
\title{Fit design-aware rank-based or permutation inference}
\description{Routes a declared design to an explicit or automatically selected admissible engine.}
\usage{
agri_rank(design, method = "auto", response = NULL, 
    estimand = c("relative_effect", "distribution", 
        "location_shift"), B = 1999, seed = 1, missing_assumption = c("unspecified", 
        "MCAR", "MAR-sensitivity"), ...)
}
\arguments{
  \item{design}{A declared design type or an `agri_design` object, depending on context.}
  \item{method}{Inferential engine name or `"auto"` for conservative design-based routing.}
  \item{response}{Optional response column name when a design contains more than one response.}
  \item{estimand}{Target effect representation used to label and interpret the analysis.}
  \item{B}{Number of bootstrap or resampling replicates. Small values are for examples only.}
  \item{seed}{Random seed used for reproducible resampling.}
  \item{missing_assumption}{Label recording the assumed missingness framework; this is not inferred from the data.}
  \item{...}{Additional arguments passed to the selected backend or downstream method.}
}
\details{Automatic routing is design-driven; it does not select a method from a preliminary normality p-value. Blocked incomplete repeated measures are deliberately rejected in the current build. The vignette suite documents the experimental-design logic, estimand, hypothesis, resampling structure, missing/unbalanced-data behavior, and backend-specific limitations in greater depth.}
\value{An `agri_rank_fit` object.}
\references{
Pauly M, Brunner E, Konietschke F (2015), DOI: 10.1111/rssb.12073. Brunner E, Konietschke F, Pauly M, Puri ML (2017), DOI: 10.1111/rssb.12222. Konietschke F, Brunner E (2023), DOI: 10.32614/RJ-2023-029. See the package vignettes and `inst/references/agriRank-methods-verified.ris` for engine-specific verified references.
}
\examples{
# Example 1
d<-agri_design(yield~treatment,simulate_agri("crd"),"crd"); agri_rank(d)

# Example 2
x<-simulate_agri("factorial");
d<-agri_design(yield~A*B,x,"factorial");
if(requireNamespace("rankFD",quietly=TRUE)) agri_rank(d,"rankFD")

# Example 3
x<-simulate_agri("repeated_missing");
d<-agri_design(height~treatment*time,x,"repeated",subject=subject,within=time);
agri_rank(d,"incomplete_wild",B=299,missing_assumption="MCAR")
}
\seealso{\code{agri_design}, \code{agri_rank}, \code{agri_effects}, \code{agri_report}}
