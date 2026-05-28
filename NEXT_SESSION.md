# NEXT_SESSION.md — h_pac_* policy-function regeneration

**Status at end of last session** (2026-05-28): all four architectural follow-ups (working paper update, Tier 4 verification, h_pac_* recipe, L2 OLS validation) complete and pushed to `origin/main` (latest commit `45b9f8a`). The model is structurally clean per FR-BDF — `yhat_au`, `pi_au`, `u_gap` all defined by structural identities (commits `dd45c87`, `f276ebe`, `053bf57`). Dynare BK-stable (`sdim=126, edim=5`), 100bp MP IRF peaks: `ln_Q −0.135% Q9`, `yhat_au −0.096% Q9`, `pi_au −0.004 pp Q3`, `pi_w −0.005 pp Q2`, `s_gap −0.991% Q8`.

**This session's goal**: regenerate the `h_pac_*` policy-function coefficients so they're internally consistent with the post-L2.A simulator dynamics. These coefficients embed agents' VAR-based discounted-sum forecasts of the PAC long-run targets; they currently embed an OLD VAR specification that no longer matches the runtime simulator.

---

## Why this matters

In FR-BDF (wp736 §3.1), agents form expectations of future PAC targets via a closed-form policy function obtained by inverting an assumed VAR companion matrix Φ. The result for each PAC block is a linear combination of current state variables:

```
pac_expectation_pac_X = h_pac_X_constant
                      + Σ_k h_pac_X_var_S_k_lag_1 · S_k(−1)
```

where `S_k` are the VAR state variables (yhat_au, i_gap, pi_au_gap, u_gap, piQ, pi_m, etc., plus the block's own `_hat` auxiliary regressor).

The coefficients `h_pac_X_*` are computed by Dynare's `pac.print()` macro against an aux *.mod file that specifies the VAR. **The aux *.mod files were deleted in the Phase L2.A cleanup** (`dynare/aux/aux_*.mod`), and the h-coefficients hardcoded in `au_pac.mod` (lines ~555–684) were generated against an even earlier VAR specification (pre-L2 OLS, pre-L2.A architectural). They are now stale in three ways:

1. **L2 OLS replaced 25+ structural calibrations** with AU point estimates (CPI Phillips, trade, deflators)
2. **L2.A architectural fixes** redefined `yhat_au`, `pi_au_gap`, `u_gap` as structural identities — the VAR dynamics those state variables follow are different
3. **Constrained wage Phillips** redefined `λ_w`, `γ_w`, `κ_w`

The model currently works because the h-coefficients are calibrated approximations of agents' bounded-rational forecasts — they don't need to be exactly model-consistent for the simulator to be BK-stable. But for IRF accuracy and full FR-BDF fidelity, they should be regenerated.

---

## Files affected

**Will need to be created** (reconstructed):
- `dynare/aux/aux_pQ.mod` — VA-price block aux VAR + pac_model
- `dynare/aux/aux_consumption.mod` — consumption block
- `dynare/aux/aux_business_inv.mod` — business investment block
- `dynare/aux/aux_housing_inv.mod` — housing investment block
- `dynare/aux/aux_employment.mod` — employment block

**Will be modified**:
- `dynare/au_pac.mod` — replace hardcoded `h_pac_*_constant`, `h_pac_*_var_*_lag_1` parameter assignments (lines ~555–684) with values from `pac.print()`. Update the parameter declaration block (lines ~325–410) if new VAR state variables are added or removed.

**May need to be created**:
- `dynare/regen_h_pac.m` — top-level MATLAB script that loops over the 5 blocks, runs Dynare on each aux *.mod, extracts the h-coefficients, and writes them out
- `dynare/tools/cherry_pick_h_pac.py` — Python utility to parse Dynare output and patch `au_pac.mod`

**Reference**:
- `ESAT_ARCHITECTURE_AUDIT.md` — has the regeneration recipe in the "Follow-up: h_pac_* regeneration" section
- `references/wp736.pdf` §3.1 (E-SAT), §A.0.2 (auxiliary regressions), Appendix A.1–A.3 (stability conditions, h-vector decomposition)
- `dynare/AUSPAC_WORKING_PAPER.md` §3 (Expectation Formation, PAC Framework), §6.8 (architectural fixes)

---

## Step-by-step plan

### Step 1: Estimate the VAR companion matrix Φ from current data

The L2 data layer (`data/l2_data_layer_v2.mat`) has the empirical regressors needed. The E-SAT core VAR per wp736 §3.1.1 is:

```
(1 − λ_q L) ŷ_t  = −σ_q · (i_{t−1} − π_{Q,t−1} − ī_{t−1} + π̄_{t−1}) + δ_q · ŷ_{us,t} + ε_q
(1 − λ_π L) (π_Q,t − π̄_t) = κ_π · ŷ_{t−1} + ε_π
(1 − λ_i L) (i_t − ī_t)   = (1 − λ_i) · (α_i · (π_{us,t−1} − π̄_{t−1}) + β_i · ŷ_{us,t−1}) + ε_i
... (foreign and trend equations)
```

In AU-PAC, the equivalent variables (with the L2.A architectural fix in mind) are:
- `yhat_au` — **now** the structural accumulation of yhat_dom; for the **agents' E-SAT VAR**, use the original IS-curve form (pre-L2.A) since agents are assumed to forecast via the reduced-form VAR
- `i_gap` — the Taylor rule (already structural; OK for agents)
- `pi_au_gap` — **now** definitional from structural pi_au aggregator; for **agents' E-SAT**, use the L2-OLS-estimated Phillips: `pi_au_gap = λ_π·pi_au_gap(−1) + κ_π·yhat_au(−1) + α_pc·(piQ−pibar) + ... + ε_pi` (the equation we DEMOTED at line 1071)
- `u_gap` — **now** = −ln_n_level; for agents' E-SAT, use the L2-OLS-estimated Okun (line 1217 pre-fix)

**Key insight**: the regenerated h-coefficients should be based on agents' belief structure, which can legitimately differ from the simulator's structural identities. The two design choices are:

- **(A) Pure VAR-based agents** (FR-BDF baseline): agents believe E-SAT, simulator uses structural identities. h-coefficients derived against agents' VAR. Simpler.
- **(B) MCE agents**: agents believe the structural model, h-coefficients derived against the actual model dynamics. Requires iteration. More accurate.

**Recommended starting point**: pure VAR-based agents (option A). Estimate the 8×8 E-SAT core VAR by OLS on `data/l2_data_layer_v2.mat` series, plus the block-specific aux regressors (piQ_hat for VA price, c_hat for consumption, etc., already in `au_pac.mod`).

### Step 2: Reconstruct one aux *.mod file as a template

Build `dynare/aux/aux_pQ.mod` first as the test case. Template structure:

```matlab
// dynare/aux/aux_pQ.mod
// Auxiliary VAR + PAC model for VA-price block expectation policy function

var yhat_au i_gap pi_au_gap u_gap yhat_us pi_us_gap ibar pibar_au pibar_us
    piQ pi_m dln_pcom pi_w_gap tau_GST_gap piQ_hat pQ_level;

varexo eps_var_yhat eps_var_i eps_var_pi eps_var_u eps_var_yhat_us
       eps_var_pi_us eps_var_piQ eps_var_pi_m eps_var_dln_pcom
       eps_var_pi_w eps_var_tau_GST eps_var_pQ;

parameters lambda_q sigma_q delta_q lambda_i alpha_i beta_i lambda_pi kappa_pi
           rho_pQ_aux a_pQ_y a_pQ_i a_pQ_pi a_pQ_u a_pQ_w a_pQ_GST
           b0_pQ b1_pQ beta_pac;

// === parameter values: import from au_pac.mod ===
// (use the L2-OLS-estimated values that match agents' beliefs)

model;
    // E-SAT VAR core (wp736 §3.1.1)
    [name='var_yhat']    yhat_au = lambda_q*yhat_au(-1) - sigma_q*(i_gap(-1) - pi_au_gap(-1)) + delta_q*yhat_us + eps_var_yhat;
    [name='var_i']       i_gap = lambda_i*i_gap(-1) + (1-lambda_i)*(alpha_i*pi_au_gap(-1) + beta_i*yhat_au(-1)) + eps_var_i;
    [name='var_pi']      pi_au_gap = lambda_pi*pi_au_gap(-1) + kappa_pi*yhat_au(-1) + eps_var_pi;
    // ... (other VAR equations: u_gap Okun, yhat_us AR, pi_us_gap, ibar, pibar_au, pibar_us, piQ, pi_m, dln_pcom, pi_w_gap, tau_GST_gap)

    // Block-specific auxiliary regression
    [name='var_piQ_hat'] piQ_hat = rho_pQ_aux*piQ_hat(-1) + a_pQ_y*yhat_au(-1) + a_pQ_i*i_gap(-1) + a_pQ_pi*pi_au_gap(-1) + a_pQ_u*u_gap(-1) + a_pQ_w*pi_w_gap(-1) + a_pQ_GST*tau_GST_gap(-1);

    // pQ_level placeholder (target variable; not used in VAR; needed for pac_target_info)
    [name='var_pQ_lvl']  pQ_level = pQ_level(-1) + piQ_hat - pibar_au;  // approximate
end;

var_model(model_name=var_pQ, eqtags=['var_yhat','var_i','var_pi', 'var_u', 'var_yhat_us', 'var_pi_us', 'var_ibar', 'var_pibar_au', 'var_pibar_us', 'var_piQ', 'var_pi_m', 'var_dln_pcom', 'var_pi_w', 'var_tau_GST', 'var_piQ_hat']);

pac_model(name=pac_pQ, var_model_name=var_pQ, discount=beta_pac);

pac_target_info(pac_pQ);
    target piQ_hat - pQ_level;
    auxname pac_target_pQ;
end;

pac.print(pac_pQ);
```

Run this with `dynare aux_pQ.mod`. It will produce a `+aux_pQ/+pac_expectations/+pac_pQ/evaluate.m` file (Dynare 7 layout) containing the h-coefficient expressions.

### Step 3: Extract h-coefficients from Dynare output

After `dynare aux_pQ.mod`, the policy-function expression is in `+aux_pQ/+pac_expectations/+pac_pQ/evaluate.m`. Parse this file to extract:

- `h_pac_pQ_constant` (the intercept)
- `h_pac_pQ_var_yhat_au_lag_1`, `h_pac_pQ_var_i_gap_lag_1`, ... (the lag coefficients)

There may be sparse/block variants too. Inspect the directory structure and use the one matching `au_pac.mod`'s state-variable ordering.

### Step 4: Patch au_pac.mod with the new h-coefficients

Replace the parameter assignment block at `au_pac.mod` lines ~555–684 with the new values. Format:

```matlab
// === PAC pQ block policy function (regenerated 2026-XX-XX) ===
h_pac_pQ_constant = X.XXXXXXX;
h_pac_pQ_var_yhat_au_lag_1 = X.XXXXXXX;
h_pac_pQ_var_i_gap_lag_1 = X.XXXXXXX;
// ... (one line per VAR state variable)
```

### Step 5: Repeat for the other 4 blocks

Build `aux_consumption.mod`, `aux_business_inv.mod`, `aux_housing_inv.mod`, `aux_employment.mod` following the same template. Each has a different block-specific auxiliary regressor:
- consumption: `c_hat`, `yh_ratio_hat` (note: two aux regressors)
- business_inv: `ib_hat`, `rKB_hat`
- housing_inv: `ih_hat`
- employment: `n_hat`

Run Dynare on each, extract h-coefficients, patch `au_pac.mod`.

### Step 6: Verify the regenerated model

```bash
cd dynare
/Applications/MATLAB_R2026a.app/bin/matlab -batch \
  "addpath('/Users/davidstephan/Applications/Dynare/7.0-arm64/matlab'); \
   dynare au_pac.mod; \
   fprintf('sdim=%d edim=%d irfs=%d\n', oo_.dr.sdim, oo_.dr.edim, isfield(oo_,'irfs'));"
```

Then run the paper IRF generation:
```bash
/Applications/MATLAB_R2026a.app/bin/matlab -batch \
  "run('gen_paper_irfs.m'); run('gen_paper_irf_charts.m')"
```

Compare IRF peaks against current Table 6.3 in the working paper. Differences should be **small** (a few percent on each peak) — if they're large (>20%), something is wrong with the VAR specification or the parameter import.

### Step 7: Iterate if pursuing MCE consistency (optional)

If you want full MCE: re-estimate the VAR coefficients against the simulator's actual dynamics (run a long simulation, fit VAR to model-generated series, regenerate h-coefficients). Typically converges in 2–3 iterations.

### Step 8: Update the working paper

Add a brief note in §6.8 or as a new §6.9 documenting the h-coefficient regeneration date and which blocks were updated. Update Table 6.3 if IRF peaks shifted meaningfully.

### Step 9: Commit + push

Commit message template:
```
feat: regenerate h_pac_* policy-function coefficients post-L2.A

- Reconstructed dynare/aux/aux_*.mod for 5 PAC blocks
- Ran Dynare pac.print() against L2-OLS-estimated VAR
- Replaced hardcoded h_pac_* parameter values in au_pac.mod
- IRF peaks vs pre-regen: ln_Q X% → Y%, ...
- Dynare BK satisfied (sdim=N, edim=M)
```

---

## Potential gotchas

1. **VAR ordering matters**: the h-coefficients are indexed by VAR state. If you put variables in a different order than the existing `au_pac.mod` expects (e.g., `var_yhat_au_lag_1` vs `var_yhat_us_lag_1`), the parameter lookup will silently use the wrong coefficient. Check the existing parameter declaration block (lines ~325–410) for the canonical order.

2. **Dynare 7 vs 6 differences**: `pac.print()` output format and file layout changed between Dynare versions. We use Dynare 7.0 ARM64 at `/Users/davidstephan/Applications/Dynare/7.0-arm64/matlab`. Inspect actual generated files; don't trust documentation that may be for Dynare 6.

3. **var_model state ordering**: The `var_model` block has a specific equation order. The companion-matrix Φ rows/columns follow this order. If the `pac_target_info` references `piQ_hat`, ensure piQ_hat is in the VAR.

4. **Discount factor `beta_pac`**: this is the PAC subjective discount factor (≈0.99 typically). Should match what's in `au_pac.mod`. Check the existing `beta_pac` parameter declaration.

5. **Stationarity of the VAR**: the estimated VAR Φ must have all eigenvalues inside the unit circle. The wp736 §A.1 stability conditions detail this. If the VAR is non-stationary, `pac.print()` will fail or produce garbage. The L2 OLS regressors are HP-detrended cyclical components, so should be stationary, but verify.

6. **Aux regressor for consumption has TWO `_hat` variables**: `c_hat` AND `yh_ratio_hat`. The aux *.mod file needs both in the VAR. The block's PAC equation uses `c_hat` as the target but `yh_ratio_hat` enters as a regressor of `c_hat`.

7. **Steady-state file may need updating**: if the new VAR introduces variables not in the current steady-state block (lines ~1576–1832), Dynare will error out on `steady`.

8. **Existing `wt_H_real_gap` exception**: per the comment at au_pac.mod:597, `wt_H_real_gap` is in the var_model state but `c_hat` doesn't load on it directly. This was a workaround for a `pac.print()` crash. Test whether the same crash happens with the new VAR; if so, replicate the workaround.

---

## Success criteria

- [ ] All 5 aux *.mod files exist and run cleanly under Dynare 7.0
- [ ] h-coefficient extraction script works (manual is OK, automated is nicer)
- [ ] `au_pac.mod` recompiles BK-stable (sdim+edim accounts for all forward-looking variables)
- [ ] IRF peaks in Table 6.3 shift by less than ~20% (small shifts indicate the L2.A architectural fix was already approximately consistent with the existing h_*)
- [ ] Working paper §6.8 mentions the regeneration date

If IRF peaks shift dramatically (>20%), something is wrong — investigate before committing. Likely culprit: VAR specification difference or parameter import bug.

---

## Time estimate

- **Step 1–4 (one block, VA-price as proof-of-concept)**: 3–4 hours
- **Step 5 (other 4 blocks)**: 2–3 hours per block ≈ 8–12 hours
- **Step 6–9 (verification, paper update, commit)**: 1–2 hours
- **Total**: 12–18 hours, 2 working days

If MCE iteration is also pursued (Step 7), add 1–2 more iterations × 4 hours = 4–8 hours.

---

## Bail-out plan

If the regeneration proves intractable (e.g., Dynare's `pac.print()` doesn't work with the new VAR specification, or the resulting h_pac_* produce a BK-unstable model), the fallback is to **leave the current calibrated h-coefficients in place** with a clearer documentation note. The model is currently BK-stable and produces sensible IRFs — perfection here is not strictly required.

A middle ground: regenerate **just the VA-price block** as a proof-of-concept, document the procedure that worked, and defer the other 4 blocks to a follow-up session.
