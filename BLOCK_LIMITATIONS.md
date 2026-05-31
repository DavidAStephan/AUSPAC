# BLOCK_LIMITATIONS.md — wp1044 partial-L2 data gaps for AU

Documented as part of the Phase L2-A data layer survey (2026-05-26).

> **UPDATE (2026-05-30, Wave 2): two of the gaps below were already closed in `l2_data_layer_v2.mat` — the caveats are stale.**
> - **BI exports**: `l2_data_layer_v2.mat` contains `exports`, `df_full` (= c + ih + exports), and a wacc-based `r_KB`. The BI estimator uses `df_full`. Re-tested with the complete `df` + wacc `r_KB`, AU business investment **still rejects** the PAC restriction (R²≈0.09, β₃ insignificant, no valid χ root) — so the rejection is robust and the wp1044 Option-1 calibration is justified, **not** a missing-data artifact.
> - **Housing price-spread**: `l2_data_layer_v2.mat` contains `p_SH` (ABS 6416 RPPI) and `p_IH` (ABS 5206 IPD). The housing estimator **does** build and estimate the `(p_SH − p_IH)` spread term; it is insignificant/wrong-signed on AU data (β₃ ≈ −2.8, t<1), consistent with the production model's `b_ph_ih = 0`.
> - **Commodity→CPI**: `dln_pcom` (RBA I02) is in `trade_price_data.mat`; the CPI Phillips now estimates `gamma_oil` = −0.0147 (insig, wrong-signed) — the flat-AU-Phillips finding is robust to the commodity channel.

## Missing AU observables

### Exports / Imports
- **Status**: FRED downloads (`NAEXKP06AUQ189S`, `NAEXKP07AUQ189S`) returned HTML error pages, not CSV data. Both files exist in `data/` but contain `<!DOCTYPE html>` rather than time-series rows.
- **Impact**: 
  - Business investment block (`df` synthetic final demand): wp1044 defines `df = c + g_inv + h_inv + exports`; without exports, AU proxy collapses to `df_AU ≈ c + h_inv` (incomplete).
  - **Mitigation**: use `df_AU = au_consumption + au_gfcf_dwelling` and document the missing exports component. Business inv coefficients should be interpreted with this caveat.
- **Fix**: re-run `data/download_extended_data.m` after debugging the FRED API call, or get the series from ABS 5206 Table 2 (national accounts expenditure breakdown).

### Housing deflators (pSH, pIH)
- **Status**: AUSPAC does not have separate observables for:
  - `pSH` — existing-housing-stock deflator
  - `pIH` — new-housing-investment deflator
- **What we have**: `au_gfcf_dwelling` (housing investment volume), `data/house_price_spliced.csv` (a single spliced house-price series), `data/abs_rba/abs_6416_rppi.csv` (residential property price index).
- **Impact**: 
  - Housing investment block (wp1044 Eq 37): the `β_3 · [(p_SH - p_IH)_{t-1} - (p_SH - p_IH)_{t-5}]` price-spread term cannot be constructed cleanly.
  - **Mitigation A**: skip the price-spread term; estimate without it; document.
  - **Mitigation B**: use the spliced house-price series as `p_SH` and construct `p_IH` as the implicit price deflator of dwelling investment (= nominal/real ratio if both available). Requires nominal au_gfcf_dwelling.
- **Decision**: try Mitigation B during housing-inv block work; fall back to A if data insufficient.

### Government investment / consumption split
- **Status**: `au_gfcf_nondwelling` includes both business + government non-dwelling investment. Government investment is not separable.
- **Impact**: synthetic `df` (above) and the business inv ECM target both nominally exclude government investment from "business inv". With AU data, business inv is the lumped private+government series. Coefficient estimates apply to the aggregated quantity.
- **Decision**: document the aggregation and proceed.

### NPISH (non-profit institutions serving households) split
- **Status**: AU `au_consumption` is total household consumption; NPISH not separate.
- **Impact**: wp1044 `df` includes "household AND NPISH consumption" — they combine the two anyway, so this is fine.
- **Decision**: no impact; AU consumption = wp1044 (c_H + c_NPISH).

### Household disposable income `y_H` in level form
- **Status**: AUSPAC's `prepare_household_income.m` constructs `au_wt_H_real_gap` which is the HP-filter GAP of log(real wages + transfers). The LEVEL series exists but is not currently in `extended_dataset.csv`.
- **Impact**: wp1044 consumption block needs `y_H` in levels for the LR Eq 33 target.  
- **Mitigation**: extract `log(W_H + TG_H)/p_C` directly from `prepare_household_income.m` workings and add to extended_dataset.
- **Decision**: do this in Phase A6.

## What this implies for block deliverables

| Block | Can replicate? | Caveat |
|---|---|---|
| VA-price | YES (full) | All inputs available; wpi has 110 obs |
| Employment | YES (full) | All inputs available |
| Consumption | YES (mostly) | y_H level needs construction; otherwise complete |
| Housing inv | PARTIAL | Drop price-spread term β_3 or use Mitigation B |
| Business inv | PARTIAL | `df` missing exports component |

The replication is 4-of-5-blocks "full" + 2-of-5-blocks "partial with documented gaps". The L2_REPLICATION_REPORT.md should make these gaps explicit.
