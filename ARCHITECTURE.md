# AUSPAC — Architecture and code map

A working developer's tour of the AUSPAC repository: which program does what,
how the data flows through them, and how the pieces fit together to produce
the working paper. Aimed at researchers / engineers reading the code for the
first time — every script and `.mod` file is named, sized, and placed in the
end-to-end pipeline.

For high-level status (v3.0 headline LMD, open items, citations), see
[`STATUS.md`](STATUS.md). For step-by-step MATLAB run instructions, see
[`RUNNING.md`](RUNNING.md). For the underlying economics, see
[`dynare/AUSPAC_WORKING_PAPER.md`](dynare/AUSPAC_WORKING_PAPER.md).

---

## 1. Big picture

AUSPAC is an **Australian replication** of the Banque de France's FR-BDF
model (Lemoine et al., 2019 WP #736; updated 2026 in Dubois et al. WP #1044).
The model is **semi-structural** in the FRB/US tradition: behavioural
equations use Polynomial Adjustment Costs (PAC), with forward-looking
expectations supplied by an inverted Expectation Satellite VAR (E-SAT).

The repo splits into five layers:

| Layer | What lives here | Format |
|---|---|---|
| **A. Raw data** | ABS, RBA, FRED, BIS, IMF series | `.csv`, `.xlsx`, `data.mat` |
| **B. Data prep** | Splicing, seasonal adjustment, gap construction | MATLAB scripts in `data/`, `dynare/scripts/data_prep/` |
| **C. Pre-Dynare estimation** | E-SAT core, supply CES, deflator regressions | MATLAB `.m` in repo root and `data/` |
| **D. Dynare model + Bayesian MCMC** | Production simulation model + full-system estimation | `.mod` in `dynare/`, drivers in `dynare/scripts/estimation/` |
| **E. Analysis / figures** | IRFs, conditional forecasts, forward-guidance test, paper figures | `.m` in `dynare/scripts/{analysis,figures}/`, Python in `dynare/regen/` and `dynare/tools/` |

The end-to-end pipeline:

```
Raw CSV/xlsx (data/, dataset.csv)
         │
         ▼  download_data.m / data/prepare_*.m / dynare/scripts/data_prep/prepare_*.m
         │
Cleaned MAT files (data.mat, estimation_data.mat, supply_data.mat)
         │
         ├──► estimate_esat.m / bayesian_estimate.m       → params.mat (E-SAT priors / posteriors)
         ├──► data/estimate_ces_2026.m                    → CES calibration (σ, α, γ)
         ├──► dynare/scripts/estimation/estimate_phase_c_lpiv.m  → b_di_c, b_ph_ih (LP-IV)
         ├──► dynare/scripts/estimation/estimate_phase_d_trade.m → trade-ECM long-run β_m, β_x
         │
         ▼  hand-edited values feed into the .mod files
         │
Dynare model files (au_pac.mod and friends; au_pac_v2.mod is production)
         │
         ├──► dynare au_pac_v2_bayesian              → Bayesian MCMC, posterior table
         │      (run_phase_r_refit.m / dynare au_pac_v2_bayesian)
         │
         ├──► dynare au_pac_v2                       → IRFs (saved_irfs_v2_phase_t.mat)
         │
         └──► dynare/scripts/analysis/*.m            → forward guidance, forecast eval,
                                                       conditional forecast, etc.
         │
         ▼  Python regen helpers in dynare/regen/
         │
Paper figures (*.png in dynare/) and working paper text
```

---

## 2. Repo layout (annotated)

```
AUSPAC/
│
├── README.md                  Repo entry point
├── RUNNING.md                 MATLAB run instructions
├── STATUS.md                  v3.0 status, phase trajectory, open items
├── ARCHITECTURE.md            (you are here) developer code map
│
├── make_paper_results.m       Top-level reproduction driver (data → estimation → model)
├── run_all.m                  Legacy E-SAT-only driver (no Dynare)
├── test_full_system.m         End-to-end regression test, pass/fail report
│
├── download_data.m            Stage 1: pull/load AU+US series → data.mat + dataset.csv
├── estimate_esat.m            Stage 2: equation-by-equation OLS on 9-eq E-SAT → params.mat
├── bayesian_estimate.m        E-SAT Bayesian RW-MH MCMC alternative to estimate_esat.m
├── esat_model.m               Constructs the A, B matrices of the E-SAT structural VAR
│
├── dataset.csv                E-SAT observable inputs (gitignored)
├── data.mat                   E-SAT pre-processed inputs (gitignored)
├── params.mat                 E-SAT estimated parameters (gitignored)
│
├── references/                Source PDFs (not generated; commited)
│   ├── wp736.pdf              FR-BDF Lemoine et al. 2019 (the source paper)
│   ├── FR-BDF-update.pdf      FR-BDF Dubois et al. 2026 (supply-block update + policy-function workflow)
│   └── RBA_mon_transmission.pdf  Mulqueeney, Ballantyne & Hambur 2025 (paper §6.2.4 benchmark)
│
├── data/                      Demand-side + supply-side data prep
│   ├── abs_rba/               Raw ABS / RBA xlsx + csv downloads
│   ├── download_abs_rba.m     Fetches ABS Cat. 5206 etc.
│   ├── download_rba.m         RBA statistical tables
│   ├── download_supply_data.m Supply block raw data (ABS 5204 capital, 6202 employment, 6345 WPI)
│   ├── download_extended_data.m  Demand-side full dataset
│   ├── prepare_estimation_data.m Builds estimation_data.mat (Bayesian observables)
│   ├── prepare_supply_data.m  Supply data → supply_data.mat for CES estimation
│   ├── estimate_ces_2026.m    CES σ + α + γ + Ē trend via FR-BDF wp1044 method
│   ├── estimate_ces_stage23.m Legacy wp736 (2019) grid-search CES calibration (kept for comparison)
│   ├── estimate_sigma_stage1.m Investment-FOC σ estimation (legacy wp736 method)
│   ├── extended_dataset.csv   Demand-side dataset (1959Q3+, gitignored or large)
│   ├── house_price_history_long.csv  Spliced AU housing prices 1959Q3-present
│   ├── house_price_spliced.csv       Final spliced series (ABS 6416 forward + back-cast)
│   └── io_tables_australia.xlsx       2019 ABS input-output tables (for IAD weights)
│
└── dynare/                    The model, scripts, outputs
    │
    ├── setup_dynare_path.m    PATH bootstrap: addpath scripts/* + locate Dynare 6.5
    │
    ├── *.mod                  Model files — see §3
    │
    ├── aux/                   Phase T policy-function aux files — see §4
    │   ├── _template_helpers.py     Python generator for aux files
    │   ├── aux_pQ.mod               VA-price PAC aux
    │   ├── aux_consumption.mod      Consumption PAC aux
    │   ├── aux_business_inv.mod     Business inv PAC aux
    │   ├── aux_housing_inv.mod      Housing inv PAC aux
    │   └── aux_employment.mod       Employment PAC aux
    │
    ├── simulation/            Phase T identities + cherrypick bundles
    │   ├── identities/        Normalised .inc files + 3 Python normalisers
    │   └── estimation/        Cherrypick output, 5 subdirs (one per PAC block)
    │
    ├── AUSPAC_WORKING_PAPER.md    The paper (~1700 lines, 9 sections + 6 appendices)
    ├── mcmc_posterior_table_phase_t.md  Auto-generated posterior table (paper Table 5.6)
    ├── phase_r_benchmark_table.md       FR-BDF IRF benchmark comparison
    ├── forecast_eval_table.md           Table 5.8 RMSE values
    ├── au_pac_model_data_README.md      Dataset conventions
    ├── prepare_pac_dseries_README.md    dseries-prep conventions
    │
    ├── *.png                  Paper figures (gitignored, auto-generated)
    ├── saved_irfs_v2_phase_t.mat    v3.0 IRFs (gitignored)
    ├── saved_irfs_{var,hybrid,mce}.mat  Legacy three-regime IRFs (gitignored)
    ├── bayesian_mcmc_results.mat        Phase S+T MCMC posterior (gitignored)
    ├── estimation_data.mat             Bayesian observable dataset (gitignored)
    ├── au_pac_model_data.csv           Dseries CSV used by various scripts
    ├── trade_volumes_sa.csv            Seasonally-adjusted trade series
    │
    ├── scripts/               MATLAB drivers — see §5
    │   ├── estimation/        21 .m files: MCMC, mode finding, posterior extraction
    │   ├── data_prep/         5 .m files: prepare_pac_dseries*, prepare_bayesian_data
    │   ├── figures/           8 .m files: IRF plotting, three-regime comparison
    │   ├── analysis/          7 .m files: forward guidance, forecast eval, identification
    │   └── tests/             1 .m file: test_smoother_comparison
    │
    ├── regen/                 Python figure-regen helpers — see §6
    │   └── regen_*.py         Reads .mat artefacts, writes PNG figures
    │
    └── tools/                 Python data utilities — see §7
        ├── apply_mcmc_writeback.py    Writes MCMC posteriors back to .mod files
        ├── splice_housing_prices.py   Long-history AU house-price splice
        ├── build_trade_volumes_csv.py Builds trade_volumes_sa.csv
        └── ...                7 more tools (sanity checks, channel diagnostics)
```

---

## 3. Model files (`dynare/*.mod`)

The repo carries **14 `.mod` files**, organised in three tiers:

### 3.1 The v3.0 production model (Phase T policy-function architecture)

| File | Role |
|---|---|
| **`au_pac_v2.mod`** | The current production simulation model. Built by Dynare's `aggregate()` from `aux/*.mod` + `simulation/identities/*.inc` + cherrypicked `simulation/estimation/*/*.inc`. Compiled output: 158 endogenous variables, 40 shocks, 270 parameters; BK rank passes with 9 forward-looking eigenvalues. Carries `stoch_simul` for IRF generation. |
| **`au_pac_v2_bayesian.mod`** | Estimation variant. Identical to `au_pac_v2.mod` body, but the `stoch_simul` block is replaced by `varobs` + `estimated_params` + `estimation()`. 28 estimated parameters (19 PAC/wage + 9 shock stds). MCMC wall-time ≈ 51 min on Apple Silicon under Rosetta 2. |

### 3.2 Legacy three-regime models (FR-BDF wp736 three-regime structure)

The paper §2.2 retains the wp736 distinction between VAR-based, Hybrid, and
full Model-Consistent Expectations regimes. These files implement each
regime as a self-contained model (Dynare's `pac_expectation()` operator
evaluated against a shadow var_model):

| File | Expectation regime |
|---|---|
| `au_pac.mod` | Hybrid: financial PVs forward-looking, demand-block PAC h-vectors backward |
| `au_pac_var.mod` | VAR-based: all expectations from the backward auxiliary VAR |
| `au_pac_mce.mod` | Model-consistent: all expectations forward-looking |

These remain runnable and produce the legacy `saved_irfs_{var,hybrid,mce}.mat`
binaries that the three-regime figure regen scripts (`dynare/regen/regen_three_regime_figs.py`)
were originally designed against. The v3.0 production model `au_pac_v2.mod`
supersedes them via a different architectural approach (cherrypick + aggregate),
not a re-specification of the structural equations.

### 3.3 Other supporting models

| File | Role |
|---|---|
| `au_pac_bayesian.mod` | Legacy three-regime Bayesian estimation file (Phase S architecture); paired with `au_pac.mod` |
| `au_pac_smooth.mod` | Kalman smoother variant for `calib_smoother` recovery of auxiliary targets |
| `au_pac_condforecast.mod` | Conditional forecasting variant (residual-inversion) |
| `au_pac_identification.mod` | Identification analysis (Iskrev / Komunjer-Ng — Dynare limitation noted) |
| `au_pac_recursive.mod` | Pseudo-real-time recursive forecast evaluation variant |
| `au_esat.mod` / `au_esat_est.mod` | Standalone E-SAT VAR (no PAC) — for E-SAT-only experiments |
| `nk_simple.mod` / `nk_discounted.mod` | Standard / discounted New Keynesian benchmarks for the forward-guidance puzzle test (§6.5) |

### 3.4 Setup helper

| File | Role |
|---|---|
| `dynare/setup_dynare_path.m` | Adds every `dynare/scripts/*` subfolder to MATLAB path, locates Dynare 6.5 install, and (for v3.0) adds Dynare's `matlab/missing/` for `rows()`. Every driver script calls this once at the top. |

---

## 4. Phase T policy-function workflow (`dynare/aux/` + `dynare/simulation/`)

This is the **production architecture** for v3.0. It implements the
Dynare-recommended cherrypick + aggregate pattern (Adjemian, Brayton & Zimic,
2024) and matches FR-BDF wp1044 §2.2's policy-function approach.

### 4.1 Aux files (`dynare/aux/aux_X.mod`)

One per PAC block (five total):

| File | Estimates | PAC equation | Auxiliary regression target |
|---|---|---|---|
| `aux_pQ.mod` | VA-price PAC params | `eq_piQ_pac` | `piQ_hat` (Phillips target) |
| `aux_consumption.mod` | Consumption PAC params | `eq_dln_c_pac` | `yh_ratio_hat`, `c_hat` |
| `aux_business_inv.mod` | Business-inv PAC params | `eq_dln_ib_pac` | `ib_hat`, `rKB_hat` |
| `aux_housing_inv.mod` | Housing-inv PAC params | `eq_dln_ih_pac` | `ih_hat` |
| `aux_employment.mod` | Employment PAC params | `eq_dln_n_pac` | `n_hat` |

Each aux file declares a minimal subset of structural variables in pure-VAR
form (lagged-only RHS), defines the auxiliary regression mapping the PAC
target to the E-SAT core, declares the PAC equation, and emits the
closed-form expectation formula via `pac.print()`. `cherrypick()` extracts
the simulation-ready equations into `simulation/estimation/<block>/`.

| Helper | Role |
|---|---|
| `dynare/aux/_template_helpers.py` | Python generator. Re-creates the four non-`pQ` aux files from a shared template + per-block specs. Run after any change to the common E-SAT structure. |

### 4.2 Identity layer (`dynare/simulation/identities/`)

The non-PAC, non-aux-VAR structural equations + declarations live here.
Aggregate combines all `.inc` files in this folder with the cherrypicked
bundles to produce `au_pac_v2.mod`.

| File | Content | Lines |
|---|---|---|
| `model.inc` | All non-PAC structural equations: IS curve, Taylor rule, E-SAT Phillips, deflators (eq_pi_c / eq_pi_m / eq_pi_ib / eq_pi_ih / eq_pi_x), term structure, WACC, UIP, housing price, wage Phillips, fiscal rule, GDP identity, sectoral wealth, trade ECMs, capital accumulation. 126 equations on single lines, `[name='X']` tags. | ~380 |
| `endogenous.inc` | 131 structural endogenous variables (`var ... ;`) | ~135 |
| `exogenous.inc` | 33 structural shocks (`varexo ... ;`) | ~40 |
| `parameters.inc` | 198 parameter names on a single `parameters ... ;` line | 1 |
| `parameter-values.inc` | 147 calibrated values (one `name = value;` per line; PAC params excluded, cherrypicked instead) | ~150 |
| `steady.inc` | `steady_state_model` block body | ~190 |
| `shocks.inc` | Shock stderr definitions | ~55 |
| `_normalize_model.py` | Strips comments from `au_pac.mod` model body, single-lines equations, removes shadow VAR + 5 PAC equations, flips 3 `def_X_gap` LHS for aggregate's dedup-by-LHS | ~120 |
| `_normalize_decls.py` | Filters shadow variables/shocks; emits aggregate-compatible `var`/`varexo` blocks | ~75 |
| `_normalize_params.py` | Pre-evaluates arithmetic on RHS (`textscan` needs pure floats); excludes aux-owned PAC params | ~100 |

The three `_normalize_*.py` scripts run idempotently to regenerate the `.inc`
files from a fresh `au_pac.mod` baseline whenever the structural model changes.

### 4.3 Cherrypick output (`dynare/simulation/estimation/<block>/`)

Auto-populated by `cherrypick()` after each aux file is estimated. Five
subdirectories (one per PAC block), each containing the same five files:

```
endogenous.inc   (variables used by the cherrypicked equations)
exogenous.inc    (shocks used)
parameters.inc   (h_* parameter declarations + PAC param names)
parameter-values.inc  (numerical values: h_* coefficients + PAC posterior means)
model.inc        (the 3 cherrypicked equations: pac_expectation_pac_X identity,
                  eq_X_pac with formula substituted, var_X auxiliary regression)
```

### 4.4 Composition into the production .mod

```matlab
aggregate('au_pac_v2.mod', {'stochastic,json=compute'}, root, ...
    'simulation/estimation/pQ', 'simulation/estimation/consumption', ...
    'simulation/estimation/business_inv', 'simulation/estimation/housing_inv', ...
    'simulation/estimation/employment', 'simulation/identities');
```

The aggregator unions all the directories (dedup by LHS variable name) and
emits `au_pac_v2.mod`. After this you append the `steady_state_model` block
and your `stoch_simul`/`estimation` block, then run `dynare au_pac_v2`.

---

## 5. MATLAB scripts (`dynare/scripts/`)

### 5.1 `scripts/estimation/` — Bayesian + PAC + iterative-OLS drivers

The most heavily populated subfolder (21 files). Three logical groups:

**A. Full-system Bayesian MCMC drivers** (the workflow that produces Table 5.6):

| Script | Role |
|---|---|
| `run_bayesian_estimation.m` | Stage 1: csminwel mode search on `au_pac_bayesian.mod` (~5 min) |
| `run_bayesian_mcmc.m` | Stage 2: 20k × 2-chain Metropolis-Hastings MCMC (~50 min) |
| `extract_mcmc_results.m` | Reads `bayesian_mcmc_results.mat`, writes `mcmc_posterior_table.md` and `mcmc_writeback.txt` |
| `run_2026_mcmc_irfs.m` | Combined wrapper: MCMC then IRF regen |
| `run_2026_refresh.m` | Full pipeline: data prep + smoother + Bayesian + IRFs |
| `run_2026_irfs_only.m` | Skip estimation, just regenerate IRFs from saved posterior |
| `run_2026_aux_figs.m` | Helper for auxiliary supplementary figures |
| `run_full_refresh.m` | Top-level: everything from a clean clone |
| `run_phase_q_uip.m` / `run_phase_q_resume.m` | Specific UIP-block refresh drivers |
| `run_phase_r_refit.m` | The structural-fix MCMC driver (5 stages: smoke + smoother + mode + MCMC + LMD report); v3.0 estimation is run via `dynare au_pac_v2_bayesian` which uses this style internally |
| `run_post_mcmc.m` | Post-estimation: IRFs + figure regen + posterior write-back |

**B. Per-block / per-phase estimators** (intermediate identification, paper §5.3):

| Script | Role |
|---|---|
| `estimate_pac.m` | Single-equation iterative OLS on one PAC equation |
| `estimate_pac_driver.m` | Loops `estimate_pac.m` over all five PAC equations |
| `estimate_pac_smooth_driver.m` | Like above but using `calib_smoother`-derived auxiliary targets |
| `estimate_auxiliary_bayesian.m` | Bayesian shrinkage estimation of the 22 E-SAT auxiliary regressions |
| `estimate_phase_c_lpiv.m` | Local-projection IV for `b_di_c` (consumption rate channel) and `b_ph_ih` (housing Tobin's Q) |
| `estimate_phase_d_trade.m` | Trade-ECM long-run identification (β_m, β_x via bivariate cointegration on 1959Q3+ data) |

**C. .mod file generators** (programmatic .mod writers):

| Script | Role |
|---|---|
| `generate_bayesian_mod.m` | Programmatically generates `au_pac_bayesian.mod` from `au_pac.mod` + estimated_params block |
| `generate_smoother_mod.m` | Builds `au_pac_smooth.mod` from `au_pac.mod` for Kalman smoother runs |
| `generate_estimation_tables.m` | Compiles paper Tables 5.1–5.8 from estimation artefacts |

### 5.2 `scripts/data_prep/` — observable construction

| Script | Role |
|---|---|
| `prepare_bayesian_data.m` | Builds `estimation_data.mat`: 11 observables (yhat_au, pi_au, i_au, yhat_us, pi_us, pi_w, dln_c, dln_ib, i_10y, dln_m, dln_x) on a common 1994Q1–2024Q4 quarterly grid |
| `prepare_smoother_data.m` | Builds `smoother_data.m` for the Kalman smoother (9 observables, gap-form) |
| `prepare_pac_dseries.m` | Builds the `dseries` database used by single-equation iterative OLS |
| `prepare_pac_dseries_hybrid.m` | Variant with COVID dummies for hybrid PAC estimation |
| `prepare_pac_dseries_smooth.m` | Variant pulling Kalman-smoothed auxiliary targets |

### 5.3 `scripts/figures/` — IRF plotting

| Script | Role |
|---|---|
| `generate_wp_irfs.m` | Generates all working-paper IRF PNGs from `saved_irfs_hybrid.mat` |
| `generate_three_regime_irfs.m` | Three-regime IRF panel (VAR / Hybrid / MCE, legacy) |
| `irf_three_regimes.m` | Per-variable three-regime panel |
| `irf_all_shocks.m` | All-shocks overview panel |
| `compare_irfs.m` | Cross-version IRF comparison (debugging) |
| `quick_uip_irfs.m` | UIP-block-only IRFs (debugging exchange-rate transmission) |
| `regen_irf_single.m` | Single-shock single-variable plot (debugging) |
| `smoke_uip_three_regimes.m` | Smoke test for the UIP-block IRFs |

### 5.4 `scripts/analysis/` — model property tests

| Script | Role |
|---|---|
| `forward_guidance.m` | Forward-guidance puzzle test (paper §6.5, Table 6.6). Runs AU-PAC vs `nk_simple.mod` + `nk_discounted.mod` over N=1..12 quarter rate cuts, reports the amplification ratio. |
| `forecast_eval.m` | Pseudo-real-time recursive RMSE evaluation (paper §5.5, Table 5.8 / Fig 5.5–5.6) |
| `conditional_forecast_driver.m` | Residual-inversion conditional forecasting (paper §6.4, Table 6.5 / Fig 6.11) |
| `long_run_convergence.m` | BGP convergence test (paper §6.1.1 / Fig 6.0) |
| `sectoral_validation.m` | Sectoral wealth half-life validation (FR-BDF wp736 §4.8.5) |
| `identification_analysis.m` | Posterior HPD-width analysis (paper Appendix F) |
| `compute_phase_q_peaks.m` | UIP-block diagnostic; reports peak IRF magnitudes |

### 5.5 `scripts/tests/`

| Script | Role |
|---|---|
| `test_smoother_comparison.m` | Smoke test comparing Kalman-smoother vs raw-observable Bayesian inputs |

---

## 6. Python figure-regen helpers (`dynare/regen/`)

Read saved `.mat` IRF artefacts, write PNGs. Used to refresh paper figures
without re-running Dynare:

| Script | Reads | Writes |
|---|---|---|
| `regen_section5_irfs.py` | `saved_irfs_hybrid.mat` | `irf_eps_*.png` (per-shock 9-panel grids) |
| `regen_three_regime_figs.py` | `saved_irfs_{var,hybrid,mce}.mat` | `three_regime_*.png` (legacy three-regime panels) |
| `regen_pac_contrib_figs.py` | `bayesian_mcmc_results.mat` | `contrib_*.png` (dynamic-contribution decompositions, paper Figs 4.3.1–4.7.1) |
| `regen_long_run_convergence.py` | `saved_irfs_hybrid.mat` | `long_run_convergence_proxy.png` (paper Fig 6.0) |
| `regen_app_experiment.py` | Custom 200bp term-premium IRF | `app_experiment_200bp.png` (paper Fig 6.14) |
| `regen_supplementary_figs.py` | Various .mat files | Supplementary appendix figures |
| `regen_wp736_style_panel.py` | `saved_irfs_hybrid.mat` | `three_regime_wp736_style.png` (FR-BDF Fig 6.2.2 replica) |
| `regen_phase_r_benchmarks.py` | `saved_irfs_*.mat` | `phase_r_benchmark_table.md` (FR-BDF IRF benchmark comparison) |

**v3.0 figure regen**: A small h5py-based script (`/tmp/regen_phase_t_figs.py` —
see commit history) regenerates the per-shock IRF panels from
`saved_irfs_v2_phase_t.mat` for the Phase T policy-function model. This is
the source of the v3.0 figures currently in `dynare/*.png`.

---

## 7. Python data utilities (`dynare/tools/`)

Auxiliary data-processing tools, mostly written during model-building
iterations:

| Script | Role |
|---|---|
| `apply_mcmc_writeback.py` | Parses `mcmc_writeback.txt` (from `extract_mcmc_results.m`) and updates the inline parameter calibrations in `au_pac.mod` + variants. Used after each MCMC re-run. |
| `apply_trade_ecm_fix.py` | One-off patch script (kept for audit history) |
| `splice_housing_prices.py` | Builds `data/house_price_spliced.csv` from ABS 6416 (post-2003) + back-cast (1959Q3 onward) via chain-linking growth rates. Used by `b_ph_ih` IV identification. |
| `build_trade_volumes_csv.py` | Produces `trade_volumes_sa.csv` (seasonally-adjusted exports/imports volumes) from ABS 5206 / 5302 |
| `build_trend_channels.py` | Constructs trend efficiency `Ē` from supply-block data using FR-BDF wp1044's two-break specification |
| `channel_diagnostics.py` | Inspects propagation of a structural shock through specific equation paths |
| `imports_trend_test.py` | Sanity check on import-volume trend estimation |
| `sanity_check_trade_ecm.py` | Verifies trade-ECM long-run elasticities against bivariate cointegration |
| `trend_diagnostics.py` | Trend-decomposition diagnostics (2002Q2 / 2008Q3 break detection) |
| `extract_2026_results.py` | Parses Dynare estimation output into paper-ready table format |

---

## 8. Top-level drivers

These live at the repo root and orchestrate multi-stage runs.

| Driver | Role |
|---|---|
| **`make_paper_results.m`** | The authoritative reproduction driver. Runs: download_data → estimate_esat → prepare_estimation_data → estimate_auxiliary_bayesian → estimate_phase_c_lpiv → estimate_phase_d_trade → compile + IRFs for all three legacy regime variants → test_full_system. Wall time ≈ 3–5 minutes per stage (most of which is Bayesian MCMC if Phase A is re-run, but the v3.0 posterior is baked into the .mod files). |
| `run_all.m` | Legacy: E-SAT-only pipeline (`download_data` → `estimate_esat` → `esat_model`). Predates the Dynare PAC implementation; preserved for compatibility with the FRB/US E-SAT-only workflow. |
| `test_full_system.m` | End-to-end regression test. Compiles all main .mod files, checks BK rank, computes a small IRF and asserts numerical agreement with the saved baseline. Fails fast on any regression. |
| `bayesian_estimate.m` | E-SAT Bayesian RW-MH MCMC (legacy alternative to `estimate_esat.m`'s OLS); kept for FRB/US-compatibility comparison. Output goes to `params.mat`. |
| `download_data.m` | Stage 1 of the pipeline. Pulls (or loads from CSV) the E-SAT observable series — quarterly AU output gap, CPI, cash rate, US output gap, US CPI, RBA inflation expectations. Outputs `data.mat` + `dataset.csv`. The flag `USE_LOCAL_CSV=true` skips the download and reads from the committed CSV (offline reproducibility). |
| `estimate_esat.m` | OLS estimation of the 9-equation E-SAT structural VAR. Following wp736 §3.1.1, the structural form is $A Z_t = B Z_{t-1} + \varepsilon_t$, inverted as $H = A^{-1}B$. Output: `params.mat`. |
| `esat_model.m` | Helper that constructs the 9×9 $A$ and $B$ matrices given a parameter vector. Used by both `estimate_esat.m` and `bayesian_estimate.m`. |

---

## 9. Data flow in detail

### 9.1 Inputs (raw data sources)

| Block | Source | Series |
|---|---|---|
| GDP / output | ABS Cat. 5206 | Real GDP, output components, deflators (quarterly) |
| Capital | ABS Cat. 5204 Tables 47–48 | Capital stock, depreciation (annual; interpolated) |
| Housing | ABS Cat. 6416 + back-cast | Residential property prices (spliced 1959Q3+) |
| Wages | ABS Cat. 6345 | Wage Price Index, total hourly rates excl. bonuses (private+public, SA) |
| Labour | ABS Cat. 6202 | Employment, unemployment, hours (SA) |
| Cash rate | RBA F1 | Overnight cash rate target |
| Mortgage rate | RBA F11 | Owner-occupier standard variable rate |
| Commodity prices | RBA G3 | RBA Commodity Price Index, USD basis |
| 10Y yield | RBA F2 | AU government 10-year yield |
| Exchange rate | BIS | Effective exchange rate indices, broad |
| US series | FRED | Output gap, CPI, federal funds rate, US 10Y, US PPI |

### 9.2 Pre-Dynare estimation stages

```
1. download_data.m          → data.mat (9 E-SAT observables)
2. estimate_esat.m          → params.mat (9-eq E-SAT VAR by equation-wise OLS)
                              [or bayesian_estimate.m for Bayesian alternative]

3. data/download_supply_data.m → supply_data.mat (capital, hours, WPI, GVA)
4. data/estimate_ces_2026.m    → CES calibration: σ = 0.5366, α = 0.45, γ = 0.046
                                   (FR-BDF wp1044 labour-FOC method, two-break Ē)

5. data/prepare_estimation_data.m → estimation_data.mat (11 Bayesian observables)

6. dynare/scripts/estimation/estimate_auxiliary_bayesian.m
                              → 22 E-SAT auxiliary regression coefficients
                                (a_pQ_y, a_pQ_i, ..., a_ih_y, ...)

7. dynare/scripts/estimation/estimate_phase_c_lpiv.m
                              → b_di_c ≈ −0.70 (consumption surprise channel)
                              → b_ph_ih ≈ +0.01 (housing Tobin's Q)
8. dynare/scripts/estimation/estimate_phase_d_trade.m
                              → β_m = 1.73, β_x = 1.56 (trade-ECM long-run elasticities)
```

All these pre-Dynare values are then **hand-pasted** into the calibration
section of `au_pac.mod` (the master model file). The `.inc` files in
`simulation/identities/parameter-values.inc` are auto-generated from
`au_pac.mod` by `_normalize_params.py`, so values propagate automatically.

### 9.3 Dynare estimation (Bayesian MCMC)

```
9. dynare au_pac_v2_bayesian          (cf §3.1)
                              → bayesian_mcmc_results.mat
                              → posterior mode + 20k × 2-chain MCMC

10. extract_mcmc_results.m    → mcmc_posterior_table_phase_t.md (paper Table 5.6)
                              → mcmc_writeback.txt (key=value pairs)

11. apply_mcmc_writeback.py   → updates b0_pQ, b1_pQ, ..., lambda_w, gamma_w, kappa_w
                                in au_pac.mod + au_pac_var.mod + au_pac_mce.mod
                                (legacy three-regime models;
                                 au_pac_v2.mod gets posteriors via aux/aux_X.mod
                                 calibration sections re-templated from posteriors)
```

### 9.4 IRF generation + figures

```
12. dynare au_pac_v2          → saved_irfs_v2_phase_t.mat (v3.0 IRFs, 158 vars × 40 shocks × 200 quarters)

    dynare au_pac_var / au_pac / au_pac_mce
                              → saved_irfs_{var,hybrid,mce}.mat (legacy three regimes)

13. Python regen scripts      → *.png in dynare/ (paper figures)
    e.g.   python3 dynare/regen/regen_section5_irfs.py
           python3 dynare/regen/regen_pac_contrib_figs.py
```

### 9.5 Model-property analyses

```
14. dynare/scripts/analysis/forward_guidance.m   → forward_guidance_puzzle_v2.png + Table 6.6
                                                   (runs AU-PAC + nk_simple + nk_discounted)
15. dynare/scripts/analysis/forecast_eval.m       → forecast_eval_table.md + Figs 5.5–5.6
                                                   (24 expanding-window origins)
16. dynare/scripts/analysis/conditional_forecast_driver.m → Table 6.5 / Fig 6.11
17. dynare/scripts/analysis/long_run_convergence.m → Fig 6.0
18. dynare/scripts/analysis/sectoral_validation.m → wealth half-life report
```

---

## 10. Working paper composition

`dynare/AUSPAC_WORKING_PAPER.md` is the live working paper, hand-written with
embedded `![caption](file.png)` figure references and Markdown tables. The
auto-generated artefacts that feed specific paper sections:

| Paper section / table | Source |
|---|---|
| Abstract LMD numbers, §5.4, Table 5.6 | `mcmc_posterior_table_phase_t.md` |
| §5.5 Table 5.8 + Figs 5.5–5.6 | `forecast_eval_table.md` + `dynare/scripts/analysis/forecast_eval.m` outputs |
| §6 Scope note + Table 6.3 | Numbers read from `saved_irfs_v2_phase_t.mat` (extracted by hand or via `regen_phase_r_benchmarks.py`) |
| §6.3 sub-section IRF figures | `dynare/regen/regen_section5_irfs.py` (or the v3.0 h5py-based regen for current PNGs) |
| Figs 4.3.1–4.7.1 (PAC dynamic-contribution decomps) | `dynare/regen/regen_pac_contrib_figs.py` |
| §6.5 Table 6.6 | `dynare/scripts/analysis/forward_guidance.m` console output |

Paper compilation is not automated end-to-end (the paper is hand-edited Markdown
with hand-pasted table numbers). The discipline is that the table numbers and
figure files agree with the saved `.mat` artefacts at any given commit.

---

## 11. Top-level reproduction recipe

For a clean checkout, the canonical reproduction sequence is:

```matlab
% From MATLAB at repo root:
USE_LOCAL_CSV = true;        % skip web downloads, use committed dataset.csv
make_paper_results           % ≈ 3–5 minutes
```

For full Bayesian MCMC re-estimation (Table 5.6), additionally:

```matlab
cd dynare
setup_dynare_path
addpath(genpath('/Applications/Dynare/6.5-x86_64/matlab/missing'))  % for rows()
dynare au_pac_v2_bayesian    % ≈ 51 minutes on Apple Silicon under Rosetta 2
```

For figure-only refresh from saved artefacts (no Dynare/MATLAB needed):

```bash
pip install scipy matplotlib h5py
python3 dynare/regen/regen_section5_irfs.py
python3 dynare/regen/regen_pac_contrib_figs.py
python3 dynare/regen/regen_long_run_convergence.py
python3 dynare/regen/regen_app_experiment.py
```

For incremental development:

| You want to | Run |
|---|---|
| Re-fit one PAC equation by iterative OLS | `dynare/scripts/estimation/estimate_pac_driver.m` |
| Re-fit full system Bayesian | `dynare/scripts/estimation/run_phase_r_refit.m` (or `dynare au_pac_v2_bayesian` directly) |
| Re-make all paper figures | `dynare/scripts/figures/generate_wp_irfs.m` (legacy) or the Python regen scripts |
| Test the forward-guidance puzzle | `dynare/scripts/analysis/forward_guidance.m` |
| Validate end-to-end | `test_full_system.m` |

---

## 12. Dependencies

| Component | Version | Required for |
|---|---|---|
| MATLAB | R2019a+ (tested on R2020a under Rosetta 2) | All `.m` scripts and Dynare workflows |
| Dynare | 6.5 | All `.mod` compilation and estimation |
| Python | 3.9+ | `dynare/regen/*.py`, `dynare/tools/*.py`, `dynare/aux/_template_helpers.py`, `dynare/simulation/identities/_normalize_*.py` |
| `scipy`, `matplotlib`, `h5py` | latest pip | Python figure-regen + .mat I/O |
| Git LFS | optional | Only if `.mat` artefacts exceed GitHub's free quota |

---

## 13. Where to look next

- **Just want to read the model?** → `dynare/AUSPAC_WORKING_PAPER.md`
- **Just want to run it?** → `RUNNING.md`
- **What's been done / what's next?** → `STATUS.md`
- **Add a new shock?** → Edit `simulation/identities/{exogenous.inc, shocks.inc, model.inc}` and the matching aux file, re-aggregate
- **Add a new PAC block?** → Create a new `aux/aux_X.mod` following the template, add `aux_X` to the aggregator call, re-aggregate
- **Re-estimate after changing the structural model?** → `dynare au_pac_v2_bayesian` (~51 min); then `python3 dynare/tools/apply_mcmc_writeback.py` to push new posteriors back to the aux file calibrations; re-aggregate
- **Why is X coefficient calibrated, not estimated?** → See the "Calibration imports" subsection of `dynare/AUSPAC_WORKING_PAPER.md` §4.13.4

---

## Citations

If you use AUSPAC in academic work, please cite both the model paper and the
underlying FR-BDF references:

> Stephan, D. (2026). *AU-PAC: A Semi-Structural Macroeconomic Model for Australia.* Working paper, https://github.com/DavidAStephan/AUSPAC
>
> Lemoine, M., Turunen, H., Chahad, M., Lepetit, A., Zhutova, A., Aldama, P., Clerc, P., and Laffargue, J.-P. (2019). *The FR-BDF Model and an Assessment of Monetary Policy Transmission to the French Economy.* Banque de France WP No. 736.
>
> Dubois, U., Ducoudré, B., Martin, R., Petronevich, A., Seghini, C., Thubin, C., and Turunen, H. (2026). *Re-estimated FR-BDF: New Features and an Assessment of Monetary Policy Tightening in France.* Banque de France WP No. 1044.
