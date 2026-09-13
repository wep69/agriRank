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
information that may affect estimability or interpretation. The scope of
this check is the response and the occupation of the factorial cells,
not the integrity of the declared randomization: a design that is broken
structurally can still return `ok = TRUE` here and be refused later,
with a specific reason, by the engine that would have to analyze it.
Fitting is therefore the step that validates the structure. The vignette
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

# Example 2
x <- simulate_agri("factorial");
x <- subset(x, !(A=="A2" & B=="B3"));
validate_agri_design(agri_design(yield~A*B,x,"factorial"), error=FALSE)

# Example 3
x <- simulate_agri("repeated");
x <- rbind(x,x[1,]);
validate_agri_design(agri_design(height ~ treatment * time, x, "repeated", 
    subject = subject, within = time), error = FALSE)
```
