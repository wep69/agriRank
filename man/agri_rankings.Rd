\name{agri_rankings}
\alias{agri_rankings}
\alias{print.agri_rankings}
\alias{plot.agri_rankings}
\title{Within-block rankings and the on-farm ranking bridge}
\description{
Builds the within-block rankings that every rank-based test in the package
already computes internally, summarises them by item, and reports the pairwise
record of which item was placed above which. Accepts a measured blocked
experiment or rankings supplied directly, as from an on-farm or tricot trial.
}
\usage{
agri_rankings(formula, data, block,
              direction = c("higher_is_better", "lower_is_better"),
              ranked = FALSE, worth = TRUE)
}
\arguments{
\item{formula}{\code{response ~ item}, where \code{response} is the measurement
or, with \code{ranked = TRUE}, the rank already assigned within the block.}

\item{data}{Data frame in long format, one row per item per block.}

\item{block}{The block, farm, plot or judge inside which the ordering was made.}

\item{direction}{\code{"higher_is_better"} when a larger measurement is a better
result, \code{"lower_is_better"} otherwise. Ignored when \code{ranked = TRUE}.}

\item{ranked}{The response is already a rank inside its block, with 1 the best.}

\item{worth}{Fit a Plackett-Luce model as a model-based companion when the
\pkg{PlackettLuce} package is installed.}
}
\details{
Two kinds of agronomic experiment produce rankings, and they meet here.

The first is the ordinary blocked trial. Every rank-based test in this package
already works on within-block ranks: Friedman and the Conover comparisons
convert the measured response into ranks inside each block and never look at the
measurements again. The ranks are therefore not a summary of the analysis, they
are the analysis, and it is worth being able to see them.

The second is the on-farm or tricot trial, in which each farmer receives a small
subset of the varieties and returns an order rather than a measurement. Nothing
was weighed, so there is no response to analyse; the order is the datum.

\strong{Completeness decides which methods are admissible.} A classical blocked
trial is complete: every item appears in every block, so rank sums are
comparable and the Friedman-type machinery of \code{\link{agri_rank}} and
\code{\link{agri_conover}} applies. An on-farm trial is usually incomplete: each
farmer ranks three varieties out of many. Rank sums are then not comparable,
because an item that happened to appear in favourable blocks collects flattering
ranks for a reason that has nothing to do with the item. This function detects
incompleteness, reports it, withholds \code{rank_sum} and warns about
\code{mean_rank}. The pairwise record survives, because each comparison is made
inside one block and is therefore immune to differences between blocks.

\code{worth = TRUE} adds Plackett-Luce worth estimates when that package is
available. This is reported separately and labelled, because it is a likelihood
model for rankings rather than a distribution-free summary: it assumes the
rankings arise from one common worth per item, which is what allows it to
combine incomplete rankings onto a single scale. Where the distribution-free
summary and the worth estimates disagree, the assumption is doing the work.
}
\value{
An object of class \code{agri_rankings}, a list with \code{summary},
\code{pairwise}, \code{rankings}, \code{worth} and \code{completeness}.
}
\references{
Turner, H. L., van Etten, J., Firth, D. and Kosmidis, I. (2020). Modelling
rankings in R: the PlackettLuce package. \emph{Computational Statistics}, 35,
1027-1057. \doi{10.1007/s00180-020-00959-3}

van Etten, J., Beza, E., Calderer, L. et al. (2019). First experiences with a
novel farmer citizen science approach. \emph{Experimental Agriculture}, 55(S1),
275-296. \doi{10.1017/S0014479716000739}
}
\seealso{
\code{\link{agri_conover}} and \code{\link{agri_cld}} for the formal comparison
of a complete blocked trial, \code{\link{agri_rank}} for the omnibus test.
}
\examples{
# Example 1. A complete blocked trial. The ranks shown here are the same ones
# the Friedman and Conover machinery uses internally.
set.seed(5)
d <- expand.grid(variety = factor(paste0("V", 1:5)),
                 farm = factor(paste0("F", 1:8)))
d$yield <- 3 + c(V1 = 0, V2 = 0.6, V3 = 1.1, V4 = 0.3, V5 = 1.4)[d$variety] +
  as.numeric(d$farm) * 0.2 + rnorm(nrow(d), 0, 0.5)

r <- agri_rankings(yield ~ variety, d, block = farm)
r$summary
r$completeness

# Example 2. The pairwise record uses only the blocks containing both items,
# so it is immune to differences between farms.
head(r$pairwise, 4)

# Example 3. An incomplete on-farm trial, where each farmer ranked three
# varieties out of nine. Rank sums are withheld, because an item that appeared
# in favourable farms would collect flattering ranks for the wrong reason.
set.seed(9)
vars <- paste0("V", 1:9)
tri <- do.call(rbind, lapply(1:40, function(i) {
  pick <- sample(vars, 3)
  q <- c(V1 = 1, V2 = 2, V3 = 3, V4 = 1.5, V5 = 3.5,
         V6 = 2.2, V7 = 0.8, V8 = 2.8, V9 = 1.2)[pick] + rnorm(3, 0, 0.8)
  data.frame(farm = paste0("F", i), variety = pick, position = rank(-q),
             stringsAsFactors = FALSE)
}))
rt <- agri_rankings(position ~ variety, tri, block = farm, ranked = TRUE)
rt$completeness
rt$summary

# Example 4. Ranking without a block is refused, because it would compare
# items across blocks, which is what blocking exists to avoid.
res <- tryCatch(agri_rankings(yield ~ variety, d),
                error = function(e) conditionMessage(e))
cat(res, "\n")

# Example 5. The figures.
p <- plot(r, type = "pairwise")
class(p)
}
\keyword{nonparametric}
