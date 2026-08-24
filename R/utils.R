# Internal utilities -------------------------------------------------------

`%||%` <- function(x, y) if (is.null(x)) y else x

.agri_stop <- function(...) stop(..., call. = FALSE)
.agri_warn <- function(...) warning(..., call. = FALSE, immediate. = TRUE)

.capture_names <- function(expr, data_names = NULL) {
  if (identical(expr, quote(NULL)) || identical(expr, quote(missing_arg()))) return(NULL)
  if (is.symbol(expr)) return(as.character(expr))
  if (is.character(expr)) return(expr)
  if (is.call(expr) && identical(expr[[1L]], as.name("c"))) {
    out <- unlist(lapply(as.list(expr)[-1L], .capture_names, data_names = data_names), use.names = FALSE)
    return(out)
  }
  .agri_stop("Variable specifications must be bare names, character strings, or c(...).")
}

.check_vars <- function(vars, data, what = "variable") {
  vars <- vars[!is.na(vars) & nzchar(vars)]
  bad <- setdiff(vars, names(data))
  if (length(bad)) .agri_stop(sprintf("Unknown %s(s): %s", what, paste(bad, collapse = ", ")))
  invisible(TRUE)
}

.response_names <- function(formula) {
  if (!inherits(formula, "formula")) .agri_stop("`formula` must be a formula.")
  all.vars(formula[[2L]])
}

.predictor_names <- function(formula) {
  if (length(formula) < 3L) return(character())
  all.vars(formula[[3L]])
}

.term_labels <- function(formula) attr(stats::terms(formula), "term.labels")

.safe_factor <- function(x) if (is.factor(x)) x else factor(x)

.interaction_key <- function(data, vars, sep = "::") {
  if (!length(vars)) return(factor(rep("all", nrow(data))))
  args <- c(lapply(data[vars], .safe_factor), list(drop = TRUE, lex.order = TRUE, sep = sep))
  do.call(interaction, args)
}


.subject_namespace <- function(data, design) {
  if (!length(design$subject)) .agri_stop("A subject identifier is required.")
  sid <- .interaction_key(data, design$subject)
  nuisance_between <- unique(c(design$block, setdiff(design$predictors, design$within %||% character())))
  if (length(nuisance_between)) {
    interaction(.interaction_key(data, nuisance_between), sid,
                drop = TRUE, lex.order = TRUE, sep = "@@")
  } else sid
}

.agri_ginv <- function(A, tol = sqrt(.Machine$double.eps)) {
  A <- as.matrix(A)
  if (!length(A)) return(A)
  s <- svd(A)
  if (!length(s$d)) return(matrix(0, nrow(A), ncol(A)))
  keep <- s$d > max(s$d) * tol
  if (!any(keep)) return(matrix(0, ncol(A), nrow(A)))
  s$v[, keep, drop = FALSE] %*% (t(s$u[, keep, drop = FALSE]) / s$d[keep])
}

.blockdiag <- function(mats) {
  mats <- mats[lengths(mats) > 0L]
  if (!length(mats)) return(matrix(numeric(), 0L, 0L))
  nr <- sum(vapply(mats, nrow, integer(1)))
  nc <- sum(vapply(mats, ncol, integer(1)))
  out <- matrix(0, nr, nc)
  r0 <- cumsum(c(1L, vapply(mats, nrow, integer(1))))
  c0 <- cumsum(c(1L, vapply(mats, ncol, integer(1))))
  for (i in seq_along(mats)) {
    out[r0[i]:(r0[i + 1L] - 1L), c0[i]:(c0[i + 1L] - 1L)] <- mats[[i]]
  }
  out
}

.trace <- function(A) sum(diag(A))

.seed_eval <- function(seed, expr) {
  if (is.null(seed)) return(force(expr))
  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (had_seed) old_seed <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  on.exit({
    if (had_seed) assign(".Random.seed", old_seed, envir = .GlobalEnv)
    else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)
  set.seed(seed)
  force(expr)
}

# Independent random number substreams, one per resampling replicate.
#
# A loop that draws from one stream produces replicate b only after replicates
# 1 to b-1 have drawn theirs, so its content depends on the order in which the
# loop ran. That is fine while everything is serial and stops being fine the
# moment any part of the loop is distributed, reordered or resumed: the same
# seed then yields different replicates, and a published interval becomes
# irreproducible for a reason the reader cannot see.
#
# L'Ecuyer's combined multiple recursive generator provides streams that are far
# apart in the cycle, so replicate b can be given its own and drawn in any
# order. This is the same device the calibration study under inst/calibration
# already uses; the exported functions now use it too.
#
# Returns a list of `.Random.seed` vectors, one per replicate.
.agri_substreams <- function(seed, n) {
  if (is.null(seed) || !n) return(NULL)
  had <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (had) old <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  old_kind <- RNGkind()
  on.exit({
    do.call(RNGkind, as.list(old_kind))
    if (had) assign(".Random.seed", old, envir = .GlobalEnv)
    else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
      rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)
  RNGkind("L'Ecuyer-CMRG")
  set.seed(seed)
  s <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  out <- vector("list", n)
  for (i in seq_len(n)) {
    out[[i]] <- s
    s <- parallel::nextRNGStream(s)
  }
  out
}

# Evaluate `expr` on a given substream, leaving the caller's RNG state and kind
# untouched afterwards.
.agri_on_stream <- function(state, expr) {
  if (is.null(state)) return(force(expr))
  had <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (had) old <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  old_kind <- RNGkind()
  on.exit({
    do.call(RNGkind, as.list(old_kind))
    if (had) assign(".Random.seed", old, envir = .GlobalEnv)
    else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
      rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)
  RNGkind("L'Ecuyer-CMRG")
  assign(".Random.seed", state, envir = .GlobalEnv)
  force(expr)
}

# Apply a function over resampling replicates, in parallel when the user has
# asked for it and sequentially otherwise.
#
# The default is sequential and stays sequential. Parallelism is opt-in for two
# reasons. It changes nothing statistically, so it should never be imposed; and
# on a small problem the cost of starting workers and shipping the data exceeds
# what it saves, so a silent default would make short examples slower.
#
# Correctness rests on the substreams introduced alongside this: replicate b is
# drawn from its own stream, so it is the same object whichever worker computes
# it and in whatever order. Without that, parallelising would have quietly made
# results depend on the number of cores.
#
# The backend is future.apply, declared in Suggests. If the user has set a
# future plan and the package is installed, that plan is honoured; otherwise
# lapply() is used and nothing is lost but time.
.agri_lapply <- function(X, FUN, parallel = FALSE, ...) {
  if (!isTRUE(parallel)) return(lapply(X, FUN, ...))
  if (!requireNamespace("future.apply", quietly = TRUE)) {
    .agri_warn("`parallel = TRUE` needs the future.apply package, which is not ",
               "installed. Running sequentially. Install future.apply and set a ",
               "plan, for example future::plan(future::multisession), to use it.")
    return(lapply(X, FUN, ...))
  }
  # The seeds are carried by the substreams, so future's own RNG guard has
  # nothing left to protect and would only warn about a risk that is already
  # handled.
  future.apply::future_lapply(X, FUN, ..., future.seed = NULL)
}

# Is a parallel plan actually in force? Used only to report it, so that a run
# that the user believes was parallel but was not is visible in the output.
.agri_parallel_workers <- function() {
  if (!requireNamespace("future", quietly = TRUE)) return(NA_integer_)
  tryCatch(as.integer(future::nbrOfWorkers()), error = function(e) NA_integer_)
}

.mc_p <- function(stat_boot, stat_obs, correction = TRUE) {
  stat_boot <- stat_boot[is.finite(stat_boot)]
  if (!length(stat_boot)) return(NA_real_)
  if (correction) (1 + sum(stat_boot >= stat_obs)) / (length(stat_boot) + 1) else mean(stat_boot >= stat_obs)
}

.effect_basis <- function(cell_df, effect_factors, all_factors) {
  if (!length(all_factors)) return(matrix(1, nrow = 1L, ncol = nrow(cell_df)))
  basis_for_factor <- function(f) {
    lev <- levels(.safe_factor(cell_df[[f]]))
    idx <- match(as.character(cell_df[[f]]), lev)
    q <- if (f %in% effect_factors) {
      if (length(lev) < 2L) matrix(0, length(lev), 0L) else stats::contr.helmert(length(lev))
    } else {
      matrix(rep(1 / length(lev), length(lev)), ncol = 1L)
    }
    q[idx, , drop = FALSE]
  }
  parts <- lapply(all_factors, basis_for_factor)
  if (any(vapply(parts, ncol, integer(1)) == 0L)) return(matrix(numeric(), 0L, nrow(cell_df)))
  K <- matrix(1, nrow(cell_df), 1L)
  for (P in parts) {
    Knew <- matrix(NA_real_, nrow(cell_df), ncol(K) * ncol(P))
    z <- 1L
    for (i in seq_len(ncol(K))) {
      for (j in seq_len(ncol(P))) {
        Knew[, z] <- K[, i] * P[, j]
        z <- z + 1L
      }
    }
    K <- Knew
  }
  t(K)
}

.p_adjust <- function(p, method = "holm") stats::p.adjust(p, method = method)

.require_pkg <- function(pkg, why = NULL) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    msg <- sprintf("Package `%s` is required%s. Install it and retry.", pkg,
                   if (is.null(why)) "" else paste0(" for ", why))
    .agri_stop(msg)
  }
  invisible(TRUE)
}

.extract_p_column <- function(x) {
  if (is.null(x)) return(NULL)
  if (is.data.frame(x) || is.matrix(x)) {
    nms <- tolower(colnames(x) %||% character())
    hit <- grep("p.*value|p-value|p_value|pvalue|resampling", nms)
    if (length(hit)) return(as.numeric(x[, hit[1L]]))
  }
  NULL
}
