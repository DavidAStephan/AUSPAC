# AUSPAC — Project status

**Version**: v3.1 (tagged 2026-05-17, branch `fix/cross-platform-paths`)
**Architecture**: Phase T policy-function PAC expectations (FR-BDF wp1044 §2.2 / Adjemian-Brayton-Zimic), with Phases W/X/Y architectural cleanup completed.
**Headline metric**: MHM log marginal density = **−780.47** (Laplace = **−779.30**). Cumulative Phase Q → Phase Y MHM improvement: **+21.80 nats**.

---

## What v3.1 is

AUSPAC is the Australian replication of FR-BDF (Banque de France WP #736 Lemoine et al., 2019; updated 2026 in WP #1044 Dubois et al.). It is a semi-structural macroeconomic model with Polynomial Adjustment Costs (PAC), explicit expectations from a structural-VAR satellite (E-SAT), and a CES supply block re-estimated on Australian data 1994Q1–2025Q4.

**Production model**: [`dynare/au_pac_v2.mod`](dynare/au_pac_v2.mod) — built via Dynare's `cherrypick()` + `aggregate()` workflow from:
- 5 aux .mod files in [`dynare/aux/`](dynare/aux/) (one per PAC block: pQ, consumption, business_inv, housing_inv, employment)
- 7 normalized identity .inc files in [`dynare/simulation/identities/`](dynare/simulation/identities/)
- 5 cherrypicked .inc bundles in [`dynare/simulation/estimation/<block>/`](dynare/simulation/estimation/)

**Bayesian estimation**: [`dynare/au_pac_v2_bayesian.mod`](dynare/au_pac_v2_bayesian.mod), 28 estimated parameters, ~50 min wall time per 20k×2-chain MCMC, current Laplace LMD = **−779.30**, MHM = **−780.47**.

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

**Cumulative Phase Q → Phase Y MHM improvement: +21.80 nats.**

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
    ├── au_pac_v2.mod                  v3.1 production model
    ├── au_pac_v2_bayesian.mod         v3.1 Bayesian estimation model
    ├── aux/                           5 aux files for PAC expectations (Phase W posteriors active)
    │   ├── _template_helpers.py
    │   ├── aux_pQ.mod / aux_consumption.mod / aux_business_inv.mod / aux_housing_inv.mod / aux_employment.mod
    ├── simulation/
    │   ├── identities/                normalized .inc files + 3 Python normalizers
    │   └── estimation/                populated by cherrypick (5 subdirs)
    │
    ├── phaseW_recherrypick.m          ★ driver: re-runs dynare + cherrypick on all 5 aux files
    │                                  (use after aux file calibration changes)
    │
    ├── au_pac.mod / au_pac_var.mod / au_pac_mce.mod
    │                                  Phase S three-regime variants (preserved for paper §§6.2.1–6.2.4)
    ├── au_pac_bayesian.mod / au_pac_smooth.mod / au_pac_recursive.mod
    ├── au_pac_condforecast.mod / au_pac_identification.mod
    │                                  Phase S support models (preserved)
    │
    ├── AUSPAC_WORKING_PAPER.md         the working paper (~2000 lines, 9 sections + 6 appendices)
    ├── mcmc_posterior_table_phase_t.md Phase T posteriors (Table 5.6 source; superseded by Phase W posteriors)
    ├── phase_r_benchmark_table.md      Phase R IRF benchmark vs FR-BDF (paper §6.3.5)
    ├── forecast_eval_table.md          Section 5.5 recursive forecast RMSEs
    ├── au_pac_model_data_README.md     dataset conventions
    ├── prepare_pac_dseries_README.md   dseries preparation conventions
    │
    ├── saved_irfs_v2_phase_t.mat       Phase T/W IRFs (current production)
    ├── saved_irfs_{var,hybrid,mce}.mat  Phase S IRFs (paper §§6.2/6.3 figures)
    ├── forward_guidance_puzzle_v2.png  Phase T FG test figure
    │
    ├── scripts/                        estimation / figures / analysis / data_prep / tests
    ├── regen/                          Python figure regen helpers
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
aggregate('au_pac_v2.mod', {'stochastic,json=compute'}, pwd, ...
    'simulation/estimation/pQ', 'simulation/estimation/consumption', ...
    'simulation/estimation/business_inv', 'simulation/estimation/housing_inv', ...
    'simulation/estimation/employment', 'simulation/identities');

% Step 3: after re-aggregate, re-add the Phase U/V/W manual override blocks
%         at the end of au_pac_v2.mod (see lines 1421–1500 area), the shocks
%         block, the steady_state_model block, and the stoch_simul block.

% Step 4: estimate
dynare au_pac_v2_bayesian;          % ~50 min on Apple Silicon under Rosetta 2

% Step 5: regen IRFs and figures
dynare au_pac_v2;
run('scripts/analysis/forward_guidance.m');   % FG puzzle test
```

### Quick load-cached MCMC (~30 sec)

```matlab
dynare au_pac_v2_bayesian   % uses mode_compute=0 + load_mh_file
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
- Rewrite working paper §§6.2.1–6.2.4 channel walkthrough under Phase T single-regime architecture (currently retained as Phase S Hybrid historical reference per §6.2 intro note)
- Optionally build `au_pac_v2_var.mod` / `au_pac_v2_mce.mod` if separate regime comparisons are needed under Phase T
- Optionally retire legacy `au_pac.mod` + 7 Phase S variants if the project commits to Phase T as the sole architecture

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
