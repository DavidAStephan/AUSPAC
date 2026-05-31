# AUSPAC — How to Run

## Prerequisites

- **MATLAB R2026a** (maca64). Not on `PATH` — invoke by full path:
  `/Applications/MATLAB_R2026a.app/bin/matlab -batch "..."`.
- **Dynare 7.0-arm64** at `~/Applications/Dynare/7.0-arm64`. The driver scripts
  add it to the path explicitly (`addpath('/Users/.../Applications/Dynare/7.0-arm64/matlab')`).
- **Python 3** with `scipy`, `matplotlib`, `h5py` — only for ad-hoc inspection of saved `.mat` artefacts.

> **Production parameters come from equation-by-equation OLS** (FR-BDF wp1044 §2.2),
> not MCMC. The old Bayesian pipeline (`au_pac_bayesian.mod`, `phaseW_recherrypick.m`,
> the `simulation/` cherrypick tree, `dynare/regen/`) was removed in cleanup `7995ce7`.

---

## 1. Solve the model + regenerate IRFs and paper artifacts (~1 min)

`au_pac.mod` hardcodes every coefficient, so this needs neither `dataset.csv`
nor any data prep.

```matlab
cd dynare
run('regen_all_artifacts.m')     % addpaths Dynare 7.0-arm64, runs `dynare au_pac.mod`,
                                 % writes saved_irfs_hybrid_writeback.mat, paper_irf_peaks.txt,
                                 % and the IRF panel PNGs into dynare/paper_artifacts/
```

Or just solve the model directly:

```matlab
cd dynare
addpath('/Users/davidstephan/Applications/Dynare/7.0-arm64/matlab')
dynare au_pac.mod                % stoch_simul(order=1, irf=200); BK printed to console; oo_.irfs populated
```

Headless equivalent:

```bash
/Applications/MATLAB_R2026a.app/bin/matlab -nodesktop -nosplash -nodisplay \
  -batch "cd dynare; run('regen_all_artifacts.m')"
```

---

## 2. Re-estimate the PAC blocks from AU data (only when you change the data/spec)

```matlab
% (once) restore the base dataset if absent:
%   from repo root:  git show 7995ce7^:dataset.csv > dataset.csv
cd data
run('run_all_l2_ols.m')          % 5 core PAC blocks -> data/pac_blocks/results_*.{mat,txt}
```

`run_all_l2_ols.m` drives the five core blocks
(`estimate_pac_va_price`, `estimate_pac_employment`, `estimate_pac_consumption`,
`estimate_pac_housing_inv`, `estimate_pac_business_inv`). The remaining headline
coefficients are produced by standalone scripts in `data/pac_blocks/`:

```matlab
cd data/pac_blocks
estimate_wage_phillips_constrained   % BK-constrained wage Phillips
estimate_cpi_phillips                % flat CPI Phillips
estimate_deflators                   % demand deflators
estimate_trade_exports               % export ECM (SA data)
estimate_trade_imports               % import ECM (SA data)
```

**Writeback**: each script writes `results_<block>.{mat,txt}`; the OLS point
estimates are then copied by hand into the parameter-assignment lines of
`dynare/au_pac.mod` (per the project convention of writing back OLS estimates
verbatim). After editing the PAC `aux/aux_*.mod` structural coefficients, the
`h_pac_*` policy-function vectors must be regenerated with `pac.print()` (see
§4) — otherwise the forward-looking expectation is inconsistent with the new
ECM speeds.

---

## 3. Data preparation (only when raw ABS/RBA/FRED series need refreshing)

```matlab
cd data
download_abs_rba         % ABS National Accounts + RBA monetary series
download_extended_data   % employment / investment / wages / financial
download_supply_data     % CES supply-side inputs
prepare_supply_data      % -> dynare/supply_data.mat
prepare_l2_data          % L2 demand-side dataset
prepare_trade_price_data % -> data/trade_price_data.mat (SA volume columns; see §6.13)
estimate_ces_2026        % CES production-function calibration
estimate_ces_stage23     % stage-2/3 CES re-estimation
```

---

## 4. Regenerate the PAC `h_pac` policy-function vectors

After changing any `aux/aux_*.mod` structural coefficient, re-derive the
discounted-expectation projection for that block:

```matlab
cd dynare
addpath('/Users/davidstephan/Applications/Dynare/7.0-arm64/matlab')
dynare aux/aux_employment.mod        % runs pac.print() -> aux_employment/Output/*.mat
dynare aux/aux_housing_inv.mod       % (repeat per changed block)
% then copy the printed h_pac_<block>_* coefficients into the matching block of au_pac.mod
```

---

## File reference

### Model files in [dynare/](dynare/)

| File | Description |
|------|-------------|
| `au_pac.mod` | Production model (self-contained: 180 endo / 53 exo / 351 params). Ends at `stoch_simul(order=1, irf=200)`. |
| `aux/aux_{pQ,consumption,business_inv,housing_inv,employment}.mod` | Per-PAC-block aux files; fed to `pac.print()` to produce the `h_pac_*` projection coefficients. |
| `regen_all_artifacts.m` | Driver: runs `dynare au_pac`, writes IRF `.mat` + peaks + panel PNGs. |

### Data / estimation files

| File | Description |
|------|-------------|
| `dataset.csv` | Core E-SAT observables, 1993Q1–2024Q4. Restore with `git show 7995ce7^:dataset.csv > dataset.csv`. |
| `data/run_all_l2_ols.m` | Driver for the 5 core PAC-block OLS estimations. |
| `data/pac_blocks/estimate_*.m` | Per-block OLS estimators. |
| `data/pac_blocks/results_*.{mat,txt}` | OLS outputs (the production coefficient source). |
| `dynare/supply_data.mat` | CES supply-side dataset for `data/estimate_ces_*.m`. |

---

## Troubleshooting

- **`matlab: command not found`** — MATLAB is not on `PATH`; call it by full path
  `/Applications/MATLAB_R2026a.app/bin/matlab`.
- **`readtable('dataset.csv')` errors** — restore it: `git show 7995ce7^:dataset.csv > dataset.csv`.
- **`dynare` not found** — `addpath('/Users/davidstephan/Applications/Dynare/7.0-arm64/matlab')` before calling `dynare`.
- **Blanchard-Kahn / eigenvalue check** — after `dynare au_pac`, inspect `oo_.dr.eigval`,
  `size(oo_.dr.ghx)`, and the printed "explosive/forward-looking" counts (a clean solve has 5 explosive eigenvalues = the number of jump variables).
- **`pac.print()` output changed after an aux edit** — that is expected; copy the new `h_pac_*` values into `au_pac.mod` (§4) and re-solve.
