# Fixed and shrunk block effects -------------------------------------------
#
# A declared block can enter a regression in two ways, and the choice is not
# cosmetic.
#
# Fixed: one free effect per block. Nothing is assumed about how blocks relate
# to each other, which is why this is the classical choice for a designed
# experiment. Its limitation is that the effects exist only for the blocks that
# were observed, so the model has nothing to say about a new field or a new
# year.
#
# Shrunk: a penalized term whose block effects are pulled towards their common
# mean by an amount the data choose. A block that happens to look extreme is
# pulled back, because part of its apparent difference is noise. This is what
# makes prediction into an unobserved block possible at all, and it is the
# model-based counterpart of agri_np_conformal(scope = "new_block").
#
# The comparison below makes the trade visible: how much each block moves, and
# therefore how much of the between-block spread the data attribute to noise.

.block_effect_vector <- function(object) {
  b <- object$block
  if (is.null(b)) return(NULL)
  d <- object$data
  levs <- levels(as.factor(d[[b]]))
  # Predict at one common covariate setting, varying only the block. The
  # differences are then the block contribution on the response scale, for any
  # engine, without reading coefficients whose meaning changes with the basis.
  base <- .np_prediction_grid(object, n = 1L)
  g <- base[rep(1L, length(levs)), , drop = FALSE]
  g[[b]] <- factor(levs, levels = levs)
  p <- tryCatch(agri_np_predict(object, g), error = function(e) NULL)
  if (is.null(p)) return(NULL)
  if (is.matrix(p)) p <- p[, 1L]
  p <- as.numeric(p)
  stats::setNames(p - mean(p), levs)
}

#' Fixed and shrunk block effects side by side
#'
#' @description
#' Reports the effect of every declared block, as estimated by the fitted model
#' and by its counterpart with the other treatment of the block, so that the
#' amount of shrinkage is visible rather than implicit.
#'
#' @param object An `agri_np_reg_fit` fitted with a `block`.
#' @param compare Refit with the other `block_effect` and report both columns.
#'   Set to `FALSE` to report only the fitted model.
#' @details
#' Effects are computed on the response scale by predicting at one common
#' covariate setting and varying only the block, then centring. That works for
#' every engine and avoids reading basis coefficients whose meaning depends on
#' the smoother.
#'
#' `raw` is the plain observed block mean minus the grand mean, which uses no
#' model at all. `shrinkage` is the proportional reduction from the fixed
#' estimate towards zero. A large shrinkage says the data attribute much of the
#' apparent between-block spread to noise; a shrinkage near zero says the blocks
#' really do differ and little is being borrowed.
#'
#' Shrinking is a working assumption about how blocks vary, not a parametric
#' claim about the response curve, which stays nonparametric either way.
#' Inference for the curve should still come from the package's resampling and
#' conformal tools.
#' @return A data frame of class `agri_np_block_effects`.
#' @seealso [agri_np_regression()] for the `block_effect` argument,
#'   [agri_np_conformal()] for the assumption-free route to a new block.
#' @export
agri_np_block_effects <- function(object, compare = TRUE) {
  if (!inherits(object, "agri_np_reg_fit"))
    .agri_stop("`object` must be an agri_np_reg_fit.")
  b <- object$block
  if (is.null(b))
    .agri_stop("This fit declares no block, so there are no block effects to ",
               "report. Refit with `block =` naming the blocking variable.")

  d <- object$data
  fac <- as.factor(d[[b]])
  levs <- levels(fac)
  y <- d[[object$response]]
  raw <- vapply(levs, function(l) mean(y[fac == l], na.rm = TRUE), numeric(1)) -
    mean(y, na.rm = TRUE)

  this <- .block_effect_vector(object)
  if (is.null(this))
    .agri_stop("The engine could not be evaluated block by block, so its block ",
               "effects cannot be reported.")
  eff <- object$block_effect %||% object$settings$block_effect %||% "fixed"

  other <- NULL
  if (isTRUE(compare)) {
    alt <- if (identical(eff, "fixed")) "shrunk" else "fixed"
    o2 <- tryCatch(
      agri_np_regression(object$formula, object$data, method = object$method,
                         tau = object$tau, family = object$family,
                         shape = object$shape, block = b, block_effect = alt,
                         na_action = "fail", span = object$settings$span,
                         degree = object$settings$degree, k = object$settings$k,
                         gam_structure = object$settings$gam_structure %||% "additive",
                         kernel_regtype = object$settings$kernel_regtype %||% "ll",
                         bwmethod = object$settings$bwmethod),
      error = function(e) NULL)
    if (!is.null(o2)) other <- stats::setNames(.block_effect_vector(o2), levs)
  }

  fixedv <- if (identical(eff, "fixed")) this else other
  shrunkv <- if (identical(eff, "fixed")) other else this

  out <- data.frame(
    block = levs,
    n = as.integer(table(fac)[levs]),
    raw = unname(raw),
    row.names = NULL, stringsAsFactors = FALSE
  )
  if (!is.null(fixedv)) out$fixed <- unname(fixedv)
  if (!is.null(shrunkv)) out$shrunk <- unname(shrunkv)
  if (!is.null(fixedv) && !is.null(shrunkv)) {
    dn <- unname(fixedv)
    out$shrinkage <- ifelse(abs(dn) > 0, 1 - unname(shrunkv) / dn, NA_real_)
  }
  structure(out, fitted_as = eff, block = b, response = object$response,
            class = c("agri_np_block_effects", "data.frame"))
}

#' @export
print.agri_np_block_effects <- function(x, ...) {
  cat("Block effects on ", attr(x, "response"),
      ", block = `", attr(x, "block"), "`\n", sep = "")
  cat("  Model was fitted with block_effect = \"", attr(x, "fitted_as"), "\"\n\n",
      sep = "")
  print(as.data.frame(x), row.names = FALSE, digits = 4)
  if (!is.null(x$shrinkage)) {
    m <- mean(x$shrinkage, na.rm = TRUE)
    cat("\nMean shrinkage: ", format(round(100 * m, 1)), "%. ", sep = "")
    cat(if (m > 0.5)
          "Most of the apparent spread between blocks is treated as noise."
        else if (m > 0.1)
          "The blocks differ, and part of the difference is borrowed back."
        else
          "The blocks genuinely differ; almost nothing is borrowed.", "\n")
  }
  cat("\nFixed effects exist only for the blocks that were observed. Shrunk\n",
      "effects allow a prediction for a block that was not, at the price of a\n",
      "working assumption about how blocks vary.\n", sep = "")
  invisible(x)
}

#' @export
plot.agri_np_block_effects <- function(x, ...) {
  .require_pkg("ggplot2", "regression graphics")
  if (is.null(x$fixed) || is.null(x$shrunk))
    .agri_stop("Both columns are needed for this figure. Rebuild with ",
               "`agri_np_block_effects(object, compare = TRUE)`.")
  d <- data.frame(g = factor(x$block, levels = x$block[order(x$fixed)]),
                  x = x$fixed, xend = x$shrunk)
  long <- rbind(
    data.frame(g = d$g, x = d$x, state = "fixed"),
    data.frame(g = d$g, x = d$xend, state = "shrunk"))
  long$state <- factor(long$state, levels = c("fixed", "shrunk"))
  ggplot2::ggplot(d, ggplot2::aes(y = g)) +
    ggplot2::geom_vline(xintercept = 0, linetype = "dashed", colour = "grey60") +
    ggplot2::geom_segment(ggplot2::aes(x = x, xend = xend, y = g, yend = g),
                          colour = "grey55", linewidth = 0.8) +
    ggplot2::geom_point(data = long, ggplot2::aes(x = x, y = g, shape = state),
                        size = 2.8, inherit.aes = FALSE) +
    ggplot2::scale_shape_manual(values = c(fixed = 16, shrunk = 21)) +
    ggplot2::labs(x = paste("Effect on", attr(x, "response")),
                  y = attr(x, "block"), shape = NULL,
                  title = "How far each block is pulled towards the common mean",
                  caption = "Filled: one free effect per block. Open: penalized, partly borrowed from the others.") +
    .agri_theme_or_minimal()
}
