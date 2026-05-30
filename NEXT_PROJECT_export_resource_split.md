# Queued project: split exports into resource vs non-resource (2026-05-30)

> **UPDATE (§6.13):** pursuing this split is what *uncovered the real cause* of the IRF
> oscillation — a Trend-vs-Seasonally-Adjusted data bug (the model used the ABS Trend
> export/import volume series). On SA data `b1_x=0.092` and the oscillation is gone with
> no constraint, so the split is **no longer needed to fix the oscillation**. It remains
> a worthwhile fidelity refinement (and the BoP goods data + series IDs gathered below
> are now in the repo: `abs_bop_goods_exports_cvm.csv`, `abs_5302_t6_goods_credits.xlsx`),
> but it is no longer urgent. The rationale below is kept for if/when it's revisited.

Recommended next structural improvement to the AU-PAC trade block, queued after the
§6.12 stability-constrained `b1_x` work. Mirrors the existing import energy/non-energy
split. Motivation, recipe, and expected outcome below.

## Why

The export short-run growth-persistence `b1_x` is robustly ≈0.78 on AU data — stable
across 7 specifications (HP, consistent-cyclical, OECD cointegration, piecewise trend
breaks, foreign-demand-growth term) and 5 sub-samples (0.77–0.79). See
`IRF_TRANSMISSION_DRIFT_INVESTIGATION.md`. That momentum forces the trade-ECM
eigenvalue modulus `√b1 ≈ 0.88` toward the unit circle and drives the IRF oscillation,
which §6.12 currently handles with a stability cap (`b1=0.65`).

**Hypothesis:** the high aggregate `b1` is a *composition* artefact. AU goods exports are
~65–70% bulk resources (iron ore, coal, LNG) whose *volume* growth is **capacity-driven**
— new mines/LNG trains come online in discrete steps, producing smooth, highly
autocorrelated volume ramps (high `b1`, weak demand-elasticity). Non-resource exports
(manufactures, services, tourism, education, rural) are **demand-driven**, less
persistent, and should cointegrate with foreign demand. Splitting should reveal:
- resource `b1` high (or better: resource volume is a near-exogenous capacity/trend
  process that does not belong in a demand-ECM at all);
- non-resource `b1` moderate (~0.4–0.5) with a working foreign-demand channel.

If so, the aggregate equation is misspecified: it pools a supply-driven series with a
demand-driven one. The fix is to model resource exports as a capacity/trend process and
keep only non-resource exports in the FR-BDF demand-ECM — which would remove the
oscillation *structurally* (no constraint needed) and is more faithful to wp1044's
demand-ECM logic (which assumes demand-driven trade).

## Data recipe (the hard part — not in repo today)

No resource/non-resource export **volume** split exists in the repo (only aggregate
`x_vol` from ABS 5206). Build it:

1. **ABS 5368.0** International Trade in Goods and Services — Table 12/13 (goods exports
   by category, current prices) or the SITC-based commodity detail. Gives resource
   (rural + non-rural bulk: metal ores, coal, gas, metals) vs non-resource (manufactures,
   other) export **values**.
2. **Deflate to volumes** with commodity-specific price indices: RBA I02 (Index of
   Commodity Prices, bulk/rural/base-metals sub-indices — already in repo as
   `rba_i02_commodity.xlsx`) and ABS 5302 export price indices by category. This is the
   noise-introducing step; document deflator choices.
3. Cross-check the reconstructed resource+non-resource volume sum against aggregate
   `x_vol` (ABS 5206) for consistency.
4. Alternative/supplement: RBA "bulk commodity export volumes" (chart-pack data) and
   ABS 5302 BoP supplementary tables.

## Model recipe (mirror the import split)

The import block already does this (`au_pac.mod` ~L1382–1430): `dln_m = w_m_ne·dln_m_ne +
w_m_e·dln_m_e`, each sub-component with its own ECM (`ln_m_*_eq`, `*_gap`, `dln_m_*`).
Symmetric export structure:

```
dln_x = w_x_res·dln_x_res + w_x_nonres·dln_x_nonres
// non-resource: standard FR-BDF demand-ECM (foreign demand + RER), expect moderate b1
dln_x_nonres = b0_xnr·xnr_gap(-1) + b1_xnr·dln_x_nonres(-1) + b2·dln_y_world + b3·s_gap + ...
// resource: capacity/trend process (NOT a demand-ECM) — e.g. exogenous capacity ramp
//   + small price/RER response; or a slow-ECM to a capacity target
dln_x_res = (capacity trend) + small commodity-price/RER terms + eps_x_res
```

Steady state, the GDP/demand identity weights (`w_iad_*_x`), the `estimation_data`
observables (add `Δln X_res`, `Δln X_nonres`), and `gen_paper_irfs` var lists all need
updating. Re-estimate each sub-block (`estimate_trade_exports.m` → two scripts).

## Expected outcome / decision

Most likely: non-resource `b1` is benign; resource volume is near-I(1)/capacity-driven.
Then model resource exports as capacity-trend → the oscillation disappears structurally
and the §6.12 `b1` cap can be **removed** (replaced by the correct decomposition). If
instead both sub-components carry high `b1`, the cap stays and we've confirmed it
rigorously. Either way it's a strict improvement in fidelity.

## Effort

Comparable to the import-split work plus a non-trivial data-construction step (ABS 5368
+ deflation). Estimate: one focused session for data + estimation (decision gate on the
sub-component `b1`s), a second for the model surgery + regeneration + paper if the gate
favours the structural route.
