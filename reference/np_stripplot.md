# Design-aware nonparametric strip-plot workflow

Declares two perpendicular strip treatment factors and preserves their
distinct block-by-strip error strata.

## Usage

``` r
np_stripplot(formula, data, block, strip_a, strip_b, method = "auto", ...)
```

## Arguments

- formula:

  Factorial model formula containing the two strip treatment factors.

- data:

  Data frame in long format.

- block:

  Blocking factor.

- strip_a:

  First strip treatment factor.

- strip_b:

  Second perpendicular strip treatment factor.

- method:

  \`"auto"\` or \`"ART"\`. Auto prefers ARTool when available; permuco
  is not admissible for strip-plots.

- ...:

  Additional backend arguments.

## Details

The ART adapter represents random block, block-by-strip-A and
block-by-strip-B terms. permuco is not admissible for this design; see
\`PERMUCO_ISOLAMENTO.md\` for the rationale.

## Value

An object of class \`agri_rank_fit\`.

## See also

`np_splitplot`, `np_splitsplit`, `agri_design`

## Examples

``` r
x <- simulate_agri("strip_plot", seed = 2)
d <- agri_design(yield ~ irrigation * nitrogen, x, design = "strip_plot", 
    block = block, strip_a = irrigation, strip_b = nitrogen)
# Auto selects ART when ARTool is installed:
np_stripplot(yield ~ irrigation * nitrogen, x, block, irrigation, nitrogen)
#> boundary (singular) fit: see help('isSingular')
#> boundary (singular) fit: see help('isSingular')
#> agriRank fit
#>   Design: strip_plot
#>   Method: Aligned Rank Transform
#>   Response: yield
#>                  Term         F Df Df.res       Pr(>F)              effect
#> 1          irrigation 39.563035  2     10 1.778182e-05          irrigation
#> 2            nitrogen  2.493754  3     15 9.964232e-02            nitrogen
#> 3 irrigation:nitrogen  4.069144  6     30 4.213868e-03 irrigation:nitrogen
# Or explicitly:
if (requireNamespace("ARTool", quietly = TRUE)) np_stripplot(yield ~ irrigation * 
    nitrogen, x, block, irrigation, nitrogen, method = "ART")
#> boundary (singular) fit: see help('isSingular')
#> boundary (singular) fit: see help('isSingular')
#> agriRank fit
#>   Design: strip_plot
#>   Method: Aligned Rank Transform
#>   Response: yield
#>                  Term         F Df Df.res       Pr(>F)              effect
#> 1          irrigation 39.563035  2     10 1.778182e-05          irrigation
#> 2            nitrogen  2.493754  3     15 9.964232e-02            nitrogen
#> 3 irrigation:nitrogen  4.069144  6     30 4.213868e-03 irrigation:nitrogen
```
