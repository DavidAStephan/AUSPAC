# AUSPAC — Project status

**Version**: v3.0 (tagged 2026-05-16, branch `fix/cross-platform-paths`)
**Architecture**: Phase T policy-function PAC expectations (FR-BDF wp1044 §2.2 / srecko / Brayton)
**Headline metric**: MHM log marginal density = **−780.47** (+0.92 nats vs Phase T MHM; Laplace = **−779.30**, +1.75 nats vs Phase T Laplace). Cumulative Phase Q → Phase W MHM improvement: **+21.58 nats**.

---

## What v3.0 is

AUSPAC is the Australian replication of FR-BDF (Banque de France WP #736 Lemoine et al., 2019; updated 2026 in WP #1044 Dubois et al.). It is a semi-structural macroeconomic model with Polynomial Adjustment Costs (PAC), explicit expectations from a structural-VAR satellite (E-SAT), and a CES supply block re-estimated on Australian data 1994Q1–2025Q4.

**Production model**: [`dynare/au_pac_v2.mod`](dynare/au_pac_v2.mod) — built via Dynare's `cherrypick()` + `aggregate()` workflow from:
- 5 aux .mod files in [`dynare/aux/`](dynare/aux/) (one per PAC block: pQ, consumption, business_inv, housing_inv, employment)
- 7 normalized identity .inc files in [`dynare/simulation/identities/`](dynare/simulation/identities/)
- 5 cherrypicked .inc bundles in [`dynare/simulation/estimation/<block>/`](dynare/simulation/estimation/)

**Bayesian estimation**: [`dynare/au_pac_v2_bayesian.mod`](dynare/au_pac_v2_bayesian.mod), 28 estimated parameters, ~51 min wall time, Laplace LMD = **−781.05**, MHM = **−781.39**.

**Working paper**: [`dynare/AUSPAC_WORKING_PAPER.md`](dynare/AUSPAC_WORKING_PAPER.md) — Table 5.6 has Phase T posteriors, Table 6.3 has Phase T monetary IRF, §4.4.0a describes the policy-function architecture.

---

## Phase trajectory and headline results

| Phase | Date | MHM LMD | Δ | Architectural / structural change |
|---|---|---|---|---|
| Phase Q | 2026-05-15 | −802.27 | baseline | Forward-NPV UIP `pv_i_uip` |
| Phase R | 2026-05-15 | −790.72 | +11.55 | Wage Phillips CPI indexation; employment-target Δq + dln_tfp signs; consumption `pv_r_lh_gap` real-rate channel |
| Phase S | 2026-05-16 | −789.10 | +1.62 | FR-BDF cost-push replication via structural deflator channels in `eq_au_phillips` |
| **Phase T (v3.0)** | 2026-05-16 | **−781.39** | **+7.71** | **srecko/FR-BDF aggregate workflow — policy-function PAC expectations replace shadow-VAR `pac_expectation()` calls** |
| **Phase W** | 2026-05-17 | **−780.47** | **+0.92** | **Self-consistent activation of `calibration.inc` Bayesian-posterior aux-regression coefficients.** Two-part fix: (i) runtime override block at [au_pac_v2.mod:1429](dynare/au_pac_v2.mod#L1429) and [au_pac_v2_bayesian.mod:708](dynare/au_pac_v2_bayesian.mod#L708) for the 24 `rho_*_aux`/`a_*_y/i/pi/u/yh` parameters (the `*_hat` variable processes); (ii) re-templated [aux/aux_*.mod](dynare/aux/) and re-ran `dynare`+`cherrypick` for each of 5 PAC blocks, refreshing the 73 `h_pac_*` policy-function coefficients computed by `pac.print()`. Partial fix (runtime override only) gave +0.77 nats Laplace; full fix (h_pac_* refresh) added another +0.97 nats Laplace. Fresh 20k×2-chain MCMC (47.6 min) confirms MHM gain of +0.92 nats; Laplace gain of +1.75 nats. |

**Cumulative Phase Q → Phase W MHM improvement: +21.58 nats.**

### Notable v3.0 findings

1. **Wage Phillips slope `κ_w` identifies with correct (FR-BDF) sign for the first time**: −0.103 with 90% HPD entirely negative [−0.178, −0.019]. Under FR-BDF eq. (52) convention `... − κ_w · pv_u_gap`, this corresponds to a *positive* structural Phillips slope (higher unemployment → lower wage growth). Phases R and S had κ_w straddling zero — the labour-market slack channel could not be distinguished from CPI indexation under the shadow-decoupled architecture.

2. **Cost-push transmission now structurally complete**: `eps_pQ` raises `piQ` on impact (+0.57 qpp); piQ then propagates into `pi_au` via the Phase S structural deflator channels (+0.119 qpp impact); the Taylor rule begins tightening by Q5; the output gap turns negative around Q8. The residual modest-positive ln_Q response throughout the IRF window is a substantive AU finding (very high RBA policy smoothing λ_i = 0.96 + AU-estimated weak piQ → CPI passthrough α_pc = 0.17), not a model artefact.

3. **Forward-guidance puzzle absence preserved**: AU-PAC ratio = 10.14 at N=12 (standard NK saturates at 1.79; linear reference is 12.0). Within ±1% across the entire Phase R → S → T refit history.

4. **Two-layer architecture solved**: Phase Q–S inherited the FRB/US shadow-VAR workaround for Dynare's pure-VAR constraint on `var_model` equations. Phase T adopts the official Dynare semi-structural workflow (Stéphane Adjemian; matches FR-BDF wp1044 §3.2.3): aux files compute the policy function via `pac.print()`, `cherrypick()` extracts simulation-ready equations, `aggregate()` combines them with structural identities into the production .mod. Structural shocks now flow into forward PAC expectations via lagged structural-variable terms in the closed-form expectation formulas.

5. **Phase W — orphaned `calibration.inc` activated, then fully consistent (2026-05-17)**: surfaced by a triple-check audit of FR-BDF vs AUSPAC price equations. The Phase T workflow had two parallel sources of truth for the 24 auxiliary-regression parameters (`rho_pQ_aux`, `a_pQ_y/i/pi/u`, the consumption/employment/investment analogues, the `rho_yh_aux`/`a_yh_*` projection, and `rho_rKB_aux`/`a_rKB_i`): the aux .mod files carried Phase S OLS placeholders, while `simulation/identities/calibration.inc` carried the Phase B Bayesian posterior modes — but no `.mod` file ever `@#include`d `calibration.inc`, so the placeholders won at runtime. Largest gap: `rho_pQ_aux` ran at 0.85 vs posterior 0.334 (2.5× too persistent); `a_pQ_{i,pi,u}` ran at zero vs nonzero posteriors. Fix in two stages: **(stage 1, +0.77 nats Laplace)** runtime override block at end of `au_pac_v2.mod` / `au_pac_v2_bayesian.mod` calibration sections (Dynare uses last-assignment-wins) — corrects the `*_hat` variable processes but leaves `h_pac_*` policy-function coefficients computed against the old VAR. **(stage 2, +0.97 nats Laplace on top of stage 1)** re-templated [dynare/aux/aux_*.mod](dynare/aux/) calibration blocks from the same posteriors, re-ran `dynare`+`cherrypick` for all 5 PAC blocks via [phaseW_recherrypick.m](dynare/phaseW_recherrypick.m), and patched the 73 refreshed `h_pac_*` coefficients into the production .mod files. **(stage 3 — verification)** fresh 20k×2-chain MCMC (47.6 min wall time) under the new self-consistent calibration: Laplace LMD = −779.30 (+1.75 nats vs Phase T); MHM LMD = **−780.47** (+0.92 nats vs Phase T). Largest h_pac_* movement: `h_pac_pQ_var_piQ_hat_lag_1` shrank ~10× (from 0.0071 to 0.00069) reflecting the much shorter projection horizon under `rho_pQ_aux=0.334` vs 0.85.

---

## Repository layout

```
AUSPAC/
├── README.md                          repo entry point
├── RUNNING.md                         MATLAB run instructions
├── STATUS.md                          (you are here) project status, v3.0
├── make_paper_results.m               top-level reproduction driver
├── references/                        FR-BDF wp736 + wp1044, RBA monetary transmission
├── data/                              raw ABS + RBA + FRED + BIS series
│
└── dynare/                            models, scripts, outputs
    ├── au_pac_v2.mod                  ★ v3.0 production model (Phase T)
    ├── au_pac_v2_bayesian.mod         ★ v3.0 Bayesian estimation model
    ├── aux/                           ★ 5 aux files for PAC expectations
    │   ├── _template_helpers.py
    │   ├── aux_pQ.mod / aux_consumption.mod / aux_business_inv.mod / aux_housing_inv.mod / aux_employment.mod
    ├── simulation/
    │   ├── identities/                ★ normalized .inc files + 3 Python normalizers
    │   └── estimation/                ★ populated by cherrypick (5 subdirs)
    │
    ├── au_pac.mod / au_pac_var.mod / au_pac_mce.mod
    │                                  Phase S three-regime variants (preserved for paper §§6.2.1–6.2.4)
    ├── au_pac_bayesian.mod / au_pac_smooth.mod / au_pac_recursive.mod
    ├── au_pac_condforecast.mod / au_pac_identification.mod
    │                                  Phase S support models (preserved)
    │
    ├── AUSPAC_WORKING_PAPER.md         the working paper (~1960 lines, 9 sections + 6 appendices)
    ├── mcmc_posterior_table_phase_t.md ★ Phase T posteriors (Table 5.6 source)
    ├── phase_r_benchmark_table.md      Phase R IRF benchmark vs FR-BDF (referenced by paper §6.3.5)
    ├── forecast_eval_table.md          Section 5.5 recursive forecast RMSEs
    ├── au_pac_model_data_README.md     dataset conventions
    ├── prepare_pac_dseries_README.md   dseries preparation conventions
    │
    ├── saved_irfs_v2_phase_t.mat       ★ Phase T IRFs
    ├── saved_irfs_{var,hybrid,mce}.mat  Phase S IRFs (used by paper §§6.2/6.3 figures)
    ├── forward_guidance_puzzle_v2.png  ★ Phase T FG test figure
    │
    ├── scripts/                        estimation / figures / analysis / data_prep / tests
    ├── regen/                          Python figure regen helpers
    └── tools/                          Python data tools (build, splice, sanity checks, writeback)
```

★ = added in v3.0 (Phase T)

---

## Reproducing v3.0 results

### Full estimation pipeline (~55 min)

```matlab
cd dynare; setup_dynare_path();
addpath(genpath('/Applications/Dynare/6.5-x86_64/matlab/missing'));   % for rows()

% Step 1: per-PAC-block aux file estimation (cherrypick to simulation/estimation/<block>/)
% (one-time setup; rerun only if aux structure changes)
for blk = {'pQ','consumption','business_inv','housing_inv','employment'}
    eval(sprintf('dynare aux/aux_%s', blk{1}));
    cherrypick(sprintf('aux_%s', blk{1}), sprintf('simulation/estimation/%s', blk{1}), ...);
end

% Step 2: aggregate into single .mod
aggregate('au_pac_v2.mod', {'stochastic,json=compute'}, pwd, ...
    'simulation/estimation/pQ', 'simulation/estimation/consumption', ...
    'simulation/estimation/business_inv', 'simulation/estimation/housing_inv', ...
    'simulation/estimation/employment', 'simulation/identities');

% Step 3: append steady_state_model + shocks + stoch_simul (or copy au_pac_v2_bayesian.mod
%         shape for estimation)

% Step 4: estimate
dynare au_pac_v2_bayesian;          % ~51 min on Apple Silicon under Rosetta 2

% Step 5: regen IRFs and figures
dynare au_pac_v2;
run('scripts/analysis/forward_guidance.m');   % FG puzzle test
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

## Open items

### Phase 5 substantive research extensions (deferred from audit, multi-week each)

These are economic-content extensions, not architectural fixes:

- **Foreign rate `i_us`** — add Fed funds rate + ibar_us to E-SAT for proper US IS real-rate channel and UIP foreign-rate term (audit #8, #42)
- **Energy / non-energy import split** — separate AU energy import deflator from non-energy (audit #33, #37)
- **Branch decomposition** — market vs non-market value-added split, ABS Cat. 5204 industry-level (audit #45)
- **Tax structure decomposition** — explicit GST / PAYG / company-tax effective rates × bases (audit #46)
- **Demographic trends** — `POP̄_t` from ABS 6202 for labour-force projection (audit #43)
- **BLR / MAPI / MAPU auxiliary forecasters** — for real RBA-style forecasting use vs current academic-replication scope (audit #48)
- **APP experiment expansion** — match FR-BDF Table 6.4.2 TP vs ER channel decomposition (audit #58)
- **Phase K final piece** — `b_di_c` clean identification via RBA OIS surprises (Bishop–Tulip RDP 2017-08); currently Bayesian-regularised at −0.701

### v3.x finishing tasks (small, when convenient)

- Rewrite working paper §§6.2.1–6.2.4 channel walkthrough under Phase T single-regime architecture (currently retained as Phase S Hybrid historical reference per §6.2 intro note)
- Optionally build `au_pac_v2_var.mod` / `au_pac_v2_mce.mod` if separate regime comparisons are needed under Phase T
- Optionally retire legacy `au_pac.mod` + 7 Phase S variants if the project commits to Phase T as the sole architecture

---

## References

| Source | Where |
|---|---|
| FR-BDF wp736 (Lemoine et al., 2019) | [`references/wp736.pdf`](references/wp736.pdf) — the original architecture |
| FR-BDF wp1044 update (Dubois et al., 2026) | [`references/FR-BDF-update.pdf`](references/FR-BDF-update.pdf) — §2.2 estimation approach, §3.2.3 policy function via E-SAT inversion |
| RBA monetary transmission survey (Mulqueeney, Ballantyne, Hambur 2025) | [`references/RBA_mon_transmission.pdf`](references/RBA_mon_transmission.pdf) — used for §6.2.4 comparison |
| Dynare semi-structural forum thread (Brayton + Adjemian, 2024) | https://forum.dynare.org/t/semi-structural-models-in-dynare/24754 — official cherrypick/aggregate workflow |
| srecko/SemiStructDynareBasics (Zimic, 2023) | https://gitlab.com/srecko/SemiStructDynareBasics — ECB-Base reference implementation |

---

## Citation

> Stephan, D. (2026). *AU-PAC: A Semi-Structural Macroeconomic Model for Australia.* Working paper, v3.0. https://github.com/DavidAStephan/AUSPAC
>
> Lemoine, M., Turunen, H., Chahad, M., Lepetit, A., Zhutova, A., Aldama, P., Clerc, P., and Laffargue, J.-P. (2019). *The FR-BDF Model and an Assessment of Monetary Policy Transmission to the French Economy.* Banque de France WP No. 736.
>
> Dubois, U., Ducoudré, B., Martin, R., Petronevich, A., Seghini, C., Thubin, C., and Turunen, H. (2026). *Re-estimated FR-BDF: New Features and an Assessment of Monetary Policy Tightening in France.* Banque de France WP No. 1044.

---

## Licence

Code: MIT (see [LICENSE](LICENSE) if present). Data: original ABS / RBA / BIS / FRED licences apply.
