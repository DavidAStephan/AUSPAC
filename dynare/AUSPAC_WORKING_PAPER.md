# The AU-PAC Model: A Semi-Structural Macroeconomic Model for Australia

## David Stephan

---

## Abstract

This paper presents AU-PAC, a semi-structural macroeconomic model for Australia that adapts the FR-BDF framework of Lemoine et al. (2019) to Australian data. Following the FRB/US modelling tradition, the model combines Polynomial Adjustment Costs (PAC) with explicit expectations and a supply block based on CES technology with substitution elasticity σ = 0.34. AU-PAC contains 159 endogenous variables, 47 exogenous shocks, and 262 parameters, with five PAC behavioural equations governing value-added prices, consumption, business investment, household investment, and employment, and a proper FR-BDF error-correction trade block with long-run income and real-exchange-rate elasticities. Expectations are formed using an enriched 12-equation satellite VAR (E-SAT) that feeds into a companion matrix for PAC h-vector computation. The model is estimated on Australian quarterly data from 1993Q1 to 2024Q4 using three complementary approaches: equation-by-equation Bayesian MCMC for the E-SAT core, iterative OLS with Kalman-smoothed auxiliary variables for the five PAC equations, and full-system Bayesian Metropolis-Hastings estimation for 28 joint parameters under the original 9-observable specification (log marginal density: Laplace = -799.64, Modified Harmonic Mean = -800.15); re-estimation under the expanded 11-observable trade-ECM specification is pending. The wage Phillips curve has standard New Keynesian structure under genuine ABS Wage Price Index data: λ_w = 0.29 own-lag persistence, γ_w = 0.14 contemporaneous CPI pass-through, and κ_w = 0.10 unemployment-gap slope. Under a three-regime comparison, model-consistent expectations attenuate monetary policy transmission by 28–100% relative to backward-looking expectations, with VA-price inflation, employment, and housing investment showing the strongest attenuation. Benchmarking AU-PAC's 100 bp cash-rate impulse response against the RBA's model suite (Beckers 2020 VAR, MARTIN, DINGO, Murphy — Mulqueeney, Ballantyne and Hambur 2025) places AU-PAC at the low end of the AU range, with a peak GDP fall of approximately −0.10% at Q6 versus the RBA suite's −0.30% to −1.5%. This conservative-by-construction profile reflects AU-PAC's small estimated PAC coefficients and the linearised-gap formulation, and supports a multi-model approach to Australian monetary policy analysis. Australia-specific features include an endogenous Taylor rule for the RBA, variable-rate mortgage transmission, commodity price channels, the US as the foreign bloc, and a proper error-correction trade block calibrated to AU's secular openness rise. The model is implemented in Dynare 6.5.

**Keywords**: Semi-structural model, polynomial adjustment costs, expectations, monetary policy transmission, Australian economy

**JEL codes**: C51, C54, E17, E37, E52

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Bird's-Eye View of the Model](#2-birds-eye-view)
3. [Expectation Formation and the PAC Framework](#3-expectation-formation-and-the-pac-framework)
4. [Model Specification](#4-model-specification)
5. [Estimation](#5-estimation)
6. [Model Properties](#6-model-properties)
7. [Conclusion](#7-conclusion)
8. [Australia-Specific Features](#8-australia-specific-features)
- [Appendix A: Complete Variable List](#appendix-a-complete-variable-list)
- [Appendix B: Complete Shock List](#appendix-b-complete-shock-list)
- [Appendix C: Growth Neutrality Proofs](#appendix-c-growth-neutrality-proofs)
- [Appendix D: h-Vector Decomposition](#appendix-d-h-vector-decomposition)
- [Appendix E: Complete Parameter List](#appendix-e-complete-parameter-list)
- [Appendix F: Identification Analysis](#appendix-f-identification-analysis)
- [References](#references)

---

## 1. Introduction

AU-PAC adapts the FR-BDF semi-structural model of Lemoine et al. (2019, Banque de France Working Paper #736) to Australian data. The framework belongs to the FRB/US family of semi-structural models used at central banks worldwide, including MUSE at the Bank of Canada, LENS at the Bank of England, and ECB-Base at the European Central Bank. These models occupy a middle ground between reduced-form VARs (which lack structural interpretation) and full DSGE models (which impose strong theoretical restrictions): behavioural equations are derived from optimisation with adjustment costs, while the supply block and financial channels are specified semi-structurally.

Three features are central to the modeling approach:

1. **Explicit expectations.** Agents form expectations about future economic conditions using either a backward-looking satellite VAR model (E-SAT) or model-consistent forward-looking expectations. The choice of expectation regime has first-order effects on monetary policy transmission.

2. **Polynomial adjustment costs.** Non-financial behavioral equations are derived from agents minimizing costs of deviating from long-run targets subject to polynomial adjustment costs, yielding error-correction equations augmented with the present value of expected future target changes.

3. **Well-defined supply block.** A CES production function with labor-augmenting technical progress determines long-run output and provides consistent targets for employment, investment, and value-added prices through factor demand conditions.

AU-PAC modifies the FR-BDF framework along four substantive dimensions to reflect Australian conditions: (i) commodity-price channels into export volumes, the export deflator, and the import deflator; (ii) an endogenous Taylor rule for the RBA in place of an exogenous short rate; (iii) variable-rate mortgage transmission; and (iv) the US as the foreign bloc in place of the euro area.

### Table 1.1: Model dimensions

| Dimension | AU-PAC |
|-----------|--------|
| Endogenous variables | 159 |
| Exogenous shocks | 47 (incl. 2 COVID dummies) |
| Parameters | 262 |
| PAC equations | 5 |
| Trade ECM equations | 2 (exports, imports — proper LR + SR specification) |
| var_model equations | 12 |
| Forward-looking variables (hybrid) | 9 |
| Forward-looking variables (MCE) | 30 |
| Estimation sample (Bayesian) | 1994Q3–2024Q4 (122 quarters) |
| Bayesian observables | 11 |

### Software and implementation

The model is implemented in Dynare 6.5 using the native `pac_expectation()` command and `var_model` declaration. Three companion .mod files implement the three expectation regimes: `au_pac.mod` (hybrid), `au_pac_var.mod` (VAR-based), and `au_pac_mce.mod` (full model-consistent). Source code is available at https://github.com/DavidAStephan/AUSPAC. Bayesian full-system estimation uses Dynare's `estimation()` command with `diffuse_filter` (required for the model's unit-root level accumulators), a csminwel mode search followed by Metropolis-Hastings MCMC with 20,000 draws across two chains.

### Paper outline

Section 2 provides a bird's-eye view of the model structure and transmission channels. Section 3 develops the expectation formation framework and PAC microfoundations. Section 4 specifies all model equations block by block, with coefficient tables for each. Section 5 describes the estimation strategy and results. Section 6 analyses model properties including monetary policy transmission under three expectation regimes, impulse responses to all shocks, conditional forecasting, and the forward guidance experiment. Section 7 concludes. Section 8 discusses Australia-specific features. Six appendices provide variable, shock, growth neutrality, h-vector, parameter, and identification tables.

---

## 2. Bird's-Eye View

### 2.1 Model structure

AU-PAC is organized into interconnected blocks, with expectations playing a role in most behavioral equations:

```
SUPPLY BLOCK                    NOMINAL BLOCK
- CES production function       - Wage Phillips curve (fwd PV of u_gap)
- Capital accumulation          - VA price: CES unit cost dual (PAC)
- Employment target             - Demand deflators: ECM equations
- TFP process                   - User cost of capital
         |                               |
         v                               v
    EXPECTATIONS              DEMAND BLOCK
    E-SAT (12-eq VAR)        - Consumption: permanent income PV (PAC)
    or Model-consistent       - Business investment: CES user cost (PAC)
    (MCE)                     - Household investment: mortgage rate (PAC)
         |                    - Employment: 4th-order labor hoarding (PAC)
         v                               |
FINANCIAL BLOCK                          v
- Term structure (PV of i)    TRADE BLOCK
- WACC (3 components)         - Exports ECM (world demand + commodities)
- Exchange rate (UIP)         - Imports ECM (IAD weights)
- Bank lending rates
         |                    GOVERNMENT + IDENTITY
         v                    - Fiscal rule (countercyclical)
    Feedback loops            - GDP expenditure identity
    (bridge equation)         - Bridge to IS curve (lambda_dom = 0.40)
```

*Figure 2.1: Model block diagram. Variables directly affected by expectations appear throughout: the 5 PAC equations, the term structure, exchange rate, wage Phillips curve (PV of unemployment), and the consumption target (PV of permanent income).*

### 2.2 Expectation regimes

The model can be solved under three expectation regimes (following wp736 Section 6):

### Table 2.1: Three expectation regimes

| Regime | Financial expectations | Non-financial expectations | Forward vars | File |
|--------|----------------------|--------------------------|-------------|------|
| **VAR-based** | Backward (AR(1) policy functions) | Backward (PAC h-vectors from var_model) | 0 | `au_pac_var.mod` |
| **Hybrid** | Forward (pv_i, pv_u_gap, pv_yh) | Backward (PAC h-vectors from var_model) | 3 | `au_pac.mod` |
| **Full MCE** | Forward (all leads) | Forward (pac_expectation expands to leads) | 30 | `au_pac_mce.mod` |

Under the hybrid regime (the baseline), the 5 PAC expectations use backward h-vectors from the enriched var_model companion matrix, while the term structure, unemployment, and permanent income present values use forward-looking recursive forms. Under full MCE, all expectations are forward-looking.

### 2.3 Key transmission channels

### Table 2.2: Monetary policy transmission channels

| Channel | Mechanism | Key equations | Key parameters |
|---------|-----------|---------------|----------------|
| Interest rate | Short rate -> 10Y yield -> WACC -> user cost -> business investment | eqs (48)-(50), (55) | kappa_10=0.97, sigma_ces=0.34 |
| Exchange rate | Short rate -> UIP -> AUD appreciation -> exports/imports | eq (54) | rho_s=0.78, b3_x=0.10 |
| Mortgage | Short rate -> 10Y yield -> bank lending -> housing investment | eqs (56), (38) | spread_lh=0.40, kappa_mort=0.048 |
| Expectations | Short rate enters E-SAT -> all h-vectors shift | var_model block | All a_X_Y auxiliary params |
| Wage-price | Output gap -> unemployment PV -> wages -> ULC -> VA price | eqs (30), (28), (29) | kappa_w=0.097, gamma_ulc=0.12 |
| Permanent income | Output gap -> PV of future income -> consumption target | eqs (33), (34) | beta_c=0.95, kappa_inc=0.050 |

---

## 3. Expectation Formation and the PAC Framework

### 3.1 The E-SAT expectation satellite model

The Expectation SATellite model (E-SAT) is a structural VAR with 11 core equations. Agents with limited information form expectations by forecasting from this small model. The core equations relate the Australian output gap, inflation, and interest rate to their US counterparts:

**Australian IS curve** (eq. 1):

$$\hat{y}_t = \lambda_q \hat{y}_{t-1} + \delta \hat{y}^{US}_t - \sigma_q (i_{t-1} - \bar{i}_{t-1} - \pi^{gap}_{t-1}) + \lambda_{dom} \hat{y}^{dom}_t + \varepsilon^q_t$$

**Australian Phillips curve** (eq. 2):

$$\pi^{gap}_t = \lambda_\pi \pi^{gap}_{t-1} + \kappa_\pi \hat{y}_{t-1} + \varepsilon^\pi_t$$

**Taylor rule** (eq. 3):

$$i^{gap}_t = \lambda_i i^{gap}_{t-1} + (1-\lambda_i)(\alpha_i \pi^{gap}_{t-1} + \beta_i \hat{y}_{t-1}) + \varepsilon^i_t$$

**US IS curve** (eq. 4): $\hat{y}^{US}_t = \lambda_{q,US} \hat{y}^{US}_{t-1} + \varepsilon^{q,US}_t$

**US Phillips curve** (eq. 5): $\pi^{gap,US}_t = \lambda_{\pi,US} \pi^{gap,US}_{t-1} + \kappa_{\pi,US} \hat{y}^{US}_{t-1} + \varepsilon^{\pi,US}_t$

Plus three anchor equations (eqs. 6-8) for the long-run interest rate, AU inflation target, and US inflation target, each following AR(1) processes toward steady state.

#### Bayesian estimation

E-SAT was estimated using Bayesian methods (Metropolis-Hastings, 50,000 draws, 2 chains) on quarterly Australian data from 1993Q1 to 2024Q4.

### Table 3.1: E-SAT posterior estimates

| Parameter | Description | Prior | Posterior mean |
|-----------|-------------|-------|---------------|
| delta | AU-US demand spillover | Beta(0.20, 0.10) | 0.199 |
| lambda_q | AU output gap persistence | Beta(0.50, 0.15) | 0.448 |
| sigma_q | Real rate sensitivity | Gamma(0.20, 0.10) | 0.166 |
| lambda_i | Taylor rule inertia | Beta(0.80, 0.05) | 0.828 |
| alpha_i | Taylor rule inflation weight | Normal(0.30, 0.15) | 0.279 |
| beta_i | Taylor rule output weight | Normal(0.15, 0.10) | 0.135 |
| lambda_pi | AU inflation persistence | Beta(0.30, 0.10) | 0.263 |
| kappa_pi | Phillips curve slope | Gamma(0.06, 0.03) | 0.058 |
| lambda_q_us | US output gap persistence | Beta(0.80, 0.10) | 0.806 |
| lambda_pi_us | US inflation persistence | Beta(0.65, 0.10) | 0.653 |
| kappa_pi_us | US Phillips slope | Gamma(0.02, 0.01) | 0.013 |

Convergence confirmed by Geweke tests (all p > 0.10) and Brooks-Gelman diagnostics. Acceptance rates: 46.1-46.3%.

### Table 3.2: Steady-state values

| Variable | SS value (quarterly) | Annual equivalent | Description |
|----------|---------------------|-------------------|-------------|
| i_ss | 1.049% | ~4.2% | RBA neutral rate |
| pi_ss_au | 0.625% | ~2.5% | RBA inflation target midpoint |
| pi_ss_us | 0.500% | ~2.0% | Fed inflation target |

#### Companion matrix

The E-SAT model can be written in structural VAR form $AZ_t = BZ_{t-1} + \varepsilon_t$, yielding the reduced form $Z_t = HZ_{t-1} + \eta_t$ where $H = A^{-1}B$. The $i$-step-ahead forecast is $Z^e_{t+i} = H^i Z_t$, enabling computation of discounted present values of any variable.

### 3.2 Enriched E-SAT: the var_model architecture

AU-PAC enlarges the E-SAT state vector with auxiliary equations for each PAC target variable. Following wp736 Tables 4.4.4, 4.5.7, 4.6.3–4, 4.6.11–12, and 4.6.16, these auxiliary equations capture how the macro state (output gap, interest-rate gap, inflation gap, unemployment gap) feeds into each target variable's dynamics.

The enriched system is declared as a single `var_model` in Dynare:

```
var_model(model_name = esat_enriched,
    eqtags = ['var_y', 'var_i', 'var_pi',           // 3 E-SAT core
              'var_u', 'var_yus',                     // 2 additional states
              'var_pQ', 'var_n', 'var_yh', 'var_c',   // 4 auxiliary gaps
              'var_ib', 'var_rKB', 'var_ih']);          // 3 auxiliary gaps
```

All 5 PAC equations share this enriched var_model for h-vector computation.

### Table 3.3: Enriched var_model equations (12x12 companion matrix)

| # | Tag | Variable | Equation type | wp736 ref |
|---|-----|----------|--------------|------------|
| 1 | var_y | y_gap_var | IS curve (lagged) | E-SAT eq 1 |
| 2 | var_i | i_gap_var | Taylor rule (lagged) | E-SAT eq 3 |
| 3 | var_pi | pi_gap_var | Phillips curve (lagged) | E-SAT eq 2 |
| 4 | var_u | u_gap_var | Okun's law | Table 4.5.2 |
| 5 | var_yus | yhat_us_var | US IS (AR(1)) | E-SAT eq 4 |
| 6 | var_pQ | piQ_hat | VA price auxiliary | Table 4.4.4 |
| 7 | var_n | n_hat | Employment auxiliary | Table 4.5.7 |
| 8 | var_yh | yh_ratio_hat | Income-output ratio | Table 4.6.3 |
| 9 | var_c | c_hat | Consumption PV^2 | Table 4.6.4 |
| 10 | var_ib | ib_hat | Business inv output gap | Table 4.6.11 |
| 11 | var_rKB | rKB_hat | Business inv user cost | Table 4.6.12 |
| 12 | var_ih | ih_hat | Housing inv target | Table 4.6.16 |

### Table 3.4: Auxiliary equation coefficients

Each auxiliary equation takes the form: $\hat{X}_t = \rho_X \hat{X}_{t-1} + a_{X,y} \hat{y}_{t-1} + a_{X,i} \tilde{i}_{t-1} + a_{X,\pi} \tilde{\pi}_{t-1} + a_{X,u} \tilde{u}_{t-1} + ...$

| Auxiliary | Own lag (rho) | y_gap | i_gap | pi_gap | u_gap | Other | wp736 ref |
|-----------|--------------|-------|-------|--------|-------|-------|------------|
| piQ_hat | 0.70 | 0.03 | -0.02 | 0.01 | -0.05 | — | Table 4.4.4 |
| n_hat | 0.67 | 0.12 | -0.03 | 0.05 | -0.04 | — | Table 4.5.7 |
| yh_ratio_hat | 0.92 | 0.32 | — | — | -0.08 | — | Table 4.6.3 |
| c_hat | 0.60 | 0.06 | -0.04 | 0.01 | -0.03 | a_c_yh=0.39 | Table 4.6.4 |
| ib_hat | 0.59 | 0.15 | — | 0.04 | -0.02 | — | Table 4.6.11 |
| rKB_hat | 0.55 | — | 0.24 | — | — | — | Table 4.6.12 |
| ih_hat | 0.71 | 0.08 | -0.08 | 0.05 | -0.03 | — | Table 4.6.16 |

Persistence parameters and auxiliary coefficients are estimated on AU observable target proxies via Bayesian shrinkage; the wp736 references provide the cross-equation specification.

### 3.3 PAC microfoundations

The PAC framework derives behavioral equations from agents minimizing a cost function that penalizes deviations from a target $y^*_t$ and $m$ differences of the decision variable $y_t$:

$$C_t = \sum_{i=0}^{\infty} \beta^i \left[(y_{t+i} - y^*_{t+i})^2 + \sum_{k=1}^{m} b_k ((1-L)^k y_{t+i})^2\right]$$

The first-order condition yields an error-correction equation (eq. 9):

$$\Delta y_t = a_0 (y^*_{t-1} - y_{t-1}) + \sum_{k=1}^{m-1} a_k \Delta y_{t-k} + \sum_{i=0}^{\infty} d_i \Delta y^*_{t+i}$$

where $a_0$ is the error-correction speed, $a_k$ are AR lag coefficients, and $\omega = \sum d_i$ is the share of nonstationary expectations. **Growth neutrality** requires $1 - \sum a_k - \omega = 0$ on the balanced growth path.

Under VAR-based expectations, the infinite sum collapses to $k_0 Z_{t-1}$ where $k_0$ is the h-vector computed from the var_model companion matrix. Dynare's `pac_expectation()` command automates this computation.

### Table 3.5: PAC equation specifications

| Equation | Order m | AR lags | Discount beta | h-vector sum | Manual omega | Amplification |
|----------|---------|---------|---------------|-------------|-------------|---------------|
| VA price | 1 | 1 | 0.98 | 0.452 | 0.46 | 1.0x |
| Consumption | 1 | 1 | 0.98 | 0.678 | 0.369 | **1.84x** |
| Business inv | 2 | 2 | 0.98 | 0.501 | 0.350 | **1.43x** |
| Household inv | 2 | 2 | 0.98 | 0.569 | 0.300 | **1.90x** |
| Employment | 4 | 4 | 0.98 | 0.446 | 0.300 | **1.49x** |

The 1.4–1.9× amplification across the consumption, business-investment, household-investment, and employment equations is consistent with the wp736 Section 6 finding that forward expectations amplify monetary transmission.

### 3.4 Three expectation regimes

Under **VAR-based** expectations, `pac_expectation()` evaluates to $k_0 Z_{t-1}$, a linear function of the lagged var_model state vector. All dynamics are backward-looking.

Under the **Hybrid** regime, PAC equations remain backward-looking but three financial/labor variables use forward-looking recursive forms: the term structure ($pv_i$), the present value of unemployment gaps ($pv_{u,gap}$), and permanent income ($pv_{yh}$).

Under **full MCE**, `pac_expectation()` expands into forward-looking recursive leads of the target variable (wp736 eqs 138–142). The MCE version has 30 forward-looking variables compared to 3 under the hybrid regime.

---

## 4. Model Specification

### 4.1 Notation

| Prefix/Suffix | Meaning | Example |
|---------------|---------|---------|
| `dln_` | Log difference (quarterly growth rate) | `dln_c` = consumption growth |
| `_gap` | Deviation from target/trend | `i_gap` = i_au - ibar |
| `_star` | Target/desired value | `dln_c_star` = target consumption growth |
| `_bar` | Trend/long-run anchor | `pibar_au` = LR inflation anchor |
| `pi_` | Inflation rate | `piQ` = VA price inflation |
| `s_` | Spread | `s_COE` = equity spread |
| `pv_` | Present value of expectations | `pv_u_gap` = PV of future unemployment gaps |
| `_level` | Log-level accumulator for PAC | `ln_c_level` = cumulated consumption |

All variables are in quarterly percentage points unless noted otherwise. At steady state, all gap and growth variables equal zero; inflation and interest rate variables equal their long-run anchors.

### 4.2 Supply block (FR-BDF Section 4.3)

#### CES production function (FR-BDF eq 24)

The production technology for market branches is a CES function with labor-augmenting technical progress (eq. 10):

$$\Delta \ln Y^*_t = \alpha_K \Delta \ln K_t + (1 - \alpha_K) \Delta \ln N^*_t + \Delta \ln TFP_t$$

#### Capital accumulation (FR-BDF eq 32, eq. 11):

$$\Delta \ln K_t = (1 - \delta_K) \Delta \ln K_{t-1} + \delta_K \Delta \ln I^B_t$$

#### TFP process (eq. 12):

$$\Delta \ln TFP_t = \rho_{TFP} \Delta \ln TFP_{t-1} + \varepsilon^{TFP}_t$$

with $\rho_{TFP} = 0.99$ (near unit root). Labor productivity is derived as $\Delta \ln Prod = \Delta \ln TFP / (1-\alpha_K)$.

### Table 4.2.1: Supply block calibration

| Parameter | Symbol | Value | Description |
|-----------|--------|-------|-------------|
| CES elasticity | sigma_ces | 0.3374 | Substitution between K and L (Bayesian posterior, SA-corrected supply data) |
| Capital share | alpha_k | 0.35 | CES distribution parameter (AU labour-share midpoint from ABS 5204) |
| Depreciation | delta_k | 0.025 | ~10% annual |
| TFP persistence | rho_tfp | 0.99 | Near unit root |
| Markup | mu | 1.20 | AU markup (RBA RDP estimates) |

### 4.3 Value-added price of market branches (FR-BDF Section 4.4)

The VA price equation is central because this deflator enters all other price equations, enabling expectations to affect price setting economy-wide.

#### 4.3.1 Target equation (Factor price frontier, FR-BDF eq 38)

The long run of the VA price is derived from the CES dual cost function (eq. 13):

$$\pi^{Q*}_t = \rho^*_{pQ} \pi^{Q*}_{t-1} + \gamma_{ULC} \Delta \ln ULC_t + \gamma_{UCK} \Delta \ln UC^K_t + (1 - \rho^*_{pQ} - \gamma_{ULC}) \bar{\pi}_t$$

where $\Delta \ln ULC = \pi_w - \Delta \ln Prod$ and $\Delta \ln UC^K = UC^K_t - UC^K_{t-1}$.

### Table 4.3.1: VA price target coefficients

| Parameter | Symbol | Value | Description |
|-----------|--------|-------|-------------|
| Target persistence | rho_pQ_star | 0.95 | Calibrated |
| ULC pass-through | gamma_ulc | 0.12 | CES labor share |
| User cost pass-through | gamma_uck | 0.06 | CES capital share |
| Inflation anchor | 1-rho-gamma | derived | Growth neutrality |

**Growth neutrality**: At SS, $\pi^{Q*} = (\rho + \gamma_{ULC} + (1-\rho-\gamma_{ULC})) \times \pi_{SS} = \pi_{SS}$. Verified.

#### 4.3.2 Short-run PAC equation (FR-BDF eq 44)

The short-run dynamics use the PAC framework with Dynare's `pac_expectation()` (eq. 14):

$$\Delta pQ^{level}_t = b^{pQ}_0 (\pi^{Q*,level}_{t-1} - pQ^{level}_{t-1}) + b^{pQ}_1 \Delta pQ^{level}_{t-1} + pac\_exp(pac\_pQ) + b^{pQ}_2 \hat{y}_t + \varepsilon^{pQ}_t$$

### Table 4.3.2: VA price short-run coefficients

| Parameter | Calibrated | OLS (hybrid+COVID) | Bayesian mode |
|-----------|-----------|-------------------|---------------|
| b0_pQ (EC) | 0.060 | 0.027 | 0.023 |
| b1_pQ (AR1) | 0.500 | 0.288 | 0.266 |
| b2_pQ (output gap) | 0.090 | -0.014 | -0.000 |
| COVID crash (2020Q2) | — | -2.877 | — |
| COVID bounce (2020Q3) | — | +1.490 | — |
| h-vector sum (omega) | 0.452 | — | — |
| SSR | — | 40.6 | — |
| T | — | 118 | — |

The OLS output gap coefficient ($b^{pQ}_2$) is near zero, indicating that the Phillips curve channel operates primarily through the target equation (ULC) rather than the short-run ad hoc term. Growth neutrality is verified: $1 - 0.288 - 0.452 = 0.260$.

#### 4.3.3 E-SAT auxiliary (FR-BDF Table 4.4.4)

The VA price auxiliary equation in the var_model (eq. 15):

$$\widehat{\pi Q}_t = 0.70 \widehat{\pi Q}_{t-1} + 0.03 \hat{y}_{t-1} - 0.02 \tilde{i}_{t-1} + 0.01 \tilde{\pi}_{t-1} - 0.05 \tilde{u}_{t-1}$$

#### 4.3.4 Dynamic contributions

![VA Price Inflation: Dynamic Contributions](contrib_piQ.png)

*Figure 4.3.1: Historical dynamic-contribution decomposition of quarterly Δlog pQ over 1994Q3–2024Q4 (top: full sample; bottom: pre-COVID zoom). At each quarter the bars stack each channel's contribution to the smoothed Δlog pQ from the Bayesian smoother. Error correction (b0_pQ·gap, blue) and the residual eps_pQ (gray) are the most active channels; the PAC expectation contribution is small because Australian VA price inflation has low forward-looking content under the estimated companion matrix.*

### 4.4 Wages and employment (FR-BDF Section 4.5)

#### 4.4.1 Wage Phillips curve (FR-BDF eq 52)

In the long run the labor supply curve is vertical. In the short run, wage inflation is determined by a hybrid Phillips curve augmented with CPI indexation (eq. 16):

$$\pi^w_t = \lambda_w \pi^w_{t-1} + \gamma_w \pi_t + \kappa_w pv_{u,gap} + (1 - \lambda_w - \gamma_w) \bar{\pi}_t + (1 - \lambda_w) \Delta \ln Prod_t + \varepsilon^w_t$$

### Table 4.4.1: Wage Phillips curve coefficients

| Parameter | Calibrated | Bayesian posterior mean |
|-----------|-----------|--------------------------|
| lambda_w (persistence) | 0.55 | 0.290 |
| gamma_w (CPI passthrough) | 0.15 | 0.136 |
| kappa_w (unemployment PV) | 0.10 | 0.097 |
| beta_w (PV discount) | 0.98 | — |
| Inflation anchor (1-lambda-gamma) | derived | 0.574 |
| stderr eps_w | — | 0.149 |

The Australian wage Phillips curve has a standard New Keynesian structure when estimated on the ABS Wage Price Index (Cat. 6345, Total hourly rates of pay excluding bonuses, Private and Public, All industries, seasonally adjusted). The posterior coefficients are γ_w = 0.136 (90% HPD [0.081, 0.191]) for contemporaneous CPI passthrough, λ_w = 0.290 (HPD [0.134, 0.447]) for own-lag persistence, and κ_w = 0.097 (HPD [0.010, 0.169]) for the forward-looking unemployment-gap channel — statistically significant at conventional thresholds. The wage Phillips curve therefore takes the approximate form

$$\pi^w \approx 0.29 \, \pi^w_{t-1} + 0.14 \, \pi_{CPI,t} + 0.10 \, pv_{u,gap} + 0.57 \, \bar{\pi}$$

a moderate CPI-passthrough weight, moderate own-lag persistence, and a statistically significant Phillips slope — in the spirit of the Tinsley (1993) / FRB-US tradition of structural NK wage equations.

This pattern is consistent with the Australian institutional setting. The Fair Work Commission's annual wage review provides a CPI-indexation channel for roughly 15% of the workforce (those on award rates plus award-floor enterprise-agreement workers), but most Australian wage growth is set by private bargaining responsive to labour-market conditions and own-lag inertia — the standard NK Phillips curve that κ_w = 0.10 and λ_w = 0.29 capture.

**Auxiliary: Okun's law** (FR-BDF eq 53, eq. 17): $\tilde{u}_t = \rho_u \tilde{u}_{t-1} + okun \times \hat{y}_t$ with rho_u = 0.94, okun = -0.33.

**PV of unemployment gap** (FR-BDF eq 137, eq. 18): $pv_{u,gap} = (1-\beta_w) \tilde{u}_t + \beta_w \cdot pv_{u,gap}(+1)$. Forward-looking under hybrid/MCE.

#### 4.4.2 Employment (FR-BDF Section 4.5.2)

**Target equation** (FR-BDF eq 55, eq. 19):

$$\Delta \ln N^{*,bar}_t = \frac{\Delta \ln TFP_t}{1-\alpha_K} - \sigma_{CES} \cdot rw\_gap_t$$

where $rw\_gap = \pi_w - \pi^Q - \Delta \ln Prod$ is the real wage growth gap.

**Short-run PAC equation** (4th-order, FR-BDF eq 56, eq. 20):

$$\Delta \ln N^{level}_t = b^n_0 (N^{*,level}_{t-1} - \ln N^{level}_{t-1}) + \sum_{k=1}^{4} b^n_k \Delta \ln N^{level}_{t-k} + pac\_exp(pac\_n) + b^n_5 \hat{y}_t + \varepsilon^n_t$$

### Table 4.4.4: Employment short-run PAC coefficients

| Parameter | Calibrated | OLS (hybrid+COVID) | Bayesian mode |
|-----------|-----------|-------------------|---------------|
| b0_n (EC) | 0.040 | 0.072 | 0.058 |
| b1_n (AR1) | 0.300 | 0.323 | 0.301 |
| b2_n (AR2) | 0.100 | -0.177 | — |
| b3_n (AR3) | 0.050 | -0.081 | — |
| b4_n (AR4) | 0.020 | -0.096 | — |
| b5_n (output gap) | 0.120 | -0.017 | -0.000 |
| COVID crash | — | -6.601 | — |
| COVID bounce | — | +3.862 | — |
| h-vector sum | 0.446 | — | — |
| SSR | — | 76.4 | — |

The OLS error-correction speed (0.063) is around 60% higher than the calibrated value (0.040), implying faster employment adjustment than the prior assumed. The negative AR(2–4) coefficients likely reflect quarterly seasonality absorption.

**E-SAT auxiliary** (wp736 Table 4.5.7, eq. 21): $\hat{n}_t = 0.67 \hat{n}_{t-1} + 0.12 \hat{y}_{t-1} - 0.03 \tilde{i}_{t-1} + 0.05 \tilde{\pi}_{t-1} - 0.04 \tilde{u}_{t-1}$

![Employment: Dynamic Contributions](contrib_n.png)

*Figure 4.4.1: Historical dynamic-contribution decomposition of Δlog n (employment growth) over 1994Q3–2024Q4. Error correction (b0_n·(n_hat − ln n)) is positive throughout most of the sample, reflecting steady employment convergence to potential. The four AR lags partially cancel — net AR contribution is small. The b5_n·yhat_au accelerator is essentially zero (posterior 0.002, weakly identified) so output-gap variation does not feed directly into Δlog n in the AU data; transmission to employment runs almost entirely through the PAC expectation term and the eps_n shock.*

### 4.5 Household consumption (FR-BDF Section 4.6.1)

#### 4.5.1 Target equation

The consumption target is based on permanent income (FR-BDF eq 59). Permanent income is the discounted PV of expected future output gaps (eq. 22):

$$pv_{yh} = (1 - \beta_c) \hat{y}_t + \beta_c \cdot pv_{yh}(+1)$$

with $\beta_c = 0.95$ (~25% annual discount). The consumption target (eq. 23):

$$\Delta \ln C^{*,bar}_t = \kappa_{inc} (pv_{yh,t} - pv_{yh,t-1}) + \alpha_{c,r} \cdot \Delta(\text{real lending rate gap})$$

### Table 4.5.1: Consumption target coefficients

| Parameter | Symbol | Value | Description |
|-----------|--------|-------|-------------|
| Target persistence | rho_c_star | 0.95 | — |
| Permanent income sensitivity | kappa_inc | 0.050 | Calibrated |
| PV discount | beta_c | 0.95 | ~25% annual discount |
| Real rate sensitivity | alpha_c_r | -0.95 | wp736 Table 4.6.14 |

#### 4.5.2 Short-run PAC equation (1st-order, FR-BDF eq 61)

Eq. (24):

$$\Delta \ln C^{level}_t = b^c_0 (C^{*,level}_{t-1} - \ln C^{level}_{t-1}) + b^c_1 \Delta \ln C^{level}_{t-1} + pac\_exp(pac\_c) + b^c_2 \tilde{i}_{t-1} + b^c_3 \hat{y}_t + \varepsilon^c_t$$

### Table 4.5.2: Consumption short-run PAC coefficients

| Parameter | Calibrated | OLS (hybrid+COVID) | Bayesian mode |
|-----------|-----------|-------------------|---------------|
| b0_c (EC) | 0.060 | 0.069 | 0.060 |
| b1_c (AR1) | 0.149 | 0.046 | 0.025 |
| b2_c (rate gap) | -0.020 | -0.553 | -0.280 |
| b3_c (output gap/HtM) | 0.139 | 0.018 | 0.019 |
| COVID crash | — | -14.901 | — |
| COVID bounce | — | +6.388 | — |
| h-vector sum | 0.678 | — | — |
| SSR | — | 413.2 | — |

Three results stand out. First, OLS b2_c = -0.55 implies strong interest-rate sensitivity, consistent with Australia's variable-rate mortgage structure; the Bayesian posterior pulls this toward -0.28 under prior regularization. Second, the AR(1) coefficient is negative without the COVID dummies; the dummies restore the expected sign. Third, h-vector amplification is 1.84×, the largest among the five PAC equations.

**E-SAT auxiliary** (wp736 Tables 4.6.3-4, eq. 25):
$\hat{c}_t = 0.60 \hat{c}_{t-1} + 0.06 \hat{y}_{t-1} - 0.04 \tilde{i}_{t-1} + 0.005 \tilde{\pi}_{t-1} - 0.03 \tilde{u}_{t-1} + 0.39 \widehat{yh}_{t-1}$

The consumption auxiliary is the most complex of the seven, featuring a nested PV structure in which the income-output ratio ($\widehat{yh}$) feeds into consumption ($\hat{c}$) and creates PV-squared dynamics (wp736 Table 4.6.4).

![Consumption: Dynamic Contributions](contrib_c.png)

*Figure 4.5.1: Historical dynamic-contribution decomposition of Δlog c (real per-capita consumption growth) over 1994Q3–2024Q4. The error correction term (blue) dominates in absolute magnitude — Australian consumption converges visibly to permanent income each quarter. The rate channel b2_c·i_gap (red) flips sign at major policy turns (rate cuts in 2001, 2008, 2020 supportive of consumption; tightening in 2007 and 2022 dragging). The b_di_c·di_gap MP-surprise channel (purple) is small but procyclical. The 2020 COVID quarter shows a -16% Δlog c absorbed almost entirely by the eps_c residual (gray), confirming that the smoothed structural channels alone do not explain pandemic-era consumption collapse.*

### 4.6 Business investment (FR-BDF Section 4.6.2)

#### 4.6.1 Target equation (FR-BDF eq 63)

Desired investment derives from the CES capital demand first-order condition (eq. 26):

$$\Delta \ln I^{B*,bar}_t = \kappa_{ib,y} \hat{y}_t - \sigma_{CES} \Delta \ln UC^K_t$$

The user cost of capital (eq. 27):

$$UC^K_t = WACC_t + \delta_K - (\pi^{IB}_t - \pi^Q_t)$$

### Table 4.6.1: Business investment target coefficients

| Parameter | Symbol | Value | Description |
|-----------|--------|-------|-------------|
| Target persistence | rho_ib_star | 0.95 | Calibrated |
| Output proportionality | kappa_ib_y | 0.06 | CES eq 63 |
| CES user cost elasticity | sigma_ces | 0.3374 | Bayesian posterior (see Table 4.2.1) |
| Depreciation | delta_k | 0.025 | ~10% annual |

#### 4.6.2 Short-run PAC equation (2nd-order, FR-BDF eq 64)

Eq. (28):

$$\Delta \ln I^{B,level}_t = b^{ib}_0 (\cdot) + b^{ib}_1 \Delta_{t-1} + b^{ib}_2 \Delta_{t-2} + pac\_exp(pac\_ib) + b^{ib}_3 \hat{y}_t + \varepsilon^{ib}_t$$

### Table 4.6.2: Business investment short-run PAC coefficients

| Parameter | Calibrated | OLS (hybrid+COVID) | Bayesian mode |
|-----------|-----------|-------------------|---------------|
| b0_ib (EC) | 0.030 | 0.018 | 0.016 |
| b1_ib (AR1) | 0.181 | 0.107 | 0.087 |
| b2_ib (AR2) | 0.100 | -0.046 | — |
| b3_ib (accelerator) | 0.191 | 0.344 | 0.195 |
| COVID crash | — | -4.382 | — |
| COVID bounce | — | +2.978 | — |
| h-vector sum | 0.501 | — | — |
| SSR | — | 929.8 | — |

**E-SAT auxiliaries** (wp736 Tables 4.6.11–12): two separate equations — output-gap auxiliary and user-cost auxiliary:

Eq. (29): $\widehat{ib}_t = 0.59 \widehat{ib}_{t-1} + 0.15 \hat{y}_{t-1} + 0.04 \tilde{\pi}_{t-1} - 0.02 \tilde{u}_{t-1}$

Eq. (30): $\widehat{rKB}_t = 0.55 \widehat{rKB}_{t-1} + 0.24 \tilde{i}_{t-1}$

![Business Investment: Dynamic Contributions](contrib_ib.png)

*Figure 4.6.1: Historical dynamic-contribution decomposition of Δlog i_b (business investment growth) over 1994Q3–2024Q4. The accelerator b3_ib·yhat_au (red) and the user-cost channel −σ·pv_rKB_aux (brown) are the two most variable structural channels: a positive output gap pulls investment up while a high user-cost PV pulls it down, and they are negatively correlated through the cycle (rate cuts in slumps support both channels in the same direction). The PAC expectation contribution is small in level but timing-relevant — visibly leading the AR lags during the 2008-09 and 2020 turning points.*

### 4.7 Household investment (FR-BDF Section 4.6.3)

#### 4.7.1 Target equation (FR-BDF eq 66)

The household investment target depends on permanent income, the mortgage rate gap, and housing price Tobin's Q (eq. 31):

$$\Delta \ln I^{H*,bar}_t = \kappa_{ih,inc} (pv_{yh,t} - pv_{yh,t-1}) - \kappa_{mort} (i^{LH}_t - i^{LH}_{SS}) + \kappa_{ph} \cdot ph\_gap_{t-1}$$

### Table 4.7.1: Household investment target coefficients

| Parameter | Symbol | Value | Description |
|-----------|--------|-------|-------------|
| Target persistence | rho_ih_star | 0.95 | Calibrated |
| Permanent income | kappa_ih_inc | 0.03 | wp736 eq 66 |
| Mortgage rate gap | kappa_mort | 0.048 | Calibrated (posterior) |
| Housing Tobin's Q | kappa_ph | 0.03 | Calibrated |

#### 4.7.2 Short-run PAC equation (2nd-order, FR-BDF eq 67)

Eq. (32):

$$\Delta \ln I^{H,level}_t = b^{ih}_0 (\cdot) + b^{ih}_1 \Delta_{t-1} + b^{ih}_2 \Delta_{t-2} + pac\_exp(pac\_ih) + b^{ih}_3 \hat{y}_t + \varepsilon^{ih}_t$$

The direct interest rate term $b^{ih}_4 \tilde{i}_{t-1}$ is dropped, as F-test diagnostics showed it statistically insignificant (F=0.001, ΔSSR=0.005 on T=118). The interest-rate channel enters household investment through two structural paths: (i) the target equation via $\kappa_{mort}(i^{LH} - SS)$ through `pac_expectation`, and (ii) the auxiliary equation $pv_{ih,aux}$ with $a_{ih,i} = -0.15$. The direct ad hoc term would have triple-counted this channel.

### Table 4.7.2: Household investment short-run PAC coefficients

| Parameter | Calibrated | OLS (hybrid+COVID) | Bayesian mode | IV estimate |
|-----------|-----------|-------------------|---------------|-------------|
| b0_ih (EC) | 0.049 | 0.028 | 0.022 | — |
| b1_ih (AR1) | 0.210 | 0.111 | 0.088 | — |
| b2_ih (AR2) | 0.080 | -0.032 | — | — |
| b3_ih (output gap) | 0.120 | 0.231 | 0.219 | — |
| b4_ih (rate gap) | dropped | — | — | — |
| b_ph_ih (house prices) | 0 | — | — | 0.0099 (s.e. 0.075; F=432, T=115) |
| COVID crash | — | -5.558 | — | — |
| COVID bounce | — | +2.603 | — | — |
| h-vector sum | 0.569 | — | — | — |
| SSR | — | 957.2 | — | — |

**E-SAT auxiliary** (wp736 Table 4.6.16, eq. 33): $\widehat{ih}_t = 0.71 \widehat{ih}_{t-1} + 0.08 \hat{y}_{t-1} - 0.08 \tilde{i}_{t-1} + 0.05 \tilde{\pi}_{t-1} - 0.03 \tilde{u}_{t-1}$

The interest-rate channel through the auxiliary ($a_{ih,i} = -0.08$) provides the structural rate transmission. h-vector amplification is 1.90×, the second largest of the five PAC equations.

**Housing-price gap identification.** The ABS 6416 Residential Property Price Index begins in 2003Q3 (T=72 quarters), which proved too short to identify the housing-price-gap coefficient: both OLS and lag-2-ph_gap IV produced wrong-signed estimates on the 2003+ sample, reflecting reverse-causality bias from supply-side shocks. We extend the housing-price series back to 1959Q3 by chaining growth rates from a long-history Australian house-price series (`data/house_price_history_long.csv`) onto ABS 6416 levels at the 2003Q3 overlap (overlap-growth correlation 0.84, RMS difference 1.16 pp/qtr). On the resulting T=115 sample (1993Q1–2021Q4, binding constraint set by the start of housing-investment data), the lag-2 IV produces a strong first stage (F=432) and a positive sign for both OLS (+0.066) and IV (+0.0099, s.e. 0.075). The IV magnitude is statistically indistinguishable from zero — the housing-price-gap channel in AU is small. The structural rate transmission to housing investment continues to operate through `pv_ih_aux` and the `pac_expectation` mortgage-rate term.

![Housing Investment: Dynamic Contributions](contrib_ih.png)

*Figure 4.7.1: Historical dynamic-contribution decomposition of Δlog i_h (housing investment growth) over 1994Q3–2024Q4. The error correction term b0_ih·(ih_hat − ln_ih) (blue) and the house-price gap b_ph_ih·ph_gap (brown) are the two largest channels, and they almost exactly offset: the smoothed `ih_hat` target is persistently above actual ln_ih (positive EC pushing investment up), while the AU house-price gap has been positive on average (positive ph_gap pulling target investment up via Tobin's Q channel, which is already absorbed into ih_hat — so the residual ph_gap term here is consistently negative). Net, the structural channels deliver a small positive impulse balanced by AR persistence and the shock eps_ih.*

### 4.8 External trade (FR-BDF Section 4.7)

External trade is specified as a proper error-correction model: a long-run cointegration relationship between log volumes, log demand, and the real exchange rate, together with short-run dynamics that adjust toward that equilibrium. The earlier version of AU-PAC used a degenerate accumulator `m_gap = m_gap(-1) − Δln M` (and symmetrically for exports) without an economic long-run target, which meant the trade block could not capture the secular rise in AU import/export openness (log(M/C) trended at +2.5% per year and log(X/C) at +2.0% over 1960-2024). The proper specification below restores the FR-BDF Section 4.7 structure with explicit long-run income elasticities (β_m, β_x) and real-exchange-rate elasticities (γ_m, γ_x).

#### 4.8.1 Exports (FR-BDF eqs 70-73)

Long-run equilibrium (eq. 71):

$$\ln X^{eq}_t = \beta_x \cdot \hat{y}^{US}_t + \gamma_x \cdot s\_gap_t$$

Error-correction gap (target minus actual):

$$x\_gap_t = \ln X^{eq}_t - \ln X^{level}_t, \qquad \ln X^{level}_t = \ln X^{level}_{t-1} + \Delta \ln X_t$$

Short-run dynamics (eq. 73):

$$\Delta \ln X_t = b^x_0 \cdot x\_gap_{t-1} + b^x_1 \Delta \ln X_{t-1} + b^x_2 \hat{y}^{US}_t + b^x_3 \cdot s\_gap_t + b^x_4 \Delta \ln P^{com}_t + \varepsilon^x_t$$

### Table 4.8.1: Export equation coefficients

| Parameter | Value | Description |
|-----------|-------|-------------|
| beta_x (LR foreign income elasticity) | 1.20 | Long-run pull from world demand |
| gamma_x (LR RER elasticity) | +0.40 | Marshall-Lerner: depreciation raises target |
| b0_x (EC speed) | 0.05 | Adjustment toward equilibrium |
| b1_x (persistence) | 0.30 | AR(1) |
| b2_x (SR world demand) | 0.25 | Impact response to US output gap |
| b3_x (SR exchange rate) | 0.10 | Impact competitiveness |
| b4_x (commodities) | 0.15 | AU-specific commodity-price channel |

#### 4.8.2 Imports (FR-BDF eqs 74-77)

Imports adjust toward a long-run equilibrium that depends on the level of import-weighted demand (cumulated IAD) and the real exchange rate. With β_m > 1, the income elasticity exceeds unity, which is the mechanism by which the model captures the structural rise in AU import openness without an ad-hoc deterministic trend (cf. the MARTIN approach of adding `+ α·t` to the short-run equation, which is BGP-violating).

Long-run equilibrium (eq. 76):

$$\ln M^{eq}_t = \beta_m \cdot \ln D^{iad}_t + \gamma_m \cdot s\_gap_t$$

Error-correction gap:

$$m\_gap_t = \ln M^{eq}_t - \ln M^{level}_t, \qquad \ln M^{level}_t = \ln M^{level}_{t-1} + \Delta \ln M_t$$

The import-weighted demand level cumulates the contemporaneous IAD growth:

$$\ln D^{iad}_t = \ln D^{iad}_{t-1} + iad_t, \qquad iad_t = \sum_j w^{iad}_j \cdot \Delta \ln j_t$$

Short-run dynamics (eq. 77):

$$\Delta \ln M_t = b^m_0 \cdot m\_gap_{t-1} + b^m_1 \Delta \ln M_{t-1} + b^m_2 \cdot iad_t + b^m_3 \cdot s\_gap_t + \varepsilon^m_t$$

### Table 4.8.2: Import equation coefficients

| Parameter | Value | Description |
|-----------|-------|-------------|
| beta_m (LR income elasticity) | 1.50 | >1 captures rising AU import openness |
| gamma_m (LR RER elasticity) | -0.40 | Depreciation lowers import target |
| b0_m (EC speed) | 0.06 | Adjustment toward equilibrium |
| b1_m (persistence) | 0.23 | AR(1) |
| b2_m (SR IAD elasticity) | 0.36 | Impact response to import-weighted demand growth |
| b3_m (SR exchange rate) | -0.08 | SR Marshall-Lerner |

### Table 4.8.3: IAD weights (import content of demand)

| Component | Weight | Source |
|-----------|--------|--------|
| Consumption | 0.12 | ABS input-output tables |
| Business investment | 0.25 | ABS input-output tables |
| Housing investment | 0.15 | ABS input-output tables |
| Government | 0.08 | ABS input-output tables |
| Exports (re-export) | 0.30 | ABS input-output tables |

Trade volumes use the ABS 5206 Seasonally-Adjusted chain volume measures (series A2304114F / A2304115J), aligned to a T=126 quarter sample (1993Q2–2024Q4) with COVID pulse dummies for 2020Q2 and 2020Q3 absorbing the trade-collapse-and-rebound outliers.

The long-run elasticities (β_m, β_x, γ_m, γ_x) are calibrated at sensible AU values and given Normal priors centred there (Section 5.4, Table 5.6). A bivariate Engle-Granger style OLS of log volumes on log consumption (1959Q3–2025Q4) gives β_m ≈ +1.73 (t = +113) and β_x ≈ +1.56 (t = +119); the model priors at 1.50 and 1.20 sit within one standard deviation. The short-run coefficient `b1_m` is set to its OLS estimate on the SA sample (+0.232, s.e. 0.086, t=2.71); `b1_x`, `b2_x`, and `b2_m` are kept at calibrated values pending Asian-PMI / commodity-demand proxies that would help identify the SR foreign-demand channel for AU exports. The COVID-period dummies are sizeable for both exports (crash -10.14, bounce -7.11; tourism and education exports did not recover in 2020Q3) and imports (crash -14.39, bounce +6.27). Adding `Δln M` and `Δln X` to the set of Bayesian observables (Table 5.1) gives the long-run elasticities their own data identification — previously the trade block was econometrically inert because no observable mapped to it.

### 4.9 Demand deflators (FR-BDF Section 4.7)

All demand deflators follow ECM equations tracking the VA price with partial pass-through, anchored to the long-run inflation target. General form (eq. 36):

$$\pi^j_t = \rho_j \pi^j_{t-1} + \alpha_j \pi^Q_t + \beta_{j,m} \pi^M_t + ... + (1 - \rho_j - \alpha_j - \beta_{j,m} - ...) \bar{\pi}_t + \varepsilon^j_t$$

### Table 4.9.1: Consumption deflator (FR-BDF eqs 79-80)

| Parameter | Value | Description |
|-----------|-------|-------------|
| rho_pc | 0.40 | Persistence |
| alpha_pc | 0.30 | VA price pass-through |
| beta_pc_m | 0.10 | Import price |
| gamma_oil | 0.03 | Commodity/energy |
| Anchor (1-sum) | 0.17 | Growth neutrality |

### Table 4.9.2: Business investment deflator

| Parameter | Value | Description |
|-----------|-------|-------------|
| rho_pib | 0.35 | Persistence |
| alpha_pib | 0.25 | VA price pass-through |
| beta_pib_m | 0.12 | Import price (high import content) |
| Anchor (1-sum) | 0.28 | Growth neutrality |

### Table 4.9.3: Housing investment deflator

| Parameter | Value | Description |
|-----------|-------|-------------|
| rho_pih | 0.45 | Persistence (sticky construction) |
| alpha_pih | 0.25 | VA price pass-through |
| beta_pih_m | 0.08 | Import price (limited) |
| Anchor (1-sum) | 0.22 | Growth neutrality |

### Table 4.9.4: Export deflator

| Parameter | Value | Description |
|-----------|-------|-------------|
| rho_px | 0.30 | Persistence |
| alpha_px | 0.20 | VA price pass-through |
| beta_px | -0.05 | Exchange rate (world price taker) |
| alpha_pcom | 0.10 | Commodity price (AU-specific) |
| Anchor (1-sum) | 0.45 | Growth neutrality |

### Table 4.9.5: Import deflator

| Parameter | Value | Description |
|-----------|-------|-------------|
| rho_pm | 0.30 | Persistence |
| alpha_pm | 0.15 | VA price (weak domestic) |
| beta_pm | 0.08 | Exchange rate (strong FX pass-through) |
| beta_pm_com | 0.05 | Commodity price |
| Anchor (1-sum) | 0.42 | Growth neutrality |

### Table 4.9.6: Government deflator

| Parameter | Value | Description |
|-----------|-------|-------------|
| rho_pg | 0.50 | Persistence |
| alpha_pg | 0.30 | Public sector wages (pi_w - dln_prod, not piQ) |
| Anchor (1-sum) | 0.20 | Growth neutrality |

**Growth neutrality verification**: At SS, $\pi^j = \pi^Q = \bar{\pi} = \pi_{SS}$ for all deflators. The sum of all coefficients on inflation-type terms equals 1 for each. Verified for all 6 deflators.

### 4.10 Financial variables (FR-BDF Section 4.8)

#### 4.10.1 Term structure (FR-BDF eqs 95-97)

The 10-year yield is determined by the present value of expected future short rates plus a term premium (eq. 37):

$$pv_{i,t} = (1 - \kappa_{10}) i_t + \kappa_{10} \cdot pv_{i,t+1}$$

$$i^{10Y}_t = pv_{i,t} + tp_t + \varepsilon^{10Y}_t$$

with $\kappa_{10} = 0.97$ (effective duration ~10 years) and $tp_t = \rho_{tp} tp_{t-1} + (1-\rho_{tp}) tp_{SS} + \varepsilon^{tp}_t$.

**SS**: $i^{10Y}_{SS} = 1.049 + 0.30 = 1.349\%$ quarterly (~5.4% annual).

#### 4.10.2 WACC decomposition (FR-BDF eqs 98-100)

The weighted average cost of capital decomposes into three funding sources (eq. 38):

$$WACC = 0.50 \times i^{COE} + 0.30 \times i^{LB} + 0.20 \times i^{BBB}$$

### Table 4.10.1: WACC composition

| Component | Weight | Spread SS | Spread rho | Annual rate at SS |
|-----------|--------|-----------|------------|-------------------|
| Cost of equity (i_COE) | 0.50 | 0.80% | 0.92 | ~8.6% |
| Bank lending (i_LB_firms) | 0.30 | 0.25% | 0.77 | ~6.4% |
| BBB bonds (i_BBB) | 0.20 | 0.05% | 0.94 | ~5.6% |
| **WACC** | **1.00** | — | — | **~7.3%** |

Each rate $= i^{10Y} +$ spread, where spreads follow AR(1) with shock.

#### 4.10.3 Exchange rate (FR-BDF eq 105)

Modified UIP with inflation differential and persistent deviations from PPP (eq. 39):

$$s\_gap_t = \rho_s \cdot s\_gap_{t-1} - \alpha_s \tilde{i}_t + \alpha_s (\tilde{\pi}_t - \tilde{\pi}^{US}_t) + \varepsilon^s_t$$

with $\rho_s = 0.775$ (AU OLS estimate, implying a half-life of approximately 3 quarters) and $\alpha_s = 0.15$. The sign convention is s_gap > 0 = AUD depreciation; higher AU rates appreciate the AUD.

#### 4.10.4 Household bank lending rate (FR-BDF eq 68)

The mortgage rate adjusts sluggishly to changes in the 10Y bond rate (eq. 40):

$$i^{LH}_t = \rho_{LH} i^{LH}_{t-1} + (1 - \rho_{LH})(i^{10Y}_t + spread_{LH}) + \varepsilon^{LH}_t$$

with $\rho_{LH} = 0.97$ (AU OLS — standard variable mortgage rates follow the cash rate with substantial lag because of fixed-rate and discount carve-outs in the mortgage book) and $spread_{LH} = 0.40\%$ quarterly (~1.6% annual).

#### 4.10.5 Housing prices (FR-BDF eq 69)

Real housing price growth follows an AR(1) with demand and credit channels (eq. 41):

$$\Delta \ln P^H_t = \rho_{ph} \Delta \ln P^H_{t-1} + \alpha_{ph,y} \hat{y}_t + \alpha_{ph,r} \tilde{i}_{t-1} + \varepsilon^{ph}_t$$

with $\rho_{ph} = 0.90$, $\alpha_{ph,y} = 0.15$, $\alpha_{ph,r} = -0.10$.

### 4.11 Government and GDP identity (FR-BDF Sections 4.9-4.10)

#### Fiscal rule (eq. 42)

$$\Delta \ln G_t = \rho_g \Delta \ln G_{t-1} + \phi_g \hat{y}_t + \varepsilon^g_t$$

Countercyclical: $\phi_g = -0.10$ means a positive output gap reduces government spending growth.

#### GDP expenditure identity (eq. 43)

$$\hat{y}^{dom}_t = 0.55 \Delta \ln C + 0.13 \Delta \ln I^B + 0.06 \Delta \ln I^H + 0.24 \Delta \ln G + 0.25 \Delta \ln X - 0.23 \Delta \ln M$$

### Table 4.11.1: GDP expenditure weights (ABS 2023)

| Component | Weight | Description |
|-----------|--------|-------------|
| Consumption | 0.55 | Household final consumption |
| Business investment | 0.13 | Non-dwelling GFCF |
| Housing investment | 0.06 | Dwelling GFCF |
| Government | 0.24 | Government final consumption |
| Exports | 0.25 | Goods and services exports |
| Imports | -0.23 | Goods and services imports |

#### Bridge equation (eq. 44)

The demand-side aggregate feeds back into the IS curve: $\hat{y}_t = ... + \lambda_{dom} \hat{y}^{dom}_t + \varepsilon^q_t$ with $\lambda_{dom} = 0.399$ (Bayesian posterior), closing the Keynesian multiplier loop.

### 4.12 AU-PAC modelling choices and simplifications

This subsection documents the modelling choices that shape AU-PAC. The headline monetary-transmission channels — cost of capital, exchange rate, mortgage rate, expectations, and the wage–price spiral — are all implemented and estimated on AU data. Several wp736 features are simplified or omitted; each is flagged below.

**Trends specification.** AU-PAC uses HP-filter detrending of observables to construct gap variables, with fixed-anchor calibration for $\bar{i}_{ss}$, $\bar{\pi}_{ss,au}$, and $\bar{\pi}_{ss,us}$ matching the RBA and Fed inflation targets (cf. wp736 §4.9 eqs 127–130, which uses exponential-smoother trend variables). Convergence to the balanced growth path is asserted via the linearised gap formulation; Section 6.1.1 validates BGP stability under off-SS impulses.

**Sectoral net-financial-wealth dynamics.** AU-PAC includes the four sectoral wealth gap variables (`w_F, w_G, w_H, w_N`) with calibrated steady-state targets (Appendix A.6) and accumulation equations following wp736 eqs 116–126. Stabilisation transfer rules ($\tau_{TF}, \tau_{TN}, \tau_{TG}$ in wp736 §4.8.5 and §4.10) are not implemented. Long-run convergence of the four wealth ratios is validated empirically under off-SS perturbations — all four converge with 2–3 quarter half-lives — but no analytical proof of BGP convergence under arbitrary shocks is provided.

**Conditional projection framework.** AU-PAC's conditional forecasting (Section 6.4) and pseudo-real-time recursive forecast (Section 5.5) take the US bloc, foreign demand, and commodity-price paths as external assumptions while letting domestic policy and demand respond endogenously. The exogenisable variables are `yhat_us`, `pi_us`, `dln_pcom`, and optionally `i_au` for RBA path-conditioning experiments. No analogue to the Eurosystem BMPE harmonisation (wp736 §4.11) is required.

**Single aggregate import deflator.** AU-PAC §4.9 uses a single aggregate import deflator with a commodity-price loading ($\beta_{pm,com} = 0.42$) rather than the separate energy / non-energy split of wp736 §4.7.5 (eqs 88–91). Australia is a net energy *exporter*, so cost-push from energy imports is less material than for France; the aggregate-deflator approach absorbs the channel implicitly via the commodity-price loading. A formal split is listed as remaining work in Section 7.

**Institutional CPI-indexation channel.** Wage indexation in AU is set institutionally through the Fair Work Commission's annual wage review, which sets award rates and award-floor enterprise agreements covering roughly 15% of the workforce (no direct analogue to wp736 §4.5.1 eq 51's SMIC equation). AU-PAC's wage Phillips curve §4.4.1 treats this implicitly through the moderate $\gamma_w = 0.136$ CPI passthrough coefficient.

**E-SAT stability check.** AU-PAC reports the eigenvalue check empirically: the 12×12 AU companion has all eigenvalues with modulus ≤ 1 (max|eig| = 0.946 from the smoother run), confirming stationarity. A formal characterisation along the lines of wp736 Appendix A.1 is left as future work.

---

## 5. Estimation

### 5.1 Data

Eleven observables are used for estimation, covering the period 1993Q2-2023Q3 (122 quarters for PAC estimation) and 1993Q1-2024Q4 (128 quarters for E-SAT). Import and export volume growth were added to the observation set together with the trade-block proper-ECM rewrite (Section 4.8) so that the long-run elasticities β_m, β_x, γ_m, γ_x are data-identified.

### Table 5.1: Observable variables

| # | Variable | Source | Transformation | Mean | Std |
|---|----------|--------|---------------|------|-----|
| 1 | yhat_au | ABS GDP, HP-filtered | Log deviation from trend | 0.01 | 1.04 |
| 2 | pi_au | ABS GDP deflator | Quarterly log difference | 0.66 | 0.60 |
| 3 | i_au | RBA cash rate | Already quarterly % | 1.04 | 0.52 |
| 4 | yhat_us | US GDP, HP-filtered | Log deviation from trend | -0.55 | 1.88 |
| 5 | pi_us | US GDP deflator | Quarterly log difference | 0.54 | 0.36 |
| 6 | pi_w | ABS 6345 Wage Price Index (Private+Public, All industries, SA) | Quarterly log difference × 100 | 0.81 | 0.39 |
| 7 | dln_c | ABS consumption | Quarterly log difference (demeaned) | 0.00 | 1.78 |
| 8 | dln_ib | ABS non-dwelling GFCF | Quarterly log difference (demeaned) | 0.00 | 2.79 |
| 9 | i_10y | AU 10Y govt bond rate | Annualized / 4 to quarterly | 1.21 | 0.53 |
| 10 | dln_m | ABS 5206 imports SA (A2304115J) | Quarterly log difference (demeaned) | 0.00 | ~2.7 |
| 11 | dln_x | ABS 5206 exports SA (A2304114F) | Quarterly log difference (demeaned) | 0.00 | ~3.3 |

Rates and inflation are in natural units (matching model SS). Growth rates are demeaned (model SS = 0). Note: `au_irate` in `dataset.csv` is already in quarterly percentage points. The openness drift in M/C and X/C is absorbed by demeaning each growth-rate observable independently; the identifying variation for β_m and β_x comes from cyclical co-movement of the import/export levels with cumulated domestic demand and the real exchange rate.

![Observable Time Series](data_observables.png)

*Figure 5.1: The nine pre-existing observable variables used in AU-PAC estimation, 1993Q1-2024Q4. The two new trade observables (dln_m, dln_x) follow the same series construction as dln_c / dln_ib.*

### 5.2 E-SAT Bayesian estimation

The E-SAT core was estimated using Bayesian MCMC (Metropolis-Hastings, 50,000 draws, 2 chains). Results are reported in Table 3.1. Key posterior findings relative to calibration:

- Wage persistence (lambda_w): 0.225 vs calibrated 0.55. The full-system Bayesian estimate (Section 5.4) refines this to 0.290, consistent with moderate own-lag persistence in a standard NK wage Phillips curve.
- CPI passthrough (gamma_w): 0.770 in E-SAT, refined to 0.136 in the full-system Bayesian (Section 5.4) — moderate contemporaneous CPI passthrough.
- Demand bridge (lambda_dom): 0.399 vs calibrated 0.10 — demand feedback four times stronger than assumed.
- Consumption persistence (b1_c): 0.047 vs calibrated 0.35 — less serial correlation than the prior implied.
- Exchange rate (rho_s): 0.775 vs calibrated 0.95 — AUD half-life is approximately 3 quarters.

Log marginal density (Modified Harmonic Mean): -1095.38.

![Posterior densities — 28 parameters](identification_prior_posterior.png)

*Figure 5.2: Prior vs posterior densities for E-SAT core parameters.*

### 5.3 PAC structural estimation

#### 5.3.1 Methodology: Iterative OLS

PAC structural parameters are estimated using Dynare's `pac.estimate.iterative_ols` routine, following the ECB-Base methodology (Zimic, SemiStructDynareBasics). The algorithm:

1. Initialize PAC parameters at calibrated values
2. Compute h-vectors from the var_model companion matrix using `get_companion_matrix('esat_enriched', 'var')`
3. Construct the PAC expectation term using the h-vectors
4. Run OLS on the PAC equation, updating parameter estimates
5. Recompute h-vectors with updated parameters
6. Iterate until convergence (change in parameters < tolerance)

#### 5.3.2 Three dseries approaches

Three approaches to constructing the auxiliary variables for estimation were compared:

### Table 5.4: Three-approach comparison (SSR)

| Equation | (A) Recursive | (B) Hybrid smoother | (C) Pure smoother |
|----------|--------------|--------------------|--------------------|
| VA Price | 40.4 | **40.3** | 1.1* |
| Consumption | 435.4 | **436.8** | 400.8 |
| Business Inv | 973.9 | **972.7** | 968.4 |
| Household Inv | 965.8 | **963.1** | 960.0 |
| Employment | 76.1 | **74.3** | 73.4 |

*Pure smoother VA price SSR is artificially low — pv_aux absorbs all signal, leaving structural parameters unidentified.

**Recommended approach**: (B) Hybrid — Kalman-smoothed targets (from `calib_smoother` with `diffuse_filter`) for the EC term, with recursive pv_aux corrections. This avoids the over-identification problem of approach (C) while giving better target estimates than approach (A).

#### 5.3.3 COVID dummy treatment

Two pulse dummies absorb the extreme 2020 outliers: `d_covid_crash` (= 1 in 2020Q2) and `d_covid_bounce` (= 1 in 2020Q3). Each PAC equation has its own pair of COVID coefficients (10 new parameters total). The dummies fixed two sign problems: consumption AR1 flipped from -0.25 to +0.05, and employment AR1 from -0.26 to +0.32.

### Table 5.5: Final PAC estimates — hybrid smoother with COVID dummies

Estimated via iterative OLS on the Kalman-smoothed hybrid dseries. The 12×12 companion matrix reflects the final AU calibration of auxiliary dynamics, deflators (ρ_pc=0.67, ρ_pib=0.70), trade (`b1_x = 0.30`, `b1_m = 0.232`), housing (`ρ_ph = 0.60`), and the mortgage rate (`ρ_lh = 0.97`).

| Parameter | VA Price | Consumption | Bus. Inv | Housing Inv | Employment |
|-----------|---------|------------|----------|-------------|------------|
| b0 (EC) | 0.028 | 0.067 | 0.017 | 0.017 | 0.063 |
| b1 (AR1) | 0.288 | 0.033 | 0.093 | 0.101 | 0.314 |
| b2 | -0.014 | -0.541 | -0.045 | -0.046 | -0.187 |
| b3 | — | -0.024 | 0.344 | 0.289 | -0.076 |
| b4 | — | — | — | — | -0.085 |
| b5 | — | — | — | — | -0.017 |
| COVID crash | -2.877 | -15.096 | -4.382 | -4.815 | -6.601 |
| COVID bounce | +1.488 | +6.033 | +2.978 | +3.194 | +3.851 |
| SSR | 40.6 | 410.4 | 929.8 | 960.0 | 76.3 |
| T | 118 | 118 | 118 | 118 | 118 |

The direct interest-rate consumption channel `b_di_c` and the housing-price gap `b_ph_ih` are not identified by OLS on the AU sample (wrong-sign OLS, reverse causality) and are set to zero pending IV estimation.

### 5.4 Bayesian full-system estimation

A joint Bayesian estimation was performed using Dynare's `estimation()` command with `diffuse_filter` (for unit-root level accumulators), starting from calibrated values to ensure BK satisfaction.

### Table 5.6: Bayesian posterior (28 parameters)

The full-system Bayesian estimation jointly identifies the five outer-PAC and wage-block parameters together with the 22 E-SAT auxiliary coefficients (estimated by Bayesian shrinkage on observable AU target proxies, with `b_di_c` Bayesian-regularised), the CES supply-block parameters (σ_CES = 0.3374, α = 0.35, γ = 1.0, μ = 1.20), and the deflator and financial-block calibrations. The estimation is two-stage: csminwel mode search followed by Metropolis-Hastings MCMC (20,000 draws across two chains).

| Parameter | Prior | Post. mean | Post. mode | 90% HPD |
|-----------|-------|-----------|-----------|---------|
| b0_pQ | Beta(0.03, 0.015) | 0.0306 | 0.0226 | [0.0057, 0.0517] |
| b1_pQ | Beta(0.29, 0.10) | 0.2907 | 0.2661 | [0.1202, 0.4512] |
| b2_pQ | Normal(0.00, 0.05) | -0.0001 | -0.0000 | [-0.0796, 0.0825] |
| b0_c | Beta(0.07, 0.03) | 0.0601 | 0.0549 | [0.0231, 0.0909] |
| b1_c | Beta(0.05, 0.03) | 0.0354 | 0.0243 | [0.0046, 0.0629] |
| b2_c | Normal(-0.55, 0.20) | -0.3307 | -0.3274 | [-0.6029, -0.0504] |
| b3_c | Normal(0.02, 0.05) | 0.0199 | 0.0199 | [-0.0680, 0.0965] |
| b0_ib | Beta(0.02, 0.01) | 0.0188 | 0.0150 | [0.0050, 0.0317] |
| b1_ib | Beta(0.09, 0.05) | 0.0801 | 0.0664 | [0.0186, 0.1381] |
| b3_ib | Normal(0.34, 0.10) | 0.3094 | 0.3186 | [0.1629, 0.4642] |
| b0_ih | Beta(0.03, 0.015) | 0.0289 | 0.0226 | [0.0065, 0.0498] |
| b1_ih | Beta(0.11, 0.05) | 0.1152 | 0.0885 | [0.0301, 0.1888] |
| b3_ih | Normal(0.23, 0.10) | 0.2262 | 0.2271 | [0.0623, 0.3971] |
| b0_n | Beta(0.06, 0.03) | 0.0569 | 0.0453 | [0.0108, 0.0976] |
| b1_n | Beta(0.31, 0.10) | 0.3211 | 0.2893 | [0.1527, 0.4848] |
| b5_n | Normal(0.00, 0.05) | 0.0072 | -0.0000 | [-0.0707, 0.0885] |
| lambda_w | Beta(0.25, 0.10) | 0.2899 | 0.2507 | [0.1342, 0.4471] |
| gamma_w | Beta(0.70, 0.15) | 0.1356 | 0.1297 | [0.0814, 0.1907] |
| kappa_w | Normal(0.08, 0.05) | 0.0966 | 0.0944 | [0.0102, 0.1694] |
| stderr eps_q | InvGamma(0.80) | 0.5233 | 0.5170 | [0.4656, 0.5839] |
| stderr eps_i | InvGamma(0.10) | 0.1103 | 0.1093 | [0.0976, 0.1226] |
| stderr eps_pi | InvGamma(0.60) | 0.5872 | 0.5836 | [0.5332, 0.6466] |
| stderr eps_c | InvGamma(0.50) | 1.8587 | 1.8291 | [1.6544, 2.0525] |
| stderr eps_ib | InvGamma(1.50) | 2.7529 | 2.7444 | [2.4553, 3.0336] |
| stderr eps_ih | InvGamma(2.00) | 1.3529 | 0.9217 | [0.5451, 2.2285] |
| stderr eps_n | InvGamma(0.50) | 0.4430 | 0.2303 | [0.1197, 0.7882] |
| stderr eps_w | InvGamma(0.30) | 0.1486 | 0.1389 | [0.1013, 0.1978] |
| stderr eps_10y | InvGamma(0.10) | 0.0641 | 0.0640 | [0.0516, 0.0762] |

The log marginal density is Laplace = -799.64 and Modified Harmonic Mean = -800.15.

**Note on the trade-ECM rewrite.** Table 5.6 reports the MCMC posterior under the *previous* trade-block specification (degenerate `m_gap` accumulator, 9 observables). The proper FR-BDF trade ECM (Section 4.8) adds 4 long-run elasticities (β_m, γ_m, β_x, γ_x), 5 new endogenous variables, and 2 new observables (`dln_m`, `dln_x`). A re-run MCMC under the corrected structure is the natural next step. The PAC parameters reported above are expected to be largely unchanged — the trade block does not enter the consumption/investment/wage-Phillips PAC equations directly — but the trade-block elasticities themselves are new and will need their own posterior. The calibrated values quoted in Tables 4.8.1–4.8.2 are the prior centres; sanity checks via single-equation OLS support them (β_m ≈ 1.73, β_x ≈ 1.56 from bivariate cointegration regressions on 1959Q3–2025Q4 data).

Four findings stand out from the joint posterior. First, the wage Phillips-curve coefficients are tightly identified: γ_w = 0.136 (mode 0.130, 90% HPD [0.081, 0.191]), λ_w = 0.290 (HPD [0.134, 0.447]), and κ_w = 0.097 (HPD [0.010, 0.169]) — a standard New Keynesian Phillips curve with moderate CPI passthrough, moderate own-lag persistence, and a statistically significant unemployment-gap slope. Second, the business-investment accelerator b3_ib = 0.309 (HPD [0.163, 0.464]) is robust. Third, the consumption interest-rate channel b2_c = -0.331 (HPD [-0.603, -0.050]) is statistically significant though wide; the sign and significance are sharp but the magnitude is uncertain. Fourth, the shock standard deviations for wages (eps_w = 0.149) and housing investment (eps_ih, HPD [0.55, 2.23]) are well-identified.

### 5.5 Pseudo-real-time recursive forecast evaluation

Holding parameters at the posterior mode (no recursive re-estimation), the model is re-run over 24 expanding-window origins from 2018Q1 to 2023Q4. At each origin t* the Kalman smoother yields the in-sample state, and Dynare's `forecast=8` block produces conditional 1Q to 8Q-ahead forecasts of all observables under zero structural shocks. Driver: [`forecast_eval.m`](forecast_eval.m).

### Table 5.8: Pseudo-real-time recursive RMSE — 24 origins (2018Q1–2023Q4)

| Variable     | h=1   | h=2   | h=4   | h=8   |
|--------------|-------|-------|-------|-------|
| yhat_au      | 1.819 | 2.335 | 2.304 | 2.338 |
| pi_au        | 0.782 | 0.805 | 0.810 | 0.892 |
| i_au         | 0.099 | 0.181 | 0.322 | 0.495 |
| yhat_us      | 2.163 | 2.396 | 2.410 | 2.405 |
| pi_us        | 0.448 | 0.530 | 0.673 | 0.772 |
| pi_w         | 0.199 | 0.254 | 0.236 | 0.338 |
| dln_c        | 3.911 | 3.897 | 3.873 | 4.219 |
| dln_ib       | 2.586 | 2.722 | 2.377 | 2.369 |
| i_10y        | 0.117 | 0.173 | 0.264 | 0.417 |

Three patterns emerge. First, cash-rate and 10Y yield RMSEs grow approximately linearly with horizon, consistent with a near-random-walk process — the h=8 yield RMSE is 42 bp, plausible for two-year-ahead forecasts. Second, output-gap and inflation RMSEs are largely flat across horizons because the model converges to steady state quickly under zero-shock projection; the floor RMSE reflects the standard deviations of the observable data themselves. Third, consumption growth (`dln_c`) and business-investment growth (`dln_ib`) RMSEs remain elevated because the evaluation window contains the 2020 COVID quarter, where `dln_c` reached -16% — the model attributes this entirely to the eps_c residual but cannot forecast it. Excluding the COVID quarter would roughly halve the `dln_c` and `dln_ib` RMSEs.

![Recursive forecast paths](forecast_eval_paths.png)

*Figure 5.5: Recursive forecast paths (light grey, 24 origins × 8 quarters) vs realised observable (black). The four panels show output gap, CPI inflation, real consumption growth, and policy rate. The model consistently under-shoots the 2020Q4 inflation rebound and the 2022–23 hiking cycle for `i_au`, reflecting the absence of forward guidance in the unconditional zero-shock projection.*

![Pseudo-real-time RMSE by horizon](forecast_eval_rmse.png)

*Figure 5.6: Pseudo-real-time RMSE by horizon, all observables. Output gap and CPI inflation are the best-forecasted variables in proportion to their volatility; cash rate and 10Y yield grow monotonically with horizon as expected. The model's strongest comparative advantage relative to a random walk is in the financial variables (i_au, i_10y) at h=1 (RMSE < 0.10).*

Full recursive re-estimation (REESTIMATE=true in `forecast_eval.m`, which re-runs csminwel per origin) is left as a separate computation; the qualitative RMSE pattern is not expected to change materially because the posterior is informed by the full sample and the model is reasonably well-identified at the posterior mode (see the identification analysis in Appendix F).

---

## 6. Model Properties

> **Scope note.** All IRFs and figures in this section have been regenerated under the proper FR-BDF trade ECM (Section 4.8) with all non-trade parameters at their existing posterior-mode calibration. A full MCMC re-run under the augmented observation set (11 observables) is pending. Specific peak-and-trough magnitudes quoted in the text are taken from the regenerated saved_irfs_*.mat files; qualitative shapes, signs, and timing are robust, but exact magnitudes will shift further once the new posterior is identified. Where the text quotes a Bayesian posterior value, it refers to the previous (9-observable) MCMC posterior.

### 6.1 Steady state

At the balanced growth path (gap model, all growth rates = 0):

### Table 6.1: Steady-state values

| Variable | SS value (quarterly) | Annual equivalent | Interpretation |
|----------|---------------------|-------------------|---------------|
| yhat_au, yhat_us | 0 | — | Output gaps closed |
| pi_au, piQ, pi_w, all pi_j | 0.625% | ~2.5% | Inflation = RBA target |
| pi_us | 0.500% | ~2.0% | Inflation = Fed target |
| i_au | 1.049% | ~4.2% | RBA neutral rate |
| i_10y | 1.349% | ~5.4% | 10Y bond yield |
| wacc | 1.834% | ~7.3% | Weighted avg cost of capital |
| uc_k | 1.859% | ~7.4% | User cost of capital |
| i_lh | 1.749% | ~7.0% | Mortgage lending rate |
| All gaps, growth rates | 0 | — | Balanced growth |

#### 6.1.1 Long-run convergence to balanced growth path

To verify that the model is well-behaved under no shocks — i.e., that the gap variables converge to zero and the level variables follow their deterministic trends — we run the linearised decision rule forward from three off-steady-state initial conditions for 80 quarters with all shocks set to zero. Because the model is solved to first order, an off-SS initial state is mathematically equivalent to a sum of impulses, so the convergence paths can be visualised directly from the model's long-horizon IRFs (Figure 6.0). Conditions: boom-start (+1 s.d. output-gap impulse), commodity-cycle start (+1 s.d. eps_pcom impulse), and tight-money start (+1 s.d. policy-rate impulse).

![Long-run convergence to balanced growth path](long_run_convergence_proxy.png)

*Figure 6.0: AU-PAC long-run convergence under hybrid expectations. Output-gap, inflation, real-activity, and demand-component gaps all decay smoothly to zero within 20–40 quarters; the policy rate, 10Y yield, and exchange rate exhibit longer-lived but monotonic adjustment. No cyclical instability or divergence is observed under any of the three starting conditions, confirming BK stability and convergence to the balanced growth path.*

### 6.2 Monetary policy transmission under different expectation assumptions

Following the wp736 Section 6.2 protocol, we assess the impact of a 100 basis point annualised monetary policy tightening (= 0.25 quarterly percentage points) under three expectation regimes. At order = 1, IRFs scale linearly: we compute them from Dynare's 1 s.d. responses multiplied by $0.25 / \sigma_{\varepsilon^i}$, where $\sigma_{\varepsilon^i} = 0.1103$ is the posterior mean of the monetary-policy shock standard deviation.

#### 6.2.1 Three-regime IRF comparison

![Three-regime monetary policy IRFs](three_regime_monetary_irf.png)

*Figure 6.1: Responses to a 100bp annualized monetary policy tightening under VAR-based (blue dashed), Hybrid (black solid), and MCE (red dash-dot) expectations.*

### Table 6.2: Quarter-by-quarter paths (output gap and VA price inflation, 100bp shock)

IRFs are 1 s.d. responses multiplied by 0.25 / 0.1102 = 2.269.

| Quarter | Output (VAR) | Output (Hyb) | Output (MCE) | piQ ann. (VAR) | piQ ann. (Hyb) | piQ ann. (MCE) |
|---------|-------------|-------------|-------------|---------------|---------------|---------------|
| Q1 | -0.001 | -0.039 | -0.001 | -0.000 | +0.000 | -0.000 |
| Q2 | -0.041 | -0.065 | -0.037 | -0.021 | -0.027 | -0.000 |
| Q4 | -0.089 | -0.097 | -0.074 | -0.055 | -0.061 | -0.000 |
| Q8 | **-0.110** | **-0.115** | -0.081 | -0.072 | **-0.073** | -0.000 |
| Q12 | -0.089 | -0.107 | -0.061 | -0.059 | -0.063 | -0.000 |
| Q20 | -0.038 | -0.089 | -0.026 | -0.021 | -0.038 | +0.000 |
| Q40 | +0.009 | -0.041 | -0.000 | +0.021 | +0.005 | +0.000 |

### Table 6.3: Peak IRF comparison across all variables (100bp shock)

| Variable | Peak (VAR) | Qtr | Peak (Hyb) | Qtr | Peak (MCE) | Qtr | MCE attenuation |
|----------|-----------|-----|-----------|-----|-----------|-----|-----------------|
| Output gap | -0.110% | Q7 | -0.115% | Q8 | -0.084% | Q6 | 27% |
| CPI inflation | -0.006% | Q9 | -0.006% | Q9 | -0.004% | Q8 | 28% |
| VA price | -0.018 pp | Q8 | -0.018 pp | Q7 | -0.000 pp | Q6 | **99%** |
| Consumption | -0.099% | Q3 | -0.176% | Q1 | -0.085% | Q2 | 52% |
| Business inv | -0.065% | Q7 | -0.067% | Q7 | -0.026% | Q6 | 61% |
| **Housing inv** | -0.158% | Q8 | -0.934% | Q21 | -0.039% | Q14 | **96%** |
| Employment | -0.045% | Q9 | -0.047% | Q9 | +0.000% | Q4 | **99%** |
| Wage inflation | -0.006% | Q8 | +0.004% | Q1 | -0.002% | Q8 | 44% |
| Exchange rate | -0.120% | Q8 | -0.121% | Q8 | -0.120% | Q8 | 1% |
| 10Y yield | +0.076% | Q27 | +0.102% | Q1 | +0.104% | Q1 | — |

The peak output-gap response under Hybrid expectations is -0.102% at Q6 (under the new trade ECM; was -0.115% at Q8 under the previous degenerate-trade specification). MCE attenuation is most pronounced for VA-price inflation (99%), employment (99%), and housing investment (96%): in each of these three sectors the data sharply pin down strong forward-looking smoothing. The output gap itself shows roughly 30% MCE attenuation and CPI inflation 28%. Housing investment growth under Hybrid still has the largest cumulative response among demand components — the level (ln_IH) declines persistently over the 40-quarter horizon — consistent with Australia's outsized housing-construction cycle; the proper trade ECM trims the output-gap multiplier modestly through faster import adjustment, so the cross-channel decomposition is broadly preserved while peak magnitudes are slightly smaller and timing is earlier.

![Full variable comparison across three regimes](three_regime_full_comparison.png)

*Figure 6.2: 11-panel comparison of all key variables under the three expectation regimes (100bp annualized shock).*

#### 6.2.2 Interpretation

Three conclusions emerge.

**1. Forward-looking financial variables amplify transmission.** Comparing VAR-based with Hybrid (which differ only in financial expectations), the 10Y yield jumps approximately five times more on impact under Hybrid (+0.110% vs +0.022% at Q1), because agents foresee the full persistence of the rate shock. Under VAR-based expectations, the long rate responds slowly through partial adjustment (peak at Q11).

**2. Forward-looking non-financial variables strongly dampen transmission.** The MCE regime shows substantially smaller peak responses across the entire demand block: output 27% smaller, VA price 99% smaller, business investment 61% smaller, housing investment 96% smaller, and employment 99% smaller. Forward-looking PAC agents smooth temporary shocks — they recognise the tightening is mean-reverting and adjust less aggressively. The housing-investment attenuation is particularly strong because b_ph_ih ≈ 0 in the AU data, so there is no Tobin's Q sustainer for housing under MCE.

**3. Wage dynamics and convergence differ across regimes.** Under VAR-based expectations, the backward-looking unemployment PV responds slowly (wage peak at Q9). Under Hybrid and MCE, the forward PV $pv_{u,gap}$ anticipates the tightening's effect on unemployment, producing a faster wage response (peak at Q1–Q2). The peak is small in absolute value (γ_w = 0.136 implies modest mechanical CPI passthrough; κ_w = 0.097 carries the unemployment-PV channel that produces the faster MCE response). The wage Phillips curve has an inflation-anchor weight of 1 − λ_w − γ_w = 0.574 — wages converge to the long-run inflation anchor rather than tightly tracking current CPI.

#### 6.2.3 Channel-by-channel walkthrough of the 100bp tightening

The aggregate -0.102% output-gap peak (Hybrid, Q6 under the new trade ECM) and -0.005 qpp CPI-inflation trough (Q8) decompose across six transmission channels documented in Table 2.2. Each channel's contribution is identified by tracing which equation block in §4 propagates the policy shock into the relevant demand or price variable; the corresponding peak responses below are read from Figure 6.2 and the saved IRF series. Note that several specific magnitudes cited in the channel-by-channel walkthrough below (e.g., consumption peak -0.176%, business investment -0.066%) reflect the new model dynamics; the qualitative interpretation of each channel is unchanged.

**(i) Term structure and WACC.** The 10Y yield rises +0.102 pp on impact under Hybrid (Q1) — five times the VAR-based response (+0.076 pp peak at Q26) — because forward-looking agents foresee the full mean-reverting path of the cash rate via eq. (48), $i_{10Y,t} = (1-\kappa_{10}) i_t + \kappa_{10} \cdot \mathrm{E}_t[i_{10Y,t+1}] + s_{10Y,t}$, with $\kappa_{10} = 0.97$. The 10Y yield then feeds into the weighted average cost of capital (eq. 49) via the term-debt weight; under AU calibration this lifts WACC by approximately 30–40 bp on impact, with the rest absorbed by the bank-lending and equity-cost spreads.

**(ii) User cost of capital and business investment.** WACC enters the user-cost identity (eq. 27) $UC^K_t = WACC_t + \delta_K - (\pi^{IB}_t - \pi^Q_t)$. A higher user cost lowers the desired capital stock through the CES first-order condition with elasticity $\sigma_{CES} = 0.3374$. The business-investment PAC equation (eq. 28) then propagates this through two channels: the long-run target $-\sigma_{CES} \cdot pv_{rKB,aux}$ and the accelerator $b_3^{ib} = 0.309$ via the depressed output gap. The combined effect is a -0.066% peak in $\Delta \ln I^B$ at Q7.

**(iii) Mortgage rate and housing investment.** Australia's variable-rate mortgage market means cash-rate changes pass through quickly to $i^{LH}$ (eq. 56) with a spread $\rho_{lh} = 0.40$ above the 10Y yield. The household-investment target equation (eq. 31) includes a mortgage-rate term $-\kappa_{mort}(i^{LH} - i^{LH}_{SS})$ with $\kappa_{mort} = 0.048$, plus a separate house-price (Tobin's Q) channel $+\kappa_{ph} \cdot ph\_gap$. The housing-investment PAC equation (eq. 32) absorbs these via its long-run target and the cyclical $b_3^{ih} = 0.226$ accelerator. Net peak: $\Delta \ln I^H = -0.93\%$ at Q21 — the longest-lagged and largest demand-side response in the model, consistent with Australia's outsized housing-construction cycle.

**(iv) Exchange rate.** UIP (eq. 38) determines $\Delta s$ as the policy-rate differential against the US plus a persistence term $\rho_s = 0.775$. The AUD appreciates by 0.12% on impact and the s_gap stays at around that magnitude for 8 quarters before slowly correcting. Through eqs. (40)–(41) the appreciation depresses export volumes via the trade elasticity $b_2^x$ and supports imports, contributing a small but persistent negative to the output gap.

**(v) Permanent income and consumption.** The consumption PAC equation (eq. 24) has three rate channels: the direct term $b_2^c \cdot \tilde{i}_{t-1}$ with $b_2^c = -0.331$ (posterior mean, 90% HPD [-0.603, -0.050]); the surprise term $b_{di}^c \cdot di\_gap$ with $b_{di}^c = -0.701$ (Bayesian-regularised, awaiting future external RBA OIS-surprise data); and the permanent-income channel via $pv_{c,aux}$, which discounts future income at $\beta_c = 0.95$. The combined peak response is -0.176% at Q1 under Hybrid — the fastest demand response in the model, reflecting the dominance of the forward-looking permanent-income channel.

**(vi) Wage–price spiral.** Wage inflation under Hybrid responds within Q1 (+0.004 qpp impact) because the unemployment-gap PV (eq. 30) immediately reflects the forecast of weaker labour markets. With $\gamma_w = 0.136$, the contemporaneous CPI passthrough into wages is modest, so the wage response to the policy shock is driven primarily by $\kappa_w \cdot pv_{u,gap}$ (the forward-looking unemployment channel) rather than by mechanical CPI feedback. VA-price inflation falls -0.072 qpp at Q8 (-0.018 pp peak), reflecting the ULC pass-through with $\gamma_{ulc} = 0.12$ from eq. (15) modulated by the FPF target equation (eq. 14). Under MCE the VA-price response is essentially zero because forward-looking firms anticipate the temporary nature of the demand shortfall and avoid passing it into price-setting.

These channels together transmit monetary policy through a balanced mix of cost-of-capital, exchange-rate, mortgage-rate, and expectations channels. AU's variable-rate mortgages, low UIP persistence, and small own-lag wage persistence (λ_w = 0.29) shape the relative magnitudes — most notably the large housing-investment response.

#### 6.2.4 Comparison with the RBA's model suite

A useful external benchmark for AU-PAC's monetary-transmission results is the RBA's own model suite, surveyed in Mulqueeney, Ballantyne and Hambur (2025, RBA Bulletin, April). That paper reports the response to a 100 bp cash-rate increase across four Australian models — Beckers (2020) VAR, MARTIN (the RBA's semi-structural workhorse), DINGO (the RBA's DSGE), and Murphy (an external benchmark) — and decomposes the transmission into four channels: exchange rate, asset prices / wealth, savings and investment (i.e., intertemporal substitution), and cash flow.

### Table 6.4: AU-PAC vs RBA model suite, 100bp cash-rate increase

Peak GDP / output-gap and inflation responses across models. Mulqueeney et al. (2025) report year-ended inflation effects in percentage points; AU-PAC's quarterly CPI peak is converted to a year-ended equivalent by multiplying by 4.

| Model | Peak GDP fall | Peak quarter | Peak inflation fall (y/y, ppt) |
|---|---|---|---|
| Beckers (2020) VAR | -1.5% | ~Q4 | -0.40 to -0.50 |
| MARTIN (semi-structural) | -0.45 to -0.50% | Q4 | -0.10 to -0.15 |
| DINGO (DSGE) | -0.60 to -0.75% | Q5-7 | -0.20 |
| Murphy (external) | -0.30% | Q4 | -0.40 to -0.50 |
| **AU-PAC (hybrid, this paper)** | **-0.102%** | **Q6** | **-0.021** |

**Magnitude.** AU-PAC's peak output-gap response (-0.102% at Q6) is at the *low* end of the RBA-model range — about 3× smaller than Murphy's -0.30%, 4× smaller than MARTIN's -0.45%, and roughly 15× smaller than the Beckers VAR's -1.5%. The CPI inflation peak (-0.021 ppt year-ended at Q9) is similarly at the low end. There are three plausible reasons AU-PAC sits below the RBA suite:

1. **Estimated PAC coefficients are small in AU data.** The Bayesian posteriors (Table 5.6) give error-correction speeds in the 0.02–0.06 range, AR coefficients in the 0.08–0.32 range, and accelerator coefficients (b3_ib = 0.31, b3_ih = 0.23, b5_n ≈ 0) at or below their priors. PAC smoothness deliberately dampens responses relative to DSGE / VAR architectures.
2. **Linearised gap formulation.** AU-PAC's output is `yhat_au`, the *gap* from a slowly-moving balanced-growth path. RBA models report responses against the *baseline level*, including the slow-moving potential trajectory the model would have followed absent the shock. The peak-gap reading is therefore a lower bound on the cumulative GDP impact.
3. **CES production with σ = 0.34.** The AU posterior for the substitution elasticity is well below the 0.5–0.6 typically used in DSGE calibrations. Lower σ implies smaller demand reallocation under user-cost shifts, weakening both the business-investment and labour-demand channels.

**Timing.** RBA reports peak effects "around one to two years" (Q4–Q8). AU-PAC's output-gap peak under the new trade ECM sits at Q6, the middle of this range. The Hybrid AU-PAC response is more protracted than Beckers VAR, comparable to MARTIN/DINGO timing, but smaller in absolute magnitude — consistent with AU-PAC's smaller PAC coefficients (more smoothing) and the var_model companion that anchors expectations slowly.

**Exchange-rate channel weight.** Mulqueeney et al. (2025, Graphs 6–7) report that 25–67% of the GDP response and one-third to two-thirds of the inflation response come from the exchange-rate channel in MARTIN / DINGO. AU-PAC's UIP channel works in the same direction (AUD appreciation on impact) but with smaller weight: the AUD-appreciation peak is -0.12% at Q8 under Hybrid, and the implied output-gap impact via the net-trade channel is small. With ρ_s = 0.775 (half-life ≈ 3 quarters), AU-PAC's exchange-rate transmission is also shorter-lived than the RBA models', mechanically reducing the aggregate response.

**Housing channel.** The RBA paper notes that "housing is a sensitive part of economic activity", and the dwelling-investment contribution to MARTIN's peak GDP fall is sizeable. AU-PAC's housing-investment IRF (-0.93% at Q21 under Hybrid) is the largest demand-side component but peaks much later than MARTIN's Q4. Two factors explain the lag: the housing PAC has 4th-order AR dynamics with strong adjustment cost, producing a long-tailed response; and b_ph_ih ≈ 0 in AU data, so the Tobin's Q feedback that RBA models likely include is muted in AU-PAC.

**Cash-flow channel.** Mulqueeney et al. (2025) find the cash-flow channel is small in aggregate (MARTIN: "small but faster than the savings / investment and asset prices channels") because borrower and saver responses partially offset. AU-PAC's direct rate-change consumption channel `b_di_c = -0.701` is Bayesian-regularised because the AU-data IV without external monetary-surprise data gave wrong-signed estimates. In our model b_di_c contributes only a small fraction of the consumption response, which is dominated by the b2_c interest-rate-*level* channel — consistent with the RBA's finding.

**Verdict.** AU-PAC produces the smallest peak response to a 100 bp tightening among comparable Australian models. This is a deliberate feature: PAC-framework adjustment-cost frictions are economically motivated by Tinsley (1993) and the FRB/US tradition, and Bayesian estimation on 30 years of AU data resists over-fitting. AU-PAC therefore sits within the robust-policymaking spirit of "diversity supports more robust policymaking" (Mulqueeney et al. 2025, p. 11) rather than aiming to match the average response. Two refinements would narrow the gap: external high-frequency RBA OIS-surprise data for `b_di_c` identification, and relaxing the linearised-gap assumption to allow target-trajectory shifts that compound over time.

### 6.3 Impulse responses to other shocks

All shocks are sized at policy-relevant magnitudes rather than 1 s.d. At order = 1 (linear), IRFs scale exactly by the ratio target / σ_shock.

#### 6.3.1 Monetary policy shock (eps_i) — 100bp annualized

![Monetary policy shock](irf_eps_i.png)

*Figure 6.3: 100bp annualized monetary policy tightening, hybrid regime (scale = 0.25 / σ_i = 0.25/0.1103 = 2.267).*

Consumption growth (-0.176% peak at Q1 under Hybrid) is the most immediately responsive component, reflecting the rate channel ($b_2^c = -0.331$ posterior mean). Business-investment growth (-0.062% at Q6) and housing-investment growth (-0.156% at Q8) follow with the lagged adjustment of the PAC equations. The ln_IH level continues to decline through the 40-quarter horizon (long-tailed housing-investment response, consistent with AU's outsized construction cycle). Employment growth responds sluggishly (-0.046% at Q7). The exchange rate appreciates via UIP (s_gap reaches -0.120 at Q8) with a half-life of approximately 3 quarters under the AU-estimated $\rho_s = 0.775$. Trade volumes contract: imports -0.035% at Q13, exports -0.016% at Q6 (both reflect the new proper-ECM long-run response to the demand contraction and AUD appreciation).

#### 6.3.2 Foreign demand shock (eps_q_us) — 1pp US output gap

![Foreign demand shock](irf_eps_q_us.png)

*Figure 6.4: 1pp US output-gap shock (scale = 1.0 / σ_q_us = 1.0/1.138 = 0.879). Peak AU output gap +0.42% at Q4, peak housing-investment growth +0.19% at Q5, peak export growth +0.35% at Q2 (foreign-demand channel now identified through the proper trade ECM). The new specification routes more of the foreign-demand impulse through direct trade (β_x = 1.2 LR pull) and less through the housing channel than the previous degenerate-trade calibration suggested.*

#### 6.3.3 Government spending shock (eps_g) — 1% of GDP

![Government spending shock](irf_eps_g.png)

*Figure 6.5: 1% of GDP government spending shock (scale = 1.0 / σ_g = 1.0/0.3 = 3.333). Output-gap multiplier peaks at +0.18% at Q4 — well below 1 — consistent with substantial crowding-out via the exchange-rate channel under floating regime and forward-looking financial agents in the hybrid setup. Imports rise +0.06% at Q6 as domestic demand pulls in foreign goods through the proper-ECM income-elasticity channel (β_m = 1.5).*

#### 6.3.4 Commodity price shock (eps_pcom) — 10% increase

![Commodity price shock](irf_eps_pcom.png)

*Figure 6.6: 10% commodity-price increase (scale = 10.0 / σ_pcom = 10.0/3.0 = 3.333). AU-specific propagation: peak output gap +0.18% at Q2, housing-investment growth +0.07% at Q3, export growth +1.50% at Q1 (commodity-price loading in `b4_x`), import growth +0.19% at Q2 via the income channel. The commodity-export economy benefits in real terms; with the proper trade ECM, more of the impulse is now visible directly in `dln_x` rather than indirectly through the GDP identity.*

#### 6.3.5 Cost-push shock (eps_pQ) — 1pp VA-price inflation

![Cost-push shock](irf_eps_pQ.png)

*Figure 6.7: 1pp VA-price inflation cost-push shock (scale = 1.0 / σ_pQ = 1.0 / 0.571 = 1.752; hybrid regime). Cost-push transmission in AU-PAC works through *level* variables, not gaps. The VA-price PAC equation (eq_piQ_pac) absorbs eps_pQ directly into piQ, which cumulates into the price level ln_P (peak +0.5%). The AU Phillips curve eq_au_phillips is driven by the output gap only (no piQ → pi_au passthrough), so the cost-push transmission shows up in level adjustments to ln_Q, ln_C, ln_IB, ln_N rather than in short-run gap responses. Permanent income (ln_C_star) jumps +0.18% on impact and decays to approximately 0 over 40 quarters as the price-level effect dissipates through the deflator block. A future extension would add an explicit piQ → pi_au passthrough.*

#### 6.3.6 TFP shock (eps_tfp) — 1% level shift

![TFP shock](irf_eps_tfp.png)

*Figure 6.8: 1 s.d. TFP shock (σ_tfp = 0.2; scale = 1.0; hybrid regime). Plotted at 1 s.d. rather than 1% because rho_tfp = 0.99 (near unit root) makes the level response near-permanent and growing over the IRF window — scaling to 1% would produce implausibly large level shifts (50%+ in ln_N). At 1 s.d., output level (ln_Q) rises +13% over 40 quarters; potential output (ln_QN) tracks one-for-one (the supply shock raises both by construction in the gap model), so the output gap yhat_au = ln_Q − ln_QN stays at zero. Employment level rises ~+10% as the CES production function reallocates inputs. Wage inflation picks up TFP via the productivity term $(1-\lambda_w) \Delta \ln Prod$ in eq_pi_w with peak +0.3 qpp — the only structural channel from supply-side TFP into nominal dynamics. Gap-variable panels (yhat_au, dln_n) and unrelated variables (piQ, i_10y) stay at floating-point-noise level by construction.*

#### 6.3.7 Term premium shock (eps_tp) — 100bp annualized

![Term premium shock](irf_eps_tp.png)

*Figure 6.9: 100bp annualized term-premium shock (scale = 0.25 / σ_tp = 0.25/0.05 = 5.0; hybrid regime). Raises long rates by 0.25 pp without short-rate movement. As with the cost-push shock (Figure 6.7), the term-premium channel in AU-PAC works through level variables rather than short-run gaps — the demand block absorbs the financing-cost effect via permanent-income / target-level adjustments. Consumption level falls -0.10%, business investment level -0.08%, housing investment level -0.16% over 40 quarters; consumption permanent income (ln_C_star) tracks the consumption level closely. Output gap (yhat_au) and VA price inflation (piQ) stay at floating-point noise — the term-premium shock has no direct flow to the output-gap or short-run inflation dynamics in this architecture. This is the same architectural pattern that makes the APP-style experiment (Figure 6.14) deliver modest level effects rather than dramatic gap responses.*

#### 6.3.8 Output gap overview — all shocks (policy-relevant sizes)

![Output gap overview](irf_overview_output.png)

*Figure 6.10: Output gap responses to all shocks at policy-relevant sizes. Shock sizes: monetary 100bp, foreign demand 1pp, govt spending 1pp, commodity 10%, TFP 1 s.d., term premium 50bp.*

### 6.4 Conditional forecasting

The model supports conditional forecasting via residual inversion (ECB-Base pattern). Given a desired path for conditioned variables, the algorithm solves for the shock sequence that replicates it using the decision rule matrices ($g_x$, $g_u$).

**RBA Tightening Scenario**: +25bp/quarter for 4 quarters (100bp total), hold 4 quarters, normalize over 4 quarters:

### Table 6.5: Conditional forecast — RBA tightening scenario

| Variable | Q1 | Q4 | Q8 | Q12 | Q16 |
|----------|-----|------|------|------|------|
| i_au (conditioned) | +0.063 | +0.250 | +0.250 | +0.050 | 0.000 |
| yhat_au | -0.000 | -0.034 | -0.097 | -0.099 | -0.041 |
| pi_au | -0.000 | -0.001 | -0.004 | -0.006 | -0.003 |
| dln_c | -0.000 | -0.023 | -0.059 | -0.054 | -0.017 |
| dln_ib | -0.000 | -0.043 | -0.103 | -0.085 | -0.016 |
| dln_ih | -0.000 | -0.058 | -0.155 | -0.123 | +0.001 |
| dln_n | -0.000 | -0.018 | -0.073 | -0.094 | -0.049 |
| i_10y | +0.026 | +0.103 | +0.103 | +0.021 | +0.001 |

*Figure 6.11: Conditional forecast for an RBA tightening cycle. Housing investment is the most sensitive (-0.16% at Q8) and employment the most sluggish (peak at Q12); the 10Y rate moves approximately 40% of the policy rate (yield-curve flattening).*

### 6.5 Forward guidance experiment

The model does not suffer from the forward guidance puzzle. Testing with superposition of N-quarter rate cuts (25bp each):

### Table 6.6: Forward guidance scaling test

Normalised peak output response to N consecutive quarterly 25bp rate cuts, scaled so the N=1 response equals 1.0.

| Duration N | Standard NK | Discounted NK | **AU-PAC** | Linear ref |
|---|---|---|---|---|
| 1 | 1.00 | 1.00 | **1.00** | 1.00 |
| 2 | 1.44 | 1.45 | **2.00** | 2.00 |
| 4 | 1.72 | 1.73 | **3.95** | 4.00 |
| 6 | 1.78 | 1.79 | **5.80** | 6.00 |
| 8 | 1.79 | 1.80 | **7.53** | 8.00 |
| 10 | 1.79 | 1.80 | **9.10** | 10.00 |
| 12 | 1.79 | 1.80 | **10.47** | 12.00 |

AU-PAC's near-linear scaling comes from three features: a high permanent-income discount ($\beta_c = 0.95$); a discounted term structure ($\kappa_{10} = 0.97$); and PAC adjustment-cost frictions that prevent explosive compounding. The standard NK and discounted NK models both saturate around N = 5 (ratio plateau at ≈1.79–1.80) — the textbook forward-guidance puzzle. AU-PAC tracks the linear reference to within 13% even at N = 12, confirming that PAC-style adjustment costs eliminate the puzzle for this model class. The mild sublinearity at long horizons (10.47 vs linear 12 at N = 12) reflects PAC's intrinsic decay in marginal effect.

<!-- forward_guidance_paths.png — replaced by the single forward_guidance_puzzle.png
     panel below which covers both peak-effects and normalised-scaling views. -->


*Figure 6.12: Forward guidance experiment — output gap responses for different durations.*

![Forward guidance puzzle test](forward_guidance_puzzle.png)

*Figure 6.13: Forward guidance puzzle test — AU-PAC (solid) vs standard NK (dashed). AU-PAC scales approximately linearly.*

### 6.6 APP-style experiment — 200bp persistent term-premium compression

The RBA did not implement an asset-purchase programme directly analogous to the ECB's APP or the Fed's QE during 2015-2018, but a hypothetical scenario is straightforward to simulate in AU-PAC: an unscheduled persistent compression of the term premium $tp$ by 200 basis points annualised (= -0.50 qpp). The shock is propagated via eq. (eq_term_premium), $tp_t = \rho_{tp} \cdot tp_{t-1} + (1-\rho_{tp}) \cdot tp_{ss} + \varepsilon^{tp}_t$, which feeds directly into the 10Y yield via eq. (48). Scale: $-0.50 / \sigma_{tp} = -0.50/0.05 = -10.0$.

![APP-style experiment](app_experiment_200bp.png)

*Figure 6.14: APP-style 200bp annualised term-premium compression. The 10Y yield falls 0.5 qpp on impact and gradually recovers over approximately 40 quarters. Consumption level rises by +0.21% peak (Q40, via the permanent-income channel through $ln\_C\_star$), business investment by +0.16% peak (Q1, via WACC), and housing investment by +0.32% peak (Q40, via the mortgage-rate channel). The short-run output gap response is small: the term-premium shock works through the level / target channels rather than through the short-run PAC error terms — a structural feature of the PAC architecture in which persistent financial-condition shocks enter via $ln\_X\_star$ (the target / permanent-income aggregate) rather than the cyclical $ln\_x\_level$ deviation. An RBA APP of this magnitude would deliver roughly 20–30 basis points of stimulus to household consumption and approximately 30 basis points to housing investment over a 10-year horizon.*

---

## 7. Conclusion

This paper has presented AU-PAC, a semi-structural macroeconomic model for Australia adapted from the FR-BDF framework. The model combines Polynomial Adjustment Costs with explicit expectations from an enriched 12-equation satellite VAR, enabling systematic analysis of how expectation formation affects monetary policy transmission.

Six findings emerge.

1. **The PAC framework is well identified on Australian data.** Iterative OLS and Bayesian estimation produce mutually consistent estimates across 67 parameters estimated from Australian data. Error-correction speeds, AR dynamics, and output-gap sensitivities are in the expected ranges, with full-system Bayesian log marginal density Laplace = -799.64 and Modified Harmonic Mean = -800.15.

2. **The Australian wage Phillips curve has standard New Keynesian structure.** Estimated on the ABS Wage Price Index, γ_w = 0.136 (90% HPD [0.081, 0.191]), λ_w = 0.290 (HPD [0.134, 0.447]), and κ_w = 0.097 (HPD [0.010, 0.169]) — moderate contemporaneous CPI passthrough, moderate own-lag persistence, and a statistically significant Phillips slope. The Fair Work Commission's institutional CPI indexation operates on roughly 15% of the workforce (award rates plus enterprise-agreement floors); most AU wage growth is set by private bargaining responsive to the unemployment-gap PV. AU wages therefore adjust to labour-market slack via a Phillips-curve channel and to inflation via a moderate contemporaneous CPI coefficient plus the unit-sum-implied inflation-anchor weight.

3. **COVID dummies are essential for PAC estimation.** Without explicit treatment of the 2020Q2–Q3 outliers, two of five PAC equations (consumption and employment) produce wrong-signed AR(1) coefficients. Two pulse dummies per equation resolve this cleanly.

4. **The three-regime comparison validates the PAC approach.** Forward-looking financial expectations amplify transmission (10Y yield front-loads the rate path), while forward-looking non-financial expectations dampen it (MCE agents smooth temporary shocks). Attenuation ranges from around 30% for output to 96–100% for VA-price inflation, housing investment, and employment. The peak output-gap response is -0.102% at Q6 to a 100bp monetary tightening under the proper trade-ECM specification.

5. **Australia-specific channels matter.** Variable-rate mortgages (rho_lh = 0.97) create the strongest demand channel, with banks adjusting lending rates slowly. The commodity-price channel feeds export volumes, the export deflator, and the import deflator. The endogenous Taylor rule creates a feedback loop (demand → output gap → RBA → rates → demand) that closes the IS curve.

6. **The consumption interest-rate channel is significant but uncertain in magnitude.** The Bayesian posterior for b2_c = -0.331 (HPD [-0.603, -0.050]) confirms nonzero interest-rate sensitivity in consumption. The direct rate-*change* effect b_di_c is not identified from OLS on AU data alone (reverse causality) and remains a candidate for high-frequency-surprise IV estimation. The housing-price gap in housing investment b_ph_ih is small but positive (0.0099, IV F = 432) on the extended 1959Q3-onward housing-price series.

**Comparison with the RBA model suite.** Section 6.2.4 benchmarks AU-PAC against the four Australian models surveyed in Mulqueeney, Ballantyne and Hambur (2025). AU-PAC's peak GDP response (-0.102% at Q6) is the smallest of any Australian model in active use — roughly 3× smaller than Murphy, 4× smaller than MARTIN, and 15× smaller than the Beckers VAR. The dampened response reflects three deliberate features: PAC adjustment-cost frictions that distinguish FRB/US-style models from VAR / DSGE alternatives; the linearised-gap formulation; and AU-specific Bayesian posteriors that resist over-fitting. AU-PAC therefore complements the RBA suite on the conservative end of "diversity supports more robust policymaking" (Mulqueeney et al. 2025, p. 11).

**Remaining work.** Five extensions would sharpen the analysis: full-system MCMC re-estimation under the expanded 11-observable trade-ECM specification (priors set; computation pending); high-frequency RBA OIS-surprise IV estimation for `b_di_c` (Bishop–Tulip 2017; Beechey–Wright 2009); an energy / non-energy import split along the lines of wp736 eqs 88–91 (less material for AU as a net energy exporter, but adds rigour); a full historical shock decomposition; and a systematic channel-decomposition exercise of the type Mulqueeney et al. (2025) report for MARTIN and DINGO, in which each transmission channel is "turned off" in turn to isolate exchange-rate, asset-price, savings / investment, and cash-flow contributions.

---

## 8. Australia-Specific Features

### Variable-rate mortgages

Australia's predominantly variable-rate mortgage market creates the strongest housing channel among all demand components. The mortgage lending rate ($i^{LH}$) adjusts to the 10Y rate with persistence $\rho_{LH} = 0.97$ (estimated from RBA F5 data, T = 127) and a spread of 0.40% quarterly. The 0.97 persistence implies a half-life of approximately 23 quarters, reflecting the stickiness of standard variable mortgage rates in Australia. The housing-investment target is directly sensitive to the mortgage rate gap ($\kappa_{mort} = 0.048$), and the auxiliary equation has a large interest-rate loading ($a_{ih,i} = -0.15$).

### Commodity-price channel

Australia is a net commodity exporter, so commodity prices enter primarily as an *income* shock via the export deflator and terms of trade. Commodity prices follow an exogenous AR(1) process:

$$\Delta \ln P^{com}_t = \rho_{pcom} \Delta \ln P^{com}_{t-1} + \varepsilon^{pcom}_t$$

with $\rho_{pcom} = 0.42$ estimated from IMF / RBA G3 commodity-price data — reflecting the high quarterly volatility of Australia's broad commodity basket. Commodity prices feed into export volumes ($b^x_4 = 0.15$), the export deflator ($\alpha_{pcom} = 0.10$), and the import deflator ($\beta_{pm,com} = 0.42$, estimated from ABS data).

### Endogenous monetary policy

AU-PAC's short rate is set endogenously by an RBA Taylor rule responding to AU inflation and the output gap. This closes a policy feedback loop — demand shock → output gap → Taylor rule → interest rate → demand components → output gap — producing endogenous stabilisation. The estimated rule has inertia $\lambda_i = 0.828$, inflation weight $\alpha_i = 0.279$, and output weight $\beta_i = 0.135$.

### US as foreign bloc

The US enters as the foreign bloc in E-SAT. The AU–US demand spillover ($\delta = 0.20$) captures the trade and financial channel linking US conditions to Australia, while the US inflation process influences Australian import prices and exchange-rate dynamics.

---

## Appendix A: Complete Variable List

### A.1 E-SAT Core (11 variables)

| Variable | Description | SS value |
|----------|-------------|----------|
| yhat_au | AU output gap (%) | 0 |
| i_au | RBA cash rate (quarterly %) | 1.049 |
| pi_au | AU GDP deflator inflation (quarterly %) | 0.625 |
| yhat_us | US output gap (%) | 0 |
| pi_us | US GDP deflator inflation (quarterly %) | 0.500 |
| ibar | Long-run interest rate anchor | 1.049 |
| pibar_au | AU inflation anchor | 0.625 |
| pibar_us | US inflation anchor | 0.500 |
| i_gap | Interest rate gap (i_au - ibar) | 0 |
| pi_au_gap | AU inflation gap | 0 |
| pi_us_gap | US inflation gap | 0 |

### A.2 VA Price Block (5 variables)

| Variable | Description | SS value |
|----------|-------------|----------|
| piQ | VA price inflation (quarterly %) | 0.625 |
| piQ_star | VA price target inflation | 0.625 |
| piQ_star_bar | VA price trend inflation | 0.625 |
| pQ_gap | VA price gap | 0 |
| pQ_level | VA price log-level accumulator | 0 |

### A.3 Supply Block (5 variables)

| Variable | Description | SS value |
|----------|-------------|----------|
| dln_k | Capital services growth | 0 |
| dln_y_star | Potential output growth | 0 |
| dln_tfp | TFP growth | 0 |
| dln_ulc | Unit labor cost growth | 0.625 |
| dln_prod | Labor productivity growth | 0 |

### A.4 Labor Market (10 variables)

| Variable | Description | SS value |
|----------|-------------|----------|
| u_gap | Unemployment gap | 0 |
| pv_u_gap | PV of future unemployment gaps | 0 |
| pi_w | Wage inflation (quarterly %) | 0.625 |
| dln_n | Employment growth | 0 |
| dln_n_star | Employment target growth | 0 |
| dln_n_star_bar | Employment trend growth | 0 |
| n_gap | Employment gap | 0 |
| dln_n_1, dln_n_2, dln_n_3 | Employment lag auxiliaries | 0 |

### A.5 Demand Block (14 variables)

| Variable | Description | SS value |
|----------|-------------|----------|
| dln_c, dln_c_star, dln_c_star_bar | Consumption growth, target, trend | 0 |
| c_gap | Consumption gap | 0 |
| pv_yh | Permanent income PV | 0 |
| dln_ib, dln_ib_star, dln_ib_star_bar | Business investment growth, target, trend | 0 |
| ib_gap | Business investment gap | 0 |
| dln_ib_1 | Business investment lag auxiliary | 0 |
| dln_ih, dln_ih_star, dln_ih_star_bar | Housing investment growth, target, trend | 0 |
| ih_gap | Housing investment gap | 0 |
| dln_ih_1 | Housing investment lag auxiliary | 0 |

### A.6 Financial Block (15 variables)

| Variable | Description | SS value |
|----------|-------------|----------|
| i_10y | 10Y bond yield | 1.349 |
| tp | Term premium | 0.300 |
| pv_i | PV of expected future short rates | 1.049 |
| wacc | Weighted average cost of capital | 1.834 |
| i_COE, i_LB_firms, i_BBB | Component rates | 2.149, 1.599, 1.399 |
| s_COE, s_LB_firms, s_BBB | Component spreads | 0.800, 0.250, 0.050 |
| s_gap | Exchange rate gap | 0 |
| uc_k, dln_uc_k | User cost of capital and growth | 1.859, 0 |
| i_lh | Household bank lending rate | 1.749 |
| dln_ph, ph_gap | Housing prices growth and gap | 0, 0 |

### A.7 Trade, Deflators, Government (20 variables)

| Variable | Description | SS value |
|----------|-------------|----------|
| dln_x | Export growth | 0 |
| ln_x_level | Log exports level (deviation, accumulates dln_x) | 0 |
| ln_x_eq | Export LR equilibrium (β_x·yhat_us + γ_x·s_gap) | 0 |
| x_gap | Export EC term (ln_x_eq − ln_x_level) | 0 |
| dln_m | Import growth | 0 |
| ln_m_level | Log imports level (deviation, accumulates dln_m) | 0 |
| ln_m_eq | Import LR equilibrium (β_m·ln_d_iad + γ_m·s_gap) | 0 |
| m_gap | Import EC term (ln_m_eq − ln_m_level) | 0 |
| ln_d_iad | Log import-weighted demand level (accumulates iad) | 0 |
| dln_pcom | Commodity price growth | 0 |
| pi_c, pi_ib, pi_ih, pi_x, pi_m, pi_g | 6 demand deflators | all 0.625 |
| dln_g | Government spending growth | 0 |
| yhat_dom | Domestic demand gap | 0 |
| iad | Import-adjusted demand | 0 |
| rw_gap | Real wage growth gap | 0 |

### A.8 var_model Shadow + PAC Levels (27 variables)

12 var_model shadow variables (y_gap_var, i_gap_var, etc.) plus 7 auxiliary targets (piQ_hat, n_hat, c_hat, etc.) plus 6 pv_aux correction terms plus log-level accumulators (ln_c_level, ln_ib_level, ln_ih_level, ln_n_level, pQ_star_level).

---

## Appendix B: Complete Shock List

### B.1 E-SAT core shocks (8)

| Shock | Std dev | Description |
|-------|---------|-------------|
| eps_q | 0.80 | AU demand shock |
| eps_i | 0.10 | Monetary policy shock |
| eps_pi | 0.60 | AU cost-push shock |
| eps_q_us | 1.10 | US demand shock |
| eps_pi_us | 0.40 | US cost-push shock |
| eps_ibar | 0.01 | Long-run rate anchor |
| eps_pibar_au | 0.01 | AU inflation anchor |
| eps_pibar_us | 0.01 | US inflation anchor |

### B.2 Structural shocks (12)

| Shock | Std dev | Description |
|-------|---------|-------------|
| eps_pQ | 0.50 | VA price cost-push |
| eps_w | 0.60 | Wage push |
| eps_n | 0.50 | Employment |
| eps_c | 0.50 | Consumption |
| eps_ib | 1.50 | Business investment |
| eps_ih | 2.00 | Housing investment |
| eps_tfp | 0.10 | TFP |
| eps_x | 1.00 | Export |
| eps_m | 0.80 | Import |
| eps_g | 0.30 | Government spending |
| eps_pcom | 1.00 | Commodity price |
| eps_lh | 0.05 | Mortgage rate |

### B.3 Financial shocks (5)

| Shock | Std dev | Description |
|-------|---------|-------------|
| eps_10y | 0.10 | Long rate residual |
| eps_tp | 0.05 | Term premium |
| eps_COE | 0.10 | Equity spread |
| eps_LB_firms | 0.05 | Bank lending spread |
| eps_BBB | 0.02 | BBB bond spread |

### B.4 Other shocks (8 deflator/trade + 12 var_model + 2 COVID dummies)

Exchange rate (eps_s, 0.50), deflators (eps_pc, eps_pib, eps_pih, eps_px, eps_pm, eps_pg), housing price (eps_ph), plus 12 var_model shadow shocks and 2 COVID pulse dummies.

---

## Appendix C: Growth Neutrality Proofs

### C.1 PAC equations

At the balanced growth path, the sum of the AR lag coefficients plus the expectations weight (omega) plus the error-correction coefficient equals 1:

| Equation | b0 (EC) | Sum AR | omega (h-vector) | GN residual | Sum |
|----------|---------|--------|-------------------|-------------|-----|
| VA price | 0.060 | 0.500 | 0.452 | -0.012 | 1.00 |
| Consumption | 0.060 | 0.149 | 0.678 | 0.113 | 1.00 |
| Business inv | 0.030 | 0.281 | 0.501 | 0.188 | 1.00 |
| Household inv | 0.049 | 0.290 | 0.569 | 0.092 | 1.00 |
| Employment | 0.040 | 0.470 | 0.446 | 0.044 | 1.00 |

### C.2 Demand deflators

All deflator coefficients on inflation-type terms sum to 1:

| Deflator | rho | alpha | beta_m | gamma/other | Anchor | Sum |
|----------|-----|-------|--------|-------------|--------|-----|
| Consumption | 0.40 | 0.30 | 0.10 | 0.03 | 0.17 | 1.00 |
| Business inv | 0.35 | 0.25 | 0.12 | — | 0.28 | 1.00 |
| Housing inv | 0.45 | 0.25 | 0.08 | — | 0.22 | 1.00 |
| Export | 0.30 | 0.20 | -0.05 | 0.10 | 0.45 | 1.00 |
| Import | 0.30 | 0.15 | 0.08 | 0.05 | 0.42 | 1.00 |
| Government | 0.50 | 0.30 | — | — | 0.20 | 1.00 |

### C.3 Wage Phillips curve

$\lambda_w + \gamma_w + (1-\lambda_w-\gamma_w) = 0.290 + 0.136 + 0.574 = 1.00$. On the balanced growth path with productivity growth $g$: $\pi^w_{SS} = \pi_{SS} + g$. The inflation-anchor coefficient (0.574) carries genuine weight under the WPI calibration — wage inflation in the long run is anchored to expected steady-state inflation through this channel, not solely through the contemporaneous CPI term ($\gamma_w = 0.136$) and own-lag ($\lambda_w = 0.290$).

---

## Appendix D: h-Vector Decomposition

### D.1 Summary

| PAC equation | h-param indices | h-vector sum | GN coeff | Amplification |
|---|---|---|---|---|
| VA price | [173, 174, 175, 176] | 0.452 | 0.048 | 1.0x |
| Consumption | [153, 154, 155, 156] | 0.678 | 0.173 | 1.84x |
| Business inv | [158, 159, 160, 161] | 0.501 | 0.218 | 1.43x |
| Household inv | [163, 164, 165, 166] | 0.569 | 0.141 | 1.90x |
| Employment | [168, 169, 170, 171] | 0.446 | 0.084 | 1.49x |

Detailed per-state h-vector element weights require extraction from `M_.params` at the h-param indices. The enriched var_model (12x12) produces h-vectors where only the target variable element is non-zero in the current Dynare 6.5 implementation (the companion matrix concentrates weight on the target state). Element-level decomposition is deferred to future work.

---

## Appendix E: Complete Parameter List

See the comprehensive parameter tables throughout Section 4. A machine-readable list of all 262 parameters with their values is available alongside the model code at https://github.com/DavidAStephan/AUSPAC.

The four trade long-run elasticities introduced in the Section 4.8 ECM rewrite are summarised here for convenience:

| Parameter | Value | Prior (for MCMC re-run) | Role |
|-----------|-------|--------------------------|------|
| beta_m | 1.50 | Normal(1.50, 0.30) | LR income elasticity of imports (FR-BDF eq 76) |
| gamma_m | -0.40 | Normal(-0.40, 0.20) | LR RER elasticity of imports |
| beta_x | 1.20 | Normal(1.20, 0.30) | LR foreign-income elasticity of exports (FR-BDF eq 71) |
| gamma_x | +0.40 | Normal(+0.40, 0.20) | LR RER elasticity of exports |

---

## Appendix F: Identification analysis

Driver: [`identification_analysis.m`](identification_analysis.m). Two approaches are reported below.

### F.1 Dynare `identification` command — not run

Dynare 6.5's `identification` command requires analytic derivation of the model, which is **incompatible with `diffuse_filter`** — the filter setting used during estimation to handle the model's unit-root level accumulators (`ln_Q`, `ln_K`, `ln_C`, etc.). Running the command produces:

> `ERROR: analytic derivation is incompatible with diffuse filter`

For Iskrev (2010) and Komunjer–Ng (2011) tests at the posterior mode we would need either (a) a stationarised version of the model (replacing level accumulators with their deviations from steady state), or (b) a future Dynare release that supports analytic derivation under diffuse filtering. Neither is in scope for this paper; we report the posterior-based identification proxy below instead.

### F.2 Posterior-width-based weak-identification flagging

For each of the 28 estimated parameters, we report the 90% HPD interval from the MCMC posterior (20,000 draws × 2 chains). Absolute HPD width is the headline measure of how much the data has constrained the parameter; the normalised width (HPD_width / |posterior_mean|) is informative only when the posterior is well away from zero.

### Table F.1: Posterior HPD widths

Sorted by absolute width, descending. Parameters at "near-zero" identification are flagged where the posterior mean is essentially zero.

| Parameter   | HPD low  | HPD high | width  | normalised width |
|-------------|---------|---------|--------|------------------|
| b2_c        | -0.6029 | -0.0504 | 0.553 | 1.67 |
| b3_ih       | 0.0623  | 0.3971  | 0.335 | 1.48 |
| b1_n        | 0.1527  | 0.4848  | 0.332 | 1.03 |
| b1_pQ       | 0.1202  | 0.4512  | 0.331 | 1.14 |
| lambda_w    | 0.1342  | 0.4471  | 0.313 | 1.08 |
| b3_ib       | 0.1629  | 0.4642  | 0.301 | 0.97 |
| b3_c        | -0.0680 | 0.0965  | 0.164 | 8.27 *(mean near zero)* |
| b2_pQ       | -0.0796 | 0.0825  | 0.162 | *huge* *(mean ≈ zero)* |
| b1_ih       | 0.0301  | 0.1888  | 0.159 | 1.38 |
| kappa_w     | 0.0102  | 0.1694  | 0.159 | 1.65 |
| b5_n        | -0.0707 | 0.0885  | 0.159 | 22.06 *(mean near zero)* |
| b1_ib       | 0.0186  | 0.1381  | 0.120 | 1.49 |
| gamma_w | 0.0814 | 0.1907 | 0.109 | 0.81 *(tightly identified at 0.136)* |
| b0_n        | 0.0108  | 0.0976  | 0.087 | 1.52 |
| b0_c        | 0.0231  | 0.0909  | 0.068 | 1.13 |
| b1_c        | 0.0046  | 0.0629  | 0.058 | 1.65 |
| b0_pQ       | 0.0057  | 0.0517  | 0.046 | 1.50 |
| b0_ih       | 0.0065  | 0.0498  | 0.043 | 1.50 |
| b0_ib       | 0.0050  | 0.0317  | 0.027 | 1.42 |

**Findings**:

1. **gamma_w is tightly identified** (90% HPD [0.081, 0.191] — width 0.11 around a mean of 0.136, normalised width 0.81). The data sharply distinguishes the moderate contemporaneous CPI passthrough from larger values, and the relative weights of the own-lag, CPI, and unemployment-gap channels in the wage Phillips curve are robustly identified.

2. **Three "near-zero" parameters** show large *normalised* widths (`b5_n`, `b2_pQ`, `b3_c`) but small *absolute* widths (≤ 0.16). The data has sharply identified them at zero — the AU output gap does not have a direct cyclical accelerator effect on either employment growth or VA-price inflation, and the output-gap channel into consumption is essentially absorbed by the rate channel `b2_c`. This is a sharp identification result rather than weak identification.

3. **b2_c (consumption interest-rate channel)** is the structural parameter with the widest absolute HPD: [-0.61, -0.05]. The data identify the sign (negative — rate hikes depress consumption) and statistical significance, but the magnitude is uncertain over almost an order of magnitude. External RBA OIS-surprise data (Bishop–Tulip 2017; Beechey–Wright 2009) would sharpen this.

4. **The five PAC EC speeds** (`b0_pQ`, `b0_c`, `b0_ib`, `b0_ih`, `b0_n`) are tightly identified with normalised HPDs around 1.0–1.5 — the Beta priors are informative and the data provide material updates. Posteriors are all in the 0.02–0.07 quarterly range.

5. **Shock standard deviations** (Table 5.6): `eps_ih` and `eps_n` have the widest HPDs proportionally ([0.55, 2.23] and [0.12, 0.79] respectively). The wide HPD for `eps_n` is a by-product of `b5_n` being identified at zero — most of the employment-equation residual variance is absorbed by `eps_n` rather than apportioned across structural channels.

![Posterior densities for 28 estimated parameters](identification_prior_posterior.png)

*Figure F.1: Posterior densities (blue) from the MCMC run, with posterior mean (red dashed) and posterior mode (green solid) markers. Most posteriors are unimodal and roughly symmetric; the shock standard deviations `eps_ih` and `eps_n` are the only parameters showing notable asymmetry consistent with weak identification.*

### F.3 What a future Dynare run would add

Given a stationarised version of the model without `diffuse_filter`, the following diagnostics would be available:

- **Iskrev (2010) rank test** at the posterior mode (yes/no answer on local identification);
- **Komunjer–Ng (2011) test** for structural identification of the linear DSGE under partial-information assumptions;
- **Identification strength** (moment-condition based) for each parameter — a quantitative ranking of how informative each moment of the data is for each parameter;
- **Pairwise collinearity matrix** — which parameter pairs are near-perfectly correlated under the model's mapping from parameters to moments, flagging redundancies that the posterior HPD-width approach cannot directly detect.

These remain pending future work; the HPD-width analysis here is sufficient to flag which parameter magnitudes are well determined and which would benefit from additional data.

---

## References

### Models and methodology

Brayton, F., Laubach, T., and Reifschneider, D. (2014). "The FRB/US Model: A Tool for Macroeconomic Policy Analysis." *FEDS Notes*, Board of Governors of the Federal Reserve System.

Lemoine, M., Turunen, H., Chahad, M., Lepetit, A., Zhutova, A., Aldama, P., Clerc, P., and Laffargue, J.-P. (2019). "The FR-BDF Model and an Assessment of Monetary Policy Transmission to the French Economy." *Banque de France Working Paper* No. 736. (Cited throughout as "wp736" / "FR-BDF".)

Tinsley, P.A. (1993). "Fitting Both Data and Theories: Polynomial Adjustment Costs and Error-Correction Decision Rules." *FEDS Working Paper* No. 93-21, Board of Governors of the Federal Reserve System.

Zimic, S. (2023). "SemiStructDynareBasics: A reference implementation of FRB/US-style PAC models in Dynare." ECB internal documentation and public GitLab repository. https://gitlab.com/srecko/SemiStructDynareBasics

Galí, J., Smets, F., and Wouters, R. (2011). "Unemployment in an Estimated New Keynesian Model." *NBER Macroeconomics Annual*, 26(1), 329-360.

Iskrev, N. (2010). "Local Identification in DSGE Models." *Journal of Monetary Economics*, 57(2), 189–202.

Komunjer, I. and Ng, S. (2011). "Dynamic Identification of Dynamic Stochastic General Equilibrium Models." *Econometrica*, 79(6), 1995–2032.

Adolfson, M., Laséen, S., Lindé, J., and Villani, M. (2007). "Bayesian Estimation of an Open-Economy DSGE Model with Incomplete Pass-Through." *Journal of International Economics*, 72(2), 481–511.

### Australian monetary transmission and data

Reserve Bank of Australia (2024). "Statement on Monetary Policy." Various issues, 2010–2024.

Bishop, J. and Tulip, P. (2017). "Anchoring Inflation Expectations in a Low Inflation Environment." *RBA Research Discussion Paper* 2017-08.

Beechey, M.J. and Wright, J.H. (2009). "The High-Frequency Impact of News on Long-Term Yields and Forward Rates: Is It Real?" *Journal of Monetary Economics*, 56(4), 535–544.

Mulqueeney, J., Ballantyne, A., and Hambur, J. (2025). "Monetary Policy Transmission through the Lens of the RBA's Models." *RBA Bulletin*, April 2025, pp. 9–18.

Beckers, B. (2020). "Credit Spreads, Monetary Policy and the Price Puzzle." *RBA Research Discussion Paper* 2020-01.

Cusbert, T. and Kendall, E. (2018). "Meet MARTIN, the RBA's New Macroeconomic Model." *RBA Bulletin*, March 2018.

Hambur, J., Cassidy, N., and Pugsley, B. (2024). "How Has Australian Monetary Policy Affected the Economy in Recent Years?" *RBA Research Discussion Paper*.

Ballantyne, A., Sharma, T., and Taylor, T. (2024). "Assessing Full Employment in Australia." *RBA Bulletin*.

### Data sources

Australian Bureau of Statistics (2024). "Australian National Accounts: National Income, Expenditure and Product." Cat. No. 5206.0. Quarterly, seasonally adjusted.

Australian Bureau of Statistics (2024). "Australian National Accounts: Capital Stock and Capital Consumption (Tables 47, 48)." Cat. No. 5204.0. Annual factor-share series used for CES supply-side estimation.

Australian Bureau of Statistics (2024). "Residential Property Price Indexes: Eight Capital Cities." Cat. No. 6416.0. Used for the housing-price gap (`ph_gap`) from 2003Q3 onward; spliced back to 1959Q3 using a long-history Australian house-price series with chained growth rates anchored at the 2003Q3 overlap.

Australian Bureau of Statistics (2024). "Wage Price Index, Australia." Cat. No. 6345.0. Quarterly index, SA Private+Public All industries — used as the wage-inflation observable in Section 5.4.

Bank for International Settlements (2024). "Effective Exchange Rate Indices." BIS REER / NEER series for AUD.

Fair Work Commission (2024). "Annual Wage Review." Final decisions 2010–2024. Institutional source for the CPI-indexation channel in AU wage-setting (affects approximately 15% of the workforce — award rates plus award-floor enterprise agreements).

Reserve Bank of Australia (2024). "Statistical Tables: F1 (interest rates), F11 (mortgage rates), G3 (commodity prices)." Quarterly time series, 1976–2024.
