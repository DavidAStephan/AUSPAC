# Prompt for next Claude Code session

Paste everything below the line into a new Claude Code session.

---

Read STATUS.md and the plan at `.claude/plans/stateful-mapping-puzzle.md`. We're building a semi-structural macro model for Australia based on WP #736 (wp736.pdf in the project root). The model is in `dynare/au_pac.mod` — 76 variables, 69 equations (before Dynare auxiliary expansion), Dynare 6.5 at `C:\dynare\6.5\matlab`, MATLAB R2019a.

## What's done

We successfully migrated the **VA price PAC equation** from simplified AR(1) expectations to Dynare's native `pac_expectation()` using a `trend_component_model` (TCM). The model compiles, BK conditions pass, and h-vectors are computed from the TCM companion matrix.

The working pattern (hard-won after ~19 iterations of debugging):

1. **TCM declaration** (before `model;` block):
```dynare
trend_component_model(model_name = esat_tcm,
    eqtags = ['eq_tcm_piQ_ec', 'eq_tcm_piQ_target'],
    targets = ['eq_tcm_piQ_target']);
pac_model(auxiliary_model_name = esat_tcm, discount = beta_pac, model_name = pac_pQ, growth = piQ_star_l(-1));
```

2. **TCM equations** (inside `model;` block) — exactly 2 equations:
   - Non-target EC: `diff(piQ_aux_l) = b0_pQ * piQ_star_l(-1) - piQ_aux_l(-1) + b1_pQ * diff(piQ_aux_l(-1)) + eps_e_q;`
   - Target (random walk): `piQ_star_l = piQ_star_l(-1) + eps_e_pQ_star;`

3. **Main PAC equation** uses `pac_expectation()` and references the TCM target in the EC term:
```dynare
diff(pQ_level) = b0_pQ * (piQ_star_l(-1) - pQ_level(-1))
                 + b1_pQ * diff(pQ_level(-1))
                 + pac_expectation(pac_pQ)
                 + b2_pQ * yhat_au
                 + eps_pQ;
```

4. **`pac.initialize('pac_pQ'); pac.update.expectation('pac_pQ');`** called BEFORE `steady;`

Key gotchas discovered:
- `pac_model` discount must be a **parameter name**, not a float literal
- TCM non-target equations need `diff()` on LHS
- TCM EC term: the LHS variable `x(-1)` must appear with coefficient exactly `-1` (unit EC), not `b*x(-1)`
- The main PAC equation EC term must reference the **TCM target variable** (`piQ_star_l`), not a separate model variable (`pQ_star_level`)
- Detrended level variables (`pQ_level`, `pQ_star_level`) needed because Dynare PAC requires `diff()` on LHS; these have SS = 0 in the gap model
- `piQ = diff(pQ_level) + pi_ss_au` links back to the rest of the model

## What's next

Migrate the remaining 4 PAC equations to use `pac_expectation()`, following the same TCM pattern. Each equation needs:
1. Its own TCM (2 equations: auxiliary EC + target random walk)
2. Its own `pac_model` declaration
3. A detrended level variable pair (actual + target)
4. The main PAC equation rewritten with `pac_expectation()`

The order should be:
1. **Consumption** (1st-order PAC, `dln_c` → `diff(ln_c_level)`)
2. **Business investment** (2nd-order PAC, `dln_ib` → `diff(ln_ib_level)`)
3. **Household investment** (2nd-order PAC, `dln_ih` → `diff(ln_ih_level)`)
4. **Employment** (4th-order PAC, `dln_n` → `diff(ln_n_level)`)

For each: create `xxx_aux_l` (TCM auxiliary), `xxx_star_l` (TCM target), `xxx_level` (main model detrended level). Add 2 TCM equations, rewrite the main PAC equation, update SS, add shocks.

After all 5 PAC equations are migrated, compare IRFs to the pre-migration baseline and to the FR-BDF paper Section 5.2 benchmarks. The expectations amplification should make the IRF magnitudes larger (closer to FR-BDF).

Reference files:
- `C:\dynare\6.5\examples\pacmodel.mod` — Dynare PAC syntax reference
- `https://gitlab.com/srecko/SemiStructDynareBasics` — full semi-structural example
- Plan: `.claude/plans/stateful-mapping-puzzle.md`

Work step by step. After each equation migration, test with `dynare au_pac noclearall nograph` to verify compilation and BK conditions. Update STATUS.md when done.
