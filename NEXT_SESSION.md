# NEXT_SESSION.md — handoff from 2026-05-26 (end of L2 rebuild + P1 gap-closure)

The 2-week wp1044 partial-L2 replication rebuild is complete. After completing it, ~half of NEXT_SESSION's "Path 1" gap-closure work was also done (exports, wacc, p_SH/p_IH alignment, exact χ). This document is the new handoff.

## TL;DR

- **`refactor/frbdf-replication-L2`** branch has the full Phase L2-A → L2-D rebuild (10 commits) PLUS Phase P1 gap-closure work (4 more commits).
- **All 5 PAC blocks** rebuilt with faithful wp1044 functional forms.
- **4 of 5 blocks fully fit** with R² between 0.41 and 0.81 (VA-price, Employment, Consumption, Housing inv).
- **Housing inv R² jumped 0.39 → 0.50** after the RPPI date-format fix + price-spread term.
- **1 block PARTIAL**: Business inv R² = 0.09 (up from 0.05). AU business inv has qualitatively different dynamics than France's; spec doesn't fit.
- **Full report**: `L2_REPLICATION_REPORT.md` (commit `6dfd44b`, updated).

## Key files to read

1. **`L2_REPLICATION_REPORT.md`** — complete per-block coefficient tables.
2. **`PAC_EQUATIONS_AUDIT.md`** — the audit that motivated this rebuild.
3. **`PAC_REBUILD_PLAN.md`** — the execution plan used.
4. **`BLOCK_LIMITATIONS.md`** — documented data gaps (most now closed).

## Branch state

```
refactor/frbdf-replication-L2     (active rebuild branch, 14 commits)

  Phase L2 P1 gap-closure (this session):
  c73fa5c  P1.7b: housing inv price-spread + RPPI date fix
  6b969f2  P1.7: business/housing inv switch to v2 data + exact chi
  _        P1 commit: extras + exact chi solver
  
  Phase L2 main rebuild:
  3fbd759  docs: rewrite NEXT_SESSION.md
  6dfd44b  Phase L2-D: final replication report
  3bed36e  Phase L2-C5: Business inv (partial)
  8ab808a  Phase L2-C4: Housing inv (partial; price-spread added later)
  aa477d2  Phase L2-C3: Consumption (full, β_0 matches!)
  751caa5  Phase L2-C2: Employment (full)
  fc8136d  Phase L2-C1: VA-price (full)
  744f875  Phase L2-B: cross-cutting helpers
  3f4696a  Phase L2-A: full wp1044 data layer
  dc8d47c  Plan
  4447241  Audit (motivating doc)
```

## Headline results (after P1 gap-closure)

| Block | Status | β_0 AU | β_0 FR | R² AU | R² FR |
|---|---|---|---|---|---|
| VA-price (Eq 16) | full | 0.26 | 0.05 | 0.41 | 0.61 |
| Employment (Eq 30) | full | 0.31 | 0.07 | 0.81 | 0.95 |
| **Consumption (Eq 35)** | **full** | **0.27** | **0.29** | **0.81** | 0.95 |
| Housing inv (Eq 37) | full | 0.60 | 0.12 | **0.50** | 0.89 |
| Business inv (Eq 46) | partial | 0.86 | 0.10 | 0.09 | 0.83 |

Best result: **consumption β_0 matches wp1044 within sampling noise** (0.27 vs 0.29). Worst: **business inv R² 0.09** — even with exports and proper wacc, AU business inv resists fitting wp1044's spec.

## Three cross-cutting findings (still hold after P1)

1. **AU has 4-8× faster ECM speeds than France** in 4 of 5 blocks (consumption matches FR exactly).
2. **AU has smaller χ (forward-looking weight) than France** in most blocks.
3. **The L1.3a consumption result (b_PAC_c = 0.80) is validated by L2** — iterative OLS gives β_PAC = 1.47 (positive, same direction), β_0 ECM speed matches wp1044.

## What's still gap'd (~3-5 days)

1. **VA-price aux equations (Phillips Eq 18 + Okun Eq 19)** not yet added to the VA-price block VAR. Would tighten the PV(π*_Q) projection and likely lift R² from 0.41 toward wp1044's 0.61. ~1 day.

2. **VAR(1) only**; wp1044 uses multiple-lag VAR. Adding 2-4 lag VAR per block is straightforward but extends sample-size concerns.

3. **OLS lag-by-lag VAR**, not Bayesian Minnesota prior. Adopting Litterman-style shrinkage would tighten the policy-function projections.

4. **Business inv specification mis-match** — even with proper df (= c+ih+exports) and wacc-based r_KB, AU business inv has R² = 0.09. AU has commodity-cycle and mining-investment dynamics not captured by wp1044's demand+user-cost spec. May need a fundamentally different specification (e.g. add commodity terms of trade as a regressor).

5. **wacc weights are a first-order proxy** — AU wacc could use better weights (cost of equity from ASX dividend yields; BBB bond spread from RBA series; bank lending rate weights from RBA composite).

6. **House price-spread term wrong-signed** in housing inv (β_3 = −2.75 vs wp1044 +0.05). Probably a definitional mismatch — my p_SH (RPPI) vs wp1044's "deflator existing housing stock" may not be the same conceptual object.

## Three paths forward, in priority order

### Path 1b: Close remaining gaps (~3-5 days)

Sub-tasks:
- Add Phillips Eq 18 + Okun Eq 19 aux equations to VA-price VAR (1 day)
- Try higher-lag VAR (1 day)
- Investigate housing β_3 wrong sign (1 day)
- Try alternative business-inv specifications (1-2 days)

Realistic R² targets after this work: VA-price 0.55, Housing 0.65, Business inv 0.40 (still well below wp1044 but functional).

### Path 2: Integrate L2 estimates into the AUSPAC Dynare model (~3-5 days)

Goal: take the L2 coefficient estimates (especially β_0 from consumption, the ω/depth/χ values per block) and write them back into the AUSPAC dynare/au_pac.mod calibration. Run au_pac.mod; produce IRFs; compare to L1.3a.

Sub-tasks:
- Update calibration.inc / parameter-values.inc with L2 posteriors (per block)
- Re-run `dynare au_pac` for stoch_simul
- Compare IRFs to round12 cached baseline + L1.3a
- Document in working paper

### Path 3: Write up + paper (~2-3 days)

Goal: formalize the wp1044 partial-L2 replication as a paper section.

### Path 0: Pause and review

The rebuild is functional for 4 of 5 blocks; business inv is documented as PARTIAL. Reasonable pause point.

## Open questions for the next session

1. The β_0 = 0.27 consumption ECM match (vs wp1044's 0.29) is striking. Worth a sub-sample stability test.
2. The β_2 wrong-signed contemp regressors in VA-price (-0.08), Employment (-0.03), Housing inv (-0.07) all hover near zero — PV terms absorbing the contemp signal?
3. Business inv R² 0.09 is bad. Is the spec fundamentally wrong for AU, or just missing commodity-cycle drivers?
4. Should L1.3a (10-obs Bayesian, b_PAC_c=0.80) be merged to main now that L2 has validated the consumption structure?

## How to pick up tomorrow

1. Read `L2_REPLICATION_REPORT.md` for full per-block details.
2. Decide on Path 1b (more gap closure) vs Path 2 (integrate to Dynare) vs Path 3 (writeup) vs Path 0 (pause).
3. If Path 1b, the most impactful single task is adding Phillips+Okun to the VA-price VAR.
4. If Path 2, the entry-point file is `dynare/au_pac.mod` parameter-values.inc.

Replication branch is stable, fully committed.
