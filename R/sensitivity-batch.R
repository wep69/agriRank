# Sensitivity and batch workflows ----------------------------------------

# Effect labels and p-values must be extracted from heterogeneous backend
# tables without assuming that row names exist or that every column whose name
# contains the letter "p" is a p-value column.
.agri_effect_labels <- function(tab) {
  tab <- as.data.frame(tab)
  n <- nrow(tab)
  if (!n) return(character(0))
  lab <- NULL
  for (cand in c("effect", "term", "source", "Effect", "Term")) {
    if (cand %in% names(tab)) { lab <- as.character(tab[[cand]]); break }
  }
  if (is.null(lab)) {
    rn <- rownames(tab)
    lab <- if (!is.null(rn) && length(rn) == n && !all(rn == as.character(seq_len(n))))
      rn else as.character(seq_len(n))
  }
  lab <- as.character(lab)
  if (length(lab) != n) lab <- rep_len(lab, n)
  lab
}

.agri_pvalues <- function(tab) {
  tab <- as.data.frame(tab)
  n <- nrow(tab)
  if (!n) return(numeric(0))
  nms <- names(tab)
  pc <- nms[grepl("^(p|p[._-]?val|p[._-]?value|pvalue|pr\\()", tolower(nms))]
  if (!length(pc)) pc <- nms[grepl("p[._-]?value|pr\\(>", tolower(nms))]
  if (!length(pc)) return(rep(NA_real_, n))
  p <- suppressWarnings(as.numeric(tab[[pc[length(pc)]]]))
  if (length(p) != n) p <- rep_len(p, n)
  p
}

#' Compare admissible inferential paradigms without selecting by p-value
#' @export
agri_sensitivity <- function(x, methods = c("primary", "ART", "permuco"), seed = 1, ...) {
  design <- if (inherits(x, "agri_rank_fit")) x$design else x
  if (!inherits(design, "agri_design")) .agri_stop("agri_design or agri_rank_fit required.")
  fits <- list()
  if ("primary" %in% methods) fits$primary <- tryCatch(if (inherits(x, "agri_rank_fit")) x else agri_rank(design, seed = seed, ...), error = identity)
  if ("ART" %in% methods && requireNamespace("ARTool", quietly = TRUE) && !design$design %in% c("repeated", "longitudinal")) fits$ART <- tryCatch(agri_rank(design, method = "ART", seed = seed, ...), error = identity)
  if ("permuco" %in% methods && requireNamespace("permuco", quietly = TRUE)) fits$permuco <- tryCatch(agri_rank(design, method = "permuco", seed = seed, ...), error = identity)
  extract <- function(f, nm) {
    if (inherits(f, "error")) return(data.frame(method = nm, effect = NA, p_value = NA, note = conditionMessage(f)))
    tab <- f$omnibus
    if (is.null(tab)) return(data.frame(method = nm, effect = NA, p_value = NA, note = "No standardized omnibus table extracted"))
    eff <- .agri_effect_labels(tab)
    p <- .agri_pvalues(tab)
    data.frame(method = nm, effect = eff, p_value = p, note = "", stringsAsFactors = FALSE)
  }
  table <- do.call(rbind, Map(extract, fits, names(fits)))
  structure(list(table = table, fits = fits,
                 interpretation = "Differences across methods quantify model sensitivity. They must not be used to choose the smallest p-value."),
            class = "agri_sensitivity")
}

#' Batch analysis of multiple responses under the same design
#' @export
agri_batch <- function(design, responses = NULL, method = "auto", adjust_across = c("none", "BH", "holm"), ...) {
  if (!inherits(design, "agri_design")) .agri_stop("agri_design required.")
  adjust_across <- match.arg(adjust_across)
  responses <- responses %||% design$response
  .check_vars(responses, design$data)
  rhs <- paste(deparse(design$formula[[3L]]), collapse = "")
  fits <- lapply(responses, function(r) {
    d <- design
    d$response <- r
    d$formula <- stats::as.formula(paste(r, "~", rhs), env = environment(design$formula))
    d$terms <- .term_labels(d$formula)
    tryCatch(agri_rank(d, method = method, response = r, ...), error = identity)
  })
  names(fits) <- responses
  summary_rows <- lapply(seq_along(fits), function(i) {
    f <- fits[[i]]; r <- responses[i]
    if (inherits(f, "error")) return(data.frame(response = r, effect = NA, p_value = NA, status = conditionMessage(f)))
    tab <- f$omnibus
    if (is.null(tab)) return(data.frame(response = r, effect = NA, p_value = NA, status = "fit; no standardized p extracted"))
    data.frame(response = r, effect = .agri_effect_labels(tab),
               p_value = .agri_pvalues(tab), status = "ok", stringsAsFactors = FALSE)
  })
  tab <- do.call(rbind, summary_rows)
  if (adjust_across != "none") tab$p_across_adjusted <- stats::p.adjust(tab$p_value, method = adjust_across)
  structure(list(design = design, fits = fits, summary = tab, adjust_across = adjust_across), class = "agri_batch")
}
