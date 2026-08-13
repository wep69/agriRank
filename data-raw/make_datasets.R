# Generates the three exported example datasets. Run from the package root:
#   source("data-raw/make_datasets.R")
# The seeds are fixed, so the files are reproducible.

dir.create("data", showWarnings = FALSE)

## ---------------------------------------------------------------------------
## agri_dose: nitrogen response in a randomized complete block design.
## Quadratic-plateau shape, classical in fertilizer trials.
## ---------------------------------------------------------------------------
set.seed(2026001)
agri_dose <- expand.grid(block = factor(paste0("B", 1:5)),
                         dose = seq(0, 280, by = 40),
                         KEEP.OUT.ATTRS = FALSE)
block_effect <- c(B1 = -0.45, B2 = -0.20, B3 = 0.05, B4 = 0.25, B5 = 0.35)
plateau <- 200
mu <- 3.1 + 0.0182 * pmin(agri_dose$dose, plateau) -
  0.0000362 * pmin(agri_dose$dose, plateau)^2
agri_dose$yield <- round(mu + block_effect[as.character(agri_dose$block)] +
                           stats::rnorm(nrow(agri_dose), 0, 0.24), 3)
agri_dose <- agri_dose[order(agri_dose$block, agri_dose$dose),
                       c("block", "dose", "yield")]
rownames(agri_dose) <- NULL

## ---------------------------------------------------------------------------
## agri_density: plants per hill, an integer agronomic decision.
## Increase then decrease, the usual density response through competition.
## ---------------------------------------------------------------------------
set.seed(2026002)
agri_density <- expand.grid(block = factor(paste0("B", 1:6)),
                            plants = 1:9,
                            KEEP.OUT.ATTRS = FALSE)
bd <- c(B1 = -0.30, B2 = -0.18, B3 = -0.05, B4 = 0.07, B5 = 0.18, B6 = 0.28)
peak <- 6
mu <- 2.4 + 1.05 * pmin(agri_density$plants, peak) -
  0.082 * pmin(agri_density$plants, peak)^2 -
  0.28 * pmax(agri_density$plants - peak, 0)
agri_density$yield <- round(mu + bd[as.character(agri_density$block)] +
                              stats::rnorm(nrow(agri_density), 0, 0.21), 3)
agri_density <- agri_density[order(agri_density$block, agri_density$plants),
                             c("block", "plants", "yield")]
rownames(agri_density) <- NULL

## ---------------------------------------------------------------------------
## agri_surface: two quantitative gradients, nitrogen and irrigation depth.
## ---------------------------------------------------------------------------
set.seed(2026003)
agri_surface <- expand.grid(block = factor(paste0("B", 1:2)),
                            nitrogen = seq(0, 240, by = 40),
                            water = seq(0.4, 1.2, by = 0.2),
                            KEEP.OUT.ATTRS = FALSE)
bs <- c(B1 = -0.12, B2 = 0.12)
mu <- 2.0 + 0.0165 * agri_surface$nitrogen - 0.0000402 * agri_surface$nitrogen^2 +
  3.10 * agri_surface$water - 1.55 * agri_surface$water^2 +
  0.0042 * agri_surface$nitrogen * agri_surface$water
agri_surface$yield <- round(mu + bs[as.character(agri_surface$block)] +
                              stats::rnorm(nrow(agri_surface), 0, 0.20), 3)
agri_surface <- agri_surface[order(agri_surface$block, agri_surface$nitrogen,
                                   agri_surface$water),
                             c("block", "nitrogen", "water", "yield")]
rownames(agri_surface) <- NULL

save(agri_dose, file = "data/agri_dose.rda", version = 2, compress = "xz")
save(agri_density, file = "data/agri_density.rda", version = 2, compress = "xz")
save(agri_surface, file = "data/agri_surface.rda", version = 2, compress = "xz")

message("agri_dose: ", nrow(agri_dose), " rows")
message("agri_density: ", nrow(agri_density), " rows")
message("agri_surface: ", nrow(agri_surface), " rows")
