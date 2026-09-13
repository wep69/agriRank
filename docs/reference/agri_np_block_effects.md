# Fixed and shrunk block effects side by side

Reports the effect of every declared block, as estimated by the fitted
model and by its counterpart with the other treatment of the block, so
that the amount of shrinkage is visible rather than implicit.

## Usage

``` r
agri_np_block_effects(object, compare = TRUE)
```

## Arguments

- object:

  An `agri_np_reg_fit` fitted with a `block`.

- compare:

  Refit with the other `block_effect` and report both columns. Set to
  `FALSE` to report only the fitted model.

## Details

A declared block can enter a regression in two ways, and the choice is
not cosmetic.

Fixed, the default, estimates one free effect per block. Nothing is
assumed about how blocks relate to each other, which is why this is the
classical choice for a designed experiment. Its limitation is that the
effects exist only for the blocks that were observed, so the model has
nothing to say about a new field or a new year.

Shrunk replaces those free effects by a penalized term whose block
effects are pulled towards their common mean by an amount the data
choose. A block that happens to look extreme is pulled back, because
part of its apparent difference is noise. This is what makes prediction
into an unobserved block possible at all, and it is the model-based
counterpart of
[`agri_np_conformal`](https://wep69.github.io/agriRank/reference/agri_np_conformal.md)
with `scope = "new_block"`.

Effects are computed on the response scale by predicting at one common
covariate setting and varying only the block, then centring. That works
for every engine and avoids reading basis coefficients whose meaning
depends on the smoother.

`raw` is the plain observed block mean minus the grand mean, which uses
no model at all. `shrinkage` is the proportional reduction from the
fixed estimate towards zero. A large shrinkage says the data attribute
much of the apparent between-block spread to noise; a shrinkage near
zero says the blocks really do differ and little is being borrowed.

Shrinking is a working assumption about how blocks vary, not a
parametric claim about the response curve, which stays nonparametric
either way. Inference for the curve should still come from the package's
resampling and conformal tools.

## Value

A data frame of class `agri_np_block_effects`.

## See also

[`agri_np_regression`](https://wep69.github.io/agriRank/reference/agri_np_regression.md)
for the `block_effect` argument,
[`agri_np_conformal`](https://wep69.github.io/agriRank/reference/agri_np_conformal.md)
for the assumption-free route to a new block.

## Examples

``` r
data(agri_dose)

# Example 1. Blocks that genuinely differ are barely shrunk, because the data
# say the differences are real.
fit <- agri_np_regression(yield ~ dose, agri_dose, method = "gam", block = block)
be <- agri_np_block_effects(fit)
be
#> Block effects on yield, block = `block`
#>   Model was fitted with block_effect = "fixed"
#> 
#>  block n     raw   fixed   shrunk shrinkage
#>     B1 8 -0.3573 -0.3573 -0.34028   0.04757
#>     B2 8 -0.3158 -0.3158 -0.30075   0.04757
#>     B3 8 -0.0109 -0.0109 -0.01038   0.04757
#>     B4 8  0.3247  0.3247  0.30928   0.04757
#>     B5 8  0.3592  0.3592  0.34214   0.04757
#> 
#> Mean shrinkage: 4.8%. The blocks genuinely differ; almost nothing is borrowed. 
#> 
#> Fixed effects exist only for the blocks that were observed. Shrunk
#> effects allow a prediction for a block that was not, at the price of a
#> working assumption about how blocks vary.

# Example 2. Blocks whose apparent differences are mostly noise are pulled hard
# towards the common mean.
set.seed(3)
d <- agri_dose
d$yield <- d$yield - 0.9 * (as.numeric(d$block) - 3) * 0.35 +
  rnorm(nrow(d), 0, 0.9)
f2 <- agri_np_regression(yield ~ dose, d, method = "gam", block = block)
agri_np_block_effects(f2)
#> Block effects on yield, block = `block`
#>   Model was fitted with block_effect = "fixed"
#> 
#>  block n     raw   fixed     shrunk shrinkage
#>     B1 8  0.2429  0.2429  2.177e-05    0.9999
#>     B2 8 -0.2249 -0.2249 -2.015e-05    0.9999
#>     B3 8 -0.3612 -0.3612 -3.236e-05    0.9999
#>     B4 8  0.2286  0.2286  2.048e-05    0.9999
#>     B5 8  0.1146  0.1146  1.027e-05    0.9999
#> 
#> Mean shrinkage: 100%. Most of the apparent spread between blocks is treated as noise. 
#> 
#> Fixed effects exist only for the blocks that were observed. Shrunk
#> effects allow a prediction for a block that was not, at the price of a
#> working assumption about how blocks vary.

# Example 3. The figure shows how far each block travels between the two
# treatments of the block term.
p <- plot(be)
class(p)
#> [1] "ggplot2::ggplot" "ggplot"          "ggplot2::gg"     "S7_object"      
#> [5] "gg"             

# Example 4. A fit without a block has no block effects, and says so.
f3 <- agri_np_regression(yield ~ dose, agri_dose, method = "gam")
res <- tryCatch(agri_np_block_effects(f3), error = function(e) conditionMessage(e))
cat(res, "\n")
#> This fit declares no block, so there are no block effects to report. Refit with `block =` naming the blocking variable. 
```
