# AU-PAC Model Data Dictionary

File: `au_pac_model_data.csv` — 128 rows (1993Q1–2024Q4), 44 columns.

Columns 1-19 have data. Columns 20-44 are empty — fill manually from ABS/RBA downloads.

## Column reference

| # | Column | Units | Source | Status | Used by |
|---|--------|-------|--------|--------|---------|
| 1 | `date` | YYYY-MM-DD (quarter start) | — | Have | All |
| **E-SAT Core** | | | | | |
| 2 | `au_ygap` | % output gap | HP filter on FRED NGDPRSAXDCAUQ | Have | varobs |
| 3 | `au_pi` | % quarterly CPI inflation | FRED AUSCPIALLQINMEI | Have | varobs |
| 4 | `au_irate` | % quarterly interest rate | RBA F1.1 cash rate / 4 | Have | varobs |
| 5 | `us_ygap` | % output gap | CBO GDPPOT vs GDPC1 | Have | varobs |
| 6 | `us_pi` | % quarterly inflation | FRED GDPDEF | Have | varobs |
| 7 | `au_irate_bar` | % quarterly | HP trend of cash rate | Have | SS anchor |
| 8 | `au_pi_bar` | % quarterly (= 0.625) | RBA target 2.5% ann | Have | SS anchor |
| 9 | `us_pi_bar` | % quarterly (= 0.500) | Fed target 2.0% ann | Have | SS anchor |
| **Demand / Labor** | | | | | |
| 10 | `au_employment` | Thousands, SA | FRED LFEMTTTTAUQ647S | Have | dln_n |
| 11 | `au_urate` | %, SA | FRED LRUNTTTTAUQ156S | Have | Okun's law |
| 12 | `au_consumption` | AUD, chain volume, SA | FRED NAEXKP02AUQ189S | Have | dln_c |
| 13 | `au_gfcf_nondwelling` | AUD, chain volume, SA | FRED NAEXKP04AUQ189S × 0.70 | Have* | dln_ib |
| 14 | `au_gfcf_dwelling` | AUD, chain volume, SA | FRED NAEXKP04AUQ189S × 0.30 | Have* | dln_ih |
| 15 | `au_exports` | AUD, chain volume, SA | FRED NAEXKP06AUQ189S | Partial | Trade block |
| 16 | `au_imports` | AUD, chain volume, SA | FRED NAEXKP07AUQ189S | Partial | Trade block |
| 17 | `au_i10` | % annualized | FRED IRLTLT01AUQ156N | Have | i_10y |
| 18 | `au_ulc_synthetic` | Index (CPI × emp_norm) | Constructed | Have | pi_w proxy |
| 19 | `au_pi_w_synthetic` | % quarterly | dlog(ulc) × 100 | Have | Bayesian obs |

*Note: GFCF split uses fixed 70/30 ratio. Better: use ABS 5206.0 Table 2 actual dwelling/non-dwelling volumes.

## Columns to fill manually (20-44)

### ABS 5206.0 Table 5 — Implicit Price Deflators (index, SA)

Download from: https://www.abs.gov.au/statistics/economy/national-accounts/australian-national-accounts-national-income-expenditure-and-product/latest-release → Data downloads → Table 5

| # | Column | What to paste | ABS series |
|---|--------|---------------|-----------|
| 20 | `ipd_consumption` | Household final consumption IPD | 5206.0 Table 5, "Households; Final consumption expenditure" |
| 21 | `ipd_business_inv` | Non-dwelling construction + M&E IPD | 5206.0 Table 5, "Private; GFCF - Total private business investment" |
| 22 | `ipd_housing_inv` | Dwelling investment IPD | 5206.0 Table 5, "Private; GFCF - Dwellings - Total" |
| 23 | `ipd_exports` | Exports IPD | 5206.0 Table 5, "Exports of goods and services" |
| 24 | `ipd_imports` | Imports IPD | 5206.0 Table 5, "Imports of goods and services" |
| 25 | `ipd_government` | Government consumption IPD | 5206.0 Table 5, "General government; Final consumption expenditure" |
| 26 | `ipd_gdp` | GDP IPD | 5206.0 Table 5, "GROSS DOMESTIC PRODUCT" |

### ABS 5206.0 Table 2 — Chain Volume Measures ($M, SA)

Same download as above → Table 2

| # | Column | What to paste | ABS series |
|---|--------|---------------|-----------|
| 27 | `vol_exports_abs` | Export volumes (better than FRED) | 5206.0 Table 2, "Exports of goods and services" |
| 28 | `vol_imports_abs` | Import volumes (better than FRED) | 5206.0 Table 2, "Imports of goods and services" |

### ABS 6416.0 / CoreLogic — Housing Prices

| # | Column | What to paste | ABS series |
|---|--------|---------------|-----------|
| 29 | `rppi_housing_prices` | Residential Property Price Index | 6416.0 (ended 2021) or CoreLogic Home Value Index |

### RBA Table F5 — Lending Rates

Download from: https://www.rba.gov.au/statistics/tables/ → F5

| # | Column | What to paste | RBA series |
|---|--------|---------------|-----------|
| 30 | `mortgage_rate_rba` | Standard variable rate, owner-occupier (% ann) | RBA F5, end-of-quarter |

### ABS 5206.0 Table 7 — GDP Income Components (current prices, $M, SA)

This is the key table for CES alpha estimation.

Download from: same 5206.0 page → Table 7

| # | Column | What to paste | ABS series |
|---|--------|---------------|-----------|
| 31 | `compensation_of_employees` | COE ($M, current prices, SA) | 5206.0 Table 7, "Compensation of employees" |
| 32 | `gross_operating_surplus` | GOS ($M, current prices, SA) | 5206.0 Table 7, "Gross operating surplus" |
| 33 | `gross_mixed_income` | GMI ($M, current prices, SA) | 5206.0 Table 7, "Gross mixed income" |
| 34 | `taxes_less_subsidies_prod` | T-S ($M, current prices, SA) | 5206.0 Table 7, "Taxes less subsidies on production and imports" |
| 35 | `gdp_current_prices` | GDP ($M, current prices, SA) | 5206.0 Table 7, "Gross domestic product" |

### ABS 6345.0 — Wage Price Index (index, SA)

Download from: https://www.abs.gov.au/statistics/economy/price-indexes-and-inflation/wage-price-index-australia/latest-release

| # | Column | What to paste | ABS series |
|---|--------|---------------|-----------|
| 36 | `wage_price_index` | Total hourly rates excl bonuses, All sectors, SA | 6345.0 Table 1 (starts 1997Q3) |

### ABS 6202.0 — Labour Force (SA)

Download from: https://www.abs.gov.au/statistics/labour/employment-and-unemployment/labour-force-australia/latest-release

| # | Column | What to paste | ABS series |
|---|--------|---------------|-----------|
| 37 | `hours_worked` | Monthly hours worked in all jobs (millions, SA) | 6202.0 Table 19 (quarterly average) |

### ABS 5204.0 — Capital Stock (annual, current prices, $M)

Download from: https://www.abs.gov.au/statistics/economy/national-accounts/australian-system-national-accounts/latest-release

| # | Column | What to paste | ABS series |
|---|--------|---------------|-----------|
| 38 | `net_capital_stock` | Net capital stock, All industries ($M) | 5204.0 Table 51 (annual → repeat for 4 quarters) |
| 39 | `consumption_fixed_capital` | CFC, All industries ($M) | 5204.0 Table 52 (annual → divide by 4 for quarterly) |

### Additional series

| # | Column | What to paste | Source |
|---|--------|---------------|--------|
| 40 | `reer_bis` | Real effective exchange rate (broad, index) | BIS via FRED: RBAUBIS |
| 41 | `commodity_price_index` | RBA commodity price index (AUD) | RBA Table I1 or IMF PCOTTINDEXM |
| 42 | `govt_consumption_volume` | Govt final consumption ($M, chain vol, SA) | ABS 5206.0 Table 2 |
| 43 | `population` | Estimated resident population (thousands) | ABS 3101.0 |
| 44 | `labor_force` | Civilian labor force (thousands, SA) | ABS 6202.0 |

## How data flows into the model

```
au_pac_model_data.csv
    ↓
    ├── dataset.csv (cols 1-9) → download_data.m
    ├── extended_dataset.csv (cols 10-19) → download_extended_data.m
    ├── abs_rba_dataset.mat (cols 20-30) → process_abs_rba_data.m
    │
    ├── prepare_smoother_data.m → smoother_data.mat (9 obs for calib_smoother)
    ├── prepare_bayesian_data.m → estimation_data.mat (9 obs for Bayesian)
    ├── prepare_pac_dseries_hybrid.m → dseries (PAC estimation)
    │
    └── estimate_ces_supply.m (cols 31-39) → CES parameters
```

## Priority for CES estimation (Phase 5)

The most important columns to fill are:
1. **cols 31-35** (income components) — needed for alpha_k
2. **col 36** (WPI) — needed for wage level in price frontier
3. **col 37** (hours worked) — needed for efficiency-adjusted wage
4. **cols 38-39** (capital stock) — needed for delta_k and capital return

With just cols 31-35, we can estimate alpha_k directly:
```
labor_share = COE / (COE + GOS + GMI)
alpha_k = 1 - labor_share
```

With cols 26 + 36 + 37, we can do the FR-BDF nonlinear grid search for sigma_ces:
```
log(ipd_gdp) = const + f(sigma, alpha, WPI/hours, user_cost)
```
