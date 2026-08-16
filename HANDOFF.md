# agriRank, documento de continuidade

**Última atualização:** 14 de agosto de 2026
**Versão do pacote:** 0.13.0
**Repositório:** https://github.com/wep69/agriRank (público)

Este documento existe para que qualquer pessoa, inclusive você mesmo daqui a
seis meses, consiga retomar o trabalho sem reconstruir o contexto.

**Guia complementar:** o `GUIA_COMPLEMENTAR.md` (mesma pasta) detalha o
procedimento operacional: ambiente e instalação elevada, validação local,
win-builder/macbuilder, commits e o roteiro completo de elaboração de
tutoriais PT/EN (com a versão EN como vinheta em destaque do pacote).

---

## 1. Onde está cada coisa

| Caminho | O que é |
|---|---|
| `D:\Walter\R\Pacotes_criados\agriRank\agriRank-gh` | **Repositório Git.** Cópia de trabalho oficial, é o que vai para o GitHub |
| `D:\agriRank-validation\agriRank` | **Área de validação.** Onde eu edito primeiro, instalo e testo |
| `D:\agriRank-validation\logs` | Todos os logs de teste, check, cobertura e calibração |
| `D:\agriRank-validation\*.R`, `*.ps1` | Scripts auxiliares de verificação, fora do pacote |
| `D:\Walter\R\Pacotes_criados\agriRank\validation_0.13.0` | Cópia congelada dos artefatos e logs |

**Atenção ao fluxo de dois diretórios.** Eu edito em `D:\agriRank-validation\agriRank`,
instalo, testo, e só então sincronizo para `agriRank-gh` com um `Copy-Item` dos
diretórios `R`, `man`, `tests`, `vignettes`, `inst`, `data`, `data-raw` mais os
arquivos de raiz. Já perdi tempo uma vez editando num e instalando do outro. Se
preferir simplificar no futuro, unifique os dois e apague a área de validação.

**Armadilha conhecida (14/08/2026):** o `README.md` da área de validação ficou
desatualizado em relação ao do repositório (o do repositório ganhou as instruções
de instalação e a recomendação de ART após o release). Uma sincronização cega dos
arquivos de raiz sobrescreveu o README do repositório e foi preciso restaurá-lo
com `git checkout -- README.md`. Antes de copiar arquivos de raiz, confira o
`git diff` de cada um; o README do repositório é o que vale.

## 2. Situação do Git

```
remoto:  origin  https://github.com/wep69/agriRank.git
branch:  main
estado:  ## main...origin/main        (sincronizado)
```

Histórico até agora:

| Commit | Assunto |
|---|---|
| `d2f906f` | Compact letter displays on every comparison route |
| `6a1abe7` | Shared example data, agronomic units and interpreted examples |
| `96b3847` | agri_conover: optional compact letter display, computed within strata |
| `9d1112d` | README: link the release assets from the cheat sheet section |
| `d227ea8` | agriRank 0.13.0: commit inicial do código-fonte |

O `.git` ocupa 20,1 MB, quase tudo por causa do cheatsheet em português, 21 MB.

**Release publicada:** `v0.13.0`, com três anexos, o tarball e os dois cheatsheets.
Não há outras tags.

### Nota sobre um erro transitório do GitHub

Em 13/08 o push do commit `d2f906f` foi recusado várias vezes com
`remote rejected ... (Internal Server Error)`, Request ID
`2A86:3A05CF:3E3BAB:423C58:6A7DD70D`. Era falha do lado do GitHub, não do
repositório. Passou sozinho depois de algumas horas. Se acontecer de novo,
espere e repita `git push origin main`.

## 3. HÁ TRABALHO NÃO COMMITADO

Este é o ponto mais importante do documento. Dois conjuntos de melhorias da
regressão estão **implementados, testados e verificados, mas não commitados**,
por pedido explícito.

### 3.1 Capacidade da regressão: extratores, bootstrap, gráficos

Arquivos modificados:

```
 M NAMESPACE
 M NEWS.md
 M R/globals.R
 M R/regression.R
 M man/agri_np_bootstrap.Rd
 M man/agri_np_diagnostics.Rd
 M man/agri_np_plot.Rd
```

Arquivos novos, ainda não rastreados:

```
?? R/regression-extractors.R
?? R/regression-plots.R
?? man/agri_np_curves.Rd
?? man/agri_np_extractors.Rd
?? man/agri_np_regression_plots.Rd
?? tests/testthat/test-regression-capacity.R
```

O que esse conjunto entrega:

- extratores `coef()`, `confint()`, `fitted()`, `residuals()`, com recusa
  nominal dos suavizadores em `coef()`;
- `agri_np_bootstrap()` com `target = "coefficients"`, `band = "simultaneous"`
  e `keep_replicates`;
- três índices de variação explicada em `agri_np_diagnostics()`, com graus de
  liberdade efetivos;
- cinco tipos novos de gráfico, quatro métodos `plot()` e a função
  `agri_np_curves()`;
- ajuste de suporte inteiro desenhado em degraus, não em linha contínua.

### 3.2 Fatores qualitativos e forest plot de coeficientes (14/08/2026)

Arquivos modificados, além dos de 3.1 onde houver sobreposição:

```
 M R/regression.R            (validação de fatores, recusa por engine,
                              alinhamento do bootstrap por nome de termo,
                              exclusão dos termos de bloco do alvo de
                              coeficientes, type = "forest")
 M R/regression-plots.R      (geom_errorbar no lugar do geom_errorbarh
                              deprecated pelo ggplot2 4.0)
 M R/globals.R, NAMESPACE, NEWS.md
 M man/agri_np_regression.Rd, man/agri_np_plot.Rd,
   man/agri_np_bootstrap.Rd, man/agri_np_extractors.Rd
 M inst/manual/REFERENCE_MANUAL.md
 M vignettes/v16-nonparametric-regression.Rmd
 M tests/testthat/test-coverage-stops-regression.R
```

Arquivos novos:

```
?? R/regression-forest.R
?? man/agri_np_forest.Rd
?? tests/testthat/test-regression-factors.R
```

O que esse conjunto entrega:

- fatores qualitativos com dois ou mais níveis nos modelos de regressão:
  coluna character é lida como fator, fator com menos de dois níveis é
  recusado com a razão científica, e `factor_predictors` fica registrado no
  ajuste e no `print()`;
- quantile, kernel, GAM e SCAM mantêm o fator como termo de ajuste;
  theil_sen, siegel, smoothing_spline, cobs, isotonic, unimodal_isotonic e
  loess recusam fatores pelo nome, citando as alternativas;
- o bootstrap de coeficientes alinha réplicas por nome de termo, então uma
  réplica reordenada ou com nível esgotado conta como falha em vez de ser
  lida na ordem original; termos de bloco são excluídos do alvo porque são
  nuisance sob reamostragem de blocos;
- `agri_np_forest()` e `agri_np_plot(type = "forest")`: forest plot dos
  intervalos de bootstrap dos coeficientes, com os níveis de cada fator
  empilhados em painel próprio e o nível de referência desenhado em zero.

Estado verificado dos cinco conjuntos: **703 asserções, 0 falhas**, e
`R CMD check --as-cran` com **0 ERRORs, 0 WARNINGs, 2 NOTEs** de ambiente
(`New submission` na feasibility; README/NEWS sem pandoc disponível no check).

Nota de ambiente: em 14/08 a biblioteca `D:/RLibrary` estava sem `mblm` e
`cobs`, apesar do registro em `validation_0.13.0/backend_versions.csv`. Ambos
foram reinstalados do CRAN antes da suíte final. Se um teste protegido por
`skip_if_not_installed()` passar a pular, verifique a biblioteca primeiro.

### 3.3 Tabelas, figuras e exportação orientadas a journal (14/08/2026)

Arquivos modificados, além dos de 3.1/3.2 onde houver sobreposição:

```
 M R/regression.R            (type = "levels", banda bootstrap por grupo em
                              type = "fit", seed, agri_theme() nos gráficos,
                              .np_resolve_cluster)
 M R/regression-plots.R, R/regression-forest.R (tema; forest sem intercepto
                              por padrão, facet_wrap com eixos livres)
 M R/reports.R               (agri_table: "coefficients", "levels", format)
 M man/agri_table.Rd, man/agri_np_plot.Rd, man/agri_np_forest.Rd
 M inst/manual/REFERENCE_MANUAL.md
 M vignettes/v16-nonparametric-regression.Rmd
```

Arquivos novos:

```
?? R/graphics-theme.R        (agri_theme, agri_save_figure)
?? R/regression-levels.R     (agri_np_levels, .np_level_grid, .np_level_plot)
?? man/agri_graphics.Rd, man/agri_np_levels.Rd
?? tests/testthat/helper-regression-data.R
?? tests/testthat/test-regression-journal.R
```

O que esse conjunto entrega:

- `agri_np_levels()` e `agri_np_plot(type = "levels")`: resposta observada e
  ajustada em cada nível dos fatores qualitativos, com IC bootstrap pontual;
- `agri_table(fit, "coefficients" | "levels")` e argumento `format =
  "data.frame"`, para tabelas de manuscrito editáveis;
- `agri_np_plot(type = "fit", group = ..., bootstrap = ...)`: curva ajustada
  com banda bootstrap por nível do fator, além do caso sem fator;
- `agri_theme()`: tema comum dos gráficos de regressão;
- `agri_save_figure()`: TIFF (LZW), PDF, SVG, EPS e PNG nas larguras de
  coluna/meia/full de journal.

Correção importante embutida: `agri_np_forest()` e `agri_np_levels()` não
reencaminhavam mais `cluster = NULL` por NSE (o símbolo era lido como nome de
variável e todas as réplicas falhavam); agora o cluster é resolvido por
`.np_resolve_cluster()` e passado como caractere.

Estado verificado dos três conjuntos: **690 asserções, 0 falhas**, e
`R CMD check --as-cran` com **0 ERRORs, 0 WARNINGs, 2 NOTEs** de ambiente.

Para commitar, sincronize os dois diretórios e use uma mensagem que descreva a
razão de cada mudança, no padrão dos commits anteriores. Os três conjuntos
podem ir em um commit cada, na ordem 3.1, 3.2 e 3.3.

### 3.4 Paleta, unidades, anotações e relatório rico (14/08/2026)

Arquivos modificados:

```
 M R/globals.R, R/regression.R (paleta em agri_np_plot, unidade em
    eixos, aviso de B < 999, refatoração wrapper/core)
 M R/regression-forest.R (palette, annotate_values, digits, order_by,
    ref_line)
 M R/reports.R (relatório com tabelas de coeficientes/níveis e figuras)
 M man/agri_np_plot.Rd, man/agri_np_forest.Rd
 M NEWS.md
```

O que esse conjunto entrega:

- paleta Okabe-Ito (daltônica) em `agri_np_plot()` para curvas
  por grupo, com `palette = "grey"` para preto-e-branco;
- argumentos `x_unit`/`y_unit` em `agri_np_plot()` para colocar
  unidades SI nos eixos sem expression();
- `annotate_values` no forest plot, escrevendo "estimativa [IC]" ao
  lado de cada linha;
- `order_by = "effect"` para ordenar linhas por magnitude dentro
  de cada painel;
- `ref_line` personalizável (zero por padrão);
- relatório de regressão com tabela de coeficientes com IC, estrutura
  de fatores, tabela de níveis e figuras (fit, forest, levels) salvas
  ao lado do relatório;
- aviso único por sessão quando `B < 999` (silenciável com
  `options(agriRank.quiet_small_B = TRUE)`).

Estado verificado: **690 asserções, 0 falhas**, e
`R CMD check --as-cran` com **0 ERRORs, 0 WARNINGs, 2 NOTEs** de ambiente.

### 3.5 Incrementos menores (14/08/2026)

Arquivos modificados:

```
 M R/reports.R (agri_format_ci, rtf, citação no relatório)
 M R/regression.R (jitter, print com referência)
 M R/regression-forest.R (caption)
 M NEWS.md, man/agri_table.Rd, man/agri_np_forest.Rd
 M inst/templates/regression-report.qmd (novo)
 M vignettes/v16-nonparametric-regression.Rmd
 M tests/testthat/test-regression-journal.R
```

O que esse conjunto entrega:

- `agri_format_ci()`: texto "1.1 (0.68; 1.5)" pronto para colar no manuscrito;
- `jitter = TRUE` em `agri_np_plot()` para pontos sobrepostos em dose-resposta;
- `caption` no forest plot com explicação do nível de referência;
- `print()` de ajustes com fator informa o nível de referência e que coeficientes são contrastes;
- `agri_table()` com `format = "rtf"` para exportação direta em Word/LibreOffice via gt;
- template Quarto em `inst/templates/regression-report.qmd`;
- bloco "How to cite" nos relatórios de regressão;
- seção sobre editabilidade de figuras na vinheta v16.

Estado verificado: **703 asserções, 0 falhas**, e
`R CMD check --as-cran` com **0 ERRORs, 0 WARNINGs, 2 NOTEs** de ambiente.

Para commitar, sincronize os dois diretórios e use uma mensagem que descreva a
razão de cada mudança. Os cinco conjuntos podem ir em um commit cada, na
ordem 3.1, 3.2, 3.3, 3.4 e 3.5.

### 3.6 Correção do adaptador umbrella (cgam), 15/08/2026

Arquivos modificados:

```
 M R/regression.R            (centralização do preditor no ajuste e na predição)
 M NEWS.md                   (entrada na seção Fixes)
 M tests/testthat/test-integer-regression.R (teste de qualidade do ajuste)
```

**Causa raiz (investigação sistemática):** o cone do termo `umbrella` do cgam
é **sensível à translação do preditor**. Com x todo positivo (ex.: 1..9
plantas), a busca do modo degenera em um ajuste quase constante (RMSE 0,76,
pseudo-R² 0,01), mesmo em dados com pico evidente. O mesmo dado com x
centrado (x−5, intervalo −4..4) ajusta perfeitamente (RMSE 0,07). O exemplo
oficial do cgam usa x em −2..2 (contém zero), por isso nunca falhou lá.
`pen`/`gcv` do cgam não alteram nada nesse caminho; não há argumento de modo
nem grid de lambda exposto na API pública.

**Correção:** o adaptador centraliza o preditor (`x − mean(range(x))`) antes
de chamar o cgam, guarda o deslocamento em `umbrella_center` e o reaplica em
toda predição. A resposta ajustada é invariante (o termo de forma carrega o
próprio intercepto). Resultado: RMSE 0,24, pseudo-R² 0,90, R² CV 0,84, ótimo
{5,6} — empatado com os demais motores inteiros.

**Verificado:** teste novo (pseudo-R² > 0,5 e ótimo em 5..7) falhava antes e
passa depois; suíte completa 705/0/0; `R CMD check --as-cran` 0E/0W/2N.
O tutorial (`tutorial-agriRank.qmd`) foi reescrito para remover a narrativa
de "guarda-chuva ruim" e re-renderizado.

**Commitado em 15/08/2026:** o pacote completo (3.1 a 3.6, com a correção do
umbrella e os ajustes de documentação `agri_format_ci.Rd`, `jitter` e largura
de linha) e o tutorial em português foram commitados e enviados ao GitHub. O
tutorial vive em `cheatsheet/agriRank_Tutorial_PT.qmd` (fonte Quarto) e
`cheatsheet/agriRank_Tutorial_PT.html` (HTML autocontido para visualização),
junto aos cheatsheets PDF.

**Tutorial EN e vinheta v18 (16/08/2026):** a versão em inglês foi criada com
os mesmos chunks, sementes e números da versão PT, renderizada sem erros e
publicada em `cheatsheet/agriRank_Tutorial_EN.qmd` + `.html`. A versão EN
também entrou no pacote como **vinheta em destaque**
`vignettes/v18-integrated-tutorial.Rmd` (VignetteIndexEntry "Integrated
agriRank Tutorial"), com os callouts convertidos para blockquotes e os
exercícios para `<details>` (compatíveis com rmarkdown) e o fluxo final em
lista em vez de mermaid. A vinheta é reconstruída pelo `R CMD check` e usa
`B = 1000`, o que eleva o check para cerca de 20 minutos.

## 4. Ferramentas

| Ferramenta | Versão | Onde |
|---|---|---|
| R | 4.6.0 (2026-04-24 ucrt) | `C:\Program Files\R\R-4.6.0\bin\x64` |
| Rtools | 45 | `C:\rtools45` |
| Quarto, que fornece o pandoc | instalado | `C:\Program Files\Quarto` |
| TinyTeX | instalado | usado para o manual em PDF |
| devtools | 2.5.2 | submissões aos builders |
| gh CLI | 2.83.2 | conta `wep69` |
| Git | 2.55.0 | |

Os 27 backends opcionais de `Suggests` estão todos instalados. Versões exatas em
`validation_0.13.0/backend_versions.csv`.

**Configuração do ambiente.** O script `D:\agriRank-validation\env.ps1` monta o
PATH, define `RSTUDIO_PANDOC` e `_R_CHECK_FORCE_SUGGESTS_`. Carregue com
`. D:\agriRank-validation\env.ps1` antes de qualquer comando. No PowerShell,
`R` sozinho é apelido de `Invoke-History`, use sempre `R.exe` e `Rscript.exe`.

**Atenção à ACL de `D:/RLibrary` (descoberto em 15/08/2026).** A ACL da
biblioteca dá ao usuário comum apenas leitura sobre arquivos existentes
(`Usuários: RX` nos arquivos; AD/WD só em diretórios). Consequência: uma
instalação **não elevada** consegue criar arquivos novos mas **não consegue
substituir nem apagar os antigos** — o `R CMD INSTALL` falha parcialmente em
silêncio e deixa um pacote misturado (funções novas ao lado de internas
antigas). O sintoma é uma função existente com assinatura antiga mesmo com o
código-fonte novo. Instale sempre **como Administrador** (terminal elevado ou
RStudio elevado). Há um script pronto: `D:\agriRank-validation\install_admin.bat`
(remove e reinstala elevado, log em `logs\install_admin.log`). Para validações
rápidas sem elevar, instale numa biblioteca isolada:
`R.exe CMD INSTALL --library=D:\agriRank-validation\lib-tutorial <pkg>` e
aponte `R_LIBS` para ela.

**Tutorial integrado.** O tutorial didático em Quarto está em
`tutorial-agriRank.qmd` (PT) e `tutorial-agriRank-EN.qmd` (EN) na raiz deste
diretório. Cobre os fluxos qualitativo (DIC/DBC/fatorial/split-plot),
quantitativo (regressão), quali+quanti (níveis com IC) e inteiro ordinal
(modelos, ótimo, conjunto de confiança), com exercícios e soluções. Renderize
com `quarto render <arquivo>.qmd`. As versões publicadas ficam em
`cheatsheet/agriRank_Tutorial_PT.{qmd,html}` e
`cheatsheet/agriRank_Tutorial_EN.{qmd,html}` no repositório; a versão EN é
também a vinheta em destaque `v18-integrated-tutorial` do pacote.

**Convenção de estilo do tutorial (preferência do autor, 15/08/2026).**
NÃO usar travessão (—, U+2014) no texto: substituir por dois-pontos ao
introduzir explicação ("subdivididas: análise tipo ANOVA") e por vírgula em
apostos/continuações ("a regressão, mas sem impor um polinômio"). Hífens
comuns (dose-resposta, split-plot) seguem permitidos. Aplicar a todo material
didático e de divulgação do pacote.

Scripts de apoio, todos em `D:\agriRank-validation`:

| Script | Função |
|---|---|
| `run_tests.R` | suíte testthat com resumo |
| `run_check13.ps1` | build e `R CMD check --as-cran`, roda em background |
| `run_coverage.ps1` | cobertura com covr |
| `submit_builders.R`, `submit_win.R` | envio a win-builder e macbuilder |
| `sweep_reg.R` | varredura funcional da regressão, 185 verificações |
| `verify_structure.R`, `verify_backends.R` | verificações do protocolo original |

Os checks levam de 12 a 15 minutos. Dispare em background com `Start-Process` e
consulte o log, em vez de esperar de forma síncrona.

## 5. O que já foi feito

### Validação de tempo de execução

Partiu do protocolo `agriRank_0.12.0.9000_LOCAL_PC_VERIFICATION.md`. O estado
inicial não passava: 11 erros de teste, 4 vinhetas quebradas, 1 ERROR e 3
WARNINGs no check. Foram corrigidos 15 defeitos de origem. Relatório completo em
`agriRank_0.12.0.9000_RUNTIME_VALIDATION_REPORT.md`.

Defeitos mais relevantes, porque revelam padrões:

1. `weights` era resolvido no ambiente da fórmula do usuário e capturava
   `stats::weights`, derrubando loess, GAM, kernel e umbrella.
2. O adaptador rankFD não preenchia `$omnibus`, o que desativava silenciosamente
   `agri_table()`, `agri_sensitivity()` e `agri_batch()` naquela rota.
3. Quatro funções falhavam com erro de subscrito onde havia uma exigência
   científica legítima a comunicar.

### Cobertura, de 74,57% para 86,53%

Seis arquivos de teste novos. A suíte foi de 175 para 622 asserções. Módulos
críticos acima de 90%: `design.R` 91,18%, `incomplete-wild.R` 91,34%,
`missing.R` 98,00%.

### Prontidão para o CRAN

Versão passou a `0.13.0`, licença para `GPL-3` sem arquivo, larguras de Rd
corrigidas por `parse` mais `deparse`, gate das vinhetas removido. Documento:
`agriRank_0.13.0_CRAN_READINESS.md`.

Resultados remotos:

- **macbuilder**, R 4.6.1, macOS arm64: **Status OK**, sem erros, avisos ou notas.
- **win-builder** R-devel e R-release: enviados, resultado por e-mail.

O macbuilder acusou tamanho instalado de 5,5 MB, que viraria NOTE no CRAN. A
causa era um widget Plotly embutido numa vinheta, cerca de 4 MB de JavaScript.
Corrigido, `doc` caiu de 4,68 MB para 0,86 MB.

### Calibração de erro tipo I

Infraestrutura em `inst/calibration/`, com paralelismo, substreams L'Ecuyer por
réplica, checkpoint e retomada. Piloto de 500 réplicas executado, relatório em
`agriRank_0.13.0_CALIBRATION_PILOT.md`.

### Auditoria da regressão

185 verificações funcionais, todas aprovadas. Documento:
`agriRank_0.13.0_REGRESSION_AUDIT.md`.

## 6. O QUE FALTA, em ordem de importância

### 6.1 A descalibração do permuco, item bloqueador

**Este é o item que mais pesa contra usar o pacote em manuscrito.**

O piloto encontrou taxa de rejeição **próxima de zero sob hipótese nula** nos
adaptadores permuco de split-split-plot e strip-plot:

| Termo | Rejeições em 500 simulações a 5% |
|---|---|
| `cultivar` (split-split) | 0 |
| `timing` (split-split) | 0 |
| `irrigation:nitrogen` (strip) | 0 |

Zero em 500 não é ruído. Um teste que nunca rejeita sob H0 também não rejeita
sob H1, ou seja, tem poder quase nulo. E o output sai bonito, com a fórmula
`Error()` estruturalmente correta, sem sintoma algum.

Hipóteses a investigar, em ordem de plausibilidade:

1. o esquema de permutação dentro dos estratos pode estar restringindo demais o
   espaço admissível, gerando distribuições nulas degeneradas. Os avisos
   "the distribution may be discrete" do permuco apontam nessa direção;
2. 999 permutações pode ser pouco para o número de unidades permutáveis com 4
   ou 5 blocos;
3. leitura da coluna de p em tabelas multiestrato, embora o piloto use
   `resampled P(>F)` explicitamente.

Enquanto não se resolver, **prefira ART** nesses dois delineamentos, como já
está registrado no README do repositório.

### 6.2 Calibração completa

Rodar as 10.000 réplicas por cenário:

```
Rscript inst/calibration/run-calibration.R --R=10000 --cores=8
```

Projeção a partir do piloto: cerca de 5,5 horas com 6 núcleos, ou 3 horas com
12. O `--resume` permite interromper. Só depois disso o rótulo experimental do
motor nativo de medidas repetidas incompletas pode ser removido.

Há também um sinal marginal a resolver: `treatment` com 30% de ausência deu
0,0741 contra limite superior de 0,0691. Pode ser flutuação, pode ser inflação
real do efeito between quando a perda por sujeito cresce.

### 6.3 Itens menores

- Commitar o trabalho da seção 3.
- Conferir os dois e-mails do win-builder.
- E-mail de Magali no `DESCRIPTION`, se ela quiser constar. O ORCID já está.
- Gerar o site com `pkgdown::build_site()`. O `_pkgdown.yml` já está pronto.
- Fechar 90% de cobertura em `utils.R` (72,63%) e `effects-contrasts.R` (75,84%).
- Considerar o R-hub, que cobre Linux e compiladores adicionais.

## 7. Duas separações que não devem ser confundidas

**Submeter ao CRAN e citar em manuscrito são decisões distintas.** O CRAN
verifica empacotamento, não validade estatística. O pacote pode ser aceito e
continuar produzindo inferência inutilizável em dois delineamentos. Tecnicamente
a submissão está liberada; cientificamente, não.

**Cobertura de testes e correção também são coisas distintas.** A descalibração
do permuco está em código com 100% de cobertura. Os testes passam, a fórmula
está certa, e a taxa de rejeição é zero. Cobertura mede execução, não correção.
Só a simulação encontrou o problema, e nenhuma quantidade de teste unitário o
teria encontrado.

## 8. Convenções adotadas

- Mensagens de erro dizem a **razão científica**, não o sintoma técnico. Quatro
  defeitos desta série eram erros de subscrito escondendo uma exigência legítima.
- Cada teste novo carrega um comentário explicando **por que** aquilo importa.
- Exemplos usam os dados exportados, declaram unidades e terminam numa leitura
  agronômica.
- Exemplos com reamostragem avisam que `B = 19` é recurso de velocidade e que
  análise exige `B >= 999`.
- Letras de CLD são calculadas dentro de cada estrato, e uma família incompleta
  de comparações é recusada.
- Documentação em inglês, esta conversa em português.
