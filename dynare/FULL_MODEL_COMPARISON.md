# AU-PAC vs FR-BDF: Full Equation-by-Equation Comparison

## Executive Summary

AU-PAC implements FR-BDF's core structure faithfully but uses a simplified approach for the backward/forward expectation wedge. The current `a_X_y * yhat_au(-1)` correction terms are **static** (no persistence), while FR-BDF's auxiliary equations are **dynamic AR(1) processes** with persistence and multiple E-SAT state variables. This explains why the three-regime IRFs differ but by less than expected.

---

## 1. E-SAT Core Block (FR-BDF Section 3.1)

### FR-BDF E-SAT (8 equations):
```
IS curve:     (1-λ_q L)ŷ_t = -σ_q(i_{t-1} - π_{t-1} - ī_{t-1} + π̄_{t-1}) + δ_q ŷ_{EA,t} + ε_q
Phillips:     (1-λ_π L)(π_t - π̄_t) = κ_π ŷ_{t-1} + ε_π
Taylor:       (1-λ_i L)(i_t - ī_t) = (1-λ_i)(α_i(π_{EA,t-1} - π̄_{t-1}) + β_i ŷ_{EA,t-1}) + ε_i
US IS:        (1-λ_{q,EA} L)ŷ_{EA,t} = -σ_{q,EA}(i_{t-1} - π_{EA,t-1} - ...) + ε_{q,EA}
US Phillips:  (1-λ_{π,EA} L)(π_{EA,t} - π̄_{EA,t}) = κ_{π,EA} ŷ_{EA,t-1} + ε_{π,EA}
3 anchors:    AR(1) for ī, π̄, π̄_{EA}
```

### AU-PAC E-SAT (8 equations, same structure):
```
eq_au_is:     yhat_au = delta*yhat_us + lambda_q*yhat_au(-1) - sigma_q*(i_gap(-1) - pi_au_gap(-1)) + lambda_dom*yhat_dom + eps_q
eq_taylor:    i_gap = lambda_i*i_gap(-1) + (1-lambda_i)*(alpha_i*pi_au_gap(-1) + beta_i*yhat_au(-1)) + eps_i
eq_au_phil:   pi_au_gap = lambda_pi*pi_au_gap(-1) + kappa_pi*yhat_au(-1) + eps_pi
eq_us_is:     yhat_us = lambda_q_us*yhat_us(-1) + eps_q_us
eq_us_phil:   pi_us_gap = lambda_pi_us*pi_us_gap(-1) + kappa_pi_us*yhat_us(-1) + eps_pi_us
3 anchors:    AR(1) for ibar, pibar_au, pibar_us
```

### Differences:
| Feature | FR-BDF | AU-PAC | Impact |
|---------|--------|--------|--------|
| IS curve | Euro area (EA) spillover | US spillover + domestic demand feedback (lambda_dom) | AU-specific: demand-side feedback loop |
| Taylor rule | Reacts to EA inflation + EA output gap | Reacts to AU inflation + AU output gap | AU has own central bank (RBA) |
| Foreign bloc | Euro area (endogenous in E-SAT) | US (simplified: AR(1) for yhat_us) | Lower foreign feedback |
| US IS curve | Full IS with real rate | Simplified AR(1) | AU-PAC: less rich US dynamics |

**Assessment**: Core structure matches. Key AU-specific addition is `lambda_dom * yhat_dom` (demand feedback), reflecting that Australia has its own central bank unlike France in the eurozone.

---

## 2. VA Price Block (FR-BDF Section 4.4)

### 2.1 Target (FR-BDF eq 38 / factor price frontier)

**FR-BDF**:
```
p*_Q = c_0 + σ/(1-σ)*log(1-α) - 1/(1-σ)*log[1 - α^σ * (Q'_K/γ)^{1-σ}] + log(W̃/(Ē*H))
```
A nonlinear function of: trend return on capital (Q'_K), total labor cost (W̃), trend efficiency (Ē), hours (H).

**AU-PAC**:
```
piQ_star = rho_pQ_star * piQ_star(-1) + gamma_ulc * dln_ulc + gamma_uck * dln_uc_k + (1-rho_pQ_star-gamma_ulc) * pibar_au
```
A linear growth-rate approximation: ULC growth + user cost growth.

**Difference**: AU-PAC linearizes the FR-BDF nonlinear price frontier into growth rates. The level form is lost. This is a standard simplification for quarterly models but loses the nonlinear capital-return interaction.

### 2.2 Short-run PAC (FR-BDF eq 44)

**FR-BDF**:
```
π_Q = PV(Δπ̂*_Q)_{t|t-1} + β_0(p*_{Q,t-1} - p_{Q,t-1}) + β_1 π_{Q,t-1} + β_2 ŷ_t + (1-β_1-ω)π̄*_{Q,t-1} + ε
```

**AU-PAC (hybrid/VAR)**:
```
diff(pQ_level) = b0_pQ*(piQ_star_l(-1) - pQ_level(-1)) + b1_pQ*diff(pQ_level(-1))
               + pac_expectation(pac_pQ) + b2_pQ*yhat_au + a_pQ_y*yhat_au(-1) + eps_pQ
```

**Term-by-term comparison**:

| FR-BDF term | AU-PAC term | Match? | Notes |
|-------------|------------|--------|-------|
| β_0(p*-p)_{t-1} | b0_pQ*(piQ_star_l(-1)-pQ_level(-1)) | YES | EC term |
| β_1 π_{Q,t-1} | b1_pQ*diff(pQ_level(-1)) | YES | AR(1) lag |
| PV(Δπ̂*_Q)_{t\|t-1} | pac_expectation(pac_pQ) | PARTIAL | See below |
| β_2 ŷ_t | b2_pQ*yhat_au | YES | Ad hoc demand |
| (1-β_1-ω)π̄*_{t-1} | [in pac_expectation growth term] | YES | Growth neutrality |
| — | a_pQ_y*yhat_au(-1) | ADDED | E-SAT auxiliary correction |

**Key difference in expectations**:
- FR-BDF: `PV(Δπ̂*_Q)_{t|t-1} = k_0 * Z_{t-1}` where k_0 is a row vector from the FULL E-SAT companion matrix (8+ dimensions). This means the expectation depends on ALL E-SAT state variables.
- AU-PAC: `pac_expectation(pac_pQ)` uses the 2-equation TCM companion matrix (2x2). The `a_pQ_y*yhat_au(-1)` term adds ONE E-SAT state variable (output gap) to approximate the richer policy function.

**What's missing**: FR-BDF's k_0 vector has coefficients on yhat, i_gap, pi_gap, yhat_EA, pi_EA, and all auxiliary variables. AU-PAC only captures the yhat channel via a_pQ_y. Missing channels: interest rate gap, inflation gap, US variables.

### 2.3 E-SAT Auxiliary Equation (FR-BDF Table 4.4.4)

**FR-BDF auxiliary for VA price target gap**:
```
(1-ρL)(π̃_{W,t} - Δē_t - π̄*_{Q,t}) = β_0 û_t + ε_t     // Phillips curve auxiliary
û_t = β_0(ŷ_{t-1} - ρŷ_{t-2}) + ρû_{t-1} + ε_t          // Okun's law auxiliary
```
The policy function (Table 4.4.4) depends on: ŷ_{t-1}, i_{t-1}-ī, π_{t-1}-π̄, ŷ_{EA,t-1}, π_{EA,t-1}-π̄_{EA}, û_{t-1}, π̃_{W,t-1}, π̄*_{Q,t-1}.

**AU-PAC simplified auxiliary**:
```
a_pQ_y * yhat_au(-1)    // Only output gap, no persistence, no other states
```

**Gap**: The FR-BDF auxiliary has 8+ state variable dependencies with AR(1) persistence. AU-PAC captures only the output gap channel with no dynamics. This is the main source of too-similar IRFs.

---

## 3. Employment Block (FR-BDF Section 4.5)

### 3.1 Wage Phillips Curve (FR-BDF eq 52)

**FR-BDF**:
```
π_W = β_0 + [Δē+π̄] + β_1(π_{C,t-1}-π̄) + β_2[π_{W,t-1}-Δē-π̄-β_1(π_{C,t-2}-π̄)]
    + β_3(Δ_4(w^m_{t-1}-e_{t-1})-π̄) + β_4 PV(û)_{t-1|t-2} + ε
```

**AU-PAC**:
```
pi_w = lambda_w*pi_w(-1) + gamma_w*pi_au + kappa_w*pv_u_gap + (1-lambda_w-gamma_w)*pibar_au + (1-lambda_w)*dln_prod + eps_w
```

**Differences**:
| Feature | FR-BDF | AU-PAC | Impact |
|---------|--------|--------|--------|
| Indexation | β_1(π_{C,t-1}-π̄) + β_2[complex lag] | gamma_w*pi_au (current CPI) | Simplified: no double-indexation |
| Minimum wage | β_3(Δ_4(w^m-e)-π̄) | ABSENT | Not relevant for AU |
| Unemployment PV | β_4 PV(û)_{t-1\|t-2} (lagged info set) | kappa_w*pv_u_gap (current) | AU-PAC uses current, not lagged |
| Productivity | Implicit in Δē | (1-lambda_w)*dln_prod | Explicit efficiency trend |

**Assessment**: AU-PAC simplifies FR-BDF's complex indexation structure but captures the core Phillips curve mechanism. The minimum wage term is appropriately dropped for Australia. The key structural difference is that FR-BDF uses the unemployment PV at t-1|t-2 (one period lagged information set) while AU-PAC uses the current PV.

### 3.2 Employment PAC (FR-BDF eq 56, 4th-order)

**FR-BDF**:
```
Δn_S = β_0(n*_{S,t-1}-n_{S,t-1}) + PV(Δn̄*_S)_{t|t-1} + PV(Δn̂*_S)_{t|t-1}
     + β_1Δn_{t-1}+β_2Δn_{t-2}+β_3Δn_{t-3} + (1-Σβ_k-ω)Δn̄*_S + β_4Δq̂_t + ε
```

**AU-PAC (hybrid/VAR)**:
```
diff(ln_n_level) = b0_n*(n_star_l(-1)-ln_n_level(-1)) + b1_n*diff(-1) + b2_n*diff(-2) + b3_n*diff(-3) + b4_n*diff(-4)
                 + pac_expectation(pac_n) + b5_n*yhat_au + a_n_y*yhat_au(-1) + eps_n
```

**Differences**:
| Feature | FR-BDF | AU-PAC | Impact |
|---------|--------|--------|--------|
| PAC order | 3 AR lags (β_1,β_2,β_3) | 4 AR lags (b1-b4) | AU adds 4th lag |
| Expectations | PV(Δn̄*)+PV(Δn̂*) decomposition | pac_expectation(pac_n) + a_n_y*yhat(-1) | Different implementation |
| Ad hoc term | β_4*Δq̂ (output gap change) | b5_n*yhat_au (output gap level) | Level vs change |
| E-SAT auxiliary | Table 4.5.7: 6 state variables | a_n_y*yhat_au(-1) only | Much simpler |

### 3.3 E-SAT Auxiliary for Employment (FR-BDF Table 4.5.7)

**FR-BDF policy function for PV(Δn̂*_S)_{t|t-1}**:
| State variable | Coefficient |
|---|---|
| ŷ_{t-1} | 0.02 |
| i_{t-1}-ī | -0.03 |
| π_{t-1}-π̄ | 0.02 |
| ŷ_{EA,t-1} | 0.01 |
| π_{EA,t-1}-π̄_{EA} | 0.00 |
| n̂*_{S,t-1} | -0.05 |

**AU-PAC simplified auxiliary**:
```
a_n_y * yhat_au(-1) = 0.12 * yhat_au(-1)
```

**Gap**: FR-BDF uses 6 state variables (output, interest rate, inflation, EA output, EA inflation, employment gap itself). The employment gap's own lag (-0.05) creates persistence in the auxiliary. AU-PAC uses only the output gap with no persistence. The 0.12 coefficient is much larger than FR-BDF's 0.02 — this compensates for the missing states but changes the dynamics.

---

## 4. Demand Block

### 4.1 Consumption (FR-BDF Section 4.6.1, eq 61)

**FR-BDF**:
```
Δc = β_0(c*-c) + β_1*Δc(-1) + PV²(y_H-ȳ)_{t|t-1} + α_1[PV(r_LH)-PV(ī-π̄)]
   + (1-β_1)(Δȳ-Δ(y_H-ȳ)) + β_2*Δŷ + β_3*Δ(r_LH-(ī-π̄)) + β_4*δ_prime + ε
```

**AU-PAC (hybrid/VAR)**:
```
diff(ln_c_level) = b0_c*(c_star_l(-1)-ln_c_level(-1)) + b1_c*diff(-1)
                 + pac_expectation(pac_c) + b2_c*i_gap(-1) + b3_c*yhat_au + a_c_y*yhat_au(-1) + eps_c
```

**Major simplifications**:
| FR-BDF term | AU-PAC | Present? |
|-------------|--------|----------|
| PV²(y_H-ȳ) — expectation of expectation (permanent income) | pac_expectation(pac_c) | Partial — PAC captures target dynamics but not the nested PV structure |
| α_1[PV(r_LH)-PV(ī-π̄)] — expected interest rate gap | b2_c*i_gap(-1) | Simplified: current gap vs PV of future gaps |
| β_2*Δŷ (hand-to-mouth) | b3_c*yhat_au | Level vs change |
| β_3*Δ(r_LH-(ī-π̄)) — interest rate change | ABSENT | Missing wealth channel |
| β_4*δ_prime (car scrappage dummy) | ABSENT | France-specific |
| PV²(y_H-ȳ) auxiliary — Table 4.6.3-4.6.4 | a_c_y*yhat_au(-1) | Very simplified |

**Assessment**: The consumption equation is the most simplified relative to FR-BDF. The key missing feature is the **nested PV expectation** (PV² — expectation of an expectation of permanent income). FR-BDF's auxiliary equations (Tables 4.6.3-4.6.4) have 9+ state variables including income-output ratio, real efficient wage, and unemployment gap. AU-PAC captures this with a single output gap term.

### 4.2 Business Investment (FR-BDF Section 4.6.2, eq 64)

**FR-BDF**:
```
Δlog I_B = β_0*log(I*/I) + β_1*Δlog I(-1) + β_2*Δlog I(-2)
         + PV(Δq̂)_{t|t-1} - σ*PV(Δlog r̂_KB)_{t|t-1}
         + (1-β_1-β_2)(Δq̂(-1) - σΔlog r̄_KB(-1)) + β_3(Δq(-1)-Δq̄(-1)) + ε
```

**AU-PAC (hybrid/VAR)**:
```
diff(ln_ib_level) = b0_ib*(ib_star_l(-1)-ln_ib_level(-1)) + b1_ib*diff(-1) + b2_ib*diff(-2)
                  + pac_expectation(pac_ib) + b3_ib*yhat_au + b4_ib*i_gap(-1) + a_ib_y*yhat_au(-1) + eps_ib
```

**Differences**:
| Feature | FR-BDF | AU-PAC | Impact |
|---------|--------|--------|--------|
| Expectations | Separate PV(Δq̂) and PV(Δlog r̂_KB) | Single pac_expectation(pac_ib) | Merged into one |
| User cost PV | σ*PV(Δlog r̂_KB) with full E-SAT state | b4_ib*i_gap(-1) | Static vs dynamic |
| E-SAT auxiliary | Table 4.6.11-12: output gap + user cost gap | a_ib_y*yhat_au(-1) | Missing user cost state |

---

## 5. The Core Issue: Why IRFs Are Too Similar

### Current a_X_y implementation

The `a_X_y * yhat_au(-1)` terms are **static additive corrections**. They have:
- No persistence (no AR(1) on the correction term itself)
- Only one state variable (yhat_au)
- No interaction with interest rates, inflation, or own lagged gaps

### What FR-BDF's E-SAT auxiliaries actually do

FR-BDF's auxiliary equations (Tables 4.4.4, 4.5.7, 4.6.3, 4.6.11-12) are **dynamic AR(1) processes** with:
- Own-lag persistence (typically 0.6-0.95)
- Multiple E-SAT state variables (output gap, interest rate gap, inflation gap, foreign variables)
- Own-gap feedback (e.g., employment gap affects future employment expectations)

The policy function for each auxiliary variable is:
```
PV(ΔX̂*)_{t|t-1} = k_0 * Z_{t-1}
```
where k_0 is a row vector with dimension = number of E-SAT + auxiliary variables (typically 10-12 elements), and Z_{t-1} includes ALL lagged state variables.

### Quantifying the gap

For a monetary policy shock (eps_i = +1 s.d.):

**FR-BDF auxiliary policy function response** (approx from Table 4.4.4):
- PV(Δπ̂*_Q): depends on ŷ(-1) with coeff -0.0015, i_gap(-1) with coeff -0.0034, π_gap(-1) with coeff 0.0009
- These generate a complex, multi-channel expectation correction

**AU-PAC a_pQ_y response**:
- a_pQ_y * yhat_au(-1) = 0.03 * (-0.0002) = -0.000006 (Q1)
- a_pQ_y * yhat_au(-1) = 0.03 * (-0.0195) = -0.000585 (Q4)

The interest rate channel (i_gap) is completely missing from AU-PAC's auxiliary correction but is the **primary channel** through which monetary policy affects expectations in FR-BDF.

### Proposed fix to make IRFs more different

Replace the static `a_X_y * yhat_au(-1)` with dynamic AR(1) auxiliary variables that depend on multiple E-SAT states:

```dynare
// New variable: backward auxiliary expectation for VA price
pv_piQ_aux = rho_pQ_aux * pv_piQ_aux(-1) + a_pQ_y * yhat_au(-1) + a_pQ_i * i_gap(-1) + a_pQ_pi * pi_au_gap(-1);

// In PAC equation: replace a_pQ_y*yhat_au(-1) with pv_piQ_aux
diff(pQ_level) = ... + pv_piQ_aux + ...
```

This adds:
1. **Persistence** via own AR(1) lag (rho_pQ_aux ~ 0.7)
2. **Interest rate channel** (a_pQ_i ~ -0.03)
3. **Inflation channel** (a_pQ_pi ~ 0.01)

These three additions would substantially amplify the backward/forward wedge, especially for monetary policy shocks where the interest rate channel dominates.

---

## 6. Summary: Changes Made to FR-BDF and Why

| Change | What | Why |
|--------|------|-----|
| US replaces Euro Area | Foreign bloc is US instead of EA | Australia trades primarily with Asia/US |
| Endogenous Taylor rule | RBA reacts to AU inflation + output | Australia has own central bank |
| lambda_dom feedback | IS curve includes domestic demand | Closes Keynesian multiplier loop |
| Variable-rate mortgage | b4_ih = -0.05 (strongest rate channel) | AU mortgage market structure |
| Commodity channel | dln_pcom in exports + deflators | AU commodity dependence |
| Import-adjusted demand | IAD replaces yhat_au in imports | Better import composition modeling |
| Linearized price frontier | Growth-rate form vs level form | Simplification for quarterly model |
| Simplified auxiliaries | a_X_y * yhat(-1) vs full E-SAT policy functions | Implementation simplicity; should be enriched |
| Nested PV dropped | No PV²(y_H) in consumption | Dynare PAC limitation |
| Minimum wage dropped | Not in wage Phillips curve | Not relevant for AU |
| Deflator import channels | beta_pc_m, beta_pib_m, etc. added | AU import content of demand |
