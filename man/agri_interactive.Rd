\name{agri_interactive}
\alias{agri_interactive}
\title{Convert an agriRank plot to Plotly}
\description{Wraps `plotly::ggplotly()` around an `agri_plot()` result.}
\usage{
agri_interactive(x, type = "data", ...)
}
\arguments{
  \item{x}{An agriRank design or fitted object as documented for the function.}
  \item{type}{Plot type.}
  \item{...}{Additional arguments passed to the selected backend or downstream method.}
}
\details{Intended for exploration and teaching; static ggplot remains the primary publication figure. The vignette suite documents the experimental-design logic, estimand, hypothesis, resampling structure, missing/unbalanced-data behavior, and backend-specific limitations in greater depth.}
\value{A Plotly htmlwidget.}
\references{
Pauly M, Brunner E, Konietschke F (2015), DOI: 10.1111/rssb.12073. Brunner E, Konietschke F, Pauly M, Puri ML (2017), DOI: 10.1111/rssb.12222. Konietschke F, Brunner E (2023), DOI: 10.32614/RJ-2023-029. See the package vignettes and `inst/references/agriRank-methods-verified.ris` for engine-specific verified references.
}
\examples{
# The examples build the widget and report its class. They deliberately do not
# print it: rendering an htmlwidget outside an interactive session can launch a
# headless browser, which is unavailable in many check and documentation
# environments. Print the object in an interactive session to see the graphic.

# Example 1: raw data
x <- simulate_agri("crd", seed = 51)
f <- np_crd(yield ~ treatment, x)
if (requireNamespace("plotly", quietly = TRUE)) {
  w1 <- agri_interactive(f, "data")
  class(w1)
}

# Example 2: relative effects
if (requireNamespace("plotly", quietly = TRUE)) {
  w2 <- agri_interactive(f, "effects")
  class(w2)
}

# Example 3: factorial interaction
xf <- simulate_agri("factorial", seed = 52)
d <- agri_design(yield ~ A * B, xf, "factorial")
if (requireNamespace("plotly", quietly = TRUE)) {
  w3 <- agri_interactive(d, "interaction")
  class(w3)
}
}
\seealso{\code{agri_design}, \code{agri_rank}, \code{agri_effects}, \code{agri_report}}
