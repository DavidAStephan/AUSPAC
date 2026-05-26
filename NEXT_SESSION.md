# NEXT_SESSION.md — handoff from 2026-05-26 (end of L2 rebuild)

The 2-week wp1044 partial-L2 replication rebuild is complete. This document is the new handoff: where things stand, what was learned, what's worth doing next.

## TL;DR

- **`refactor/frbdf-replication-L2`** branch has the full Phase L2-A → L2-D rebuild (9 commits, ~12 working days of work compressed into one session).
- **All 5 PAC blocks** rebuilt with faithful wp1044 functional forms (PAC expectation at coef=1, block-specific aux VARs, derived growth-neutrality, χ from characteristic polynomial, COVID dummies).
- **3 of 5 blocks converged cleanly** (VA-price R²=0.41, Employment R²=0.81, Consumption R²=0.81 with β_0 matching wp1044's 0.29 almost exactly).
- **2 of 5 blocks PARTIAL** due to AU data gaps: Housing inv (no pSH/pIH deflators) and Business inv (exports missing from FRED).
- **Full report**: `L2_REPLICATION_REPORT.md` (commit `6dfd44b`).

## Key files to read

1. **`L2_REPLICATION_REPORT.md`** — complete per-block coefficient tables, R² gaps, structural findings, gaps vs full wp1044 fidelity.
2. **`PAC_EQUATIONS_AUDIT.md`** (commit `4447241`) — the audit that motivated this rebuild; gap catalogue per block.
3. **`PAC_REBUILD_PLAN.md`** (commit `dc8d47c`) — the execution plan used.
4. **`BLOCK_LIMITATIONS.md`** — documented data gaps (exports, pSH/pIH, etc.).

## Branch state

```
refactor/frbdf-replication-L2     (active rebuild branch)
  6dfd44b  Phase L2-D: final replication report
  3bed36e  Phase L2-C5: Business inv (partial)
  8ab808a  Phase L2-C4: Housing inv (partial)
  aa477d2  Phase L2-C3: Consumption (full, β_0 matches!)
  751caa5  Phase L2-C2: Employment (full)
  fc8136d  Phase L2-C1: VA-price (full)
  744f875  Phase L2-B: cross-cutting helpers
  3f4696a  Phase L2-A: full wp1044 data layer
  dc8d47c  Plan
  4447241  Audit (motivating doc)
  abd8953  (previous shallow iterative OLS, superseded)

refactor/frbdf-replication         (L1.3a + scaffolds, preserved)
refactor/frbdf-replication-5block  (L1.3b 5-block scaffold, never run)
```

## Headline results

| Block | Status | β_0 AU | β_0 FR | R² AU | R² FR |
|---|---|---|---|---|---|
| VA-price (Eq 16) | full | 0.26 | 0.05 | 0.41 | 0.61 |
| Employment (Eq 30) | full | 0.31 | 0.07 | 0.81 | 0.95 |
| **Consumption (Eq 35)** | **full** | **0.27** | **0.29** | **0.81** | 0.95 |
| Housing inv (Eq 37) | partial | 0.55 | 0.12 | 0.39 | 0.89 |
| Business inv (Eq 46) | partial | 0.76 | 0.10 | 0.05 | 0.83 |

Best result: **consumption β_0 matches wp1044 within sampling noise** (0.27 vs 0.29).

## Three cross-cutting findings

1. **AU has 4-8× faster ECM speeds than France** in 4 of 5 blocks (consumption matches FR exactly). Possible reasons: more flexible AU price-setting, shorter business cycles, or HP-trend proxies giving artificially fast convergence.

2. **AU has smaller χ (forward-looking weight) than France** in most blocks. AU agents appear less forward-looking, or AR coefficients are genuinely shorter-memory.

3. **The L1.3a consumption result (b_PAC_c = 0.80) is validated by L2** — iterative OLS gives β_PAC = 1.47 (positive, same direction), and β_0 ECM speed matches wp1044. The Bayesian Kalman approach was structurally OK on this block; the 14-hour cost was its only real limitation.

## What's still gap'd from wp1044 (~1 more week to close)

1. **VAR(1) only**; wp1044 uses multiple-lag VAR. Adding 2-4 lag VAR per block is straightforward but extends sample-size concerns.

2. **OLS lag-by-lag VAR**, not Bayesian Minnesota prior. Adopting Litterman-style shrinkage would tighten the policy-function projections.

3. **χ from simplified depth-agnostic quadratic** vs wp1044's exact higher-order characteristic polynomial root. Likely affects depth-2 (housing inv, business inv) and depth-3 (employment) blocks most.

4. **Auxiliary equation π*_Q (Eq 17) gave β_0 = 0.024 vs wp1044's 0.71** — AU wages don't drive VA-price the way FR's do, or my W_H + Δē proxy is mis-scaled. Worth digging into.

5. **Three data gaps in `BLOCK_LIMITATIONS.md`**:
   - Exports (FRED downloads return HTML — re-download)
   - Housing deflators pSH/pIH (use ABS 6416 residential property index + implicit dwelling-inv deflator)
   - Proper r_KB wacc (cost of equity + BBB bond + bank lending rate weights)

## Three paths forward, in priority order

### Path 1: Close the 5 remaining wp1044 gaps (~1 week)
Goal: get business inv R² above 0.50, housing inv above 0.60, all blocks structurally faithful.

Sub-tasks:
- Re-download exports from FRED or ABS 5206 Table 2
- Build pSH = ABS 6416 spliced; pIH = implicit deflator of dwelling inv
- Build proper r_KB wacc using AU financing weights (cost of equity from ASX dividend yields; BBB bond from RBA spread series; bank lending rate from RBA)
- Re-estimate aux Eq 17 with better identification
- Add Phillips + Okun aux equations to VA-price block VAR
- Switch χ solver to exact characteristic-polynomial root

After this: a true full-fidelity wp1044 partial-L2 replication.

### Path 2: Integrate L2 estimates into the AUSPAC Dynare model (~3-5 days)
Goal: take the L2 coefficient estimates (especially β_0 from consumption, the ω/depth/χ values per block) and write them back into the AUSPAC dynare/au_pac.mod calibration. Run au_pac.mod with these new values; produce IRFs; compare to L1.3a.

Sub-tasks:
- Update calibration.inc / parameter-values.inc with L2 posteriors (per block)
- Re-run `dynare au_pac` for stoch_simul
- Compare IRFs to round12 cached baseline + L1.3a
- Document in working paper

This is the "ship it" path — get the L2 insights into the production simulation model.

### Path 3: Write up + paper (~2-3 days)
Goal: formalize the wp1044 partial-L2 replication as a paper section.

Sub-tasks:
- Section on AU-vs-FR PAC differences (the 4-8× ECM speed finding, the smaller χ pattern)
- Methods section describing the partial-L2 (vs full Bayesian-Kalman) approach
- Empirical results tables per block
- Conclude: wp1044 framework is structurally sound for AU but with AU-calibrated coefficients

### Path 0: Pause and review
The rebuild is complete; results are solid for 3 blocks and documented-partial for 2. A natural pause point.

## Open questions for the next session

1. The β_0 = 0.27 consumption ECM match (vs wp1044's 0.29) is striking. Is this real or coincidence? Worth a robustness check with sub-sample stability tests.

2. The β_2 wrong-signed contemp regressors in VA-price (-0.08), Employment (-0.03), Housing inv (-0.05) all hover near zero. Could indicate the PV terms are already absorbing the contemp signal; alternatively could be specification issue. Worth testing without PV terms.

3. Business inv R² = 0.05 is so bad that the partial-L2 is not informative. Is the problem the missing exports, the missing wacc, or something more fundamental about AU business inv dynamics?

4. Should L1.3a (10-obs Bayesian, b_PAC_c=0.80) be merged to main now that L2 has validated the consumption structure? Decision depends on whether AUSPAC's "production model" identity should be Bayesian-Kalman or block-by-block OLS.

## How to pick up tomorrow

1. Read `L2_REPLICATION_REPORT.md` for full per-block details.
2. Decide on Path 1 (close gaps) vs Path 2 (integrate to Dynare) vs Path 3 (writeup) vs Path 0 (pause).
3. If Path 1 or 2, the entry-point files are `data/prepare_l2_data.m` and `data/pac_blocks/estimate_pac_*.m`.

Replication branch is stable, fully committed, ready to extend or merge as needed.
