# AUSPAC — How to Run

## Prerequisites

- **MATLAB** R2019a or newer (Apple Silicon hosts can run R2020a under Rosetta with `arch -x86_64`).
- **Dynare 6.5** — auto-located by [dynare/setup_dynare_path.m](dynare/setup_dynare_path.m). Standard install paths are detected on Windows (`C:\dynare\6.5\matlab`, `C:\Program Files\Dynare\6.5\matlab`), macOS (`/Applications/Dynare/6.5-x86_64/matlab`, `/Applications/Dynare/6.5-arm64/matlab`), and Linux (`/usr/lib/dynare/matlab`). Override with `DYNARE_PATH` env var if installed elsewhere.
- **Python 3** with `scipy`, `matplotlib`, `h5py` — only for the figure-regen scripts in [dynare/regen/](dynare/regen/).

All commands below assume MATLAB started from the repo root. Scripts self-locate, so explicit `cd` is only noted where strictly required.

---

## Quick start: load the cached MCMC and print summary stats (~30 sec)

```matlab
cd dynare; setup_dynare_path;
addpath(genpath('/Applications/Dynare/6.5-x86_64/matlab/missing'));   % needed for rows()
dynare au_pac_bayesian          % mode_compute=0 + load_mh_file reloads cached MCMC
                                % reports Laplace LMD (-779.30) and MHM LMD (-780.47)
```

## Quick start: regenerate IRFs from the current model (~30 sec)

```matlab
cd dynare; setup_dynare_path;
addpath(genpath('/Applications/Dynare/6.5-x86_64/matlab/missing'));
dynare au_pac                   % solves the model, runs stoch_simul, saves
                                % oo_.irfs with 22 default output series
```

---

## Full estimation pipeline (~55 min, only when you change the model)

```matlab
cd dynare; setup_dynare_path;
addpath(genpath('/Applications/Dynare/6.5-x86_64/matlab/missing'));

% Step 1: per-PAC-block aux-file estimation + cherrypick
%         Re-runs Dynare on each aux/aux_X.mod and cherrypicks to
%         simulation/estimation/<block>/. Required after editing any
%         aux/aux_*.mod file or after calibration.inc changes.
run('phaseW_recherrypick.m');

% Step 2: aggregate the cherrypicked .inc bundles into au_pac.mod
%         Required only when simulation/identities/*.inc or the cherrypicked
%         bundles change structurally; pure parameter-value refreshes do not
%         require re-aggregation.
aggregate('au_pac.mod', {'stochastic,json=compute'}, pwd, ...
    'simulation/estimation/pQ', 'simulation/estimation/consumption', ...
    'simulation/estimation/business_inv', 'simulation/estimation/housing_inv', ...
    'simulation/estimation/employment', 'simulation/identities');

% Step 3: after Step 2, re-apply the runtime override blocks at the end of
%         au_pac.mod (Phase U/V/W manual overrides, the shocks block,
%         steady_state_model block, and stoch_simul block).

% Step 4: fresh MCMC (~50 min on Apple Silicon under Rosetta)
%         To estimate, set mode_compute=4 (csminwel) and mh_replic=20000 in
%         the estimation() block of au_pac_bayesian.mod, then:
dynare au_pac_bayesian
%         Once converged, revert estimation() to mode_compute=0 + load_mh_file
%         so subsequent invocations cheaply reload the chains.
```

---

## Data preparation (only when raw series need refreshing)

```matlab
cd data
download_abs_rba       % refreshes ABS National Accounts + RBA monetary series
download_extended_data % refreshes employment / investment / wages / financial
download_supply_data   % refreshes CES supply-side inputs
download_rba           % RBA secondary series
prepare_estimation_data % writes dynare/estimation_data.mat (9 observables)
prepare_supply_data    % writes dynare/supply_data.mat
estimate_ces_2026      % refreshes CES production-function calibration
estimate_ces_stage23   % stage-2/3 CES re-estimation
```

These scripts produce the CSVs and `.mat` files in [data/](data/) and the `estimation_data.mat` and `supply_data.mat` files in [dynare/](dynare/). You only need to re-run them when the underlying ABS/RBA/FRED data has been updated.

---

## Figure regeneration from saved artefacts (no MATLAB, no Dynare)

```bash
pip install scipy matplotlib h5py
python3 dynare/regen/regen_three_regime_figs.py      # paper §6.2 three-regime comparison
python3 dynare/regen/regen_pac_contrib_figs.py       # PAC channel-contribution figures
python3 dynare/regen/regen_section5_irfs.py          # §5 IRF panel
python3 dynare/regen/regen_long_run_convergence.py   # long-run convergence proxy
python3 dynare/regen/regen_app_experiment.py         # appendix APP experiment
python3 dynare/regen/regen_supplementary_figs.py     # supplementary figures
python3 dynare/regen/regen_wp736_style_panel.py      # wp736-style benchmark panel
python3 dynare/regen/regen_phase_r_benchmarks.py     # paper §6.3 phase-R benchmark table
```

These read pre-baked `saved_irfs*.mat` and `oo_` artefacts. They never need Dynare.

---

## File reference

### Model files in [dynare/](dynare/)

| File | Description |
|------|-------------|
| `au_pac.mod` | Production semi-structural model (164 endogenous variables, 33 exogenous shocks). |
| `au_pac_bayesian.mod` | Bayesian-estimation variant with `varobs`, `estimated_params`, and an `estimation()` block. |
| `aux/aux_pQ.mod`, `aux/aux_consumption.mod`, `aux/aux_business_inv.mod`, `aux/aux_housing_inv.mod`, `aux/aux_employment.mod` | Per-PAC-block aux files. Each is fed to Dynare's `pac.print()` + `cherrypick()` to extract the policy-function expectation formula. |
| `simulation/identities/*.inc` | Source-of-truth `.inc` files (endogenous, parameters, model equations, parameter values, steady state, shocks). The `aggregate()` workflow inlines these into `au_pac.mod`. |
| `simulation/estimation/<block>/*.inc` | Cherrypick outputs for each PAC block — fed to `aggregate()`. |
| `nk_simple.mod`, `nk_discounted.mod` | Standard NK reference models for the forward-guidance puzzle test (paper §6.5). |

### Scripts in [dynare/](dynare/)

| File | Description |
|------|-------------|
| `setup_dynare_path.m` | Locates and adds the Dynare installation to MATLAB path. |
| `phaseW_recherrypick.m` | One-shot driver that runs Dynare + `cherrypick()` on all 5 aux files. Use after editing any `aux/aux_*.mod` or `simulation/identities/calibration.inc`. |

### Data files

| File | Description |
|------|-------------|
| `dataset.csv` | Core E-SAT observables (output gap, inflation, rates), 1993Q1–2024Q4. |
| `data/extended_dataset.csv` | Employment, investment, wages, 10Y rate. |
| `dynare/estimation_data.mat` | Demeaned MAT-format input to `au_pac_bayesian.mod`'s `estimation()` block. Produced by [data/prepare_estimation_data.m](data/prepare_estimation_data.m). |
| `dynare/supply_data.mat` | CES supply-side dataset used by `data/estimate_ces_*.m`. |

### Saved IRF artefacts (already baked, used by the Python regen scripts)

| File | Used by |
|------|---------|
| `dynare/saved_irfs.mat` | Current production IRFs. |
| `dynare/saved_irfs_var.mat`, `dynare/saved_irfs_hybrid.mat`, `dynare/saved_irfs_mce.mat` | Paper §6.2 three-regime comparison figures. |

---

## Troubleshooting

- **`oo_.var` is a double, not struct**: After `stoch_simul`, run `oo_.var = struct(); get_companion_matrix('esat_enriched', 'var');`
- **`diary` doesn't capture Dynare output**: Use file-based logging (`fopen`/`fprintf`/`fclose`).
- **Apple Silicon: MATLAB R2020a fails with "could not determine the machine architecture"**: Prefix with `arch -x86_64` to force Rosetta.
- **Mode search needed (parameter set changed)**: Temporarily set `mode_compute=4` and `mh_replic=0` in the `estimation()` block of `au_pac_bayesian.mod`, run, capture the Laplace LMD, then revert to `mode_compute=0` + `load_mh_file`.
