# Prompt for next Claude Code session

Paste everything below the line into a new Claude Code session.

---

Read STATUS.md. We're building a semi-structural macro model for Australia based on WP #736 (wp736.pdf in the project root). The model is in `dynare/au_pac.mod` — Dynare 6.5 at `C:\dynare\6.5\matlab`, MATLAB R2019a at `C:\Program Files\MATLAB\R2019a\bin\matlab.exe`.

## Current state

All 3 model variants compile, solve, and produce correct IRFs:
- `au_pac.mod` (Hybrid) — 140 endo, var_model architecture
- `au_pac_var.mod` (VAR-based) — 140 endo, var_model architecture  
- `au_pac_mce.mod` (Full MCE) — 154 endo, 30 forward vars

PAC structural estimation is working via 3 approaches:
- **Approach A** (Recursive): `estimate_pac_driver.m` — original, crude recursive auxiliary construction
- **Approach B** (Hybrid, recommended): `estimate_pac_smooth_driver.m` — Kalman-smoothed auxiliary targets + recursive pv_aux corrections
- **Approach C** (Pure Smoother): all variables from `calib_smoother` — lowest SSR but VA Price parameters unidentified

Full system test (`test_full_system.m`) passes 62/62 real tests across 10 stages.
Three-way comparison (`test_smoother_comparison.m`) runs all approaches side-by-side.

## 3-way estimation comparison (2026-04-13)

| Equation | SSR (A/B/C) | b0 EC (A/B/C) | Key issue |
|----------|-------------|---------------|-----------|
| VA Price | 40.4/40.3/1.1 | 0.020/0.021/0.060* | *C: params stuck at initial (over-identification) |
| Consumption | 435/437/401 | 0.088/0.098/0.097 | Negative AR1 (-0.25) across all approaches |
| Business Inv | 974/973/968 | 0.018/0.018/0.030 | Negative AR2 (-0.05); strong accelerator (b3~0.43) |
| Household Inv | 966/963/960 | 0.024/0.026/0.029 | Interest rate sign flip (b4>0 across all) |
| Employment | 76/74/73 | 0.046/0.088/0.105 | All AR(1-4) negative; hybrid gives cleaner EC |

## Immediate next task: Diagnose parameter sign issues

The negative AR coefficients and wrong-signed interest rate effects persist across ALL 3 dseries approaches. This is NOT a methodology artifact — it's a data feature. Possible causes:

1. **COVID period** (2020Q1-2021Q2): extreme outliers in dln_n (-6%), dln_ib, dln_ih may dominate OLS
   - Try: estimate on pre-COVID sample (1994Q2-2019Q4) to see if signs normalize
   - Try: add COVID dummies to the PAC equations

2. **Variable-rate mortgage transmission**: AU has mostly variable-rate mortgages unlike FR fixed-rate
   - The positive b4_ih might reflect that rate hikes → existing homeowners refinance → construction activity (short-run positive, long-run negative)
   - Or: the i_gap measure doesn't capture the mortgage spread properly

3. **Identification**: the enriched var_model (12 equations) may create too many correlated regressors
   - The pac_expectation h-vectors are linear combinations of ALL 12 VAR states
   - With pv_aux also a linear combination of the same states, multicollinearity is likely

4. **Sample-dependent estimation**: Try Bayesian estimation (Option C from STATUS.md) with informative priors centered on FR-BDF values — priors would regularize the sign issues

## Key files

| File | Purpose |
|------|---------|
| `dynare/estimate_pac_smooth_driver.m` | Recommended pipeline (hybrid approach) |
| `dynare/test_smoother_comparison.m` | Runs all 3 approaches side-by-side |
| `dynare/prepare_pac_dseries_hybrid.m` | Hybrid dseries (smoothed targets + recursive corrections) |
| `dynare/au_pac.mod` lines 2039-2088 | Commented-out Bayesian estimation block |

## Running

```matlab
cd('c:\Users\david\french_model\dynare')
addpath('C:\dynare\6.5\matlab')
estimate_pac_smooth_driver   % hybrid approach (recommended)
test_smoother_comparison     % all 3 approaches
```

Work step by step. Use file-based logging (fopen/fprintf/fclose) since diary doesn't work well with Dynare.
