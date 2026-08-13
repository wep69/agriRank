## Test environments

* Local: Windows 11, R 4.6.0 (2026-04-24 ucrt), x86_64-w64-mingw32, Rtools 45
* win-builder: R-devel, R-release
* macbuilder: R-release

## R CMD check results

Local `R CMD check --as-cran`: 0 errors, 0 warnings, 2 notes.

### Note 1: New submission and ORCID identifiers

```
New submission
Found the following (possibly) invalid ORCID iDs:
  iD: 0000-0003-1085-0191   (from: DESCRIPTION)
  iD: 0009-0009-5419-959X   (from: DESCRIPTION)
```

This is a new submission.

Both ORCID identifiers are correct. Their check digits were verified against the
ISO 7064 MOD 11-2 algorithm used by the ORCID standard: 0000-0003-1085-0191
gives check digit 1, and 0009-0009-5419-959X gives check digit X. The note is
raised because the check process on the submitting machine has no outbound
network access to orcid.org.

### Note 2: pandoc not available locally

```
Files 'README.md' or 'NEWS.md' cannot be checked without 'pandoc' being installed.
```

Local environment limitation. Pandoc is available to the vignette engine through
Quarto but is not on the PATH of the check process.

## Additional information

* All 27 optional backends listed under Suggests were installed for the check,
  so no test or example was skipped.
* Test suite: 486 expectations, 0 failures. Line coverage 86.5%.
* All 18 vignettes are executed at build time (36 s total on the local machine).
* The package has no compiled code and no external system requirements.

## Downstream dependencies

None. This is a new submission.
