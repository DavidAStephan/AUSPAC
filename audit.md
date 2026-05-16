# AUSPAC ↔ FR-BDF wp736 alignment audit

## Phase R refit COMPLETE — 2026-05-15

**MCMC re-run successfully completed** with all 4 structural fixes applied.
Headline: LMD MHM = -790.72 (Phase Q baseline -802.27, **+11.55 nats improvement**).
Forward-guidance puzzle absence preserved (AU-PAC ratio 10.06 at N=12).

See [`STATUS.md`](STATUS.md) Phase R section for full results table and
[`dynare/phase_r_benchmark_table.md`](dynare/phase_r_benchmark_table.md) for
FR-BDF IRF benchmark comparison.

---

## Phase R refit (2026-05-15) — fixes applied

**Status legend for action items**:
- 🟢 **FIXED** — code changed in Phase R / Phase S
- ✅ **CLOSED** — Phase 4 documentation pass complete (audit item resolved in working paper §4.13)
- ✅ **VERIFIED** — Phase S follow-up Dynare run produced quantitative evidence supporting model design
- 📝 **DOCUMENTED** — Phase R / Phase S clarified comments / no functional change needed
- ⏳ **DEFERRED** — Phase 5 research backlog (multi-week)

| # | Item | Status | Notes |
|---|---|---|---|
| #6, #54 | LR BGP convergence test | ✅ VERIFIED | Phase S follow-up (2026-05-16): 1100-quarter simulation under Phase S model + 1 s.d. eps_i shock + zero subsequent shocks. All gap variables converge to |x| < 1e-7 at Q1100 (yhat_au 8.3e-9, pi_au_gap 5.8e-11, s_gap 7.9e-9, i_gap 1.0e-9, dln_c 1.6e-8, dln_ib 1.6e-8). ln_Q non-stationary level settles at finite +2.76 (permanent capital-level effect of temporary monetary shock under PAC adjustment costs — expected). |
| #11 | pv_X_aux doubling test | 📝 DOCUMENTED | Static analysis: REAL interpretation (Phase 0) |
| #14, #53 | δ_k sensitivity check | ✅ VERIFIED | Phase S follow-up (2026-05-16): swept δ_k across 0.0134 (AU baseline 5.4%/yr), 0.020 (8%/yr), 0.025 (10%/yr), 0.030 (12%/yr). 100bp monetary IRF ln_Q peak essentially unchanged (-0.289% to -0.304%, 5% variation), but **Q40 capital-channel tail grows ~10×** from -0.015% (AU) to -0.160% (12%/yr). Confirms slow AU ln_K recovery is **part calibration** (low ABS-measured AU depreciation rate) and **part specification** (PAC adjustment costs). AU value retained at 0.0134 — empirically grounded in ABS 5204 industrial-asset accounts (Phase G); changing it requires re-calibrating the K/Y ratio and user cost. δ_k = 0.0375 (15%/yr FR-BDF audit value) broke SS without re-calibration of dependent params. |
| #17 | Add Δq channel to eq_dln_n_star_bar | 🟢 FIXED | Phase 1.C — `(yhat_au - yhat_au(-1))` added |
| #18, #34 | pv_X_aux puzzle | 📝 DOCUMENTED | Static analysis confirms REAL interpretation; comments improved (Phase 1.B) |
| #21 | dln_tfp sign in eq_dln_n_star_bar | 🟢 FIXED | Phase 1.C — leading sign flipped + → − |
| #22 | Wage Phillips κ_w sign convention | 🟢 FIXED | Phase 1.D — equation flipped + → −, kappa_w reset to 0.32, prior re-centred |
| #23 | Wage Phillips inflation measure | 🟢 FIXED | Phase 1.D — `gamma_w·pi_au` → `gamma_w·pi_c` |
| #26 | PV(real rate gap) in consumption PAC | 🟢 FIXED | Phase 1.E — added `pv_r_lh_gap` + 4 components across 8 .mod files |
| #55 | pv_X_aux behavior under MCE | 📝 DOCUMENTED | Comment added flagging future verification (Phase 1.B) |
| #56 | `/exp(Δȳ)` growth correction in pv_yh | 📝 DOCUMENTED | Skipped — gap form makes correction vanish at SS |
| #57 | α_c_r ↔ σ_2 correspondence | 📝 DOCUMENTED | Different parameterisations; documented in working paper §4 |
| #1-#5, #7, #9, #10, #12, #13, #15, #16, #19, #24, #25, #27, #35, #36, #38-#41, #44, #47, #49-#52 | Documentation flags | ✅ CLOSED | Phase 4 documentation pass (2026-05-16): captured in working paper §4.13 "AU adaptations vs FR-BDF design" — six subsections covering AU empirical findings, structural simplifications, local-market adaptations, calibration imports, fiscal-block differences, and methodological choices |
| #20 | var_pQ enrichment (eps_pQ structural deflator channels in E-SAT inflation eq) | 🟢 FIXED | Phase S (2026-05-16): FR-BDF wp736 §3.1.1 cost-push replication completed. Added structural deflator channels `α_pc·(piQ−pibar_au) + β_pc_m·(pi_m−pibar_au) + γ_oil·dln_pcom` to `eq_au_phillips` across 8 .mod files, replicating FR-BDF's E-SAT where π_Q is on the LHS. BK rank verified on all 3 main variants. MCMC re-run lifted MHM from Phase R −790.72 to **Phase S −789.10** (+1.62 nats). Cost-push transmission now structurally correct: pi_au +0.119 qpp impact (was 0), Taylor rule tightens by Q5, output gap turns negative Q8. ln_Q remains modestly positive because of AU-specific high policy smoothing (λ_i=0.96) + weak piQ→CPI passthrough (α_pc=0.17) — substantive AU finding documented in WP §6.3.5. Forward-guidance puzzle still absent (ratio 10.09 at N=12). |
| (architecture) | Shadow-VAR disconnect from structural shocks | 🟢 FIXED | Phase T (2026-05-16): srecko/FR-BDF aggregate-workflow refactor. The 12 shadow var_* variables (y_gap_var, pi_gap_var, piQ_hat, n_hat, ...) decoupled from structural shocks — a Dynare-implementation workaround inherited from FRB/US — have been replaced by `pac.print()`-generated closed-form expectation formulas referencing LAGGED STRUCTURAL variables (yhat_au(-1), piQ(-1), pi_m(-1), dln_pcom(-1)). Architecture now matches FR-BDF wp1044 §2.2's policy-function approach (inversion of estimated core E-SAT) and Stéphane Adjemian's official Dynare semi-structural workflow. au_pac_v2.mod compiles + BK passes; Bayesian MCMC re-estimation under v2 produced **Laplace LMD = -781.05 / MHM = -781.39** (vs Phase S -788.95/-789.10), a **+7.7 MHM nat improvement** and **+20.66 nats cumulative vs Phase Q baseline**. As a bonus, the wage Phillips slope kappa_w identified with the correct (FR-BDF expected) sign: -0.103 (HPD entirely negative under Phase T sign convention; Phase S had +0.046 with HPD straddling zero). 5 aux .mod files + cherrypick + aggregate workflow proven end-to-end. |
| #8, #28-#33, #37, #42, #43, #45, #46, #48, #58 | Substantive extensions | ⏳ DEFERRED | Phase 5 research backlog (see plan.md) |

### Phase R driver scripts created

- [`dynare/scripts/estimation/run_phase_r_refit.m`](dynare/scripts/estimation/run_phase_r_refit.m)
  — automates Phase 2 (MCMC re-run, ~55 min wall time)
- [`dynare/regen/regen_phase_r_benchmarks.py`](dynare/regen/regen_phase_r_benchmarks.py)
  — produces FR-BDF benchmark comparison table (#49-#52)

### Phase R execution checklist (for user)

After Phase R structural fixes (already applied to all 8 .mod files):

```matlab
% 1. Verify all variants compile + pass BK rank
cd dynare; setup_dynare_path();
dynare au_pac_var noclearall nograph;     % expect BK pass
dynare au_pac noclearall nograph;          % expect BK pass
dynare au_pac_mce noclearall nograph;      % expect BK pass

% 2. Re-run MCMC (~55 min)
run_phase_r_refit;

% 3. Apply posterior writeback
% (Python from repo root)
% python3 dynare/tools/apply_mcmc_writeback.py

% 4. Regenerate IRFs at irf=200 (already configured)
dynare au_pac_var noclearall nograph;
dynare au_pac noclearall nograph;
dynare au_pac_mce noclearall nograph;

% 5. Generate FR-BDF benchmark comparison
% python3 dynare/regen/regen_phase_r_benchmarks.py

% 6. Verify forward-guidance puzzle absence still holds (Phase L)
forward_guidance;          % should still give linear ratio ~10 at N=12

% 7. Verify long-run BGP convergence (audit #54)
% Configure simul_replic with extended horizon, run unconditional sim
```

### Acceptance criteria

- [ ] All 3 main variants pass BK rank under Phase R
- [ ] MCMC LMD doesn't degrade by >5 nats vs Phase Q (-802.27)
- [ ] κ_w posterior is now negative-signed (or HPD includes 0 with negative mass)
- [ ] Output-gap response `yhat_au` peak under monetary shock more aligned with FR-BDF -0.15
- [ ] Forward-guidance puzzle absence preserved (Phase L test passes)
- [ ] LR BGP convergence verified (audit #54)
- [ ] FR-BDF benchmark comparison table (Phase 3) shows AUSPAC values within
      reasonable distance of FR-BDF benchmarks for all 7 shocks

---

## Phase 0 (refit) results — 2026-05-15

**`pv_X_aux` puzzle (#18 / #34) — RESOLVED via static analysis**

Verdict: **REAL interpretation (path 1.B in plan.md)**. The wedges are NOT
redundant. `var_X` equations in `esat_enriched` use **VAR shadow variables**
(`y_gap_var`, `i_gap_var`, etc.) defined at [au_pac.mod:158-162](dynare/au_pac.mod#L158),
while `pv_X_aux` equations use **structural variables** (`yhat_au`, `i_gap`,
etc.). Under any structural shock without a corresponding `eps_var_*` shock,
these diverge, so the wedge captures the difference between simplified-VAR
forecasts and full-model realizations. Action: improve docs (Phase 1.B), do
not remove.

**LR BGP convergence (#54) — DEFERRED to user Dynare run**

Static analysis cannot test convergence. User must run extended unconditional
simulation 2024Q1 → 2300Q1. Test instructions documented in plan.md Phase 0.2.
Risk: low (Phase Q forward UIP refresh validated impact dynamics; LR
behavior unverified).



Section-by-section comparison of the FR-BDF model (Lemoine et al. 2019, Banque de
France WP #736) against the AUSPAC implementation in `dynare/au_pac.mod` and
sibling variants.

**Verdict legend:**
- ✓ **Aligned** — FR-BDF spec correctly implemented (possibly with AU calibration)
- ⚠ **Differs** — intentional AU adaptation, flagged for visibility
- ✗ **Mismatch** — likely bug or unintended divergence, action required

**Started:** 2026-05-15. Driven by discovery that `eps_tfp` was specified as a
growth-rate AR(1) shock with ρ=0.99 (integrated 100×) instead of FR-BDF's
permanent-level shock convention (§5.2.7). See [STATUS.md](STATUS.md) for the
fix log; this file accumulates the systematic comparison.

---

## Section progress

| # | wp736 section | Pages | Status |
|---|---|---|---|
| 1 | §2 Bird's-eye view (architecture) | 8–14 | done 2026-05-15 |
| 2 | §3.1 E-SAT expectations satellite | 15–22 | done 2026-05-15 |
| 3 | §3.2–3.3 PAC microfoundations + PV computation | 23–28 | done 2026-05-15 |
| 4 | §4.3 Supply block (CES, trend efficiency) | 30–40 | done 2026-05-15 |
| 5 | §4.4 VA price | 41–44 | done 2026-05-15 |
| 6 | §4.5 Labor market (supply + demand) | 45–52 | done 2026-05-15 |
| 7 | §4.6.1 Household consumption | 53–60 | done 2026-05-15 |
| 8 | §4.6.2–4.6.3 Business + household investment | 61–68 | done 2026-05-15 |
| 9 | §4.6.4 External trade | 69–74 | done 2026-05-15 |
| 10 | §4.7 Demand deflators (6 of them) | 75–83 | done 2026-05-15 |
| 11 | §4.8 Financial block (rates, FX, asset positions) | 84–95 | done 2026-05-15 |
| 12 | §4.9 Trends | 96–97 | done 2026-05-15 |
| 13 | §4.10–4.11 Accounting + conditional projections | 98–101 | done 2026-05-15 |
| 14 | §5 Long-run convergence + structural IRFs | 102–115 | done 2026-05-15 |
| 15 | §6 MCE / forward guidance / APP | 116–130 | done 2026-05-15 |

---

## §2 Bird's-eye view of the model — findings

Architectural review only; deep equation-level checks belong to §3–§4 audits. Reading
of wp736 pp. 8–14 versus `dynare/au_pac.mod` block markers and STATUS.md.

### §2.1 Role of expectations + PAC framework

| Item | FR-BDF spec | AUSPAC | Verdict |
|---|---|---|---|
| Long-term targets independent of rest of model, neoclassical+monopolistic | yes | yes (capital, labor, VA price targets per CES + markup) | ✓ |
| 5 PAC behavioural equations | VA price, consumption, business inv, household inv, employment | same 5 | ✓ |
| Targets driven by aggregate demand + real factor prices | yes | yes | ✓ |
| Financial block: no PAC, expectations via no-arbitrage (term structure, UIP) | yes | yes | ✓ |

### §2.2 Expectations formation — three regimes

| Regime | FR-BDF | AUSPAC variant |
|---|---|---|
| VAR-based (E-SAT) | yes | `dynare/au_pac_var.mod` |
| Model-consistent (MCE) | yes | `dynare/au_pac_mce.mod` |
| Hybrid (financial-MCE, non-financial VAR) | yes | `dynare/au_pac.mod` |

Verdict: ✓ All three regimes implemented as separate compiled .mod files.

E-SAT core: FR-BDF "structural VAR estimated with Bayesian methods... IS and Phillips
curves for euro area and France and a Taylor rule for euro area." AUSPAC E-SAT is the
12-equation enriched VAR `esat_enriched` declared at [au_pac.mod:953](dynare/au_pac.mod#L953),
which adds auxiliary equations beyond the core IS+Phillips+Taylor block.

⚠ **Note** — AUSPAC's E-SAT VAR is enlarged (12 eqs) vs FR-BDF's narrower core. This
is intentional per Phase B (auxiliary coefficients re-estimated 2026-05-09). Defer
detailed E-SAT comparison to §3.1 audit.

### §2.3 Supply, VA price, labor market

| Item | FR-BDF | AUSPAC | Verdict |
|---|---|---|---|
| CES production function (capital + labor with labor-augmenting tech progress) | eq. 24 | [au_pac.mod:1183](dynare/au_pac.mod#L1183), Phase G + 2026-05-14 recalibration | ✓ |
| Capital accumulation eq | yes | [au_pac.mod:1122](dynare/au_pac.mod#L1122) | ✓ |
| Wage Phillips curve à la Galí (2011), vertical in LR | yes | [au_pac.mod:1306](dynare/au_pac.mod#L1306), `eq_pi_w` | ✓ |
| LR unemployment = exogenous level | yes | `u_ss_au` calibrated; `u_gap` mean-reverts | ✓ |
| VA price PAC, target from CES factor-price frontier + markup | yes | [au_pac.mod:1228](dynare/au_pac.mod#L1228), `eq_piQ_star` | ✓ (deeper check in §4.4) |

### §2.4 Demand components + deflators

| Item | FR-BDF | AUSPAC | Verdict |
|---|---|---|---|
| Consumption target = permanent income + interest-rate gap | yes | [au_pac.mod:81](dynare/au_pac.mod#L81), `pv_yh`, `r_lh_gap` | ✓ |
| HtM (hand-to-mouth) consumers via current output gap | yes | included in PAC: `b_yh_c · yhat_au` term | ✓ |
| Business investment target from steady-state I/Q ratio + user cost | yes (Tobin's Q) | [au_pac.mod:88](dynare/au_pac.mod#L88), `eq_dln_ib_star_bar` | ✓ |
| Business inv PAC extended with current value-added growth (HtM-firm proxy) | yes (§2.4 last para — "ad hoc term... liquidity-constrained firms") | check via grep — present? | ⚠ verify in §4.6.2 audit |
| Household inv target = permanent income + housing user cost + relative housing price | yes | [au_pac.mod:95](dynare/au_pac.mod#L95), Phase C `b_ph_ih=0.0099` | ✓ |
| Imports target = real exch rate + import-intensity-weighted demand | yes | [au_pac.mod:120](dynare/au_pac.mod#L120), Phase D v3 IAD-weighted demand | ✓ |
| Exports target = world demand + real exch rate | yes | same | ✓ |
| **Trade short-run = ECM not PAC** | yes (explicit in §2.4) | check our spec — is it ECM or PAC? | ⚠ verify in §4.6.4 audit |
| Demand deflators = simple ECM toward weighted average of VA price + import price | yes | [au_pac.mod:133](dynare/au_pac.mod#L133) | ✓ |

### §2.5 Financial block

| Item | FR-BDF | AUSPAC | Verdict |
|---|---|---|---|
| Short rate = main interest rate, drives all expectations | 3-month Euribor | RBA cash rate `i_au` | ⚠ AU adaptation |
| Short-rate process in simulation = AR(1) with historical-mean anchor (or Taylor rule) | yes | check what we have | ⚠ verify in §4.8.1 |
| 10Y govt bond rate = expectations component + time-varying term premium | term structure | `i_10y_au` with term premium | ✓ |
| **Exchange rates via UIP** | yes | yes — Phase Q forward UIP added 2026-05-15 | ✓ |
| WACC = function of bank lending rate, bond rate, cost of equity | yes | `wacc_au` defined | ✓ (deeper check in §4.8.3) |
| Bank lending rate transmission to households + firms | yes | yes | ✓ |
| Net financial assets per agent | yes | sector financial accounts at [au_pac.mod:177](dynare/au_pac.mod#L177) | ✓ (Phase N validated) |

⚠ **Foreign block**: FR-BDF uses the Euro Area (ECB Taylor rule, EA inflation/output
gap). AUSPAC uses the US (FRED data, fed funds rate, US output gap, US CPI). This is
the largest single architectural divergence — intentional, AU's macro is more
US-correlated than EA-correlated. Affects: E-SAT foreign equations, UIP, anchors.

### §2.6 Accounting framework + public finances

| Item | FR-BDF | AUSPAC | Verdict |
|---|---|---|---|
| Branch decomposition (market/non-market) of value-added + labor-market vars | yes (§4.10) | partial — we have GDP identity at [au_pac.mod:143](dynare/au_pac.mod#L143) | ⚠ verify §4.10 audit |
| Energy/non-energy decomposition of imports | yes | Phase E deferred per STATUS.md | ⚠ AU adaptation gap, documented |
| Fiscal rule = social transfers stabilise gov't net asset ratio | yes | `eq_b_g`, `tau_TG` rule at [au_pac.mod:177+](dynare/au_pac.mod#L177) | ✓ (Phase N validated) |
| Public finance "simulation mode" with effective tax rates | yes | check via §4.10 audit | ⚠ |

### §2.7 Long run of the model — **CRITICAL spec difference**

FR-BDF (p. 13):
> "Contrary to closed-economy models, the real interest rate here is **exogenous in
> the long run**, determined by the exogenous nominal interest rate and by the ECB
> inflation target. Setting the growth rate of world demand and the inflation rates
> of competing countries equal to rates at the domestic level for ensuring a balanced
> growth path, the convergence of demand toward the long run output determines, in
> our small open economy framework, the **long run equilibrium of the real exchange
> rate**, a key driver of external trade. As competitors' prices are exogenous, as
> well as the nominal exchange rate in the long run, the level of the real exchange
> rate determines the level of the domestic value added price in the long run."

This relies on the Eurozone fixed-exchange-rate assumption: nominal rate is exogenous
because it's an ECB policy variable that France can't influence; real exchange rate
LR equilibrium pins the LR domestic VA price level.

In AUSPAC: AUD is **floating**, with UIP determining `s_gap` dynamically. Implications:
- The nominal AU short rate `i_au` is **endogenous** in our long run (Taylor rule via
  E-SAT); it's not pinned by an external authority.
- Real exchange rate LR equilibrium is NOT determined the same way — UIP relates
  expected exchange-rate change to interest-rate differential, which means the LR
  real rate is jointly determined with the LR exchange rate, not exogenous to it.

| Item | FR-BDF | AUSPAC | Verdict |
|---|---|---|---|
| LR real rate exogenous | yes (Eurosystem) | NO — endogenous via Taylor + UIP | ⚠ structurally different (AU floating) |
| LR real exchange rate pinned by trade-balance equilibrium | yes | yes, similar mechanism via UIP convergence | ✓ |
| LR output growth = labor efficiency + demography | yes | yes — `dln_y_star = α·dln_k + (1-α)·dln_n_star_bar + dln_tfp`, all → 0 in gap model | ✓ |
| LR inflation = central bank target | ECB target | RBA target — `pi_ss_au = 0.625` (2.5% annual) | ✓ |
| Convergence to BGP demonstrated in unconditional simulation | yes (Fig 5.1) | partially — see Phase N sectoral validation; full BGP convergence not formally re-tested under floating regime | ⚠ defer to §5.1 audit |

⚠ **Action item**: when we get to §5.1 audit, formally re-verify long-run BGP
convergence for our floating-AUD specification. The Phase Q forward UIP refresh
changed exchange-rate dynamics significantly; need to check that the LR real rate /
exchange rate / inflation joint equilibrium is well-defined.

### §2.8 Estimation

| Item | FR-BDF | AUSPAC | Verdict |
|---|---|---|---|
| Block-by-block estimation (not joint) | yes | yes — Phases A–G in STATUS.md | ✓ |
| Estimated under VAR-based expectations only | yes | yes — `au_pac_bayesian.mod` is the VAR variant | ✓ |
| Iterative OLS for short-run PAC equations (à la FRB/US) | yes | yes — [scripts/estimation/estimate_pac.m](dynare/scripts/estimation/estimate_pac.m) | ✓ |
| Bayesian VAR for E-SAT core | yes | yes — `au_esat.mod`, `run_bayesian_estimation.m` | ✓ |
| Discount factor β calibrated to 0.98 (most blocks) | yes (p. 29) | check `beta_pac` value | ⚠ verify in §3 audit |

### §2 summary

**Architectural alignment: strong** (✓ across all 6 functional blocks).

**Flagged AU adaptations** (⚠ — intentional, document but don't fix):
- Foreign block: US replaces Euro Area
- Floating AUD with UIP replaces fixed Eurozone exchange rate
- Commodity-price channel added (Stage 11b) for AU's mining-driven economy
- LR real rate is **endogenous** in AUSPAC (vs exogenous in FR-BDF) — direct
  consequence of floating exchange rate

**Action items for later sections**:
1. ⚠ §3.1 audit — verify E-SAT enriched VAR (12 eqs) maintains FR-BDF's IS+Phillips+Taylor core structure
2. ⚠ §4.6.2 audit — confirm business inv PAC has the "ad hoc current value-added growth" term FR-BDF mentions in §2.4
3. ⚠ §4.6.4 audit — confirm trade short-run dynamics use **ECM** (not PAC), per FR-BDF §2.4
4. ⚠ §4.8.1 audit — verify short-rate process in simulation (AR(1) with historical mean, or Taylor rule)
5. ⚠ §4.10 audit — verify market/non-market branch decomposition + simulation-mode tax rates
6. ⚠ §5.1 audit — formally re-verify LR BGP convergence under floating AUD
7. ⚠ §3 audit — verify PAC discount factor β = 0.98

No ✗ mismatches identified at the architectural level. The TFP shock fix
(2026-05-15) closed the only known structural divergence.

---

## §3.1 E-SAT expectations satellite — findings

Comparing wp736 §3.1.1 (pp. 16–17) E-SAT core 8 equations against
[`dynare/au_esat.mod`](dynare/au_esat.mod) (standalone version) and the enriched
12-eq `var_model esat_enriched` declared at [au_pac.mod:961](dynare/au_pac.mod#L961).

### Core 8-equation E-SAT (FR-BDF eqs in §3.1.1)

FR-BDF state vector: `Z = [1, ŷ_t, i_t, π_Q_t, ŷ_ea_t, π_ea_t, ī_t, π̄_t, π̄_ea_t]'`
AUSPAC state vector: same shape but ea→us substitutions: `[1, yhat_au, i_au, pi_au, yhat_us, pi_us, ibar, pibar_au, pibar_us]`.

| # | FR-BDF equation | AUSPAC equation | Verdict |
|---|---|---|---|
| 1 | French IS: `(1-λ_q L)ŷ = -σ_q (real_rate_gap)_{-1} + δ_q ŷ_ea + ε_q` | `eq_au_is` ([au_pac.mod:997](dynare/au_pac.mod#L997)): identical PLUS extra `+ λ_dom · yhat_dom` term | ⚠ AU adds Keynesian-multiplier bridge term (Phase 7a, lambda_dom=0.399) — not in FR-BDF |
| 2 | French Phillips: `(1-λ_π L)(π_Q-π̄) = κ_π ŷ_{-1} + ε_π` | `eq_au_phillips` — same form | ✓ |
| 3 | Taylor rule: `(1-λ_i L)(i-ī) = (1-λ_i)(α π_ea_gap_{-1} + β ŷ_ea_{-1}) + ε_i` — reacts to **EA** (foreign) inflation/output | `eq_taylor` — RBA reacts to **AU** (domestic) inflation/output | ✓ AU adaptation: RBA is independent CB, must react to AU vars |
| 4 | EA IS: `(1-λ_q,ea L)ŷ_ea = -σ_q,ea (real_rate_gap)_{-1} + ε_q,ea` — has full real-rate channel | `eq_us_is` ([au_pac.mod:1014](dynare/au_pac.mod#L1014)): `yhat_us = λ_q,us · yhat_us(-1) + ε_q,us` — **pure AR(1), no real rate** | ✗ **MISMATCH** |
| 5 | EA Phillips: `(1-λ_π,ea L)(π_ea-π̄_ea) = κ_π,ea ŷ_ea_{-1} + ε_π,ea` | `eq_us_phillips` — same form | ✓ |
| 6 | LR i anchor: AR(1) toward ī | `eq_ibar` — AR(1) toward `i_ss` | ✓ |
| 7 | LR domestic π anchor | `eq_pibar_au` — AR(1) toward `pi_ss_au` | ✓ |
| 8 | LR foreign π anchor | `eq_pibar_us` — AR(1) toward `pi_ss_us` | ✓ |

### ✗ Mismatch: foreign-block IS curve

FR-BDF EA IS curve (eq 4) responds to the EA real-rate gap — even though France
can't influence the ECB rate, the EA *itself* has a Taylor-rule stabilization
mechanism baked in via the same `i_t` driving EA real rates.

AUSPAC's `eq_us_is` is a pure AR(1) with no real-rate channel. There is no
US short rate (`i_us`) variable in our model, so we can't represent a Fed
real-rate response. Consequence: US output gap shocks decay **only via**
`λ_q,us = 0.806` autocorrelation (~3-quarter half-life), with no internal
Fed-policy feedback. In FR-BDF, EA shocks decay via both AR persistence AND
EA-Taylor feedback through real rates.

**Why this matters for AU**:
- US output gap is a regressor in our AU IS curve (eq 1, `δ · yhat_us`)
- A US shock under our spec → fast-decaying US output gap → fast-decaying AU output co-movement effect
- Under FR-BDF-style spec → US shock would have hump-shaped recovery (Fed tightening → real rates → demand) → longer AU spillover

**Action required**: Add `i_us` (US short rate, exogenous AR(1) is fine), an
`ibar_us` (US LR rate anchor), and reformulate `eq_us_is` with the real-rate
channel:
```
i_us_gap = i_us - ibar_us
yhat_us = λ_q,us · yhat_us(-1) - σ_q,us · (i_us_gap(-1) - pi_us_gap(-1)) + ε_q,us
```
Optionally also add a US Taylor rule (`eq_us_taylor`) if we want explicit Fed
policy feedback. Calibration: σ_q,us could be borrowed from FR-BDF's σ_q,ea = 0.54
or estimated from FRED data.

This is a deliberate-looking simplification (not a coding bug), but it does
diverge from the FR-BDF blueprint and likely under-attenuates US-shock spillovers.
**Defer the fix** until we have user agreement — it requires adding 2 new
endogenous variables across 8 .mod files plus an i_us data series in the E-SAT
estimation dataset.

### ⚠ AU extension: `λ_dom · yhat_dom` term in AU IS curve

[au_pac.mod:1001](dynare/au_pac.mod#L1001) adds `+ lambda_dom * yhat_dom` to the
AU IS curve, where `yhat_dom` is a weighted sum of demand-component growth rates
(per [au_pac.mod:802](dynare/au_pac.mod#L802) comment). `lambda_dom = 0.399`.

Comment in code: *"closes the Keynesian multiplier loop: monetary policy → demand
components → yhat_dom → yhat_au → inflation → policy"*.

This term is **not** in the FR-BDF E-SAT spec — it's an AUSPAC-specific extension
(Phase 7a per the comment). It introduces a feedback channel from disaggregated
demand back into the IS curve. Defensible as a way to harden the model's
Keynesian multiplier under VAR-based expectations, but it changes the E-SAT
companion matrix interpretation: the auxiliary VAR no longer purely satisfies
Rudebusch & Svensson (1999) structural VAR assumptions FR-BDF cites.

⚠ **Verify** in `au_esat.mod` (the standalone Bayesian-estimation version):
the `yhat_dom` term is **NOT** there ([au_esat.mod:124-128](dynare/au_esat.mod#L124)),
which is correct — the standalone E-SAT has nowhere to source `yhat_dom` from.
So `lambda_dom` only enters the full-model `au_pac.mod`. This means the AU IS
curve in the full model differs from the AU IS curve we Bayesian-estimate in
isolation — there's a **specification gap between estimation and use** worth
documenting.

### Enriched 12-equation `esat_enriched` VAR

FR-BDF says (§3.1.1, p. 17–18 transition):
> "These eight equations which form the core of the ESAT model are not always
> sufficient to describe the formation of agents' expectations... This will
> require adding auxiliary equations into the system."

And gives an example for an employment-target auxiliary `n̂*_t`:
`(1-λ_{n̂*} L) n̂*_t = a_{n̂*} ŷ_{t-1} + b_{n̂*} (i-ī)_{t-1} + c_{n̂*} (π_Q-π̄)_{t-1} + ε`

AUSPAC's `esat_enriched` ([au_pac.mod:961](dynare/au_pac.mod#L961)) adds 7 such
auxiliaries on top of the 5 core dynamic state vars (5 + 7 = 12 equations):

| Tag | Variable | Sensitivities | FR-BDF table |
|---|---|---|---|
| `var_y` | `y_gap_var` | core IS (no `λ_dom·yhat_dom` here — uses pure FR-BDF form) | core eq 1 |
| `var_i` | `i_gap_var` | core Taylor | core eq 3 |
| `var_pi` | `pi_gap_var` | core Phillips | core eq 2 |
| `var_u` | `u_gap_var` | Okun's law on `y_gap_var(-1)` | Table 4.5.2 |
| `var_yus` | `yhat_us_var` | AR(1) | core eq 4/5 (foreign) |
| `var_pQ` | `piQ_hat` | y, i, pi, u gap channels | Table 4.4.4 |
| `var_n` | `n_hat` | y, i, pi, u gap channels | Table 4.5.7 |
| `var_yh` | `yh_ratio_hat` | y, u gap channels | Table 4.6.3 |
| `var_c` | `c_hat` | y, i, pi, u, yh gap channels (nested PV²) | Table 4.6.4 |
| `var_ib` | `ib_hat` | y, pi, u gap channels (no i — separate `var_rKB`) | Table 4.6.11 |
| `var_rKB` | `rKB_hat` | i gap only | Table 4.6.12 |
| `var_ih` | `ih_hat` | y, i, pi, u gap channels | Table 4.6.16 |

| Item | FR-BDF | AUSPAC | Verdict |
|---|---|---|---|
| Pattern: each auxiliary has rho-AR(1) + sensitivities to core gaps | yes | yes | ✓ |
| Auxiliary equations leave core unaffected (last row of B = 0 above core) | yes | yes (pure VAR(1) form, no contemporaneous core terms) | ✓ |
| FR-BDF auxiliaries shown have 3 sensitivities (y, i, pi); AUSPAC adds u | n/a | adds u_gap channel everywhere | ⚠ AU enriched — defensible |
| `var_y` here uses pure FR-BDF IS form (not the `λ_dom`-augmented one) | n/a | yes — clean separation between expectation-VAR and structural IS | ✓ thoughtful |

Verdict on enriched VAR: ✓ **Correctly implements FR-BDF auxiliary-VAR extension
pattern**. The `var_y` correctly uses FR-BDF's clean IS form (not the
λ_dom-augmented structural form), so the expectation-formation mechanism is
internally consistent.

### Bayesian estimation: AU vs FR-BDF posterior comparison

Both estimate the core 8-eq E-SAT via Bayesian methods (FR-BDF: pre-crisis
1999Q1–2008Q4; AUSPAC: posterior in `au_esat.mod` lines 88–104).

| Param | FR-BDF mean (Table 3.1.1) | AUSPAC mean | Notable? |
|---|---|---|---|
| σ_q (IS sensitivity) | 0.28 | 0.166 | AU lower real-rate sensitivity |
| κ_π (Phillips slope) | 0.08 | 0.058 | similar |
| λ_q (IS persistence) | 0.73 | 0.448 | AU much less persistent |
| λ_π (Phillips persistence) | 0.58 | 0.263 | AU much less persistent |
| λ_i (Taylor inertia) | 0.92 | 0.828 | similar |
| **α_i (Taylor inflation reaction)** | **1.19** | **0.279** | ⚠ AU **violates Taylor principle** (α < 1) |
| β_i (Taylor output reaction) | 0.09 | 0.135 | AU more output-aggressive |
| δ (foreign IS spillover to domestic) | 0.08 | 0.199 | AU **2.5× more sensitive** to foreign output |
| λ_ī (LR rate anchor) | 0.985 (calibrated) | 0.985 | matches ✓ |
| λ_π̄ (LR π anchor) | 0.93 (estimated) | 0.93 (calibrated) | matches |
| π̄ (LR inflation, annualized) | 1.9% (ECB target) | 2.5% (RBA target) | ✓ AU adaptation |

⚠ **Two notable estimation findings worth flagging in §5 audit**:
1. **α_i = 0.28 < 1** — AU Taylor rule violates the Taylor principle. RBA's
   estimated reaction to inflation is below the threshold for determinacy.
   Could reflect the RBA's "flexible inflation targeting" stance, or it could
   indicate sample/identification issues. Likely warrants a robustness check
   with a tighter prior on α_i (FR-BDF's prior was Normal(1.5, 0.25)).
2. **δ = 0.199** — AU's IS curve is 2.5× more sensitive to foreign output gap
   than France's was to EA. Reflects AU's commodity-export exposure to global
   demand. Substantively correct but worth documenting.

### §3.1 summary

**Verdict on E-SAT specification**:

- **Core architecture: ✓ aligned** (8 equations, same A/B matrix structure, same
  Bayesian estimation approach)
- **Auxiliary VAR pattern: ✓ correctly implemented** (12-eq enriched VAR
  follows FR-BDF's auxiliary-equation extension pattern; clean separation
  between expectation-formation and structural IS curve)
- **One ✗ mismatch**: foreign-block IS curve is pure AR(1) instead of a full
  IS-with-real-rate-channel. Requires adding `i_us` and `ibar_us` to align.
  Defer until user decision.
- **One ⚠ AU extension**: `λ_dom · yhat_dom` Keynesian-multiplier bridge in the
  full-model AU IS curve. Documented; correctly excluded from the
  expectation-VAR `var_y` to avoid contaminating expectations.
- **Two ⚠ estimation flags**: α_i < 1 (Taylor principle violation), δ = 0.20
  (high foreign sensitivity). Both are estimation results, not spec issues —
  flag for §5 IRF audit.

**Action items added**:
8. ⚠ §3.1 follow-up: add `i_us` + `ibar_us` to E-SAT and reformulate `eq_us_is`
   with real-rate channel (matches FR-BDF eq 4 structure). Requires data
   sourcing (FRED fed funds rate) + 2 new endogenous variables across 8 .mod
   files. **User decision required**.
9. ⚠ §5 IRF audit: re-examine α_i < 1 result with tighter prior; consider
   whether AU Taylor rule needs reformulation.
10. ⚠ Document the `λ_dom · yhat_dom` extension prominently — it's an
    estimation-vs-use specification gap (Bayesian estimation in `au_esat.mod`
    excludes it; full-model use in `au_pac.mod` includes it).

---

## §3.2–3.3 PAC microfoundations + present values — findings

### §3.2.1 Cost function and rational error-correction equation

FR-BDF PAC cost function (eq 2):

```
C_t = Σ_{i≥0} β^i [ (y_{t+i} - y*_{t+i})²  -  Σ_{k=1}^m b_k ((1-L)^k y_{t+i})² ]
```

Standard Brayton et al. (2000) / Tinsley (2002) form. After differentiation, the
m-th-order PAC equation (eq 5) with stationary/nonstationary target decomposition
(eq 11) is:

```
Δy_t = a_0 (y*_{t-1} - y_{t-1})  +  Σ_{k=1}^{m-1} a_k Δy_{t-k}  +  PV(Δŷ*)_t  +  PV(Δȳ*)_t
```

| Item | FR-BDF | AUSPAC | Verdict |
|---|---|---|---|
| Five PAC equations using this form | VA price, consumption, business inv, household inv, employment | same five at [au_pac.mod:1283](dynare/au_pac.mod#L1283) (`eq_piQ_pac`), 1367 (`eq_n_pac`), 1418 (`eq_c_pac`), 1472 (`eq_ib_pac`), 1519 (`eq_ih_pac`) | ✓ |
| Implementation: Dynare native `pac_expectation()` macro on the auxiliary VAR | n/a (FR-BDF predates Dynare's PAC support) | yes — `pac_model(auxiliary_model_name=esat_enriched, discount=beta_pac, model_name=pac_X)` at [au_pac.mod:968-972](dynare/au_pac.mod#L968) | ✓ AU uses Dynare 6.5 native PAC |
| Discount factor β | 0.98 (most blocks; consumption uses 0.95 — see §4.6.1) | `beta_pac = 0.98` ([au_pac.mod:853](dynare/au_pac.mod#L853)); consumption uses `beta_c = 0.95` ([au_pac.mod:1392](dynare/au_pac.mod#L1392)) | ✓ matches |
| Stationary/nonstationary target split (eq 10) — each PAC has its own `omega` share | yes | yes — `omega_pQ=0.46`, `omega_n`, `omega_c`, `omega_ib`, `omega_ih` parameters at [au_pac.mod:311+](dynare/au_pac.mod#L311) | ✓ |

### §3.2.2 Growth neutrality constraint (eq 9)

FR-BDF eq 9 adds an additive `[1 - Σ a_k - Σ d_i] · g` term to ensure that at the
balanced growth path (Δy_t = Δy*_t = g), the error-correction term vanishes.

| Item | FR-BDF | AUSPAC | Verdict |
|---|---|---|---|
| Growth-neutrality correction term added to PAC eqs | yes — eq 9, term `[1-Σa-Σd]·g` | NOT explicitly added because we're in **gap form**: at SS, `dln_*_star_bar = 0`, so g = 0 and the correction term is identically zero | ✓ correct by construction |
| Comment at [au_pac.mod:1410](dynare/au_pac.mod#L1410) says "handled by 'growth' option in pac_model" but no `growth=` is set | n/a | comment is misleading — `growth=` option not used because g=0 everywhere | ⚠ minor doc inaccuracy |

⚠ **Action item**: clarify the comment at [au_pac.mod:1410](dynare/au_pac.mod#L1410)
to read: "Growth neutrality holds trivially in gap form (g=0 at SS); no `growth=`
option needed in the `pac_model` declaration." Apply across all 5 PAC equation
comments.

### §3.3.1 PV of expected target changes — VAR-based and MCE forms

FR-BDF eqs (16)-(17) for VAR-based:
```
PV(Δŷ*)_{t|t-1} = k_0 · Z_{t-1}     (cyclical / stationary)
PV(Δȳ*)_{t|t-1} = k_1 · Z_{t-1}     (trend / nonstationary)
```
where k_0, k_1 are 1×n vectors derived from PAC polynomial A and VAR companion
matrix H per eqs (14)-(15).

FR-BDF eqs (19)-(20) for MCE: recursive forms with explicit forward leads.

| Item | FR-BDF | AUSPAC | Verdict |
|---|---|---|---|
| VAR-based PV via H companion matrix | eqs 14-17 | Dynare's `pac_expectation(pac_X)` macro computes this internally given the `var_model` declaration | ✓ delegated to Dynare 6.5 |
| MCE PV via recursive forward leads | eqs 19-20 | Dynare auto-handles when the model uses leads — `au_pac_mce.mod` activates this regime | ✓ delegated to Dynare 6.5 |
| Auxiliary equations added to E-SAT for target variables outside core | yes (last paragraph p. 17 → p. 18) | yes — 7 auxiliaries in `esat_enriched` (var_pQ, var_n, var_yh, var_c, var_ib, var_rKB, var_ih) cover the 5 PAC targets + 2 income/user-cost wedges | ✓ |

### ⚠ AUSPAC-specific: additive `pv_X_aux` "backward expectation correction"

This is a notable AUSPAC pattern *not* in the FR-BDF spec. Each PAC equation
includes both `pac_expectation(pac_X)` AND an additive `pv_X_aux` term:

```matlab
[name = 'eq_piQ_pac']
diff(pQ_level) = b0_pQ * (piQ_hat(-1) - pQ_level(-1))
               + b1_pQ * diff(pQ_level(-1))
               + pac_expectation(pac_pQ)         ← FR-BDF eq 11 PV term
               + b2_pQ * yhat_au
               + b_covid_* * dummies
               + pv_piQ_aux                      ← AU additive wedge (NOT in FR-BDF)
               + eps_pQ;
```

`pv_X_aux` ([au_pac.mod:1268-1279](dynare/au_pac.mod#L1268)) is structurally identical to the
auxiliary equations inside `esat_enriched` (var_X), but added externally:

```matlab
pv_piQ_aux = rho_pQ_aux * pv_piQ_aux(-1) + a_pQ_y * yhat_au(-1) + a_pQ_i * i_gap(-1)
           + a_pQ_pi * pi_au_gap(-1) + a_pQ_u * u_gap(-1)
```

Comment at [au_pac.mod:1259](dynare/au_pac.mod#L1259):
> "BACKWARD EXPECTATION CORRECTIONS (additive first-order wedge) — These AR(1)
> terms represent the DIFFERENCE between E-SAT simplified forecasts and the full
> model RE solution. They create the backward/forward wedge at first-order
> perturbation. ... Absent in MCE (forward leads already capture everything)."

| Item | FR-BDF | AUSPAC | Verdict |
|---|---|---|---|
| Additive backward wedge on top of pac_expectation | n/a — FR-BDF's `pac_expectation` equivalent (their eqs 14-17 implementation) is supposed to give the full PV directly | yes — adds `pv_X_aux` term to all 5 PAC equations | ⚠ AU-specific — *potentially* double-counts cyclical (ŷ*) component |
| Wedge is zero in MCE variant | n/a | comment says "absent in MCE" — verify in `au_pac_mce.mod` | ⚠ verify |

⚠ **Risk**: if `pac_expectation(pac_pQ)` already delivers PV(Δŷ*) + PV(Δȳ*) correctly
via the enriched VAR (which includes `var_pQ` mirroring `pv_piQ_aux`), then adding
`pv_piQ_aux` separately may **double-count** the cyclical channel. The comment
frames it as a "wedge" — a *correction* between simplified VAR and full RE — but
the term has no compensating subtraction; it's just additive.

Two interpretations:
1. **Intentional reweighting**: The Dynare `pac_expectation` macro delivers the
   theoretical `k_0 Z_{t-1} + k_1 Z_{t-1}` exactly per eqs (14)-(17), but the
   coefficient signs/magnitudes from auxiliary VAR estimation may not be what's
   needed; `pv_X_aux` provides additional flexibility. In this case, the Bayesian
   posterior on PAC `b_*` coefficients absorbs the wedge — fine for fit but
   confounds interpretation.
2. **Genuine duplication**: If `var_pQ` in `esat_enriched` and `pv_piQ_aux` are
   running the same regression on the same RHS variables, the model effectively
   has the cyclical-channel coefficient counted twice. This would show as
   over-amplified IRFs to interest rate / inflation gap shocks in the VAR variant,
   matched in the MCE variant by the absence of the wedge.

⚠ **Action item**: write a short test that computes PAC IRFs with `pv_X_aux ≡ 0`
forced and compares against the published IRFs. If IRFs are materially different,
interpretation (1) holds (the wedge does work). If they're nearly identical,
interpretation (2) holds (the wedge is redundant) — the term should be removed
to align with FR-BDF.

This is the most consequential single finding in this audit so far other than
the TFP shock fix. Worth resolving before any further estimation refinement.

### §3.3.2 PV with constant discount factor (eqs 21-23)

Used for asset-pricing-style expectations where discounting is *not* tied to PAC
polynomial coefficients (e.g., long-run interest rate, permanent income).

FR-BDF eq (23) MCE recursive form: `PV(y)_t = β E_t PV(y)_{t+1} + (1-β) y_t`.

AUSPAC has three such PV variables:

| Variable | Discount | Driver | Equation | Verdict |
|---|---|---|---|---|
| `pv_u_gap` | β_w = 0.98 | unemployment gap (wage Phillips eq 137) | [au_pac.mod:1304](dynare/au_pac.mod#L1304): `pv_u_gap = (1-β_w)·u_gap + β_w·pv_u_gap(+1)` | ✓ exact eq (23) form |
| `pv_yh` | β_c = 0.95 | output gap as permanent-income proxy (consumption eq 59) | [au_pac.mod:1392](dynare/au_pac.mod#L1392): `pv_yh = (1-β_c)·yhat_au + β_c·pv_yh(+1)` | ✓ exact eq (23) form |
| `pv_i_uip` | β_uip = 0.92 | policy-rate gap for forward UIP (Phase Q, 2026-05-15) | [au_pac.mod:1565+](dynare/au_pac.mod#L1565): `pv_i_uip = (i_au-ibar) + β_uip·pv_i_uip(+1)` (Hybrid/MCE) | ⚠ slightly different form |

⚠ **Note on `pv_i_uip`**: the equation does **not** use the `(1-β_uip)` weight —
it's `pv_i_uip = i_gap + β_uip·pv_i_uip(+1)` (Phase Q convention per
[au_pac.mod:1565+](dynare/au_pac.mod#L1565) comment). This means `pv_i_uip` at SS = `i_gap / (1-β_uip)`,
amplifying the impact 1/(1-0.92) = 12.5× rather than being a unit-weighted PV.
This is **deliberate** per Phase Q (the impact response is supposed to be ~4.55× i_gap
at λ_i = 0.85 per STATUS.md), but it's a different convention from FR-BDF's eq (23)
asset-pricing PV. Worth a comment in the .mod that `pv_i_uip` is a *standard NPV*
form (eq 21 directly: `Σ β^i y_{t+i}` without the (1-β) normalization),
**not** an eq (23) recursive normalized PV.

### β_c = 0.95 vs β_pac = 0.98 — consumption block uses lower discount

FR-BDF (§4.6.1, p. 53–60) explains the consumption discount uses a higher rate
(lower β) to reflect "household risk aversion and income uncertainty" — see §2.4
of FR-BDF: *"Permanent income is constructed using a high discount rate that
arises from a combination of household risk aversion and income uncertainty."*

AUSPAC `beta_c = 0.95` ([au_pac.mod:1392](dynare/au_pac.mod#L1392) `pv_yh` recursion). This matches
FR-BDF's design — defer detailed value comparison to §4.6.1 audit.

### §3.2-3.3 summary

**Verdict on PAC framework**:

- ✓ Cost-function form, error-correction equation, stationary/nonstationary
  target split, β=0.98 calibration, native Dynare `pac_expectation()` usage —
  all match FR-BDF spec.
- ✓ Constant-discount-factor PVs (eq 23) correctly implemented for `pv_u_gap`
  (wage Phillips) and `pv_yh` (consumption permanent income).
- ⚠ `pv_i_uip` uses standard NPV form (eq 21) not the (1-β)-normalized eq (23) —
  intentional per Phase Q, but warrants a code comment to prevent confusion.
- ⚠ Comment at [au_pac.mod:1410](dynare/au_pac.mod#L1410) about growth neutrality is
  slightly misleading; should say "trivially holds in gap form".
- ⚠ **Major flag**: additive `pv_X_aux` "backward expectation correction" wedge
  is **not in FR-BDF spec** and may double-count the cyclical channel relative
  to what Dynare's `pac_expectation` already provides.

**Action items added**:
11. ⚠ **Investigate `pv_X_aux` doubling risk**: write a quick test that sets
    all `pv_X_aux ≡ 0` and recomputes IRFs. If material change → wedge has real
    quantitative effect (interpretation 1, fine). If tiny change → wedge is
    redundant with `pac_expectation` (interpretation 2, remove to match FR-BDF).
    Most consequential pending issue in the audit.
12. ⚠ Clarify comments at [au_pac.mod:1410, 1463, 1509, 1357](dynare/au_pac.mod#L1410)
    re growth neutrality: it holds trivially in gap form, no `growth=` option needed.
13. ⚠ Add a code comment at the `pv_i_uip` equation explaining it uses standard
    NPV (eq 21) not normalized-PV (eq 23), citing Phase Q rationale.

---

## §4.3 Supply block (deep audit) — findings

The TFP shock spec was already fixed 2026-05-15 (random-walk in `ln_tfp_LR` with
AR(1) smoothing toward `ln_tfp` via `rho_tfp`). This deep audit covers the rest
of the supply block: CES production, factor demands, user cost, FPF/VA price
target, capital accumulation, and calibration.

### Equation-by-equation comparison

| FR-BDF eq | Description | AUSPAC implementation | Verdict |
|---|---|---|---|
| 24 | CES production: `Q = γ·[α·K^((σ-1)/σ) + (1-α)·(EHN)^((σ-1)/σ)]^(σ/(σ-1))` | **NOT in .mod as a level equation**. FR-BDF design uses linearised log-FPF (eq 38) — full nonlinear form is not needed for PAC framework. | ✓ FR-BDF design |
| 25 | Solow residual `E_t` (inversion of 24) | not in .mod (level computation done in data prep at [data/scripts/estimate_ces_2026.m](data/scripts/estimate_ces_2026.m)) | ✓ |
| 26 | Capital FOC: `r̃_K/P_Q = (α/μ)·γ^((σ-1)/σ)·(Q/K)^(1/σ)` | implicit via `eq_dln_ib_star_bar` (linearised growth form) | ✓ |
| 27 | Labor FOC: `W̃/P_Q = ((1-α)/μ)·γ^((σ-1)/σ)·EH·(Q/(EHN))^(1/σ)` | implicit via `eq_dln_n_star_bar` (linearised) | ✓ |
| 28 | Real user cost: `r̃_K/P_Q = (wacc + δ̃ - PV(π_Q)) · P_Ĩ/P_Q` | [au_pac.mod:1438](dynare/au_pac.mod#L1438) `eq_uc_k`: `uc_k = wacc + delta_k - (pi_ib - piQ)` | ✓ matches structurally |
| 29 | FPF: `P_Q = (μ/γ)·(1-α)^(σ/(1-σ))·[1-α^σ·(Q'_K/γ)^(1-σ)]^(-1/(1-σ)) · W̃/(EH)` | linearised in [au_pac.mod:1237](dynare/au_pac.mod#L1237) `eq_piQ_star` | ✓ via log-linear pass-through |
| 30 | Marginal return: `Q'_K = α·γ^((σ-1)/σ)·(Q/K)^(1/σ)` | implicit (used in eq 28 calibration) | ✓ |
| 31 | Equilibrium capital `K*` | implicit (gap form) | ✓ |
| 32 | Capital accumulation: `K_t = (1-δ̃)K_{t-1} + Ĩ_t` | [au_pac.mod:1128](dynare/au_pac.mod#L1128) `eq_dln_k`: `dln_k = (1-delta_k)·dln_k(-1) + delta_k·dln_ib` (linearised) | ✓ |
| 33 | Equilibrium investment `Ĩ* = (δ̃+g_K)/(1+g_K)·K*` | implicit | ✓ |
| 34 | I* re-derived via FOC | implicit | ✓ |
| 35 | `log Ĩ* = a_0 + log(Q) - σ·log(r̃_K/P_Q) + log((δ̃+g_K)/(1+g_K))` | [au_pac.mod:1452](dynare/au_pac.mod#L1452) `eq_dln_ib_star_bar = kappa_ib_y·yhat_au - sigma_ces·dln_uc_k` | ✓ growth-form linearisation |
| 36 | `log N* = b̃_0 + log(Q) - log(Ē) - σ·log(W̃/(P_Q·Ē)) + (σ-1)·log(H)` | [au_pac.mod:1341](dynare/au_pac.mod#L1341) `eq_dln_n_star_bar = dln_tfp/(1-α_k) - σ_ces·rw_gap` | ✓ growth form |
| 37 | salaried employment `log N*_S` (similar) | implicit | ✓ |
| 38 | VA price equilibrium (FPF dual) | [au_pac.mod:1237](dynare/au_pac.mod#L1237) `eq_piQ_star = ρ_pQ_star·piQ_star(-1) + γ_ulc·dln_ulc + γ_uck·dln_uc_k + …` | ✓ |
| §4.3 trend efficiency Ē | random walk + AR(1) smoothing per §5.2.7 | [au_pac.mod:1207-1214](dynare/au_pac.mod#L1207) `eq_ln_tfp_LR`, `eq_ln_tfp`, `eq_dln_tfp` (fixed 2026-05-15) | ✓ aligned post-fix |

### CES log-linear pass-through identities ✓ verified

FR-BDF unit-cost dual implies (linearised around SS):
- `γ_ulc = (1-α)·σ` (labor share × elasticity)
- `γ_uck = α·σ` (capital share × elasticity)

AUSPAC values:
- α = 0.45, σ = 0.5366
- (1-α)·σ = 0.55 × 0.5366 = **0.2951** → matches `gamma_ulc = 0.2951` at [au_pac.mod:622](dynare/au_pac.mod#L622) ✓
- α·σ = 0.45 × 0.5366 = **0.2415** → matches `gamma_uck = 0.2415` at [au_pac.mod:623](dynare/au_pac.mod#L623) ✓

Cross-restrictions properly enforced. ✓

### Calibration comparison (Table 4.3.2)

| Param | FR-BDF (Table 4.3.2) | AUSPAC | Source / verdict |
|---|---|---|---|
| σ (CES elasticity) | 0.53 | 0.5366 | ✓ matches; AU posterior from labour-FOC Bayesian estimate (2026-05-14 refresh) |
| α (capital share) | 0.26 | **0.45** | ⚠ AU-specific: ABS 5204 Table 48 capital-income share. Substantial difference (1.7×). Documented in STATUS.md as 2026-05-14 recalibration. |
| γ (CES scale) | 0.34 | **0.0458** | ⚠ AU-specific: analytical from 2019 Q_market/K_total mean (units-driven, not directly comparable across base years) |
| μ (markup) | 1.31 | **1.20** | ⚠ AU-specific: RBA RDP 2018-09 mid-range markup |
| δ (depreciation, annual) | 15.0% | **5.4%** (`delta_k = 0.0134/q`) | ⚠ AU-specific: ABS 5204 net capital stock + depreciation series. **Very large difference** (2.8× lower) — major driver of slow capital recovery in IRFs (~50q half-life vs FR-BDF's ~18q) |
| Ē trend growth p.a. | not specified | 3.07% pre-2002Q2 / 0.43% 2002-2008 / 0.49% post-2008 | ⚠ AU-specific (vs FR-BDF: 2.4% pre-2002Q2 / 0.85% afterwards, 4.2% step at 2008Q3) |

### ⚠ Major calibration flag: δ_k = 0.0134/quarter

AU's quarterly depreciation rate is **2.8× lower** than France's. This is real
(ABS 5204 net capital stock methodology gives lower depreciation than French
QNA), but it has consequences:

- ln_K half-life under AR(1) (1-δ)·dln_k(-1) = 0.9866·dln_k(-1) is
  log(0.5)/log(0.9866) = **51 quarters** (~13 years)
- vs FR-BDF's δ=0.0375 implies half-life ≈ 18 quarters
- This is *the* dominant driver of the slow ln_K recovery we identified in the
  TFP-shock investigation (which led to this audit)

The δ = 5.4% annual is substantially low even by international standards. ABS
methodology is conservative on depreciation. Worth flagging because:
1. It's the single biggest reason ln_Q IRFs look "stuck" at long horizons —
   capital recovery dynamics dominate
2. Robustness check at δ=0.025 (FR-BDF Phase G original) might reveal whether
   the slow-recovery is calibration-driven or structural

⚠ **Action item**: in the §5 IRF audit, run a sensitivity check on δ_k at FR-BDF's
~0.0375/q value to quantify how much of the slow-recovery is calibration vs spec.

### CES production function in level form — not in .mod (intentional)

Comment at [au_pac.mod:1183-1189](dynare/au_pac.mod#L1183):
> "CES effects captured through factor demand target equations… Does NOT redefine yhat_au —
> IS curve still drives output gap."

STATUS.md confirms (Phase G):
> "What's NOT done: full non-linear CES production function in Dynare equation form.
> The linearised log-FPF (γ_ulc and γ_uck) IS the CES factor-price-frontier
> linearised around steady state, which is what the PAC framework actually uses."

This is **consistent with FR-BDF design**. FR-BDF's PAC framework uses the
log-linearised FPF (eq 38) for VA price targets and the log-linearised factor-demand
equations (eqs 35-37) for investment/employment targets. The level CES production
function (eq 24) is used only at the data-preparation stage to compute the Solow
residual E (eq 25). ✓

Confirmed by checking `data/scripts/estimate_ces_2026.m` (per STATUS.md) — the
level CES is solved there to back out E_t and Ē_t.

### `eq_uc_k` matches FR-BDF eq 28 ✓

FR-BDF eq 28: `r̃_K/P_Q = (wacc + δ̃ - PV(π_Q)|_{t-1}) · P_Ĩ/P_Q`

AUSPAC ([au_pac.mod:1438](dynare/au_pac.mod#L1438)): `uc_k = wacc + delta_k - (pi_ib - piQ)`

Three differences in form:
- AUSPAC drops the `· P_Ĩ/P_Q` relative-price multiplier (assumed unity in linearised form around SS) — ✓ standard
- AUSPAC uses `(pi_ib - piQ)` (current investment price inflation minus VA price inflation) instead of FR-BDF's `PV(π_Q)|_{t-1}` (one-period-ahead expected VA inflation) — ⚠ subtle: ours is contemporaneous relative-price growth, FR-BDF's is forward-looking expected VA inflation. Different timing convention. In MCE variant the difference may matter; in VAR variant it's effectively a calibration choice. **Worth verifying in §5 IRF audit** — interest rate shock should affect uc_k via WACC.
- ✓ Both have wacc and δ as additive terms

### `eq_dln_ib_star_bar` matches FR-BDF eq 35 ✓

FR-BDF eq 35: `log Ĩ* = a_0 + log(Q) - σ·log(r̃_K/P_Q) + log((δ̃+g_K)/(1+g_K))`

In growth-rate form (subtracting period t-1):
   `dln(I*) = dln(Q) - σ·dln(r̃_K/P_Q)`

AUSPAC: `dln_ib_star_bar = kappa_ib_y·yhat_au - sigma_ces·dln_uc_k`

| Component | FR-BDF | AUSPAC | Verdict |
|---|---|---|---|
| Output channel | `dln(Q)` | `kappa_ib_y · yhat_au` (gap, not growth) | ⚠ AU uses output gap not output growth |
| User-cost channel | `-σ·dln(r̃_K/P_Q)` | `-sigma_ces·dln_uc_k` | ✓ same |

⚠ The output channel uses **output gap** (`yhat_au`) with sensitivity `kappa_ib_y = 0.06`,
not output growth. FR-BDF's eq 35 has output growth (the change in log Q).

In gap form the difference is consequential:
- FR-BDF: investment target rises with output growth (accelerator on Δlog Q)
- AUSPAC: investment target rises with output gap level (proportional to ŷ)

These are *different* mechanisms. AUSPAC's spec is more like a "neoclassical
investment accelerator" while FR-BDF's is a "level-form investment-output ratio".
This may be a deliberate AU specification choice (weaker accelerator on AU data?)
or it may be an unintended divergence. ⚠ **Investigate**.

### `eq_dln_n_star_bar` matches FR-BDF eq 36 ✓

FR-BDF eq 36 (linearised growth form):
   `dln(N*) = dln(Q) - dln(Ē) - σ·dln(W̃/(P_Q·Ē))`

AUSPAC: `dln_n_star_bar = dln_tfp/(1-α_k) - σ_ces·rw_gap`

Where `rw_gap = pi_w - piQ - dln_prod` and `dln_prod = dln_tfp/(1-α_k)`.

Substituting:
   `dln_n_star_bar = dln_tfp/(1-α_k) - σ_ces·(pi_w - piQ - dln_tfp/(1-α_k))`

FR-BDF rearranged in gap form would give:
   `dln(N*) = (dln(Q) - dln(Ē)) - σ·(dln(W̃) - dln(P_Q) - dln(Ē))`

For Cobb-Douglas (σ→1) this reduces to dln(Q) - dln(Ē)·... — the AUSPAC form
captures the labor-augmenting tech progress correctly via dln_tfp/(1-α_k).

| Component | FR-BDF | AUSPAC | Verdict |
|---|---|---|---|
| Output growth | dln(Q) | **MISSING** — no `dln(Q)` term | ✗ **POTENTIAL MISMATCH** |
| Trend efficiency | -dln(Ē) → +dln_tfp/(1-α_k) | yes (positive sign) | ✓ |
| Real wage gap | -σ·dln(W̃/(P_Q·Ē)) → -σ·rw_gap | yes | ✓ |

⚠ **The dln(Q) channel is absent from AUSPAC's `eq_dln_n_star_bar`**. In FR-BDF's
eq 36, employment target rises one-for-one with output growth (a core
neoclassical labor-demand mechanism). AUSPAC's version omits this term entirely.

This is **structurally significant**: in our model, the labor demand target
responds to TFP and real wage gap but **not** to output. Output gap enters via
the PAC equation's `b2_n · yhat_au` term (a separate "ad hoc" channel) but not
via the long-run target. This means the implied LR employment-to-output
elasticity may be ill-defined in our spec.

⚠ **Action item**: verify whether the missing `dln(Q)` (or `yhat_au`) term in
eq_dln_n_star_bar is intentional. Check git blame for [au_pac.mod:1340-1341](dynare/au_pac.mod#L1340)
and the Stage 12 fix comments. If unintentional, add `+ b_yh_n · yhat_au` to
match FR-BDF eq 36's output channel.

### `eq_piQ_star` matches FR-BDF eq 38 (linearised) ✓

VA price target uses log-linearised FPF dual:

FR-BDF eq 38 in growth form:
   `dlog P*_Q = γ_ulc·dlog ULC + γ_uck·dlog r̃_K`

AUSPAC ([au_pac.mod:1237](dynare/au_pac.mod#L1237)):
   `piQ_star = ρ_pQ_star·piQ_star(-1) + γ_ulc·dln_ulc + γ_uck·dln_uc_k + (1-ρ_pQ_star-γ_ulc)·pibar_au`

Two AU-specific extensions vs FR-BDF eq 38:
1. **AR(1) persistence** (`ρ_pQ_star · piQ_star(-1)`) — adds smoothing not in FR-BDF eq 38
2. **Anchor term** `(1-ρ_pQ_star-γ_ulc)·pibar_au` — pulls target toward LR inflation anchor

These extensions ensure piQ_star → pibar_au at SS (verified in comment at
[au_pac.mod:1235-1236](dynare/au_pac.mod#L1235)). FR-BDF eq 38 in their integrated form would also have
this property, but stated differently. Defensible AU implementation.

### §4.3 summary

**Verdict on supply block**:

- ✓ Structural alignment: all FR-BDF eqs (24, 26-28, 32, 35, 36, 38) implemented
  via linearised growth-form equivalents
- ✓ CES log-linear pass-through identities (γ_ulc=(1-α)σ, γ_uck=ασ) **exactly
  satisfied** by current calibration
- ✓ User cost formula matches FR-BDF eq 28 (modulo timing convention)
- ✓ Trend efficiency now FR-BDF-aligned (TFP shock fix 2026-05-15)
- ✓ Skipping CES level form (eq 24) is consistent with FR-BDF PAC design
- ⚠ Calibration substantially differs (α=0.45 vs 0.26, γ=0.046 vs 0.34, μ=1.20
  vs 1.31, δ=5.4%/yr vs 15%/yr) — all documented AU adaptations, but δ in
  particular drives long IRF horizons
- ⚠ `uc_k` uses contemporaneous `(pi_ib - piQ)` not forward `PV(π_Q)|_{t-1}` —
  timing convention difference
- ⚠ `dln_ib_star_bar` uses output GAP not output GROWTH — divergence from FR-BDF
  eq 35
- ✗ **`dln_n_star_bar` missing `dln(Q)` channel** from FR-BDF eq 36 — likely
  unintentional, worth investigating

**Action items added**:
14. ⚠ §5 IRF audit: sensitivity check on `delta_k` at FR-BDF's ~0.0375/q value
    to quantify how much of slow ln_K recovery is calibration vs spec
15. ⚠ Verify timing of `uc_k`: AU uses contemporaneous `(pi_ib - piQ)`, FR-BDF
    uses `PV(π_Q)|_{t-1}`. May matter under MCE.
16. ⚠ Investigate `eq_dln_ib_star_bar` output channel: is `kappa_ib_y · yhat_au`
    deliberate substitution for FR-BDF's `dln(Q)` accelerator term?
17. ✗ **Add `dln(Q)` (or `yhat_au` proxy) channel to `eq_dln_n_star_bar`** to
    match FR-BDF eq 36 — currently missing the labor-demand output channel

---

## §4.4 VA price of market branches — findings

The VA price equation is *the* central deflator equation in FR-BDF (every other
deflator is anchored to it). Three components: (i) long-run target from FPF
(eq 38), (ii) PAC short-run equation (eq 44), (iii) auxiliary equations added
to E-SAT for forecasting target growth (eqs 45-48).

### Long-run target — already covered in §4.3 ✓

`p*_{Q,t} = c_0 + (σ/(1-σ))·log(1-α) - (1/(1-σ))·log[1-α^σ·(Q'_K/γ)^(1-σ)] + log(W̃/(Ē·H))`

Linearised in [au_pac.mod:1237](dynare/au_pac.mod#L1237) `eq_piQ_star`. Per §4.3 audit: ✓ aligned via
γ_ulc = (1-α)·σ, γ_uck = α·σ pass-through identities, both exactly satisfied.

### PAC short-run equation (FR-BDF eq 44)

FR-BDF eq 44:
```
π_{Q,t} = PV(π*_Q)_{t|t-1}                 ← discounted PV of expected target growth
        + β_0·[p*_{Q,t-1} - p_{Q,t-1}]      ← error correction
        + β_1·π_{Q,t-1}                     ← persistence
        + β_2·ŷ_t                            ← ad hoc current demand (HtM firms)
        + (1-β_1-ω)·π̄*_{Q,t-1}             ← growth-neutrality / LR anchor pull
        + ε_t
```

AUSPAC `eq_piQ_pac` ([au_pac.mod:1283](dynare/au_pac.mod#L1283)):
```
diff(pQ_level) = b0_pQ * (piQ_hat(-1) - pQ_level(-1))      ← error correction
               + b1_pQ * diff(pQ_level(-1))                ← persistence
               + pac_expectation(pac_pQ)                   ← Dynare PV from VAR
               + b2_pQ * yhat_au                           ← current demand
               + b_covid_crash_pQ * d_covid_crash + b_covid_bounce_pQ * d_covid_bounce
               + pv_piQ_aux                                ← AU additive wedge (§3 audit flag)
               + eps_pQ;
```

| FR-BDF term | AUSPAC term | Verdict |
|---|---|---|
| LHS: `π_{Q,t}` | `diff(pQ_level)` | ✓ identical |
| `β_0·[p*_{Q,t-1} - p_{Q,t-1}]` | `b0_pQ * (piQ_hat(-1) - pQ_level(-1))` | ✓ |
| `β_1·π_{Q,t-1}` | `b1_pQ * diff(pQ_level(-1))` | ✓ |
| `β_2·ŷ_t` | `b2_pQ * yhat_au` | ✓ |
| `PV(π*_Q)_{t|t-1}` | `pac_expectation(pac_pQ) + pv_piQ_aux` | ⚠ doubled (§3 flag) |
| `(1-β_1-ω)·π̄*_{Q,t-1}` (growth-neutrality) | **MISSING explicit term** | ⚠ verify (likely absorbed into pac_expectation in gap form) |
| `ε_t` | `eps_pQ` | ✓ |
| (none) | `b_covid_* * dummies` | ⚠ AU pandemic addition, defensible |

### Calibration comparison (Table 4.4.3)

| Param | FR-BDF (Table 4.4.3) | AUSPAC (au_pac.mod) | Verdict |
|---|---|---|---|
| β_0 (error correction) | 0.06 (s.e. 0.02) | **0.0306** (90% HPD [0.006, 0.053]) | ⚠ AU half-magnitude — slower error correction. Phase B/MCMC posterior. |
| β_1 (persistence) | 0.50 (s.e. 0.09) | **0.2907** (90% HPD [0.128, 0.461]) | ⚠ AU lower persistence (~half) |
| β_2 (output gap) | 0.09 (s.e. 0.03) | **−0.0001** (90% HPD [−0.079, +0.086]) | ⚠ AU effectively zero — output-gap sensitivity not identified in AU data |
| ω (nonstationary share) | 0.46 | 0.46 | ✓ exact match (calibrated) |

⚠ **Three of four short-run coefficients estimate substantially smaller than
FR-BDF's**. β_2 is essentially zero with HPD straddling zero — meaning we have
**no statistically identified output-gap channel into VA price** in AU data.
This is consistent with AU's flatter Phillips curve (a known empirical AU finding).

This is an **estimation finding**, not a spec issue. Worth noting for §5 IRF
audit interpretation.

### ⚠ Missing growth-neutrality term `(1-β_1-ω)·π̄*_{Q,t-1}`

FR-BDF eq 44 includes an explicit `(1-β_1-ω)·π̄*_{Q,t-1}` term. With β_1=0.50,
ω=0.46, this contributes `0.04·π̄*_Q` — small but non-zero, and ensures
balanced-growth-path neutrality (per FR-BDF §3.2.2).

In AUSPAC:
- Coefficient `(1-b1_pQ-omega_pQ) = 1 - 0.291 - 0.46 = 0.249` — **larger**
  than FR-BDF's 0.04 because b1_pQ is so much smaller
- No explicit `+ 0.249·pibar_au` (or `piQ_star_bar`) term in `eq_piQ_pac`

Two possibilities:
1. **Dynare's `pac_expectation(pac_pQ)` macro automatically includes this term**
   when computing PV(π*_Q) — the trend component (k_1 vector per FR-BDF eq 17)
   captures it via `var_pQ`'s coefficient on inflation anchor variables.
2. **Term is genuinely missing** — and our SS doesn't balance unless `pv_piQ_aux`
   absorbs it (which would explain why `pv_piQ_aux` is needed structurally,
   not just as a "wedge").

If interpretation 2 holds, this links back to the **§3 `pv_X_aux` doubling
question**: maybe `pv_piQ_aux` isn't a "wedge" at all — it's the **growth-
neutrality term** FR-BDF eq 44 specifies, just hidden behind a misleading name.

⚠ **Action item — RESOLVE THE `pv_X_aux` PUZZLE**: This audit is now the second
section to flag it. To resolve:
1. Compute SS values: at SS, `diff(pQ_level) = pi_ss_au = 0.625`; `b0_pQ·(0)`,
   `b1_pQ·0.625 = 0.182`, `pac_expectation(pac_pQ) = ?`, `b2·0 = 0`, `pv_piQ_aux
   = ?`. The SS condition `0.625 = 0.182 + pac_exp + pv_piQ_aux` requires
   `pac_exp + pv_piQ_aux = 0.443`. FR-BDF spec would have `pac_exp = 0.443`
   (carrying both PV and the growth-neutrality `(1-β_1-ω)·π̄*`).
2. If `pac_expectation(pac_pQ)` at SS evaluates to ~0.443, then `pv_piQ_aux` is
   indeed redundant and should be removed.
3. If `pac_expectation(pac_pQ)` at SS is ~0 (because gaps are zero at SS), then
   `pv_piQ_aux` is filling in for the missing growth-neutrality term — should
   be renamed and its role explicitly documented.

This needs a Dynare run to resolve definitively. **Highest-priority pending
item in the audit.**

### Auxiliary E-SAT equations (FR-BDF eqs 45-47)

FR-BDF adds three equations to E-SAT to forecast `PV(π*_Q)`:

**Eq 45** — VA price target growth:
```
π*_{Q,t} = β_0·(π_{W,t} - Δē_t) + (1-β_0)·π̄*_{Q,t-1} + ε_t
```
Target growth = weighted avg of (efficient real wage growth) and (HP-trend of target).

**Eq 46** — efficient real wage Phillips:
```
(1-ρL)[π_{W,t} - Δē_t - π̄*_{Q,t-1}] = β_0·û_t + ε_t
```

**Eq 47** — Okun's law:
```
û_t = β_0·(ŷ_t - ρ·ŷ_{t-1}) + ρ·û_{t-1} + ε_t
```

**AUSPAC's approach is structurally different**:

| FR-BDF style | AUSPAC | Verdict |
|---|---|---|
| Three structural auxiliary eqs (45-47) linking target to wage / efficiency / unemployment | Single reduced-form policy-function regression `var_pQ`: target gap on (y, i, π, u) gaps | ⚠ different methodology |

Our `var_pQ` ([au_pac.mod:1061](dynare/au_pac.mod#L1061)):
```
piQ_hat = rho_pQ_aux*piQ_hat(-1) + a_pQ_y*y_gap_var(-1) + a_pQ_i*i_gap_var(-1)
        + a_pQ_pi*pi_gap_var(-1) + a_pQ_u*u_gap_var(-1) + eps_var_pQ
```

This regresses target gap directly on E-SAT state vars. It's a **policy
function**, not a structural equation. FR-BDF's policy function for
PV(π*_Q)|_{t-1} is shown in their Table 4.4.4 (column 1) with specific
implied coefficients (-1.5e-3 on ŷ, etc.) derived by solving E-SAT + eqs 45-47.

| FR-BDF policy func coef (Table 4.4.4) | AUSPAC `var_pQ` coef | Notes |
|---|---|---|
| ŷ_{t-1}: −1.5e-3 | a_pQ_y | very small (FR-BDF) |
| (i-ī)_{t-1}: −3.4e-3 | a_pQ_i | very small |
| (π_Q-π̄_Q)_{t-1}: 8.7e-4 | a_pQ_pi | ~zero |
| ŷ_{ea,t-1}: 4.8e-4 | (none in AUSPAC) | foreign demand channel |
| û_{t-1}: −1.1e-2 | a_pQ_u | unemployment channel |
| π̃_{W,t-1}: 1.2e-2 | (none) | wage growth channel |
| π̄*_{Q,t-1}: 0.44 | (none — `var_pQ` is gap-form) | trend anchor |

⚠ The FR-BDF policy function has TWO terms (π̃_W trend wage, π̄*_Q trend target)
that AUSPAC's gap-form `var_pQ` cannot capture by construction. These are
trend/level dependencies. The 0.44 coefficient on π̄*_{Q,t-1} is large and is
exactly the trend-anchor channel that we conjectured `pv_piQ_aux` might be
filling in for.

Defer detailed `a_pQ_*` value comparison to §5 audit.

### Eq 48 — HP-trend smoother for π̄*_Q

FR-BDF eq 48:
```
π̄*_{Q,t} = α_0·π̄*_{Q,t-1} + (1-α_0)·π̄
```
α_0 = 0.95 (12-quarter half-life), π̄ = 0.0048 (1.92% annualized = ECB target).

AUSPAC `eq_piQ_star_bar` ([au_pac.mod:1244](dynare/au_pac.mod#L1244)):
```
piQ_star_bar = pibar_au;
```

| Item | FR-BDF | AUSPAC | Verdict |
|---|---|---|---|
| Form | AR(1) smoother with exogenous π̄ | direct equality to `pibar_au` | ⚠ different |
| Persistence | 0.95 | 0.93 (via `pibar_au`'s own AR(1) `lambda_pibar`) | ✓ similar |
| LR anchor value | 0.0048/q (1.92%/yr) | `pi_ss_au = 0.0625/q` (2.5%/yr) | ✓ AU adaptation (RBA target) |

Effectively: AUSPAC's `pibar_au` (which itself is AR(1) with λ=0.93) plays the
role FR-BDF assigns separately to π̄*_Q. Mechanically equivalent — slight
naming/decomposition difference. ✓ aligned in spirit.

### §4.4 summary

**Verdict on VA price block**:

- ✓ Long-run target via linearised FPF (per §4.3) — exactly aligned
- ✓ Short-run PAC equation has all FR-BDF eq 44 terms (error correction, lag,
  PV, output gap, COVID extension)
- ⚠ Estimation: 3 of 4 short-run coefficients (β_0, β_1, β_2) are substantially
  smaller than FR-BDF's; β_2 ≈ 0 means **no identified output-gap channel** in
  AU data. Real empirical finding (AU flat Phillips curve), not a spec issue.
- ⚠ **Missing explicit `(1-β_1-ω)·π̄*_{Q,t-1}` growth-neutrality term**. Likely
  absorbed into `pac_expectation(pac_pQ)` via the trend-anchor channel of the
  auxiliary VAR — but might explain why `pv_piQ_aux` is structurally needed.
- ⚠ Auxiliary equation methodology differs: FR-BDF uses 3 structural eqs (45-47);
  AUSPAC uses single reduced-form policy regression (`var_pQ`). Defensible
  alternative, but loses 2 channels (efficient wage growth, trend target anchor).
- ✓ HP-trend smoother (eq 48) effectively replicated via `pibar_au` AR(1).

**Action items added**:
18. ✗ **Top priority — resolve `pv_X_aux` puzzle by computing SS values**.
    This audit links the §3 doubling question directly to the §4.4 missing
    `(1-β_1-ω)·π̄*_Q` term. Two interpretations:
    - **(a) Wedge interpretation**: pac_expectation already provides growth-
      neutrality; `pv_X_aux` is double-counting → remove.
    - **(b) Substitute interpretation**: pac_expectation only provides PV of
      target gap; `pv_X_aux` is a misnamed substitute for the missing FR-BDF
      growth-neutrality term → rename and document, do not remove.
    Need a Dynare SS computation to choose. **Most consequential pending item.**
19. ⚠ Document AU's flat Phillips curve finding (β_2 = 0) prominently — affects
    §5 IRF interpretation (output gap shocks produce minimal direct VA price
    response in AU)
20. ⚠ Optional: consider re-formulating `var_pQ` to include trend-anchor
    channel `+ a_pQ_pibar · pibar_au(-1)` to capture the FR-BDF policy-function
    coefficient of 0.44 explicitly. May improve forecast accuracy under
    VAR-based expectations.

---

## §4.5 Labor market (supply + demand) — findings

### §4.5.1 Wage Phillips curve (FR-BDF eqs 49-54)

**FR-BDF derivation**: starts with NK Phillips with hybrid indexation (eq 49), adds
indexation variable x_{t-1} (eq 50) and minimum-wage process (eq 51), then solves
forward to get the estimable form (eq 52):

```
π_{W,t} = β_0 + [Δē_t + π̄_t]
        + β_1·(π_{C,t-1} - π̄_{t-1})                                      ← consumer-π gap, lagged
        + β_2·[π_{W,t-1} - Δē_{t-1} - π̄_{t-1} - β_1·(π_{C,t-2} - π̄_{t-2})]  ← efficient real wage hybrid
        + β_3·(Δ_4(w^m_{t-1} - e_{t-1}) - π̄_{t-1})                        ← minimum wage growth
        + β_4·PV(û)_{t-1|t-2}                                             ← forward unemployment-gap PV
        + ε^w_t
```

**AUSPAC `eq_pi_w`** ([au_pac.mod:1316](dynare/au_pac.mod#L1316)):
```
pi_w = lambda_w * pi_w(-1)
     + gamma_w * pi_au
     + kappa_w * pv_u_gap
     + (1 - lambda_w - gamma_w) * pibar_au
     + (1 - lambda_w) * dln_prod
     + eps_w;
```

| FR-BDF term | AUSPAC term | Verdict |
|---|---|---|
| LHS: `π_{W,t}` | `pi_w` | ✓ |
| `β_0` (small constant) | absent | ✓ FR-BDF residual centring; not needed in gap form |
| `Δē_t + π̄_t` (efficiency + LR inflation as additive trend) | `(1-λ_w-γ_w)·pibar_au + (1-λ_w)·dln_prod` (different decomposition) | ⚠ different parameterisation |
| `β_1·(π_{C,t-1} - π̄_{t-1})` (lagged consumer-π gap) | `γ_w·pi_au` (contemporaneous, NOT in gap form, uses VA price not consumer price) | ⚠ wrong index AND wrong inflation measure |
| `β_2·[hybrid efficient real wage gap]` | `λ_w·pi_w(-1)` (just AR(1) on lagged wage inflation) | ⚠ AUSPAC simplifies to standard NK Phillips form |
| `β_3·minimum wage growth` (eq 51 process) | absent — no AU minimum-wage channel | ⚠ AU drops |
| `β_4·PV(û)_{t-1|t-2}` (forward unemployment PV at t-1) | `κ_w·pv_u_gap` (at time t, **with potentially wrong sign**) | ✗ see below |
| `ε^w_t` | `eps_w` | ✓ |

**⚠ MAJOR**: AUSPAC's wage Phillips is a **simpler New Keynesian textbook form**, not
FR-BDF's NK-with-hybrid-indexation-and-minimum-wage spec. Likely intentional (AU
uses ABS WPI, not French wage data; AU has no equivalent of France's SMIC indexation
mechanism). But the equation is structurally different from FR-BDF eq 52.

### ✗ Possible sign error on unemployment-gap channel

FR-BDF eq 49: `π_W - x = α + β·E[π_W(+1) - x] - λ·(u - u_N)` with **−λ** (positive λ).
FR-BDF eq 52 estimated: `+β_4·PV(û)` with `β_4 = -0.32` (Table 4.5.3).

Both forms: high unemployment → wage deflation. The minus sign matters.

AUSPAC: `+ kappa_w · pv_u_gap` with `kappa_w = +0.0966` (posterior mean), HPD `[-0.028, 0.128]`.

**Sign convention check**:
- `eq_u_gap` ([au_pac.mod:1296](dynare/au_pac.mod#L1296)): `u_gap = ρ·u_gap(-1) + okun_coeff·yhat_au` with `okun_coeff = -0.13` (negative)
- Therefore `u_gap > 0` ⟺ unemployment > NAIRU (slack labor market)
- `pv_u_gap = (1-β_w)·u_gap + β_w·pv_u_gap(+1)` carries the same sign convention
- High slack (`pv_u_gap > 0`) × `+kappa_w·pv_u_gap` (with κ_w > 0) → positive contribution to wage inflation

**This is the wrong sign.** High unemployment should reduce wage inflation, not raise it. The FR-BDF coefficient is negative (-0.32). AUSPAC's posterior is +0.0966.

Two interpretations:
1. **Sign coding error** — should be `- kappa_w · pv_u_gap` with `kappa_w > 0`, OR
   `+ kappa_w · pv_u_gap` with `kappa_w < 0` (FR-BDF convention).
2. **Estimation finding (unidentified)** — the HPD straddles zero ([-0.028, 0.128]),
   so the data isn't strongly identifying the sign. The Bayesian prior may have
   biased the mode toward positive. AU's wage Phillips really may be flat to slightly
   positive (consistent with the AU "flat Phillips" empirical pattern).

Either way: ⚠ **Worth flipping the sign convention to match FR-BDF and tightening the
prior**. With FR-BDF's prior centred on -0.32, our posterior would likely also be
slightly negative or zero, but at least the sign convention would match.

### ⚠ Inflation measure mismatch (`pi_au` vs `π_C`)

FR-BDF eq 52 uses **π_C** (consumer price inflation) for indexation. AUSPAC uses
**pi_au** which is the VA price inflation (`piQ` essentially) — not consumer price
inflation.

AUSPAC has separate `pi_c` (consumption deflator inflation) declared but the wage
Phillips uses `pi_au` (VA price). Two different inflation measures. Workers index
to consumer prices (what they buy), not VA prices (what firms charge per unit
output).

⚠ **Action item**: verify whether `pi_au` in AUSPAC actually equals VA-price
inflation or has a different definition. If it's VA price, replace with `pi_c`
(consumer price inflation) per FR-BDF eq 52.

### Calibration comparison (Table 4.5.3)

| Param | FR-BDF | AUSPAC | Notes |
|---|---|---|---|
| β_0 | -5e-4 (s.e. 4e-4) | absent | ✓ FR-BDF residual centring |
| β_1 (consumer-π indexation) | 0.24 (s.e. 0.1) | gamma_w = 0.1356 | AU lower (~half); also wrong inflation measure |
| β_2 (efficient real wage persistence) | 0.32 (s.e. 0.1) | lambda_w = 0.2899 | similar |
| β_3 (minimum wage) | 0.22 (s.e. 0.1) | absent | AU drops (no minimum-wage channel) |
| β_4 (unemployment-gap PV) | **-0.32** (s.e. 0.2) | **kappa_w = +0.0966** [-0.028, 0.128] | ✗ sign and HPD |

### §4.5.2 Labor demand — target salaried employment (FR-BDF eq 55)

This is where the §4.3 audit flagged a missing `dln(Q)` channel (action item #17).
Re-examining now in detail.

FR-BDF eq 55:
```
n*_{S,t} = b_0 + q_t - ē_t - h_t - σ·(w̃_t - p_{Q,t} - ē_t - h_t)
```

Expanding and grouping coefficients on each variable:
- `+1` on q_t (output)
- `+(σ-1) = -(1-σ)` on ē_t (trend efficiency)
- `+(σ-1)` on h_t (hours, ≈0 in growth-rate form for AU)
- `-σ` on w̃_t (nominal wage)
- `+σ` on p_{Q,t} (VA price)

In growth form (FR-BDF style), with Δē = dln_prod:
```
Δn*_S = Δq + (σ-1)·Δē - σ·Δw̃ + σ·Δp_Q
       = Δq - (1-σ)·dln_prod - σ·pi_w + σ·piQ
```

Numerically with AUSPAC σ=0.5366, α_k=0.45 (so dln_prod = dln_tfp/(1-α_k)):
```
Δn*_S = Δq - (1-0.5366)/(1-0.45)·dln_tfp - 0.5366·pi_w + 0.5366·piQ
       = Δq - 0.843·dln_tfp - 0.5366·pi_w + 0.5366·piQ
```

**AUSPAC `eq_dln_n_star_bar`** ([au_pac.mod:1341](dynare/au_pac.mod#L1341)):
```
dln_n_star_bar = dln_tfp/(1-α_k) - σ_ces·rw_gap
```
where `rw_gap = pi_w - piQ - dln_prod = pi_w - piQ - dln_tfp/(1-α_k)`.

Substituting:
```
dln_n_star_bar = dln_tfp/(1-α_k) - σ·(pi_w - piQ - dln_tfp/(1-α_k))
              = dln_tfp/(1-α_k)·(1+σ) - σ·pi_w + σ·piQ
              = +2.794·dln_tfp - 0.5366·pi_w + 0.5366·piQ
```

| Channel | FR-BDF coefficient | AUSPAC coefficient | Verdict |
|---|---|---|---|
| Output Δq | +1 | **0 (missing)** | ✗ already action #17 |
| Trend efficiency dln_tfp | -0.843 (negative) | **+2.794 (positive, opposite sign)** | ✗ NEW finding |
| Wage inflation pi_w | -0.5366 | -0.5366 | ✓ |
| VA price inflation piQ | +0.5366 | +0.5366 | ✓ |

### ✗ NEW MAJOR FINDING: dln_tfp coefficient has wrong sign in `eq_dln_n_star_bar`

FR-BDF eq 55: coefficient on ē in level form is **−1**: `n* = … − ē_t − …`. Intuition: more efficient labor → fewer workers needed for same output (labor-saving).

AUSPAC's `dln_tfp/(1-α_k)` leading term is **positive**, implying more TFP → more workers needed at same output. **This is inconsistent with the labor-augmenting CES production function.**

The error appears to come from Stage 12 (per [au_pac.mod:1334](dynare/au_pac.mod#L1334) comment):
> "Stage 12 fix: Added real wage sensitivity from paper eq. 55:
>    n* = b0 + q - ē - σ·(w̃ - pQ - ē - h)
> In growth rates: dln_n_star depends on productivity AND real wage gap."

Stage 12 correctly identified eq 55 has `-ē` and `-σ·(w̃ - pQ - ē - h)`, but
implemented it as `+dln_tfp/(1-α_k) - σ·rw_gap` instead of `-dln_tfp/(1-α_k) - σ·rw_gap`.
The leading dln_tfp term should be **negative**, not positive.

**Combined with the missing `Δq` channel (action #17)**, the AUSPAC `eq_dln_n_star_bar`
gets:
- Sign on dln_tfp **wrong** (+2.794 vs FR-BDF's -0.843)
- Output channel **missing** entirely

Net effect on TFP-shock employment IRF: AUSPAC predicts large positive employment
response to TFP shock (because of +2.794 coefficient). FR-BDF predicts a small
positive response (≈+(σ−α)·dln_E for labor-augmenting tech with σ>α: +(0.5366−0.45)·dln_E = +0.087·dln_E).

⚠ **This is the second-most-impactful finding in the audit so far** (after the
TFP shock random-walk fix). Combined with the user's original concern about
permanent ln_Q deviations, this likely contributes to anomalous employment-gap
behaviour under TFP shocks.

⚠ **Recommended fix** (combine with action #17):
```
[name = 'eq_dln_n_star_bar']
dln_n_star_bar = yhat_au_growth                       // NEW: Δq channel (FR-BDF eq 55)
               - dln_tfp/(1 - alpha_k)                // FIXED: was +, should be −
               - sigma_ces * rw_gap;                  // unchanged
```
where `yhat_au_growth = yhat_au - yhat_au(-1)` (or some output-growth proxy).

This needs verification once the model recompiles — there may be tightly-coupled
implications elsewhere.

### Salaried employment short-run PAC (FR-BDF eq 56)

FR-BDF eq 56 (4th-order PAC, simplified for comparison):
```
Δn_{S,t} = β_0·(n*_{S,t-1} - n_{S,t-1})
         + PV(Δn̄*_S)_{t|t-1} + PV(Δn̂*_S)_{t|t-1}
         + β_1·Δn_{S,t-1} + β_2·Δn_{S,t-2} + β_3·Δn_{S,t-3}
         + (1-β_1-β_2-β_3-ω)·Δn̄*_{S,t}                                 ← growth-neutrality
         + β_4·Δŷ_t                                                    ← output gap CHANGE
         + ε_t
```

AUSPAC `eq_dln_n_pac` ([au_pac.mod:1361](dynare/au_pac.mod#L1361)):
```
diff(ln_n_level) = b0_n * (n_hat(-1) - ln_n_level(-1))
                 + b1_n*diff(ln_n_level(-1))
                 + b2_n*diff(ln_n_level(-2))
                 + b3_n*diff(ln_n_level(-3))
                 + b4_n*diff(ln_n_level(-4))                            ← AUSPAC adds 4th lag
                 + pac_expectation(pac_n)
                 + b5_n * yhat_au                                        ← LEVEL not CHANGE
                 + b_covid_* * dummies
                 + pv_n_aux                                              ← §3 wedge concern
                 + eps_n;
```

| FR-BDF term | AUSPAC term | Verdict |
|---|---|---|
| Error correction `β_0·(n* - n)_{t-1}` | `b0_n·(n_hat(-1) - ln_n_level(-1))` | ✓ |
| 3-period lag structure | **4-period** lag structure (b1, b2, b3, b4_n) | ⚠ AU adds 4th lag |
| `PV(Δn̄*_S) + PV(Δn̂*_S)` | `pac_expectation(pac_n) + pv_n_aux` | ⚠ wedge concern (§3 #11) |
| `(1-β_1-β_2-β_3-ω)·Δn̄*_{S,t}` (growth-neutrality) | absent (or in `pac_expectation`) | ⚠ same concern as VA price |
| `β_4·Δŷ_t` (output gap CHANGE) | `b5_n·yhat_au` (output gap LEVEL) | ⚠ different — change vs level |
| (no covid in FR-BDF) | `b_covid_* * dummies` | ⚠ AU pandemic addition |

### Calibration comparison (Table 4.5.6)

| Param | FR-BDF | AUSPAC | Notes |
|---|---|---|---|
| β_0 (error correction) | 0.06 (s.e. 0.02) | b0_n = 0.0569 | ✓ matches |
| β_1 (1-quarter lag) | **0.87** (s.e. 0.11) | b1_n = 0.3211 | ⚠ AU much less persistent |
| β_2 (2-quarter lag) | -0.30 (s.e. 0.15) | b2_n = -0.1869 | ⚠ AU smaller magnitude |
| β_3 (3-quarter lag) | 0.17 (s.e. 0.10) | b3_n = -0.0763 | ⚠ AU has wrong sign |
| (no β_4 lag in FR-BDF) | - | b4_n = -0.0852 | ⚠ AU adds 4th lag |
| β_4 / b5_n (output gap) | 0.15 (s.e. 0.03) | b5_n = 0.0072 [-0.084, 0.080] | ⚠ AU effectively zero (HPD straddles 0) |
| ω (nonstationary share) | 0.26 | omega_n = 0.30 | ✓ similar |

⚠ AU lag structure is **substantively different** from FR-BDF's. FR-BDF has very
high persistence (β_1=0.87) with sign-alternating lower-order corrections.
AUSPAC has more moderate persistence with smaller corrections. This may reflect
ABS data properties (less persistent quarterly employment dynamics than French
QNA) or a genuinely different employment adjustment process.

The output-gap channel `b5_n ≈ 0` again confirms the **AU flat-Phillips finding**:
employment doesn't respond directly to output gap in our short-run estimation.

### Auxiliary equation for E-SAT (FR-BDF eq 57)

```
n̂*_{S,t} = β_0·ŷ_{t-1} + β_1·(i_{t-1} - ī_{t-1}) + β_2·(π_Q,t-1 - π̄_Q,t-1) + β_3·n̂*_{S,t-1} + ε_t
```

AUSPAC `var_n` ([au_pac.mod:1065](dynare/au_pac.mod#L1065)):
```
n_hat = ρ_n_aux·n_hat(-1) + a_n_y·y_gap_var(-1) + a_n_i·i_gap_var(-1)
      + a_n_pi·pi_gap_var(-1) + a_n_u·u_gap_var(-1) + eps_var_n
```

| FR-BDF | AUSPAC | Verdict |
|---|---|---|
| ŷ_{t-1}, (i-ī)_{t-1}, (π_Q-π̄_Q)_{t-1}, n̂*_{S,t-1} | y_gap, i_gap, pi_gap, n_hat lags | ✓ aligned |
| (no û channel) | `+ a_n_u · u_gap_var(-1)` | ⚠ AU adds u-gap channel |

✓ Structurally aligned, AU adds one extra channel.

### §4.5 summary

**Verdict on labor market block**:

- ⚠ Wage Phillips spec is structurally simpler than FR-BDF eq 52 (no minimum-wage
  channel, simplified to NK textbook form, possibly wrong inflation measure)
- ✗ **Wage Phillips κ_w sign convention** likely wrong (positive vs FR-BDF's
  negative β_4 = -0.32). Posterior straddles zero so empirically unidentified,
  but sign convention should match FR-BDF.
- ✗ **`eq_dln_n_star_bar` has wrong sign on dln_tfp leading term** (+2.794 vs
  FR-BDF's −0.843). Stage 12 fix introduced this error. Combined with missing
  `Δq` channel (action #17), labor-demand target dynamics are substantially off.
- ⚠ Employment short-run PAC has 4 lags vs FR-BDF's 3
- ⚠ Employment PAC uses output gap **level** vs FR-BDF's output gap **change**
- ⚠ AU calibration substantially different on lag persistence (β_1 = 0.32 vs
  0.87) — may be real AU labor-market property or estimation issue

**Action items added**:
21. ✗ **Top priority — fix `eq_dln_n_star_bar`**: change leading term from
    `+dln_tfp/(1-α_k)` to `−dln_tfp/(1-α_k)`. Combine with action #17 (add
    output-growth channel). Affects all 8 .mod files.
22. ✗ **Wage Phillips sign**: flip `+ kappa_w · pv_u_gap` to `− kappa_w · pv_u_gap`
    OR change MCMC prior to centre kappa_w on FR-BDF's −0.32 value, then re-run
    Bayesian estimation.
23. ⚠ Verify `pi_au` definition: if it's VA price inflation, replace with `pi_c`
    (consumer price inflation) in `eq_pi_w` to match FR-BDF eq 52's indexation.
24. ⚠ Consider replacing `b5_n · yhat_au` with `b5_n · diff(yhat_au)` (output gap
    change) to match FR-BDF eq 56's β_4·Δŷ_t.

---

## §4.6.1 Household consumption — findings

The single largest demand-side block. FR-BDF specifies three coupled equations:
target (eq 59), permanent income (eq 60), short-run PAC (eq 61), plus the
auxiliary real bank lending rate equation (eq 62).

### Long-run target (FR-BDF eq 59)

```
c*_t = α_0 + PV(y_H)|_{t-1} + α_1·(r_LH,t - (ī_t - π̄_t))
```

Where `PV(y_H)` = permanent income (PV of disposable household income, eq 60).
`r_LH` = real household bank lending rate. `(ī_t - π̄_t)` = LR real short rate.

Calibration (text after eq 59): α_0 = -0.16, α_1 = -0.95, implied IES ≈ 0.1.

### ⚠ AU permanent-income simplification

FR-BDF eq 60: `PV(y_H)|_{t-1} = PV(y_H − ȳ)|_{t-1} + ȳ_t` — separates the
income-output ratio gap from LR output. Requires modeling **real disposable
household income** y_H as a separate variable (taxes, transfers, wages, asset
income aggregated).

AUSPAC `eq_pv_yh` ([au_pac.mod:1392](dynare/au_pac.mod#L1392)):
```
pv_yh = (1 - beta_c) * yhat_au + beta_c * pv_yh(+1);
```

Comment ([au_pac.mod:1386](dynare/au_pac.mod#L1386)): *"PV(yH)_t = (1-beta_c)·yhat_au_t + beta_c·PV(yH)_{t+1}"*

⚠ AUSPAC uses **PV of OUTPUT GAP `yhat_au`** as a permanent-income proxy. This
is a substantial simplification — FR-BDF's `PV(y_H)` is the PV of disposable
household income / LR GDP ratio. The proxy is defensible (real wages track output
in Cobb-Douglas approximation) but loses the disposable-income channel (taxes,
transfers, capital income).

⚠ **Action item**: document this proxy explicitly. Consider whether to add a
disposable-income variable y_H to the .mod (would require AU income/tax data).

### Target equation `eq_dln_c_star_bar`

AUSPAC ([au_pac.mod:1399](dynare/au_pac.mod#L1399)):
```
dln_c_star_bar = kappa_inc · (pv_yh - pv_yh(-1))
               + alpha_c_r · ((i_lh - pi_c - LR_real_rate) - lagged_same)
```

| FR-BDF eq 59 term (in growth form) | AUSPAC term | Verdict |
|---|---|---|
| ΔPV(y_H) | `kappa_inc · Δpv_yh` | ⚠ proxy: PV of output gap not income |
| α_1 · Δ(r_LH - ī - π̄) | `alpha_c_r · Δ(i_lh - pi_c - LR_real)` | ✓ form matches; α_1 = -0.95 EXACT match |
| α_0 (constant) | absent | ✓ gap form |

✓ Real-rate channel structurally matches FR-BDF with **exact α_1 = -0.95**.

### Calibration comparison

| Param | FR-BDF | AUSPAC | Notes |
|---|---|---|---|
| α_0 (target constant) | -0.16 | absent | ✓ gap form |
| α_1 (real rate sensitivity) | -0.95 | alpha_c_r = -0.95 | ✓ EXACT match |
| β_c (consumption discount) | 0.95 | beta_c = 0.95 | ✓ EXACT match |
| (kappa_inc not in FR-BDF) | - | 0.050 | AU permanent-income sensitivity |

### Short-run PAC (FR-BDF eq 61)

FR-BDF eq 61 (1st-order PAC with multiple expectation channels):
```
Δc_t = β_0·(c*_{t-1} - c_{t-1})                                ← error correction
     + β_1·Δc_{t-1}                                            ← lag persistence
     + PV²(y_H - ȳ)|_{t-1}                                    ← NESTED PV (expectation of expectation)
     + α_1·(PV(r_LH)|_{t-1} - (PV(ī)|_{t-1} - PV(π̄)|_{t-1}))    ← PV of real rate gap
     + (1-β_1)·(Δ(ȳ_t) - Δ(y_{H,t} - ȳ_t))                     ← LR output growth - income-output ratio change
     + β_2·Δŷ_t                                                ← rule-of-thumb consumers (output gap CHANGE)
     + β_3·(Δr_{LH,t} - (Δī_t - Δπ̄_t))                          ← wealth effect (interest rate change)
     + β_4·δ_prime                                             ← 2011 dummy
```

AUSPAC `eq_dln_c_pac` ([au_pac.mod:1415](dynare/au_pac.mod#L1415)):
```
diff(ln_c_level) = b0_c · (c_hat(-1) - ln_c_level(-1))
                 + b1_c · diff(ln_c_level(-1))
                 + pac_expectation(pac_c)
                 + b2_c · i_gap(-1)                            ← lagged interest rate GAP (LEVEL)
                 + b_di_c · di_gap                             ← interest rate CHANGE (Phase C addition)
                 + b3_c · yhat_au                              ← output gap LEVEL
                 + b_covid_* · dummies
                 + pv_c_aux                                    ← AU additive wedge
                 + eps_c
```

| FR-BDF term | AUSPAC term | Verdict |
|---|---|---|
| Error correction `β_0·(c* - c)_{t-1}` | `b0_c·(c_hat(-1) - ln_c_level(-1))` | ✓ |
| Lag persistence `β_1·Δc_{t-1}` | `b1_c · diff(ln_c_level(-1))` | ✓ |
| `PV²(y_H - ȳ)|_{t-1}` (nested PV) | `pac_expectation(pac_c)` (Dynare auto-PV from `var_c`) | ⚠ wedge concern (§3 #11) |
| `α_1·PV(real rate gap)` | **MISSING — no PV-of-real-rate term in PAC eq** | ✗ MISMATCH |
| `(1-β_1)·(Δȳ - Δ(y_H - ȳ))` | **MISSING — no output-growth / income-ratio change term** | ✗ MISMATCH |
| `β_2·Δŷ_t` (output gap CHANGE) | `b3_c · yhat_au` (output gap LEVEL) | ⚠ AU uses level not change |
| `β_3·(Δr_{LH} - Δī - Δπ̄)` (wealth effect, RATE CHANGE) | `b_di_c · di_gap` | ✓ ish — but uses i_gap change not real lending rate change |
| (none in FR-BDF) | `b2_c · i_gap(-1)` (lagged i_gap level) | ⚠ AU adds extra channel |
| `β_4·δ_prime` (2011 dummy) | absent | ✓ no AU equivalent |
| (none) | `b_covid_* · d_covid_*` | ⚠ AU pandemic |
| (none) | `pv_c_aux` | ⚠ §3 wedge concern |

### ✗ Two missing FR-BDF channels in `eq_dln_c_pac`

**1. PV of real rate gap (`α_1·(PV(r_LH) - PV(ī) + PV(π̄))`) — MISSING**

FR-BDF eq 61 has an explicit forward-looking real-rate channel: the PV of expected
future real lending rate gap. This propagates the consumption response to monetary
policy through expected future real rates.

AUSPAC has lagged level (`b2_c · i_gap(-1)`) and current change (`b_di_c · di_gap`)
but **no PV-of-real-rate term**. Consequence: under MCE, our consumption response
to monetary shocks may underestimate the forward-looking real-rate channel that
FR-BDF identifies as central to no-forward-guidance-puzzle behaviour.

**2. Output growth − income-ratio change `(1-β_1)·(Δȳ - Δ(y_H - ȳ))` — MISSING**

This term ensures growth-neutrality of consumption (analogous to the missing
`(1-β_1-ω)·π̄*_Q` term in §4.4 VA price audit). With AU's β_1 = 0.035 and
omega_c = 0.369, the implied coefficient is `(1-0.035) ≈ 0.965` on the missing
term — substantial.

This may explain why `pv_c_aux` is structurally needed (substituting for the
missing growth-neutrality term, per §4.4 audit hypothesis).

### Calibration comparison (Table 4.6.2)

| Param | FR-BDF | AUSPAC | Notes |
|---|---|---|---|
| β_0 (error correction) | 0.12 (s.e. 0.05) | b0_c = 0.0601 | AU half magnitude |
| β_1 (lag persistence) | -0.08 (s.e. 0.09) | b1_c = 0.0354 | both small, sign inconsistent (HPD straddles zero in both) |
| β_2 (output gap CHANGE) | 0.26 (s.e. 0.11) | b3_c = 0.0199 [-0.064, 0.095] | ⚠ AU effectively zero (HPD straddles 0) — **fourth confirmation of AU flat Phillips** |
| β_3 (interest rate change wealth) | -0.71 (s.e. 0.45) | b_di_c = -0.701 | ✓ near-EXACT match BUT see Phase C note |
| β_4 (2011 dummy) | 0.007 | absent | ✓ no AU equivalent |
| (extra) | - | b2_c = -0.3307 [-0.589, -0.057] | AU adds significant lagged-i_gap channel |
| α_1 (target) | -0.95 | alpha_c_r = -0.95 | ✓ EXACT match |
| β_c (consumption discount) | 0.95 | beta_c = 0.95 | ✓ EXACT match |

### ⚠ b_di_c = -0.701 is essentially imported from FR-BDF's prior

STATUS.md notes: *"b_di_c = -0.701: Phase C Bayesian regularised (IV with monetary-
surprise instrument failed identification due to RBA endogeneity); posterior
dominated by prior N(-0.71, 0.30^2)"*

So the "match" with FR-BDF's β_3 = -0.71 is artifactual — we couldn't identify
b_di_c from AU data and used FR-BDF's value as the prior mean. The "agreement"
between AUSPAC's posterior and FR-BDF's estimate is an artifact of the prior,
not independent confirmation.

⚠ Worth flagging in the working paper: AU's interest-rate-change wealth-effect
coefficient is **not independently identified** from AU data.

### Real bank lending rate auxiliary (FR-BDF eq 62)

FR-BDF eq 62:
```
r_LH,t = β_0·r_LH,{t-1} + (1-β_0)·(ī_{t-1} - π̄_{t-1} + s̄_LH)
       + β_1·(i_{t-1} - ī_{t-1}) + β_2·(π̄_{t-1} - π_{t-1})
```

With s̄_LH = 1.12% (annualized term premium = sum of bank lending spread + 10y term premium).

Calibration (Table 4.6.5): β_0 = 0.88 (high persistence), β_1 = 0.12 (short-rate
gap pass-through), β_2 = -0.06 (inflation-gap counter).

**AUSPAC**: defer detailed comparison to §4.8 audit — this is part of the
financial block.

For now: AUSPAC has `i_lh` (nominal household lending rate) and the
real-rate-gap construction in `eq_dln_c_star_bar` ([au_pac.mod:1399-1401](dynare/au_pac.mod#L1399)) uses
`(i_lh - pi_c - (i_ss + tp_ss + spread_lh - pi_ss_au))`. Structurally aligned
with FR-BDF eq 62's anchor structure. ✓ (deferred for full check)

### Auxiliary equations for E-SAT (Tables 4.6.3-4.6.7)

FR-BDF adds 5 auxiliary policy functions for the consumption block:
1. `PV(y_H - ȳ)|_{t-1}` (income-output ratio expectation)
2. `PV²(y_H - ȳ)|_{t-1}` (nested PV — expectation of expectation, eq 61 input)
3. `PV(i_LH)|_{t-1}` (bank lending rate)
4. `PV(Δī)|_{t-1}` (LR rate)
5. `PV(Δπ̄)|_{t-1}` (LR inflation)

Plus FR-BDF auxiliary equations for the input variables:
- `y_H - ȳ` (income-output ratio): driven by Δw_eff, û (Table 4.6.3 col 2)
- `Δw_eff` (real efficient wage growth): driven by own lag, û (Table 4.6.3 col 3)

AUSPAC has `var_yh` and `var_c` in the enriched VAR:

`var_yh` ([au_pac.mod:1070](dynare/au_pac.mod#L1070)):
```
yh_ratio_hat = ρ·yh_ratio_hat(-1) + a_yh_y·y_gap(-1) + a_yh_u·u_gap(-1) + eps_var_yh
```

`var_c` ([au_pac.mod:1076](dynare/au_pac.mod#L1076)):
```
c_hat = ρ·c_hat(-1) + a_c_y·y_gap(-1) + a_c_i·i_gap(-1) + a_c_pi·pi_gap(-1)
      + a_c_u·u_gap(-1) + a_c_yh·yh_ratio_hat(-1) + eps_var_c
```

| Item | FR-BDF | AUSPAC | Verdict |
|---|---|---|---|
| Income-output ratio auxiliary | yes (driven by Δw_eff, û) | yes (driven by y_gap, u_gap) | ⚠ AU drops Δw_eff channel |
| Nested PV² auxiliary for consumption | yes — depends on income-ratio expectation | yes — `var_c` depends on `yh_ratio_hat` (correctly nested) | ✓ structurally aligned |
| Real efficient wage auxiliary `Δw_eff` | yes (separate equation) | absent in E-SAT (would need wage equation in VAR) | ⚠ AU simplification |

✓ Nested PV² structure for consumption correctly implemented (rare and important
mechanical detail for FR-BDF-style PAC). ⚠ But the Δw_eff channel is dropped,
consistent with the permanent-income proxy simplification.

### §4.6.1 summary

**Verdict on consumption block**:

- ✓ Long-run target structure matches FR-BDF eq 59 (real-rate channel, EXACT
  α_1 = -0.95 match)
- ✓ Discount factor β_c = 0.95 matches (high discount per FR-BDF risk-aversion
  rationale; key for no-forward-guidance-puzzle)
- ✓ Nested PV² structure correctly implemented (`var_yh` → `var_c`)
- ⚠ **Permanent income proxied by PV of output gap** instead of FR-BDF's
  PV of disposable income — substantial AU simplification, defensible but
  loses fiscal/wealth channels
- ✗ **`α_1·PV(real rate gap)` term MISSING from short-run PAC** — FR-BDF eq 61
  has explicit forward-looking real-rate channel; AUSPAC has only lagged level
  + current change. May contribute to weaker monetary transmission.
- ✗ **`(1-β_1)·(Δȳ - Δ(y_H - ȳ))` growth-neutrality term MISSING** — likely
  links to `pv_c_aux` substitute hypothesis (§4.4 #18)
- ⚠ b_di_c = -0.701 "matches" FR-BDF only because we used FR-BDF's value as the
  Bayesian prior; AU IV failed to identify
- ⚠ b3_c ≈ 0 (output gap channel) — fourth confirmation of AU flat Phillips
- ⚠ AU drops minimum-wage / efficient-wage channels throughout (consistent
  with §4.5 wage Phillips simplification)

**Action items added**:
25. ⚠ Document permanent-income proxy: AU uses `PV(yhat_au)` instead of
    FR-BDF's `PV(y_H)`. Consider adding disposable income variable `y_H` if
    AU income/tax data is available.
26. ✗ **Add `α_1·PV(real rate gap)` term to `eq_dln_c_pac`** to match FR-BDF
    eq 61. Requires defining `pv_r_lh_gap = (1-β)·(i_lh - pi_c - LR_real) +
    β·pv_r_lh_gap(+1)` and adding `+ alpha_c_r · pv_r_lh_gap` to the PAC eq.
    Affects no-forward-guidance-puzzle behaviour (Phase L). High priority for
    monetary-policy applications.
27. ⚠ Linked to #18: investigate whether `pv_c_aux` is substituting for the
    missing `(1-β_1)·(Δȳ - Δ(y_H - ȳ))` growth-neutrality term in eq 61.

---

## §4.6.2 Business investment — findings

### Long-run target (FR-BDF eq 63)

```
log I*_B,t = α_0 + q_t - σ·log r_KB,{t-1} + log(I*/K*)
```

In growth form: `Δlog I*_B = Δq - σ·Δlog r_KB`.

Calibration: α_0 = 0.016 (estimated), σ = 0.53 (calibrated from §4.3 supply block).

AUSPAC `eq_dln_ib_star_bar` ([au_pac.mod:1452](dynare/au_pac.mod#L1452)):
```
dln_ib_star_bar = kappa_ib_y · yhat_au - sigma_ces · dln_uc_k
```

| FR-BDF target growth term | AUSPAC term | Verdict |
|---|---|---|
| Δq (output growth) | `kappa_ib_y · yhat_au` (output gap **LEVEL**) | ⚠ same as §4.3 — uses gap level not growth |
| -σ·Δlog r_KB | `-sigma_ces · dln_uc_k` | ✓ aligned |
| α_0 | absent | ✓ gap form |

Already action item #16 (output channel in `dln_ib_star_bar`).

### Short-run PAC (FR-BDF eq 64) — best-aligned PAC equation in audit so far

FR-BDF eq 64:
```
Δlog I_B,t = β_0·log(I*_B,t-1 / I_B,t-1)                                ← error correction
           + β_1·Δlog I_B,{-1} + β_2·Δlog I_B,{-2}                       ← 2 lags
           + PV(Δq̂)|_{t-1} - σ·PV(Δlog r̂_KB)|_{t-1}                    ← SPLIT PV
           + (1-β_1-β_2)·(Δq̂_{t-1} - σ·Δlog r̂_KB,{t-1})                 ← growth-neutrality
           + β_3·(Δq_{t-1} - Δȳ_{t-1})                                  ← ad hoc business-cycle demand
```

AUSPAC `eq_dln_ib_pac` ([au_pac.mod:1468](dynare/au_pac.mod#L1468)):
```
diff(ln_ib_level) = b0_ib · (ib_hat(-1) - ln_ib_level(-1))              ← error correction
                  + b1_ib · diff(ln_ib_level(-1))                       ← lag 1
                  + b2_ib · diff(ln_ib_level(-2))                       ← lag 2
                  + pac_expectation(pac_ib)                             ← PV(Δq̂) part
                  + b3_ib · yhat_au                                      ← ad hoc demand (LEVEL)
                  + b_covid_* · dummies
                  - sigma_ces · pv_rKB_aux                               ← user-cost PV channel ✓
                  + pv_ib_aux                                           ← AU wedge
                  + eps_ib
```

| FR-BDF term | AUSPAC term | Verdict |
|---|---|---|
| Error correction | `b0_ib·(ib_hat(-1) - ln_ib_level(-1))` | ✓ |
| 2 lags | `b1_ib`, `b2_ib` | ✓ |
| **`PV(Δq̂)|_{t-1} - σ·PV(Δlog r̂_KB)|_{t-1}` SPLIT** | **`pac_expectation(pac_ib) - sigma_ces · pv_rKB_aux`** | ✓ **AUSPAC correctly splits** |
| `(1-β_1-β_2)·(Δq̂ - σ·Δlog r̂_KB)` (growth-neutrality) | absent (or in pac_expectation) | ⚠ recurring concern |
| `β_3·(Δq_{t-1} - Δȳ_{t-1})` (output GROWTH gap) | `b3_ib · yhat_au` (output gap LEVEL) | ⚠ change vs level |

✓ **Major positive finding**: the `- sigma_ces · pv_rKB_aux` term explicitly
implements FR-BDF eq 64's user-cost PV channel as a **separate additive term**
beyond `pac_expectation(pac_ib)`. This is structurally correct per FR-BDF and
shows that AUSPAC's authors understood the eq 64 split. Best-aligned PAC
equation in the audit so far.

⚠ Caveat: this also weakens the §3 `pv_X_aux` doubling concern for *this*
equation specifically — `pv_rKB_aux` here is clearly playing the role of
`σ·PV(Δlog r̂_KB)` (FR-BDF's user-cost PV channel), not "wedge". The remaining
`pv_ib_aux` is still the §3 wedge concern.

### Calibration comparison (Table 4.6.9)

| Param | FR-BDF | AUSPAC | Notes |
|---|---|---|---|
| β_0 (error correction) | 0.085 (s.e. 0.029) | b0_ib = 0.0188 | AU 4.5× smaller |
| β_1 (1-quarter lag) | 0.29 (s.e. 0.14) | b1_ib = 0.0801 | AU much smaller |
| β_2 (2-quarter lag) | 0.20 (s.e. 0.1) | b2_ib = -0.0445 | AU smaller, sign flipped (OLS not in MCMC) |
| β_3 (ad hoc demand) | 0.58 (s.e. 0.36) | b3_ib = 0.3094 | AU about half |
| σ (user cost) | 0.53 | sigma_ces = 0.5366 | ✓ matches |

Per STATUS.md: *"b3_ib = 0.331 (HPD [0.166, 0.477]) — strong business-investment
accelerator"*. So output channel **is** statistically significant — distinguishes
from the b2/b3/b5_n flat-Phillips findings elsewhere. Investment responds to
demand, just less than FR-BDF's β_3=0.58 magnitude.

### Auxiliary equations (Tables 4.6.11-12)

FR-BDF Table 4.6.11 — `PV(Δq̂)` policy function with separate `q̂` auxiliary:
- q̂ aux: `q̂_t = a·ŷ_t + b·q̂_{t-1}` (a=0.61, b=0.59)

AUSPAC `var_ib` ([au_pac.mod:1081](dynare/au_pac.mod#L1081)):
```
ib_hat = ρ·ib_hat(-1) + a_ib_y·y_gap(-1) + a_ib_pi·pi_gap(-1) + a_ib_u·u_gap(-1) + eps_var_ib
```

⚠ AU uses `ib_hat` (investment target gap directly) instead of FR-BDF's `q̂`
(value-added gap as input to investment). Different intermediate variable.
Adds u_gap channel that FR-BDF doesn't have. Otherwise structurally aligned.

FR-BDF Table 4.6.12 — `PV(Δlog r̂_KB)` policy function:
- (i-ī)_{t-1}: 0.24 (positive — high real rate → high expected user cost)
- (i_{t-2}-ī_{t-2}): -0.13 (auxiliary x_t = i_{t-1})
- ŷ_{ea,t-1}: 0.012, (π_ea-π̄_ea)_{t-1}: 0.038
- r̂_{KB,t-1}: -0.055
- Aux equation has rho = 4.45 (anomalously high, possibly typo)

AUSPAC `var_rKB` ([au_pac.mod:1086](dynare/au_pac.mod#L1086)):
```
rKB_hat = ρ·rKB_hat(-1) + a_rKB_i·i_gap_var(-1) + eps_var_rKB
```

⚠ AU substantially simpler — just one channel (i_gap with single lag, no
2-lag implementation). FR-BDF has more dynamics (2 i-gap lags via aux variable,
plus EA channels).

### §4.6.2 summary

- ✓ **Best-aligned PAC equation in audit so far**: `pv_rKB_aux` correctly
  implements FR-BDF eq 64's user-cost PV channel as separate additive term
- ✓ User cost equation structure aligned (modulo §4.3 timing concern)
- ⚠ Output channel uses `yhat_au` (level) instead of FR-BDF's `Δq̂` (change) —
  same as employment & consumption (action #16, #24)
- ⚠ Coefficients much smaller than FR-BDF (β_0, β_1) but b3_ib=0.31 IS significant
- ⚠ User cost auxiliary `var_rKB` simplified (one channel vs FR-BDF's multi-channel)

---

## §4.6.3 Household investment — findings

### Long-run target (FR-BDF eq 66)

```
log I*_H = log γ_0 + PV(y_H)|_{t-1}                                    ← permanent income
         + γ_1·(p_IH,{t-1} - p_C,{t-1})                                ← new housing price relative to consumption
         + γ_2·(p_SH,{t-2} - p_C,{t-2})                                ← OLD housing price relative (Tobin's Q)
         + γ_3·log(i_LH,{t-2} - PV(π_Q)|_{t-2|t-3} + δ_H)              ← real housing user cost
```

Calibration Table 4.6.14:
- γ_0 = 0.005, γ_1 = -2.2 (new housing price), γ_2 = +0.55 (Tobin's Q),
  γ_3 = -0.071 (real user cost), δ_H = 1.8% per year

AUSPAC `eq_dln_ih_star_bar` ([au_pac.mod:1495](dynare/au_pac.mod#L1495)):
```
dln_ih_star_bar = kappa_ih_inc · (pv_yh - pv_yh(-1))                   ← perm income (output-gap proxy)
                - kappa_mort · (i_lh - LR_lending)                     ← mortgage rate gap LEVEL
                + kappa_ph · ph_gap(-1)                                 ← housing price gap (lagged)
```

### ✗ Multiple channels missing or simplified

| FR-BDF eq 66 term (growth form) | AUSPAC term | Verdict |
|---|---|---|
| ΔPV(y_H) (permanent income change) | `kappa_ih_inc · Δpv_yh` | ⚠ output-gap proxy (consistent with §4.6.1) |
| **γ_1·Δ(p_IH - p_C)** (new housing price relative) | **MISSING** | ✗ no `p_IH` deflator in AUSPAC |
| γ_2·Δ(p_SH - p_C) (Tobin's Q on existing housing) | `kappa_ph · ph_gap(-1)` | ⚠ AU uses lagged level, FR-BDF uses change in relative price |
| γ_3·Δlog(i_LH - PV(π_Q) + δ_H) (real user cost) | `-kappa_mort · (i_lh - LR_lending)` | ✗ AU uses NOMINAL rate gap, missing PV(π_Q), missing δ_H |

⚠ **Three substantial simplifications**:
1. **No `p_IH` (new housing investment deflator) variable** — AUSPAC drops the
   relative-price-of-new-housing channel entirely
2. **Real housing user cost not implemented properly** — AUSPAC uses nominal
   mortgage rate deviation, not real user cost (no inflation deflation, no
   housing depreciation δ_H)
3. **Tobin's Q channel uses housing price gap LEVEL not CHANGE** — different
   timing convention

### Calibration comparison (Table 4.6.14)

| Param | FR-BDF | AUSPAC | Notes |
|---|---|---|---|
| γ_0 | 0.005 | absent | ✓ gap form |
| γ_1 (new housing price elasticity) | -2.2 | absent | ✗ missing channel |
| γ_2 (Tobin's Q on existing housing) | +0.55 | kappa_ph = 0.03 | ⚠ AU 18× smaller (different scaling) |
| γ_3 (real user cost) | -0.071 | -kappa_mort = -0.048 | ⚠ AU smaller, simpler form |
| δ_H (housing depreciation) | 1.8% per year | absent in target | ⚠ missing |

### Short-run PAC (FR-BDF eq 67)

FR-BDF eq 67:
```
Δlog I_H = β_0·error_correction
         + β_1·Δlog I_H,{-1}                                            ← 1 lag (FR-BDF uses 1, not 2)
         + PV(Δlog Î*_H)|_{t-1} - PV(Δlog Ī*_H)|_{t-1}                  ← gap-trend split PV
         + (1-β_1-ω)·Δlog Ī*_H,t                                        ← growth-neutrality
         + β_2·Δŷ_t                                                      ← output gap CHANGE
         + β_3·(Δp_SH,t - Δp̄_SH,t)                                       ← housing price gap CHANGE
```

AUSPAC `eq_dln_ih_pac` ([au_pac.mod:1515](dynare/au_pac.mod#L1515)):
```
diff(ln_ih_level) = b0_ih · (ih_hat(-1) - ln_ih_level(-1))
                  + b1_ih · diff(ln_ih_level(-1))                        ← lag 1
                  + b2_ih · diff(ln_ih_level(-2))                        ← lag 2 (extra)
                  + pac_expectation(pac_ih)
                  + b3_ih · yhat_au                                       ← output gap LEVEL
                  + b_ph_ih · ph_gap(-1)                                  ← housing price gap LEVEL (lagged)
                  + b_covid_* · dummies
                  + pv_ih_aux                                            ← AU wedge
                  + eps_ih
```

| FR-BDF | AUSPAC | Verdict |
|---|---|---|
| Error correction | ✓ | ✓ |
| 1 lag (β_1 only) | **2 lags** (b1_ih, b2_ih) | ⚠ AU adds 2nd lag |
| Gap-trend split PV | combined `pac_expectation(pac_ih)` | ⚠ doesn't split |
| Growth-neutrality `(1-β_1-ω)·Δlog Ī*_H,t` | absent | ⚠ recurring concern |
| `β_2·Δŷ_t` (output gap CHANGE) | `b3_ih · yhat_au` (LEVEL) | ⚠ change vs level |
| `β_3·(Δp_SH - Δp̄_SH)` (housing price CHANGE) | `b_ph_ih · ph_gap(-1)` (lagged LEVEL) | ⚠ change vs level |

### Calibration comparison (Table 4.6.15)

| Param | FR-BDF | AUSPAC | Notes |
|---|---|---|---|
| β_0 (error correction) | 0.056 (s.e. 0.019) | b0_ih = 0.0289 | AU half magnitude |
| β_1 (lag persistence) | 0.62 (s.e. 0.069) | b1_ih = 0.1152 | AU much smaller (5×) |
| β_2 (output gap change) | 0.34 (s.e. 0.20) | b3_ih = 0.2262 | AU smaller (~2/3) |
| β_3 (housing price change) | 0.32 (s.e. 0.09) | b_ph_ih = 0.0099 | ⚠ AU **30× smaller** |
| ω | 0.36 | (in pac_model) | ✓ similar |

⚠ b_ph_ih = 0.0099 documented in [au_pac.mod:697](dynare/au_pac.mod#L697) as Phase C result with
spliced 1959+ housing series. Sign matches FR-BDF (+) but magnitude is 30× smaller.
Per Phase C note: *"the AU housing-price-gap channel is close to zero in the
longer sample"*. Substantial AU finding — AU housing investment doesn't respond
to housing price changes the way French data does.

### Housing price equation (FR-BDF eq 69 vs AUSPAC `eq_dln_ph`)

FR-BDF eq 69 (existing housing stock price, AR(2) with inflation anchor):
```
Δp_SH,t = ρ_0·Δp_SH,{t-1} + ρ_1·Δp_SH,{t-2} + (1-ρ_0-ρ_1)·p̄i_t
```
ρ_0 = 0.48, ρ_1 = 0.43.

AUSPAC `eq_dln_ph` ([au_pac.mod:1830](dynare/au_pac.mod#L1830)):
```
dln_ph = rho_ph · dln_ph(-1)
       + alpha_ph_y · yhat_au                                            ← demand channel (NEW)
       + alpha_ph_r · i_gap(-1)                                           ← credit channel (NEW)
       + eps_ph
```

| FR-BDF | AUSPAC | Verdict |
|---|---|---|
| AR(2) | AR(1) | ⚠ AU drops 2nd lag |
| Inflation anchor `(1-ρ_0-ρ_1)·p̄i` | absent | ⚠ AU operates in real housing price space |
| (no demand channel) | `alpha_ph_y · yhat_au` | ⚠ AU adds demand channel |
| (no credit channel) | `alpha_ph_r · i_gap(-1)` | ⚠ AU adds credit channel |

⚠ AU housing price equation is structurally **different** from FR-BDF: real
prices (not nominal), simpler AR(1) with demand + credit channels added. This
reflects AU's variable-rate-mortgage-driven housing market vs France's
fixed-rate / inflation-driven structure. Defensible AU adaptation but
substantial divergence from FR-BDF eq 69.

### §4.6.3 summary

- ⚠ **Substantial simplification of FR-BDF target eq 66**: missing
  `p_IH` (new housing price) channel, simplified user cost (no PV(π_Q), no δ_H)
- ⚠ Tobin's Q coefficient (b_ph_ih = 0.0099) is 30× smaller than FR-BDF's
  γ_2 = 0.55 — Phase C empirical finding for AU
- ⚠ Housing price equation is restructured for AU (real prices, demand+credit
  channels) — defensible AU adaptation
- ⚠ AU adds 2nd lag in PAC; FR-BDF uses only 1 lag
- ⚠ `b_ph_ih` uses lagged level not change per FR-BDF eq 67's β_3

**Action items added**:
28. ⚠ Document `p_IH` (new housing price deflator) absence: AUSPAC drops the
    `γ_1·(p_IH - p_C)` channel from FR-BDF eq 66. Adding it would require an
    AU new-housing-investment-deflator series.
29. ⚠ Real housing user cost: replace `kappa_mort · (i_lh - LR_lending)` with
    proper real user cost including `-PV(π_Q)` and `+δ_H` per FR-BDF eq 66.
30. ⚠ Document AU housing price equation divergence: AU uses real prices with
    demand+credit channels (variable-rate-mortgage economy), FR-BDF uses
    nominal AR(2) with inflation anchor. Defensible, but worth flagging.

---

## §4.6.4 External trade — findings

Confirms the §2.4 audit observation: trade short-run uses ECM (not PAC) per
FR-BDF design. Both AUSPAC and FR-BDF do this. Three sub-blocks: exports
(eqs 70-71), non-energy imports (eqs 74-75), energy imports (eqs 76-77).

### Exports — long-run target (FR-BDF eq 70)

```
x*_t = β_0 + d_W,t + β_1·(p_X,t - p_CX,t) + β_2·ω_t
```
- d_W = world demand (with **unit coefficient** for BGP)
- p_X − p_CX = export price relative to foreign competitors
- ω_t = weight of emerging countries (proxy for "missing" competitor pressure)

Calibration (Table 4.6.20): β_0=11.93, β_1=−1.27, β_2=−0.63.

AUSPAC `eq_ln_x_eq` ([au_pac.mod:1631](dynare/au_pac.mod#L1631)):
```
ln_x_eq = beta_x · yhat_us + gamma_x · s_gap
```
- beta_x = 1.20, gamma_x = 0.40

| FR-BDF eq 70 | AUSPAC | Verdict |
|---|---|---|
| Constant β_0 | absent | ✓ gap form |
| World demand `d_W` × **unit coefficient** | `beta_x · yhat_us` (β_x=1.20, output gap LEVEL, not world demand) | ⚠ AU calibrates non-unit coef AND uses output gap not demand level |
| `β_1·(p_X − p_CX)` (price competitiveness) | `gamma_x · s_gap` (real exchange rate gap) | ⚠ AU uses RER not export-vs-competitor price ratio |
| `β_2·ω` (emerging-countries weight, −0.63) | absent | ⚠ no AU "Asian demand share" channel |

⚠ Three structural divergences. AU adaptation acceptable but worth noting:
1. **No `d_W` (true world demand) variable** — AU uses US output gap as proxy
2. **No price-competitiveness `(p_X − p_CX)` variable** — AU uses RER instead
3. **No emerging-country weight ω** — would help AU explain commodity-export
   dynamics linked to China/Asia demand

### Exports — short-run ECM (FR-BDF eq 71)

```
Δx_t = β_0·Δd_W,{t-1} + (1-β_0)·Δq̄ + β_1·[x_{t-1} - x*_{t-1}] + ε_t
```

✓ **Confirms FR-BDF §2.4 statement**: trade uses **ECM** form (single error-correction
to long-run target), not PAC. The `β_1·[x - x*]_{t-1}` term is the ECM signature.

AUSPAC `eq_dln_x` ([au_pac.mod:1636](dynare/au_pac.mod#L1636)):
```
dln_x = b0_x · x_gap(-1)               ← ECM ✓
      + b1_x · dln_x(-1)                ← AU adds own lag
      + b2_x · yhat_us                  ← contemporaneous demand (FR-BDF uses lagged)
      + b3_x · s_gap                    ← AU adds RER impact
      + b4_x · dln_pcom                 ← AU adds commodity price (Stage 11b, mining)
      + eps_x
```

| FR-BDF eq 71 | AUSPAC | Verdict |
|---|---|---|
| `β_0·Δd_W,{t-1}` (lagged demand growth) | `b2_x · yhat_us` (contemporaneous gap LEVEL) | ⚠ change vs level + timing |
| `(1-β_0)·Δq̄` (LR growth term — growth-neutrality) | absent | ⚠ AU drops |
| `β_1·[x - x*]_{t-1}` (error correction) | `b0_x · x_gap(-1)` | ✓ |
| (none in FR-BDF) | `b1_x · dln_x(-1)` (own lag) | ⚠ AU adds |
| (none) | `b3_x · s_gap` (impact RER) | ⚠ AU adds |
| (none) | `b4_x · dln_pcom` (commodity price) | ⚠ AU adds — defensible (mining-driven AU exports) |
| ε_t | eps_x | ✓ |

✓ ECM form **structurally matches FR-BDF eq 71** (key methodological point
from §2.4 verified).

### Exports — calibration comparison

| Param | FR-BDF | AUSPAC | Notes |
|---|---|---|---|
| LR β_0 (constant) | 11.93 | absent | ✓ gap form |
| LR β_1 (price elasticity) | -1.27 | gamma_x = +0.40 | ⚠ different spec (AU uses RER); magnitudes/signs not directly comparable |
| LR β_2 (emerging countries) | -0.63 | absent | ⚠ AU drops |
| LR demand elasticity | 1 (unit, FR-BDF balanced-growth constraint) | beta_x = 1.20 | ⚠ AU calibrates separately |
| SR β_0 (demand pass) | 0.83 | b2_x = 0.25 | ⚠ AU much smaller |
| SR β_1 (error correction) | -0.15 | b0_x = 0.05 | ⚠ AU 3× slower correction |
| (extra) | - | b1_x = 0.30 (own lag) | AU adds |
| (extra) | - | b3_x = 0.10 (impact RER) | AU adds |
| (extra) | - | b4_x = 0.15 (commodity price) | AU adds (mining) |

⚠ STATUS.md notes b1_x and b2_x kept at FR-BDF values because AU OLS gave
wrong-signed estimates (US output gap is wrong demand proxy). Phase D residual:
*"Asian-PMI / China-GDP proxies would help"*. AU export equation is not
independently identified from AU data.

### Non-energy imports — long-run target (FR-BDF eq 74)

```
m*_O,t = β_0 + d_MO,t + β_1·(p_X,t - p_MO,t) + β_2·(ws_t - q_N,t)
```
- d_MO = import-intensity-adjusted demand (eq 72: weighted sum of demand components)
- p_X − p_MO = price competitiveness (export vs non-energy import price)
- ws_t − q_N,t = "variety" of foreign vs French goods

Calibration (Table 4.6.21): LR β_0=2.79, β_1=1.11, β_2=0.39.

AUSPAC `eq_ln_m_eq` ([au_pac.mod:1656](dynare/au_pac.mod#L1656)):
```
ln_m_eq = beta_m · ln_d_iad + gamma_m · s_gap
```
- beta_m = 1.50, gamma_m = -0.40

| FR-BDF eq 74 | AUSPAC | Verdict |
|---|---|---|
| Constant β_0 | absent | ✓ gap form |
| `d_MO` (IAD demand) with unit coefficient | `beta_m · ln_d_iad` (β_m=1.50) | ⚠ AU calibrates non-unit elasticity |
| `β_1·(p_X − p_MO)` (price competitiveness, β_1=1.11) | `gamma_m · s_gap` (RER, γ_m=-0.40) | ⚠ AU uses RER not price ratio |
| `β_2·(ws − q_N)` (variety, β_2=0.39) | absent | ⚠ AU drops |

### IAD weights comparison (FR-BDF eq 72 vs AUSPAC `w_iad_*`)

FR-BDF eq 72: `D_MO = 0.194·C + 0.094·C_G + 0.252·I_B + 0.197·I_G + 0.150·I_H + 0.305·X`

| Component | FR-BDF | AUSPAC | Verdict |
|---|---|---|---|
| Consumption C | 0.194 | w_iad_c = 0.12 | ⚠ AU 38% lower (less import-content in consumption) |
| Government cons. C_G | 0.094 | w_iad_g = 0.08 | ⚠ AU slightly lower |
| Business inv. I_B | 0.252 | w_iad_ib = 0.25 | ✓ near-match |
| Government inv. I_G | 0.197 | (folded into w_iad_g?) | ⚠ AU lacks separate I_G weight |
| Household inv. I_H | 0.150 | w_iad_ih = 0.15 | ✓ EXACT match |
| Exports X | 0.305 | w_iad_x = 0.30 | ✓ near-match |

⚠ AUSPAC drops separate `I_G` (government investment) weight — folded into
overall government share. Otherwise IAD weight structure is well-aligned. ✓
Sourced from "ABS National Accounts" per [au_pac.mod:828+](dynare/au_pac.mod#L828) comments.

### Non-energy imports — short-run ECM (FR-BDF eq 75)

```
Δm_O = β_0·Δd_MO,{t-1} + (1-β_0)·Δȳ + β_1·[m_O - m*_O]_{t-1} + ε_t
```

AUSPAC `eq_dln_m` ([au_pac.mod:1661](dynare/au_pac.mod#L1661)):
```
dln_m = b0_m · m_gap(-1)
      + b1_m · dln_m(-1)
      + b2_m · iad
      + b3_m · s_gap
      + eps_m
```

| FR-BDF eq 75 | AUSPAC | Verdict |
|---|---|---|
| `β_0·Δd_MO,{t-1}` (lagged IAD growth) | `b2_m · iad` (contemporaneous IAD growth) | ⚠ timing |
| `(1-β_0)·Δȳ` (LR growth term) | absent | ⚠ AU drops |
| `β_1·[m_O - m*_O]_{t-1}` (error correction) | `b0_m · m_gap(-1)` | ✓ |
| (none) | `b1_m · dln_m(-1)` (own lag) | ⚠ AU adds |
| (none) | `b3_m · s_gap` (impact RER) | ⚠ AU adds |

✓ ECM form structurally matches FR-BDF eq 75.

✓ Phase D v3 SUCCESS: per STATUS.md, *"b1_m = 0.232 (t=2.71), b2_m = 0.359
(t=3.56) — both significant once IAD demand index is used"*. Imports DO have
empirically identified short-run dynamics from AU data, unlike exports.

### Calibration comparison (Table 4.6.21)

| Param | FR-BDF | AUSPAC | Notes |
|---|---|---|---|
| LR β_0 (constant) | 2.79 | absent | ✓ gap form |
| LR β_1 (price elasticity) | 1.11 | gamma_m = -0.40 | ⚠ different spec |
| LR β_2 (variety) | 0.39 | absent | ⚠ |
| LR income elasticity | unit | beta_m = 1.50 | ⚠ AU calibrates >1 (rising openness) |
| SR β_0 (demand) | 1.91 | b2_m = 0.36 | ⚠ AU much smaller |
| SR β_1 (error correction) | -0.19 | b0_m = 0.06 | ⚠ AU 3× slower |
| (extra) | - | b1_m = 0.23 (own lag) | AU adds |
| (extra) | - | b3_m = -0.08 (RER) | AU adds |

### ✗ Energy imports (FR-BDF eqs 76-77) — NOT IMPLEMENTED in AUSPAC

FR-BDF separately models energy imports (eqs 76-77). The split is required because
"of the heterogeneity in coefficients of adjustment (for price) and elasticity of
substitutions (for volumes)".

AUSPAC has **no separate energy-import equation**. STATUS.md confirms: *"Phase E
(energy split): documented as deferred in dynare/PHASE_E_ENERGY_SPLIT.md"*. AU
treats all imports as a single aggregate `dln_m` covering both energy and
non-energy.

This is a **known AU adaptation gap** flagged in §2.6 audit. Re-confirm here as
a structural divergence from FR-BDF design. Affects:
- Oil-price shock transmission (eps_pcom may not propagate correctly through
  imports without separate energy-import equation)
- Trade-balance dynamics under commodity-price shocks
- Phase E future work item

⚠ **Action item**: Phase E (energy/non-energy import split) remains
prioritised future work. Especially relevant for AU which is a major commodity
*exporter* but also imports refined energy products.

### §4.6.4 summary

- ✓ ECM form (not PAC) **confirmed structurally** — matches FR-BDF §2.4 design
- ✓ IAD weighting structure aligned (modulo missing I_G separation)
- ✓ Non-energy import block: empirically identified after Phase D v3 IAD-demand
  reformulation (b1_m and b2_m both significant in AU data)
- ⚠ **Export block uses substantially different long-run spec**: AU uses output
  gap + RER instead of FR-BDF's `d_W + (p_X − p_CX) + ω`
- ⚠ Export short-run dynamics not independently identified from AU data
  (b1_x, b2_x kept at FR-BDF values; needs Asian-PMI proxy)
- ⚠ Both AU sub-blocks add own-lag and impact-RER terms not in FR-BDF spec
- ✗ **Energy imports not implemented** — Phase E deferred (re-confirms §2.6 flag)

**Action items added**:
31. ⚠ Consider adding `ω_t` (emerging-countries weight) channel to export target
    `eq_ln_x_eq`. Would help capture AU-China commodity demand dynamics.
    Requires constructing an Asian/emerging-market demand share series.
32. ⚠ Document export equation identification gap: `b1_x = 0.30` and `b2_x = 0.25`
    are FR-BDF values, not AU posteriors. Phase D residual.
33. ✗ **Energy imports (eqs 76-77) deferred** — re-confirm Phase E priority.
    AU as major commodity exporter+importer makes the split substantively
    important for oil/commodity shock transmission.

---

## §4.7 Demand deflators — findings

FR-BDF specifies **8 deflators** (consumption, business inv, household inv, export,
non-energy import, energy import, total import (identity), government). AUSPAC
implements **6** (consumption, business inv, household inv, export, **combined
import**, government) — the energy/non-energy import split is deferred per Phase E.

### ✗ MAJOR systematic finding: AUSPAC deflators are NOT proper ECMs

**Every** FR-BDF deflator short-run equation has a level-form error correction term
`β·[p_j,{t-1} - p*_j,{t-1}]` (eqs 80, 82, 84, 86, 89, 91). AUSPAC's deflator
equations have **none of these EC terms**.

AUSPAC's universal pattern (with j ∈ {c, ib, ih, x, m, g}):
```
pi_j = rho_j · pi_j(-1) + alpha_j · piQ + (other channels)
     + (1 - rho_j - alpha_j - betas) · pibar_au + eps_j
```

This is a **simple inflation rule** that ensures GROWTH-rate convergence to LR
inflation `pibar_au` at SS, but does **NOT** anchor the price LEVEL ratio to VA
price. FR-BDF's ECM design enforces both growth-rate AND level-ratio convergence.

⚠ **Implications**:
- Deflator price levels could drift relative to VA price over long horizons
- Consistent with the §4.4 finding (`(1-β_1-ω)·π̄*_Q` term missing) and the
  recurring growth-neutrality concerns
- Likely related to the `pv_X_aux` puzzle (§3 #11, §4.4 #18) — substituting
  for missing FR-BDF level-correction terms?

⚠ **Action item**: investigate whether `pv_X_aux` plays the role of FR-BDF's
EC terms in the deflator equations OR whether the "no-ECM" form is intentional
AU adaptation. If unintentional, this affects all 6 deflators.

### Per-equation comparison

#### §4.7.1 Consumption deflator (FR-BDF eqs 79-80)

FR-BDF eq 80 (short-run, ECM):
```
π_C,t = (1-β_0-β_1)·π̄_Q,t + β_0·π_Q,t + β_1·π_Q,{t-1}
      + β_2·Δ(P_MNRJ,t/P̄_t)                          ← non-linear oil price (normalised)
      + β_3·[p_C,{t-1} - p*_C,{t-1}]                   ← error correction
      + ε_t
```

AUSPAC `eq_pi_c` ([au_pac.mod:1685](dynare/au_pac.mod#L1685)):
```
pi_c = rho_pc · pi_c(-1)                              ← own lag (FR-BDF uses lagged π_Q)
     + alpha_pc · piQ                                  ← contemporaneous VA price
     + beta_pc_m · pi_m                                ← import price (Stage 12)
     + gamma_oil · dln_pcom                            ← commodity price (Stage 12)
     + (1 - rho_pc - alpha_pc - beta_pc_m) · pibar_au
     + eps_pc
```

| FR-BDF eq 80 | AUSPAC | Verdict |
|---|---|---|
| `(1-β_0-β_1)·π̄_Q,t` | ✓ same form | ✓ |
| `β_0·π_Q,t` (current VA price growth) | `alpha_pc · piQ` | ✓ |
| `β_1·π_Q,{t-1}` (LAGGED VA price growth) | `rho_pc · pi_c(-1)` (LAGGED OWN inflation) | ⚠ different lag variable |
| `β_2·Δ(P_MNRJ/P̄)` (oil price NORMALIZED) | `gamma_oil · dln_pcom` (commodity growth) | ⚠ different normalisation |
| `β_3·[p_C - p*_C]_{t-1}` (EC) | **MISSING** | ✗ |
| (no general import in FR-BDF eq 80) | `beta_pc_m · pi_m` | ⚠ AU adds (overlaps with oil channel) |

⚠ **Calibration**: AU `alpha_pc = 0.17` vs FR-BDF SR β_0 = 0.63 — **AU 4× weaker
contemporaneous VA price pass-through**. Per code comment: *"weaker than FR-BDF 0.71"*.

#### §4.7.2 Business investment deflator (FR-BDF eqs 81-82)

FR-BDF eq 82 (short-run, ECM):
```
π_IB,t = (1-β_0-β_1)·π̄_Q,t + β_0·π_M,t                ← import price ONLY (no VA price growth!)
       + β_1·π_IB,{t-1}                                ← own lag
       + β_2·[p_IB,{t-1} - p*_IB,{t-1}]                 ← EC
       + ε_t
```

AUSPAC `eq_pi_ib` ([au_pac.mod:1696](dynare/au_pac.mod#L1696)):
```
pi_ib = rho_pib · pi_ib(-1) + alpha_pib · piQ + beta_pib_m · pi_m
      + (1 - rho_pib - alpha_pib - beta_pib_m) · pibar_au + eps_pib
```

| FR-BDF | AUSPAC | Verdict |
|---|---|---|
| `(1-β_0-β_1)·π̄_Q` | ✓ |
| `β_0·π_M` (import) | `beta_pib_m · pi_m` | ✓ |
| `β_1·π_IB,{t-1}` (own lag) | `rho_pib · pi_ib(-1)` | ✓ |
| `β_2·[p_IB - p*_IB]_{t-1}` (EC) | **MISSING** | ✗ |
| (no VA price growth in FR-BDF) | `alpha_pib · piQ` | ⚠ AU adds |

#### §4.7.3 Household investment deflator (FR-BDF eqs 83-84)

FR-BDF eq 84 has trend dummies `T_08q3`, `δ_99Q4`, `δ_08Q4` for French data
idiosyncrasies + EC term. AUSPAC drops the dummies (no AU equivalent) and the
EC term, adds own lag and import price channels.

#### §4.7.4 Export deflator (FR-BDF eqs 85-86)

FR-BDF eq 85 (target):
```
p*_X,t = (1-β_2)·[(1-β_0)·p_Q + (β_0-β_1)·p_MNRJ + β_1·p_MO]
       + β_2·p_CX,t                                    ← FOREIGN COMPETITORS' EXPORT PRICE
```

FR-BDF eq 86 (short-run, ECM):
```
π_X,t = (1-β_0-β_1)·π̄_Q + β_0·π_Q + β_1·π_M + β_2·[p_X - p*_X]_{t-1} + ε_t
```

AUSPAC `eq_pi_x` ([au_pac.mod:1716](dynare/au_pac.mod#L1716)):
```
pi_x = rho_px · pi_x(-1) + alpha_px · piQ + (1 - rho_px - alpha_px) · pibar_au
     + beta_px · s_gap                                  ← AU adds RER pass-through
     + alpha_pcom · dln_pcom                            ← AU adds commodity (Stage 11b)
     + eps_px
```

| FR-BDF eq 86 | AUSPAC | Verdict |
|---|---|---|
| `(1-β_0-β_1)·π̄_Q` | `(1-rho_px-alpha_px)·pibar_au` | ✓ |
| `β_0·π_Q` | `alpha_px · piQ` | ✓ |
| `β_1·π_M` (import growth) | absent | ⚠ AU drops |
| `β_2·[p_X - p*_X]_{t-1}` (EC) | **MISSING** | ✗ |
| (none — but eq 85 has β_2·p_CX in target) | `beta_px · s_gap` | ⚠ AU substitutes RER for foreign-competitor-price channel |
| (none) | `alpha_pcom · dln_pcom` | ⚠ AU adds (mining) |

⚠ AU **drops the foreign-competitors-export-price (`p_CX`) channel** entirely
from the export deflator. FR-BDF eq 85 includes `β_2·p_CX` with `β_2 = 0.27`
(substantial weight). AU's `beta_px · s_gap` partially substitutes this via
the RER channel, but it's not equivalent. Consequence: AU export deflator
doesn't respond to international price movements except via the AUD itself.

⚠ **Calibration**: `alpha_px = 0.20` per [au_pac.mod:782](dynare/au_pac.mod#L782) note: *"kept: AU est
2.23 implausible (multicollinearity)"*. Not identified from AU data.

#### §4.7.5 Import deflators — split NOT implemented

FR-BDF has **two separate deflator equations** (non-energy: eqs 88-89, energy:
eqs 90-91) plus accounting identity (eq 87). AUSPAC has a SINGLE combined
`eq_pi_m` ([au_pac.mod:1729](dynare/au_pac.mod#L1729)):
```
pi_m = rho_pm · pi_m(-1) + alpha_pm · piQ + (1 - rho_pm - alpha_pm) · pibar_au
     + beta_pm · s_gap                                  ← exchange rate pass-through
     + beta_pm_com · dln_pcom                           ← commodity (energy proxy)
     + eps_pm
```

Comment ([au_pac.mod:1727](dynare/au_pac.mod#L1727)): *"Captures energy import price channel without
separate energy import block. Paper has separate energy (eq. 91) and non-energy
(eq. 89) import deflators."*

⚠ Same Phase E deferred issue. Re-confirms §4.6.4 #33 action item.

⚠ **Calibration**: `alpha_pm = 0.38` per [au_pac.mod:788](dynare/au_pac.mod#L788) note: *"AU est 0.384
(s.e.0.199), stronger than FR-BDF 0.15"*. AU import prices are MORE responsive
to VA price than France's — possibly because AU's import structure (more capital
+ consumer goods, fewer intermediates).

#### §4.7.6 Government deflator (FR-BDF eq 92)

FR-BDF eq 92:
```
π_G,t = 0.54·(π_W,{t-1} - Δē_{t-1}) + (1-0.54)·π̄_{t-1} + ε_t
```

All RHS terms are LAGGED (no contemporaneous variables).

AUSPAC `eq_pi_g` ([au_pac.mod:1769](dynare/au_pac.mod#L1769)):
```
pi_g = rho_pg · pi_g(-1)
     + alpha_pg · (pi_w - dln_prod)                     ← CONTEMPORANEOUS efficient wage
     + (1 - rho_pg - alpha_pg) · pibar_au               ← CONTEMPORANEOUS anchor
     + eps_pg
```

| FR-BDF eq 92 | AUSPAC | Verdict |
|---|---|---|
| `0.54·(π_W,{t-1} - Δē_{t-1})` (LAGGED) | `alpha_pg · (pi_w - dln_prod)` (CONTEMPORANEOUS) | ⚠ timing |
| `(1-0.54)·π̄_{t-1}` (LAGGED) | `(1-rho_pg-alpha_pg)·pibar_au` (CONTEMPORANEOUS) | ⚠ timing |
| (none) | `rho_pg · pi_g(-1)` (own lag) | ⚠ AU adds |
| ε_t | eps_pg | ✓ |

⚠ **Calibration**: AU `alpha_pg = 0.37` vs FR-BDF 0.54. Per code comment:
*"AU est 0.37 (s.e.0.02). Slightly stronger wage pass-through."* — AU has
SMALLER wage share (0.37 < 0.54). FR-BDF's 0.54 is calibrated to
"share of public sector wages in government spending in 2014Q4". AU's 0.37
is estimated.

### Calibration summary table

| Deflator | FR-BDF SR β_0 (VA price) | AUSPAC `alpha_*` | Verdict |
|---|---|---|---|
| Consumption (π_C) | 0.63 | alpha_pc = 0.17 | ⚠ AU 4× weaker |
| Business inv (π_IB) | 0.11 (import only, no VA) | alpha_pib = 0.19 + beta_pib_m | ⚠ different decomposition |
| Household inv (π_IH) | 0.9 | alpha_pih = 0.40 | ⚠ AU 2× weaker |
| Export (π_X) | 0.89 | alpha_px = 0.20 | ⚠ AU 4× weaker (not identified) |
| Import (π_M) | 0.21 (NRJ) / 0.36 (non-NRJ) | alpha_pm = 0.38 | ⚠ similar to non-energy FR-BDF |
| Government (π_G) | 0.54 (wage) | alpha_pg = 0.37 (wage) | ⚠ AU smaller wage share |

| Deflator | FR-BDF SR β_1 (own/lagged) | AUSPAC `rho_*` | Verdict |
|---|---|---|---|
| Consumption | 0.16 (lagged π_Q) | rho_pc = 0.67 (own lag) | ⚠ much higher own-persistence |
| Business inv | 0.42 (own) | rho_pib = 0.70 | ⚠ higher |
| Household inv | (no own lag) | rho_pih = 0.49 | ⚠ AU adds own lag |
| Export | 0.48 (lagged import π) | rho_px = 0.21 (own lag) | ⚠ different |
| Import | 0.36 (own, non-NRJ) | rho_pm = 0.28 | ✓ similar |
| Government | (no own lag, lagged anchor) | rho_pg = 0.13 | ⚠ AU adds own lag |

### §4.7 summary

**Key findings**:

- ✗ **SYSTEMATIC: All 6 AU deflator equations LACK the level-form ECM term**
  `β·[p_j - p*_j]_{t-1}` that FR-BDF eqs 80, 82, 84, 86, 89, 91 all have.
  AUSPAC uses a "simple inflation rule" form (own lag + growth components +
  LR anchor pull). Ensures growth-rate convergence but not level-ratio anchor.
  May explain `pv_X_aux` necessity.
- ✗ **Energy/non-energy import split** (FR-BDF eqs 87-91) **not implemented** —
  AU has single combined `eq_pi_m`. Phase E deferred. (re-confirms §4.6.4 #33)
- ⚠ **AU adds own-lag persistence** (`rho_*`) to several deflators where FR-BDF
  uses lagged VA price or no lag (consumption, household inv, government)
- ⚠ **VA price pass-through coefficients are systematically smaller in AU**
  (consumption 4× weaker, exports 4× weaker, household inv 2× weaker)
- ⚠ **Export deflator drops foreign-competitor-price channel** (FR-BDF's
  β_2·p_CX = 0.27 weight). AU substitutes with RER but loses direct
  international-price-competition channel.
- ⚠ Several AU deflators add channels not in FR-BDF: commodity prices (Stage
  11b for export + import + consumption), exchange rate (export, import),
  general import price (consumption, business inv, household inv)
- ⚠ Government deflator: AU uses CONTEMPORANEOUS wage and anchor (FR-BDF uses
  LAGGED). AU adds own lag.

**Action items added**:
34. ✗ **Investigate missing ECM terms across all 6 deflators**: do AU deflator
    equations need the FR-BDF `β·[p_j - p*_j]_{t-1}` level-correction terms?
    Affects long-run price-level dynamics. Linked to `pv_X_aux` puzzle (#18, #27).
    If yes — major refactor across 6 equations + 5 target equations to compute.
35. ⚠ Consider adding foreign-competitor-export-price `p_CX` channel to
    `eq_pi_x` to capture international price competition. Currently AU only
    has RER channel via `beta_px · s_gap`.
36. ⚠ Government deflator timing: should AU `eq_pi_g` use LAGGED `pi_w(-1)` and
    `pibar_au(-1)` per FR-BDF eq 92, or is contemporaneous form intentional?
37. ✗ Energy/non-energy import deflator split (FR-BDF eqs 88-91) — re-confirm
    Phase E priority (already #33).

---

## §4.8 Financial block — findings

### §4.8.1 Short-term interest rate (FR-BDF eq 93)

Already audited in §3.1 — eq 93 is the E-SAT Taylor rule. AUSPAC's `eq_taylor`
correctly adapts to AU domestic vars (RBA Taylor rule). ✓ aligned.

LR rate anchor `ī_t` (FR-BDF eq 94): AR(1) calibrated. AUSPAC `eq_ibar` with
`lambda_ibar = 0.985` (matches E-SAT calibration in §3.1). ✓ aligned.

### §4.8.2 Long-term government rate (FR-BDF eqs 95-97) — well aligned

FR-BDF eq 95: `i_10,t = PV(i)|_{t-1} + s_10,t`
FR-BDF eq 97 (theoretical): `i_10,t = (1-κ_10)·Σ κ^s_10·i_{t+s} + s_10,t`
FR-BDF eq 132 (recursive): `PV(i)_t = (1-κ_10)·i_t + κ_10·PV(i)_{t+1}`

AUSPAC ([au_pac.mod:1541-1546](dynare/au_pac.mod#L1541)):
```
[eq_pv_i]  pv_i = (1 - kappa_10) · i_au + kappa_10 · pv_i(+1);     ← exact eq 132
[eq_i_10y] i_10y = pv_i + tp + eps_10y;                              ← exact eq 95
```

| Item | FR-BDF | AUSPAC | Verdict |
|---|---|---|---|
| `i_10 = PV(i) + s_10` | eq 95 | `i_10y = pv_i + tp + eps_10y` | ✓ EXACT match (plus AU residual) |
| Recursive PV form `PV(i)_t = (1-κ)·i_t + κ·PV(i)_{t+1}` | eq 132 | identical | ✓ EXACT match |
| `κ_10` decay parameter | 0.97 implied (≈ 10Y duration) | `kappa_10 = 0.97` | ✓ EXACT match |
| Term spread AR(1): `s_10,t = (1-ρ_10)·s̄_10 + ρ_10·s_10,{t-1}` | eq 96 | `tp = ρ_tp · tp(-1) + (1-ρ_tp)·tp_ss + eps_tp` | ✓ same form |
| ρ_10 (term spread persistence) | 0.80 | `rho_tp` (need to verify value) | ⚠ verify |

✓ **Best-aligned single equation in the financial block** — both functional form
and calibration parameter match FR-BDF exactly.

### §4.8.3 WACC + private interest rates (FR-BDF eqs 98-100) — EXACT calibration import

FR-BDF eq 98: `wacc_t = 0.5·i_COE,t + 0.3·i_LB,t + 0.2·i_BBB,t`

AUSPAC `eq_wacc` ([au_pac.mod:1576](dynare/au_pac.mod#L1576)):
```
wacc = w_COE · i_COE + w_LB_firms · i_LB_firms + w_BBB · i_BBB
```

With weights:
- `w_COE = 0.50` ✓ EXACT FR-BDF
- `w_LB_firms = 0.30` ✓ EXACT FR-BDF
- `w_BBB = 0.20` ✓ EXACT FR-BDF

Component rates (FR-BDF eq 99): `i_j = s_j + i_10`
AUSPAC: `i_COE = i_10y + s_COE`, etc. ✓ same form.

Spreads (FR-BDF eq 100): `s_j,t = s̄_j(1-ρ_j) + ρ_j·s_{j,t-1}`
AUSPAC: identical form ✓

Spread persistence (FR-BDF Table 4.8.4):
- ρ_COE = 0.92 → AUSPAC `rho_COE = 0.92` ✓ EXACT
- ρ_LB = 0.77 → AUSPAC `rho_LB_firms = 0.77` ✓ EXACT
- ρ_BBB = 0.94 → AUSPAC `rho_BBB = 0.94` ✓ EXACT

⚠ **Notable**: WACC weights and spread persistences directly imported from FR-BDF
without independent AU estimation. Per code comment ([au_pac.mod:718-723](dynare/au_pac.mod#L718)):
*"paper: 0.5"*, *"paper: 0.92"* etc. Defensible — these are funding-mix shares
that don't depend strongly on country, and AU corporate funding is
broadly similar to French. But should be flagged as imported-not-estimated.

### §4.8.4 Exchange rates (FR-BDF eqs 101-106)

FR-BDF UIP framework (eqs 101-104):
```
ξ_$ + p_EA - p_F = β + [PV_nd(i)|_{t-1} - PV_nd(i_F)|_{t-1}]
                   - [PV_nd(π_EA)|_{t+1|t-1} - PV_nd(π_F)|_{t+1|t-1}] + η_t
(1-ρL)·η_t = ε_t
```

ρ_$,EA estimates: ρ = 0.95 (Table 4.8.6, both EUR/USD and Euro effective).

AUSPAC ([au_pac.mod:1594-1601](dynare/au_pac.mod#L1594)) — **Phase Q forward UIP, refreshed 2026-05-15**:
```
[eq_pv_i_uip] pv_i_uip = (i_au - ibar) + beta_uip · pv_i_uip(+1);
[eq_s_gap]    s_gap = rho_s · s_gap(-1)
                    - alpha_s · pv_i_uip
                    + alpha_s · (pi_au_gap - pi_us_gap)
                    + eps_s;
```

| Item | FR-BDF eq 105 | AUSPAC | Verdict |
|---|---|---|---|
| Real exchange rate gap (LHS) | `ξ_$ + p_EA - p_F` (full real RER) | `s_gap` (real exchange rate gap) | ✓ same concept |
| AR(1) persistence on residual | `ρ = 0.95` | `rho_s = 0.775` (AU posterior) | ⚠ AU much less persistent (per AU data) |
| Domestic-foreign rate PV: `PV(i) - PV(i_F)` | both PVs of rate gaps | `pv_i_uip = NPV of (i_au - ibar)` only — **no foreign rate** | ⚠ AU uses domestic rate gap only, not differential |
| Inflation PV differential `PV(π_EA) - PV(π_F)` | both PVs | `(pi_au_gap - pi_us_gap)` (CONTEMPORANEOUS gaps, not PV) | ⚠ AU uses contemporaneous, not PV |
| ε_t | η_t with AR(1) | eps_s | ✓ |

⚠ **Three structural differences vs FR-BDF eq 105**:
1. **No foreign short rate `i_F`** — AUSPAC's `pv_i_uip` is the NPV of the AU
   rate gap relative to its own LR anchor, not a true rate differential. This
   is consistent with the §3.1 #8 finding (no `i_us` in our model).
2. **Contemporaneous inflation gaps** instead of PV of inflation differential
3. **`pv_i_uip` uses standard NPV** (coefficient 1 on i_gap, not (1-β)) — already
   flagged in §3.2-3.3 #13. Comment confirms this is deliberate per Phase Q:
   *"the impact response is amplified by 1/(1-β_uip·λ_i) ≈ 4.55× at β=0.92"*

⚠ **Calibration**: ρ_s = 0.775 (AU est, AU-data half-life ~3q) vs FR-BDF's 0.95
(half-life ~14q). AUD has much faster mean-reversion to PPP than EUR. Real AU
finding.

### Foreign short rate (FR-BDF eq 107) — NOT in AUSPAC

FR-BDF eq 107: `i_F,t = ρ·i_F,{t-1} + (1-ρ)·ī + ε_t` — Fed AR(1).

AUSPAC has no `i_us` (foreign short rate) variable at all. This connects to:
- §3.1 #8: missing real-rate channel in `eq_us_is`
- §4.8.4 above: UIP missing foreign rate term

Same root cause: AU treats US as fully exogenous (no Fed Taylor rule, no Fed
short rate). Reasonable small-open-economy simplification but represents a real
divergence from FR-BDF foreign-block design.

### §4.8.5 Net property income and net asset positions (eqs 116-126) — strongly aligned

FR-BDF stabilization rules for transfers (eqs 123-125) and rate of return (eq 126).

| Item | FR-BDF | AUSPAC | Verdict |
|---|---|---|---|
| Transfer policy form: `τ = (1-ρ_stab,1)·τ(-1) + ρ_stab,1·τ* - ρ_stab,2·(...)` | eqs 123-125 | [au_pac.mod:1880+](dynare/au_pac.mod#L1880) similar form | ✓ |
| `ρ_stab,1` (transfer adjustment speed) | 0.10 | `rho_stab_1 = 0.10` | ✓ EXACT |
| `ρ_stab,2` (debt-stabilizing reaction) | 0.10 | `rho_stab_2 = 0.25` | ⚠ AU 2.5× stronger — per code comment "stronger for BK" (Blanchard-Kahn determinacy) |
| `W_F/Y` (firms net asset ratio) | -0.7 × 4 = -2.80 | `w_F_ss = -0.70 * 4` | ✓ EXACT |
| `W_G/Y` (gov net asset ratio) | -0.4 × 4 = -1.60 | `w_G_ss = -0.40 * 4` | ✓ EXACT |
| `τ*_TF` (LR firms transfer target) | 0.026 | `tau_F_ss = ?` (need verify) | ⚠ verify |
| `γ` (firms revaluation) | -0.018 | `gamma_reval = -0.018` | ✓ EXACT |
| Asset returns: `i_j = ρ_j,0(1-ρ_j,1) + (1-ρ_j,1)·i_10 + ρ_j,1·i_j(-1)` | eq 126 | (deferred to §4.10 audit) | ⚠ verify |
| `ρ_j,1 = 0.983` (40-quarter half-life calibration) | yes | ? | ⚠ verify |

⚠ AU calibrates **`rho_stab_2 = 0.25`** (vs FR-BDF 0.10) — explicit comment notes
this is **strengthened to satisfy Blanchard-Kahn determinacy**. This is a
legitimate AU adaptation but worth noting: the FR-BDF calibration (0.10) gives
weaker debt-stabilization, which AUSPAC found to be insufficient for BK rank
in the AU model. Could indicate AU-specific weak determinacy properties or
identification issues.

⚠ Phase N validation (per STATUS.md): *"4 sectoral wealth-to-GDP ratios converge
with 2-3 quarter half-lives under 20% off-SS perturbation — model passes the
FR-BDF Section 4.8.5 validation"*. ✓ AU sector accounts validated.

### Bank lending rate for households (FR-BDF eq 62, in §4.6.1)

FR-BDF eq 62 (deferred from §4.6.1 audit):
```
r_LH,t = β_0·r_LH,{t-1} + (1-β_0)·(ī_{t-1} - π̄_{t-1} + s̄_LH)
       + β_1·(i_{t-1} - ī_{t-1}) + β_2·(π̄_{t-1} - π_{t-1})
```
β_0 = 0.88, β_1 = 0.12, β_2 = -0.06; s̄_LH = 1.12% annualized.

AUSPAC `eq_i_lh` ([au_pac.mod:1818](dynare/au_pac.mod#L1818)):
```
i_lh = rho_lh · i_lh(-1) + (1 - rho_lh) · (i_10y + spread_lh) + eps_lh
```

| FR-BDF eq 62 | AUSPAC `eq_i_lh` | Verdict |
|---|---|---|
| Anchor `(ī - π̄ + s̄_LH)` (LR real rate + spread) | `(i_10y + spread_lh)` (10Y nominal rate + spread) | ⚠ different anchor — AU uses 10Y bond rate not LR real short rate |
| `β_0` (lag persistence) | `rho_lh = 0.97` | ⚠ AU MUCH higher (0.97 vs 0.88 — slower pass-through) |
| `β_1·(i - ī)` (rate gap) | absent — only via `(1-rho_lh)·i_10y` | ⚠ AU drops separate rate-gap channel |
| `β_2·(π̄ - π)` (inflation gap counter) | absent | ⚠ AU drops |
| ε_t | eps_lh | ✓ |

⚠ AUSPAC simplified the bank lending rate equation substantially. Uses a partial
adjustment toward 10Y rate + spread, not the more complex FR-BDF eq 62 form
with separate short-rate-gap and inflation-gap terms.

### §4.8 summary

**Verdict on financial block**:

- ✓ **Term structure (eq 95-97)**: EXACT match — both functional form and
  `kappa_10 = 0.97` calibration imported
- ✓ **WACC (eqs 98-100)**: EXACT match on weights (0.5/0.3/0.2) and spread
  persistences (0.92/0.77/0.94). Best-calibrated block in audit.
- ✓ **Sector financial accounts (eqs 116-126)**: target ratios EXACT match,
  most params EXACT match (ρ_stab,1=0.10, γ=-0.018)
- ⚠ **Exchange rate (Phase Q forward UIP, eqs 105-106)**: structurally similar
  but AU drops foreign short rate, uses contemporaneous inflation gaps, uses
  standard NPV (not (1-β) normalised)
- ⚠ **No foreign short rate `i_F`** — affects UIP and US IS (links to §3.1 #8)
- ⚠ **Bank lending rate (eq 62)**: AU simplified substantially (drops separate
  rate-gap and inflation-gap channels, uses 10Y rate as anchor not LR real rate)
- ⚠ **`rho_stab_2 = 0.25`** vs FR-BDF 0.10 — strengthened for BK determinacy

**Action items added**:
38. ⚠ Verify `rho_tp` value: should match FR-BDF ρ_10 = 0.80 per Table 4.8.2.
39. ⚠ Document FR-BDF calibration imports: WACC weights and spread persistences
    are imported from FR-BDF (not AU-estimated). Defensible but worth flagging.
40. ⚠ Investigate `rho_stab_2 = 0.25` necessity: why does AU need 2.5× stronger
    debt-stabilizing reaction for BK determinacy? May indicate weak determinacy
    properties in AU model.
41. ⚠ Consider augmenting `eq_i_lh` with separate short-rate-gap (β_1·(i-ī))
    and inflation-gap (β_2·(π̄-π)) channels per FR-BDF eq 62. Currently AU has
    only partial-adjustment to (i_10y + spread).
42. ⚠ Foreign rate `i_us` absence (linked to #8): would enable both proper
    UIP foreign-rate term in eq 105 AND US IS real-rate channel.

---

## §4.9 Trends — findings

### FR-BDF approach: HP-filter exponential smoothers in data prep

FR-BDF uses **trend variables** `x̄_t` for two purposes (p. 96):
1. PAC framework: decompose target expectations into PV(Δx̄*) (trend growth)
   and PV(Δx̂*) (gap change)
2. LR output evaluation: trends of labor force, hours per employee, non-market
   GDP

**Two smoother forms**:

FR-BDF eq 127 (single exponential smoother):
```
x̄_t = ρ_HT·(x̄_{t-1} + g_x) + (1-ρ_HT)·x_t + ε_t
```

FR-BDF eq 128 (with AR(1) residuals, for highly persistent residuals):
```
x̄_t = ρ_HT·(x̄_{t-1} + g_x) + (1-ρ_HT)·x_t + η_t
η_t = ρ_TVP·η_{t-1} + ε_t
```

**Calibration**: ρ_HT = 0.95 (90% convergence within 40 quarters), ρ_TVP = 0.83
(10% residual after 12 quarters).

### Key FR-BDF design decision (p. 97)

> "From what precedes, we conclude that trends should be exogenous when feasible.
> Thus, we choose to anchor the exponential smoother not to the actual variable
> that we wish to smooth, but rather to the long run equilibrium of the variable."

**Example (eq 129) — employment trend**:
```
ñ*_{S,t} = log((1-u_N,t)·ν̄·ψ̄_t·POP̄_t)
```
Where ALL components are exogenous trends:
- `u_N,t` = LR equilibrium unemployment rate (exogenous)
- `ν̄` = avg ratio of salaried to total employment
- `ψ̄_t` = trend share of market-branch employment
- `POP̄_t` = labor-force trend

**Example (eq 130) — capital marginal-return trend**:
```
̄Q'_K,t ≡ μ·(̄r_K,t/P_Q,t)
```
Anchored to steady-state of capital demand condition.

### Four trends with "particular status" (deterministic, not smoothers)

p. 97: *"Four trend variables have a particular status and depart from the
modelling framework that we have presented here:"*
1. `ī_t` — LR trend short rate
2. `π̄_t` — LR trend VA price inflation
3. `π̄_EA,t` — LR EA inflation
4. `Ē_t` — trend labor efficiency (deterministic, per §4.3)

These are exogenous in the strict sense (don't depend on actual variable at all).

### AUSPAC approach: structural gap-form model, no in-model HP smoothers

AUSPAC takes a **methodologically different approach**: HP filters are applied
at the **data preparation stage** (`data/scripts/`), and the Dynare model uses
**gap-form variables** where the trend has already been removed.

The "trends" that appear in the AUSPAC `.mod` are:

**Long-run anchors (FR-BDF "particular status" trends)**:
| FR-BDF | AUSPAC | Verdict |
|---|---|---|
| `ī_t` (LR short rate trend) | `ibar` AR(1) toward `i_ss` ([au_pac.mod:1023](dynare/au_pac.mod#L1023)) | ✓ similar |
| `π̄_t` (LR domestic inflation) | `pibar_au` AR(1) toward `pi_ss_au` ([au_pac.mod:1026](dynare/au_pac.mod#L1026)) | ✓ similar |
| `π̄_EA,t` (LR foreign inflation) | `pibar_us` AR(1) toward `pi_ss_us` | ✓ similar |
| `Ē_t` (trend labor efficiency) | `ln_tfp_LR` RW with permanent shocks (post-Phase Q fix) | ⚠ different spec, similar behavior — see §4.3 audit |

**Trend GROWTH RATES (instead of trend levels)**:
| Variable | AUSPAC equation | FR-BDF equivalent |
|---|---|---|
| `dln_y_star` | `α·dln_k + (1-α)·dln_n_star_bar + dln_tfp` | derived from production function trends |
| `dln_c_star_bar` | `κ_inc·d(pv_yh) + α_c_r·d(real rate gap)` | growth of consumption permanent income |
| `dln_ib_star_bar` | `κ·yhat_au - σ·dln_uc_k` | derived from investment FOC |
| `dln_ih_star_bar` | `κ·d(pv_yh) - κ·(rate gap) + κ·ph_gap` | derived from housing demand |
| `dln_n_star_bar` | `dln_tfp/(1-α_k) - σ·rw_gap` | derived from labor FOC |

**Trend LEVEL accumulators (cumulative integrals)**:
- `ln_QN`, `ln_C_star`, `ln_IB_star`, `ln_IH_star`, `ln_N_star`, `ln_K`, `ln_P_star`
- Pure accounting identities accumulating trend growth rates per FR-BDF eq 43

### ⚠ Major design difference: endogenous vs exogenous trends

AUSPAC's `dln_n_star_bar = dln_tfp/(1-α_k) - σ_ces·rw_gap` is **fully endogenous** —
depends on TFP shock + real wage gap (model variables).

FR-BDF eq 129 `ñ*_{S,t} = log((1-u_N)·ν̄·ψ̄·POP̄)` is **fully exogenous** —
all four components are external trends from data.

These are substantively different design choices:
- **FR-BDF**: trend = pre-defined external benchmark; gap = deviation from this benchmark
- **AUSPAC**: trend = model-derived equilibrium; gap = deviation from current model SS

⚠ **Implications**:
- FR-BDF's exogenous trends can't be moved by model dynamics — pure benchmarks
- AUSPAC's endogenous trends move with structural shocks (e.g., TFP shock raises
  the *trend* employment, not just the gap)
- FR-BDF's approach prevents the "loop between endogenous variables and their
  trends" warned about in p. 97
- AUSPAC's approach can produce trend amplification effects FR-BDF avoids

This is a known FR-BDF design preference (*"trends should be exogenous when
feasible"*) that AUSPAC has not followed for `dln_n_star_bar`, `dln_ib_star_bar`,
`dln_c_star_bar`, `dln_ih_star_bar`. These are all derived endogenously from
structural relationships rather than anchored to exogenous demographic/sectoral
data series.

### ⚠ AU lacks demographic / structural-employment trend variables

Specifically MISSING from AUSPAC vs FR-BDF eq 129:
- `u_N,t` (LR equilibrium unemployment) — AUSPAC has only `u_ss_au` as a constant
- `ν̄` (salaried/total employment ratio) — absent
- `ψ̄_t` (market-branch employment share trend) — absent
- `POP̄_t` (labor force trend) — absent

These would let AU's employment trend respond to structural demographic shifts
(aging population, participation trends, etc.) independently of TFP and real-wage
dynamics. Currently AUSPAC's model assumes all these structural trends are
constant (effectively folded into the `α_k` and `(1-α_k)` weights).

⚠ **Action item**: consider augmenting `dln_n_star_bar` to incorporate exogenous
demographic and labor-market structural trends, particularly `POP̄_t` (ABS 6202
working-age population trend). Currently AU labor demand trend is over-driven
by TFP shocks.

### ⚠ Persistence calibrations differ

FR-BDF: ρ_HT = 0.95 (HP smoother persistence — data-prep level).
AUSPAC E-SAT: λ_ī = 0.985, λ_π̄ = 0.93, λ_π̄_us = 0.93 (in-model AR(1) anchor
persistence).

These are different concepts (HP-filter smoother vs AR(1) anchor). Both achieve
similar slow mean-reversion behavior but at different points in the modeling
pipeline. ⚠ Worth noting for documentation but not a substantive misalignment.

### §4.9 summary

**Verdict on trends**:

- ✓ Long-run anchors (`ibar`, `pibar_au`, `pibar_us`) match FR-BDF's
  "deterministic trend" anchors with AR(1) form
- ✓ Trend labor efficiency `ln_tfp_LR` now FR-BDF-aligned post Phase Q fix
- ⚠ **AUSPAC uses endogenous structural trends** (dln_n_star_bar, dln_ib_star_bar,
  dln_c_star_bar, dln_ih_star_bar) — methodologically different from FR-BDF's
  preferred exogenous-trend approach (p. 97)
- ⚠ **AU lacks demographic / structural-employment trends** (`u_N,t`, `ν̄`, `ψ̄_t`,
  `POP̄_t`) — labor-demand trend may be over-driven by TFP shocks
- ⚠ HP-filter smoothers (FR-BDF eqs 127-128) applied at data-prep stage in AUSPAC,
  not in Dynare model — methodologically different but functionally similar

**Action items added**:
43. ⚠ Consider adding exogenous demographic trend variables (`POP̄_t` from ABS 6202)
    to enable separation of demographic from TFP-driven labor demand trends.
    Currently `dln_n_star_bar` doesn't respond to AU's known demographic
    transition (aging, participation changes).
44. ⚠ Document the "endogenous vs exogenous trends" methodological choice
    explicitly in the working paper. AUSPAC takes a different design path
    than FR-BDF p. 97 prefers; this should be acknowledged with reasoning.

---

## §4.10 Accounting framework + public finances — findings

### Two key FR-BDF decompositions

**1. Branch decomposition** (market vs non-market): production + labor market vars
   - Market = INSEE codes AZ to MN (industry, services excl. public)
   - Non-market = OQ (public administration, education, health)

**2. Sector decomposition** (5 economic agents):
   - Firms (NFC + FC grouped together)
   - Government
   - Households (incl. unincorporated enterprises)
   - NPISH (non-profit institutions serving households)
   - Rest of the world

### Government block special features (FR-BDF):
- Two modes: **forecasting** (variables exogenized from MAPU model) and
  **simulation** (endogenous via tax rates / ratios)
- Receipts: each = exogenous effective tax rate × endogenous tax basis
- Spending: some related to macro aggregates with effective rates (e.g.,
  unemployment benefits = unemployment × wage per capita)
- Other spending volumes: ratio to LR output assumed exogenous
- Fiscal rule: social transfers `T_G,t` (excl. unemployment + transfers in kind)
  endogenized via FR-BDF eq 125 to ensure gov net asset ratio convergence

### Government peculiarities (FR-BDF):
- Operational surplus = exogenous share of LR output (not VA net of compensations)
- Government VA = surplus + paid compensations + other taxes − subsidies
- Government final consumption = accounting construction (gov VA + intermediate
  consumption + paid social benefits in kind − sales of services)

### AUSPAC accounting framework

| Item | FR-BDF | AUSPAC | Verdict |
|---|---|---|---|
| **Branch decomposition** (market vs non-market) | yes | NOT IMPLEMENTED — aggregate VA only | ✗ |
| **Sector decomposition** | 5 (firms, gov, HH, NPISH, RoW) | 4 (firms, gov, HH, NPISH); RoW implicit via trade block + UIP | ⚠ |
| Sector financial accounts (eqs 116-122) | yes | yes ([au_pac.mod:1865-1930+](dynare/au_pac.mod#L1865)) — Phase N validated | ✓ |
| Government block detailed (forecasting/simulation modes) | yes (MAPU interaction) | simpler — single mode with `eq_dln_g` | ⚠ |
| Tax receipts via "exogenous tax rate × endogenous basis" | yes | NOT IMPLEMENTED — no separate tax-rate decomposition | ✗ |
| Fiscal rule for social transfers | FR-BDF eq 125 (asset-ratio feedback) | `eq_tau_G` simpler form (see below) | ⚠ |

### ✗ MAJOR: Branch decomposition (market/non-market) absent

AUSPAC has **no separate market vs non-market branch accounts**. FR-BDF uses
this decomposition to:
- Apply CES production technology only to market branches
- Define output gap relative to market branches' output
- Have separate non-market output (mostly public services) growing at LR rate

Without this decomposition:
- AU's `Q` (value added) implicitly mixes market + non-market branches
- AU's CES production function is applied to aggregate output (which is
  inappropriate — non-market output doesn't follow CES profit-maximization)
- AU's `dln_n` covers all employment, not just market-branch employment

⚠ This is a substantial spec divergence from FR-BDF. Implementing would
require ABS Cat. 5204 industry-level VA + employment data and adding
non-market branch variables (`Q^nm`, `N_OQ`) per FR-BDF eq 130 framework.

⚠ Defensible AU adaptation if the simplification doesn't materially affect
results (non-market branch is ~20% of GDP, slow-moving). But should be
documented as a known FR-BDF design departure.

### ✗ Tax receipts: no exogenous-rate × endogenous-basis structure

FR-BDF: each receipt = (exogenous effective tax rate) × (endogenous tax basis).
AUSPAC: no explicit tax block. Government revenue is implicit in the GDP
identity ([au_pac.mod:143-148](dynare/au_pac.mod#L143)) but no tax-rate variables.

⚠ Means AU can't simulate tax-rate changes (e.g., GST hike, income tax
reform) endogenously. Tax-policy analysis would require model extension.

### Sector financial accounts (FR-BDF eqs 116-126) — well aligned

FR-BDF eq 116-119: net property income per sector
- AUSPAC: `eq_yf_F`, `eq_yf_G`, `eq_yf_H`, `eq_yf_N` ([au_pac.mod:1869-1879](dynare/au_pac.mod#L1869))
- ✓ aligned (uses SS wealth `w_j_ss` instead of dynamic wealth — FR-BDF's
  W_{j,t-1} would be more accurate but creates feedback risk per code comment)

FR-BDF eq 120: `ΔW_j = B_j` (wealth accumulation)
- AUSPAC has wealth accumulation via b_j ratios ✓

FR-BDF eq 122: `v_F = γ·Y·P̄_Y` (firms revaluation, γ=-0.018)
- AUSPAC: `gamma_reval = -0.018` ✓ EXACT match

### ⚠ Transfer rules simpler than FR-BDF eqs 123-125

FR-BDF eq 123 (firms transfer):
```
τ_TF,t = (1-ρ_stab,1)·τ_TF,{t-1} + ρ_stab,1·τ*_TF
       - ρ_stab,2·[(-B_F + γȲP̄_Ȳ)/(YP_Y) + W_F/Y · (exp(g+π̄)-1)/exp(g+π̄)]
```
TWO components: AR(1) + structural debt-stabilization feedback.

AUSPAC `eq_tau_F` ([au_pac.mod:1888-1889](dynare/au_pac.mod#L1888)):
```
tau_F = (1 - rho_stab_1) * tau_F(-1) + rho_stab_1 * tau_F_ss
```

⚠ AU uses **only AR(1) component** — drops the FR-BDF debt-stabilization feedback
term. Per code comment ([au_pac.mod:1885-1886](dynare/au_pac.mod#L1885)):
*"Wealth stabilization happens endogenously through the consumption/income
channel, not transfers."*

Different design choice:
- FR-BDF: explicit fiscal-rule-style stabilization in `τ_TF` itself
- AUSPAC: relies on emergent macro stabilization (debt → wealth → consumption → output)

Both can produce stable wealth dynamics, but FR-BDF's approach has stronger
theoretical microfoundations. AU's approach is simpler but harder to interpret.

### ⚠ Government fiscal rule: countercyclical instead of asset-ratio-based

FR-BDF eq 125: government social transfers stabilize the gov net asset ratio.

AUSPAC `eq_tau_G` ([au_pac.mod:1897-1899](dynare/au_pac.mod#L1897)):
```
tau_G = (1 - rho_stab_1) * tau_G(-1) + rho_stab_1 * tau_G_ss
      + 0.05 * yhat_au
```

⚠ AU uses **countercyclical fiscal rule** (responds to output gap, coefficient
0.05) instead of FR-BDF's asset-ratio rule. This is a different fiscal-policy
specification — AU implicitly assumes RBA-style or progressive-taxation-style
automatic stabilizers, while FR-BDF assumes Eurozone-style asset-stabilization
mandate.

⚠ Defensible AU adaptation but represents a real divergence.

---

## §4.11 Conditional projections (BMPE) — findings

### FR-BDF approach for conditional forecasts

In BMPE exercises (Eurosystem Broad Macroeconomic Projection Exercises):
1. **Some exogenous variables** (world demand, competitors' prices) projected
   with Eurosystem assumptions
2. **Several endogenous variables exogenized**: term structure + UIP no longer
   determine LR rate / NEER / USD-EUR; oil prices and competitors' prices
   exogenized
3. **Three auxiliary models** integrated:
   - **BLR**: bank lending rates (with Eurosystem assumptions)
   - **MAPI**: HICP inflation forecasts
   - **MAPU**: public finances
4. **Labor force** from Insee, **LR equilibrium unemployment** from external
   assessment
5. **HICP via MAPI**: iterated with FR-BDF until convergence
6. **Public finances via MAPU**: iterated with FR-BDF until convergence
7. **Minimum wage equation modified** (FR-BDF eq 131): drops LR stability
   formula

Table 4.11.1 lists 14+ variables that change status (endogenous → exogenous)
in BMPE exercises.

### AUSPAC `au_pac_condforecast.mod`

AUSPAC has a separate `.mod` file for conditional forecasts ([dynare/au_pac_condforecast.mod](dynare/au_pac_condforecast.mod), 2096 lines vs au_pac.mod's 2306).

| Item | FR-BDF | AUSPAC | Verdict |
|---|---|---|---|
| Separate `.mod` for cond. forecasts | yes (modified equations) | yes (`au_pac_condforecast.mod`) | ✓ |
| Term structure + UIP exogenized | yes | check (need to verify) | ⚠ verify |
| Auxiliary BLR model | yes | NOT IMPLEMENTED | ✗ |
| Auxiliary MAPI inflation model | yes | NOT IMPLEMENTED | ✗ |
| Auxiliary MAPU public finances model | yes | NOT IMPLEMENTED | ✗ |
| External labor force / unemployment projections | yes (Insee) | unclear (need to check Phase H/N integration) | ⚠ |
| Minimum wage formula modification (eq 131) | yes | n/a (AU has no minimum wage equation) | ✓ |
| `conditional_forecast_paths` block in .mod | yes (Dynare native) | yes ([au_pac_condforecast.mod:2080+](dynare/au_pac_condforecast.mod#L2080), with stylized RBA tightening cycle) | ✓ |

### ✗ Three FR-BDF auxiliary models NOT in AUSPAC

FR-BDF integrates with three external models for BMPE:
- **BLR**: bank lending rates (Eurosystem-coordinated)
- **MAPI**: HICP forecasts (Banque de France-specific)
- **MAPU**: public finances (Banque de France-specific)

AUSPAC has **no equivalent auxiliary models**. For AU forecasting:
- Bank lending rates handled within `au_pac.mod` via `eq_i_lh` (already audited
  in §4.6.1, simplified form)
- AU has no separate HICP forecast model — `pi_c` is the model's own consumption
  inflation
- No public finances model — AU has simpler `eq_dln_g` government spending rule

⚠ This is a substantial design simplification but appropriate for AUSPAC's
scope (it's an academic replication, not a central bank forecasting platform).

### ⚠ Conditional forecast scenario stylized

Looking at [au_pac_condforecast.mod:2080+](dynare/au_pac_condforecast.mod#L2080):
```
conditional_forecast_paths;
var i_au;
periods 1:16;
values 0.0625, 0.1250, 0.1875, 0.2500, 0.2500, ..., 0.0000;
end;
conditional_forecast(parameter_set = calibration, controlled_varexo = (eps_i), replic = 5000);
```

This is a stylized 4-quarter RBA tightening followed by gradual unwinding.
Useful for impact analysis but NOT a real forecasting setup with external
projections of world demand, oil prices, etc.

⚠ For real AU forecasting work (e.g., RBA SOFP-style projections), AUSPAC
would need significant extensions to:
- Read external projections of world demand, USD/AUD exchange rate, commodity
  prices
- Exogenize relevant model variables
- Implement BLR-equivalent for bank lending rate forecasts

### §4.10-4.11 summary

**Verdict on accounting + conditional projections**:

- ✓ Sector financial accounts (4 agents) reasonably well aligned with FR-BDF
  eqs 116-126 (γ_reval EXACT match, w_F_ss / w_G_ss EXACT, ρ_stab_1 EXACT)
- ✗ **Branch decomposition (market vs non-market) NOT IMPLEMENTED** — AU has
  aggregate VA only. CES applied to aggregate (incl. non-market) which is
  inappropriate strictly speaking
- ✗ **Tax receipts: no exogenous-rate × endogenous-basis structure** — AU
  can't simulate tax-policy changes endogenously
- ⚠ **Transfer rules simpler than FR-BDF**: AU uses pure AR(1) (`eq_tau_F`) or
  output-gap feedback (`eq_tau_G`) instead of FR-BDF's asset-ratio
  stabilization (eqs 123-125)
- ⚠ **`rho_stab_2 = 0.25`** (vs FR-BDF 0.10) — strengthened for BK determinacy
  (linked to §4.8 #40)
- ✓ Conditional forecast variant exists (`au_pac_condforecast.mod`) with
  Dynare native `conditional_forecast_paths`
- ✗ **Three FR-BDF auxiliary models (BLR, MAPI, MAPU) NOT IMPLEMENTED** —
  appropriate for academic replication but limits real forecasting use
- ⚠ Conditional forecast scenario is stylized RBA tightening — not a real
  external-projection-driven forecasting setup

**Action items added**:
45. ✗ **Branch decomposition (market vs non-market)** — known FR-BDF design
    departure. CES production should formally apply only to market branches.
    Adding requires ABS Cat. 5204 industry-level VA + employment data and
    introducing `Q^nm`, `N_OQ` variables.
46. ⚠ **Tax receipts structure**: consider adding exogenous effective tax
    rate × endogenous tax basis decomposition for Australian tax types (GST,
    PAYG, company tax). Would enable tax-policy analysis.
47. ⚠ **Government fiscal rule alignment**: AUSPAC `eq_tau_G` is countercyclical
    on output gap (0.05·yhat_au); FR-BDF eq 125 stabilizes asset ratio. Document
    this divergence — it represents different assumptions about Australian
    fiscal-policy reaction function.
48. ⚠ **For real AU forecasting use**: would need BLR-equivalent (RBA-tracked
    lending rates), CPI auxiliary model (linked to RBA SMP forecasts), and
    public finances model (linked to Treasury budget forecasts). Currently
    AUSPAC is academic-replication scope only.

---

## §5 Long-run convergence + structural IRFs — findings

This section validates the model's dynamic properties. Three sub-questions:
(a) Does the model converge to the BGP under unconditional simulation?
(b) Are the IRFs to standard shocks economically reasonable?
(c) Are AUSPAC's quantitative IRF magnitudes consistent with FR-BDF's?

### §5.1 Long-run convergence — formal test pending

FR-BDF unconditional simulation: run 2018Q1 → 2300Q1 (282 years), all
residuals = 0, exogenous variables extrapolated at LR growth rates. Output
and inflation gaps converge to **~0 in around 40 years** (~160 quarters).

Key finding (p. 102):
> "the closure of these gaps is only ensured by price-competitiveness
> mechanisms which affect other model dynamics very slowly; the dynamics of
> these variables are also influenced by stock variables (capital, financial
> assets) which have very inertial dynamics"

Sectoral wealth: -70%/+2%/-40% targets for firms/NPISH/government, "convergence
is very slow" especially for government. Households converge to ~120% net
foreign debt at SS (per simulation).

| Item | FR-BDF | AUSPAC | Verdict |
|---|---|---|---|
| Unconditional simulation toward BGP | demonstrated (Fig 5.1.1) | NOT FORMALLY VERIFIED for AU under floating-AUD regime | ⚠ |
| Output + inflation gap convergence | ~40 years (~160 quarters) | unknown — Phase Q forward UIP changed dynamics significantly | ⚠ |
| Sectoral wealth convergence | very slow but stable | Phase N validated 2-3 quarter half-lives for wealth ratios under 20% perturbation | ✓ partial |
| Net household foreign debt SS | ~120% per simulation | not formally computed | ⚠ |

⚠ **Action item already exists** (§2 #6): "formally re-verify long-run BGP
convergence for our floating-AUD specification". The Phase Q forward UIP
refresh (2026-05-15) changed exchange-rate dynamics significantly — need to
check that LR real rate / exchange rate / inflation joint equilibrium is
well-defined under the new specification.

### §5.2 Structural IRFs — seven shocks

FR-BDF presents IRFs to 7 shocks. AUSPAC has all 7 + AU-specific commodity-price
shock (Stage 11b for mining economy):

| Shock | FR-BDF (eq) | AUSPAC | Verdict |
|---|---|---|---|
| §5.2.1 Short-term interest rate (eps_i) | yes | `eps_i` | ✓ |
| §5.2.2 Term-premium (eps_tp) | yes | `eps_tp` | ✓ |
| §5.2.3 Foreign demand (eps_q_ea) | yes | `eps_q_us` | ✓ AU adapt (US not EA) |
| §5.2.4 Government spending (eps_g) | yes | `eps_g` | ✓ |
| §5.2.5 Oil price (eps_pcom) | yes | `eps_pcom` | ✓ AU broader (commodity, not just oil) |
| §5.2.6 Cost-push (eps_pQ) | yes | `eps_pQ` | ✓ |
| §5.2.7 Labor efficiency (eps_E) | yes | `eps_tfp_LR` (renamed Phase Q fix) | ✓ |
| (no FR-BDF equivalent — AU-specific) | n/a | `eps_pcom` (commodity for mining) | ⚠ AU extension |

### §5.2.1 Monetary policy shock — IRF magnitude comparison

FR-BDF +100bp annualized monetary shock, persistence λ_i = 0.92:
- Real GDP peak: **-0.15% at Q12**
- VA price inflation: **-0.10pp at Q12**
- Unemployment: **+0.1pp at Q12**
- LR rate: +0.16pp on impact (Q1)
- NEER: +0.40% on impact (Q1)
- Real exports recover, real GDP turns positive after Q24

AUSPAC (per STATUS.md Phase Q, 100bp annualized monetary shock):
- Real GDP (ln_Q): **-0.269% VAR / -0.234% Hyb / -0.141% MCE** at Q40
- Output gap (yhat_au): -0.128% VAR Q9 / -0.151% Hyb Q7 / -0.127% MCE Q7
- Consumption growth: -0.097% VAR Q3 / -0.175% Hyb Q1
- VA price inflation: -0.086pp y/y Hyb peak Q8

| Variable | FR-BDF VAR | AUSPAC VAR | Ratio | Notes |
|---|---|---|---|---|
| Real GDP peak | -0.15% at Q12 | -0.269% at Q40 | **1.8× larger, 3.3× later** | AU response is much stronger and slower |
| VA price infl peak | -0.10pp at Q12 | -0.086pp at Q8 | ~similar magnitude | ✓ |
| Output gap (yhat_au) peak | implied ~-0.15% | -0.128% at Q9 | ✓ similar | ✓ |

⚠ **AUSPAC monetary policy effect on real GDP is ~2× larger and 3× slower**
than FR-BDF's. Strongly consistent with §4.3 audit finding: low δ_k = 0.0134
(5.4% annual depreciation) gives AU capital half-life of 51 quarters vs
FR-BDF's ~18 quarters. Capital channel dominates the long, slow output response.

⚠ **Output gap response IS comparable to FR-BDF** — confirms that AU's
gap-stationary measures are well-calibrated, but the LEVEL response (`ln_Q`)
diverges due to slow capital recovery. This is the core finding from the
2026-05-15 user-triggered investigation (the audit's origin).

### §5.2.4 Government spending — fiscal multiplier

FR-BDF: +1% of GDP shock, ρ=0.9. **Real GDP peak +1.2% on impact** (multiplier
above 1). Crowding-IN of consumption + investment in short run.

⚠ AUSPAC fiscal multiplier NOT documented in STATUS.md or working paper. ⚠
Action item to verify.

### §5.2.3 Foreign demand shock

FR-BDF: +1% on foreign demand volume, ρ=0.9.
- Real GDP peak: +0.14% at Q4
- Real exports +0.8%, real imports +0.6% on impact
- "Strong response of imports related to (i) large import content of exports
  (~33%) via IAD; (ii) large short-run elasticity of imports excluding energy
  to IAD (1.9)"

AUSPAC has `eps_q_us` shock and IAD demand index (Phase D v3). Not directly
documented per-shock IRF for `eps_q_us` in STATUS.md. ⚠ verify.

### §5.2.7 Labor efficiency shock — already audited

Per Phase Q fix (2026-05-15):
- ✓ AUSPAC's `eps_tfp_LR` is now structurally aligned with FR-BDF's permanent
  +1% level shock (eq 5.2.7 spec)
- ✓ No more exploding ln_Q response (was +13.27 at Q39 pre-fix)

### Forward-guidance-puzzle test (§6.3 in FR-BDF, but related to IRF properties)

FR-BDF: model does NOT suffer from forward-guidance puzzle (key §6.3 result).

AUSPAC (per STATUS.md Phase L extended to N=12):
- Standard NK saturates at amplification ratio 1.79 (vs linear 12) — has puzzle
- AU-PAC tracks linear to within 13% (10.47 at N=12) — **no puzzle** ✓

✓ Critical FR-BDF replication property successfully validated for AUSPAC.

### Sectoral wealth validation (§4.8.5 + §5.1)

FR-BDF Fig 5.1.3 shows convergence of net financial assets per sector,
"although convergence is very slow in the case of government net assets".

AUSPAC Phase N (per STATUS.md):
> "4 sectoral wealth-to-GDP ratios converge with 2-3 quarter half-lives under
> 20% off-SS perturbation — model passes the FR-BDF Section 4.8.5 validation"

⚠ AU's 2-3 quarter half-lives are MUCH faster than FR-BDF's "very slow"
characterization. This is consistent with AUSPAC having `rho_stab_2 = 0.25`
vs FR-BDF's 0.10 (already flagged in §4.8 #40 as strengthened for BK
determinacy). AU sectoral stabilization may be too aggressive vs FR-BDF
design intent.

### §5 summary

**Verdict on model properties**:

- ✓ All 7 FR-BDF shocks present in AUSPAC + AU-specific commodity shock
- ✓ Forward-guidance-puzzle absence successfully replicated (Phase L)
- ✓ Output gap (`yhat_au`) IRF magnitude comparable to FR-BDF
- ✓ Sectoral wealth converges (Phase N validated)
- ⚠ **Real GDP (`ln_Q`) IRF ~2× larger and 3× slower than FR-BDF** — driven
  by slow capital channel (low δ_k); originated this audit
- ⚠ **Long-run BGP convergence not formally verified** for AU under floating
  AUD regime (action #6 from §2 audit, still open)
- ⚠ Sectoral wealth convergence MUCH faster in AU (2-3 quarters) than FR-BDF
  ("very slow") — may indicate over-aggressive `rho_stab_2 = 0.25` calibration
- ⚠ Per-shock AU IRF documentation INCOMPLETE: STATUS.md only documents
  monetary IRF in detail; no quantitative comparison for foreign demand,
  government spending, oil/commodity, term premium, cost-push shocks

**Action items added**:
49. ⚠ **Document fiscal multiplier**: AUSPAC's response to `eps_g` not
    benchmarked against FR-BDF's "above 1 at impact". Run IRF and document.
50. ⚠ **Document foreign demand IRF** (`eps_q_us`) against FR-BDF §5.2.3
    benchmarks (real GDP +0.14% at Q4, imports response).
51. ⚠ **Document term premium IRF** (`eps_tp`) against FR-BDF §5.2.2
    benchmarks (real GDP -0.05%, business inv -0.45%).
52. ⚠ **Document cost-push IRF** (`eps_pQ`) against FR-BDF §5.2.6 benchmarks
    (real GDP -0.45% at Q8).
53. ⚠ Linked to #14: AU monetary IRF magnitude is ~2× FR-BDF — sensitivity
    check on δ_k at FR-BDF 0.0375 to quantify capital-channel contribution.
54. ⚠ Linked to #6: formally verify LR BGP convergence under floating-AUD
    + Phase Q forward UIP. Re-run unconditional simulation 2024Q1 → 2300Q1.

---

## §6 MCE / forward guidance / APP — findings

Final audit section. Three sub-blocks: (1) MCE PV equations + simulation
methodology, (2) monetary policy under three regimes, (3) forward guidance
puzzle, (4) APP simulation.

### §6.1.1 MCE PV equations (eqs 132-142)

FR-BDF lists 6 PV equations with constant discount factors used under MCE:

| Eq | Variable | β | Form | AUSPAC equivalent | Verdict |
|---|---|---|---|---|---|
| 132 | PV(i) (term structure) | 0.97 | recursive | `eq_pv_i`: `pv_i = (1-kappa_10)·i_au + kappa_10·pv_i(+1)`, kappa_10=0.97 | ✓ EXACT |
| 133 | PV_nd(i-ī) (non-discounted) | 1.0 | `(i-ī) + PV_nd(+1)` | `eq_pv_i_uip`: `pv_i_uip = (i_au-ibar) + beta_uip·pv_i_uip(+1)`, beta_uip=0.92 | ⚠ AU uses 0.92 not 1.0 (different discount), but Phase Q deliberate |
| 134 | PV_nd(i_F-ī) (foreign rate) | 1.0 | recursive | **NOT IN AUSPAC** — no `i_us` variable | ✗ (linked to §3.1 #8) |
| 135 | PV(π_Q) | 0.994 | recursive | `pv_piQ_aux` (different — AR(1) on E-SAT gap channels) | ⚠ different form |
| 136 | PV(y_H) | 0.95 | `(1-β)·y_H + (β/exp(Δȳ))·PV(+1)` | `eq_pv_yh`: `pv_yh = (1-beta_c)·yhat_au + beta_c·pv_yh(+1)`, beta_c=0.95 | ⚠ matches β but **missing `/exp(Δȳ)` growth correction**, AND uses output gap proxy (per §4.6.1) |
| 137 | PV(û) | 0.98 | recursive | `eq_pv_u_gap`: `pv_u_gap = (1-beta_w)·u_gap + beta_w·pv_u_gap(+1)`, beta_w=0.98 | ✓ EXACT |

**Verdict**:
- ✓ Eq 132 (term structure PV): EXACT match
- ✓ Eq 137 (unemployment PV): EXACT match
- ⚠ Eq 133 (UIP PV): Phase Q chose `beta_uip = 0.92` not 1.0 (deliberate per
  STATUS.md — gives ~4.55× impact amplification)
- ⚠ Eq 136 (permanent income PV): missing growth correction `/exp(Δȳ)`
  AND uses output gap proxy (per §4.6.1 audit)
- ⚠ Eq 135 (VA price PV): completely different form (AR(1) on gap channels
  vs FR-BDF's recursive normalised PV) — already flagged in §4.4 audit
- ✗ Eq 134 (foreign rate PV): not implemented — no `i_us` variable

### §6.1.1 PV equations for target changes (eqs 138-142)

FR-BDF gives explicit MCE forms for PAC PV terms (PV(πQ*), PV(Δn*_S), PV(Δc*),
PV(Δlog I*_H), PV(Δlog I*_B)).

AUSPAC uses **Dynare's native `pac_expectation()` macro** which automatically
generates the equivalent forms when the model is compiled in MCE mode
([au_pac_mce.mod](dynare/au_pac_mce.mod)). No separate equation needed in `.mod` file.

| FR-BDF | AUSPAC | Verdict |
|---|---|---|
| 5 explicit MCE PV equations (138-142) | Dynare native `pac_expectation(pac_X)` handles MCE auto | ✓ different implementation strategy, equivalent functional effect |

⚠ The `pv_X_aux` "wedge" terms (§3 #11, §4.4 #18, #34) appear in BOTH
`au_pac.mod` and `au_pac_mce.mod`. Per code comment ([au_pac.mod:1266](dynare/au_pac.mod#L1266)):
*"Absent in MCE (forward leads already capture everything)."*

⚠ But grep shows `pv_piQ_aux` etc. ARE in `au_pac_mce.mod` too. So either:
- Comment is wrong / aspirational (the wedges are kept in MCE)
- Or they're set to zero somehow

Worth verifying — if wedges remain in MCE, they may double-count or
contradict the FR-BDF MCE design intent.

⚠ **Action item**: confirm `pv_X_aux` behavior under MCE — should be zero
per FR-BDF design but may not be in AUSPAC implementation.

### §6.1.2 Simulation methodology

FR-BDF: counterfactual experiments computed as deviations from baseline
because FR-BDF is non-linear.

AUSPAC: same approach — Dynare's IRF computation is deviation-from-SS by
construction. ✓ aligned.

### §6.2 Monetary policy under three expectation regimes

FR-BDF Table 6.2.1 + Fig 6.2.2 main results for +100bp annualized monetary
shock:

| Regime | Output peak | Inflation peak | Convergence |
|---|---|---|---|
| Hybrid | LARGEST | LARGEST | slow ("undershoot") |
| VAR-based | medium | medium | slow ("undershoot") |
| MCE | SMALLEST | SMALLEST | fast |

FR-BDF ordering: **Hybrid > VAR > MCE** for both output and inflation peak.

Two key mechanisms:
1. **Forward-looking financial vars (Hybrid)** AMPLIFY response (LR rate moves
   sooner, exchange rate moves sooner)
2. **Forward-looking non-financial vars (full MCE)** DAMPEN response (agents
   smooth consumption knowing the future income loss)

AUSPAC results (per STATUS.md Phase Q, post 2026-05-15):

| Variable | VAR | Hybrid | MCE | Ordering | Match? |
|---|---|---|---|---|---|
| Real GDP (ln_Q) | -0.269% Q40 | -0.234% Q40 | -0.141% Q40 | VAR > Hyb > MCE | ⚠ |
| Output gap (yhat_au) | -0.128% Q9 | -0.151% Q7 | -0.127% Q7 | Hyb > VAR > MCE | ✓ |
| Consumption growth | -0.097% Q3 | -0.175% Q1 | -0.083% Q2 | Hyb > VAR > MCE | ✓ |
| VA price inflation | (not reported) | -0.086pp Q8 | (>99% MCE attenuation) | Hyb > MCE | ✓ |
| Exchange rate (s_gap) | -0.989% Q20 | -0.966% Q8 | -0.970% Q8 | similar magnitude, faster Hyb | ⚠ |

**Mixed verdict**:
- ✓ **Output GAP, consumption growth, VA price inflation**: ordering matches
  FR-BDF (Hybrid > VAR > MCE)
- ⚠ **Real GDP LEVEL (ln_Q)**: ordering REVERSED (VAR > Hyb > MCE) — driven
  by slow capital recovery dominating LEVEL response (§5 audit finding)
- ✓ **MCE attenuation strong**: 53% MCE attenuation on consumption growth,
  >99% on VA inflation — matches FR-BDF Fig 6.2.2 dampening effect
- ✓ **Hybrid amplification**: 18% over VAR on output gap, 80% on consumption
  growth — matches FR-BDF's Hyb > VAR result

So AUSPAC successfully replicates the **directional** FR-BDF properties
(Hyb > VAR > MCE for stationary measures, MCE strongest dampening) but
the LEVEL ordering inverts due to capital channel dominance.

### §6.2 Phase Q forward UIP refresh — critical for replication

Per STATUS.md: *"the AU-PAC monetary-IRF comparison still showed Hybrid ≈ VAR —
opposite to the FR-BDF wp736 §6.2 ordering where Hybrid > VAR. The root cause
was that the exchange-rate equation `eq_s_gap` used the contemporaneous policy-
rate gap `i_gap` rather than a forward NPV of the expected rate path"*.

⚠ Phase Q (2026-05-15) was a critical fix — without it, AUSPAC failed to
replicate the FR-BDF §6.2 Hyb > VAR ordering. The forward NPV `pv_i_uip`
restored the financial-amplification mechanism. ✓ aligned now.

### §6.3 Forward guidance puzzle — fully replicated ✓

FR-BDF claim: model does NOT suffer from forward guidance puzzle. Linear
response of peak GDP to forward-guidance duration (not exponential).

Compared against three DSGE models:
- **Nondiscounted NK**: textbook DSGE — has puzzle (exponential)
- **Discounted NK** (McKay et al. 2017): partial fix
- **FPH** (Woodford & Xie 2019): finite planning horizon

**FR-BDF wins**: nearly perfectly linear response.

AUSPAC Phase L (extended to N=12 per STATUS.md):
- Standard NK: amplification ratio 1.79 (vs linear 12) — has puzzle ✓
- AU-PAC: 10.47 at N=12 (within 13% of linear) — **no puzzle** ✓

✓ **Critical FR-BDF result fully replicated for AU.**

### §6.3 Mechanism — high discount + high risk aversion

FR-BDF (p. 125): *"In FR-BDF, agents are implicitly characterized by a very
high degree of risk aversion. In most DSGEs this elasticity is calibrated to
values close to 1."*

Key mechanisms (from FR-BDF eq 145):
1. β = 0.95 on permanent income (~25% annual discount rate, much higher than
   DSGE values)
2. Discounted term structure (eq 132 with κ_10 = 0.97) — not just expected sum
3. High risk aversion `σ_2 ≈ 0.55`
4. Consumption depends on **household lending premium** (`r_LH`) not short rate

| Mechanism | FR-BDF | AUSPAC | Verdict |
|---|---|---|---|
| Permanent-income discount β_c | 0.95 | `beta_c = 0.95` | ✓ EXACT |
| Term-structure discount κ_10 | 0.97 | `kappa_10 = 0.97` | ✓ EXACT |
| Risk aversion σ_2 | ~0.55 | `alpha_c_r = -0.95` (different parameterisation) | ⚠ verify |
| Consumption dep. on bank lending rate | yes | yes (via `i_lh - pi_c` in `eq_dln_c_star_bar`) | ✓ |

✓ **All four no-forward-guidance-puzzle mechanisms present in AUSPAC.**
This explains why AU-PAC successfully avoids the puzzle.

### §6.4 Asset Purchase Programmes (APP)

FR-BDF: applies APP shock decomposition to French economy 2015-2018.
- Total term-premium effect: 100bp (over 3 packages 2015Q1, 2015Q4, 2016Q1)
- Total exchange rate effect: 9% (12% on EUR/USD, weighted)
- Cumulative GDP impact: 0.82% (VAR) / 0.73% (MCE) over 4 years
- Cumulative inflation impact: 1.08% (VAR) / 1.85% (MCE) over 4 years

⚠ Notable: under MCE inflation effect of exchange rate movements is much
larger (1.85 vs 1.08).

AUSPAC has APP-style experiment per `regen/regen_app_experiment.py` and
[Fig 6.14 `app_experiment_200bp.png`](dynare/app_experiment_200bp.png).

| Item | FR-BDF | AUSPAC | Verdict |
|---|---|---|---|
| APP simulation framework | yes (Eurosystem APP 2015-2018, 100bp+9%) | yes (200bp tightening experiment per Fig 6.14) | ✓ aligned in spirit |
| Term-premium decomposition | yes (3 packages, 100bp total) | check `regen_app_experiment.py` for AU calibration | ⚠ verify |
| Exchange rate channel separation | yes (Table 6.4.2 splits TP vs ER) | likely combined | ⚠ verify |
| MCE vs VAR comparison | yes | likely VAR-based only | ⚠ verify |

⚠ AUSPAC's APP-style experiment exists but appears less elaborate than
FR-BDF's Eurosystem APP impact analysis. For RBA QE evaluation
(2020-2022 Term Funding Facility, RBA bond purchases), would need similar
shock decomposition.

### §7 Conclusion (FR-BDF) — relevance to AUSPAC

FR-BDF emphasizes:
1. ✓ **Rich financial channels** — AUSPAC has WACC, term structure, UIP, BLR
2. ✓ **No forward guidance puzzle** — AUSPAC replicates this (Phase L)
3. ✓ **Well-defined long run with BGP convergence** — AUSPAC partially (Phase N
   sectoral wealth, but full BGP not formally verified per #6 / #54)
4. ⚠ **Future work — financial accelerator + house/stock price dynamics** —
   AUSPAC has housing prices but no financial accelerator (consistent gap)

### §6 summary

**Verdict on MCE / forward guidance / APP**:

- ✓ Term structure PV (eq 132) and unemployment PV (eq 137) EXACT match
- ✓ Forward-guidance-puzzle absence successfully replicated (Phase L
  amplification 10.47 vs linear 12 at N=12)
- ✓ All four no-puzzle mechanisms present (β_c=0.95, κ_10=0.97, high risk
  aversion, lending-rate-based consumption)
- ✓ Three-regime ordering for STATIONARY measures (output gap, consumption
  growth) matches FR-BDF Hyb > VAR > MCE
- ✓ Phase Q forward UIP (2026-05-15) was critical for restoring this ordering
- ⚠ Real GDP (ln_Q LEVEL) ordering REVERSED (VAR > Hyb > MCE) due to slow
  capital recovery dominating
- ⚠ Permanent-income PV (eq 136) missing `/exp(Δȳ)` growth correction
- ✗ Foreign rate PV (eq 134) not implemented (no `i_us`)
- ⚠ `pv_X_aux` wedge behavior under MCE unverified — comment says "absent"
  but grep shows present in `au_pac_mce.mod`
- ⚠ APP-style experiment exists but less elaborate than FR-BDF's Table 6.4.2
  decomposition

**Action items added**:
55. ⚠ **Verify `pv_X_aux` MCE behavior**: code comment says "absent in MCE"
    but `pv_X_aux` equations appear in `au_pac_mce.mod`. Either zero them
    out or update comment. Linked to #18 / #34 puzzle.
56. ⚠ Consider adding `/exp(Δȳ)` growth correction to `eq_pv_yh` to fully
    match FR-BDF eq 136. Currently AU `pv_yh` is recursive PV without growth
    correction (which only matters for non-zero LR growth, but that's our
    case).
57. ⚠ Verify `alpha_c_r = -0.95` (AU consumption real-rate sensitivity)
    corresponds to FR-BDF risk aversion `σ_2 ≈ 0.55` mechanism. Different
    parameterisations may not be directly comparable.
58. ⚠ Consider expanding APP-style experiment to match FR-BDF Table 6.4.2
    decomposition (separate TP vs ER channels, VAR vs MCE comparison).
    Relevant for RBA QE policy analysis.

---

## Audit complete — final summary

All 15 sections audited (2026-05-15). Total **58 action items** identified.

### Verdict counts by category

- ✓ **Successfully aligned**: TFP shock spec (post-fix), 8-equation E-SAT core,
  PAC framework, β=0.98 calibration, recursive PV terms (132, 137), term
  structure (eqs 95-97), WACC weights (eqs 98-100), sector financial accounts
  (most params), forward-guidance-puzzle absence (Phase L), three-regime IRF
  ordering for stationary measures
- ⚠ **AU adaptations** (intentional, document but don't fix): US replaces EA,
  floating AUD with UIP, commodity-price channel (Stage 11b), lower
  depreciation rate (δ_k=0.0134), AU flat Phillips curve (β_2≈0 across 4
  equations), endogenous trends, simplified wage Phillips, simpler bank
  lending rate, simpler transfer rules
- ✗ **Genuine mismatches needing action**:
  1. **Sign error on `dln_tfp` in `eq_dln_n_star_bar`** (#21) — easy fix
  2. **Missing `Δq` channel in `eq_dln_n_star_bar`** (#17) — combine with #21
  3. **Sign convention on `kappa_w · pv_u_gap`** (#22) — verify
  4. **Missing `α_1·PV(real rate gap)` in `eq_dln_c_pac`** (#26) — affects
     monetary transmission
  5. **`pv_X_aux` puzzle**: 6 deflators + 5 PAC eqs all missing FR-BDF
     level-correction terms (#18 / #34) — needs SS computation to resolve
  6. **No foreign short rate `i_us`** — affects US IS (#8) + UIP (#42)
  7. **Branch decomposition** (market vs non-market) absent (#45)
  8. **Energy/non-energy import split** deferred (#33)

### Top-priority action items

1. **#18 / #34** — Resolve `pv_X_aux` puzzle (highest leverage; affects 11+ eqs)
2. **#21 + #17** — Fix `dln_tfp` sign + add `Δq` channel in eq_dln_n_star_bar
3. **#26** — Add forward real-rate PV channel to consumption PAC
4. **#22** — Verify wage Phillips κ_w sign convention
5. **#54** — Formally verify LR BGP convergence under floating AUD + Phase Q

### Audit trigger resolved

The original 2026-05-15 user concern was: *"GDP IRFs show permanent deviations
from steady-state for temporary shocks while consumption components revert."*

This audit confirmed three contributing factors:
1. **Plotting choice** (level ln_Q vs growth dln_c) — fixed in figure-regen scripts
2. **Slow capital channel** (δ_k = 5.4% annual) — real model property,
   action #14/53 sensitivity check pending
3. **TFP shock spec** (was integrated AR(1) on growth rate, now permanent
   level shock per FR-BDF §5.2.7) — fixed 2026-05-15

The audit additionally identified 8 ✗ structural mismatches and 50+
methodological flags worth tracking. None invalidate AUSPAC's overall
replication claim, but several (especially #21, #26, #34) are worth fixing
to improve quantitative alignment with FR-BDF.
