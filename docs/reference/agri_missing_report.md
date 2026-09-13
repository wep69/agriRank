# Characterize missing response observations

Summarizes missingness overall and, for repeated data, by subject,
occasion, pattern, and monotone-dropout structure.

## Usage

``` r
agri_missing_report(x, response = NULL, subject = NULL, within = NULL)
```

## Arguments

- x:

  An agriRank design or fitted object as documented for the function.

- response:

  Optional response column name when a design contains more than one
  response.

- subject:

  Experimental-unit identifier for repeated or multivariate
  observations.

- within:

  Within-subject factor(s), usually time or measurement occasion.

## Details

The missingness mechanism cannot be established from observed data
alone. The vignette suite documents the experimental-design logic,
estimand, hypothesis, resampling structure, missing/unbalanced-data
behavior, and backend-specific limitations in greater depth.

## Value

An \`agri_missing_report\` list.

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
x<-simulate_agri("repeated_missing");
d<-agri_design(height~treatment*time,x,"repeated",subject=subject,within=time);
agri_missing_report(d)
#> $response
#> [1] "height"
#> 
#> $n_rows
#> [1] 48
#> 
#> $n_missing
#> [1] 15
#> 
#> $missing_rate
#> [1] 0.3125
#> 
#> $missing_rows
#>  [1] 10 13 14 15 20 23 26 28 30 33 34 39 40 43 48
#> 
#> $assumption_note
#> [1] "The missingness mechanism cannot be established from observed data alone. MCAR/MAR/MNAR assumptions require scientific justification and sensitivity analysis."
#> 
#> $repeated
#> $repeated$n_subjects
#> [1] 12
#> 
#> $repeated$n_occasions
#> [1] 4
#> 
#> $repeated$complete_subjects
#> [1] 2
#> 
#> $repeated$incomplete_subjects
#> [1] 10
#> 
#> $repeated$subjects_with_no_observed_response
#> [1] 0
#> 
#> $repeated$observed_by_occasion
#>  1  2  3  4 
#> 10  7  8  8 
#> 
#> $repeated$missing_rate_by_occasion
#>         1         2         3         4 
#> 0.1666667 0.4166667 0.3333333 0.3333333 
#> 
#> $repeated$pattern_counts
#> patterns
#> 1011 1101 1110 1111 0001 0011 1010 1100 
#>    2    2    2    2    1    1    1    1 
#> 
#> $repeated$monotone_subjects
#> [1] 5
#> 
#> $repeated$nonmonotone_subjects
#> [1] 7
#> 
#> $repeated$observation_matrix
#>                 1     2     3     4
#> control@@1   TRUE  TRUE  TRUE  TRUE
#> control@@2   TRUE  TRUE  TRUE  TRUE
#> control@@3   TRUE FALSE  TRUE  TRUE
#> control@@4  FALSE FALSE FALSE  TRUE
#> control@@5   TRUE  TRUE  TRUE FALSE
#> control@@6   TRUE  TRUE FALSE  TRUE
#> treated@@7   TRUE FALSE  TRUE FALSE
#> treated@@8   TRUE FALSE  TRUE  TRUE
#> treated@@9  FALSE FALSE  TRUE  TRUE
#> treated@@10  TRUE  TRUE FALSE FALSE
#> treated@@11  TRUE  TRUE FALSE  TRUE
#> treated@@12  TRUE  TRUE  TRUE FALSE
#> 
#> 
#> attr(,"class")
#> [1] "agri_missing_report"

# Example 2
x<-simulate_agri("repeated_missing",missing_rate=.25);
agri_missing_report(x,"height","subject","time")
#> $response
#> [1] "height"
#> 
#> $n_rows
#> [1] 48
#> 
#> $n_missing
#> [1] 17
#> 
#> $missing_rate
#> [1] 0.3541667
#> 
#> $missing_rows
#>  [1] 10 13 14 15 20 23 25 26 28 29 30 33 34 39 40 43 48
#> 
#> $assumption_note
#> [1] "The missingness mechanism cannot be established from observed data alone. MCAR/MAR/MNAR assumptions require scientific justification and sensitivity analysis."
#> 
#> $repeated
#> $repeated$n_subjects
#> [1] 12
#> 
#> $repeated$n_occasions
#> [1] 4
#> 
#> $repeated$complete_subjects
#> [1] 2
#> 
#> $repeated$incomplete_subjects
#> [1] 10
#> 
#> $repeated$subjects_with_no_observed_response
#> [1] 0
#> 
#> $repeated$observed_by_occasion
#> 1 2 3 4 
#> 8 7 8 8 
#> 
#> $repeated$missing_rate_by_occasion
#>         1         2         3         4 
#> 0.3333333 0.4166667 0.3333333 0.3333333 
#> 
#> $repeated$pattern_counts
#> patterns
#> 0011 1101 1110 1111 0001 0010 1011 1100 
#>    2    2    2    2    1    1    1    1 
#> 
#> $repeated$monotone_subjects
#> [1] 5
#> 
#> $repeated$nonmonotone_subjects
#> [1] 7
#> 
#> $repeated$observation_matrix
#>        1     2     3     4
#> 1   TRUE  TRUE  TRUE  TRUE
#> 2   TRUE  TRUE  TRUE  TRUE
#> 3   TRUE FALSE  TRUE  TRUE
#> 4  FALSE FALSE FALSE  TRUE
#> 5   TRUE  TRUE  TRUE FALSE
#> 6   TRUE  TRUE FALSE  TRUE
#> 7  FALSE FALSE  TRUE FALSE
#> 8  FALSE FALSE  TRUE  TRUE
#> 9  FALSE FALSE  TRUE  TRUE
#> 10  TRUE  TRUE FALSE FALSE
#> 11  TRUE  TRUE FALSE  TRUE
#> 12  TRUE  TRUE  TRUE FALSE
#> 
#> 
#> attr(,"class")
#> [1] "agri_missing_report"

# Example 3
x<-simulate_agri("crd"); x$yield[1:2]<-NA; agri_missing_report(x,"yield")
#> $response
#> [1] "yield"
#> 
#> $n_rows
#> [1] 24
#> 
#> $n_missing
#> [1] 2
#> 
#> $missing_rate
#> [1] 0.08333333
#> 
#> $missing_rows
#> [1] 1 2
#> 
#> $assumption_note
#> [1] "The missingness mechanism cannot be established from observed data alone. MCAR/MAR/MNAR assumptions require scientific justification and sensitivity analysis."
#> 
#> attr(,"class")
#> [1] "agri_missing_report"
```
