# Shared data builders for the regression-module tests.

# Two cultivars that share the nitrogen dose response but differ in baseline
# yield by about 0.9 Mg/ha, so the cultivar coefficient and the level
# summaries are both recoverable by every route under test.
.np_make_factor_data <- function() {
  data(agri_dose, package = "agriRank")
  dz <- agri_dose
  dz$cultivar <- factor(rep(c("Ana", "Bela"), length.out = nrow(dz)))
  dz$yield <- dz$yield + ifelse(dz$cultivar == "Bela", 0.9, 0)
  dz
}
