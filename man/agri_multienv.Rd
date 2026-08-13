\name{agri_multienv}
\alias{agri_multienv}
\title{Analyze multi-environment treatment data with enforced environment structure}
\description{Declares environment and optional within-environment block information before fitting a rank/permutation workflow.}
\usage{
agri_multienv(formula, data, environment, block = NULL, 
    method = "auto", environment_interaction = TRUE, ...)
}
\arguments{
\item{formula}{Treatment formula. Environment may be omitted because it is enforced by this wrapper.}
\item{data}{Data frame.}
\item{environment}{One environment/site/year factor.}
\item{block}{Optional block factor; repeated block labels are namespaced within environment by block-aware engines.}
\item{method}{Inferential backend or `"auto"`.}
\item{environment_interaction}{If TRUE and environment is missing from the formula, add treatment-by-environment interactions. If FALSE, add the environment main effect only. An explicitly supplied environment formula is respected.}
\item{...}{Additional backend arguments.}
}
\details{Direct \code{agri_design(..., design="multienv")} declarations require environment to be in the formula. \code{agri_multienv()} is the convenience layer that injects it when absent, preventing accidental pooled genotype-only inference. When \code{environment_interaction = FALSE} creates an additive multi-environment model, automatic routing uses \pkg{permuco}; the ARTool adapter is reserved for factorial fixed-effect structures that include the relevant interactions.}
\value{An `agri_rank_fit` with environment enforcement metadata.}
\examples{
x<-simulate_agri("multienv");
if (requireNamespace("ARTool", quietly = TRUE) || requireNamespace("permuco", 
    quietly = TRUE)) agri_multienv(yield ~ genotype, x, environment, block)
x<-simulate_agri("multienv");
if (requireNamespace("ARTool", quietly = TRUE)) agri_multienv(yield ~ genotype * 
    environment, x, environment, block, method = "ART")
x<-simulate_agri("multienv");
if (requireNamespace("permuco", quietly = TRUE)) agri_multienv(yield ~ 
    genotype, x, environment, block, method = "permuco", environment_interaction = FALSE, 
    np = 99)
}
\seealso{\code{agri_design}, \code{agri_multivariate}, \code{agri_rank}}
