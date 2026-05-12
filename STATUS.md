# AUSPAC — status

As of 2026-05-11 (final post-WPI refresh).

## Current state

All planned model-development phases complete. Final calibration in
working paper Table 5.6 (LMD Laplace = -799.64, MHM = -800.15).

Authoritative documents:

| Doc | What it is |
|---|---|
| [`dynare/AUSPAC_WORKING_PAPER.md`](dynare/AUSPAC_WORKING_PAPER.md) | The paper |
| [`dynare/NEXT_STEPS.md`](dynare/NEXT_STEPS.md) | Forward-looking task list |
| [`README.md`](README.md) | Repo entry point, replication instructions |
| [`RUNNING.md`](RUNNING.md) | Detailed MATLAB run instructions |

## Headline findings (final, 2026-05-11)

### Wage Phillips curve under WPI (CORRECTED)
- `γ_w = 0.136` mean (HPD [0.081, 0.191]) — moderate, not "near-full" CPI passthrough
- `λ_w = 0.290` mean (HPD [0.134, 0.447]) — moderate own-lag persistence
- `κ_w = 0.097` mean (HPD [0.010, 0.169]) — statistically significant Phillips slope
- The pre-2026-05-11 "γ_w = 0.95 near-full CPI indexation" finding was a CPI-tautology
  driven by the synthetic ULC = dlog(CPI×emp_norm) wage proxy. ABS 6345 WPI
  resolves the tautology; the wage block has standard NK structure.

### Demand-side parameters (stable across refreshes)
- `b3_ib = 0.309` (HPD [0.163, 0.464]) — strong business-investment accelerator
- `b2_c = -0.331` (HPD [-0.603, -0.050]) — significant consumption rate channel
- `b_ph_ih = 0.0099` — Tobin's Q channel ≈ 0 (Phase C resolved 2026-05-11 with
  1959+ spliced housing-price series)
- `b1_m = 0.232` (t=2.71), `b2_m = 0.359` (t=3.56) — Phase D v3 with ABS 5206 SA
  + IAD demand index resolves both wrong-sign issues

### Supply-side
- `σ_CES = 0.34` (Bayesian regularised under SA-corrected supply data)
- AU labor share `α = 0.35` (calibrated from ABS 5204)

### Three-regime monetary IRFs (100bp annualised tightening)
- Output gap: -0.109% VAR / -0.115% Hyb / -0.083% MCE — 28% MCE attenuation
- VA-price inflation: -0.018 pp peak / 100% MCE attenuation
- Housing investment: -0.93% Hyb peak at Q21 / -0.040% MCE peak — 96% MCE attenuation
- Employment: 99% MCE attenuation
- Business investment: 63% MCE attenuation
- Consumption: 52% MCE attenuation

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

## 2026-05-11 final refresh sequence

1. **Phase C** (b_ph_ih): spliced 1959Q3+ housing-price series → b_ph_ih = 0.0099
2. **Phase D v2** (b1_m): switched ABS 5206 Trend → SA → b1_m = 0.255 → 0.232 (v3)
3. **Phase D v3** (b2_m): added IAD-weighted demand index → b2_m = 0.359 (resolved)
4. **ABS Trend → SA audit**: fixed 3 quiet bugs in supply_data (industry GVA, hours, WPI)
5. **Phase G Stages 1+2+3**: re-ran on SA-corrected supply data → σ = 0.3374
6. **First MCMC refresh** (with synthetic ULC still): LMD -931.45
7. **WPI integration** into pi_w observable: replaced synthetic CPI×emp_norm with ABS 6345
   WPI SA + 18-quarter synthetic backfill 1994Q3-1997Q2
8. **Final MCMC refresh** under WPI: LMD -799.64 (+131 nat improvement from WPI alone)
9. **Posterior writeback** (28 params × 3 .mod files)
10. **IRFs regenerated** for all 3 regimes
11. **Phase I refresh**: pi_w RMSE drops 10×
12. **Phase L extension** (forward guidance N=8 → N=12): AU-PAC ratio 10.47 vs linear 12
13. **Phase N validation**: sectoral wealth half-lives 2–3 quarters
14. **Paper updated**: Abstract, Non-Technical Summary, §4.4.1, §5.4, §6.2.3, §6.5, §7,
    §B.2, Appendix F, References

## Phase K residuals (data-dependent)

One Phase K parameter remains unresolved (down from four pre-2026-05-11):

| Param | Status | Needed data |
|---|---|---|
| `b_di_c` | Bayesian-regularised at -0.701 | RBA OIS surprises (Bishop–Tulip RDP 2017-08; Beechey–Wright 2009 high-freq) |

Three Phase K residuals resolved on 2026-05-11:
- `b_ph_ih` via spliced 1959+ housing prices
- `b1_m`, `b2_m` via SA volumes + IAD demand index

## Release notes (Phase O)

- **Version**: 1.0 (ready to tag)
- **Branch**: `fix/cross-platform-paths` (current)
- **Replication**: `README.md` documents the figure-regen Python pipeline that
  reproduces every paper figure from `saved_irfs_*.mat` + `bayesian_mcmc_results.mat`
  without MATLAB; full MATLAB pipeline reproduces the MCMC posterior in ~55 min
  (5 min csminwel + 50 min Metropolis-Hastings) on Apple Silicon under Rosetta 2.
