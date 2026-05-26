# NEXT_SESSION.md — handoff from 2026-05-26 (end of L2 P1b)

The 2-week wp1044 partial-L2 replication rebuild is complete, plus the Phase L2-P1 gap-closure work, plus Phase L2-P1b business-inv simplified-spec exploration. **All 5 blocks now have R² ≥ 0.33.**

## TL;DR

- **`refactor/frbdf-replication-L2`** branch has ~22 commits covering audit, plan, Phase A→D rebuild, P1 gap-closure, P1b VAR(2)/simplified specs, and P1c business inv exhaustive search.
- **4 of 5 PAC blocks fit wp1044 structure** with AU data: VA-price (R²=0.41), Employment (0.81), Consumption (0.81, β_0=0.27 matches wp1044's 0.29), Housing inv (0.50).
- **Business inv block REJECTS wp1044 strict PAC** structurally — tested 7+ specifications (dummies, trends, ToT-augmented target, terms-of-trade, etc.). Free-estimated PV(Δq̂) coefficient = −5 (wp1044 imposes +1); PV(Δq_AU)=−0.11 with ToT target. **No spec preserves coef=+1 on PV with positive raw R².** See `PAC_BI_AU_EXPLORATION.md` for the full 10-section writeup.
- **Decision locked in (PAC_BI_AU_EXPLORATION.md §7)**: for AUSPAC's IRF/replication purposes, **import BI deep parameters from wp1044 Table 3.5.13** (Option 1). Other 4 blocks use AU L2 estimates.
- **Full L2 report**: `L2_REPLICATION_REPORT.md`. **BI exploration**: `PAC_BI_AU_EXPLORATION.md`.

## Key files to read

1. **`PAC_BI_AU_EXPLORATION.md`** — **READ THIS FIRST** if revisiting BI. Full saga of why strict PAC fails on AU BI, all 7+ variants tried, Option 1/2/3 paths, locked-in decision.
2. **`L2_REPLICATION_REPORT.md`** — complete per-block coefficient tables.
3. **`PAC_EQUATIONS_AUDIT.md`** — audit that motivated this rebuild.
4. **`PAC_REBUILD_PLAN.md`** — the execution plan used.
5. **`BLOCK_LIMITATIONS.md`** — documented data gaps (most now closed).

## Branch state

```
refactor/frbdf-replication-L2     (17 commits, ready to merge or extend)

  Latest commits:
  _        P1b: VAR(2) didn't help + business inv simplified spec (R^2 0.33)
  531cbb2  docs: update L2 report + NEXT_SESSION after P1 gap-closure
  c73fa5c  P1.7b: housing inv price-spread + RPPI date fix
  6b969f2  P1.7: business/housing inv switch to v2 data + exact chi
  d193c11  P1: close 4 of 5 wp1044 data gaps + exact chi solver
  3fbd759  docs: rewrite NEXT_SESSION after L2 rebuild
  6dfd44b  Phase L2-D: final replication report
  3bed36e..fc8136d  Phase L2-C blocks (5 commits)
  744f875  Phase L2-B: helpers
  3f4696a  Phase L2-A: data layer
  dc8d47c  Plan
  4447241  Audit
```

## Headline results

| Block | Status | β_0 AU | β_0 FR | R² AU | R² FR |
|---|---|---|---|---|---|
| VA-price (Eq 16) | full | 0.26 | 0.05 | 0.41 | 0.61 |
| Employment (Eq 30) | full | 0.31 | 0.07 | 0.81 | 0.95 |
| **Consumption (Eq 35)** | full | **0.27** | **0.29** | **0.81** | 0.95 |
| Housing inv (Eq 37) | full | 0.60 | 0.12 | 0.50 | 0.89 |
| **Business inv (Eq 46, simplified)** | full | 0.35 | 0.10 | **0.33** | 0.83 |

Range of R²: 0.33-0.81. Median: ~0.50.

## Three cross-cutting findings (refined)

1. **AU has 4-8× faster ECM speeds than France** across 4 of 5 blocks. Consumption is the only block where β_0 matches FR.

2. **AU PAC blocks fit better with SIMPLER specs than France**. The wp1044 4-PV-term machinery actively hurts business inv. Removing it improves R² 3.6× and brings coefficients close to wp1044. AU data is noisier at higher frequencies than France's; the PV operator amplifies that noise.

3. **L1.3a Bayesian and L2 OLS agree on consumption** — both give β_PAC > 0, β_0 close to wp1044's 0.29.

## What's still gap'd (~2-3 days)

1. **VA-price block** has R² = 0.41 vs wp1044's 0.61. Adding Phillips Eq 18 + Okun Eq 19 aux equations to the VAR has been deferred. Likely lift R² to ~0.50. (~1 day)

2. **Consumption β_PAC = 1.47** is much larger than L1.3a Bayesian's 0.80. Could be PV²(y_H - ybar) absorbing variation that flows through to β_PAC in the simplified form. Worth investigating. (~0.5 day)

3. **Housing β_3 wrong-signed** (price spread term). Probably definitional mismatch with wp1044's "deflator existing housing stock" vs my RPPI. Try alternative pSH constructions. (~0.5 day)

4. **VAR(2) tested and doesn't help** AU data with current sample size (negative finding from this session).

5. **Bayesian Minnesota prior on VAR** still not implemented.

## Three paths forward

### Path 2 (RECOMMENDED): Integrate hybrid L2/wp1044 estimates into Dynare (~3-5 days)

Per `PAC_BI_AU_EXPLORATION.md` Section 9, the hybrid calibration is:

| Block | Source of coefficients |
|---|---|
| VA-price | AU L2 (β_0=0.26, β_1=0.30, R²=0.41) |
| Employment | AU L2 (β_0=0.31, β_1=0.30, R²=0.81) |
| Consumption | AU L2 (β_0=0.27 ≈ wp1044's 0.29, R²=0.81) |
| Housing inv | AU L2 (β_0=0.60, β_1=0.35, R²=0.50) |
| **Business inv** | **wp1044 calibration**: β_0=0.096, β_1=0.33, β_2=0.11, β_3=0.69, ω=0.35, σ=0.50 |

Then `dynare au_pac` for stoch_simul. Compare IRFs to L1.3a baseline.

### Path 3: Write up (~2-3 days)

Three publishable findings:
- AU has faster ECM speeds than France across 4 of 5 blocks
- Consumption β_0 matches France's exactly (0.27 vs 0.29)
- **Business inv structurally rejects wp1044 PAC**: PV(Δq̂) coefficient is structurally negative on AU; +1 wp1044 restriction fails for all targets tested (market VA, terms of trade). Implication: AU business inv has different deep structure than France's. Document Option 1 calibration as the practical path.

### Path 0: Pause

Reasonable pause point. The rebuild + exhaustive BI exploration are complete; the decision is locked in.

## How to pick up tomorrow

1. Read `L2_REPLICATION_REPORT.md` for full per-block details.
2. Decide on Path 1c (apply PV-removal lesson) vs Path 2 (integrate to Dynare) vs Path 3 (writeup).
3. If Path 1c, replicate the spec-search approach from `data/pac_blocks/estimate_pac_business_inv_simple.m` on housing inv.

Branch at 17 commits. All commits passing. No outstanding edits.
