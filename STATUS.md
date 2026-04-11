# AUSPAC Project Status — 2026-04-11

## What this project is

Australian adaptation of the FR-BDF semi-structural macroeconomic model (Banque de France WP #736, Lemoine et al. 2019). The model replicates the FRB/US-style PAC (Polynomial Adjustment Costs) framework with explicit expectations, CES supply block, and full financial channels.

- **Model file**: `dynare/au_pac.mod`
- **Reference**: `wp736.pdf` (142 pages)
- **Tools**: MATLAB R2019a, Dynare 6.5
- **GitHub**: https://github.com/DavidAStephan/AUSPAC

## Current model state

**131 equations** (95 before Dynare auxiliaries), **41 shocks**, **2 forward-looking variables**, BK conditions verified.

All 5 PAC equations use Dynare's native `pac_expectation()` with `trend_component_model` (TCM) companions. The model has a CES production function (sigma = 0.53) with consistent factor demand targets, capital accumulation, decomposed WACC, forward-looking permanent income and unemployment expectations.

## Paper coverage audit

| Paper section | Topic | Status | Key equations |
|---|---|---|---|
| 3.1 | E-SAT expectation satellite model | Done | 8-equation structural VAR, Bayesian estimated |
| 3.2 | PAC framework | Done | All 5 PAC equations use native `pac_expectation()` |
| 4.3 | CES production function | Done | sigma_ces=0.53, capital accumulation (eq 32), growth-rate form |
| 4.3.2 | Factor demand targets | Done | Employment (eq 55), investment (eq 63), VA price (eq 38) all use sigma_ces |
| 4.4 | VA price (factor price frontier) | Done | CES unit cost dual with ULC + user cost channels |
| 4.5.1 | Wage Phillips curve | Done | Forward PV of unemployment gap, hybrid indexation, productivity trend |
| 4.5.2 | Employment demand (PAC) | Done | 4th-order PAC, labor hoarding via pac_expectation() |
| 4.6.1 | Consumption (PAC) | Done | Permanent income PV (beta=0.95), bank lending rate, HtM proxy |
| 4.6.2 | Business investment (PAC) | Done | 2nd-order PAC, CES user cost sensitivity, output accelerator |
| 4.6.3 | Household investment (PAC) | Done | 2nd-order PAC, mortgage rate, housing price Tobin's Q |
| 4.6.4 | External trade | Done | Exports ECM + imports ECM with IAD weights |
| 4.7 | Demand deflators | Done | 6 ECM equations with import price channels |
| 4.8.1 | Short-term interest rate | Done | Taylor rule (E-SAT core) |
| 4.8.2 | Long-term government rate | Done | Term structure with term premium AR(1) |
| 4.8.3 | Private interest rates / WACC | Done | 3-component WACC (COE, bank lending, BBB), each with AR(1) spread |
| 4.8.4 | Exchange rates (UIP) | Done | Modified UIP with inflation differential |
| 4.9 | Government + GDP identity | Done | Fiscal rule + expenditure identity |
| 5.2 | Impulse responses | Done | IRF comparison scripts for monetary, TFP, commodity shocks |
| 6 | MCE / forward expectations | Partial | h-vectors from TCM; forward PV for unemployment and income |

## Implementation stages

### Stage 0: E-SAT VAR (pure MATLAB)
- 5 core equations (IS, Taylor, Phillips for AU/US) + 3 anchor equations
- Bayesian MCMC estimation (50k draws), stable eigenvalues
- Files: `estimate_esat.m`, `bayesian_estimate.m`, `esat_model.m`, `dataset.csv`

### Stages 1-7: Building the Dynare model block by block
Built up from E-SAT core to 53 variables / 27 shocks:
- **Stage 2**: VA price PAC equation
- **Stage 3**: Wage Phillips curve + employment PAC (4th-order)
- **Stage 4**: Consumption (1st-order) + business investment (2nd-order) + housing investment (2nd-order) PAC
- **Stage 5**: Term structure, WACC, UIP exchange rate, exports/imports ECM
- **Stage 6**: 6 demand deflator ECMs, government fiscal rule, GDP expenditure identity
- **Stage 7**: Feedback loops (bridge equation, WACC->investment, mortgage->housing, income->consumption)

### Stage 8: Bayesian Estimation
- 9 observables, 24 estimated parameters, mode_compute=4
- 50k MH draws x 2 chains, converged (Geweke + Brooks-Gelman)
- Key findings: wages more forward-looking (lambda_w: 0.55->0.25), steeper Phillips curve (kappa_w: 0.10->0.24), demand bridge 4x stronger (lambda_dom: 0.10->0.41)
- Parameters updated to posterior means

### Stage 9: Supply Block + Wage-Price Spiral
- TFP process, productivity growth, unit labor cost
- Wage-price spiral: demand -> output gap -> wages -> ULC -> VA prices -> real wages -> demand
- Employment target from inverted production function

### Stages 10-11: Equation Upgrades + Validation
- User cost of capital (wacc + depreciation - capital gains)
- Commodity price channel (Australia-specific)
- IRF comparison and expectation experiment scripts

### Stage 12: Equation Audit (14 fixes)
- Real wage gap for employment target, IAD for imports, UIP inflation differential
- Household bank lending rate, housing prices, government deflator from wages
- Import price channels in all deflators

### Stage 13: Native Dynare PAC Expectations (5/5 migrated)
All 5 PAC equations migrated from manual `omega*target` to Dynare's `pac_expectation()`:

| PAC equation | Order | TCM model | h-vector / manual omega |
|---|---|---|---|
| VA price | 1st | `esat_tcm` | 0.452 / ~0.45 (1.0x) |
| Consumption | 1st | `c_tcm` | 0.678 / 0.369 (**1.84x**) |
| Business investment | 2nd | `ib_tcm` | 0.501 / 0.350 (**1.43x**) |
| Household investment | 2nd | `ih_tcm` | 0.569 / 0.300 (**1.90x**) |
| Employment | 4th | `n_tcm` | 0.446 / 0.300 (**1.49x**) |

h-vectors 1.4-1.9x larger than manual weights, confirming FR-BDF Section 6 prediction that forward expectations amplify monetary transmission.

### Stage 14: CES Production Function + Structural Upgrades
- **CES elasticity** (`sigma_ces = 0.53`): unified parameter governing employment target, investment target, and VA price target
- **Capital accumulation** (eq 32): `dln_k = (1-delta_k)*dln_k(-1) + delta_k*dln_ib` — capital as state variable
- **Production function**: `dln_y_star = alpha_k*dln_k + (1-alpha_k)*dln_n_star_bar + dln_tfp`
- **Investment target** (eq 63): `dln_ib_star_bar = kappa_ib_y*yhat_au - sigma_ces*dln_uc_k`
- **VA price target** (CES unit cost dual): `piQ_star = ... + gamma_ulc*dln_ulc + gamma_uck*dln_uc_k + ...`
- **WACC decomposition** (eq 98): `wacc = 0.5*i_COE + 0.3*i_LB_firms + 0.2*i_BBB`, each with AR(1) spread
- **Forward unemployment PV** (eq 52): `pv_u_gap = (1-0.98)*u_gap + 0.98*pv_u_gap(+1)` in wage Phillips curve
- **Permanent income** (eqs 59-61): `pv_yh = (1-0.95)*yhat_au + 0.95*pv_yh(+1)` — high discount avoids forward guidance puzzle

## Remaining gaps vs paper

| Priority | Gap | Paper ref | Notes |
|---|---|---|---|
| 1 | Long-run output level (Q/QN) | eq 43 | Currently growth-rate only; output gap IS-curve driven |
| 2 | Energy/non-energy import split | eqs 88-91 | Single import deflator currently |
| 3 | Minimum wage in wage equation | eq 52 | Less relevant for AU than France |
| 4 | Wealth effect in consumption | eq 59 | Not significant on AU data |
| 5 | Full PAC rate gap expressions | various | Simplified to `i_gap` for PAC parser |

## Australia vs France adaptations

- Australia has own central bank: Taylor rule reacts to domestic variables
- US replaces euro area as foreign bloc
- RBA cash rate (~4.2% mean) replaces Euribor
- Inflation target: 2.5% (RBA midpoint) vs 1.9% (ECB)
- Floating AUD/USD exchange rate vs fixed-within-eurozone
- Variable-rate mortgages: strongest housing channel of any demand component
- Commodity price channel: AU-specific (mining exports, terms of trade)

## Technical notes

- Dynare 6.5 at `C:\dynare\6.5\matlab`
- `stoch_simul` requires `noprint` due to Dynare 6.5 `subst_auxvar` bug with many diff() auxiliaries
- 5 `pac.initialize()` + `pac.update.expectation()` calls before `steady;`
- Git remote: https://github.com/DavidAStephan/AUSPAC.git
