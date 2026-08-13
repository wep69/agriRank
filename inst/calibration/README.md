# agriRank calibration studies

Type-I error and power calibration for the design-aware engines and for the
native incomplete repeated-measures engine.

**These scripts are deliberately excluded from `R CMD check`.** They are a
simulation study, not a unit test, and a full run takes hours to days.

## Layout

```
inst/calibration/
  README.md                this file
  calib-core.R             scenario definitions, RNG management, runner
  run-calibration.R        command-line entry point
  results/                 RDS chunks, one per scenario (created on first run)
```

## How to run

From the package root, in a plain R session:

```r
source("inst/calibration/run-calibration.R")
```

Or from the shell, choosing replicates, cores and scenarios:

```
Rscript inst/calibration/run-calibration.R --R=10000 --cores=8
Rscript inst/calibration/run-calibration.R --R=500 --cores=4 --scenarios=split_split,strip_plot
Rscript inst/calibration/run-calibration.R --R=10000 --resume
```

## Reproducibility

Each replicate `i` of each scenario receives its own L'Ecuyer-CMRG substream,
advanced deterministically from a fixed master seed. The result of replicate `i`
therefore does **not** depend on the number of cores, on the order of execution,
or on whether the run was resumed from a previous chunk. This is what makes the
study auditable: `seed_master` plus the replicate index reproduce any single
experiment exactly.

## Resuming

Results are written incrementally to `results/<scenario>.rds` after every chunk.
Re-running with `--resume` reads what is already on disk, computes only the
missing replicates and appends them. A run interrupted by a reboot loses at most
one chunk.

## Acceptance criterion

Under H0 with `R` replicates, the Monte Carlo standard error of an empirical
rejection rate at nominal level `alpha` is `sqrt(alpha * (1 - alpha) / R)`.
For `alpha = 0.05`:

| R      | MC standard error | 95% acceptance interval |
|--------|-------------------|-------------------------|
| 500    | 0.00975           | [0.0309, 0.0691]        |
| 1000   | 0.00689           | [0.0365, 0.0635]        |
| 10000  | 0.00218           | [0.0457, 0.0543]        |

A rate outside the interval is evidence of miscalibration, not of Monte Carlo
noise. **A 500-replicate pilot only detects gross miscalibration.** No claim
about calibration should be published from fewer than 10000 replicates per
scenario, as required by section 10 of the verification protocol.
