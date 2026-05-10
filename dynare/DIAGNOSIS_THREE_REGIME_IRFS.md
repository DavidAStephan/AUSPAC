# Diagnosis: Why Three Expectation Regimes Produce Identical IRFs

> **STATUS: RESOLVED (2026-04-14, confirmed 2026-05-09).** The fix described
> below ("expand the TCM auxiliary equations to include E-SAT state variables")
> was implemented as the enriched 12-equation `var_model` (`esat_enriched`) that
> all three model variants now share. STATUS.md Table 6.3 confirms the three
> regimes now produce different IRFs (MCE attenuation 21–95% across blocks),
> matching FR-BDF Section 6 qualitatively. This file is retained as a record
> of the original problem and its diagnosis.

---


## Finding

Running `au_pac_var.mod`, `au_pac.mod` (hybrid), and `au_pac_mce.mod` with a monetary policy shock produces **identical IRFs** for output, consumption, investment, employment, and VA price inflation. Only the 10Y yield, exchange rate, and wage inflation timing differ.

This contradicts FR-BDF Figure 6.2.2, which shows clear differences across all three regimes for output and inflation.

## Root Cause

### Why our IRFs are identical

Each PAC equation uses a `trend_component_model` (TCM) with only **2 equations**:
1. A random walk for the target level: `x*_l = x*_l(-1) + eps`
2. An error-correction equation: `x_l = x_l(-1) + b0*(x*_l(-1) - x_l(-1)) + eps`

The h-vectors computed from this 2-equation system are functions of only `b0` (EC speed) and `beta_pac` (discount factor). They don't depend on E-SAT state variables (output gap, inflation, interest rate).

At first-order perturbation, the backward h-vector policy function and the forward MCE recursive equation produce **mathematically identical solutions** because the h-vectors ARE the rational expectations solution of the 2-equation TCM system. There's no wedge between backward and forward expectations.

### Why FR-BDF gets different IRFs

In FR-BDF, the backward-looking expectations are formed using the **E-SAT satellite model** — a simplified 8-equation VAR with IS curves, Phillips curves, and a Taylor rule. The E-SAT auxiliary equations (Tables 4.4.4, 4.5.7, 4.6.3, 4.6.11, 4.6.12) link each PAC target gap to E-SAT core state variables:

- Employment target gap depends on: `yhat(-1)`, `i_gap(-1)`, `pi_gap(-1)`, `n_gap(-1)`
- Consumption income-output ratio depends on: `yhat(-1)`, `i_gap(-1)`, `pi_gap(-1)`, `weff(-1)`, `u_gap(-1)`
- Business investment target depends on: `yhat(-1)`, `i_gap(-1)`, `pi_gap(-1)`, `rKB_gap(-1)`, `q_gap(-1)`

These auxiliary equations make the backward h-vectors depend on the full E-SAT state vector. The backward policy function from E-SAT predicts a **different** output path than the full model's RE solution because E-SAT is a simplified model missing many transmission channels.

Under MCE, the PAC expectation terms use the full model's RE solution instead (eqs 138-142), which incorporates all channels. This creates the wedge between backward and forward expectations.

## Fix Required

### For `au_pac.mod` (Hybrid) and `au_pac_var.mod` (VAR-based)

Enrich each TCM's non-target equation to include E-SAT core state variables. Instead of:

```
// Current: trivial EC equation
piQ_aux_l = piQ_aux_l(-1) + b0_pQ * (piQ_star_l(-1) - piQ_aux_l(-1))
```

Use an auxiliary equation that links to E-SAT dynamics:

```
// Enriched: EC + E-SAT state variable dependence
piQ_aux_l = piQ_aux_l(-1) + b0_pQ * (piQ_star_l(-1) - piQ_aux_l(-1))
          + a_pQ_y * yhat_au(-1) + a_pQ_i * i_gap(-1) + a_pQ_pi * pi_au_gap(-1)
```

This makes the TCM companion matrix depend on the E-SAT state, so the h-vectors become functions of yhat_au, i_gap, pi_au_gap — exactly as in FR-BDF's auxiliary equations.

**Challenge**: Dynare's `trend_component_model` only allows equations within the TCM block. Adding E-SAT variables to the TCM means those variables must be part of the TCM system. This may require expanding the TCM to include the E-SAT core equations, or using a `var_model` instead.

### For `au_pac_mce.mod` (Full MCE)

This file is already correct — it uses `pac_model` without `auxiliary_model_name`, so Dynare uses MCE mode with forward leads. The compiled dynamic equations confirm forward leads are present.

### Alternative approach: Manual omega with E-SAT policy functions

Instead of modifying the TCMs, we could revert to manual omega weights and compute them as E-SAT policy functions (like pre-Stage 14). This would give:
- VAR/Hybrid: `omega * k_0 * Z_{t-1}` where `k_0` depends on E-SAT companion matrix
- MCE: forward recursive PV equations (eqs 138-142)

This matches FR-BDF exactly but loses the native `pac_expectation()` machinery.

## Recommendation

**Short-term**: Expand the TCM auxiliary equations to include E-SAT state variables. This is the minimal change that preserves the Dynare PAC framework while creating the necessary wedge between backward and forward expectations.

**Long-term**: Implement the full FR-BDF approach where the E-SAT auxiliary equations are estimated as part of the PAC estimation pipeline (iterative OLS with E-SAT-derived expectation terms).
