# WORKING_PAPER_OUTLINE_V2.md

**Purpose**: target structure for the regenerated AUSPAC working paper, post Phase L2 P1c.

**Generated**: 2026-05-26.

This outline replaces the implicit structure of the pre-L2 paper (`dynare/AUSPAC_WORKING_PAPER.md`, 1951 lines, last substantive revision before Phase L2). The regeneration brings the paper in line with:

1. The Phase L2 wp1044-faithful partial-replication methodology (iterative OLS, block-specific VARs, exact χ via depth-m characteristic polynomial, derived growth-neutrality, dummies).
2. The four-of-five-blocks-fit / business-inv-rejection finding documented in `L2_REPLICATION_REPORT.md` and `PAC_BI_AU_EXPLORATION.md`.
3. The hybrid calibration locked into `dynare/au_pac.mod` (BI imported from wp1044 Table 3.5.13; other four blocks at AU L2 estimates).

## Audit summary of the existing paper

### Sections to keep ~as-is

- **§1.1 abstract framing** (model class, FRB/US lineage, AU adaptations) — modest edit.
- **§2 Bird's-Eye View** (model structure diagram, transmission table) — keep, refresh dimensions table.
- **§3.1 E-SAT** — keep; the satellite VAR is unchanged by Phase L2.
- **§3.2 Enriched var_model** — keep; unchanged by Phase L2.
- **§4.1 Notation** — keep.
- **§4.2.1–4.2.2 CES production function and capital accumulation** — keep.
- **§4.4.1 Wage Phillips curve** — keep; wage block was not part of Phase L2 PAC rebuild.
- **§4.7 Household investment** numbering is becoming obsolete; renamed to §4.6.2 Housing inv with L2 refresh. (See "Section renumbering" below.)
- **§4.8 External trade** — keep; trade ECM untouched by L2.
- **§4.9 Demand deflators** — keep.
- **§4.10 Financial variables** — keep.
- **§4.11 Government and GDP identity** — keep.
- **§6.4–6.6 Conditional forecasting, forward guidance, APP** — keep; unaffected by BI hybrid calibration.
- **§8 Australia-specific features** — keep.
- **Appendices A–F** — keep; refresh §A and §B variable/shock lists if any are renamed by the BI calibration edits (none were).

### Sections to rewrite

- **§1 Introduction** — add Phase L2 context paragraph + hybrid calibration disclosure in motivation; refresh Table 1.1 dimensions and add the L2 sample-coverage row.
- **§3.3 PAC microfoundations** — strengthen the coef = +1 structural-restriction discussion (this is the headline failure mode for AU BI); add a forward reference to §5 cross-block findings.
- **§3.5 PAC equation specifications** (new): summary table of all 5 blocks with: Eq number, LHS variable, ECM target, PV terms, depth, dummies, ω calibration. Currently scattered through §4.
- New **§3.5 Iterative OLS estimation pipeline** — the Phase L2 methodology. Six-step pipeline: build block-specific VAR(p), seed coefficients, compute χ from exact characteristic polynomial, compute PV via `(I−χΦ)⁻¹χΦ`, fit OLS on PV-residualised LHS, iterate to convergence.
- New **§3.6 Hybrid calibration: when local data doesn't identify** — Option 1 rationale; references `PAC_BI_AU_EXPLORATION.md` and the small-open-economy literature.
- **§4.2.3 CES calibration** — refresh AU calibration table with current values; no methodological change but refresh numbers.
- **§4.3 VA-price** — replace §4.3.2 Table 4.3.2 with L2 results (β₀=0.258, β₁=0.304, ω=0.62 imposed per wp1044, R²=0.41); add note on aux Phillips+Okun gap; cross-ref new §5.
- **§4.4.2 Employment** — replace Table 4.4.4 with L2 depth-3 employment (β₀=0.314, β₁=0.295, R²=0.81); add Δq̂ contemp regressor; flag the wrong-sign β₄ note.
- **§4.5 Consumption** — replace Table 4.5.2 with L2 results (β₀=0.266 ≈ wp1044's 0.29, β_PAC=1.47, α₁=−81.4 with α₁·χ=−0.81 reduced form, R²=0.81); **lead the headline finding β₀ ≈ wp1044's**.
- **§4.6 Investment** — major rewrite:
  - §4.6.1 housing inv: L2 results with full price-spread term active (β₀=0.495, β₁=0.293, R²=0.43; ABS 6416 RPPI as `pSH`, IPD dwelling inv as `pIH`).
  - §4.6.2 business inv: MAJOR REWRITE documenting the wp1044 structural rejection, the 7+ spec variants tested, the Option 1 decision. Cross-references new Appendix G.
- **§5 Estimation** — keep its existing §5.1–§5.5 structure, but insert NEW §5.0 "wp1044-faithful partial-L2 replication (Phase L2)" at the head — the block-by-block iterative-OLS results table.
- New **§5 Cross-block findings** (renaming current §5 to §6) — see "New sections" below.
- **§6 IRFs** (currently numbered §6) — refresh charts and tables under the hybrid calibration. Three sub-points:
  - Note that BI calibration has changed and IRF magnitudes via the BI channel will reflect wp1044 parameters.
  - Add explicit AU-vs-FR-BDF IRF comparison panels for the four blocks where AU L2 estimates are close to wp1044.
  - Note BI IRFs are wp1044-calibrated; mining shock IRFs flow through E-SAT/trade rather than directly through BI's deep parameters.
- **§7 Conclusion** — restructure around the three new publishable findings: (i) AU PAC framework valid for 4/5 blocks; (ii) consumption β₀ matches France; (iii) AU BI structurally rejects wp1044; hybrid calibration adopted.

### Sections to add

- **§3.5 Iterative OLS estimation pipeline** (already listed above).
- **§3.6 Hybrid calibration** (already listed above).
- **§5 Cross-block findings** (NEW — see below).
- **Appendix G: BI exploration** (NEW — see below).

### Sections to remove or condense

- **§4.11.1, §4.11.2 Rounds 4–8 model extensions** — keep (they describe wired extensions) but condense. Round 1.3 should not be re-described since it was rejected (per memory).
- **§5.3.2 Three dseries approaches** — supersede with the Phase L2 iterative-OLS results; keep one paragraph noting the prior approach as a baseline.
- **§5.3.3 COVID dummy treatment** — collapse into one paragraph; the dummy detail is now distributed across §4 per-block tables.
- **§4.13 AU adaptations vs FR-BDF design** — keep but trim §4.13.4 (calibration imports) to a single paragraph that names the BI block import from wp1044 explicitly and cross-references the new §3.6.

### Section renumbering (target v2 paper)

Current paper has:
- §5 = Estimation
- §6 = Model Properties (steady state, IRFs)
- §7 = Conclusion
- §8 = AU-specific features

Target v2 paper:
- §5 = **Cross-block findings (NEW)**
- §6 = Estimation (current §5 content, refreshed)
- §7 = Model Properties / IRFs (current §6 content, refreshed)
- §8 = Conclusion (current §7, restructured)
- §9 = Australia-specific features (current §8)
- Appendices A–F (unchanged) + new Appendix G (BI exploration).

## Target structure of v2 paper

```
Abstract (refresh with L2 + Option 1 disclosure)
1. Introduction
   1.1 The AU-PAC project context
   1.2 Phase L2 wp1044-faithful partial replication — what this paper documents
   1.3 The hybrid calibration in one paragraph (forward to §3.6)
   1.4 Paper outline
   Table 1.1 Model dimensions (refreshed)
2. Bird's-Eye View
   2.1 Model structure (unchanged)
   2.2 Expectation regimes (unchanged)
   2.3 Transmission channels (unchanged)
3. Expectation Formation, PAC Framework, and Phase L2 Methodology
   3.1 E-SAT (unchanged)
   3.2 Enriched var_model (unchanged)
   3.3 PAC microfoundations (strengthen coef=+1 discussion)
   3.4 Expectation architecture (unchanged)
   3.5 [NEW] Iterative OLS estimation pipeline
   3.6 [NEW] Hybrid calibration: when local data doesn't identify
   Table 3.5: PAC equation specifications (refreshed)
4. Model Specification
   4.1 Notation
   4.2 Supply (4.2.1, 4.2.2, 4.2.3 refreshed)
   4.3 VA-price (Table 4.3.2 replaced with L2 results)
   4.4 Wages and employment (4.4.1 unchanged; 4.4.2 Table 4.4.4 refreshed)
   4.5 Household consumption (Table 4.5.2 refreshed; lead the β₀ match)
   4.6 Investment
       4.6.1 Housing inv (Table 4.6.1.x refreshed; price spread active)
       4.6.2 Business inv — wp1044 calibration with rejection rationale (MAJOR REWRITE)
   4.7 [removed; merged into 4.6]
   4.8 External trade (unchanged)
   4.9 Demand deflators (unchanged)
   4.10 Financial variables (unchanged)
   4.11 Government and GDP identity (unchanged)
   4.12 AU-PAC modelling choices (unchanged)
   4.13 AU adaptations (trim §4.13.4)
5. [NEW] Cross-block findings
   5.1 AU ECM speeds are 4–8× faster than France
   5.2 AU PAC structure validates for 4 of 5 blocks
   5.3 Business investment structurally rejects wp1044: three hypotheses + Option 1
   5.4 Implications for IRF analysis
6. Estimation (formerly §5)
   6.0 [NEW] wp1044-faithful partial-L2 replication — block-by-block iterative OLS
   6.1 Data
   6.2 E-SAT Bayesian estimation (refresh)
   6.3 PAC structural estimation — methodology (refresh, integrate L2)
   6.4 Bayesian full-system estimation (refresh)
   6.5 Pseudo-real-time recursive forecast evaluation (unchanged)
7. Model Properties (formerly §6)
   7.1 Steady state (unchanged)
   7.2 Monetary policy transmission (IRFs refreshed under hybrid calibration)
   7.3 Impulse responses to other shocks (refreshed)
   7.4 AU vs FR-BDF IRF comparison (NEW sub-section)
   7.5 Conditional forecasting (unchanged)
   7.6 Forward guidance experiment (unchanged)
   7.7 APP-style experiment (unchanged)
8. Conclusion (formerly §7, restructured around 3 findings)
9. Australia-specific features (formerly §8)
Appendix A: Complete Variable List
Appendix B: Complete Shock List
Appendix C: Growth Neutrality Proofs
Appendix D: h-Vector Decomposition
Appendix E: Complete Parameter List
Appendix F: Identification Analysis
Appendix G: [NEW] Business investment exploration — the wp1044 PAC restriction on AU data
References
```

## New paper-artifact files to commit

Under `dynare/paper_artifacts/` (created by the build scripts):

- `table_1_trend_efficiency.{txt,tex}` — L1.1 trend efficiency Eq 7
- `table_2_block_trend_regimes.{txt,tex}` — L1.2 block-specific trend growth rates
- `table_3_va_price.{txt,tex}` — VA-price PAC L2 coefficients vs wp1044
- `table_4_employment.{txt,tex}` — Employment PAC L2 coefficients vs wp1044
- `table_5_consumption.{txt,tex}` — Consumption PAC L2 coefficients vs wp1044
- `table_6_housing_inv.{txt,tex}` — Housing inv L2 coefficients vs wp1044
- `table_7_business_inv_wp1044.{txt,tex}` — BI wp1044 calibration import
- `table_8_cross_block_summary.{txt,tex}` — 5-row cross-block summary
- `table_9_bi_exploration.{txt,tex}` — 7+ BI spec variants R²
- `chart_fitted_actual_<block>.png` — per-block fitted vs actual (5 panels)
- `chart_residual_hist_<block>.png` — per-block residual histograms (5 panels)
- `chart_beta0_cross_block.png` — bar chart of β₀ AU vs wp1044
- `chart_bi_exploration.png` — BI spec variant R² bar chart
- `chart_l11_trend_efficiency.png` — L1.1 fitted trend
- `chart_l12_trend_regimes.png` — L1.2 trend regime growth rates
- `irf_<shock>_hybrid.png` — re-generated IRF charts from hybrid model
- `irf_au_vs_wp1044_<block>.png` — AU vs wp1044 IRF panels for the 4 fitting blocks

## Working principles preserved

1. **No re-estimation.** Numbers come from `data/pac_blocks/results_*.{mat,txt}` and from wp1044 Tables 3.3.3 / 3.4.9 / 3.5.2 / 3.5.7 / 3.5.13.
2. **Edit in place.** `Edit` tool on `dynare/AUSPAC_WORKING_PAPER.md`; only rewrite sections flagged above.
3. **Cross-reference, don't duplicate.** Long-form BI saga lives in `PAC_BI_AU_EXPLORATION.md`; the paper carries a summary in §4.6.2 + a tabular appendix.
4. **Per-phase commits.** Phase A (this file + scripts), Phase B (artifacts), Phase C1–C5 (rewrite sections), Phase C6–C10 (BI rewrite, cross-block findings, conclusion, appendix), Phase D (compile + commit).
