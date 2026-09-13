\name{agri_p}
\alias{agri_p}
\title{Extract the omnibus p-values of a fit}
\description{Reads the p-value of every tested effect without requiring the caller to know which backend produced the fit. Each backend names its own column: the car-style \code{Pr(>F)}, the \code{p-value} of MANOVA.RM, or the separated \code{parametric P(>F)} and \code{resampled P(>F)} of permuco. Generic report code that guesses the column name receives \code{NULL} instead of an error, which is how an empty table passes unnoticed inside a long document.}
\usage{
agri_p(x, which = c("primary", "parametric"))
}
\arguments{
  \item{x}{An \code{agri_rank_fit}, an \code{agri_ancova_fit}, or an omnibus data frame.}
  \item{which}{\code{"primary"} for the canonical \code{p_value} column, \code{"parametric"} for the parametric p-value of a permutation backend.}
}
\details{The canonical column \code{p_value} holds the resampled p-value when the engine resamples and the asymptotic p-value otherwise, because a permutation engine was chosen for its permutation distribution. \code{which = "parametric"} returns the parametric value that permuco reports beside it, which shows how far the permutation distribution moved the conclusion away from the F approximation. A backend that reports a single p-value answers both requests with that value and says so in a warning.}
\value{A data frame with columns \code{effect} and \code{p_value}.}
\seealso{\code{agri_rank}, \code{agri_table}, \code{agri_effects}}
\examples{
set.seed(1)
d <- data.frame(trat = factor(rep(c("T1", "T2", "T3", "T4"), each = 8)))
d$y <- 10 + ifelse(d$trat == "T4", 1.5, 0) + stats::rnorm(nrow(d))
dg <- agri_design(y ~ trat, data = d, design = "crd")
fit <- agri_rank(dg, method = "kruskal")
agri_p(fit)

if (requireNamespace("permuco", quietly = TRUE)) {
  fp <- agri_rank(dg, method = "permuco", B = 999, seed = 1)
  agri_p(fp)
  agri_p(fp, which = "parametric")
}
}
