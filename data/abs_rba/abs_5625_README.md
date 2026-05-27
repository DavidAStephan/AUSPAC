# ABS 5625 — Private New Capital Expenditure data

**Downloaded**: 2026-05-26, Dec-2025 release (latest at time).

**Purpose**: enables the Phase L3 mining-vs-non-mining BI hypothesis test referenced in §5.3 and Appendix G of `dynare/AUSPAC_WORKING_PAPER.md`. Specifically, Hypothesis B (mining-sector dominance of AU BI dynamics): if the wp1044 PAC rejection on aggregate AU `dln_ib` is driven by mining heterogeneity, then re-estimating the wp1044 PAC equation on the non-mining sub-component should show a smaller PV(Δq̂) deviation from the structural +1.

## Files

| File | Description |
|---|---|
| `abs_5625_07_volume_measures_seasonally_adjusted_capex.xlsx` | Chain-volume real capex, SA, by industry. Headline file for the regression. |
| `abs_5625_04_current_prices_seasonally_adjusted_capex.xlsx` | Current-prices SA, for nominal-deflator construction. |
| `abs_5625_19_current_prices_mining_manufacturing_subdivisions_capex.xlsx` | Within-mining sub-industry detail (coal, oil/gas, metal ores, etc.) for finer-grained analysis. |

## Series structure (Table 07)

Sheet `Data1`. Header row 0 carries the descriptor (semicolon-separated: aggregate ; expenditure type ; chain-volume; industry). Series ID is on row 9. Quarterly observations 1987Q3–2025Q4 (T = 154).

Key columns for the BI split:

| Column | Series ID | Description |
|---|---|---|
| 1 | A124797535F | **Total Buildings & Structures, all industries** (the BI level building block) |
| 2 | A3515875V | **Mining: Buildings & Structures** |
| 3 | A124798315W | **Non-Mining: Buildings & Structures** (incl. Education + Health) |
| 4 | A3515878A | Manufacturing: Buildings & Structures |
| 20 | (Total Eq+Plant) | **Total Equipment, Plant & Machinery, all industries** |
| 21 | (Mining Eq+Plant) | **Mining: Equipment, Plant & Machinery** |
| 22 | (Non-Mining Eq+Plant) | **Non-Mining: Equipment, Plant & Machinery** |

The AUSPAC `au_gfcf_nondwelling` aggregate that drives the existing `dln_ib` is approximately:
`Buildings & Structures total + Equipment, Plant & Machinery total + intangibles` (the latter not in ABS 5625; comes from ABS 5204).

## How to use for the Phase L3 test

1. Build `dln_ib_mining = Δlog(mining buildings + mining E&P)` and
   `dln_ib_nonmining = Δlog(non-mining buildings + non-mining E&P)`.
2. Re-run `data/pac_blocks/estimate_pac_business_inv.m` (and v3 free-PV variant) separately on each sub-series. Same wp1044 functional form; same VAR state.
3. Check whether the **PV(Δq̂) coefficient** under free-PV estimation:
   - Stays at ≈ −5 on **mining** → Hypothesis B partially supported (mining-driven rejection)
   - Approaches +1 on **non-mining** → Hypothesis B strongly supported (non-mining fits wp1044; aggregate is contaminated by mining)
   - Stays at ≈ −5 on **both** → Hypothesis A (different agent objective globally) likely, not mining-specific

4. If the non-mining series passes the coef=+1 test, the production model could move to a two-block BI structure: estimated non-mining PAC + calibrated mining PAC (further Option 1 variant), with a non-mining-dominant aggregate.

## Sample-period notes

- Mining capex series has a clear regime shift 2002→2014 (the resources boom). Sub-sample estimation should consider splitting at 2003Q1 and 2015Q1 or using time-varying intercepts.
- ABS 5625 starts 1987Q3 — 6 years earlier than the AUSPAC base sample. Extending the regression sample back to 1987 vs starting at 1993 may matter for identification.
- The non-mining-including-Education+Health aggregate is closest to the wp1044 "business investment" concept (Australia's tertiary sector + manufacturing). Excluding Education and Health (col 3 doesn't, but the subdivision sums in col 4-19 do) gives a closer cross-country comparison.

## See also

- `PAC_BI_AU_EXPLORATION.md` §6 (the three hypotheses A, B, C)
- `AUSPAC_WORKING_PAPER.md` §5.3 and Appendix G
