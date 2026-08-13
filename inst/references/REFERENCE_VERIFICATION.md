# Double verification of bibliographic metadata for agriRank

Verification date: 2026-08-12.

The table records the core references used in the vignettes and reference manual. Each record was checked against the publisher/journal or CRAN and a second independent bibliographic source. When sources conflicted, the publisher version of record was treated as authoritative.

| Reference | DOI | Source 1 | Source 2 | Verification result |
|---|---|---|---|---|
| Pauly, Brunner & Konietschke (2015) | 10.1111/rssb.12073 | Oxford Academic/JRSSB | AGRIS/National Agricultural Library | confirmed: 77(2), 461–473, 2015 |
| Brunner et al. (2017) | 10.1111/rssb.12222 | Oxford Academic/Wiley | Consensus/arXiv metadata | confirmed: 79(5), 1463–1485, 2017 |
| Umlauft, Konietschke & Pauly (2017) | 10.1111/bmsp.12089 | Wiley/BPS | PubMed | confirmed: 70(3), 368–390, 2017 |
| Friedrich, Konietschke & Pauly (2017) | 10.1016/j.csda.2016.06.016 | ScienceDirect | Univ. Augsburg repository/AGRIS | confirmed: 113, 38–52, 2017 |
| Umlauft et al. (2019) | 10.1016/j.jmva.2018.12.005 | ScienceDirect | Consensus | confirmed: 171, 176–192, 2019 |
| Noguchi et al. (2012) | 10.18637/jss.v050.i12 | Journal of Statistical Software | OpenAIRE/RePEc | confirmed: 50(12), 1–23, 2012 |
| Friedrich et al. (2019) MANOVA.RM | 10.32614/RJ-2019-051 | The R Journal | Univ. Augsburg repository | confirmed: 11(2), 380–400, 2019 |
| Frossard & Renaud (2021) | 10.18637/jss.v099.i15 | Journal of Statistical Software | CRAN permuco metadata | confirmed |
| Hothorn et al. (2008) | 10.18637/jss.v028.i08 | Journal of Statistical Software | Zeileis publication bibliography/DOAJ | confirmed: 28(8), 1–23 |
| Happ et al. (2020) | 10.18637/jss.v095.c01 | Journal of Statistical Software | DOAJ/PMU Research Portal | confirmed: 95, Code Snippet 1, 1–22 |
| Brunner et al. (2021) | 10.1111/insr.12418 | Wiley | bibliographic secondary search | confirmed: 89(2), 349–366 |
| Konietschke & Brunner (2023) | 10.32614/RJ-2023-029 | The R Journal | CRAN rankFD metadata | confirmed: 15(1), 142–158 |
| Amro, Konietschke & Pauly (2024) | 10.1002/bimj.70008 | Wiley | PubMed/PMC | confirmed: 66(8), e70008, 2024 |
| Jan & Shieh (2025) | 10.1007/s13571-025-00362-2 | Springer/Sankhya B | National Yang Ming Chiao Tung University repository | confirmed: 87, 686–711, 2025 |
| Thiel et al. (2026) | 10.1016/j.csda.2025.108290 | ScienceDirect | Univ. Salzburg/PMU Research Portal | confirmed: 215, 108290, 2026 |
| Wobbrock et al. (2011) | 10.1145/1978942.1978963 | ACM metadata via DOI index | DBLP/CiNii | confirmed: CHI 2011, 143–146 |
| Elkin et al. (2021) | 10.1145/3472749.3474784 | ARTool official citation | arXiv/ACM metadata | confirmed: UIST 2021, 754–768 |

## Notes

1. An online-first publication date must not replace the bibliographic year of the volume.
2. One secondary database displayed an inconsistent year for Amro et al.; Wiley, PubMed, and PMC confirm the bibliographic year 2024.
3. For R software, cite the methodological/software article and, when relevant, the exact package version used.
4. Package versions should be recorded dynamically with `sessionInfo()` rather than hard-coded in vignette prose.

## Regression-module additions verified on 2026-08-12

| Reference | DOI | Source 1 | Source 2 | Verification result |
|---|---|---|---|---|
| Hayfield & Racine (2008) | 10.18637/jss.v027.i05 | Journal of Statistical Software | current CRAN `np` metadata/documentation | confirmed: *Journal of Statistical Software* 27(5), 2008; authors/title/DOI concordant |
| Pya & Wood (2015) | 10.1007/s11222-013-9448-7 | Springer, *Statistics and Computing* | current CRAN `scam` documentation | confirmed: 25(3), 543–559, 2015; online-first 2014 must not replace volume year |
| Sen (1968) | 10.1080/01621459.1968.10480934 | Taylor & Francis/JASA | CRAN `mblm` documentation | confirmed: 63(324), 1379–1389, 1968 |
| Wood (2025) | 10.1146/annurev-statistics-112723-034249 | Annual Reviews | current CRAN `mgcv` metadata | confirmed: *Annual Review of Statistics and Its Application* 12, 497–526, 2025 |
| Ng & Maechler (2007) | 10.1177/1471082X0700700403 | SAGE, *Statistical Modelling* | ETH Research Collection / Northern Arizona University | confirmed: 7(4), 315–328, 2007 |
| Koenker & Bassett (1978) | 10.2307/1913643 | JSTOR/Econometrica issue metadata | RePEc | confirmed: 46(1), 33–50, 1978 |

### Operational package-method verification

The Conover adapter was checked against the current official R documentation for `PMCMRplus::kwAllPairsConoverTest()` and `PMCMRplus::frdAllPairsConoverTest()`. The former is documented for Kruskal-type all-pairs comparisons; the latter for Friedman-type ranked data in a complete unreplicated block design. The regression adapters were checked against current official documentation for `np`, `scam`, `mgcv`, `mblm`, and `cobs` as well as their cited methodological papers where available.

## Regression-inference additions verified on 2026-08-12

### Racine, Hart & Li (2006), kernel predictor significance

- **Canonical metadata:** Racine, J. S.; Hart, J.; Li, Q. (2006). *Testing the Significance of Categorical Predictor Variables in Nonparametric Regression Models*. **Econometric Reviews**, 25(4), 523-544. DOI: **10.1080/07474930600972590**.
- **Verification source 1:** Taylor & Francis journal record, volume 25, issue 4, pages 523-544, DOI 10.1080/07474930600972590.
- **Verification source 2:** McMaster University Experts record, which independently confirms authors, journal, volume, issue, pages, year, publisher, and DOI.
- **Implementation link:** `np::npsigtest()` documents this paper as a methodological reference for mixed-data nonparametric regression significance testing.

### Hsiao, Li & Racine (2007), nonparametric model specification

- **Canonical metadata:** Hsiao, C.; Li, Q.; Racine, J. S. (2007). *A consistent model specification test with mixed discrete and continuous data*. **Journal of Econometrics**, 140(2), 802-826. DOI: **10.1016/j.jeconom.2006.07.015**.
- **Verification source 1:** Elsevier/ScienceDirect journal record, volume 140, issue 2, pages 802-826, DOI 10.1016/j.jeconom.2006.07.015.
- **Verification source 2:** McMaster University Experts and RePEc independently confirm authors, journal, volume, issue, pages, year, and DOI.
- **Implementation link:** `np::npcmstest()` documents this paper as the basis of the mixed-data consistent specification test.


## Integer-support regression additions verified on 2026-08-12

| Reference | DOI | Source 1 | Source 2 | Verification result |
|---|---|---|---|---|
| Wang & van Ryzin (1981) | 10.1093/biomet/68.1.301 | Oxford Academic / *Biometrika* | JSTOR, stable record 2335831 | confirmed: *Biometrika* 68(1), 301–309, April 1981 |
| Racine & Li (2004) | 10.1016/S0304-4076(03)00157-X | Elsevier / ScienceDirect | McMaster University Experts | confirmed: *Journal of Econometrics* 119(1), 99–130, 2004 |
| Turner & Wollan (1997) | 10.1016/S0167-9473(97)00009-1 | Elsevier / ScienceDirect | RePEc | confirmed: *Computational Statistics & Data Analysis* 25(3), 305–320, 1997 |
| Stout (2008) | 10.1016/j.csda.2008.08.005 | Elsevier / ScienceDirect | University of Michigan author publication record | confirmed: *Computational Statistics & Data Analysis* 53(2), 289–297, 2008 |
| Geng & Shi (1990) | 10.2307/2347399 | Oxford Academic / JRSS Series C | RePEc | confirmed: 39(3), 397–402, 1990 |
| Liao & Meyer (2019) | 10.18637/jss.v089.i05 | Journal of Statistical Software | archived arXiv preprint | confirmed: *Journal of Statistical Software* 89(5), 2019 |

### Package-method verification

- Current `np` documentation (version 0.70-5, 2026-07-15) explicitly distinguishes ordered factors and documents the Wang–van Ryzin and Li–Racine ordered kernels exposed by `npregbw()` for ordered categorical predictors.
- Current `Iso` documentation (version 0.0-21) documents `ufit()` as a least-squares unimodal isotonic regression and states that an unspecified mode is selected by exhaustive search over admissible `x` locations.
- Current `cgam` documentation (version 1.32, 2026-03-05) explicitly documents `umbrella(x)` and permits ordinary parametric covariates in the same constrained additive model.
- These package records are used for operational implementation details; methodological interpretation is anchored to the peer-reviewed references above.
