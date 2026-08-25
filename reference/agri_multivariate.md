# Integrated multivariate resampling inference

Routes multivariate analyses through MANOVA.RM and returns a common
\`agri_multivariate_fit\` object accepted by agriRank tables, reports,
dashboards and exports.

## Usage

``` r
agri_multivariate(formula, data, subject = NULL, within = NULL, 
    block = NULL, resampling = "WildBS", iter = 4999, seed = 1, 
    ...)
```

## Arguments

- formula:

  Model formula. Use \`cbind(y1, y2, ...) ~ ...\` for wide multivariate
  responses.

- data:

  Data frame.

- subject:

  Subject/unit identifier for long-format MANOVA or multivariate
  repeated measures.

- within:

  Optional within-subject factor(s); with multiple responses this routes
  to
  [`MANOVA.RM::multRM()`](https://rdrr.io/pkg/MANOVA.RM/man/multRM.html).
  The declared within factors are enforced in the fitted formula after
  the between-subject factors.

- block:

  Optional agronomic block adjustment. If omitted from the formula it is
  added as an adjustment factor.

- resampling:

  Resampling scheme passed to MANOVA.RM.

- iter:

  Number of resampling iterations.

- seed:

  Reproducible seed.

- ...:

  Additional backend arguments.

## Details

Multiple responses without `within` use
[`MANOVA.RM::MANOVA.wide()`](https://rdrr.io/pkg/MANOVA.RM/man/MANOVA.wide.html).
A single long-format response with `subject` uses
[`MANOVA.RM::MANOVA()`](https://rdrr.io/pkg/MANOVA.RM/man/MANOVA.html).
Multiple responses plus `within` use
[`MANOVA.RM::multRM()`](https://rdrr.io/pkg/MANOVA.RM/man/multRM.html).
For the multivariate repeated-measures route, agriRank canonicalizes the
scientific formula so the between-subject factors precede the declared
within-subject factors and the full between-by-within factorial
structure is represented, as required by the MANOVA.RM interface.
Missing modeled values are rejected before fitting. Block adjustment is
treated as an additive model factor by the MANOVA.RM backend, not as a
random block effect.

## Value

An object of class \`agri_multivariate_fit\` containing the declared
design, standardized omnibus table, descriptive and covariance
components, backend object, seed and reproducibility metadata.

## References

Friedrich S, Konietschke F, Pauly M (2019). The R Journal 11(2),
380-400. DOI: 10.32614/RJ-2019-051. Friedrich S, Pauly M (2018). Journal
of Multivariate Analysis 165, 166-179.

## See also

`agri_table`, `agri_report`, `agri_multienv`

## Examples

``` r
if(requireNamespace("MANOVA.RM",quietly=TRUE)){set.seed(1);
x<-data.frame(trt=factor(rep(1:3,each=8)),y1=rnorm(24),y2=rnorm(24));
z<-agri_multivariate(cbind(y1,y2)~trt,x,iter=99);
print(z)}
#> agriRank multivariate fit
#>   Mode: MANOVA.wide
#>   Method: MANOVA.RM::MANOVA.wide (WildBS)
#>   Responses: y1, y2
#>   Test statistic df p-value statistic_family effect WildBS (WTS) WildBS (MATS)
#> 1          0.351  4   0.986              WTS    trt           NA            NA
#> 2          0.227 NA      NA             MATS    trt           NA            NA
#> 3             NA NA      NA       resampling    trt            1             1
if(requireNamespace("MANOVA.RM",quietly=TRUE)){set.seed(2);
x <- data.frame(block = factor(rep(1:4, each = 6)), trt = factor(rep(rep(1:3, 
    each = 2), 4)), y1 = rnorm(24), y2 = rnorm(24))
z<-agri_multivariate(cbind(y1,y2)~trt,x,block=block,iter=99);
agri_table(z)}
#> Warning: The covariance matrix is singular. The WTS provides no valid test statistic!


  

Test statistic
```
