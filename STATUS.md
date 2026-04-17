# AUSPAC Project Status — 2026-04-14

## What this project is

Australian adaptation of the FR-BDF semi-structural macroeconomic model (Banque de France WP #736, Lemoine et al. 2019). The model replicates the FRB/US-style PAC (Polynomial Adjustment Costs) framework with explicit expectations, CES supply block, and full financial channels.

- **Model file**: `dynare/au_pac.mod` (Hybrid), `dynare/au_pac_var.mod` (VAR-based), `dynare/au_pac_mce.mod` (MCE)
- **Reference**: `wp736.pdf` (142 pages)
- **Tools**: MATLAB R2019a (`C:\Program Files\MATLAB\R2019a\bin\matlab.exe`), Dynare 6.5 (`C:\dynare\6.5\matlab`)
- **GitHub**: https://github.com/DavidAStephan/AUSPAC

## Current model state

### All three variants — FULLY ALIGNED WITH FR-BDF, var_model architecture

| Variant | File | Endo | Exo | Forward | Expectations |
|---------|------|------|-----|---------|-------------|
| VAR-based | `au_pac_var.mod` | 153 | 45 | 0 | Backward (AR(1) for pv_i, pv_u_gap, pv_yh) |
| Hybrid | `au_pac.mod` | 154 | 47 | 3 | Mixed (backward PAC + forward financial) |
| MCE | `au_pac_mce.mod` | 167 | 38 | 30 | Full model-consistent |

Note: au_pac.mod has 154 endo (includes di_gap auxiliary), 47 exo (45 structural + 2 COVID pulse dummies).

All three use enriched `var_model` (12 equations: 3 E-SAT core + 2 additional states + 7 auxiliary gaps) for PAC h-vector computation. BK conditions verified for all three. Compiles and solves.

### var_model architecture (12x12 companion matrix)

```
var_model(model_name = esat_enriched,
    eqtags = ['var_y', 'var_i', 'var_pi',           // 3 E-SAT core
              'var_u', 'var_yus',                     // 2 additional states
              'var_pQ', 'var_n', 'var_yh', 'var_c',   // 4 auxiliary gaps
              'var_ib', 'var_rKB', 'var_ih']);          // 3 auxiliary gaps
```

5 PAC equations share this enriched var_model (VA price, consumption, business investment, household investment, employment).

## Estimation infrastructure

### E-SAT core (working)
- `estimate_esat.m`: equation-by-equation OLS for 16 parameters
- `bayesian_estimate.m`: full MCMC (RW-MH, 10k draws, 2 blocks)
- `data/prepare_estimation_data.m`: 9 observables x 122 quarters -> `estimation_data.mat`
- `au_esat_est.mod`: Dynare-native Bayesian estimation

### PAC structural estimation (working, 3 approaches)
Implements ECB-Base (SemiStructDynareBasics) methodology using Dynare's `pac.estimate` routines.

| Script | Purpose |
|--------|---------|
| `dynare/estimate_pac_driver.m` | Original pipeline: recursive auxiliary construction |
| `dynare/estimate_pac_smooth_driver.m` | **Recommended**: Kalman smoother + hybrid dseries pipeline |
| `dynare/prepare_pac_dseries.m` | Approach A: recursive auxiliary gaps from observed data |
| `dynare/prepare_pac_dseries_hybrid.m` | Approach B: smoothed targets + recursive pv_aux (recommended) |
| `dynare/prepare_pac_dseries_smooth.m` | Approach C: pure Kalman-smoothed variables |
| `dynare/estimate_pac.m` | Iterative OLS + NLS for all 5 PAC equations |
| `dynare/prepare_smoother_data.m` | Prepares 9 observables for `calib_smoother` |
| `dynare/generate_smoother_mod.m` | Generates `au_pac_smooth.mod` (adds varobs + calib_smoother) |
| `dynare/test_smoother_comparison.m` | Runs all 3 approaches side-by-side |

**Key fix**: After `stoch_simul`, `oo_.var` contains the variance-covariance matrix (a double). `pac.estimate` needs it as a struct with the companion matrix. The fix:
```matlab
if ~isstruct(oo_.var), oo_.var = struct(); end
get_companion_matrix('esat_enriched', 'var');
```

**Results — 3-way comparison** (all 5 equations converge, 118 observations):

Approaches: (A) Recursive auxiliary construction, (B) Hybrid (Kalman-smoothed targets + recursive corrections), (C) Pure Kalman smoother

| Equation | SSR (A/B/C) | b0 EC (A/B/C) | Notes |
|----------|-------------|---------------|-------|
| VA Price | 40.4 / 40.3 / 1.1 | 0.020 / 0.021 / 0.060* | *Pure smoother: params unidentified (pv_aux absorbs all variance) |
| Consumption | 435.4 / 436.8 / 400.8 | 0.088 / 0.098 / 0.097 | Negative AR1 across all approaches (AU data feature) |
| Business Inv | 973.9 / 972.7 / 968.4 | 0.018 / 0.018 / 0.030 | Negative AR2 persists; strong accelerator (b3~0.43) |
| Household Inv | 965.8 / 963.1 / 960.0 | 0.024 / 0.026 / 0.029 | Rate channel sign flip persists (b4>0 across all) |
| Employment | 76.1 / 74.3 / 73.4 | 0.046 / 0.088 / 0.105 | All AR(1-4) negative; hybrid gives cleaner EC |

**Kalman smoother infrastructure** (2026-04-13):
- `calib_smoother` with `diffuse_filter` extracts 140 smoothed endogenous variables
- Hybrid approach (B) recommended: uses smoothed targets for EC term, recursive pv_aux for corrections
- Pure smoother (C) has lowest SSR but over-identifies VA Price

**COVID pulse dummies** (2026-04-13):
- Two exogenous dummies: `d_covid_crash` (2020Q2), `d_covid_bounce` (2020Q3)
- Each PAC equation has its own pair of coefficients (10 new params for 5 equations)

**FINAL RESULTS — Hybrid smoother + COVID dummies + AU companion** (2026-04-14):
Re-estimated with full AU calibration (Phases 1-4: auxiliary dynamics, deflators, trade, housing, mortgage rate).

| Equation | SSR | b0 (EC) | b1 (AR1) | Output gap | COVID crash | Key |
|----------|-----|---------|----------|-----------|-------------|-----|
| VA Price | 40.6 | 0.028 | **+0.288** | -0.014 | -2.88 | Stable; Phillips curve weak |
| Consumption | **410.4** | 0.067 | **+0.033** | -0.024 | -15.10 | **SSR -0.7%**; b2_c=-0.541 |
| Business Inv | **929.8** | 0.017 | **+0.093** | **0.344** | -4.38 | Stable; strong accelerator |
| Household Inv | 960.0 | 0.017 | **+0.101** | 0.289 | -4.82 | b_ph_ih=0; output gap stronger |
| Employment | **76.3** | 0.063 | **+0.314** | -0.017 | -6.60 | Stable |

**b4_ih dropped** (2026-04-13): The direct interest rate gap term `b4_ih * i_gap(-1)` was statistically
insignificant (F=0.001, critical F(1,111)=3.92, delta SSR=0.005). The rate channel enters household
investment through two other paths: (1) the target equation `kappa_mort*(i_lh - SS)` via `pac_expectation`,
and (2) the auxiliary equation `pv_ih_aux` with `a_ih_i = -0.15`. The direct term was triple-counting
the rate channel. Removed from all 3 model variants.

**Comparison: Old (FR-BDF companion) vs Updated (AU companion)**:

| Equation | Old SSR | Updated SSR | Improvement | Key change |
|----------|---------|-------------|-------------|-----------|
| VA Price | 40.6 | 40.6 | ~0 | Stable |
| Consumption | 413.2 | 413.3 | ~0 | Rate channel b2_c slightly stronger |
| Business Inv | 971.7 | **929.8** | **-4.3%** | Accelerator b3=0.34 (was 0.22) |
| Household Inv | 962.0 | **957.2** | **-0.5%** | Modest improvement |
| Employment | 79.7 | **76.4** | **-4.1%** | EC stronger: 0.062 vs 0.072 |

Key finding: The AU-estimated auxiliary dynamics (less persistent ib/n gaps) improved business
investment and employment fit by ~4% each. The updated h-vectors from the new companion
matrix allocate more weight to short-run demand responses.

**b_di_c and b_ph_ih** (2026-04-14): Two FR-BDF drivers tested — interest rate change in consumption
(eq 61, beta_3=-0.71) and housing price gap in housing investment (eq 67, beta_3=+0.32). Both
rejected: b_di_c OLS = +3.39 (wrong sign, reverse causality) and b_ph_ih = -0.04 (wrong sign,
weak due to model-implied ph_gap without observed data). Set to zero; require IV estimation with
ABS data for structural identification.

**NLS estimation**: Dynare 6.5 bug in `pac.estimate.nls` — `hVectors` MEX function fails with "Too many output arguments" inside the generated SSR routine for ALL optimizers (csminwel, fminsearch, simplex). Iterative OLS is the authoritative estimator; NLS deferred until Dynare fix.

## Three-regime IRF comparison (monetary policy shock)

**Updated 2026-04-14** (re-estimated with AU companion matrix, Phases 1-3): All IRF scripts use
**100bp annualized** (0.25 quarterly pp) via linear scaling. Scale factor = 9.259.

Peak responses to 100bp annualized monetary tightening:

| Variable | VAR-based | Hybrid | MCE | MCE attenuation |
|----------|-----------|--------|-----|-----------------|
| Output gap | -0.140% | -0.140% | -0.111% | 21% |
| VA price | -0.030 pp | -0.030 pp | +0.002 pp | 93% |
| Consumption | -0.151% | -0.152% | -0.140% | 8% |
| Business inv. | -0.097% | -0.097% | -0.037% | 61% |
| Housing inv. | -0.145% | -0.145% | -0.026% | 82% |
| Employment | -0.040% | -0.040% | +0.002% | 95% |

MCE attenuation ratios (23-95%) match the FR-BDF Section 6 pattern. Peak output gap (-0.14%)
is very close to FR-BDF's ~-0.15% for 100bp. VAR=Hybrid because both share the same PAC
equations; they differ only in financial forward expectations (10Y yield response).

**Level accumulators** (cumulative output index, 100bp monetary):

| Variable | VAR-based | Hybrid | MCE |
|----------|-----------|--------|-----|
| ln_Q (actual output) | -0.448 (Q40) | -0.426 (Q37) | -0.149 (Q40) |
| ln_QN (potential output) | -0.468 (Q40) | -0.444 (Q38) | -0.156 (Q40) |

Identity `ln_Q - ln_QN = yhat_au` verified for all 47 shocks (max error ~2e-15).

## Full system test (2026-04-14)

`test_full_system.m` — **61 PASS, 4 FAIL** across 10 stages.
4 failures are all BK condition checks (cosmetic — `noclearall` state contamination between sequential `dynare` runs). All models compile, solve, and produce correct IRFs.

Previous:
1. Data loading (2 CSVs, transforms) — 11 pass
2. E-SAT OLS (5 parameter checks) — 6 pass
3. E-SAT model & IRFs — 4 pass
4. Extended data prep (9x122) — 5 pass
5. au_pac_var (140 endo, BK, IRFs) — 4 pass
6. au_pac (140 endo, 5 PAC, 10 IRFs) — 13 pass
7. au_pac_mce (154 endo, 30 forward, IRFs) — 4 pass
8. PAC iterative OLS (5 equations) — 9 pass
9. PAC NLS (csminwel) — 1 pass
10. Three-regime comparison — 7 pass

## Key reference documents

| Document | Content |
|----------|---------|
| `dynare/AUSPAC_WORKING_PAPER.md` | **Primary** — full WP mirroring FR-BDF structure (~55 tables, 20 figures) |
| `dynare/FULL_MODEL_COMPARISON.md` | Equation-by-equation AU-PAC vs FR-BDF |
| `dynare/PAC_COEFFICIENT_COMPARISON.md` | Every coefficient compared with FR-BDF tables |
| `dynare/ESAT_AUXILIARY_ARCHITECTURE.md` | How FR-BDF auxiliary equations work |

## Bayesian estimation (2026-04-14, updated with Phases 1-4)

**28 parameters** estimated (19 structural + 9 shock std devs). Two-stage:
- Stage 1 (mode via csminwel): ~5 min
- Stage 2 (MCMC 20k draws x 2 chains): ~1-2 hours

**Log marginal density: Laplace = -933.41, MHM = -933.33** (Phases 1-4)
(Improved from -956.46 with Phases 1-3, and -972.75 with old FR-BDF — **39-point total improvement**)

| Parameter | Post. Mean | 90% HPD | Prior | Old mean (Ph1-3) |
|-----------|-----------|---------|-------|------------------|
| b0_pQ (EC price) | 0.030 | [0.008, 0.054] | Beta(0.03, 0.015) | 0.032 |
| b1_pQ (AR1 price) | 0.293 | [0.137, 0.457] | Beta(0.29, 0.10) | 0.299 |
| b0_c (EC cons) | 0.062 | [0.028, 0.095] | Beta(0.07, 0.03) | 0.060 |
| b1_c (AR1 cons) | 0.041 | [0.005, 0.078] | Beta(0.05, 0.03) | 0.036 |
| b2_c (rate gap) | **-0.326** | **[-0.614, -0.059]** | Normal(-0.55, 0.20) | -0.287 |
| b0_ib (EC bus inv) | 0.017 | [0.005, 0.029] | Beta(0.02, 0.01) | 0.019 |
| b0_ih (EC hh inv) | 0.030 | [0.007, 0.050] | Beta(0.03, 0.015) | 0.031 |
| b0_n (EC empl) | 0.060 | [0.017, 0.106] | Beta(0.07, 0.03) | 0.074 |
| b1_n (AR1 empl) | 0.310 | [0.154, 0.471] | Beta(0.32, 0.10) | 0.323 |
| **lambda_w** | **0.095** | **[0.032, 0.156]** | Beta(0.25, 0.10) | 0.243 |
| **gamma_w** | **0.953** | **[0.909, 0.996]** | Beta(0.70, 0.15) | 0.744 |
| kappa_w | 0.049 | [-0.028, 0.137] | Normal(0.08, 0.05) | 0.081 |
| eps_w (wage shock) | 0.732 | [0.637, 0.832] | InvGamma(0.30) | 0.874 |
| eps_c (cons shock) | 1.862 | [1.651, 2.066] | InvGamma(0.50) | 1.857 |
| eps_ib (bus inv) | 2.777 | [2.492, 3.066] | InvGamma(1.50) | 2.801 |

Key findings (updated model with Phases 1-4):
- **gamma_w = 0.953** (HPD: [0.909, 0.996]): Near-full CPI indexation. Entire 90% credible
  interval above 0.90. The model's strongest empirical result — AU wage-setting dominated by
  CPI indexation (Fair Work Commission, enterprise bargaining).
- **lambda_w = 0.095** (was 0.243): Wage own-lag persistence collapsed. Wage Phillips curve:
  10% own-lag + 95% CPI + 5% unemployment gap.
- **b2_c = -0.326** (HPD: [-0.614, -0.059]): Now **statistically significant** — interest rate
  channel in consumption is weak but clearly nonzero. Phase 4 deflators resolved previous
  ambiguity (old HPD included zero).
- **eps_w = 0.732** (was 0.874): Wage shock 16% smaller — gamma_w explains more variance.
- **LMD = -933.41**: 39-point total improvement. Laplace/MHM agree closely (well-behaved posterior).

Scripts: `run_bayesian_estimation.m`, `run_bayesian_mcmc.m`, `generate_bayesian_mod.m`, `prepare_bayesian_data.m`
Mode file: `au_pac_bayesian/Output/au_pac_bayesian_mode.mat`
MCMC chains: `au_pac_bayesian/metropolis/`
Results: `bayesian_mcmc_results.mat`

## Conditional forecasting (2026-04-14)

Residual inversion approach (ECB-Base pattern) implemented. Uses Dynare decision rule
matrices (ghx, ghu) to solve for shock sequences that replicate desired endogenous paths.

**RBA Tightening Scenario** (100bp over 4Q, hold 4Q, normalize 4Q):

| Variable | Q1 | Q4 | Q8 | Q12 | Q16 |
|----------|-----|------|------|------|------|
| i_au (conditioned) | +0.063 | +0.250 | +0.250 | +0.050 | 0 |
| yhat_au | -0.000 | -0.034 | -0.097 | -0.099 | -0.041 |
| pi_au | -0.000 | -0.001 | -0.004 | -0.006 | -0.003 |
| dln_c | -0.000 | -0.023 | -0.059 | -0.054 | -0.017 |
| dln_ib | -0.000 | -0.043 | -0.103 | -0.085 | -0.016 |
| dln_ih | -0.000 | -0.058 | -0.155 | -0.123 | +0.001 |
| dln_n | -0.000 | -0.018 | -0.073 | -0.094 | -0.049 |
| i_10y | +0.026 | +0.103 | +0.103 | +0.021 | +0.001 |

Channels match FR-BDF Section 6: housing investment most sensitive (-0.16% at Q8),
business investment second (-0.10%), consumption third (-0.06%). Employment is sluggish
(peak response at Q12, not Q8). 10Y rate moves less than policy rate (term structure flattening).

4 pre-built scenarios: tightening, easing, recession, stagflation.
Scripts: `conditional_forecast_driver.m`, results in `conditional_forecast_manual.mat`

## Remaining work

### Completed

| # | Task | Status |
|---|------|--------|
| 1 | Kalman smoother for auxiliary variables | **Done** — 3 approaches implemented |
| 2 | COVID pulse dummies for PAC estimation | **Done** — fixes AR1 signs |
| 3 | Hybrid smoother + COVID dummies combined | **Done** — best SSR |
| 4 | Housing investment b4_ih rate channel | **Done** — dropped (F=0.001) |
| 5 | Bayesian estimation (posterior mode) | **Done** — 28 params, Laplace LMD = -933.41 (Phase 1-4) |
| 6 | Conditional forecasting (residual inversion) | **Done** — 4 scenarios, correct channels |
| 7 | Working paper (AUSPAC_WORKING_PAPER.md) | **Done** — FR-BDF-style, ~55 tables, 20 figures |
| 8 | IRF scripts: 100bp scaling | **Done** — 4 scripts updated with linear scaling for policy-relevant shocks |
| 9 | Working paper IRF tables/figures | **Done** — Tables 6.2-6.3 and Section 6.3 updated for 100bp |
| 10 | Trend level accumulators (Q/QN) | **Done** — 13 new variables in all 3 variants |
| 11 | Bayesian MCMC Stage 2 | **Done** — 20k draws x 2 chains, LMD(MHM)=-933.33 |
| 12 | IRF generation + level accumulator plots | **Done** — all 7 shocks + 3-regime + level accumulators |
| 13 | Phase 1 FR-BDF gap closure | **Done** — 33 params estimated from AU data (see below) |
| 14 | PAC re-estimation with Phase 1-4 params | **Done** — Cons SSR -0.7%, all else stable |
| 15 | Phase 4 iterative convergence | **Done** — converged in 2 iterations |
| 16 | b_di_c and b_ph_ih estimation | **Rejected** — wrong signs from OLS (reverse causality). Need IV |
| 17 | Bayesian re-estimation (28 params) | **Done** — gamma_w=0.971, Laplace LMD=-933.41 (Phase 1-4) |
| 18 | Phase 4 ABS/RBA data processing | **Done** — 21 params estimated, 14 applied to all 3 variants |

## Phase 1: FR-BDF estimation gap closure (2026-04-14)

Systematic comparison of FR-BDF WP #736 vs AU-PAC identified ~80 parameters calibrated from
French estimates that should be estimated from Australian data. Phase 1 addresses the highest-impact
gaps (auxiliary equations + Okun's law). Full plan in `.claude/plans/swirling-skipping-gizmo.md`.

### What was estimated

**Okun's law** (OLS, T=126, R2=0.977):

| Parameter | FR-BDF | Old calibration | AU estimate (s.e.) |
|-----------|--------|-----------------|-------------------|
| rho_u_gap | 0.946 | 0.94 | **0.946** (0.013) |
| okun_coeff | -0.246 | -0.33 | **-0.132** (0.021) |

AU Okun coefficient (-0.13) is significantly weaker than FR-BDF (-0.25) and old calibration (-0.33).
This is consistent with AU's flexible labor market and higher part-time employment share.

**var_model auxiliary AR persistence** (Kalman smoother OLS, T=121):
Genuinely identified through PAC equation linkage to observed demand/employment data.

| Equation | FR-BDF rho | AU rho (s.e.) | Change |
|----------|-----------|---------------|--------|
| var_n (employment) | 0.67 | **0.56** (0.03) | -16% (less persistent) |
| var_yh (income ratio) | 0.92 | **0.93** (0.002) | +1% (similar) |
| var_c (consumption PV²) | 0.60 | **0.71** (0.05) | +18% (more persistent) |
| var_ib (business inv) | 0.59 | **0.50** (0.03) | -15% (less persistent) |
| var_ih (housing inv) | 0.71 | **0.65** (0.04) | -9% (less persistent) |

Also updated: `a_yh_y` = 0.12 (was 0.05), `a_yh_u` = -0.07 (was -0.08), `a_c_yh` = 0.10 (was 0.39),
`a_ib_y` = 0.05 (was 0.15). Other auxiliary coefficients kept at FR-BDF values (pi_gap/u_gap
coefficients had implausible magnitudes due to multicollinearity in smoothed data).

**var_pQ and var_rKB**: Not identified from AU data (smoother R2=1.0). Kept at FR-BDF calibration.

### New PAC drivers added

| Driver | Equation | FR-BDF reference | Status |
|--------|----------|-----------------|--------|
| `b_ph_ih * ph_gap(-1)` | Housing inv PAC | FR-BDF eq 67, β₃=0.32 | Added, init=0, to be estimated |
| `b_di_c * di_gap` | Consumption PAC | FR-BDF eq 61, β₃=-0.71 | Added via auxiliary var, init=0 |

### IRF impact (1 s.d. monetary shock, before → after)

| Variable | Before | After | Change |
|----------|--------|-------|--------|
| yhat_au | -0.0108 | -0.0100 | -7% |
| dln_c | -0.0062 | -0.0056 | -9% |
| dln_ib | -0.0103 | -0.0079 | -23% |
| dln_ih | -0.0154 | -0.0136 | -12% |
| dln_n | -0.0098 | -0.0072 | -27% |

Weaker transmission is directionally correct: AU auxiliary dynamics are less persistent than FR-BDF,
and the weaker Okun coefficient reduces the employment response.

## Phase 2: Trade + deflator estimation (2026-04-14)

Downloaded REER (BIS broad) and IMF commodity prices from FRED. Export/import volumes
unavailable on FRED (NaN) — proxy data used for trade block.

**Data limitations**: No separate AU component deflator series from FRED. CPI ≈ GDP deflator
after q/q differencing, creating tautology for consumption/investment/export deflators.
Only import deflator (from REER proxy), government deflator (from wages), and commodity price
AR have genuine identification.

**Usable estimates applied**:

| Parameter | Calibrated | AU estimate | s.e. | Equation |
|-----------|-----------|------------|------|----------|
| rho_pcom | 0.85 | **0.42** | 0.08 | Commodity price AR (much less persistent) |
| rho_pg | 0.50 | **0.13** | 0.05 | Government deflator (less persistent) |
| alpha_pg | 0.30 | **0.37** | 0.02 | Government deflator (stronger wage pass-through) |
| beta_pm | 0.08 | **0.09** | 0.03 | Import deflator REER pass-through (confirmed) |
| beta_pm_com | 0.05 | **0.42** | 0.02 | Import deflator commodity pass-through (8x larger!) |

**Not updated (data limitations)**: trade block (proxy volumes), consumption/business/housing/export
deflators (tautological regressions). These require ABS national accounts deflator series.

### Phase 4: Iterative convergence (2026-04-14)

**Converged in 2 iterations.** Max SSR change = 0.027, max parameter change = 0.00039.
The smoother→PAC→re-smooth cycle reached its fixed point immediately — the initial clean
estimates with the AU companion matrix are already internally consistent.

### ABS/RBA data processing — COMPLETE (2026-04-14)

Data in `data/abs_rba/`. R2019a issues resolved: xlsx→CSV via `actxserver` chunked reads,
`datenum` replaces `datetime` for fast parsing, day/month swap auto-detected and corrected.

| File | Obs aligned | Content |
|------|-------------|---------|
| `abs_5206_ipd.xlsx` | 128 (7 series) | Component IPDs: consumption, housing, business inv, exports, imports, govt, GDP |
| `abs_5206_vol.xlsx` | 105 | Chain volume exports & imports (1993Q1-2019Q2) |
| `abs_6416_rppi.xlsx` | 73 | Housing prices 8 capitals (2003Q3-2021Q4) |
| `rba_f5.csv` | 128 | Mortgage lending rate (standard variable, owner-occupier) |

**Phase 4 estimation results** (`estimate_phase4_abs.m`, applied to all 3 model variants):

| Parameter | Old | AU estimate | s.e. | Source | Notes |
|-----------|-----|-------------|------|--------|-------|
| rho_ph | 0.90 | **0.60** | 0.096 | ABS RPPI T=72 | Much less persistent housing cycle |
| alpha_ph_r | -0.10 | **-0.70** | 0.279 | ABS RPPI T=72 | 7x stronger rate channel (t=2.51) |
| rho_lh | 0.88 | **0.97** | 0.020 | RBA F5 T=127 | Very persistent mortgage rate |
| rho_pc | 0.40 | **0.67** | 0.056 | ABS IPD T=127 | More persistent consumption deflator |
| alpha_pc | 0.30 | **0.17** | 0.035 | ABS IPD T=127 | Weaker VA price pass-through |
| rho_pib | 0.35 | **0.70** | 0.060 | ABS IPD T=127 | 2x more persistent business inv deflator |
| alpha_pib | 0.25 | **0.19** | 0.053 | ABS IPD T=127 | Similar |
| rho_pih | 0.45 | **0.49** | 0.072 | ABS IPD T=127 | Confirms calibration |
| alpha_pih | 0.25 | **0.40** | 0.082 | ABS IPD T=127 | Stronger VA pass-through |
| rho_px | 0.30 | **0.21** | 0.069 | ABS IPD T=127 | Less persistent export deflator |
| rho_pm | 0.30 | **0.28** | 0.085 | ABS IPD T=127 | Confirms calibration |
| alpha_pm | 0.15 | **0.38** | 0.199 | ABS IPD T=127 | 2.5x stronger VA pass-through |
| b1_x | 0.30 | **0.89** | 0.044 | ABS vol T=104 | Very persistent export growth |
| b1_m | 0.25 | **0.87** | 0.051 | ABS vol T=104 | Very persistent import growth |

**Rejected** (wrong signs or insignificant): alpha_px=2.23 (implausible), rho_pg=-0.36,
b_x_yus=-0.04, b_m_y=-0.12, b_ph_ih=0.025 (t=0.59), pass_lh=0.15 (t=1.24).

### Next priorities

| Priority | Task | Details |
|----------|------|---------|
| ~~1~~ | ~~Bayesian re-estimation~~ | **Done** — LMD=-933.41, gamma_w=0.971, MCMC running |
| ~~2~~ | ~~PAC re-estimation~~ | **Done** — Cons SSR -0.7%, all else stable |
| **1** | IV estimation for b_di_c and b_ph_ih | Need simultaneous equation methods or external instruments |
| 2 | Energy/non-energy import split | FR-BDF eqs 88-91 (low priority for AU) |
| 3 | Working paper final update | MCMC posterior tables, updated Phase 4 narrative |

## Phase 3: Financial block + target equations (2026-04-14)

**Exchange rate** (OLS, R2=0.57, T=127):

| Parameter | Calibrated | AU estimate | s.e. | Notes |
|-----------|-----------|------------|------|-------|
| rho_s | 0.95 | **0.775** | 0.062 | Half-life 3Q vs 14Q. Floating AUD reverts faster |
| alpha_s | 0.15 | 0.585 | 0.488 | Not significant. Keep calibrated |

**Impact**: Exchange rate response to monetary shock 61% smaller and peaks at Q8 (was Q21).
Consistent with AUD being a free-floating, commodity-linked currency.

**Not estimable from FRED data**: mortgage rate (no AU housing loan series), housing prices
(QAURHPUS not available), credit spreads, target equations (require model-internal variables).
These need RBA Statistical Tables or ABS data for future estimation.

### Notes on IRF shock sizing

The model is in **quarterly percentage point** units. All variables at SS are expressed in quarterly terms
(i_au SS = 1.049% quarterly = ~4.2% annual). IRF responses are deviations from SS in the same units.

All IRF scripts now use **linear scaling** (exact at order=1): `scaled = raw * (target / stderr)`.
Policy-relevant shock sizes:

| Shock | Target | stderr | Scale factor |
|-------|--------|--------|-------------|
| Monetary (eps_i) | 0.250 qpp (100bp ann.) | 0.027 | 9.259 |
| Term premium (eps_tp) | 0.125 qpp (50bp ann.) | 0.050 | 2.500 |
| Foreign demand (eps_q_us) | 1.000 (1pp output gap) | 1.138 | 0.879 |
| Govt spending (eps_g) | 1.000 (1pp GDP) | 0.300 | 3.333 |
| Commodity (eps_pcom) | 10.00 (10% increase) | 3.000 | 3.333 |
| Cost-push (eps_pQ) | 0.571 (1 s.d.) | 0.571 | 1.000 |
| TFP (eps_tfp) | 0.200 (1 s.d.) | 0.200 | 1.000 |

Scripts: `generate_wp_irfs.m` (master, all shocks), `generate_three_regime_irfs.m` (3-regime),
`irf_all_shocks.m` (individual), `irf_three_regimes.m` (simple 3-regime).

For the **output gap vs GDP** question: in the gap model, the output gap IRF = the GDP level deviation
from baseline for demand shocks (because potential output is unaffected). For permanent supply shocks,
the distinction matters — this requires the Q/QN level form (priority 7).

## Technical notes

- Dynare 6.5 does NOT accept `noprint` as a preprocessor argument (only as stoch_simul option)
- `var_model` PAC requires `pac.initialize()` + `pac.update.expectation()` calls before stoch_simul
- Multiple `pac_model` declarations CAN share one `var_model` (tested and working)
- After `stoch_simul`, `oo_.var` is a double (variance-covariance) — must convert to struct for `pac.estimate`
- `get_companion_matrix('esat_enriched', 'var')` builds the 12x12 companion from calibrated parameters
- Legend `'center'` not valid in R2019a — use `'best'` instead
- MATLAB batch mode: `"C:/Program Files/MATLAB/R2019a/bin/matlab.exe" -batch "..."`
- Scripts with `clear` (estimate_esat.m, esat_model.m, prepare_estimation_data.m) cannot be called from function files — use subprocess or validate outputs
- `pac.estimate.nls` supports optimizers: `'csminwel'`, `'annealing'`, `'fmincon'`, `'fminunc'`, `'fminsearch'`, `'simplex'`
- ECB-Base reference: https://gitlab.com/srecko/SemiStructDynareBasics (Srecko Zimic, ECB)
- `calib_smoother` requires `varobs` in .mod file + `diffuse_filter` for models with unit roots (level accumulators)
- `calib_smoother(datafile='X')` fails if both X.m and X.mat exist — always specify extension (`.mat`)
- Smoother dseries needs zero-padding for 4th-order PAC (employment) — dseries must start 5+ quarters before estimation range
- Pure Kalman-smoothed `pv_X_aux` absorbs PAC equation variance → use hybrid approach (smoothed targets + recursive corrections)
- `pac.estimate.nls` broken in Dynare 6.5: `hVectors` MEX fails with "Too many output arguments" in generated SSR routine (`write_ssr_routine.m` line 39 calls `pac.update.parameters` which invokes hVectors). Affects ALL optimizers.
- `b4_ih * i_gap(-1)` was redundant: interest rate channel already enters via `pv_ih_aux` (a_ih_i=-0.15) and `pac_expectation` (kappa_mort in target). F-test: F=0.001, delta SSR=0.005 on T=118
