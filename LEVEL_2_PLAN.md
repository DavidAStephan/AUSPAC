# LEVEL_2_PLAN.md — iterative-OLS rebuild matching FR-BDF wp1044 exactly

**Status**: draft / sketch only. To be elaborated and executed only if Phase L1.4 evaluation shows that the full-information Bayesian Kalman approach is materially mis-estimating PAC parameters relative to what wp1044's block-by-block iterative-OLS would deliver.

**Branch when started**: would be created as `refactor/frbdf-replication-L2` from the head of `refactor/frbdf-replication` (or its 5-block extension), keeping L1 alive for comparison.

---

## 1. Why L2 might be warranted

L1 (Bayesian MCMC on the joint model) and L2 (block-by-block iterative OLS) differ in their **estimator**, not their model. The model equations are the same. Three reasons L1 might give different parameter estimates than wp1044's L2:

1. **Cross-block contamination via the Kalman filter.** When VA-price, employment, consumption, business inv, and housing inv are all in one likelihood, a misspecification in one block can pull parameters in another. wp1044's block-by-block OLS isolates each PAC eq.

2. **Trend treatment as observable vs known regressor.** L1 treats `dy_bar_gap` as a noisy observable on a RW endogenous variable; the Kalman filter blends the data path with model uncertainty. L2 treats `Δȳ_t` as a known, pre-computed time series — no measurement noise, no model uncertainty about its path. Initially I expected this to mean L1 would pay a ~112-nat-per-obs "mechanical LMD penalty" but the L1.3a Laplace LMD (-684.86 vs round12's -779.30, **+94 nats better** at 10 obs vs 9) showed the trend observable contributes positively, not negatively. The actual L1-vs-L2 LMD comparison goes the other way: L1 may have an *advantage* because the Kalman filter exploits the smooth structure of the HP-trend series. L2's argument is identification, not fit quality.

3. **E-SAT VAR identification.** L1 estimates the VAR jointly with everything else; the policy-function projection coefficients `d_i` (for PV computation) are derived from the joint posterior. L2 estimates the E-SAT VAR alone first, then *takes those `d_i` as fixed* for the PAC regression. The two approaches deliver identifiably different `d_i` estimates when the structural model is misspecified.

A meaningful gap between L1 and wp1044's reported French estimates on conceptually-similar parameters (β_0, β_1 in consumption; ω in price block) would be evidence that the estimator matters and L2 is worth building.

---

## 2. Decision criteria — when to start L2

L2 is a ~2-week build (per NEXT_SESSION.md estimate). Build cost is high, so don't start unless L1.3 + L1.4 evaluation produces at least one of:

- **L1.3a `b_PAC_c` posterior is far from `(1 - b1_c)`** by more than 2 posterior SDs. wp1044 notes the coefficient is "somewhat modified" from `(1 - β_1)`; if AU posterior says it's *very* different, that's an identification signal worth investigating with iterative OLS.
- **Chain convergence problems persist** after L1.3 mh_jscale tuning (e.g. one chain stuck at < 10% acceptance). The Kalman filter joint posterior may be too flat or multimodal for MCMC to traverse — iterative OLS sidesteps this.
- **MHM is *worse* on L1.3a vs round12** (consumption-only) -- i.e. the L1.3a model fits the data, including dy_bar_gap, worse than the no-trend baseline fit its smaller data. (Originally framed as "net of mechanical penalty"; the L1.3a Laplace LMD result -684.86 vs round12 -779.30 = +94 nats Laplace showed the trend observable actually helps fit, not hurts. So a *negative* MHM result for L1.3a is now unlikely; if it does happen, that's a strong signal that joint Kalman estimation breaks somewhere.) Iterative OLS doesn't have this problem because the trend is exogenous to the PAC estimator.
- **L1.3b results show systematic shifts** in derived `(1 - Σβ - ω)` coefficients across the 4 derived-coefficient blocks (employment, VA price, business inv, housing inv) in implausible directions (e.g. coefficient going negative, β_k summing past 1).

If none of these triggers fire, L1 is good enough and the 2-week L2 cost isn't justified.

---

## 3. L2 architecture sketch

### 3.1 Pipeline (wp1044 §2.2)

```
Step 1.  CES calibration                                [DONE - Phase G/L1.1]
         estimate_ces_2026.m + estimate_trend_efficiency.m
         outputs: sigma, gamma, alpha, mu, Ebar series

Step 2.  Long-run output ybar from Ebar                 [DONE - Phase L1.2]
         compute_trend_objects.m -> trend_series.mat
         outputs: log_ybar (and other block-specific trends)

Step 3.  E-SAT VAR Bayesian estimation                  [PARTIAL - exists]
         dynare/au_pac_bayesian.mod estimates the VAR jointly with PAC.
         For L2: extract just the VAR coefficients via Litterman-style
         Minnesota prior shrinkage on the 8 E-SAT equations.  Pin those
         coefficients for use in step 4.
         outputs: VAR coefficient matrices A_1, ..., A_p; companion
                  matrix Phi for PV computation.

Step 4.  PAC short-run equations via iterative OLS      [NEW - L2 build]
         For each of the 5 PAC equations:
            (a) initial guess of beta coefficients (could use L1 posterior
                mean or wp736 calibrated values)
            (b) compute PV terms using Phi from step 3:
                  PV(x)_{t|t-1} = e_x' * (I - Phi)^{-1} * Phi * z_{t-1}
                where e_x picks out variable x and z_{t-1} is the VAR
                state at t-1
            (c) OLS regression of the PAC equation with PV terms +
                trend objects (from step 2) as fixed regressors
            (d) update beta from OLS estimates
            (e) iterate until ||beta_new - beta_old|| < tol
         outputs: 5 PAC beta vectors + their OLS standard errors
```

### 3.2 Code skeleton

```
data/                       # unchanged from L1
  estimate_ces_2026.m
  estimate_trend_efficiency.m
  compute_trend_objects.m
  prepare_estimation_data.m   # could be simplified -- L2 doesn't need
                              # estimation_data.mat in the same form

dynare/                     # split into VAR + PAC components
  au_esat_var.mod             # NEW: 8-eq E-SAT VAR alone, Bayesian
                              # estimation with Minnesota prior
  au_pac_iterative_ols.m      # NEW: orchestrator script
    - loads VAR companion matrix from au_esat_var output
    - loads trend_series.mat
    - for each PAC block:
        - calls solve_pac_iterative_ols(beta_init, var_phi, trends)
        - returns beta_final, residuals, fit diagnostics

  pac_blocks/                 # NEW directory
    pac_consumption.m         # implements eq 35 with iterative OLS
    pac_business_inv.m        # implements eq 46
    pac_employment.m          # implements eq 30
    pac_va_price.m            # implements eq 16
    pac_housing_inv.m         # implements eq 37

  au_pac.mod                  # SIMULATION model only -- takes the L2
                              # posterior means as calibrated parameters
                              # and runs stoch_simul.
                              # No estimation block.  (Or keep both
                              # estimation modes side-by-side.)
```

### 3.3 The hard part — PV computation

The PAC expectation term `PV(x*)_{t|t-1}` is a forward-discounted sum of expected future values of the target variable. In Dynare 6.5 this is auto-generated via `pac.print()` against the var_model declaration.  For iterative OLS we need to compute it manually.

If the VAR state is `z_t = [yhat_au_t, i_au_t, pi_au_t, ..., trend_t]`, and the VAR is `z_t = Phi * z_{t-1} + eta_t`, then the expected value of any linear function `e_x' * z_{t+h}` given information at `t-1` is:

```
E[e_x' * z_{t+h} | t-1] = e_x' * Phi^{h+1} * z_{t-1}
```

The PV with quadratic adjustment cost discount factor `chi` is:

```
PV(x)_{t|t-1} = sum_{h=0..inf} chi^h * E[e_x' * z_{t+h} | t-1]
              = e_x' * (I - chi*Phi)^{-1} * Phi * z_{t-1}
```

where `chi` depends on the PAC block's β coefficients via wp736 Eq 7:
- For a depth-1 PAC: `chi = β_1 + ω`
- For deeper PAC (consumption depth 1, employment depth 4, etc.): chi solves the characteristic polynomial of the difference equation

Each iterative OLS step re-computes `chi` from the current β estimate, then re-computes PV terms, then re-OLS.

### 3.4 Iteration convergence

Typical convergence behaviour for iterative OLS on PAC (per wp736 §4.2):
- 5-15 iterations to reach `||Δβ|| < 1e-4`
- If diverging or oscillating: damping (β_new = α·β_OLS + (1-α)·β_old, α ≈ 0.5) usually fixes it
- Numerical issues with (I - chi*Phi)^{-1} when chi*Phi has eigenvalues near 1 — guard with `cond` check

### 3.5 Standard errors

Iterative OLS gives standard errors via the OLS variance-covariance matrix at convergence.  These are conditional on the calibrated VAR Phi and the trend series. They don't account for VAR estimation uncertainty.  wp1044 §3.5.1 footnote 28 notes this as a limitation; full uncertainty propagation would require either bootstrap or a two-stage Bayesian setup.

For first-pass L2 reporting, use the OLS SEs and note the limitation.

---

## 4. What L2 buys you and what it doesn't

**Buys**:
- Direct comparison to wp1044's French estimates (apples-to-apples)
- Cleanly identifiable β_PAC per block (no Kalman filter blending)
- ~~No mechanical LMD penalty from extra observables~~ -- struck out; the L1.3a Laplace evidence showed the predicted penalty was wrong-signed. Adding tightly-fit HP-trend observables *improves* LMD.
- Robust to block-level misspecification

**Doesn't buy**:
- Forecast accuracy (likely similar; the equations are the same)
- Counterfactual policy analysis (the *model* used for stoch_simul is the same regardless of how parameters were estimated)
- Convergence robustness (different failure modes: iterative OLS can hit numerical issues from cond((I-chi*Phi)^{-1}); MCMC can fail on multi-modal posteriors)

L2 is **about replicating wp1044's methodology**, not about being a better model.  If the goal is "FR-BDF as faithfully as possible on AU data", L2 is the destination.  If the goal is "best AU semi-structural model", L1 is fine.

---

## 5. Open questions to nail down before starting L2

1. **VAR estimation method**: Bayesian Minnesota prior (matches wp1044) or OLS lag-by-lag (simpler)?
2. **VAR specification**: which 8 variables, what lag order, what hyperparameters?
3. **PV computation**: closed form `(I - chi*Phi)^{-1}` (fast, requires invertibility) or sum-truncated (robust, slower)?
4. **Convergence tolerance and damping factor**: defaults from wp736 §4.2 (`tol = 1e-4`, `α = 1.0` then `α = 0.5` if oscillation detected)?
5. **Sample handling**: same 1993Q2-2023Q3 sample as L1, or extend?  (L1 sample is constrained by the 9-observable common-NaN requirement; L2 PAC equations can use longer samples for each block individually.)
6. **Cross-validation against L1**: side-by-side comparison report once L2 converges; how to interpret differences > 1 posterior SD?

---

## 6. Effort estimate

| Component | Effort | Notes |
|---|---|---|
| E-SAT VAR estimation | 2-3 days | Minnesota prior is standard; existing var_model declaration in .mod files is useful starting point |
| PV computation helper | 1-2 days | Mostly linear algebra; needs careful eigenvalue handling |
| Iterative OLS skeleton + 1 block (consumption) | 2-3 days | Same loop structure for all 5; consumption is the easiest |
| Remaining 4 PAC blocks | 3-4 days | Mostly mechanical once consumption works |
| Cross-validation report + writeup | 2 days | Compare L1 vs L2 vs wp1044 French numbers |
| **Total** | **~2 weeks** | Single full-time-equivalent week of focused work |

If 2 weeks is too much, the **partial L2** alternative is: implement just the consumption block's iterative OLS as a diagnostic to see whether `b_PAC_c` posterior shifts materially between the two estimators.  That's ~5-6 days and answers the headline question without the full rebuild.

---

## 7. Decision tree

```
L1.3a MCMC done
       |
       v
   compare(L1.3a, round12)  via report_l13a_results.m
       |
       +-- b_PAC_c posterior close to (1-b1_c)?     YES -> L1 is OK, stop here
       |
       NO
       v
   apply L1.3b scaffold (5-block extension)
       |
       v
   compare(L1.3b, L1.3a, round12)
       |
       +-- derived β_PAC blocks well-behaved?       YES -> L1 is enough
       |   (no negative, no Σβ > 1, chains converge)
       |
       NO -> consider partial L2 (consumption block iterative OLS)
       |
       v
   partial-L2 result
       |
       +-- b_PAC_c much closer to wp1044 expectation in L2?
       |       YES -> full L2 (~2 weeks)
       |       NO  -> live with L1 and document the gap
```

End of plan sketch.
