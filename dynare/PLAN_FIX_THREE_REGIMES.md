# Plan: Fix Three-Regime Expectation Differences

## Problem
All 3 model files (VAR, Hybrid, MCE) produce identical IRFs for output, consumption, investment, employment, and VA price inflation because the PAC `trend_component_model` auxiliary equations are too simple (2 equations each) — the backward h-vectors mathematically equal the forward MCE solution.

## Root Cause
The TCM companion matrix has dimension 2x2 (one EC equation + one target random walk). The h-vectors from this system don't depend on E-SAT state variables (output gap, interest rate, inflation). The backward policy function is identical to the RE solution.

## Failed Approach
Enriching TCMs with E-SAT core equations failed because:
- TCM requires strict EC structure: `diff(X) = A0*(X(-1) - C0*Z(-1)) + ...`
- E-SAT core equations (IS curve, Phillips, Taylor) are AR(1) processes, not EC equations
- Dynare rejects them: "LHS variable should not appear with a multiplicative constant in error correction term"

## Correct Approach: Manual E-SAT Policy Functions

### For au_pac.mod (Hybrid) and au_pac_var.mod (VAR-based):

1. **Keep the TCMs** — they provide the PAC structural parameters (EC speed, AR lags, discount factor) needed to compute h-vectors.

2. **Replace `pac_expectation()` in the PAC equations** with explicit expectation variables that are computed as E-SAT policy functions of model state variables.

3. **Add 5 new expectation variables** (one per PAC equation):
   - `pv_piQ_star` = expected PV of VA price target changes
   - `pv_n_star` = expected PV of employment target changes  
   - `pv_c_star` = expected PV of consumption target changes
   - `pv_ib_star` = expected PV of business investment target changes
   - `pv_ih_star` = expected PV of housing investment target changes

4. **For each variable, add an auxiliary equation** that computes it as a backward AR(1) function of E-SAT state variables (FR-BDF Tables 4.4.4, 4.5.7, 4.6.3, 4.6.11-12):
   ```
   pv_piQ_star = a_pQ_1 * yhat_au(-1) + a_pQ_2 * (i_gap(-1) - pibar_au) + a_pQ_3 * piQ_star(-1)
   ```

5. **Rewrite each PAC equation** replacing `pac_expectation(pac_X)` with the explicit `pv_X_star` variable plus the growth neutrality correction:
   ```
   diff(pQ_level) = b0_pQ * (pQ_star_level(-1) - pQ_level(-1))  // EC
                  + b1_pQ * diff(pQ_level(-1))                   // AR lag
                  + pv_piQ_star                                  // manual expectation
                  + b2_pQ * yhat_au                              // ad hoc
                  + (1 - b1_pQ - omega_pQ) * piQ_star_bar(-1)   // growth neutrality
                  + eps_pQ
   ```

### For au_pac_mce.mod (Full MCE):

1. **Drop TCMs entirely** (already done — no `auxiliary_model_name`).
2. **Replace the 5 expectation variables** with forward-looking recursive PV equations (FR-BDF eqs 138-142):
   ```
   pv_piQ_star = beta0 * piQ_star + beta1 * piQ_star(+1) + beta2 * pv_piQ_star(+1) + beta3 * pv_piQ_star(+2)
   ```
3. These have leads → forward-looking → MCE solution differs from backward E-SAT policy functions.

### Key: What Creates the Wedge
- **Backward (VAR/Hybrid)**: `pv_piQ_star` depends on E-SAT state variables via a simplified model. When the output gap falls after a monetary shock, the backward agent predicts inflation will fall by `a_pQ_1 * yhat(-1)`, using the E-SAT Phillips slope. This simplified prediction differs from the full model's RE solution.
- **Forward (MCE)**: `pv_piQ_star` uses the full model's RE solution via forward leads. The prediction incorporates all channels — investment accelerator, trade competitiveness, government fiscal rule — that E-SAT misses.

## Implementation Steps

1. Revert au_pac.mod TCM changes (restore 5 separate 2-equation TCMs)
2. Add 5 new PV expectation variables  
3. Add 5 backward auxiliary equations linking PVs to E-SAT state
4. Replace pac_expectation() with manual PV + growth neutrality in PAC equations
5. Keep TCM declarations (for parameter computation) but mark pac_expectation as unused
6. Do the same for au_pac_var.mod
7. In au_pac_mce.mod: replace pac_expectation() with forward recursive PV equations
8. Test all 3 models solve
9. Run generate_three_regime_irfs.m and verify different IRFs
