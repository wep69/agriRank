\name{agri_np_longitudinal}
\alias{agri_np_longitudinal}
\alias{print.agri_np_longitudinal_fit}
\title{Regression along a gradient measured repeatedly on the same units}
\usage{
agri_np_longitudinal(formula, data, subject, time,
                     time_effect = c("smooth", "varying"), k = 10L, ...)
}
\arguments{
\item{formula}{Regression formula, response on the left and the gradient plus
any other predictors on the right. Do not put the time variable here; give it to
\code{time}.}
\item{data}{Data frame in long form, one row per unit and occasion.}
\item{subject}{The unit measured repeatedly, as a name or a string: the plot,
the pot, the animal.}
\item{time}{The occasion, as a name or a string.}
\item{time_effect}{How time enters. \code{"smooth"} gives it its own smooth, so
the level of the response drifts over time but its shape does not.
\code{"varying"} lets the shape of the gradient response differ between
occasions, which is the interesting case and needs time to be a factor with
enough observations per level.}
\item{k}{Basis dimension for the smooths.}
\item{...}{Passed to \code{\link{agri_np_regression}}.}
}
\description{Fits a response curve when each experimental unit is measured more
than once, entering the unit as a penalised random effect and making it the
resampling cluster for everything downstream.}
\details{
A trial that measures the same plots at four dates has four rows per plot, and
analysing them as four independent observations inflates the apparent
replication fourfold. That is the error the repeated-measures side of the
package exists to prevent, and until 0.14.0 the regression side had no
equivalent.

The returned object is an ordinary \code{agri_np_reg_fit} whose \code{block} is
the subject. That is not a trick: the subject \strong{is} the unit of
resampling, so every tool in the module then does the right thing without
knowing anything about repeated measurement. \code{\link{agri_np_bootstrap}}
resamples whole subjects, \code{\link{agri_np_conformal}} splits by subject, and
\code{\link{agri_np_compare}} with \code{cv_scope = "new_block"} holds out whole
subjects, which is the honest question: how well is a plot predicted that was
never measured.

\code{block_effect = "shrunk"} is used, so subject effects are penalised towards
their common mean. With fixed subject effects a model with many plots and few
occasions each would spend most of its degrees of freedom on nuisance.

\strong{This is not a GAMM with a modelled within-subject correlation.} Nothing
here estimates an autocorrelation over time. The dependence is handled by
resampling whole subjects, which assumes nothing about its form and, in
exchange, cannot recover the efficiency that a correct correlation model would.
If the occasions are many and closely spaced, say a weekly series over a season,
a model that represents the correlation is the better tool and this one will be
conservative.
}
\value{An \code{agri_np_reg_fit} with an extra \code{$longitudinal} component
describing the structure.}
\seealso{\code{\link{agri_repeated}} for the rank-based repeated-measures side,
\code{\link{agri_np_regression}}, \code{\link{agri_np_conformal}}.}
\examples{
if (requireNamespace("mgcv", quietly = TRUE)) {
  set.seed(31)
  d <- expand.grid(N = seq(0, 200, 50), plot = factor(1:12), time = factor(1:3))
  d$yield <- 3 + 0.03 * d$N - 0.00009 * d$N^2 +
    as.numeric(d$plot) * 0.15 + as.numeric(d$time) * 0.4 + rnorm(nrow(d), 0, 0.25)

  # Example 1: the level drifts between occasions, the shape does not
  fit <- agri_np_longitudinal(yield ~ N, d, subject = plot, time = time, k = 4)
  fit

  # Example 2: every interval downstream now resamples whole plots, without
  # being told anything about repeated measurement
  agri_np_bootstrap(fit, B = 49, n = 25, seed = 1)

  # Example 3: the shape itself allowed to differ between occasions, which is
  # the question a multi-harvest trial usually asks
  agri_np_longitudinal(yield ~ N, d, subject = plot, time = time,
                       time_effect = "varying", k = 4)

  # Example 4: data that are not repeated measurements are refused rather than
  # given a random effect with one observation per level
  d1 <- d[!duplicated(d$plot), ]
  try(agri_np_longitudinal(yield ~ N, d1, subject = plot, time = time))
}
}
