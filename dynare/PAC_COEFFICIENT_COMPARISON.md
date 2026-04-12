# PAC Equation Coefficient Comparison: AU-PAC vs FR-BDF

## Overview

This document compares every coefficient in the 5 PAC equations between AU-PAC (Australian adaptation) and FR-BDF (Banque de France WP #736). For each equation, we show:
- A. Target equation coefficients
- B. Short-run PAC equation coefficients with fit diagnostics
- C. E-SAT auxiliary regression coefficients and policy functions
- D. Key differences and rationale

All FR-BDF values are from the paper's estimation tables. AU-PAC values are from the current calibration (to be re-estimated with Australian data).

---

## 1. VA Price Inflation (piQ)

### A. Target Equation

**FR-BDF eq 38 (Factor Price Frontier):**
```
p*_Q = c₀ + σ/(1-σ)·log(1-α) - 1/(1-σ)·log[1 - ασ·(Q'_K/γ)^(1-σ)] + log(W̃/(Ē·H))
```

| Coeff | FR-BDF | AU-PAC | AU-PAC form |
|-------|--------|--------|-------------|
| σ (CES elasticity) | 0.53 | 0.53 | sigma_ces |
| α (capital share) | 0.26 | 0.33* | alpha_k |
| γ (scale) | 0.34 | — | Not used (linearized) |
| µ (markup) | 1.31 | — | Not used (linearized) |
| R² | 0.97 | N/A | Calibrated |

*AU-PAC uses Cobb-Douglas alpha_k=0.33 vs FR-BDF CES alpha=0.26. FR-BDF's alpha is a CES distribution parameter, not directly comparable to Cobb-Douglas capital share.

**AU-PAC linearized target** (eq_piQ_star):
```
piQ_star = rho_pQ_star·piQ_star(-1) + gamma_ulc·dln_ulc + gamma_uck·dln_uc_k + (1-rho-gamma_ulc)·pibar_au
```

| Coeff | Value | FR-BDF equivalent |
|-------|-------|-------------------|
| rho_pQ_star | 0.95 | — (level form in FR-BDF, no explicit persistence) |
| gamma_ulc | 0.12 | ~labor share (1-α)/(1-σ) ≈ consistent |
| gamma_uck | 0.06 | ~capital cost pass-through |
| 1-rho-gamma_ulc | 0.03 | inflation anchor |

**Change from FR-BDF**: Linearized the nonlinear price frontier into a growth-rate AR(1) with ULC and user cost pass-through. The level form with trend return on capital Q'_K is replaced by dln_uc_k.

### B. Short-run PAC Equation

**FR-BDF eq 44 (Table 4.4.3):**
```
πQ = PV(Δπ̂*_Q)_{t|t-1} + β₀(p* - p)_{t-1} + β₁·πQ(-1) + β₂·ŷ + (1-β₁-ω)·π̄* + ε
```

| Coeff | Symbol | FR-BDF | AU-PAC | Match? |
|-------|--------|--------|--------|--------|
| EC speed | β₀ / b0_pQ | 0.06 (0.02) | **0.06** | Exact |
| AR(1) persistence | β₁ / b1_pQ | 0.50 (0.09) | **0.50** | Exact |
| Output gap | β₂ / b2_pQ | 0.09 (0.03) | **0.09** | Exact |
| Expectations share | ω / omega_pQ | 0.46 | **0.46** | Exact |
| Growth neutrality | 1-β₁-ω | 0.04 | **0.04** | Exact |
| PAC order m | — | 1 | **1** | Match |
| Discount β | — | 0.98 | **0.98** | Match |
| R² | — | 0.40 | N/A | — |
| Sample | — | 1997Q1-2017Q4 | Calibrated | — |

*FR-BDF standard errors in parentheses.*

**AU-PAC additional term** (not in FR-BDF eq 44):
```
+ pv_piQ_aux    // Dynamic E-SAT auxiliary (backward expectation correction)
```

### C. E-SAT Auxiliary Equations

**FR-BDF Table 4.4.4 — Policy function PV(π*_Q)_{t|t-1}:**

| E-SAT state variable | FR-BDF policy function coeff |
|---------------------|------------------------------|
| ŷ_{t-1} | -1.5×10⁻³ |
| i_{t-1} - ī | -3.4×10⁻³ |
| π_{Q,t-1} - π̄_Q | 8.7×10⁻⁴ |
| ŷ_{EA,t-1} | 4.8×10⁻⁴ |
| π_{EA,t-1} - π̄_{EA} | 0.00 |
| û_{t-1} | -1.1×10⁻² |
| π̃_{W,t-1} | 1.2×10⁻² |
| π̄*_{Q,t-1} | 0.44 |

**FR-BDF Auxiliary equations (Table 4.4.4):**

*Eq 45 — VA price target growth:*
```
π*_Q = 0.59·π̃_W + 0.41·π̄*_Q + ε     (R² = 0.48)
```

*Eq 46 — Efficient wage Phillips:*
```
(1-0.25L)(π̃_W - π̄*_Q) = -0.04·û + ε     (R² = 0.02)
```

*Eq 47 — Okun's law:*
```
û = -0.246·ŷ + 0.946·û(-1) + ε     (R² = 0.92)
```

**AU-PAC Dynamic Auxiliary** (eq_pv_piQ_aux):
```
pv_piQ_aux = 0.70·pv_piQ_aux(-1) + 0.03·yhat_au(-1) - 0.02·i_gap(-1)
```

| Feature | FR-BDF | AU-PAC |
|---------|--------|--------|
| Number of state variables | 8 | 2 (+ own lag) |
| Own persistence | Implicit via E-SAT VAR | **0.70** (explicit AR(1)) |
| Output gap sensitivity | -0.0015 | **0.03** (much larger, compensates for fewer states) |
| Interest rate sensitivity | -0.0034 | **-0.02** |
| Inflation sensitivity | 0.00087 | — (absent) |
| Unemployment gap | -0.011 | — (absent, captured via output gap) |
| Wage inflation | 0.012 | — (absent) |
| Long-run trend | 0.44 | — (in pac_expectation growth term) |

**Key difference**: FR-BDF uses a 3-equation auxiliary system (eqs 45-47) with 8 E-SAT state dependencies. AU-PAC collapses this to a single AR(1) with output gap and interest rate. The larger a_pQ_y (0.03 vs -0.0015) compensates for the missing auxiliary structure.

---

## 2. Employment (dln_n)

### A. Target Equation

**FR-BDF eq 55 (inverted CES labor demand):**
```
log(N*_S) = b₀ + log(Q) - log(Ē) - σ·log(W̃/(P_Q·Ē·H)) + (σ-1)·log(H)
```

| Coeff | FR-BDF (Table 4.5.5) | AU-PAC |
|-------|---------------------|--------|
| b₀ (intercept) | 8.85e-2 (0.07e-2) | — (growth rate form) |
| σ (CES) | 0.53 (calibrated) | **0.53** |
| R² | 0.98 | N/A |

**AU-PAC growth-rate form** (eq_dln_n_star_bar):
```
dln_n_star_bar = dln_tfp/(1-alpha_k) - sigma_ces·rw_gap
```
where rw_gap = pi_w - piQ - dln_prod.

**Change from FR-BDF**: Level form → growth rate form. CES substitution elasticity preserved.

### B. Short-run PAC Equation

**FR-BDF eq 56 (Table 4.5.6):**
```
Δn_S = β₀(n*-n)_{t-1} + PV(Δn̄*) + PV(Δn̂*) + β₁Δn(-1) + β₂Δn(-2) + β₃Δn(-3) + (1-Σbk-ω)Δn̄* + β₄Δq̂ + ε
```

| Coeff | Symbol | FR-BDF (Table 4.5.6) | AU-PAC | Match? |
|-------|--------|---------------------|--------|--------|
| EC speed | β₀ / b0_n | 0.06 (0.02) | **0.04** | Lower* |
| AR(1) | β₁ / b1_n | 0.87 (0.11) | **0.30** | Much lower* |
| AR(2) | β₂ / b2_n | -0.30 (0.15) | **0.10** | Different sign* |
| AR(3) | β₃ / b3_n | 0.17 (0.10) | **0.05** | Lower |
| AR(4) | — / b4_n | — | **0.02** | Added* |
| Output gap | β₄ / b5_n | 0.15 (0.03) | **0.12** | Similar |
| Expectations ω | — / omega_n | 0.26 | **0.30** | Similar |
| Growth neutrality | — | 1-0.87+0.30-0.17-0.26=0.04 | **0.23** | Different |
| PAC order m | — | 3 (cubic) | **4** (quartic) | AU adds lag |
| R² | — | 0.92 | N/A | — |
| Sample | — | 1997Q1-2017Q4 | Calibrated | — |

*FR-BDF has much higher AR(1)=0.87 and negative AR(2)=-0.30, reflecting hump-shaped French labor adjustment. AU-PAC has lower, monotonically declining AR coefficients and adds a 4th lag.

### C. E-SAT Auxiliary Equations

**FR-BDF Table 4.5.7 — Policy function PV(Δn̂*_S)_{t|t-1}:**

| E-SAT state | FR-BDF coeff |
|-------------|-------------|
| ŷ_{t-1} | 0.02 |
| i_{t-1} - ī | -0.03 |
| π_{Q,t-1} - π̄_Q | 0.02 |
| ŷ_{EA,t-1} | 0.01 |
| π_{EA,t-1} - π̄_{EA} | 0.00 |
| n̂*_{S,t-1} | -0.05 |

**FR-BDF Auxiliary equation (eq 57):**
```
n̂*_S = 0.30·ŷ(-1) + 0.07·(i-ī)(-1) + 0.16·(πQ-π̄)(-1) + 0.67·n̂*_S(-1) + ε     (R² = 0.82)
```

**AU-PAC Dynamic Auxiliary** (eq_pv_n_aux):
```
pv_n_aux = 0.67·pv_n_aux(-1) + 0.12·yhat_au(-1) - 0.03·i_gap(-1)
```

| Feature | FR-BDF eq 57 | AU-PAC |
|---------|-------------|--------|
| Own persistence | **0.67** | **0.67** | Exact match! |
| Output gap | **0.30** (0.09) | **0.12** | Lower (different Okun) |
| Interest rate gap | **0.07** (0.3) | **-0.03** | Different sign* |
| Inflation gap | **0.16** (0.13) | — | Absent |
| R² | 0.82 | N/A | — |

*FR-BDF's positive interest rate coefficient (0.07) is not significant (s.e.=0.3). AU-PAC uses negative sign reflecting the monetary policy demand channel.

---

## 3. Household Consumption (dln_c)

### A. Target Equation

**FR-BDF eq 59:**
```
c* = α₀ + PV(yH)_{t|t-1} + α₁·(rLH - (ī - π̄))
```

| Coeff | FR-BDF | AU-PAC |
|-------|--------|--------|
| α₀ (constant) | -0.16 | — (gap model, zero SS) |
| α₁ (interest rate) | -0.95 | **-0.95** (alpha_c_r) | Exact |
| β_c (PV discount) | 0.95 | **0.95** | Exact |
| IES (implied) | ~0.1 | ~0.1 | Match |

**AU-PAC target growth** (eq_dln_c_star_bar):
```
dln_c_star_bar = 0.05·Δ(pv_yh) - 0.95·Δ(real lending rate gap)
```

### B. Short-run PAC Equation

**FR-BDF eq 61 (Table 4.6.2):**
```
Δc = β₀(c*-c) + β₁Δc(-1) + PV²(yH-ȳ) + α₁[PV(rLH)-PV(ī-π̄)] + (1-β₁)(Δȳ-Δ(yH-ȳ)) + β₂Δŷ + β₃Δ(rLH-r̄) + β₄δ_prime + ε
```

| Coeff | Symbol | FR-BDF (Table 4.6.2) | AU-PAC | Match? |
|-------|--------|---------------------|--------|--------|
| EC speed | β₀ / b0_c | 0.12 (0.05) | **0.06** | Lower* |
| AR(1) | β₁ / b1_c | -0.08 (0.09) | **0.149** | Different sign* |
| Output gap (HtM) | β₂ / b3_c | 0.26 (0.11) | **0.139** | Lower |
| Interest rate change | β₃ / b2_c | -0.71 (0.45) | **-0.02** | Much smaller* |
| Car scrappage dummy | β₄ | 0.007 (0.002) | — | Dropped (France-specific) |
| Expectations share | ω | — | **0.369** | — |
| Growth neutrality | — | — | **0.482** | — |
| R² | — | 0.54 | N/A | — |

*FR-BDF EC speed is 2x AU-PAC. FR-BDF AR(1) is negative (unusual, suggesting overshooting). AU-PAC interest rate change sensitivity is much smaller (-0.02 vs -0.71).

**Missing FR-BDF terms in AU-PAC**:
- PV²(yH-ȳ) — nested expectation of permanent income (replaced by pac_expectation)
- α₁[PV(rLH)-PV(ī-π̄)] — expected interest rate gap level (replaced by b2_c*i_gap(-1))
- β₄δ_prime — car scrappage dummy (France-specific, dropped)

### C. E-SAT Auxiliary Equations

**FR-BDF Table 4.6.3 — Policy function PV(yH-ȳ)_{t|t-1}:**

| E-SAT state | FR-BDF coeff |
|-------------|-------------|
| Constant | -0.29 |
| ŷ_{t-1} | -0.036 |
| i_{t-1} - ī | -0.085 |
| π_{t-1} - π̄ | 0.013 |
| ŷ_{EA,t-1} | 0.007 |
| π_{EA,t-1} - π̄_{EA} | -0.004 |
| yH - ȳ_{t-1} | 0.39 |
| Δw_{eff,t-1} | 0.3 |
| û_{t-1} | -0.21 |

**FR-BDF Auxiliary equation for yH - ȳ:**
```
yH - ȳ = -0.49·(1-0.92) + 0.92·(yH-ȳ)(-1) + 0.32·Δw_eff(-1) - 0.08·û(-1) + ε     (R² = 0.91)
```

**FR-BDF Table 4.6.4 — Policy function PV²(yH-ȳ)_{t|t-1} (nested expectation):**

| E-SAT state | FR-BDF coeff |
|-------------|-------------|
| Constant | -0.043 |
| ŷ_{t-1} | -0.052 |
| i_{t-1} - ī | -0.012 |
| π_{t-1} - π̄ | 0.002 |
| ŷ_{EA,t-1} | 0.001 |
| π_{EA,t-1} - π̄_{EA} | -0.001 |
| yH - ȳ_{t-1} | 0.034 |
| PV(yH-ȳ)_{t-1} | -0.12 |
| Δw_{eff,t-1} | 0.029 |
| û_{t-1} | -0.03 |

**AU-PAC Dynamic Auxiliary** (eq_pv_c_aux):
```
pv_c_aux = 0.60·pv_c_aux(-1) + 0.06·yhat_au(-1) - 0.04·i_gap(-1)
```

| Feature | FR-BDF Table 4.6.3 | FR-BDF Table 4.6.4 (PV²) | AU-PAC |
|---------|--------------------|-----------------------------|--------|
| State variables | 9 | 10 | 2 + own lag |
| Own persistence | 0.92 (yH-ȳ aux) | -0.12 (PV lag) | **0.60** |
| Output gap | -0.036 | -0.052 | **0.06** (positive, compensating) |
| Interest rate | -0.085 | -0.012 | **-0.04** |
| Real wage growth | 0.3 / 0.32 | 0.029 | — (absent) |
| Unemployment gap | -0.21 / -0.08 | -0.03 | — (absent) |
| R² (aux eq) | 0.91 | — | N/A |

**Key difference**: FR-BDF uses the most complex auxiliary structure of any PAC equation — a nested PV (expectation of an expectation) with 10 state variables including real wage growth, unemployment gap, and a separate income-output ratio auxiliary. AU-PAC collapses this to 3 coefficients.

---

## 4. Business Investment (dln_ib)

### A. Target Equation

**FR-BDF eq 63:**
```
log(I*) = α₀ + log(Q) - σ·log(rKB) + log(I*/K*)
```

| Coeff | FR-BDF | AU-PAC |
|-------|--------|--------|
| α₀ | 0.016 | — (growth rate form) |
| σ (CES) | 0.53 | **0.53** | Exact |
| I*/K* | historical mean | — |

**AU-PAC growth-rate form** (eq_dln_ib_star_bar):
```
dln_ib_star_bar = 0.06·yhat_au - 0.53·dln_uc_k
```

### B. Short-run PAC Equation

**FR-BDF eq 64 (Table 4.6.9):**
```
Δlog(IB) = β₀·log(I*/I) + β₁Δlog(I)(-1) + β₂Δlog(I)(-2) + PV(Δq̂) - σ·PV(Δlog(r̂_KB)) + (1-β₁-β₂)(Δq̂-σΔlog(r̄_KB)) + β₃(Δq-Δq̄) + ε
```

| Coeff | Symbol | FR-BDF (Table 4.6.9) | AU-PAC | Match? |
|-------|--------|---------------------|--------|--------|
| EC speed | β₀ / b0_ib | 0.085 (0.029) | **0.030** | Lower* |
| AR(1) | β₁ / b1_ib | 0.29 (0.14) | **0.181** | Lower |
| AR(2) | β₂ / b2_ib | 0.2 (0.1) | **0.10** | Lower |
| Accelerator | β₃ / b3_ib | 0.58 (0.36) | **0.191** | Much lower* |
| User cost (ad hoc) | — / b4_ib | — | **-0.03** | Added in AU-PAC |
| Expectations share | ω | — | **0.35** | — |
| Growth neutrality | — | — | **0.369** | — |
| R² | — | 0.52 | N/A | — |

*FR-BDF EC speed (0.085) is nearly 3x AU-PAC (0.030). FR-BDF accelerator (0.58) is 3x AU-PAC (0.191). These may reflect different investment dynamics between France and Australia.

**Note**: FR-BDF uses separate PV expectations for output gap and user cost gap. AU-PAC merges these into a single pac_expectation() + the ad hoc b4_ib*i_gap(-1) term.

### C. E-SAT Auxiliary Equations

**FR-BDF Table 4.6.11 — Policy function PV(Δq̂)_{t|t-1}:**

| E-SAT state | FR-BDF coeff |
|-------------|-------------|
| ŷ_{t-1} | 0.035 |
| i_{t-1} - ī | -0.101 |
| π_{t-1} - π̄ | 0.027 |
| ŷ_{EA,t-1} | 0.015 |
| π_{EA,t-1} - π̄_{EA} | -0.002 |
| r̂_{KB,t-1} | 0 |
| q̂_{t-1} | -0.071 |

**FR-BDF Auxiliary equation for q̂ (output gap for investment):**
```
q̂ = 0.59·q̂(-1) + 0.61·ŷ     (R² = 0.90)
```

**FR-BDF Table 4.6.12 — Policy function PV(Δlog(r̂_KB))_{t|t-1}:**

| E-SAT state | FR-BDF coeff |
|-------------|-------------|
| ŷ_{t-1} | 0 |
| i_{t-1} - ī | 0.24 |
| i_{t-2} - ī | -0.13 |
| π_{t-1} - π̄ | 0 |
| ŷ_{EA,t-1} | 0.012 |
| π_{EA,t-1} - π̄_{EA} | 0.038 |
| r̂_{KB,t-1} | -0.055 |
| q̂_{t-1} | 0 |

**FR-BDF Auxiliary for r̂_KB:**
```
r̂_KB = 4.45·(i-ī)(-1)     (R² = 0.63)
```

**AU-PAC Dynamic Auxiliary** (eq_pv_ib_aux):
```
pv_ib_aux = 0.59·pv_ib_aux(-1) + 0.15·yhat_au(-1) - 0.06·i_gap(-1)
```

| Feature | FR-BDF Table 4.6.11 (output) | FR-BDF Table 4.6.12 (user cost) | AU-PAC |
|---------|-------|------|--------|
| Own persistence | 0.59 (q̂ aux) | -0.055 (r̂_KB) | **0.59** (matches output aux!) |
| Output gap | 0.035 | 0 | **0.15** |
| Interest rate | -0.101 | 0.24 (net: 0.24-0.101=0.139) | **-0.06** |
| R² | 0.90 / 0.63 | — | N/A |

**Key**: FR-BDF has TWO separate auxiliary equations — one for output gap expectations, one for user cost expectations. AU-PAC merges them into one. The persistence (0.59) exactly matches FR-BDF's output gap auxiliary.

---

## 5. Household Investment (dln_ih)

### A. Target Equation

**FR-BDF eq 66 (Table 4.6.14):**
```
log(I*_H) = log(γ₀) + PV(yH) + γ₁(pIH-pC) + γ₂(pSH-pC) + γ₃·log(rLH + δH)
```

| Coeff | FR-BDF (Table 4.6.14) | AU-PAC |
|-------|----------------------|--------|
| γ₀ | 0.005 (0.001) | — |
| γ₁ (new housing price) | -2.2 (0.11) | — (simplified) |
| γ₂ (existing housing) | 0.55 (0.036) | kappa_ph = **0.03** (Tobin's Q proxy) |
| γ₃ (user cost) | -0.071 (0.023) | kappa_mort = **0.048** |
| R² | 0.82 | N/A |

**AU-PAC target growth** (eq_dln_ih_star_bar):
```
dln_ih_star_bar = 0.03·Δ(pv_yh) - 0.048·(i_lh - SS) + 0.03·ph_gap(-1)
```

### B. Short-run PAC Equation

**FR-BDF eq 67 (Table 4.6.15):**
```
Δlog(IH) = β₀·log(I*/I) + β₁Δlog(I)(-1) + PV(Δlog(Î*)) + PV(Δlog(Ī*)) + (1-β₁-ω)Δlog(Ī*) + β₂Δŷ + β₃Δ(pSH-p̄SH) + ε
```

| Coeff | Symbol | FR-BDF (Table 4.6.15) | AU-PAC | Match? |
|-------|--------|----------------------|--------|--------|
| EC speed | β₀ / b0_ih | 0.056 (0.019) | **0.049** | Similar |
| AR(1) | β₁ / b1_ih | 0.62 (0.069) | **0.21** | Much lower* |
| Output gap | β₂ / b3_ih | 0.34 (0.20) | **0.12** | Lower |
| Housing price gap | β₃ | 0.32 (0.09) | — (in target, not short-run) |
| Mortgage rate | — / b4_ih | — | **-0.05** | AU-specific addition |
| AR(2) | — / b2_ih | — | **0.08** | Added in AU-PAC |
| Expectations ω | — / omega_ih | 0.36 | **0.30** | Similar |
| Growth neutrality | — | 0.02 | **0.41** | Different* |
| R² | — | 0.87 | N/A | — |

*FR-BDF AR(1) = 0.62 is very high (strong persistence). AU-PAC much lower at 0.21 with an added AR(2) = 0.08. FR-BDF growth neutrality is tiny (0.02) because β₁+ω = 0.62+0.36 = 0.98; AU-PAC is much larger because b₁+b₂+ω = 0.21+0.08+0.30 = 0.59.

### C. E-SAT Auxiliary Equations

**FR-BDF Table 4.6.16 — Policy function PV(Δlog(Î*_H))_{t|t-1}:**

| E-SAT state | FR-BDF coeff |
|-------------|-------------|
| ŷ_{t-1} | 0.029 |
| i_{t-1} - ī | -0.15 |
| π_{t-1} - π̄ | 0.035 |
| ŷ_{EA,t-1} | 0.004 |
| π_{EA,t-1} - π̄_{EA} | -0.012 |
| log(Î*_H)_{t-1} | -0.044 |

**FR-BDF Auxiliary equation:**
```
log(Î*_H) = 0.38·ŷ(-1) - 0.89·(i-ī)(-1) + 0.49·(π-π̄)(-1) + 0.71·log(Î*_H)(-1) + ε     (R² = 0.62)
```

**AU-PAC Dynamic Auxiliary** (eq_pv_ih_aux):
```
pv_ih_aux = 0.71·pv_ih_aux(-1) + 0.08·yhat_au(-1) - 0.08·i_gap(-1)
```

| Feature | FR-BDF aux eq | FR-BDF policy fn | AU-PAC |
|---------|-------------|-----------------|--------|
| Own persistence | **0.71** | -0.044 (policy) | **0.71** (exact match!) |
| Output gap | **0.38** (0.26) | 0.029 | **0.08** |
| Interest rate | **-0.89** (0.96) | -0.15 | **-0.08** |
| Inflation gap | **0.49** (0.54) | 0.035 | — (absent) |
| R² | 0.62 | — | N/A |

**Note**: AU-PAC persistence (0.71) exactly matches FR-BDF auxiliary. Interest rate sensitivity is much smaller (0.08 vs 0.89), but FR-BDF's estimate has a huge standard error (0.96), making it not significant.

---

## 6. Wage Phillips Curve (supporting equation for all PAC blocks)

**FR-BDF eq 52 (Table 4.5.3):**
```
πW = β₀ + [Δē+π̄] + β₁(πC(-1)-π̄) + β₂[πW(-1)-Δē-π̄-β₁(πC(-2)-π̄)] + β₃Δ₄(w^m-e-π̄) + β₄·PV(û) + ε
```

**AU-PAC** (eq_pi_w):
```
pi_w = lambda_w·pi_w(-1) + gamma_w·pi_au + kappa_w·pv_u_gap + (1-lambda_w-gamma_w)·pibar_au + (1-lambda_w)·dln_prod + eps_w
```

| Coeff | Symbol | FR-BDF (Table 4.5.3) | AU-PAC | Match? |
|-------|--------|---------------------|--------|--------|
| Constant | β₀ | -5×10⁻⁴ (4×10⁻⁴) | — | Dropped |
| CPI indexation | β₁ | 0.24 (0.1) | gamma_w = **0.15** | Lower |
| Wage persistence | β₂ | 0.32 (0.1) | lambda_w = **0.247** | Lower |
| Minimum wage | β₃ | 0.22 (0.1) | — | Dropped (not relevant for AU) |
| Unemployment PV | β₄ | -0.32 (0.2) | kappa_w = **0.238** | Opposite sign convention |
| R² | — | 0.18 | N/A | — |

**Sign convention note**: FR-BDF β₄ = -0.32 because higher unemployment → lower wages (negative). AU-PAC kappa_w = +0.238 with pv_u_gap defined as negative when unemployment is high.

---

## Summary: Coefficient Similarity Matrix

| Equation | EC speed match | AR lag match | Ad hoc match | Expectations match | Auxiliary match |
|----------|-------------|-------------|-------------|-------------------|----------------|
| VA price | **EXACT** (0.06) | **EXACT** (0.50) | **EXACT** (0.09) | Similar (ω=0.46) | Simplified (2 vs 8 states) |
| Employment | Lower (0.04 vs 0.06) | Much different (0.30 vs 0.87) | Similar (0.12 vs 0.15) | Similar (ω=0.30 vs 0.26) | rho matches (0.67) |
| Consumption | Lower (0.06 vs 0.12) | Different sign (0.15 vs -0.08) | Lower (0.14 vs 0.26) | — | Very simplified (2 vs 10 states) |
| Business inv | Lower (0.03 vs 0.085) | Lower (0.18 vs 0.29) | Lower (0.19 vs 0.58) | Similar (ω=0.35) | rho matches (0.59) |
| Housing inv | Similar (0.049 vs 0.056) | Much lower (0.21 vs 0.62) | Lower (0.12 vs 0.34) | Similar (ω=0.30 vs 0.36) | rho matches (0.71) |

## Estimation Status

| Component | FR-BDF | AU-PAC |
|-----------|--------|--------|
| **E-SAT core** | Bayesian (50,000 draws, 2 chains) | Bayesian posteriors adopted |
| **PAC target equations** | OLS, 1995Q1-2017Q4 | Calibrated from FR-BDF |
| **PAC short-run equations** | Iterative OLS with E-SAT | Calibrated from FR-BDF |
| **E-SAT auxiliary equations** | OLS, separate estimation | Calibrated from FR-BDF |
| **Auxiliary policy functions** | Matrix algebra (eqs 14-17) | Dynamic AR(1) approximation |
| **Production function** | Grid search calibration | Calibrated from FR-BDF |

**Next step**: Re-estimate all AU-PAC parameters with Australian data using `pac.estimate.iterative_ols()` for the short-run equations and Bayesian MCMC for the E-SAT core.
