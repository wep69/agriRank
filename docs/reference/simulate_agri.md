# Simulate representative agricultural experiments

Generates reproducible teaching data for CRD, RCBD, factorial,
split-plot, split-split, strip-plot, repeated, incomplete repeated, and
multi-environment workflows, and for the three quantitative-gradient
scenarios used by the regression module.

## Usage

``` r
simulate_agri(
  design = c("crd", "rcbd", "factorial", "split_plot",
    "split_split", "strip_plot", "repeated",
    "repeated_missing", "multienv", "dose_response",
    "integer_density", "surface"),
  seed = 123,
  n = 6,
  missing_rate = 0.2
)
```

## Arguments

- design:

  A declared design type or an \`agri_design\` object, depending on
  context.

- seed:

  Random seed used for reproducible resampling.

- n:

  Replication or block count used by the selected synthetic-data
  generator.

- missing_rate:

  Probability used to introduce missing responses in the synthetic
  repeated-data generator.

## Details

These are synthetic teaching data, not evidence from real experiments.
The vignette suite documents the experimental-design logic, estimand,
hypothesis, resampling structure, missing/unbalanced-data behavior, and
backend-specific limitations in greater depth.

The quantitative-gradient scenarios mirror the exported data sets and
are meant for the regression module:

- `"dose_response"`:

  Nitrogen rate in kg ha\\^{-1}\\ from 0 to 280 in `n` blocks, with a
  quadratic-plateau response. Compare
  [`agri_dose`](https://wep69.github.io/agriRank/reference/agri_dose.md).

- `"integer_density"`:

  Plants per hill from 1 to 9 in `n` blocks, with a unimodal response.
  Compare
  [`agri_density`](https://wep69.github.io/agriRank/reference/agri_density.md).

- `"surface"`:

  Nitrogen by irrigation depth with a positive cross term. Compare
  [`agri_surface`](https://wep69.github.io/agriRank/reference/agri_surface.md).

Use the exported data sets when a fixed, citable example is wanted, and
these generators when a fresh replicate of the same structure is wanted.

## Value

A data frame.

## References

Pauly M, Brunner E, Konietschke F (2015), DOI: 10.1111/rssb.12073.
Brunner E, Konietschke F, Pauly M, Puri ML (2017), DOI:
10.1111/rssb.12222. Konietschke F, Brunner E (2023), DOI:
10.32614/RJ-2023-029. See the package vignettes and
\`inst/references/agriRank-methods-verified.ris\` for engine-specific
verified references.

## See also

`agri_design`, `agri_rank`, `agri_effects`, `agri_report`

## Examples

``` r
# Example 1
simulate_agri("crd",seed=1)
#>    treatment     yield
#> 1          A  3.215201
#> 2          A 10.089378
#> 3          A  9.833313
#> 4          A  6.397175
#> 5          A 13.465300
#> 6          A  7.607349
#> 7          B  7.986543
#> 8          B  5.080908
#> 9          B  3.792519
#> 10         B  4.228435
#> 11         B  5.098564
#> 12         B  5.858917
#> 13         C  4.577259
#> 14         C  9.934132
#> 15         C  9.054440
#> 16         C 10.328321
#> 17         C  9.779201
#> 18         C  7.238575
#> 19         D  3.687878
#> 20         D  9.719359
#> 21         D 12.022952
#> 22         D  6.053721
#> 23         D  6.602271
#> 24         D  7.282409

# Example 2
simulate_agri("repeated_missing",seed=2,n=8,missing_rate=.15)
#>    subject treatment time    height
#> 1        1   control    1 10.154537
#> 2        1   control    2        NA
#> 3        1   control    3 14.887263
#> 4        1   control    4 11.784259
#> 5        2   control    1  8.407913
#> 6        2   control    2        NA
#> 7        2   control    3        NA
#> 8        2   control    4 12.533157
#> 9        3   control    1 12.401309
#> 10       3   control    2        NA
#> 11       3   control    3        NA
#> 12       3   control    4 14.954709
#> 13       4   control    1        NA
#> 14       4   control    2 11.930909
#> 15       4   control    3        NA
#> 16       4   control    4  9.779383
#> 17       5   control    1  9.952726
#> 18       5   control    2 10.124897
#> 19       5   control    3 10.897769
#> 20       5   control    4 13.048419
#> 21       6   control    1 11.103622
#> 22       6   control    2 10.467553
#> 23       6   control    3        NA
#> 24       6   control    4        NA
#> 25       7   control    1 12.998865
#> 26       7   control    2 12.310454
#> 27       7   control    3 12.797032
#> 28       7   control    4        NA
#> 29       8   control    1 10.259305
#> 30       8   control    2 11.277521
#> 31       8   control    3 12.982796
#> 32       8   control    4 13.895884
#> 33       9   treated    1 12.187290
#> 34       9   treated    2 15.418209
#> 35       9   treated    3 18.458367
#> 36       9   treated    4 20.285779
#> 37      10   treated    1 13.093151
#> 38      10   treated    2 11.416533
#> 39      10   treated    3        NA
#> 40      10   treated    4 15.341486
#> 41      11   treated    1 10.662951
#> 42      11   treated    2 11.725700
#> 43      11   treated    3 15.882802
#> 44      11   treated    4 18.623088
#> 45      12   treated    1 11.718475
#> 46      12   treated    2 19.359380
#> 47      12   treated    3        NA
#> 48      12   treated    4 16.441371
#> 49      13   treated    1  7.707771
#> 50      13   treated    2 11.870369
#> 51      13   treated    3 13.565551
#> 52      13   treated    4 15.630607
#> 53      14   treated    1  7.369145
#> 54      14   treated    2 10.615967
#> 55      14   treated    3 10.799844
#> 56      14   treated    4 11.965771
#> 57      15   treated    1        NA
#> 58      15   treated    2 15.536289
#> 59      15   treated    3 15.746156
#> 60      15   treated    4 16.388897
#> 61      16   treated    1  8.362223
#> 62      16   treated    2  8.475437
#> 63      16   treated    3 10.297404
#> 64      16   treated    4 13.106031

# Example 3
simulate_agri("multienv",seed=3,n=5)
#>    environment block genotype     yield
#> 1           E1     1        A  8.083147
#> 2           E1     1        B 10.486166
#> 3           E1     1        C 11.839197
#> 4           E1     1        D 10.591814
#> 5           E1     2        A 10.634053
#> 6           E1     2        B  9.664067
#> 7           E1     2        C 10.829712
#> 8           E1     2        D 15.423512
#> 9           E1     3        A  5.859195
#> 10          E1     3        B 13.029789
#> 11          E1     3        C  9.802414
#> 12          E1     3        D 10.735985
#> 13          E1     4        A  8.901677
#> 14          E1     4        B 10.838185
#> 15          E1     4        C 11.607157
#> 16          E1     4        D 12.289632
#> 17          E1     5        A  8.739661
#> 18          E1     5        B  9.366935
#> 19          E1     5        C 12.746941
#> 20          E1     5        D 12.310682
#> 21          E2     1        A 10.529657
#> 22          E2     1        B  8.885915
#> 23          E2     1        C 12.110780
#> 24          E2     1        D 11.495806
#> 25          E2     2        A  9.740506
#> 26          E2     2        B  9.533027
#> 27          E2     2        C 14.495609
#> 28          E2     2        D 14.029938
#> 29          E2     3        A 10.096861
#> 30          E2     3        B  8.074757
#> 31          E2     3        C 12.801110
#> 32          E2     3        D 13.552586
#> 33          E2     4        A 10.612508
#> 34          E2     4        B 13.336824
#> 35          E2     4        C 10.775511
#> 36          E2     4        D 14.143744
#> 37          E2     5        A 12.165545
#> 38          E2     5        B 11.400965
#> 39          E2     5        C 11.116118
#> 40          E2     5        D 14.201674
#> 41          E3     1        A 12.711971
#> 42          E3     1        B 10.532163
#> 43          E3     1        C 17.452183
#> 44          E3     1        D 12.760114
#> 45          E3     2        A 12.179040
#> 46          E3     2        B  8.902146
#> 47          E3     2        C 12.402150
#> 48          E3     2        D 14.005545
#> 49          E3     3        A  9.011110
#> 50          E3     3        B 10.482849
#> 51          E3     3        C 13.498413
#> 52          E3     3        D 11.855644
#> 53          E3     4        A 10.585587
#> 54          E3     4        B 10.504714
#> 55          E3     4        C  9.571073
#> 56          E3     4        D 12.243888
#> 57          E3     5        A  8.818026
#> 58          E3     5        B 14.702564
#> 59          E3     5        C 14.582825
#> 60          E3     5        D 12.122012

# Example 4: a fresh replicate of the nitrogen-rate structure
head(simulate_agri("dose_response", seed = 4, n = 4))
#>    block dose    yield
#> 1     B1    0 3.557575
#> 5     B1   40 4.290276
#> 9     B1   80 4.481280
#> 13    B1  120 5.107353
#> 17    B1  160 5.520102
#> 21    B1  200 5.499322

# Example 5: an integer treatment for the discrete-decision workflow
head(simulate_agri("integer_density", seed = 5, n = 4))
#>    block plants    yield
#> 1     B1      1 3.542414
#> 5     B1      2 3.926999
#> 9     B1      3 4.400129
#> 13    B1      4 4.977576
#> 17    B1      5 5.604119
#> 21    B1      6 5.735004

# Example 6: two interacting quantitative gradients
head(simulate_agri("surface", seed = 6, n = 6))
#>    block nitrogen water    yield
#> 1     B1        0   0.4 3.198085
#> 15    B1        0   0.6 3.675888
#> 29    B1        0   0.8 3.386061
#> 43    B1        0   1.0 3.631515
#> 57    B1        0   1.2 3.497534
#> 3     B1       40   0.4 3.692070
```
