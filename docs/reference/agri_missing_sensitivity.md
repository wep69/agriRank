# Compare all-available and complete-subject repeated analyses

Runs the same native wild-rank paradigm on all available repeated
measurements and on complete subjects.

## Usage

``` r
agri_missing_sensitivity(x, B = 999, seed = 1, statistic = "ATS")
```

## Arguments

- x:

  An agriRank design or fitted object as documented for the function.

- B:

  Number of bootstrap or resampling replicates. Small values are for
  examples only.

- seed:

  Random seed used for reproducible resampling.

- statistic:

  Quadratic-form statistic, one of ATS, WTS, or MATS where supported.

## Details

Differences are sensitivity signals, not tests of MCAR, MAR, or MNAR.
The vignette suite documents the experimental-design logic, estimand,
hypothesis, resampling structure, missing/unbalanced-data behavior, and
backend-specific limitations in greater depth.

## Value

A list with comparison table and both fitted analyses.

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
x<-simulate_agri("repeated_missing",seed=101,n=14,missing_rate=.10);
d<-agri_design(height~treatment*time,x,"repeated",subject=subject,within=time);
agri_missing_sensitivity(d,B=299)

# Example 2
x<-simulate_agri("repeated_missing",seed=102,n=18,missing_rate=.25);
d<-agri_design(height~treatment*time,x,"repeated",subject=subject,within=time);
agri_missing_sensitivity(d,B=299,statistic="ATS")

# Example 3
x<-simulate_agri("repeated");
d<-agri_design(height~treatment*time,x,"repeated",subject=subject,within=time);
agri_missing_sensitivity(d)
```
