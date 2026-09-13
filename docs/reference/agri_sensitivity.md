# Compare admissible inferential paradigms

Fits selected alternative engines and tabulates their effect-level
p-values without choosing the smallest one.

## Usage

``` r
agri_sensitivity(x, methods = c("primary", "ART", "permuco"), seed = 1, ...)
```

## Arguments

- x:

  An agriRank design or fitted object as documented for the function.

- methods:

  Vector of admissible alternative engines included in sensitivity
  analysis.

- seed:

  Random seed used for reproducible resampling.

- ...:

  Additional arguments passed to the selected backend or downstream
  method.

## Details

Use to assess conclusion stability, not for method shopping. The
vignette suite documents the experimental-design logic, estimand,
hypothesis, resampling structure, missing/unbalanced-data behavior, and
backend-specific limitations in greater depth.

## Value

An \`agri_sensitivity\` object.

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
x<-simulate_agri("factorial"); d<-agri_design(yield~A*B,x,"factorial"); agri_sensitivity(d)
#> Warning: The number of permutations is below 2000, p-values might be unreliable.
#> $table
#>            method effect      p_value note
#> primary.1 primary      A 0.0149000000     
#> primary.2 primary      B 0.0054000000     
#> primary.3 primary    A:B 0.1784000000     
#> ART.1         ART      A 0.0088775925     
#> ART.2         ART      B 0.0008957788     
#> ART.3         ART    A:B 0.0330224447     
#> permuco.1 permuco      A 0.0150075038     
#> permuco.2 permuco      B 0.0055027514     
#> permuco.3 permuco    A:B 0.1840920460     
#> 
#> $fits
#> $fits$primary
#> agriRank fit
#>   Design: factorial
#>   Method: rankFD pseudo-rank factorial inference
#>   Response: yield
#>   Resampling: none (asymptotic test)
#>   effect statistic     df p_value    df1     df2
#> 1      A    6.9339 1.0000  0.0149 1.0000 22.8596
#> 2      B    6.6740 1.9702  0.0054 1.9702 22.8596
#> 3    A:B    1.8632 1.9702  0.1784 1.9702 22.8596
#> 
#> $fits$ART
#> agriRank fit
#>   Design: factorial
#>   Method: Aligned Rank Transform
#>   Response: yield
#>   Resampling: none (asymptotic test)
#>   effect statistic df      p_value Term Df Df.res    Sum Sq Sum Sq.res  F value
#> 1      A  7.833677  1 0.0088775925    A  1     30  802.7778   3074.333 7.833677
#> 2      B  8.948476  2 0.0008957788    B  2     30 1441.5000   2416.333 8.948476
#> 3    A:B  3.829436  2 0.0330224447  A:B  2     30  786.0556   3079.000 3.829436
#>         Pr(>F)
#> 1 0.0088775925
#> 2 0.0008957788
#> 3 0.0330224447
#> 
#> $fits$permuco
#> agriRank fit
#>   Design: factorial
#>   Method: permuco permutation ANOVA on mid-ranks
#>   Response: yield
#>   Resampling replicates: 1999
#>   effect statistic df     p_value       SS        F parametric P(>F)
#> 1      A  6.933889  1 0.015007504 498.7778 6.933889      0.013240580
#> 2      B  6.674004  2 0.005502751 960.1667 6.674004      0.004002043
#> 3    A:B  1.863222  2 0.184092046 268.0556 1.863222      0.172687331
#>   resampled P(>F)
#> 1     0.015007504
#> 2     0.005502751
#> 3     0.184092046
#> 
#> 
#> $interpretation
#> [1] "Differences across methods quantify model sensitivity. They must not be used to choose the smallest p-value."
#> 
#> attr(,"class")
#> [1] "agri_sensitivity"

# Example 2
x<-simulate_agri("factorial");
d<-agri_design(yield~A*B,x,"factorial");
f<-agri_rank(d);
agri_sensitivity(f,c("primary","ART"))
#> $table
#>            method effect      p_value note
#> primary.1 primary      A 0.0149000000     
#> primary.2 primary      B 0.0054000000     
#> primary.3 primary    A:B 0.1784000000     
#> ART.1         ART      A 0.0088775925     
#> ART.2         ART      B 0.0008957788     
#> ART.3         ART    A:B 0.0330224447     
#> 
#> $fits
#> $fits$primary
#> agriRank fit
#>   Design: factorial
#>   Method: rankFD pseudo-rank factorial inference
#>   Response: yield
#>   Resampling: none (asymptotic test)
#>   effect statistic     df p_value    df1     df2
#> 1      A    6.9339 1.0000  0.0149 1.0000 22.8596
#> 2      B    6.6740 1.9702  0.0054 1.9702 22.8596
#> 3    A:B    1.8632 1.9702  0.1784 1.9702 22.8596
#> 
#> $fits$ART
#> agriRank fit
#>   Design: factorial
#>   Method: Aligned Rank Transform
#>   Response: yield
#>   Resampling: none (asymptotic test)
#>   effect statistic df      p_value Term Df Df.res    Sum Sq Sum Sq.res  F value
#> 1      A  7.833677  1 0.0088775925    A  1     30  802.7778   3074.333 7.833677
#> 2      B  8.948476  2 0.0008957788    B  2     30 1441.5000   2416.333 8.948476
#> 3    A:B  3.829436  2 0.0330224447  A:B  2     30  786.0556   3079.000 3.829436
#>         Pr(>F)
#> 1 0.0088775925
#> 2 0.0008957788
#> 3 0.0330224447
#> 
#> 
#> $interpretation
#> [1] "Differences across methods quantify model sensitivity. They must not be used to choose the smallest p-value."
#> 
#> attr(,"class")
#> [1] "agri_sensitivity"

# Example 3
x<-simulate_agri("factorial");
d<-agri_design(yield~A*B,x,"factorial");
agri_sensitivity(d,c("primary","ART","permuco"))
#> Warning: The number of permutations is below 2000, p-values might be unreliable.
#> $table
#>            method effect      p_value note
#> primary.1 primary      A 0.0149000000     
#> primary.2 primary      B 0.0054000000     
#> primary.3 primary    A:B 0.1784000000     
#> ART.1         ART      A 0.0088775925     
#> ART.2         ART      B 0.0008957788     
#> ART.3         ART    A:B 0.0330224447     
#> permuco.1 permuco      A 0.0150075038     
#> permuco.2 permuco      B 0.0055027514     
#> permuco.3 permuco    A:B 0.1840920460     
#> 
#> $fits
#> $fits$primary
#> agriRank fit
#>   Design: factorial
#>   Method: rankFD pseudo-rank factorial inference
#>   Response: yield
#>   Resampling: none (asymptotic test)
#>   effect statistic     df p_value    df1     df2
#> 1      A    6.9339 1.0000  0.0149 1.0000 22.8596
#> 2      B    6.6740 1.9702  0.0054 1.9702 22.8596
#> 3    A:B    1.8632 1.9702  0.1784 1.9702 22.8596
#> 
#> $fits$ART
#> agriRank fit
#>   Design: factorial
#>   Method: Aligned Rank Transform
#>   Response: yield
#>   Resampling: none (asymptotic test)
#>   effect statistic df      p_value Term Df Df.res    Sum Sq Sum Sq.res  F value
#> 1      A  7.833677  1 0.0088775925    A  1     30  802.7778   3074.333 7.833677
#> 2      B  8.948476  2 0.0008957788    B  2     30 1441.5000   2416.333 8.948476
#> 3    A:B  3.829436  2 0.0330224447  A:B  2     30  786.0556   3079.000 3.829436
#>         Pr(>F)
#> 1 0.0088775925
#> 2 0.0008957788
#> 3 0.0330224447
#> 
#> $fits$permuco
#> agriRank fit
#>   Design: factorial
#>   Method: permuco permutation ANOVA on mid-ranks
#>   Response: yield
#>   Resampling replicates: 1999
#>   effect statistic df     p_value       SS        F parametric P(>F)
#> 1      A  6.933889  1 0.015007504 498.7778 6.933889      0.013240580
#> 2      B  6.674004  2 0.005502751 960.1667 6.674004      0.004002043
#> 3    A:B  1.863222  2 0.184092046 268.0556 1.863222      0.172687331
#>   resampled P(>F)
#> 1     0.015007504
#> 2     0.005502751
#> 3     0.184092046
#> 
#> 
#> $interpretation
#> [1] "Differences across methods quantify model sensitivity. They must not be used to choose the smallest p-value."
#> 
#> attr(,"class")
#> [1] "agri_sensitivity"
```
