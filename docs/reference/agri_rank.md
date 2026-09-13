# Fit design-aware rank-based or permutation inference

Routes a declared design to an explicit or automatically selected
admissible engine. The omnibus test comes back in a canonical shape, so
a report reads the same table whichever backend ran.

## Usage

``` r
agri_rank(design, method = "auto", response = NULL, 
    estimand = c("relative_effect", "distribution", 
        "location_shift"), B = 1999, seed = 1, missing_assumption = c("unspecified", 
        "MCAR", "MAR-sensitivity"), ...)
```

## Arguments

- design:

  A declared design type or an \`agri_design\` object, depending on
  context.

- method:

  Inferential engine name or \`"auto"\` for conservative design-based
  routing.

- response:

  Optional response column name when a design contains more than one
  response.

- estimand:

  Target effect representation. It selects the estimator reported by
  [`agri_effects()`](https://wep69.github.io/agriRank/reference/agri_effects.md):
  the Brunner-Munzel relative effect for `"relative_effect"`, the
  Hodges-Lehmann shift against the first level for `"location_shift"`,
  and the descriptive distribution summary for `"distribution"`.

- B:

  Number of resampling replicates for the engines that resample. It
  reaches the native wild bootstrap directly, `permuco` as `np` and
  `MANOVA.RM` as `iter`. An engine that cannot use it warns when `B` is
  supplied, and a value below 999 warns because the smallest attainable
  p-value is `1/(B + 1)`. The number that actually ran is recorded in
  `fit$resampling`.

- seed:

  Random seed used for reproducible resampling.

- missing_assumption:

  Label recording the assumed missingness framework; this is not
  inferred from the data.

- ...:

  Additional arguments passed to the selected backend or downstream
  method.

## Details

Automatic routing is design-driven; it does not select a method from a
preliminary normality p-value. Blocked incomplete repeated measures are
deliberately rejected in the current build. The vignette suite documents
the experimental-design logic, estimand, hypothesis, resampling
structure, missing/unbalanced-data behavior, and backend-specific
limitations in greater depth.

The `omnibus` component always carries the columns `effect`,
`statistic`, `df` and `p_value`, with the columns the backend itself
reports kept beside them, so existing engine-specific readers keep
working. When a backend separates a parametric from a resampled p-value,
`p_value` is the resampled one, because it is the value the user asked
for by choosing a resampling engine; the parametric value survives in
its own column and
[`agri_p()`](https://wep69.github.io/agriRank/reference/agri_p.md) reads
either. Error-stratum rows such as `Residuals` are not tests and stay
out of `omnibus`; the untouched backend table remains in `fit$raw`.

## Value

An \`agri_rank_fit\` object whose \`omnibus\` table carries the
canonical columns \`effect\`, \`statistic\`, \`df\` and \`p_value\`,
together with the columns reported by the selected backend. The fields
\`B\`, \`resampling\` and \`resampling_used\` record the replicate count
requested, the count that actually ran, and whether the engine could use
one.

## References

Pauly M, Brunner E, Konietschke F (2015), DOI: 10.1111/rssb.12073.
Brunner E, Konietschke F, Pauly M, Puri ML (2017), DOI:
10.1111/rssb.12222. Konietschke F, Brunner E (2023), DOI:
10.32614/RJ-2023-029. See the package vignettes and
\`inst/references/agriRank-methods-verified.ris\` for engine-specific
verified references.

## See also

`agri_design`, `agri_rank`, `agri_effects`, `agri_p`, `agri_report`

## Examples

``` r
# Example 1
d<-agri_design(yield~treatment,simulate_agri("crd"),"crd"); agri_rank(d)

# Example 2
x<-simulate_agri("factorial");
d<-agri_design(yield~A*B,x,"factorial");
if(requireNamespace("rankFD",quietly=TRUE)) agri_rank(d,"rankFD")

# Example 3
x<-simulate_agri("repeated_missing");
d<-agri_design(height~treatment*time,x,"repeated",subject=subject,within=time);
agri_rank(d,"incomplete_wild",B=999,missing_assumption="MCAR")
```
