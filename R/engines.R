# Statistical engines ------------------------------------------------------

.engine_kruskal <- function(design, response = NULL) {
  response <- response %||% design$response[1L]
  if (length(design$predictors) != 1L) .agri_stop("Kruskal-Wallis requires one treatment factor.")
  f <- stats::reformulate(design$predictors, response)
  z <- stats::kruskal.test(f, data = design$data)
  list(method = "Kruskal-Wallis", omnibus = data.frame(effect = design$predictors, statistic = unname(z$statistic), df = unname(z$parameter), p_value = z$p.value), raw = z)
}

.engine_friedman <- function(design, response = NULL) {
  response <- response %||% design$response[1L]
  if (length(design$predictors) != 1L || length(design$block) != 1L)
    .agri_stop("Friedman compatibility engine requires one treatment factor and one block factor.")
  dat <- design$data[!is.na(design$data[[response]]), , drop = FALSE]
  tab <- table(dat[[design$block]], dat[[design$predictors]])
  if (any(tab != 1L)) .agri_stop("Classical Friedman requires exactly one observation for each block-by-treatment cell. Use a permutation/rank-based alternative for incomplete or replicated blocks.")
  f <- stats::as.formula(sprintf("%s ~ %s | %s", response, design$predictors, design$block))
  z <- stats::friedman.test(f, data = dat)
  list(method = "Friedman rank-sum", omnibus = data.frame(effect = design$predictors, statistic = unname(z$statistic), df = unname(z$parameter), p_value = z$p.value), raw = z)
}

.engine_rankfd <- function(design, response = NULL, ...) {
  .require_pkg("rankFD", "general factorial rank inference")
  response <- response %||% design$response[1L]
  terms_declared <- .term_labels(design$formula)
  if (length(design$predictors) > 1L && !any(grepl(":", terms_declared, fixed = TRUE)))
    .agri_stop("The rankFD backend requires an interaction term for multifactor inference. Use `permuco` for an explicitly additive multifactor model.")
  f <- stats::as.formula(paste(response, "~", paste(deparse(design$formula[[3L]]), collapse = "")), env = environment(design$formula))
  z <- rankFD::rankFD(f, data = design$data, ...)
  # Keep backend object intact; extraction is version-tolerant.
  tab <- NULL
  for (nm in c("ANOVA.Type.Statistic", "ANOVA.test", "ATS",
               "Wald.Type.Statistic", "WTS", "Wald.test")) {
    if (!is.null(z[[nm]])) { tab <- as.data.frame(z[[nm]]); break }
  }
  if (!is.null(tab)) {
    # Normalize the backend column names so downstream summaries
    # (agri_table, agri_sensitivity, agri_batch) find effect and p-value.
    if (!"effect" %in% names(tab)) tab <- cbind(effect = rownames(tab), tab)
    nm2 <- names(tab)
    nm2[tolower(nm2) %in% c("p-value", "p.value", "pvalue", "p_value")] <- "p_value"
    nm2[tolower(nm2) == "statistic"] <- "statistic"
    names(tab) <- nm2
    rownames(tab) <- NULL
  }
  list(method = "rankFD pseudo-rank factorial inference", omnibus = tab, raw = z, formula = f)
}

.engine_art <- function(design, response = NULL, ...) {
  .require_pkg("ARTool", "aligned rank transform")
  response <- response %||% design$response[1L]
  dat <- design$data
  fixed_terms <- .term_labels(design$formula)
  if (!length(fixed_terms)) .agri_stop("ART requires at least one fixed treatment term.")
  if (length(design$predictors) > 1L && !any(grepl(":", fixed_terms, fixed = TRUE)))
    .agri_stop("ARTool requires an interaction-containing factorial specification when multiple fixed factors are present. Use `permuco` for an explicitly additive multifactor model.")
  if (design$design == "multienv" && length(design$environment)) {
    env <- design$environment[1L]
    has_env_interaction <- any(vapply(fixed_terms, function(tt) {
      vars <- all.vars(stats::as.formula(paste("~", tt)))
      env %in% vars && length(setdiff(vars, env)) > 0L
    }, logical(1)))
    if (length(setdiff(design$predictors, env)) && !has_env_interaction)
      .agri_stop("ARTool requires the factorial interaction structure for multiple fixed factors. For a multi-environment main-effect-only model, use `permuco` instead of `ART`.")
  }
  rhs <- paste(fixed_terms, collapse = " + ")
  random_terms <- character()
  if (length(design$block)) dat$.agri_block <- .safe_factor(dat[[design$block[1L]]])

  if (design$design == "rcbd" && length(design$block)) {
    random_terms <- c(random_terms, "(1|.agri_block)")
  }
  if (design$design == "split_plot") {
    dat$.agri_wp_unit <- .interaction_key(dat, c(design$block, design$whole_plot))
    random_terms <- c("(1|.agri_block)", "(1|.agri_wp_unit)")
  }
  if (design$design == "split_split") {
    dat$.agri_wp_unit <- .interaction_key(dat, c(design$block, design$whole_plot))
    dat$.agri_sp_unit <- .interaction_key(dat, c(design$block, design$whole_plot, design$subplot))
    random_terms <- c("(1|.agri_block)",
                      "(1|.agri_wp_unit)", "(1|.agri_sp_unit)")
  }
  if (design$design == "strip_plot") {
    dat$.agri_strip_a_unit <- .interaction_key(dat, c(design$block, design$strip_a))
    dat$.agri_strip_b_unit <- .interaction_key(dat, c(design$block, design$strip_b))
    random_terms <- c("(1|.agri_block)",
                      "(1|.agri_strip_a_unit)", "(1|.agri_strip_b_unit)")
  }
  if (design$design == "multienv" && length(design$block)) {
    dat$.agri_env_block <- .interaction_key(dat, c(design$environment, design$block))
    random_terms <- c(random_terms, "(1|.agri_env_block)")
  }
  if (length(random_terms)) rhs <- paste(rhs, "+", paste(unique(random_terms), collapse = " + "))

  f <- stats::as.formula(paste(response, "~", rhs))
  z <- ARTool::art(f, data = dat, ...)
  tab <- as.data.frame(stats::anova(z))
  tab$effect <- rownames(tab); rownames(tab) <- NULL
  list(method = "Aligned Rank Transform", omnibus = tab, raw = z, formula = f,
       randomization_terms = unique(random_terms))
}

.engine_permuco <- function(design, response = NULL, np = 4999, seed = 1, rank_response = TRUE, ...) {
  .require_pkg("permuco", "permutation ANOVA/ANCOVA")
  # Nested field strata are not admissible: aovperm implements Error(subject/within),
  # not Error(block/whole_plot/subplot). On data with a true sub-plot effect,
  # aov returned p = 0.030 while permuco returned p = 0.713 on identical ranks.
  # See PERMUCO_ISOLAMENTO.md for the full investigation.
  if (design$design %in% c("split_plot", "split_split", "strip_plot")) {
    .agri_stop(sprintf(
      paste0("Method `permuco` is not admissible for the `%s` design in agriRank. ",
             "permuco::aovperm implements the repeated-measures Error() form, in which each ",
             "subject contributes one observation per within-cell. A field split-plot carries ",
             "several sub-units inside every whole plot, so the sub-plot stratum is never built ",
             "and every term is tested against an inflated whole-plot mean square. On data with ",
             "a true sub-plot effect, base aov returned p = 0.030 while permuco returned ",
             "p = 0.713 on the identical ranks. Use `method = \"ART\"`, which reproduces the ",
             "correct strata, or the native wild-bootstrap engine."),
      design$design))
  }
  response <- response %||% design$response[1L]
  dat <- design$data
  # Only the block copy survives. The whole-plot, sub-plot and strip copies used
  # to feed Error() branches for the nested field designs, which are refused
  # above; they were removed in 0.14.0 and must not be reinstated. Naming them
  # differently from the fixed-effects terms was itself part of the defect, since
  # aovperm could then match no term to any stratum at all.
  if (length(design$block)) dat$.agri_block <- .safe_factor(dat[[design$block[1L]]])
  yname <- response
  if (rank_response) {
    yname <- ".agri_rank_y"
    dat[[yname]] <- rank(dat[[response]], na.last = "keep", ties.method = "average")
  }
  rhs <- paste(.term_labels(design$formula), collapse = " + ")
  if (!nzchar(rhs)) .agri_stop("Permutation ANOVA requires at least one model term.")
  if (design$design == "rcbd" && length(design$block)) rhs <- paste(".agri_block +", rhs)
  if (design$design == "multienv" && length(design$block)) {
    dat$.agri_env_block <- .interaction_key(dat, c(design$environment, design$block))
    rhs <- paste(".agri_env_block +", rhs)
  }
  if (design$design %in% c("repeated", "longitudinal") && length(design$block)) {
    # Treat block as a nuisance term in the fixed-effects part. The repeated
    # subject/within structure is still represented by Error() below.
    rhs <- paste(".agri_block +", rhs)
  }
  if (design$design %in% c("repeated", "longitudinal") && length(design$subject) && length(design$within)) {
    dat$.agri_subject <- .subject_namespace(dat, design)
    rhs <- paste0(rhs, " + Error(.agri_subject/(", paste(design$within, collapse = "*"), "))")
  }
  # The only Error() this engine builds is the repeated-measures form above, which
  # is what aovperm actually implements. Nested field strata are refused by the
  # guard at the top of THIS function, not by fit.R: fit.R only changed which
  # engine automatic mode selects, so removing the guard here would reopen the
  # defect for anyone passing method = "permuco" explicitly. See
  # PERMUCO_ISOLAMENTO.md.
  f <- stats::as.formula(paste(yname, "~", rhs))
  z <- .seed_eval(seed, permuco::aovperm(f, data = dat, np = np, ...))
  tab <- tryCatch(as.data.frame(z$table), error = function(e) NULL)
  if (is.null(tab)) tab <- tryCatch(as.data.frame(z$anova_table), error = function(e) NULL)
  list(method = if (rank_response) "permuco permutation ANOVA on mid-ranks" else "permuco permutation ANOVA",
       omnibus = tab, raw = z, formula = f)
}

.engine_nparld <- function(design, response = NULL, alpha = 0.05, ...) {
  .require_pkg("nparLD", "rank-based longitudinal inference")
  response <- response %||% design$response[1L]
  dat <- design$data
  dat$.agri_subject <- .subject_namespace(dat, design)
  f <- stats::as.formula(paste(response, "~", paste(deparse(design$formula[[3L]]), collapse = "")), env = environment(design$formula))
  nparld_formals <- tryCatch(names(formals(nparLD::nparLD)), error = function(e) character())
  nparld_args <- list(f, data = dat, subject = ".agri_subject", alpha = alpha)
  if ("description" %in% nparld_formals) nparld_args$description <- FALSE
  if ("plot.CI" %in% nparld_formals) nparld_args$plot.CI <- FALSE
  dots <- list(...)
  if (length(dots)) nparld_args <- c(nparld_args, dots)
  z <- do.call(nparLD::nparLD, nparld_args)
  tab <- as.data.frame(z$ANOVA.test)
  tab$effect <- rownames(tab); rownames(tab) <- NULL
  list(method = "nparLD ANOVA-type rank inference", omnibus = tab,
       effects = as.data.frame(z$RTE), raw = z, formula = f)
}

.engine_manovarm_rm <- function(design, response = NULL, iter = 4999,
                                resampling = c("WildBS", "Perm", "paramBS"), seed = 1, alpha = 0.05, ...) {
  .require_pkg("MANOVA.RM", "semi-parametric repeated-measures resampling")
  resampling <- match.arg(resampling)
  response <- response %||% design$response[1L]
  dat <- design$data
  dat$.agri_subject <- .subject_namespace(dat, design)
  f <- stats::as.formula(paste(response, "~", paste(deparse(design$formula[[3L]]), collapse = "")), env = environment(design$formula))
  z <- MANOVA.RM::RM(f, data = dat, subject = ".agri_subject",
                     within = design$within, iter = iter, alpha = alpha,
                     resampling = resampling, seed = seed, ...)
  tab <- tryCatch(as.data.frame(z$ATS), error = function(e) NULL)
  list(method = paste("MANOVA.RM", resampling), omnibus = tab, raw = z, formula = f)
}
