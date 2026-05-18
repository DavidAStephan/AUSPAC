# AUSPAC — A Semi-Structural Macroeconomic Model for Australia

**AU-PAC** is the Australian adaptation of the Banque de France's FR-BDF
model (Lemoine et al., 2019, [WP #736](references/wp736.pdf)). It is a
semi-structural macroeconomic model with Polynomial Adjustment Costs (PAC),
explicit expectations from a 12-equation satellite VAR, and a CES supply
block estimated on Australian data. The model covers 154 endogenous
variables, 47 exogenous shocks, and 258 parameters; five PAC behavioural
equations govern value-added prices, consumption, business investment,
household investment, and employment.

Status: **v3.0 — Phase T architecture** (tagged 2026-05-16). Bayesian MCMC
MHM log marginal density = **−781.39** (+20.66 cumulative nats over Phase Q
baseline). PAC expectations now use the FR-BDF wp1044 / srecko / Brayton
policy-function pattern. Full status, phase trajectory, and open items in
[`STATUS.md`](STATUS.md). Working paper in
[`dynare/AUSPAC_WORKING_PAPER.md`](dynare/AUSPAC_WORKING_PAPER.md).

---

## Quick start (full reproduction)

Prerequisites: MATLAB R2019a+, Dynare 6.5, Python 3.9+. Detailed install
instructions in [`RUNNING.md`](RUNNING.md).

```matlab
% From the repo root in MATLAB:
make_paper_results
```

This script runs the full estimation pipeline, generates all figures, and
refreshes the working paper tables. Wall time ≈ 2 hours on Apple Silicon
under Rosetta 2 (most of which is the 20k-draw × 2-chain Bayesian MCMC).

For figure-only refreshes from saved artefacts (no Dynare/MATLAB needed):

```bash
pip install scipy matplotlib
python3 dynare/regen/regen_three_regime_figs.py        # Figs 6.1, 6.2
python3 dynare/regen/regen_pac_contrib_figs.py         # Figs 4.3.1, 4.4.1, 4.5.1, 4.6.1, 4.7.1
python3 dynare/regen/regen_section5_irfs.py            # Figs 6.3–6.9 (per-shock IRF panels)
python3 dynare/regen/regen_long_run_convergence.py     # Fig 6.0 (long-run convergence proxy)
python3 dynare/regen/regen_app_experiment.py           # Fig 6.14 (APP-style 200bp experiment)
```

Each script reads from and writes back to `dynare/` (where the
`saved_irfs_*.mat` and PNG outputs live), regardless of where it's invoked.

---

## Repository layout

```
AUSPAC/
├── README.md                          (you are here)
├── RUNNING.md                         step-by-step MATLAB run instructions
├── STATUS.md                          v3.0 status + phase trajectory + open items
├── make_paper_results.m               top-level reproduction driver
├── run_all.m                          legacy E-SAT pipeline driver
├── test_full_system.m                 end-to-end regression test
├── download_data.m / estimate_esat.m / esat_model.m / bayesian_estimate.m
│                                      legacy E-SAT chain (root for compat)
├── dataset.csv / data.mat / params.mat
│                                      E-SAT outputs (gitignored)
│
├── references/                        source PDFs
│   ├── wp736.pdf                      FR-BDF source paper (Lemoine et al. 2019)
│   ├── FR-BDF-update.pdf              FR-BDF 2026 update (Dubois et al.)
│   └── RBA_mon_transmission.pdf       RBA monetary transmission reference
│
├── data/                              raw + downloaded data
│   ├── abs_rba/                       ABS / RBA xlsx + csv
│   ├── extended_dataset.csv           demand-side dataset
│   ├── house_price_*.csv              housing-price series
│   ├── io_tables_australia.xlsx       2019 input-output tables
│   ├── download_*.m                   data fetch scripts
│   ├── prepare_*.m                    data prep scripts
│   └── estimate_ces_*.m / estimate_sigma_stage1.m  (CES calibration drivers)
│
└── dynare/                            ▼ models, source, outputs ▼
    ├── au_pac_v2.mod                  ★ v3.0 production model (Phase T policy-function)
    ├── au_pac_v2_bayesian.mod         ★ v3.0 Bayesian estimation model
    ├── aux/                           ★ 5 PAC aux files (estimation inputs)
    ├── simulation/identities/         ★ normalized .inc files + Python normalizers
    ├── simulation/estimation/         ★ cherrypicked .inc bundles (5 subdirs)
    │
    ├── au_pac.mod                     Phase S Hybrid model (preserved for paper §6.2)
    ├── au_pac_var.mod                 Phase S VAR variant (preserved)
    ├── au_pac_mce.mod                 Phase S MCE variant (preserved)
    ├── au_pac_bayesian.mod            Phase S Bayesian estimation .mod
    ├── au_pac_smooth.mod              Kalman smoother .mod
    ├── au_pac_condforecast.mod        Conditional forecast .mod
    ├── au_pac_identification.mod      Identification analysis .mod
    ├── au_pac_recursive.mod           Recursive forecast .mod
    ├── au_esat.mod / au_esat_est.mod  Auxiliary E-SAT VAR
    ├── nk_simple.mod / nk_discounted.mod
    │                                  NK benchmarks for forward-guidance test
    │
    ├── setup_dynare_path.m            path bootstrap (addpath scripts/* + Dynare)
    │
    ├── AUSPAC_WORKING_PAPER.md        the working paper (live, beside its PNGs)
    ├── mcmc_posterior_table_phase_t.md ★ v3.0 posteriors (Table 5.6 source)
    ├── phase_r_benchmark_table.md     Phase R IRF benchmark vs FR-BDF
    ├── forecast_eval_table.md         Section 5.5 recursive forecast RMSEs
    ├── *_README.md                    data + dseries READMEs
    │
    ├── scripts/
    │   ├── estimation/                Bayesian + PAC + Phase B/C/D estimators,
    │   │                              run_bayesian_*.m, run_2026_*.m, run_phase_q_*.m
    │   ├── figures/                   IRF generators (generate_*_irfs.m, irf_*.m,
    │   │                              compare_irfs.m, quick_uip_irfs.m)
    │   ├── analysis/                  forward_guidance, forecast_eval,
    │   │                              conditional_forecast, identification,
    │   │                              long_run_convergence, sectoral_validation
    │   ├── data_prep/                 prepare_pac_dseries*.m, prepare_*_data.m
    │   └── tests/                     test_smoother_comparison.m
    │
    ├── regen/                         Python figure-regen helpers (Phase H)
    │   └── regen_*.py                 reads .mat from dynare/, writes PNG to dynare/
    │
    ├── tools/                         Python data tools + appliers
    │   ├── build_*.py / splice_*.py / trend_*.py / channel_*.py
    │   ├── sanity_check_*.py / imports_*.py
    │   ├── extract_2026_results.py
    │   └── apply_mcmc_writeback.py / apply_trade_ecm_fix.py
    │
    ├── bayesian_mcmc_results.mat      Phase G MCMC posterior (gitignored)
    ├── saved_irfs_{var,hybrid,mce}.mat IRFs for all 45 shocks × 24 vars × 40Q (gitignored)
    ├── estimation_data.mat            122-quarter estimation dataset (gitignored)
    │
    └── (figures: *.png — auto-generated, gitignored)
```

`dynare/setup_dynare_path.m` is the bootstrap entry point: it adds every
`dynare/scripts/*` subfolder to the MATLAB path and then locates Dynare 6.5.
Drivers cd into `dynare/` and call `setup_dynare_path()` once at the top.

---

## Reproducing paper results

All paths below are relative to the repo root.

### Tables in the paper

| Table | Source                                  | Script                                                              |
|-------|-----------------------------------------|---------------------------------------------------------------------|
| 5.6   | `dynare/bayesian_mcmc_log.txt`           | `dynare/scripts/estimation/run_bayesian_mcmc.m` → `extract_mcmc_results.m` |
| 5.7   | `dynare/phase_c_results.txt`             | `dynare/scripts/estimation/estimate_phase_c_lpiv.m`                 |
| 6.1   | Hard-coded from steady-state computation | manual                                                              |
| 6.2   | `dynare/saved_irfs_*.mat`                | `dynare/regen/regen_three_regime_figs.py` (verify table values)     |
| 6.3   | `dynare/saved_irfs_*.mat`                | as above                                                            |
| 6.5   | `dynare/scripts/analysis/conditional_forecast_driver.m` | `conditional_forecast_driver.m`                      |
| 6.6   | `dynare/scripts/analysis/forward_guidance.m`            | `forward_guidance.m`                                 |

### Figures in the paper

| Figure | File                              | Script                                            |
|--------|-----------------------------------|---------------------------------------------------|
| 4.3.1  | `dynare/contrib_piQ.png`           | `dynare/regen/regen_pac_contrib_figs.py`          |
| 4.4.1  | `dynare/contrib_n.png`             | as above                                          |
| 4.5.1  | `dynare/contrib_c.png`             | as above                                          |
| 4.6.1  | `dynare/contrib_ib.png`            | as above                                          |
| 4.7.1  | `dynare/contrib_ih.png`            | as above                                          |
| 6.0    | `dynare/long_run_convergence_proxy.png` | `dynare/regen/regen_long_run_convergence.py` |
| 6.1    | `dynare/three_regime_monetary_irf.png`  | `dynare/regen/regen_three_regime_figs.py`    |
| 6.2    | `dynare/three_regime_full_comparison.png` | as above                                   |
| 6.3    | `dynare/irf_eps_i.png`             | `dynare/regen/regen_section5_irfs.py`             |
| 6.4    | `dynare/irf_eps_q_us.png`          | as above                                          |
| 6.5    | `dynare/irf_eps_g.png`             | as above                                          |
| 6.6    | `dynare/irf_eps_pcom.png`          | as above                                          |
| 6.7    | `dynare/irf_eps_pQ.png`            | as above                                          |
| 6.8    | `dynare/irf_eps_tfp.png`           | as above                                          |
| 6.9    | `dynare/irf_eps_tp.png`            | as above                                          |
| 6.13   | `dynare/forward_guidance_puzzle.png` | `dynare/scripts/analysis/forward_guidance.m`    |
| 6.14   | `dynare/app_experiment_200bp.png`  | `dynare/regen/regen_app_experiment.py`            |

---

## Data sources

| Block         | Source                                                                     |
|---------------|---------------------------------------------------------------------------|
| GDP / output  | ABS Cat. 5206.0 — National Income, Expenditure and Product (quarterly)    |
| Capital stock | ABS Cat. 5204.0 Tables 47/48 — capital and depreciation (annual)          |
| Housing prices| ABS Cat. 6416.0 — Residential Property Price Indexes                       |
| Wages         | ABS Cat. 6345.0 — Wage Price Index                                         |
| Hours / employment | ABS Cat. 6202.0 — Labour Force                                       |
| Cash rate     | RBA F1                                                                     |
| Mortgage rate | RBA F11                                                                    |
| Commodity prices | RBA G3 — RBA Index of Commodity Prices                                  |
| 10Y yield     | RBA F2                                                                     |
| Exchange rate | BIS effective exchange rate indices                                        |
| US series     | FRED — output gap, CPI, federal funds rate, US 10Y                         |

Aggregation conventions and transformations are documented in
[`dynare/au_pac_model_data_README.md`](dynare/au_pac_model_data_README.md)
and [`dynare/prepare_pac_dseries_README.md`](dynare/prepare_pac_dseries_README.md).

---

## Dependencies

| Component           | Version    | Where                                                 |
|---------------------|------------|-------------------------------------------------------|
| MATLAB              | R2019a+    | required for Dynare workflows                          |
| Dynare              | 6.5        | https://www.dynare.org/download/                       |
| Python              | 3.9+       | for figure-regeneration helpers (Phase H artefacts)    |
| `scipy`, `matplotlib` | latest   | `pip install scipy matplotlib`                         |
| Git LFS             | optional   | only needed if `.mat` artefacts grow beyond GitHub's free quota |

---

## Citation

If you use AU-PAC in academic work, please cite both the model paper and the
underlying FR-BDF reference:

> Stephan, D. (2026). *AU-PAC: A Semi-Structural Macroeconomic Model for
> Australia.* Working paper, available at
> https://github.com/DavidAStephan/AUSPAC
>
> Lemoine, M., Turunen, H., Chahad, M., Lepetit, A., Zhutova, A., Aldama, P.,
> Clerc, P., and Laffargue, J.-P. (2019). *The FR-BDF Model and an Assessment
> of Monetary Policy Transmission to the French Economy.* Banque de France
> Working Paper No. 736.

---

## Licence

Code: MIT (see [LICENSE](LICENSE) if present, else default).
Data: original ABS / RBA / BIS / FRED licences apply; redistributed
derivatives are subject to the respective provider terms.
