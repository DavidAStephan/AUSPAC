# PAC_BI_AU_EXPLORATION.md — exhaustive notes on AU business inv vs wp1044 PAC

**Purpose**: future-self reminder of EVERYTHING we tried to make AU business
investment fit the wp1044 PAC structural restriction (PV terms at coef=+1
for VA-target, coef=−σ for user-cost-target), why nothing works, and the
path forward.

**Status**: Phase L2 P1c complete. 6 specification variants tested across
8 commits (`78d7c41`, `b01d4d1`, prior P1c series). No strict-PAC variant
delivers a positive R² on raw AU dln_ib. The wp1044 structural restriction
is unambiguously **rejected by AU business investment data**.

**Date**: 2026-05-26, end of session.

---

## 1. The structural problem in one paragraph

wp1044 Eq 46 derives the business-investment PAC equation from a
quadratic cost-minimization problem over forward-looking expectations.
The first-order condition implies a coefficient = 1 on
$\mathrm{PV}(\Delta\hat q)$ and coefficient = $-\sigma$ on
$\mathrm{PV}(\Delta\log\hat r_{KB})$. These are **structural identities**
of the model, not estimated parameters. When we estimate the AU BI
equation with the wp1044 spec, free-estimated PV coefficients on AU data
come out near zero or with the **wrong sign**. The PV structural
restrictions are statistically rejected. Any attempt to IMPOSE them at
their wp1044 values forces a level/scale wedge between fitted and
observed dln_ib that no amount of dummies, trends, terms-of-trade
regressors, or target-variable substitution can close. The wedge is
mechanical: if PV is wrong, $X\hat\beta + \text{PV terms}$ doesn't equal
dln_ib regardless of how well $\hat\beta$ fits the
PV-residualized LHS.

## 2. What "coef=+1 on PV" means structurally

From wp736 §3 (PAC framework derivation, unchanged in wp1044):

Agent minimizes
$$\sum_{h=0}^\infty \beta^h\left[c_y(y_{t+h}-y^*_{t+h})^2 + c_\Delta(\Delta y_{t+h})^2\right]$$

FOC manipulation gives:
$$\Delta y_t = a_0(y^*_{t-1}-y_{t-1}) + \sum a_k\Delta y_{t-k} + \sum d_i\Delta y^*_{t+i}$$

where the coefficients $d_i$ have closed-form expression
$d_i = \frac{c_y}{c_y+c_\Delta}\chi^i$ with $\chi$ = smallest stable root of
the characteristic polynomial. The forward sum can be written as a PV
operator on the state via the VAR companion matrix, and
**$\sum d_i$ normalizes such that the coefficient on
$\mathrm{PV}(\Delta y^*)$ in the regression is structurally = 1**.

If you estimate this coefficient and get a value ≠ 1 (or wrong sign),
the underlying optimization is rejected. Three immediate consequences:

- **Not RE / DSGE-consistent**: the equation isn't derived from
  optimization. Becomes reduced-form.
- **Lucas critique applies**: estimated relationship is policy-regime
  dependent.
- **No balanced growth path in steady state**: variable doesn't track
  target's long-run growth rate.

For an IRF / counterfactual project (which AUSPAC is), having coef ≠ 1
on PV means the IRFs through the expectation channel are mechanically
wrong. So we want coef=1 to hold, or to find some way to validate it
structurally.

## 3. Variants tested

All variants on the same 122-obs sample (1993Q2–2023Q3), AU
au_gfcf_nondwelling as dln_ib LHS, with wp1044's σ_ces = 0.5366. Full
wp1044 PAC ingredients: ECM on $(I^*_B/I_B)$, depth-2 lags, 4 PV terms
$(+\mathrm{PV}(\Delta\hat q) + \mathrm{PV}(\Delta\bar q)
- \sigma\mathrm{PV}(\Delta\log\hat r_{KB})
- \sigma\mathrm{PV}(\Delta\log\bar r_{KB}))$, derived growth-neutrality
$(1-\beta_1-\beta_2-\omega)(\Delta\bar q_{t-1} + \Delta\log\bar r_{KB,t-1})$,
$\beta_3$ on synthetic df gap (= c + h_inv + exports), ω=0.35 calibrated.

Variant labels match the per-block script names in `data/pac_blocks/`.

| Variant | Spec | R² (raw) | Verdict |
|---|---|---|---|
| baseline (`estimate_pac_business_inv.m`) | strict wp1044 PAC | 0.09 | Clamps hit; barely any signal |
| v1 (`estimate_pac_business_inv_au.m`) | strict PAC + 10 AU dummies (GST, GFC, mining, COVID) | 0.11 | Dummies don't penetrate over-fit PAC structure |
| v2 (`estimate_pac_business_inv_au_v2.m`) | pre-residualize dummies, then PAC on residuals | −23.7 | Two-stage approach inconsistent; PV depends on un-cleaned VAR |
| v3-A (`estimate_pac_business_inv_au_v3.m`, Variant A) | PV regressors with FREE coefficients + dummies | **0.53** | Best fit; **PV(Δq̂) coef = −5.03 (NOT +1) — PAC rejected** |
| v3-B | strict PAC + dummies, single shot | −2.20 | Single-shot doesn't fix the wedge |
| v3-C | strict PAC + dummies, iterative, looser clamps | −67 | Diverges; b_1, b_2 hit clamps |
| v4 (`estimate_pac_business_inv_au_v4.m`) | combined PV at coef=+1 (sum) + dummies | −33 | Weaker structural restriction still fails |
| v5 (`estimate_pac_business_inv_au_v5.m`) | strict PAC + dummies + ToT + 3-segment piecewise trends | −10.7 | R²_adj=0.73 but raw R²=−10.7; wedge persists |
| v6 (`estimate_pac_business_inv_au_v6_tot.m`) | **Option 2: replace q (market VA) with q_AU (ToT)**, strict PAC + dummies | −39.1 | Even with commodity-augmented target, strict PAC fails |
| wp736 (`estimate_pac_business_inv_wp736.m`) | wp736 Eq 64 (2019 simpler 2-PV form) + dummies | −0.75 | The pre-COVID original spec also fails on AU |

### Key diagnostic from v3-A (PV regressors free)

When PV terms are estimated as free OLS regressors on AU data:
- PV(Δq̂) coefficient = **−5.03** (wp1044 imposes **+1**)
- PV(Δq̄) coefficient = +2.77 (wp1044 imposes +1, right sign but 2.8× larger)
- PV(Δr̂_KB) coefficient = −1.25 (wp1044 imposes −σ = −0.54)
- PV(Δr̄_KB) coefficient = +0.001 (wp1044 imposes −σ = −0.54)

PV(Δq̂)'s wrong sign is the killer. No restriction holds on the data.

### Key diagnostic from v6 (Option 2: ToT target)

When q is replaced by ToT (commodity-augmented target) and PV terms
are free:
- PV(Δq_AU_hat) coefficient = **−0.11** (wp1044 would want +1)
- PV(Δq_AU_bar) coefficient = +0.30
- PV(Δr̂_KB) coefficient = −0.27
- PV(Δr̄_KB) coefficient = +0.025

The PV(target)-coefficient-near-zero finding tells us: **changing the
target variable doesn't rescue PAC**. AU business investment doesn't
respond to forward-looking expectations of EITHER market VA OR
commodity terms of trade with the structural coefficient. The agent's
forward-looking weight is just very different from wp1044's framework.

## 4. Why this matters for AUSPAC

AUSPAC is a replication/IRF project. We need coef=1 on PV terms for:
- IRF propagation through expectations channel
- Counterfactual policy analysis
- Welfare comparisons
- Lucas-critique-immune simulation

The data tells us: AU business inv doesn't have coef=1. We have to choose:

## 5. Path forward — three options

### Option 1: Calibrate wp1044 BI coefficients from French estimates (RECOMMENDED for IRFs)

Treat AU BI block's deep parameters (β_0, β_1, β_2, β_3, ω, σ) as
**imported from wp1044 Table 3.5.13** rather than AU-estimated:

  β_0 = 0.096, β_1 = 0.33, β_2 = 0.11, β_3 = 0.69, ω = 0.35, σ = 0.50

The wp1044 structural form runs in the dynare model with these
coefficients. AU data informs the E-SAT VAR + other 4 PAC blocks but
not BI's deep parameters.

**Pros**:
- Strict PAC preserved, IRFs work correctly
- Standard small-open-economy literature approach (when local data
  identifies poorly, import from larger economy)
- AU specifics enter via the data-driven E-SAT (yhat_au, pi_au, i_au,
  i_10y, etc.) and the OTHER blocks' AU estimates
- Defensible in writeup: "BI block calibrated from wp1044 due to AU
  data identification limits documented in PAC_BI_AU_EXPLORATION.md"

**Cons**:
- BI dynamics in AU model are imported, not estimated
- AU mining-cycle dynamics not directly captured
- Model fits AU history less well than a free-OLS would

**Implementation**: ~1-2 hours. Edit `dynare/au_pac.mod` parameter-
values.inc to set BI block params at wp1044 values; leave other 4
blocks at L2 AU estimates. Re-run dynare au_pac for IRFs.

### Option 2: Replace q with commodity-augmented target (TESTED, doesn't work)

The script `data/pac_blocks/estimate_pac_business_inv_au_v6_tot.m`
tested this. **Free-estimated PV(Δq_AU_hat) ≈ −0.11, not +1.**
Strict PAC with q_AU target gives R² = −39. Option 2 is empirically
rejected and should not be pursued further.

### Option 3: Hybrid — Variant A (free PV) for estimation + Option 1 for simulation

- **Estimation/historical decomposition**: use the in-sample
  Variant A model (PV regressors free, R²=0.53). Useful for
  historical analysis, "what was driving AU BI" narrative.
- **IRF simulation / counterfactuals**: use the Option 1 calibration
  in dynare. IRFs are structurally correct.
- Make the dual-track explicit in any writeup.

This is the practice many central-bank models follow when in-sample
estimation diverges from structural form.

## 6. Why the wp1044 PAC restriction fails specifically on AU BI

Three non-exclusive hypotheses:

### Hypothesis A: Different agent objective

AU business inv agents may not minimize wp1044's specific quadratic
cost function. Heterogeneous agents (mining sector vs non-mining),
financial frictions, or different time-preference rates would change
the FOC and the implied PV coefficient.

### Hypothesis B: Mining sector dominance

AU's resource sector represents 10-15% of GDP but ~25% of business
investment in mining-boom periods. Mining-sector capex is driven by:
- Long-term commodity demand expectations (China)
- Specific project lumpiness (e.g., LNG plants 2010-2014)
- Foreign direct investment decisions

These dynamics don't reduce cleanly to wp1044's "expected market VA
growth" framework. The aggregate AU business inv series mixes
forward-looking mining decisions with backward-looking non-mining
decisions, producing apparent zero-or-negative forward-looking
behavior in aggregate.

### Hypothesis C: Sample-period contamination

The AU sample (1993-2024) spans:
- Mining boom 2003-2014 (idiosyncratic ToT shock)
- GFC 2008-2009
- COVID 2020-2021
- GST regime change 2000
- Various policy regime changes (RBA inflation targeting evolution)

Each is a structural break that disrupts long-run PAC identification.
French data (longer, smoother) has fewer such breaks.

## 7. Decision and lock-in

**Selected path**: Option 1 for the IRF model. Document in writeup
that AU BI's deep parameters are imported from wp1044 due to AU data
identification limits (specifically the PV(Δq̂) coefficient sign
mismatch).

Variant A (PV free, R²=0.53) is **NOT** used in the production model;
it's kept as a diagnostic / historical-decomposition tool.

Option 2 is **rejected** based on v6 results (PV(q_AU_hat) coefficient
also fails coef=+1 test). Do not revisit.

## 8. Implementation checklist for Option 1

When implementing into `dynare/au_pac.mod`:

```matlab
% Business inv block: wp1044 calibration (PAC_BI_AU_EXPLORATION.md Option 1)
b0_ib   = 0.096;  // wp1044 Table 3.5.13
b1_ib   = 0.33;
b2_ib   = 0.11;
b3_ib   = 0.69;
omega_ib = 0.35;
% sigma_ces already at 0.5366 from CES calibration
```

The Bayesian estimation `au_pac_bayesian.mod` should EXCLUDE business
inv parameters from estimated_params (treat as calibrated).

Update `dynare/au_pac.mod` comment block to reference this document.

## 9. Cross-block consistency check

Other 4 PAC blocks (VA-price, employment, consumption, housing inv) DO
fit wp1044 structure on AU data with R² between 0.41 and 0.81. Use
**AU L2 estimates** for those blocks (from
`data/pac_blocks/results_<block>.mat`), not wp1044's French values:

| Block | AU L2 estimate (preferred) |
|---|---|
| VA-price (Eq 16) | β_0=0.26, β_1=0.30, R²=0.41 |
| Employment (Eq 30) | β_0=0.31, β_1=0.30, R²=0.81 |
| Consumption (Eq 35) | β_0=0.27 ≈ wp1044's 0.29, R²=0.81 |
| Housing inv (Eq 37) | β_0=0.60, β_1=0.35, R²=0.50 |
| **Business inv (Eq 46)** | **wp1044 calibration imported** (no AU estimate) |

This is the recommended hybrid: AU-estimated where the framework fits
the data, wp1044-calibrated where it doesn't.

## 10. Files referenced

  data/pac_blocks/
    estimate_pac_business_inv.m         baseline strict PAC (R^2=0.09)
    estimate_pac_business_inv_au.m      v1: + AU dummies (R^2=0.11)
    estimate_pac_business_inv_au_v2.m   v2: pre-residualize (R^2=-23.7)
    estimate_pac_business_inv_au_v3.m   v3: 3 sub-variants A/B/C
    estimate_pac_business_inv_au_v4.m   v4: combined PV coef=1 (R^2=-33)
    estimate_pac_business_inv_au_v5.m   v5: ToT + piecewise trends (R^2=-10.7)
    estimate_pac_business_inv_au_v6_tot.m  v6: replace q with ToT (R^2=-39)
    estimate_pac_business_inv_wp736.m   2019 simpler form (R^2=-0.75)
    estimate_pac_business_inv_simple.m  Simplified, drops PV (R^2=0.33)

End of exploration. **AU business inv block: use Option 1 (wp1044
calibration) for dynare simulation/IRFs.**
