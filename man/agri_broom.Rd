\name{agri_broom}
\alias{agri_broom}
\alias{agri_tidy}
\alias{agri_glance}
\alias{agri_augment}
\title{Tidy an agriRank fit into a data frame}
\usage{
agri_tidy(x, ...)

agri_glance(x, ...)

agri_augment(x, ...)
}
\arguments{
\item{x}{An \code{agri_np_reg_fit} or an \code{agri_rank_fit}.}
\item{...}{For a regression fit: \code{n}, the grid size for the tidied curve;
\code{conf.int}, whether to add a cluster-bootstrap interval, which resamples
and so is not free; \code{conf.level}; and for \code{agri_augment()},
\code{data} or \code{newdata}. Other arguments reach
\code{\link{agri_np_bootstrap}} or \code{\link{agri_np_predict}}.}
}
\description{\code{tidy()}, \code{glance()} and \code{augment()} methods in the
sense of the broom package, so that an agriRank result travels into a report
through the same vocabulary as any other model.}
\details{
The broom generics are registered when broom is installed and are absent
otherwise, because broom is a suggestion rather than a dependency. The
\code{agri_*} functions documented here reach the same code without loading
broom at all.

\code{agri_tidy()} on a regression fit returns the \strong{fitted curve}, one
row per grid point, not a coefficient table. Most of the sixteen engines have no
coefficients, and those that do have them for a spline basis rather than for any
quantity worth reporting. There is no \code{p.value} column for the same reason:
no test was performed. For a test use \code{\link{agri_np_optimum_test}},
\code{\link{agri_np_significance}}, or the rank-based side of the package, whose
\code{agri_tidy()} does return one row per term with a p-value.

\code{agri_augment()} without \code{data} or \code{newdata} uses the rows stored
in the fit, which is the only choice guaranteed to align with the fitted values.
A rank-based fit has no per-row fitted value to attach, and the call is refused
with a pointer to \code{\link{agri_effects}}.
}
\value{A data frame.}
\seealso{\code{\link{agri_np_diagnostics}} for the fuller diagnostic summary,
\code{\link{agri_table}} and \code{\link{agri_report}} for the package's own
reporting path.}
\examples{
data(agri_dose)
fit <- agri_np_regression(yield ~ dose, agri_dose, method = "smoothing_spline")

# Example 1: the fitted curve, one row per grid point
head(agri_tidy(fit, n = 25))

# Example 2: one row describing the whole fit
agri_glance(fit)

# Example 3: the original rows with fitted values and residuals attached
head(agri_augment(fit))

# Example 4: the rank side tidies to one row per term, with a p-value, because
# there a test was actually performed. Note that the rank engines compare
# levels, so the rate enters as a factor rather than as a number; for the
# quantitative gradient itself, the regression side above is the right tool.
if (requireNamespace("ARTool", quietly = TRUE)) {
  d <- agri_dose
  d$rate <- factor(d$dose)
  des <- agri_design(yield ~ rate, d, design = "rcbd", block = "block")
  agri_tidy(agri_rank(des, method = "ART"))
}
}
