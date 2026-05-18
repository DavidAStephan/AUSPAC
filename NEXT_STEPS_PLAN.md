# AUSPAC — Next-steps development plan (v3.2 roadmap)

**Date drafted**: 2026-05-17
**Current state**: v3.1, post-Phase-Y. MHM = −780.47, Laplace = −779.30.
**Source materials**: structural reading of FR-BDF wp1044 (Dubois et al. 2026) and ECB-BASE (Angelini et al. 2019, ECB WP 2315) against the current AUSPAC code.

This document sequences the recommended additions to AUSPAC in three rounds by expected fit gain, research leverage, and implementation effort. Items in each round are independent and can be tackled in any order within the round; rounds themselves are sequenced low-risk → high-leverage → conditional.

---

## Round 1 — Low-risk additions (~4 weeks total)

Five small additions that together likely add 1–3 nats Laplace LMD (rough order-of-magnitude based on Phase W's experience) and substantially enrich the analytical / reporting surface, with no architectural risk.

### 1.1 HICP-style headline-decomposition reporting block

**Sources**: ECB-BASE §3.2.3 (HICP block) + FR-BDF wp1044 §3.6.4 (new in wp1044, absent from wp736). Both papers endorse.

**What to add**: A one-way reporting layer where total CPI is decomposed into core, energy, food, and (for AU) trimmed-mean / tradeables / non-tradeables components. New endogenous variables:
- `pi_au_core` = weighted average of piQ and pi_m (excluding energy passthrough)
- `pi_au_energy` = driven by `dln_pcom` and the AU energy import deflator (when added in Round 2)
- `pi_au_food` = weighted of wages, agricultural commodity index, and energy passthrough
- `pi_au_trim` = trimmed-mean CPI proxy (AU-specific; RBA reports this)
- `pi_au_tradeables`, `pi_au_nontradeables` (AU-specific decomposition matching RBA discourse)

**Why**: RBA's actual inflation discourse uses trimmed-mean, weighted-median CPI, and tradeables/non-tradeables splits. AUSPAC currently has only headline `pi_au`. Adding this enables direct comparison to RBA forecasts and richer post-2022 inflation-surge analysis.

**Effort**: 2–3 days. All new variables are one-way functions of existing model objects — zero feedback into dynamics, so zero estimation risk.

**Implementation steps**:
1. Add new variable declarations to `simulation/identities/endogenous.inc`
2. Add the weighted-average identities to `simulation/identities/model.inc`
3. Calibrate weights from ABS Cat. 6401 (CPI by sub-component) and RBA inflation expectations data
4. Add new variables to `stoch_simul` output list in `au_pac.mod`
5. Add a §4.9.x subsection to the working paper documenting the reporting layer

**Verification**: model preprocesses (smoke test), IRFs include the new components, BK rank unchanged.

---

### 1.2 Direct wage + transfer income channel in consumption

**Source**: FR-BDF wp1044 §3.5.1 eq 35 (new vs wp736). ECB-BASE has the analogous mechanism via the η_T = 0.271 transfer-income weight in its permanent-income decomposition.

**What to add**: A term in the consumption short-run equation capturing rule-of-thumb consumers' direct response to wage and government-transfer income:

`+ β_HtM · Δ[log(W_H,t + TG_H,t) − p_C_VAT,t − ỹ_t]`

In FR-BDF wp1044 this β_HtM = 0.32 (s.e. 0.10), and replaces the previous output-growth term. R² rose to 0.95.

**Why**: AU has significant hand-to-mouth consumer share (RBA's "Distributional and indirect effects of monetary policy" research). The direct wage+transfer channel matters substantially for analysing fiscal-transfer policy (JobKeeper-style), minimum-wage decisions, and the FY-end tax-refund cycle. AUSPAC currently has `b_di_c = -0.701` (rate channel via Phase C IV) but not the wage+transfer income channel.

**Effort**: 1 day code + re-estimation.

**Implementation steps**:
1. Construct the wage+transfer aggregate `wt_H_real = log(W_H + TG_H) − p_C` in `model.inc` (ABS Cat. 5206 Table 3 has wages received by households; ABS Cat. 5512 has government transfers)
2. Add the `b_HtM · Δ[wt_H_real − ỹ]` term to `eq_dln_c_pac` in the aux file `aux/aux_consumption.mod`
3. Re-run dynare + cherrypick for the consumption block via `phaseW_recherrypick.m`
4. Patch the new `b_HtM` parameter into `au_pac.mod` and `au_pac_bayesian.mod` (declare + assign; possibly add to `estimated_params` with Normal(0.30, 0.10) prior centred on wp1044 posterior)
5. Run mode search to verify Laplace LMD improves
6. Optionally run fresh 20k MCMC (~50 min)

**Verification**: posterior mean for b_HtM should be positive and statistically significant on AU data; Laplace LMD improvement expected.

---

### 1.3 Time-varying inflation attractor (Cogley-Sbordone)

**Source**: ECB-BASE §3.2.3 (WAPRO uses this for π̄_t).

**What to add**: Replace the simple AR(1) anchor `pibar_au = ρ·pibar_au(-1) + (1−ρ)·pi_ss_au` with a Cogley-Sbordone time-varying attractor that drifts smoothly with realised inflation deviation:

`pibar_au_t = (1−β_π)·pi_ss_au + β_π·pibar_au_{t-1} + δ_pibar·(pi_au_{t-1} − pibar_au_{t-1})`

with calibrated δ_pibar ≈ 0.05–0.10 (ECB-BASE posterior range).

**Why**: Episodes like the 2022–2023 inflation surge are hard to fit with a constant long-run anchor — survey measures of long-run inflation expectations visibly moved up during 2022. A time-varying attractor lets the model accommodate persistent expectation shifts without contaminating the structural slope of the Phillips curve.

**Effort**: 1 day code + re-estimation.

**Implementation steps**:
1. Modify `eq_pibar_au` in `simulation/identities/model.inc` to add the deviation-correction term
2. Add new parameter `delta_pibar` to `parameter-values.inc`, calibrate to 0.07 initial
3. Optionally add to `estimated_params` with Beta(0.07, 0.04) prior
4. Re-run mode search; verify LMD improvement

**Verification**: posterior should pull δ_pibar away from 0 only if AU data supports time variation in the inflation anchor. The 2022–2024 sample includes the inflation surge, so identification should be reasonable.

**Can be implemented independently of Round 3 (full WAPRO MCE block).**

---

### 1.4 PV² (squared expectation operator) in consumption

**Source**: FR-BDF wp1044 §3.5.1 eq 35 (new vs wp736).

**What to add**: A new auxiliary variable `pv2_yh` = E[discounted future squared income-output ratio | E-SAT state at t-1], entered into the consumption short-run equation as an uncertainty premium / conditional variance proxy. wp1044's policy function for PV² is in Table 3.5.3.

**Why**: Could improve forecast performance in periods of high income uncertainty (COVID, 2022 mortgage-rate spike, 2008 GFC). AUSPAC currently has `pv_yh` (first-order PV) but probably not the squared form.

**Effort**: 2–3 days.

**Implementation steps**:
1. Add `pv2_yh` to `aux/aux_consumption.mod` declarations
2. Add `var_pv2_yh` equation (auxiliary regression onto E-SAT state, mirroring wp1044 Table 3.5.3 coefficients but re-estimated on AU data)
3. Modify `eq_dln_c_pac` in the aux file to reference `pv2_yh(-1)`
4. Re-run `phaseW_recherrypick.m` for consumption block (regenerates `h_pac_c_*` coefficients including the new pv2_yh projection)
5. Patch new `h_pac_c_var_pv2_yh_lag_1` into production .mod files
6. Mode-search verify

---

### 1.5 Quasi-endogenous employment target with trend+gap expectation split

**Source**: FR-BDF wp1044 §3.4.3 (new vs wp736 — "instead of anchoring the long-term employment to a fixed exogenous path, we now use a quasi-endogenous target").

**What to add**: Modify `aux/aux_employment.mod` so the employment target's expectation term is split into:
- Low-frequency trend component (calibrated unit-root process for `n̄*_S,t-1`)
- Cyclical gap component (auxiliary AR(1) equation driven by output gap)

per wp1044 eq 31–32. This captures labor-hoarding behaviour — firms shed fewer workers in downturns when they anticipate a rebound in desired employment.

**Why**: AU's labor-hoarding was significant in 2020–2021 (JobKeeper subsidised it explicitly). Currently AUSPAC's employment PAC has a simple expectation structure that may underestimate this hoarding effect.

**Effort**: ~1 week (more elaborate aux-file restructure than the others in Round 1).

**Implementation steps**:
1. Modify `aux/aux_employment.mod` to add `n_hat_trend` and `n_hat_cyclical_gap` as separate var_model states
2. Update `eq_dln_n_pac` to reference both components with separate `pac_expectation()` calls
3. Re-run dynare + cherrypick via `phaseW_recherrypick.m`
4. Patch the new h_pac_n_* coefficients into production .mod files (will likely change all employment-block h coefficients)
5. Mode-search verify
6. If positive, run fresh 20k MCMC

**Verification**: post-2020 employment IRFs should show stronger persistence (less worker shedding) than under the current spec.

---

### Round 1 summary

| Item | Source | Effort | Expected ΔLaplace |
|---|---|---|---|
| 1.1 HICP reporting block | ECB-BASE + wp1044 | 2–3 days | 0 (no feedback) |
| 1.2 Wage+transfer income channel in consumption | wp1044 eq 35 | 1 day | +0.3–0.8 nats |
| 1.3 Time-varying inflation attractor | ECB-BASE WAPRO | 1 day | +0.2–0.5 nats |
| 1.4 PV² in consumption | wp1044 eq 35 | 2–3 days | +0.1–0.3 nats |
| 1.5 Quasi-endogenous employment target | wp1044 §3.4.3 | 1 week | +0.2–0.5 nats |
| **Round 1 total** | | **~4 weeks** | **+0.8–2.1 nats Laplace** |

These five items are independent and can be parallelised if you have multiple sessions. Suggest doing them in the order listed (cheapest first).

---

## Round 2 — High-leverage architectural addition (~6–8 weeks)

Two larger additions that unlock new research domains.

### 2.1 Energy index (oil + gas) split

**Source**: FR-BDF wp1044 Appx E + §3.6.4 HICP energy. wp736 had only oil.

**What to add**: Replace AUSPAC's single `dln_pcom` exogenous commodity index with a structural split:
- Oil price index (in AUD)
- Gas / LNG price index (in AUD)
- Synthetic energy price index `p_SEI_au` as time-varying-weight composite (weights from ABS energy-import data)

Then route the synthetic index through:
- Existing cost-push channels in `eq_pi_c`, `eq_pi_x`, `eq_pi_m`, `eq_pi_g`
- The new HICP energy component (Round 1.1)
- The credit/financial-asset block (Round 2.2) via leverage and revaluation effects

**Why**: AU is a major LNG exporter; gas prices are highly relevant for both export-revenue analysis (income channel) and domestic gas-electricity-CPI passthrough (cost channel). The combined oil+gas energy index matches the post-2022 inflation environment better than oil alone. STATUS.md previously listed this as a Phase 5 open item ("Energy / non-energy import split", audit #33, #37).

**Effort**: 1–2 weeks.

**Implementation steps**:
1. Construct AU energy import deflator from ABS Cat. 5368.0 (oil + LNG + electricity components); split into oil and gas series
2. Define `dln_p_oil`, `dln_p_gas` as new exogenous variables in `model.inc`
3. Define `p_SEI_au` as weighted composite with quarterly-varying weights (calibrated from AU energy-import balance)
4. Replace `dln_pcom` references with `p_SEI_au` in `eq_pi_c`, `eq_pi_x`, `eq_pi_m`, `eq_pi_g`
5. Split `gamma_oil` parameter into `gamma_oil_split` + `gamma_gas_split` (re-estimate by single-equation OLS on AU data)
6. Re-run mode search + fresh MCMC

**Verification**: 2022-2024 IRFs for energy shocks should match RBA's "How energy prices affect Australian inflation" analysis (RBA Bulletin Sept 2022).

---

### 2.2 Credit / financial-asset block (the major investment)

**Source**: FR-BDF wp1044 §3.7.2–3.7.3 (entirely new vs wp736). Bove et al. (2020) for household side; Dees et al. (2022) for corporate side.

**What to add**: A full credit-and-financial-asset block with:

#### Household side (wp1044 eq 58–67)
- Housing-debt stock `D^H` (eq 58)
- New mortgages flow `M^H` (eq 59), with target related to house prices, residential investment, real interest rate, debt service ratio (eq 60); ECM short-run (eq 61)
- Debt service ratio `dsr_t = (δ_t + i*_t)·D^H_{t-1} / Y_t` (eq 62)
- **Time-varying debt amortization** δ_t with maturity-dependent kappa coefficient (eq 63) — exceptionally relevant for AU's variable-rate mortgage market
- Other household loans `C^O` as flow relative to disposable income (eq 66)
- Aggregation with NPISH (eq 67)

#### Corporate side (wp1044 eq 68–76)
- Corporate bank loans `L^e` relative to GDP, responding to financing need and bank-bond spread (eq 68)
- Bonds-to-debt ratio `BD^C` ECM with bank-loan vs BBB-bond spread (eq 69)
- Equity revaluations `RY^C` from stock-market dynamics (eq 70)
- Stock-price ECM (CAC40-equivalent → in AU context, ASX-200 + super-fund holdings) (eq 71–72)
- Net equity `E_t` identity from net assets, financing need, currency, bonds, bank loans (eq 73)
- Asset accumulation identities `F2_t`, `F8_t` (eq 74–75)
- Net market leverage `D^C / E_t` (eq 76)

#### Sectoral stabilisation (wp1044 eq 86–88)
- Transfer-policy rules for firms and NPISH to stabilise net assets (eq 86–87) — complements AUSPAC's existing govt fiscal rule (`rho_stab_1`, `rho_stab_2`)
- Asset return AR(1) processes (eq 89)

**Why this is the highest-leverage addition**:
- AU has the highest household-debt-to-income ratio in the OECD (~200%); credit dynamics are a critical channel for monetary transmission.
- Currently AUSPAC has WACC composite cost of capital but no debt stock tracking, no debt service ratio, no household-mortgage block, no corporate leverage. Adding this unlocks:
  - **Financial-stability / leverage-cycle analysis**
  - **Macroprudential policy experiments** (LVR caps, debt service ratio limits — current RBA / APRA policy debate)
  - **Better unconventional monetary policy analysis** (lending-rate channel through bank balance sheets — relevant for any future QE)
  - **Direct comparability to RBA's "Australian household debt and consumption" research** (Bulletin / RDP series)

**Effort**: **~4–6 weeks**. Major addition.

**Implementation steps** (high-level — detail this further before commencing):
1. Data collection: RBA D-series (housing debt), ABS 5232.0 (financial accounts), ASX-200 history, AU mortgage-rate data (RBA F-series + APRA monthly)
2. Calibrate the dozen+ new parameters from Bove et al. (2020) framework adapted to AU (debt amortization, mortgage maturity, loan-to-value, etc.)
3. Add ~15 new endogenous variables: `D^H`, `M^H`, `dsr`, `delta_amort`, `C^O`, `L^e`, `B^C`, `BD^C`, `RY^C`, `E_t`, `leverage`, `F2`, `F8`, `cac40_au` (proxy: log ASX-200), and stock-price/equity processes
4. Add ~20 new equations to `model.inc` (the eq 58–89 chain from wp1044, adapted)
5. Re-aggregate (this is large enough to warrant a proper aggregate run rather than patching), then re-add the Phase U/V/W manual overrides
6. Re-estimate via fresh MCMC (likely >51 min due to expanded parameter count; budget ~90 min)

**Verification**: Stress-test that the model still passes BK rank with ~175 endogenous variables (up from current 158). Validate against RBA's "Financial stability" analytical narratives.

**Phase name suggestion**: Phase 5a-Credit.

**Dependency note**: Time-varying debt amortization (wp1044 eq 63) and equity revaluations (eq 70+84+85) are bundled in this block — cannot implement independently.

---

### Round 2 summary

| Item | Source | Effort | Expected ΔLaplace | Unlocks |
|---|---|---|---|---|
| 2.1 Energy index (oil + gas) | wp1044 Appx E | 1–2 weeks | +0.3–0.7 nats | Energy-inflation analysis matching RBA 2022+ narratives |
| 2.2 Credit / financial-asset block | wp1044 §3.7.2–3.7.3 | 4–6 weeks | +1.0–3.0 nats (large model expansion) | Macroprudential, financial-stability, QE analysis |
| **Round 2 total** | | **~6–8 weeks** | **+1.3–3.7 nats** | Significantly broader policy-analysis scope |

---

## Round 3 — Conditional (only if research priorities pivot, ~3–4 weeks)

### 3.1 WAPRO-style MCE wage-price subsystem

**Source**: ECB-BASE §3.2.3 (the WAPRO subsystem).

**What to add**: Carve out a small DSGE-style wage-price-output subsystem with model-consistent (rational) expectations, estimated jointly by Bayesian MCMC. The rest of the model stays VAR-based. Specifically:
- Forward-looking New Keynesian price Phillips curve (Cogley-Sbordone time-varying attractor + forward-looking E_t π_{t+1} term)
- Forward-looking wage Phillips curve (Galí-Smets-Wouters 2012 form)
- Kalman-filtered NAIRU and output gap as unobservable states
- Two-country (AU + US) IS curves + Taylor rules within the satellite
- Joint Bayesian system estimation via Kalman + Metropolis-Hastings

**Why this is conditional**: If the research agenda shifts toward forward-guidance experiments, QE / asset-purchase analysis, or unconventional monetary policy, the current all-VAR architecture won't let the price block respond to anticipated future policy. AUSPAC's existing forward-guidance puzzle test (paper §6.5, ratio = 10.14 at N=12) shows the current architecture handles standard FG fine — but a WAPRO-style block would enable richer experiments.

**Why NOT to do unless needed**:
- Major restructure (~3–4 weeks)
- Adds estimation complexity (joint Bayesian system on top of the existing 28-parameter MCMC)
- May not give clear gains for the academic-replication use case
- Risks destabilising the well-functioning Phase T/W/X/Y architecture

**Effort**: ~3–4 weeks if pursued.

**Decision criterion**: Pursue **only if** AUSPAC's research priorities pivot to:
- Unconventional monetary policy / QE / asset-purchase experiments
- Forward-guidance research beyond the standard puzzle test
- Inflation-expectations anchoring under regime changes

If yes: detailed implementation plan needed (out of scope for this document).

---

## Cumulative roadmap

| Round | Items | Effort | Expected ΔLaplace | When to do |
|---|---|---|---|---|
| Round 1 | 5 low-risk additions | ~4 weeks | +0.8–2.1 nats | Recommended immediately as next development cycle |
| Round 2 | Energy split + credit block | ~6–8 weeks | +1.3–3.7 nats | After Round 1, especially the credit block |
| Round 3 | WAPRO MCE block | ~3–4 weeks | unclear | Only if research priorities pivot to FG/QE |
| **Total Rounds 1+2** | | **~10–12 weeks** | **+2.1–5.8 nats Laplace** | Plus much broader analytical scope |

If all three rounds are completed, AUSPAC would:
- Have a Bayesian-estimated MCE wage-price block (matching ECB-BASE)
- Have a full credit/financial-asset block (matching wp1044, surpassing ECB-BASE which has HH-only)
- Cover energy oil+gas split (matching wp1044)
- Have HICP-style headline decomposition (matching both)
- Retain its existing architectural strengths: CES production, full 4-sector financial accounts, explicit fiscal debt-stabilization rule, AU-specific commodity and mortgage channels

In short: a model that combines the best of FR-BDF wp1044 (the credit-block and HICP additions) and ECB-BASE (the WAPRO MCE option) on top of AUSPAC's existing AU-specific innovations.

---

## What this plan deliberately does NOT include

For clarity, these are items that came up during the audit / comparison work but are out of scope here:

| Item | Why excluded |
|---|---|
| Negotiated wage equation (wp1044 §3.4.2 eq 27) | France-specific institutional feature (SMIC indexation, "coups de pouce"). AU's Fair Work Commission annual wage review serves a similar function via different mechanisms; not a direct port. |
| Monthly basic wage equation (wp1044 eq 28) | France-specific minimum-wage proxy. AU doesn't have an analog with this structure. |
| CES production with two trend breaks (2002Q2 + 2008Q3) | AUSPAC already has this (Phase G work; FR-BDF 2026 labor-FOC method with two-break trend efficiency). |
| Cleaner ECB-BASE per-equation Base VAR (3 vars + target augmentation) | Phase W just activated Bayesian posteriors on the large E-SAT successfully (+1.75 nats Laplace). Switching to a smaller Base VAR would undo that work and likely lose fit. |
| Updated household investment housing-stock-price ECM (wp1044 eq 39–41 / Bove 2020) | Bundled with Round 2.2 credit block. AUSPAC's `b_ph_ih = 0.0099` (Phase C) is the current AU-spliced-housing-price-series version; worth refreshing under the wp1044 Bove framework when doing the credit-block work. |
| Intra/extra-EA trade split (ECB-BASE §3.1.4) | EA-specific; AU has no currency-union trade. |
| Sector accounts ESA-2010 closure (ECB-BASE Appx B.6) | AUSPAC already has fuller 4-sector closure (F/G/H/N) from FR-BDF wp736 §4.8.5. |

---

## Existing Phase 5 substantive extensions (from the previous STATUS.md backlog)

These remain valid and complement the wp1044/ECB-BASE additions above. Rolling them into this plan:

| Existing Phase 5 item | Relationship to this plan |
|---|---|
| Foreign rate `i_us` — add Fed funds rate + ibar_us to E-SAT (audit #8, #42) | Independent of this plan; can be done any time |
| Energy / non-energy import split (audit #33, #37) | **Subsumed by Round 2.1** (energy oil+gas split) |
| Branch decomposition — market vs non-market VA (audit #45) | Independent; substantial standalone project |
| Tax structure decomposition — GST/PAYG/company effective rates (audit #46) | Independent |
| Demographic trends — `POP̄_t` from ABS 6202 (audit #43) | Independent; small (~1 week) |
| BLR / MAPI / MAPU auxiliary forecasters (audit #48) | Independent; substantial (real RBA-style forecasting use case) |
| APP experiment expansion (audit #58) | **Best after Round 2.2** (credit block enables richer TP vs ER decomposition) |
| Phase K final piece — `b_di_c` clean identification via RBA OIS surprises | **Complements Round 1.2** (the wage+transfer channel adds another income-side ROT mechanism; b_di_c remains the rate-side channel) |

---

## Suggested first action

Given the audit closure earlier today (Phase Y), the natural next move is **Round 1.1** (HICP reporting block) — lowest risk, immediate analytical value, ~3 days, zero dependency on anything else. From there, Round 1.2 (wage+transfer channel) and Round 1.3 (time-varying inflation attractor) can be done in a single afternoon each.

Round 2.2 (credit block) is the highest-leverage item but the largest single investment; recommend planning a dedicated sprint after Round 1 is complete.
