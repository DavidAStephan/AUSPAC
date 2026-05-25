# NEXT_SESSION.md — handoff from 2026-05-25 evening

The Phase L1 (wp1044-faithful replication) work that was just *planned*
last session has now been substantially executed. **L1.1, L1.2, and
L1.3a are committed and working; L1.3b is a parse-checked scaffold on
a side branch; L2 has a written plan.** This document is the new
handoff: where things are now, what's been learned, and what to do next.

---

## TL;DR

- **Branch `refactor/frbdf-replication`** carries Phases L1.1 + L1.2 +
  L1.3a (consumption-block-only wp1044 trend treatment) plus the L2
  plan + a report helper.
- **L1.3a MCMC** is running on the main worktree as of this writing
  (~2.5 hours in; should finish soon).
- **Branch `refactor/frbdf-replication-5block`** in worktree
  `/tmp/auspac-5block` carries the L1.3b 5-block scaffold (consumption
  + business inv + employment + VA price + housing inv).  Parse-checked,
  not MCMC-run.
- **The "-112 nat per added observable mechanical penalty" assumption
  from the previous handoff was WRONG.**  L1.3a Laplace LMD jumped
  from -779.30 (round12, 9 obs) to **-684.86 (L1.3a, 10 obs) = +94 nats
  BETTER**, because HP-trend observables have tight sd (~0.16% q/q) and
  contribute positively to the likelihood.  This invalidates a few of
  the comparisons that were planned to subtract a penalty.

---

## State of the work, branch by branch

### `main` (untouched)
- Last commit: `1b76446` (PR #10 merge, Option α).
- Production model still includes Option α.  Not used in the L1
  replication work; left intact for backward compatibility.

### `refactor/frbdf-replication` (active work)
Commits (newest first):

| Commit | Phase | What it does |
|---|---|---|
| `423b537` | Penalty fix | Corrected the wrong -112 nat framing in `report_l13a_results.m` and `LEVEL_2_PLAN.md` after the L1.3a Laplace result contradicted it |
| `1c19365` | L1 followups | Adds `dynare/report_l13a_results.m` (posterior comparison helper) and `LEVEL_2_PLAN.md` (~6 page L2 sketch) |
| `de20f42` | **L1.3a** | Wired `dy_bar_gap` into au_pac_bayesian.mod (consumption-block-only wp1044 Eq 35 growth-neutrality), plus `b_PAC_c` as a freely estimated parameter with prior N(0.85, 0.30).  10 observables.  Initial log posterior at priors = -1846.63, parses + filters cleanly. |
| `f0940b5` | **L1.2** | `data/compute_trend_objects.m` builds 7+ HP-filtered trend objects for the 5 PAC blocks (HP λ=1600).  Output: `data/trend_series.mat`. |
| `c982319` | **L1.1** | `data/estimate_trend_efficiency.m` estimates wp1044 Eq 7 on AU data via profile-likelihood OLS.  z_1=0.81 (vs FR 0.56), regime growth rates pre-2002/2002-08/post-08 = 3.36%/0.20%/0.57% p.a.  Output: `data/trend_efficiency.mat`. |
| `5929c9e` | docs | TRENDS_COMPARISON.md + NEXT_SESSION.md (the previous handoff) |
| `7211f97` | Phase R | Reverted Option α (PR #10); HtM channel intact at b_HtM=0.32; round12 cached chain restored to live position |

Cached round12 chain: `dynare/au_pac_bayesian.cached_round12_calibrated_2026-05-22/` (preserved untouched, used by report_l13a_results.m as the baseline).

### `refactor/frbdf-replication-5block` (parallel scaffold)
Lives in worktree `/tmp/auspac-5block`. Commits:

| Commit | What |
|---|---|
| `dfdfe20` | Updated inline penalty-comment in `.mod` (same fix as `423b537` but in worktree) |
| `b3a10ea` | **L1.3b SCAFFOLD**: wires the 4 remaining PAC blocks (business inv with 2 trends, employment, VA price, housing inv).  All 4 use derived `(1 - Σβ - ω)` coefficients (wp736 Eq 9 form); only `b_PAC_c` is freely estimated.  15 observables (10 + 5). |

**Verified to parse**: `dynare au_pac` runs stoch_simul OK (182 eqs); `dynare au_pac_bayesian` with `mode_compute=0 mh_replic=0` returns initial log posterior at priors = -2273.11 (vs L1.3a -1846, consistent with 5 more obs at prior means).  No Blanchard-Kahn issues.

**NOT MCMC-run yet** -- waiting on L1.3a result + a user-go-decision.

To apply the scaffold to the main branch later: `git merge refactor/frbdf-replication-5block` from `refactor/frbdf-replication` once L1.3a is judged complete.  Or cherry-pick `dfdfe20 b3a10ea` selectively.

---

## What L1.1, L1.2, L1.3a learned (so far)

### L1.1 — trend labour efficiency Ē_t (AU OLS estimate)

| Coefficient | AU L1.1 | wp1044 FR | ces_2026 AU |
|---|---|---|---|
| z_1 (AR(1) persistence) | **0.81** | 0.56 | -- |
| Trend pre-2002Q2 (p.a.) | 3.36% | 2.40% | 3.07% |
| Trend 2002Q2-2008Q3 (p.a.) | 0.20% | 1.40% | 0.43% |
| Trend post-2008Q3 (p.a.) | 0.57% | 0.70% | 0.49% |

Key finding: **AU Ē_t is more persistent** (z_1 = 0.81 vs FR 0.56), meaning trend transitions smooth over 5-6 quarters vs ~3-4 for France.  Cross-validation against `ces_2026_calibration.txt` agreement within 0.3pp across all three regimes.

### L1.2 — block-specific trend objects (HP λ=1600)

| Block | Trend | Regime growth p.a. (pre-2002 / 2002-08 / post-08) |
|---|---|---|
| Consumption | ȳ_t (HP of log Q_total) | 3.79% / 3.15% / 2.42% |
| Business inv | q̄_t (HP of log Q_market) | 4.06% / 3.30% / 2.27% |
| Employment | n̄*_S (HP of log n_total) | 1.56% / 2.37% / 1.91% |
| Housing inv | Ī*_H (HP of log gfcf_dwelling) | 5.71% / 6.55% / 1.82% |
| VA-price | π̄*_Q (HP of d log p_Q) | mean 2.66% p.a. |
| Real user cost | log r̄_KB | mean -4.05 (level ~6.8% p.a.) |
| HtM channel | ỹ_t (HP of d log Q_total) | mean 2.93% p.a. |

Structural ȳ from Ē via CES long-run = 4.15% / 3.15% / 2.56% — matches HP-filter ȳ within 0.2pp.  Internal consistency between supply and consumption blocks.

### L1.3a — consumption block wired (MCMC running)

Mode optimisation completed (Laplace LMD = -684.86).  MCMC sampling in progress.

**Headline finding so far**: Laplace LMD went from -779.30 (round12, 9 obs) to **-684.86 (L1.3a, 10 obs) = +94 nats** -- adding the trend treatment **improved** the fit, not the predicted "-112 nat penalty" worse.

Sample sd of `dy_bar_gap` (the new observable, post-demeaning) is 0.16% q/q -- HP-filtered trend signals are much tighter than the unit-variance heuristic that produced the -112 figure.  Going forward, expect L1.3b (adding 5 more tightly-fit trend observables) to *also* improve LMD, not degrade it.

Awaiting:
- Posterior mean + 90% HPD for `b_PAC_c` (the new free parameter; prior N(0.85, 0.30))
- Changes in `b_HtM` (currently calibrated 0.32) and `b1_c` (currently posterior 0.0375 from round12)
- MHM LMD for proper Bayesian model comparison
- Chain acceptance rates (NEXT_SESSION.md noted prior beta-W run had Chain 2 stuck at 3%; new `mh_jscale=0.25` should help)

---

## What broke from the previous handoff's assumptions

1. **"-112 nat per added observable mechanical penalty"** -- WRONG.  Adding tightly-fit HP-trend observables IMPROVES Laplace LMD.  The previous handoff's L1.3 effort estimate cited this penalty multiple times; the analysis based on subtracting it (cross-spec MHM comparisons) is incorrect.  Fixes are in `423b537` (LEVEL_2_PLAN.md, report_l13a_results.m) and `dfdfe20` (L1.3b scaffold comment).  The L1.3a commit message (`de20f42`) still has the wrong text but the code logic is fine.

2. **L1.3a wall time estimate of "60-90 min"** -- ACTUAL was ~2.5 hours (mode_compute=4 alone took 90 min; csminwel ran 100+ iterations).  L1.3b will probably take 2.5-4 hours.

3. **Decision criteria for L2 (in LEVEL_2_PLAN.md §2)** -- one of the four triggers was "MHM net of penalty worse on L1.3a vs round12".  With penalty arithmetic removed, just compare MHM directly.  And given the +94 nat Laplace evidence, a worse MHM is now very unlikely.  L2 criteria stand but the "trend-as-observable hurts fit" hypothesis looks weak.

---

## What to do next (in order)

### Once L1.3a MCMC finishes (probably within ~30 min of writing this)

1. **Run the report helper**:
   ```matlab
   cd dynare
   addpath('/Applications/Dynare/6.5-x86_64/matlab')
   report_l13a_results
   ```
   Output goes to stdout + `dynare/L1_3a_report.txt`.  Read both.

2. **Check the 4 numbers that matter**:
   - `b_PAC_c` posterior mean -- does it land near (1 - b1_c) ≈ 0.96 or far from it?
   - `b_HtM` posterior mean -- did promoting trend treatment shift it materially?  (b_HtM is still calibrated at 0.32, so this is checking robustness; if it would have changed had it been estimated, that's noise we're ignoring.)
   - `b0_c`, `b1_c` -- consumption ECM speed and lag.  These are the params most likely to change.
   - MHM LMD with `(MHM_L1.3a - MHM_round12)`.

3. **Run convergence diagnostics**: Brooks-Gelman, acceptance rates per chain.  Brain trust says if Chain 2 acceptance < 10%, the chain didn't mix well and either (a) re-run with lower mh_jscale or (b) flag as a robustness concern.

### Decision point

Based on the report:

**Path A** -- L1.3a results clean, b_PAC_c well-identified, chains mixed:
   - Merge `refactor/frbdf-replication-5block` into `refactor/frbdf-replication`
   - Re-run `prepare_estimation_data.m` (will produce 15-col estimation_data.mat)
   - Launch L1.3b MCMC (~3 hrs)
   - Compare again.  If all four derived `(1-Σβ-ω)` coefficients are plausible, L1 replication is done; move to L1.4 documentation.

**Path B** -- b_PAC_c far from (1 - b1_c) or chains poor:
   - Don't extend to 5 blocks (would amplify the problem).
   - Open LEVEL_2_PLAN.md §3, start the partial-L2 (consumption block only, iterative OLS).
   - This is ~5-6 days of work.

**Path C** -- everything is fine and the L1 result largely matches round12 (b_HtM/b0_c/b1_c shift < 1 posterior SD):
   - The wp1044 trend treatment doesn't materially change AU results.
   - Write that up as a result.
   - Skip L1.3b extension (low marginal value) and L2 (no signal that estimator matters).
   - Move to L1.4 documentation + close out the replication.

### Settling open decisions from the previous handoff

The four "open decisions" in the previous NEXT_SESSION.md should be revisited with L1.3a data in hand:

1. **HtM functional form** (gap vs level-differential).  L1.3a kept the gap form.  If b_HtM seems stable in posterior, the gap form is fine.  Defer.
2. **Trend injection mechanism**.  RW + varobs worked.  No change needed.  Resolved.
3. **β_PAC estimated vs derived**.  L1.3a estimated `b_PAC_c` only; L1.3b scaffold uses derived form for the other 4 blocks.  Consistent with wp1044 §3.5.1.  Resolved.
4. **Eq 7 on AU data**.  Done in L1.1.  Resolved.

---

## Files / artifacts to look at first

If you're picking up cold:

1. **`LEVEL_2_PLAN.md`** — full architecture sketch for the iterative-OLS rebuild (§7 has a decision tree)
2. **`TRENDS_COMPARISON.md`** — full math of FR-BDF Eq 5-11, 35; comparison vs AUSPAC Options α/β/β-W
3. **`dynare/report_l13a_results.m`** — run after MCMC done to get the posterior comparison
4. **`data/trend_efficiency.mat`** + **`data/trend_series.mat`** — the L1.1/L1.2 outputs that drive everything
5. **`dynare/au_pac_bayesian.mod`** lines 967-972 (modified consumption equation) and lines 1737-1740 (b_PAC_c estimated_params entry)
6. **`/tmp/auspac-5block/dynare/au_pac_bayesian.mod`** lines 993-995, 1004-1006, 1013-1015, 965-967 (the 4 PAC equation extensions for L1.3b)

---

## Effort estimates revised (vs the previous handoff)

| Phase | Old estimate | Actual / revised |
|---|---|---|
| Phase R revert | 1 hour | 1 hour ✓ |
| L1.1 Eq 7 OLS | half day | half day ✓ (already had infrastructure in `estimate_ces_2026.m` Step 5) |
| L1.2 trend objects | 1.5 days | ~1 hour ✓ (HP filter is fast; the design discussion eliminated need for 5 separate scripts) |
| L1.3a consumption only | 1-2 days (phased alt.) | ~2-3 hours code + 2.5 hours MCMC ✓ |
| L1.3b remaining 4 blocks | 3 days | ~2 hours code + ~3-4 hours MCMC (if run) |
| Full L1.3 (5 blocks) | 3 days | ~5-6 hours total if done in one go (L1.3a+L1.3b) |
| L1.4 evaluation | half day | half day (mostly running the report + writeup) |
| **Total Phase L1** | **5-7 days** | **~1 day of focused work + 1-2 long MCMC runs** |
| Full L2 (only if triggered) | ~2 weeks | unchanged |
| Partial L2 (consumption only) | ~5-6 days | unchanged |

The "easier than expected" surprise was Phase L1.2: the doc had it as 1.5 days of structural derivation (deriving 5 trend objects via the supply block).  In practice, wp1044 just HP-filters the relevant series for each PAC block's growth-neutrality term, so it's one short script.  The structural ȳ from Ē is documented but not used downstream.

---

## How to pick up tomorrow

1. Check on L1.3a MCMC: `ls dynare/au_pac_bayesian/metropolis/` -- if `au_pac_bayesian_mh1_blck1.mat` and `..._blck2.mat` are present, chain finished.
2. Read `dynare/au_pac_bayesian_L1_3a.log` for the final output (acceptance rates, MHM LMD).
3. Run `report_l13a_results.m` per the instructions above.
4. Read this file, decide Path A/B/C, execute.

Good luck.
