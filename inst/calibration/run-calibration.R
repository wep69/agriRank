# ---------------------------------------------------------------------------
# Entry point for the agriRank calibration study.
#
#   Rscript inst/calibration/run-calibration.R --R=10000 --cores=8
#   Rscript inst/calibration/run-calibration.R --R=500 --cores=4 --scenarios=strip_plot_ART
#   Rscript inst/calibration/run-calibration.R --R=10000 --resume
# ---------------------------------------------------------------------------

suppressPackageStartupMessages(library(agriRank))

.cal_here <- function() {
  a <- commandArgs(trailingOnly = FALSE)
  f <- sub("^--file=", "", a[grep("^--file=", a)])
  if (length(f)) dirname(normalizePath(f)) else file.path(getwd(), "inst", "calibration")
}
CAL_DIR <- .cal_here()
source(file.path(CAL_DIR, "calib-core.R"))

args <- commandArgs(trailingOnly = TRUE)
getopt <- function(name, default) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (!length(hit)) return(default)
  sub(paste0("^--", name, "="), "", hit[1])
}

R        <- as.integer(getopt("R", "500"))
cores    <- as.integer(getopt("cores", max(1L, parallel::detectCores() - 1L)))
chunk    <- as.integer(getopt("chunk", "50"))
resume   <- ("--resume" %in% args) || identical(getopt("resume", "TRUE"), "TRUE")
outdir   <- getopt("out", file.path(CAL_DIR, "results"))
wanted   <- getopt("scenarios", "")

scen <- cal_scenarios()
if (nzchar(wanted)) {
  keep <- trimws(strsplit(wanted, ",")[[1]])
  scen <- scen[intersect(names(scen), keep)]
}

message("=====================================================================")
message(sprintf("agriRank calibration | R = %d | cores = %d | scenarios = %d",
                R, cores, length(scen)))
message(sprintf("results: %s", outdir))
if (R < 10000L) {
  message("")
  message("*** WARNING: this is a PILOT run. ***")
  message(sprintf("With R = %d the Monte Carlo standard error at alpha = 0.05 is %.5f,",
                  R, sqrt(0.05 * 0.95 / R)))
  message(sprintf("so only rates outside [%.4f, %.4f] are distinguishable from noise.",
                  0.05 - 1.96 * sqrt(0.05 * 0.95 / R),
                  0.05 + 1.96 * sqrt(0.05 * 0.95 / R)))
  message("A pilot detects gross miscalibration only. Section 10 of the")
  message("verification protocol requires at least 10000 replicates per scenario")
  message("before any calibration claim is made.")
  message("")
}
message("=====================================================================")

t0 <- Sys.time()
for (nm in names(scen)) {
  message(sprintf("--- %s: %s", nm, scen[[nm]]$label))
  cal_run_scenario(nm, scen[[nm]], R = R, cores = cores, chunk = chunk,
                   dir = outdir, resume = resume)
}
message(sprintf("total elapsed: %.1f min",
                as.numeric(difftime(Sys.time(), t0, units = "mins"))))

s <- cal_summarise(outdir)
if (!is.null(s)) {
  message("\n=== Type-I error summary ===")
  print(s, row.names = FALSE, digits = 4)
  utils::write.csv(s, file.path(outdir, "type1_summary.csv"), row.names = FALSE)
  bad <- subset(s, alpha == 0.05 & !calibrated)
  if (nrow(bad)) {
    message("\nOutside the 95% Monte Carlo interval at alpha = 0.05:")
    print(bad[, c("scenario", "term", "replicates", "rejection_rate", "lower", "upper")],
          row.names = FALSE, digits = 4)
  } else {
    message("\nNo scenario is outside the Monte Carlo interval at alpha = 0.05.")
  }
  if (R < 10000L) {
    message("\nReminder: pilot resolution. Re-run with --R=10000 before reporting.")
  }
}
