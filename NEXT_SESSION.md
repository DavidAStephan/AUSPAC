# NEXT_SESSION.md — pickup notes from 2026-05-23

You ended the 2026-05-23 session mid-way through the Round 1.2 follow-up exploration. This document captures **exactly where things stand** so you (or a future Claude session) can resume without re-deriving context.

---

## TL;DR

- The Round 1.2 hand-to-mouth (`b_HtM`) channel has been thoroughly explored across **5 trend-treatment specifications**.
- **Empirical headline: AU's `b_HtM ∈ [0.08, 0.19]` across all specs, with HPDs touching or crossing zero in 3 of 5.** Well below France's wp1044 value of 0.32.
- **Option α (FR-BDF-faithful: trend in model, not in data)** is now committed as the architecturally-correct specification. MHM = −1101.87, `b_HtM = 0.114` with 90% HPD [−0.10, +0.29].
- **Two known limitations** of Option α:
  1. `pi_w` trend mismatch (model SS 0.625 vs data mean 1.16% qoq, ~5–10 nats LMD penalty)
  2. Constant trend `g_bar_C = 0.498` is the post-2008 BGP value; doesn't capture pre-2002 high-growth regime
- **Option β** (time-varying trend with breaks at 2002Q2 + 2008Q3) is the next planned extension to fix both.

---

## What's in the code right now (post-merge state)

### Model files
- `dynare/au_pac.mod` and `dynare/au_pac_bayesian.mod` both have Option α active:
  - Two new parameters: `g_bar_C = 0.498`, `g_bar_IB = 0.498` (% qoq)
  - `eq_dln_c_star_bar` has `+ g_bar_C` constant drift
  - `eq_dln_ib_star_bar` has `+ g_bar_IB` constant drift
  - `eq_c_gap` and `eq_ib_gap` subtract `dln_*_star_bar` to stay stationary
  - `eq_ln_C_star` and `eq_ln_IB_star` evolve as `(dln_*_star_bar − g_bar_*)`
  - Two new measurement variables: `dln_C_obs = dln_c + dln_c_star_bar` (SS = `g_bar_C`), same for IB
  - `varobs`: `dln_c → dln_C_obs`, `dln_ib → dln_IB_obs`, `pi_w` stays
  - `pi_w` model SS still `pi_ss = 0.625% qoq` (KNOWN LIMITATION)
- `dynare/au_pac_bayesian.mod` estimation block is in **cheap-reload mode**:
  ```
  mode_compute=0, mode_file='au_pac_bayesian_seed_mode', mh_replic=0, load_mh_file, mh_jscale=0.15
  ```
  Running `dynare au_pac_bayesian` reads the Option α cached chain in `dynare/au_pac_bayesian/` and reports posteriors. **DO NOT** flip `mh_replic` to a positive number unless you intend to OVERWRITE the cache with a fresh MCMC.

### Data pipeline
- `data/prepare_estimation_data.m` has `DEMEAN_MODE = 'none'` set. Don't change unless you're running a comparison spec.
  - `'sample'` = legacy constant-mean demeaning
  - `'hp_trend'` = HP-filter trend subtraction (TVD spec)
  - `'frbdf'` = CES Ē two-break trend + employment HP-trend subtraction
  - `'none'` = Option α (no demeaning of growth rates)
- 10 observables in `estimation_data.mat`: standard 9 + `wt_H_real_gap`
- 6 stimulus quarters (2008Q4-2009Q1, 2020Q1-Q4) NaN-d in `wt_H_real_gap` (Option 4)
- `data/prepare_household_income.m` now also writes wages-only and transfers-only HP-gap columns (`au_wt_H_W_gap`, `au_wt_H_TG_gap`) to `extended_dataset.csv` — these are NOT used by Option α but are pre-built infrastructure for Option 2 (wages-vs-transfers decomposition).

### Cached MCMC chains (all in `dynare/`)
| Directory | Content | When to reuse |
|---|---|---|
| `au_pac_bayesian/` | **Active Option α chain** (b_HtM=0.114, MHM −1101.87) | Default — current state |
| `au_pac_bayesian.cached_pre_round12_2026-05-22/` | Pre-Round-1.2 baseline (9-obs, b_HtM CALIBRATED at 0) | Comparison vs the pre-channel state |
| `au_pac_bayesian.cached_round12_calibrated_2026-05-22/` | Round 1.2 with `b_HtM` calibrated at 0.32 (the FR-BDF value) | Comparison vs first attempt at the channel |
| `au_pac_bayesian.cached_opt4_2026-05-23/` | Option 4: NaN stim quarters + sample-mean demeaning, b_HtM=0.190 | Strongest case for non-zero b_HtM |
| `au_pac_bayesian.cached_tvd_hp_2026-05-23/` | TVD: HP-filter trend, b_HtM=0.078, MHM=−1083.88 (best LMD) | Best statistical fit |
| `au_pac_bayesian.cached_frbdf_2026-05-23/` | FR-BDF data demeaning, b_HtM=0.160 | Middle ground |
| `au_pac_bayesian.cached_optalpha_2026-05-23/` | Option α with `mh_jscale=0.15` (the canonical Option α run) | Identical to active cache; explicit backup |

### Mode-file artifacts
- `dynare/au_pac_bayesian_seed_mode.mat` — hybrid seed mode (34 baseline params + b_HtM 0.13 + SE_eps_wtH 1.18). Built by `dynare/build_round12_seed_mode.m` from the pre-Round-1.2 baseline mode file. Used as the starting point for all Round 1.2 follow-up MCMCs.
- `dynare/build_round12_seed_mode.m` — the constructor script for the seed mode file. Re-run if you change `estimated_params` (the param positions need to be updated).

---

## How to reproduce the current state

```bash
cd /Users/davidstephan/Documents/AUSPAC
# 1. Re-prepare data (DEMEAN_MODE='none' for Option α)
matlab -batch "cd data; prepare_estimation_data"
# 2. Load Option α cached chain and print posterior summaries
matlab -batch "cd dynare; setup_dynare_path; dynare au_pac_bayesian"
```

This should reproduce: `MHM LMD = −1101.87`, `b_HtM posterior = 0.114`.

---

## What's next — three threads to pick up

### Thread A — Option β (HIGHEST PRIORITY)

**Goal**: Replace the constant `g_bar_C` / `g_bar_IB` drift in Option α with a **time-varying trend** that has two breaks (2002Q2 and 2008Q3) matching the CES Ē regime structure. Also add a wage trend (`g_bar_W`) so `pi_w` SS adapts. This should:
- Fix the pre-2002 trend under-prediction (CES Ē trend was 0.77% qoq, vs current Option α 0.123% qoq)
- Fix the post-2008 trend mismatch in `pi_w` (currently 0.5% qoq below data)
- Restore LMD competitiveness with TVD

**Implementation sketch**:

1. **Add time-varying drift parameters**. Option: make `g_bar_C` / `g_bar_IB` / `g_bar_W` *functions of time* via a calibrated deterministic dummy series.
   - Simplest: add a `regime_pre02`, `regime_mid`, `regime_post08` dummy time series to `estimation_data.mat`
   - Add a model variable `g_bar_C_t` defined as `g_bar_C_pre02·d_pre02 + g_bar_C_mid·d_mid + g_bar_C_post08·d_post08`
   - Replace `g_bar_C` in `eq_dln_c_star_bar` with `g_bar_C_t`

2. **Calibrate the three regime values** from `dynare/ces_2026_calibration.txt`:
   - `g_bar_C_pre02` = `dln_E_bar_pre02/(1-α_k) + dln_N_bar` ≈ 0.77 + 0.375 = 1.15% qoq
   - `g_bar_C_mid` = 0.43/4/(1-0.45) + 0.375 ≈ 0.20 + 0.375 ≈ 0.57% qoq
   - `g_bar_C_post08` = 0.49/4/(1-0.45) + 0.375 ≈ 0.22 + 0.375 ≈ 0.60% qoq
   
   (cross-check: sample mean of dln_c is 0.77% qoq, which is between the three regime values weighted by their durations)

3. **Add wage trend `g_bar_W_t`** with same regime structure:
   - `g_bar_W_pre02` = `pi_ss + dln_E_bar_pre02` = 0.625 + 0.77 = 1.40% qoq (matches data 1990s mean)
   - `g_bar_W_mid` = 0.625 + 0.108 = 0.73% qoq
   - `g_bar_W_post08` = 0.625 + 0.123 = 0.75% qoq
   
   This needs a modification to `eq_pi_w` or a separate `dln_w_trend` identity.

4. **Update SS values** — `dln_c_star_bar` SS depends on which regime is "current". For SS computation use post-2008 values. For simulation, Dynare will use the time-varying values.

5. **Re-run MCMC** — same as Option α, with the time-varying trends in place. Expected outcome: `b_HtM` somewhere between TVD and FR-BDF values (HPD probably still crosses zero), but LMD should match or beat TVD because the model now correctly handles the pre-2002 high-growth regime.

**Tricky parts**:
- Dynare doesn't natively support time-varying parameters. Workaround: declare the time-varying drift as an EXOGENOUS time-series (like an observed deterministic dummy) and treat it as a calibrated forcing variable.
- The dummy regime indicators need to be in `estimation_data.mat` alongside the observables.

**Files to touch**: `simulation/identities/parameters.inc`, `parameter-values.inc`, `model.inc`, `endogenous.inc`, `au_pac.mod`, `au_pac_bayesian.mod`, `data/prepare_estimation_data.m`. Probably 4-6 hours of careful surgery + a 60-90 min MCMC.

### Thread B — Option 2 (wages-vs-transfers decomposition)

**Goal**: Test whether the AU HtM channel is driven by wages or transfers separately, by decomposing `wt_H_real_gap` into two observables: `wt_H_W_gap` (compensation of employees only) and `wt_H_TG_gap` (social assistance only).

**Status**: Data is already prepared. `data/prepare_household_income.m` writes both columns (`au_wt_H_W_gap`, `au_wt_H_TG_gap`) to `extended_dataset.csv`. The raw-data SDs we computed:
- Wages-only: SD 1.79%, range [−4.5%, +7.3%] — cyclical
- Transfers-only: **SD 5.61%, range [−10.5%, +31.0%]** — recession-spike dominated
- Combined: SD 1.62% (wages signal dominates the SD)

**Implementation sketch**:

1. Add two new endogenous variables: `wt_H_W_gap`, `wt_H_TG_gap` (replacing `wt_H_real_gap`).
2. Add two new AR(1) reduced forms in `aux_consumption.mod`'s `var_model`.
3. Modify the consumption PAC equation: `+ b_HtM_W · (wt_H_W_gap − yhat_au) + b_HtM_TG · (wt_H_TG_gap − yhat_au)`.
4. Add `b_HtM_W`, `b_HtM_TG` to `estimated_params`. Drop `b_HtM`.
5. Add `wt_H_W_gap` and `wt_H_TG_gap` to `varobs`. Drop `wt_H_real_gap`.
6. Rebuild seed mode file (parameter positions change).
7. Re-run MCMC.

**Expected outcome**:
- `b_HtM_W` close to FR-BDF magnitude (~0.2-0.3) — wages drive the cyclical HtM response
- `b_HtM_TG` near zero — transfers absorbed by saving/debt paydown (the user's original hypothesis)

This would be the cleanest cross-country story: "AU and France have similar wage-HtM channels, but AU households save transfer windfalls more than French households do."

**Files to touch**: `aux/aux_consumption.mod`, `simulation/identities/*.inc`, `au_pac.mod`, `au_pac_bayesian.mod`, `data/prepare_estimation_data.m`. About 3-4 hours of work + MCMC.

### Thread C — Refresh stale FRED data

**Discovery**: `au_consumption` in `extended_dataset.csv` is NaN from 2023Q4 onwards. The estimation sample currently ends at 2023Q3. Refreshing FRED `NAEXKP02AUQ189S` would extend the sample by 4-5 quarters and let us include the 2024 data.

To refresh: run `data/download_extended_data.m` (it uses FRED's API; sample will extend automatically). Then re-run `prepare_estimation_data.m` and re-MCMC.

Low-effort, possibly informative. Could be done independently of A or B.

---

## Known gotchas and workarounds

1. **`mode_compute=4` (csminwel) and `mode_compute=5` (newrat) BOTH CRASH** with Option α + Option 4 NaN-d observations. Error: `dsge_likelihood` line 763 dimension mismatch in numerical gradient. Workaround: `mode_compute=0 + mh_jscale=0.15`. This bypasses the gradient computation that triggers the crash.

2. **The pre-Round-1.2 LMDs (−779 / −780) are NOT comparable to Round 1.2 follow-up LMDs (~−1100)** because the observable set changed (9 obs → 10 obs). Adding `wt_H_real_gap` to `varobs` mechanically reduces LMD by ~−138 nats just from the new likelihood term. Within-spec comparisons (Option 4 vs TVD vs FR-BDF vs Option α) ARE valid.

3. **Laplace LMD reported by Dynare under `mode_compute=0`** is computed at the supplied seed mode, NOT at the actual posterior mode. It will be much worse than MHM. Use MHM as the LMD metric for these runs.

4. **`pi_w` is the weakest equation** in the model right now. Posterior `stderr eps_w` is ~7× its prior mean across all Round 1.2 specs. The trend mismatch (model SS 0.625 vs data mean 1.16 % qoq) is the suspected cause. Option β should help.

5. **`b1_pQ = 0.69`** in TVD and Option α (vs 0.28 in the seeded baseline) is anomalous. Not sure what's driving this — possibly model identification difficulty under the larger 10-obs setup. Could be worth investigating.

6. **`alpha_pc` near boundary in FR-BDF** (0.58 vs prior mean 0.30). FR-BDF run had less stable mode. Don't read into that posterior.

---

## Open questions worth thinking about

1. **Is Option α's `g_bar_C = 0.498` the right post-2008 value?** Re-derive from latest CES calibration. Could be off by 0.05-0.10% qoq. Affects observable matching by similar order.

2. **Should we also handle the `pi_w` trend?** If yes — how? Adding drift to `ln_tfp_LR` creates SS-consistency problems with `dln_n_star_bar`'s structural identity. May need a separate `g_bar_W` parameter with its own equation, not derived from `ln_tfp_LR`.

3. **Stale FRED snapshot** — `au_consumption` only goes through 2023Q3. Refresh would extend the sample by 4-5 quarters and potentially improve identification.

4. **The `kalman_filter_d: not enough information` warnings** in every Option 4+ run come from the diffuse filter struggling with the 6 NaN-d quarters. They're warnings not errors, but may indicate the partial-NaN handling is fragile. Consider whether to NaN entire rows instead of just `wt_H_real_gap` for those quarters.

---

## Files modified in this session (uncommitted)

```
data/prepare_estimation_data.m        # DEMEAN_MODE toggle, dln_C_obs/dln_IB_obs save
data/prepare_household_income.m       # wages+transfers split columns
data/extended_dataset.csv             # added 3 columns: wt_H_real_gap, wt_H_W_gap, wt_H_TG_gap
dynare/au_pac.mod                     # Option α: drifts, new vars, eqs, SS values
dynare/au_pac_bayesian.mod            # mirror + varobs + estimated_params + cheap-reload config
dynare/simulation/identities/         # parameters.inc, parameter-values.inc, endogenous.inc, model.inc
dynare/build_round12_seed_mode.m      # new — constructs hybrid seed mode file
dynare/aux/aux_consumption.mod        # Round 1.2 var_model state
STATUS.md                             # v3.1.4 row added
dynare/AUSPAC_WORKING_PAPER.md        # new §4.11.4
NEXT_SESSION.md                       # THIS FILE
```

Plus all the auto-regenerated Dynare derivative files in `dynare/aux/+aux_consumption/` and the cherrypicked `dynare/simulation/estimation/consumption/`.

---

## How to pick up

The cleanest entry points, in priority order:

1. **`STATUS.md`** — phase table including v3.1.4 row gives the timeline of what was done.
2. **`dynare/AUSPAC_WORKING_PAPER.md` §4.11.4** — full economic and technical narrative of the 5-way comparison.
3. **This file (`NEXT_SESSION.md`)** — operational details, file inventory, gotchas.
4. **`CES_PRODUCTION_FUNCTION_APPROACH.md`** — separate write-up of the CES calibration that Option β will need to reference for the trend regime values.

Then pick one of Thread A (Option β), Thread B (Option 2), or Thread C (FRED refresh) to work on.

Good luck.
