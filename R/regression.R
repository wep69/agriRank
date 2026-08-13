# Nonparametric and semiparametric regression -----------------------------

.np_method_choices <- c(
  "auto", "theil_sen", "siegel", "quantile", "loess",
  "smoothing_spline", "kernel", "gam", "scam", "cobs", "isotonic",
  "discrete_kernel", "unimodal_isotonic", "umbrella", "integer_grid"
)


.integerish <- function(x, tol = 1e-8) {
  is.numeric(x) && all(is.na(x) | (is.finite(x) & abs(x - round(x)) <= tol))
}

.integer_support_values <- function(data, predictor,
                                    mode = c("observed_integer", "integer_range", "custom_integer"),
                                    integer_range = NULL, integer_values = NULL) {
  mode <- match.arg(mode)
  x <- data[[predictor]]
  if (!is.numeric(x) || !.integerish(x))
    .agri_stop("Integer-support regression requires a numeric predictor containing only integer values.")
  observed <- sort(unique(as.integer(round(x[is.finite(x)]))))
  if (!length(observed)) .agri_stop("No finite integer predictor values are available.")
  support <- switch(mode,
    observed_integer = observed,
    integer_range = {
      rr <- integer_range %||% range(observed)
      if (length(rr) != 2L || !all(is.finite(rr)) || !.integerish(as.numeric(rr)))
        .agri_stop("`integer_range` must contain two finite integer bounds.")
      rr <- sort(as.integer(round(rr)))
      seq.int(rr[1L], rr[2L])
    },
    custom_integer = {
      if (is.null(integer_values) || !length(integer_values))
        .agri_stop("`integer_values` must be supplied when predictor_support = 'custom_integer'.")
      if (!is.numeric(integer_values) || !.integerish(integer_values))
        .agri_stop("`integer_values` must contain only finite integer values.")
      sort(unique(as.integer(round(integer_values))))
    }
  )
  if (!all(observed %in% support))
    .agri_stop("The declared integer support does not contain every observed predictor value.")
  list(values = support, observed = observed, mode = mode)
}

.integer_prediction_grid <- function(object, fixed = list(), support = NULL) {
  if (is.null(object$integer_support) || !length(object$integer_support))
    .agri_stop("The fitted object does not define an integer decision support.")
  predictor <- object$integer_predictor %||% object$primary_predictor
  vals <- support %||% object$integer_support
  if (!all(vals %in% object$integer_support))
    .agri_stop("Requested prediction values must belong to the fitted integer support.")
  vars <- unique(c(object$predictors, object$block %||% character()))
  n <- length(vals)
  out <- as.data.frame(setNames(lapply(vars, function(v) rep(.np_reference_value(object$data[[v]]), n)), vars),
                       stringsAsFactors = FALSE)
  for (v in vars) {
    if (is.factor(object$data[[v]])) out[[v]] <- factor(out[[v]], levels = levels(object$data[[v]]))
  }
  out[[predictor]] <- as.integer(vals)
  if (length(fixed)) {
    bad <- setdiff(names(fixed), names(out))
    if (length(bad)) .agri_stop("Unknown fixed prediction variable(s): ", paste(bad, collapse = ", "))
    for (v in names(fixed)) {
      val <- fixed[[v]]
      if (is.factor(object$data[[v]])) out[[v]] <- factor(rep(val, n), levels = levels(object$data[[v]]))
      else out[[v]] <- rep(val, n)
    }
  }
  out
}

.integer_validate_newdata <- function(object, newdata) {
  if (is.null(object$integer_support) || !length(object$integer_support)) return(newdata)
  predictor <- object$integer_predictor %||% object$primary_predictor
  if (!predictor %in% names(newdata))
    .agri_stop("New data must contain the integer predictor `", predictor, "`.")
  x <- newdata[[predictor]]
  if (!is.numeric(x) || !.integerish(x))
    .agri_stop("Predictions for an integer-support fit are restricted to integer predictor values.")
  xi <- as.integer(round(x))
  bad <- sort(unique(xi[!xi %in% object$integer_support]))
  if (length(bad))
    .agri_stop("Prediction requested outside the admissible integer support: ", paste(bad, collapse = ", "), ".")
  newdata[[predictor]] <- xi
  newdata
}

.integer_engine_newdata <- function(object, newdata) {
  z <- .integer_validate_newdata(object, newdata)
  if (identical(object$method, "discrete_kernel")) {
    predictor <- object$integer_predictor %||% object$primary_predictor
    z[[predictor]] <- ordered(as.character(z[[predictor]]),
                              levels = as.character(object$integer_support))
  }
  z
}

.aggregate_integer_response <- function(data, predictor, response, weights = NULL) {
  x <- as.integer(round(data[[predictor]]))
  y <- data[[response]]
  w <- weights %||% rep(1, length(y))
  sp <- split(seq_along(x), x)
  xx <- as.integer(names(sp))
  yy <- vapply(sp, function(ii) stats::weighted.mean(y[ii], w[ii]), numeric(1))
  ww <- vapply(sp, function(ii) sum(w[ii]), numeric(1))
  ord <- order(xx)
  data.frame(x = xx[ord], y = yy[ord], w = ww[ord], row.names = NULL)
}

.np_umbrella_formula <- function(formula, primary, block = NULL) {
  response <- .response_names(formula)[1L]
  predictors <- setdiff(.predictor_names(formula), primary)
  parts <- c(sprintf("umbrella(%s)", primary), predictors, block %||% character())
  stats::as.formula(paste(response, "~", paste(unique(parts), collapse = " + ")),
                    env = asNamespace("cgam"))
}

.np_simple_formula <- function(formula) {
  tl <- .term_labels(formula)
  length(tl) > 0L && all(grepl("^[.A-Za-z][.A-Za-z0-9_]*$", tl))
}

.np_append_terms <- function(formula, terms) {
  terms <- unique(terms[nzchar(terms)])
  if (!length(terms)) return(formula)
  lhs <- paste(deparse(formula[[2L]]), collapse = "")
  rhs0 <- paste(deparse(formula[[3L]]), collapse = "")
  existing <- all.vars(formula[[3L]])
  add <- setdiff(terms, existing)
  if (!length(add)) return(formula)
  stats::as.formula(paste(lhs, "~", paste(c(rhs0, add), collapse = " + ")), env = environment(formula))
}

.np_auto_gam_formula <- function(formula, data, block = NULL, k = 10L, structure = c("additive", "tensor")) {
  structure <- match.arg(structure)
  if (!.np_simple_formula(formula)) return(.np_append_terms(formula, block %||% character()))
  response <- .response_names(formula)[1L]
  predictors <- .predictor_names(formula)
  nums <- predictors[vapply(data[predictors], is.numeric, logical(1))]
  cats <- setdiff(predictors, nums)
  if (identical(structure, "tensor") && length(nums) >= 2L) {
    kt <- max(3L, min(as.integer(k), floor(sqrt(max(9, nrow(data) / 2)))))
    kk <- paste(rep(kt, 2L), collapse = ",")
    parts <- c(sprintf("te(%s, k=c(%s))", paste(nums[1:2], collapse = ","), kk),
               if (length(nums) > 2L) vapply(nums[-(1:2)], function(v) sprintf("s(%s, k=%d)", v, as.integer(k)), character(1)) else character(),
               cats)
  } else {
    # The thin-plate basis dimension cannot exceed the number of unique
    # covariate values, which is a real constraint for designed experiments
    # with few quantitative levels.
    parts <- vapply(predictors, function(v) {
      if (!is.numeric(data[[v]])) return(v)
      kv <- min(as.integer(k), length(unique(data[[v]][is.finite(data[[v]])])) - 1L)
      if (kv < 3L) return(v)
      sprintf("s(%s, k=%d)", v, kv)
    }, character(1))
  }
  parts <- unique(c(parts, block %||% character()))
  stats::as.formula(paste(response, "~", paste(parts, collapse = " + ")), env = environment(formula))
}

.np_scam_basis <- function(shape) {
  switch(shape,
    increasing = "mpi",
    decreasing = "mpd",
    convex = "cx",
    concave = "cv",
    increasing_convex = "micx",
    increasing_concave = "micv",
    decreasing_convex = "mdcx",
    decreasing_concave = "mdcv",
    .agri_stop("Unsupported SCAM shape constraint: ", shape)
  )
}

.np_scam_formula <- function(formula, data, primary, shape, block = NULL, k = 10L) {
  if (identical(shape, "none")) .agri_stop("`method = 'scam'` requires an explicit shape constraint.")
  response <- .response_names(formula)[1L]
  predictors <- setdiff(.predictor_names(formula), primary)
  bs <- .np_scam_basis(shape)
  smooth <- sprintf("s(%s, bs='%s', k=%d)", primary, bs, as.integer(k))
  other <- vapply(predictors, function(v) {
    if (is.numeric(data[[v]])) sprintf("s(%s, k=%d)", v, as.integer(k)) else v
  }, character(1))
  parts <- unique(c(smooth, other, block %||% character()))
  stats::as.formula(paste(response, "~", paste(parts, collapse = " + ")), env = environment(formula))
}

.np_cobs_constraint <- function(shape) {
  switch(shape,
    none = "none",
    increasing = "increase",
    decreasing = "decrease",
    convex = "convex",
    concave = "concave",
    .agri_stop("COBS currently supports shape = none, increasing, decreasing, convex, or concave in agriRank.")
  )
}

.np_reference_value <- function(x) {
  if (is.numeric(x)) stats::median(x, na.rm = TRUE)
  else if (is.factor(x)) levels(x)[1L]
  else if (is.logical(x)) FALSE
  else {
    tab <- sort(table(x), decreasing = TRUE)
    if (!length(tab)) NA else names(tab)[1L]
  }
}

.np_prediction_grid <- function(object, predictor = NULL, n = 200L, fixed = list(), range = NULL) {
  if (!is.null(object$integer_support) && length(object$integer_support)) {
    predictor <- predictor %||% object$integer_predictor %||% object$primary_predictor
    if (!is.null(range)) {
      if (length(range) != 2L || !all(is.finite(range))) .agri_stop("`range` must contain two finite limits.")
      keep <- object$integer_support >= min(range) & object$integer_support <= max(range)
      vals <- object$integer_support[keep]
      if (!length(vals)) .agri_stop("No admissible integer values fall within the requested range.")
      return(.integer_prediction_grid(object, fixed = fixed, support = vals))
    }
    return(.integer_prediction_grid(object, fixed = fixed))
  }
  dat <- object$data
  numeric_predictors <- object$numeric_predictors
  predictor <- predictor %||% object$primary_predictor %||% numeric_predictors[1L]
  if (is.null(predictor) || !predictor %in% names(dat) || !is.numeric(dat[[predictor]])) {
    .agri_stop("A numeric focal predictor is required to build a prediction grid.")
  }
  xr <- range %||% base::range(dat[[predictor]], na.rm = TRUE)
  if (length(xr) != 2L || !all(is.finite(xr))) .agri_stop("Cannot determine a finite predictor range.")
  vars <- unique(c(object$predictors, object$block %||% character()))
  out <- as.data.frame(setNames(lapply(vars, function(v) rep(.np_reference_value(dat[[v]]), n)), vars), stringsAsFactors = FALSE)
  for (v in vars) {
    if (is.factor(dat[[v]])) out[[v]] <- factor(out[[v]], levels = levels(dat[[v]]))
  }
  out[[predictor]] <- seq(xr[1L], xr[2L], length.out = n)
  if (length(fixed)) {
    bad <- setdiff(names(fixed), names(out))
    if (length(bad)) .agri_stop("Unknown fixed prediction variable(s): ", paste(bad, collapse = ", "))
    for (v in names(fixed)) {
      val <- fixed[[v]]
      if (is.factor(dat[[v]])) out[[v]] <- factor(rep(val, n), levels = levels(dat[[v]]))
      else out[[v]] <- rep(val, n)
    }
  }
  out
}

.np_metrics <- function(observed, predicted) {
  ok <- is.finite(observed) & is.finite(predicted)
  if (!any(ok)) return(data.frame(n = 0L, RMSE = NA_real_, MAE = NA_real_, MedAE = NA_real_, bias = NA_real_, Spearman = NA_real_))
  y <- observed[ok]; p <- predicted[ok]; e <- y - p
  data.frame(
    n = length(y),
    RMSE = sqrt(mean(e^2)),
    MAE = mean(abs(e)),
    MedAE = stats::median(abs(e)),
    bias = mean(e),
    Spearman = suppressWarnings(stats::cor(y, p, method = "spearman")),
    row.names = NULL
  )
}

.np_engine_predict <- function(object, newdata, se.fit = FALSE, level = 0.95) {
  method <- object$method
  eng <- object$engine
  primary <- object$primary_predictor
  if (method %in% c("theil_sen", "siegel", "quantile", "loess")) {
    z <- stats::predict(eng, newdata = newdata)
    if (is.matrix(z) && ncol(z) > 1L) return(z)
    return(as.numeric(z))
  }
  if (method == "smoothing_spline") {
    return(as.numeric(stats::predict(eng, x = newdata[[primary]])$y))
  }
  if (method == "kernel") {
    return(as.numeric(stats::predict(eng, newdata = newdata)))
  }
  if (method == "discrete_kernel") {
    nd <- .integer_engine_newdata(object, newdata)
    return(as.numeric(stats::predict(eng, newdata = nd)))
  }
  if (method == "unimodal_isotonic") {
    predictor <- object$integer_predictor %||% primary
    xx <- newdata[[predictor]]
    return(as.numeric(stats::approx(eng$x, eng$y, xout = xx, method = "constant",
                                    f = 0, rule = 2, ties = "ordered")$y))
  }
  if (method == "umbrella") {
    # cgam renamed the prediction data argument from `newData` to `newdata`;
    # dispatch on whichever formal the installed version exposes.
    cgam_int <- if (se.fit) "confidence" else "none"
    z <- tryCatch(
      stats::predict(eng, newdata = newdata, interval = cgam_int, level = level),
      error = function(e)
        stats::predict(eng, newData = newdata, interval = cgam_int, level = level)
    )
    if (is.list(z) && !is.null(z$fit)) {
      if (!se.fit) return(as.numeric(z$fit))
      return(data.frame(fit = as.numeric(z$fit),
                        lower = as.numeric(z$lower),
                        upper = as.numeric(z$upper)))
    }
    return(as.numeric(z))
  }
  if (method == "integer_grid") {
    return(.np_engine_predict(object$base_fit, newdata, se.fit = se.fit, level = level))
  }
  if (method %in% c("gam", "scam")) {
    if (!se.fit) return(as.numeric(stats::predict(eng, newdata = newdata, type = "response")))
    pp <- stats::predict(eng, newdata = newdata, type = "link", se.fit = TRUE)
    crit <- stats::qnorm(1 - (1 - level) / 2)
    eta <- as.numeric(pp$fit); se <- as.numeric(pp$se.fit)
    fam <- object$family
    inv <- fam$linkinv
    data.frame(
      fit = inv(eta),
      lower = inv(eta - crit * se),
      upper = inv(eta + crit * se)
    )
  } else if (method == "cobs") {
    z <- stats::predict(eng, z = newdata[[primary]], interval = if (se.fit) "confidence" else "none", level = level)
    if (is.matrix(z)) {
      if (!se.fit) return(as.numeric(z[, if ("fit" %in% colnames(z)) "fit" else 2L]))
      cn <- colnames(z)
      fit_col <- if ("fit" %in% cn) "fit" else cn[2L]
      lo_col <- grep("ci.lo|lower", cn, value = TRUE)[1L]
      hi_col <- grep("ci.up|upper", cn, value = TRUE)[1L]
      return(data.frame(fit = as.numeric(z[, fit_col]), lower = as.numeric(z[, lo_col]), upper = as.numeric(z[, hi_col])))
    }
    as.numeric(z)
  } else if (method == "isotonic") {
    as.numeric(stats::approx(eng$x, eng$yf, xout = newdata[[primary]], rule = 2, ties = "ordered")$y * object$isotonic_sign)
  } else .agri_stop("Prediction is not implemented for method `", method, "`.")
}

#' Fit nonparametric, rank-robust and semiparametric regression models
#'
#' @description
#' Fits a unified regression workflow for agronomic continuous gradients such as
#' dose, salinity, temperature, time, soil properties, or environmental indices.
#' Strictly nonparametric engines (LOESS, smoothing splines, kernel regression,
#' isotonic regression and constrained quantile splines) are separated from
#' rank-robust or semiparametric companions (Theil-Sen/Siegel, quantile
#' regression, GAM and SCAM). The selected engine is always retained in the
#' returned object.
#'
#' @param formula Regression formula or an `agri_design` object with one response.
#' @param data Data frame. May be omitted when `formula` is an `agri_design` object.
#' @param method Regression engine. `auto` uses only structural information,
#'   never response p-values, to select an admissible method.
#' @param tau Quantile for quantile or COBS regression.
#' @param family Family for GAM/SCAM.
#' @param shape Optional shape constraint.
#' @param block Optional agronomic block variable. It is retained as an
#'   adjustment factor for engines that support multivariable adjustment.
#' @param weights Optional numeric observation weights.
#' @param na_action Missing-data handling for response, modeled predictors, block, and weights. The default `fail` prevents silent row deletion; `complete` explicitly uses complete rows and records the omission count.
#' @param span LOESS span.
#' @param degree LOESS or COBS polynomial degree where applicable.
#' @param k Basis dimension for GAM/SCAM automatic smooths.
#' @param gam_structure For automatically generated GAMs, use separate additive smooths or a tensor-product smooth for the first two numeric predictors.
#' @param kernel_regtype Local-linear (`ll`) or local-constant (`lc`) kernel regression for the `np` engine.
#' @param bwmethod Bandwidth-selection method passed to `np::npregbw()`.
#' @param predictor_support Decision support for integer-predictor methods. `observed_integer`
#'   permits only integer values actually evaluated; `integer_range` permits every
#'   integer in a declared or observed range; `custom_integer` uses `integer_values`.
#' @param integer_predictor Optional name of the integer-valued focal predictor.
#' @param integer_range Two integer bounds used with `predictor_support = "integer_range"`.
#' @param integer_values Explicit admissible values used with `predictor_support = "custom_integer"`.
#' @param integer_kernel Ordered-data kernel used by `method = "discrete_kernel"`.
#' @param integer_base_method Continuous/flexible backend fitted by `method = "integer_grid"`;
#'   all public predictions and decisions are subsequently restricted to the integer support.
#' @param ... Additional arguments passed to the selected backend.
#' @export
agri_np_regression <- function(formula, data = NULL,
                               method = c("auto", "theil_sen", "siegel", "quantile", "loess",
                                          "smoothing_spline", "kernel", "gam", "scam", "cobs", "isotonic",
                                          "discrete_kernel", "unimodal_isotonic", "umbrella", "integer_grid"),
                               tau = 0.5,
                               family = stats::gaussian(),
                               shape = c("none", "increasing", "decreasing", "convex", "concave",
                                         "increasing_convex", "increasing_concave",
                                         "decreasing_convex", "decreasing_concave"),
                               block = NULL, weights = NULL,
                               na_action = c("fail", "complete"),
                               span = 0.75, degree = 2L, k = 10L,
                               gam_structure = c("additive", "tensor"),
                               kernel_regtype = c("ll", "lc"),
                               bwmethod = "cv.aic",
                               predictor_support = c("continuous", "observed_integer", "integer_range", "custom_integer"),
                               integer_predictor = NULL,
                               integer_range = NULL,
                               integer_values = NULL,
                               integer_kernel = c("wangvanryzin", "liracine"),
                               integer_base_method = c("gam", "scam", "kernel", "quantile", "loess", "smoothing_spline", "cobs"),
                               ...) {
  design_object <- NULL
  design_block <- NULL
  design_quantitative <- NULL
  if (inherits(formula, "agri_design")) {
    design_object <- formula
    if (length(design_object$response) != 1L) .agri_stop("Regression from `agri_design` requires exactly one response.")
    data <- design_object$data
    formula <- design_object$formula
    design_block <- design_object$block
    design_quantitative <- design_object$quantitative
    if (design_object$design %in% c("repeated", "longitudinal") && length(design_object$subject))
      .agri_stop("Regression from a repeated/longitudinal agri_design is not yet routed automatically because subject dependence must be represented explicitly. Fit a subject-aware model outside this module or use the dedicated agriRank repeated-measures workflow until a validated GAMM adapter is added.")
  }
  if (!inherits(formula, "formula")) .agri_stop("`formula` must be a formula or agri_design object.")
  if (is.null(data)) .agri_stop("`data` is required unless an agri_design object is supplied.")
  if (!is.data.frame(data)) data <- as.data.frame(data)
  method <- match.arg(method)
  shape <- match.arg(shape)
  na_action <- match.arg(na_action)
  gam_structure <- match.arg(gam_structure)
  kernel_regtype <- match.arg(kernel_regtype)
  predictor_support <- match.arg(predictor_support)
  integer_kernel <- match.arg(integer_kernel)
  integer_base_method <- match.arg(integer_base_method)
  response <- .response_names(formula)
  if (length(response) != 1L) .agri_stop("Regression requires exactly one response variable.")
  response <- response[1L]
  predictors <- .predictor_names(formula)
  if (!length(predictors)) .agri_stop("At least one predictor is required.")
  bexpr <- substitute(block)
  .bval_ok <- TRUE
  bval <- tryCatch(block, error = function(e) {.bval_ok <<- FALSE; NULL})
  # A bare symbol that resolves to NULL (e.g. `block = block_nm` in internal
  # recursion) means "no block", and must not be captured as a variable name.
  block_nm <- if (identical(bexpr, quote(NULL)) || (.bval_ok && is.null(bval))) design_block
              else if (is.character(bval)) bval
              else .capture_names(bexpr, names(data))
  if (!length(block_nm)) block_nm <- NULL
  if (length(block_nm) > 1L) .agri_stop("The regression module currently accepts at most one agronomic block variable.")
  .check_vars(unique(c(response, predictors, block_nm)), data)
  dat <- data
  fit_vars <- unique(c(response, predictors, block_nm))
  cc <- stats::complete.cases(dat[, fit_vars, drop = FALSE])
  if (!is.null(weights)) {
    if (length(weights) != nrow(dat)) .agri_stop("`weights` must have one value per input row.")
    cc <- cc & is.finite(weights)
  }
  n_original <- nrow(dat)
  n_omitted <- sum(!cc)
  if (n_omitted > 0L) {
    if (identical(na_action, "fail"))
      .agri_stop(sprintf("Regression data contain %d incomplete/non-finite row(s) among the modeled response, predictors, block, or weights. Use `na_action = 'complete'` only when complete-row analysis is scientifically justified.", n_omitted))
    .agri_warn(sprintf("Regression is using %d complete row(s) and explicitly omitting %d row(s). This is not an imputation or missing-data model.", sum(cc), n_omitted))
    dat <- droplevels(dat[cc, , drop = FALSE])
    if (!is.null(weights)) weights <- weights[cc]
  }
  if (length(block_nm)) dat[[block_nm]] <- .safe_factor(dat[[block_nm]])
  numeric_predictors <- predictors[vapply(dat[predictors], is.numeric, logical(1))]
  dq <- intersect(design_quantitative %||% character(), numeric_predictors)
  if (!is.null(integer_predictor)) {
    integer_predictor <- as.character(integer_predictor)[1L]
    if (!integer_predictor %in% predictors) .agri_stop("`integer_predictor` must be one of the modeled predictors.")
    if (!is.numeric(dat[[integer_predictor]])) .agri_stop("`integer_predictor` must be numeric before integer-support encoding.")
    primary <- integer_predictor
  } else {
    primary <- if (length(dq)) dq[1L] else if (length(numeric_predictors)) numeric_predictors[1L] else NULL
  }
  fam <- if (is.function(family)) family() else family

  integer_methods <- c("discrete_kernel", "unimodal_isotonic", "umbrella", "integer_grid")
  integer_info <- NULL
  if (method %in% integer_methods) {
    if (is.null(primary)) .agri_stop("Integer-support regression requires a numeric focal predictor.")
    if (identical(predictor_support, "continuous")) predictor_support <- "observed_integer"
    integer_info <- .integer_support_values(dat, primary, mode = predictor_support,
                                            integer_range = integer_range,
                                            integer_values = integer_values)
  } else if (!identical(predictor_support, "continuous")) {
    if (is.null(primary)) .agri_stop("An integer decision support requires a numeric focal predictor.")
    integer_info <- .integer_support_values(dat, primary, mode = predictor_support,
                                            integer_range = integer_range,
                                            integer_values = integer_values)
  }

  if (identical(method, "auto")) {
    if (!identical(shape, "none")) {
      if (requireNamespace("scam", quietly = TRUE) && !is.null(primary)) method <- "scam"
      else if (length(numeric_predictors) == 1L && requireNamespace("cobs", quietly = TRUE) && shape %in% c("increasing","decreasing","convex","concave")) method <- "cobs"
      else if (length(numeric_predictors) == 1L && shape %in% c("increasing","decreasing")) method <- "isotonic"
      else .agri_stop("No installed automatic engine can honor the requested shape constraint.")
    } else if (!identical(fam$family, "gaussian")) {
      if (requireNamespace("mgcv", quietly = TRUE)) method <- "gam" else .agri_stop("A non-Gaussian automatic regression requires `mgcv`.")
    } else if (length(predictors) == 1L && length(numeric_predictors) == 1L && !length(block_nm)) {
      method <- "smoothing_spline"
    } else if (requireNamespace("mgcv", quietly = TRUE)) method <- "gam"
    else if (requireNamespace("np", quietly = TRUE)) method <- "kernel"
    else .agri_stop("Install `mgcv` or `np`, or select an explicit regression method.")
  }

  one_numeric <- length(predictors) == 1L && length(numeric_predictors) == 1L
  if (!identical(shape, "none") && !method %in% c("scam", "cobs", "isotonic", "integer_grid"))
    .agri_stop("A shape constraint is only implemented by SCAM, COBS, isotonic regression, integer-grid wrappers, or `method = 'auto'`. Do not declare a shape that the selected engine will ignore.")
  if (identical(method, "umbrella") && !identical(shape, "none"))
    .agri_stop("`method = 'umbrella'` already imposes an increase-then-decrease order; leave `shape = 'none'`.")
  if (identical(method, "isotonic") && identical(shape, "none"))
    .agri_stop("Isotonic regression requires an explicit scientific direction: `shape = 'increasing'` or `shape = 'decreasing'`.")
  if (!is.null(weights) && method %in% c("theil_sen", "siegel", "kernel", "isotonic", "discrete_kernel"))
    .agri_stop(sprintf("Observation weights are not implemented by the agriRank `%s` adapter and will not be silently ignored.", method))
  no_block_methods <- c("theil_sen", "siegel", "loess", "smoothing_spline", "cobs", "isotonic", "unimodal_isotonic")
  if (length(block_nm) && method %in% no_block_methods) {
    .agri_stop(sprintf("Method `%s` does not adjust for the declared block in agriRank. Use kernel, quantile, GAM or SCAM, or omit block only when scientifically justified.", method))
  }
  if (method %in% c("theil_sen", "siegel", "smoothing_spline", "cobs", "isotonic", "unimodal_isotonic") && !one_numeric) {
    .agri_stop(sprintf("Method `%s` currently requires exactly one numeric predictor.", method))
  }
  if (method %in% integer_methods && !.integerish(dat[[primary]]))
    .agri_stop("The focal predictor for an integer-support method must contain only integer values.")
  if (method == "loess" && length(numeric_predictors) != length(predictors)) {
    .agri_stop("LOESS in agriRank currently requires all modeled predictors to be numeric.")
  }

  # Modelling environment: several backends (loess, mgcv, np, cgam, quantreg)
  # rebuild their model frame with `eval(mf, environment(formula))`. When the
  # user formula carries the calling environment, the symbols `dat` and
  # `weights` are looked up there, where `weights` resolves to `stats::weights`
  # (a closure) and `dat` does not exist. Binding both in a child environment of
  # the formula environment keeps user-supplied terms visible and makes the
  # adapter arguments resolvable.
  .model_env <- new.env(parent = environment(formula) %||% parent.frame())
  assign("dat", dat, envir = .model_env)
  assign("weights", weights, envir = .model_env)
  environment(formula) <- .model_env

  formula_used <- formula
  engine <- NULL
  extra <- list()

  if (method %in% c("theil_sen", "siegel")) {
    .require_pkg("mblm", "Theil-Sen/Siegel median regression")
    engine <- mblm::mblm(formula, dataframe = dat, repeated = identical(method, "siegel"))
  } else if (method == "quantile") {
    .require_pkg("quantreg", "quantile regression")
    formula_used <- .np_append_terms(formula, block_nm %||% character())
    engine <- quantreg::rq(formula_used, data = dat, tau = tau, weights = weights, ...)
  } else if (method == "loess") {
    engine <- stats::loess(formula, data = dat, span = span, degree = degree, weights = weights, ...)
  } else if (method == "smoothing_spline") {
    x <- dat[[primary]]; y <- dat[[response]]
    ok <- is.finite(x) & is.finite(y)
    w <- if (is.null(weights)) rep(1, sum(ok)) else weights[ok]
    engine <- stats::smooth.spline(x[ok], y[ok], w = w, ...)
  } else if (method == "kernel") {
    .require_pkg("np", "mixed-data kernel regression")
    formula_used <- .np_append_terms(formula, block_nm %||% character())
    bw <- np::npregbw(formula = formula_used, data = dat, regtype = kernel_regtype, bwmethod = bwmethod, ...)
    engine <- np::npreg(bws = bw)
    extra$bandwidth <- bw
  } else if (method == "discrete_kernel") {
    .require_pkg("np", "ordered-discrete kernel regression")
    model_dat <- dat
    model_dat[[primary]] <- ordered(as.character(as.integer(round(model_dat[[primary]]))),
                                    levels = as.character(integer_info$values))
    formula_used <- .np_append_terms(formula, block_nm %||% character())
    # Local-linear kernel regression requires at least one continuous
    # regressor. An ordered-integer support with no continuous covariate must
    # fall back to the local-constant estimator instead of failing.
    assign("model_dat", model_dat, envir = .model_env)
    dk_vars <- intersect(all.vars(formula_used[[3L]]), names(model_dat))
    dk_regtype <- kernel_regtype
    if (identical(dk_regtype, "ll") &&
        !any(vapply(model_dat[dk_vars], function(z) is.numeric(z) && !is.ordered(z), logical(1)))) {
      dk_regtype <- "lc"
    }
    bw <- np::npregbw(formula = formula_used, data = model_dat,
                      regtype = dk_regtype, bwmethod = bwmethod,
                      okertype = integer_kernel, ...)
    engine <- np::npreg(bws = bw)
    extra$bandwidth <- bw
    extra$model_data <- model_dat
  } else if (method == "unimodal_isotonic") {
    .require_pkg("Iso", "unimodal isotonic regression")
    agg <- .aggregate_integer_response(dat, primary, response, weights = weights)
    engine <- Iso::ufit(y = agg$y, x = agg$x, w = agg$w, type = "raw", ...)
    extra$unimodal_mode <- engine$mode
    extra$aggregated_integer_data <- agg
  } else if (method == "umbrella") {
    .require_pkg("cgam", "umbrella-order constrained regression")
    formula_used <- .np_umbrella_formula(formula, primary = primary, block = block_nm)
    cgam_env <- new.env(parent = asNamespace("cgam"))
    assign("dat", dat, envir = cgam_env)
    assign("weights", weights, envir = cgam_env)
    environment(formula_used) <- cgam_env
    engine <- cgam::cgam(formula_used, data = dat, family = fam, weights = weights, ...)
  } else if (method == "integer_grid") {
    base <- agri_np_regression(
      formula, data = dat, method = integer_base_method, tau = tau, family = fam,
      shape = shape, block = block_nm, weights = weights, na_action = "fail",
      span = span, degree = degree, k = k, gam_structure = gam_structure,
      kernel_regtype = kernel_regtype, bwmethod = bwmethod, predictor_support = "continuous",
      ...
    )
    engine <- base$engine
    formula_used <- base$formula_used
    extra$base_fit <- base
    extra$base_method <- integer_base_method
  } else if (method == "gam") {
    .require_pkg("mgcv", "generalized additive regression")
    formula_used <- .np_auto_gam_formula(formula, dat, block = block_nm, k = k, structure = gam_structure)
    engine <- mgcv::gam(formula_used, data = dat, family = fam, weights = weights, method = "REML", ...)
  } else if (method == "scam") {
    .require_pkg("scam", "shape-constrained additive regression")
    if (is.null(primary)) .agri_stop("SCAM requires at least one numeric predictor to constrain.")
    formula_used <- .np_scam_formula(formula, dat, primary = primary, shape = shape, block = block_nm, k = k)
    engine <- scam::scam(formula_used, data = dat, family = fam, weights = weights, ...)
  } else if (method == "cobs") {
    .require_pkg("cobs", "constrained quantile B-spline regression")
    if (length(tau) != 1L) .agri_stop("COBS requires a single `tau` value.")
    x <- dat[[primary]]; y <- dat[[response]]; ok <- is.finite(x) & is.finite(y)
    w <- if (is.null(weights)) rep(1, sum(ok)) else weights[ok]
    engine <- cobs::cobs(x[ok], y[ok], w = w, tau = tau, degree = max(1L, min(as.integer(degree), 2L)),
                         constraint = .np_cobs_constraint(shape), lambda = -1, print.mesg = FALSE, ...)
  } else if (method == "isotonic") {
    if (!shape %in% c("none", "increasing", "decreasing")) .agri_stop("Isotonic regression supports increasing or decreasing constraints only.")
    x <- dat[[primary]]; y <- dat[[response]]; ok <- is.finite(x) & is.finite(y)
    ord <- order(x[ok]); xx <- x[ok][ord]; yy <- y[ok][ord]
    sgn <- if (identical(shape, "decreasing")) -1 else 1
    engine <- stats::isoreg(xx, sgn * yy)
    extra$isotonic_sign <- sgn
  } else .agri_stop("Unknown regression method `", method, "`.")

  out <- c(list(
    call = match.call(), formula = formula, formula_used = formula_used,
    data = dat, response = response, predictors = predictors,
    numeric_predictors = numeric_predictors, primary_predictor = primary,
    block = block_nm, design = design_object, method = method, tau = tau, family = fam, shape = shape,
    engine = engine, weights = weights,
    integer_predictor = if (!is.null(integer_info)) primary else NULL,
    predictor_support = if (!is.null(integer_info)) integer_info$mode else "continuous",
    integer_support = if (!is.null(integer_info)) integer_info$values else NULL,
    integer_observed = if (!is.null(integer_info)) integer_info$observed else NULL,
    n_original = n_original, n_omitted = n_omitted, na_action = na_action,
    settings = list(span = span, degree = degree, k = k, gam_structure = gam_structure,
                    kernel_regtype = kernel_regtype, bwmethod = bwmethod, na_action = na_action,
                    predictor_support = if (!is.null(integer_info)) integer_info$mode else "continuous",
                    integer_range = integer_range, integer_values = integer_values,
                    integer_kernel = integer_kernel, integer_base_method = integer_base_method,
                    integer_predictor = if (!is.null(integer_info)) primary else NULL)
  ), extra)
  if (is.null(out$isotonic_sign)) out$isotonic_sign <- 1
  class(out) <- "agri_np_reg_fit"
  pred <- tryCatch(.np_engine_predict(out, dat), error = function(e) rep(NA_real_, nrow(dat)))
  if (is.matrix(pred)) pred <- pred[, 1L]
  out$fitted <- as.numeric(pred)
  out$residuals <- dat[[response]] - out$fitted
  out$metrics <- .np_metrics(dat[[response]], out$fitted)
  out
}

#' @export
print.agri_np_reg_fit <- function(x, ...) {
  cat("agriRank nonparametric regression\n")
  cat("  Method: ", x$method, "\n", sep = "")
  cat("  Response: ", x$response, "\n", sep = "")
  cat("  Predictors: ", paste(x$predictors, collapse = ", "), "\n", sep = "")
  if (length(x$block)) cat("  Block adjustment: ", x$block, "\n", sep = "")
  if (!identical(x$shape, "none")) cat("  Shape constraint: ", x$shape, "\n", sep = "")
  if (!is.null(x$integer_support) && length(x$integer_support)) {
    cat("  Integer decision support: {", paste(x$integer_support, collapse = ", "), "}\n", sep = "")
    if (identical(x$method, "integer_grid")) cat("  Latent base method: ", x$base_method, "\n", sep = "")
  }
  invisible(x)
}

#' @export
summary.agri_np_reg_fit <- function(object, ...) {
  ans <- list(
    method = object$method,
    formula = object$formula_used,
    metrics = object$metrics,
    backend = tryCatch(summary(object$engine), error = function(e) object$engine)
  )
  class(ans) <- "summary.agri_np_reg_fit"
  ans
}

#' @export
print.summary.agri_np_reg_fit <- function(x, ...) {
  cat("agriRank nonparametric regression summary\n")
  cat("Method: ", x$method, "\n\n", sep = "")
  print(x$metrics, row.names = FALSE)
  cat("\nBackend summary:\n")
  print(x$backend)
  invisible(x)
}

#' Predict from a nonparametric regression fit
#' @param object agri_np_reg_fit.
#' @param newdata New data frame. Defaults to training data.
#' @param interval `none` or `confidence`. Analytic confidence intervals are
#'   returned only for engines that expose defensible model-based uncertainty;
#'   otherwise use `agri_np_bootstrap()`.
#' @param level Confidence level.
#' @export
agri_np_predict <- function(object, newdata = NULL, interval = c("none", "confidence"), level = 0.95) {
  if (!inherits(object, "agri_np_reg_fit")) .agri_stop("`object` must be an agri_np_reg_fit.")
  interval <- match.arg(interval)
  newdata <- newdata %||% object$data
  newdata <- .integer_validate_newdata(object, newdata)
  want_se <- identical(interval, "confidence")
  supported <- object$method %in% c("gam", "scam", "cobs", "umbrella") ||
    (identical(object$method, "integer_grid") && object$base_method %in% c("gam", "scam", "cobs"))
  if (want_se && !supported) {
    .agri_warn("Analytic confidence intervals are not standardized for this engine. Returning fitted values only; use agri_np_bootstrap() for resampling-based intervals.")
    want_se <- FALSE
  }
  .np_engine_predict(object, newdata, se.fit = want_se, level = level)
}

#' @export
predict.agri_np_reg_fit <- function(object, newdata = NULL, ...) agri_np_predict(object, newdata = newdata, ...)

#' Regression diagnostics and predictive-error summaries
#' @export
agri_np_diagnostics <- function(object) {
  if (!inherits(object, "agri_np_reg_fit")) .agri_stop("`object` must be an agri_np_reg_fit.")
  res <- object$residuals
  fit <- object$fitted
  ok <- is.finite(res) & is.finite(fit)
  spearman_rf <- if (sum(ok) >= 4L) suppressWarnings(stats::cor(res[ok], fit[ok], method = "spearman")) else NA_real_
  details <- list()
  if (object$method == "smoothing_spline") details <- list(df = object$engine$df, spar = object$engine$spar)
  if (object$method == "loess") details <- list(enp = object$engine$enp, trace_hat = object$engine$trace.hat)
  if (object$method %in% c("kernel", "discrete_kernel")) details <- list(bandwidth = object$bandwidth)
  if (object$method == "unimodal_isotonic") details <- list(mode = object$unimodal_mode, mse = object$engine$mse)
  if (object$method == "integer_grid") details <- list(base_method = object$base_method, integer_support = object$integer_support)
  if (object$method %in% c("gam", "scam")) {
    sm <- tryCatch(summary(object$engine), error = function(e) NULL)
    if (!is.null(sm)) details$edf <- tryCatch(sum(sm$edf), error = function(e) NA_real_)
  }
  list(
    method = object$method,
    metrics = object$metrics,
    residual_median = stats::median(res, na.rm = TRUE),
    residual_MAD = stats::mad(res, na.rm = TRUE),
    residual_fitted_spearman = spearman_rf,
    n_missing_response = sum(is.na(object$data[[object$response]])),
    n_original = object$n_original %||% nrow(object$data),
    n_omitted = object$n_omitted %||% 0L,
    na_action = object$na_action %||% "fail",
    details = details
  )
}

#' Compare regression engines by cross-validation
#'
#' @description
#' Compares predictive performance without using the comparison to choose the
#' smallest inferential p-value. If `block` is supplied, folds are stratified
#' within blocks so all block levels remain represented in training data.
#' @export
agri_np_compare <- function(formula, data,
                            methods = c("smoothing_spline", "loess", "kernel", "gam"),
                            block = NULL, kfold = 5L, seed = 1,
                            metric = c("RMSE", "MAE", "MedAE"), ...) {
  metric <- match.arg(metric)
  bexpr <- substitute(block)
  bval <- tryCatch(block, error = function(e) NULL)
  block_nm <- if (identical(bexpr, quote(NULL))) character() else if (is.character(bval)) bval else .capture_names(bexpr, names(data))
  if (length(block_nm) > 1L) .agri_stop("Cross-validation currently accepts at most one agronomic block variable.")
  .check_vars(block_nm, data)
  n <- nrow(data)
  if (n < 6L) .agri_stop("Cross-validation requires at least six observations.")
  kfold <- max(2L, min(as.integer(kfold), n))
  folds <- integer(n)
  .seed_eval(seed, {
    if (length(block_nm)) {
      for (b in unique(data[[block_nm]])) {
        ii <- which(data[[block_nm]] == b)
        folds[ii] <- sample(rep(seq_len(kfold), length.out = length(ii)))
      }
    } else folds <- sample(rep(seq_len(kfold), length.out = n))
    folds
  }) -> folds

  out <- lapply(methods, function(m) {
    pred <- rep(NA_real_, n); errs <- character()
    for (f in seq_len(kfold)) {
      tr <- data[folds != f, , drop = FALSE]; te <- data[folds == f, , drop = FALSE]
      z <- tryCatch(
        agri_np_regression(formula, tr, method = m, block = block_nm, ...),
        error = function(e) e
      )
      if (inherits(z, "error")) { errs <- c(errs, conditionMessage(z)); next }
      pp <- tryCatch(agri_np_predict(z, te), error = function(e) e)
      if (inherits(pp, "error")) { errs <- c(errs, conditionMessage(pp)); next }
      if (is.matrix(pp)) pp <- pp[, 1L]
      pred[folds == f] <- as.numeric(pp)
    }
    met <- .np_metrics(data[[.response_names(formula)[1L]]], pred)
    data.frame(method = m, met, selected_metric = met[[metric]],
               failures = length(unique(errs)), stringsAsFactors = FALSE)
  })
  ans <- do.call(rbind, out)
  ans <- ans[order(ans$selected_metric), , drop = FALSE]
  rownames(ans) <- NULL
  attr(ans, "metric") <- metric
  attr(ans, "note") <- "Cross-validation ranks predictive error only; it does not select an inferential method by p-value."
  ans
}

#' Numerical derivative of a fitted regression curve
#' @export
agri_np_derivative <- function(object, predictor = NULL, n = 200L, fixed = list(), h = NULL) {
  if (!inherits(object, "agri_np_reg_fit")) .agri_stop("`object` must be an agri_np_reg_fit.")
  if (!is.null(object$integer_support) && length(object$integer_support)) {
    .agri_warn("An instantaneous derivative is not an admissible decision quantity for an integer-support fit. Returning first finite differences instead.")
    return(agri_integer_difference(object, order = 1L, fixed = fixed))
  }
  predictor <- predictor %||% object$primary_predictor
  grid <- .np_prediction_grid(object, predictor = predictor, n = n, fixed = fixed)
  x <- grid[[predictor]]
  if (is.null(h)) h <- max(diff(range(x)), .Machine$double.eps) / 1000
  gp <- grid; gm <- grid
  xr <- range(x)
  gp[[predictor]] <- pmin(x + h, xr[2L]); gm[[predictor]] <- pmax(x - h, xr[1L])
  yp <- agri_np_predict(object, gp); ym <- agri_np_predict(object, gm)
  if (is.matrix(yp)) yp <- yp[, 1L]
  if (is.matrix(ym)) ym <- ym[, 1L]
  data.frame(predictor = predictor, x = x, derivative = (as.numeric(yp) - as.numeric(ym)) / (gp[[predictor]] - gm[[predictor]]))
}

#' Locate a smoothed agronomic optimum or minimum
#'
#' @description
#' Searches the fitted curve over the observed predictor range. This is a
#' descriptive optimum of the selected smoother, not an economic optimum and
#' not a substitute for a prespecified parametric response model when such a
#' model is scientifically required.
#' @export
agri_np_optimum <- function(object, predictor = NULL, objective = c("max", "min"),
                            n = 500L, fixed = list(), range = NULL) {
  if (!inherits(object, "agri_np_reg_fit")) .agri_stop("`object` must be an agri_np_reg_fit.")
  objective <- match.arg(objective)
  predictor <- predictor %||% object$primary_predictor
  grid <- .np_prediction_grid(object, predictor = predictor, n = n, fixed = fixed, range = range)
  p <- agri_np_predict(object, grid)
  if (is.matrix(p)) p <- p[, 1L]
  p <- as.numeric(p)
  idx <- if (objective == "max") which.max(p) else which.min(p)
  data.frame(
    predictor = predictor,
    optimum = grid[[predictor]][idx],
    fitted_response = p[idx],
    objective = objective,
    at_boundary = idx %in% c(1L, nrow(grid)),
    support = if (!is.null(object$integer_support) && length(object$integer_support)) object$predictor_support else "continuous",
    row.names = NULL
  )
}

.bootstrap_sample <- function(data, cluster = NULL) {
  if (is.null(cluster) || !length(cluster)) return(data[sample.int(nrow(data), nrow(data), replace = TRUE), , drop = FALSE])
  lev <- unique(as.character(data[[cluster]]))
  draw <- sample(lev, length(lev), replace = TRUE)
  pieces <- lapply(seq_along(draw), function(j) {
    d <- data[as.character(data[[cluster]]) == draw[j], , drop = FALSE]
    d[[cluster]] <- factor(paste0(draw[j], "__boot", j))
    d
  })
  do.call(rbind, pieces)
}

#' Cluster-aware bootstrap confidence bands for a regression curve
#' @export
agri_np_bootstrap <- function(object, newdata = NULL, predictor = NULL,
                              B = 499L, level = 0.95, seed = 1,
                              cluster = NULL, n = 200L, fixed = list()) {
  if (!inherits(object, "agri_np_reg_fit")) .agri_stop("`object` must be an agri_np_reg_fit.")
  cexpr <- substitute(cluster)
  cval <- tryCatch(cluster, error = function(e) NULL)
  cluster_nm <- if (identical(cexpr, quote(NULL))) object$block else if (is.character(cval)) cval else .capture_names(cexpr, names(object$data))
  if (length(cluster_nm) > 1L) .agri_stop("Bootstrap currently supports at most one cluster variable.")
  if (is.null(newdata)) newdata <- .np_prediction_grid(object, predictor = predictor, n = n, fixed = fixed)
  original <- agri_np_predict(object, newdata)
  if (is.matrix(original)) original <- original[, 1L]
  boot <- matrix(NA_real_, nrow(newdata), B)
  failures <- 0L
  .seed_eval(seed, {
    for (b in seq_len(B)) {
      db <- .bootstrap_sample(object$data, cluster = cluster_nm)
      z <- tryCatch(
        agri_np_regression(object$formula, db, method = object$method, tau = object$tau,
                           family = object$family, shape = object$shape,
                           block = object$block, na_action = object$settings$na_action %||% "fail", span = object$settings$span,
                           degree = object$settings$degree, k = object$settings$k,
                           gam_structure = object$settings$gam_structure %||% "additive",
                           kernel_regtype = object$settings$kernel_regtype %||% "ll",
                           bwmethod = object$settings$bwmethod,
                           predictor_support = if (!is.null(object$integer_support)) "custom_integer" else "continuous",
                           integer_predictor = object$integer_predictor,
                           integer_values = object$integer_support,
                           integer_kernel = object$settings$integer_kernel %||% "wangvanryzin",
                           integer_base_method = object$base_method %||% object$settings$integer_base_method %||% "gam"),
        error = function(e) NULL
      )
      if (is.null(z)) { failures <- failures + 1L; next }
      pp <- tryCatch(agri_np_predict(z, newdata), error = function(e) NULL)
      if (is.null(pp)) { failures <- failures + 1L; next }
      if (is.matrix(pp)) pp <- pp[, 1L]
      boot[, b] <- as.numeric(pp)
    }
  })
  alpha <- 1 - level
  lower <- apply(boot, 1L, stats::quantile, probs = alpha/2, na.rm = TRUE, names = FALSE)
  upper <- apply(boot, 1L, stats::quantile, probs = 1-alpha/2, na.rm = TRUE, names = FALSE)
  out <- cbind(newdata, fit = as.numeric(original), lower = lower, upper = upper)
  attr(out, "B") <- B
  attr(out, "failures") <- failures
  attr(out, "cluster") <- cluster_nm
  class(out) <- c("agri_np_bootstrap", class(out))
  out
}


.require_integer_fit <- function(object) {
  if (!inherits(object, "agri_np_reg_fit"))
    .agri_stop("`object` must be an agri_np_reg_fit.")
  if (is.null(object$integer_support) || !length(object$integer_support))
    .agri_stop("This function requires a regression fit with an explicit integer decision support.")
  invisible(TRUE)
}

#' Predict only at admissible integer values
#'
#' @description
#' Evaluates the fitted regression on its declared integer decision support.
#' Non-integer values and integers outside the support are never generated.
#' @param object An integer-support `agri_np_reg_fit`.
#' @param support Optional subset of the fitted integer support.
#' @param fixed Named values for other covariates.
#' @param interval `none` or `confidence` when supported by the backend.
#' @param level Confidence level.
#' @export
agri_integer_predict <- function(object, support = NULL, fixed = list(),
                                 interval = c("none", "confidence"), level = 0.95) {
  .require_integer_fit(object)
  interval <- match.arg(interval)
  support <- support %||% object$integer_support
  if (!is.numeric(support) || !.integerish(support))
    .agri_stop("`support` must contain integer values.")
  support <- as.integer(round(support))
  grid <- .integer_prediction_grid(object, fixed = fixed, support = support)
  pp <- agri_np_predict(object, grid, interval = interval, level = level)
  predictor <- object$integer_predictor %||% object$primary_predictor
  out <- data.frame(integer_value = grid[[predictor]], stringsAsFactors = FALSE)
  names(out)[1L] <- predictor
  if (is.data.frame(pp) && all(c("fit", "lower", "upper") %in% names(pp))) {
    out <- cbind(out, pp)
  } else {
    if (is.matrix(pp)) pp <- pp[, 1L]
    out$fit <- as.numeric(pp)
  }
  out
}

#' Finite differences on an integer decision support
#'
#' @description
#' Replaces an instantaneous derivative by changes between admissible integer
#' decisions. First differences report the fitted response change between
#' consecutive support values. Second differences are defined only when the
#' support is consecutive with unit spacing.
#' @param object An integer-support regression fit.
#' @param order Difference order, 1 or 2.
#' @param fixed Named values for other covariates.
#' @export
agri_integer_difference <- function(object, order = 1L, fixed = list()) {
  .require_integer_fit(object)
  order <- as.integer(order)
  if (!order %in% c(1L, 2L)) .agri_stop("`order` must be 1 or 2.")
  predictor <- object$integer_predictor %||% object$primary_predictor
  pr <- agri_integer_predict(object, fixed = fixed)
  x <- pr[[predictor]]
  y <- pr$fit
  if (length(x) < order + 1L) .agri_stop("The integer support is too small for the requested difference order.")
  if (order == 1L) {
    dx <- diff(x)
    return(data.frame(
      from = x[-length(x)], to = x[-1L], delta_x = dx,
      fit_from = y[-length(y)], fit_to = y[-1L],
      difference = diff(y), difference_per_integer = diff(y) / dx,
      row.names = NULL
    ))
  }
  if (any(diff(x) != 1L))
    .agri_stop("Second finite differences require consecutive unit-spaced integer support. Refit with predictor_support = 'integer_range' when interpolation to unobserved integers is scientifically acceptable.")
  data.frame(
    center = x[2:(length(x)-1L)],
    fit_left = y[1:(length(y)-2L)],
    fit_center = y[2:(length(y)-1L)],
    fit_right = y[3:length(y)],
    second_difference = y[3:length(y)] - 2*y[2:(length(y)-1L)] + y[1:(length(y)-2L)],
    row.names = NULL
  )
}

#' Locate a maximum or minimum on the admissible integer support
#'
#' @param object An integer-support regression fit.
#' @param objective `max` or `min`.
#' @param fixed Named values for other covariates.
#' @param tolerance Numerical tolerance for declaring tied optima.
#' @export
agri_integer_optimum <- function(object, objective = c("max", "min"),
                                 fixed = list(), tolerance = sqrt(.Machine$double.eps)) {
  .require_integer_fit(object)
  objective <- match.arg(objective)
  predictor <- object$integer_predictor %||% object$primary_predictor
  pr <- agri_integer_predict(object, fixed = fixed)
  y <- pr$fit
  best <- if (objective == "max") max(y, na.rm = TRUE) else min(y, na.rm = TRUE)
  idx <- which(abs(y - best) <= tolerance * max(1, abs(best)))
  ans <- list(
    predictor = predictor,
    objective = objective,
    optima = data.frame(integer_value = pr[[predictor]][idx], fitted_response = y[idx]),
    best_response = best,
    at_boundary = any(idx %in% c(1L, nrow(pr))),
    support = object$integer_support,
    support_mode = object$predictor_support
  )
  names(ans$optima)[1L] <- predictor
  class(ans) <- "agri_integer_optimum"
  ans
}

#' @export
print.agri_integer_optimum <- function(x, ...) {
  cat("agriRank integer-support optimum\n")
  cat("  Objective: ", x$objective, "\n", sep = "")
  cat("  Admissible support: {", paste(x$support, collapse = ", "), "}\n", sep = "")
  cat("  Optimal integer value(s): ", paste(x$optima[[x$predictor]], collapse = ", "), "\n", sep = "")
  cat("  Fitted response: ", format(x$best_response, digits = 6), "\n", sep = "")
  if (isTRUE(x$at_boundary)) cat("  Note: at least one optimum is at the support boundary.\n")
  invisible(x)
}

#' Summarize discrete agronomic efficiency over the integer support
#'
#' @description
#' Returns fitted response, relative response compared with the fitted maximum,
#' and finite marginal changes between adjacent admissible decisions.
#' @param object An integer-support regression fit.
#' @param fixed Named values for other covariates.
#' @export
agri_integer_efficiency <- function(object, fixed = list()) {
  .require_integer_fit(object)
  predictor <- object$integer_predictor %||% object$primary_predictor
  pr <- agri_integer_predict(object, fixed = fixed)
  y <- pr$fit
  ymax <- max(y, na.rm = TRUE)
  rel <- if (is.finite(ymax) && ymax > 0) y / ymax else rep(NA_real_, length(y))
  dprev <- c(NA_real_, diff(y))
  dxprev <- c(NA_real_, diff(pr[[predictor]]))
  dnext <- c(diff(y), NA_real_)
  dxnext <- c(diff(pr[[predictor]]), NA_real_)
  data.frame(
    integer_value = pr[[predictor]],
    fitted_response = y,
    relative_to_fitted_maximum = rel,
    marginal_gain_from_previous = dprev,
    gain_per_integer_from_previous = dprev / dxprev,
    marginal_gain_to_next = dnext,
    gain_per_integer_to_next = dnext / dxnext,
    row.names = NULL
  ) -> out
  names(out)[1L] <- predictor
  out
}

#' Find an integer agronomic decision threshold
#'
#' @description
#' Finds the smallest admissible integer satisfying a prespecified practical
#' criterion. Criteria are defined before examining p-values and are evaluated
#' only on the declared support.
#' @param object An integer-support regression fit.
#' @param criterion `fraction_of_maximum`, `gain_from_baseline`, or `marginal_gain`.
#' @param value Criterion value. For `fraction_of_maximum` it must lie in (0,1].
#' @param baseline Baseline integer for `gain_from_baseline`; defaults to the smallest support value.
#' @param fixed Named values for other covariates.
#' @export
agri_integer_threshold <- function(object,
                                   criterion = c("fraction_of_maximum", "gain_from_baseline", "marginal_gain"),
                                   value = 0.95, baseline = NULL, fixed = list()) {
  .require_integer_fit(object)
  criterion <- match.arg(criterion)
  predictor <- object$integer_predictor %||% object$primary_predictor
  pr <- agri_integer_predict(object, fixed = fixed)
  x <- pr[[predictor]]; y <- pr$fit
  if (criterion == "fraction_of_maximum") {
    if (!is.finite(value) || value <= 0 || value > 1) .agri_stop("For `fraction_of_maximum`, `value` must lie in (0,1].")
    ymax <- max(y, na.rm = TRUE)
    if (!is.finite(ymax) || ymax <= 0) .agri_stop("A fraction-of-maximum threshold requires a positive fitted maximum.")
    idx <- which(y >= value * ymax)
    target <- if (length(idx)) min(idx) else NA_integer_
    return(data.frame(
      criterion = criterion, target = value,
      integer_value = if (is.na(target)) NA_integer_ else x[target],
      fitted_response = if (is.na(target)) NA_real_ else y[target],
      threshold_response = value * ymax,
      row.names = NULL
    ))
  }
  if (criterion == "gain_from_baseline") {
    baseline <- baseline %||% min(x)
    if (!baseline %in% x) .agri_stop("`baseline` must belong to the admissible integer support.")
    ib <- match(baseline, x)
    idx <- which(x >= baseline & (y - y[ib]) >= value)
    target <- if (length(idx)) min(idx) else NA_integer_
    return(data.frame(
      criterion = criterion, target = value, baseline = baseline,
      integer_value = if (is.na(target)) NA_integer_ else x[target],
      fitted_response = if (is.na(target)) NA_real_ else y[target],
      achieved_gain = if (is.na(target)) NA_real_ else y[target] - y[ib],
      row.names = NULL
    ))
  }
  dd <- agri_integer_difference(object, order = 1L, fixed = fixed)
  idx <- which(dd$difference_per_integer <= value)
  target <- if (length(idx)) idx[1L] else NA_integer_
  data.frame(
    criterion = criterion, target = value,
    integer_value = if (is.na(target)) NA_integer_ else dd$to[target],
    marginal_gain_per_integer = if (is.na(target)) NA_real_ else dd$difference_per_integer[target],
    row.names = NULL
  )
}

#' Bootstrap the optimum over an integer decision support
#'
#' @description
#' Re-fits the selected model in each bootstrap sample and searches only the
#' original admissible integer support. When multiple integers tie within a
#' replicate, probability mass is divided equally among the tied optima.
#' @param object An integer-support regression fit.
#' @param objective `max` or `min`.
#' @param B Number of bootstrap replications.
#' @param seed Reproducible seed.
#' @param cluster Optional cluster variable; defaults to the declared agronomic block.
#' @param fixed Named values for other covariates.
#' @param tolerance Numerical tie tolerance.
#' @export
agri_integer_bootstrap <- function(object, objective = c("max", "min"),
                                   B = 499L, seed = 1, cluster = NULL,
                                   fixed = list(), tolerance = sqrt(.Machine$double.eps)) {
  .require_integer_fit(object)
  objective <- match.arg(objective)
  if (!is.null(object$weights))
    .agri_stop("Integer-optimum bootstrap with observation weights is not yet implemented; weights will not be silently discarded.")
  cexpr <- substitute(cluster)
  cval <- tryCatch(cluster, error = function(e) NULL)
  cluster_nm <- if (identical(cexpr, quote(NULL))) object$block else if (is.character(cval)) cval else .capture_names(cexpr, names(object$data))
  if (length(cluster_nm) > 1L) .agri_stop("Bootstrap currently supports at most one cluster variable.")
  support <- object$integer_support
  predictor <- object$integer_predictor %||% object$primary_predictor
  mass <- setNames(rep(0, length(support)), as.character(support))
  failures <- 0L
  ties <- integer(B)
  .seed_eval(seed, {
    for (b in seq_len(B)) {
      db <- .bootstrap_sample(object$data, cluster = cluster_nm)
      z <- tryCatch(
        agri_np_regression(
          object$formula, data = db, method = object$method, tau = object$tau,
          family = object$family, shape = object$shape, block = object$block,
          na_action = "fail", span = object$settings$span, degree = object$settings$degree,
          k = object$settings$k, gam_structure = object$settings$gam_structure %||% "additive",
          kernel_regtype = object$settings$kernel_regtype %||% "ll",
          bwmethod = object$settings$bwmethod,
          predictor_support = "custom_integer", integer_predictor = predictor,
          integer_values = support, integer_kernel = object$settings$integer_kernel %||% "wangvanryzin",
          integer_base_method = object$base_method %||% object$settings$integer_base_method %||% "gam"
        ),
        error = function(e) NULL
      )
      if (is.null(z)) { failures <- failures + 1L; next }
      pr <- tryCatch(agri_integer_predict(z, fixed = fixed), error = function(e) NULL)
      if (is.null(pr) || !nrow(pr)) { failures <- failures + 1L; next }
      y <- pr$fit
      best <- if (objective == "max") max(y, na.rm = TRUE) else min(y, na.rm = TRUE)
      idx <- which(abs(y - best) <= tolerance * max(1, abs(best)))
      if (!length(idx)) { failures <- failures + 1L; next }
      ties[b] <- length(idx)
      vals <- as.character(pr[[predictor]][idx])
      mass[vals] <- mass[vals] + 1 / length(vals)
    }
  })
  successful <- B - failures
  prob <- if (successful > 0L) mass / successful else rep(NA_real_, length(mass))
  ans <- list(
    predictor = predictor, objective = objective, B = as.integer(B),
    successful = successful, failures = failures,
    probabilities = data.frame(integer_value = support, probability = as.numeric(prob)),
    mean_tie_size = if (successful > 0L) mean(ties[ties > 0L]) else NA_real_,
    support = support, support_mode = object$predictor_support,
    cluster = cluster_nm, seed = seed
  )
  names(ans$probabilities)[1L] <- predictor
  class(ans) <- "agri_integer_bootstrap"
  ans
}

#' @export
print.agri_integer_bootstrap <- function(x, ...) {
  cat("agriRank bootstrap distribution of the integer optimum\n")
  cat("  Objective: ", x$objective, "\n", sep = "")
  cat("  Successful refits: ", x$successful, " / ", x$B, "\n", sep = "")
  print(x$probabilities, row.names = FALSE)
  invisible(x)
}

#' Construct a bootstrap confidence set for the integer optimum
#'
#' @description
#' Constructs a highest-probability discrete set from an
#' `agri_integer_bootstrap` object. The selected support points are added in
#' descending bootstrap probability until their cumulative mass reaches the
#' requested level. The result is a set of admissible decisions, not a
#' continuous interval that would imply impossible fractional counts.
#' @param bootstrap An `agri_integer_bootstrap` object.
#' @param level Probability level.
#' @export
agri_integer_confset <- function(bootstrap, level = 0.95) {
  if (!inherits(bootstrap, "agri_integer_bootstrap"))
    .agri_stop("`bootstrap` must be produced by agri_integer_bootstrap().")
  if (!is.finite(level) || level <= 0 || level >= 1) .agri_stop("`level` must lie strictly between 0 and 1.")
  p <- bootstrap$probabilities
  if (all(!is.finite(p$probability))) .agri_stop("No successful bootstrap refits are available.")
  ord <- order(p$probability, decreasing = TRUE, na.last = NA)
  cs <- cumsum(p$probability[ord])
  nkeep <- which(cs >= level)[1L]
  keep <- ord[seq_len(nkeep)]
  predictor <- bootstrap$predictor
  vals <- sort(p[[predictor]][keep])
  ans <- list(
    predictor = predictor, level = level, values = vals,
    probability_mass = sum(p$probability[keep]),
    hull = range(vals), method = "highest_probability_discrete_set",
    probabilities = p
  )
  class(ans) <- "agri_integer_confset"
  ans
}

#' @export
print.agri_integer_confset <- function(x, ...) {
  cat("agriRank bootstrap confidence set for an integer optimum\n")
  cat("  Level: ", format(100*x$level, digits = 4), "%\n", sep = "")
  cat("  Set: {", paste(x$values, collapse = ", "), "}\n", sep = "")
  cat("  Included bootstrap mass: ", format(x$probability_mass, digits = 4), "\n", sep = "")
  invisible(x)
}


#' ggplot2 visualization for nonparametric regression
#' @param object An `agri_np_reg_fit` object.
#' @param type One-dimensional fit, residual, derivative, or two-dimensional surface.
#' @param predictor Numeric focal predictor for one-dimensional graphics.
#' @param n Grid resolution.
#' @param fixed Named values at which other covariates are held fixed.
#' @param interval Request an analytic confidence ribbon when the backend supports it.
#' @param group Optional grouping variable for conditional curves.
#' @param surface_predictors Two numeric predictors for a response-surface plot.
#' @param ... Reserved for future extensions.
#' @export
agri_np_plot <- function(object, type = c("fit", "residuals", "derivative", "surface"),
                         predictor = NULL, n = 200L, fixed = list(), interval = FALSE,
                         group = NULL, surface_predictors = NULL, ...) {
  if (!inherits(object, "agri_np_reg_fit")) .agri_stop("`object` must be an agri_np_reg_fit.")
  type <- match.arg(type)
  predictor <- predictor %||% object$primary_predictor
  if (type == "residuals") {
    dd <- data.frame(fitted = object$fitted, residual = object$residuals)
    return(ggplot2::ggplot(dd, ggplot2::aes(x = fitted, y = residual)) +
      ggplot2::geom_point() + ggplot2::geom_hline(yintercept = 0, linetype = 2) +
      ggplot2::labs(x = "Fitted value", y = "Residual") + ggplot2::theme_minimal())
  }
  if (type == "derivative") {
    if (!is.null(object$integer_support) && length(object$integer_support)) {
      dd <- agri_integer_difference(object, order = 1L, fixed = fixed)
      return(ggplot2::ggplot(dd, ggplot2::aes(x = to, y = difference)) +
        ggplot2::geom_line() + ggplot2::geom_point() +
        ggplot2::geom_hline(yintercept = 0, linetype = 2) +
        ggplot2::labs(x = predictor, y = "Finite difference in fitted response") +
        ggplot2::theme_minimal())
    }
    dd <- agri_np_derivative(object, predictor = predictor, n = n, fixed = fixed)
    return(ggplot2::ggplot(dd, ggplot2::aes(x = x, y = derivative)) +
      ggplot2::geom_line() + ggplot2::geom_hline(yintercept = 0, linetype = 2) +
      ggplot2::labs(x = predictor, y = "Estimated derivative") + ggplot2::theme_minimal())
  }
  if (type == "surface") {
    grid <- .np_surface_grid(object, predictors = surface_predictors, n = min(as.integer(n), 100L), fixed = fixed)
    sp <- surface_predictors %||% object$numeric_predictors[1:2]
    pp <- agri_np_predict(object, grid)
    if (is.matrix(pp)) pp <- pp[, 1L]
    dd <- data.frame(x1 = grid[[sp[1L]]], x2 = grid[[sp[2L]]], fit = as.numeric(pp))
    return(ggplot2::ggplot(dd, ggplot2::aes(x = x1, y = x2, fill = fit)) +
      ggplot2::geom_raster() +
      ggplot2::geom_contour(data = dd, ggplot2::aes(x = x1, y = x2, z = fit), inherit.aes = FALSE) +
      ggplot2::labs(x = sp[1L], y = sp[2L], fill = object$response) + ggplot2::theme_minimal())
  }
  if (!is.null(group)) {
    group <- as.character(group)[1L]
    if (!group %in% names(object$data)) .agri_stop("Unknown grouping variable `", group, "`.")
    lev <- if (is.factor(object$data[[group]])) levels(object$data[[group]]) else unique(as.character(object$data[[group]]))
    grids <- lapply(lev, function(g) {
      fx <- fixed; fx[[group]] <- g
      z <- .np_prediction_grid(object, predictor = predictor, n = n, fixed = fx)
      pp <- agri_np_predict(object, z); if (is.matrix(pp)) pp <- pp[, 1L]
      data.frame(x = z[[predictor]], fit = as.numeric(pp), group = g, stringsAsFactors = FALSE)
    })
    dd <- do.call(rbind, grids)
    raw <- data.frame(x = object$data[[predictor]], y = object$data[[object$response]], group = as.character(object$data[[group]]))
    return(ggplot2::ggplot(raw, ggplot2::aes(x = x, y = y, group = group)) +
      ggplot2::geom_point(ggplot2::aes(shape = group), alpha = 0.65) +
      ggplot2::geom_line(data = dd, ggplot2::aes(x = x, y = fit, linetype = group), inherit.aes = FALSE) +
      ggplot2::labs(x = predictor, y = object$response, shape = group, linetype = group) + ggplot2::theme_minimal())
  }
  grid <- .np_prediction_grid(object, predictor = predictor, n = n, fixed = fixed)
  pp <- if (interval) agri_np_predict(object, grid, interval = "confidence") else agri_np_predict(object, grid)
  dd <- data.frame(x = grid[[predictor]])
  if (is.data.frame(pp) && all(c("fit", "lower", "upper") %in% names(pp))) {
    dd <- cbind(dd, pp)
  } else {
    if (is.matrix(pp)) pp <- pp[, 1L]
    dd$fit <- as.numeric(pp)
  }
  raw <- data.frame(x = object$data[[predictor]], y = object$data[[object$response]])
  p <- ggplot2::ggplot(raw, ggplot2::aes(x = x, y = y)) +
    ggplot2::geom_point(alpha = 0.65) +
    ggplot2::geom_line(data = dd, ggplot2::aes(x = x, y = fit), inherit.aes = FALSE) +
    ggplot2::labs(x = predictor, y = object$response) + ggplot2::theme_minimal()
  if (all(c("lower", "upper") %in% names(dd))) {
    p <- p + ggplot2::geom_ribbon(data = dd, ggplot2::aes(x = x, ymin = lower, ymax = upper),
                                  inherit.aes = FALSE, alpha = 0.2)
  }
  p
}

#' @export
plot.agri_np_reg_fit <- function(x, ...) agri_np_plot(x, ...)

.np_surface_grid <- function(object, predictors = NULL, n = 60L, fixed = list()) {
  nums <- object$numeric_predictors
  predictors <- predictors %||% nums[seq_len(min(2L, length(nums)))]
  if (length(predictors) != 2L || !all(predictors %in% nums))
    .agri_stop("A response-surface plot requires exactly two numeric predictors.")
  n <- max(15L, as.integer(n))
  x1 <- seq(min(object$data[[predictors[1L]]], na.rm = TRUE), max(object$data[[predictors[1L]]], na.rm = TRUE), length.out = n)
  x2 <- seq(min(object$data[[predictors[2L]]], na.rm = TRUE), max(object$data[[predictors[2L]]], na.rm = TRUE), length.out = n)
  grid <- expand.grid(setNames(list(x1, x2), predictors), KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
  vars <- setdiff(unique(c(object$predictors, object$block %||% character())), predictors)
  for (v in vars) {
    val <- fixed[[v]] %||% .np_reference_value(object$data[[v]])
    if (is.factor(object$data[[v]])) grid[[v]] <- factor(rep(val, nrow(grid)), levels = levels(object$data[[v]]))
    else grid[[v]] <- rep(val, nrow(grid))
  }
  grid
}

#' Convert an agronomic nonparametric regression graphic to Plotly
#'
#' @description
#' Creates an interactive version of the editable ggplot2 regression graphic.
#' This is an exploratory communication layer and does not alter the fitted
#' model or its inferential interpretation.
#' @param object An `agri_np_reg_fit` object.
#' @param type Plot type passed to `agri_np_plot()`.
#' @param ... Additional arguments passed to `agri_np_plot()`.
#' @export
agri_np_interactive <- function(object, type = c("fit", "residuals", "derivative", "surface"), ...) {
  .require_pkg("plotly", "interactive nonparametric regression graphics")
  type <- match.arg(type)
  plotly::ggplotly(agri_np_plot(object, type = type, ...))
}

#' Bootstrap significance tests for predictors in kernel regression
#'
#' @description
#' Applies the consistent mixed-data kernel significance test implemented by
#' `np::npsigtest()` to a fitted `agriRank` kernel regression. By default,
#' scientific predictors are tested while a declared agronomic block remains in
#' the conditioning set and is not itself tested.
#' @param object An `agri_np_reg_fit` fitted with `method = "kernel"`.
#' @param variables Optional character vector of predictors to test. Defaults to
#'   the scientific predictors in the original regression formula.
#' @param joint Test the selected predictors jointly rather than separately.
#' @param B Number of bootstrap replications.
#' @param boot_method Bootstrap method accepted by `np::npsigtest()`.
#' @param boot_type Type-I or the more computationally intensive Type-II
#'   bootstrap calibration used by `np::npsigtest()`.
#' @param pivot Use the pivotal statistic.
#' @param seed Reproducible bootstrap seed.
#' @param ... Additional arguments passed to `np::npsigtest()`.
#' @export
agri_np_significance <- function(object, variables = NULL, joint = FALSE,
                                 B = 399L,
                                 boot_method = c("wild-rademacher", "wild", "iid", "pairwise"),
                                 boot_type = c("II", "I"), pivot = TRUE,
                                 seed = 42L, ...) {
  if (!inherits(object, "agri_np_reg_fit")) .agri_stop("`object` must be an agri_np_reg_fit.")
  if (!object$method %in% c("kernel", "discrete_kernel"))
    .agri_stop("`agri_np_significance()` currently requires `method = 'kernel'` or `method = 'discrete_kernel'`.")
  .require_pkg("np", "kernel regression significance testing")
  boot_method <- match.arg(boot_method)
  boot_type <- match.arg(boot_type)
  vars_used <- .predictor_names(object$formula_used)
  variables <- variables %||% object$predictors
  if (!length(variables)) .agri_stop("At least one predictor must be selected for testing.")
  bad <- setdiff(variables, vars_used)
  if (length(bad)) .agri_stop("Unknown predictor(s) for kernel significance test: ", paste(bad, collapse = ", "))
  index <- match(variables, vars_used)
  z <- np::npsigtest(
    bws = object$bandwidth,
    boot.num = as.integer(B),
    boot.method = boot_method,
    boot.type = boot_type,
    pivot = isTRUE(pivot),
    joint = isTRUE(joint),
    index = index,
    random.seed = as.integer(seed),
    ...
  )
  attr(z, "agriRank_variables") <- variables
  attr(z, "agriRank_block_adjustment") <- object$block
  attr(z, "agriRank_note") <- paste(
    "This is a model-based bootstrap significance test for kernel regression;",
    "it is not a randomization test derived from the field-experiment allocation scheme."
  )
  z
}

#' Nonparametric specification test for a prespecified Gaussian regression
#'
#' @description
#' Tests whether a prespecified linear or polynomial Gaussian regression appears
#' too restrictive relative to a mixed-data nonparametric alternative, using
#' `np::npcmstest()`. This is a model-specification diagnostic, not a procedure
#' for searching over many candidate equations and retaining the most favorable
#' p-value.
#' @param model A fitted `lm` or Gaussian `glm` object created with `x = TRUE`
#'   and `y = TRUE`.
#' @param data Optional original data frame. When omitted, the model frame is
#'   used to recover the explanatory variables whenever possible.
#' @param B Number of bootstrap replications.
#' @param distribution Bootstrap or asymptotic reference distribution.
#' @param boot_method Bootstrap method accepted by `np::npcmstest()`.
#' @param pivot Use the pivotal statistic.
#' @param density_weighted Weight the statistic by the estimated predictor density.
#' @param seed Reproducible bootstrap seed.
#' @param ... Additional kernel/bandwidth arguments passed to `np::npcmstest()`.
#' @export
agri_np_specification <- function(model, data = NULL, B = 399L,
                                  distribution = c("bootstrap", "asymptotic"),
                                  boot_method = c("wild-rademacher", "wild", "iid"),
                                  pivot = TRUE, density_weighted = TRUE,
                                  seed = 42L, ...) {
  .require_pkg("np", "nonparametric model specification testing")
  if (!inherits(model, c("lm", "glm"))) .agri_stop("`model` must inherit from lm or glm.")
  if (inherits(model, "glm") && !identical(model$family$family, "gaussian"))
    .agri_stop("`np::npcmstest()` uses residual bootstrapping and agriRank restricts this adapter to continuous Gaussian outcomes.")
  if (is.null(model$x) || is.null(model$y))
    .agri_stop("Refit the candidate model with `x = TRUE, y = TRUE` before using agri_np_specification().")
  distribution <- match.arg(distribution)
  boot_method <- match.arg(boot_method)
  form <- stats::formula(model)
  predictor_vars <- unique(all.vars(stats::delete.response(stats::terms(form))))
  mf <- tryCatch(stats::model.frame(model), error = function(e) NULL)
  source <- data %||% mf
  if (is.null(source)) .agri_stop("Could not recover predictor data; supply the original `data` explicitly.")
  source <- as.data.frame(source)
  available <- intersect(predictor_vars, names(source))
  if (!length(available)) {
    # Fall back to the non-intercept columns of the stored model matrix. This
    # preserves transformed candidates but loses original mixed-data classes.
    mm <- as.data.frame(model$x)
    keep <- setdiff(names(mm), "(Intercept)")
    if (!length(keep)) .agri_stop("No explanatory variables could be recovered from the candidate model.")
    xdat <- mm[keep]
    .agri_warn("Original predictors were not recoverable; the specification test is using columns of the stored model matrix.")
  } else {
    xdat <- source[available]
  }
  ydat <- as.numeric(model$y)
  if (nrow(xdat) != length(ydat))
    .agri_stop("Recovered predictor data and model response have different numbers of observations. Supply the exact model data after the model's missing-data handling.")
  z <- np::npcmstest(
    model = model,
    xdat = xdat,
    ydat = ydat,
    distribution = distribution,
    boot.method = boot_method,
    boot.num = as.integer(B),
    pivot = isTRUE(pivot),
    density.weighted = isTRUE(density_weighted),
    random.seed = as.integer(seed),
    ...
  )
  attr(z, "agriRank_note") <- paste(
    "A small p-value is evidence against the prespecified parametric functional form;",
    "it is not evidence that one particular nonparametric smoother is uniquely correct."
  )
  z
}
