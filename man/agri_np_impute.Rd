\name{agri_np_impute}
\alias{agri_np_impute}
\alias{print.agri_np_impute}
\title{Multiple imputation for a regression with missing plots}
\usage{
agri_np_impute(formula, data, block = NULL, m = 5L, B = 199L,
               level = 0.95, seed = 1, n = 100L, method = "gam",
               mice_method = "pmm", parallel = FALSE, ...)
}
\arguments{
\item{formula}{Regression formula.}
\item{data}{Data frame, with gaps.}
\item{block}{Optional block, which becomes the resampling unit.}
\item{m}{Number of imputations. Five is the classical default and ten is safer
when the fraction of missing information is appreciable.}
\item{B}{Bootstrap replicates used for the within-imputation variance. This is
\code{m * B} refits in total, so it is the expensive argument.}
\item{level}{Confidence level.}
\item{seed}{Random seed.}
\item{n}{Grid size.}
\item{method}{Engine, passed to \code{\link{agri_np_regression}}.}
\item{mice_method}{Imputation method passed to \code{mice::mice()}. Predictive
mean matching, the default, draws replacement values from observed ones and so
cannot invent a yield outside the range that was actually seen.}
\item{parallel}{Distribute the bootstrap replicates over a \code{future} plan.}
\item{...}{Passed to \code{\link{agri_np_regression}}.}
}
\description{Refits the regression on \code{m} imputed data sets, pools the
curve by Rubin's rules, and always reports the complete-case fit beside it so
that the two can be compared. Requires the \pkg{mice} package.}
\details{
The regression module offered complete-case analysis and nothing else, with
\code{na_action = "fail"} as the default so that rows were never dropped
silently. That default is right and stays. But complete-case analysis is
unbiased only when the missingness is unrelated to the response, and in a field
trial it usually is not: the plot that was lost is often the flooded one, the
grazed one, the one at the end of the row.

\strong{This is the one place in the package that assumes a missingness
mechanism.} Multiple imputation is valid when the data are missing at random
given the observed variables, and that is an assumption about why the plots were
lost, not a property the data can confirm. Everything else in agriRank avoids
such assumptions; this function makes one deliberately, and reports the
complete-case answer alongside so that the reader can see what the assumption
bought.

Read the two together. If the imputed and complete-case curves agree, the
missingness is not driving the conclusion and the simpler analysis can be
reported. If they disagree, that disagreement is the finding: the conclusion
depends on what was assumed about the plots that were lost, and the methods
section has to say so. The printed output computes the gap as a percentage of
the tested range and says which case applies.

The pooled variance at each grid point is the average within-imputation
bootstrap variance plus \code{(1 + 1/m)} times the variance of the \code{m}
point estimates. The block survives into the within part because that part uses
the package's cluster bootstrap. The \code{fmi} column of \code{$curve} is the
fraction of missing information, which says how much the imputation is actually
doing at each point of the curve.
}
\value{An object of class \code{agri_np_impute}.}
\seealso{\code{\link{agri_missing_report}} and
\code{\link{agri_missing_sensitivity}} for the rank-based side,
\code{\link{agri_np_regression}} with \code{na_action = "complete"} for the
explicit complete-case route.}
\references{
Rubin, D. B. (1987). \emph{Multiple Imputation for Nonresponse in Surveys}.
Wiley.

van Buuren, S. and Groothuis-Oudshoorn, K. (2011). mice: Multivariate imputation
by chained equations in R. \emph{Journal of Statistical Software}, 45(3), 1-67.
}
\examples{
if (requireNamespace("mice", quietly = TRUE) &&
    requireNamespace("mgcv", quietly = TRUE)) {
  set.seed(51)
  d <- expand.grid(N = seq(0, 200, by = 50), block = factor(1:5), rep = 1:2)
  d$yield <- 3 + 0.030 * d$N - 0.00009 * d$N^2 +
    as.numeric(d$block) * 0.3 + rnorm(nrow(d), 0, 0.3)
  d <- d[, c("N", "block", "yield")]
  d$yield[sample(nrow(d), 8)] <- NA

  # Example 1: the pooled curve, always printed beside the complete-case one.
  # m and B are small here for speed.
  im <- agri_np_impute(yield ~ N, d, block = block, m = 3, B = 49,
                       seed = 1, n = 40, k = 4)
  im

  # Example 2: how much the imputation is doing, point by point along the curve
  head(im$curve[, c("x", "complete_case", "pooled", "fmi")])

  # Example 3: with nothing missing the function refuses rather than adding
  # noise for no reason
  try(agri_np_impute(yield ~ N, d[!is.na(d$yield), ], block = block, m = 3))
}
}
