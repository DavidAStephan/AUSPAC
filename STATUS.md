# AUSPAC — status

As of **2026-05-15** (Phase Q forward-looking UIP refresh + full MCMC re-run).

## Current state

All planned model-development phases complete. Phase Q added a forward-looking NPV of the policy-rate gap (`pv_i_uip`) into the UIP equation — under Hybrid/MCE the spot AUD internalises the full expected rate path on impact, delivering FR-BDF-style Hybrid amplification (output gap −0.151% Q7 under Hybrid vs −0.128% Q9 under VAR, 18% amplification; consumption growth −0.175% Q1 under Hybrid vs −0.097% Q3 under VAR, 80% amplification).

**Final calibration**: working paper Table 5.6, **LMD Laplace = −801.71, MHM = −802.27** (improvement of ~1.5 log-likelihood units over the 2026-05-14 contemporaneous-i_gap UIP specification at MHM −803.23).

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
