# Estimate power by simulation

Simulates the full intended analysis workflow and estimates rejection
probability with Monte Carlo uncertainty.

## Usage

``` r
agri_power(generator, analyzer, nsim = 1000, alpha = 0.05, seed = 1)
```

## Arguments

- generator:

  Function receiving simulation index \`i\` and returning one synthetic
  data frame.

- analyzer:

  Function receiving one synthetic data frame and returning a p-value or
  an \`agri_rank_fit\`.

- nsim:

  Number of simulated experiments.

- alpha:

  Significance threshold used to derive a compact letter display.

- seed:

  Random seed used for reproducible resampling.

## Details

The result is specific to the supplied generator and analyzer. The
vignette suite documents the experimental-design logic, estimand,
hypothesis, resampling structure, missing/unbalanced-data behavior, and
backend-specific limitations in greater depth.

## Value

An \`agri_power\` object.

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
G<-function(i) simulate_agri("crd",seed=100+i);
A<-function(z) np_crd(yield~treatment,z)$omnibus$p_value[1];
agri_power(G,A,nsim=30)
#> $power
#> [1] 0.1333333
#> 
#> $mc_se
#> [1] 0.06206329
#> 
#> $nsim_requested
#> [1] 30
#> 
#> $nsim_success
#> [1] 30
#> 
#> $alpha
#> [1] 0.05
#> 
#> $p_values
#>  [1] 0.20642030 0.75780503 0.15999196 0.68843852 0.35324881 0.24133019
#>  [7] 0.18389510 0.04798053 0.05620381 0.19348638 0.03948350 0.05263627
#> [13] 0.68843852 0.14557655 0.02222327 0.12035463 0.09045460 0.11456613
#> [19] 0.39679312 0.02650445 0.15637852 0.71808256 0.64885536 0.17326751
#> [25] 0.25086644 0.13509367 0.37349103 0.50743154 0.46572961 0.23342162
#> 
#> $seed
#> [1] 1
#> 
#> attr(,"class")
#> [1] "agri_power"

# Example 2
G<-function(i) simulate_agri("rcbd",seed=200+i);
A<-function(z) np_rcbd(yield~treatment,z,block);
agri_power(G,A,nsim=30)
#> $power
#> [1] 0.7666667
#> 
#> $mc_se
#> [1] 0.07722022
#> 
#> $nsim_requested
#> [1] 30
#> 
#> $nsim_success
#> [1] 30
#> 
#> $alpha
#> [1] 0.05
#> 
#> $p_values
#>  [1] 0.003190422 0.002192438 0.005586546 0.004636605 0.283886131 0.012858001
#>  [7] 0.002905153 0.283886131 0.060184324 0.003503416 0.012858001 0.012858001
#> [13] 0.065789053 0.001816649 0.003846794 0.002192438 0.002192438 0.029290887
#> [19] 0.078553160 0.007383161 0.005586546 0.035110116 0.078553160 0.011725876
#> [25] 0.001816649 0.003190422 0.003190422 0.171797144 0.003846794 0.002905153
#> 
#> $seed
#> [1] 1
#> 
#> attr(,"class")
#> [1] "agri_power"

# Example 3
G<-function(i) simulate_agri("crd",seed=300+i,n=8);
A<-function(z) np_crd(yield~treatment,z)$omnibus$p_value[1];
agri_power(G,A,nsim=30,alpha=.01)
#> $power
#> [1] 0.1333333
#> 
#> $mc_se
#> [1] 0.06206329
#> 
#> $nsim_requested
#> [1] 30
#> 
#> $nsim_success
#> [1] 30
#> 
#> $alpha
#> [1] 0.01
#> 
#> $p_values
#>  [1] 0.042780967 0.095674152 0.132810981 0.710737066 0.586078586 0.167480376
#>  [7] 0.302801184 0.027925501 0.262385902 0.342379310 0.658230894 0.039822757
#> [13] 0.041223238 0.006976198 0.198293194 0.005286039 0.197818001 0.305966639
#> [19] 0.589681108 0.121546533 0.075135443 0.108205481 0.019838736 0.003565401
#> [25] 0.014896406 0.002700003 0.178792111 0.479929553 0.073084278 0.064586641
#> 
#> $seed
#> [1] 1
#> 
#> attr(,"class")
#> [1] "agri_power"
```
