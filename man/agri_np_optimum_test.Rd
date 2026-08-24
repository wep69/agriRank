\name{agri_np_optimum_test}
\alias{agri_np_optimum_test}
\alias{print.agri_np_optimum_test}
\alias{plot.agri_np_optimum_test}
\title{Confidence interval and tests for the location of an optimum}
\description{
Resamples the location of the fitted optimum, rather than the fitted curve, so
that a recommended rate can be reported with the uncertainty it actually
carries. Optionally compares the optimum between levels of a qualitative
predictor.
}
\usage{
agri_np_optimum_test(object, by = NULL, objective = c("max", "min"),
                     B = 999L, level = 0.95, seed = 1, n = 200L,
                     fixed = list(), range = NULL, cluster = NULL,
                     adjust = c("holm", "none", "BH", "bonferroni",
                                "hochberg", "hommel", "BY"),
                     external = TRUE, parallel = FALSE)
}
\arguments{
\item{object}{An \code{agri_np_reg_fit} from \code{\link{agri_np_regression}}.}

\item{by}{Optional qualitative predictor whose levels are to be compared, as a
name or a string. It must already be a predictor of the fitted model.}

\item{objective}{\code{"max"} or \code{"min"}.}

\item{B}{Bootstrap replicates. Use at least 999 for anything reported.}

\item{level}{Confidence level of the interval for the optimum.}

\item{seed}{Random seed.}

\item{n}{Grid size on which the optimum is located.}

\item{fixed}{Values at which other covariates are held.}

\item{range}{Optional two-element range of the predictor to search within.}

\item{cluster}{Resampling unit. Defaults to the declared block, which keeps
whole blocks together. Pass \code{NA} to resample individual rows, which is
only legitimate for a completely randomized layout.}

\item{adjust}{Multiplicity adjustment applied across the pairwise contrasts
produced by \code{by}, passed to \code{\link[stats]{p.adjust}}. Defaults to
\code{"holm"}. With \code{k} levels there are \code{k(k-1)/2} comparisons and
the family-wise error rate grows accordingly. Use \code{"none"} only when a
single contrast was specified in advance.}

\item{external}{Cross-check against \code{npregfast::critical()} when that
package is installed.}

\item{parallel}{Distribute the replicates over a \code{future} plan, through
\pkg{future.apply}. The answer does not depend on it: each replicate is drawn
from its own L'Ecuyer-CMRG substream, so a run on four cores returns the same
interval as a run on one.}
}
\details{
\code{\link{agri_np_optimum}} returns a point, and a point is not a
recommendation. Two questions have to be answered first.

How precisely is the location determined? A response that plateaus has a
maximum that wanders over a wide stretch of the gradient from one resampled
experiment to the next, even when the curve itself is well estimated.

Is the maximum interior at all? An optimum reported at the edge of the tested
range is usually an artefact: a maximum has to land somewhere, and if the
response never turns over it lands on the boundary. \code{p_boundary} is the
share of replicates whose optimum falls on an end of the searched range, and
\code{identified} is \code{FALSE} when that share reaches one half. In that
situation the honest report is not a rate but the statement produced by
\code{\link{agri_np_significant_slope}}.

The resampling is the package's own cluster bootstrap, so whole blocks are
resampled and the declared randomization is respected. With \code{by}, every
pair of levels is compared through the bootstrap distribution of the difference
between their optima, computed inside the same resampling loop so that the two
optima of a replicate come from the same resampled experiment. The p-value is
the resampling p-value with the Davison and Hinkley correction, so its smallest
attainable value is \code{2/(B + 1)} rather than zero.

Comparing optima requires a model in which the curves may have different
shapes. A qualitative predictor entering additively forces parallel curves and
therefore one common optimum, so the function detects that and refuses instead
of reporting a difference of exactly zero. Fit with
\code{gam_structure = "varying"}, which gives one smooth per level.

Nothing here assumes a distribution for the response and nothing fits a
parametric response function. The optimum is located by evaluation on a grid,
exactly as in \code{\link{agri_np_optimum}}.
}
\value{
An object of class \code{agri_np_optimum_test}, a list with components
\code{optimum}, \code{contrasts}, \code{replicates}, \code{curves} and
\code{external}.
}
\references{
Davison, A. C. and Hinkley, D. V. (1997). \emph{Bootstrap Methods and their
Application}. Cambridge University Press.

Sperlich, S., Gonzalez-Manteiga, W. and Roca-Pardinas, J. (2013). Bootstrap
inference for nonparametric regression.
}
\seealso{
\code{\link{agri_np_optimum}} for the point estimate,
\code{\link{agri_np_sizer}} for where the response is still changing,
\code{\link{agri_integer_optimum}} when the decision is an integer.
}
\examples{
data(agri_dose)

# Example 1. A nitrogen response that plateaus. The fitted maximum sits on the
# boundary, and resampling shows it is there in every replicate, so no rate is
# identified. B is small here for speed.
fit <- agri_np_regression(yield ~ dose, agri_dose, method = "gam", block = block)
ot <- agri_np_optimum_test(fit, B = 39, seed = 1, n = 40, external = FALSE)
ot$optimum

# Example 2. The distribution of the resampled optimum. Mass piled against an
# end of the range is the visual form of the same conclusion.
p <- plot(ot, type = "distribution")
class(p)

# Example 3. Comparing two cultivars needs a model whose curves may differ in
# shape, so the qualitative predictor must enter through a varying smooth.
set.seed(7)
a <- agri_dose; a$cultivar <- "late"
b <- agri_dose; b$cultivar <- "early"
b$yield <- b$yield - 0.000045 * (b$dose - 160)^2 + rnorm(nrow(b), 0, 0.15)
d2 <- rbind(a, b)
d2$cultivar <- factor(d2$cultivar, levels = c("early", "late"))

fit2 <- agri_np_regression(yield ~ dose + cultivar, d2, method = "gam",
                           block = block, gam_structure = "varying")
ot2 <- agri_np_optimum_test(fit2, by = cultivar, B = 39, seed = 1, n = 40,
                            external = FALSE)
ot2$optimum
ot2$contrasts

# Example 4. An additive adjustment forces parallel curves, so the comparison
# is refused rather than answered with a difference of zero.
fit_add <- agri_np_regression(yield ~ dose + cultivar, d2, method = "gam",
                              block = block)
res <- tryCatch(agri_np_optimum_test(fit_add, by = cultivar, B = 19),
                error = function(e) conditionMessage(e))
cat(res, "\n")

# Example 5. An integer decision is not located on a continuous grid, so the
# function points to the integer machinery instead.
data(agri_density)
fi <- agri_np_regression(yield ~ plants, agri_density, method = "integer_grid",
                         integer_base_method = "smoothing_spline",
                         predictor_support = "observed_integer")
res2 <- tryCatch(agri_np_optimum_test(fi), error = function(e) conditionMessage(e))
cat(res2, "\n")
}
\keyword{regression}
