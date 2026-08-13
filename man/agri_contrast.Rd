\name{agri_contrast}
\alias{agri_contrast}
\title{Test user-defined contrasts}
\description{Tests arbitrary contrast matrices for the native incomplete repeated wild-rank engine with simultaneous resampling calibration.}
\usage{
agri_contrast(x, C, labels = NULL, B = NULL, seed = NULL, adjust = "holm", level = 0.95)
}
\arguments{
  \item{x}{An agriRank design or fitted object as documented for the function.}
  \item{C}{Numeric contrast matrix with columns matching the native repeated cell grid.}
  \item{labels}{Optional labels for rows of the contrast matrix.}
  \item{B}{Number of bootstrap or resampling replicates. Small values are for examples only.}
  \item{seed}{Random seed used for reproducible resampling.}
  \item{adjust}{Multiplicity adjustment method.}
  \item{level}{Confidence level.}
}
\details{General user-defined contrasts for other engines should currently be obtained from the backend object. The vignette suite documents the experimental-design logic, estimand, hypothesis, resampling structure, missing/unbalanced-data behavior, and backend-specific limitations in greater depth.}
\value{A data frame of contrast estimates and uncertainty.}
\references{
Pauly M, Brunner E, Konietschke F (2015), DOI: 10.1111/rssb.12073. Brunner E, Konietschke F, Pauly M, Puri ML (2017), DOI: 10.1111/rssb.12222. Konietschke F, Brunner E (2023), DOI: 10.32614/RJ-2023-029. See the package vignettes and `inst/references/agriRank-methods-verified.ris` for engine-specific verified references.
}
\examples{
# Example 1
x<-simulate_agri("repeated_missing");
d<-agri_design(height~treatment*time,x,"repeated",subject=subject,within=time);
f<-agri_rank(d,"incomplete_wild",B=299,missing_assumption="MCAR");
k<-nrow(f$engine$prep$cell_grid);
C<-matrix(c(1,-1,rep(0,k-2)),1);
agri_contrast(f,C,B=299)

# Example 2
x<-simulate_agri("repeated_missing");
d<-agri_design(height~treatment*time,x,"repeated",subject=subject,within=time);
f<-agri_rank(d,"incomplete_wild",B=299,missing_assumption="MCAR");
k<-nrow(f$engine$prep$cell_grid);
C<-rbind(c(1,-1,rep(0,k-2)),c(rep(0,2),1,-1,rep(0,k-4)));
agri_contrast(f,C,B=299)

# Example 3
x<-simulate_agri("repeated_missing");
d<-agri_design(height~treatment*time,x,"repeated",subject=subject,within=time);
f<-agri_rank(d,"incomplete_wild",B=299,missing_assumption="MCAR");
k<-nrow(f$engine$prep$cell_grid);
C<-diag(k)[1,,drop=FALSE]-diag(k)[k,,drop=FALSE];
agri_contrast(f,C,labels="first-last",B=299)
}
\seealso{\code{agri_design}, \code{agri_rank}, \code{agri_effects}, \code{agri_report}}
