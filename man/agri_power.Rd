\name{agri_power}
\alias{agri_power}
\title{Estimate power by simulation}
\description{Simulates the full intended analysis workflow and estimates rejection probability with Monte Carlo uncertainty.}
\usage{
agri_power(generator, analyzer, nsim = 1000, alpha = 0.05, seed = 1)
}
\arguments{
  \item{generator}{Function receiving simulation index `i` and returning one synthetic data frame.}
  \item{analyzer}{Function receiving one synthetic data frame and returning a p-value or an `agri_rank_fit`.}
  \item{nsim}{Number of simulated experiments.}
  \item{alpha}{Significance threshold used to derive a compact letter display.}
  \item{seed}{Random seed used for reproducible resampling.}
}
\details{The result is specific to the supplied generator and analyzer. The vignette suite documents the experimental-design logic, estimand, hypothesis, resampling structure, missing/unbalanced-data behavior, and backend-specific limitations in greater depth.}
\value{An `agri_power` object.}
\references{
Pauly M, Brunner E, Konietschke F (2015), DOI: 10.1111/rssb.12073. Brunner E, Konietschke F, Pauly M, Puri ML (2017), DOI: 10.1111/rssb.12222. Konietschke F, Brunner E (2023), DOI: 10.32614/RJ-2023-029. See the package vignettes and `inst/references/agriRank-methods-verified.ris` for engine-specific verified references.
}
\examples{
# Example 1
G<-function(i) simulate_agri("crd",seed=100+i);
A<-function(z) np_crd(yield~treatment,z)$omnibus$p_value[1];
agri_power(G,A,nsim=30)

# Example 2
G<-function(i) simulate_agri("rcbd",seed=200+i);
A<-function(z) np_rcbd(yield~treatment,z,block);
agri_power(G,A,nsim=30)

# Example 3
G<-function(i) simulate_agri("crd",seed=300+i,n=8);
A<-function(z) np_crd(yield~treatment,z)$omnibus$p_value[1];
agri_power(G,A,nsim=30,alpha=.01)
}
\seealso{\code{agri_design}, \code{agri_rank}, \code{agri_effects}, \code{agri_report}}
