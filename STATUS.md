# AUSPAC Project Status — 2026-04-12

## What this project is

Australian adaptation of the FR-BDF semi-structural macroeconomic model (Banque de France WP #736, Lemoine et al. 2019). The model replicates the FRB/US-style PAC (Polynomial Adjustment Costs) framework with explicit expectations, CES supply block, and full financial channels.

- **Model file**: `dynare/au_pac.mod` (Hybrid), `dynare/au_pac_var.mod` (VAR-based), `dynare/au_pac_mce.mod` (MCE)
- **Reference**: `wp736.pdf` (142 pages)
- **Tools**: MATLAB R2019a (`C:\Program Files\MATLAB\R2019a\bin\matlab.exe`), Dynare 6.5 (`C:\dynare\6.5\matlab`)
- **GitHub**: https://github.com/DavidAStephan/AUSPAC

## Current model state

### au_pac.mod (Hybrid) — MIGRATED TO var_model
- **~135 endogenous variables**, **~40 shocks**, **3 forward-looking variables** (pv_i, pv_u_gap, pv_yh)
- Uses enriched `var_model` (8 equations: 3 E-SAT core + 5 auxiliary gaps) for PAC h-vector computation
- h-vectors computed from 8×8 companion matrix — correct FR-BDF architecture (Section 3.1.1)
- Additive `pv_X_aux` corrections create backward/forward wedge at first-order perturbation
- BK conditions verified, compiles and solves

### au_pac_var.mod (VAR-based) — STILL ON OLD TCM INFRASTRUCTURE
- Still uses 5 separate 2-equation `trend_component_model`s (old Stage 13 architecture)
- Has `pv_X_aux` additive corrections with enriched FR-BDF-aligned auxiliary equations
- Backward AR(1) for pv_i, pv_u_gap, pv_yh (fully backward-looking)
- **NEEDS MIGRATION** to var_model (same pattern as au_pac.mod)
- Compiles and solves

### au_pac_mce.mod (Full MCE) — CORRECT AS-IS
- No auxiliary model (pac_model without auxiliary_model_name)
- No pv_X_aux terms (forward leads capture everything)
- 28 forward-looking variables
- pac_expectation() inserts forward leads directly into compiled equations
- Compiles and solves

## Three-regime IRF comparison (monetary policy shock)

| Variable | VAR-based | Hybrid | MCE | Backward/MCE ratio |
|---|---|---|---|---|
| Output gap | -0.0244% (Q4) | -0.0243% (Q4) | -0.0195% (Q4) | **1.25x** |
| VA price inflation | -0.0103% (Q6) | -0.0097% (Q6) | -0.0027% (Q4) | **3.6-3.8x** |
| Consumption | -0.0139% | -0.0134% | -0.0044% | **3.0-3.2x** |
| Business investment | -0.0296% | -0.0286% | -0.0067% | **4.3x** |
| Housing investment | -0.0380% | -0.0367% | -0.0066% | **5.5-5.7x** |
| Employment | -0.0187% (Q7) | -0.0181% (Q7) | -0.0032% (Q4) | **5.7-5.9x** |

## PAC Auxiliary Architecture (KEY INSIGHT)

### FR-BDF approach (correct)
Auxiliary equations are **appended to the E-SAT VAR**, enlarging the companion matrix H. The h-vectors k₀ = f(PAC polynomial, E-SAT dynamics, auxiliary coefficients) are a SINGLE linear function of ALL state variables. See `ESAT_AUXILIARY_ARCHITECTURE.md`.

### Our implementation (hybrid approach)
1. **var_model** (`esat_enriched`): 8-equation VAR with E-SAT core + 5 auxiliary gap equations. Companion matrix is 8×8. `pac_expectation()` computes h-vectors from this enlarged matrix. This is structurally correct.
2. **pv_X_aux additive terms**: Dynamic AR(1) processes with output gap, interest rate, and inflation gap channels. These provide the first-order backward/forward wedge that would otherwise vanish (at first-order perturbation, h-vectors and RE solution coincide mathematically).

### Why both are needed
At first-order perturbation, `pac_expectation()` h-vectors from ANY companion matrix produce the same RE solution. The pv_X_aux terms represent the DIFFERENCE between E-SAT simplified forecasts and the full model RE — this is what creates the visible three-regime differences in IRFs.

## Key reference documents

| Document | Content |
|----------|---------|
| `dynare/AU_PAC_MODEL_DOCUMENTATION.md` | ~1500-line FR-BDF-style documentation |
| `dynare/FULL_MODEL_COMPARISON.md` | Complete equation-by-equation AU-PAC vs FR-BDF |
| `dynare/PAC_COEFFICIENT_COMPARISON.md` | Every coefficient compared with FR-BDF tables |
| `dynare/ESAT_AUXILIARY_ARCHITECTURE.md` | How FR-BDF auxiliary equations work |
| `dynare/DIAGNOSIS_THREE_REGIME_IRFS.md` | Root cause analysis of identical IRFs |
| `dynare/PLAN_FIX_THREE_REGIMES.md` | Implementation plan for three-regime fix |

## Remaining work

| Priority | Task | Status |
|---|---|---|
| 1 | **Migrate au_pac_var.mod to var_model** | In progress — same pattern as au_pac.mod |
| 2 | Fix sequential Dynare run issue in test_all_three.m | Workspace conflict between runs |
| 3 | Regenerate three-regime comparison plots | After var_model migration |
| 4 | Re-estimate PAC parameters with Australian data | Using pac.estimate.iterative_ols() |
| 5 | Long-run output level (Q/QN) | eq 43 — currently growth-rate only |
| 6 | Energy/non-energy import split | eqs 88-91 |

## Technical notes

- Dynare 6.5 does NOT accept `noprint` as a preprocessor argument (only as stoch_simul option)
- `var_model` PAC requires `pac.initialize()` + `pac.update.expectation()` calls before stoch_simul
- Multiple `pac_model` declarations CAN share one `var_model` (tested and working)
- Legend `'center'` not valid in R2019a — use `'best'` instead
- MATLAB batch mode: `"C:/Program Files/MATLAB/R2019a/bin/matlab.exe" -batch "..."`
