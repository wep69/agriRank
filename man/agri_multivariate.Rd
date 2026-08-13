\name{agri_multivariate}
\alias{agri_multivariate}
\title{Integrated multivariate resampling inference}
\description{Routes multivariate analyses through MANOVA.RM and returns a common `agri_multivariate_fit` object accepted by agriRank tables, reports, dashboards and exports.}
\usage{
agri_multivariate(formula, data, subject = NULL, within = NULL, 
    block = NULL, resampling = "WildBS", iter = 4999, seed = 1, 
    ...)
}
\arguments{
\item{formula}{Model formula. Use `cbind(y1, y2, ...) ~ ...` for wide multivariate responses.}
\item{data}{Data frame.}
\item{subject}{Subject/unit identifier for long-format MANOVA or multivariate repeated measures.}
\item{within}{Optional within-subject factor(s); with multiple responses this routes to \code{MANOVA.RM::multRM()}. The declared within factors are enforced in the fitted formula after the between-subject factors.}
\item{block}{Optional agronomic block adjustment. If omitted from the formula it is added as an adjustment factor.}
\item{resampling}{Resampling scheme passed to MANOVA.RM.}
\item{iter}{Number of resampling iterations.}
\item{seed}{Reproducible seed.}
\item{...}{Additional backend arguments.}
}
\details{Multiple responses without \code{within} use \code{MANOVA.RM::MANOVA.wide()}. A single long-format response with \code{subject} uses \code{MANOVA.RM::MANOVA()}. Multiple responses plus \code{within} use \code{MANOVA.RM::multRM()}. For the multivariate repeated-measures route, agriRank canonicalizes the scientific formula so the between-subject factors precede the declared within-subject factors and the full between-by-within factorial structure is represented, as required by the MANOVA.RM interface. Missing modeled values are rejected before fitting. Block adjustment is treated as an additive model factor by the MANOVA.RM backend, not as a random block effect.}
\value{An object of class `agri_multivariate_fit` containing the declared design, standardized omnibus table, descriptive and covariance components, backend object, seed and reproducibility metadata.}
\references{Friedrich S, Konietschke F, Pauly M (2019). The R Journal 11(2), 380-400. DOI: 10.32614/RJ-2019-051. Friedrich S, Pauly M (2018). Journal of Multivariate Analysis 165, 166-179.}
\examples{
if(requireNamespace("MANOVA.RM",quietly=TRUE)){set.seed(1);
x<-data.frame(trt=factor(rep(1:3,each=8)),y1=rnorm(24),y2=rnorm(24));
z<-agri_multivariate(cbind(y1,y2)~trt,x,iter=99);
print(z)}
if(requireNamespace("MANOVA.RM",quietly=TRUE)){set.seed(2);
x <- data.frame(block = factor(rep(1:4, each = 6)), trt = factor(rep(rep(1:3, 
    each = 2), 4)), y1 = rnorm(24), y2 = rnorm(24))
z<-agri_multivariate(cbind(y1,y2)~trt,x,block=block,iter=99);
agri_table(z)}
if(requireNamespace("MANOVA.RM",quietly=TRUE)){set.seed(3);
x<-data.frame(trt=factor(rep(1:2,each=10)),y1=rnorm(20),y2=rnorm(20));
z<-agri_multivariate(cbind(y1,y2)~trt,x,iter=99);
f<-tempfile(fileext=".md");
agri_report(z,f);
file.exists(f)}
if(requireNamespace("MANOVA.RM",quietly=TRUE)){set.seed(4);
x<-expand.grid(subject=factor(1:8),time=factor(c("T1","T2")));
x$trt<-factor(ifelse(as.integer(x$subject)<=4,"A","B"));
x$y1<-rnorm(nrow(x));
x$y2<-rnorm(nrow(x));
z<-agri_multivariate(cbind(y1,y2)~trt,x,subject=subject,within=time,iter=99);
z$formula}
}
\seealso{\code{agri_table}, \code{agri_report}, \code{agri_multienv}}
