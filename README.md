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
├── STATUS.md                          current status + phase trajectory + open items
├── NEXT_STEPS_PLAN.md                 v3.2 roadmap
├── ARCHITECTURE.md                    developer code map
├── dataset.csv / data.mat / params.mat   data artefacts (gitignored)
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
│   └── estimate_ces_*.m               CES production calibration drivers
│
└── dynare/                            ▼ models, source, outputs ▼
    ├── au_pac.mod                     ★ production model (164 endo, 33 exo shocks)
    ├── au_pac_bayesian.mod            ★ Bayesian-estimation variant
    ├── aux/                              5 PAC aux files (estimation inputs)
    ├── simulation/identities/            source-of-truth .inc files
    ├── simulation/estimation/            cherrypicked .inc bundles (5 subdirs)
    │
    ├── nk_simple.mod / nk_discounted.mod    NK reference models for FG puzzle test
    │
    ├── phaseW_recherrypick.m             driver: re-run dynare + cherrypick on all 5 aux files
    ├── setup_dynare_path.m               locates Dynare 6.5
    │
    ├── AUSPAC_WORKING_PAPER.md           the working paper (live, beside its PNGs)
    ├── mcmc_posterior_table.md           Bayesian posterior table (paper Table 5.6 source)
    ├── phase_r_benchmark_table.md        Phase R IRF benchmark vs FR-BDF
    ├── forecast_eval_table.md            §5.5 recursive forecast RMSEs
    ├── *_README.md                       data + dseries READMEs
    │
    ├── regen/                            Python figure-regen helpers
    │   └── regen_*.py                    read .mat from dynare/, write PNG to dynare/
    │
    ├── tools/                            Python data tools (build, splice, sanity checks, writeback)
    │
    ├── saved_irfs.mat                    current production IRFs
    ├── saved_irfs_{var,hybrid,mce}.mat   already-baked Phase S three-regime IRFs (paper §6.2)
    ├── estimation_data.mat               estimation dataset input to au_pac_bayesian.mod
    │
    └── (figures: *.png — auto-generated)
```

`dynare/setup_dynare_path.m` is the bootstrap entry point: it locates Dynare 6.5.

---

## Reproducing paper results

All paths below are relative to the repo root.

### Tables in the paper

| Table | Source                                  | Notes                                                              |
|-------|-----------------------------------------|--------------------------------------------------------------------|
| 5.6   | `dynare/mcmc_posterior_table.md`         | Reload cached MCMC via `dynare au_pac_bayesian` to recompute       |
| 5.7   | `dynare/forecast_eval_table.md`          | Static table baked from Phase S forecast-eval; regenerate with Phase T driver if revisited |
| 6.1   | Hard-coded from steady-state computation | manual                                                             |
| 6.2   | `dynare/saved_irfs_{var,hybrid,mce}.mat` | `dynare/regen/regen_three_regime_figs.py` (verify table values)    |
| 6.3   | `dynare/saved_irfs_{var,hybrid,mce}.mat` | as above                                                           |
| 6.5   | (Phase S conditional-forecast driver)    | Driver retired in 2026-05-18 cleanup; rebuild against Phase T if needed |
| 6.6   | (Phase S forward-guidance test)          | Driver retired; reproduce with a fresh script invoking `nk_simple.mod` + `nk_discounted.mod` + `au_pac.mod` |

### Figures in the paper

All paper figures regenerate from pre-baked `.mat` artefacts via the [dynare/regen/](dynare/regen/) Python scripts (no Dynare needed):

| Figure | File                                          | Script                                          |
|--------|-----------------------------------------------|-------------------------------------------------|
| 4.3.1–4.7.1 | `dynare/contrib_*.png`                   | `dynare/regen/regen_pac_contrib_figs.py`        |
| 6.0    | `dynare/long_run_convergence_proxy.png`       | `dynare/regen/regen_long_run_convergence.py`   |
| 6.1–6.2 | `dynare/three_regime_*.png`                  | `dynare/regen/regen_three_regime_figs.py`      |
| 6.3–6.9 | `dynare/irf_eps_*.png`                       | `dynare/regen/regen_section5_irfs.py`          |
| 6.13   | `dynare/forward_guidance_puzzle.png`          | already-baked; regenerate via a fresh Phase T FG driver if revisited |
| 6.14   | `dynare/app_experiment_200bp.png`             | `dynare/regen/regen_app_experiment.py`         |

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
