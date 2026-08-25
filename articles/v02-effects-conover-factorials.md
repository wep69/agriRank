# Effects, Conover, Contrasts, and Factorial Inference

**Comparison vignette** **Package:** `agriRank` **Version targeted:**
`0.14.0` **Owns:** what happens after a significant omnibus test.
Effects, design-aware pairwise comparisons, compact letter displays,
factorial decomposition, and simple effects.

------------------------------------------------------------------------

## 1. Why this vignette exists

An omnibus test answers one question, and it is rarely the question the
experiment was designed to answer. “Some treatments differ” is not a
recommendation, a variety release decision, or a management guideline.

Everything that follows the omnibus test, however, is where the
multiplicity problems live, where compact letters are most often
over-read, and where the distinction between “not detected” and “equal”
collapses in practice.

This vignette owns that territory. Its organising rule:

> **A comparison is admissible only in the stratum where the
> randomization made it. Report the size of a difference alongside the
> decision about it, always.**

### 1.1 What comes before and after

| Stage | Where |
|----|----|
| declaring and validating the design | *Design Foundations, CRD, and RCBD* |
| hierarchical plot strata | *Hierarchical Plot Designs, Trends, ANCOVA, and Power* |
| quantitative treatments as curves | *Nonparametric and Shape-Aware Regression* |
| tables and figures for the comparisons | *Graphics, Tables, Reports, and Reproducibility* |

------------------------------------------------------------------------

## 2. Learning objectives

After working through this vignette, the reader should be able to:

1.  explain why a post-hoc procedure is chosen by the design and not by
    habit;
2.  distinguish the Kruskal-type Conover procedure from the
    Friedman-type one, and say which layout each requires;
3.  recognise when a complete-block post-hoc procedure must be refused,
    and what to do instead;
4.  interpret a probability-of-superiority effect and state its scale;
5.  choose a multiplicity adjustment and defend the choice;
6.  read a compact letter display correctly, and explain to a co-author
    what sharing a letter does not mean;
7.  decompose a factorial into main effects and interaction, and say why
    a one-way test on the cells is a different analysis;
8.  choose among pseudo-rank, aligned-rank and permutation engines on
    structural grounds;
9.  run a sensitivity analysis across those engines and interpret
    disagreement;
10. follow a detected interaction with simple effects that answer a
    stated biological question, rather than with every comparison the
    software can produce;
11. assemble a reportable comparison section that a reviewer can check.

------------------------------------------------------------------------

## 3. The comparison module in one map

| Function | Answers | Requires |
|----|----|----|
| [`agri_effects()`](https://wep69.github.io/agriRank/reference/agri_effects.md) | how large, per treatment cell | a fitted object |
| [`agri_pairs()`](https://wep69.github.io/agriRank/reference/agri_pairs.md) | which pairs differ, generically | a fitted object |
| [`agri_conover()`](https://wep69.github.io/agriRank/reference/agri_conover.md) | which pairs differ, in the design’s own stratum | a compatible layout |
| [`agri_cld()`](https://wep69.github.io/agriRank/reference/agri_cld.md) | a compact summary for a figure | a complete family of comparisons |
| [`agri_contrast()`](https://wep69.github.io/agriRank/reference/agri_contrast.md) | one planned question | a supporting engine |
| [`agri_sensitivity()`](https://wep69.github.io/agriRank/reference/agri_sensitivity.md) | does the conclusion survive another engine | a fitted object |

### 3.1 The order in which to read the output

``` r

data.frame(
  read = 1:5,
  what = c("omnibus", "interaction", "effect sizes", "pairwise", "letters"),
  question = c("is there anything here",
               "do the factors act independently",
               "how large is it, agronomically",
               "which pairs, with multiplicity controlled",
               "a compact summary for the figure"),
  never_report_alone = c(FALSE, FALSE, FALSE, FALSE, TRUE)
)
#>   read         what                                  question
#> 1    1      omnibus                    is there anything here
#> 2    2  interaction          do the factors act independently
#> 3    3 effect sizes            how large is it, agronomically
#> 4    4     pairwise which pairs, with multiplicity controlled
#> 5    5      letters          a compact summary for the figure
#>   never_report_alone
#> 1              FALSE
#> 2              FALSE
#> 3              FALSE
#> 4              FALSE
#> 5               TRUE
```

The last row is the one that matters. A compact letter display is the
only object in this list that must never appear without one of the
others beside it.

------------------------------------------------------------------------

## 4. Self-contained starting objects

The examples require one fitted completely randomized design and one
fitted complete randomized block design. They are recreated here so this
vignette runs independently.

``` r

crd <- simulate_agri("crd", seed = 301, n = 8)
fit_crd <- np_crd(
  yield ~ treatment,
  data = crd,
  method = "auto"
)

rcbd <- simulate_agri("rcbd", seed = 302, n = 6)
fit_rcbd <- np_rcbd(
  yield ~ treatment,
  data = rcbd,
  block = block,
  method = "friedman"
)
```

``` r

data.frame(
  object = c("fit_crd", "fit_rcbd"),
  design = c(fit_crd$design$design, fit_rcbd$design$design),
  method = c(fit_crd$method, fit_rcbd$method),
  omnibus_p = signif(c(fit_crd$omnibus$p_value[1],
                       fit_rcbd$omnibus$p_value[1]), 3)
)
#>     object design   method omnibus_p
#> 1  fit_crd    crd  kruskal   0.04280
#> 2 fit_rcbd   rcbd friedman   0.00559
```

Both omnibus tests reject, so proceeding to comparisons is legitimate.
Had either not rejected, the comparisons below would still run, and that
is worth a warning: **the software will not stop you from comparing
pairs after a non-significant omnibus test.** Whether you should is a
scientific question about whether the comparisons were planned.

------------------------------------------------------------------------

## Part I. Effects before decisions

## 5. How large, before how significant

### 5.1 The cell summaries

``` r

eff_crd <- agri_effects(fit_crd)
eff_crd
#>   cell n   median mean_rank
#> 1    A 8 6.905835    16.750
#> 2    B 8 5.756625    10.625
#> 3    C 8 6.277535    14.875
#> 4    D 8 8.135447    23.750
```

Two quantities per cell, and the pairing is deliberate.

`median` is a **location on the response scale**. It is what a reader
needs for agronomic magnitude, and it is the robust counterpart of a
treatment mean: a single extreme plot moves it very little.

`mean_rank` is what the **analysis actually used**. The omnibus test and
every comparison below operate on ranks and never revisit the original
units.

### 5.2 Why a treatment mean does not belong here

Printing a mean beside a rank test is a category error that appears
constantly in the applied literature. The two objects can even order the
treatments differently.

``` r

mm <- aggregate(yield ~ treatment, crd, function(v)
  c(mean = mean(v), median = stats::median(v)))
data.frame(treatment = mm$treatment,
           mean = round(mm$yield[, "mean"], 3),
           median = round(mm$yield[, "median"], 3),
           rank_of_mean = rank(-mm$yield[, "mean"]),
           rank_of_median = rank(-mm$yield[, "median"]))
#>   treatment  mean median rank_of_mean rank_of_median
#> 1         A 6.713  6.906            2              2
#> 2         B 5.583  5.757            4              4
#> 3         C 6.432  6.278            3              3
#> 4         D 9.308  8.135            1              1
```

When the two orderings differ, a paper that tests ranks and tabulates
means is internally inconsistent, and a careful reader will notice.

### 5.3 Interpretation

Report the median for magnitude and the test for evidence. Neither alone
is a result: a median without a test is anecdote, and a p-value without
a median is a decision with no agronomic content.

------------------------------------------------------------------------

## Part II. Pairwise comparisons are design-dependent

## 6. Conover after a completely randomized analysis

``` r

if (requireNamespace("PMCMRplus", quietly = TRUE)) {
  con_crd <- agri_conover(fit_crd, adjust = "holm")
  print(head(as.data.frame(con_crd), 8))
}
#>   stratum group1 group2 paired_by_block  statistic    p_value p_adjusted
#> 1     all      B      A           FALSE -1.4459194 0.15930115 0.47790344
#> 2     all      C      A           FALSE -0.4426284 0.66143516 0.66143516
#> 3     all      C      B           FALSE  1.0032910 0.32431264 0.64862529
#> 4     all      D      A           FALSE  1.6524793 0.10960846 0.43843383
#> 5     all      D      B           FALSE  3.0983987 0.00439733 0.02638398
#> 6     all      D      C           FALSE  2.0951077 0.04532937 0.22664683
#>                                         method
#> 1 Conover all-pairs after Kruskal-type ranking
#> 2 Conover all-pairs after Kruskal-type ranking
#> 3 Conover all-pairs after Kruskal-type ranking
#> 4 Conover all-pairs after Kruskal-type ranking
#> 5 Conover all-pairs after Kruskal-type ranking
#> 6 Conover all-pairs after Kruskal-type ranking
```

For an independent one-way design the adapter uses the **Kruskal-type**
all-pairs Conover procedure. It compares mean ranks computed over the
whole experiment, which is correct precisely because the design asserts
that all observations are exchangeable under the null.

## 7. Conover in a complete randomized block design

``` r

if (requireNamespace("PMCMRplus", quietly = TRUE)) {
  con_rcbd <- agri_conover(fit_rcbd, adjust = "holm")
  print(head(as.data.frame(con_rcbd), 8))
}
#>   stratum group1 group2 paired_by_block statistic      p_value   p_adjusted
#> 1     all      B      A            TRUE -1.490712 1.567647e-01 0.1642082252
#> 2     all      C      A            TRUE -3.354102 4.348595e-03 0.0173943798
#> 3     all      C      B            TRUE -1.863390 8.210411e-02 0.1642082252
#> 4     all      D      A            TRUE -5.590170 5.158932e-05 0.0003095359
#> 5     all      D      B            TRUE -4.099458 9.472993e-04 0.0047364964
#> 6     all      D      C            TRUE -2.236068 4.096896e-02 0.1229068679
#>                                          method
#> 1 Conover all-pairs after Friedman-type ranking
#> 2 Conover all-pairs after Friedman-type ranking
#> 3 Conover all-pairs after Friedman-type ranking
#> 4 Conover all-pairs after Friedman-type ranking
#> 5 Conover all-pairs after Friedman-type ranking
#> 6 Conover all-pairs after Friedman-type ranking
```

For a complete unreplicated block design the adapter uses the
**Friedman-type** Conover procedure and preserves pairing by block. Note
the `paired_by_block` column: it is not decoration, it records which
procedure was used.

### 7.1 The two procedures are not interchangeable

|  | Kruskal-type | Friedman-type |
|----|----|----|
| Ranks computed | over the whole experiment | within each block |
| Requires | independence | complete unreplicated blocks |
| Removes | nothing | the block effect, exactly |
| Appropriate after | [`np_crd()`](https://wep69.github.io/agriRank/reference/np_crd.md) | `np_rcbd(method = "friedman")` |

Applying the Kruskal-type procedure to blocked data commits the same
error as the omnibus safeguard in the design vignette prevents: it
discards the block and compares against a yardstick the design had
already eliminated.

### 7.2 The continuity that matters

Both procedures operate on the **same ranks** the omnibus test used.
That continuity is not a convenience. A post-hoc procedure computed on a
different quantity from the omnibus test can contradict it, and the
reader has no way to tell which to believe.

## 8. When the layout no longer supports the classical procedure

``` r

rcbd_incomplete <- rcbd[-1, ]

des_rcbd_incomplete <- agri_design(
  yield ~ treatment,
  rcbd_incomplete,
  design = "rcbd",
  block = block
)

agri_conover(agri_rank(des_rcbd_incomplete, method = "auto"))
#> Error:
#> ! Classical Friedman requires exactly one observation for each block-by-treatment cell. Use a permutation/rank-based alternative for incomplete or replicated blocks.
```

### 8.1 What the refusal means, and what it does not

It does **not** mean that losing one plot makes the experiment
unanalysable. It means the classical complete-block Conover procedure is
no longer automatically the right post-hoc method, because its
derivation assumes exactly one observation per block-by-treatment cell.

### 8.2 What to do instead

| Situation | Route |
|----|----|
| one or two plots lost at random | a permutation engine, retaining the block |
| systematic loss related to treatment | report it; the missingness is a finding |
| replication inside cells | `rankFD`, `ART` or `permuco`, then [`agri_pairs()`](https://wep69.github.io/agriRank/reference/agri_pairs.md) |
| a genuinely incomplete block design | a design-specific analysis, and say so |

``` r

# An engine that tolerates the incomplete layout, with the block retained.
fit_inc <- agri_rank(des_rcbd_incomplete, method = "ART")
#> Registered S3 method overwritten by 'lme4':
#>   method           from
#>   na.action.merMod car
fit_inc$method
#> [1] "ART"
head(as.data.frame(agri_pairs(fit_inc, adjust = "holm")), 5)
#> Warning: For multifactor ART contrasts, ARTool's ART-C procedure is preferred.
#> The generic comparisons below operate on observed treatment cells and preserve
#> blocks when a complete paired block comparison is available.
#>   stratum group1 group2 paired_by_block  A cliff_delta hodges_lehmann
#> 1     all      A      B            TRUE NA          NA     -0.2597322
#> 2     all      A      C            TRUE NA          NA     -0.5081647
#> 3     all      A      D            TRUE NA          NA     -1.6480506
#> 4     all      B      C            TRUE NA          NA     -0.5263279
#> 5     all      B      D            TRUE NA          NA     -1.0515183
#>      p_value p_adjusted
#> 1 1.00000000  1.0000000
#> 2 0.05905823  0.2952911
#> 3 0.05905823  0.2952911
#> 4 0.29450739  0.5890148
#> 5 0.05917207  0.2952911
```

Note that `method = "auto"` also refuses here, and correctly so: the
automatic route selects the classical procedure for a design declared as
`rcbd`, and the incompleteness is a fact about the data rather than the
declaration. Naming an engine that tolerates the layout is the analyst’s
decision, and it belongs in the methods section.

### 8.3 Interpretation

Report the number of missing cells in the methods, and the post-hoc
procedure actually used. A reader who finds an unexplained change of
procedure between two tables will assume the worst.

------------------------------------------------------------------------

## Part III. Effect measures for a pair

## 9. Generic pairwise comparisons

``` r

pairs_crd <- agri_pairs(
  fit_crd,
  method = "wilcoxon",
  adjust = "holm"
)
head(as.data.frame(pairs_crd), 8)
#>   stratum group1 group2 paired_by_block        A cliff_delta hodges_lehmann
#> 1     all      A      B           FALSE 0.734375     0.46875      1.1277191
#> 2     all      A      C           FALSE 0.531250     0.06250      0.4204367
#> 3     all      A      D           FALSE 0.265625    -0.46875     -1.3687508
#> 4     all      B      C           FALSE 0.453125    -0.09375     -0.6738052
#> 5     all      B      D           FALSE 0.046875    -0.90625     -2.4232393
#> 6     all      C      D           FALSE 0.281250    -0.43750     -2.4562735
#>       p_value p_adjusted
#> 1 0.127807601 0.63903800
#> 2 0.874825977 1.00000000
#> 3 0.127807601 0.63903800
#> 4 0.792895503 1.00000000
#> 5 0.002761604 0.01656963
#> 6 0.156253958 0.63903800
```

The output can include, depending on the engine and the design:

- the two groups compared;
- whether pairing by block was used;
- a probability-of-superiority effect;
- a Cliff-type effect;
- a Hodges-Lehmann location shift;
- the raw p-value;
- the multiplicity-adjusted p-value.

## 10. Probability of superiority

### 10.1 The definition

For independent samples $`Y_i`$ and $`Y_j`$,

``` math
A_{ij} = P(Y_i > Y_j) + \tfrac{1}{2} P(Y_i = Y_j),
```

with the empirical estimator

``` math
\widehat A_{ij} = \frac{\#(Y_i>Y_j) + 0.5\,\#(Y_i=Y_j)}{n_i n_j}.
```

### 10.2 The scale, and how to say it in words

| $`A_{ij}`$ | Meaning                                                       |
|------------|---------------------------------------------------------------|
| 0.50       | complete overlap; a plot from either is equally likely to win |
| 0.64       | a plot from group i wins about two times in three             |
| 0.71       | wins about five times in seven                                |
| 0.80       | wins four times in five                                       |
| 1.00       | every plot from i exceeds every plot from j                   |

The practical advantage is that “cultivar A out-yields cultivar B in
seven fields out of ten” is a sentence a grower can act on, and it does
not depend on whether yield was recorded in grams or kilograms.

### 10.3 Cliff’s delta, the same information rescaled

Cliff’s $`\delta = 2A_{ij} - 1`$ runs from $`-1`$ to $`1`$ and is zero
under no effect. The two are equivalent; report whichever your field
expects, and say which.

``` r

p <- as.data.frame(pairs_crd)
nm <- intersect(c("A", "effect", "delta", "cliff"), names(p))
if (length(nm)) {
  a <- p[[nm[1]]]
  data.frame(comparison = paste(p$group1, "vs", p$group2),
             A = round(a, 3), cliff_delta = round(2 * a - 1, 3))
}
#>   comparison     A cliff_delta
#> 1     A vs B 0.734       0.469
#> 2     A vs C 0.531       0.062
#> 3     A vs D 0.266      -0.469
#> 4     B vs C 0.453      -0.094
#> 5     B vs D 0.047      -0.906
#> 6     C vs D 0.281      -0.438
```

### 10.4 Interpretation

An effect measure is what survives translation. A p-value depends on the
sample size; $`A_{ij}`$ does not, which is why it belongs in the
abstract and the p-value in the results table.

------------------------------------------------------------------------

## Part IV. Multiplicity

## 11. Choosing an adjustment

### 11.1 The problem, stated concretely

With $`k`$ treatments there are $`k(k-1)/2`$ pairs. At $`\alpha = 0.05`$
and no adjustment, the probability of at least one false positive rises
quickly.

``` r

k <- 3:10
data.frame(
  treatments = k,
  pairs = choose(k, 2),
  P_at_least_one_false_positive = round(1 - 0.95^choose(k, 2), 3)
)
#>   treatments pairs P_at_least_one_false_positive
#> 1          3     3                         0.143
#> 2          4     6                         0.265
#> 3          5    10                         0.401
#> 4          6    15                         0.537
#> 5          7    21                         0.659
#> 6          8    28                         0.762
#> 7          9    36                         0.842
#> 8         10    45                         0.901
```

With six treatments, an unadjusted analysis is more likely than not to
produce a spurious significant pair.

### 11.2 The available adjustments

| Adjustment | Controls | Comment |
|----|----|----|
| `"none"` | nothing | only for a single planned comparison |
| `"holm"` | family-wise error rate | uniformly better than Bonferroni; a good default |
| `"BH"` | false discovery rate | for screening many treatments, not for a confirmatory pair |
| `"bonferroni"` | family-wise error rate | conservative; use when simplicity matters more than power |

``` r

raw <- as.data.frame(agri_pairs(fit_crd, adjust = "none"))
hol <- as.data.frame(agri_pairs(fit_crd, adjust = "holm"))
bh  <- as.data.frame(agri_pairs(fit_crd, adjust = "BH"))
data.frame(
  comparison = paste(raw$group1, "vs", raw$group2),
  raw = signif(raw$p_value, 3),
  holm = signif(hol$p_adjusted, 3),
  BH = signif(bh$p_adjusted, 3)
)
#>   comparison     raw   holm     BH
#> 1     A vs B 0.12800 0.6390 0.2340
#> 2     A vs C 0.87500 1.0000 0.8750
#> 3     A vs D 0.12800 0.6390 0.2340
#> 4     B vs C 0.79300 1.0000 0.8750
#> 5     B vs D 0.00276 0.0166 0.0166
#> 6     C vs D 0.15600 0.6390 0.2340
```

### 11.3 The decision that matters more than the method

The family over which you adjust is a scientific choice, and it is made
before the analysis. Adjusting over the three comparisons you care about
is defensible; adjusting over all pairs and then reporting only the
three is not, and neither is the reverse.

### 11.4 Interpretation

State the family, the adjustment, and the number of comparisons in it.
Those three facts let a reader reconstruct what was controlled.

------------------------------------------------------------------------

## Part V. Compact letter displays

## 12. The display, and the caution

``` r

if (requireNamespace("multcompView", quietly = TRUE)) {
  letters_crd <- agri_cld(fit_crd, adjust = "holm", alpha = 0.05)
  print(letters_crd)
}
#>   group letter
#> 1     A     ab
#> 2     B      a
#> 3     C     ab
#> 4     D      b
```

### 12.1 What sharing a letter means

Sharing a letter means the adjusted comparison **did not reach** the
chosen threshold. It does not mean the treatments are equal, similar, or
equivalent.

Consider the display

| Treatment | Letter |
|-----------|--------|
| A         | a      |
| B         | ab     |
| C         | b      |

It is entirely possible here that A and C differ by an agronomically
large amount, that B lies between them, and that the experiment simply
lacked the power to separate B from either. The letters record three
decisions, not three quantities.

### 12.2 The specific failure mode

The display is **not transitive** in the way readers assume. A shares a
letter with B, and B with C, but A and C do not share one. A reader who
concludes “A and C are similar because both are similar to B” has drawn
a conclusion the display does not support.

### 12.3 What a stronger presentation contains

1.  the observed data, plotted;
2.  the effect estimates;
3.  intervals where they are defined;
4.  the adjusted pairwise inference;
5.  letters, last, as a compact visual aid.

### 12.4 Letters are computed within strata

In a factorial with an interaction, a display pooled across the other
factor is not interpretable, because two treatments may share a letter
at one level and not at another.
[`agri_cld()`](https://wep69.github.io/agriRank/reference/agri_cld.md)
computes the display inside the stratum in which the comparisons were
made, and refuses an incomplete family of comparisons rather than
producing a plausible-looking partial display.

### 12.5 Interpretation

Use letters in a figure, never as the result. If a table contains
letters and no effect sizes, the table has reported decisions and
withheld findings.

------------------------------------------------------------------------

## Part VI. Factorial experiments

## 13. Why a one-way test is not a factorial analysis

``` r

fac <- simulate_agri("factorial", seed = 401, n = 7)
str(fac)
#> 'data.frame':    42 obs. of  3 variables:
#>  $ A    : Factor w/ 2 levels "A1","A2": 1 1 1 1 1 1 1 1 1 1 ...
#>  $ B    : Factor w/ 3 levels "B1","B2","B3": 1 1 1 1 1 1 1 2 2 2 ...
#>  $ yield: num  4.12 5.99 5.76 3.76 5.03 ...

des_fac <- agri_design(yield ~ A * B, fac, design = "factorial")
design_summary(des_fac)
#> $design
#> [1] "factorial"
#> 
#> $responses
#> [1] "yield"
#> 
#> $treatments
#> [1] "A" "B"
#> 
#> $blocks
#> NULL
#> 
#> $subjects
#> NULL
#> 
#> $within
#> NULL
#> 
#> $whole_plot
#> NULL
#> 
#> $subplot
#> NULL
#> 
#> $subsubplot
#> NULL
#> 
#> $strip_a
#> NULL
#> 
#> $strip_b
#> NULL
#> 
#> $environment
#> NULL
#> 
#> $n_rows
#> [1] 42
#> 
#> $n_treatment_cells_observed
#> [1] 6
#> 
#> $missing_response
#> yield 
#>     0 
#> 
#> $randomization
#> [1] "Factorial treatment combinations are assigned to independent experimental units."
#> 
#> $validation
#> $ok
#> [1] TRUE
#> 
#> $problems
#> [1] severity code     message 
#> <0 rows> (or 0-length row.names)
#> 
#> attr(,"class")
#> [1] "agri_validation"
```

The scientific questions are three, not one:

1.  Is there an effect of A, averaged over B?
2.  Is there an effect of B, averaged over A?
3.  Does the effect of A depend on the level of B?

A one-way Kruskal-Wallis test on the six A-by-B cells answers a fourth
question, “do the six cells differ”, and no amount of interpretation
recovers the three from it. The decomposition is the analysis.

### 13.1 The interaction is read first

If the interaction is present, the main effects are averages over
conditions in which the behaviour differs. They remain correct as
marginal statements but they describe no particular level, and quoting
them as if they did is the commonest misreading of a factorial table.

## 14. Pseudo-rank factorial analysis

``` r

if (requireNamespace("rankFD", quietly = TRUE)) {
  fit_rankfd <- agri_rank(des_fac, method = "rankFD")
  print(fit_rankfd)
  print(anova(fit_rankfd))
}
#> agriRank fit
#>   Design: factorial
#>   Method: rankFD pseudo-rank factorial inference
#>   Response: yield
#>   effect statistic   df1     df2 p_value
#> 1      A   23.1740 1.000 24.8447  0.0001
#> 2      B    8.8097 1.947 24.8447  0.0014
#> 3    A:B    0.7397 1.947 24.8447  0.4841
#>   effect statistic   df1     df2 p_value
#> 1      A   23.1740 1.000 24.8447  0.0001
#> 2      B    8.8097 1.947 24.8447  0.0014
#> 3    A:B    0.7397 1.947 24.8447  0.4841
```

### 14.1 Why pseudo-ranks

Ordinary ranks depend on the sample sizes of the groups being pooled. In
an unbalanced design that dependence induces apparent effects that are
artefacts of the allocation rather than the treatment.

Pseudo-ranks replace the empirical distribution of the pooled sample
with an unweighted average of the group distributions, which removes
that dependence. The practical consequence: in an unbalanced factorial,
ordinary ranks can make a larger group look better simply for being
larger.

### 14.2 When it matters most

| Design | Difference between ranks and pseudo-ranks |
|----|----|
| balanced | negligible |
| mildly unbalanced | small |
| strongly unbalanced | can change the conclusion |
| unbalanced with unequal spread | can change the conclusion and its direction |

## 15. Aligned Rank Transform

``` r

if (requireNamespace("ARTool", quietly = TRUE)) {
  fit_art <- agri_rank(des_fac, method = "ART")
  print(anova(fit_art))
}
#>   Term Df Df.res    Sum Sq Sum Sq.res    F value       Pr(>F) effect
#> 1    A  1     36 2072.0238   4078.000 18.2915295 0.0001333659      A
#> 2    B  2     36 1723.0000   4426.286  7.0067777 0.0026907038      B
#> 3  A:B  2     36  186.1429   5958.000  0.5623651 0.5747850869    A:B
```

### 15.1 What alignment does

ART removes all effects except the one being tested, ranks the aligned
residuals, and applies an ordinary factorial analysis to those ranks.
That is what makes a nonparametric test of an **interaction** possible
at all, which the classical rank tests do not provide.

### 15.2 The caveat that is easy to miss

Contrasts computed after ART require care. The alignment used for
testing the A main effect is not the alignment appropriate to a contrast
within a level of B. Where multifactor contrasts are needed, the ART-C
variant exists for exactly this reason and should be used through the
corresponding backend workflow.

## 16. Permutation route

``` r

if (requireNamespace("permuco", quietly = TRUE)) {
  fit_perm <- agri_rank(des_fac, method = "permuco", B = 999, seed = 401)
  print(anova(fit_perm))
}
#>                 SS df          F parametric P(>F) resampled P(>F)
#> A         1826.881  1 23.1739656     2.649319e-05      0.00020004
#> B         1389.000  2  8.8097252     7.684977e-04      0.00040008
#> A:B        116.619  2  0.7396557     4.843911e-01      0.48429686
#> Residuals 2838.000 36         NA               NA              NA
```

### 16.1 What permutation buys, and what it assumes

A permutation test builds the reference distribution from the data by
permuting the treatment labels, which needs no asymptotic approximation.
It is therefore the natural choice for small experiments and heavily
tied responses.

What it assumes is **exchangeability under the null**, and in a
structured design that means permuting within the correct stratum. A
permutation that ignores the hierarchy tests the wrong hypothesis.

### 16.2 A documented limitation of this version

The permutation backend shows a calibration failure in split-split-plot
and strip-plot strata: under the null hypothesis it rejected in none of
500 simulated experiments, where roughly 25 rejections would be expected
at the 5% level.

This is documented in `VALIDATION_PLAN.md` and it is not repaired by
test coverage. For those two designs, prefer `rankFD` or `ART` and
report the choice. For the factorial designs of this vignette the
backend behaves as expected.

## 17. Choosing among the three

| Structure | Prefer | Why |
|----|----|----|
| balanced factorial, moderate n | any of the three | they will agree |
| unbalanced factorial | `rankFD` | pseudo-ranks remove the allocation artefact |
| interaction is the primary question | `ART` | it is designed for this |
| small n, heavy ties | `permuco` | no asymptotic approximation |
| split-split or strip-plot | `rankFD` or `ART` | see 16.2 |

The choice is made from the **structure**, before the response is
examined.

------------------------------------------------------------------------

## Part VII. Sensitivity across engines

## 18. Running the comparison

``` r

sens_fac <- agri_sensitivity(
  agri_rank(des_fac, method = "rankFD"),
  methods = c("primary", "ART", "permuco"),
  seed = 401
)
sens_fac$table
#>            method    effect      p_value note
#> primary.1 primary         A 1.000000e-04     
#> primary.2 primary         B 1.400000e-03     
#> primary.3 primary       A:B 4.841000e-01     
#> ART.1         ART         A 1.333659e-04     
#> ART.2         ART         B 2.690704e-03     
#> ART.3         ART       A:B 5.747851e-01     
#> permuco.1 permuco         A 2.649319e-05     
#> permuco.2 permuco         B 7.684977e-04     
#> permuco.3 permuco       A:B 4.843911e-01     
#> permuco.4 permuco Residuals           NA
```

``` r

sens_fac$interpretation
#> [1] "Differences across methods quantify model sensitivity. They must not be used to choose the smallest p-value."
```

### 18.1 How to read it

Sensitivity analysis is not a tournament for p-values. It asks whether
substantive conclusions are stable across reasonable inferential
paradigms.

| Outcome | Reading | What to report |
|----|----|----|
| all engines agree | the conclusion does not rest on the choice | one sentence, plus the table in supplementary material |
| engines disagree in magnitude only | the conclusion is stable, the precision is not | report the range |
| engines disagree in direction or decision | **the disagreement is the finding** | report all of them, and say which was pre-specified |

### 18.2 The pre-specification that makes it honest

A sensitivity analysis is only meaningful if the **primary** engine was
chosen before the data were examined. Otherwise “sensitivity” is a
search, and reporting the most convenient result is misconduct rather
than simplification.

### 18.3 A reportable sentence

> The treatment-by-factor interaction was examined with a
> design-compatible primary rank-based analysis (`rankFD`,
> pre-specified) and compared with aligned-rank and permutation
> alternatives as a sensitivity analysis. Differences among methods were
> interpreted as model dependence and not as a basis for selecting the
> smallest p-value.

------------------------------------------------------------------------

## Part VIII. Simple effects

## 19. When a marginal comparison misleads

Suppose an A-by-B interaction is scientifically important. A comparison
of A averaged over B then describes no level of B in particular.

``` r

if (exists("fit_rankfd")) {
  simple_A <- agri_pairs(fit_rankfd, factor = "A", by = "B", adjust = "holm")
  print(head(as.data.frame(simple_A), 8))
}
#>   stratum group1 group2 paired_by_block          A cliff_delta hodges_lehmann
#> 1      B1     A1     A2           FALSE 0.04081633  -0.9183673     -1.5964395
#> 2      B2     A1     A2           FALSE 0.14285714  -0.7142857     -1.1583765
#> 3      B3     A1     A2           FALSE 0.24489796  -0.5102041     -0.9795126
#>       p_value p_adjusted
#> 1 0.004937905 0.01481372
#> 2 0.029842064 0.05968413
#> 3 0.125201030 0.12520103
```

``` r

if (exists("fit_rankfd") && requireNamespace("PMCMRplus", quietly = TRUE)) {
  simple_A_conover <- agri_conover(fit_rankfd, factor = "A", by = "B",
                                   adjust = "holm")
  print(head(as.data.frame(simple_A_conover), 8))
}
#>   stratum group1 group2 paired_by_block statistic      p_value   p_adjusted
#> 1      B1     A2     A1           FALSE  4.576929 0.0006358041 0.0006358041
#> 2      B2     A2     A1           FALSE  2.738613 0.0179774804 0.0179774804
#> 3      B3     A2     A1           FALSE  1.711633 0.1126631619 0.1126631619
#>                                         method
#> 1 Conover all-pairs after Kruskal-type ranking
#> 2 Conover all-pairs after Kruskal-type ranking
#> 3 Conover all-pairs after Kruskal-type ranking
```

### 19.1 The discipline that keeps this honest

Use simple effects only when they answer a stated biological question.
Do not generate every possible comparison because the software can.

The reason is arithmetic. With three levels of A inside three levels of
B there are nine comparisons of A within B, plus nine of B within A.
Reporting the significant ones from eighteen unplanned comparisons is a
selection procedure, whatever adjustment is applied to the subset that
gets reported.

### 19.2 Deciding in advance

| Before the data | Then |
|----|----|
| “we will compare cultivars within each nitrogen level” | a family of $`k_A(k_A-1)/2`$ per level, adjusted within level |
| “we will compare the new cultivar to the control everywhere” | a much smaller family, and much more power |
| “we will look and see” | not a comparison procedure |

### 19.3 Interpretation

Report the family, its size, and whether it was pre-specified. Those
three facts distinguish a simple-effects analysis from a fishing
expedition, and no adjustment method can substitute for them.

------------------------------------------------------------------------

## Part IX. Common mistakes, and the function that prevents each

## 20. Applying an independent-groups post-hoc to blocked data

**The mistake.** Kruskal-type Conover after a blocked analysis.

**Why it is wrong.** It compares mean ranks computed over the whole
experiment, reintroducing the between-block variation the design
removed.

**What prevents it.**
[`agri_conover()`](https://wep69.github.io/agriRank/reference/agri_conover.md)
routes on the declared design and uses the Friedman-type procedure for
complete blocks. See sections 6 and 7.

------------------------------------------------------------------------

## 21. Forcing a complete-block procedure onto an incomplete layout

**The mistake.** Dropping a plot and running the same post-hoc as
before.

**Why it is wrong.** The classical Friedman-type derivation assumes
exactly one observation per cell.

**What prevents it.**
[`agri_conover()`](https://wep69.github.io/agriRank/reference/agri_conover.md)
refuses and names the reason. See section 8.

------------------------------------------------------------------------

## 22. Reporting letters as the result

**The mistake.** A results table containing treatment labels and
letters, and nothing else.

**Why it is wrong.** It reports decisions and withholds findings. A
reader cannot tell whether a shared letter reflects similarity or low
power.

**What prevents it.** Nothing in software can.
[`agri_effects()`](https://wep69.github.io/agriRank/reference/agri_effects.md)
provides what belongs beside the letters. See section 12.

------------------------------------------------------------------------

## 23. Reading a letter display transitively

**The mistake.** “A and C are similar, because both share a letter with
B.”

**Why it is wrong.** The display is not transitive. Section 12.2.

**What prevents it.** Only a correct caption. Write one.

------------------------------------------------------------------------

## 24. Analysing a factorial as a one-way test on cells

**The mistake.** Kruskal-Wallis on the six A-by-B combinations.

**Why it is wrong.** It answers “do the cells differ” and cannot recover
the main effects or the interaction. Section 13.

**What prevents it.** `agri_design(yield ~ A * B)` records the factorial
structure, and the factorial engines decompose it.

------------------------------------------------------------------------

## 25. Using ordinary ranks in a strongly unbalanced factorial

**The mistake.** Ranking the pooled sample when group sizes differ
markedly.

**Why it is wrong.** The rank of an observation then depends on how many
observations each group contributed, which is an allocation artefact.

**What prevents it.** `method = "rankFD"` uses pseudo-ranks. Section
14.1.

------------------------------------------------------------------------

## 26. Selecting the engine that gave the smallest p-value

**The mistake.** Running `rankFD`, ART and permuco, and reporting the
one that reached significance.

**Why it is wrong.** The reported p-value is then the minimum of three,
and its null distribution is not the one being quoted.

**What prevents it.**
[`agri_sensitivity()`](https://wep69.github.io/agriRank/reference/agri_sensitivity.md)
returns all engines together with the explicit note that they must not
be used to select the smallest. Section 18.

------------------------------------------------------------------------

## 27. Generating all simple effects and reporting the significant ones

**The mistake.** Eighteen unplanned comparisons, three reported.

**Why it is wrong.** Section 19.1.

**What prevents it.** Pre-specification. Write the family down before
the harvest.

------------------------------------------------------------------------

## Part X. Compact selection guide

## 28. Choose the comparison by the design

| After | Use | Not |
|----|----|----|
| [`np_crd()`](https://wep69.github.io/agriRank/reference/np_crd.md) | [`agri_conover()`](https://wep69.github.io/agriRank/reference/agri_conover.md) (Kruskal-type) | Friedman-type |
| `np_rcbd(method = "friedman")` | [`agri_conover()`](https://wep69.github.io/agriRank/reference/agri_conover.md) (Friedman-type) | Kruskal-type |
| an incomplete block layout | [`agri_pairs()`](https://wep69.github.io/agriRank/reference/agri_pairs.md) with a permutation engine | classical Conover |
| [`np_factorial()`](https://wep69.github.io/agriRank/reference/np_factorial.md) with an interaction | simple effects, pre-specified | marginal comparisons alone |
| any of the above | [`agri_effects()`](https://wep69.github.io/agriRank/reference/agri_effects.md) beside the comparisons | letters alone |

## 29. Choose the adjustment by the family

| The family is                     | Use                              |
|-----------------------------------|----------------------------------|
| one planned comparison            | `"none"`, and say it was planned |
| all pairs, confirmatory           | `"holm"`                         |
| many treatments, screening        | `"BH"`                           |
| all pairs, and simplicity matters | `"bonferroni"`                   |

------------------------------------------------------------------------

## Part XI. Minimum reporting checklist

## 30. What the comparison section must contain

1.  the omnibus result, before any pairwise comparison;
2.  the interaction, read before the main effects, in a factorial;
3.  the effect sizes with their scale named;
4.  the post-hoc procedure, and why it matches the design;
5.  the multiplicity adjustment and the size of the family;
6.  whether the family was pre-specified;
7.  the stratum in which letters were computed;
8.  the sensitivity analysis across admissible engines;
9.  the resampling count and seed for permutation engines.

## 31. A worked comparison paragraph

> Following a significant omnibus test, treatments were compared with
> the design-aware Conover all-pairs procedure on within-block ranks
> ([`agri_conover()`](https://wep69.github.io/agriRank/reference/agri_conover.md)),
> with Holm adjustment over the six pairwise comparisons, which were
> pre-specified. Effect sizes are reported as the probability that a
> randomly chosen plot from one treatment exceeds one from the other.
> Compact letters were computed within the single stratum of this design
> and are shown in Figure 2 as a visual aid only. Conclusions were
> unchanged under aligned-rank and permutation alternatives
> ([`agri_sensitivity()`](https://wep69.github.io/agriRank/reference/agri_sensitivity.md),
> 999 permutations, seed 401), reported in Table S2.

------------------------------------------------------------------------

## 32. Where to go next

| If you now want | Read |
|----|----|
| the design declaration these comparisons rest on | *Design Foundations, CRD, and RCBD* |
| comparisons inside a split-plot or strip-plot | *Hierarchical Plot Designs, Trends, ANCOVA, and Power* |
| a quantitative treatment described as a curve | *Nonparametric and Shape-Aware Regression* |
| figures and tables for these comparisons | *Graphics, Tables, Reports, and Reproducibility* |
| the whole workflow on one experiment | *Integrated Agronomic Case Study* |

------------------------------------------------------------------------

## Part XII. Glossary

## 33. Terms used in this vignette

| Term | Meaning here |
|----|----|
| **omnibus test** | a test that any effect exists, before asking which |
| **post-hoc** | a comparison made after, and conditional on, an omnibus result |
| **family** | the set of comparisons over which multiplicity is controlled |
| **family-wise error rate** | the probability of at least one false positive in the family |
| **false discovery rate** | the expected proportion of false positives among the rejections |
| **probability of superiority** | $`P(Y_i>Y_j)+\tfrac12 P(Y_i=Y_j)`$ |
| **Cliff’s delta** | $`2A_{ij}-1`$, the same quantity rescaled to $`[-1,1]`$ |
| **Hodges-Lehmann shift** | the median of all pairwise differences between two samples |
| **pseudo-rank** | a rank computed against an unweighted average of the group distributions |
| **aligned rank** | a rank of residuals from which all other effects have been removed |
| **compact letter display** | a summary in which treatments not separated share a letter |
| **simple effect** | the effect of one factor within a fixed level of another |
| **stratum** | the level of the hierarchy at which an effect is tested |

------------------------------------------------------------------------

## Selected methodological references

- Brunner, E., Konietschke, F., Pauly, M., and Puri, M. L. (2017).
  Rank-based procedures in factorial designs: hypotheses about
  non-parametric treatment effects. *Journal of the Royal Statistical
  Society: Series B*, 79(5), 1463-1485.
  <https://doi.org/10.1111/rssb.12222>
- Cliff, N. (1993). Dominance statistics: ordinal analyses to answer
  ordinal questions. *Psychological Bulletin*, 114(3), 494-509.
- Conover, W. J. (1999). *Practical Nonparametric Statistics*, 3rd
  edition. Wiley.
- Elkin, L. A., Kay, M., Higgins, J. J., and Wobbrock, J. O. (2021). An
  aligned rank transform procedure for multifactor contrast tests.
  *Proceedings of UIST 2021*, 754-768.
  <https://doi.org/10.1145/3472749.3474784>
- Holm, S. (1979). A simple sequentially rejective multiple test
  procedure. *Scandinavian Journal of Statistics*, 6(2), 65-70.
- Konietschke, F., and Brunner, E. (2023). rankFD: An R software package
  for nonparametric analysis of general factorial designs. *The R
  Journal*, 15(1), 142-158. <https://doi.org/10.32614/RJ-2023-029>
- Pauly, M., Brunner, E., and Konietschke, F. (2015). Asymptotic
  permutation tests in general factorial designs. *Journal of the Royal
  Statistical Society: Series B*, 77(2), 461-473.
  <https://doi.org/10.1111/rssb.12073>
- Wobbrock, J. O., Findlater, L., Gergle, D., and Higgins, J. J. (2011).
  The aligned rank transform for nonparametric factorial analyses using
  only ANOVA procedures. *Proceedings of CHI 2011*, 143-146.
  <https://doi.org/10.1145/1978942.1978963>

The package also ships a verified RIS library under `inst/references/`.
