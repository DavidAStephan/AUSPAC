# The AU-PAC Model: A Semi-Structural Macroeconomic Model for Australia

## David Stephan

### April 2026

---

## Abstract

This document presents AU-PAC, a semi-structural macroeconomic model for Australia adapted from the FR-BDF model of the Banque de France (Lemoine et al., 2019, WP #736). The model follows the FRB/US approach, combining Polynomial Adjustment Costs (PAC) with explicit expectations and a well-defined supply block. AU-PAC features a CES production function, five PAC behavioral equations with Dynare's native `pac_expectation()` machinery, a decomposed weighted average cost of capital, forward-looking permanent income and unemployment expectations, and Australia-specific channels including variable-rate mortgages and commodity prices. The model contains 131 equations (including Dynare auxiliaries), 41 shocks, and 95 endogenous variables, with 2 forward-looking variables under the hybrid expectation regime and 27 under full model-consistent expectations. It is implemented in Dynare 6.5 with MATLAB R2019a.

---

## 1. Introduction

AU-PAC is the Australian adaptation of the FR-BDF semi-structural model developed by the Banque de France for the French economy. The model is designed for monetary policy analysis, combining three features that are central to the FRB/US modeling tradition:

1. **Explicit expectations**: Agents form expectations about future economic conditions using either a backward-looking satellite VAR model (E-SAT) or model-consistent forward-looking expectations.

2. **Polynomial adjustment costs**: Non-financial behavioral equations are derived from agents minimizing costs of deviating from long-run targets subject to polynomial adjustment costs, yielding error-correction equations augmented with the present value of expected future target changes.

3. **Well-defined supply block**: A CES production function with labor-augmenting technical progress determines long-run output and provides consistent targets for employment, investment, and value-added prices through factor demand conditions.

### Key differences from FR-BDF

Australia differs from France in several economically important ways that are reflected in the model:

| Feature | France (FR-BDF) | Australia (AU-PAC) |
|---------|----------------|-------------------|
| Monetary policy | Exogenous (ECB sets rates) | Endogenous Taylor rule (RBA) |
| Foreign bloc | Euro area | United States |
| Exchange rate regime | Fixed within eurozone | Floating AUD/USD |
| Inflation target | 1.9% (ECB) | 2.5% (RBA midpoint) |
| Short-term rate | 3-month Euribor | RBA cash rate (~4.2% mean) |
| Mortgage structure | Mixed fixed/variable | Predominantly variable-rate |
| Commodity exposure | Low | High (mining exports) |

### Model dimensions

| Dimension | Count |
|-----------|-------|
| Equations (incl. Dynare auxiliaries) | 131 |
| Endogenous variables (core) | 95 |
| Exogenous shocks | 41 |
| Parameters | ~100 |
| Forward-looking variables (hybrid) | 2 |
| Forward-looking variables (full MCE) | 27 |
| PAC equations | 5 |
| Trend component models | 5 |

### Software

- Dynare 6.5 with native `pac_expectation()` and `trend_component_model` support
- MATLAB R2019a
- Model file: `dynare/au_pac.mod` (VAR-based/hybrid), `dynare/au_pac_mce.mod` (full MCE)

---

## 2. Bird's Eye View

### 2.1 Model structure

AU-PAC is organized into the following blocks, with expectations playing a role in most non-financial and financial equations:

```
SUPPLY BLOCK                    NOMINAL BLOCK
- CES production function       - Wage Phillips curve (fwd PV of u_gap)
- Capital accumulation          - VA price: CES unit cost dual (PAC)
- Employment target             - Demand deflators: ECM equations
- TFP process                   - User cost of capital
         |                               |
         v                               v
    EXPECTATIONS              DEMAND BLOCK
    E-SAT (VAR) or           - Consumption: permanent income PV (PAC)
    Model-consistent          - Business investment: CES user cost (PAC)
    (MCE)                     - Household investment: mortgage rate (PAC)
         |                    - Employment: 4th-order (PAC)
         v                               |
FINANCIAL BLOCK                          v
- Term structure              TRADE BLOCK
- WACC (3 components)         - Exports ECM (world demand)
- Exchange rate (UIP)         - Imports ECM (IAD weights)
- Bank lending rates
         |                    GOVERNMENT + IDENTITY
         v                    - Fiscal rule
    Feedback loops            - GDP expenditure identity
    (bridge equation)         - Bridge to IS curve
```

Variables directly affected by expectations appear throughout the model: the 5 PAC equations (VA price, consumption, business investment, household investment, employment), the term structure, exchange rates, the wage Phillips curve (via the present value of expected future unemployment gaps), and the consumption target (via the present value of expected permanent income).

### 2.2 Expectation regimes

The model can be solved under three expectation regimes, following FR-BDF Section 6:

| Regime | Financial expectations | Non-financial expectations | File |
|--------|----------------------|--------------------------|------|
| **VAR-based** | Backward (E-SAT h-vectors) | Backward (E-SAT h-vectors) | `au_pac.mod` with pv_u_gap/pv_yh set backward |
| **Hybrid** | Forward (pv_u_gap, pv_yh leads) | Backward (PAC h-vectors from TCM) | `au_pac.mod` (current default) |
| **Full MCE** | Forward | Forward (pac_expectation expands to leads) | `au_pac_mce.mod` |

Under the hybrid regime (the baseline), the 5 PAC expectations use VAR-based h-vectors from trend component model companions, while the unemployment and permanent income present values use forward-looking recursive forms. Under full MCE, all expectations are forward-looking, with 27 eigenvalues larger than 1 (compared to 2 under the hybrid).

### 2.3 Key transmission channels

A monetary policy tightening (positive eps_i shock) transmits through:

1. **Interest rate channel**: Short rate -> long rate (term structure) -> WACC -> user cost of capital -> business investment target
2. **Exchange rate channel**: Short rate -> UIP -> AUD appreciation -> exports fall, imports cheaper -> disinflation
3. **Mortgage channel**: Short rate -> long rate -> bank lending rate -> household investment (strongest sensitivity: b4_ih = -0.05)
4. **Expectations channel**: Short rate enters E-SAT core -> all PAC h-vectors shift -> consumption, investment, employment, VA price expectations update
5. **Wage-price channel**: Output gap -> unemployment gap PV -> wage Phillips curve -> ULC -> VA price target -> all deflators
6. **Permanent income channel**: Output gap -> PV of future income (beta_c=0.95 discount) -> consumption target

---

## 3. Expectation Formation and the PAC Framework

### 3.1 The E-SAT expectation satellite model

The Expectation SATellite model (E-SAT) is a structural VAR with 8 core equations plus auxiliary equations for specific targets. Agents with limited information form expectations by forecasting from this small model.

#### Core equations

The core of E-SAT relates the Australian output gap, inflation, and interest rate to their US counterparts through IS curves, Phillips curves, and a Taylor rule:

**Australian IS curve:**

(1 - lambda_q * L) * yhat_au = delta * yhat_us - sigma_q * (i_gap(-1) - pi_au_gap(-1)) + eps_q

**Australian Phillips curve:**

(1 - lambda_pi * L) * pi_au_gap = kappa_pi * yhat_au(-1) + eps_pi

**Taylor rule:**

(1 - lambda_i * L) * i_gap = (1 - lambda_i) * (alpha_i * pi_au_gap(-1) + beta_i * yhat_au(-1)) + eps_i

**US IS curve:**

yhat_us = lambda_q_us * yhat_us(-1) + eps_q_us

**US Phillips curve:**

(1 - lambda_pi_us * L) * pi_us_gap = kappa_pi_us * yhat_us(-1) + eps_pi_us

**Anchor equations** (3): Interest rate, AU inflation, and US inflation anchors follow AR(1) processes toward their steady-state values.

#### Bayesian estimation

E-SAT was estimated using Bayesian methods (Metropolis-Hastings, 50,000 draws, 2 chains) on quarterly Australian data from 1993Q1 to 2024Q4. The posterior means are:

| Parameter | Description | Posterior Mean |
|-----------|-------------|---------------|
| delta | AU-US demand spillover | 0.199 |
| lambda_q | AU output gap persistence | 0.448 |
| sigma_q | Real rate sensitivity | 0.166 |
| lambda_i | Taylor rule inertia | 0.828 |
| alpha_i | Taylor rule inflation weight | 0.279 |
| beta_i | Taylor rule output weight | 0.135 |
| lambda_pi | AU inflation persistence | 0.263 |
| kappa_pi | Phillips curve slope | 0.058 |
| lambda_q_us | US output gap persistence | 0.806 |
| lambda_pi_us | US inflation persistence | 0.653 |
| kappa_pi_us | US Phillips slope | 0.013 |

**Steady-state values**: i_ss = 1.049% quarterly (~4.2% annual), pi_ss_au = 0.625% quarterly (~2.5% annual), pi_ss_us = 0.50% quarterly (~2.0% annual).

#### Companion matrix and expectation computation

The E-SAT model can be written in structural VAR form AZ_t = BZ_t-1 + eps_t, yielding the reduced form Z_t = HZ_t-1 + eta_t where H = A^(-1)B. The i-step-ahead forecast is Z^e_{t+i} = H^i * Z_t, which allows computation of discounted present values of any variable in the E-SAT state vector.

### 3.2 PAC microfoundations

The Polynomial Adjustment Costs framework derives behavioral equations from agents minimizing a cost function that penalizes deviations from a target y*_t and m differences of the decision variable y_t:

C_t = sum_{i=0}^{infinity} beta^i * [(y_{t+i} - y*_{t+i})^2 - sum_{k=1}^{m} b_k * ((1-L)^k * y_{t+i})^2]

The first-order condition yields an error-correction equation augmented with the present value of expected future target changes:

Delta y_t = a_0 * (y*_{t-1} - y_{t-1}) + sum_{k=1}^{m-1} a_k * Delta y_{t-k} + sum_{i=0}^{infinity} d_i * Delta y*_{t+i}

where a_0 is the error-correction speed, a_k are the AR lag coefficients, and sum d_i (denoted omega) is the share of nonstationary expectations. Growth neutrality requires 1 - sum a_k - omega = 0 on the balanced growth path.

The five PAC equations in AU-PAC have the following orders of adjustment costs:

| Equation | m (order) | AR lags | Discount beta |
|----------|-----------|---------|---------------|
| VA price inflation | 1 | 1 | 0.98 |
| Consumption | 1 | 1 | 0.98 |
| Business investment | 2 | 2 | 0.98 |
| Household investment | 2 | 2 | 0.98 |
| Employment | 4 | 4 | 0.98 |

### 3.3 PAC implementation in Dynare

AU-PAC uses Dynare 6.5's native `pac_expectation()` with `trend_component_model` (TCM) companions. Each PAC equation has:

1. A **TCM declaration** specifying 2 equations: a non-target error-correction equation and a target random walk.
2. A **pac_model declaration** linking the TCM to the PAC equation with a discount factor and growth term.
3. The **PAC equation** itself, with `pac_expectation(pac_xxx)` replacing the infinite sum of expected future target changes.

Under VAR-based expectations, Dynare computes h-vectors k_0 and k_1 from the TCM companion matrix, so that the present value of expected target changes equals k_0 * Z_{t-1} (stationary component) plus k_1 * Z_{t-1} (nonstationary component).

#### h-vector analysis

The h-vectors from the TCM companion matrices weight future target changes more heavily than the manual omega approximation used before the migration to native PAC:

| PAC equation | Manual omega | h-vector sum | Amplification ratio |
|---|---|---|---|
| VA price | ~0.45 | 0.452 | 1.0x |
| Consumption | 0.369 | 0.678 | **1.84x** |
| Business investment | 0.350 | 0.501 | **1.43x** |
| Household investment | 0.300 | 0.569 | **1.90x** |
| Employment | 0.300 | 0.446 | **1.49x** |

This 1.4-1.9x amplification confirms the FR-BDF Section 6 finding that forward expectations amplify monetary transmission.

### 3.4 Model-consistent expectations (MCE)

Under MCE, the `pac_model` declarations omit the `auxiliary_model_name` parameter, causing Dynare to expand `pac_expectation()` into forward-looking recursive leads of the target variable. The MCE form (FR-BDF eqs 138-142) is:

Z_t = -sum_{i=1}^{m} alpha_i * beta^(i+1) * Z_{t+i} + A(1) * [Delta y*_t + double_sum_terms]

where the alpha parameters are computed from the PAC polynomial's EC and AR coefficients. The MCE version (`au_pac_mce.mod`) has 27 forward-looking variables compared to 2 under the hybrid regime.

---

## 4. Model Specification

### 4.1 Notation

| Prefix/Suffix | Meaning | Example |
|---|---|---|
| `dln_` | Log difference (quarterly growth) | `dln_c` = consumption growth |
| `_gap` | Deviation from target/trend | `i_gap` = i_au - ibar |
| `_star` | Target/desired value | `dln_c_star` = target consumption growth |
| `_bar` | Trend/long-run value | `pibar_au` = LR inflation anchor |
| `pi_` | Inflation rate | `piQ` = VA price inflation |
| `s_` | Spread | `s_COE` = equity spread |
| `pv_` | Present value of expectations | `pv_u_gap` = PV of future unemployment gaps |

### 4.2 Supply block

#### CES production function (FR-BDF eq 24)

The production technology for market branches is a CES function with labor-augmenting technical progress:

Q_t = gamma * [alpha * K_t^((sigma-1)/sigma) + (1-alpha) * (E_t * H_t * N_t)^((sigma-1)/sigma)]^(sigma/(sigma-1))

where K_t is capital services, N_t is employment, H_t is hours per worker, E_t is labor-augmenting efficiency, and sigma is the elasticity of substitution between capital and labor.

In the gap model (where all growth rates are zero at steady state), this is implemented in growth-rate form:

```
[eq_dln_y_star]
dln_y_star = alpha_k * dln_k + (1 - alpha_k) * dln_n_star_bar + dln_tfp
```

#### Capital accumulation (FR-BDF eq 32)

Capital services evolve according to the linearized accumulation equation:

```
[eq_dln_k]
dln_k = (1 - delta_k) * dln_k(-1) + delta_k * dln_ib
```

At steady state, I/K = delta_k, so investment maintains the capital stock. The (1-delta_k) persistence means capital adjusts gradually — a temporary investment boom has a persistent effect on the capital stock.

#### TFP process

```
[eq_dln_tfp]
dln_tfp = rho_tfp * dln_tfp(-1) + eps_tfp
```

with rho_tfp = 0.99 (near unit root). Labor productivity is derived as dln_prod = dln_tfp / (1-alpha_k).

#### Calibration

| Parameter | Value | Description |
|-----------|-------|-------------|
| sigma_ces | 0.53 | CES substitution elasticity (FR-BDF Table 4.3.2) |
| alpha_k | 0.33 | Capital share |
| delta_k | 0.025 | Quarterly depreciation (~10% annual) |
| rho_tfp | 0.99 | TFP persistence |
| gamma (scale) | 0.34 | CES scale parameter |
| mu (markup) | 1.31 | Monopolistic competition markup |

### 4.3 Value-added price (FR-BDF Section 4.4)

#### Target: CES unit cost dual (Factor Price Frontier)

The VA price target derives from the CES dual cost function. In log-linearized growth rates, the target depends on both unit labor cost growth (labor share channel) and user cost growth (capital share channel):

```
[eq_piQ_star]
piQ_star = rho_pQ_star * piQ_star(-1)
         + gamma_ulc * dln_ulc
         + gamma_uck * dln_uc_k
         + (1 - rho_pQ_star - gamma_ulc) * pibar_au
```

where dln_ulc = pi_w - dln_prod (unit labor cost growth) and dln_uc_k = uc_k - uc_k(-1) (user cost growth).

**Growth neutrality**: At SS, dln_ulc = pi_ss_au, dln_uc_k = 0, pibar_au = pi_ss_au. Then piQ_star_ss = (rho_pQ_star + gamma_ulc + (1-rho_pQ_star-gamma_ulc)) * pi_ss_au + gamma_uck * 0 = pi_ss_au.

#### Short-run PAC equation

```
[eq_piQ_pac]
diff(pQ_level) = b0_pQ * (piQ_star_l(-1) - pQ_level(-1))
               + b1_pQ * diff(pQ_level(-1))
               + pac_expectation(pac_pQ)
               + b2_pQ * yhat_au
               + eps_pQ
```

| Parameter | Value | Description |
|-----------|-------|-------------|
| b0_pQ | 0.06 | Error correction speed |
| b1_pQ | 0.50 | Persistence |
| b2_pQ | 0.09 | Output gap sensitivity |
| rho_pQ_star | 0.95 | Target persistence |
| gamma_ulc | 0.12 | ULC pass-through (labor share) |
| gamma_uck | 0.06 | User cost pass-through (capital share) |

#### Wage-price spiral

The VA price target depends on ULC, which depends on wages (pi_w), which depend on the output gap through the Phillips curve. This creates the wage-price spiral:

demand shock -> yhat_au -> pi_w (Phillips) -> dln_ulc -> piQ_star -> piQ (PAC) -> pi_c -> real wages -> demand

### 4.4 Labor market (FR-BDF Section 4.5)

#### Wage Phillips curve (FR-BDF eq 52)

Wage inflation depends on lagged wage inflation (persistence), current CPI inflation (indexation), the present value of expected future unemployment gaps (forward-looking labor market tightness), the inflation anchor, and productivity growth:

```
[eq_pi_w]
pi_w = lambda_w * pi_w(-1)
     + gamma_w * pi_au
     + kappa_w * pv_u_gap
     + (1 - lambda_w - gamma_w) * pibar_au
     + (1 - lambda_w) * dln_prod
     + eps_w
```

The forward-looking unemployment gap present value is defined recursively:

```
[eq_pv_u_gap]
pv_u_gap = (1 - beta_w) * u_gap + beta_w * pv_u_gap(+1)
```

where the unemployment gap follows Okun's law:

```
[eq_u_gap]
u_gap = rho_u_gap * u_gap(-1) + okun_coeff * yhat_au
```

| Parameter | Value | Description |
|-----------|-------|-------------|
| lambda_w | 0.247 | Wage persistence (posterior mean) |
| kappa_w | 0.238 | Sensitivity to expected unemployment (posterior) |
| gamma_w | 0.15 | CPI indexation weight |
| okun_coeff | -0.33 | Okun's law coefficient |
| rho_u_gap | 0.94 | Unemployment gap persistence |
| beta_w | 0.98 | Discount for expected future unemployment |

**Growth neutrality**: At SS with dln_prod = 0, pi_w_ss = pi_ss_au. On the balanced growth path with productivity growth g, pi_w_ss = pi_ss_au + g (wages grow at inflation + productivity).

#### Employment target (FR-BDF eq 55)

The target is derived from the CES first-order condition for labor, inverted for employment:

```
[eq_dln_n_star_bar]
dln_n_star_bar = dln_tfp / (1 - alpha_k) - sigma_ces * rw_gap
```

where rw_gap = pi_w - piQ - dln_prod is the real wage growth gap. When real wages rise above productivity (rw_gap > 0), firms reduce labor demand proportionally to sigma_ces.

#### Employment PAC equation (FR-BDF eq 56, 4th-order)

```
[eq_dln_n_pac]
diff(ln_n_level) = b0_n * (n_star_l(-1) - ln_n_level(-1))
                 + b1_n * diff(ln_n_level(-1))
                 + b2_n * diff(ln_n_level(-2))
                 + b3_n * diff(ln_n_level(-3))
                 + b4_n * diff(ln_n_level(-4))
                 + pac_expectation(pac_n)
                 + b5_n * yhat_au
                 + eps_n
```

The 4th-order adjustment costs capture the fact that employment adjustment is very costly and gradual in practice. The `pac_expectation(pac_n)` term captures labor hoarding: when a negative demand shock is expected to be temporary, firms cut fewer jobs because the expected employment target will recover.

### 4.5 Demand block (FR-BDF Section 4.6)

#### Household consumption (1st-order PAC, FR-BDF eqs 59-61)

The consumption target depends on permanent income — the discounted present value of expected future output gaps:

```
[eq_pv_yh]
pv_yh = (1 - beta_c) * yhat_au + beta_c * pv_yh(+1)
```

with beta_c = 0.95 (~25% annual discount rate). This heavy discounting reflects risk aversion and income uncertainty and is key to avoiding the forward guidance puzzle.

The consumption target grows with changes in permanent income:

```
[eq_dln_c_star_bar]
dln_c_star_bar = kappa_inc * (pv_yh - pv_yh(-1))
```

The short-run PAC equation:

```
[eq_dln_c_pac]
diff(ln_c_level) = b0_c * (c_star_l(-1) - ln_c_level(-1))
                 + b1_c * diff(ln_c_level(-1))
                 + pac_expectation(pac_c)
                 + b2_c * i_gap(-1)
                 + b3_c * yhat_au
                 + eps_c
```

| Parameter | Value | Description |
|-----------|-------|-------------|
| b0_c | 0.060 | Error correction speed |
| b1_c | 0.149 | Persistence (posterior) |
| b2_c | -0.02 | Interest rate sensitivity (substitution) |
| b3_c | 0.139 | Output gap sensitivity (HtM proxy, posterior) |
| beta_c | 0.95 | Permanent income discount |
| kappa_inc | 0.050 | Permanent income sensitivity |

#### Business investment (2nd-order PAC, FR-BDF eqs 63-64)

The investment target derives from the CES capital demand first-order condition. In growth rates, desired investment depends on output (accelerator) and the user cost of capital:

```
[eq_dln_ib_star_bar]
dln_ib_star_bar = kappa_ib_y * yhat_au - sigma_ces * dln_uc_k
```

where the user cost is uc_k = wacc + delta_k - (pi_ib - piQ), combining financial cost (WACC), depreciation, and capital gains.

```
[eq_dln_ib_pac]
diff(ln_ib_level) = b0_ib * (ib_star_l(-1) - ln_ib_level(-1))
                  + b1_ib * diff(ln_ib_level(-1))
                  + b2_ib * diff(ln_ib_level(-2))
                  + pac_expectation(pac_ib)
                  + b3_ib * yhat_au
                  + b4_ib * i_gap(-1)
                  + eps_ib
```

| Parameter | Value | Description |
|-----------|-------|-------------|
| b0_ib | 0.030 | Error correction |
| b1_ib | 0.181 | 1st lag (posterior) |
| b2_ib | 0.10 | 2nd lag |
| b3_ib | 0.191 | Output gap (accelerator, posterior) |
| b4_ib | -0.03 | Interest rate sensitivity |
| kappa_ib_y | 0.06 | Output proportionality in target |
| sigma_ces | 0.53 | CES user cost elasticity |

#### Household investment (2nd-order PAC, FR-BDF eqs 66-67)

The housing investment target depends on the mortgage rate gap and the housing price gap (Tobin's Q for housing):

```
[eq_dln_ih_star_bar]
dln_ih_star_bar = -kappa_mort * (i_lh - (i_ss + tp_ss + spread_lh)) + kappa_ph * ph_gap(-1)
```

When mortgage rates rise above steady state, housing investment falls. When house prices are above trend (ph_gap > 0), the incentive to build new housing rises.

| Parameter | Value | Description |
|-----------|-------|-------------|
| b0_ih | 0.049 | Error correction |
| b4_ih | -0.05 | Interest rate sensitivity (**strongest** of all demand components) |
| kappa_mort | 0.048 | Mortgage rate gap -> target |
| kappa_ph | 0.03 | Housing price Tobin's Q |

Australia's variable-rate mortgage dominance makes this the strongest interest rate transmission channel.

#### External trade (FR-BDF Section 4.6.4)

**Exports** follow an error-correction model driven by world demand (proxied by the US output gap) and price competitiveness:

```
[eq_dln_x]
dln_x = b0_x * x_gap(-1) + b1_x * dln_x(-1) + b2_x * yhat_us
      + b3_x * s_gap + b4_x * dln_pcom + eps_x
```

**Imports** use import-adjusted demand (IAD) rather than the raw output gap, with weights reflecting the import content of each expenditure component:

```
[eq_dln_m]
dln_m = b0_m * m_gap(-1) + b1_m * dln_m(-1) + b2_m * iad + b3_m * s_gap + eps_m
```

where iad = 0.12*dln_c + 0.25*dln_ib + 0.15*dln_ih + 0.08*dln_g + 0.30*dln_x.

### 4.6 Demand deflators (FR-BDF Section 4.7)

All demand deflators follow error-correction equations tracking the VA price with partial pass-through, anchored to the long-run inflation target:

```
pi_j = rho_j * pi_j(-1) + alpha_j * piQ + beta_j_m * pi_m + ... + (1 - rho_j - alpha_j - beta_j_m) * pibar_au
```

| Deflator | rho | alpha (VA price) | beta_m (import) | beta_s (FX) | Other |
|----------|-----|-----------------|-----------------|-------------|-------|
| Consumption (pi_c) | 0.40 | 0.30 | 0.10 | — | gamma_oil=0.03 |
| Business inv. (pi_ib) | 0.35 | 0.25 | 0.12 | — | — |
| Housing inv. (pi_ih) | 0.45 | 0.25 | 0.08 | — | — |
| Exports (pi_x) | 0.30 | 0.20 | — | -0.05 | alpha_pcom=0.10 |
| Imports (pi_m) | 0.30 | 0.15 | — | 0.08 | beta_pm_com=0.05 |
| Government (pi_g) | 0.50 | 0.30* | — | — | — |

*Government deflator uses (pi_w - dln_prod) instead of piQ, reflecting public sector wage costs.

All satisfy growth neutrality: at SS, pi_j = piQ = pibar_au = pi_ss_au = 0.625%.

### 4.7 Financial block (FR-BDF Section 4.8)

#### Term structure (FR-BDF eq 95)

```
[eq_i_10y]
i_10y = rho_L * i_10y(-1) + (1 - rho_L) * (i_au + tp) + eps_10y
```

with rho_L = 0.900 and tp following AR(1) with rho_tp = 0.98, tp_ss = 0.30% quarterly.

**SS**: i_10y = 1.049 + 0.30 = 1.349% quarterly (~5.4% annual).

#### WACC decomposition (FR-BDF eqs 98-100)

The weighted average cost of capital decomposes into three funding sources:

```
[eq_wacc]
wacc = 0.5 * i_COE + 0.3 * i_LB_firms + 0.2 * i_BBB
```

Each rate = 10Y government rate + spread, where spreads follow AR(1):

| Component | Weight | Spread SS | Spread rho | Annual rate at SS |
|-----------|--------|-----------|------------|-------------------|
| Cost of equity (i_COE) | 0.50 | 0.80% | 0.92 | ~8.6% |
| Bank lending (i_LB_firms) | 0.30 | 0.25% | 0.77 | ~6.4% |
| BBB bonds (i_BBB) | 0.20 | 0.05% | 0.94 | ~5.6% |
| **WACC** | **1.00** | — | — | **~7.3%** |

#### Exchange rate (FR-BDF eq 105)

Modified UIP with inflation differential and persistent deviations from PPP:

```
[eq_s_gap]
s_gap = rho_s * s_gap(-1) - alpha_s * i_gap + alpha_s * (pi_au_gap - pi_us_gap) + eps_s
```

s_gap > 0 = AUD depreciation. Higher AU rates attract capital, appreciating the AUD.

#### User cost of capital (FR-BDF eq 28/65)

```
[eq_uc_k]
uc_k = wacc + delta_k - (pi_ib - piQ)
```

Financial cost (WACC) + depreciation - capital gains (investment deflator vs VA price).

**SS**: uc_k = 1.834 + 0.025 = 1.859% quarterly (~7.4% annual).

### 4.8 Government and GDP identity (FR-BDF Section 4.9-4.10)

#### Fiscal rule

```
[eq_dln_g]
dln_g = rho_g * dln_g(-1) + phi_g * yhat_au + eps_g
```

Countercyclical: phi_g = -0.10 means a positive output gap reduces government spending growth.

#### GDP expenditure identity

```
[eq_gdp_identity]
yhat_dom = 0.55*dln_c + 0.13*dln_ib + 0.06*dln_ih + 0.24*dln_g + 0.25*dln_x - 0.23*dln_m
```

Weights from ABS National Accounts 2023 averages. The demand-side aggregate yhat_dom feeds back into the IS curve through the bridge equation:

```
yhat_au = ... + lambda_dom * yhat_dom + eps_q
```

with lambda_dom = 0.399 (posterior mean), closing the Keynesian multiplier loop.

---

## 5. Estimation

### 5.1 Data

Nine observables are used for estimation, covering the period 1993Q2-2023Q3 (122 quarters):

| Observable | Source | Transformation |
|------------|--------|---------------|
| yhat_au | ABS GDP, HP-filtered | Log deviation from trend |
| pi_au | ABS GDP deflator | Quarterly log difference |
| i_au | RBA cash rate / 4 | Annualized to quarterly |
| yhat_us | US GDP, HP-filtered | Log deviation from trend |
| pi_us | US GDP deflator | Quarterly log difference |
| pi_w | Synthetic ULC | Log difference of CPI*(employment/emp_0) |
| dln_c | ABS consumption | Quarterly log difference |
| dln_ib | ABS non-dwelling GFCF | Quarterly log difference (70% of total GFCF) |
| i_10y | AU 10Y govt bond / 4 | Annualized to quarterly |

All variables are demeaned by their sample means to avoid low-rate era bias relative to model steady state.

### 5.2 Bayesian estimation results

The E-SAT core was estimated with Bayesian MCMC (50,000 draws, 2 chains). Convergence was confirmed by Geweke tests (all p > 0.10) and Brooks-Gelman diagnostics. Acceptance rates: 46.1-46.3%.

Key posterior findings vs calibration:

| Parameter | Calibrated | Posterior Mean | Key finding |
|-----------|-----------|---------------|-------------|
| lambda_w | 0.55 | **0.247** | Wages much more forward-looking |
| kappa_w | 0.10 | **0.238** | Steeper wage Phillips curve |
| lambda_dom | 0.10 | **0.399** | Demand bridge 4x stronger |
| b1_c | 0.35 | **0.149** | Less consumption persistence |
| b3_ib | 0.20 | **0.191** | Investment accelerator confirmed |
| rho_s | 0.92 | **0.950** | More FX persistence |
| eps_c stderr | 0.50 | **1.794** | Consumption shocks 3.5x larger |

Log marginal density (Modified Harmonic Mean): -1095.38.

---

## 6. Model Properties

### 6.1 Steady state

At the balanced growth path (gap model, all growth rates = 0):

| Variable | SS Value | Interpretation |
|----------|----------|---------------|
| yhat_au, yhat_us | 0 | Output gaps closed |
| pi_au, piQ, pi_w, pi_c, ... | 0.625% | All inflation = pi_ss_au (~2.5% annual) |
| i_au | 1.049% | ~4.2% annual (RBA neutral rate) |
| i_10y | 1.349% | ~5.4% annual |
| wacc | 1.834% | ~7.3% annual |
| uc_k | 1.859% | ~7.4% annual |
| dln_c, dln_ib, dln_ih, dln_n, ... | 0 | Zero growth (gap model) |
| s_gap, u_gap, pv_u_gap, pv_yh | 0 | All gaps closed |

### 6.2 IRFs to monetary policy shock

Response to a 1 standard deviation tightening shock (eps_i):

| Variable | Peak response | Quarter of peak |
|----------|--------------|-----------------|
| Output gap | -0.020% | Q4 |
| VA price inflation | -0.003% | Q4 |
| Consumption | -0.004% | Q3 |
| Business investment | -0.007% | Q4 |
| Housing investment | -0.007% | Q3 |
| Employment | -0.003% | Q4 |
| Wage inflation | -0.006% | Q4 |
| Exchange rate (s_gap) | -0.044% | Q9 |
| 10Y yield | +0.023% | Q7 |

Housing investment and business investment are the most rate-sensitive demand components. Consumption is the least sensitive, consistent with the heavy discounting of permanent income (beta_c = 0.95).

### 6.3 h-vector amplification

The native `pac_expectation()` h-vectors produce expectations weights 1.4-1.9x larger than the manual omega approximation. This amplification reflects the full discounted sum of expected future target changes computed from the TCM companion matrix, confirming FR-BDF Section 6: forward expectations amplify monetary transmission.

---

## 7. Monetary Policy Transmission

### 7.1 Expectation regimes

Under first-order perturbation (`stoch_simul(order=1)`), the VAR-based and MCE models produce identical IRFs. This is because the certainty equivalence principle applies at first order — both are solutions to the same linear rational expectations system. The difference between expectation regimes manifests in:

- Nonlinear simulations (deterministic `simul` / `perfect_foresight_solver`)
- Anticipated shocks (forward guidance)
- Second-order approximations

### 7.2 Forward guidance

The model is designed to avoid the forward guidance puzzle. The high discount factor in the permanent income equation (beta_c = 0.95, equivalent to ~25% annual) means that promises of future interest rate changes have a rapidly declining effect on current consumption. This mirrors the FR-BDF finding (Section 6.3) that peak GDP effects increase linearly — not exponentially — with the duration of forward guidance announcements.

---

## 8. Australia-Specific Features

### Variable-rate mortgages

Australia's predominantly variable-rate mortgage market creates the strongest housing channel of any demand component. The household investment PAC equation has b4_ih = -0.05, the largest interest rate coefficient, and the mortgage rate (i_lh) adjusts rapidly to changes in the 10Y government rate with spread_lh = 0.40% quarterly.

### Commodity price channel

Australia's commodity exports are modeled with an exogenous AR(1) process for commodity prices:

```
dln_pcom = rho_pcom * dln_pcom(-1) + 0.10 * yhat_us + eps_pcom
```

Commodity prices feed into export volumes (b4_x = 0.15), the export deflator (alpha_pcom = 0.10), and the import deflator (beta_pm_com = 0.05).

### Own central bank

Unlike FR-BDF where the short rate is exogenous (set by the ECB for the euro area), AU-PAC has an endogenous Taylor rule where the RBA reacts to domestic inflation and output gap. This creates a feedback loop absent in the French model: demand shocks -> output gap -> Taylor rule -> interest rate -> demand components.

### US as foreign bloc

The US replaces the euro area as the foreign bloc in E-SAT. The AU-US demand spillover (delta = 0.20) captures the trade channel linking US economic conditions to Australia.

---

## Appendix A: Complete Variable List

### E-SAT Core (11 variables)
| Variable | Description |
|----------|-------------|
| yhat_au | Australian output gap (%) |
| i_au | AU short-term interest rate (quarterly %) |
| pi_au | AU GDP deflator inflation (quarterly %) |
| yhat_us | US output gap (%) |
| pi_us | US inflation (quarterly %) |
| ibar | LR interest rate anchor (quarterly %) |
| pibar_au | LR AU inflation anchor (quarterly %) |
| pibar_us | LR US inflation anchor (quarterly %) |
| i_gap | i_au - ibar |
| pi_au_gap | pi_au - pibar_au |
| pi_us_gap | pi_us - pibar_us |

### VA Price Block (4 variables)
| Variable | Description |
|----------|-------------|
| piQ | VA price inflation (quarterly %) |
| piQ_star | Growth rate of VA price target |
| piQ_star_bar | HP trend of VA price target growth |
| pQ_gap | Gap between VA price target and actual (log) |

### Supply Block (5 variables)
| Variable | Description |
|----------|-------------|
| dln_k | Capital services growth (quarterly %) |
| dln_y_star | Potential output growth (quarterly %) |
| dln_tfp | TFP growth (quarterly %) |
| dln_ulc | Unit labor cost growth (quarterly %) |
| dln_prod | Labor productivity growth proxy (quarterly %) |

### Labor Market (10 variables)
| Variable | Description |
|----------|-------------|
| pi_w | Nominal wage inflation (quarterly %) |
| u_gap | Unemployment gap (pp) |
| pv_u_gap | PV of expected future unemployment gaps |
| dln_n | Employment growth (quarterly %) |
| dln_n_star | Target employment growth rate |
| dln_n_star_bar | Trend employment growth |
| n_gap | Employment gap (log level) |
| dln_n_1 | Auxiliary: dln_n(-1) |
| dln_n_2 | Auxiliary: dln_n(-2) |
| dln_n_3 | Auxiliary: dln_n(-3) |

### Demand Block (14 variables)
| Variable | Description |
|----------|-------------|
| dln_c | Consumption growth |
| dln_c_star | Target consumption growth |
| dln_c_star_bar | Trend consumption growth |
| c_gap | Consumption gap |
| pv_yh | PV of expected future output gaps (permanent income) |
| dln_ib | Business investment growth |
| dln_ib_star | Target investment growth |
| dln_ib_star_bar | Trend investment growth |
| ib_gap | Investment gap |
| dln_ib_1 | Auxiliary: dln_ib(-1) |
| dln_ih | Household investment growth |
| dln_ih_star | Target housing investment growth |
| dln_ih_star_bar | Trend housing investment growth |
| ih_gap | Housing investment gap |

### User Cost + Financial (15 variables)
| Variable | Description |
|----------|-------------|
| uc_k | User cost of capital (quarterly %) |
| dln_uc_k | User cost growth |
| i_10y | 10Y AU government bond yield |
| tp | Term premium |
| wacc | Weighted average cost of capital |
| i_COE | Cost of equity |
| i_LB_firms | Bank lending rate for firms |
| i_BBB | BBB corporate bond rate |
| s_COE | Equity spread |
| s_LB_firms | Bank lending spread |
| s_BBB | BBB bond spread |
| s_gap | Real exchange rate gap |
| i_lh | Household bank lending rate |
| dln_ih_1 | Auxiliary: dln_ih(-1) |

### Trade + Deflators + Government (15 variables)
| Variable | Description |
|----------|-------------|
| dln_x | Export volume growth |
| x_gap | Export gap |
| dln_m | Import volume growth |
| m_gap | Import gap |
| pi_c | Consumption deflator inflation |
| pi_ib | Business investment deflator inflation |
| pi_ih | Housing investment deflator inflation |
| pi_x | Export deflator inflation |
| pi_m | Import deflator inflation |
| dln_pcom | Commodity price growth |
| dln_g | Government spending growth |
| pi_g | Government deflator inflation |
| yhat_dom | Domestic demand gap |
| rw_gap | Real wage growth gap |
| iad | Import-adjusted demand |

### Housing + Other (2 variables)
| Variable | Description |
|----------|-------------|
| dln_ph | Real housing price growth |
| ph_gap | Housing price gap |

### PAC Level Variables (15 variables)
| Variable | Description |
|----------|-------------|
| piQ_aux_l | TCM auxiliary VA price level |
| piQ_star_l | TCM target VA price level |
| pQ_level | VA price detrended log-level |
| pQ_star_level | VA price target detrended log-level |
| c_aux_l, c_star_l, ln_c_level | Consumption TCM + level |
| ib_aux_l, ib_star_l, ln_ib_level | Business inv. TCM + level |
| ih_aux_l, ih_star_l, ln_ih_level | Housing inv. TCM + level |
| n_aux_l, n_star_l, ln_n_level | Employment TCM + level |

---

## Appendix B: Complete Shock List

| Shock | Std. Dev. | Description |
|-------|-----------|-------------|
| eps_q | 0.506 | AU output gap (posterior) |
| eps_i | 0.081 | Taylor rule (posterior) |
| eps_pi | 0.729 | AU Phillips curve (posterior) |
| eps_q_us | 1.088 | US output gap |
| eps_pi_us | 0.265 | US Phillips curve |
| eps_ibar | 0.01 | Interest rate anchor |
| eps_pibar_au | 0.01 | AU inflation anchor |
| eps_pibar_us | 0.01 | US inflation anchor |
| eps_pQ | 0.50 | VA price |
| eps_w | 0.60 | Wage |
| eps_n | 0.40 | Employment |
| eps_c | 1.794 | Consumption (posterior) |
| eps_ib | 2.807 | Business investment (posterior) |
| eps_ih | 1.729 | Household investment (posterior) |
| eps_10y | 0.10 | Long rate |
| eps_tp | 0.05 | Term premium |
| eps_COE | 0.15 | Cost of equity spread |
| eps_LB_firms | 0.10 | Bank lending spread |
| eps_BBB | 0.08 | BBB bond spread |
| eps_s | 2.50 | Exchange rate |
| eps_x | 1.20 | Exports |
| eps_m | 1.00 | Imports |
| eps_pc | 0.30 | Consumption deflator |
| eps_pib | 0.40 | Investment deflator |
| eps_pih | 0.50 | Housing deflator |
| eps_px | 0.80 | Export deflator |
| eps_pm | 0.70 | Import deflator |
| eps_g | 0.30 | Government spending |
| eps_pg | 0.30 | Government deflator |
| eps_tfp | 0.20 | TFP |
| eps_pcom | 3.00 | Commodity prices |
| eps_lh | 0.15 | Bank lending rate |
| eps_ph | 1.00 | Housing prices |
| eps_e_q | 0.506 | TCM non-target (VA price) |
| eps_e_pQ_star | 0.50 | TCM target (VA price) |
| eps_e_c | 0.506 | TCM non-target (consumption) |
| eps_e_c_star | 0.50 | TCM target (consumption) |
| eps_e_ib | 0.506 | TCM non-target (business inv.) |
| eps_e_ib_star | 0.50 | TCM target (business inv.) |
| eps_e_ih | 0.506 | TCM non-target (housing inv.) |
| eps_e_ih_star | 0.50 | TCM target (housing inv.) |
| eps_e_n | 0.506 | TCM non-target (employment) |
| eps_e_n_star | 0.50 | TCM target (employment) |

---

## References

- Lemoine, M., Turunen, H., Chahad, M., Lepetit, A., Zhutova, A., Aldama, P., Clerc, P. & Laffargue, J.-P. (2019). "The FR-BDF Model and an Assessment of Monetary Policy Transmission in France." Banque de France Working Paper #736.
- Brayton, F., Davis, M. & Tulip, P. (2000). "PAC in FRB/US." Federal Reserve Board.
- Tinsley, P.A. (2002). "Rational error correction." Computational Economics, 19(2), 197-225.
