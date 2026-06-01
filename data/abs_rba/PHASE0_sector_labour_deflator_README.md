# Phase 0 sector labour + deflator downloads (industry-split project)

Created during industry-split Phase 0 (spec `NEXT_PROJECT_industry_split.md` §3.1).
Goal: obtain mining + non-mining labour (employment, hours), a sector VA deflator,
and by-industry WPI. This file records the exact working SDMX URLs, the dimension
keys, and the data-availability gaps found in this environment.

## TL;DR — MUST-BUILD vs OBTAINED

| Series | Status | Source |
|---|---|---|
| Mining employment (SA, Q) | **OBTAINED** | Labour Account `LABOUR_ACCT_Q`, MEASURE=M19, IND=B |
| Mining hours (SA, Q) | **OBTAINED** | Labour Account `LABOUR_ACCT_Q`, MEASURE=M28, IND=B |
| Total employment + hours (SA, Q) | **OBTAINED** | same flow, IND=TOTAL → non-mining = TOTAL − B (residual) |
| Sector (mining) VA deflator | **STILL-MISSING** (current-price quarterly GVA not on API) → use `rba_i02` A$ commodity proxy (spec §2.1 fallback) |
| By-industry WPI (Mining) | **OBTAINED (Original only)** | WPI flow, INDUSTRY=B; SA only exists for All-Industries |

All four new CSVs are quarterly, Mining (Division B) + Total, ≥115 obs (GATE 0 ≥120
met by the Labour Account 126-obs series; WPI is 115 obs from 1997-Q3).

## ABS Data Explorer SDMX API — working pattern

Base: `https://data.api.abs.gov.au/rest/` (use `curl -sSL`; `data.abs.gov.au` 301s here).
CSV via header `-H "Accept: text/csv"`. Dataflow list:
`https://data.api.abs.gov.au/rest/dataflow/ABS?detail=allstubs`.
DSD + codelists: `…/datastructure/ABS/<FLOW>?references=children`.

### 1. Labour Account (employment + hours, by industry, quarterly) — BETTER than 6291

The spec asked for ABS 6291 EQ06/EQ09. The Labour Account quarterly flow is superior:
it carries employment AND hours, by ANZSIC division, SA, in one flow, 1994-Q3 onward.

Flow `LABOUR_ACCT_Q` ("Labour Account Australia, Final Quarterly Balanced").
Dimension order: `MEASURE . ASGS_2016 . LABOURACCT_IND . TSEST . FREQ`.
Codes used:
- MEASURE: `M19` = Persons; Labour Account employed persons (NUM, ×10^3 persons)
- MEASURE: `M28` = Volume; Labour Account hours actually worked in all jobs (HR, ×10^3)
- ASGS_2016: `AUS`
- LABOURACCT_IND: `B` = Mining; `TOTAL` = Total all industries
- TSEST: `20` = Seasonally Adjusted; `10` = Original
- FREQ: `Q`

Working URLs (saved to this dir):
```
# SA (abs_labour_acct_q_mining_total_sa.csv)
https://data.api.abs.gov.au/rest/data/ABS,LABOUR_ACCT_Q/M19+M28.AUS.B+TOTAL.20.Q?startPeriod=1994-Q1
# Original (abs_labour_acct_q_mining_total_original.csv)
https://data.api.abs.gov.au/rest/data/ABS,LABOUR_ACCT_Q/M19+M28.AUS.B+TOTAL.10.Q?startPeriod=1994-Q1
```
Coverage: M19/M28 × {B,TOTAL}, SA, n=126, 1994-Q3..2025-Q4.
Mining employment share latest = 1.52%; mining hours share = 2.05% (matches spec "~2%").
**Non-mining = TOTAL − B** (residual; mining ≈2% so any non-mining proxy error is tiny).
NOTE: Labour Account "employed persons" differs in level from 6202 LFS (multiple-job/
self-employment treatment); use it consistently for BOTH mining and total so the
share/residual is internally consistent. Do NOT mix LFS total with Labour-Account mining.

### 2. By-industry WPI — Original only (SA not published below All-Industries)

Flow `WPI`. Dimension order: `MEASURE . INDEX . SECTOR . INDUSTRY . TSEST . REGION . FREQ`.
Codes: MEASURE=`1` (Quarterly Index); INDEX=`THRPEB` (Total hourly rates excl bonuses,
matches the in-repo aggregate `abs_6345_wpi.xlsx`); SECTOR=`7` (Private and Public);
INDUSTRY=`B` (Mining) / `TOT` (All Industries); TSEST=`20` SA / `10` Original; REGION=`AUS`; FREQ=`Q`.

```
# By-industry, ORIGINAL (abs_6345_wpi_by_industry_mining_total_original.csv) — has B and TOT
https://data.api.abs.gov.au/rest/data/ABS,WPI/1.THRPEB.7.B+TOT.10.AUS.Q?startPeriod=1997-Q1
# Total, SA (abs_6345_wpi_total_sa.csv) — only TOT returns (no industry SA)
https://data.api.abs.gov.au/rest/data/ABS,WPI/1.THRPEB.7.B+TOT.20.AUS.Q?startPeriod=1997-Q1
```
Coverage: n=115, 1997-Q3..2026-Q1. **Mining (B) WPI is Original only** — the SA query
returns ONLY the All-Industries total (ABS publishes SA only at the aggregate). If a
mining wage wedge is ever needed, X-13 the Original mining series locally; but the spec
(§ "Deferred") keeps ONE national `pi_w`, so by-industry WPI is informational, not on the
critical path.

### 3. Sector VA deflator — NOT obtainable via API (current-price quarterly GVA absent)

Flow `ANA_IND_GVA` ("Production of GDP (P)") is the only by-industry GVA flow.
Dimension order: `MEASURE . DATA_ITEM . SECTOR . TSEST . INDUSTRY . REGION . FREQ`.
The MEASURE codelist *advertises* `C` (Current prices) and `DCH` (Implicit price
deflators), BUT the API holds **ZERO records** for them — confirmed exhaustively:
every combination of MEASURE∈{C,DCH} × DATA_ITEM∈{GPP,IND_GVA,GPM_MIN} × TSEST∈{10,20}
× INDUSTRY=B returns NoRecordsFound. Only chain-volume measures exist:
`VCH, PCT_VCH, TCH, PCT_RCH`. Example that DOES work (volume mining GVA):
```
https://data.api.abs.gov.au/rest/data/ABS,ANA_IND_GVA/VCH.GPM_MIN.SSS.20.B.AUS.Q?lastNObservations=4
```
The quarterly 5206 publication has industry GVA only in chain-volume terms (Table 6 =
`5206006_Industry_GVA.xlsx`, already in repo). There is no `5206005`/`5206007` current-
price industry-GVA table (all 404). Current-price division GVA is published only ANNUALLY
in 5204 (ASNA). So a quarterly current-price mining GVA → quarterly mining VA deflator is
NOT directly downloadable here.

**Fallback in use (spec §2.1 / GATE-0 fallback, already satisfied by existing files):**
the mining VA deflator collapses to the RBA A$ commodity-price index
(`abs_rba/rba_i02_commodity.xlsx`, sheet `Data`, series **GRCPAIAD** = "Commodity prices –
A$, All items", monthly, Index 2024/25=100), which maps to the model's existing `dln_pcom`
driver. The `piQ` composite must therefore be designed to NOT need a regressed sector VA
deflator (spec §2.5 / GATE 0). NOTE `rba_g02_commodity.csv` is a stale HTML error page —
use `rba_i02_commodity.xlsx`.

## Existing-file inventory findings (corrections to the spec)

1. `abs_6202_labour_force.xlsx` and `abs_6202_hours.xlsx` are **aggregate only**
   (by sex / full-part-time / state). NO industry breakdown. Confirmed not usable for the split.
2. `abs_5206_ipd.xlsx` is the **expenditure-side** IPD (C/I/G/X/M/GDP deflators only).
   It does NOT contain any by-industry value-added deflator → does NOT supply a mining VA
   deflator (spec step-1 hypothesis rejected).
3. `abs_5206_industry_gva.xlsx` is **5206 Table 6 = chain VOLUME only**. Data2 is
   "Contributions to growth", NOT current price. No current-price column anywhere.
4. `abs_6345_wpi.xlsx` is **Table 1 = All-Industries** (Private/Public sector split only).
   No industry breakdown. By-industry WPI required the new download above.

### COLUMN-MAP CORRECTION for `abs_5206_industry_gva.xlsx` Data1 (SA, $M chain volume)

The spec §3.1/§3.2/§ "Key file:line anchors" lists these SA-level columns, but they are
each off by +1 (one column too low) versus the actual file. Verified actual columns:

| Series (SA, $M, chain volume) | Spec says col | ACTUAL col |
|---|---|---|
| Mining (B) division TOTAL | 119 | **120** (col 119 = "Exploration & mining support services" sub-industry only) |
| Public administration & safety (O) | 155 | **156** |
| Education and training (P) | 156 | **157** |
| Health care and social assistance (Q) | 157 | **158** |
| Ownership of dwellings | 160 | **161** |
| Gross value added at basic prices (TOTAL) | 161 | **162** |

`build_market_sector_capital.py` (the "fix FIRST" step) MUST use the actual columns above,
and should assert by header text (Series Type row + Units row), NOT by hard-coded index.
GVA-at-basic-prices=162, Taxes-less-subsidies=163, Stat-disc(P)=164, GDP=165.
(This corroborates the spec's own warning to assert-by-text, not by row number.)

## Files written this session
- abs_labour_acct_q_mining_total_sa.csv          (employment+hours, SA)
- abs_labour_acct_q_mining_total_original.csv    (employment+hours, Original; robustness)
- abs_6345_wpi_by_industry_mining_total_original.csv (Mining + Total WPI, Original)
- abs_6345_wpi_total_sa.csv                       (All-Industries WPI, SA; reference)
- PHASE0_sector_labour_deflator_README.md         (this file)
