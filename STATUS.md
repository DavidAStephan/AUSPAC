# AUSPAC — status

As of **2026-05-14** (FR-BDF 2026 CES recalibration + full MCMC refresh).

## Current state

All planned model-development phases complete. Supply block recalibrated under the FR-BDF 2026 method (Dubois et al. BdF WP #1044 §3.1.2); full-system Bayesian MCMC re-run from scratch on 11 observables.

**Final calibration**: working paper Table 5.6, **LMD Laplace = −803.31, MHM = −803.23**.

Authoritative documents:

| Doc | What it is |
|---|---|
| [`dynare/AUSPAC_WORKING_PAPER.md`](dynare/AUSPAC_WORKING_PAPER.md) | The paper |
| [`dynare/NEXT_STEPS.md`](dynare/NEXT_STEPS.md) | Forward-looking task list |
| [`README.md`](README.md) | Repo entry point, replication instructions |
| [`RUNNING.md`](RUNNING.md) | Detailed MATLAB run instructions |
| [`FR-BDF-update.pdf`](FR-BDF-update.pdf) | FR-BDF 2026 reference paper (Dubois et al.) |
| [`data/estimate_ces_2026.m`](data/estimate_ces_2026.m) | New CES calibration driver |

## Headline findings (final, 2026-05-14)

### Supply-side (FR-BDF 2026 CES recalibration, NEW)
- `σ_CES = 0.5366` — labour FOC estimation (FD spec, prior N(0.50, 0.20²), data weight 64%)
- `α = 0.45` — AU capital-income share (ABS 5204 Tab 48)
- `γ = 0.0458` — analytical from 2019 Q_market/K_total mean (units-driven)
- `μ = 1.20` — RBA RDP 2018-09 mid-range markup
- Trend efficiency Ē growth (p.a.): 3.07% pre-2002Q2 / 0.43% 2002-2008 / 0.49% post-2008
- Working paper §4.2 production function math corrected: now properly CES level-form
  with explicit log-linearisation around K_T*=E_T*H_T*N_T* base-year steady state
  (was Cobb-Douglas-looking in pre-2026-05-14 paper)

### Wage Phillips curve under WPI (refreshed under FR-BDF 2026 calibration)
- `γ_w = 0.138` mean (HPD [0.080, 0.196]) — moderate CPI passthrough
- `λ_w = 0.329` mean (HPD [0.168, 0.487]) — moderate own-lag persistence
- `κ_w = 0.090` mean (HPD [0.015, 0.174]) — statistically significant Phillips slope
- Standard New Keynesian structure; small shifts from pre-recalibration values
  (γ_w 0.136→0.138, λ_w 0.290→0.329, κ_w 0.097→0.090) within HPD of each other

### Demand-side parameters (stable across recalibration)
- `b3_ib = 0.328` (HPD [0.177, 0.475]) — strong business-investment accelerator (up from 0.309)
- `b2_c = -0.330` (HPD [-0.631, -0.047]) — significant consumption rate channel (essentially unchanged)
- `b_ph_ih = 0.0099` — Tobin's Q channel ≈ 0 (Phase C resolved 2026-05-11 with
  1959+ spliced housing-price series)
- `b1_m = 0.232` (t=2.71), `b2_m = 0.359` (t=3.56) — Phase D v3 with ABS 5206 SA
  + IAD demand index resolves both wrong-sign issues

### Three-regime monetary IRFs (100bp annualised tightening, FR-BDF 2026 convention: GDP not gap)
- **Real GDP (ln_Q): -0.223% VAR / -0.222% Hyb / -0.093% MCE** — 58% MCE attenuation (peak at Q40)
- Output gap (yhat_au, gap convention): -0.10% Hyb peak at Q6 — 20% MCE attenuation
- VA-price inflation: -0.071 pp y/y Hyb peak / 99% MCE attenuation
- Consumption growth: -0.177% Hyb peak at Q1 / 53% MCE attenuation
- Housing investment growth: -0.158% Hyb peak at Q8 / 75% MCE attenuation
- Business investment growth: -0.075% Hyb peak / 67% MCE attenuation
- Employment growth: -0.047% Hyb peak / 99% MCE attenuation
- 10Y yield: +0.42 pp at Q1 (Hyb forward-looking financial expectations)
- IRF figures regenerated 2026-05-14 to plot `ln_Q` (real GDP) per FR-BDF convention
  rather than `yhat_au` (output gap); GDP trough at Q40 reflects cumulative capital
  decay driving potential output down well after the demand-side gap closes.

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

- **Version**: 2.0 (ready to tag, FR-BDF 2026 CES recalibration release)
- **Branch**: `fix/cross-platform-paths` (current)
- **Replication**: `README.md` documents the figure-regen Python pipeline that
  reproduces every paper figure from `saved_irfs_*.mat` + `bayesian_mcmc_results.mat`
  without MATLAB; full MATLAB pipeline reproduces the MCMC posterior in ~55 min
  (5 min csminwel + 50 min Metropolis-Hastings) on Apple Silicon under Rosetta 2.
