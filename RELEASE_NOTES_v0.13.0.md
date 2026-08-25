# NA

First public release.

## Install

Without vignettes, fast:

``` r

remotes::install_github("wep69/agriRank")
```

With vignettes, about a minute, needs Pandoc:

``` r

remotes::install_github("wep69/agriRank", build_vignettes = TRUE)
```

## Status

- `R CMD check` with CRAN settings: 0 errors, 0 warnings.
- macbuilder, R 4.6.1, macOS arm64: Status OK, no errors, warnings or
  notes.
- 486 test expectations, 0 failures, 86.5 percent line coverage.
- 18 vignettes, all executed at build time.
- Numerical identity verified against stats, PMCMRplus, ARTool, permuco,
  nparLD, MANOVA.RM, np, Iso and cgam.
- Regression module audited with 185 functional checks, including the
  integer decision workflow.

## Known limitation

Type-I error calibration is incomplete. The 500-replicate pilot under
`inst/calibration` found that the permuco adapters for split-split-plot
and strip-plot reject at a rate near zero under the null hypothesis. A
test that never rejects under H0 also has almost no power under H1.
Prefer ART for confirmatory inference in those two designs until the
full 10000-replicate study is finished. The native incomplete
repeated-measures engine keeps its experimental label for the same
reason.

## Assets

- `agriRank_0.13.0.tar.gz`, the source package.
- Cheat sheets in Portuguese and English.
