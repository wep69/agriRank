# ---------------------------------------------------------------------------
# agriRank calibration core
#
# Scenario definitions, reproducible RNG substreams, parallel execution with
# incremental checkpointing, and the Monte Carlo acceptance criterion.
#
# Nothing here is exported by the package. This file is sourced by
# run-calibration.R.
# ---------------------------------------------------------------------------

CAL_SEED_MASTER <- 20260812L
CAL_ALPHAS <- c(0.01, 0.05, 0.10)

# --- RNG -------------------------------------------------------------------
# One L'Ecuyer-CMRG substream per replicate, advanced deterministically from
# the master seed. Replicate i is reproducible regardless of core count,
# execution order, or whether the run was resumed.
cal_seed_for <- function(i, master = CAL_SEED_MASTER) {
  set.seed(master, kind = "L'Ecuyer-CMRG")
  s <- .Random.seed
  if (i > 1L) for (k in seq_len(i - 1L)) s <- parallel::nextRNGStream(s)
  s
}

cal_with_seed <- function(i, expr, master = CAL_SEED_MASTER) {
  old <- if (exists(".Random.seed", .GlobalEnv)) get(".Random.seed", .GlobalEnv) else NULL
  on.exit({
    if (is.null(old)) rm(".Random.seed", envir = .GlobalEnv)
    else assign(".Random.seed", old, envir = .GlobalEnv)
  }, add = TRUE)
  assign(".Random.seed", cal_seed_for(i, master), envir = .GlobalEnv)
  force(expr)
}

# --- Data generators under H0 ----------------------------------------------
# Every generator produces data in which the tested factors have no effect.
# Block, whole-plot, subplot and subject variation is real; treatment effects
# are zero. The nuisance structure must be present, otherwise a test can look
# calibrated simply because there is nothing for it to get wrong.

gen_split_split <- function(nb = 4L, sd_b = 1.0, sd_wp = 0.8, sd_sp = 0.6, sd_e = 1.0) {
  d <- expand.grid(block = factor(seq_len(nb)),
                   irrigation = factor(c("low", "high")),
                   cultivar = factor(c("C1", "C2", "C3")),
                   timing = factor(c("early", "late")),
                   KEEP.OUT.ATTRS = FALSE, stringsAsFactors = TRUE)
  b <- stats::rnorm(nlevels(d$block), 0, sd_b)
  wp <- stats::rnorm(nb * 2L, 0, sd_wp)
  sp <- stats::rnorm(nb * 2L * 3L, 0, sd_sp)
  d$wp_id <- interaction(d$block, d$irrigation, drop = TRUE)
  d$sp_id <- interaction(d$block, d$irrigation, d$cultivar, drop = TRUE)
  d$yield <- b[as.integer(d$block)] +
    wp[as.integer(d$wp_id)] +
    sp[as.integer(d$sp_id)] +
    stats::rnorm(nrow(d), 0, sd_e)
  d
}

gen_strip_plot <- function(nb = 5L, sd_b = 1.0, sd_a = 0.8, sd_bb = 0.8, sd_e = 1.0) {
  d <- expand.grid(block = factor(seq_len(nb)),
                   irrigation = factor(c("I1", "I2", "I3")),
                   nitrogen = factor(c("N1", "N2", "N3")),
                   KEEP.OUT.ATTRS = FALSE, stringsAsFactors = TRUE)
  d$a_id <- interaction(d$block, d$irrigation, drop = TRUE)
  d$b_id <- interaction(d$block, d$nitrogen, drop = TRUE)
  b <- stats::rnorm(nlevels(d$block), 0, sd_b)
  ra <- stats::rnorm(nlevels(d$a_id), 0, sd_a)
  rb <- stats::rnorm(nlevels(d$b_id), 0, sd_bb)
  d$yield <- b[as.integer(d$block)] + ra[as.integer(d$a_id)] +
    rb[as.integer(d$b_id)] + stats::rnorm(nrow(d), 0, sd_e)
  d
}

gen_repeated_missing <- function(n_sub = 20L, n_time = 4L, missing_rate = 0.15,
                                 sd_sub = 1.0, sd_e = 1.0, ordinal = FALSE,
                                 hetero = FALSE) {
  grp <- factor(rep(c("control", "treated"), each = n_sub / 2L))
  d <- expand.grid(subject = factor(seq_len(n_sub)), time = factor(seq_len(n_time)),
                   KEEP.OUT.ATTRS = FALSE, stringsAsFactors = TRUE)
  d$treatment <- grp[as.integer(d$subject)]
  u <- stats::rnorm(n_sub, 0, sd_sub)
  s <- if (hetero) ifelse(d$treatment == "treated", sd_e * 2, sd_e) else sd_e
  d$height <- u[as.integer(d$subject)] + stats::rnorm(nrow(d), 0, s)
  if (ordinal) d$height <- as.numeric(cut(d$height, breaks = 5L, labels = FALSE))
  if (missing_rate > 0) {
    drop <- stats::runif(nrow(d)) < missing_rate
    d$height[drop] <- NA_real_
  }
  d
}

# --- p-value extraction -----------------------------------------------------
cal_pvalues <- function(fit, terms) {
  tab <- fit$omnibus
  if (is.null(tab)) return(stats::setNames(rep(NA_real_, length(terms)), terms))
  tab <- as.data.frame(tab)
  lab <- if ("effect" %in% names(tab)) as.character(tab$effect) else rownames(tab)
  lab <- trimws(gsub("\\s+", "", lab))
  # Backends name their p-value column differently. Resampling-based columns
  # come first: they are the inference the engine actually performs.
  prefer <- c("p_boot", "resampled P(>F)", "p_value", "p-Value", "p.value",
              "pvalue", "Pr(>F)", "parametric P(>F)", "p_asymptotic")
  nm <- names(tab)
  hit <- prefer[tolower(prefer) %in% tolower(nm)]
  if (!length(hit)) {
    cand <- nm[grepl("p[-_. ]?val|^p$|pr\\(>", tolower(nm))]
    if (!length(cand)) return(stats::setNames(rep(NA_real_, length(terms)), terms))
    hit <- cand[1]
  }
  col <- nm[match(tolower(hit[1]), tolower(nm))]
  p <- suppressWarnings(as.numeric(tab[[col]]))
  out <- vapply(terms, function(tt) {
    i <- match(gsub("\\s+", "", tt), lab)
    if (is.na(i)) NA_real_ else p[i]
  }, numeric(1))
  stats::setNames(out, terms)
}

# The native engine consumes a declared design, not a raw formula.
cal_wild <- function(missing_rate, ordinal = FALSE, hetero = FALSE, B = 499L) {
  d <- gen_repeated_missing(missing_rate = missing_rate, ordinal = ordinal,
                            hetero = hetero)
  des <- agriRank::agri_design(height ~ treatment * time, d, design = "repeated",
                               subject = subject, within = time)
  f <- suppressWarnings(
    agriRank::incomplete_wild_rank_test(des, B = B, statistic = "ATS",
                                        missing_assumption = "MCAR",
                                        seed = sample.int(.Machine$integer.max, 1L))
  )
  cal_pvalues(f, c("treatment", "time", "treatment:time"))
}

# --- Scenarios --------------------------------------------------------------
# Each scenario is one (data generator, analysis, tested terms) triple.
cal_scenarios <- function() {
  list(
    split_split_ART = list(
      label = "Split-split-plot, ART, H0 in all three strata",
      terms = c("irrigation", "cultivar", "timing"),
      needs = "ARTool",
      run = function() {
        d <- gen_split_split()
        f <- agriRank::np_splitsplit(yield ~ irrigation * cultivar * timing, d,
                                     block = block, whole_plot = irrigation,
                                     subplot = cultivar, subsubplot = timing,
                                     method = "ART")
        cal_pvalues(f, c("irrigation", "cultivar", "timing"))
      }
    ),
    split_split_permuco = list(
      label = "Split-split-plot, permuco, H0 in all three strata",
      terms = c("irrigation", "cultivar", "timing"),
      needs = "permuco",
      run = function() {
        d <- gen_split_split()
        f <- agriRank::np_splitsplit(yield ~ irrigation * cultivar * timing, d,
                                     block = block, whole_plot = irrigation,
                                     subplot = cultivar, subsubplot = timing,
                                     method = "permuco", np = 999)
        cal_pvalues(f, c("irrigation", "cultivar", "timing"))
      }
    ),
    strip_plot_ART = list(
      label = "Strip-plot, ART, H0 for A, B and A:B",
      terms = c("irrigation", "nitrogen", "irrigation:nitrogen"),
      needs = "ARTool",
      run = function() {
        d <- gen_strip_plot()
        f <- agriRank::np_stripplot(yield ~ irrigation * nitrogen, d, block = block,
                                    strip_a = irrigation, strip_b = nitrogen,
                                    method = "ART")
        cal_pvalues(f, c("irrigation", "nitrogen", "irrigation:nitrogen"))
      }
    ),
    strip_plot_permuco = list(
      label = "Strip-plot, permuco, H0 for A, B and A:B",
      terms = c("irrigation", "nitrogen", "irrigation:nitrogen"),
      needs = "permuco",
      run = function() {
        d <- gen_strip_plot()
        f <- agriRank::np_stripplot(yield ~ irrigation * nitrogen, d, block = block,
                                    strip_a = irrigation, strip_b = nitrogen,
                                    method = "permuco", np = 999)
        cal_pvalues(f, c("irrigation", "nitrogen", "irrigation:nitrogen"))
      }
    ),
    incomplete_wild_15 = list(
      label = "Native wild-bootstrap engine, 15% missing, Gaussian",
      terms = c("treatment", "time", "treatment:time"),
      needs = NULL,
      run = function() cal_wild(missing_rate = 0.15)
    ),
    incomplete_wild_30 = list(
      label = "Native wild-bootstrap engine, 30% missing, Gaussian",
      terms = c("treatment", "time", "treatment:time"),
      needs = NULL,
      run = function() cal_wild(missing_rate = 0.30)
    ),
    incomplete_wild_ordinal = list(
      label = "Native wild-bootstrap engine, ordinal response with ties",
      terms = c("treatment", "time", "treatment:time"),
      needs = NULL,
      run = function() cal_wild(missing_rate = 0.15, ordinal = TRUE)
    ),
    incomplete_wild_hetero = list(
      label = "Native wild-bootstrap engine, heteroscedastic groups",
      terms = c("treatment", "time", "treatment:time"),
      needs = NULL,
      run = function() cal_wild(missing_rate = 0.15, hetero = TRUE)
    )
  )
}

# --- Runner -----------------------------------------------------------------
cal_result_file <- function(scenario, dir) file.path(dir, paste0(scenario, ".rds"))

cal_run_scenario <- function(name, spec, R, cores = 1L, chunk = 50L,
                             dir = "inst/calibration/results", resume = TRUE,
                             quiet = FALSE) {
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  fpath <- cal_result_file(name, dir)

  done <- if (resume && file.exists(fpath)) readRDS(fpath) else NULL
  have <- if (is.null(done)) integer(0) else done$replicate
  todo <- setdiff(seq_len(R), have)
  if (!length(todo)) {
    if (!quiet) message(sprintf("[%s] already complete (%d replicates)", name, R))
    return(invisible(done))
  }
  if (!is.null(spec$needs) && !requireNamespace(spec$needs, quietly = TRUE)) {
    if (!quiet) message(sprintf("[%s] skipped, package '%s' not installed", name, spec$needs))
    return(invisible(NULL))
  }

  one <- function(i) {
    out <- cal_with_seed(i, tryCatch(spec$run(), error = function(e) {
      stats::setNames(rep(NA_real_, length(spec$terms)), spec$terms)
    }))
    c(replicate = i, out)
  }

  cl <- NULL
  if (cores > 1L) {
    cl <- parallel::makeCluster(cores)
    on.exit(parallel::stopCluster(cl), add = TRUE)
    parallel::clusterEvalQ(cl, {
      suppressPackageStartupMessages(library(agriRank))
      NULL
    })
    parallel::clusterExport(cl, varlist = c("cal_seed_for", "cal_with_seed",
                                            "cal_pvalues", "cal_wild",
                                            "gen_split_split", "gen_strip_plot",
                                            "gen_repeated_missing", "CAL_SEED_MASTER"),
                            envir = environment(cal_run_scenario))
  }

  t0 <- Sys.time()
  chunks <- split(todo, ceiling(seq_along(todo) / chunk))
  for (k in seq_along(chunks)) {
    idx <- chunks[[k]]
    res <- if (is.null(cl)) lapply(idx, one) else parallel::parLapply(cl, idx, one)
    part <- as.data.frame(do.call(rbind, res))
    done <- if (is.null(done)) part else rbind(done, part)
    done <- done[order(done$replicate), , drop = FALSE]
    saveRDS(done, fpath)  # checkpoint: a crash loses at most one chunk
    if (!quiet) {
      el <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
      n_ok <- sum(!is.na(done[[spec$terms[1]]]))
      message(sprintf("[%s] %d/%d replicates, %.0fs elapsed, %.2fs per replicate, %d valid",
                      name, nrow(done), R, el, el / length(unlist(chunks[seq_len(k)])), n_ok))
    }
  }
  invisible(done)
}

# --- Summary and acceptance -------------------------------------------------
cal_summarise <- function(dir = "inst/calibration/results", alphas = CAL_ALPHAS) {
  fs <- list.files(dir, pattern = "[.]rds$", full.names = TRUE)
  if (!length(fs)) return(NULL)
  out <- list()
  for (f in fs) {
    d <- readRDS(f)
    scen <- tools::file_path_sans_ext(basename(f))
    terms <- setdiff(names(d), "replicate")
    for (tt in terms) {
      p <- d[[tt]]
      p <- p[is.finite(p)]
      R <- length(p)
      for (a in alphas) {
        rate <- mean(p <= a)
        se <- sqrt(a * (1 - a) / R)
        out[[length(out) + 1L]] <- data.frame(
          scenario = scen, term = tt, alpha = a, replicates = R,
          rejection_rate = rate,
          mc_se = se,
          lower = a - 1.96 * se, upper = a + 1.96 * se,
          calibrated = rate >= a - 1.96 * se & rate <= a + 1.96 * se,
          stringsAsFactors = FALSE
        )
      }
    }
  }
  res <- do.call(rbind, out)
  res[order(res$scenario, res$term, res$alpha), ]
}
