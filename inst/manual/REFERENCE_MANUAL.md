# agriRank Reference Manual

**Version:** 0.12.0.9000  
**Documentation language:** English  
**Updated:** 2026-08-12

This long-form manual complements the `.Rd` reference pages. The organizing rule is design -> estimand -> admissible inference -> effects/contrasts -> visualization -> reporting. Each exported function has three examples: minimal, agronomic, and advanced/integrated.

## Statistical documentation policy

- Never use a preliminary normality p-value as an automatic switch between ANOVA and a rank test.
- Preserve the experimental unit and randomization strata.
- State the estimand before interpreting a test.
- Report effect estimates and uncertainty whenever available.
- Do not infer MCAR/MAR/MNAR from observed missingness patterns alone.
- Treat compact letter displays as secondary summaries.
- Record backend, seed, resampling count, and package versions.

## 1. `agri_design()` — Declare an agricultural experimental design

Creates the design object that records the treatment formula, randomization strata, repeated-measures identifiers, quantitative treatments, and structural validation information.

**Statistical role.** Design declaration itself performs no treatment test. The object is the contract used by downstream analysis functions.

**Returns.** An object of class `agri_design`.

**Three examples**

### Example 1

```r
d <- agri_design(yield ~ treatment, simulate_agri("crd"), design = "crd")
```

### Example 2

```r
x <- simulate_agri("rcbd"); d <- agri_design(yield ~ treatment, x, design = "rcbd", block = block)
```

### Example 3

```r
x <- simulate_agri("repeated"); d <- agri_design(height ~ treatment * time, x, design = "repeated", subject = subject, within = time)
```

## 2. `validate_agri_design()` — Validate an agricultural experimental design

Checks missing design variables, all-missing responses, empty factorial cells, duplicated repeated cells, numeric block coding, and other structural problems before inference.

**Statistical role.** Fatal structural errors can stop execution; warnings preserve information that may affect estimability or interpretation.

**Returns.** An `agri_validation` list with `ok` and a table of problems.

**Three examples**

### Example 1

```r
validate_agri_design(agri_design(yield ~ treatment, simulate_agri("crd"), "crd"), error = FALSE)
```

### Example 2

```r
x <- simulate_agri("factorial"); x <- subset(x, !(A=="A2" & B=="B3")); validate_agri_design(agri_design(yield~A*B,x,"factorial"), error=FALSE)
```

### Example 3

```r
x <- simulate_agri("repeated"); x <- rbind(x,x[1,]); validate_agri_design(agri_design(height~treatment*time,x,"repeated",subject=subject,within=time), error=FALSE)
```

## 3. `design_summary()` — Summarize a declared agricultural design

Returns a compact machine-readable summary of the randomization and data structure.

**Statistical role.** Useful for reports and quality-control pipelines.

**Returns.** A list.

**Three examples**

### Example 1

```r
design_summary(agri_design(yield~treatment,simulate_agri("crd"),"crd"))
```

### Example 2

```r
x<-simulate_agri("rcbd"); design_summary(agri_design(yield~treatment,x,"rcbd",block=block))
```

### Example 3

```r
x<-simulate_agri("repeated"); design_summary(agri_design(height~treatment*time,x,"repeated",subject=subject,within=time))
```

## 4. `agri_methods()` — List available inferential domains and engines

Provides a compact registry of implemented and adapter-backed methods.

**Statistical role.** Availability of optional engines still depends on installed Suggested packages.

**Returns.** A data frame.

**Three examples**

### Example 1

```r
agri_methods()
```

### Example 2

```r
subset(agri_methods(), grepl("repeated", domain))
```

### Example 3

```r
subset(agri_methods(), grepl("implemented", status))
```

## 5. `agri_rank()` — Fit design-aware rank-based or permutation inference

Routes a declared design to an explicit or automatically selected admissible engine.

**Statistical role.** Automatic routing is design-driven; it does not select a method from a preliminary normality p-value. Blocked incomplete repeated measures are deliberately rejected in the current build.

**Returns.** An `agri_rank_fit` object.

**Three examples**

### Example 1

```r
d<-agri_design(yield~treatment,simulate_agri("crd"),"crd"); agri_rank(d)
```

### Example 2

```r
x<-simulate_agri("factorial"); d<-agri_design(yield~A*B,x,"factorial"); if(requireNamespace("rankFD",quietly=TRUE)) agri_rank(d,"rankFD")
```

### Example 3

```r
x<-simulate_agri("repeated_missing"); d<-agri_design(height~treatment*time,x,"repeated",subject=subject,within=time); agri_rank(d,"incomplete_wild",B=299,missing_assumption="MCAR")
```

## 6. `np_crd()` — Analyze a completely randomized design

Convenience wrapper around `agri_design()` and `agri_rank()` for CRD data.

**Statistical role.** Use the full API when explicit design metadata are needed.

**Returns.** An `agri_rank_fit`.

**Three examples**

### Example 1

```r
np_crd(yield~treatment,simulate_agri("crd"))
```

### Example 2

```r
x<-simulate_agri("crd"); x$score<-round(x$yield); np_crd(score~treatment,x,"kruskal")
```

### Example 3

```r
x<-simulate_agri("crd"); np_crd(yield~treatment,x[-c(1,2),])
```

## 7. `np_rcbd()` — Analyze a randomized complete block design

Convenience wrapper for one- or multifactor treatment structures randomized within blocks.

**Statistical role.** The block is part of the randomization and must not be discarded because of a preliminary significance test.

**Returns.** An `agri_rank_fit`.

**Three examples**

### Example 1

```r
x<-simulate_agri("rcbd"); np_rcbd(yield~treatment,x,block)
```

### Example 2

```r
x<-simulate_agri("rcbd"); x$score<-round(x$yield); np_rcbd(score~treatment,x,block,"friedman")
```

### Example 3

```r
x<-simulate_agri("rcbd",n=8); np_rcbd(yield~treatment,x,block,"friedman")
```

## 8. `np_factorial()` — Analyze a nonparametric factorial experiment

Convenience wrapper for factorial treatment structures with or without blocks.

**Statistical role.** For unbalanced independent factorial designs, pseudo-rank methods are generally preferable when unweighted relative effects are the estimand.

**Returns.** An `agri_rank_fit`.

**Three examples**

### Example 1

```r
x<-simulate_agri("factorial"); np_factorial(yield~A*B,x)
```

### Example 2

```r
x<-simulate_agri("factorial"); if(requireNamespace("rankFD",quietly=TRUE)) np_factorial(yield~A*B,x,method="rankFD")
```

### Example 3

```r
x<-simulate_agri("factorial"); if(requireNamespace("ARTool",quietly=TRUE)) np_factorial(yield~A*B,x,method="ART")
```

## 9. `np_splitplot()` — Analyze a split-plot experiment

Declares whole-plot and subplot strata before dispatching to a compatible backend.

**Statistical role.** A split-plot design contains hierarchical randomization and must not be analyzed as a simple CRD.

**Returns.** An `agri_rank_fit`.

**Three examples**

### Example 1

```r
x<-simulate_agri("split_plot"); if(requireNamespace("permuco",quietly=TRUE)) np_splitplot(yield~irrigation*cultivar,x,block,irrigation,cultivar,"permuco")
```

### Example 2

```r
x<-simulate_agri("split_plot"); if(requireNamespace("ARTool",quietly=TRUE)) np_splitplot(yield~irrigation*cultivar,x,block,irrigation,cultivar,"ART")
```

### Example 3

```r
x<-simulate_agri("split_plot"); if(requireNamespace("permuco",quietly=TRUE)||requireNamespace("ARTool",quietly=TRUE)) np_splitplot(yield~irrigation*cultivar,x,block,irrigation,cultivar)
```

## 10. `np_repeated()` — Analyze repeated measurements

Convenience wrapper that declares subject and within-subject factors before fitting repeated-measures inference.

**Statistical role.** Repeated observations from one subject are dependent.

**Returns.** An `agri_rank_fit`.

**Three examples**

### Example 1

```r
x<-simulate_agri("repeated"); np_repeated(height~treatment*time,x,subject,time)
```

### Example 2

```r
x<-simulate_agri("repeated"); if(requireNamespace("nparLD",quietly=TRUE)) np_repeated(height~treatment*time,x,subject,time,method="nparLD")
```

### Example 3

```r
x<-simulate_agri("repeated_missing"); np_repeated(height~treatment*time,x,subject,time,method="incomplete_wild",B=299,missing_assumption="MCAR")
```

## 11. `agri_repeated()` — Analyze repeated measurements with explicit backend selection

Provides a dedicated repeated-measures router for nparLD, MANOVA.RM, permuco, and the native incomplete wild-rank engine.

**Statistical role.** The current native incomplete engine is unblocked; blocked incomplete repeated data are not silently simplified.

**Returns.** An `agri_rank_fit`.

**Three examples**

### Example 1

```r
x<-simulate_agri("repeated"); d<-agri_design(height~treatment*time,x,"repeated",subject=subject,within=time); if(requireNamespace("nparLD",quietly=TRUE)) agri_repeated(d,"nparLD")
```

### Example 2

```r
x<-simulate_agri("repeated"); d<-agri_design(height~treatment*time,x,"repeated",subject=subject,within=time); if(requireNamespace("MANOVA.RM",quietly=TRUE)) agri_repeated(d,"MANOVA.RM",iter=499)
```

### Example 3

```r
x<-simulate_agri("repeated_missing"); d<-agri_design(height~treatment*time,x,"repeated",subject=subject,within=time); agri_repeated(d,"native_wild",B=299,missing_assumption="MCAR")
```

## 12. `agri_missing_report()` — Characterize missing response observations

Summarizes missingness overall and, for repeated data, by subject, occasion, pattern, and monotone-dropout structure.

**Statistical role.** The missingness mechanism cannot be established from observed data alone.

**Returns.** An `agri_missing_report` list.

**Three examples**

### Example 1

```r
x<-simulate_agri("repeated_missing"); d<-agri_design(height~treatment*time,x,"repeated",subject=subject,within=time); agri_missing_report(d)
```

### Example 2

```r
x<-simulate_agri("repeated_missing",missing_rate=.25); agri_missing_report(x,"height","subject","time")
```

### Example 3

```r
x<-simulate_agri("crd"); x$yield[1:2]<-NA; agri_missing_report(x,"yield")
```

## 13. `agri_missing_sensitivity()` — Compare all-available and complete-subject repeated analyses

Runs the same native wild-rank paradigm on all available repeated measurements and on complete subjects.

**Statistical role.** Differences are sensitivity signals, not tests of MCAR, MAR, or MNAR.

**Returns.** A list with comparison table and both fitted analyses.

**Three examples**

### Example 1

```r
x<-simulate_agri("repeated_missing",missing_rate=.10); d<-agri_design(height~treatment*time,x,"repeated",subject=subject,within=time); agri_missing_sensitivity(d,B=299)
```

### Example 2

```r
x<-simulate_agri("repeated_missing",missing_rate=.25); d<-agri_design(height~treatment*time,x,"repeated",subject=subject,within=time); agri_missing_sensitivity(d,B=299,statistic="ATS")
```

### Example 3

```r
x<-simulate_agri("repeated"); d<-agri_design(height~treatment*time,x,"repeated",subject=subject,within=time); agri_missing_sensitivity(d)
```

## 14. `agri_effects()` — Extract treatment effect summaries

Returns backend-provided effects when available or observed-cell descriptive rank summaries otherwise.

**Statistical role.** Interpret the returned effect according to the engine and estimand.

**Returns.** A data frame.

**Three examples**

### Example 1

```r
fit<-np_crd(yield~treatment,simulate_agri("crd")); agri_effects(fit)
```

### Example 2

```r
fit<-np_crd(yield~treatment,simulate_agri("crd")); agri_effects(fit,ci=TRUE,B=199)
```

### Example 3

```r
x<-simulate_agri("factorial"); if(requireNamespace("rankFD",quietly=TRUE)){fit<-np_factorial(yield~A*B,x,method="rankFD"); agri_effects(fit)}
```

## 15. `agri_pairs()` — Compute pairwise treatment comparisons

Provides ordinary pairwise comparisons or simultaneous maxT comparisons for the native repeated wild-rank engine.

**Statistical role.** In factorial experiments use `by` to obtain scientifically meaningful simple effects where appropriate.

**Returns.** A data frame.

**Three examples**

### Example 1

```r
fit<-np_crd(yield~treatment,simulate_agri("crd")); agri_pairs(fit)
```

### Example 2

```r
x<-simulate_agri("factorial"); f<-np_factorial(yield~A*B,x); agri_pairs(f,by="B")
```

### Example 3

```r
x<-simulate_agri("repeated_missing"); d<-agri_design(height~treatment*time,x,"repeated",subject=subject,within=time); f<-agri_rank(d,"incomplete_wild",B=299,missing_assumption="MCAR"); agri_pairs(f,factor="time",by="treatment",B=299)
```

## 16. `agri_contrast()` — Test user-defined contrasts

Tests arbitrary contrast matrices for the native incomplete repeated wild-rank engine with simultaneous resampling calibration.

**Statistical role.** General user-defined contrasts for other engines should currently be obtained from the backend object.

**Returns.** A data frame of contrast estimates and uncertainty.

**Three examples**

### Example 1

```r
x<-simulate_agri("repeated_missing"); d<-agri_design(height~treatment*time,x,"repeated",subject=subject,within=time); f<-agri_rank(d,"incomplete_wild",B=299,missing_assumption="MCAR"); k<-nrow(f$engine$prep$cell_grid); C<-matrix(c(1,-1,rep(0,k-2)),1); agri_contrast(f,C,B=299)
```

### Example 2

```r
x<-simulate_agri("repeated_missing"); d<-agri_design(height~treatment*time,x,"repeated",subject=subject,within=time); f<-agri_rank(d,"incomplete_wild",B=299,missing_assumption="MCAR"); k<-nrow(f$engine$prep$cell_grid); C<-rbind(c(1,-1,rep(0,k-2)),c(rep(0,2),1,-1,rep(0,k-4))); agri_contrast(f,C,B=299)
```

### Example 3

```r
x<-simulate_agri("repeated_missing"); d<-agri_design(height~treatment*time,x,"repeated",subject=subject,within=time); f<-agri_rank(d,"incomplete_wild",B=299,missing_assumption="MCAR"); k<-nrow(f$engine$prep$cell_grid); C<-diag(k)[1,,drop=FALSE]-diag(k)[k,,drop=FALSE]; agri_contrast(f,C,labels="first-last",B=299)
```

## 17. `agri_cld()` — Create a compact letter display

Summarizes multiplicity-adjusted ordinary pairwise comparisons as letters.

**Statistical role.** CLD is secondary to effect estimates and confidence intervals.

**Returns.** A data frame with groups and letters.

**Three examples**

### Example 1

```r
fit<-np_crd(yield~treatment,simulate_agri("crd")); if(requireNamespace("multcompView",quietly=TRUE)) agri_cld(fit)
```

### Example 2

```r
fit<-np_crd(yield~treatment,simulate_agri("crd")); if(requireNamespace("multcompView",quietly=TRUE)) agri_cld(fit,adjust="BH")
```

### Example 3

```r
fit<-np_crd(yield~treatment,simulate_agri("crd")); if(requireNamespace("multcompView",quietly=TRUE)) agri_cld(fit,alpha=.01)
```

## 18. `agri_sensitivity()` — Compare admissible inferential paradigms

Fits selected alternative engines and tabulates their effect-level p-values without choosing the smallest one.

**Statistical role.** Use to assess conclusion stability, not for method shopping.

**Returns.** An `agri_sensitivity` object.

**Three examples**

### Example 1

```r
x<-simulate_agri("factorial"); d<-agri_design(yield~A*B,x,"factorial"); agri_sensitivity(d)
```

### Example 2

```r
x<-simulate_agri("factorial"); d<-agri_design(yield~A*B,x,"factorial"); f<-agri_rank(d); agri_sensitivity(f,c("primary","ART"))
```

### Example 3

```r
x<-simulate_agri("factorial"); d<-agri_design(yield~A*B,x,"factorial"); agri_sensitivity(d,c("primary","ART","permuco"))
```

## 19. `agri_batch()` — Analyze multiple responses under one design

Fits the same declared design to several response columns, optionally adjusting p-values across responses.

**Statistical role.** Across-response multiplicity adjustment is explicit rather than automatic.

**Returns.** An `agri_batch` object.

**Three examples**

### Example 1

```r
x<-simulate_agri("crd"); x$biomass<-x$yield+rnorm(nrow(x)); d<-agri_design(yield~treatment,x,"crd"); agri_batch(d,c("yield","biomass"))
```

### Example 2

```r
x<-simulate_agri("crd"); x$biomass<-x$yield+rnorm(nrow(x)); d<-agri_design(yield~treatment,x,"crd"); agri_batch(d,c("yield","biomass"),adjust_across="BH")
```

### Example 3

```r
x<-simulate_agri("crd"); x$biomass<-x$yield+rnorm(nrow(x)); x$spad<-30+x$yield+rnorm(nrow(x)); d<-agri_design(yield~treatment,x,"crd"); agri_batch(d,c("yield","biomass","spad"),adjust_across="holm")
```

## 20. `agri_power()` — Estimate power by simulation

Simulates the full intended analysis workflow and estimates rejection probability with Monte Carlo uncertainty.

**Statistical role.** The result is specific to the supplied generator and analyzer.

**Returns.** An `agri_power` object.

**Three examples**

### Example 1

```r
G<-function(i) simulate_agri("crd",seed=100+i); A<-function(z) np_crd(yield~treatment,z)$omnibus$p_value[1]; agri_power(G,A,nsim=30)
```

### Example 2

```r
G<-function(i) simulate_agri("rcbd",seed=200+i); A<-function(z) np_rcbd(yield~treatment,z,block); agri_power(G,A,nsim=30)
```

### Example 3

```r
G<-function(i) simulate_agri("crd",seed=300+i,n=8); A<-function(z) np_crd(yield~treatment,z)$omnibus$p_value[1]; agri_power(G,A,nsim=30,alpha=.01)
```

## 21. `agri_trend()` — Test an ordered treatment trend

Uses permutation of rank association, restricted within blocks when a block is declared.

**Statistical role.** Treatment scores should encode the scientifically meaningful ordering.

**Returns.** A list with statistic and permutation p-value.

**Three examples**

### Example 1

```r
x<-simulate_agri("rcbd"); x$dose<-rep(c(0,50,100,150),times=6); d<-agri_design(yield~dose,x,"rcbd",block=block,quantitative=dose); agri_trend(d,B=299)
```

### Example 2

```r
x<-simulate_agri("rcbd"); x$dose<-rep(c(0,50,100,150),times=6); d<-agri_design(yield~dose,x,"rcbd",block=block,quantitative=dose); agri_trend(d,treatment=dose,B=299)
```

### Example 3

```r
x<-simulate_agri("rcbd"); x$dose<-rep(c(0,50,100,150),times=6); d<-agri_design(yield~dose,x,"rcbd",block=block,quantitative=dose); agri_trend(d,treatment=dose,scores=c(`0`=0,`50`=1,`100`=3,`150`=6),B=299)
```

## 22. `agri_ancova()` — Fit a permutation ANCOVA adapter

Uses `permuco` Freedman-Lane permutation ANCOVA, optionally on response mid-ranks.

**Statistical role.** This function is not the 2026 resampling NANCOVA method; that remains a future engine.

**Returns.** A list containing the fitted model and extracted omnibus table.

**Three examples**

### Example 1

```r
if(requireNamespace("permuco",quietly=TRUE)){x<-simulate_agri("crd"); x$base<-rnorm(nrow(x)); agri_ancova(yield~treatment,x,covariates=base,np=299)}
```

### Example 2

```r
if(requireNamespace("permuco",quietly=TRUE)){x<-simulate_agri("crd"); x$base<-rnorm(nrow(x)); agri_ancova(yield~treatment,x,covariates=base,np=299,rank_response=FALSE)}
```

### Example 3

```r
if(requireNamespace("permuco",quietly=TRUE)){x<-simulate_agri("rcbd"); x$base<-rnorm(nrow(x)); agri_ancova(yield~treatment,x,covariates=base,block=block,np=299)}
```

## 23. `agri_multivariate()` — Fit multivariate resampling inference

Adapter to `MANOVA.RM::MANOVA()` for multiple responses sharing an experimental-unit structure.

**Statistical role.** Interpret the multivariate global hypothesis before exploratory endpoint-specific follow-up.

**Returns.** The object returned by `MANOVA.RM::MANOVA()`.

**Three examples**

### Example 1

```r
if(requireNamespace("MANOVA.RM",quietly=TRUE)){x<-data.frame(id=factor(1:24),trt=factor(rep(1:3,each=8)),y1=rnorm(24),y2=rnorm(24)); agri_multivariate(cbind(y1,y2)~trt,x,id,iter=299)}
```

### Example 2

```r
if(requireNamespace("MANOVA.RM",quietly=TRUE)){x<-data.frame(id=factor(1:24),trt=factor(rep(1:3,each=8)),y1=rnorm(24),y2=rgamma(24,3)); agri_multivariate(cbind(y1,y2)~trt,x,id,resampling="WildBS",iter=299)}
```

### Example 3

```r
if(requireNamespace("MANOVA.RM",quietly=TRUE)){x<-data.frame(id=factor(1:24),trt=factor(rep(1:3,each=8)),y1=rnorm(24),y2=rnorm(24),y3=rnorm(24)); agri_multivariate(cbind(y1,y2,y3)~trt,x,id,iter=299)}
```

## 24. `agri_multienv()` — Analyze multi-environment treatment data

Declares environment and optional block information before fitting a rank/permutation workflow.

**Statistical role.** Genotype-by-environment interaction should be represented explicitly when scientifically relevant.

**Returns.** An `agri_rank_fit`.

**Three examples**

### Example 1

```r
x<-simulate_agri("multienv"); if(requireNamespace("ARTool",quietly=TRUE)||requireNamespace("permuco",quietly=TRUE)) agri_multienv(yield~genotype*environment,x,environment,block)
```

### Example 2

```r
x<-simulate_agri("multienv"); if(requireNamespace("ARTool",quietly=TRUE)) agri_multienv(yield~genotype*environment,x,environment,block,"ART")
```

### Example 3

```r
x<-simulate_agri("multienv"); if(requireNamespace("permuco",quietly=TRUE)) agri_multienv(yield~genotype*environment,x,environment,block,"permuco")
```

## 25. `agri_plot()` — Create publication-oriented ggplot graphics

Creates observed-data, effect, interaction, missingness, or contrast plots from agriRank objects.

**Statistical role.** Static ggplot output is intentionally editable with normal ggplot2 syntax.

**Returns.** A `ggplot` object.

**Three examples**

### Example 1

```r
x<-simulate_agri("crd"); d<-agri_design(yield~treatment,x,"crd"); agri_plot(d,"data")
```

### Example 2

```r
x<-simulate_agri("crd"); f<-np_crd(yield~treatment,x); agri_plot(f,"effects")
```

### Example 3

```r
x<-simulate_agri("factorial"); d<-agri_design(yield~A*B,x,"factorial"); agri_plot(d,"interaction")
```

## 26. `agri_interactive()` — Convert an agriRank plot to Plotly

Wraps `plotly::ggplotly()` around an `agri_plot()` result.

**Statistical role.** Intended for exploration and teaching; static ggplot remains the primary publication figure.

**Returns.** A Plotly htmlwidget.

**Three examples**

### Example 1

```r
x<-simulate_agri("crd"); f<-np_crd(yield~treatment,x); if(requireNamespace("plotly",quietly=TRUE)) agri_interactive(f,"data")
```

### Example 2

```r
x<-simulate_agri("crd"); f<-np_crd(yield~treatment,x); if(requireNamespace("plotly",quietly=TRUE)) agri_interactive(f,"effects")
```

### Example 3

```r
x<-simulate_agri("factorial"); d<-agri_design(yield~A*B,x,"factorial"); if(requireNamespace("plotly",quietly=TRUE)) agri_interactive(d,"interaction")
```

## 27. `agri_table()` — Create standardized analysis tables

Returns omnibus, effect, pairwise, or missingness tables and upgrades them to `gt` when available.

**Statistical role.** The table reflects only quantities available from the selected backend.

**Returns.** A data frame or `gt_tbl`.

**Three examples**

### Example 1

```r
f<-np_crd(yield~treatment,simulate_agri("crd")); agri_table(f,"omnibus")
```

### Example 2

```r
f<-np_crd(yield~treatment,simulate_agri("crd")); agri_table(f,"effects")
```

### Example 3

```r
f<-np_crd(yield~treatment,simulate_agri("crd")); agri_table(f,"missing")
```

## 28. `agri_report()` — Generate a reproducible analysis report

Writes Markdown/Quarto or renders HTML, Word, or PDF reports containing design, missingness, method, omnibus inference, and reproducibility information.

**Statistical role.** Rendered formats require Pandoc and rmarkdown.

**Returns.** The normalized path of the generated report.

**Three examples**

### Example 1

```r
f<-np_crd(yield~treatment,simulate_agri("crd")); agri_report(f,tempfile(fileext=".md"),"md","en")
```

### Example 2

```r
f<-np_crd(yield~treatment,simulate_agri("crd")); agri_report(f,tempfile(fileext=".qmd"),"qmd","en")
```

### Example 3

```r
f<-np_crd(yield~treatment,simulate_agri("crd")); if(requireNamespace("rmarkdown",quietly=TRUE)&&rmarkdown::pandoc_available()) agri_report(f,tempfile(fileext=".md"),"html","en")
```

## 29. `agri_dashboard()` — Generate a self-contained Quarto dashboard source

Creates a QMD dashboard source with embedded-resource HTML settings.

**Statistical role.** Rendering the QMD itself requires Quarto/Pandoc outside this function.

**Returns.** The normalized QMD path.

**Three examples**

### Example 1

```r
f<-np_crd(yield~treatment,simulate_agri("crd")); agri_dashboard(f)
```

### Example 2

```r
f<-np_crd(yield~treatment,simulate_agri("crd")); agri_dashboard(f,tempfile(fileext=".qmd"))
```

### Example 3

```r
x<-simulate_agri("repeated_missing"); d<-agri_design(height~treatment*time,x,"repeated",subject=subject,within=time); f<-agri_rank(d,"incomplete_wild",B=299,missing_assumption="MCAR"); agri_dashboard(f,tempfile(fileext=".qmd"))
```

## 30. `export_results()` — Export an analysis bundle

Stores design summary, omnibus results, effects, missingness, method, seed, and session information as an RDS file.

**Statistical role.** The exported bundle is intended for reproducibility and downstream archiving.

**Returns.** The normalized RDS path.

**Three examples**

### Example 1

```r
f<-np_crd(yield~treatment,simulate_agri("crd")); export_results(f,tempfile(fileext=".rds"))
```

### Example 2

```r
f<-np_crd(yield~treatment,simulate_agri("crd")); z<-tempfile(fileext=".rds"); export_results(f,z); names(readRDS(z))
```

### Example 3

```r
x<-simulate_agri("repeated_missing"); d<-agri_design(height~treatment*time,x,"repeated",subject=subject,within=time); f<-agri_rank(d,"incomplete_wild",B=299,missing_assumption="MCAR"); export_results(f,tempfile(fileext=".rds"))
```

## 31. `simulate_agri()` — Simulate representative agricultural experiments

Generates reproducible teaching data for CRD, RCBD, factorial, split-plot, repeated, incomplete repeated, and multi-environment workflows.

**Statistical role.** These are synthetic teaching data, not evidence from real experiments.

**Returns.** A data frame.

**Three examples**

### Example 1

```r
simulate_agri("crd",seed=1)
```

### Example 2

```r
simulate_agri("repeated_missing",seed=2,n=8,missing_rate=.15)
```

### Example 3

```r
simulate_agri("multienv",seed=3,n=5)
```

## 32. `incomplete_wild_rank_test()` — Wild-bootstrap rank inference for incomplete repeated measurements

Implements an experimental rank-based quadratic-form procedure with ATS, WTS, or MATS and subject-level wild multipliers for incompletely observed unblocked repeated factorial designs.

**Statistical role.** The theoretical reference framework is primarily MCAR. The implementation remains experimental until independent numerical benchmarking is complete; blocked incomplete repeated designs are rejected.

**Returns.** An `agri_incomplete_wild` object.

**Three examples**

### Example 1

```r
x<-simulate_agri("repeated_missing"); d<-agri_design(height~treatment*time,x,"repeated",subject=subject,within=time); incomplete_wild_rank_test(d,B=299,statistic="ATS",missing_assumption="MCAR")
```

### Example 2

```r
x<-simulate_agri("repeated_missing"); d<-agri_design(height~treatment*time,x,"repeated",subject=subject,within=time); incomplete_wild_rank_test(d,B=299,statistic="WTS",weights="mammen",missing_assumption="MCAR")
```

### Example 3

```r
x<-simulate_agri("repeated_missing"); d<-agri_design(height~treatment*time,x,"repeated",subject=subject,within=time); incomplete_wild_rank_test(d,B=299,statistic="MATS",weights="normal",missing_assumption="MAR-sensitivity")
```

## Core methodological references

The documentation uses the bibliographic year of the version of record. Core references were cross-checked against the publisher/journal record and at least one independent bibliographic source; see `inst/references/REFERENCE_VERIFICATION.md` and `inst/references/agriRank-methods-verified.ris`.

- Pauly, M., Brunner, E., & Konietschke, F. (2015). Asymptotic permutation tests in general factorial designs. *Journal of the Royal Statistical Society: Series B*, 77(2), 461–473. DOI: 10.1111/rssb.12073.
- Brunner, E., Konietschke, F., Pauly, M., & Puri, M. L. (2017). Rank-based procedures in factorial designs: hypotheses about non-parametric treatment effects. *Journal of the Royal Statistical Society: Series B*, 79(5), 1463–1485. DOI: 10.1111/rssb.12222.
- Umlauft, M., Konietschke, F., & Pauly, M. (2017). Rank-based permutation approaches for non-parametric factorial designs. *British Journal of Mathematical and Statistical Psychology*, 70(3), 368–390. DOI: 10.1111/bmsp.12089.
- Friedrich, S., Konietschke, F., & Pauly, M. (2017). A wild bootstrap approach for nonparametric repeated measurements. *Computational Statistics & Data Analysis*, 113, 38–52. DOI: 10.1016/j.csda.2016.06.016.
- Umlauft, M., Placzek, M., Konietschke, F., & Pauly, M. (2019). Wild bootstrapping rank-based procedures: multiple testing in nonparametric factorial repeated measures designs. *Journal of Multivariate Analysis*, 171, 176–192. DOI: 10.1016/j.jmva.2018.12.005.
- Noguchi, K., Gel, Y. R., Brunner, E., & Konietschke, F. (2012). nparLD: An R software package for the nonparametric analysis of longitudinal data in factorial experiments. *Journal of Statistical Software*, 50(12), 1–23. DOI: 10.18637/jss.v050.i12.
- Friedrich, S., Konietschke, F., & Pauly, M. (2019). MANOVA.RM: Resampling-based analysis of multivariate data and repeated measures designs. *The R Journal*, 11(2), 380–400. DOI: 10.32614/RJ-2019-051.
- Frossard, J., & Renaud, O. (2021). Permutation tests for regression, ANOVA, and comparison of signals: the permuco package. *Journal of Statistical Software*, 99(15). DOI: 10.18637/jss.v099.i15.
- Hothorn, T., Hornik, K., van de Wiel, M. A., & Zeileis, A. (2008). Implementing a class of permutation tests: the coin package. *Journal of Statistical Software*, 28(8), 1–23. DOI: 10.18637/jss.v028.i08.
- Brunner, E., Konietschke, F., Bathke, A. C., & Pauly, M. (2021). Ranks and pseudo-ranks: surprising results of certain rank tests in unbalanced designs. *International Statistical Review*, 89(2), 349–366. DOI: 10.1111/insr.12418.
- Konietschke, F., & Brunner, E. (2023). rankFD: An R software package for nonparametric analysis of general factorial designs. *The R Journal*, 15(1), 142–158. DOI: 10.32614/RJ-2023-029.
- Amro, L., Konietschke, F., & Pauly, M. (2024). Incompletely observed nonparametric factorial designs with repeated measurements: a wild bootstrap approach. *Biometrical Journal*, 66(8), e70008. DOI: 10.1002/bimj.70008.
- Jan, S.-L., & Shieh, G. (2025). Power and sample size procedures for the Friedman test. *Sankhya B*, 87, 686–711. DOI: 10.1007/s13571-025-00362-2.
- Thiel, N. et al. (2026). Resampling NANCOVA for small samples. *Computational Statistics & Data Analysis*, 215, 108290. DOI: 10.1016/j.csda.2025.108290.
- Wobbrock, J. O., Findlater, L., Gergle, D., & Higgins, J. J. (2011). The aligned rank transform for nonparametric factorial analyses using only ANOVA procedures. *CHI 2011*, 143–146. DOI: 10.1145/1978942.1978963.
- Elkin, L. A., Kay, M., Higgins, J. J., & Wobbrock, J. O. (2021). An aligned rank transform procedure for multifactor contrast tests. *UIST 2021*, 754–768. DOI: 10.1145/3472749.3474784.

# Conover multiple comparisons

## `agri_conover()`

**Purpose.** Perform design-aware Conover all-pairs rank comparisons. For independent one-way/CRD data, `agriRank` routes to `PMCMRplus::kwAllPairsConoverTest()`. For a complete unreplicated RCBD, it routes to `PMCMRplus::frdAllPairsConoverTest()` so pairing within blocks is preserved. Incomplete or replicated RCBD cells are rejected rather than silently analyzed with the wrong layout.

**Primary estimand.** Pairwise stochastic/rank separation following a significant or scientifically prespecified omnibus rank analysis. The adjusted p-values are inferential outputs; effect estimates should still be reported alongside them when available.

**Example 1: CRD.**

```r
set.seed(201)
d <- data.frame(
  trt = factor(rep(LETTERS[1:4], each = 8)),
  y = c(rgamma(8, 5, 1), rgamma(8, 6, 1), rgamma(8, 8, 1), rgamma(8, 9, 1))
)
des <- agri_design(y ~ trt, d, design = "crd")
fit <- agri_rank(des, method = "kruskal")
agri_conover(fit, adjust = "holm")
```

**Example 2: complete RCBD.**

```r
set.seed(202)
d <- expand.grid(block = factor(1:6), trt = factor(LETTERS[1:4]))
d$y <- rgamma(nrow(d), 8, 1) + as.numeric(d$trt)
des <- agri_design(y ~ trt, d, design = "rcbd", block = block)
fit <- agri_rank(des, method = "friedman")
agri_conover(fit, adjust = "holm")
```

**Example 3: factorial simple effects.**

```r
set.seed(203)
d <- expand.grid(block = factor(1:5), cultivar = factor(c("C1", "C2", "C3")),
                 irrigation = factor(c("I1", "I2")))
d$y <- rgamma(nrow(d), 8, 1) + 2 * (d$cultivar == "C3")
des <- agri_design(y ~ cultivar * irrigation, d, design = "rcbd", block = block)
fit <- agri_rank(des, method = "ART")
if (requireNamespace("PMCMRplus", quietly = TRUE))
  agri_conover(fit, by = "irrigation", factor = "cultivar", adjust = "holm")
```

# Nonparametric regression for Agronomy

The regression module is intentionally broader than one statistical tradition. It distinguishes the **strictly nonparametric core** (LOESS, smoothing splines, mixed-data kernel regression, isotonic regression, and constrained quantile B-splines) from **rank-robust or semiparametric companions** (Theil-Sen/Siegel regression, quantile regression, GAM, and SCAM). This distinction is retained in the help pages and vignettes so that a flexible smoother is not incorrectly described as a distribution-free confirmatory test.

## `agri_np_regression()`

Fits a unified agronomic response-curve object. `method = "auto"` uses design structure, response family, predictor types, and explicit shape constraints only; it never chooses a model because one method generated a smaller p-value.

### Example 1: smoothing spline for a dose gradient

```r
set.seed(211)
dose <- seq(0, 200, length.out = 45)
y <- 40 + 0.55 * dose - 0.002 * dose^2 + rnorm(45, 0, 5)
d <- data.frame(dose, yield = y)
fit <- agri_np_regression(yield ~ dose, d, method = "smoothing_spline")
summary(fit)
```

### Example 2: mixed-data kernel regression

```r
if (requireNamespace("np", quietly = TRUE)) {
  set.seed(212)
  d <- data.frame(
    N = runif(80, 0, 200),
    cultivar = factor(sample(c("A", "B"), 80, TRUE))
  )
  d$yield <- 25 + 0.45 * d$N - 0.0015 * d$N^2 + 4 * (d$cultivar == "B") + rnorm(80, 0, 4)
  fit <- agri_np_regression(yield ~ N + cultivar, d, method = "kernel")
  agri_np_diagnostics(fit)
}
```

### Example 3: block-adjusted shape-constrained response

```r
if (requireNamespace("scam", quietly = TRUE)) {
  set.seed(213)
  d <- expand.grid(block = factor(1:5), salinity = seq(0.5, 4.5, length.out = 12))
  d$biomass <- 35 - 5 * d$salinity + rnorm(nrow(d), 0, 2)
  fit <- agri_np_regression(biomass ~ salinity, d, method = "scam",
                            shape = "decreasing", block = block)
  agri_np_plot(fit)
}
```

## Regression support functions

The following functions use the same `agri_np_reg_fit` object and each has three runnable examples in its dedicated `.Rd` page:

- `agri_np_predict()`: predictions and supported analytic intervals.
- `agri_np_diagnostics()`: predictive-error and smoother-specific diagnostics.
- `agri_np_compare()`: cross-validated predictive comparison, never p-value fishing.
- `agri_np_derivative()`: finite-difference first derivative of the fitted curve.
- `agri_np_optimum()`: descriptive maximum/minimum of the fitted curve within a prespecified range.
- `agri_np_bootstrap()`: row- or block/cluster-resampled pointwise percentile bands.
- `agri_np_plot()`: raw observations plus fitted curve, residual diagnostics, or derivative plot.

## Interpretation boundary

A nonparametric curve should not automatically replace an agronomically meaningful mechanistic or prespecified response model. For fertilizer dose, salinity, temperature, growth, and environmental gradients, the regression module is designed to reveal shape, quantify conditional behavior, support robust sensitivity analyses, and generate reproducible figures. Economic optimum requires costs/prices and a corresponding objective; `agri_np_optimum()` deliberately reports only a descriptive fitted optimum.

## `agri_np_interactive()` and response surfaces

`agri_np_plot(type = "surface")` evaluates a fitted multivariable regression over a two-dimensional grid while holding other covariates at prespecified or reference values. `agri_np_plot(group = ...)` displays conditional curves by a grouping factor. `agri_np_interactive()` converts the same ggplot2 object to Plotly for exploratory HTML output without refitting the statistical model.

Three guarded examples for `agri_np_interactive()` are provided in its dedicated help page: a fitted curve, a derivative curve, and a two-dimensional agronomic response surface.

## Kernel predictor significance: `agri_np_significance()`

This function is available only for `agri_np_regression(..., method = "kernel")`. It wraps `np::npsigtest()` and tests selected continuous, ordered, or unordered predictors with a bootstrap reference distribution. Scientific predictors are tested by default; a separately declared agronomic block remains in the conditioning set rather than being treated as the target predictor.

The default uses the more computationally intensive Type-II calibration. Type I is useful for faster exploratory calculations, but near-threshold conclusions in modest samples should be checked with Type II. The procedure is model-based and should not be described as a field-randomization test.

### Example 1: test a continuous dose predictor

```r
if (requireNamespace("np", quietly = TRUE)) {
  set.seed(221)
  d <- data.frame(dose = runif(35, 0, 180))
  d$yield <- 5 + .06*d$dose - .00018*d$dose^2 + rnorm(35, 0, .5)
  k1 <- agri_np_regression(yield ~ dose, d, method = "kernel")
  agri_np_significance(k1, variables = "dose", B = 99, boot_type = "I")
}
```

### Example 2: test cultivar conditionally on dose

```r
if (requireNamespace("np", quietly = TRUE)) {
  set.seed(222)
  d <- data.frame(dose = runif(40, 0, 150), cultivar = factor(rep(c("A", "B"), 20)))
  d$yield <- 4 + .05*d$dose + ifelse(d$cultivar == "B", 1, 0) + rnorm(40, 0, .5)
  k2 <- agri_np_regression(yield ~ dose + cultivar, d, method = "kernel")
  agri_np_significance(k2, variables = "cultivar", B = 99, boot_type = "I")
}
```

### Example 3: joint test with block retained as an adjustment

```r
if (requireNamespace("np", quietly = TRUE)) {
  set.seed(223)
  d <- expand.grid(block = factor(1:4), dose = seq(0, 120, length.out = 8), cultivar = factor(c("A", "B")))
  d$yield <- 5 + .05*d$dose + as.numeric(d$block)/5 + ifelse(d$cultivar == "B", .8, 0) + rnorm(nrow(d), 0, .45)
  k3 <- agri_np_regression(yield ~ dose + cultivar, d, method = "kernel", block = block)
  agri_np_significance(k3, variables = c("dose", "cultivar"), joint = TRUE, B = 99, boot_type = "I")
}
```

## Parametric-form specification: `agri_np_specification()`

This function wraps `np::npcmstest()` for a continuous Gaussian response. The candidate `lm` or Gaussian `glm` must be fitted with `x = TRUE, y = TRUE`. It evaluates whether the proposed parametric functional form is compatible with a flexible mixed-data conditional-mean alternative.

A rejection says that the candidate equation is too restrictive. It does not identify a uniquely correct nonparametric model.

### Example 1: linear dose response

```r
if (requireNamespace("np", quietly = TRUE)) {
  set.seed(224)
  d <- data.frame(dose = seq(0, 160, length.out = 35))
  d$yield <- 5 + .06*d$dose - .00025*d$dose^2 + rnorm(35, 0, .4)
  m1 <- lm(yield ~ dose, d, x = TRUE, y = TRUE)
  agri_np_specification(m1, B = 99)
}
```

### Example 2: quadratic candidate

```r
if (requireNamespace("np", quietly = TRUE)) {
  set.seed(225)
  d <- data.frame(dose = seq(0, 160, length.out = 35))
  d$yield <- 5 + .06*d$dose - .00025*d$dose^2 + rnorm(35, 0, .4)
  m2 <- lm(yield ~ dose + I(dose^2), d, x = TRUE, y = TRUE)
  agri_np_specification(m2, B = 99)
}
```

### Example 3: block-adjusted candidate

```r
if (requireNamespace("np", quietly = TRUE)) {
  set.seed(226)
  d <- expand.grid(block = factor(1:4), dose = seq(0, 140, length.out = 8))
  d$yield <- 5 + .07*d$dose - .0003*d$dose^2 + as.numeric(d$block)/3 + rnorm(nrow(d), 0, .4)
  mb <- lm(yield ~ block + dose + I(dose^2), d, x = TRUE, y = TRUE)
  agri_np_specification(mb, B = 99)
}
```

## Regression missing-data and dependence safeguards

`agri_np_regression()` stops by default when the modeled response, predictors, block, or weights contain missing/non-finite values. `na_action = "complete"` must be requested explicitly and records the number of omitted rows; it is not an imputation or missing-data model. Repeated/longitudinal `agri_design` objects are also rejected until a validated subject-aware regression adapter is available. This prevents an ordinary smoother from silently treating repeated observations as independent.



# Integer-support nonparametric regression

## Scientific scope

Integer-valued predictors are common in Agronomy: plants per plot, insects per sampling unit, fruits retained per plant, applications, irrigation events, branches, shoots, traps, or animals per pen. These variables are quantitative and ordered, but the decision space is discrete.

For an admissible support

\[
\mathcal{X}_I=\{x_1,\ldots,x_K\}\subset\mathbb{Z},
\]

`agriRank` defines a fitted maximum by

\[
x_I^*=\arg\max_{x\in\mathcal{X}_I}\widehat m(x),
\]

not by estimating a continuous maximum and rounding it.

Three support declarations are available:

- `observed_integer`: only tested integer values are admissible;
- `integer_range`: every integer between two bounds is admissible;
- `custom_integer`: an explicit user-defined integer set.

The choice is part of the estimand and is saved in the fitted object and reports.

## Four implemented pathways

### 1. `method = "discrete_kernel"`

The focal integer predictor is internally encoded as an ordered factor and fitted with `np`. Current `np` supports ordered discrete kernels, including the Wang–van Ryzin family. In simplified local-constant notation,

\[
\widehat m(x)=
\frac{\sum_i Y_i K_\lambda(X_i,x)}
     {\sum_i K_\lambda(X_i,x)}.
\]

For the Wang–van Ryzin ordered kernel,

\[
K_\lambda(x_i,x)=
\begin{cases}
1-\lambda,&x_i=x,\\
(1-\lambda)\lambda^{|x_i-x|}/2,&x_i\neq x.
\end{cases}
\]

**Example 1: insects as an ordered discrete predictor**

```r
if (requireNamespace("np", quietly = TRUE)) {
  set.seed(601)
  d <- data.frame(insects = rep(0:8, each = 6))
  d$damage <- 4 + 1.5*d$insects + rnorm(nrow(d), 0, 1.1)

  fit <- agri_np_regression(
    damage ~ insects, d,
    method = "discrete_kernel",
    predictor_support = "observed_integer"
  )

  agri_integer_predict(fit)
}
```

**Example 2: full integer interpolation**

```r
if (requireNamespace("np", quietly = TRUE)) {
  set.seed(602)
  d <- data.frame(insects = rep(c(0,2,4,6,8), each = 6))
  d$damage <- 5 + 1.4*d$insects + rnorm(nrow(d))

  fit <- agri_np_regression(
    damage ~ insects, d,
    method = "discrete_kernel",
    predictor_support = "integer_range",
    integer_range = c(0,8)
  )

  agri_integer_predict(fit)
}
```

**Example 3: block-adjusted ordered kernel**

```r
if (requireNamespace("np", quietly = TRUE)) {
  set.seed(603)
  d <- expand.grid(block = factor(1:4), insects = 0:7)
  d$damage <- 3 + 1.6*d$insects + as.numeric(d$block)/3 + rnorm(nrow(d))

  fit <- agri_np_regression(
    damage ~ insects, d,
    method = "discrete_kernel",
    block = block
  )

  agri_integer_optimum(fit, objective = "min")
}
```

### 2. `method = "unimodal_isotonic"`

For one integer predictor, the fit minimizes weighted squared error subject to

\[
\theta_1\le\cdots\le\theta_m
\quad\text{and}\quad
\theta_m\ge\cdots\ge\theta_K.
\]

`Iso::ufit()` searches the admissible observed mode positions when the mode is not prespecified.

**Example 1: plant-density maximum**

```r
if (requireNamespace("Iso", quietly = TRUE)) {
  set.seed(611)
  d <- data.frame(plants = rep(1:10, each = 6))
  d$yield <- 30 + 8*pmin(d$plants, 6) - 5*pmax(d$plants - 6, 0) +
    rnorm(nrow(d), 0, 1.8)

  fit <- agri_np_regression(
    yield ~ plants, d,
    method = "unimodal_isotonic"
  )

  agri_integer_optimum(fit)
}
```

**Example 2: integer predictions**

```r
if (requireNamespace("Iso", quietly = TRUE)) {
  set.seed(612)
  d <- data.frame(fruits = rep(2:10, each = 5))
  d$mass <- 20 + 5*pmin(d$fruits, 6) - 3*pmax(d$fruits - 6, 0) +
    rnorm(nrow(d))

  fit <- agri_np_regression(mass ~ fruits, d, method = "unimodal_isotonic")
  agri_integer_predict(fit)
}
```

**Example 3: bootstrap uncertainty in the discrete optimum**

```r
if (requireNamespace("Iso", quietly = TRUE)) {
  set.seed(613)
  d <- data.frame(plants = rep(1:8, each = 8))
  d$yield <- 25 + 8*pmin(d$plants, 5) - 5*pmax(d$plants - 5, 0) +
    rnorm(nrow(d), 0, 1.5)

  fit <- agri_np_regression(yield ~ plants, d, method = "unimodal_isotonic")
  bt <- agri_integer_bootstrap(fit, B = 99, seed = 9)
  agri_integer_confset(bt, level = .95)
}
```

### 3. `method = "umbrella"`

The constrained systematic component can be written as

\[
\eta_i=f_{\mathrm{umb}}(x_i)+\mathbf z_i^\top\boldsymbol\beta,
\]

with

\[
f(x_1)\le\cdots\le f(x_m)\ge\cdots\ge f(x_K).
\]

The implementation uses `cgam::umbrella()`. Ordinary parametric covariates can remain in the model, which permits a declared block to be retained as an adjustment factor.

**Example 1: umbrella response**

```r
if (requireNamespace("cgam", quietly = TRUE)) {
  set.seed(621)
  d <- data.frame(plants = rep(1:9, each = 6))
  d$yield <- 22 + 8*pmin(d$plants, 6) - 5*pmax(d$plants - 6, 0) +
    rnorm(nrow(d), 0, 1.5)

  fit <- agri_np_regression(yield ~ plants, d, method = "umbrella")
  agri_integer_optimum(fit)
}
```

**Example 2: umbrella RCBD**

```r
if (requireNamespace("cgam", quietly = TRUE)) {
  set.seed(622)
  d <- expand.grid(block = factor(1:5), plants = 1:9)
  d$yield <- 25 + 8*pmin(d$plants, 6) - 5*pmax(d$plants - 6, 0) +
    as.numeric(d$block)*.6 + rnorm(nrow(d), 0, 1.5)

  fit <- agri_np_regression(
    yield ~ plants, d,
    method = "umbrella",
    block = block
  )
  agri_integer_predict(fit)
}
```

**Example 3: fitted efficiency table**

```r
if (requireNamespace("cgam", quietly = TRUE)) {
  set.seed(623)
  d <- data.frame(plants = rep(1:8, each = 7))
  d$yield <- 20 + 7*pmin(d$plants, 5) - 4*pmax(d$plants - 5, 0) +
    rnorm(nrow(d))

  fit <- agri_np_regression(yield ~ plants, d, method = "umbrella")
  agri_integer_efficiency(fit)
}
```

### 4. `method = "integer_grid"`

This pathway fits a selected flexible latent model \(\widehat m_c(x)\), but every public prediction and decision is evaluated only on \(\mathcal{X}_I\):

\[
x_I^*=\arg\max_{x\in\mathcal{X}_I}\widehat m_c(x).
\]

No rounding is performed.

**Example 1: smoothing spline**

```r
set.seed(631)
d <- data.frame(plants = rep(1:10, each = 5))
d$yield <- 25 + 7*d$plants - .45*d$plants^2 + rnorm(nrow(d))

fit <- agri_np_regression(
  yield ~ plants, d,
  method = "integer_grid",
  integer_base_method = "smoothing_spline",
  predictor_support = "integer_range"
)

agri_integer_optimum(fit)
```

**Example 2: only observed treatments are admissible**

```r
set.seed(632)
d <- data.frame(plants = rep(c(1,3,5,7,9), each = 6))
d$yield <- 20 + 7*d$plants - .45*d$plants^2 + rnorm(nrow(d))

fit <- agri_np_regression(
  yield ~ plants, d,
  method = "integer_grid",
  integer_base_method = "smoothing_spline",
  predictor_support = "observed_integer"
)

agri_integer_predict(fit)
```

**Example 3: GAM latent curve with integer decisions**

```r
if (requireNamespace("mgcv", quietly = TRUE)) {
  set.seed(633)
  d <- data.frame(plants = rep(1:12, each = 5))
  d$yield <- 20 + 7*d$plants - .38*d$plants^2 + rnorm(nrow(d))

  fit <- agri_np_regression(
    yield ~ plants, d,
    method = "integer_grid",
    integer_base_method = "gam",
    predictor_support = "integer_range"
  )

  agri_integer_difference(fit)
}
```

## Finite differences

For integer support, the package replaces instantaneous derivatives with finite changes:

\[
\Delta \widehat m(k)=\widehat m(k+1)-\widehat m(k),
\]

and, for unit-spaced support,

\[
\Delta^2\widehat m(k)=
\widehat m(k+1)-2\widehat m(k)+\widehat m(k-1).
\]

Use:

```r
agri_integer_difference(fit, order = 1)
agri_integer_difference(fit, order = 2)
```

## Practical thresholds

For a fraction \(\rho\) of the fitted maximum,

\[
x_\rho=
\min\{x\in\mathcal X_I:
\widehat m(x)\ge
\rho\max_{s\in\mathcal X_I}\widehat m(s)\}.
\]

Examples:

```r
agri_integer_threshold(fit, "fraction_of_maximum", value = .95)
agri_integer_threshold(fit, "gain_from_baseline", value = 10, baseline = 1)
agri_integer_threshold(fit, "marginal_gain", value = 1)
```

## Bootstrap distribution and confidence set

For bootstrap replicate \(b\),

\[
x_b^*=
\arg\max_{x\in\mathcal X_I}
\widehat m_b(x).
\]

`agri_integer_bootstrap()` estimates the probability distribution over admissible optima. Tied optima split the replicate's probability mass equally. `agri_integer_confset()` constructs a highest-probability discrete set, for example \(\{5,6,7\}\), instead of a fractional interval.

```r
bt <- agri_integer_bootstrap(fit, B = 999, seed = 1)
agri_integer_confset(bt, level = .95)
```

## Interpretation rules

1. `observed_integer` is the conservative default for the four integer-specific pathways.
2. `integer_range` explicitly allows interpolation to integers not directly tested.
3. Integer \(X\) does not imply a count distribution for \(Y\).
4. A fitted biological maximum is not automatically an economic optimum.
5. Shape restrictions must be scientifically justified before model inspection.
6. Blocks are retained only by engines able to model them.
7. Repeated observations require the dedicated dependence-aware workflow and are not converted to independent integer-regression data.
8. Do not run several integer methods merely to retain the most favorable optimum.

## Verified references

- Wang, M.-C., & van Ryzin, J. (1981). *A class of smooth estimators for discrete distributions*. **Biometrika**, 68(1), 301–309. DOI: 10.1093/biomet/68.1.301.
- Racine, J., & Li, Q. (2004). *Nonparametric estimation of regression functions with both categorical and continuous data*. **Journal of Econometrics**, 119(1), 99–130. DOI: 10.1016/S0304-4076(03)00157-X.
- Turner, T. R., & Wollan, P. C. (1997). *Locating a maximum using isotonic regression*. **Computational Statistics & Data Analysis**, 25(3), 305–320. DOI: 10.1016/S0167-9473(97)00009-1.
- Stout, Q. F. (2008). *Unimodal regression via prefix isotonic regression*. **Computational Statistics & Data Analysis**, 53(2), 289–297. DOI: 10.1016/j.csda.2008.08.005.
- Geng, Z., & Shi, N.-Z. (1990). *Isotonic Regression for Umbrella Orderings*. **Journal of the Royal Statistical Society Series C: Applied Statistics**, 39(3), 397–402. DOI: 10.2307/2347399.
- Liao, X., & Meyer, M. C. (2019). *cgam: An R Package for the Constrained Generalized Additive Model*. **Journal of Statistical Software**, 89(5). DOI: 10.18637/jss.v089.i05.

The metadata audit and source-by-source verification are stored in `inst/references/REFERENCE_VERIFICATION.md`.


# Hierarchical designs and integrated multivariate inference (0.12.x)

## Split-split plots

Use `np_splitsplit()` or declare the design explicitly with `subsubplot=`. The hierarchy is block -> whole-plot unit -> subplot unit -> sub-subplot observation. All treatment factors must be included in the scientific formula.

```r
x <- simulate_agri("split_split")
fit <- np_splitsplit(
  yield ~ irrigation * cultivar * timing, x,
  block = block, whole_plot = irrigation,
  subplot = cultivar, subsubplot = timing,
  method = "auto"
)
```

The permuco adapter encodes `Error(block/whole_plot/subplot)`. The ART adapter creates distinct block, block-by-whole-plot, and block-by-whole-plot-by-subplot grouping units.

## Strip plots

Use `np_stripplot()` with both perpendicular treatment factors.

```r
x <- simulate_agri("strip_plot")
fit <- np_stripplot(
  yield ~ irrigation * nitrogen, x,
  block = block, strip_a = irrigation, strip_b = nitrogen
)
```

The classical error structure distinguishes block-by-strip-A and block-by-strip-B errors. The A-by-B interaction is associated with the strip-intersection/residual stratum.

## Multivariate responses

`agri_multivariate()` returns `agri_multivariate_fit`, not a raw backend object. Wide `cbind()` outcomes route to `MANOVA.RM::MANOVA.wide()`, long-form single-response multivariate vectors route to `MANOVA.RM::MANOVA()`, and multiple outcomes plus `within=` route to `MANOVA.RM::multRM()`. The object works with `agri_table()`, `agri_report()`, `agri_dashboard()`, and `export_results()`.

## Multi-environment enforcement

`agri_multienv()` prevents accidental environment pooling. If environment is missing from the formula, the default expands the treatment structure to include environment and its interactions. Set `environment_interaction = FALSE` only when the scientific model intentionally requires an environment main effect without treatment-by-environment interaction.

## Common result/report integration added in 0.12.0.9000

The common communication layer now accepts the following additional analysis objects:

- `agri_multivariate_fit`;
- `agri_ancova_fit`;
- `agri_trend`;
- `agri_power`;
- `agri_batch`;
- `agri_sensitivity`;
- `agri_missing_report`.

Where scientifically meaningful, these objects can be passed to `agri_table()`, `agri_report()`, `agri_dashboard()`, and `export_results()`. This does not imply that all statistical estimands are interchangeable: each object retains its own inferential target, backend, resampling assumptions, and limitations.
