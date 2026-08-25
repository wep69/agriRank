# Validate an agricultural experimental design

Checks missing design variables, all-missing responses, empty factorial
cells, duplicated repeated cells, numeric block coding, and other
structural problems before inference.

## Usage

``` r
validate_agri_design(x, error = TRUE)
```

## Arguments

- x:

  An agriRank design or fitted object as documented for the function.

- error:

  Logical; if \`TRUE\`, fatal design-validation problems stop execution.

## Details

Fatal structural errors can stop execution; warnings preserve
information that may affect estimability or interpretation. The vignette
suite documents the experimental-design logic, estimand, hypothesis,
resampling structure, missing/unbalanced-data behavior, and
backend-specific limitations in greater depth.

## Value

An \`agri_validation\` list with \`ok\` and a table of problems.

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
validate_agri_design(agri_design(yield ~ treatment, simulate_agri("crd"), "crd"), error = FALSE)
#> $ok
#> [1] TRUE
#> 
#> $problems
#> [1] severity code     message 
#> <0 rows> (or 0-length row.names)
#> 
#> attr(,"class")
#> [1] "agri_validation"

# Example 2
x <- simulate_agri("factorial");
x <- subset(x, !(A=="A2" & B=="B3"));
validate_agri_design(agri_design(yield~A*B,x,"factorial"), error=FALSE)
#> $ok
#> [1] TRUE
#> 
#> $problems
#>   severity                 code
#> 1  warning empty_factorial_cell
#>                                                                              message
#> 1 At least one factorial treatment cell is empty; some effects may be non-estimable.
#> 
#> attr(,"class")
#> [1] "agri_validation"

# Example 3
x <- simulate_agri("repeated");
x <- rbind(x,x[1,]);
validate_agri_design(agri_design(height ~ treatment * time, x, "repeated", 
    subject = subject, within = time), error = FALSE)
#> $ok
#> [1] FALSE
#> 
#> $problems
#>   severity                    code
#> 1    error duplicate_repeated_cell
#>                                                                                                                                                                           message
#> 1 A subject has more than one observation for the same within-subject cell within its between-subject treatment group. Aggregate technical replicates explicitly before analysis.
#> 
#> attr(,"class")
#> [1] "agri_validation"
```
