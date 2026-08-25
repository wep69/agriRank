# Design-aware nonparametric split-split-plot workflow

Declares three hierarchical treatment strata and routes inference
through a backend that preserves block, whole-plot and subplot
experimental units.

## Usage

``` r
np_splitsplit(formula, data, block, whole_plot, subplot, 
    subsubplot, method = "auto", ...)
```

## Arguments

- formula:

  Factorial model formula containing whole-plot, subplot and sub-subplot
  treatment factors.

- data:

  Data frame in long format.

- block:

  Blocking factor.

- whole_plot:

  Whole-plot treatment factor.

- subplot:

  Subplot treatment factor.

- subsubplot:

  Sub-subplot treatment factor.

- method:

  \`"auto"\` or \`"ART"\`. Auto selects ART when ARTool is installed;
  permuco is not admissible for nested field strata.

- ...:

  Additional backend arguments.

## Details

The declared hierarchy is block -\> whole plot -\> subplot -\>
sub-subplot. The ART adapter uses random intercepts for block,
whole-plot units, and subplot units. permuco is not admissible for this
design; see \`PERMUCO_ISOLAMENTO.md\` for the rationale.

## Value

An object of class \`agri_rank_fit\`.

## See also

`np_splitplot`, `np_stripplot`, `agri_design`

## Examples

``` r
x <- simulate_agri("split_split", seed = 1)
d <- agri_design(yield ~ irrigation * cultivar * timing, x, design = "split_split", 
    block = block, whole_plot = irrigation, subplot = cultivar, subsubplot = timing)
# Auto selects ART when ARTool is installed:
np_splitsplit(yield ~ irrigation * cultivar * timing, x, block, irrigation, cultivar, timing)
#> boundary (singular) fit: see help('isSingular')
#> boundary (singular) fit: see help('isSingular')
#> boundary (singular) fit: see help('isSingular')
#> boundary (singular) fit: see help('isSingular')
#> boundary (singular) fit: see help('isSingular')
#> boundary (singular) fit: see help('isSingular')
#> boundary (singular) fit: see help('isSingular')
#> agriRank fit
#>   Design: split_split
#>   Method: Aligned Rank Transform
#>   Response: yield
#>                         Term         F Df Df.res      Pr(>F)
#> 1                 irrigation 2.5774353  1      5 0.169304670
#> 2                   cultivar 5.9501449  2     20 0.009383259
#> 3                     timing 0.4820337  1     30 0.492844523
#> 4        irrigation:cultivar 0.2067273  2     20 0.814957369
#> 5          irrigation:timing 0.3304848  1     30 0.569660338
#> 6            cultivar:timing 0.6031332  2     30 0.553594334
#> 7 irrigation:cultivar:timing 0.2392276  2     30 0.788723107
#>                       effect
#> 1                 irrigation
#> 2                   cultivar
#> 3                     timing
#> 4        irrigation:cultivar
#> 5          irrigation:timing
#> 6            cultivar:timing
#> 7 irrigation:cultivar:timing
# Or explicitly:
if (requireNamespace("ARTool", quietly = TRUE)) np_splitsplit(yield ~ irrigation * 
    cultivar * timing, x, block, irrigation, cultivar, timing, method = "ART")
#> boundary (singular) fit: see help('isSingular')
#> boundary (singular) fit: see help('isSingular')
#> boundary (singular) fit: see help('isSingular')
#> boundary (singular) fit: see help('isSingular')
#> boundary (singular) fit: see help('isSingular')
#> boundary (singular) fit: see help('isSingular')
#> boundary (singular) fit: see help('isSingular')
#> agriRank fit
#>   Design: split_split
#>   Method: Aligned Rank Transform
#>   Response: yield
#>                         Term         F Df Df.res      Pr(>F)
#> 1                 irrigation 2.5774353  1      5 0.169304670
#> 2                   cultivar 5.9501449  2     20 0.009383259
#> 3                     timing 0.4820337  1     30 0.492844523
#> 4        irrigation:cultivar 0.2067273  2     20 0.814957369
#> 5          irrigation:timing 0.3304848  1     30 0.569660338
#> 6            cultivar:timing 0.6031332  2     30 0.553594334
#> 7 irrigation:cultivar:timing 0.2392276  2     30 0.788723107
#>                       effect
#> 1                 irrigation
#> 2                   cultivar
#> 3                     timing
#> 4        irrigation:cultivar
#> 5          irrigation:timing
#> 6            cultivar:timing
#> 7 irrigation:cultivar:timing
```
