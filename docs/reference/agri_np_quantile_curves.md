# Smooth conditional quantile curves

Fits one smooth curve per requested quantile of the response, and
reports the curves, their spread and how the spread changes along the
gradient.

## Usage

``` r
agri_np_quantile_curves(formula, data = NULL,
                        quantiles = c(0.1, 0.25, 0.5, 0.75, 0.9),
                        block = NULL, block_effect = c("fixed", "shrunk"),
                        k = 10L, n = 100L, fixed = list(),
                        gam_structure = c("additive", "tensor", "varying"))
```

## Arguments

- formula:

  Regression formula, or an `agri_np_reg_fit` whose formula, data, block
  and settings are reused.

- data:

  Data frame. Not needed when `formula` is a fitted object.

- quantiles:

  Quantiles to fit.

- block:

  Optional block variable, as in
  [`agri_np_regression`](https://wep69.github.io/agriRank/reference/agri_np_regression.md).

- block_effect:

  `"fixed"` or `"shrunk"`.

- k:

  Basis dimension for each smooth.

- n:

  Grid size for the reported curves.

- fixed:

  Values at which other covariates are held.

- gam_structure:

  Passed to
  [`agri_np_regression`](https://wep69.github.io/agriRank/reference/agri_np_regression.md).

## Details

Every other curve in this package describes a central tendency, which is
a strong restriction on the agronomic question it can answer. A
fertilizer, a cultivar or an irrigation schedule can lift the good plots
without lifting the poor ones. The mean response then rises, and a
recommendation based on it will disappoint exactly the growers whose
fields resemble the poor plots.

Two readings follow from the fan of curves. The low quantile is the
exposure curve, what a grower meets in a bad year. The distance between
the outer quantiles is the risk, and a treatment that widens it is
buying its average gain with variability.

Each quantile is fitted independently, so the curves can cross where the
data are thin. Crossings are counted and reported rather than silently
repaired, because a crossing is evidence that the quantiles are not
separately identified in that part of the gradient.

`coverage` is the share of observed plots at or below each fitted curve
and should sit near the quantile itself; `deviation` is the gap and
`tracking` flags a gap above 0.1. It is measured on the fitting data, so
it is optimistic, which makes a large gap all the more telling.

Nothing here assumes a distribution for the response. The pinball loss
defines the quantile directly and the smoothness of each curve is chosen
by the data.

## Value

An object of class `agri_np_quantile_curves`, a list with components
`curves`, `summary`, `spread`, `crossings` and `fits`.

## References

Fasiolo, M., Wood, S. N., Zaffran, M., Nedellec, R. and Goude, Y.
(2021). Fast calibrated additive quantile regression. *Journal of the
American Statistical Association*, 116(535), 1402-1412.
[doi:10.1080/01621459.2020.1725521](https://doi.org/10.1080/01621459.2020.1725521)

Koenker, R. (2005). *Quantile Regression*. Cambridge University Press.

## See also

[`agri_np_regression`](https://wep69.github.io/agriRank/reference/agri_np_regression.md)
with `method = "smooth_quantile"` for a single quantile,
[`agri_np_conformal`](https://wep69.github.io/agriRank/reference/agri_np_conformal.md)
for an interval covering a future plot.

## Examples

``` r
data(agri_dose)

# Example 1. One quantile at a time. The 10th percentile is the exposure curve:
# what a grower meets in a poor plot, which the median does not describe.
q10 <- agri_np_regression(yield ~ dose, agri_dose, method = "smooth_quantile",
                          tau = 0.10, block = block)
q50 <- agri_np_regression(yield ~ dose, agri_dose, method = "smooth_quantile",
                          tau = 0.50, block = block)
nd <- data.frame(dose = c(80, 160, 240),
                 block = factor("B3", levels = levels(agri_dose$block)))
data.frame(dose = nd$dose,
           q10 = as.numeric(agri_np_predict(q10, nd)),
           q50 = as.numeric(agri_np_predict(q50, nd)))

# Example 2. A fan of quantiles on an experiment with variability that grows
# with the rate. The spread widens, so the treatment raises the level and the
# risk together.
set.seed(11)
d <- do.call(rbind, lapply(1:12, function(b) {
  z <- agri_dose[agri_dose$block == "B1", c("dose", "yield")]
  z$block <- factor(paste0("B", b), levels = paste0("B", 1:12))
  z$yield <- z$yield + rnorm(nrow(z), 0, 0.10 + 0.006 * z$dose)
  z
}))
qc <- agri_np_quantile_curves(yield ~ dose, d, block = block, n = 40)
qc$summary

# Example 3. The spread itself, which is the quantity to read when asking
# whether an average gain was bought with variability.
head(qc$spread)
p <- plot(qc, type = "spread")
class(p)

# Example 4. A quantile too far into the tail for the replication available is
# refused rather than fitted from two or three plots.
res <- tryCatch(agri_np_quantile_curves(yield ~ dose, d, quantiles = c(0.01, 0.99)),
                error = function(e) conditionMessage(e))
cat(res, "\n")
```
