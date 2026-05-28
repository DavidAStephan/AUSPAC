# E-SAT-shadows-structural Architecture Audit

**Created**: 2026-05-28
**Status**: Phase L2.A in progress
**Trigger**: identification of the `yhat_au` defining-equation error (E-SAT IS curve at au_pac.mod:1051 was *defining* `yhat_au` instead of the structural identity `Y_t/Y_{N,t} − 1`).

## The error pattern

FR-BDF (wp736 §2.3, §4.3, §4.3.3; wp1044 §3.1) explicitly designs the E-SAT model as a **tool agents use to form expectations** about future paths of `yhat`, `pi`, `i`. The E-SAT VAR contains an IS curve, a Phillips curve, and a Taylor rule, **but those equations do not determine the model's actual state variables**. Actual state variables are defined either structurally (CES production function for potential output; demand-side identity for actual GDP) or via behavioural PAC equations.

The error pattern is: **using an E-SAT VAR equation as the defining equation for an actual model state variable** instead of the structural identity. This corrupts monetary-policy transmission because the structural channels (PAC demand-block aggregation, deflator components, etc.) are short-circuited by the reduced-form E-SAT equation.

The yhat_au case (now fixed at au_pac.mod:1051) showed a 5–7× amplification in IRF magnitudes after correction — the structural channels were being dampened by the parallel E-SAT IS-curve channel.

## How to identify the error

For each model state variable `x` that has a corresponding E-SAT VAR equation, check whether `x` is defined by:

| Test | Pass | Fail |
|---|---|---|
| Is there a structural identity for `x` derivable from supply or demand block? | structural identity present | only E-SAT-style reduced form |
| Is `x` an "actual" macro variable (GDP, inflation, unemployment, real exchange rate)? | needs structural anchor | OK to use E-SAT form |
| Is `x` an "expectation" variable (with `_hat`, `_aux`, `_eq` suffix)? | OK to use E-SAT form | — |
| Is `x` an actual policy instrument (cash rate, fiscal stance)? | OK — central bank's reaction function IS the actual rule | — |

A defining equation with the pattern
```
x_t = ρ·x_{t−1} + a·(other_var_lag) + b·(other_var_lag) + ε_t
```
is **suspicious** when `x` is an actual macro variable — it looks like a reduced-form E-SAT equation. Cross-check against FR-BDF: if FR-BDF defines `x` structurally (via the production function, expenditure identity, deflator aggregation, etc.), then our equation should match that.

## Audit candidates in au_pac.mod

### Tier 1: confirmed candidates needing the same fix

#### 1.1 `pi_au_gap` — CPI inflation gap (au_pac.mod:1071)

**Current**:
```
pi_au_gap = λ_π·pi_au_gap(−1) + κ_π·yhat_au(−1) + α_pc·(piQ − pibar_au) + α_pc_lag·(piQ(−1) − pibar_au(−1))
          + β_pc_m·(pi_m − pibar_au) + γ_oil·dln_pcom + b_ECM_pc·(p_C_star(−1) − p_C(−1)) + ε_pi
```

Then `pi_au = pi_au_gap + pibar_au` (line 1042).

**FR-BDF design**: pi_au (headline CPI) is a **weighted aggregate of demand-side deflator components**: `pi_au = w_food·pi_au_food + w_energy·pi_au_energy + w_core·pi_au_core` (or equivalent decomposition). The Phillips curve is an E-SAT forecasting tool, not a defining equation.

We already have `pi_au_food`, `pi_au_energy` defined structurally (lines 1524, 1527). And `pi_c` (consumption deflator) at line 1416. The missing piece: define `pi_au` as the weighted sum, and demote line 1071 to an E-SAT auxiliary.

**Risk**: similar amplification of CPI IRFs (the architectural fix for yhat_au amplified GDP by 5–7×; CPI fix may amplify pi_au by 3–5×). This may push the model out of the "flat AU Phillips" regime if the demand-side deflator components have stronger transmission than the E-SAT Phillips.

**Recommended fix**:
1. Move line 1071 to an auxiliary equation labeled `pi_au_gap_esat_aux`
2. Replace pi_au definition with: `pi_au = w_cpi_food·pi_au_food + w_cpi_energy·pi_au_energy + (1 − w_cpi_food − w_cpi_energy)·pi_au_core`
3. Add structural equation for `pi_au_core` (likely follow pi_c equation form)
4. Keep `pi_au_gap = pi_au − pibar_au` as definitional

### Tier 2: candidates that need investigation but are likely OK

#### 2.1 `i_gap` — interest rate gap / Taylor rule (au_pac.mod:1054)

**Current**:
```
i_gap = λ_i·i_gap(−1) + (1 − λ_i)·(α_i·pi_au_gap(−1) + β_i·yhat_au(−1)) + ε_i
```

**FR-BDF design**: the EA Taylor rule inside E-SAT represents agents' expectation of ECB policy. The actual EA cash rate path may differ.

**Australia distinction**: the RBA has independent monetary policy, so this Taylor rule **is** the actual policy reaction function. No structural identity should override it.

**Verdict**: OK as-is. Document that for AU, this Taylor rule serves dual purpose (actual policy rule + expectation formation), unlike FR-BDF where the actual ECB rate is exogenous to France.

#### 2.2 `u_gap` — unemployment gap (au_pac.mod:1191)

**Current**:
```
u_gap = ρ_u_gap·u_gap(−1) + okun_coeff·yhat_au
```

This is **Okun's law** — a reduced-form structural relationship between output gap and unemployment gap. It's not an E-SAT equation per se; it's the standard semi-structural way to map output to unemployment.

**FR-BDF design**: §4.5 has labour market block where unemployment is determined by labour supply (workforce) minus labour demand (employment from PAC employment equation). The unemployment rate ratio is then computed structurally. FR-BDF doesn't appear to have an Okun's law shortcut — it has full labour market accounting.

**Verdict**: investigate. AU-PAC has `n_total_lvl`, `labour_force_lvl` in supply_data. We could in principle define `u_au = 1 − n_total/labour_force` structurally and use `u_gap = u_au − u_trend`. But the current Okun shortcut is a reasonable approximation given the PAC employment block already determines `dln_n`.

**Recommended action**: verify that `u_gap` driven by Okun is consistent with the dln_n from the employment PAC block. If they diverge, the model has two competing definitions of labour market slack. Either fix by:
- Defining `u_gap` from labour-market accounting (preferred for full FR-BDF fidelity)
- Or by adding a bridge equation that forces consistency

### Tier 3: variables that look like E-SAT but are correctly labelled and used

#### 3.1 The `*_hat` auxiliary variables

`piQ_hat, c_hat, ib_hat, ih_hat, n_hat, yh_ratio_hat, rKB_hat`

These are **explicitly** E-SAT auxiliary regressors (defined at lines ~977, 1002, 1011, 1024, 1033, 999, plus rKB_hat elsewhere). They follow VAR(1) structure with the core E-SAT state variables as drivers. They feed into the corresponding PAC equations as long-run targets via the `b0_x·(x_hat(−1) − x_level(−1))` ECM term.

**Verdict**: correctly designed. The `_hat` suffix signals expectation-formation; the PAC blocks consume `_hat` as their LR target.

#### 3.2 The `pac_expectation_pac_*` discounted-sum policy functions

These (lines ~968, 980, 1005, 1017, 1027) are the closed-form policy functions for the discounted-sum expectations that enter PAC equations. They are NOT E-SAT defining equations; they are the realised values of the forward-NPV under the assumed VAR.

**Verdict**: correctly designed.

#### 3.3 The forward-NPV recursions

`pv_i, pv_i_uip, pv_u_gap, pv_yh, pv_r_lh_gap` — these are forward-looking recursions (`pv_x = ... + β·pv_x(+1)`) used to compute model-consistent present values for the PAC equations. They are part of the PAC machinery, not E-SAT.

**Verdict**: correctly designed.

### Tier 4: things to double-check (not E-SAT errors but architecturally adjacent)

#### 4.1 `piQ` — VA price inflation (au_pac.mod:974)

```
diff(pQ_level) = b0_pQ·(piQ_hat(−1) − pQ_level(−1)) + b1_pQ·diff(pQ_level(−1))
               + pac_expectation_pac_pQ + yhat_au·b2_pQ + γ_ulc·(dln_ulc − pibar_au) + γ_uck·dln_uc_k + ε_pQ
```

This is the **PAC equation for VA price**. It's a structural behavioural equation, not E-SAT. The `piQ_hat` term is the E-SAT-style aux regression for the LR target (which is fine — that's how PAC equations consume E-SAT forecasts).

**Verdict**: correctly designed. piQ is the model's actual VA-price inflation.

#### 4.2 `s_gap` — real exchange rate gap (au_pac.mod:1304)

```
s_gap = ρ_s·s_gap(−1) − α_s·pv_i_uip + α_s·(pi_au_gap − pi_us_gap) + ε_s
```

This is the **UIP equation**. In FR-BDF, UIP is the actual exchange-rate equation (not E-SAT). It uses a forward-NPV `pv_i_uip` that integrates the future interest-rate gap.

**Verdict**: correctly designed. s_gap is the actual real exchange rate gap.

## Plan to execute the audit

### Step 1 (NOW — done in this session)
- Fix `yhat_au` (line 1051). Verify BK + IRF amplification.

### Step 2 (NEXT — separate PR)
- Fix `pi_au_gap` (line 1071). Structurally define `pi_au` from food/energy/core deflator components. Add `pi_au_core` structural equation. Demote line 1071 to E-SAT aux.

### Step 3 (LATER — optional)
- Investigate `u_gap` consistency with PAC employment dln_n. Decide whether to define `u_gap` from labour-market accounting or keep Okun shortcut.

### Step 4 (DOC)
- Update working paper §6.6 + §6.7 with the architectural-fix story:
  - §6.6 already documents the L2 OLS audit
  - Add §6.8 "Phase L2.A architectural fix: yhat_au and pi_au structural definitions"
  - Update Table 6.3 IRF peaks with post-architectural-fix values
  - Add comparison with RBA suite (AU-PAC now in mid-range, no longer conservative outlier)

## Heuristic for future development

When adding a new model state variable `x_t`, ask before writing its defining equation:

1. **Is there a CES, demand-identity, or deflator-aggregation derivation for x_t?** If yes, use that.
2. **Is x_t an actual policy instrument?** If yes, use the policy reaction function as the defining equation.
3. **Is x_t a behavioural variable with a PAC-style ECM target?** If yes, use a PAC equation with `x_hat` as the LR target.
4. **None of the above?** Then x_t may need a reduced-form equation — but verify it's not shadowing a structural identity that exists elsewhere.

If the candidate defining equation looks like an E-SAT IS curve, Phillips curve, or Taylor rule, the variable should usually be named `x_esat_aux` or `x_hat`, not `x_au` or `x_gap`. E-SAT equations are **forecasting tools for agents**, not **defining equations for the simulator**.
