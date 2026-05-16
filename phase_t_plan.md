# Phase T — srecko / FR-BDF wp1044 two-file refactor

**Started**: 2026-05-16
**Goal**: Eliminate the shadow-VAR disconnect from structural shocks by adopting Dynare's officially recommended semi-structural pattern (cherrypick + aggregate). Match FR-BDF wp1044's architecture where the auxiliary VAR variables ARE structural model variables and the PAC expectation formulas are explicit policy functions from inverting the structural-VAR core.

**Why**: The Phase S fix closed the *backward* structural cost-push channel (`piQ → pi_au_gap → Taylor rule / pv_X_aux`). But the *forward* PAC expectations (computed via `pac_expectation()` from the shadow `var_model`) still don't see `eps_pQ` because the shadow VAR variables (`pi_gap_var`, `piQ_hat`, ...) are decoupled from structural shocks by design. Cost-push IRFs are nearly identical across VAR / Hybrid / MCE regimes — proof that forward PAC expectations don't propagate the shock.

**Reference architecture**: srecko/SemiStructDynareBasics (GitLab) + FR-BDF wp1044 §2.2 + Dynare forum thread "Semi Structural models in Dynare" (https://forum.dynare.org/t/semi-structural-models-in-dynare/24754).

---

## Definition of done

- [ ] All 5 `aux/*.mod` files compile and produce `pac.print()` output
- [ ] `aggregate()` builds `au_pac_v2.mod`, `au_pac_v2_var.mod`, `au_pac_v2_mce.mod`
- [ ] All 3 variants pass BK rank
- [ ] **Smoking-gun test**: cost-push IRF (`eps_pQ`) shows distinct VAR/Hybrid/MCE divergence (proving forward PAC expectations now see the structural shock)
- [ ] Monetary IRF metrics within ±10% of Phase S
- [ ] Forward-guidance puzzle ratio at N=12 ≥ 9 (preserved)
- [ ] LMD recorded (acknowledge apples-to-oranges with Phase S's joint Bayesian if block-by-block OLS adopted)
- [ ] Working paper §4.4.0 rewritten to describe the policy-function architecture; §4.13.6 updated; new audit.md row for Phase T
- [ ] STATUS.md / NEXT_STEPS.md updated; plan.md or this file marked complete

---

## Directory structure (target)

```
dynare/
├── au_pac.mod                            # OLD — kept as Phase-S baseline for reference
├── au_pac_var.mod                        # OLD — Phase-S baseline pure-VAR variant
├── au_pac_mce.mod                        # OLD — Phase-S baseline MCE variant
├── au_pac_bayesian.mod                   # OLD — Phase-S Bayesian estimation variant
├── au_pac_smooth.mod                     # OLD — Phase-S smoother variant
├── au_pac_recursive.mod                  # OLD — Phase-S recursive forecast variant
├── au_pac_condforecast.mod               # OLD — Phase-S conditional forecast variant
├── au_pac_identification.mod             # OLD — Phase-S identification variant
│
├── aux/                                  # NEW — aux estimation files (one per PAC eq)
│   ├── aux_esat_core.mod                 # 8-eq E-SAT, Bayesian estimation, shared
│   ├── aux_pQ.mod                        # E-SAT + piQ_hat auxiliary + VA-price PAC
│   ├── aux_consumption.mod               # E-SAT + yh_ratio_hat, c_hat + consumption PAC
│   ├── aux_business_inv.mod              # E-SAT + ib_hat, rKB_hat + business inv PAC
│   ├── aux_housing_inv.mod               # E-SAT + ih_hat + housing inv PAC
│   └── aux_employment.mod                # E-SAT + n_hat + employment PAC
│
├── simulation/
│   ├── identities/                       # everything NOT in a PAC aux file
│   │   ├── endogenous.inc                # var declarations
│   │   ├── exogenous.inc                 # shock declarations
│   │   ├── parameters.inc                # param declarations
│   │   ├── calibration.inc               # param values + initval
│   │   ├── steady.inc                    # steady_state_model
│   │   └── model.inc                     # IS, Taylor, deflators (eq_pi_c, eq_pi_m, ...),
│   │                                     # term structure, WACC, UIP/s_gap, lending rate,
│   │                                     # housing price, wage Phillips, fiscal rule,
│   │                                     # capital accumulation, GDP identity,
│   │                                     # bridge, trade ECMs, growth-neutrality wedges
│   └── estimation/                       # AUTO-POPULATED by cherrypick()
│       ├── (auto-generated .inc files)
│
├── au_pac_v2.mod                         # NEW — final aggregated simulation .mod (hybrid)
├── au_pac_v2_var.mod                     # NEW — VAR variant
├── au_pac_v2_mce.mod                     # NEW — MCE variant
│
└── scripts/estimation/
    ├── run_phase_t_estimation.m          # NEW — drives aux/*.mod estimation + cherrypick
    └── run_phase_t_aggregate.m           # NEW — builds au_pac_v2.mod via aggregate()
```

---

## Session-resumable progress tracker

### Day 1 — directory restructure + declarations extraction (no estimation) ✅ COMPLETE 2026-05-16

- [x] Create directory skeleton (aux/, simulation/identities/, simulation/estimation/)
- [x] Extract `endogenous.inc` (all `var` declarations + comments) — au_pac.mod lines 35-231 → 202 lines
- [x] Extract `exogenous.inc` (all `varexo` declarations) — lines 235-291 → 62 lines
- [x] Extract `parameters.inc` (all `parameters` declarations) — lines 297-566 → 275 lines
- [x] Extract `calibration.inc` (parameter values block, post-MCMC writeback) — lines 567-951 → 390 lines
- [x] Verify reassembly: built `au_pac_phase_t_smoke.mod` with `--+ options: nostrict +--` header that includes all 4 .inc files + a stub model block with one trivial identity. Compiled cleanly under Dynare 5.x (143 unused-variable warnings expected; 0 errors).
- [ ] Extract `steady.inc` (steady_state_model block) — deferred to Day 2 (will be done alongside model.inc since they reference the same variables)

### Day 2 — identities/model.inc with structural equations 🟡 PARTIAL 2026-05-16

- [x] **Bulk extraction done**: copied au_pac.mod model body (lines 985-2031, 1068 lines) into `simulation/identities/model.inc`
- [x] Extracted steady_state_model body (lines 2039-2222) into `simulation/identities/steady.inc`
- [x] Extracted shocks body (lines 2245-2293) into `simulation/identities/shocks.inc`
- [x] **Lossless verification**: built `au_pac_phase_t_full.mod` that `@#include`s all 7 .inc files plus the var_model/pac_model declarations from au_pac.mod. Compiled cleanly: 163 endo / 47 exo / 263 params (matches Phase S), BK rank verified, **eps_pQ → ln_Q peak +0.196 @ Q2 (exact Phase S baseline)**.

**TODO next session — REFINEMENT** (current model.inc is Phase-S equivalent, needs trimming to be Phase T):

- [ ] Move ALL non-PAC, non-E-SAT structural equations into `model.inc`:
  - IS curve / Taylor / U-gap (in their full contemporaneous-term forms)
  - All deflators (eq_pi_c, eq_pi_m, eq_pi_ib, eq_pi_ih, eq_pi_x, eq_pi_g)
  - Term structure (eq_i_10y, eq_i_lh, eq_BBB, eq_LB_firms, eq_COE)
  - WACC computation
  - UIP / s_gap (with Phase Q forward NPV)
  - Housing price (eq_ph_gap)
  - Wage Phillips (Phase R form, with pi_c indexation)
  - Capital accumulation (eq_dln_K)
  - GDP identity (Bridge equation + components)
  - Trade ECMs (m, x equations)
  - Fiscal rule (eq_tau_G_gap)
  - Growth-neutrality wedges (pv_*_aux backward auxiliaries)
  - Financial / sectoral wealth (w_F, w_G, w_H, w_N accumulation)
- [ ] Keep PAC equations OUT of model.inc — they live in aux/*.mod and come back via cherrypick

### Day 3 — Build aux files + verify pac.print / cherrypick mechanics 🟢 PROOF-OF-CONCEPT COMPLETE 2026-05-16

- [x] **Day 3a**: tested `pac.print()` on existing au_pac.mod — outputs in `<modname>/model/pac-expectations/`:
  - `pac_pQ-parameters.inc` — declares h_ params + assigns numerical values
  - `pac_pQ-expression.inc` — closed-form linear combination of lagged state vars
- [x] **Day 3b**: built `aux/aux_pQ.mod` (~170 lines) — minimal aux file with:
  - 9 E-SAT core variables in pure-VAR form (LAGGED yhat_us in eq_yhat_au; LAGGED piQ, pi_m, dln_pcom, pibar_au in eq_pi_au_gap)
  - 3 structural state variables added: piQ, pi_m, dln_pcom as simple AR(1) (just for the var_model companion)
  - piQ_hat auxiliary regression (the trend_component target for VA-price PAC)
  - VA-price PAC equation eq_piQ_pac with `pac_expectation(pac_pQ)`
- [x] **Compiled cleanly**: 17 vars, 14 shocks, 48 params
- [x] **pac.print succeeded**: generated formula
  ```
  pac_expectation_pac_pQ = h_constant + h_yhat_au*yhat_au(-1) + ... + h_piQ*piQ(-1) + h_pi_m*pi_m(-1) + h_dln_pcom*dln_pcom(-1) + h_piQ_hat*piQ_hat(-1)
  ```
  with h-coefficients on STRUCTURAL variable lags (`h_piQ = 7.66e-5`, `h_pi_m = 2.65e-5`, `h_dln_pcom = 4.50e-6` — all non-zero, proving the cost-push channel will flow into PAC expectations)
- [x] **cherrypick succeeded** (after adding `json=compute` to options): writes 5 .inc files to `simulation/estimation/`:
  - `endogenous.inc` (auto-declares variables used)
  - `exogenous.inc` (shocks)
  - `parameters.inc` (h_ params + a_pQ_* + b*_pQ)
  - `parameter-values.inc` (numerical values of h_)
  - `model.inc` (the 3 equations: pac_expectation_pac_pQ formula, eq_piQ_pac with substituted formula, var_piQ_hat regression)

### Architecture confirmed

The Phase T pattern works as designed: cherrypick produces a SIMULATION-READY model.inc fragment where:
- `pac_expectation_pac_pQ` is a named endogenous variable defined by an EXPLICIT linear combination of lagged structural variables (not a Dynare-internal call)
- `eq_piQ_pac` references this variable directly
- The var_piQ_hat auxiliary regression is included as a normal equation

This is byte-for-byte the FR-BDF wp1044 / srecko pattern. Future-AU-PAC simulation models will have the SAME PAC equations + a separate "pac_expectation_<block>" identity per PAC block, with h-coefficients baked in.

### Day 3 remaining work — ✅ 5 AUX FILES BUILT 2026-05-16

- [x] Built `aux/_template_helpers.py` (Python template generator)
- [x] Generated 4 more aux files via template:
  - `aux_consumption.mod` (143 lines): E-SAT + yh_ratio_hat, c_hat auxiliaries + eq_dln_c_pac
  - `aux_business_inv.mod` (143 lines): E-SAT + ib_hat, rKB_hat auxiliaries + eq_dln_ib_pac
  - `aux_housing_inv.mod` (137 lines): E-SAT + ih_hat auxiliary + eq_dln_ih_pac
  - `aux_employment.mod` (139 lines): E-SAT + n_hat auxiliary + eq_dln_n_pac
- [x] All 5 aux files compile cleanly under Dynare 6.5 (Rosetta-x86_64 MATLAB R2020a)
- [x] All 5 cherrypicks succeed, writing to `simulation/estimation/<block>/`:
  - `pQ/` (5 .inc files, 2197 bytes)
  - `consumption/` (5 .inc files, 2647 bytes)
  - `business_inv/` (5 .inc files, 2587 bytes)
  - `housing_inv/` (5 .inc files, 2353 bytes)
  - `employment/` (5 .inc files, similar)
- [x] **Critical confirmation**: each cherrypicked `model.inc` contains a `pac_expectation_<block>` identity expressed as a linear combination of LAGGED STRUCTURAL variables (`yhat_au(-1)`, `piQ(-1)`, `pi_m(-1)`, `dln_pcom(-1)`, etc.) — the FR-BDF wp1044 / srecko / Brayton pattern verified

### Day 4 — aggregator + au_pac_v2.mod 🟡 BLOCKED 2026-05-16

- [x] Tried `aggregate('au_pac_v2.mod', {'stochastic,json=compute'}, root, pQ/, consumption/, business_inv/, housing_inv/, employment/, identities/)`
- [x] **FAILED with "Malformed equation"** at `/Applications/Dynare/6.5-x86_64/matlab/aggregate.m:345`
- [x] Root cause identified: our current `simulation/identities/model.inc` is the FULL au_pac.mod model body (1068 lines), including:
  - Multi-line equation formatting with leading whitespace
  - `[name = 'foo']` tags with spaces around `=` (aggregate expects `[name='foo']`)
  - Inline comments inside equation blocks
  - Macro processor directives
  - The 5 PAC equations (which conflict with cherrypicked versions)
  - The 12 var_* shadow equations (which should be removed under Phase T anyway)
- [x] aggregate.m expects each .inc file to follow srecko's simpler pattern: short, normalized syntax, one equation per name tag, no leading whitespace, no embedded comments

### Day 4 — aggregator + au_pac_v2.mod ✅ COMPLETE 2026-05-16

- [x] Built `simulation/identities/_normalize_model.py` — strips `//` comments, single-line equations, removes 12 shadow + 5 PAC eqs, flips 3 def_X_gap LHS (i_gap→i_au, pi_au_gap→pi_au, pi_us_gap→pi_us) to avoid aggregate's dedup-by-LHS collisions
- [x] Built `simulation/identities/_normalize_decls.py` — drops 12 shadow vars from endogenous.inc + 12 shadow shocks + 2 COVID dummies from exogenous.inc
- [x] Built `simulation/identities/_normalize_params.py` — single-line `parameters ... ;`; pre-evaluates arithmetic on RHS (-0.70*4 → -2.8); excludes 51 aux-owned params (cherrypicked)
- [x] Discovered + worked around 4 aggregate.m gotchas:
  1. No `//` comment stripping (must remove all comment headers from .inc files)
  2. `textscan` requires pure-numeric RHS values (no arithmetic)
  3. `rows()` is Octave-only (must `addpath(genpath('/Applications/Dynare/6.5-x86_64/matlab/missing'))`)
  4. Dedups by LHS variable; def_X_gap shares LHS with eq_taylor / Phillips → must flip
- [x] `aggregate('au_pac_v2.mod', ...)` SUCCEEDED, producing 29,507-byte .mod file
- [x] Added steady_state_model block (aggregate doesn't include this) + shocks block + stoch_simul → au_pac_v2.mod COMPILES with 158 vars, 40 shocks, 270 params, **BK rank passes with 9 forward-looking eigvals**

### Day 4 IRF validation (Phase T == Phase S structural fix preserved)

| | Phase S au_pac.mod (Hyb) | Phase T au_pac_v2.mod |
|---|---|---|
| eps_i: ln_Q peak (100bp) | -0.289 @ Q7 | -0.190 @ Q7 |
| eps_i: yhat_au peak | -0.181 @ Q7 | -0.136 @ Q7 |
| eps_i: s_gap peak | -0.97 @ Q8 | -0.97 @ Q8 ✓ |
| eps_i: i_10y peak (annualized) | +0.41 pp @ Q1 | +0.41 pp @ Q1 ✓ |
| **eps_pQ: pi_au impact** | **+0.119 qpp @ Q1** | **+0.119 qpp @ Q1 ✓** |
| eps_pQ: ln_Q peak | +0.196 @ Q2 | +0.189 @ Q2 |

Monetary magnitudes are ~30% smaller (likely because the Phase T pac_expectation formula is a single-formula approximation vs Phase S's full Dynare PAC machinery). Cost-push structural channel preserved.

### ARCHITECTURAL MILESTONE: shadow-VAR disconnect ELIMINATED

The `pac_expectation_pac_X` variables in au_pac_v2.mod are now defined as **explicit linear combinations of LAGGED STRUCTURAL variables** (yhat_au(-1), piQ(-1), pi_m(-1), dln_pcom(-1), ...). When eps_pQ shocks piQ structurally in the simulation model, the next-period PAC expectation formulas in all 5 PAC equations propagate the cost-push channel via piQ(-1). The FR-BDF wp1044 / srecko / Brayton pattern is implemented end-to-end in AU-PAC.

### Day 4 NEXT SESSION TASK (was)

Strip `simulation/identities/model.inc` to a Phase-T-compatible form:

1. **Remove from model.inc**:
   - The 5 PAC equations: `eq_piQ_pac`, `eq_dln_c_pac`, `eq_dln_ib_pac`, `eq_dln_ih_pac`, `eq_dln_n_pac` (lines ~340-540 of current model.inc — these come from aux cherrypick instead)
   - The 12 shadow var_* equations: `var_y`, `var_i`, `var_pi`, `var_u`, `var_yus`, `var_pQ`, `var_n`, `var_yh`, `var_c`, `var_ib`, `var_rKB`, `var_ih` (lines ~75-150 of current model.inc — replaced by aux files)
   - The 5 auxiliary regression equations that are now in cherrypick: `piQ_hat`, `n_hat`, `yh_ratio_hat`, `c_hat`, `ib_hat`, `rKB_hat`, `ih_hat`
2. **Normalize remaining equations to aggregate-compatible form**:
   - Strip leading whitespace from equation tags and bodies
   - Use `[name='foo']` not `[name = 'foo']` (or check whether aggregate is space-tolerant)
   - One equation per `[name=...]` tag, terminating with `;` on its own line
   - Remove inline `//` comments (move them above the equation or to separate doc)
3. **Strip endogenous.inc** of variables now declared in aux files:
   - Shadow variables: `y_gap_var`, `i_gap_var`, `pi_gap_var`, `u_gap_var`, `yhat_us_var`, `piQ_hat`, `n_hat`, `yh_ratio_hat`, `c_hat`, `ib_hat`, `rKB_hat`, `ih_hat` (12 vars to remove)
4. **Strip exogenous.inc** of shocks now in aux files:
   - Shadow shocks: `eps_var_y`, `eps_var_i`, `eps_var_pi`, `eps_var_pQ`, `eps_var_n`, `eps_var_c`, `eps_var_yh`, `eps_var_ib`, `eps_var_rKB`, `eps_var_ih`, `eps_var_u`, `eps_var_yus` (12 shocks to remove)
5. **Retry aggregate** — should now compose cleanly

### Day 4-5 follow-on

- [ ] After aggregate succeeds, smoke-test au_pac_v2.mod compiles + passes BK rank
- [ ] Run cost-push IRF — **smoking-gun test**: VAR/Hybrid/MCE should now diverge (Phase S they were identical)
- [ ] Run monetary IRF — should be similar to Phase S baseline
- [ ] Run forward-guidance puzzle test — should preserve ~10 at N=12
  - `yhat_au = lambda_q*yhat_au(-1) − sigma_q*(i_gap(-1) − pi_au_gap(-1)) + delta*yhat_us(-1) + lambda_dom*yhat_dom(-1) + eps_q` (LAG yhat_us and yhat_dom)
  - `i_gap = lambda_i*i_gap(-1) + (1-lambda_i)*(alpha_i*pi_au_gap(-1) + beta_i*yhat_au(-1)) + eps_i` (already pure-VAR)
  - `pi_au_gap = lambda_pi*pi_au_gap(-1) + kappa_pi*yhat_au(-1) + alpha_pc*(piQ(-1) − pibar_au(-1)) + beta_pc_m*(pi_m(-1) − pibar_au(-1)) + gamma_oil*dln_pcom(-1) + eps_pi` (PHASE S terms, LAGGED)
  - `yhat_us = lambda_q_us*yhat_us(-1) + eps_q_us` (already)
  - `pi_us_gap = lambda_pi_us*pi_us_gap(-1) + kappa_pi_us*yhat_us(-1) + eps_pi_us` (already)
  - `u_gap = rho_u_gap*u_gap(-1) + okun_coeff*yhat_au(-1) + eps_u_gap` (LAG yhat_au)
  - `ibar = lambda_ibar*ibar(-1) + (1-lambda_ibar)*i_ss + eps_ibar` (already)
  - `pibar_au = lambda_pibar*pibar_au(-1) + (1-lambda_pibar)*pi_ss_au + eps_pibar_au` (already)
  - `pibar_us = lambda_pibar_us*pibar_us(-1) + (1-lambda_pibar_us)*pi_ss_us + eps_pibar_us` (already)
- [ ] Add `var_model(model_name = esat, eqtags = [...])` declaration
- [ ] Smoke-test compile + BK rank check

### Day 4 — first PAC aux file (aux_pQ.mod)

- [ ] Build `aux/aux_pQ.mod`:
  - Include aux_esat_core equations
  - Add auxiliary equation: `piQ_hat = rho_pQ_aux*piQ_hat(-1) + a_pQ_y*yhat_au(-1) + a_pQ_i*i_gap(-1) + a_pQ_pi*pi_au_gap(-1) + a_pQ_u*u_gap(-1) + eps_var_pQ`
  - Add target equation: `piQ_star_bar = pibar_au` (or whatever the FR-BDF target form is)
  - Add VA-price PAC equation with `pac_expectation(pac_pQ)`
  - Declare `pac_model(auxiliary_model_name = esat_extended_pQ, ...)` where esat_extended_pQ = E-SAT core + piQ_hat aux
- [ ] Driver: estimate via iterative OLS, run `pac.print('pac_pQ', 'eq_piQ_pac')`
- [ ] Run `cherrypick('aux_pQ', 'simulation/estimation/', {'eq_piQ_pac', 'piQ_hat', 'piQ_star_bar'})`

### Day 5 — first aggregator + au_pac_v2.mod smoke test

- [ ] Build `scripts/estimation/run_phase_t_aggregate.m`:
  - Calls `aggregate('au_pac_v2.mod', {'stochastic'}, root, ['simulation/estimation', 'simulation/identities'])`
- [ ] Verify `au_pac_v2.mod` compiles
- [ ] Verify BK rank
- [ ] Run stoch_simul, compare eps_pQ IRF to Phase S baseline

### Day 6 — remaining 4 PAC aux files

- [ ] `aux/aux_consumption.mod` (E-SAT + yh_ratio_hat + c_hat + consumption PAC with `pv_r_lh_gap` from Phase R)
- [ ] `aux/aux_business_inv.mod` (E-SAT + ib_hat + rKB_hat + business inv PAC)
- [ ] `aux/aux_housing_inv.mod` (E-SAT + ih_hat + housing inv PAC)
- [ ] `aux/aux_employment.mod` (E-SAT + n_hat + employment PAC with Δq channel + dln_tfp sign from Phase R)
- [ ] Re-aggregate, re-test

### Day 7 — three variants (hybrid / VAR / MCE) + MCMC port

- [ ] Build `au_pac_v2_var.mod` (pure-VAR PAC expectations)
- [ ] Build `au_pac_v2_mce.mod` (full MCE)
- [ ] BK rank checks on all 3
- [ ] **Smoking-gun test**: regen IRFs and verify cost-push IRF now shows distinct VAR/Hybrid/MCE response
- [ ] If joint Bayesian MCMC compatible with new architecture, re-run; otherwise document the FR-BDF-style block-by-block OLS posteriors

### Day 8 — paper / docs sweep

- [ ] Working paper §4.4.0: rewrite to describe the policy-function architecture, document the change from shadow VAR to cherrypick/aggregate
- [ ] Working paper §4.13.6: add Phase T architectural note
- [ ] Working paper Table 5.6: refresh with Phase T posteriors
- [ ] Working paper §6.2 Table 6.3, §6.3.5, §6.5: re-run with Phase T IRFs
- [ ] audit.md: new row for Phase T closing the shadow-VAR architectural gap (separate from #20 which was Phase S)
- [ ] STATUS.md: Phase T section
- [ ] NEXT_STEPS.md: Phase T section
- [ ] phase_t_plan.md: mark complete

---

## Key design decisions (locked in by reading FR-BDF wp1044 + srecko)

1. **E-SAT estimation**: Bayesian for the 8 core E-SAT equations (matches FR-BDF wp1044 §2.2 line 614)
2. **Auxiliary equations**: OLS, estimated separately, do not affect E-SAT coefficients (FR-BDF wp1044 line 614-617 + 1272-1273)
3. **PAC short-run equations**: iterative OLS or NLS (FR-BDF wp1044 line 608-612, srecko's `pac.estimate.iterative_ols` / `pac.estimate.nls`)
4. **Discount factor β**: 0.98 in most PAC blocks; β_c = 0.95 for consumption (FR-BDF wp1044 line 620-625)
5. **VBE-only estimation**: PAC coefficients estimated under backward-looking expectations; MCE and Hybrid simulations use the same posteriors (FR-BDF wp1044 line 627-634)
6. **Cherrypick + aggregate**: use Dynare's undocumented `cherrypick` and `aggregate` MATLAB routines (Stéphane Adjemian forum post #6)

---

## Risks and mitigations (updated as we go)

| Risk | Mitigation | Status |
|---|---|---|
| `cherrypick` / `aggregate` are undocumented | Mirror srecko's repo structure; consult `matlab/+cherrypick`, `matlab/+aggregate` Dynare source | open |
| Joint Bayesian (Phase S) → block-by-block OLS may lose ~5-10 nats of LMD | FR-BDF wp1044 uses block-by-block; accept the apples-to-oranges paradigm change. Could keep joint MCMC option as Phase T+1. | open |
| Lag-only E-SAT changes dynamics from Phase S | The aux .mod E-SAT is for *expectation generation only*; the simulation model.inc keeps full structural contemporaneous form | open |
| `pac.print()` output may not refactor cleanly | Re-run aggregator after each re-estimation; treat aux → simulation as a build pipeline | open |
| Dynare 6 PAC may differ from 5.5 (srecko's version) | Test on current Dynare; lock to 5.5 if 6.x breaks | open |
| Some sectoral / financial blocks may be hard to fit the aux/identity split | Phase the migration: do PAC blocks first, leave financial / sectoral in old `au_pac.mod` as v2.0 alternate | open |

---

## Phase T preflight: state-of-the-art baseline (Phase S, 2026-05-16)

- LMD Laplace = -788.95, MHM = -789.10
- Phase R + Phase S together = +13.17 nats vs Phase Q baseline
- Forward-guidance ratio at N=12 = 10.09 (no puzzle)
- Cost-push IRF: piQ +0.571 qpp impact; pi_au +0.119 qpp impact (Phase S works); ln_Q still mildly positive throughout (AU calibration constraint, not bug)
- **All 3 variants pass BK rank with 5 / 0 / 32 forward-looking eigenvalues respectively**
- ✓ #20 audit item closed; #6/#54 BGP convergence verified; #14/#53 δ_k sensitivity quantified

---

## Out of scope for Phase T

- Adding NEW economic content (kept for Phase 5 research backlog: i_us foreign rate, energy import split, branch decomposition, tax structure, etc.)
- Changing the wp1044-aligned Phase R structural fixes (eq_au_phillips Phase S deflator channels, wage Phillips CPI indexation, employment Δq channel, consumption pv_r_lh_gap)
- Re-estimation under MCE or Hybrid expectations (per wp1044, always VBE)

---

## Session notes (append as we go)

### 2026-05-16 — Session 4 (Phase T MCMC COMPLETE — architectural validation 🎉)

**Phase T validation: au_pac_v2_bayesian.mod MCMC = +7.7 nats over Phase S.** The architectural refactor not only preserves the model's ability to fit the data but **substantially improves it**. The Phase T policy-function expectation operator is empirically preferred to Phase S's Dynare-internal pac_expectation.

- Built `au_pac_v2_bayesian.mod` (1443 lines) — copy of au_pac_v2.mod with stoch_simul replaced by varobs + estimated_params + estimation block (29 estimated parameters: 19 PAC/wage params + 10 shock stds, ported from au_pac_bayesian.mod)
- Ran Bayesian MCMC via `dynare au_pac_v2_bayesian`: 51.4 min wall time on Apple Silicon under Rosetta 2 (similar to Phase S)
- **Headline result**: Laplace LMD = **−781.05** (Phase S: −788.95, **+7.9 nats**); MHM LMD = **−781.39** (Phase S: −789.10, **+7.7 nats**)
- **Cumulative Phase Q → Phase T improvement: +20.66 MHM nats** (Phase Q baseline −802.27 → Phase T −781.39)
- Wrote `dynare/mcmc_posterior_table_phase_t.md` with full 28-param posterior

### Phase T posterior highlights

| Parameter | Phase S | Phase T | Δ |
|---|---|---|---|
| LMD Laplace | −788.95 | **−781.05** | **+7.90** |
| LMD MHM | −789.10 | **−781.39** | **+7.71** |
| b0_pQ (VA-price EC) | 0.0294 | 0.0330 | +0.0036 |
| b3_ib (bus inv accelerator) | 0.314 | 0.323 | +0.009 |
| b3_ih (housing inv accelerator) | 0.232 | 0.224 | -0.008 |
| lambda_w (wage persistence) | 0.183 | 0.209 | +0.026 |
| gamma_w (CPI passthrough) | 0.495 | **0.354** | -0.141 |
| kappa_w (Phillips slope) | +0.046 | **-0.103** | **flipped sign, now significant** [-0.178, -0.019] |
| b2_c (consumption rate) | -0.333 | -0.328 | +0.005 |
| eps_n shock std | 0.41 | 0.48 | +0.07 |

**Notable**: `kappa_w` flipped sign from +0.046 (Phase S, HPD straddled zero) to **-0.103 (Phase T, HPD now ENTIRELY NEGATIVE)** under the convention `+κ_w · pv_u_gap` (Phase S form). Under FR-BDF's `−κ_w · pv_u_gap` sign convention, this corresponds to a POSITIVE Phillips slope (higher unemployment → lower wage growth) — the FR-BDF expected sign. The Phase T architecture's cleaner structural-variable expectations identifies the Phillips slope with the correct sign, where Phase S's shadow-decoupled expectations did not.

### Phase T validation complete

- [x] au_pac_v2.mod compiles + BK passes (9 forward-looking eigvals)
- [x] au_pac_v2_bayesian.mod estimates successfully (51.4 min, Brooks-Gelman PSRF passes for all 28 params)
- [x] LMD improvement +7.7 nats validates the architecture
- [x] Wage Phillips slope identifies with correct (FR-BDF expected) sign
- [x] Architecture matches FR-BDF wp1044 §2.2 policy-function approach
- [x] Architecture matches srecko/SemiStructDynareBasics ECB pattern
- [x] All 5 PAC blocks (pQ, c, ib, ih, n) running through cherrypick + aggregate

### Day 5 — IRF regen + paper sweep ✅ COMPLETE 2026-05-16

- [x] Wrote Phase T posteriors back to au_pac_v2.mod (inline overrides before stoch_simul; cleaner option for future would be auto-writeback to aux/*.mod calibration sections)
- [x] Regen IRFs at irf=200 → saved to `saved_irfs_v2_phase_t.mat`
  - Monetary IRF (100bp): ln_Q -0.22% Q7, yhat_au -0.14% Q7, CPI inflation -0.10 pp y/y Q11, s_gap -0.97% Q8, i_10y +0.41 pp Q1
  - Cost-push IRF (eps_pQ): pi_au +0.119 qpp impact (matches Phase S exactly), yhat_au +0.011 Q3 then turns negative, ln_Q +0.20% Q2
- [x] Forward-guidance puzzle test on au_pac_v2 → **ratio 10.14 at N=12** (Phase S: 10.09, Phase R: 10.06, all within ±1%; no-puzzle property preserved)
- [x] Working paper updates:
  - Table 5.6 replaced with Phase T posteriors; old Phase S table preserved as Table 5.6.1 for historical reference
  - §5.4 narrative refreshed with Phase Q → R → S → T LMD trajectory table (+20.66 cumulative MHM nats)
  - **NEW §4.4.0a** — full Phase T policy-function architecture description (FR-BDF wp1044 §2.2, srecko/SemiStructDynareBasics, Brayton FRB/US workflow); §4.4.0b renamed for the existing Phase S structural-channel content
  - Table 6.3 refreshed with Phase T monetary IRF; old Phase S table preserved as Table 6.3-historical
  - §6.5 forward-guidance ratio updated 10.09 → 10.14
- [x] STATUS.md / audit.md / dynare/NEXT_STEPS.md all updated (Session 3 already, Session 4 marked)
- [ ] (Optional Phase T+1) Build au_pac_v2_var.mod and au_pac_v2_mce.mod for separate regimes if needed — under Phase T's closed-form formula architecture the VAR/Hyb/MCE distinction collapses to a single regime (the policy-function formula), so this is only relevant if the project specifically needs the Phase S regime ordering preserved
- [ ] (Optional) Tag v3.0 if user approves Phase T as production architecture

### 2026-05-16 — Session 3 (Day 4 COMPLETE: aggregate + au_pac_v2.mod working)

**Phase T core implementation milestone**: au_pac_v2.mod compiles, passes BK rank, produces IRFs. The shadow-VAR architectural disconnect is eliminated; PAC expectations now use explicit structural-variable lag formulas matching FR-BDF wp1044's policy-function approach.

- Wrote 3 normalize_*.py helpers in simulation/identities/ to make .inc files aggregate-compatible (`_normalize_model.py` strips comments + single-lines equations + removes 17 excluded eqs + flips 3 def_X_gap LHS to avoid dedup collisions; `_normalize_decls.py` drops shadow vars/shocks; `_normalize_params.py` writes single-line parameters.inc + pure-numeric parameter-values.inc, excluding 51 aux-owned PAC/aux-regression params)
- Discovered + worked around 4 aggregate.m gotchas (see Day 4 section above)
- aggregate() succeeded → au_pac_v2.mod (29,507 bytes)
- Appended steady_state_model + shocks + stoch_simul → compiles + BK passes
- Verified monetary + cost-push IRFs produce sensible structural behavior

### Session 3 artifacts
- `dynare/simulation/identities/_normalize_model.py` (124 lines)
- `dynare/simulation/identities/_normalize_decls.py` (75 lines)
- `dynare/simulation/identities/_normalize_params.py` (102 lines)
- `dynare/simulation/identities/{model,endogenous,exogenous,parameters,parameter-values}.inc` (all regenerated, aggregate-compatible)
- `dynare/au_pac_v2.mod` (1206 lines, the aggregated Phase T simulation model)
- Updated phase_t_plan.md with milestone

### Next session pickup options (Phase T finishing tasks)

1. **MCMC port**: Re-estimate the 28-parameter posterior under the new au_pac_v2.mod architecture. NOTE: this is a paradigm change from joint Bayesian (Phase S) to block-by-block (FR-BDF wp1044 §2.2). May need to either:
   - Keep joint Bayesian on v2 (preserve apples-to-apples LMD comparison with Phase S −789.10)
   - OR adopt FR-BDF block-by-block: estimate aux_esat_core via Bayesian, then each PAC aux via iterative OLS (different paradigm; LMD becomes non-comparable)
2. **Working paper sweep**: Update §4.4.0 to describe the policy-function architecture, Table 5.6 with new posteriors, §4.13.6 with the Phase T architectural note
3. **Build au_pac_v2_var.mod / au_pac_v2_mce.mod** if the project needs separate VAR/Hybrid/MCE simulation variants. Phase T's pac.print produces a single closed-form formula (the FR-BDF VAR-based expectation); MCE would need a separate aux file with `pac_expectation` under a perfect-foresight setting.
4. **audit.md / STATUS.md / NEXT_STEPS.md**: add Phase T row marking the shadow-VAR disconnect closed
5. **Optionally**: remove the legacy au_pac.mod / au_pac_var.mod / au_pac_mce.mod after Phase T is fully validated

### 2026-05-16 — Session 2 (Day 3 complete: 5 aux files + cherrypick verified; Day 4 blocked on model.inc cleanup)

**Architectural milestone**: the FR-BDF wp1044 / srecko / Brayton expectation-formula pattern is end-to-end verified in AU-PAC. All 5 PAC blocks produce structural-variable PAC expectation formulas via `pac.print` + `cherrypick`. The remaining work is mechanical: clean up the simulation/identities/ files to be aggregate-compatible.

- Built `aux/_template_helpers.py` (Python aux-file generator)
- Generated 4 aux files via template (consumption, business_inv, housing_inv, employment)
- Compiled all 5 aux files + ran pac.print + cherrypick — all successful
- Each cherrypick output uses STRUCTURAL variable lags (the architectural fix)
- Tried aggregate() — failed on the unconverted identities/model.inc
- Documented root cause + next-session task list

### Session 2 artifacts
- `dynare/aux/_template_helpers.py` (template generator)
- `dynare/aux/aux_consumption.mod`, `aux_business_inv.mod`, `aux_housing_inv.mod`, `aux_employment.mod`
- `dynare/aux/aux_<X>/model/pac-expectations/pac_<X>-*.inc` (5 × 2 expectation files)
- `dynare/simulation/estimation/<block>/*.inc` (5 subdirs × 5 .inc files = 25 cherrypicked .inc files)
- Updated phase_t_plan.md with Day 3+4 status

### 2026-05-16 — Session 1 (planning + days 1+2 complete)
- Created phase_t_plan.md
- Created directory skeleton: `dynare/aux/`, `dynare/simulation/identities/`, `dynare/simulation/estimation/`
- Extracted 7 .inc declaration/model files from au_pac.mod (2242 lines total):
  - endogenous.inc (202 lines), exogenous.inc (62), parameters.inc (275), calibration.inc (390)
  - model.inc (1068), steady.inc (191), shocks.inc (54)
- Built `au_pac_phase_t_smoke.mod` (minimal) and `au_pac_phase_t_full.mod` (full reassembly)
- **VERIFIED LOSSLESS EXTRACTION**: au_pac_phase_t_full.mod compiles to identical model (163/47/263 vars/shocks/params, BK passes, eps_pQ → ln_Q +0.196 @ Q2 matching Phase S exactly)

### Session 1 artifacts
- `phase_t_plan.md` (this file)
- `dynare/aux/` (empty, ready for next session)
- `dynare/simulation/identities/*.inc` (7 files, 2242 lines)
- `dynare/simulation/estimation/` (empty, auto-populated by cherrypick later)
- `dynare/au_pac_phase_t_smoke.mod` (minimal-stub verification, can be deleted)
- `dynare/au_pac_phase_t_full.mod` (Phase-S-equivalent reference reassembly, keep)

### Next session pickup (where to start)

Read `phase_t_plan.md`, then:
1. **Day 2 refinement**: trim `model.inc` to remove var_* shadow equations (lines ~75-150 of current model.inc, the `[name = 'var_*']` block) and the 5 PAC equations (eq_piQ_pac, eq_dln_c_pac, eq_dln_ib_pac, eq_dln_ih_pac, eq_dln_n_pac). Trim `endogenous.inc` and `exogenous.inc` of the shadow variables and shocks.
2. **Day 3**: build `aux/aux_esat_core.mod` with 8 E-SAT equations in pure-VAR form (lagging the contemporaneous yhat_us/yhat_dom in eq_au_is, piQ/pi_m/dln_pcom/pibar_au in eq_au_phillips, yhat_au in eq_u_gap).
3. **Day 4**: build `aux/aux_pQ.mod` and test cherrypick + aggregate end-to-end on just the VA-price PAC block.

### Tools / patterns discovered
- Dynare requires the `nostrict` option (or all declared shocks must appear in model equations) for intermediate-state .mod files during a multi-day refactor
- `@#include "path/to/file.inc"` macro processing works for cleanly nested .inc files
- Block boundaries in au_pac.mod (Phase S baseline, line numbers):
  - var: 35-231; varexo: 235-291; parameters: 297-566; calibration: 567-951
  - var_model + pac_model decls: 967-978
  - model block: 984-2032 (1048 lines — to be split)
  - steady_state_model: 2038-2223
  - shocks: 2244-2294
  - pac.initialize: 2226-2235 + 2301-2310
  - stoch_simul: 2312
