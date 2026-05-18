# AUSPAC — Architecture and code map

A working developer's tour of the AUSPAC repository: which file does what, how the data flows, and how the pieces fit together to produce the working paper. For high-level status, see [STATUS.md](STATUS.md). For step-by-step run instructions, see [RUNNING.md](RUNNING.md). For the underlying economics, see [dynare/AUSPAC_WORKING_PAPER.md](dynare/AUSPAC_WORKING_PAPER.md).

---

## 1. Big picture

AUSPAC is an **Australian replication** of the Banque de France's FR-BDF model (Lemoine et al., 2019 WP #736; updated 2026 in Dubois et al. WP #1044). The model is **semi-structural** in the FRB/US tradition: behavioural equations use Polynomial Adjustment Costs (PAC), with forward-looking expectations supplied by the Phase T policy-function workflow (Adjemian/Brayton/Zimic; FR-BDF wp1044 §3.2.3) using Dynare's `cherrypick()` + `aggregate()` pipeline.

The repo splits into three layers:

| Layer | What lives here | Format |
|---|---|---|
| **A. Data** | Raw ABS/RBA/FRED/BIS series, fetch and prep scripts | `.csv`, `.xlsx`, `.mat` in `data/` and root |
| **B. Model** | Production `.mod` files, source `.inc` identities, aux files | `dynare/au_pac.mod`, `dynare/aux/`, `dynare/simulation/` |
| **C. Outputs** | Pre-baked IRFs, paper figures, regen helpers | `dynare/saved_irfs*.mat`, `dynare/*.png`, `dynare/regen/`, `dynare/tools/` |

The end-to-end pipeline:

```
Raw CSV/xlsx (data/, dataset.csv)
         │
         ▼  data/download_*.m, data/prepare_*.m
         │
Cleaned MAT files (dynare/estimation_data.mat, dynare/supply_data.mat)
         │
         ▼
Aux files (dynare/aux/aux_*.mod) ──► dynare + cherrypick ──► simulation/estimation/<block>/
         │                          (phaseW_recherrypick.m)
         ▼
Identity layer (dynare/simulation/identities/*.inc)
         │
         ▼  aggregate() ──► au_pac.mod (production)
         │
         ├──► dynare au_pac_bayesian   → Bayesian MCMC, posterior table
         ├──► dynare au_pac            → IRFs (saved_irfs.mat)
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
├── STATUS.md                  Current status, phase trajectory, open items
├── NEXT_STEPS_PLAN.md         v3.2 roadmap
├── ARCHITECTURE.md            (you are here) developer code map
│
├── dataset.csv / data.mat / params.mat   Data artefacts produced by data/ scripts
│
├── references/                Source PDFs (wp736, wp1044, RBA, ECB-BASE)
│
├── data/                      Data fetch + prep
│   ├── download_*.m              Pulls ABS/RBA/FRED/BIS series → CSV
│   ├── prepare_estimation_data.m → dynare/estimation_data.mat (9-observable input)
│   ├── prepare_supply_data.m    → dynare/supply_data.mat
│   ├── estimate_ces_2026.m      CES production-function calibration
│   └── estimate_ces_stage23.m   Stage-2/3 CES re-estimation
│
└── dynare/                    ▼ Models, source, outputs ▼
    │
    ├── au_pac.mod             ★ Production model (164 endo, 33 exo shocks)
    ├── au_pac_bayesian.mod    ★ Bayesian-estimation variant
    │
    ├── aux/                   PAC aux files (estimation-only; feed cherrypick)
    │   ├── _template_helpers.py
    │   ├── aux_pQ.mod              VA-price PAC block
    │   ├── aux_consumption.mod     Consumption PAC block
    │   ├── aux_business_inv.mod    Business investment PAC block
    │   ├── aux_housing_inv.mod     Housing investment PAC block
    │   └── aux_employment.mod      Employment PAC block
    │
    ├── simulation/
    │   ├── identities/        Source-of-truth .inc files for au_pac.mod
    │   │   ├── endogenous.inc      var declarations
    │   │   ├── exogenous.inc       varexo declarations
    │   │   ├── parameters.inc      parameter declarations
    │   │   ├── parameter-values.inc parameter assignments
    │   │   ├── calibration.inc     Bayesian-posterior aux-regression coefs
    │   │   ├── model.inc           equations
    │   │   ├── steady.inc          steady-state block
    │   │   ├── shocks.inc          shocks block
    │   │   └── _normalize_*.py     Python normalizers for the .inc files
    │   └── estimation/        Cherrypick outputs per PAC block (5 subdirs)
    │
    ├── nk_simple.mod / nk_discounted.mod   NK reference models (FG puzzle test)
    │
    ├── phaseW_recherrypick.m  Driver: re-runs dynare + cherrypick on all 5 aux files
    ├── setup_dynare_path.m    Locates Dynare 6.5
    │
    ├── AUSPAC_WORKING_PAPER.{md,pdf,tex,html}   The working paper (live, beside its PNGs)
    ├── PRICE_RESPONSE_DIAGNOSIS.md              Phase R/S/T price-response audit history
    ├── mcmc_posterior_table.md                  Bayesian posterior table (paper Table 5.6)
    ├── phase_r_benchmark_table.md               Phase R IRF benchmark vs FR-BDF (paper §6.3.5)
    ├── forecast_eval_table.md                   §5.5 recursive forecast RMSEs
    ├── au_pac_model_data_README.md              Dataset conventions
    ├── prepare_pac_dseries_README.md            dseries conventions
    │
    ├── regen/                 Python figure-regen helpers (read pre-baked .mat → write .png)
    │   ├── regen_three_regime_figs.py     Paper §6.2 three-regime comparison
    │   ├── regen_pac_contrib_figs.py      §4 PAC channel contributions
    │   ├── regen_section5_irfs.py         §5 IRF panel
    │   ├── regen_long_run_convergence.py  §6.0 convergence proxy
    │   ├── regen_app_experiment.py        Appendix APP experiment
    │   ├── regen_supplementary_figs.py    Supplementary figures
    │   ├── regen_wp736_style_panel.py     wp736-style benchmark panel
    │   └── regen_phase_r_benchmarks.py    §6.3 Phase R benchmark table
    │
    ├── tools/                 Python data tools (build, splice, sanity checks, writeback)
    │
    ├── diagnosis/             JSON outputs from price-response audits + identification
    │
    ├── saved_irfs.mat                    Current production IRFs
    ├── saved_irfs_{var,hybrid,mce}.mat   Already-baked Phase S three-regime IRFs (paper §6.2)
    ├── estimation_data.mat               Bayesian estimation input
    │
    └── (figures: *.png — auto-generated)
```

---

## 3. The production model (`au_pac.mod`)

Single production `.mod` file produced by `cherrypick()` + `aggregate()`. The `// --+ options: stochastic,json=compute +--` header on line 1 is what makes the workflow self-bootstrapping.

**Structural blocks** (from [dynare/simulation/identities/model.inc](dynare/simulation/identities/model.inc)):

| Block | Equations |
|---|---|
| IS / Taylor / Phillips | `eq_au_is`, `eq_taylor`, `eq_au_phillips` (Phase V ECM form) |
| Wage Phillips curve | `eq_pi_w` with `pv_u_gap` forward-looking term |
| PAC behavioural equations | `pQ_level`, `ln_c_level`, `ln_ib_level`, `ln_ih_level`, `ln_n_level` (via `pac_expectation_*` from cherrypick) |
| Production / CES factors | `dln_y_star`, `eq_ln_tfp`, `eq_dln_ulc`, `eq_rw_gap` |
| Demand deflators | `eq_pi_c`, `eq_pi_ib`, `eq_pi_ih`, `eq_pi_x`, `eq_pi_m`, `eq_pi_g` (AU reduced-form, see paper §4.9) |
| HICP reporting (Round 1.1) | `eq_pi_au_food`, `eq_pi_au_energy`, `eq_pi_au_core`, `eq_pi_au_trad`, `eq_pi_au_nontrad`, `eq_pi_au_trim` |
| Sectoral financial accounts | `eq_b_F`, `eq_b_G`, `eq_b_H`, `eq_b_N`, `eq_b_ROW` |
| ECM / level accumulators | `pQ_level`, `p_C_level`, `p_M_level`, `p_C_star_level` |

**Auxiliary PAC support** (auto-generated by cherrypick into the production file):

| Block | What | Aux source |
|---|---|---|
| `piQ_hat` / `pv_piQ_aux` | VA-price PAC target + projection | `aux/aux_pQ.mod` |
| `c_hat` / `yh_ratio_hat` / `pv_c_aux` | Consumption PAC target + projection | `aux/aux_consumption.mod` |
| `ib_hat` / `rKB_hat` / `pv_ib_aux` / `pv_rKB_aux` | Business inv PAC + WACC gap projection | `aux/aux_business_inv.mod` |
| `ih_hat` / `pv_ih_aux` | Housing inv PAC | `aux/aux_housing_inv.mod` |
| `n_hat` / `pv_n_aux` | Employment PAC | `aux/aux_employment.mod` |
| `h_pac_*` policy-function coefficients | Closed-form expectation formulas | Auto-emitted by `pac.print()` |

`au_pac_bayesian.mod` is structurally identical to `au_pac.mod` but adds a `varobs` declaration (9 observables), an `estimated_params` block (28 parameters), and an `estimation()` call that loads cached MCMC chains by default.

---

## 4. Phase T policy-function workflow

The key innovation of Phase T (FR-BDF wp1044 §3.2.3 / Adjemian-Brayton-Zimic) is that **expectations in the PAC equations are computed as closed-form policy functions of the model state**, not via shadow-VAR pseudovariables.

### 4.1 Aux files (`dynare/aux/aux_X.mod`)

Each PAC block has its own small `.mod` file. It declares:
- A `var_model` whose state vector is the structural E-SAT core (`yhat_au`, `i_gap`, `pi_au_gap`, `u_gap`, etc.) plus the relevant `_hat` target variable.
- A `pac_model` declaration pointing at the var_model.
- The PAC behavioural equation under `[name='eq_X_pac']`.
- A `pac.print()` call that emits the closed-form expectation formula into a JSON sidecar.

### 4.2 Identity layer (`dynare/simulation/identities/`)

The eight `.inc` files are the canonical source of truth for what the production model contains. The Python normalizers (`_normalize_*.py`) keep declarations and equations in alphabetical/canonical order across edits.

### 4.3 Cherrypick output (`dynare/simulation/estimation/<block>/`)

`cherrypick()` walks the aux file's JSON and extracts just the equations needed for simulation (auxiliary VAR equations, `*_hat` projection, PAC behavioural equation with the closed-form `pac_expectation_pac_X` substituted in, plus the `h_pac_*` policy-function coefficient values).

### 4.4 Composition into the production .mod

`aggregate()` combines the 5 cherrypicked block bundles with the identity layer to produce `au_pac.mod`. After re-aggregating, you must re-apply the runtime override blocks at the end of `au_pac.mod` (Phase U/V/W overrides, shocks block, steady_state_model, stoch_simul).

[dynare/phaseW_recherrypick.m](dynare/phaseW_recherrypick.m) is the one-shot MATLAB driver that runs Dynare + `cherrypick()` on all five aux files.

---

## 5. Python helpers

### 5.1 `dynare/regen/` — figure regeneration

These scripts read pre-baked `.mat` artefacts and write paper PNGs. They never invoke Dynare, so they're the fastest way to refresh paper figures after a parameter change that re-runs the model.

| Script | Output |
|---|---|
| `regen_three_regime_figs.py` | Paper §6.2 three-regime comparison (uses `saved_irfs_{var,hybrid,mce}.mat`) |
| `regen_pac_contrib_figs.py` | §4 PAC channel contributions (`contrib_*.png`) |
| `regen_section5_irfs.py` | §5 IRF panel (`irf_eps_*.png`) |
| `regen_long_run_convergence.py` | §6.0 convergence proxy |
| `regen_app_experiment.py` | Appendix APP experiment |
| `regen_supplementary_figs.py` | Supplementary figures |
| `regen_wp736_style_panel.py` | wp736-style benchmark panel |
| `regen_phase_r_benchmarks.py` | §6.3 Phase R benchmark |

### 5.2 `dynare/tools/` — data tools

Lower-level Python utilities for data build/splice/sanity checks. Used during data prep and one-off data-quality work.

---

## 6. Data flow

1. **Fetch raw data** — `data/download_*.m` pulls ABS/RBA/FRED/BIS series into CSVs.
2. **Prep observables** — `data/prepare_estimation_data.m` transforms to model units (quarterly %, demeaned) and writes `dynare/estimation_data.mat` (9 observables × 128 quarters).
3. **Calibrate CES** — `data/estimate_ces_2026.m` / `estimate_ces_stage23.m` produce the production-function parameters that feed `simulation/identities/parameter-values.inc`.
4. **Estimate auxiliary regressions** — once per major architectural change, run [phaseW_recherrypick.m](dynare/phaseW_recherrypick.m) to refresh the policy-function coefficients in `simulation/estimation/<block>/parameter-values.inc`.
5. **Run Bayesian MCMC** — `dynare au_pac_bayesian` with `mode_compute=4` + `mh_replic=20000`; about 50 min wall time. Once converged, revert to `mode_compute=0` + `load_mh_file` for cheap reloads.
6. **Generate IRFs** — `dynare au_pac` writes `oo_.irfs` (snapshot in `saved_irfs.mat`).
7. **Regenerate figures** — Python scripts in `dynare/regen/`.

---

## 7. Working paper composition

The paper at [dynare/AUSPAC_WORKING_PAPER.md](dynare/AUSPAC_WORKING_PAPER.md) is the live, authoritative document. The corresponding `.pdf`/`.tex`/`.html` are auto-generated. The paper references PNG figures and `.md` tables that live alongside it in `dynare/`:

- Tables: `mcmc_posterior_table.md`, `phase_r_benchmark_table.md`, `forecast_eval_table.md`
- Figures: `contrib_*.png`, `three_regime_*.png`, `irf_eps_*.png`, `forward_guidance_puzzle.png`, `app_experiment_200bp.png`, etc.

---

## 8. Dependencies

| Component | Version | Notes |
|---|---|---|
| MATLAB | R2019a+ | Required for Dynare workflows. On Apple Silicon, R2020a needs `arch -x86_64` for Rosetta. |
| Dynare | 6.5 | Auto-located by [dynare/setup_dynare_path.m](dynare/setup_dynare_path.m). |
| Python | 3.9+ | For figure-regen helpers. |
| `scipy`, `matplotlib`, `h5py` | latest | `pip install scipy matplotlib h5py` |

---

## 9. Where to look next

- **Want to run the model?** [RUNNING.md](RUNNING.md).
- **Want to see what's been done and what's open?** [STATUS.md](STATUS.md).
- **Want to plan the next development cycle?** [NEXT_STEPS_PLAN.md](NEXT_STEPS_PLAN.md).
- **Want to understand the economics?** [dynare/AUSPAC_WORKING_PAPER.md](dynare/AUSPAC_WORKING_PAPER.md).
- **Want to read the source equations?** [dynare/simulation/identities/model.inc](dynare/simulation/identities/model.inc).
- **Want the Phase T workflow internals?** §4 above, then read the aux files in [dynare/aux/](dynare/aux/).

---

## Citations

> Lemoine, M., Turunen, H., Chahad, M., Lepetit, A., Zhutova, A., Aldama, P., Clerc, P., and Laffargue, J.-P. (2019). *The FR-BDF Model and an Assessment of Monetary Policy Transmission to the French Economy.* Banque de France WP No. 736.
>
> Dubois, U., Ducoudré, B., Martin, R., Petronevich, A., Seghini, C., Thubin, C., and Turunen, H. (2026). *Re-estimated FR-BDF: New Features and an Assessment of Monetary Policy Tightening in France.* Banque de France WP No. 1044.
>
> Angelini, E., Bokan, N., Christoffel, K., Ciccarelli, M., and Zimic, S. (2019). *Introducing ECB-BASE: The blueprint of the new ECB semi-structural model for the euro area.* ECB Working Paper Series No. 2315.
