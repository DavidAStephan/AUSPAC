# PAC_EQUATIONS_AUDIT.md — wp1044 vs current AUSPAC L2 iterative-OLS implementation

Generated 2026-05-26 to audit whether the L2 partial replication (commit `abd8953`) faithfully reproduces wp1044's 5 PAC equations and their auxiliary VAR specifications. **TL;DR: it does not.** Substantial gaps exist for every block, ranging from minor (missing COVID dummies) to fundamental (wrong LHS variable; wrong ECM target; missing PV decomposition into trend + gap components).

Source: `references/FR-BDF-update.pdf` (wp1044, May 2026 update). All equation numbers refer to that document.

This document is the audit — it does not modify code. Use it to decide which gaps matter and which to close before iterating further.

---

## 1. VA-price Phillips (wp1044 §3.3, Eq 16)

### 1.1 wp1044 functional form

$$
\pi_{Q,t} = \mathrm{PV}(\pi^*_Q)_{t|t-1}
         + \beta_0 (p^*_{Q,t-1} - p_{Q,t-1})
         + \beta_1 \pi_{Q,t-1}
         + \beta_2 \hat{y}_t
         + (1 - \beta_1 - \omega) \bar{\pi}_{Q,t-1}
         + \sum_k \beta_{3+k} \delta_k + \varepsilon_t
$$

Where:
- $\pi_{Q,t}$ — **VA-price quarterly inflation** (NOT CPI)
- PV term is on the VA-price target's growth rate, `π*_Q`, at coefficient = 1 (structural)
- ECM term is the VA-price level gap `p*_Q - p_Q` (target level minus actual level, lagged)
- `β_2·ŷ_t` is **contemporaneous output gap**
- `(1 - β_1 - ω)·π̄_Q,t-1` is the derived-coefficient growth-neutrality term on the **trend** VA inflation
- COVID dummies `δ_COVID,20Q1..21Q1` plus three period-specific dummies `δ_{03Q2}`, `δ_{10Q4}`, `δ_{06Q3}`, `δ_{08Q1}`

Auxiliary equations (Eqs 17-20 + Table 3.3.4):
- **Eq 17**: $\pi^*_{Q,t} = \beta_0 (\pi_{W,t} - \Delta\bar{e}_t) + (1 - \beta_0) \bar{\pi}^*_{Q,t} + \varepsilon_t$  (VA-price target dynamics)
- **Eq 18**: Wage Phillips: $(1 - \rho L)[\pi_{W,t} - \Delta\bar{e}_t - \bar{\pi}^*_{Q,t}] = \beta_0 \hat{u}_t + \varepsilon_t$
- **Eq 19**: Okun's law: $\hat{u}_t = \beta_0 \hat{y}_t + \eta_t$, $\eta_t = \rho \eta_{t-1} + \varepsilon_t$
- **Eq 20**: Long-term efficiency unit-root: $\Delta\bar{e}_t = \Delta\bar{e}_{t-1} + \varepsilon_t$

The VAR state for `PV(π*_Q)` (Table 3.3.4):  
$z = [\hat{y}, i-\bar{i}, \pi_Q - \bar{\pi}_Q, \hat{y}_{EA}, \pi_{EA} - \bar{\pi}_{EA}, \hat{u}, \tilde{\pi}_W, \bar{\pi}^*_Q]$ (8 variables)

wp1044 estimates (Table 3.3.3): β_0=0.05, β_1=0.20, β_2=0.09, ω=0.62, R²=0.61. β_0 from Phillips=0.46.

### 1.2 Current AUSPAC L2 iterative-OLS spec (`estimate_all_pac_iterative.m`)

```matlab
LHS:           pi_au                        % CPI quarterly inflation (WRONG -- not π_Q)
ECM proxy:     lag(yhat_au)                 % output-gap lag (WRONG -- not p*_Q - p_Q level gap)
LHS lag:       lag(pi_au)                   % ✓ matches β_1 π_Q,t-1
Trend reg:     lag(pi_Q_bar)                % matches (1-β_1-ω) π̄_Q,t-1 structurally
PAC target:    pi_au (in VAR state)         % proxy for π*_Q -- it's the ACTUAL, not the TARGET
omega:         0.46 (calibrated)            % wp1044 uses 0.62 (different!)
PAC_exp:       (I - chi*Phi)^{-1} chi Phi z_{-1}, e_target picks pi_au from generic state z
```

VAR state (generic, shared across blocks):  
`z = [yhat_au, pi_au, i_au, i_10y, y_H_gap, c_gap, n_gap, ib_gap, ih_gap]` (9 vars)

### 1.3 Gaps for VA-price

| # | Gap | Severity | Notes |
|---|---|---|---|
| 1 | **LHS is `pi_au` (CPI), not `π_Q` (VA price)** | Critical | Different price index; CPI has VAT, energy, food; VA-price is producer side. wp1044 uses `pi_Q`. AUSPAC has `piQ` in the model but the OBSERVABLE in `estimation_data.mat` is `pi_au` (CPI). Needs a `piQ` observable. |
| 2 | **ECM term is `yhat_au_lag`, not `p*_Q - p_Q`** | Critical | wp1044 ECM is the price-LEVEL gap (target minus actual log VA price). My implementation uses the output gap lag as a proxy. Structurally different. |
| 3 | **Output gap enters lagged, not contemporaneous** | Major | wp1044 has `β_2 ŷ_t` (contemp). My OLS uses no contemporaneous output gap. |
| 4 | **PAC target in VAR is `pi_au` not `π*_Q`** | Major | wp1044's PV is over the inflation TARGET `π*_Q`, which is itself constructed from Eq 17 (wage growth + trend VA inflation). My proxy ignores this. |
| 5 | **ω = 0.46 vs wp1044's 0.62** | Minor | Calibrated AUSPAC value differs. Pre-existing AUSPAC choice. |
| 6 | **Missing 4 COVID dummies + 4 period dummies** | Minor | wp1044 has 8 dummies; my OLS has none. |
| 7 | **Missing wage Phillips (Eq 18) + Okun (Eq 19) aux equations in VAR** | Major | These are part of the wp1044 VAR for `PV(π*_Q)`. My generic state has no wage/Okun structure. |
| 8 | **VAR state lacks `u_gap`, `pi_w_gap`, `trend VA price`** | Major | wp1044 Table 3.3.4 state needs all three. |

### 1.4 Recommendation

For the VA-price block, my current OLS is essentially "AR(1) of CPI with lagged output gap and HP-trend VA inflation as controls". It's not a wp1044 replication. To match wp1044 Eq 16 properly:
- Build a `piQ` observable from `extended_dataset` (VA deflator from `prepare_supply_data.m` would work — supply_data.mat has `p_q_total_lvl`)
- Construct `π*_Q` via Eq 17 (needs wage growth + trend VA price)
- Add Okun + wage Phillips to the auxiliary VAR
- Replace `lag(yhat_au)` ECM with `(p*_Q - p_Q)` level gap

This is roughly a 1-2 day rebuild of just this block.

---

## 2. Employment (wp1044 §3.4.3, Eq 30)

### 2.1 wp1044 functional form

$$
\Delta n_{S,t} = \beta_0 (n^*_{S,t-1} - n_{S,t-1})
              + \mathrm{PV}(\Delta\bar{n}^*_S)_{t|t-1} + \mathrm{PV}(\Delta\hat{n}^*_S)_{t|t-1}
              + \beta_1 \Delta n_{S,t-1} + \beta_2 \Delta n_{S,t-2} + \beta_3 \Delta n_{S,t-3}
              + (1 - \beta_1 - \beta_2 - \beta_3 - \omega) \Delta\bar{n}^*_{S,t-1}
              + \beta_4 \Delta \hat{q}_t
              + \beta_5 \delta_{COVID,20Q2} + \beta_6 \delta_{COVID,20Q3} + \varepsilon_t
$$

Critical features:
- **Depth = 3** (three Δn lags), NOT 4 as I assumed
- **TWO PV terms**: `PV(Δn̄*)` (trend) + `PV(Δn̂*)` (gap) — decomposition of expectations into trend/cycle
- **Growth-neutrality at derived coefficient `(1-Σβ-ω)`** on the trend `Δn̄*_{S,t-1}` (separate from the PV)
- **ECM uses `n*_S - n_S`** (employment target level gap)
- **Contemporaneous `Δq̂_t`** = market VA gap growth
- 2 COVID dummies

Auxiliary equations:
- **Eq 31**: $\hat{n}^*_{S,t} = \beta_0 \hat{y}_{t-1} + \beta_3 \hat{n}^*_{S,t-1} + \varepsilon_t$ (employment gap target, AR(1) with output gap input)
- **Eq 32**: $\mathrm{PV}(\Delta\bar{n}^*_S)_{t|t-1} = \omega \Delta\bar{n}^*_{S,t-1}$ (calibrated unit-root trend, ω-weighted)

VAR state for the gap policy function (Table 3.4.10):  
$z = [\hat{y}, i-\bar{i}, \pi_Q - \bar{\pi}_Q, \hat{y}_{EA}, \pi_{EA} - \bar{\pi}_{EA}, \hat{n}^*_S]$ (6 vars)

wp1044 estimates (Table 3.4.9): β_0=0.07, β_1=0.44, β_2=0.12, β_3=0.12, β_4=0.13, ω=0.34, R²=0.95.

### 2.2 Current AUSPAC L2 iterative-OLS spec

```matlab
LHS:           dln_n              % 100*Δlog(au_employment) -- proxy for Δn_S
ECM proxy:     lag(n_gap)         % HP-gap of log(employment) lag (not Δlog!)
LHS lags:      4 (depth=4)        % WRONG -- wp1044 is depth=3
Trend reg:     lag(dn_bar)        % Δn̄_S trend growth
omega:         0.30               % wp1044 is 0.34 (close)
PAC target:    n_gap in state z
```

### 2.3 Gaps for Employment

| # | Gap | Severity | Notes |
|---|---|---|---|
| 1 | **Depth 4 vs wp1044's 3** | Critical | My iter OLS adds a 4th lag (b4_n) that doesn't exist in wp1044. Over-parameterization is likely why employment didn't converge (alternating β_d signs). |
| 2 | **Only ONE PV term, not two** | Critical | wp1044 has separate PV for trend Δn̄* and gap Δn̂* (decomposed expectations). My OLS has only PV(n_gap). |
| 3 | **Missing `Δq̂_t` contemporaneous regressor** | Major | wp1044's β_4·Δq̂_t (market VA gap growth) carries 0.13. Currently missing. |
| 4 | **Missing trend growth-neutrality term `(1-Σβ-ω)Δn̄*`** | Major | The derived-coefficient term on the trend. My implementation has it as a free coefficient (β_PAC), not derived. |
| 5 | **ECM proxy is HP gap of log(emp) lag, not `(n*_S - n_S)`** | Major | wp1044 uses the target-vs-actual level gap. The target `n*_S` comes from Eq 30 derivation (FOC of producer maximisation). My HP-gap proxy is different. |
| 6 | **Missing COVID dummies** | Minor | β_5, β_6 in wp1044. |
| 7 | **Auxiliary VAR missing `n̂*_S` (employment gap target) state** | Major | wp1044 Eq 31 auxiliary equation defines `n̂*_S` as an AR(1) with output gap input. Needed for the PV(Δn̂*) computation. |
| 8 | **VAR state lacks `i_gap`, `π_Q_gap`, foreign vars** | Major | wp1044 Table 3.4.10 state. My generic state has `i_au`, `i_10y`, `pi_au` instead. |

### 2.4 Recommendation

Employment failure to converge (max iter, ||delta||=2.58) was driven by gap #1 (over-parameterized depth) — fixing depth to 3 should restore convergence. Adding gap #3 (Δq̂_t contemp) likely lifts R². The decomposed expectations (gap #2) is a substantive wp1044 feature, but it requires building `n̂*_S` as an aux variable first. ~1 day to fix.

---

## 3. Consumption (wp1044 §3.5.1, Eqs 33–35)

### 3.1 wp1044 functional form

Long-run target (Eq 33):
$$
c^*_t = \alpha_0 + \mathrm{PV}(y_H)_{t|t-1} + \alpha_1 (r_{LH,t} - (\bar{i}_t - \bar{\pi}_t))
$$

Permanent income decomposition (Eq 34):
$$
\mathrm{PV}(y_H)_{t|t-1} = \mathrm{PV}(y_H - \bar{y})_{t|t-1} + \bar{y}_t
$$

Short-run (Eq 35):
$$
\Delta c_t = \beta_0 (c^*_{t-1} - c_{t-1}) + \beta_1 \Delta c_{t-1}
          + \mathrm{PV}^2(y_H - \bar{y})_{t|t-1}
          + \alpha_1 [\mathrm{PV}(r_{LH})_{t|t-1} - (\mathrm{PV}(\bar{i})_{t|t-1} - \mathrm{PV}(\bar{\pi})_{t|t-1})]
          + \beta_{PAC} (\Delta \bar{y}_{t-1})
          + \beta_2 [\Delta \log(W_H + TG_H) - p^{VAT}_{C,t} - \tilde{y}_t]
          + \beta_3 (\Delta r_{LH,t} - (\Delta \bar{i}_t - \Delta \bar{\pi}_t))
          + \beta_4..\beta_7 \delta_{COVID}
$$

Critical features:
- **`PV²(y_H - ȳ)` enters at coefficient = 1** (the squared PV is structural)
- **`α_1·PV(r_LH gap)` enters with `α_1` FREE-ESTIMATED** (α_1 is shared with the long-run Eq 33; wp1044 lists α_1=−1.15)
- **`β_PAC·Δȳ_{t-1}` is freely estimated** ("somewhat modified as non-stationary component of expectations is zero for gap terms")
- **HtM channel: `β_2·[Δlog(W_H + TG_H) - p^VAT_C - ỹ_t]`** — level-differential form with REAL wage+transfer income growth NET of HP-trend output growth `ỹ`
- **Impact rate term: `β_3·(Δr_LH - (Δī - Δπ̄))`** — contemporaneous change in real long rate
- 4 COVID dummies

Variables (Table 3.5.1): `y_H` = log real disposable income, `r_LH` = real household bank lending rate, `ỹ` = HP-trend of output GROWTH (note: of GROWTH, not level), `W_H + TG_H` = wages + government transfers in nominal terms, `p^VAT_C` = consumer price deflator including VAT.

Auxiliary equations (Appendix A.0.2, A.0.3):
- **A.0.2** equations for: `y_H,t - ȳ_t` (AR(1) with output gap + wage growth + unemployment), `Δw_eff,t` (real efficient wage growth, AR(1)), `û_t` (unemployment gap, AR(1) on output gap)
- **A.0.3 / Eq A.1**: `r_LH,t = β_0 r_LH,t-1 + (1-β_0)(ī - π̄ + β_3) + β_1 (i - ī) + β_2 (π̄ - π)` (real lending rate as AR(1) with policy/inflation drivers)

VAR state for `PV(y_H - ȳ)` and `PV²(y_H - ȳ)` (Table 3.5.3):  
$z = [\hat{y}, i-\bar{i}, \pi - \bar{\pi}, \hat{y}_{EA}, \pi_{EA} - \bar{\pi}_{EA}, y_H - \bar{y}, \Delta w_{eff}, \hat{u}, \mathrm{PV}(y_H - \bar{y})]$ (9 vars)

wp1044 estimates (Table 3.5.2): β_0=0.29, β_1=0.17, β_2=0.32, β_3=−1.07, α_1=−1.15 (from LR eq), R²=0.95.

### 3.2 Current AUSPAC L2 iterative-OLS spec

```matlab
LHS:           dln_c                              % ✓
ECM proxy:     lag(c_gap)                         % HP gap of log(consumption), proxy for (c* - c)
LHS lag:       lag(dln_c)                         % depth=1 ✓
Trend reg:     lag(dy_bar_gap)                    % matches β_PAC Δȳ_{t-1} ✓
PAC target:    c_gap in state                     % proxy
omega:         0.00                               % ✓ wp1044 says zero for gap terms
```

Plus my earlier standalone `estimate_consumption_pac_iterative.m` adds HtM channel `(y_H_gap - yhat_au)` but uses the AUSPAC Round 1.2 GAP form, not wp1044's level-differential form.

### 3.3 Gaps for Consumption

| # | Gap | Severity | Notes |
|---|---|---|---|
| 1 | **PV² of (y_H - ȳ) replaced by PV of c_gap** | Critical | wp1044 has `PV²(y_H - ȳ)_{t|t-1}` at coef=1. My OLS uses PV of c_gap (HP gap of consumption itself, not income vs trend output). Different structural object. |
| 2 | **No α_1·PV(r_LH - (ī-π̄)) term** | Critical | wp1044's forward-real-rate term. Missing entirely. |
| 3 | **HtM channel uses Round 1.2 GAP form not wp1044 level-differential** | Major | wp1044 uses `β_2·[Δlog(W_H + TG_H)/p^VAT_C - ỹ_t]`. AUSPAC Round 1.2 uses `b_HtM·(wt_H_real_gap - yhat_au)`. Different functional form. |
| 4 | **Missing impact rate term β_3·(Δr_LH - Δī + Δπ̄)** | Major | wp1044 estimate -1.07 — significant. Currently missing. |
| 5 | **Missing 4 COVID dummies** | Minor | β_4..β_7 in wp1044. |
| 6 | **No auxiliary y_H, w_eff, u_gap, r_LH equations in VAR** | Major | wp1044 Appendix A.0.2/A.0.3 has 4 aux equations driving PV computation. My generic state has none of them. |
| 7 | **ECM proxy `c_gap` ≠ wp1044's `(c* - c)` where c* is from Eq 33** | Major | wp1044's c* = α_0 + PV(y_H) + α_1·(r_LH - real LR rate). My proxy is just the HP gap of log consumption. |
| 8 | **β_PAC freely estimated ✓ but its variation is unidentified without c* properly constructed** | Linked to #7 | If c* is wrong, β_0 and the implied chi are wrong; cascades into β_PAC identification. |

### 3.4 Recommendation

Consumption is the most-divergent block. To match wp1044:
- Build `c*` from observables via Eq 33 (need real disposable income series `y_H`; wages+transfers approximation already in `au_wt_H_real_gap`)
- Add auxiliary equations for y_H, w_eff, u_gap in the VAR (Appendix A.0.2)
- Add `r_LH` aux equation (Appendix A.0.3) for the real lending rate dynamics
- Replace HtM channel from Round 1.2 form to wp1044 level-differential form
- Add impact rate term

~2-3 days for proper replication of just the consumption block.

---

## 4. Housing investment (wp1044 §3.5.2, Eqs 36–37)

### 4.1 wp1044 functional form

Long-run target (Eq 36):
$$
\log I^*_{H,t} = \gamma_0 + \mathrm{PV}(y_H)_{t|t-1}
               + \gamma_1 (p_{IH,t} - p_{C,t}) + \gamma_2 (p_{SH,t} - p_{C,t})
               + \gamma_3 [i_{LH,t} - \mathrm{PV}(\pi_Q)_{t|t-1} + \delta_H - (\bar{i}_t - \bar{\pi}_{Q,t})]
$$

Short-run (Eq 37):
$$
\Delta \log I_{H,t} = \beta_0 \log(I^*_{H,t-1}/I_{H,t-1}) + \beta_1 \Delta \log I_{H,t-1}
                    + \mathrm{PV}(\Delta \log \hat{I}^*_H)_{t|t-1} - \mathrm{PV}(\Delta \log \bar{I}^*_H)_{t|t-1}
                    + (1 - \beta_1 - \omega) \Delta \log \bar{I}^*_{H,t}
                    + \beta_2 (\Delta y_t - \tilde{y}_t)
                    + \beta_3 [(p_{SH,t-1} - p_{IH,t-1}) - (p_{SH,t-5} - p_{IH,t-5})]
                    + \beta_4..\beta_7 \delta_{COVID}
$$

Critical features:
- **TWO PV terms decomposed**: gap `PV(Δlog Î*_H)` MINUS trend `PV(Δlog Ī*_H)` — both at coef=1
- **Growth-neutrality `(1-β_1-ω)·Δlog Ī*_H,t`** on trend, contemporaneous (note: not lagged!)
- **`β_2·(Δy - ỹ)`** = output growth above its HP-growth-trend (contemp)
- **`β_3` lag-1 to lag-5 difference** in housing price spread `(p_SH - p_IH)`
- depth = 1 (single Δlog I_H lag)
- 4 COVID dummies

wp1044 estimates (Table 3.5.7): β_0=0.12, β_1=0.18, β_2=0.50, β_3=0.05, ω=0.05 implied, R²=0.89.

### 4.2 Current AUSPAC L2 iterative-OLS spec

```matlab
LHS:           dln_ih          % ✓
ECM proxy:     lag(ih_gap)     % HP gap of log(housing inv)
LHS lags:      depth=2         % WRONG -- wp1044 is depth=1
Trend reg:     lag(dlogIH_bar) % trend housing inv growth lag
omega:         0.30
```

### 4.3 Gaps for Housing inv

| # | Gap | Severity | Notes |
|---|---|---|---|
| 1 | **Depth 2 vs wp1044's 1** | Critical | b1_ih only in wp1044; my depth=2 over-parameterized. |
| 2 | **Only ONE PV term, not gap-minus-trend decomposition** | Critical | wp1044 has `PV(Δlog Î*_H) - PV(Δlog Ī*_H)` (gap-trend difference at coef=1). My single PV is different. |
| 3 | **Missing `(Δy - ỹ)` contemporaneous output growth gap** | Major | wp1044 β_2 = 0.50 — very large. Missing entirely. |
| 4 | **Missing price spread `[(p_SH - p_IH)_{t-1} - (p_SH - p_IH)_{t-5}]`** | Major | β_3 = 0.05 in wp1044; needs `pSH` and `pIH` series. AUSPAC doesn't have these in observables. |
| 5 | **Growth-neutrality term `(1-β_1-ω)Δlog Ī*_H` is contemporaneous, not lagged** | Minor | wp1044 has it at time t, not t-1. Subtle difference. |
| 6 | **Missing 4 COVID dummies** | Minor | β_4..β_7. |
| 7 | **ECM proxy `ih_gap` ≠ `log(I*_H / I_H)`** | Major | wp1044's I*_H comes from Eq 36 (LR target with permanent income + housing prices + user cost). My HP-gap is different object. |

### 4.4 Recommendation

Housing inv needs significant work — both the gap-trend PV decomposition and the contemporaneous output growth gap are missing. The price spread term needs `pSH` (existing housing deflator) and `pIH` (new housing deflator) which AUSPAC currently doesn't have. ~2-3 days.

---

## 5. Business investment (wp1044 §3.5.3, Eq 46)

### 5.1 wp1044 functional form

$$
\Delta \log I_{B,t} = \beta_0 \log(I^*_{B,t-1}/I_{B,t-1})
                    + \beta_1 \Delta \log I_{B,t-1} + \beta_2 \Delta \log I_{B,t-2}
                    + \mathrm{PV}(\Delta \hat{q})_{t|t-1} + \mathrm{PV}(\Delta \bar{q})_{t|t-1}
                    - \sigma \mathrm{PV}(\Delta \log \hat{r}_{KB})_{t|t-1}
                    - \sigma \mathrm{PV}(\Delta \log \bar{r}_{KB,t-1})_{t|t-1}
                    + (1 - \beta_1 - \beta_2 - \omega) \Delta \log \bar{r}_{KB,t-1}
                    + (1 - \beta_1 - \beta_2 - \omega) \Delta \bar{q}_{t-1}
                    + \beta_3 (\Delta df_t - \Delta \bar{df}_t)
                    + \beta_4..\beta_6 \delta_{COVID}
$$

Critical features (the most complex of the 5 PAC blocks):
- **FOUR PV terms**: `PV(Δq̂)` + `PV(Δq̄)` − σ·`PV(Δlog r̂_KB)` − σ·`PV(Δlog r̄_KB)` (gap+trend decomposition for BOTH market VA AND user cost, with σ scaling the user cost)
- **TWO growth-neutrality terms**: `(1-β_1-β_2-ω)·Δlog r̄_KB,t-1` AND `(1-β_1-β_2-ω)·Δq̄_t-1` — both derived coefficient
- **`β_3·(Δdf_t - Δd̄f_t)`** = synthetic final demand growth gap (df = household consumption + household investment + government investment + exports, chain-linked; NOT total VA — this was a wp1044 update)
- depth = 2 (two Δlog I_B lags)
- σ is the CES elasticity (=0.50 in wp1044)
- 3 COVID dummies

wp1044 estimates (Table 3.5.13): β_0=0.096, β_1=0.33, β_2=0.11, β_3=0.69, R²=0.83.

### 5.2 Current AUSPAC L2 iterative-OLS spec

```matlab
LHS:           dln_ib          % ✓ matches Δlog I_B
ECM proxy:     lag(ib_gap)     % HP gap of log(I_B)
LHS lags:      depth=2 ✓       % matches wp1044
Trend reg:     lag(dq_bar)     % market VA growth (one of two trend regressors!)
omega:         0.35
```

In an earlier spec (`pac_blocks_ols.m`) I also tested separate `dlog_rkb` and combined `(dq_bar - σ_ces · dlog_rkb)`; both fitted poorly.

### 5.3 Gaps for Business inv

| # | Gap | Severity | Notes |
|---|---|---|---|
| 1 | **Only ONE PV term, not four** | Critical | wp1044 has PV(Δq̂) + PV(Δq̄) − σ·PV(Δlog r̂_KB) − σ·PV(Δlog r̄_KB). My implementation collapses these to a single PV. |
| 2 | **Missing the second growth-neutrality term on `Δlog r̄_KB,t-1`** | Critical | wp1044 has TWO `(1-β_1-β_2-ω)`-scaled trend terms: one on q̄ and one on r̄_KB. My OLS has only one trend regressor (dq_bar). |
| 3 | **`(Δdf - Δd̄f)` synthetic demand term missing** | Critical | β_3 = 0.69 in wp1044 — the LARGEST coefficient. AUSPAC doesn't have synthetic final-demand `df` constructed. |
| 4 | **Missing 3 COVID dummies** | Minor | β_4..β_6. |
| 5 | **ECM proxy `ib_gap` ≠ `log(I*_B / I_B)`** | Major | I*_B comes from FOC of capital-labour substitution; my HP-gap is different. |
| 6 | **σ-scaling of user cost PV missing** | Major | The `-σ` factor on the user cost PV terms ties business inv to CES capital-labour substitution. Currently missing. |

### 5.4 Recommendation

Business inv is the most complex block. Why my one-shot OLS gave wrong-signed coefficients (commit `dd8f8c5`): I was missing the `Δdf` synthetic demand (the dominant driver) and the four-way PV decomposition. ~3 days to rebuild properly, but the new synthetic `df` series construction is the long pole.

---

## 6. Cross-block summary table

| Block | wp1044 depth | My depth | wp1044 PV terms | My PV | Missing major regressors | Convergence | wp1044 R² | My R² |
|---|---|---|---|---|---|---|---|---|
| VA-price | 1 | 1 ✓ | 1 | 1 (wrong target) | output gap contemp, 8 dummies, aux Phillips+Okun | converged | 0.61 | 0.04 ‼ |
| Employment | 3 | 4 ✗ | 2 (trend+gap) | 1 | Δq̂ contemp, derived trend term, 2 dummies, aux n̂* eq | max iter ✗ | 0.95 | 0.50 |
| Consumption | 1 | 1 ✓ | PV²(y_H-ȳ) + PV(r_LH gap) | PV(c_gap) | impact rate, HtM (wrong form), aux y_H/r_LH eqs, 4 dummies | converged | 0.95 | 0.27 |
| Housing inv | 1 | 2 ✗ | 2 (gap-trend) | 1 | (Δy-ỹ) contemp, price spread, contemp trend term, 4 dummies | converged | 0.89 | 0.65 |
| Business inv | 2 | 2 ✓ | 4 (q̂+q̄-σ·r̂_KB-σ·r̄_KB) | 1 | (Δdf-Δd̄f), σ-scaled user cost, second trend term, 3 dummies | converged | 0.83 | 0.73 |

R² gap is striking: every block significantly under-fits wp1044's R² because I'm missing major regressors.

---

## 7. Methodology gaps (beyond functional form)

1. **VAR(1) vs higher-order**: wp1044's E-SAT VAR has multiple lags. My VAR(1) is a simplification.
2. **OLS lag-by-lag vs Bayesian Minnesota prior**: wp1044 uses Bayesian estimation for the E-SAT VAR. My pure OLS gives different precision.
3. **Generic 9-var VAR shared across blocks vs block-specific VARs**: wp1044 tailors the VAR state per block (Tables 3.3.4, 3.4.10, 3.5.3, 3.5.8, 3.5.14, 3.5.15 each list different state variables). My single state is a shortcut.
4. **chi = Σβ_lags + ω simplification**: wp1044's chi is the smallest root of the depth-m characteristic polynomial. For depth 1 this matches; for depth 2+ the simplification is approximate.
5. **PV uses (I - χΦ)^-1 χΦ but wp1044 may use a slightly different operator form**: need to check wp736 §3 Eq 8 carefully — the χ enters inside the inverse but not always with χ multiplying Φ on the right. I've used `(I - χΦ)^-1 · χΦ` which gives `PV(x)_{t|t-1} = e_x' · χΦ(I-χΦ)^-1 z_{t-1}` (a single-period-ahead form). Should sanity-check against wp1044's Table 3.3.4 numerical policy function coefficients.

---

## 8. Effort estimate for proper wp1044 replication

| Block | Effort to reach wp1044 fidelity | Required data not yet in AUSPAC |
|---|---|---|
| VA-price | 1-2 days | `piQ` observable, π*_Q construction, wage Phillips, Okun |
| Employment | 1 day | n̂*_S construction (Eq 31), Δq̂ contemp |
| Consumption | 2-3 days | y_H, w_eff, u_gap aux eqs (App A.0.2), r_LH aux eq (A.0.3), wages+transfers level-differential HtM |
| Housing inv | 2-3 days | pSH, pIH (existing/new housing deflators), trend output growth ỹ, Δlog Ī*_H |
| Business inv | 3 days | Synthetic `df` final demand, separate trend r̄_KB regressor, σ-scaled user cost PV |
| Cross-cutting | 2 days | Block-specific VARs, characteristic-polynomial chi |
| **Total** | **~2 weeks** | |

This matches the original LEVEL_2_PLAN.md ~2-week estimate. The current `estimate_all_pac_iterative.m` is a 1-day approximation, not a wp1044 replication.

---

## 9. Honest assessment of the current L2 partial replication

What it IS: a quick diagnostic OLS that shares a single VAR state across all 5 blocks, uses HP-gap proxies for the wp1044 structural targets, omits most of the contemporaneous regressors and dummies, and uses an approximate `chi = Σβ + ω` formula.

What it IS NOT: a wp1044 replication. The structural targets, auxiliary equations, decomposed expectations, and block-specific VAR states are all wp1044 features that my code lacks.

**The "all β_PAC positive across 5 blocks" finding from commit `abd8953` is therefore not a vindication of wp1044's framework on AU data.** It's evidence that *something resembling a PAC growth-neutrality term* fits AU data with positive sign across blocks — but the structural objects being tested differ from wp1044's in every block.

A proper replication requires the additional ~2 weeks of work itemized above. Whether that's worth doing depends on whether the goal is methodological fidelity (do it) or AU-specific forecasting (the current AUSPAC L1 model is probably good enough).

---

## 10. Concrete next steps if pursuing proper replication

In priority order (highest-value-per-day first):

1. **Employment block fix** (~1 day): set depth=3, add Δq̂_t contemp, add n̂*_S aux equation, separate trend PV. Should restore convergence and raise R² toward wp1044's 0.95.

2. **VA-price block fix** (~2 days): build `piQ` observable from supply_data.mat `p_q_total_lvl`, construct π*_Q from Eq 17, add Phillips+Okun aux equations to VAR. This block currently has R²=0.04 — biggest gap.

3. **Block-specific VAR states** (~1 day): replace the single 9-var generic VAR with five block-specific VARs matching the wp1044 policy-function tables.

4. **Consumption block fix** (~3 days): wp1044 c* construction, aux equations for y_H/w_eff/u_gap, level-differential HtM, impact rate term. Biggest fix.

5. **Housing inv + business inv fixes** (~3 days each): require new observables not yet in AUSPAC.

Total to faithful wp1044 partial L2: ~2 weeks of focused work.

End of audit.
