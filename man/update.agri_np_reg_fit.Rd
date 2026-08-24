\name{update.agri_np_reg_fit}
\alias{update.agri_np_reg_fit}
\title{Refit a nonparametric regression changing only what is named}
\usage{
\method{update}{agri_np_reg_fit}(object, formula = NULL, ...)
}
\arguments{
  \item{object}{An \code{agri_np_reg_fit}.}
  \item{formula}{Optional replacement formula.}
  \item{...}{Arguments of \code{\link{agri_np_regression}} to change, for
    example \code{method}, \code{shape}, \code{k}, \code{span},
    \code{block_effect} or \code{gam_structure}. An argument that is not a
    formal of \code{agri_np_regression} is refused by name rather than silently
    ignored.}
}
\description{Refits the model with the arguments given in \code{...} replacing
the ones used originally, leaving everything else as it was.}
\details{Comparing two engines or trying a shape constraint otherwise means
retyping the whole call, which is where a predictor or a block quietly goes
missing between the two versions being compared.

The refit uses the data stored in the fit, that is, the data after the declared
\code{na_action} was applied. This is deliberate: it guarantees that the two
models are fitted to the same rows, which is the point of comparing them. If the
original data frame has since changed, refit from it explicitly rather than
through this method.

All the guards of \code{\link{agri_np_regression}} still apply. Asking for an
engine that cannot adjust for a declared block fails here exactly as it would in
a fresh call.}
\value{A new \code{agri_np_reg_fit}.}
\seealso{\code{\link{agri_np_regression}},
  \code{\link{agri_np_compare}} for comparing engines by predictive error.}
\examples{
data(agri_dose)
f1 <- agri_np_regression(yield ~ dose, agri_dose, method = "smoothing_spline")

# Example 1: change the engine, keep everything else
f2 <- update(f1, method = "loess")
c(f1$method, f2$method)

# Example 2: change the smoothing parameter only
f3 <- update(f1, method = "gam", k = 8)
f3$settings$k

# Example 3: impose a shape the agronomy guarantees, and compare
if (requireNamespace("scam", quietly = TRUE)) {
  f4 <- update(f1, method = "scam", shape = "increasing_concave")
  c(free = f1$metrics$RMSE, constrained = f4$metrics$RMSE)
  # The constrained fit cannot beat the free one on RMSE. It buys precision
  # where the constraint is true, not a better fit to these data.
}

# Example 4: an argument that does not exist is named rather than ignored
try(update(f1, smoothing = 3))
}
