# AUSPAC Project Status — 2026-04-12

## What this project is

Australian adaptation of the FR-BDF semi-structural macroeconomic model (Banque de France WP #736, Lemoine et al. 2019). The model replicates the FRB/US-style PAC (Polynomial Adjustment Costs) framework with explicit expectations, CES supply block, and full financial channels.

- **Model file**: `dynare/au_pac.mod` (Hybrid), `dynare/au_pac_var.mod` (VAR-based), `dynare/au_pac_mce.mod` (MCE)
- **Reference**: `wp736.pdf` (142 pages)
- **Tools**: MATLAB R2019a (`C:\Program Files\MATLAB\R2019a\bin\matlab.exe`), Dynare 6.5 (`C:\dynare\6.5\matlab`)
- **GitHub**: https://github.com/DavidAStephan/AUSPAC

## Current model state

### au_pac.mod (Hybrid) — FULLY ALIGNED WITH FR-BDF
- **140 endogenous variables**, **~42 shocks**, **3 forward-looking variables** (pv_i, pv_u_gap, pv_yh)
- Uses enriched `var_model` (12 equations: 3 E-SAT core + 2 additional states + 7 auxiliary gaps) for PAC h-vector computation
- **12x12 companion matrix** — comparable to FR-BDF's ~11x11 system (Section 3.1.1)
- Additional states: unemployment gap (u_gap_var), foreign output (yhat_us_var) — matching FR-BDF's 6-9 state dependencies
- Nested PV (PV²) for consumption: yh_ratio_hat → c_hat chain (FR-BDF Tables 4.6.3-4.6.4)
- Separate user cost PV for business investment: rKB_hat (FR-BDF Table 4.6.12)
- Additive `pv_X_aux` corrections with proper parameter mapping (u_gap, pi_au_gap separated)
- Sector financial accounts (Section 4.8.5, eqs 116-126): 20 variables
- BK conditions verified, compiles and solves

### au_pac_var.mod (VAR-based) — FULLY ALIGNED WITH FR-BDF
- **140 endogenous variables**, **~42 shocks**, **0 forward-looking variables**
- Same 12x12 var_model as hybrid, same auxiliary architecture
- Backward AR(1) for pv_i, pv_u_gap, pv_yh (fully backward-looking)
- Sector financial accounts included
- BK conditions verified, compiles and solves

### au_pac_mce.mod (Full MCE) — FULLY ALIGNED WITH FR-BDF
- **154 endogenous variables**, **~35 shocks**, **30 forward-looking variables**
- No auxiliary model (pac_model without auxiliary_model_name)
- Nested PV (PV²): pv2_yh = (1-beta)*pv_yh + beta*pv2_yh(+1) (FR-BDF Table 4.6.4)
- Forward user cost PV: pv_rKB = (1-beta)*dln_uc_k + beta*pv_rKB(+1) (FR-BDF eq 64)
- Sector financial accounts included
- BK conditions verified, compiles and solves

## Three-regime IRF comparison (monetary policy shock)

| Variable | VAR-based | Hybrid | MCE | Backward/MCE ratio |
|---|---|---|---|---|
| Output gap | -0.0242% (Q4) | -0.0242% (Q4) | -0.0194% (Q4) | **1.25x** |
| VA price inflation | -0.0103% (Q6) | -0.0103% (Q6) | -0.0027% (Q4) | **3.8x** |

## var_model architecture (12x12 companion matrix)

```
var_model(model_name = esat_enriched,
    eqtags = ['var_y', 'var_i', 'var_pi',           // 3 E-SAT core
              'var_u', 'var_yus',                     // 2 additional states
              'var_pQ', 'var_n', 'var_yh', 'var_c',   // 4 auxiliary gaps
              'var_ib', 'var_rKB', 'var_ih']);          // 3 auxiliary gaps
```

### FR-BDF alignment details
1. **E-SAT core** (3 eqs): IS curve, Taylor rule, Phillips curve — pure VAR(1) form
2. **Unemployment gap** (var_u): Okun's law in VAR form (FR-BDF Table 4.5.2)
3. **Foreign output** (var_yus): US output AR(1) (FR-BDF: Euro area equivalent)
4. **VA price aux** (var_pQ): Depends on ŷ, i, π, û (FR-BDF Table 4.4.4)
5. **Employment aux** (var_n): Depends on ŷ, i, π, û (FR-BDF Table 4.5.7, eq 57)
6. **Income ratio aux** (var_yh): yH-ȳ with output + unemployment (FR-BDF Table 4.6.3)
7. **Consumption PV²** (var_c): Depends on yh_ratio_hat — nested PV (FR-BDF Table 4.6.4)
8. **Investment output** (var_ib): q̂ output channel only (FR-BDF Table 4.6.11)
9. **Investment user cost** (var_rKB): r̂_KB interest rate channel (FR-BDF Table 4.6.12)
10. **Housing inv aux** (var_ih): Depends on ŷ, i, π, û (FR-BDF Table 4.6.16)

### pv_X_aux backward correction terms
Each PAC equation has an additive AR(1) correction with 4 channels:
- `a_X_y * yhat_au(-1)` — output gap
- `a_X_i * i_gap(-1)` — interest rate gap
- `a_X_pi * pi_au_gap(-1)` — inflation gap
- `a_X_u * u_gap(-1)` — unemployment gap

These create the backward/forward wedge at first-order perturbation.

## Key reference documents

| Document | Content |
|----------|---------|
| `dynare/AU_PAC_MODEL_DOCUMENTATION.md` | ~1500-line FR-BDF-style documentation |
| `dynare/FULL_MODEL_COMPARISON.md` | Complete equation-by-equation AU-PAC vs FR-BDF |
| `dynare/PAC_COEFFICIENT_COMPARISON.md` | Every coefficient compared with FR-BDF tables |
| `dynare/ESAT_AUXILIARY_ARCHITECTURE.md` | How FR-BDF auxiliary equations work |

## Remaining work

| Priority | Task | Status |
|---|---|---|
| 1 | Re-estimate PAC parameters with Australian data | Using pac.estimate.iterative_ols() |
| 2 | Long-run output level (Q/QN) | eq 43 — currently growth-rate only |
| 3 | Energy/non-energy import split | eqs 88-91 (low priority — AU is net energy exporter) |

## Technical notes

- Dynare 6.5 does NOT accept `noprint` as a preprocessor argument (only as stoch_simul option)
- `var_model` PAC requires `pac.initialize()` + `pac.update.expectation()` calls before stoch_simul
- Multiple `pac_model` declarations CAN share one `var_model` (tested and working)
- Legend `'center'` not valid in R2019a — use `'best'` instead
- MATLAB batch mode: `"C:/Program Files/MATLAB/R2019a/bin/matlab.exe" -batch "..."`
- Sequential Dynare runs: use `clearvars -except` + `clearvars -global` between models
