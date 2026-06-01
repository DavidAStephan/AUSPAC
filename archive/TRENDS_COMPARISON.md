# Trend Treatment in PAC Equations: FR-BDF vs AUSPAC Options α / β / β-W

**Author:** AUSPAC project
**Date:** 2026-05-24
**Sources:**
- Lemoine et al. (2019), *The FR-BDF Model and an Assessment of Monetary Policy Transmission in France*, Banque de France WP #736 (henceforth wp736)
- Dubois et al. (2026), *Re-estimated FR-BDF: New Features and an Assessment of Monetary Policy Tightening in France*, Banque de France WP #1044 (henceforth wp1044)
- AUSPAC working paper §4.11.3–§4.11.6 and source files in `dynare/`

---

## 1. The problem

Macroeconomic data have trends. Consumption growth in AU averages 0.77% per quarter; in France it averages something similar; both are positive and non-zero. A semi-structural model has to reconcile that observable mean with its predicted mean. There are two philosophies:

1. **Trend in data** — subtract the trend from data before estimation (TVD, HP-filter, structural demeaning). The model then works with zero-mean variables.
2. **Trend in model** — feed raw data; the model produces predictions with the correct non-zero mean via explicit drift terms.

Both FR-BDF and AUSPAC choose path (2), but they implement it very differently. This document derives both approaches from first principles to make the comparison precise.

---

## 2. FR-BDF's approach — the canonical PAC growth-neutrality construction

### 2.1 The PAC cost function and error-correction equation

(wp736 §3.2.1, Eq 2–5)

Agents minimise a polynomial cost function in deviations of the choice variable $y_t$ from its long-run target $y^*_t$:

$$
C_t = \sum_{i=0}^{\infty} \beta^i \left[ (y_{t+i} - y^*_{t+i})^2 - \sum_{k=1}^m b_k \left((1-L)^k y_{t+i}\right)^2 \right]
\tag{wp736 Eq 2}
$$

where $\beta$ is the discount factor (calibrated 0.98 in most blocks; 0.95 in consumption per wp736 §4.6.1) and $b_k$ are adjustment cost parameters. The first-order condition with respect to $y_t$ yields the canonical PAC decision rule (wp736 Eq 5):

$$
\boxed{\;\Delta y_t = a_0(y^*_{t-1} - y_{t-1}) + \sum_{k=1}^{m-1} a_k \Delta y_{t-k} + \sum_{i=0}^{\infty} d_i \, \Delta y^*_{t+i}\;}
\tag{wp736 Eq 5}
$$

This says: today's growth has three components — error correction toward the long-run target, lagged dynamics, and the discounted sum of expected future changes in the target.

### 2.2 The growth-neutrality constraint

(wp736 §3.2.2, Eq 8–9)

At a balanced growth path (BGP), $\Delta y_t = \Delta y^*_t = g$ and $y_{t-1} = y^*_{t-1}$. Substituting into Eq 5:

$$
0 = \left[1 - \sum_{k=1}^{m-1} a_k - \sum_{i=0}^{\infty} d_i\right] g
$$

For the model to be growth-neutral (i.e., the ECM term vanishes at BGP for any growth rate $g$), the coefficients must satisfy:

$$
\sum_{k=1}^{m-1} a_k + \sum_{i=0}^{\infty} d_i = 1
$$

In practice FR-BDF doesn't impose this constraint by re-parameterisation. Instead it adds an explicit "growth-neutrality correction" term to Eq 5:

$$
\boxed{\;\Delta y_t = a_0(y^*_{t-1} - y_{t-1}) + \sum_{k=1}^{m-1} a_k \Delta y_{t-k} + \sum_{i=0}^{\infty} d_i \, \Delta y^*_{t+i} + \underbrace{\left[1 - \sum_{k=1}^{m-1} a_k - \sum_{i=0}^{\infty} d_i\right] g}_{\text{growth-neutrality correction}}\;}
\tag{wp736 Eq 9}
$$

When the coefficients happen to sum to 1, the correction term vanishes. When they don't, the term provides the additive drift needed to align the model's BGP with the data's mean growth rate. **The growth rate $g$ is exogenous to this equation** — it has to be supplied from elsewhere.

### 2.3 Target decomposition into stationary and non-stationary components

(wp736 §3.3.1, Eq 10–13)

FR-BDF decomposes the target into two parts:

$$
y^*_t = \hat{y}^*_t + \bar{y}^*_t
\qquad \text{(stationary) + (non-stationary trend)}
$$

Footnote 19 of wp736 states explicitly: **"These components are computed with a trend-cycle decomposition, e.g. an HP filter."**

Plugging into the PAC equation:

$$
\Delta y_t = a_0(y^*_{t-1} - y_{t-1}) + \sum_{k=1}^{m-1} a_k \Delta y_{t-k} + \text{PV}(\Delta \hat{y}^*)_t + \text{PV}(\Delta \bar{y}^*)_t
\tag{wp736 Eq 11}
$$

where
$$
\text{PV}(\Delta \hat{y}^*)_t = \sum_{i=0}^{\infty} d_i \Delta \hat{y}^*_{t+i}, \qquad
\text{PV}(\Delta \bar{y}^*)_t = \sum_{i=0}^{\infty} d_i \Delta \bar{y}^*_{t+i}
\tag{wp736 Eq 12-13}
$$

The stationary component's PV is computed using the E-SAT VAR (wp736 §3.3, Eq 16). The **non-stationary component's PV is computed using a separate, calibrated unit-root process** for $\Delta \bar{y}^*$ — wp736 Eq 58 for employment:

$$
\text{PV}(\Delta \bar{n}^*_S)_{t|t-1} = \omega \, \Delta \bar{n}^*_{S,t-1}
\tag{wp736 Eq 58}
$$

The coefficient $\omega$ on the lagged trend growth is what enters PAC equations.

### 2.4 The trend is **estimated separately** — the trend efficiency equation

(wp1044 §3.1.1, Eq 7)

This is the key piece I missed initially. FR-BDF doesn't impose ad-hoc constant trends or step functions. They **estimate a stochastic-trend equation for $\bar{E}_t$** (trend labour efficiency) using OLS *before* estimating PAC equations:

$$
\log(\bar{E}_t) = z_1 \log(\bar{E}_{t-1}) + (1-z_1)\bigl(z_2 + z_3 \delta_{08Q3-} - 0.059 \, \delta_{20Q2-21Q4}\bigr)
$$
$$
+ z_4 (T_{1,t} - z_1 T_{1,t-1}) + z_5 (T_{2,t} - z_1 T_{2,t-1}) + z_6 (T_{3,t} - z_1 T_{3,t-1})
$$
$$
+ z_7 \Bigl(\log\tfrac{TUC_t}{\overline{TUC}} - z_1 \log\tfrac{TUC_{t-1}}{\overline{TUC}}\Bigr)
+ z_8 (\delta_{COVID,20q1} + \delta_{COVID,20q3}) + z_9 \delta_{COVID,20q2} + \varepsilon_t
\tag{wp1044 Eq 7}
$$

Components:
- $z_1 \approx 0.56$ — AR(1) persistence of the trend
- $T_{1,t}, T_{2,t}, T_{3,t}$ — **three deterministic time trends** starting 1990Q1, 2002Q2, 2008Q3 (slope-break design)
- $z_3 \delta_{08Q3-}$ — level shift after 2008Q3 (GFC permanent loss)
- $-0.059 \, \delta_{20Q2-21Q4}$ — level shift over the COVID period
- $z_7 \cdot \log(TUC/\overline{TUC})$ — cyclical correction via capacity utilisation
- $z_8, z_9 \delta_{COVID}$ — COVID dummies for 2020Q1-Q3 outliers
- $\varepsilon_t$ — stochastic residual

The implied annual trend growth rates: **2.4% before 2002Q2, 1.4% between 2002Q2-2008Q3, 0.7% after 2008Q3**.

The full trend output $\bar{y}_t$ is then constructed from $\bar{E}_t$ via the long-run output equation derived from the CES production function (wp1044 §3.1.3, not reproduced here).

### 2.5 The full FR-BDF consumption equation in practice

(wp1044 §3.5.1, Eq 33–35)

The long-run target:
$$
c^*_t = \alpha_0 + \text{PV}(y_H)_{t|t-1} + \alpha_1 (r_{LH,t} - (\bar{i}_t - \bar{\pi}_t))
\tag{wp1044 Eq 33}
$$

Permanent income decomposition (this is the trend-cycle split of the target):
$$
\text{PV}(y_H)_{t|t-1} = \text{PV}(y_H - \bar{y})_{t|t-1} + \bar{y}_t
\tag{wp1044 Eq 34}
$$

Short-run PAC equation:
$$
\Delta c_t = \beta_0 (c^*_{t-1} - c_{t-1}) + \beta_1 \Delta c_{t-1}
+ \text{PV}^2(y_H - \bar{y})_{t|t-1}
+ \alpha_1 \bigl(\text{PV}(r_{LH})_{t|t-1} - (\text{PV}(\bar{i})_{t|t-1} - \text{PV}(\bar{\pi})_{t|t-1})\bigr)
$$
$$
\boxed{+ \beta_{\text{PAC}} \Delta \bar{y}_{t-1}}
+ \beta_2 \bigl[\Delta(\log(W_{H,t} + TG_{H,t}) - p^{\text{VAT}}_{C,t}) - \tilde{y}_t\bigr]
+ \beta_3 (\Delta r_{LH,t} - (\Delta \bar{i}_t - \Delta \bar{\pi}_t))
+ \beta_4 \delta_{\text{COVID}}
\tag{wp1044 Eq 35}
$$

The boxed term `+ β_PAC · Δȳ_{t-1}` is the growth-neutrality correction (from Eq 9 with $g \to \Delta \bar{y}_{t-1}$). $\bar{y}_t$ is the **HP-filtered trend of GDP**, time-varying. $\tilde{y}_t$ is a *second*, distinct HP trend (specifically the HP-trend of output growth, used in the hand-to-mouth channel).

$\beta_{\text{PAC}}$ is **estimated** rather than imposed (wp1044 estimates it implicitly via the polynomial coefficients). Note: in the 2019 version (wp736 Eq 61) the coefficient was the constrained $(1 - \beta_1)$; in the 2026 version they let it be a free parameter $\beta_{\text{PAC}}$, "somewhat modified as the non-stationary component of expectations is zero for expectations of gap terms" (wp1044 p. 43).

### 2.6 Estimation pipeline

(wp1044 §2.2, wp736 §4.1)

FR-BDF estimates block-by-block, NOT jointly:

1. **Supply block first** (calibrate CES; estimate $\bar{E}_t$ via Eq 7 OLS; derive $\bar{y}_t$).
2. **E-SAT (VAR) second** (Bayesian estimation of a small 8-equation VAR; gives the $d_i$ coefficients for PV computation).
3. **PAC short-run equations third** (iterative OLS: given an initial guess of PAC coefficients, compute PV's from E-SAT, run OLS on PAC equation, iterate to convergence).

Crucially, the trend $\bar{y}_t$ in step 3 is **a pre-computed time series, fixed from step 1**. It enters as a known regressor, not as a state variable being estimated jointly. This is why FR-BDF doesn't have AUSPAC's "how do we get the trend into Dynare's Kalman filter?" problem — they don't use a Kalman filter for PAC estimation at all.

---

## 3. AUSPAC's approach — Bayesian estimation requires different plumbing

### 3.1 Architectural constraint: AUSPAC uses full-information Bayesian estimation

AUSPAC differs from FR-BDF in one fundamental way that drives all the trend-handling decisions: **AUSPAC estimates the entire model jointly via Dynare's Bayesian MCMC with diffuse Kalman filter**, not block-by-block via OLS. This was the Phase T decision (2026-05-16, AUSPAC working paper §4.3): we adopt the "official" Dynare semi-structural workflow (Adjemian; matches FR-BDF wp1044 §3.2.3 architecturally for the policy-function PAC expectations) rather than the iterative-OLS pipeline.

The consequence: trends cannot enter as "pre-computed time series passed as regressors" because Dynare's `estimation` block doesn't read arbitrary exogenous time series for use in model equations. Trends must enter either as:
- **Parameters** (constant, calibrated or estimated)
- **Endogenous variables** (with model equations governing their evolution)
- **Observables** (with `varobs` and Kalman-filter machinery)

Option α, β, and β-W are three successive responses to this constraint.

### 3.2 Option α — constant trend in model

(committed 2026-05-23; AUSPAC working paper §4.11.4)

**Treat $g$ in wp736 Eq 9 as a single constant parameter, hardcoded for the whole sample.**

The structural target equation (from `dynare/simulation/identities/model.inc`):
$$
\Delta c^*_{\text{bar},t} = \underbrace{\bar{g}_C}_{\text{constant}} + \kappa_{\text{inc}} \Delta \text{pv\_yh}_t + \alpha_{c,r} \Delta(i_{lh} - \pi_c - r^*)_t - \alpha_{\text{PAYG}} \Delta \tau^{\text{PAYG,gap}}_t
$$

with $\bar{g}_C = 0.498\%$ qoq, calibrated as:
$$
\bar{g}_C = \frac{\bar{E}_{\text{post-08}}}{1 - \alpha_k} + \overline{\text{pop}} = \frac{0.49\%/4}{1-0.45} + 0.275 \approx 0.498\%/\text{qoq}
$$

i.e., taking only the **post-2008Q3 BGP value** from the FR-BDF $\bar{E}$ calibration and ignoring the regime structure.

The observable equation:
$$
\Delta C^{\text{obs}}_t = \Delta c_t + \Delta c^*_{\text{bar},t}
$$

At SS this gives $\Delta C^{\text{obs}}_{SS} = 0 + 0.498$, which is fed against raw $\Delta \log C$ data (mean 0.768%).

**Comparison with FR-BDF**: this is equivalent to setting $\Delta \bar{y}_t = 0.498$ for all $t$ in wp1044 Eq 35. The growth-neutrality correction term is captured by $\bar{g}_C$ but the time variation in $\bar{y}_t$ is ignored.

**Limitation**: pre-2002 high-growth quarters (FR-BDF Ē trend 2.4% p.a. = 0.60%/qoq, AU CES 3.07% p.a. = 0.77%/qoq) are under-predicted. The model assigns this trend-data mismatch to the cyclical $\Delta c_t$, distorting the b₀ (ECM speed) estimate downward.

### 3.3 Option β — three-regime time-varying trend for C and IB

(committed 2026-05-24, commit `0045ebf`; AUSPAC working paper §4.11.5)

**Replace the constant $\bar{g}_C$ with a regime-varying $\bar{g}_C + g^{\text{gap}}_{C,t}$ where $g^{\text{gap}}_{C,t}$ is observed as a step function.**

The structural target equation becomes:
$$
\Delta c^*_{\text{bar},t} = \bar{g}_C + g^{\text{gap}}_{C,t} + \kappa_{\text{inc}} \Delta \text{pv\_yh}_t + \cdots
$$

where $g^{\text{gap}}_{C,t}$ is **an endogenous random walk** in the model:
$$
g^{\text{gap}}_{C,t} = g^{\text{gap}}_{C,t-1} + \varepsilon^{C,\text{gap}}_t,
\qquad \varepsilon^{C,\text{gap}}_t \sim \mathcal{N}(0, 1^2) \text{ (calibrated)}
$$

The Kalman filter receives an observed data series (calibrated step function):

$$
g^{\text{gap},\text{data}}_{C,t} = \begin{cases}
+1.172 & t < 2002\text{Q2} \\
-0.028 & 2002\text{Q2} \le t < 2008\text{Q3} \\
0.000 & t \ge 2008\text{Q3}
\end{cases}
$$

These values come from the **AU CES 2026 calibration** (`dynare/ces_2026_calibration.txt`) following the same three-regime structure as FR-BDF wp1044 Eq 7 — same break dates (2002Q2, 2008Q3), different regime values reflecting AU-specific trend Ē growth (3.07% / 0.43% / 0.49% p.a. vs FR-BDF's 2.4% / 1.4% / 0.7%).

**Why a random walk and not just a varexo_det?** Dynare 6.5's `estimation()` does not read `varexo_det` values from the data file during Bayesian estimation. Confirmed empirically (2026-05-24): replacing actual gap data with zeros produced bit-identical Laplace LMD (−2740.03), proving the gap series wasn't entering the Kalman filter. The endogenous random walk + `varobs` + calibrated shock pattern is a workaround that does enter the filter correctly.

**Comparison with FR-BDF**: conceptually equivalent. FR-BDF computes $\Delta \bar{y}_t$ via Eq 7 (smooth stochastic trend with slope breaks), then passes it as a regressor to PAC equations. AUSPAC computes $g^{\text{gap}}_{C,t}$ as a step function from the CES calibration (a discrete approximation to the smooth trend) and smuggles it through Kalman. Mathematically:
$$
\Delta \bar{y}^{\text{FR-BDF}}_t \approx \bar{g}_C + g^{\text{gap}}_{C,t}
$$
with FR-BDF's version smoother (AR(1) over smooth trend), AUSPAC's version blockier (perfectly tracked step function).

### 3.4 Option β-W — extension to the wage Phillips curve

(committed 2026-05-24, commit `19c9e1d`; AUSPAC working paper §4.11.6)

**Mirror the C/IB pattern for the wage trend.** The wage Phillips equation (from `model.inc`):
$$
\pi^w_t = \lambda_w \pi^w_{t-1} + \gamma_w \pi^c_t - \kappa_w \, \text{pv\_u\_gap}_t + (1-\lambda_w-\gamma_w) \bar{\pi}^{\text{au}}_t + (1-\lambda_w)(\Delta \text{prod}_t + g^{\text{gap}}_{W,t}) + \varepsilon^w_t
$$

The new term $(1-\lambda_w) g^{\text{gap}}_{W,t}$ enters on the same footing as productivity drift $\Delta \text{prod}_t$. The $(1-\lambda_w)$ multiplier ensures that at SS (random walk at origin):
$$
\pi^w_{SS} = \lambda_w \pi^w_{SS} + (1-\lambda_w)\pi_{ss} + (1-\lambda_w) \cdot 0 \implies \pi^w_{SS} = \pi_{ss} = 0.625
$$

unchanged from Option α/β. When the regime drives $g^{\text{gap}}_W = 0.768$ (pre-02), the conditional mean shifts to:
$$
\pi^w_{SS,\text{regime}} = \pi_{ss} + g^{\text{gap}}_W = 0.625 + 0.768 = 1.393\%/\text{qoq}
$$

matching the calibrated pre-02 wage trend (from $\bar{E}_{\text{pre-02}}$ via $\pi_{ss} + \bar{E}_{\text{regime}}$).

The data series:
$$
g^{\text{gap},\text{data}}_{W,t} = \begin{cases}
+0.768 & t < 2002\text{Q2} \\
+0.108 & 2002\text{Q2} \le t < 2008\text{Q3} \\
+0.123 & t \ge 2008\text{Q3}
\end{cases}
$$

equal to the CES $\bar{E}$ regime values directly (because the gap is defined relative to constant $\pi_{ss}$ baseline).

**Comparison with FR-BDF**: FR-BDF's wage Phillips equation (wp1044 §3.4) implicitly handles this via its own block of trend equations for wages (`prodis`-based trend). The AUSPAC version is simpler — directly mirrors the AUSPAC C/IB pattern.

---

## 4. Side-by-side comparison

### 4.1 Trend object

| | FR-BDF wp1044 | AUSPAC Option α | AUSPAC Option β | AUSPAC Option β-W |
|---|---|---|---|---|
| Trend variable | $\Delta\bar{y}_t$ (HP-filtered trend output growth) | $\bar{g}_C = 0.498$ (constant) | $\bar{g}_C + g^{\text{gap}}_{C,t}$ (3-regime) | C/IB regime + $g^{\text{gap}}_{W,t}$ |
| Time-varying? | Yes — smooth stochastic | No | Yes — step function | Yes — step function |
| Where it's computed | Outside model (Eq 7 OLS) | Hardcoded parameter | MATLAB step-function in `prepare_estimation_data.m` | Same |
| Regime breaks | 2002Q2, 2008Q3 (deterministic trends $T_{1,t}, T_{2,t}, T_{3,t}$) | None | 2002Q2, 2008Q3 (step indicator) | Same |
| Smoothness | AR(1) persistence $z_1 \approx 0.56$ over deterministic trends + level shifts | n/a (constant) | Step function (no smoothing) | Same |
| COVID handling | Calibrated $-0.059$ level shift, AR-smoothed | Same constant value | Same step value (no COVID shift) | Same |

### 4.2 Where it appears in the consumption PAC equation

| Equation form | FR-BDF wp1044 Eq 35 | AUSPAC Option α | AUSPAC Option β |
|---|---|---|---|
| Error correction | $\beta_0(c^*_{t-1} - c_{t-1})$ | same | same |
| Lagged growth | $\beta_1 \Delta c_{t-1}$ | $b_1 \Delta c_{t-1}$ via `aux_consumption.mod` | same |
| Stationary expectation | $\text{PV}^2(y_H - \bar{y})_{t\|t-1}$ | via `pv_yh` policy function | same |
| Trend term | $\beta_{\text{PAC}} \Delta \bar{y}_{t-1}$ | $\bar{g}_C$ inside `dln_c_star_bar` | $\bar{g}_C + g^{\text{gap}}_{C,t}$ inside `dln_c_star_bar` |
| HtM channel | $\beta_2 [\Delta(\log(W_H + TG_H) - p^{VAT}_C) - \tilde{y}_t]$ | $b_{\text{HtM}} (\text{wt\_H\_real\_gap} - \hat{y}_t)$ | same |
| Interest gap | $\beta_3(\Delta r_{LH,t} - \cdots)$ | similar via `pv_r_lh_gap` | same |

### 4.3 Estimation pipeline

| Step | FR-BDF (wp1044 §2.2) | AUSPAC (post-Phase T) |
|---|---|---|
| 1. Supply block | Calibrate CES via Eq 7 OLS, derive $\bar{y}_t$ | Calibrate CES via `estimate_ces_2026.m`, derive regime values |
| 2. E-SAT VAR | Bayesian estimation, gives $d_i$ coefficients for PV | Bayesian estimation; PAC policy functions auto-computed via `pac.print()` |
| 3. PAC equations | Iterative OLS, takes $\bar{y}_t$ as fixed regressor | Joint Bayesian estimation in Dynare; trends enter via varobs+RW machinery |
| Trend object in estimation | Pre-computed time series, fixed input | Endogenous RW observed perfectly via Kalman |
| Why the difference | Block-by-block OLS doesn't need full state-space | Full-information Bayesian needs every observed series to be modelled as a state |

### 4.4 Architectural quote from each paper

**FR-BDF wp736 §3.3.1 footnote 19**:
> "These components [$\hat{y}^*_t$ and $\bar{y}^*_t$] are computed with a trend-cycle decomposition, e.g. an HP filter."

**FR-BDF wp1044 §3.1.1, on Ē trend**:
> "Trend [Ē] is estimated under three key assumptions: (i) it follows a deterministic trend with slope breaks; (ii) it includes a level shift in 2008-Q3 to reflect the lasting impact of the 2008–09 recession and an additional level shift in 2020-Q1 to incorporate the observed reduction in productivity after Covid-19 crisis; and (iii) it incorporates an autoregressive component to allow smooth adjustment to shocks. The annual trend growth rate is estimated at 2.4% before 2002-Q2, 1.4% between 2002-Q2 and 2008-Q3 and 0.7% afterwards, with the 2008-Q3 step estimated at −0.036% and the 2020-Q1 step calibrated at −0.059%."

**AUSPAC NEXT_SESSION.md gotcha #1 (post-Option-β discovery)**:
> "Dynare 6.5 silently ignores `varexo_det` values from the datafile in Bayesian estimation. Confirmed empirically: replacing actual gap series with zeros in the data file produced identical Laplace LMD."

---

## 5. The substantive difference — what we get vs what FR-BDF gets

### 5.1 What FR-BDF gets

FR-BDF's $\Delta \bar{y}_t$ is **smooth** (AR(1) smoothing of three deterministic trend segments + level shifts), **estimated** ($z_1$ persistence is estimated; deterministic trend coefficients $z_3, z_4, z_5, z_6$ are estimated; level shift sizes are estimated), and **enters PAC equations as a pre-computed regressor**. The PAC short-run coefficients (e.g., $\beta_{\text{PAC}}$ in Eq 35) are then estimated by OLS given $\Delta \bar{y}_t$ as data.

This means:
- The trend can shift gradually around break dates rather than jumping discretely
- The trend's contribution to consumption growth is identified by **time-series variation** in $\Delta \bar{y}_t$
- The PAC coefficient $\beta_{\text{PAC}}$ has a clean OLS interpretation: it's the coefficient on $\Delta \bar{y}_{t-1}$ in a single-equation regression

### 5.2 What AUSPAC Options α/β/β-W get

AUSPAC's $g^{\text{gap}}_{C,t}$ is a **calibrated step function** (no estimation of regime values; no smoothing across breaks), **observed perfectly via Kalman** through a random-walk identity with a calibrated stderr=1.0 shock, and **enters the PAC equation as a state variable** alongside `dln_c_star_bar`. The Bayesian MCMC jointly estimates the PAC coefficients, the Phillips block, and the HtM channel given this trend.

This means:
- Trend variation comes from the discrete breaks; smoothness is approximated only by the AR-like Kalman filter dynamics
- The "trend coefficient" doesn't have a clean OLS interpretation — it's absorbed into the existing PAC structure (`dln_c_star_bar` carries $\bar{g}_C + g^{\text{gap}}$ as its full SS)
- The mechanical likelihood penalty of having $g^{\text{gap}}$ as a varobs is ~110 nats per series, complicating cross-spec LMD comparisons

### 5.3 What FR-BDF doesn't model that I do (and vice versa)

| Feature | FR-BDF | AUSPAC |
|---|---|---|
| Smooth trend (AR(1) over deterministic segments) | Yes ($z_1 \approx 0.56$) | No (sharp step function) |
| Trend persistence as estimated parameter | Yes | No (random walk imposes $\rho = 1$) |
| Trend regime values estimated | Yes ($z_4, z_5, z_6$ via OLS) | No (calibrated from CES) |
| COVID level shift in trend | Yes ($-0.059$ calibrated; $-0.036$ for GFC estimated) | No (single post-2008 regime through end of sample) |
| Wage trend separate from output trend | Implicitly via wage block | Yes (Option β-W's $g^{\text{gap}}_W$ explicit) |
| Trend enters likelihood | No (pre-computed input) | Yes (as varobs, ~110 nats per series mechanical penalty) |
| Joint estimation with PAC coefs | No (iterative OLS) | Yes (full Bayesian MCMC) |
| Posterior uncertainty over trend | None (trend is fixed) | Implicit via Kalman; but driven by calibrated shock stderr |

---

## 6. Implications and pragmatic recommendations

### 6.1 Conceptually, AUSPAC ≈ FR-BDF for the trend mechanism

Both put the trend in the model rather than in the data. Both decompose the target into stationary + non-stationary parts. Both use the same break dates (2002Q2, 2008Q3) reflecting structural breaks in productivity growth. AUSPAC's Option β/β-W is the AUSPAC-appropriate realisation of FR-BDF's wp736 Eq 11 architecture, with the workarounds needed because AUSPAC uses full Bayesian estimation rather than iterative OLS.

### 6.2 Things FR-BDF does that AUSPAC could adopt

**(A) Smooth the trend across breaks via AR(1) on deterministic segments.** Currently AUSPAC's $g^{\text{gap}}$ is a perfectly sharp step function — Kalman absorbs the −1.2 jump at 2002Q2 as a single large shock. FR-BDF's Eq 7 with $z_1 = 0.56$ would distribute the regime change over ~3-4 quarters, which is more economically plausible. Could be implemented in AUSPAC by replacing the step function in `prepare_estimation_data.m` with an AR(1)-smoothed series before saving to `estimation_data.mat`.

**(B) Estimate regime values rather than calibrate.** The three regime constants (1.670 / 0.470 / 0.498) are currently fixed at CES calibration values. Could be promoted to `estimated_params` with priors centred on the calibration, letting AU data refine them. Identification might be shallow (mid regime spans only 25 quarters) but it's worth a sensitivity check.

**(C) Add a post-COVID level shift.** FR-BDF includes $-0.059$ level shift over 2020Q2-2021Q4 calibrated to reflect permanent productivity loss. AUSPAC's regime structure treats all of 2008Q3-end as one regime, ignoring the COVID step.

**(D) Estimate $\beta_{\text{PAC}}$ as a free coefficient rather than letting it be implicit.** Currently AUSPAC's wage equation has the structural $(1-\lambda_w)$ multiplier on $g^{\text{gap}}_W$ — making it identical to the productivity drift coefficient. wp1044 lets $\beta_{\text{PAC}}$ vary freely. This would relax the structural restriction and potentially fit better.

### 6.3 Things AUSPAC does that FR-BDF doesn't

**(E) Trend as an explicit state variable observed via Kalman.** This is mostly a cost of the Bayesian estimation choice, not a feature. But it does mean that AUSPAC could in principle smooth the observed trend (apply Kalman smoother to the implied $g^{\text{gap}}$ posterior) and get a posterior distribution over the trend at each date — something FR-BDF can't do because its trend is deterministic.

**(F) Separate trend object for the wage Phillips curve.** Option β-W explicitly carries $g^{\text{gap}}_W$ separately from $g^{\text{gap}}_C$, even though they happen to be calibrated identically (both = $\bar{E}_{\text{regime}}$). FR-BDF's wage equation block (wp1044 §3.4) handles wage trends via its own structural block; treating wage trend as a separate observable lets the data potentially identify a different wage drift if it exists.

### 6.4 The big takeaway

AUSPAC's Options α/β/β-W are AUSPAC's adaptation of FR-BDF's growth-neutrality machinery to a Bayesian-estimation context. The economics is the same; the plumbing is different. The remaining gaps (smooth trend, estimated regime values, post-COVID shift) are within reach as incremental refinements rather than architectural changes.

---

## 7. Equations side-by-side cheat sheet

Treat $\Delta y_t$ as the cyclical growth of variable $y$ (consumption, investment, or wages); $y^*_t$ is the target.

**Generic PAC equation (FR-BDF wp736 Eq 9):**
$$
\Delta y_t = a_0(y^*_{t-1} - y_{t-1}) + \sum_k a_k \Delta y_{t-k} + \sum_i d_i \Delta y^*_{t+i} + \left[1 - \sum_k a_k - \sum_i d_i\right] g
$$

**FR-BDF wp1044 consumption (Eq 35), trend term:**
$$
\cdots + \beta_{\text{PAC}} \cdot \underbrace{\Delta \bar{y}_{t-1}}_{\text{HP-filtered, smooth}} + \cdots
$$

**AUSPAC Option α consumption (`model.inc:222`), trend term:**
$$
\cdots + \underbrace{\bar{g}_C}_{\text{constant 0.498}} + \cdots \quad \text{(inside } \Delta c^*_{\text{bar},t} \text{)}
$$

**AUSPAC Option β consumption (`model.inc:236`), trend term:**
$$
\cdots + \bar{g}_C + \underbrace{g^{\text{gap}}_{C,t}}_{\text{step function, Kalman-tracked}} + \cdots \quad \text{(inside } \Delta c^*_{\text{bar},t} \text{)}
$$

**AUSPAC Option β-W wage Phillips (`model.inc:194`), trend term:**
$$
\cdots + (1-\lambda_w)\bigl(\Delta\text{prod}_t + \underbrace{g^{\text{gap}}_{W,t}}_{\text{step function, Kalman-tracked}}\bigr) + \cdots
$$

**The mapping in one line:**
$$
\underbrace{\Delta \bar{y}_t^{\text{FR-BDF, smooth}}}_{\text{HP-filtered trend, fitted by Eq 7}} \quad \longleftrightarrow \quad \underbrace{\bar{g}_C + g^{\text{gap}}_{C,t}^{\text{AUSPAC, step}}}_{\text{constant + Kalman-tracked step}}
$$

with FR-BDF's smoothness coming from AR(1) over slope-break deterministic trends, and AUSPAC's coming from the random-walk identity that the Kalman filter solves perfectly against the step-function data series.
