\name{np_splitsplit}
\alias{np_splitsplit}
\title{Design-aware nonparametric split-split-plot workflow}
\description{Declares three hierarchical treatment strata and routes inference through a backend that preserves block, whole-plot and subplot experimental units.}
\usage{
np_splitsplit(formula, data, block, whole_plot, subplot, 
    subsubplot, method = "auto", ...)
}
\arguments{
\item{formula}{Factorial model formula containing whole-plot, subplot and sub-subplot treatment factors.}
\item{data}{Data frame in long format.}
\item{block}{Blocking factor.}
\item{whole_plot}{Whole-plot treatment factor.}
\item{subplot}{Subplot treatment factor.}
\item{subsubplot}{Sub-subplot treatment factor.}
\item{method}{`"auto"`, `"permuco"`, or `"ART"`.}
\item{...}{Additional backend arguments.}
}
\details{The declared hierarchy is block -> whole plot -> subplot -> sub-subplot. The permuco adapter uses an Error(block/whole_plot/subplot) hierarchy; the ART adapter uses random intercepts for block, whole-plot units, and subplot units. Numerical calibration must be verified locally before release.}
\value{An object of class `agri_rank_fit`.}
\examples{
x <- simulate_agri("split_split", seed = 1)
d <- agri_design(yield ~ irrigation * cultivar * timing, x, design = "split_split", 
    block = block, whole_plot = irrigation, subplot = cultivar, subsubplot = timing)
if (requireNamespace("permuco", quietly = TRUE)) np_splitsplit(yield ~ 
    irrigation * cultivar * timing, x, block, irrigation, cultivar, timing, 
    method = "permuco", np = 99)
if (requireNamespace("ARTool", quietly = TRUE)) np_splitsplit(yield ~ irrigation * 
    cultivar * timing, x, block, irrigation, cultivar, timing, method = "ART")
}
\seealso{\code{np_splitplot}, \code{np_stripplot}, \code{agri_design}}
