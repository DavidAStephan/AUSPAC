# AUSPAC — Project status

**Version**: v3.2 (Phase L2 P1c hybrid BI calibration locked 2026-05-26; working paper v2 regenerated)
**Architecture**: Phase T policy-function PAC expectations (FR-BDF wp1044 §2.2 / Adjemian-Brayton-Zimic), with Phases W/X/Y architectural cleanup completed, Round 1.1 HICP-style reporting block, 2026-05-21 Rounds 4-8 consolidation, 2026-05-22 Round 1.2 hand-to-mouth wage+transfer income channel, and **2026-05-26 Phase L2 wp1044-faithful partial-replication with hybrid Option 1 BI calibration**.
**Headline metric (current cache)**: Laplace LMD = **−662.27**, MHM LMD = **−665.51** — fresh 20k×2-chain MCMC under the full structural model (ULC/UCK channels + deflator ECMs + endogenous spreads + energy/non-energy import split + corrected K_market data pipeline), completed 2026-05-28. **+31.9 nats MHM improvement** vs the pre-structural-fix hybrid (−697.36), **+120.3 nats** vs Round 1.2 (−785.80). Cumulative Phase Q → current MHM improvement: **+136.8 nats** (from −802.27 to −665.51). MATLAB R2026a + Dynare 7.0 (native ARM, parallel pool, 20 min wall time). Chains cached in `dynare/au_pac_bayesian/metropolis/`.
**Phase L2 P1c finding**: wp1044 PAC framework validates on AU for 4 of 5 PAC blocks (VA-price, employment, consumption, housing inv — R² ∈ [0.41, 0.81]). Business investment structurally rejects the wp1044 PAC restriction (PV(Δq̂) coef = −5.03 vs structural +1 across 11 spec variants); the production model imports BI deep parameters from wp1044 Table 3.5.13 via the **Option 1 hybrid calibration**. Headline finding: consumption β₀ = 0.27 ≈ wp1044's 0.29 — the single closest cross-country agreement. Working paper v2 regenerated at `dynare/AUSPAC_WORKING_PAPER.{md,tex,html}` (PDF compilation pending LaTeX install — see `WORKING_PAPER_BLOCKERS.md`).

---

## What v3.1 is

AUSPAC is the Australian replication of FR-BDF (Banque de France WP #736 Lemoine et al., 2019; updated 2026 in WP #1044 Dubois et al.). It is a semi-structural macroeconomic model with Polynomial Adjustment Costs (PAC), explicit expectations from a structural-VAR satellite (E-SAT), and a CES supply block re-estimated on Australian data 1994Q1–2025Q4.

**Production model**: [`dynare/au_pac.mod`](dynare/au_pac.mod) — built via Dynare's `cherrypick()` + `aggregate()` workflow from:
- 5 aux .mod files in [`dynare/aux/`](dynare/aux/) (one per PAC block: pQ, consumption, business_inv, housing_inv, employment)
- 7 normalized identity .inc files in [`dynare/simulation/identities/`](dynare/simulation/identities/)
- 5 cherrypicked .inc bundles in [`dynare/simulation/estimation/<block>/`](dynare/simulation/estimation/)

**Bayesian estimation**: [`dynare/au_pac_bayesian.mod`](dynare/au_pac_bayesian.mod), 28 estimated parameters, ~50 min wall time per 20k×2-chain MCMC, current Laplace LMD = **−779.30**, MHM = **−780.47**.

**Working paper**: [`dynare/AUSPAC_WORKING_PAPER.md`](dynare/AUSPAC_WORKING_PAPER.md) — §4.3 documents the post-Phase-Y single-target VA-price architecture, §4.4.0 the Phillips curve with Phase V structural channels, §4.9 the demand-deflator reduced-form simplification, §8 the explicit AU-vs-FR-BDF architectural deviations.

---

## Phase trajectory and headline results

| Phase | Date | LMD (MHM unless noted) | Δ | Change |
|---|---|---|---|---|
| Phase Q | 2026-05-15 | −802.27 | baseline | Forward-NPV UIP `pv_i_uip` |
| Phase R | 2026-05-15 | −790.72 | +11.55 | Wage Phillips CPI indexation; employment-target Δq + dln_tfp signs; consumption `pv_r_lh_gap` real-rate channel |
| Phase S | 2026-05-16 | −789.10 | +1.62 | FR-BDF cost-push replication via structural deflator channels in `eq_au_phillips` |
| Phase T (v3.0) | 2026-05-16 | −781.39 | +7.71 | srecko/FR-BDF aggregate workflow — policy-function PAC expectations replace shadow-VAR `pac_expectation()` calls |
| **Phase W** | 2026-05-17 | **−780.47** | **+0.92** | Self-consistent activation of `calibration.inc` Bayesian-posterior aux-regression coefficients. Two-stage fix: runtime override block in the production .mod files for the 24 `rho_*_aux` / `a_*_y/i/pi/u/yh` parameters, then re-templated aux .mod files and re-cherrypicked all 5 PAC blocks to refresh the 73 `h_pac_*` policy-function coefficients. Verified by fresh 20k×2-chain MCMC. Laplace gain +1.75 nats. |
| Phase X | 2026-05-17 | (Laplace −779.30) | +0.00 | Parameter-name unification: aux files' `rho_pi_m` renamed to `rho_pm` (value 0.28) to match `model.inc`. Eliminates the only aux-vs-identities parameter-name drift. Neutral LMD; kept for naming consistency. |
| **Phase Y** | 2026-05-17 | (MHM −780.47) | +0.00 | Orphan-equation removal: `eq_piQ_star`, `eq_piQ_star_bar`, `eq_pQ_star_level`, `eq_pQ_gap` and parameters `rho_pQ_star`, `gamma_ulc`, `gamma_uck` deleted from `model.inc` and the production .mod files. They were verified-orphan diagnostic equations (never on the RHS of any other equation). Removal leaves `piQ_hat` as the canonical VA-price PAC target, matching FR-BDF wp736 Table 4.4.4 and ECB-BASE WAPRO single-target architecture. LMD unchanged. |
| **Round 1.1** | 2026-05-18 | (MHM −780.4699, Laplace −779.3031) | +0.00 | HICP-style headline-decomposition reporting block: 6 new endogenous reporting variables (`pi_au_food`, `pi_au_energy`, `pi_au_core`, `pi_au_trad`, `pi_au_nontrad`, `pi_au_trim`) and 12 calibrated parameters (CPI weights from ABS Cat. 6401, tradeables share from RBA). Identity-preserving decomposition: pi_au ≡ Σ w_i·component_i to machine precision. Zero feedback into existing dynamics, so cached MCMC re-loaded with bit-identical Laplace/MHM. |
| Round 1.3 (REJECTED) | 2026-05-18 | (control −779.3032 vs candidate −781.1822) | **−1.88** | Cogley-Sbordone time-varying inflation attractor `+ delta_pibar·(pi_au(-1) − pibar_au(-1))` in eq_pibar_au, with `delta_pibar` estimated under Beta(0.07, 0.04) prior. Fresh 7.8-min csminwel mode search: posterior mode 0.024 (data pulls toward zero), Laplace LMD −781.18. Matched control with delta_pibar pinned at 0: Laplace LMD −779.30 (identical to cached baseline → confirms csminwel ≡ MCMC mode on this model). Result: data does not support time-varying anchor on the AU sample; parameter cost (1.88 nats) exceeds the tiny likelihood gain. Implied Bayes factor 0.15 in favor of the simpler model. Reverted. |
| **Repo cleanup** | 2026-05-18 | (Laplace preserved via fresh mode search) | n/a | Full retire of the Phase S architecture: deleted 8 Phase S `.mod` files (`au_pac`, `au_pac_bayesian`, `au_pac_var`, `au_pac_mce`, `au_pac_smooth`, `au_pac_recursive`, `au_pac_condforecast`, `au_pac_identification`), the legacy E-SAT satellite (`au_esat.mod`, `au_esat_est.mod`), 10 perturbation experiment .mods, the entire `dynare/scripts/` Phase S support tree (~38 .m files), 5 legacy top-level scripts (`make_paper_results.m`, `run_all.m`, `test_full_system.m`, `bayesian_estimate.m`, `download_data.m`, `esat_model.m`, `estimate_esat.m`), and `data/estimate_sigma_stage1.m`. Renamed `au_pac_v2.mod → au_pac.mod`, `au_pac_v2_bayesian.mod → au_pac_bayesian.mod`, and dropped `_v2` / `_phase_t` suffixes from saved artefacts. Updated [STATUS.md](STATUS.md), [README.md](README.md), [RUNNING.md](RUNNING.md), [ARCHITECTURE.md](ARCHITECTURE.md), [working paper](dynare/AUSPAC_WORKING_PAPER.md), [PRICE_RESPONSE_DIAGNOSIS.md](dynare/PRICE_RESPONSE_DIAGNOSIS.md). **Cached MCMC chains lost** (they lived in `+au_pac_v2_bayesian/metropolis/`, gitignored, removed with the v2 output dirs) — the estimation block in `au_pac_bayesian.mod` now defaults to `mode_compute=4` + `mh_replic=0` (fresh csminwel mode search, ~8 min); change `mh_replic=0 → 20000` to regenerate the full posterior chains (~50 min) and recover MHM. |
| **Rounds 4–8** (model extensions) | 2026-05-20 | (smoke-tested; new endo_nbr 175 vs old 164, new shocks 49 vs old 33) | n/a (calibrated) | Six concurrent model extensions added to the source `.inc` layer and patched into both production `.mod` files: **Round 4** foreign monetary policy (`i_us`, `ibar_us` + Taylor closure on US gaps; new params `lambda_ibar_us`, `i_ss_us`, `alpha_i_us`, `beta_i_us`); **Round 5** demographic trend gap `dln_pop_bar` AR(1) shifter into `eq_dln_n_star_bar` (new param `rho_pop`); **Round 6** tax structure decomposition with three gap variables `tau_GST_gap`, `tau_PAYG_gap`, `tau_CIT_gap` and their pass-through channels (GST → `eq_pi_c`, PAYG → `eq_dln_c_star_bar` ΔPAYG drag, CIT → `eq_uc_k` user-cost bump); **Round 7** market vs non-market VA decomposition (`yhat_market` / `yhat_nonmarket`, identity-preserving `yhat_au ≡ w_market·yhat_market + (1-w_market)·yhat_nonmarket` with `w_market = 0.85` per ABS Cat 5206); **Round 8** RBA-style auxiliary forecasters `BLR_hat`, `MAPI_hat`, `MAPU_hat` (one-way nowcast projections of i_lh, ph_gap, dln_ih). All gap variables are zero at SS (gap form); foreign rate has explicit SS at `i_ss_us = 0.625`. 11 new endogenous variables, 18 new parameters, 9 new shocks. None of the new shocks enters the existing 9-observable likelihood, so Laplace LMD is expected to be preserved at ≈ -779.30. |
| **Rounds 4–8 consolidation** | 2026-05-21 | (Laplace −779.29 / MHM −780.10 from fresh 20k×2-chain MCMC) | +0.01 / +0.26 nats | PR #6. The Round 4–8 work added structural equations but did not extend the per-block `var_model` companion matrices, so agents formed PAC expectations as if the new shocks did not exist. Four direct channels wired in: `aux_employment` ← `dln_pop_bar` with `a_n_pop = 1.0` (one-for-one passthrough into long-run employment target); `aux_consumption` ← `tau_PAYG_gap` with `a_c_PAYG = -0.10` (mirroring `alpha_PAYG` in eq_dln_c_star_bar); `aux_business_inv` ← `tau_CIT_gap` with `a_ib_CIT = -0.011` (≈ −σ_ces·α_CIT long-run elasticity) and `a_rKB_CIT = +0.02` (direct user-cost channel via rKB_hat); `aux_pQ` ← `tau_GST_gap` with `a_pQ_GST = 0.05` (indirect CPI→wages→VA pass-through). `phaseW_recherrypick.m` regenerated four new `h_pac_*_var_NEW_lag_1` policy-function coefficients (h_pac_n_pop = +0.124, h_pac_c_PAYG = -0.0096, h_pac_ib_CIT = -2.4e-4, h_pac_pQ_GST = +8.2e-4). Production `au_pac.mod` and `au_pac_bayesian.mod` surgically patched — no `aggregate()` re-run; all Phase U/V/W manual overrides preserved. Skipped: Round 4 (no AU PAC channel for `i_us`/`ibar_us`), Round 7 (identity from `yhat_au`, auto-projected), Round 8 (one-way nowcasters, no feedback). LMD preservation argument in working paper §4.11.2: new shocks not in `varobs` + zero historical realisations → `h_pac` × NEW(−1) terms vanish in the Kalman recursion → MHM bit-identical to cached baseline; the +0.26-nat MHM movement is within standard MHM Monte-Carlo noise. Fresh chains now authoritative cache. |
| **Round 1.2** (HtM income channel) | 2026-05-22 | (Laplace −784.47 / MHM −785.80 from fresh 20k×2-chain MCMC) | **−5.19 / −5.70 nats (worse)** | PR #8. Hand-to-mouth wage+transfer income channel from FR-BDF wp1044 §3.5.1 eq 35: `+ b_HtM*(wt_H_real_gap - yhat_au)` added contemporaneously to consumption PAC short-run equation, with `b_HtM = 0.32` calibrated from FR-BDF posterior. Data pipeline: ABS 5206 Table 20 (Household Income) + Table 23 (Social Assistance) downloaded; `data/prepare_household_income.m` constructs `au_wt_H_real_gap` from `(W_H + TG_H) / p_C` HP-gap. Series captures GFC stimulus +4.0% (2008Q4) and JobKeeper +3.2% (2020Q3). Structural state `wt_H_real_gap` added as new var_model state in aux_consumption.mod + structural identity layer; channel applied in production model rather than aux file (Dynare 6.5 pac.print() crashes if var_model state appears in aux PAC equation RHS). **Negative empirical result.** The fresh MCMC under Round 1.2 returns MHM = -785.80 vs the Round 4-8 baseline of -780.10 — a 5.7-nat penalty. Posterior consumption-PAC parameters barely shifted (b0_c 0.054 → 0.054, b2_c -0.33 → -0.41, b3_c 0.022 → 0.029), so the data didn't "compensate" for the new channel; it just absorbed the calibrated `b_HtM` as a misspecified addition. The channel as calibrated does not improve fit on AU data. **Recommended follow-up**: promote `b_HtM` to estimated_params with N(0.30, 0.10) prior so the data can pull it toward zero if appropriate; or add `au_wt_H_real_gap` to `varobs` so the model can use the empirical series directly rather than predicting it as a latent state. The structural plumbing (wt_H_real_gap state, eps_wtH shock, data column, production .mod patches) is in place; only the calibration value of `b_HtM` needs revision. |

**Cumulative Phase Q → Rounds 4–8 consolidation MHM improvement: +22.17 nats** (the +0.26-nat 2026-05-21 movement is within MHM Monte-Carlo noise but is included for completeness).

### Notable v3.1 architecture (post-audit)

1. **Single canonical VA-price target after Phase Y.** Pre-Phase-Y, AUSPAC carried both `eq_piQ_star` (analytical CES factor-price-frontier target using ULC and user-cost-of-capital) and `piQ_hat` (PAC aux regression onto E-SAT state) as parallel VA-price target objects. A triple-check audit identified `eq_piQ_star` and its dependents as orphaned diagnostics — never referenced on the RHS of any other equation. Phase Y removed them; the model now uses a single target (`piQ_hat`) matching FR-BDF and ECB-BASE practice. The CES dual factor-price frontier remains the theoretical reference (working paper §4.3.1) but is no longer a coded equation.

2. **`calibration.inc` Bayesian posteriors are active (Phase W).** The Phase B (2026-05-09) Bayesian posterior modes for 24 auxiliary-regression coefficients (`rho_pQ_aux`, `a_pQ_y/i/pi/u`, the consumption/employment/investment analogues, the `rho_yh_aux`/`a_yh_*` projection, `rho_rKB_aux`/`a_rKB_i`) are now active at runtime. Pre-Phase-W they were dead-letter because no .mod file `@#include`d `calibration.inc`. The fix was two-stage: runtime override block at the end of the production .mod calibration sections (Dynare uses last-assignment-wins), plus re-templated aux .mod files with re-cherrypicked `h_pac_*` policy-function coefficients so the projection is self-consistent with the new `*_hat` dynamics. Largest movement: `h_pac_pQ_var_piQ_hat_lag_1` shrank ~10× (from 0.0071 to 0.00069) reflecting the much shorter projection horizon under `rho_pQ_aux=0.334` vs the prior 0.85.

3. **Three AU-specific architectural deviations from FR-BDF, now documented in the working paper §8**:
   - **Domestic-demand feedback** `λ_dom·ŷ^dom_t` in the IS curve (model.inc:17) — closes the Keynesian multiplier loop; no FR-BDF analogue; Bayesian posterior `λ_dom = 0.40` (4× prior mean, indicating strong data support).
   - **Phase V Phillips-curve additions**: lagged VA-price passthrough `α_pc_lag·(π^Q_{t-1} − π̄^au_{t-1})` and ECM correction `b_ECM_pc·(p^{C,*}_{t-1} − p^C_{t-1})` in `eq_au_phillips`. The ECM term substitutes for the long-run anchoring that would otherwise have been lost when the demand-deflator block was collapsed (next point).
   - **Demand-deflator reduced-form collapse**: 6 demand deflators (`eq_pi_c`, `eq_pi_ib`, `eq_pi_ih`, `eq_pi_x`, `eq_pi_m`, `eq_pi_g`) implemented as single-equation AR(1)+cost-push rather than FR-BDF's two-equation target+ECM. Deliberate simplification for AU estimation tractability (128 quarters of data); long-run anchoring relocated to the Phillips curve via the `b_ECM_pc` term above.

4. **Wage Phillips slope `κ_w` identifies with correct (FR-BDF) sign**: −0.103 with 90% HPD entirely negative [−0.178, −0.019]. Under the FR-BDF eq. (52) convention `... − κ_w · pv_u_gap`, this is a *positive* structural Phillips slope (higher unemployment → lower wage growth).

5. **Cost-push transmission structurally complete**: `eps_pQ` raises `piQ` on impact (+0.57 qpp); piQ propagates into `pi_au` via the Phase S structural deflator channels (+0.119 qpp impact); the Taylor rule begins tightening by Q5; the output gap turns negative around Q8. The residual modest-positive ln_Q response throughout the IRF window is a substantive AU finding (very high RBA policy smoothing `λ_i = 0.96` + AU-estimated weak piQ → CPI passthrough `α_pc = 0.20` after Phase V re-estimate), not a model artefact.

6. **Forward-guidance puzzle absence preserved**: AU-PAC ratio = 10.14 at N=12 (standard NK saturates at 1.79; linear reference is 12.0). Within ±1% across the entire Phase R → Y refit history.

7. **Two-layer architecture solved (Phase T)**: Phase Q–S inherited the FRB/US shadow-VAR workaround for Dynare's pure-VAR constraint on `var_model` equations. Phase T adopts the official Dynare semi-structural workflow (Adjemian; matches FR-BDF wp1044 §3.2.3): aux files compute the policy function via `pac.print()`, `cherrypick()` extracts simulation-ready equations, `aggregate()` combines them with structural identities into the production .mod. Structural shocks now flow into forward PAC expectations via lagged structural-variable terms in the closed-form expectation formulas.

---

## Repository layout

```
AUSPAC/
├── README.md                          repo entry point
├── RUNNING.md                         MATLAB run instructions
├── STATUS.md                          (you are here) project status, v3.1
├── NEXT_STEPS_PLAN.md                 ★ priority roadmap for v3.2 development
├── ARCHITECTURE.md                    developer code map
├── make_paper_results.m               top-level reproduction driver
├── references/                        FR-BDF wp736 + wp1044, ECB-BASE, RBA monetary transmission
├── data/                              raw ABS + RBA + FRED + BIS series
│
└── dynare/                            models, scripts, outputs
    ├── au_pac.mod                     production model (164 endo, 33 exo shocks)
    ├── au_pac_bayesian.mod            Bayesian-estimation variant of au_pac.mod
    ├── aux/                           5 aux files for PAC expectations (Phase W posteriors active)
    │   ├── _template_helpers.py
    │   └── aux_pQ.mod / aux_consumption.mod / aux_business_inv.mod / aux_housing_inv.mod / aux_employment.mod
    ├── simulation/
    │   ├── identities/                source-of-truth .inc files (endo, params, model, steady, shocks)
    │   └── estimation/                cherrypick outputs per PAC block (5 subdirs)
    │
    ├── phaseW_recherrypick.m          ★ driver: re-runs dynare + cherrypick on all 5 aux files
    │                                  (use after aux file calibration changes)
    ├── setup_dynare_path.m            locates Dynare 6.5 install
    │
    ├── nk_simple.mod / nk_discounted.mod   reference NK models for FG puzzle test (paper §6.5)
    │
    ├── AUSPAC_WORKING_PAPER.md         the working paper (~2000 lines, 9 sections + 6 appendices)
    ├── mcmc_posterior_table.md         Bayesian posterior table (paper Table 5.6 source)
    ├── phase_r_benchmark_table.md      Phase R IRF benchmark vs FR-BDF (paper §6.3.5)
    ├── forecast_eval_table.md          §5.5 recursive forecast RMSEs
    ├── au_pac_model_data_README.md     dataset conventions
    ├── prepare_pac_dseries_README.md   dseries preparation conventions
    │
    ├── saved_irfs.mat                  current production IRFs
    ├── saved_irfs_{var,hybrid,mce}.mat already-baked Phase S three-regime IRFs (paper §§6.2/6.3 figures)
    ├── forward_guidance_puzzle.png     FG puzzle test figure
    │
    ├── regen/                          Python figure regen helpers (read pre-baked .mats; no Dynare needed)
    └── tools/                          Python data tools (build, splice, sanity checks, writeback)
```

---

## Reproducing v3.1 results

### Full estimation pipeline (~55 min)

```matlab
cd dynare; setup_dynare_path();
addpath(genpath('/Applications/Dynare/6.5-x86_64/matlab/missing'));   % for rows()

% Step 1: per-PAC-block aux file estimation + cherrypick
%         Use phaseW_recherrypick.m as a one-shot driver — it runs dynare
%         on each aux/aux_X.mod and cherrypicks to simulation/estimation/<block>/
run('phaseW_recherrypick.m');

% Step 2: aggregate into single .mod (only needed if you've modified
%         simulation/identities/ or the cherrypicked .inc files structurally;
%         pure parameter-value refreshes via Phase W's `patch_h_pac.py` style
%         don't require re-aggregation)
aggregate('au_pac.mod', {'stochastic,json=compute'}, pwd, ...
    'simulation/estimation/pQ', 'simulation/estimation/consumption', ...
    'simulation/estimation/business_inv', 'simulation/estimation/housing_inv', ...
    'simulation/estimation/employment', 'simulation/identities');

% Step 3: after re-aggregate, re-add the Phase U/V/W manual override blocks
%         at the end of au_pac.mod (see lines 1421–1500 area), the shocks
%         block, the steady_state_model block, and the stoch_simul block.

% Step 4: estimate
dynare au_pac_bayesian;          % ~50 min on Apple Silicon under Rosetta 2

% Step 5: regen IRFs
dynare au_pac;
```

### Quick load-cached MCMC (~30 sec)

```matlab
dynare au_pac_bayesian   % uses mode_compute=0 + load_mh_file
                            % loads cached MCMC, recomputes summary statistics
```

### Figure-only refresh from saved artefacts (no Dynare needed)

```bash
pip install scipy matplotlib h5py
python3 dynare/regen/regen_three_regime_figs.py     # uses saved_irfs_{var,hybrid,mce}.mat
python3 dynare/regen/regen_pac_contrib_figs.py
python3 dynare/regen/regen_section5_irfs.py
python3 dynare/regen/regen_long_run_convergence.py
python3 dynare/regen/regen_app_experiment.py
```

---

## Audit trail (2026-05-17)

A triple-check audit of FR-BDF vs AUSPAC price equations was completed 2026-05-17. Findings and resolutions:

| Audit finding | Resolution |
|---|---|
| `calibration.inc` orphaned — 24 aux-regression posteriors dead-letter at runtime | ✅ Phase W (runtime override + aux retemplate + re-cherrypick); +0.92 nats MHM |
| `rho_pi_m` (aux) vs `rho_pm` (model.inc) name drift | ✅ Phase X (renamed + unified value); neutral LMD |
| Dual VA-price target (analytical `eq_piQ_star` + PAC `piQ_hat`) | ✅ Phase Y (orphan equations removed; single canonical target) |
| Demand-deflator collapse + `b_ECM_pc` + `λ_dom` AU innovations undocumented | ✅ Working paper §3.1, §4.4.0, §4.9, §8 updated |

The audit concluded with no remaining open audit items. The next development priorities are in [`NEXT_STEPS_PLAN.md`](NEXT_STEPS_PLAN.md).

---

## Open items

The full development roadmap is in [`NEXT_STEPS_PLAN.md`](NEXT_STEPS_PLAN.md). High-level summary:

### Round 1 — low-risk additions (~4 weeks total)
HICP-style reporting block; direct wage+transfer income channel in consumption (wp1044 eq 35); time-varying inflation attractor (ECB-BASE Cogley-Sbordone); PV² operator in consumption (wp1044); quasi-endogenous employment target with trend+gap expectation split (wp1044).

### Round 2 — high-leverage architectural addition (~6–8 weeks)
Energy index (oil + gas split, wp1044 Appx E); **credit/financial-asset block** (wp1044 §3.7.2–3.7.3 — fully new; absent from wp736).

### Round 3 — conditional (only if research priorities pivot)
WAPRO-style MCE wage-price subsystem (ECB-BASE §3.2.3) for forward-guidance / unconventional-policy research.

### v3.x finishing tasks (small, when convenient)
- Rewrite working paper §§6.2.1–6.2.4 channel walkthrough under the Phase T single-regime architecture (currently retained as Phase S Hybrid historical reference per §6.2 intro note)
- Optionally rebuild `au_pac_var.mod` / `au_pac_mce.mod` under the Phase T architecture if separate regime comparisons are needed (the Phase S variants and their support scripts were retired in the 2026-05-18 cleanup; the paper's §6.2 figures still regenerate from the saved `saved_irfs_{var,hybrid,mce}.mat` artefacts via `dynare/regen/regen_three_regime_figs.py`)

---

## References

| Source | Where |
|---|---|
| FR-BDF wp736 (Lemoine et al., 2019) | [`references/wp736.pdf`](references/wp736.pdf) — the original architecture |
| FR-BDF wp1044 update (Dubois et al., 2026) | [`references/FR-BDF-update.pdf`](references/FR-BDF-update.pdf) — §2.2 estimation approach, §3.2.3 policy function, §3.7 credit block (new), §3.6.4 HICP block (new) |
| ECB-BASE (Angelini et al., 2019, ECB WP 2315) | [`references/ecb-base.pdf`](references/ecb-base.pdf) — WAPRO MCE subsystem; HICP decomposition; alternative VAR-augmentation architecture |
| RBA monetary transmission survey (Mulqueeney, Ballantyne, Hambur 2025) | [`references/RBA_mon_transmission.pdf`](references/RBA_mon_transmission.pdf) — used for §6.2.4 comparison |
| Dynare semi-structural forum thread (Brayton + Adjemian, 2024) | https://forum.dynare.org/t/semi-structural-models-in-dynare/24754 — official cherrypick/aggregate workflow |
| srecko/SemiStructDynareBasics (Zimic, 2023) | https://gitlab.com/srecko/SemiStructDynareBasics — ECB-BASE reference implementation |

---

## Citation

> Stephan, D. (2026). *AU-PAC: A Semi-Structural Macroeconomic Model for Australia.* Working paper, v3.1. https://github.com/DavidAStephan/AUSPAC
>
> Lemoine, M., Turunen, H., Chahad, M., Lepetit, A., Zhutova, A., Aldama, P., Clerc, P., and Laffargue, J.-P. (2019). *The FR-BDF Model and an Assessment of Monetary Policy Transmission to the French Economy.* Banque de France WP No. 736.
>
> Dubois, U., Ducoudré, B., Martin, R., Petronevich, A., Seghini, C., Thubin, C., and Turunen, H. (2026). *Re-estimated FR-BDF: New Features and an Assessment of Monetary Policy Tightening in France.* Banque de France WP No. 1044.
>
> Angelini, E., Bokan, N., Christoffel, K., Ciccarelli, M., and Zimic, S. (2019). *Introducing ECB-BASE: The blueprint of the new ECB semi-structural model for the euro area.* ECB Working Paper Series No. 2315.

---

## Licence

Code: MIT (see [LICENSE](LICENSE) if present). Data: original ABS / RBA / BIS / FRED licences apply.
