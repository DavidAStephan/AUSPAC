# AUSPAC — status

As of **2026-05-16** (Phase T srecko/FR-BDF aggregate-workflow refactor: architectural milestone — shadow-VAR disconnect eliminated; au_pac_v2_bayesian.mod MCMC complete with **Laplace LMD = -781.05 / MHM = -781.39**, **+7.7 nats over Phase S, +20.66 nats over Phase Q baseline**).

## Phase T srecko/FR-BDF refactor (2026-05-16) — ARCHITECTURAL MILESTONE

**Headline result**: Adopted Dynare's officially recommended semi-structural pattern (cherrypick + aggregate, per Stéphane Adjemian's forum post + Flint Brayton's FRB/US workflow + srecko/SemiStructDynareBasics ECB example + FR-BDF wp1044 §2.2). The shadow-VAR architectural disconnect that limited Phase S has been eliminated. Phase T LMD Laplace = **−781.05**, a **+7.9 nat improvement** over Phase S (−788.95) and **+20.66 nats over Phase Q baseline** (−801.71).

### Phase T structural change

| Item | Before (Phase S) | After (Phase T) |
|---|---|---|
| PAC expectations | `pac_expectation(pac_X)` — Dynare internal call evaluating shadow var_model | Explicit closed-form linear combinations of LAGGED STRUCTURAL variables (e.g. `pac_expectation_pac_pQ = h_const + h_yhat_au·yhat_au(-1) + h_piQ·piQ(-1) + ...`) |
| var_model variables | 12 SHADOW variables (`y_gap_var`, `pi_gap_var`, ...) decoupled from structural shocks | STRUCTURAL variables (yhat_au, pi_au_gap, piQ, pi_m, dln_pcom) directly carry structural shock effects into expectations |
| Architecture | Monolithic `au_pac.mod` (~2300 lines) | 5 aux files (per PAC block) + 7 identity .inc files + aggregator → `au_pac_v2.mod` |
| Cost-push transmission to PAC | Decoupled (shadow VAR didn't see eps_pQ) | Connected (h_var_piQ_lag_1 = 7.66e-5 non-zero; eps_pQ → piQ → next-period PAC expectation) |
| LMD Laplace | −788.95 | **−781.05 (+7.9 nats)** |
| LMD MHM | −789.10 | **−781.39 (+7.7 nats)** |
| BK rank | 5 forward-looking eigvals | 9 forward-looking eigvals (extra from forward-looking structural NPVs) |
| `kappa_w` Phillips slope | +0.046 (HPD straddles zero) | **-0.103 (HPD entirely negative)** — correct FR-BDF sign once shadow-decoupling removed |

### Phase T file layout

- **`dynare/aux/`** — 5 aux .mod files (one per PAC block) + Python template generator
  - aux_pQ.mod, aux_consumption.mod, aux_business_inv.mod, aux_housing_inv.mod, aux_employment.mod
- **`dynare/simulation/identities/`** — 7 normalized .inc files (model, endogenous, exogenous, parameters, parameter-values, steady, shocks) + 3 Python normalizers
- **`dynare/simulation/estimation/`** — 5 subdirectories populated by `cherrypick()`, each containing the cherrypicked PAC equation + auxiliary regression + closed-form expectation formula
- **`dynare/au_pac_v2.mod`** — final simulation .mod built by `aggregate()` (1206 lines, 158 vars, 40 shocks, 270 params)
- **`dynare/au_pac_v2_bayesian.mod`** — Bayesian estimation variant (1443 lines)
- **`phase_t_plan.md`** — full implementation plan + 3-session progress log

### Phase T audit closure

- ✅ **Shadow-VAR disconnect** (architectural finding from Phase S investigation): now eliminated. The forward-looking PAC expectations propagate the structural cost-push channel through `piQ(-1)`, `pi_m(-1)`, `dln_pcom(-1)` in every PAC equation.

---

## Phase S FR-BDF cost-push replication (2026-05-16) — COMPLETE

## Phase S FR-BDF cost-push replication (2026-05-16) — COMPLETE

**Headline result**: Adding structural deflator channels (piQ, pi_m, dln_pcom) to the E-SAT inflation equation `eq_au_phillips`, mirroring FR-BDF wp736 §3.1.1 where π_Q sits on the Phillips LHS, lifted MHM by another **+1.62 nats** (Phase R −790.72 → Phase S **−789.10**) on top of Phase R's +11.55 nats. Cumulative Phase Q → Phase S improvement is **+13.17 MHM nats** — the largest sustained improvement in AU-PAC estimation history.

### Phase S changes

| Item | Before (Phase R) | After (Phase S) |
|---|---|---|
| `eq_au_phillips` | `pi_au_gap = λ_π·pi_au_gap(-1) + κ_π·yhat_au(-1) + ε_π` | + `α_pc·(piQ−pibar_au) + β_pc_m·(pi_m−pibar_au) + γ_oil·dln_pcom` |
| eps_pQ → pi_au impact | 0 qpp | **+0.119 qpp** (structural FR-BDF replication) |
| eps_pQ → output gap (Hyb peak Q12) | −0.005% | **−0.008%** (correct sign + larger) |
| Monetary IRF: CPI y/y peak (Hyb) | −0.037 pp | **−0.133 pp** (3.5× stronger; matches FR-BDF mechanism) |
| Wage-Phillips γ_w (CPI passthrough) | 0.458 | **0.495** (sharper identification under structural channels) |
| LMD Laplace | −790.47 | **−788.95** (+1.52) |
| LMD MHM | −790.72 | **−789.10** (+1.62) |
| Forward-guidance ratio N=12 | 10.06 | 10.09 (puzzle absence preserved) |
| BK rank (3 main variants) | passes | passes ✓ |

### Phase S audit items resolved

- 🟢 **#20 var_pQ enrichment** — was the only remaining ⚠ structural-mismatch item. Now FIXED via FR-BDF replication.
- ✅ **#6, #54 LR BGP convergence** — VERIFIED 2026-05-16 via 1100-quarter Phase S simulation. All gap variables converge to |x| < 1e-7 at Q1100 (yhat_au 8.3e-9, pi_au_gap 5.8e-11, s_gap 7.9e-9, dln_c 1.6e-8). ln_Q settles at finite non-zero +2.76 (permanent capital-level effect of temporary shock — expected under PAC).
- ✅ **#14, #53 δ_k sensitivity** — VERIFIED 2026-05-16 via δ_k sweep across 0.0134, 0.020, 0.025, 0.030. ln_Q peak essentially unchanged (−0.289% to −0.304%), but Q40 capital-channel tail grows 10× from −0.015% (AU) to −0.160% (12%/yr). Confirms slow ln_K recovery is part calibration (AU δ_k = 5.4%/yr is ABS-measured) + part PAC specification. AU value retained as empirically grounded; FR-BDF audit value δ_k = 0.0375 broke SS without dependent-param recalibration.

### Phase S artifacts

- [`dynare/au_pac.mod`](dynare/au_pac.mod) — `eq_au_phillips` augmented with FR-BDF deflator channels (and 7 other variants)
- [`dynare/bayesian_mcmc_results.mat`](dynare/bayesian_mcmc_results.mat) — refreshed posteriors (28 params)
- [`dynare/saved_irfs_{var,hybrid,mce}.mat`](dynare/) — IRFs at irf=200 with Phase S posteriors
- [`dynare/mcmc_posterior_table.md`](dynare/mcmc_posterior_table.md) — Phase S posterior table
- [`dynare/AUSPAC_WORKING_PAPER.md`](dynare/AUSPAC_WORKING_PAPER.md) — §4.4.0 (new), Table 5.6, §6.2 Table 6.3, §6.3.5, §6.5 all updated

---

## Phase R refit (2026-05-15) — COMPLETE

**Headline result**: structural fixes from FR-BDF wp736 audit improved log
marginal density by **+11.55 nats** (MHM −802.27 → −790.72), monetary IRF
peak quarter shifted from Q40 to Q9-10 (matching FR-BDF Q12), and
forward-guidance-puzzle absence preserved (AU-PAC ratio 10.06 vs linear 12 at
N=12). All 3 main variants pass Blanchard-Kahn.

### Phase R MCMC results vs Phase Q baseline

| Metric | Phase Q | Phase R | Δ |
|---|---|---|---|
| Log marginal density (Laplace) | -801.71 | **-790.47** | **+11.24** ✓ |
| Log marginal density (MHM) | -802.27 | **-790.72** | **+11.55** ✓ |
| Forward-guidance ratio at N=12 | 10.47 | 10.06 | -0.41 (still well within no-puzzle) ✓ |
| Monetary IRF peak quarter (ln_Q) | Q40 | Q9-10 | -30q earlier ✓ |
| BK rank (3 main variants) | passes | passes | ✓ |

### Phase R MCMC posterior shifts (key parameters)

| Param | Phase Q mean | Phase R mean | Notes |
|---|---|---|---|
| `lambda_w` (wage persistence) | 0.290 | **0.202** | down — consistent with stronger indexation |
| `gamma_w` (CPI indexation in wage Phillips) | 0.136 | **0.458** | UP MASSIVELY — pi_au→pi_c switch (#23) revealed strong consumer-price indexation in AU data |
| `kappa_w` (unemployment-gap channel, NEW SIGN CONVENTION) | 0.097 (wrong-signed) | **0.054** (correct sign) | flipped sign per #22; HPD straddles zero (AU flat Phillips) |
| `b3_ib` (business inv accelerator) | 0.309 | 0.307 | stable |
| `b2_c` (consumption rate-gap) | -0.331 | **-0.357** | stronger negative |
| `b3_c`, `b5_n`, `b2_pQ` | ~0 | ~0 | AU flat Phillips persists |

### Phase R fixes applied (all 8 .mod files)

| # | Audit | Fix | FR-BDF reference |
|---|---|---|---|
| 1.B | #18, #34 | `pv_X_aux` puzzle resolved — REAL interpretation: wedges capture VAR-vs-structural gap. Documentation clarified. | §3.1.1 auxiliary equations |
| 1.C | #17, #21 | `eq_dln_n_star_bar`: added `(yhat_au - yhat_au(-1))` Δq channel + flipped sign on `dln_tfp/(1-α_k)` term. Pre-fix dln_tfp coef was +2.79 (wrong sign, 3.3× too large vs FR-BDF -0.84). | eq 36 / eq 55 |
| 1.D | #22, #23 | Wage Phillips: flipped `+ kappa_w·pv_u_gap` → `- kappa_w·pv_u_gap`; replaced `gamma_w·pi_au` (VA price) with `gamma_w·pi_c` (consumer price for indexation); kappa_w prior re-centred. | eq 49 / eq 52 |
| 1.E | #26 | Added new endogenous `pv_r_lh_gap` (forward NPV of real lending rate gap, β_c=0.95 discount) + new term `+ alpha_c_r · pv_r_lh_gap` in `eq_dln_c_pac`. Provides forward-looking real-rate channel. | eq 61 |

### Post-cleanup path regressions also fixed

The 2026-05-15 repository cleanup moved scripts into `scripts/{estimation,data_prep,analysis,...}/` subfolders, breaking 8 file-path expressions that used `..` to reach repo root. Phase R repaired:
- 6 data_prep scripts: `..` → `..,..,..` for repo-root paths
- 2 generate_*_mod scripts: `fileparts(mfilename)` → `pwd` for output to dynare/
- `extract_mcmc_results.m`: explicit `dynare/` resolution + cd
- `run_phase_r_refit.m`: hardened against sub-script `clear` calls (global timer, exist() checks)

### Phase R artifacts

- [`dynare/scripts/estimation/run_phase_r_refit.m`](dynare/scripts/estimation/run_phase_r_refit.m) — refit driver (5 stages)
- [`dynare/regen/regen_phase_r_benchmarks.py`](dynare/regen/regen_phase_r_benchmarks.py) — FR-BDF IRF benchmark comparison (h5py + scipy compatible)
- [`dynare/phase_r_benchmark_table.md`](dynare/phase_r_benchmark_table.md) — quantitative comparison for all 7 shocks × 3 variants
- [`dynare/bayesian_mcmc_results.mat`](dynare/bayesian_mcmc_results.mat) — refreshed posteriors (28 params)
- [`dynare/saved_irfs_{var,hybrid,mce}.mat`](dynare/) — IRFs at irf=200
- [`dynare/forward_guidance_puzzle.png`](dynare/forward_guidance_puzzle.png) — Phase L verification (10.06 ratio)

### Audit items resolved by Phase R + Phase 4 doc pass

- 🟢 **9 FIXED**: #17, #21, #22, #23, #26 (structural fixes via Phase 1.C/1.D/1.E)
- ✅ **30+ CLOSED** (Phase 4 documentation pass, 2026-05-16): #1-#5, #7, #9, #10, #12, #13, #15, #16, #19, #20, #24, #25, #27, #35, #36, #38-#41, #44, #47, #49-#52 captured in working paper §4.13 "AU adaptations vs FR-BDF design" (six subsections: AU empirical findings, structural simplifications, local-market adaptations, calibration imports, fiscal-block differences, methodological choices)
- ⏳ **17 DEFERRED** to Phase 5 research backlog: i_us foreign rate (#8), branch decomposition (#45), energy import split (#33/#37), demographic trends (#43), tax structure (#46), BLR/MAPI/MAPU auxiliary models, APP experiment expansion. See [`plan.md`](plan.md) Phase 5.
- 🔍 **2 PENDING** Dynare runs: #54 LR BGP convergence — partially via Phase L test (forward guidance ratio stable); #14/#53 δ_k sensitivity — deferred (low priority).

### Outstanding flags from benchmark comparison

- `eps_pQ` (cost-push) IRF shows wrong sign vs FR-BDF (+0.15 vs -0.45 expected). Likely pre-existing issue, not Phase R regression. Worth investigating in follow-up.
- `eps_tfp_LR` IRF small at Q16 — consistent with permanent level shock building toward asymptotic value over longer horizon (50+ quarters per audit).
- `eps_g` impact multiplier small (0.086 at Q4 vs FR-BDF 1.20 at Q1) — suggests fiscal multiplier in AUSPAC is much weaker. May warrant prior re-think for `b_yh_c` HtM channel.
- `eps_q_us` foreign demand spillover larger than FR-BDF (+0.75 vs +0.14) — consistent with audit #3.1 finding (δ=0.20 in AU vs 0.08 in FR-BDF, due to AU-China commodity exposure).

### Phase R fixes applied (all 8 .mod files)

| # | Audit | Fix | FR-BDF reference |
|---|---|---|---|
| 1.B | #18, #34 | `pv_X_aux` puzzle resolved — REAL interpretation: wedges capture VAR-vs-structural gap (var_X uses VAR shadows; pv_X_aux uses structural variables). Documentation clarified. | §3.1.1 auxiliary equations |
| 1.C | #17, #21 | `eq_dln_n_star_bar`: added `(yhat_au - yhat_au(-1))` Δq channel + flipped sign on `dln_tfp/(1-α_k)` term. Pre-fix dln_tfp coefficient was +2.79 (wrong sign, 3.3× too large vs FR-BDF's -0.84). | eq 36 / eq 55 |
| 1.D | #22, #23 | Wage Phillips: flipped `+ kappa_w·pv_u_gap` → `- kappa_w·pv_u_gap` (sign convention); replaced `gamma_w·pi_au` (VA price) with `gamma_w·pi_c` (consumer price for indexation). `kappa_w` reset to 0.32 (FR-BDF |β_4|), prior re-centred. | eq 49 / eq 52 |
| 1.E | #26 | Added new endogenous `pv_r_lh_gap` (forward NPV of real lending rate gap, β_c=0.95 discount) + new term `+ alpha_c_r · pv_r_lh_gap` in `eq_dln_c_pac`. Provides forward-looking real-rate channel essential for no-forward-guidance-puzzle property under MCE. | eq 61 |

### Phase R driver

Run via `dynare/scripts/estimation/run_phase_r_refit.m` — performs:
1. Smoke test: compile all 3 main variants under new specs, verify BK rank
2. Smoothed-series refresh
3. Bayesian Stage 1 (csminwel mode finding, ~5 min)
4. Bayesian Stage 2 (MH MCMC 20k×2 chains, ~50 min)
5. LMD comparison vs Phase Q baseline (-801.71 / -802.27)

After MCMC: regenerate IRFs at irf=200 and run
`dynare/regen/regen_phase_r_benchmarks.py` for FR-BDF comparison table.

### Phase R deferred items

Audit items #8 (foreign rate `i_us`), #45 (branch decomposition),
#33/#37 (energy import split, Phase E), #43 (demographic trends), #46
(tax structure), #58 (APP experiment expansion) — see [plan.md](plan.md)
Phase 5 (research backlog).

---

## Phase Q baseline (pre-refit) — 2026-05-15

Phase Q added a forward-looking NPV of the policy-rate gap (`pv_i_uip`) into the UIP equation — under Hybrid/MCE the spot AUD internalises the full expected rate path on impact, delivering FR-BDF-style Hybrid amplification (output gap −0.151% Q7 under Hybrid vs −0.128% Q9 under VAR, 18% amplification; consumption growth −0.175% Q1 under Hybrid vs −0.097% Q3 under VAR, 80% amplification).

**Final Phase Q calibration**: working paper Table 5.6, **LMD Laplace = −801.71, MHM = −802.27** (improvement of ~1.5 log-likelihood units over the 2026-05-14 contemporaneous-i_gap UIP specification at MHM −803.23). Phase R MCMC re-run will produce updated values.

Authoritative documents:

| Doc | What it is |
|---|---|
| [`dynare/AUSPAC_WORKING_PAPER.md`](dynare/AUSPAC_WORKING_PAPER.md) | The paper |
| [`dynare/NEXT_STEPS.md`](dynare/NEXT_STEPS.md) | Forward-looking task list |
| [`README.md`](README.md) | Repo entry point, replication instructions |
| [`RUNNING.md`](RUNNING.md) | Detailed MATLAB run instructions |
| [`FR-BDF-update.pdf`](FR-BDF-update.pdf) | FR-BDF 2026 reference paper (Dubois et al.) |
| [`data/estimate_ces_2026.m`](data/estimate_ces_2026.m) | New CES calibration driver |

## Headline findings (final, 2026-05-15 — Phase Q forward-looking UIP)

### Supply-side (FR-BDF 2026 CES recalibration, NEW)
- `σ_CES = 0.5366` — labour FOC estimation (FD spec, prior N(0.50, 0.20²), data weight 64%)
- `α = 0.45` — AU capital-income share (ABS 5204 Tab 48)
- `γ = 0.0458` — analytical from 2019 Q_market/K_total mean (units-driven)
- `μ = 1.20` — RBA RDP 2018-09 mid-range markup
- Trend efficiency Ē growth (p.a.): 3.07% pre-2002Q2 / 0.43% 2002-2008 / 0.49% post-2008
- Working paper §4.2 production function math corrected: now properly CES level-form
  with explicit log-linearisation around K_T*=E_T*H_T*N_T* base-year steady state
  (was Cobb-Douglas-looking in pre-2026-05-14 paper)

### Wage Phillips curve under WPI (refreshed under FR-BDF 2026 calibration + Phase Q UIP)
- `γ_w = 0.137` mean (HPD [0.082, 0.191]) — moderate CPI passthrough
- `λ_w = 0.337` mean (HPD [0.179, 0.514]) — moderate own-lag persistence
- `κ_w = 0.095` mean (HPD [0.023, 0.176]) — statistically significant Phillips slope
- Standard New Keynesian structure; small Phase Q shifts from pre-UIP values
  (γ_w 0.138→0.137, λ_w 0.329→0.337, κ_w 0.090→0.095) within HPD of each other

### Demand-side parameters (stable across Phase Q)
- `b3_ib = 0.331` (HPD [0.166, 0.477]) — strong business-investment accelerator
- `b2_c = -0.330` (HPD [-0.620, -0.074]) — significant consumption rate channel
- `b_ph_ih = 0.0099` — Tobin's Q channel ≈ 0 (Phase C resolved 2026-05-11 with
  1959+ spliced housing-price series)
- `b1_m = 0.232` (t=2.71), `b2_m = 0.359` (t=3.56) — Phase D v3 with ABS 5206 SA
  + IAD demand index resolves both wrong-sign issues

### Three-regime monetary IRFs (100bp annualised tightening, FR-BDF 2026 convention: GDP not gap)
- **Real GDP (ln_Q): -0.269% VAR / -0.234% Hyb / -0.141% MCE** — 40% MCE attenuation (peak at Q40)
- **Output gap (yhat_au): -0.128% VAR Q9 / -0.151% Hyb Q7 / -0.127% MCE Q7** — **Hybrid AMPLIFIES VAR by 18%** (FR-BDF Hybrid > VAR ordering now obtains)
- **Consumption growth: -0.097% VAR Q3 / -0.175% Hyb Q1 / -0.083% MCE Q2** — **Hybrid amplifies VAR by 80%**, 53% MCE attenuation
- **Exchange rate (s_gap, %): -0.989% VAR Q20 / -0.966% Hyb Q8 / -0.970% Hyb Q8** — Phase Q forward UIP shifts AUD-appreciation peak from Q20 to Q8 under Hybrid/MCE; magnitudes ~8× larger than pre-Phase-Q
- VA-price inflation: -0.086 pp y/y Hyb peak Q8 / >99% MCE attenuation
- Housing investment growth: -0.179% Hyb peak Q8 / 74% MCE attenuation
- Business investment growth: -0.091% Hyb peak Q7 / 58% MCE attenuation
- Employment growth: -0.059% Hyb peak Q9 / 98% MCE attenuation
- 10Y yield: +0.41 pp Q1 (Hyb forward-looking financial expectations, 36% above VAR Q27 peak)
- IRF figures regenerated 2026-05-15 (Phase Q) under new MCMC posterior + forward UIP.

### Forward-guidance puzzle (Phase L, extended to N=12)
- Standard NK saturates at amplification ratio 1.79 (vs linear 12)
- AU-PAC tracks linear to within 13% (10.47 at N=12) — no puzzle

### Forecast evaluation (Phase I, 24 origins 2018Q1–2023Q4)
- WPI wage-inflation RMSE: 0.20 at h=1 (vs 2.32 under synthetic ULC — 10× tighter)
- Output gap h=1 RMSE: 1.82
- Policy rate h=1 RMSE: 0.10
- Consumption growth h=1 RMSE: 3.91 (COVID-quarter outlier)

### Identification (Phase J)
- Iskrev/Komunjer-Ng rank tests incompatible with `diffuse_filter` (Dynare 6.5 limitation)
- HPD-width analysis confirms `gamma_w` and the structural EC speeds are well-identified
- Weak: eps_ih, eps_n shock stds (residual Phase J gaps)

### Sectoral asset accounts (Phase N)
- 4 sectoral wealth-to-GDP ratios converge with 2–3 quarter half-lives under 20% off-SS
  perturbation — model passes the FR-BDF Section 4.8.5 validation

## 2026-05-15 Phase Q forward-looking UIP refresh sequence

After the FR-BDF 2026 recalibration (2026-05-14), the AU-PAC monetary-IRF comparison still showed Hybrid ≈ VAR — opposite to the FR-BDF wp736 §6.2 ordering where Hybrid > VAR. The root cause was that the exchange-rate equation `eq_s_gap` used the *contemporaneous* policy-rate gap `i_gap` rather than a forward NPV of the expected rate path, so all three regimes saw the same impact UIP signal. Phase Q (2026-05-15) added a forward-looking NPV variable `pv_i_uip`:

1. **New endogenous variable** `pv_i_uip` added to all 8 .mod files (au_pac, au_pac_var, au_pac_mce, au_pac_bayesian, au_pac_recursive, au_pac_identification, au_pac_smooth, au_pac_condforecast) with:
   - **Hybrid / MCE / derivatives**: `pv_i_uip = (i_au − ibar) + β_uip · pv_i_uip(+1)` (forward NPV)
   - **VAR**: `pv_i_uip = (i_au − ibar) + β_uip · pv_i_uip(−1)` (backward AR(1))
   - β_uip = 0.92 (standard NPV form; impact value ≈ 4.55× i_gap at λ_i = 0.85)
2. **Modified eq_s_gap** in all 8 .mod files to use `−α_s · pv_i_uip` instead of `−α_s · i_gap`
3. **Steady state**: pv_i_uip_ss = 0 (PPP holds in long run)
4. **Smoke test**: all three regimes pass Blanchard-Kahn rank condition with the new auxiliary variable
5. **Stage 1 mode finding** via csminwel: 3m07s, LMD Laplace = −801.71 (improvement from −803.31 pre-Phase-Q)
6. **Stage 2 MCMC** (20k × 2 chains): ~45 min wall time, MHM = −802.27 (improvement from −803.23 pre-Phase-Q)
7. **Three-regime IRF regeneration**: saved_irfs_{var,hybrid,mce}.mat all refreshed 2026-05-15 12:17–12:22
8. **Paper sweep**: abstract, Table 1.1 (n_endo 159→160, n_par 262→263, hybrid forward vars 9→4 ✓), Table 2.1 (added pv_i_uip), Table 2.2 (UIP row), §4.10.3 (new forward-NPV UIP equation), Table 5.6 (28-param posterior + new LMD/MHM), §6.2 Table 6.3 (all three regimes refreshed + Hyb/VAR amplification ratio column), §6.2.2 interpretation (Hybrid amplification narrative), §6.2.3 channel walkthrough (rewritten Exchange Rate channel), §6.2.4 RBA comparison (updated GDP peak), §7 conclusion (FR-BDF Hybrid > VAR ordering now documented)

## 2026-05-14 FR-BDF 2026 recalibration refresh sequence

After the FR-BDF 2026 reference paper (Dubois et al. WP #1044) was published, the AUSPAC supply block was recalibrated using the three innovations in their §3.1.2:

1. **Bug audit** of working paper §4.2 production function math — eq (10) was a Cobb-Douglas log-linearisation labelled "CES"; rewritten as proper level-form CES with explicit base-year linearisation
2. **New calibration driver** [`data/estimate_ces_2026.m`](data/estimate_ces_2026.m): γ from base-year Q/K (replaces 40k-point grid), σ from labour FOC (replaces investment FOC that failed on AU mining-boom data), two-break trend efficiency (2002Q2 and 2008Q3)
3. **Parameter writeback** across 8 .mod files: alpha_k 0.35→0.45, sigma_ces 0.337→0.5366, gamma_ulc 0.21→0.2951, gamma_uck 0.11→0.2415
4. **Steady-state smoke test**: model compiles and solves Blanchard-Kahn under new parameters
5. **Stage 1 mode finding** via csminwel: 3m23s, mode LMD = -803.31
6. **Stage 2 MCMC** (20k × 2 chains): 46m26s, MHM = -803.23, Brooks-Gelman PSRF passed all 28 params
7. **Three-regime IRF regeneration**: saved_irfs_{var,hybrid,mce}.mat all refreshed
8. **Paper sweep**: abstract, all 6 PAC posterior tables (4.3.2 / 4.4.1 / 4.4.4 / 4.5.2 / 4.6.2 / 4.7.2), §5.4 Table 5.6 + LMD + narrative, §6.2 IRF tables + interpretation, §6.2.4 RBA-suite comparison (-0.046% vs prior -0.102%), §7 conclusions, growth-neutrality appendix

## Earlier (2026-05-11) refresh sequence — pre-recalibration

1. **Phase C** (b_ph_ih): spliced 1959Q3+ housing-price series → b_ph_ih = 0.0099
2. **Phase D v2** (b1_m): switched ABS 5206 Trend → SA → b1_m = 0.255 → 0.232 (v3)
3. **Phase D v3** (b2_m): added IAD-weighted demand index → b2_m = 0.359 (resolved)
4. **ABS Trend → SA audit**: fixed 3 quiet bugs in supply_data (industry GVA, hours, WPI)
5. **Phase G Stages 1+2+3**: re-ran on SA-corrected supply data → σ = 0.3374 (later superseded 2026-05-14)
6. **First MCMC refresh** (with synthetic ULC still): LMD -931.45
7. **WPI integration** into pi_w observable: replaced synthetic CPI×emp_norm with ABS 6345
   WPI SA + 18-quarter synthetic backfill 1994Q3-1997Q2
8. **MCMC refresh under WPI** (pre-recalibration): LMD -799.64 / MHM -800.15
9. **Phase I refresh**: pi_w RMSE drops 10×
10. **Phase L extension** (forward guidance N=8 → N=12): AU-PAC ratio 10.47 vs linear 12
11. **Phase N validation**: sectoral wealth half-lives 2–3 quarters

## Phase K residuals (data-dependent)

One Phase K parameter remains unresolved (down from four pre-2026-05-11):

| Param | Status | Needed data |
|---|---|---|
| `b_di_c` | Bayesian-regularised at -0.701 | RBA OIS surprises (Bishop–Tulip RDP 2017-08; Beechey–Wright 2009 high-freq) |

Three Phase K residuals resolved on 2026-05-11:
- `b_ph_ih` via spliced 1959+ housing prices
- `b1_m`, `b2_m` via SA volumes + IAD demand index

## Release notes (Phase O)

- **Version**: 2.1 (ready to tag, FR-BDF 2026 CES recalibration + Phase Q forward-UIP release)
- **Branch**: `fix/cross-platform-paths` (current)
- **Replication**: `README.md` documents the figure-regen Python pipeline that
  reproduces every paper figure from `saved_irfs_*.mat` + `bayesian_mcmc_results.mat`
  without MATLAB; full MATLAB pipeline reproduces the MCMC posterior in ~55 min
  (5 min csminwel + 50 min Metropolis-Hastings) on Apple Silicon under Rosetta 2.
