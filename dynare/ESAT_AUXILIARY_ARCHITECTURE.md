# How FR-BDF E-SAT Auxiliary Equations Actually Work

## The Key Insight (FR-BDF Section 3.1.1, pages 19-21)

The auxiliary equations are **appended to the E-SAT VAR system**, enlarging the state vector and companion matrix. They are NOT separate additive terms.

### FR-BDF Architecture

**Step 1**: Start with E-SAT core (8 equations, state vector Z of dimension 9 including constant):
```
Z = [1, ŷ, i, π_Q, ŷ_EA, π_EA, ī, π̄, π̄_EA]
```
Companion matrix H is 9×9. Reduced form: Z_t = H · Z_{t-1}

**Step 2**: For each PAC equation that needs expectations, ADD auxiliary equations to the system:
```
// Example: employment auxiliary (Table 4.5.7, eq 57)
(1 - 0.67·L) n̂* = 0.30·ŷ(-1) + 0.07·(i-ī)(-1) + 0.16·(π-π̄)(-1)

// Plus trend auxiliary
Δn̄* = Δn̄*(-1)
```

**Step 3**: The state vector GROWS:
```
Z = [1, ŷ, i, π_Q, ŷ_EA, π_EA, ī, π̄, π̄_EA, n̂*, Δn̄*]
```
Now 11 elements. Companion matrix H becomes 11×11.

**Step 4**: The additional rows of B (transition matrix) encode the auxiliary dynamics:
```
B_10 = [0, 0.30, 0.07, 0.16, 0, 0, -0.07, -0.16, 0, 0.67, 0]
B_11 = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1]
```

**Step 5**: The additional COLUMNS (above rows 10-11) of A and B are ZEROS:
```
// Core E-SAT variables are NOT affected by auxiliaries
// This is block-recursive: core → auxiliary, not auxiliary → core
```

**Step 6**: Compute h-vectors from the ENLARGED companion matrix:
```
k_0 = A(1)·A(β) · [(ι'_m · I_m) ⊗ H'] · [I_{nm} - (G ⊗ H')]^{-1} · [ι_m ⊗ ι_{k0}]
```
where H is now the 11×11 matrix. The k_0 vector has 11 elements:
```
PV(Δn̂*)_{t|t-1} = k_0[1]·1 + k_0[2]·ŷ_{t-1} + k_0[3]·i_{t-1} + ... + k_0[10]·n̂*_{t-1} + k_0[11]·Δn̄*_{t-1}
```

### What This Means

The h-vector `k_0` is a **SINGLE** linear combination of ALL state variables, where the weights are jointly determined by:
1. The PAC polynomial (EC speed b0, AR lags b1-b4, discount factor β)
2. The E-SAT VAR dynamics (IS curve, Phillips, Taylor rule parameters)
3. The auxiliary equation coefficients (0.30, 0.07, 0.16, 0.67)

The PAC polynomial determines HOW the companion matrix eigenvalues interact with the discount factor to weight future states. A high b0 (fast EC) means the agent cares more about near-term states; a high discount factor means distant states matter more.

## Our Current Implementation (WRONG)

We have TWO separate, independent terms:

```dynare
// Term 1: pac_expectation() from 2×2 TCM companion matrix
pac_expectation(pac_n)  // h-vector depends only on b0_n, b1_n, beta_pac
                        // Does NOT see E-SAT state variables

// Term 2: separate additive AR(1) auxiliary
+ pv_n_aux              // AR(1) with rho=0.67, a_y=0.12, a_i=-0.03, a_pi=0.05
                        // Persistence determined by rho_n_aux, NOT by PAC polynomial
```

### Why This Is Wrong

1. **The PAC polynomial doesn't influence the auxiliary weights.** In FR-BDF, the PAC adjustment cost structure (b0, b1, β) determines how much weight each E-SAT state gets in expectations. In our implementation, `pv_n_aux` has its own AR(1) persistence (rho_n_aux=0.67) that's independent of the PAC polynomial.

2. **The auxiliary persistence is double-counted.** In FR-BDF, the auxiliary equation's AR(1) coefficient (0.67) is INSIDE the companion matrix H, and the PAC polynomial interacts with it via the G⊗H' Kronecker product. In our implementation, the 0.67 shows up as rho_n_aux AND the pac_expectation has its own persistence from the TCM h-vector.

3. **The weights are additive instead of multiplicative.** FR-BDF's k_0 vector has weights that are products of PAC and VAR parameters. Our implementation adds pac_expectation (PAC-only weights) + pv_n_aux (VAR-only weights). The interaction terms are missing.

## The Correct Fix

### Option A: Enlarge the TCMs (best but Dynare-constrained)

Embed the E-SAT core + auxiliary equations into each trend_component_model. This is what we tried before and failed because TCM requires strict EC structure.

### Option B: Use var_model instead of trend_component_model

Dynare's `pac_model` can reference a `var_model` as the auxiliary model. A `var_model` has no EC structure constraint — it's pure VAR(p). This would allow us to embed the full E-SAT core + auxiliary equations as a VAR system.

The `var_model` approach would:
1. Define a VAR with ~11 equations (8 E-SAT core + 2 auxiliary per PAC equation)
2. Use `pac_model(auxiliary_model_name = esat_var, ...)` 
3. Dynare would compute h-vectors from the full 11×11 companion matrix
4. The h-vectors would JOINTLY depend on PAC polynomial + E-SAT dynamics + auxiliary coefficients

### Option C: Compute h-vectors manually in MATLAB (most accurate)

1. Build the enlarged E-SAT companion matrix H (11×11) in MATLAB
2. Compute k_0 and k_1 using the PAC formula (eq 14-15)
3. Hard-code the resulting k_0 vector as parameter values in the .mod file
4. Replace pac_expectation() with `k_0[1]*1 + k_0[2]*yhat(-1) + k_0[3]*i_gap(-1) + ...`

This exactly matches FR-BDF but requires manual matrix computation whenever parameters change.

### Option D: Keep current approach as approximation (pragmatic)

Accept that our pv_X_aux + pac_expectation() is an approximation. The main deficiency is that the PAC polynomial doesn't influence the auxiliary weights. This matters most when the PAC order m > 1 (employment has 4th-order costs), because higher-order adjustment costs change the effective discount rates for distant states.

For 1st-order PAC equations (VA price, consumption), the approximation is quite good because the effective discount is simply β (0.98), close to the auxiliary's own persistence.

## Recommendation

**Option B (var_model)** is the most promising if Dynare supports it for our equation structure. This preserves the native pac_expectation() machinery while using the correct enlarged companion matrix.

**Option C (manual h-vectors)** is the most accurate fallback if var_model doesn't work.

**Option D (current)** is acceptable for now as a well-documented approximation, especially since we plan to re-estimate all parameters with Australian data anyway.
