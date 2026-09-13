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
# Or explicitly:
if (requireNamespace("ARTool", quietly = TRUE)) np_stripplot(yield ~ irrigation * 
    nitrogen, x, block, irrigation, nitrogen, method = "ART")
```
