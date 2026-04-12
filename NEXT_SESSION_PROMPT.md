# Prompt for next Claude Code session

Paste everything below the line into a new Claude Code session.

---

Read STATUS.md. We're building a semi-structural macro model for Australia based on WP #736 (wp736.pdf in the project root). The model is in `dynare/au_pac.mod` — Dynare 6.5 at `C:\dynare\6.5\matlab`, MATLAB R2019a at `C:\Program Files\MATLAB\R2019a\bin\matlab.exe`.

## Current state

We have 3 model variants for different expectation regimes:
- `au_pac.mod` (Hybrid) — **migrated to var_model architecture** with enriched E-SAT auxiliary
- `au_pac_var.mod` (VAR-based) — **still on old trend_component_model, needs migration**
- `au_pac_mce.mod` (Full MCE) — correct as-is, no auxiliary model

The hybrid model uses a `var_model` named `esat_enriched` with 8 equations (3 E-SAT core + 5 auxiliary gaps) as the PAC auxiliary model. This correctly implements FR-BDF Section 3.1.1 where auxiliary equations are appended to the E-SAT VAR. Additionally, `pv_X_aux` additive correction terms create the backward/forward wedge at first-order perturbation.

The three regimes now produce clearly different IRFs to monetary policy (output gap ratio 1.25x, VA price 3.8x backward vs MCE). See `ESAT_AUXILIARY_ARCHITECTURE.md` for the full explanation.

## Immediate task: Migrate au_pac_var.mod to var_model

`au_pac_var.mod` still uses the old 5 separate `trend_component_model` declarations. It needs the same migration that was done to `au_pac.mod`:

1. **Replace TCM variable declarations** with var_model shadow variables (y_gap_var, i_gap_var, pi_gap_var) and auxiliary gap variables (piQ_hat, n_hat, c_hat, ib_hat, ih_hat). Keep pv_X_aux variables.

2. **Replace TCM shock declarations** (eps_e_q, eps_e_pQ_star, etc.) with var_model shocks (eps_var_y, eps_var_i, eps_var_pi, eps_var_pQ, eps_var_n, eps_var_c, eps_var_ib, eps_var_ih).

3. **Replace 5 trend_component_model + 5 pac_model declarations** with 1 `var_model(model_name = esat_enriched, eqtags = [...])` + 5 `pac_model(auxiliary_model_name = esat_enriched, ...)`.

4. **Replace 10 TCM equations** (5 EC + 5 target random walks) with 8 var_model equations (3 E-SAT core + 5 auxiliary gaps) in pure VAR(1) form.

5. **Update PAC equation EC targets** from old TCM targets (piQ_star_l, c_star_l, etc.) to new var_model auxiliary variables (piQ_hat, c_hat, etc.).

6. **Keep pv_X_aux terms** in PAC equations — these provide the first-order wedge.

7. **Add pac.initialize + pac.update.expectation calls** before stoch_simul.

8. **Update shocks block** with new var_model shock variances.

The hybrid model (`au_pac.mod`) is the working template — all the changes are identical. Key difference: au_pac_var.mod uses backward AR(1) for pv_i, pv_u_gap, pv_yh instead of forward recursive.

## After migration

1. Fix `test_all_three.m` — sequential Dynare runs have workspace conflicts. Consider saving to separate .mat files between runs (the `generate_three_regime_irfs.m` script already does this).

2. Run `generate_three_regime_irfs.m` to regenerate the comparison plots with all three models on the new architecture.

3. Update `AU_PAC_MODEL_DOCUMENTATION.md` Section 6.2 tables with final values.

## Key files

- `dynare/au_pac.mod` — Hybrid (TEMPLATE for migration, working)
- `dynare/au_pac_var.mod` — VAR-based (NEEDS MIGRATION)
- `dynare/au_pac_mce.mod` — MCE (correct, no changes needed)
- `dynare/test_var_pac.mod` — Prototype proving var_model PAC works
- `dynare/test_var_pac_multi.mod` — Prototype proving multi-PAC shared var_model works
- `dynare/ESAT_AUXILIARY_ARCHITECTURE.md` — Explains the architecture
- `dynare/PAC_COEFFICIENT_COMPARISON.md` — All coefficients compared with FR-BDF

Work step by step. After each change, verify by running: `"C:/Program Files/MATLAB/R2019a/bin/matlab.exe" -batch "cd('c:\Users\david\french_model\dynare'); addpath('C:\dynare\6.5\matlab'); dynare au_pac_var noclearall nograph"`. Use file-based logging (fopen/fprintf/fclose) since diary doesn't work well with Dynare.
