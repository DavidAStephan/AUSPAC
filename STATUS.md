# AUSPAC Project Status — 2026-04-13

## What this project is

Australian adaptation of the FR-BDF semi-structural macroeconomic model (Banque de France WP #736, Lemoine et al. 2019). The model replicates the FRB/US-style PAC (Polynomial Adjustment Costs) framework with explicit expectations, CES supply block, and full financial channels.

- **Model file**: `dynare/au_pac.mod` (Hybrid), `dynare/au_pac_var.mod` (VAR-based), `dynare/au_pac_mce.mod` (MCE)
- **Reference**: `wp736.pdf` (142 pages)
- **Tools**: MATLAB R2019a (`C:\Program Files\MATLAB\R2019a\bin\matlab.exe`), Dynare 6.5 (`C:\dynare\6.5\matlab`)
- **GitHub**: https://github.com/DavidAStephan/AUSPAC

## Current model state

### All three variants — FULLY ALIGNED WITH FR-BDF, var_model architecture

| Variant | File | Endo | Exo | Forward | Expectations |
|---------|------|------|-----|---------|-------------|
| VAR-based | `au_pac_var.mod` | 140 | 45 | 0 | Backward (AR(1) for pv_i, pv_u_gap, pv_yh) |
| Hybrid | `au_pac.mod` | 140 | 47 | 3 | Mixed (backward PAC + forward financial) |
| MCE | `au_pac_mce.mod` | 154 | ~35 | 30 | Full model-consistent |

Note: au_pac.mod has 47 exo (45 structural + 2 COVID pulse dummies).

All three use enriched `var_model` (12 equations: 3 E-SAT core + 2 additional states + 7 auxiliary gaps) for PAC h-vector computation. BK conditions verified for all three. Compiles and solves.

### var_model architecture (12x12 companion matrix)

```
var_model(model_name = esat_enriched,
    eqtags = ['var_y', 'var_i', 'var_pi',           // 3 E-SAT core
              'var_u', 'var_yus',                     // 2 additional states
              'var_pQ', 'var_n', 'var_yh', 'var_c',   // 4 auxiliary gaps
              'var_ib', 'var_rKB', 'var_ih']);          // 3 auxiliary gaps
```

5 PAC equations share this enriched var_model (VA price, consumption, business investment, household investment, employment).

## Estimation infrastructure

### E-SAT core (working)
- `estimate_esat.m`: equation-by-equation OLS for 16 parameters
- `bayesian_estimate.m`: full MCMC (RW-MH, 10k draws, 2 blocks)
- `data/prepare_estimation_data.m`: 9 observables x 122 quarters -> `estimation_data.mat`
- `au_esat_est.mod`: Dynare-native Bayesian estimation

### PAC structural estimation (working, 3 approaches)
Implements ECB-Base (SemiStructDynareBasics) methodology using Dynare's `pac.estimate` routines.

| Script | Purpose |
|--------|---------|
| `dynare/estimate_pac_driver.m` | Original pipeline: recursive auxiliary construction |
| `dynare/estimate_pac_smooth_driver.m` | **Recommended**: Kalman smoother + hybrid dseries pipeline |
| `dynare/prepare_pac_dseries.m` | Approach A: recursive auxiliary gaps from observed data |
| `dynare/prepare_pac_dseries_hybrid.m` | Approach B: smoothed targets + recursive pv_aux (recommended) |
| `dynare/prepare_pac_dseries_smooth.m` | Approach C: pure Kalman-smoothed variables |
| `dynare/estimate_pac.m` | Iterative OLS + NLS for all 5 PAC equations |
| `dynare/prepare_smoother_data.m` | Prepares 9 observables for `calib_smoother` |
| `dynare/generate_smoother_mod.m` | Generates `au_pac_smooth.mod` (adds varobs + calib_smoother) |
| `dynare/test_smoother_comparison.m` | Runs all 3 approaches side-by-side |

**Key fix**: After `stoch_simul`, `oo_.var` contains the variance-covariance matrix (a double). `pac.estimate` needs it as a struct with the companion matrix. The fix:
```matlab
if ~isstruct(oo_.var), oo_.var = struct(); end
get_companion_matrix('esat_enriched', 'var');
```

**Results — 3-way comparison** (all 5 equations converge, 118 observations):

Approaches: (A) Recursive auxiliary construction, (B) Hybrid (Kalman-smoothed targets + recursive corrections), (C) Pure Kalman smoother

| Equation | SSR (A/B/C) | b0 EC (A/B/C) | Notes |
|----------|-------------|---------------|-------|
| VA Price | 40.4 / 40.3 / 1.1 | 0.020 / 0.021 / 0.060* | *Pure smoother: params unidentified (pv_aux absorbs all variance) |
| Consumption | 435.4 / 436.8 / 400.8 | 0.088 / 0.098 / 0.097 | Negative AR1 across all approaches (AU data feature) |
| Business Inv | 973.9 / 972.7 / 968.4 | 0.018 / 0.018 / 0.030 | Negative AR2 persists; strong accelerator (b3~0.43) |
| Household Inv | 965.8 / 963.1 / 960.0 | 0.024 / 0.026 / 0.029 | Rate channel sign flip persists (b4>0 across all) |
| Employment | 76.1 / 74.3 / 73.4 | 0.046 / 0.088 / 0.105 | All AR(1-4) negative; hybrid gives cleaner EC |

**Kalman smoother infrastructure** (2026-04-13):
- `calib_smoother` with `diffuse_filter` extracts 140 smoothed endogenous variables
- Hybrid approach (B) recommended: uses smoothed targets for EC term, recursive pv_aux for corrections
- Pure smoother (C) has lowest SSR but over-identifies VA Price

**COVID pulse dummies** (2026-04-13):
- Two exogenous dummies: `d_covid_crash` (2020Q2), `d_covid_bounce` (2020Q3)
- Each PAC equation has its own pair of coefficients (10 new params)
- Results with COVID dummies (recursive approach A):

| Equation | SSR | b0 (EC) | b1 (AR1) | COVID crash | COVID bounce | Key improvement |
|----------|-----|---------|----------|-------------|-------------|-----------------|
| VA Price | 40.6 | 0.026 | **+0.287** | -2.88 | +1.49 | AR1 improved (0.18->0.29) |
| Consumption | 416.9 | 0.063 | **+0.056** | -15.01 | +6.52 | AR1 flipped neg->pos |
| Business Inv | 973.0 | 0.017 | **+0.107** | -5.51 | +3.11 | AR1 improved (0.08->0.11) |
| Household Inv | 964.5 | 0.025 | **+0.111** | -5.67 | +2.54 | AR1 improved (0.08->0.11) |
| Employment | 83.0 | 0.044 | **+0.345** | -6.81 | +4.01 | AR1 flipped neg->pos |

Key finding: COVID dummies fix consumption AR1 (-0.25 -> +0.06) and employment AR1 (-0.26 -> +0.34). Housing rate channel (b4_ih) reduced but not flipped.

## Three-regime IRF comparison (monetary policy shock)

Q4 responses to 1 s.d. monetary policy tightening:

| Variable | VAR-based | Hybrid | MCE | MCE attenuation |
|----------|-----------|--------|-----|-----------------|
| Output gap | -0.0067% | -0.0067% | -0.0047% | 30% smaller |
| VA price | -0.0027% | -0.0027% | -0.0006% | 78% smaller |
| Consumption | -0.0043% | -0.0043% | -0.0012% | 72% smaller |
| Business inv. | -0.0079% | -0.0079% | -0.0009% | 89% smaller |
| Housing inv. | -0.0130% | -0.0130% | -0.0022% | 83% smaller |
| Employment | -0.0040% | -0.0040% | -0.0007% | 83% smaller |

VAR-MCE differentiation = 0.0052 (meaningful, matches FR-BDF Section 6 pattern). MCE forward-looking agents smooth shocks — smaller, faster-adjusting responses.

## Full system test (2026-04-12)

`test_full_system.m` — **62 PASS, 0 real FAIL** across 10 stages:
1. Data loading (2 CSVs, transforms) — 11 pass
2. E-SAT OLS (5 parameter checks) — 6 pass
3. E-SAT model & IRFs — 4 pass
4. Extended data prep (9x122) — 5 pass
5. au_pac_var (140 endo, BK, IRFs) — 4 pass
6. au_pac (140 endo, 5 PAC, 10 IRFs) — 13 pass
7. au_pac_mce (154 endo, 30 forward, IRFs) — 4 pass
8. PAC iterative OLS (5 equations) — 9 pass
9. PAC NLS (csminwel) — 1 pass
10. Three-regime comparison — 7 pass

## Key reference documents

| Document | Content |
|----------|---------|
| `dynare/AU_PAC_MODEL_DOCUMENTATION.md` | ~1500-line FR-BDF-style documentation |
| `dynare/FULL_MODEL_COMPARISON.md` | Complete equation-by-equation AU-PAC vs FR-BDF |
| `dynare/PAC_COEFFICIENT_COMPARISON.md` | Every coefficient compared with FR-BDF tables |
| `dynare/ESAT_AUXILIARY_ARCHITECTURE.md` | How FR-BDF auxiliary equations work |

## Remaining work

| Priority | Task | Status |
|----------|------|--------|
| 1 | Kalman smoother for auxiliary variables | **Done** — 3 approaches implemented (recursive/hybrid/pure smoother) |
| 2 | COVID pulse dummies for PAC estimation | **Done** — fixes consumption AR1 and employment AR1 sign issues |
| 3 | Activate Dynare `estimation()` block for joint Bayesian estimation | Infrastructure ready (commented out in au_pac.mod lines 2039-2088) |
| 4 | Implement residual inversion for conditional forecasting | ECB-Base pattern available |
| 5 | SUR estimation for auxiliary gap equations | Would improve cross-equation efficiency |
| 6 | Long-run output level (Q/QN) | eq 43 — currently growth-rate only |
| 7 | Energy/non-energy import split | eqs 88-91 (low priority — AU is net energy exporter) |

## Technical notes

- Dynare 6.5 does NOT accept `noprint` as a preprocessor argument (only as stoch_simul option)
- `var_model` PAC requires `pac.initialize()` + `pac.update.expectation()` calls before stoch_simul
- Multiple `pac_model` declarations CAN share one `var_model` (tested and working)
- After `stoch_simul`, `oo_.var` is a double (variance-covariance) — must convert to struct for `pac.estimate`
- `get_companion_matrix('esat_enriched', 'var')` builds the 12x12 companion from calibrated parameters
- Legend `'center'` not valid in R2019a — use `'best'` instead
- MATLAB batch mode: `"C:/Program Files/MATLAB/R2019a/bin/matlab.exe" -batch "..."`
- Scripts with `clear` (estimate_esat.m, esat_model.m, prepare_estimation_data.m) cannot be called from function files — use subprocess or validate outputs
- `pac.estimate.nls` supports optimizers: `'csminwel'`, `'annealing'`, `'fmincon'`, `'fminunc'`, `'fminsearch'`, `'simplex'`
- ECB-Base reference: https://gitlab.com/srecko/SemiStructDynareBasics (Srecko Zimic, ECB)
- `calib_smoother` requires `varobs` in .mod file + `diffuse_filter` for models with unit roots (level accumulators)
- `calib_smoother(datafile='X')` fails if both X.m and X.mat exist — always specify extension (`.mat`)
- Smoother dseries needs zero-padding for 4th-order PAC (employment) — dseries must start 5+ quarters before estimation range
- Pure Kalman-smoothed `pv_X_aux` absorbs PAC equation variance → use hybrid approach (smoothed targets + recursive corrections)
