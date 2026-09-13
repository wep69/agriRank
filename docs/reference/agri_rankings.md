# Within-block rankings and the on-farm ranking bridge

Builds the within-block rankings that every rank-based test in the
package already computes internally, summarises them by item, and
reports the pairwise record of which item was placed above which.
Accepts a measured blocked experiment or rankings supplied directly, as
from an on-farm or tricot trial.

## Usage

``` r
agri_rankings(formula, data, block,
              direction = c("higher_is_better", "lower_is_better"),
              ranked = FALSE, worth = TRUE)
```

## Arguments

- formula:

  `response ~ item`, where `response` is the measurement or, with
  `ranked = TRUE`, the rank already assigned within the block.

- data:

  Data frame in long format, one row per item per block.

- block:

  The block, farm, plot or judge inside which the ordering was made.

- direction:

  `"higher_is_better"` when a larger measurement is a better result,
  `"lower_is_better"` otherwise. Ignored when `ranked = TRUE`.

- ranked:

  The response is already a rank inside its block, with 1 the best.

- worth:

  Fit a Plackett-Luce model as a model-based companion when the
  PlackettLuce package is installed.

## Details

Two kinds of agronomic experiment produce rankings, and they meet here.

The first is the ordinary blocked trial. Every rank-based test in this
package already works on within-block ranks: Friedman and the Conover
comparisons convert the measured response into ranks inside each block
and never look at the measurements again. The ranks are therefore not a
summary of the analysis, they are the analysis, and it is worth being
able to see them.

The second is the on-farm or tricot trial, in which each farmer receives
a small subset of the varieties and returns an order rather than a
measurement. Nothing was weighed, so there is no response to analyse;
the order is the datum.

**Completeness decides which methods are admissible.** A classical
blocked trial is complete: every item appears in every block, so rank
sums are comparable and the Friedman-type machinery of
[`agri_rank`](https://wep69.github.io/agriRank/reference/agri_rank.md)
and
[`agri_conover`](https://wep69.github.io/agriRank/reference/agri_conover.md)
applies. An on-farm trial is usually incomplete: each farmer ranks three
varieties out of many. Rank sums are then not comparable, because an
item that happened to appear in favourable blocks collects flattering
ranks for a reason that has nothing to do with the item. This function
detects incompleteness, reports it, withholds `rank_sum` and warns about
`mean_rank`. The pairwise record survives, because each comparison is
made inside one block and is therefore immune to differences between
blocks.

`worth = TRUE` adds Plackett-Luce worth estimates when that package is
available. This is reported separately and labelled, because it is a
likelihood model for rankings rather than a distribution-free summary:
it assumes the rankings arise from one common worth per item, which is
what allows it to combine incomplete rankings onto a single scale. Where
the distribution-free summary and the worth estimates disagree, the
assumption is doing the work.

## Value

An object of class `agri_rankings`, a list with `summary`, `pairwise`,
`rankings`, `worth` and `completeness`.

## References

Turner, H. L., van Etten, J., Firth, D. and Kosmidis, I. (2020).
Modelling rankings in R: the PlackettLuce package. *Computational
Statistics*, 35, 1027-1057.
[doi:10.1007/s00180-020-00959-3](https://doi.org/10.1007/s00180-020-00959-3)

van Etten, J., Beza, E., Calderer, L. et al. (2019). First experiences
with a novel farmer citizen science approach. *Experimental
Agriculture*, 55(S1), 275-296.
[doi:10.1017/S0014479716000739](https://doi.org/10.1017/S0014479716000739)

## See also

[`agri_conover`](https://wep69.github.io/agriRank/reference/agri_conover.md)
and [`agri_cld`](https://wep69.github.io/agriRank/reference/agri_cld.md)
for the formal comparison of a complete blocked trial,
[`agri_rank`](https://wep69.github.io/agriRank/reference/agri_rank.md)
for the omnibus test.

## Examples

``` r
# Example 1. A complete blocked trial. The ranks shown here are the same ones
# the Friedman and Conover machinery uses internally.
set.seed(5)
d <- expand.grid(variety = factor(paste0("V", 1:5)),
                 farm = factor(paste0("F", 1:8)))
d$yield <- 3 + c(V1 = 0, V2 = 0.6, V3 = 1.1, V4 = 0.3, V5 = 1.4)[d$variety] +
  as.numeric(d$farm) * 0.2 + rnorm(nrow(d), 0, 0.5)

r <- agri_rankings(yield ~ variety, d, block = farm)
r$summary
#>   item blocks mean_rank rank_sum wins win_share
#> 1   V5      8     1.500       12    5     0.625
#> 2   V3      8     2.250       18    3     0.375
#> 3   V2      8     3.125       25    0     0.000
#> 4   V4      8     3.875       31    0     0.000
#> 5   V1      8     4.250       34    0     0.000
r$completeness
#>   blocks items observations expected_if_complete complete
#> 1      8     5           40                   40     TRUE

# Example 2. The pairwise record uses only the blocks containing both items,
# so it is immune to differences between farms.
head(r$pairwise, 4)
#>   item_a item_b blocks a_above_b b_above_a ties share_a   p_value
#> 1     V1     V2      8         2         6    0    0.25 0.2890625
#> 2     V1     V3      8         2         6    0    0.25 0.2890625
#> 3     V1     V4      8         2         6    0    0.25 0.2890625
#> 4     V1     V5      8         0         8    0    0.00 0.0078125

# Example 3. An incomplete on-farm trial, where each farmer ranked three
# varieties out of nine. Rank sums are withheld, because an item that appeared
# in favourable farms would collect flattering ranks for the wrong reason.
set.seed(9)
vars <- paste0("V", 1:9)
tri <- do.call(rbind, lapply(1:40, function(i) {
  pick <- sample(vars, 3)
  q <- c(V1 = 1, V2 = 2, V3 = 3, V4 = 1.5, V5 = 3.5,
         V6 = 2.2, V7 = 0.8, V8 = 2.8, V9 = 1.2)[pick] + rnorm(3, 0, 0.8)
  data.frame(farm = paste0("F", i), variety = pick, position = rank(-q),
             stringsAsFactors = FALSE)
}))
rt <- agri_rankings(position ~ variety, tri, block = farm, ranked = TRUE)
rt$completeness
#>   blocks items observations expected_if_complete complete
#> 1     40     9          120                  360    FALSE
rt$summary
#>   item blocks mean_rank rank_sum wins  win_share
#> 1   V5     14  1.285714       NA   10 0.71428571
#> 2   V8      9  1.444444       NA    6 0.66666667
#> 3   V3     17  1.588235       NA    8 0.47058824
#> 4   V2     13  1.692308       NA    6 0.46153846
#> 5   V6     14  1.857143       NA    6 0.42857143
#> 6   V4     15  2.266667       NA    2 0.13333333
#> 7   V1     13  2.307692       NA    1 0.07692308
#> 8   V7     14  2.714286       NA    1 0.07142857
#> 9   V9     11  2.909091       NA    0 0.00000000

# Example 4. Ranking without a block is refused, because it would compare
# items across blocks, which is what blocking exists to avoid.
res <- tryCatch(agri_rankings(yield ~ variety, d),
                error = function(e) conditionMessage(e))
cat(res, "\n")
#> `block =` is required: the farm, plot or judge inside which the ordering was made. Without it there is no unit within which the items were compared, and ranking the whole data set at once would compare items across blocks, which is what blocking exists to avoid. 

# Example 5. The figures.
p <- plot(r, type = "pairwise")
class(p)
#> [1] "ggplot2::ggplot" "ggplot"          "ggplot2::gg"     "S7_object"      
#> [5] "gg"             
```
