# Standard extractors for regression fits ---------------------------------
#
# A fitted curve always has fitted values and residuals. Coefficients are a
# different matter: they exist only when the engine defines a finite parameter
# vector with an interpretation. Returning basis coefficients of a spline as if
# they were slopes would be misleading, so those engines are refused by name.

# Engines whose coefficients are agronomically interpretable.
.np_parametric_engines <- c("theil_sen", "siegel", "quantile")

#' @export
fitted.agri_np_reg_fit <- function(object, ...) {
  z <- as.numeric(object$fitted)
  names(z) <- rownames(object$data)
  z
}

#' @export
residuals.agri_np_reg_fit <- function(object, ...) {
  z <- as.numeric(object$residuals)
  names(z) <- rownames(object$data)
  z
}

#' @export
coef.agri_np_reg_fit <- function(object, ...) {
  if (!object$method %in% .np_parametric_engines)
    .agri_stop(sprintf("Method `%s` does not define interpretable regression coefficients. It estimates a curve, not a finite parameter vector. Use agri_np_predict(), agri_np_derivative() or agri_np_optimum() to describe the fitted response, and coef() only with %s.",
                       object$method, paste(.np_parametric_engines, collapse = ", ")))
  cf <- stats::coef(object$engine)
  if (is.matrix(cf)) cf <- cf[, 1L]
  cf
}

#' @export
confint.agri_np_reg_fit <- function(object, parm = NULL, level = 0.95,
                                    method = c("auto", "backend", "bootstrap"),
                                    B = 999L, seed = 1, ...) {
  method <- match.arg(method)
  cf <- stats::coef(object)          # refuses non-parametric engines
  out <- NULL
  if (method %in% c("auto", "backend")) {
    out <- tryCatch({
      ci <- stats::confint(object$engine, level = level)
      ci <- as.matrix(ci)
      data.frame(term = rownames(ci), estimate = as.numeric(cf),
                 lower = ci[, 1L], upper = ci[, 2L],
                 method = "backend", stringsAsFactors = FALSE)
    }, error = function(e) NULL, warning = function(w) NULL)
    if (is.null(out) && identical(method, "backend"))
      .agri_stop("The backend does not expose a confidence interval for this engine. Use `method = \"bootstrap\"`.")
  }
  if (is.null(out)) {
    bt <- agri_np_bootstrap(object, target = "coefficients", B = B, level = level,
                            seed = seed, keep_replicates = FALSE)
    out <- data.frame(term = bt$term, estimate = bt$estimate,
                      lower = bt$lower, upper = bt$upper,
                      method = "bootstrap", stringsAsFactors = FALSE)
  }
  if (!is.null(parm)) out <- out[out$term %in% parm, , drop = FALSE]
  rownames(out) <- NULL
  attr(out, "level") <- level
  out
}
