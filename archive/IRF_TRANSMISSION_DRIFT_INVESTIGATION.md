# Why monetary transmission weakened and ln_Q drifts positive (2026-05-30)

Investigation of two IRF properties of the §6.11 production model (trade fix
`b1_x=0.30`, `b1_m_ne=0.23` + reverted §6.10 PAC hybrid = §6.9 PAC blocks).
Both questions are now answered to decimal-level precision. Reproducible drivers:
`dynare/investigate.m` (2×2 decomposition + convergence) and `dynare/part_d.m`
(supply-channel proof), MATLAB R2026a + Dynare 7.0.

## TL;DR

1. **Weaker transmission is ~90% the trade fix, not the PAC revert.** The `ln_Q`
   trough went −0.139% (Q9) → −0.039% (Q17). A clean 2×2 decomposition attributes
   **+0.090** of that +0.100 change to the trade growth-persistence revert and only
   **+0.010** to undoing the §6.10 PAC hybrid. The old −0.139% was largely the first
   downswing of the trade-ECM 11Q oscillation; once the oscillation is removed, the
   −0.039% is the genuine hump-shaped transmission.
2. **The positive drift is a permanent shift in *potential output* `ln_QN`, not the
   output gap, and it is pre-existing — not caused by §6.11.** The gap `yhat_au`
   fully reverts to 0 (~Q200). `ln_Q` settles at +0.062% because `ln_QN` settles at
   +0.062%. The driver is the CES trend-labor equation: a temporary tightening leaves
   a non-zero *cumulative* real-wage gap, which permanently raises trend labour and
   hence potential output. This violates long-run monetary neutrality on the real
   side. It exists in every model version (old HEAD: +0.092%); the trade fix actually
   *reduced* it.

## Finding 1 — what weakened monetary transmission

2×2 design, isolating PAC block (§6.9 L2 OLS vs §6.10 hybrid) × trade persistence
(AU OLS `b1_x=0.87,b1_m_ne=0.74` vs wp1044 `0.30,0.23`). Identical shock, scale=2.26.

| Config | PAC block | trade `b1` | `ln_Q` trough | trough Q |
|---|---|---|---|---|
| C1 (= committed HEAD) | §6.10 hybrid | 0.87 / 0.74 | **−0.1392%** | Q9 |
| C2 | §6.10 hybrid | 0.30 / 0.23 | −0.0490% | Q17 |
| C3 | §6.9 L2 OLS | 0.87 / 0.74 | −0.1307% | Q9 |
| C4 (= §6.11 production) | §6.9 L2 OLS | 0.30 / 0.23 | **−0.0387%** | Q17 |

C1 reproduces the committed Table 6.3 −0.139% exactly → the harness is faithful.
Decomposition of the +0.100 trough change:

- **trade-fix effect** (C1→C2): **+0.0902**  (≈90%)
- **PAC-revert effect** (C2→C4): **+0.0104**  (≈10%)
- cross-check via the other path: PAC alone (C1→C3) +0.0085; trade alone (C3→C4) +0.0920.

**Mechanism.** The deep −0.139% trough at Q9 was substantially the first downswing
of the trade-ECM complex mode (|λ|=√b1≈0.93, ~11Q period; see
`IRF_OSCILLATION_TRADE_AR_FIX.md`). With high export/import growth-persistence the
monetary-shock-induced exchange-rate move (`s_gap` −0.99% @Q8) feeds a large,
prolonged net-trade swing into the `yhat_au` integrator. Collapsing `b1_x`→0.30
damps that mode (root → √0.30≈0.55) so the swing disappears; the trough then occurs
at the natural hump of the mortgage/investment channels (Q17) at −0.039%. The
weakening is removal of a *spurious oscillatory amplification*, not loss of a
genuine transmission channel.

**Caveat.** −0.039% is at/below the conservative end of the AU model range (RBA
suite peaks ≈ −0.1 to −0.3%). The full revert (`b1=0`·AU weight) trades AU signal
for smoothness; a shrinkage `b1 = w·AU + (1−w)·wp1044` with `0<w<1` would restore
some transmission depth while keeping the root well inside the unit circle.

## Finding 2 — what the positive drift is

Long-horizon solve (irf=2000), §6.11 config:

| Q | ln_Q | yhat_au (gap) | ln_QN (potential) |
|---|---|---|---|
| 17  | −0.0387 | −0.0479 | +0.0092 |
| 40  | +0.0760 | +0.0212 | +0.0547 |
| 200 | +0.0648 | +0.0001 | +0.0647 |
| 500 | +0.0622 | +0.0000 | +0.0622 |
| 2000| +0.0622 | −0.0000 | +0.0622 |

So `ln_Q = ln_QN + yhat_au`: the gap reverts fully; the permanent +0.062% is entirely
potential output. The eigenvalue spectrum has 5 explosive roots (=edim, the forward
variables) plus several exact unit roots — `ln_QN` is one (`ln_QN = ln_QN(-1)+dln_y_star`).

**Exact source.** `dln_y_star = α_k·dln_k + (1−α_k)·dln_n_star_bar + dln_tfp`, and
the Phase-L2.A structural trend-labour equation (au_pac.mod:1254) is

```
dln_n_star_bar = (yhat_au − yhat_au(-1)) − dln_tfp/(1−α_k) − sigma_ces·rw_gap + dln_pop_bar
```

Cumulating `ln_QN = Σ dln_y_star` over the IRF, the `dln_tfp` terms cancel,
`yhat_au(∞)=0`, `Σdln_pop_bar=0` (no pop shock), and `Σdln_k=0` (the capital filter
has DC gain 1 acting on `Σdln_ib`, which is 0 because the investment gap reverts).
What survives is:

> **`ln_QN(∞) = −(1−α_k)·sigma_ces·Σ(rw_gap)`**

Verified numerically to 5 dp (α_k=0.45, sigma_ces=0.537):

```
sum(dln_ib)        = -0.00000      sum(dln_k)         = -0.00000
sum(dln_tfp)       = +0.00000      sum(dln_pop_bar)   = -0.00000
sum(rw_gap)        = -0.21065      yhat_au(2000)      = -0.00000
ln_QN(2000)            = +0.06217
-(1-α_k)*sigma_ces*sum(rw_gap) = +0.06217   <-- exact match
α_k*sum(dln_k)         = -0.00000  (capital channel contributes nothing)
```

**Economic reading.** `rw_gap` itself reverts to 0, but its *integral* is negative
(−0.211): a monetary tightening depresses the real wage for an extended transition.
Through the CES factor-substitution term, that cumulative real-wage depression
permanently raises trend labour input (`ln_N_star` +0.113), and with labour share
(1−α_k)=0.55 that is +0.062% of permanent potential output. The output **gap** closes,
but the **level** of potential is permanently higher.

**This is pre-existing, not a §6.11 artefact.** Every config carries it (old HEAD
C1: `ln_Q` Q200 = +0.092%). The trade fix changed the `rw_gap` transition path and
so *reduced* the permanent shift from +0.092% to +0.062%.

**Is it a bug?** It is a genuine property of the FR-BDF/wp1044 CES potential-output
design as implemented in §6.8 (trend factors respond to relative prices). A
*permanent* real effect of a *temporary nominal* shock is a long-run-neutrality
violation that is economically questionable for a monetary shock. Options if it is
judged undesirable: (a) damp/remove the `sigma_ces·rw_gap` term in `dln_n_star_bar`
(makes trend labour depend only on the gap change + trend pop, restoring neutrality);
(b) feed a *gap* rather than an integrating accumulator into `ln_N_star`; (c) accept
it as the intended FR-BDF supply-side hysteresis and document it. No change is made
here — flagging for a design decision.

## Resolution (§6.12, 2026-05-30): stability-constrained b1

Follow-up investigation of whether the weaker transmission could be recovered by a
less-blunt `b1_x` than the §6.11 wp1044 revert (0.30). Tested seven export-equation
specifications (HP, consistent-cyclical, OECD trading-partner cointegration, piecewise
trend-breaks at 2003Q3/2011, a significant short-run foreign-demand-growth term) and
five sub-samples: **`b1_x` is robustly 0.69–0.87 (samples 0.77–0.79)** — the high AU
export-growth momentum is genuine, not a detrending/target artefact. AU exports do not
cointegrate with foreign demand (supply/capacity-driven volume trend). Since the
oscillation modulus is `√b1`, only a direct cap on `b1` damps it. The all-IRF-variable
frontier (the PAC growth-rate IRFs `Δlog C`/`Δlog I_H` bind before `ln_Q`) gives the
constrained-optimal cap **`b1_x = b1_m_ne = 0.49` (`√b1 ≤ 0.70`)** — adopted, deepening
the `ln_Q` trough to −0.043% (Q11) while keeping every IRF non-oscillatory. The positive
`ln_QN` drift (Finding 2) is unchanged by `b1` (it is the separate CES `rw_gap`
hysteresis). Full detail in working-paper §6.12; evidence scripts
`data/pac_blocks/estimate_exports_*.m`, `dynare/frontier*.m`. Structural follow-up
(resource/non-resource export split) queued in `NEXT_PROJECT_export_resource_split.md`.

## Stones turned (and their results)

- 2×2 PAC×trade decomposition of the trough — trade fix dominant (90/10). ✓
- C1 reproduces committed −0.139 — harness validated. ✓
- Long-horizon convergence to Q2000 — gap reverts; potential is permanent. ✓
- Cumulative demand-component decomposition of `yhat_au` — all six net to 0. ✓
- Per-level reversion check — every cyclical/eq level → 0. ✓
- Analytic + numeric proof that the permanent term is `−(1−α_k)·σ·Σrw_gap`. ✓
- Capital / TFP / population channels explicitly ruled out (all Σ = 0). ✓
- Eigenvalue spectrum — 5 explosive (=edim) + unit roots (level integrators). ✓
- Pre-existence across configs (old HEAD +0.092 vs new +0.062). ✓
