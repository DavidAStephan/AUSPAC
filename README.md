# AUSPAC — A Semi-Structural Macroeconomic Model for Australia

**AU-PAC** is the Australian adaptation of the Banque de France's FR-BDF
model (Lemoine et al., 2019, [WP #736](wp736.pdf)). It is a
semi-structural macroeconomic model with Polynomial Adjustment Costs (PAC),
explicit expectations from a 12-equation satellite VAR, and a CES supply
block estimated on Australian data. The model covers 154 endogenous
variables, 47 exogenous shocks, and 258 parameters; five PAC behavioural
equations govern value-added prices, consumption, business investment,
household investment, and employment.

Status: **Phase G complete** (Phases A–G, 2026-05-10). All behavioural
parameters are estimated or Bayesian-regularised on AU data. Headline
results in [`dynare/AUSPAC_WORKING_PAPER.md`](dynare/AUSPAC_WORKING_PAPER.md).
Open follow-ups in [`dynare/NEXT_STEPS.md`](dynare/NEXT_STEPS.md).

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
cd dynare
pip install scipy matplotlib
python3 regen_three_regime_figs.py        # Figs 6.1, 6.2
python3 regen_pac_contrib_figs.py         # Figs 4.3.1, 4.4.1, 4.5.1, 4.6.1, 4.7.1
python3 regen_section5_irfs.py            # Figs 6.3–6.9 (per-shock IRF panels)
python3 regen_long_run_convergence.py     # Fig 6.0 (long-run convergence proxy)
python3 regen_app_experiment.py           # Fig 6.14 (APP-style 200bp experiment)
```

---

## Repository layout

```
auspac/
├── README.md                          (you are here)
├── RUNNING.md                         step-by-step MATLAB run instructions
├── STATUS.md                          phase log / development history
├── wp736.pdf                          FR-BDF source paper (Lemoine et al. 2019)
├── make_paper_results.m               top-level reproduction driver
├── run_all.m                          end-to-end pipeline runner
├── download_data.m                    FRED / RBA / ABS data fetch
├── dataset.csv                        E-SAT core dataset (auto-built)
├── data/
│   └── extended_dataset.csv           demand-side dataset
└── dynare/                            ▼ all model code lives here ▼
    ├── au_pac.mod                     Hybrid model (financial-forward, PAC-backward)
    ├── au_pac_var.mod                 VAR-based (all-backward) variant
    ├── au_pac_mce.mod                 Full MCE (all-forward) variant
    ├── au_pac_bayesian.mod            Bayesian estimation .mod
    ├── au_pac_smooth.mod              Kalman smoother .mod
    │
    ├── AUSPAC_WORKING_PAPER.md        the working paper (live)
    ├── NEXT_STEPS.md                  forward-looking task list (Phases I–O)
    │
    ├── estimate_pac.m                 iterative-OLS PAC estimation
    ├── estimate_phase_c_lpiv.m        Phase C: b_di_c, b_ph_ih (Bayesian shrinkage)
    ├── estimate_phase_d_trade.m       Phase D: b1_x from ABS 5206
    ├── run_bayesian_estimation.m      Bayesian Stage 1 (csminwel mode)
    ├── run_bayesian_mcmc.m            Bayesian Stage 2 (Metropolis-Hastings)
    ├── extract_mcmc_results.m         post-MCMC table generator
    │
    ├── generate_three_regime_irfs.m   3-regime monetary IRF comparison (canonical)
    ├── generate_wp_irfs.m             per-shock IRF panels (canonical)
    ├── forward_guidance.m             forward-guidance puzzle test
    ├── forecast_eval.m                Phase I recursive forecast evaluation driver
    ├── identification_analysis.m      Phase J identification diagnostics driver
    ├── long_run_convergence.m         FR-BDF Fig 5.1.1 long-run convergence driver
    │
    ├── regen_three_regime_figs.py     Python helper (no MATLAB)
    ├── regen_pac_contrib_figs.py      Python helper (no MATLAB)
    ├── regen_section5_irfs.py         Python helper (no MATLAB)
    ├── regen_long_run_convergence.py  Python helper (no MATLAB)
    ├── regen_app_experiment.py        Python helper (no MATLAB)
    │
    ├── bayesian_mcmc_results.mat      Phase G MCMC posterior (smoother + chains)
    ├── saved_irfs_{var,hybrid,mce}.mat IRFs for all 45 shocks × 24 vars × 40Q
    ├── estimation_data.mat            122-quarter estimation dataset
    │
    └── (figures: *.png — auto-generated)
```

---

## Reproducing paper results

### Tables in the paper

| Table | Source                                                | Script                                       |
|-------|-------------------------------------------------------|----------------------------------------------|
| 5.6   | `bayesian_mcmc_log.txt`                                | `run_bayesian_mcmc.m` → `extract_mcmc_results.m` |
| 5.7   | `phase_c_results.txt`                                  | `estimate_phase_c_lpiv.m`                    |
| 6.1   | Hard-coded from steady-state computation               | manual                                       |
| 6.2   | `saved_irfs_*.mat`                                     | `regen_three_regime_figs.py` (verify table values) |
| 6.3   | `saved_irfs_*.mat`                                     | as above                                     |
| 6.5   | `conditional_forecast_driver.m`                        | `conditional_forecast_driver.m`              |
| 6.6   | `forward_guidance.m`                                   | `forward_guidance.m`                         |

### Figures in the paper

| Figure | File                                          | Script                                  |
|--------|-----------------------------------------------|-----------------------------------------|
| 4.3.1  | `contrib_piQ.png`                              | `regen_pac_contrib_figs.py`             |
| 4.4.1  | `contrib_n.png`                                | as above                                |
| 4.5.1  | `contrib_c.png`                                | as above                                |
| 4.6.1  | `contrib_ib.png`                               | as above                                |
| 4.7.1  | `contrib_ih.png`                               | as above                                |
| 6.0    | `long_run_convergence_proxy.png`               | `regen_long_run_convergence.py`         |
| 6.1    | `three_regime_monetary_irf.png`                | `regen_three_regime_figs.py`            |
| 6.2    | `three_regime_full_comparison.png`             | as above                                |
| 6.3    | `irf_eps_i.png`                                | `regen_section5_irfs.py`                |
| 6.4    | `irf_eps_q_us.png`                             | as above                                |
| 6.5    | `irf_eps_g.png`                                | as above                                |
| 6.6    | `irf_eps_pcom.png`                             | as above                                |
| 6.7    | `irf_eps_pQ.png`                               | as above                                |
| 6.8    | `irf_eps_tfp.png`                              | as above                                |
| 6.9    | `irf_eps_tp.png`                               | as above                                |
| 6.13   | `forward_guidance_puzzle.png`                  | `forward_guidance.m`                    |
| 6.14   | `app_experiment_200bp.png`                     | `regen_app_experiment.py`               |

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
[`dynare/au_pac_model_data_README.md`](dynare/au_pac_model_data_README.md).

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
