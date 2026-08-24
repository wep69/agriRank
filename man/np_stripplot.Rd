\name{np_stripplot}
\alias{np_stripplot}
\title{Design-aware nonparametric strip-plot workflow}
\description{Declares two perpendicular strip treatment factors and preserves their distinct block-by-strip error strata.}
\usage{np_stripplot(formula, data, block, strip_a, strip_b, method = "auto", ...)}
\arguments{
\item{formula}{Factorial model formula containing the two strip treatment factors.}
\item{data}{Data frame in long format.}
\item{block}{Blocking factor.}
\item{strip_a}{First strip treatment factor.}
\item{strip_b}{Second perpendicular strip treatment factor.}
\item{method}{`"auto"` or `"ART"`. Auto prefers ARTool when available; permuco is not admissible for strip-plots.}
\item{...}{Additional backend arguments.}
}
\details{The ART adapter represents random block, block-by-strip-A and block-by-strip-B terms. permuco is not admissible for this design; see `PERMUCO_ISOLAMENTO.md` for the rationale.}
\value{An object of class `agri_rank_fit`.}
\examples{
x <- simulate_agri("strip_plot", seed = 2)
d <- agri_design(yield ~ irrigation * nitrogen, x, design = "strip_plot", 
    block = block, strip_a = irrigation, strip_b = nitrogen)
# Auto selects ART when ARTool is installed:
np_stripplot(yield ~ irrigation * nitrogen, x, block, irrigation, nitrogen)
# Or explicitly:
if (requireNamespace("ARTool", quietly = TRUE)) np_stripplot(yield ~ irrigation * 
    nitrogen, x, block, irrigation, nitrogen, method = "ART")
}
\seealso{\code{np_splitplot}, \code{np_splitsplit}, \code{agri_design}}
