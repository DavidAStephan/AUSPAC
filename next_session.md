# next_session.md — AUSPAC single entry point (authoritative)

**As of 2026-05-31, `main` @ 21e00f8.** This is the single file to read first next session:
current state, what's done, what remains (prioritised), how to reproduce, and the new-scope
specs. It supersedes the former `STATUS.md` / `NEXT_STEPS.md` / `WAVE3_ROADMAP.md` trio.

Project goal (unchanged): *a functioning, close replication of FR-BDF (Banque de France WP #736,
Lemoine et al. 2019; updated 2026 in WP #1044, Dubois et al.) on Australian data that estimates
every behavioural equation — nothing calibrated except the theoretical / steady-state quantities
FR-BDF itself fixes.*

> **Methodology note (read first).** Production parameters come from **equation-by-equation OLS /
> calibration following FR-BDF wp1044 §2.2** — the same estimation philosophy as FR-BDF itself.
> The earlier full-system **Bayesian MCMC pipeline was removed** in cleanup `7995ce7` (with
> `au_pac_bayesian.mod`, `dynare/simulation/`, `nk_*.mod`, etc.). Any LMD / Laplace / MHM number in
> older docs or in `AUSPAC_WORKING_PAPER.md` §6.2/§6.4 is **historical** and not reproducible.

---

## Current state

Model: [`dynare/au_pac.mod`](dynare/au_pac.mod) — self-contained, **182 declared endo / 55 shocks /
~351 parameters**. BK-stable (5 explosive eig, max|eig|=1.087); all level accumulators revert to ≈0
at Q200 (long-run money-neutral, `lambda_hyst = 0`). **~40–45 % of behavioural parameters are
genuinely AU-estimated.** Toolchain: Dynare **7.0-arm64** (`~/Applications/Dynare/7.0-arm64`) +
MATLAB **R2026a** (maca64; earlier Dynare 6.5 / R2020a-under-Rosetta is retired).

| Block | Status | How AUSPAC gets the parameters |
|---|---|---|
| VA-price PAC | **AU-estimated** | iterative OLS (`results_va_price`), N=108, R²=0.41 |
| Wage Phillips | **AU-estimated** | BK-constrained OLS (`results_wage_phillips_constrained`), κ_w=0.343 |
| Employment PAC | **AU-estimated** | OLS depth-3, exact χ (`results_employment`), N=124, R²=0.86, b0_n=0.48 |
| Consumption PAC | AU-estimated (short-run) | OLS (`results_consumption`), β₀=0.23 ≈ wp1044 0.29; PV² operator not built |
| Housing inv PAC | AU-estimated (short-run) | OLS (`results_housing_inv`), b0_ih=0.60; price-spread on proxy pSH/pIH |
| **Business inv PAC** | **calibrated from wp1044** | Table 3.5.13 (Option 1 hybrid); AU rejects the PAC FOC (R²≈0.09) |
| Exports / Imports | short-run AU-OLS; LR borrowed | SA-data ECM (`results_exports`/`results_imports`); LR elasticities + energy-import block reverted to wp1044 |
| Demand deflators | AU-OLS | per-deflator OLS; **CPI Phillips is flat** (R²=0.06, only persistence identified) |
| Supply / CES | calibrated (legit) | α=0.45, σ=0.5366 from wp1044; γ_ulc/γ_uck CES-pinned |
| Financial / WACC / UIP | calibrated SS; AR(1) persistences AU-estimated | `rho_tp`/`rho_lh`/`rho_BBB`/`rho_LB_firms` estimated; `rho_s` still calibrated (B2) |
| Household credit / DSR (wp1044 §3.7.2) | **AU-estimated** (exogenous AR(1)) | `DSR_gap` from RBA E2×F5; rationally-consistent stock pending (C2) |
| NFC accelerator (wp1044 §3.7.3) | **AU-estimated** (leverage-based) | `lev_nfc_gap` from RBA D2 → spreads; endogenous stock pending (C2) |
| HICP decomposition | calibrated | identity-only reporting block (behavioural promotion = B1) |

**Fidelity rubric:** *AU-estimated* = every behavioural coef is an AU OLS point estimate (insignificant/
wrong-signed values written back verbatim per the OLS-over-calibration convention). *AU-estimated
(short-run)* = dynamics AU-estimated, long-run target uses an HP-trend/proxy not a wp1044 FOC object.
*calibrated from wp1044* = deep params imported because AU data rejects (BI) or can't identify the
restriction; documented, not a silent carryover. *calibrated (legit)* = theoretical/SS quantities
FR-BDF itself calibrates. Block-by-block detail: [`L2_REPLICATION_REPORT.md`](L2_REPLICATION_REPORT.md),
[`PAC_EQUATIONS_AUDIT.md`](PAC_EQUATIONS_AUDIT.md), working paper §4–§5.

---

## Recently completed (do NOT redo) — PRs #11–#15, 2026-05-30/31

- **Docs truth-up** — README/RUNNING rewritten to the OLS reality; working-paper errata + dimensions
  (182/55/351) + Dynare 7.0; reproducible `forecast_eval.m`; fidelity rubric.
- **Model correctness** — potential-output hysteresis fixed toward long-run neutrality (`lambda_hyst = 0`);
  `ln_IH`/`ln_IB` reporting trends fixed; `h_pac` re-verified bit-identical.
- **PAC machinery verified** — `dynare/verify_pac_chi_pv.m`: the `(I−χΦ)⁻¹χΦ` operator is correct to
  machine precision and source-faithful; **employment-χ bug fixed** (approximate depth-1 → exact
  depth-m; R² 0.82→0.86, b0_n 0.31→0.48).
- **AU estimation** — `rho_tp` 0.98→0.88, `rho_lh` 0.97→0.91, `gamma_oil` (commodity→CPI); spread
  persistences `rho_BBB`/`rho_LB_firms`. BI rejection confirmed **robust**.
- **New wp1044 blocks** — household credit/DSR (§3.7.2) + leverage-based NFC accelerator (§3.7.3),
  AU-estimated. Finding: AU spreads are *pro-cyclical* via the credit cycle (opposite of Bernanke-Gertler).
- **Drift resolved** — consumption/housing SA re-estimates written back (β₀ 0.27→0.23, b0_ih 0.50→0.60).
- **Quick wins A1–A3 (2026-05-31)** — (A1) removed duplicate `eps_pm_ne`/`eps_pm_e` `varexo` (no more
  "declared twice" warnings); (A2) the 3 formerly-`(not estimated)` shock stds are now AU OLS residual
  stds — `eps_q_us` 1.1118, `eps_pi_us` 0.2625 (`data/pac_blocks/estimate_foreign_block.m`), `eps_pQ`
  0.6975 (`estimate_pac_va_price.m` now reports `resid_sd`); (A3) Table 4.5.2 fully re-tabulated on the
  SA layer (α₁·χ reduced form now −1.27 ≈ France's −1.15).
- **Paper IRF refresh (2026-05-31)** — §7 IRF numbers (abstract, errata, Table 6.3, six-channel
  walkthrough, Table 6.4 RBA comparison, verdict, all §7.3 captions, conclusions) re-extracted from the
  current model (`dynare/extract_irf_numbers.m`) after the ECM-speed writebacks; 100bp monetary real-GDP
  trough −0.073%/−0.098% → **−0.144% @Q11**, output-gap → **−0.086%**. `stoch_simul` extended with
  `dln_x dln_m ln_QN`. **Two model-property findings flagged for review:** (a) **fiscal multiplier is now
  large** — 1%-of-GDP `eps_g` → output-gap +0.91% / real-GDP +1.56% (was +0.18%); worth a λ_dom /
  spending-share sensitivity check; (b) **TFP→output-level transmission is degenerate** (`eps_tfp_LR`
  σ=0.01 + §6.8 refactor → ≈0 output at 1 s.d.; the old "+13% ln_Q" Fig 6.8 was a pre-refactor σ=0.2
  illustration).

---

## Remaining work (prioritised)

### A — Quick wins ✓ ALL DONE 2026-05-31

### B — Data-blocked (need a download / a constructed series)
- **B1. Energy oil+gas split + HICP behavioural components** (wp1044 §3.6.4 / Appx E). Needs an AU energy
  price series — RBA I02 has no oil/gas sub-component. Path: ABS 6457 petroleum sub-index (fragile
  versioned xlsx URL), or Brent-in-AUD (global oil × RBA F11). Then split the energy-import block and
  promote the HICP food/energy reporting variables to behavioural equations. *Specs: Appendix §3.4–3.5.*
  Effort ~3–4 days once the series exists.
- **B2. `rho_s` (real-exchange-rate gap)** — the `s_gap` equation carries a forward UIP term (`pv_i_uip`),
  so a bare AR(1) is misspecified; needs joint/IV estimation. TWI available (RBA F11).
- **B3. Trade long-run elasticities** (`beta_x`/`gamma_x`/`beta_m_ne`/…) — AU OLS gives wrong-signed/insig
  values (mining vs non-mining composition). Either build the resource/non-resource export split
  ([`NEXT_PROJECT_export_resource_split.md`](NEXT_PROJECT_export_resource_split.md)) or accept as a
  documented permanent calibration exception.

### C — Structural (research-grade, higher risk/effort)
- **C1. Quasi-endogenous employment/investment anchors** (wp1044 §3.4.3/§3.5.3). Replaces exogenous trend
  targets with conjuncture-responsive ones (fixes Round 4–8 over-dampening). **Lowest ROI**: anchors are
  already semi-endogenous, the most-affected block (BI) is calibrated anyway, and it changes the VAR
  companion → `h_pac` (needs `pac.print()` regen + careful BK validation). *Specs: Appendix §3.1.*
- **C2. Make the DSR/credit + NFC blocks "rationally consistent."** Added as exogenous AR(1)s; the faithful
  version makes household debt / NFC leverage endogenous stocks (ECM) and adds `DSR_gap`/`lev_nfc_gap` to
  the relevant aux-VARs + regenerates `h_pac` so agents *anticipate* the shocks. Also addresses the broader
  "Round 4–8 not rationally consistent" gap.
- **C3. Hand-to-mouth + PV² consumption operator** (wp1044 §3.5.1). Round 1.2 added the `wt_H_real_gap`
  plumbing; promote `b_HtM` to `estimated_params` (or add the income series to `varobs`) and build the PV² term.

### D — Validation & rigor
- **D1. Extend `forecast_eval.m`** from 1-step to multi-horizon (h=1…8) and more observables; optionally a
  true recursive re-estimation variant.
- **D2. (from the IRF refresh) Review the two flagged model properties** — the large fiscal multiplier and
  the degenerate TFP→output transmission (see "Recently completed" / paper §7.3.3 + §7.3.6).

---

## Operational notes
- **RBA downloads work** via `https://www.rba.gov.au/statistics/tables/csv/<table>-data.csv` (e.g. `f5`,
  `e2`, `f3`, `d2`). ABS "latest-release" landing pages return HTML — need the specific versioned xlsx URL.
- **MATLAB** is invoked by full path (not on PATH): `/Applications/MATLAB_R2026a.app/bin/matlab -batch "..."`.
- **Paper build**: `pandoc AUSPAC_WORKING_PAPER.md -o AUSPAC_WORKING_PAPER.tex --standalone --mathjax
  --include-in-header=paper_header.tex` then `tectonic AUSPAC_WORKING_PAPER.tex` (both installed; run from `dynare/`).
- **Diagnostics** (run from `dynare/`): `check_bk.m` (BK), `validate_wave1.m` (100bp IRF + Q200 neutrality),
  `verify_pac_chi_pv.m` (χ/PV operator), `extract_irf_numbers.m` (every paper-cited IRF number).
- **χ solvers**: employment uses `solve_pac_chi_exact` (exact depth-m); consumption uses `solve_pac_chi` with
  a single `[beta_1]` (genuinely depth-1). `solve_pac_chi` is approximate for depth>1 — don't pass multi-lag vectors.
- **Reproducibility**: `dataset.csv` restore-on-demand (`git show 7995ce7^:dataset.csv > dataset.csv`); the L2
  data layers regenerate deterministically via `data/prepare_l2_data.m` + `prepare_l2_data_extras.m`.

## Reproduce results
```matlab
% 0. (once) restore the base dataset if absent:  git show 7995ce7^:dataset.csv > dataset.csv
% 1. Refresh PAC-block coefficients from AU data (~minutes)
cd data; run('run_all_l2_ols.m');   % 5 core PAC blocks
%   standalone: estimate_wage_phillips_constrained.m, estimate_cpi_phillips.m, estimate_deflators.m,
%   estimate_trade_exports.m / estimate_trade_imports.m, estimate_foreign_block.m
% 2. Write updated coefficients into dynare/au_pac.mod (per-block writeback)
% 3. Solve + regenerate IRFs and paper artifacts (~1 min)
cd ../dynare; run('regen_all_artifacts.m');
```

## Repository layout
```
AUSPAC/
├── README.md / RUNNING.md / next_session.md     entry / run / ★ this file (state + backlog + specs)
├── L2_REPLICATION_REPORT.md                      per-block wp1044-vs-AU comparison
├── PAC_EQUATIONS_AUDIT.md                         equation-by-equation fidelity audit
├── BLOCK_LIMITATIONS.md                           AU data gaps per block
├── CES_PRODUCTION_FUNCTION_APPROACH.md            CES calibration method
├── ESAT_ARCHITECTURE_AUDIT.md / IRF_*.md / TRENDS_COMPARISON.md   design/investigation records
├── NEXT_PROJECT_export_resource_split.md          B3 follow-up spec
├── dataset.csv                                    base E-SAT observables (restore via git show)
├── references/                                    wp736, wp1044, ECB-BASE, RBA transmission
├── data/
│   ├── pac_blocks/   estimate_*.m + results_*.{mat,txt}   ← production PAC coefficients
│   ├── prepare_*.m / download_*.m                          data build
│   └── run_all_l2_ols.m                                    5-PAC-block OLS driver
└── dynare/
    ├── au_pac.mod                                 ★ production model (self-contained)
    ├── aux/aux_{pQ,consumption,business_inv,housing_inv,employment}.mod   PAC aux (pac.print source)
    ├── regen_all_artifacts.m / extract_irf_numbers.m / check_bk.m / validate_wave1.m
    ├── AUSPAC_WORKING_PAPER.{md,tex,pdf}           the working paper (137pp)
    └── paper_artifacts/                            figures + tables
```

---

## Appendix — new-scope (wp1044) block specs

Status: Waves 0/1/2/4 executed; Wave 3 partially executed (RBA CSV `tables/csv/<t>-data.csv` works; ABS
landing pages do not). **DONE this branch:** §3.2 DSR block (rho_DSR=0.864), §3.3 leverage-based NFC
accelerator (rho_lev=0.93, kappa_lev_BBB=0.019), `rho_lh` 0.97→0.9133, employment-χ exact solver, the
3 "(not estimated)" shock stds (A2). **Genuinely blocked:** §3.4/§3.5 energy split + HICP behavioural
(no AU oil/gas series); §3.1 quasi-endogenous anchors (research-grade, alters `h_pac`).

### 3.1 Quasi-endogenous employment / investment anchors (wp1044 §3.4.3, §3.5.3)
Replace the *exogenous* trend targets `n*_S`, `I*_B` with **quasi-endogenous** anchors that respond
partially to the output/profit gap (wp1044's fix for the same over-dampening AUSPAC's Round 4–8 note flags).
Trend equations already carry partial conjuncture terms; the aux-VAR target projections (`n_hat`, `ib_hat`)
are what the PAC expectation uses. **No new data.** Implementation: (1) in `aux/aux_employment.mod` /
`aux/aux_business_inv.mod`, add a quasi-endogenous loading of the target's trend component on a slow-moving
conjuncture state; (2) expand the block `var_model` state vector and re-run `pac.print()`; (3) write the
regenerated `h_pac_<block>_*` into `au_pac.mod`, re-solve, confirm BK with `check_bk.m`, check IRF
amplitude. **Risk medium-high:** changes the VAR companion → `h_pac` (unlike b0/b1 ECM speeds, which leave
`h_pac` invariant). Validate BK + IRFs carefully.

### 3.2 Household credit + DSR (wp1044 §3.7.2) — ✅ DONE (PR #13); rational-consistency follow-up = C2
Implemented as exogenous AR(1) `DSR_gap` (RBA E2 BHFDDIT × RBA F5 mortgage rate) → `eq_dln_c_star_bar`
(rho_DSR=0.864, alpha_DSR=−0.10). **Remaining (C2):** make mortgage debt an endogenous stock (ECM toward a
target driven by housing wealth + income), DSR = debt·interest/disposable-income, add `DSR_gap` to the
consumption/housing aux-VARs + regenerate `h_pac`. Data: RBA E2/D2, ABS 5206 Table 20.

### 3.3 NFC financial accelerator (wp1044 §3.7.3) — ✅ DONE (PR #13, leverage-based); stock follow-up = C2
`lev_nfc_gap` (RBA D2 business credit, rho_lev=0.93) feeds the corporate spreads (kappa_lev_BBB=0.019, t=3.0),
replacing the wrong-signed output-gap proxy. See `data/pac_blocks/estimate_nfc_leverage.m`. **Remaining (C2):**
make `lev_nfc` an endogenous debt/equity stock rather than an AR(1).

### 3.4 Energy split — oil+gas synthetic index (wp1044 §3.6.4 / Appx E) — partially present (B1)
AUSPAC has `dln_pcom` (RBA I02) → CPI via `gamma_oil` and an energy/non-energy import split
(`pi_m_e`/`pi_m_ne`, `eps_pm_e`) with the energy block at wp1044 calibration. Missing: a *separate AU oil/gas
index* and AU estimation of the energy-import block. Data: ABS 6427 (import price index by SITC, incl.
petroleum) or Brent/TTF-in-AUD via RBA F11. Build `dln_penergy`, replace the broad `dln_pcom` in the
energy-import block, estimate `beta_m_e`/`gamma_m_e`. **Blocker:** ABS 6427 download + SITC parse.

### 3.5 HICP behavioural components (wp1044 §3.6.4) — (B1)
AUSPAC's HICP decomposition (`pi_au_food`, `_energy`, `_core`) is a one-way *reporting* identity. Promote
food/energy to behavioural equations (food on ABS food CPI + ag prices; energy on `dln_penergy` from §3.4),
feeding back into `pi_au` via the existing aggregation weights. Gated on §3.4.

---

## References & citation
| Source | Where |
|---|---|
| FR-BDF wp736 (Lemoine et al., 2019) | [`references/wp736.pdf`](references/wp736.pdf) |
| FR-BDF wp1044 update (Dubois et al., 2026) | [`references/FR-BDF-update.pdf`](references/FR-BDF-update.pdf) |
| ECB-BASE (Angelini et al., 2019) | [`references/ecb-base.pdf`](references/ecb-base.pdf) |
| RBA monetary transmission (Mulqueeney, Ballantyne, Hambur 2025) | [`references/RBA_mon_transmission.pdf`](references/RBA_mon_transmission.pdf) |

> Stephan, D. (2026). *AU-PAC: A Semi-Structural Macroeconomic Model for Australia.* Working paper, v4.0.
> Lemoine, M., et al. (2019). *The FR-BDF Model…* Banque de France WP No. 736.
> Dubois, U., et al. (2026). *Re-estimated FR-BDF.* Banque de France WP No. 1044.
