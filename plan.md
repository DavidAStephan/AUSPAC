# AUSPAC ↔ FR-BDF alignment — implementation plan

**Date:** 2026-05-15
**Source:** [`audit.md`](audit.md) (15 sections, 58 action items)
**Goal:** address audit findings through a sequenced, dependency-aware refit.

---

## Strategic framing

The audit identified **8 genuine ✗ structural mismatches**, **50+ ⚠ AU
adaptations / calibration flags**, and **8 deferred extensions**. The fixes
fall into three classes:

1. **Cheap structural fixes** — sign errors, missing channels in growth-form
   equations. Don't require new data. Re-uses existing MCMC machinery.
2. **Diagnostic-then-decide** — the `pv_X_aux` puzzle (action #18/#34)
   touches 11+ equations across 6 deflators + 5 PAC equations. Must be
   resolved BEFORE other PAC-equation fixes to avoid double work.
3. **Substantive extensions** — adding new variables (foreign rate `i_us`,
   demographic trends), new data series, new auxiliary models. Multi-week
   each. Defer to future research phases.

**Sequencing principle:** resolve the gating diagnostic first, then bundle
all structural fixes into ONE MCMC re-run rather than one re-run per fix.

**Compute budget:** ~55 min per MCMC re-run (3-5min csminwel + 50min MH).
Plan ≤2 re-runs total. IRF regeneration ~15 min per variant × 3 variants.

**Wall time estimate:** 3-4 weeks part-time.

---

## Phase 0 — Diagnostic (gating, 1-2 days, NO model changes)

Resolve the two highest-leverage open questions before touching code.

### 0.1 Resolve `pv_X_aux` puzzle (audit #18 / #34)

**The question**: do AUSPAC's `pv_X_aux` "wedge" terms (in `eq_piQ_pac`,
`eq_dln_n_pac`, `eq_dln_c_pac`, `eq_dln_ib_pac`, `eq_dln_ih_pac` + 6 deflators)
double-count what `pac_expectation()` already provides, OR do they substitute
for the missing FR-BDF level-correction `(1-β-ω)·π̄*` terms?

**Test (~30 min compute)**:

```matlab
cd dynare; setup_dynare_path();
dynare au_pac noclearall nograph;

% Force pv_X_aux to zero, recompute IRFs
M_.params(M_.param_names_long.startsWith('pv_')) = 0;

% Set all pv_X_aux SS values to zero, re-solve
oo_no_wedge = oo_;
% ... recompute IRFs

% Compare to baseline IRFs
diff_pct = max(abs(oo_.irfs.ln_Q_eps_i - oo_no_wedge.irfs.ln_Q_eps_i)) / ...
           max(abs(oo_.irfs.ln_Q_eps_i)) * 100;

if diff_pct < 5
    disp('Wedges are REDUNDANT — remove (interpretation 1)');
else
    disp('Wedges DO real work — keep + rename (interpretation 2)');
end
```

**Decision tree**:
- **If REDUNDANT** → execute Phase 1A (delete wedges from 11 equations
  across 8 .mod files). MCMC re-run required. Major simplification.
- **If REAL** → execute Phase 1B (rename `pv_X_aux` → `growth_neutrality_X`,
  document as FR-BDF level-correction substitute, no code change).

**Why this gates everything else**: the deflator equations (§4.7 audit) and
several PAC equations (§4.4, §4.5, §4.6.1 audits) are all affected. Fixing
sign errors and adding channels in those equations BEFORE knowing the wedge
status would cause double work.

### 0.2 Long-run BGP convergence test (audit #6 / #54)

Run unconditional simulation 2024Q1 → 2300Q1 (1100 quarters) under Phase Q
forward UIP, all residuals zero, exogenous variables at LR growth rates.

```matlab
cd dynare; setup_dynare_path();
dynare au_pac noclearall nograph;
% configure simul_replic with extended horizon
% verify yhat_au, pi_au, s_gap → 0
% verify w_F, w_G, w_H asset ratios converge
```

**Output**: pass/fail on FR-BDF Fig 5.1 convergence test. If fail,
investigate whether floating AUD + Phase Q UIP introduced indeterminacy.

### Phase 0 deliverables

- Decision: REDUNDANT vs REAL on `pv_X_aux`
- Pass/fail on LR BGP convergence
- Updated `audit.md` with Phase 0 results
- Go/no-go for Phase 1

---

## Phase 1 — Structural bug fixes (2-3 days, no MCMC yet)

Apply structural corrections that don't change estimation infrastructure.
All edits replicated across **8 .mod files** (au_pac, au_pac_var, au_pac_mce,
au_pac_bayesian, au_pac_smooth, au_pac_condforecast, au_pac_recursive,
au_pac_identification) using a Python helper script (per the TFP shock fix
pattern from 2026-05-15).

### 1.A IF Phase 0 says "REDUNDANT" — wedge removal (additional 1 day)

Delete from all 8 .mod files:
- `pv_piQ_aux`, `pv_n_aux`, `pv_c_aux`, `pv_ib_aux`, `pv_rKB_aux`, `pv_ih_aux`
  variable declarations + 6 equations
- `+ pv_*_aux` terms in 5 PAC equations
- For deflators: replace `+ (1-rho-alpha-beta)·pibar_au` term with FR-BDF's
  proper `+ β·[p_j(-1) - p*_j(-1)]` ECM error-correction (need to define
  `p*_j` target equations for each deflator)

This is the LARGER refactor branch. Adds ~5 target-equation declarations.

### 1.B IF Phase 0 says "REAL" — rename + document (15 min)

- Rename `pv_X_aux` → `growth_neutrality_X` across 8 .mod files
- Update comments to cite FR-BDF eqs 80, 82, 84, 86, 89, 91 level-correction role
- No estimation impact

### 1.C Sign + missing-channel fixes in `eq_dln_n_star_bar` (audit #21, #17)

[au_pac.mod:1340-1341](dynare/au_pac.mod#L1340) currently:
```
dln_n_star_bar = dln_tfp / (1 - alpha_k) - sigma_ces * rw_gap;
```

**Replace with** (FR-BDF eq 36 in growth form):
```
dln_n_star_bar = (yhat_au - yhat_au(-1))                  // NEW: Δq channel (#17)
               - dln_tfp / (1 - alpha_k)                   // FIXED: was +, should be − (#21)
               - sigma_ces * rw_gap;                       // unchanged
```

**Effect**: corrects labor demand response to TFP shock from +2.79·dln_tfp
(wrong sign, 30× too large) to FR-BDF's -0.84·dln_tfp + Δq channel ≈ +0.087.

**Verify**: model still passes Blanchard-Kahn rank check.

### 1.D Wage Phillips sign + inflation measure (audit #22, #23)

[au_pac.mod:1316-1322](dynare/au_pac.mod#L1316) currently has `+ kappa_w · pv_u_gap`
with `kappa_w = +0.0966`. Change either:

- **Option A** (FR-BDF convention): flip to `- kappa_w · pv_u_gap` and
  re-estimate `kappa_w` with prior centred on +0.32 (FR-BDF |β_4|).
- **Option B** (less invasive): leave equation form, change MCMC prior on
  `kappa_w` to `Normal(-0.32, 0.10²)` to recover correct sign.

Recommend **Option A** for clarity.

ALSO replace `gamma_w · pi_au` with `gamma_w · pi_c` (consumer price inflation,
not VA price). Workers index to what they buy.

### 1.E Forward real-rate PV in consumption (audit #26)

Add new endogenous variable + equation across 8 .mod files:
```
[name = 'eq_pv_r_lh_gap']
pv_r_lh_gap = (1 - beta_c) * (i_lh - pi_c - LR_real_rate)
            + beta_c * pv_r_lh_gap(+1);
```

Add to `eq_dln_c_pac`:
```
diff(ln_c_level) = ...
                 + alpha_c_r * pv_r_lh_gap          // NEW: FR-BDF eq 61 PV(r_LH) channel
                 ...;
```

**Effect**: strengthens forward-looking monetary transmission via consumption,
aligned with FR-BDF eq 61.

### Phase 1 deliverables

- 8 .mod files updated consistently (Python script per TFP shock fix pattern)
- BK rank verified for all variants
- Diff applied to `STATUS.md` documenting Phase R (audit-driven refit)
- Ready for MCMC

---

## Phase 2 — MCMC refresh (~1 day wall, 1 hour compute)

```matlab
cd dynare; setup_dynare_path();
estimate_pac_smooth_driver;       % refresh smoothed series
run_bayesian_estimation;           % csminwel mode (~5 min)
run_bayesian_mcmc;                 % MH 20k×2 (~50 min)
extract_mcmc_results;              % posterior table
```

**Expected posterior shifts**:
- `kappa_w`: +0.097 → -0.10 ± 0.05 (sign flip, magnitude similar)
- `b3_ib`, `b_di_c`, `b3_n`, `b3_c`: should shift if the wedge interpretation
  changed (Phase 0 result tells us how much)
- `gamma_w` (CPI passthrough): may shift now that `pi_c` is the indexation
  variable instead of `pi_au`

**Compare to Phase Q baseline** (LMD Laplace -801.71, MHM -802.27) to
confirm no degradation. Expect either improvement or comparable fit.

**Output**: refreshed `bayesian_mcmc_results.mat`, `mcmc_posterior_table.md`,
parameter writeback to .mod files via `apply_mcmc_writeback.py`.

---

## Phase 3 — IRF regeneration + benchmark comparison (1 day)

```bash
# Regenerate IRFs at irf=200 (already configured per 2026-05-15 cleanup)
cd dynare; setup_dynare_path();
dynare au_pac noclearall nograph;
dynare au_pac_var noclearall nograph;
dynare au_pac_mce noclearall nograph;

# Regenerate figures
python3 dynare/regen/regen_three_regime_figs.py
python3 dynare/regen/regen_section5_irfs.py
python3 dynare/regen/regen_pac_contrib_figs.py
```

**Quantitative benchmarks vs FR-BDF** (audit #49-52 + new):

| Shock | FR-BDF benchmark | AUSPAC pre-fix | AUSPAC post-fix target |
|---|---|---|---|
| eps_i (monetary, +100bp) | -0.15% GDP at Q12 | -0.27% GDP at Q40 | < -0.20% with peak < Q30 (closer to FR-BDF) |
| eps_g (gov spending, +1% GDP) | +1.2% GDP impact | TBD | document fiscal multiplier |
| eps_q_us (foreign demand, +1%) | +0.14% GDP at Q4 | TBD | document |
| eps_tp (term premium, +100bp) | -0.05% GDP | TBD | document |
| eps_pQ (cost-push, +1pp) | -0.45% GDP at Q8 | TBD | document |
| eps_pcom (commodity, +10%) | -0.20% GDP | TBD | document |
| eps_tfp_LR (perm efficiency, +1%) | +0.6% GDP at 4yr (FR-BDF abstract) | TBD post-fix | verify |
| Forward guidance N=12 | linear ratio ~12 | 10.47 ✓ | should remain ≥10 |

Generate `audit_post_fix_comparison.md` with side-by-side FR-BDF vs AUSPAC
quantitative IRF comparison for all 7 shocks.

---

## Phase 4 — Documentation pass (3-5 days, no compute)

Group the 30+ ⚠ items that need documentation (not code change). Write into
working paper §4 as "AU adaptations vs FR-BDF design intent" subsection.

### 4.1 AU empirical findings (estimation results)

Document as substantive AU econometric findings:
- **AU flat Phillips curve** (audit #19): β_2≈0 across VA price (#4.4), wage
  (κ_w≈0, #4.5), employment (b5_n≈0, #4.5), consumption (b3_c≈0, #4.6.1).
  Four independent confirmations from MCMC posteriors.
- **AU export equation underidentification** (#32): b1_x and b2_x kept at
  FR-BDF values (Phase D failed to identify with US output gap proxy)
- **AU consumption interest channel** (#27 note): b_di_c=-0.701 imported
  from FR-BDF prior (Phase C IV failed)

### 4.2 AU structural simplifications (intentional)

- **Permanent income proxy** (#25): AU uses PV(yhat_au) instead of FR-BDF's
  PV(y_H) (PV of disposable income). No AU disposable-income variable.
- **No `p_IH` (new housing deflator)** (#28): AU drops γ_1 channel from
  household investment target.
- **Real housing user cost simplified** (#29): AU uses nominal rate gap, not
  PV(π_Q) deflated rate.
- **Housing price equation restructured** (#30): AU adds demand+credit
  channels to AR(1), drops AR(2) inflation anchor.
- **Wage Phillips simplified** (#4.5 wage): AU drops minimum-wage channel,
  uses standard NK form.

### 4.3 AU adaptations to local market structure

- **Foreign block: US not EA** (#2 audit): RBA reacts to AU vars (independent
  CB), not foreign vars.
- **Floating AUD with UIP** (#2.7): LR real rate endogenous in AU vs
  exogenous in FR-BDF (Eurozone fixed rate).
- **Commodity price channel** (Stage 11b): added for AU mining-driven
  exports/imports (#4.6.4).
- **Phase Q forward UIP** (Phase Q, 2026-05-15): NPV of policy-rate gap
  drives s_gap (vs FR-BDF UIP via interest differential).

### 4.4 Calibration imports (not AU-estimated)

Document that the following are imported from FR-BDF, not AU-estimated:
- WACC weights `w_COE=0.5`, `w_LB=0.3`, `w_BBB=0.2` (#39)
- Spread persistences `ρ_COE=0.92`, `ρ_LB=0.77`, `ρ_BBB=0.94` (#39)
- Sector wealth targets `w_F_ss=-2.80`, `w_G_ss=-1.60` (§4.8 #40)
- `kappa_10=0.97` term-structure decay (§4.8)
- `gamma_reval=-0.018` firms revaluation (§4.8)
- `b_di_c=-0.701` consumption rate channel (Phase C, #27)

### 4.5 AU government / fiscal differences

- **No tax-rate decomposition** (#46): AU can't simulate tax-policy changes
  endogenously
- **Countercyclical fiscal rule** (#47): AU `eq_tau_G` responds to output gap
  (0.05·yhat_au); FR-BDF eq 125 responds to asset ratio
- **`rho_stab_2 = 0.25`** (vs FR-BDF 0.10) — strengthened for BK determinacy
  (audit #40)

### 4.6 Methodological choices

- **Endogenous structural trends** (#44): AUSPAC's dln_n_star_bar etc. are
  endogenous (derived from CES); FR-BDF p. 97 prefers exogenous (anchored to
  external benchmarks)
- **No HP-filter smoothers in Dynare** (#4.9): AU uses gap-form structural
  model; HP filters applied at data-prep stage only
- **Standard NPV (not normalised) in pv_i_uip** (#13): Phase Q convention
  for ~4.55× amplification

### Phase 4 deliverables

- Working paper §4 subsection: "AU adaptations vs FR-BDF design"
- Updated [STATUS.md](STATUS.md) with audit-driven changes
- Updated [audit.md](audit.md) status: all ⚠ items marked "documented"

---

## Phase 5 — Defer to future research

These require multi-week effort (data sourcing, structural model changes)
and are appropriate for follow-on work, not the current refit.

| # | Item | Reason for deferral |
|---|---|---|
| #8, #42 | Add `i_us` (Fed short rate) + `ibar_us` to E-SAT | New variable across 8 .mod files + new FRED data series + MCMC re-run with new dimension. Affects US IS real-rate channel + UIP foreign rate term. ~1 week. |
| #43 | Add demographic trends (`POP̄_t` from ABS 6202) | Requires AU labor-force projection methodology; introduces 1+ exogenous trend variables. Moderate value. |
| #45 | Branch decomposition (market vs non-market) | Requires ABS Cat. 5204 industry-level VA + employment series; introduces `Q^nm`, `N_OQ` variables. ~2 weeks. Moderate value (non-market ~20% of GDP). |
| #28, #29 | Real housing user cost with `p_IH` deflator | Requires AU new-housing-investment-deflator series. Moderate value. |
| #33, #37 | Energy / non-energy import split (Phase E) | Already noted in STATUS.md as deferred. Requires ABS energy import series + 2 separate import equations. AU as commodity exporter+importer makes this substantively important. ~1 week. |
| #31 | Add emerging-countries weight `ω` to export equation | Requires Asian/EM demand share series. Would help AU-China commodity dynamics. ~3 days. |
| #46 | Tax structure for fiscal-policy analysis | Requires explicit tax-rate × tax-base decomposition for GST/PAYG/company tax. Substantial extension. |
| #48, #58 | Real-forecasting / RBA QE auxiliary models | BLR-equivalent + CPI auxiliary (RBA SMP integration) + public finances (Treasury budget). Out of academic-replication scope. |

**Recommendation**: track these as a "Phase R+1" research backlog. Don't
attempt during the current refit.

---

## Decision points (need user input)

Before executing Phase 0, please confirm:

### D1 — Phase 0 wedge resolution priority

The `pv_X_aux` puzzle (action #18/#34) is the highest-leverage open item but
also the most uncertain. Three options:

- **(a) Run the diagnostic** (Phase 0.1) and follow the decision tree —
  recommended; resolves the question definitively
- **(b) Assume "REAL" interpretation** and skip diagnostic — keeps existing
  posteriors, fastest path
- **(c) Assume "REDUNDANT" interpretation** and execute removal — most
  invasive but strongest FR-BDF alignment if correct

### D2 — Wage Phillips κ_w sign fix scope

Audit #22: Option A flips equation to `-kappa_w·pv_u_gap` AND re-estimates
with positive prior. Option B keeps equation, changes prior to centre on
negative value. Which is preferred?

### D3 — `eq_dln_n_star_bar` fix priority

Action #21 + #17 fix has two components: sign correction + add Δq channel.
- Both together (recommended)?
- Sign-only first, Δq later?

### D4 — Phase 5 research backlog

Confirm that these are deferred:
- i_us (#8/#42) — defer? (1 week)
- Branch decomposition (#45) — defer? (2 weeks)
- Energy import split (#33/#37) — defer? (1 week, already in STATUS.md)
- Or attempt some during current refit?

---

## Risk register

| Risk | Probability | Mitigation |
|---|---|---|
| Phase 1.C/1.D structural changes break BK rank | Medium | Verify after each .mod edit; revert if BK fails; have Phase Q baseline as fallback |
| MCMC posterior shifts so much that paper §5 results no longer hold | Low-Medium | Compare to Phase Q baseline; if MHM degrades by >5 nats, investigate |
| Wedge removal (Phase 1.A) breaks deflator dynamics — long-run prices drift | Medium | Add explicit ECM target equations as part of Phase 1.A; test SS computation before MCMC |
| Phase 0 BGP convergence test fails | Low-Medium | Investigate whether Phase Q forward UIP introduced indeterminacy; may need to dial back beta_uip from 0.92 |
| Working paper rewrite (Phase 4) is larger than estimated | Medium | Scope tightly to "AU adaptations" subsection; defer broader rewrites |
| User changes priority mid-stream | Low | Modular phases; can pause after any phase with intermediate state preserved |

---

## Effort summary

| Phase | Wall time | Compute time | Risk |
|---|---|---|---|
| Phase 0 — diagnostic | 1-2 days | 30 min | Low |
| Phase 1 — structural fixes | 2-3 days | 0 | Medium |
| Phase 2 — MCMC re-run | 1 day | 1 hour | Low |
| Phase 3 — IRF + benchmarks | 1 day | 30 min | Low |
| Phase 4 — documentation | 3-5 days | 0 | Low |
| **Total** | **~3-4 weeks** | **~2 hours** | Medium |

Phase 5 (deferred research) excluded from this estimate.

---

## Suggested sequencing

```
Week 1
  Mon-Tue: Phase 0 diagnostic — pv_X_aux + BGP convergence
  Wed:     Decision review with user (which Phase 1 branch)
  Thu-Fri: Phase 1 structural fixes (1.B/1.C/1.D/1.E)

Week 2
  Mon:     Phase 1.A wedge removal (if Phase 0 said REDUNDANT)
  Tue-Wed: Phase 2 MCMC re-run + verification
  Thu-Fri: Phase 3 IRF regeneration + benchmark comparison

Week 3-4
  Phase 4 documentation pass
  Working paper §4 subsection drafting
  Final audit.md updates marking items resolved
```

---

## Definition of done

This refit is complete when:

- [ ] All 8 ✗ structural mismatches addressed (fixed, removed, or formally
      deferred with rationale)
- [ ] MCMC re-run completed; posterior table updated
- [ ] All 3 model variants (var/hybrid/mce) compile + pass BK rank
- [ ] IRFs regenerated at irf=200; quantitative comparison with FR-BDF
      benchmarks documented for all 7 shocks
- [ ] Forward-guidance puzzle absence still verified (Phase L)
- [ ] LR BGP convergence verified under floating AUD + Phase Q UIP
- [ ] All ⚠ items either fixed, documented in working paper §4, or
      explicitly deferred to Phase 5 backlog
- [ ] STATUS.md updated with Phase R (audit refit) summary
- [ ] audit.md action items annotated with resolution status

---

## Audit document cross-reference

This plan addresses every audit action item except those listed in Phase 5
backlog. Cross-reference:

| Audit # | Phase | Notes |
|---|---|---|
| #1-7 | Phase 4 | §2 architectural notes, document |
| #8 | Phase 5 | Foreign rate `i_us` — deferred |
| #9, #10 | Phase 4 | E-SAT estimation findings, document |
| #11 | Phase 0 | Linked to #18/#34 |
| #12, #13 | Phase 1.B | Quick comment cleanup |
| #14, #53 | Phase 3 | δ_k sensitivity check |
| #15, #16 | Phase 4 | Documentation |
| #17 + #21 | Phase 1.C | `eq_dln_n_star_bar` fix |
| #18, #34 | Phase 0 + 1.A/1.B | Wedge resolution |
| #19 | Phase 4 | AU flat Phillips finding |
| #20 | Phase 5 | Optional `var_pQ` enrichment |
| #22, #23 | Phase 1.D | Wage Phillips |
| #24 | Phase 1.D (or skip) | Output gap level → change in PAC |
| #25, #27 | Phase 4 | Permanent income proxy doc |
| #26 | Phase 1.E | Forward real-rate PV |
| #28-30 | Phase 5 | Housing investment extensions |
| #31, #32 | Phase 5 | Export equation extensions |
| #33, #37 | Phase 5 | Energy import split (Phase E) |
| #35-36 | Phase 4 | Deflator documentation |
| #38, #39 | Phase 4 | Document FR-BDF imports |
| #40 | Phase 0.2 + 4 | BGP test result determines whether to adjust |
| #41 | Phase 5 | Bank lending rate enrichment |
| #42 | Phase 5 | Foreign rate (with #8) |
| #43, #44 | Phase 5 / Phase 4 | Demographic trends + endogenous-trend doc |
| #45 | Phase 5 | Branch decomposition |
| #46 | Phase 5 | Tax structure |
| #47, #48 | Phase 4 / Phase 5 | Fiscal rule + forecasting model docs |
| #49-52 | Phase 3 | Per-shock IRF benchmarks |
| #54 | Phase 0.2 | LR BGP convergence test |
| #55 | Phase 0 / Phase 1.A | Linked to wedge resolution |
| #56 | Phase 1.E | Add `/exp(Δȳ)` correction to pv_yh |
| #57 | Phase 4 | Verify alpha_c_r ↔ σ_2 mapping |
| #58 | Phase 5 | APP experiment expansion |
