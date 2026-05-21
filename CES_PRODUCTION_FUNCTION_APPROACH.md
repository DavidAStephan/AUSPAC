# CES Production Function Calibration: FR-BDF 2026 Method

A detailed walk-through of how the Banque de France updated the CES production-function calibration in **WP #1044 (Dubois et al., 2026)** compared with the **WP #736 (Lemoine et al., 2019)** original, and the results we obtain when the new method is applied to Australian data inside **AUSPAC**.

This document is meant to be self-contained for someone porting the FR-BDF 2026 procedure into a different model. The implementation reference is [`data/estimate_ces_2026.m`](data/estimate_ces_2026.m); the numerical results we report below come from running that script against AU quarterly data (1990–2024).

---

## 1. The production technology (unchanged across both versions)

Both wp736 and wp1044 use the same CES production function for the **market branches** of the economy (households' own dwellings + non-market public/non-profit sectors are handled separately, as statistical trends):

$$
Q_t \;=\; \gamma \Bigl[\, \alpha\, K_t^{(\sigma-1)/\sigma} \;+\; (1-\alpha)\,(E_t H_t N_{S,t})^{(\sigma-1)/\sigma}\,\Bigr]^{\sigma/(\sigma-1)}
\tag{1}
$$

Variables and parameters:

| Symbol | Meaning |
|---|---|
| $Q_t$ | Market-sector real value added |
| $K_t$ | Capital services (or capital stock proxy) |
| $N_{S,t}$ | Salaried employment in market branches |
| $H_t$ | Hours per worker |
| $E_t$ | Labour-augmenting efficiency index |
| $\sigma$ | Elasticity of substitution between $K$ and $EHN_S$ |
| $\alpha$ | CES distribution parameter (controls capital intensity) |
| $\gamma$ | Scale parameter |
| $\mu$ | Aggregate markup (not in eq. 1; enters factor demand FOCs) |

The first-order conditions of the firm's cost minimisation problem under markup $\mu$ give three long-run equilibrium conditions that the calibration must respect:

$$
\log \tilde{I}^*_t = a_0 + \log Q_t - \sigma \log \frac{\tilde r_{K,t}}{P_{Q,t}} + \log\!\Bigl(\!\frac{\tilde \mu_t + g^K_t}{1 + g^K_t}\Bigr)
\tag{2: investment}
$$

$$
\log N^*_{S,t} = b_0 + \log Q_t - \log E_t - \sigma \log\frac{\tilde W_t}{P_{Q,t} E_t} + (\sigma-1)\log H_t
\tag{3: employment}
$$

$$
\log P^*_{Q,t} = c_0 + \frac{\sigma}{1-\sigma}\log(1-\alpha) - \frac{1}{1-\sigma}\log\!\Bigl[1 - \alpha\bigl(\tfrac{Q^{0,\text{tr}}_{K,t}}{\mu}\bigr)^{\!1-\sigma}\Bigr] + \log\frac{\tilde W_t}{E_t H_t}
\tag{4: VA price}
$$

with theoretical intercepts

$$
a_0 = \log\!\Bigl(\frac{\alpha}{\mu}\Bigr)\sigma, \quad b_0 = \log\!\Bigl(\frac{1-\alpha}{\mu}\Bigr)\sigma + \log \mu, \quad c_0 = \log\!\Bigl(\frac{\mu}{\gamma}\Bigr)
\tag{5}
$$

These are the **cross-restrictions** between the four structural parameters $(\sigma, \alpha, \gamma, \mu)$ and the OLS-estimable intercepts $(a_0, b_0, c_0)$ of the three long-run equations.

---

## 2. The wp736 (2019) approach: joint grid search

### 2.1 Procedure

wp736 §4.3.2 calibrates $(\sigma, \alpha, \gamma, \mu)$ as follows.

**Step 1 — $\sigma$ from the investment FOC.** Estimate eq. (2) directly: regress $\log \tilde I^*_t$ on $\log Q_t$ and $\log(\tilde r_{K,t}/P_{Q,t})$. The slope on the log real user cost is $\sigma$. The investment equation is chosen first because it does **not** depend on the unobserved efficiency $E_t$, only on the observed user cost.

> wp736 obtains $\hat\sigma = 0.53$ on French data 1995Q1–2017Q4.

**Step 2 — $a_0$ from the investment FOC.** The intercept of the same regression gives an estimate of $a_0$. From eq. (5), this pins down a *function* of $(\alpha, \mu)$:
$$
\mu = \exp\!\Bigl[\log\alpha + \tfrac{1}{\sigma}(\log\alpha - a_0)\Bigr]
$$

So $\mu$ is now expressed as a function of $\alpha$ (with $\sigma$ already fixed).

**Step 3 — joint $(\alpha, \gamma)$ grid search.** This leaves two free parameters, $\alpha$ and $\gamma$, and two remaining cross-restrictions on $b_0$ and $c_0$. wp736 does a 2-D grid search over $(\alpha, \gamma) \in [0.2, 0.4]^2$ with step 0.001 → **40,401 grid points**.

For each grid point $(\alpha_i, \gamma_i)$:

1. Reconstruct the Solow residual $E_t$ from the level CES eq. (1) given $(\alpha_i, \gamma_i, \sigma)$.
2. Estimate trend efficiency $\bar E_t$ by HP-filter (single break in 2008Q3).
3. OLS-estimate $b_0$ and $c_0$ from eqs. (3) and (4) using the implied $\bar E_t$.
4. Compute the $\ell_1$ deviation from theoretical intercepts:

$$
\| x \|_1 = \Bigl|b_0 - \log\!\bigl(\tfrac{1-\alpha_i}{\mu_i}\bigr)\sigma - (\sigma-1)\log\gamma_i\Bigr| + \Bigl|c_0 - \log\!\bigl(\tfrac{\mu_i}{\gamma_i}\bigr)\Bigr|
$$

5. Pick the grid point that minimises $\|x\|_1$, requiring $\min \|x\|_1 < 10^{-3}$ for a valid calibration.

> wp736 finds: $\sigma=0.53$, $\alpha=0.26$, $\gamma=0.34$, $\mu=1.31$, $\min\|x\|_1 = 0.0006$.

### 2.2 Why this approach was problematic

By the time wp1044 was written (2026), three problems with the 2019 method had become apparent on French data:

| Problem | Consequence |
|---|---|
| **Step 1 ($\sigma$ from investment FOC) became unstable** post-2008 ZLB and QE | The relationship between investment and the real user cost broke down during unconventional monetary policy; $\hat\sigma$ jumped around across sub-samples. |
| **40k-point grid search** is computationally heavy | Slow to re-run when data revisions arrive; difficult to do sensitivity analysis. |
| **Cross-restrictions are sensitive to the units of $\gamma$** | $\gamma$ is a chain-volume scale that depends on base-year conventions, but it enters the implied markup multiplicatively. Small differences in $\gamma$ produced large differences in $\mu$. |

In Australia all three problems showed up in spades on AU data — see [§7](#7-australian-results-vs-french-2026-results) below.

---

## 3. The wp1044 (2026) approach: three innovations

Section 3.1.2 of wp1044 makes **three** changes to the calibration:

### Innovation 1 — Analytical $\gamma$ from a base-year identity

Instead of grid-searching for $\gamma$, the 2026 method calibrates it **analytically** from a one-line identity.

**The key assumption.** Pick a base year $T^*$ in which the economy is close to its balanced growth path (BGP). Assume that *at the base year* the capital stock equals effective labour input:

$$
K_{T^*} \,=\, E_{T^*}\,H_{T^*}\,N_{S,T^*}^* \tag{6}
$$

This is the BGP property of the CES function — on the BGP, the capital-labour ratio (in efficiency units) is constant; choosing units so that ratio is 1 at $T^*$ is just a normalisation. Note that this normalisation **does not** restrict the data — it pins the *units* of $E_t$ relative to $K_t$, but says nothing about the actual ratio of capital to labour in physical or real-$ terms.

**Consequence.** Under eq. (6), evaluate the CES eq. (1) at $T^*$:

$$
Q_{T^*} \,=\, \gamma \bigl[\, \alpha\, K_{T^*}^{(\sigma-1)/\sigma} + (1-\alpha)\, K_{T^*}^{(\sigma-1)/\sigma}\,\bigr]^{\sigma/(\sigma-1)} \,=\, \gamma K_{T^*}.
$$

Both terms have the same kernel because of eq. (6), so the bracket collapses to $K_{T^*}^{(\sigma-1)/\sigma}$, and the outer exponent flips the sign back: the level CES becomes simply $Q_{T^*} = \gamma K_{T^*}$.

Therefore:

$$
\boxed{\;\gamma \,=\, \exp\!\Bigl(\,\overline{\log Q_t}_{\,t\in T^*} - \overline{\log K_t}_{\,t\in T^*}\,\Bigr)\;}
\tag{7}
$$

where the overline denotes the within-year mean over the four quarters of the base year. **wp1044 picks $T^*=2019$** (close to the end of the estimation sample but unaffected by COVID) and obtains $\hat\gamma = 0.2561$ for France.

**What's nice about this:**
- **No grid search.** $\gamma$ is identified from a single observed ratio.
- **Robust to the choice of base year.** wp1044 verifies that $\hat\gamma$ doesn't move much when you pick 2018 or 2017 instead.
- **Decouples $\gamma$ from $\sigma$.** Under eq. (6), the level CES at the base year is *independent of $\sigma$*. So we can pick $\gamma$ without committing to $\sigma$ first.

**One-line takeaway.** Steady-state capital and effective-labour inputs are equal *by choice of units*; this makes $\gamma$ the level of the output–capital ratio at the base year.

### Innovation 2 — $\sigma$ from the labour FOC (not the investment FOC)

The substitution elasticity $\sigma$ is now estimated from the long-run **employment** equation (3), not the investment equation (2). The reason is purely empirical: the relationship between investment and the real user cost broke down after 2008. The labour FOC remains stable.

**The estimable form.** Rearrange eq. (3) to isolate $\sigma$ as a slope coefficient:

$$
\log N_{S,t} - \log Q_t + \log E_t + \log H_t \,=\, b_0 \,-\, \sigma \cdot \log\!\Bigl(\frac{\tilde W_t}{P_{Q,t}\, E_t\, H_t}\Bigr)
\tag{8}
$$

The RHS variable is the **log real efficient hourly wage**: the wage rate per worker, deflated by the VA price and adjusted for hours and efficiency.

**The chicken-and-egg problem.** Equation (8) needs $E_t$, which is recovered from the level CES (eq. 1) inverted on $(\alpha, \sigma, \gamma)$. But $\alpha$ and $\sigma$ haven't been calibrated yet — so $E_t$ is unobserved at this stage.

**The proxy trick.** wp1044 replaces unobserved efficiency $E_t$ in eq. (8) with **trend labour productivity** $\hat\Phi_t$, where:

$$
\Phi_t \,\equiv\, \frac{Q_t}{N_{S,t} H_t}
$$

is the simple observed productivity per hour. Trend productivity $\hat\Phi_t$ is estimated by a deterministic AR(1) with two trend breaks, a 2008Q3 level step, and a COVID level shift (wp1044 eq. 6):

$$
\log\Phi_t \,=\, z_1 \log\Phi_{t-1} + (1-z_1)\bigl(z_2 + z_6\,\mathbb{1}_{\ge 2008\text{Q3}} - 0.043\,\mathbb{1}_{2020\text{Q2}\text{–}2021\text{Q4}}\bigr) + z_3(T_1 - z_1 T_{1,t-1}) + z_4(T_2 - z_1 T_{2,t-1}) + z_5(T_3 - z_1 T_{3,t-1}) + z_7\,\mathbb{1}_{2020\text{Q2}} + z_8(\mathbb{1}_{2020\text{Q1}} + \mathbb{1}_{2020\text{Q3}}) + \varepsilon_t
\tag{6}
$$

where $T_1, T_2, T_3$ are time trends that pick up after 1990, 2002Q2 and 2008Q3 respectively. The quasi-differenced form ($y_{qd} = y_t - z_1 y_{t-1}$) makes the regression linear in $(z_2, ..., z_8)$ conditional on $z_1$; a 1-D grid search over $z_1 \in [0.1, 0.95]$ closes the loop.

**Annual growth rates.** Because $T_1, T_2, T_3$ are in year-fractions, $z_3, z_4, z_5$ are directly **annual** growth rates of trend productivity in each regime. wp1044 obtains 2.4% / 1.4% / 0.7% p.a. across the three regimes for France.

**The labour-FOC regression.** With $\hat\Phi_t$ in hand, run eq. (8) replacing $E_t$ with $\hat\Phi_t$:

$$
\underbrace{\log N_{S,t} - \log Q_t + \log\hat\Phi_t + \log H_t}_{y_t} \;=\; b_0 \,-\, \sigma \cdot \underbrace{\log\!\Bigl(\frac{\tilde W_t}{P_{Q,t}\, \hat\Phi_t\, H_t}\Bigr)}_{x_t} \,+\, u_t
\tag{9}
$$

OLS the level regression $y = a + \beta x + u$ and read off $\hat\sigma = -\hat\beta$.

> wp1044 obtains $\hat\sigma = 0.4951$ with s.e. 0.168 on French data 1990Q1–2021Q4, R²=0.95.

**Why this is more robust.** The investment FOC fails under unconventional MP because the WACC compresses to the ZLB while investment continues to vary for non-rate reasons (corporate balance sheet, animal spirits). The labour FOC doesn't have this problem — the real efficient wage moved smoothly across the GFC and the QE era. Knoblach & Stöckl (2020) meta-analysis confirms labour-side estimates are typically more stable than capital-side ones across the international literature.

### Innovation 3 — Two-break trend efficiency $\bar E_t$ (re-derived from CES, not from productivity)

After Steps 1–2, $(\sigma, \gamma)$ are pinned. The **trend efficiency** $\bar E_t$ — which is what *actually enters* the model's behavioural equations — is then estimated as a second AR(1) regression, structurally identical to eq. (6) but applied to the inverted-CES Solow residual rather than to observed productivity:

1. Invert the level CES eq. (1) for $E_t$ given $(\sigma, \gamma, \alpha_{\text{bootstrap}})$:
   $$
   E_t \,=\, \biggl[\, \frac{(Q_t/\gamma)^{(\sigma-1)/\sigma} - \alpha\, K_t^{(\sigma-1)/\sigma}}{(1-\alpha)(H_t N_{S,t})^{(\sigma-1)/\sigma}}\,\biggr]^{\!\sigma/(\sigma-1)}
   $$
2. Run the same trend regression (wp1044 eq. 7) on $\log E_t$, with the same two breaks. This delivers a *smoother* trend than wp736's HP-filter approach because the breaks are explicit and the regression jointly fits persistence + trend + breaks + COVID effects.

The bigger COVID coefficient on $\bar E_t$ ($-0.059$ in wp1044 vs $-0.043$ on $\hat\Phi_t$) reflects the empirical observation that *measured* labour productivity dropped less than CES-implied *efficiency* did during COVID, because capital-labour substitution increased temporarily.

### Innovation 4 (implicit) — $\alpha$ and $\mu$ are re-pinned via the cross-restrictions

After Innovations 1–3, the original wp736 grid search collapses to a **1-D problem**: solve for $\alpha$ such that the cross-restriction on $b_0$ from eq. (5) holds, given $(\sigma, \gamma)$ now fixed. The remaining cross-restriction on $c_0$ pins $\mu$.

> wp1044 reports the updated French calibration as $\alpha=0.21$, $\mu=1.33$ (compared to wp736's $\alpha=0.26$, $\mu=1.31$). The shift in $\alpha$ reflects the new (lower) trend efficiency growth flowing through the Solow residual into the capital share.

### 3.1 Summary of differences

| Aspect | wp736 (2019) | wp1044 (2026) |
|---|---|---|
| **$\gamma$** | 2-D grid search over 40,401 points | Analytical: $\gamma = \overline{Q_{T^*}/K_{T^*}}$ in a base year |
| **$\sigma$** | From investment FOC eq. (2) (slope on $\log r_K/P_Q$) | From labour FOC eq. (3) (slope on log real efficient wage) |
| **Efficiency $E_t$** | Solow residual + HP-filter trend + single 2008Q3 break | Solow residual + AR(1)-trend with **two breaks** (2002Q2, 2008Q3) + COVID step |
| **Proxy for unobserved $E_t$ in eq. (3)** | n/a (didn't matter; $\sigma$ was estimated from eq. 2) | Trend labour productivity $\hat\Phi_t = Q/(NH)$ (wp1044 eq. 6) |
| **$(\alpha, \mu)$** | Solved from 2-D grid that minimises $\ell_1$ on $(b_0, c_0)$ cross-restrictions | Solved by 1-D problem on $(b_0, c_0)$ given $\sigma$ and $\gamma$ |
| **Computational cost** | ~minutes (40k grid evaluations) | ~seconds (closed-form $\gamma$ + 1-D regression for $\sigma$) |
| **Robustness to ZLB era** | Poor (investment FOC breaks down) | Good (labour FOC stable) |
| **Robustness to base-year unit conventions** | Sensitive (grid-fitted $\gamma$ is units-dependent) | $\gamma$ is *explicitly* a ratio of base-year quantities |
| **French results** | $\sigma=0.53$, $\gamma=0.34$, $\alpha=0.26$, $\mu=1.31$ | $\sigma=0.50$, $\gamma=0.2561$, $\alpha=0.21$, $\mu=1.33$ |

The new method retains the **same theoretical model** (eqs 1–4 are unchanged) and the **same cross-restrictions**; what changes is the order of identification and the choice of which FOC supplies $\sigma$. The new ordering — `γ → σ → α → μ` — uses only well-conditioned regressions at each stage.

---

## 4. Mathematical justification of the simplifications

### 4.1 Why does $\gamma = \overline{Q/K}$ work?

The level CES eq. (1) under the BGP normalisation $K_{T^*} = E_{T^*} H_{T^*} N_{S,T^*}^*$ becomes

$$
Q_{T^*} \,=\, \gamma\, K_{T^*}^{(\sigma-1)/\sigma}\cdot K_{T^*}^{(\sigma-1)/\sigma\,\cdot\,\sigma/(\sigma-1)} \,=\, \gamma\, K_{T^*}
$$

so $\gamma$ is exactly the level of the output-to-capital ratio at $T^*$. The exponents collapse because both inputs are equal in efficiency units. The simplification works *because* the CES is homogeneous of degree 1 (constant returns to scale) — outside CRS, you'd need an extra term. The simplification also makes $\gamma$ **invariant to $\sigma$** at the base year, which is what allows the calibration to proceed sequentially.

### 4.2 Why is the labour FOC more robust than the investment FOC?

Both eq. (2) and eq. (3) have $\sigma$ as the slope coefficient on a log relative price. The difference is what's on the right-hand side:

- **Eq. (2)** has $\log(\tilde r_{K,t}/P_{Q,t})$ — the real user cost of capital. The user cost is $\tilde r_K = (\text{WACC} + \delta - \pi^e) P_{IB}$, so it includes the expected discount rate. Under unconventional MP, the WACC is compressed (rates at ZLB, spreads compressed by central-bank asset purchases), while investment continues to vary for non-rate reasons (uncertainty, balance-sheet effects). The result is a flat regression line and an unstable estimate of $\sigma$.
- **Eq. (3)** has $\log(\tilde W_t/(P_{Q,t} E_t))$ — the real efficient wage. Wages are slow-moving, primarily driven by Phillips-curve dynamics, and the deflator $P_Q \cdot E$ tracks long-run productivity-adjusted price levels. There's no QE-style structural break in this relationship.

In Australia, the same logic applies but for a different reason: the **mining boom** (2003–2012) drove a wedge between user costs and investment that broke the investment-FOC regression. The labour FOC was unaffected.

### 4.3 What does the two-break trend efficiency capture?

For France:
- **Pre-2002Q2**: trend productivity growth ~2.4% p.a., consistent with the post-war catch-up.
- **2002Q2–2008Q3**: ~1.4% p.a. — slowdown coinciding with the early-2000s tech slowdown.
- **Post-2008Q3**: ~0.7% p.a. — secular slowdown documented in many advanced economies.

The 2008Q3 level step (~-0.036) reflects the permanent productivity loss from the GFC recession, distinct from the slope change. wp1044's argument is that without the second break, a single trend would over-fit the pre-2002 high-growth regime and produce implausibly low efficiency growth post-2008.

### 4.4 Why is the COVID step on $\bar E$ larger than on $\hat\Phi$?

For France: $-5.9\%$ on $\bar E$ vs $-4.3\%$ on $\hat\Phi$. The reasoning:
- **Observed productivity** $\hat\Phi$ is the simple ratio $Q/(NH)$. It captures the average labour output during COVID.
- **CES-implied efficiency** $\bar E$ is the "labour-augmenting technical change" component holding capital fixed. During COVID, firms substituted capital for labour (remote work tech, automation in some sectors), so capital was over-utilised. CES inversion attributes this to a *larger* efficiency drop than what shows up in average productivity.

This is one of the model-specific reasons to estimate the two trends separately rather than fold $\bar E$ in with $\hat\Phi$.

---

## 5. Step-by-step procedure (for porting to another model)

Here's the recipe applicable to any quarterly macro model with a CES production function for the market branches. The order matters — each step uses results from the previous one.

### Inputs needed (quarterly time series)
- $Q_t$: real market-sector value added (log)
- $K_t$: capital stock or services (log)
- $N_{S,t}$: salaried market employment (log)
- $H_t$: hours per worker (log)
- $W_t$: nominal wage cost per worker (log) — gross wages plus social contributions
- $P_{Q,t}$: market VA deflator (log)
- Pick a **base year** $T^*$: pre-COVID, post-any-major-regime-break, ideally near the end of the sample. (wp1044 uses 2019.)

### Step 1: Observed productivity
$$\log \Phi_t \,=\, \log Q_t - \log N_{S,t} - \log H_t$$

### Step 2: Trend productivity $\hat\Phi_t$
Estimate wp1044 eq. (6):
$$
\log\Phi_t = z_1 \log\Phi_{t-1} + (1-z_1)(z_2 + z_6 \mathbb{1}_{\ge 2008\text{Q3}} - \kappa_{\text{COVID}}\,\mathbb{1}_{2020\text{Q2}\text{–}2021\text{Q4}}) + z_3(T_1 - z_1 T_{1,t-1}) + z_4(T_2 - z_1 T_{2,t-1}) + z_5(T_3 - z_1 T_{3,t-1}) + z_7 \mathbb{1}_{20\text{Q2}} + z_8 (\mathbb{1}_{20\text{Q1}} + \mathbb{1}_{20\text{Q3}}) + \varepsilon_t
$$
where $T_1$ = trend years since sample start, $T_2$ = years since 2002Q2, $T_3$ = years since 2008Q3 (each $\ge 0$). Use a **grid search over $z_1$** (the only non-linear parameter) and OLS the rest. Pick the $z_1$ that maximises the log-likelihood.

The **deterministic trend** $\hat\Phi_t = z_2 + z_6 \mathbb{1}_{\ge 08\text{Q3}} + z_3 T_1 + z_4 T_2 + z_5 T_3 - \kappa_{\text{COVID}}\mathbb{1}_{20\text{Q2}\text{-}21\text{Q4}}$ is what proxies $E_t$ in Step 3.

### Step 3: Substitution elasticity $\sigma$
Run the level regression eq. (9):
$$
\log N_{S,t} - \log Q_t + \log\hat\Phi_t + \log H_t \;=\; b_0 - \sigma \cdot \log\!\Bigl(\frac{W_t}{P_{Q,t}\,\hat\Phi_t\,H_t}\Bigr) + u_t
$$
$\hat\sigma$ is the negative of the slope. If the level regression has poor DW (<1.5), fall back to first differences (and consider Bayesian regularisation with a tight prior).

**Health checks:**
- $\sigma$ should land in $[0.3, 0.8]$ (Knoblach & Stöckl 2020 meta-analysis). $\sigma=1$ is Cobb-Douglas (not supported by the literature). $\sigma < 0$ is wrong-signed.
- Compare R², DW, residual autocorrelation against the FR-BDF benchmark.

### Step 4: Scale parameter $\gamma$
$$\boxed{\hat\gamma \,=\, \exp\!\bigl[\,\overline{\log Q_t} - \overline{\log K_t}\,\bigr]\;\;\text{over } t \in T^*\,}$$
Simple within-year mean of the log output-capital ratio.

### Step 5: Trend efficiency $\bar E_t$
Invert the level CES eq. (1) at a bootstrap $\alpha$ (use a labour-share-based guess, e.g. $\alpha=0.35$):
$$
E_t \,=\, \Bigl[\,\frac{(Q_t/\hat\gamma)^{(\sigma-1)/\sigma} - \alpha K_t^{(\sigma-1)/\sigma}}{(1-\alpha)(H_t N_{S,t})^{(\sigma-1)/\sigma}}\,\Bigr]^{\!\sigma/(\sigma-1)}
$$
Then run the same wp1044 eq. (7) trend regression on $\log E_t$ (typically with a *bigger* COVID step than for productivity — wp1044 uses $-5.9\%$ vs $-4.3\%$).

### Step 6: Re-pin $\alpha$ and $\mu$
Two options:
- **Cross-restriction route** (wp1044's headline approach). Solve the 1-D problem on $\alpha$ such that the $b_0$ cross-restriction holds at the OLS-estimated employment intercept $b_0^{\text{OLS}}$. Then $\mu$ follows from the $c_0$ cross-restriction. Requires the underlying chain-volume conventions to be "well-behaved" — see §7 for AU where they aren't.
- **Independent-data route** (AUSPAC's fallback). Set $\alpha$ to the empirical capital-income share (national accounts) and $\mu$ to an independent markup estimate (production-function literature). Use the cross-restriction as a **diagnostic** rather than as a binding identification equation.

### Step 7: Document and save
Save $(\sigma, \alpha, \gamma, \mu)$ plus all the trend parameters $(z_1, \ldots, z_8)$ for both $\hat\Phi$ and $\bar E$. The model's behavioural equations will use $\sigma$ (in the factor demand FOCs), $\alpha$ (in the linearised potential output identity), $\gamma$ (in the long-run output level identity), and $\mu$ (in the inflation-anchor equations).

---

## 6. AUSPAC's Australian application

[`data/estimate_ces_2026.m`](data/estimate_ces_2026.m) implements the procedure of §5 against AU quarterly data. Data sources:

- $Q_t$: ABS 5206 Table 6, market-sector real GVA (chain volume).
- $K_t$: ABS 5204 Table 63 net capital stock, total economy (annual; quarterly-interpolated).
- $N_{S,t}$: ABS 6202 Table 1, total employed (proxy for salaried — AU 6202 doesn't split salaried/non-salaried).
- $H_t$: ABS 6202 Table 19, aggregate monthly hours / employed.
- $W_t$: ABS 6345 Table 1, Wage Price Index (SA, post-1997Q3); ABS 6302 Table 1 Average Weekly Earnings for pre-1997 splice.
- $P_{Q,t}$: ABS 5206 Table 5 / Table 6, market-sector IPD (chain Laspeyres-Paasche aggregation of expenditure deflators).
- $\delta_K$: 0.025 quarterly (10% annual), from ABS 5204 Table 47 depreciation rate average 1995–2024.

The script handles the AU-specific issues with three deliberate departures from the FR-BDF 2026 procedure:

1. **COVID step calibration** is smaller on AU data ($-1.5\%$ on $\hat\Phi$, $-2.0\%$ on $\bar E$) than for France ($-4.3\%$ / $-5.9\%$). AU's COVID productivity hit was milder and shorter due to (a) the stronger fiscal response (JobKeeper kept the employment-output ratio roughly intact), and (b) a smaller services-sector COVID disruption (lower per-capita case counts).

2. **Spec selection for $\sigma$**: AU's level regression has DW = 0.37 → strong serial correlation → no cointegration in levels (the mining boom drove a wedge between hourly labour cost and productivity 2003–2012). The script falls back to first differences when DW < 1.5, with **Bayesian regularisation** under a $\sigma \sim N(0.50, 0.20^2)$ prior centred on the FR-BDF 2026 posterior. This is the spec actually used in AUSPAC: posterior $\sigma = 0.5366$.

3. **$\alpha$ and $\mu$ are calibrated directly** from AU sources rather than from the FR-BDF cross-restriction. The reason: AU's analytical $\gamma = 0.0458$ sits in different units from France's $\gamma = 0.2561$ (AU $Q$ is market-sector chain-volume, $K$ is total-economy net capital stock; the level ratio differs from France's by an order of magnitude because of base-year and aggregation choices). The cross-restriction on $c_0$ then implies $\mu \approx 20$, way outside the plausible range $[1.0, 2.0]$. Rather than chase that, AUSPAC uses the cross-restriction as a *diagnostic* and calibrates $\alpha$ from the AU capital-income share and $\mu$ from RBA Research Discussion Papers.

---

## 7. Australian results vs French 2026 results

### Table 7.1: Headline calibration comparison

| Parameter | Symbol | **AU (AUSPAC)** | **FR (wp1044)** | Comment |
|---|---|---|---|---|
| Substitution elasticity | $\sigma$ | **0.5366** | 0.4951 | Statistically very close; both in [0.3, 0.8] range of Knoblach & Stöckl meta-analysis |
| Scale parameter | $\gamma$ | **0.0458** | 0.2561 | Different units (AU market-VA / total-capital vs FR market-VA / market-capital) |
| Capital distribution | $\alpha$ | **0.45** | 0.21 | AU has higher measured capital-income share (capital-intensive mining + agriculture) |
| Markup | $\mu$ | **1.20** | 1.33 | AU markups consistently estimated lower than FR (Hambur RDP 2018-09 puts AU in [1.15, 1.25]) |

### Table 7.2: Trend efficiency growth comparison

| Sub-period | **AU $\bar E$ growth p.a.** | **FR $\bar E$ growth p.a.** | Comment |
|---|---|---|---|
| pre-2002Q2 | **3.07%** | 2.40% | AU pre-2002 productivity high due to 1990s structural reform |
| 2002Q2–2008Q3 | **0.43%** | 1.40% | AU mining-boom era had labour reallocation toward less-productive sectors (KLEMS data shows similar) |
| post-2008Q3 | **0.49%** | 0.70% | Both economies slow post-GFC; AU slightly weaker due to mining-bust productivity drag |

### Table 7.3: Trend productivity growth (Step 2 reference)

| Sub-period | **AU $\hat\Phi$ growth p.a.** | **FR $\hat\Phi$ growth p.a.** |
|---|---|---|
| pre-2002Q2 | 2.54% | 2.40% |
| 2002Q2–2008Q3 | 0.87% | 1.40% |
| post-2008Q3 | 0.39% | 0.70% |

Note the discrepancy between $\bar E$ growth and $\hat\Phi$ growth (3.07% vs 2.54% pre-2002Q2): this reflects the CES inversion redistributing growth between efficiency and capital intensity, exactly as wp1044 documents for France post-COVID.

### 7.4 What worked and what didn't on AU data

**Worked well (no modification needed):**
- Innovation 1 — analytical $\gamma$. Gave a clean point estimate; insensitive to base-year choice (2018, 2019, 2020 all give similar $\hat\gamma \approx 0.046$).
- Innovation 2 — labour-FOC $\sigma$. Statistically significant (t-stat 4.4 on FD spec, 105 quarters), economically plausible, robust across sub-samples.
- Innovation 3 — two-break trend $\bar E$. Captured the AU mining-boom regime change as a 2002Q2 break naturally; would have been hard to identify in a single-break or HP-filter framework.

**Required modification:**
- Bayesian regularisation on $\sigma$. AU level regression has DW=0.37 (no cointegration); FD spec gives σ=0.557 (s.e. 0.127) but with high variance. Posterior under $N(0.50, 0.20^2)$ prior shrinks toward 0.50 with 41% data weight — final σ=0.5366. wp1044's preferred level spec doesn't work on AU.

**Didn't work; replaced with independent-data calibration:**
- The cross-restrictions for $(\alpha, \mu)$. AU's $\gamma$ sits in different units from France's $\gamma$ because of chain-volume conventions; the implied markup is implausible (~20). AUSPAC uses ABS 5204 capital-income share for $\alpha=0.45$ and RBA RDP 2018-09 mid-range for $\mu=1.20$.

---

## 8. What changes in the model code when you use the FR-BDF 2026 calibration

For a porter writing a different model, here's where the four calibration outputs appear in the actual macro equations:

| Where in the model | What changes | Why |
|---|---|---|
| **Long-run output identity** $\Delta \ln Q^* = \alpha \Delta \ln K + (1-\alpha)\Delta \ln(EHN)$ | Uses $\alpha$; collapses to Cobb-Douglas form under base-year normalisation | Innovation 1 — the BGP normalisation makes the log-linearised CES algebraically Cobb-Douglas at the base-year point, independent of $\sigma$. $\sigma$ matters only away from the base year (in the FOCs). |
| **Employment target** $\log N^* = b_0 + \log Q - \log E - \sigma \log(W/(P_Q E)) + (\sigma-1)\log H$ | Uses $\sigma$ from Innovation 2 | Standard FR-BDF eq. (3). |
| **Investment target** $\log I^* = a_0 + \log Q - \sigma \log(r_K/P_Q) + \ldots$ | Uses $\sigma$ from Innovation 2 | Even though Innovation 2 estimates $\sigma$ from the labour FOC, the same $\sigma$ enters the investment FOC. wp1044 verifies the two estimates are statistically consistent. |
| **VA price target** $\log P^*_Q = c_0 + \frac{\sigma}{1-\sigma}\log(1-\alpha) - \ldots + \log(W/(EH))$ | Uses $\sigma, \alpha, \gamma$ from all three innovations | Inflation anchor for the VA price PAC equation. |
| **CES dual pass-throughs** $\gamma_{ULC} = (1-\alpha)\sigma$, $\gamma_{UCK} = \alpha\sigma$ | Both functions of $\sigma$ and $\alpha$ | These appear linearly in the inflation Phillips curve. AU: $(1-0.45)\cdot 0.54 = 0.30$; FR: $(1-0.21)\cdot 0.50 = 0.40$. |
| **Long-run output growth** $\bar g_Q = (1-\alpha)\cdot \bar g_E + (1-\alpha)\cdot \bar g_H + \alpha\cdot \bar g_K$ on the BGP | Uses $\alpha$ and the $\bar E$ trend growth rates from Innovation 3 | Determines steady-state real growth. |

---

## 9. Practical lessons for porting

1. **Don't expect the cross-restrictions to give plausible $\mu$ on your data.** They worked for France because the chain-volume conventions and the market-vs-total aggregations line up cleanly. On other countries (AU, anywhere with different national-accounts conventions), the cross-restriction on $c_0$ produces an implausible $\mu$ and should be treated as a diagnostic. Calibrate $\mu$ from independent sources (markup literature).

2. **The base-year normalisation is your friend.** Once you accept $K_{T^*} = E_{T^*} H_{T^*} N_{T^*}^*$, *all the algebra simplifies dramatically*. The level CES becomes $Q^*_{T^*} = \gamma K_{T^*}$. The shares at the base year are $s_K = \alpha$ and $s_N = 1-\alpha$ (independent of $\sigma$). The log-linearisation reduces to Cobb-Douglas form (independent of $\sigma$). $\sigma$ enters *only* through the responsiveness of factor demands to relative-price changes, which is exactly the channel you want — substitutability between $K$ and $L$.

3. **The labour FOC will work even when the investment FOC won't.** This is a near-universal property of advanced-economy data post-2008. Anywhere with a ZLB episode (US, EA, UK, JP) or a mining-style sectoral wedge (AU, CA, NO, NL) will see the investment FOC fail. The labour FOC is structurally more robust because wages and labour are more tightly cointegrated with productivity than investment is with the user cost.

4. **Use the deterministic trend, not the dynamic fitted values, as your proxy for $E_t$.** The deterministic trend strips out the shocks $\varepsilon_t$; it's the *structural* trend you want to pass into the labour-FOC regression. wp1044 is explicit about this; AUSPAC follows the same convention.

5. **First differences are your friend on data with cointegration breakdown.** Use the level regression as the default; switch to FD if Durbin-Watson < 1.5 or if R² is suspiciously close to 1.0 (spurious regression). Bayesian shrinkage on $\sigma$ with prior centred on the FR-BDF posterior is a clean way to handle ambiguity.

6. **Two trend breaks is the right number for most advanced economies.** 2002 (early-2000s tech-productivity slowdown) and 2008 (GFC). Anywhere with a different structural-break history (e.g., emerging markets) should pick its own break dates.

7. **The COVID step on efficiency is bigger than on productivity.** This is by-construction once you invert the level CES — capital was over-utilised during COVID, so CES attributes more of the output drop to efficiency loss than the productivity ratio does. Calibrate the two COVID steps separately.

---

## 10. Files in AUSPAC implementing this

| File | Role |
|---|---|
| [`data/estimate_ces_2026.m`](data/estimate_ces_2026.m) | Driver implementing Steps 1–7 above. |
| [`data/prepare_supply_data.m`](data/prepare_supply_data.m) | Builds `dynare/supply_data.mat` (log-levels of Q, K, N, H, P_Q, W, δ). |
| [`data/download_supply_data.m`](data/download_supply_data.m) | Downloads the underlying ABS xlsx (5204, 5206, 6202, 6302, 6345). |
| `dynare/ces_2026_calibration.txt` | Human-readable summary of the AU calibration (regenerated each run). |
| `dynare/ces_2026_calibration.mat` | Machine-readable equivalent — used by `dynare/au_pac.mod` and aux files. |
| [`dynare/AUSPAC_WORKING_PAPER.md`](dynare/AUSPAC_WORKING_PAPER.md) §4.2 | Paper section documenting the procedure and results. |

## 11. References

- **Dubois et al. (2026)**: U. Dubois, B. Ducoudré, R. Martin, A. Petronevich, C. Seghini, C. Thubin, H. Turunen. *Re-estimated FR-BDF: New Features and an Assessment of Monetary Policy Tightening in France.* Banque de France WP No. 1044. — Source of the calibration procedure described in §3 above. Section 3.1.2 specifically.
- **Lemoine et al. (2019)**: M. Lemoine, H. Turunen, M. Chahad, A. Lepetit, A. Zhutova, P. Aldama, P. Clerc, J.-P. Laffargue. *The FR-BDF Model and an Assessment of Monetary Policy Transmission to the French Economy.* Banque de France WP No. 736. — Source of the original (2019) approach. Section 4.3.2 specifically.
- **Knoblach & Stöckl (2020)**: M. Knoblach and F. Stöckl. *What determines the elasticity of substitution between capital and labor? A literature review.* Journal of Economic Surveys 34(4): 847–875.
- **Devulder et al. (2024)**: cited in wp1044 §3.1.2 for the calibration of the COVID-19 productivity loss; updated in the Bank of France June 2025 Macroeconomic Projections.
- **Hambur (2018)**: J. Hambur. *Product Market Competition and its Implications for the Australian Economy.* RBA RDP 2018-09. — Source of the AU markup calibration.
- **Andrews & Hambur (2022)**: D. Andrews and J. Hambur. *The Decline in Average Hours Worked in Australia.* RBA RDP 2022-09. — Used for AU labour-input series construction.
