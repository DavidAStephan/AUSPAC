# AUSPAC — Project status

**Version**: v4.0 (equation-by-equation OLS production line; 2026-05-30 SA-data fix + progress review)
**Model**: [`dynare/au_pac.mod`](dynare/au_pac.mod) — self-contained production model, 180 declared endogenous variables (≈195 after Dynare auxiliary-variable expansion), 53 exogenous shocks, 351 parameters.
**Toolchain**: Dynare **7.0-arm64** (`~/Applications/Dynare/7.0-arm64`) + MATLAB **R2026a** (maca64). *(Earlier docs referenced Dynare 6.5 / MATLAB R2020a under Rosetta — that environment is retired.)*

> **Methodology note (read first).** As of commit `54d8ff7` the production parameters come from **equation-by-equation OLS / calibration following FR-BDF wp1044 §2.2** — the same estimation philosophy as FR-BDF itself. The earlier full-system **Bayesian MCMC pipeline was removed** in cleanup `7995ce7` (along with `au_pac_bayesian.mod`, `dynare/simulation/`, `phaseW_recherrypick.m`, `dynare/regen/`, `nk_*.mod`, `ARCHITECTURE.md`, `NEXT_STEPS_PLAN.md`). Any LMD / Laplace / MHM number in older docs or in `AUSPAC_WORKING_PAPER.md` §6.2/§6.4 is **historical** and not reproducible from the current tree.

---

## What AUSPAC is

AUSPAC is the Australian replication of FR-BDF (Banque de France WP #736, Lemoine et al. 2019; updated 2026 in WP #1044, Dubois et al.). It is a semi-structural macro model with Polynomial Adjustment Costs (PAC), an E-SAT structural-VAR expectation satellite, and a CES supply block, estimated on Australian data 1993Q1–2024Q4. The stated research goal is *a functioning, close replication that estimates every FR-BDF behavioural equation on AU data — nothing calibrated* (theoretical / steady-state calibrations are acceptable; behavioural carryovers are treated as gaps to close).

---

## Estimation status against the goal

Reviewed 2026-05-30. Honest accounting: **~35–45 % of behavioural parameters are genuinely AU-estimated**; the model is BK-stable and reproduces its own headline IRFs, but several blocks remain calibrated/borrowed and the new wp1044 credit block is absent.

| Block | Status | How AUSPAC gets the parameters |
|---|---|---|
| VA-price PAC | **AU-estimated** | iterative OLS (`results_va_price`), N=108, R²=0.41 |
| Wage Phillips | **AU-estimated** | BK-constrained OLS (`results_wage_phillips_constrained`), κ_w=0.343 |
| Employment PAC | **AU-estimated** | OLS depth-3 (`results_employment`), N=124, R²=0.81 |
| Consumption PAC | AU-estimated (short-run) | OLS (`results_consumption`), β₀=0.27 ≈ wp1044 0.29; PV² operator not built |
| Housing inv PAC | AU-estimated (short-run) | OLS (`results_housing_inv`); price-spread on proxy pSH/pIH |
| **Business inv PAC** | **calibrated from wp1044** | Table 3.5.13 (Option 1 hybrid); AU rejects the PAC FOC (R²≈0.09) — but confounded by a `df` target missing the exports component |
| Exports / Imports | short-run AU-OLS; LR borrowed | SA-data ECM (`results_exports`/`results_imports`); long-run elasticities + whole energy-import block reverted to wp1044 |
| Demand deflators | AU-OLS | per-deflator OLS; **CPI Phillips is flat** (R²=0.06, only persistence identified) |
| Supply / CES | calibrated (legit) | α=0.45, σ=0.5366 from wp1044; γ_ulc/γ_uck CES-pinned |
| Financial / WACC / UIP | calibrated | calibrated SS; persistences are AR(1)-estimable (closeable) |
| HICP decomposition | calibrated | identity-only reporting block |
| Credit / financial-accelerator (wp1044 §3.7) | **missing** | not implemented |

Full block-by-block detail is in [`L2_REPLICATION_REPORT.md`](L2_REPLICATION_REPORT.md), [`PAC_EQUATIONS_AUDIT.md`](PAC_EQUATIONS_AUDIT.md), and the working paper §4–§5.

---

## Open items (2026-05-30 review)

**Active / Wave 1 (correctness):**
1. **PAC `h_pac` self-consistency** — the 2026-05-30 SA-data fix re-parameterised `aux/aux_employment.mod` and `aux/aux_housing_inv.mod`, but `pac.print()` was not re-run, so the live `h_pac_n_*` / `h_pac_ih_*` policy-function vectors (stamped 2026-05-28) no longer match the structural ECM speeds. *Fix: re-run `pac.print()` for those two blocks, write back, re-solve.*
2. **Potential-output hysteresis** — the `sigma_ces·rw_gap` term in `dln_n_star_bar` ([au_pac.mod:1259](dynare/au_pac.mod#L1259)) makes a *temporary* nominal shock permanently shift potential output `ln_QN`; extended to Q200 the sign is economically backwards (a tightening leaves output/employment permanently higher). *Decision: fix toward long-run neutrality (damp/gap the term).*

**Backlog (closeable calibration gaps):** business-investment identification (complete `df` with AU exports, build full AU WACC, re-test strict PAC); trade long-run elasticities; financial/WACC persistences (AR(1) OLS); shock std devs (OLS residuals); energy split; flat-Phillips drivers (import-price ECM `p_C*`, commodity passthrough `dln_pcom`).

**Scope (new wp1044 blocks):** household credit + DSR and NFC financial-accelerator (§3.7); quasi-endogenous employment/investment anchors (fixes Round 4–8 rational consistency); HtM + PV² consumption; HICP behavioural components.

**Validation:** reconstruct `forecast_eval.m` so the §6.5 pseudo-real-time RMSEs are reproducible; one shared fidelity rubric (full/partial/proxy/imported) across all docs.

**Latent defects:** duplicate `eps_pm_ne`/`eps_pm_e` `varexo` declarations ([au_pac.mod:942-943](dynare/au_pac.mod#L942)); stale wage-Phillips provenance comment (lines 1919-1927).

---

## Repository layout

```
AUSPAC/
├── README.md / RUNNING.md / STATUS.md         entry / run / status docs
├── L2_REPLICATION_REPORT.md                   per-block wp1044-vs-AU comparison
├── PAC_EQUATIONS_AUDIT.md                      equation-by-equation fidelity audit
├── BLOCK_LIMITATIONS.md                        AU data gaps per block
├── CES_PRODUCTION_FUNCTION_APPROACH.md         CES calibration method
├── IRF_*_INVESTIGATION.md / *_FIX.md           recent IRF/trade investigations
├── dataset.csv                                 base E-SAT observables (restore: git show 7995ce7^:dataset.csv > dataset.csv)
├── references/                                 wp736, FR-BDF-update (wp1044), ECB-BASE, RBA transmission
├── data/
│   ├── pac_blocks/   estimate_*.m + results_*.{mat,txt}   ← production PAC coefficients
│   ├── prepare_*.m / download_*.m                          data build
│   └── run_all_l2_ols.m                                    5-PAC-block OLS driver
└── dynare/
    ├── au_pac.mod                              ★ production model (self-contained)
    ├── aux/aux_{pQ,consumption,business_inv,housing_inv,employment}.mod   PAC aux files (pac.print source)
    ├── regen_all_artifacts.m                   re-run dynare au_pac + regenerate paper artifacts
    ├── AUSPAC_WORKING_PAPER.{md,tex,pdf}        the working paper
    └── paper_artifacts/                         figures + tables
```

---

## Reproducing results

```matlab
% 0. (once) restore the base dataset if absent:
%    git show 7995ce7^:dataset.csv > dataset.csv

% 1. Refresh PAC-block coefficients from AU data (~minutes)
cd data; run('run_all_l2_ols.m');          % 5 core PAC blocks
%   standalone blocks: estimate_wage_phillips_constrained.m, estimate_cpi_phillips.m,
%   estimate_deflators.m, estimate_trade_exports.m / estimate_trade_imports.m
% 2. Write updated coefficients into dynare/au_pac.mod (manual / per-block writeback)

% 3. Solve the model + regenerate IRFs and paper artifacts (~1 min)
cd ../dynare; run('regen_all_artifacts.m');   % addpaths Dynare 7.0-arm64, runs `dynare au_pac`
```

MATLAB is invoked by full path (not on `PATH`):
`/Applications/MATLAB_R2026a.app/bin/matlab -batch "..."`.

---

## References

| Source | Where |
|---|---|
| FR-BDF wp736 (Lemoine et al., 2019) | [`references/wp736.pdf`](references/wp736.pdf) |
| FR-BDF wp1044 update (Dubois et al., 2026) | [`references/FR-BDF-update.pdf`](references/FR-BDF-update.pdf) |
| ECB-BASE (Angelini et al., 2019) | [`references/ecb-base.pdf`](references/ecb-base.pdf) |
| RBA monetary transmission (Mulqueeney, Ballantyne, Hambur 2025) | [`references/RBA_mon_transmission.pdf`](references/RBA_mon_transmission.pdf) |

---

## Citation

> Stephan, D. (2026). *AU-PAC: A Semi-Structural Macroeconomic Model for Australia.* Working paper, v4.0.
>
> Lemoine, M., et al. (2019). *The FR-BDF Model and an Assessment of Monetary Policy Transmission to the French Economy.* Banque de France WP No. 736.
>
> Dubois, U., et al. (2026). *Re-estimated FR-BDF.* Banque de France WP No. 1044.
