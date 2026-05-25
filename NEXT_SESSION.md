# NEXT_SESSION.md — handoff from 2026-05-24 evening

This session ended with a **directional pivot**: drop AUSPAC's custom trend-treatment innovations (Options α / β / β-W) and refocus the project on a clean replication of FR-BDF wp1044. This document captures what was learned about the FR-BDF approach and the concrete next steps so you can resume tomorrow.

---

## TL;DR

- **Options α / β / β-W are NOT being merged to main.** The branch `feat/round-1-2-followup-option-beta` (commits `0045ebf`, `19c9e1d`) stays alive in git history as side-branches but the production model will be reverted to pre-Option-α state with HtM channel intact.
- **The replication direction is wp1044** — specifically Eq 7 (trend labour efficiency Ē estimation) for the trend object, Eq 33-35 for consumption PAC.
- **Three replication depth levels identified** (Level 1 / 2 / 3 in `TRENDS_COMPARISON.md` §4-6). **Decision made: Level 1 first, evaluate, then decide on Level 2.**
- **Today's only deliverable** = this document + `TRENDS_COMPARISON.md` (full math-detailed comparison of FR-BDF vs AUSPAC Options α/β/β-W).
- **Tomorrow starts with Phase R (revert) + Phase L1 (implement Eq 7)** as detailed below.

---

## What I learned about FR-BDF wp1044 Eq 7 (the trend efficiency equation)

This is THE key piece of the FR-BDF trend architecture that AUSPAC has not been replicating. Full details with derivation in `TRENDS_COMPARISON.md` §2.4; concise summary here.

### The equation itself (wp1044 §3.1.1)

$$
\log(\bar{E}_t) = z_1 \log(\bar{E}_{t-1}) + (1-z_1)\bigl(z_2 + z_3 \delta_{08Q3-} - 0.059 \, \delta_{20Q2-21Q4}\bigr)
$$
$$
+ z_4 (T_{1,t} - z_1 T_{1,t-1}) + z_5 (T_{2,t} - z_1 T_{2,t-1}) + z_6 (T_{3,t} - z_1 T_{3,t-1})
$$
$$
+ z_7 \Bigl(\log\tfrac{TUC_t}{\overline{TUC}} - z_1 \log\tfrac{TUC_{t-1}}{\overline{TUC}}\Bigr)
+ z_8 (\delta_{COVID,20q1} + \delta_{COVID,20q3}) + z_9 \delta_{COVID,20q2} + \varepsilon_t
$$

where:
- `Ē_t` = trend labour efficiency (labour-augmenting technological progress)
- `T_{1,t}, T_{2,t}, T_{3,t}` = **three deterministic time trends** starting 1990Q1, 2002Q2, 2008Q3 — these are the regime-break trends (slope-break design, one trend variable per regime)
- `δ_{08Q3-}` = step dummy = 1 after 2008Q3, 0 before → captures permanent GFC level shift
- `δ_{20Q2-21Q4}` = step dummy for COVID period (calibrated, NOT estimated, at −0.059)
- `TUC_t` = capacity utilisation (proxies cyclical correction)
- `δ_{COVID,20qX}` = quarter-specific COVID outlier dummies
- `z_1, ..., z_9` = parameters, all estimated via OLS

### Why this matters

Three big things AUSPAC has been doing wrong relative to this:

1. **No AR(1) smoothing.** wp1044 estimates `z_1 ≈ 0.56`. This means the trend doesn't jump at regime breaks — it transitions smoothly over ~3-4 quarters. AUSPAC's Option β uses sharp step functions (regime values pre-02=+1.172, mid=−0.028, post-08=0 with no smoothing).

2. **No estimation of the trend itself.** FR-BDF estimates all 9 coefficients via OLS on observed labour productivity data. AUSPAC just reads pre-computed regime means from `ces_2026_calibration.txt`. The CES calibration script (`estimate_ces_2026.m`) doesn't fit Eq 7 — it just takes regime-mean growth rates of HP-filtered productivity.

3. **No COVID handling.** wp1044 has `−0.059 δ_{20Q2-21Q4}` as a calibrated permanent productivity loss from COVID. AUSPAC's regime structure has all of 2008Q3-end as one regime — no COVID step.

### Estimated coefficients in wp1044 Table 3.1.4 (France data)

| Coefficient | Estimate | Std Error | Role |
|---|---|---|---|
| `z_1` | 0.559 | 0.080 | AR(1) persistence of log(Ē) |
| `z_2` | −1.964 | 0.014 | intercept |
| `z_3` | −0.036 | 0.013 | GFC level shift |
| `z_4` | 0.006 | 0.000 | pre-2002Q2 trend slope |
| `z_5` | −0.002 | 0.001 | 2002Q2-2008Q3 trend slope |
| `z_6` | −0.002 | 0.000 | post-2008Q3 trend slope |
| `z_7` | 0.041 | 0.103 | TUC cyclical correction |
| `z_8` | −0.025 | 0.014 | COVID 2020Q1+Q3 dummies |
| `z_9` | 0.103 | 0.034 | COVID 2020Q2 dummy |

Implied annual trend growth rates: **2.4% pre-2002Q2, 1.4% 2002Q2-2008Q3, 0.7% post-2008Q3**.

### How Ē_t feeds into the rest of the model

Once Ē_t is estimated:
1. **Long-run output ȳ_t** is derived from Ē_t via the CES factor-price frontier (wp1044 §3.1.3 — not detailed here)
2. **Δȳ_t** is the trend output growth rate, time-varying
3. **PAC equations use `+ β_PAC · Δȳ_{t-1}`** as the explicit growth-neutrality term (wp1044 Eq 35 for consumption; analogous in other PAC blocks)
4. **Permanent income** in the consumption target is decomposed as `PV(y_H) = PV(y_H - ȳ) + ȳ_t` (wp1044 Eq 34)

### Estimation pipeline (wp1044 §2.2)

The fact that this is OLS-estimated **before** the PAC equations is critical for understanding the architectural difference:

1. CES calibration (closed-form + grid)
2. **Eq 7 OLS estimation for Ē_t** — gives smooth trend series
3. **CES long-run output equation → ȳ_t** (deterministic transformation)
4. E-SAT VAR via Bayesian methods (8-equation VAR; gives `d_i` coefficients for PV computation)
5. **PAC short-run equations via iterative OLS** — using `ȳ_t` from step 3 as a fixed regressor

This block-by-block approach is why FR-BDF doesn't have the Dynare `varexo_det`-can't-read-datafile problem. They don't use Dynare's joint Bayesian estimation for PAC equations at all.

---

## FR-BDF has 5 PAC equations — ALL need block-specific trends

This is critical and was underdocumented in the first draft of this handoff. FR-BDF wp1044 applies the PAC framework to exactly **five** behavioural equations, and **each one has its own block-specific trend object that enters as a growth-neutrality term**. Estimating Eq 7 to get smooth `Ē_t` is only the supply-block prerequisite; the actual replication work touches all 5 PAC blocks plus the (non-PAC) wage Phillips curve.

### The 5 PAC equations and their growth-neutrality terms

| # | Block | wp1044 § | Equation | Trend object | Growth-neutrality term |
|---|---|---|---|---|---|
| 1 | Value-added price | §3.3 | Eq 16 | `π̄*_Q,t` = HP filter of VA-price inflation target `π*_Q,t` | `(1 - β_1 - ω) π̄*_{Q,t-1}` (ω calibrated 0.62) |
| 2 | Employment (labor demand) | §3.4.3 | Eq 30 | `Δn̄*_{S,t}` = calibrated unit-root / HP of trend salaried employment `n̄*_S` | `(1 - β_1 - β_2 - β_3 - ω) Δn̄*_{S,t-1}` |
| 3 | Household consumption | §3.5.1 | Eq 35 | `Δȳ_t` = HP-filtered trend output growth | `β_PAC · Δȳ_{t-1}` (free parameter) |
| 4 | Household investment | §3.5.2 | Eq 37 | `Δlog Ī*_{H,t}` = HP trend of housing-investment target | `(1 - β_1 - ω) Δlog Ī*_{H,t}` (contemporaneous) |
| 5 | Business investment | §3.5.3 | Eq 46 | `Δq̄_{t-1}` (HP trend of VA volume) + `Δlog(r̄_KB,t-1)` (HP trend of real user cost) | `(1 - β_1 - β_2 - ω)(Δq̄_{t-1} - σ · Δlog(r̄_KB,t-1))` |

Key observations:

- **There is no single "trend output" that all PAC blocks use.** Each block has its own HP-filtered trend object, derived from different model variables. `Δȳ_t` enters consumption (block 3) and indirectly housing investment (block 4 has `(Δy_t - ȳ_t)` ad-hoc term), but business investment uses `Δq̄_t` (HP of VA) and `r̄_KB` (HP of real user cost), employment uses `n̄*_S`, and VA price uses `π̄*_Q`.

- **The coefficient on the growth-neutrality term differs across blocks.** Most use the "derived" form `(1 - Σβ_k - ω)` (where `ω` is the calibrated share of the non-stationary component in expectations and β_k are the autoregressive coefficients). Consumption uses a free `β_PAC` instead — wp1044 explicitly notes this is "somewhat modified as the non-stationary component of expectations is zero for expectations of gap terms" (p.43).

- **`ω` is calibrated, not estimated, in most blocks.** wp1044 Table 3.3.3 reports `ω = 0.62` for VA price. Different blocks have different `ω` values per block (varies with the trend object's persistence).

### Where the block-specific trends come from

The supply block produces `Ē_t` (from Eq 7) and then derives downstream trend objects:

```
Ē_t  →  ȳ_t           (trend GDP, via CES long-run output)
        n̄*_S,t        (trend salaried employment, via labor FOC + HP filter)
        q̄_t           (trend VA volume, equals ȳ_t * market-branches-share)
        π̄*_Q,t        (HP filter of VA price target π*_Q,t from price frontier)
        r̄_KB,t        (HP trend of real user cost; depends on wacc + π_Q + depreciation)

(separate from supply block:)
        Ī*_H,t         (housing investment target trend; depends on permanent income, prices)
```

So fully replicating FR-BDF requires:
1. Estimating Eq 7 for `Ē_t` (Phase L1.1)
2. Computing 5+ downstream trend objects from `Ē_t` and other supply-block outputs (Phase L1.2 — bigger than the current doc suggests)
3. Wiring all 5 trend objects into all 5 PAC equations with the correct growth-neutrality terms (Phase L1.3 — needs to touch ALL 5 blocks, not just consumption + business investment)

### What AUSPAC currently has vs the FR-BDF target

| Block | AUSPAC trend treatment (current main, pre-Option-α revert) | FR-BDF wp1044 |
|---|---|---|
| pQ (VA price) | Demeaned data via HP filter / sample mean; no explicit trend in equation | `π̄*_Q,t` HP filter, `(1-β_1-ω) π̄*_{Q,t-1}` in `eq_au_phillips` analog |
| Employment | Same demeaning approach | `Δn̄*_{S,t}` calibrated unit root, `(1-β_1-β_2-β_3-ω) Δn̄*_{S,t-1}` |
| Consumption | b_HtM channel + demeaned data | `β_PAC Δȳ_{t-1}` + Eq 35 HtM in level-differential form |
| Housing investment | Same demeaning | `(1-β_1-ω) Δlog Ī*_{H,t}` |
| Business investment | Same demeaning | `(1-β_1-β_2-ω)(Δq̄_{t-1} - σΔlog r̄_KB,t-1)` |

**AUSPAC currently has the trend treatment missing in all 5 PAC blocks** (Round 4-8 baseline does block-by-block demeaning rather than carrying trends in equations). The Options α/β/β-W only addressed consumption + business investment + wage trend; pQ, employment, and housing investment were never given explicit trend terms even in α/β/β-W.

### Implication for Phase L1 scope

The Phase L1.3 step in the original handoff said "add `β_PAC_c · dy_bar_t(-1)` term to consumption short-run equation (and analogous for other PAC blocks if doing this for all blocks)". The parenthetical was understating the work. To replicate FR-BDF properly, Phase L1.3 must touch **all 5 PAC equations**, each with its block-specific trend object.

This roughly **doubles the Phase L1 effort** (now ~5-7 days instead of ~3). The trend-derivation step (L1.2) is also bigger — 5+ HP filtering operations on different variables, all driven by the Ē_t output of Eq 7.

### Revised effort estimates

- **Phase R (revert)**: still ~1 hour, unchanged
- **Phase L1.1 (Eq 7 trend Ē estimation)**: ~half day
- **Phase L1.2 (derive 5+ trend objects from supply block)**: ~1.5 days (was 0.5 days)
- **Phase L1.3 (inject all 5 trend objects into all 5 PAC equations + re-run MCMC)**: ~3 days (was 1 day)
  - For each of 5 PAC blocks: add endogenous-RW machinery for its trend object, add growth-neutrality term to equation, add to varobs (5 new observables total ⇒ 15 obs not 11 obs), confirm SS computation
  - 50-90 min MCMC at end
- **Phase L1.4 (evaluate)**: ~half day

**Total Phase L1 revised: ~5-7 days** for true wp1044-faithful Level 1 replication across all 5 PAC blocks.

If this is too much, consider an **incremental L1**: implement Eq 7 + derive only the consumption trend `ȳ_t` first (1-2 days), evaluate that, then add the other 4 blocks incrementally. This is methodologically less rigorous but lets you check the approach works before paying the full cost.

---

## What I also learned about wp1044 Eq 35 (consumption short-run)

For context — the consumption short-run equation in wp1044 is:

$$
\Delta c_t = \beta_0 (c^*_{t-1} - c_{t-1}) + \beta_1 \Delta c_{t-1}
+ \text{PV}^2(y_H - \bar{y})_{t|t-1}
+ \alpha_1 \bigl(\text{PV}(r_{LH})_{t|t-1} - (\text{PV}(\bar{i})_{t|t-1} - \text{PV}(\bar{\pi})_{t|t-1})\bigr)
$$
$$
+ \beta_{\text{PAC}} \Delta \bar{y}_{t-1}
+ \beta_2 \bigl[\Delta(\log(W_{H,t} + TG_{H,t}) - p^{\text{VAT}}_{C,t}) - \tilde{y}_t\bigr]
+ \beta_3 (\Delta r_{LH,t} - (\Delta \bar{i}_t - \Delta \bar{\pi}_t))
+ \beta_4 \delta_{\text{COVID}}
$$

Key features:
- **`β_PAC · Δȳ_{t-1}`** = growth-neutrality term using the smooth FR-BDF trend
- **`β_2 [Δ(log(W_H + TG_H) - p_C^VAT) - ỹ_t]`** = the **HtM channel in level-differential form**, NOT the gap form AUSPAC uses
  - `W_H + TG_H` = total wages + government transfers (nominal)
  - `p_C^VAT` = consumer price deflator including VAT
  - `ỹ_t` = a **second** HP trend (HP trend of output GROWTH, distinct from `ȳ_t` which is HP trend of output LEVEL)
  - AUSPAC currently uses `b_HtM * (wt_H_real_gap - yhat_au)` — gap form, not level-differential form
- **Coefficient estimates** (Table 3.5.2): β_0=0.29, β_1=0.17, β_2=0.32, β_3=−1.07, β_PAC ≈ free parameter

---

## What I learned about FR-BDF's overall PAC architecture (wp736 §3.2-3.3)

Full derivation in `TRENDS_COMPARISON.md` §2. One-paragraph summary:

The PAC equation (wp736 Eq 5) is derived from cost minimisation: agents choose `y_t` to minimise quadratic deviations from target `y*_t` plus quadratic adjustment costs. The first-order condition gives:

$$\Delta y_t = a_0(y^*_{t-1} - y_{t-1}) + \sum_{k=1}^{m-1} a_k \Delta y_{t-k} + \sum_{i=0}^{\infty} d_i \Delta y^*_{t+i}$$

For growth-neutrality (Eq 8-9), FR-BDF adds a `+[1 - Σa_k - Σd_i] g` term where `g` is the trend growth rate. The target is decomposed into stationary + non-stationary components (Eq 11): `y* = ŷ* + ȳ*`. The non-stationary component's PV is computed via a single-coefficient calibrated unit-root process (Eq 58: `PV(Δȳ*) = ω · Δȳ*_{t-1}`).

So at the equation-form level, AUSPAC's PAC equations match FR-BDF reasonably well (Level 1 of the gap analysis). The deviations are in:
- (Level 2) the trend object: AUSPAC uses constants/steps where FR-BDF uses Eq-7-smoothed estimates
- (Level 3) the estimator: AUSPAC uses joint Bayesian MCMC where FR-BDF uses iterative OLS for PAC equations

---

## Decisions made this session

1. **Replication depth: Level 1 first, then evaluate Level 2.** Implement wp1044 Eq 7 trend estimation in MATLAB; keep current Bayesian MCMC for PAC equations. If headline results change materially, consider Level 2 (iterative OLS for PAC) — otherwise Level 1 is enough.

2. **Revert α/β/β-W from production model.** The trend machinery (`g_bar_C`, `g_bar_IB`, `dln_C_obs`, `dln_IB_obs`, time-varying gap variables, all related identities) gets removed. Commits stay in git history; branch `feat/round-1-2-followup-option-beta` stays alive but unmerged.

3. **Keep HtM channel intact.** The Round 1.2 HtM work (PR #8) — `b_HtM * (wt_H_real_gap - yhat_au)` term in consumption PAC, `wt_H_real_gap` as 10th observable — stays in the production model.

4. **`b_HtM` will stay CALIBRATED at 0.32 for the revert baseline.** Matches wp1044 default. Promotion to estimated parameter can happen as part of Phase L1 if desired (since wp1044 estimates β_2).

---

## Decisions still open (need direction tomorrow)

### Open decision 1: HtM functional form
- **Option A (current)**: `b_HtM * (wt_H_real_gap - yhat_au)` — gap form, AUSPAC-specific
- **Option B (wp1044-faithful)**: `β_2 [Δ(log(W_H + TG_H) - p_C^VAT) - ỹ_t]` — level differential, needs new data series (wages+transfers in nominal terms, CPI-with-VAT, second HP trend `ỹ_t`)

Option B is the true wp1044 replication. Option A is what's currently in the model. The data for Option B (wages+transfers) is already partly built (`prepare_household_income.m` constructs `wt_H_real_gap` from W_H + TG_H), but the functional form differs and the second HP trend `ỹ_t` is not yet computed.

**Recommendation**: do Option B as part of Phase L1 (changing the HtM form is a small extra task on top of the trend treatment) so the replication is complete.

### Open decision 2: how to inject smooth `Δȳ_t` into Dynare estimation
- **Option α-style**: as a parameter — impossible because it's time-varying
- **Option β-style**: as endogenous RW + varobs (existing workaround) — works, but mechanical LMD penalty of ~110 nats from added observable
- **Pre-demeaning**: subtract `Δȳ_t` from `dln_c` data in MATLAB; model sees demeaned data; conceptually identical to FR-BDF's "trend as fixed input" but loses the "trend in model" architectural property

**Recommendation**: stick with the RW+varobs workaround for consistency with Phase T architecture. The mechanical penalty is the cost of the Bayesian-MCMC choice but doesn't affect parameter identification.

### Open decision 3: should `β_PAC` be a free estimated parameter?
- wp1044 estimates it (their Eq 35 has it explicitly)
- AUSPAC currently has the equivalent term baked into `dln_c_star_bar` with `(1-λ_w)` multiplier for the wage case
- For C / IB blocks, AUSPAC adds the trend as `g_bar_C` constant — there's no separately estimated `β_PAC`-equivalent

**Recommendation**: yes, add `β_PAC_c`, `β_PAC_ib` (and `β_PAC_w` for wages) as estimated parameters during Phase L1. This is what wp1044 does.

### Open decision 4: estimate Eq 7 on AUSTRALIAN data, or use FR-BDF's French estimates?
- This is fundamental — we are doing an AU replication, so we should estimate Eq 7 on AU labour productivity data
- AU CES script already has the productivity data; just need to fit Eq 7 by OLS on it
- The implied AU trend growth rates may differ from France's 2.4 / 1.4 / 0.7

**Recommendation**: estimate Eq 7 on AU data. That's the replication exercise.

---

## Concrete next steps for tomorrow

### Phase R — Revert α/β/β-W (~1 hour)

1. From current branch state, create new branch `refactor/frbdf-replication` based on `main` (not on `feat/round-1-2-followup-option-beta`)
2. The current `main` has Option α from PR #10. Revert those changes:
   - **Files to revert**:
     - `dynare/simulation/identities/parameters.inc` — remove `g_bar_C`, `g_bar_IB` from params list
     - `dynare/simulation/identities/parameter-values.inc` — remove `g_bar_C = 0.498`, `g_bar_IB = 0.498` and the related Option α comment block
     - `dynare/simulation/identities/endogenous.inc` — remove `dln_C_obs`, `dln_IB_obs`
     - `dynare/simulation/identities/model.inc` — revert `eq_ln_C_star`, `eq_dln_C_obs`, `eq_ln_IB_star`, `eq_dln_IB_obs`, `eq_dln_c_star_bar`, `eq_dln_ib_star_bar`, `eq_c_gap`, `eq_ib_gap` to pre-α form
     - `dynare/au_pac.mod` — mirror reverts in production model
     - `dynare/au_pac_bayesian.mod` — mirror + restore `varobs ... dln_c ... dln_ib ...` (drop `dln_C_obs`, `dln_IB_obs`); revert `steady_state_model` block; restore `estimation` block to pre-α form (probably cached chain reload from `cached_round12_calibrated`)
     - `data/prepare_estimation_data.m` — restore `DEMEAN_MODE = 'sample'`, drop the Option β g_bar_C_gap / g_bar_IB_gap / g_bar_W_gap output blocks
3. Use existing cached chain `au_pac_bayesian.cached_round12_calibrated_2026-05-22/` as baseline (b_HtM=0.32, MHM=−785.80 on 10 obs)
4. Verify model parses + cached chain loads via `dynare au_pac_bayesian` dry-run
5. Commit revert

**Quick way to do this**: use `git revert` to undo the Option α commits (78235c6 and its merge 1b76446) plus the Round 1.2 follow-up sub-work. Then manually verify nothing got broken.

### Phase L1.1 — Implement wp1044 Eq 7 in MATLAB (~half day)

Create new script: `data/estimate_trend_efficiency.m`. Inputs needed:
- AU labour productivity per hour: `prodis_t = Q_t / (N_{S,t} * H_t)` — Q=market VA volume, N_S=salaried employment, H=hours per worker
- AU capacity utilisation series for the TUC term — may need to source (RBA capacity utilisation index? ABS data?)
- COVID dummy variables (already in data prep)
- Three deterministic trend series starting 1990Q1, 2002Q2, 2008Q3 (linear time trends)

Output: estimated coefficients z_1...z_9 + fitted Ē_t time series.

**Implementation approach**: standard OLS via `regress()` in MATLAB. The Eq 7 form has the AR(1) on the LHS, so it's a single-equation regression of `log(Ē_t)` on `log(Ē_{t-1})` plus the other terms (with `(1-z_1)` and `-z_1` adjustments). Can also estimate by NLS to handle the AR(1) coefficient cleanly.

Cross-validation: compare implied annual trend growth rates against the current `ces_2026_calibration.txt` regime means (3.07% / 0.43% / 0.49% for AU). If they're close, that's evidence the existing CES regimes are reasonable; if not, that's interesting.

### Phase L1.2 — Derive 5+ trend objects from supply block (~1.5 days)

This step is bigger than the original draft suggested — all 5 PAC blocks need their own block-specific trend object (see "FR-BDF has 5 PAC equations" section above).

Create scripts under `data/`:
- `compute_trend_output.m` — derive `ȳ_t` (trend GDP) from `Ē_t` via wp1044 §3.1.3 long-run output equation (still need to read pages 21-25 of wp1044 to get the exact form):
  - Long-run output = CES production function at full capital utilisation and SS unemployment
  - Roughly `ȳ_t = α_k * log(K^*_t) + (1-α_k) * (log(Ē_t) + log(H^*) + log(N^*_t))` (Cobb-Douglas approx; CES adds substitution adjustment)
  - Need: long-run capital `K^*` (from investment FOC), long-run employment `N^*` (HP trend of employment), constant hours `H^*`
  - Output: `ȳ_t` series + `Δȳ_t` (consumption block uses this)
- `compute_trend_employment.m` — derive `n̄*_{S,t}` (trend salaried employment) via HP filter of n*_S from labour FOC. Use wp1044 Eq 29 for the FOC. Output: `n̄*_S` series + `Δn̄*_S` (employment block uses this)
- `compute_trend_va_price.m` — derive `π̄*_{Q,t}` via HP filter of `π*_Q,t` (the VA price target from price frontier, wp1044 §3.3). Output: `π̄*_Q` series (VA price block uses this)
- `compute_trend_va_volume.m` — derive `q̄_t` (trend VA volume) and `r̄_KB,t` (trend real user cost) via HP filters. The business investment block needs both.
- `compute_trend_housing_inv.m` — derive `Ī*_{H,t}` (trend housing investment target). Depends on permanent income trend `ȳ_H` and other inputs.

All five trend series saved to `extended_dataset.csv` or a new `trend_series.mat` for `prepare_estimation_data.m` to load.

**Cross-validation**: compare implied AU regime growth rates against current `ces_2026_calibration.txt` regime means for each trend. They should be in the same ballpark if the Eq 7 estimation is consistent with the previous CES calibration.

### Phase L1.3 — Inject all 5 trend objects into all 5 PAC equations + re-run MCMC (~3 days)

This is the big step. Each of the 5 PAC blocks gets its own trend object wired in. Same endogenous-RW + varobs workaround pattern as Options β/β-W (Dynare 6.5's `varexo_det` is still the blocker), but applied to 5 trend objects simultaneously.

For each block:

| Block | New endo variable | Trend object data series | Growth-neutrality term added to | Estimated β_PAC parameter |
|---|---|---|---|---|
| pQ | `pi_Q_bar_gap_t` | HP filter of π*_Q,t saved to data | `eq_au_phillips` (the VA-price PAC) | `(1-β_1-ω)` derived |
| Employment | `dn_S_bar_gap_t` | Δn̄*_S series | `aux_employment.mod` PAC | `(1-Σβ_k-ω)` derived |
| Consumption | `dy_bar_gap_t` | Δȳ_t series | `aux_consumption.mod` PAC | `β_PAC_c` free, prior N((1-β_1), 0.1) |
| Housing inv | `dlogIH_bar_gap_t` | Δlog Ī*_{H,t} series | `aux_housing_inv.mod` PAC | `(1-β_1-ω)` derived |
| Business inv | `dq_bar_gap_t`, `dlogRKB_bar_gap_t` | Δq̄_t and Δlog r̄_KB,t series | `aux_business_inv.mod` PAC | `(1-β_1-β_2-ω)(... - σ·...)` derived |

Updates needed:

1. **`prepare_estimation_data.m`**: load 5+ trend series and save as new observable columns
2. **`dynare/au_pac.mod`** and **`au_pac_bayesian.mod`**:
   - Add 6 new endogenous variables (one per block; business inv needs 2)
   - Add 6 new shocks `eps_*_bar_gap` with calibrated `stderr 1.0`
   - Add 6 random-walk identities
   - Add growth-neutrality terms to 5 PAC short-run equations
   - Add 6 new observables to `varobs` (going from 10 obs to 16 obs in total)
   - Update steady-state model (all gaps = 0 at SS)
   - For consumption, promote `β_PAC_c` to `estimated_params` with prior N((1-β_1), 0.1) ≈ N(0.83, 0.1)
3. **Source layer** (`simulation/identities/`): mirror all changes in `endogenous.inc`, `model.inc`, etc.

4. **Re-run MCMC** (~60-90 min wall time — longer than 50 min because more observables; expect convergence issues similar to β-W's Chain 2 stuck at 3% acceptance; may need `mh_jscale=0.20-0.25` from the start)

5. **Compare results**:
   - vs `cached_round12_calibrated` (the new revert baseline)
   - vs Options α/β/β-W cached chains (for completeness)
   - Per-block sensitivity: which PAC parameters move when which trend is properly handled?
   - Headline `b_HtM` posterior

**Mechanical LMD penalty**: 6 new observables at calibrated stderr=1.0 ⇒ ~6 × 112 = 672 nats of mechanical penalty. So expected MHM ≈ −1100 − 672 ≈ −1770 on 16 obs setup. Within-spec comparisons (e.g. with/without smooth trends in pQ specifically) are valid; cross-spec only after subtracting mechanical penalty.

**Phased alternative if 5-block surgery is too much in one go**: implement Eq 7 + just the consumption trend first (1-2 days), evaluate, then add the other 4 blocks in subsequent passes. Less rigorous as a replication exercise but lower-risk.

### Phase L1.4 — Decide on Level 2 (~half day)

Look at the Phase L1 results:
- Does the smooth FR-BDF-style trend change `b_HtM` posterior? Phillips parameters? `b0_c`?
- Are the chains better mixed than Options β/β-W (which had Chain 1: 19% / Chain 2: 3% acceptance)?
- Does MHM improve net of mechanical penalty?

If headline results change a lot, that's evidence the estimator choice (Bayesian vs OLS) matters → consider Level 2. If they don't change much, Level 1 is enough.

---

## Files modified this session

- `TRENDS_COMPARISON.md` (new, ~10k words) — full math comparison FR-BDF vs Options α/β/β-W
- `NEXT_SESSION.md` (this file, completely rewritten) — handoff for tomorrow

Production model files are UNCHANGED from the end of the Option β-W work (on `feat/round-1-2-followup-option-beta`). The revert is for tomorrow.

---

## How to pick up tomorrow

1. **Read `TRENDS_COMPARISON.md` first** — it has the full math of FR-BDF Eq 5-11, 35 and the side-by-side comparison with Options α/β/β-W. The most important sections are §2.4 (Eq 7), §2.5 (Eq 35), and §6 (recommendations).
2. **Read this file second** — confirms the directional decisions made this evening and the open decisions for tomorrow.
3. **Confirm the four open decisions above** (HtM functional form; injection mechanism; β_PAC estimated; estimate Eq 7 on AU data).
4. **Execute Phase R, then Phase L1.1-1.4** as detailed above.

**Revised cumulative time estimate** (after recognising all 5 PAC blocks need block-specific trends):
- 1h revert
- 5-7 days L1 implementation (Eq 7 + 5+ trend derivations + 5-block PAC wiring + MCMC)
- 0.5 day evaluation

**Total: ~6-8 days** for true wp1044-faithful Level 1 across all 5 PAC blocks.

Phased alternative (consumption block only first, then expand): ~3 days for first pass, then ~1 day per additional block.

If Level 2 is chosen after L1.4, add ~2 weeks for the iterative OLS PAC rebuild.

Good luck.
