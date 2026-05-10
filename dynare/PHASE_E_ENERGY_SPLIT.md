# Phase E: Energy / non-energy commodity import split — deferred

## Status: NOT IMPLEMENTED (low priority)

## What FR-BDF does (Section 4.7, eqs 88-91)

FR-BDF separates the import block into two streams:
1. **Energy imports** (oil, gas, refined petroleum) — driven primarily by world energy prices, with low domestic-demand elasticity.
2. **Non-energy imports** (manufactured goods, services) — driven by domestic absorption, with REER pass-through.

This matters for France because the energy import bill is large and shocks to oil prices propagate differently than shocks to general world demand.

## Why we have not implemented it for Australia

1. **Australia's structure is opposite to France's.** Australia is a *net energy exporter* (coal, LNG, uranium). Energy imports are dominated by **refined petroleum** only — a much smaller share of total imports than for France.
2. **No AU-specific energy import deflator series in the current data pipeline.** The ABS 5206 IPD chains we use are aggregate import deflators only.
3. **Marginal IRF gain.** Phase 4 work (PAC structural re-estimation) showed that a single commodity price AR(1) (`rho_pcom`) plus the commodity → import deflator coefficient (`beta_pm_com`, AU-est = 0.42, 8x stronger than FR-BDF's 0.05) already captures the dominant terms-of-trade transmission for Australia.

## What would be needed to implement

1. **Data**: ABS 5368 (international trade in goods) decomposes imports by SITC commodity class. Need to extract:
   - Mineral fuels, lubricants and related materials (SITC 3) — the energy stream
   - All other categories — the non-energy stream
   For each: chain-volume measures *and* implicit price deflators, both at quarterly frequency 1993Q1+.
2. **Model code**: split `m`, `dln_m`, `pi_m` into `m_e` / `m_ne`, `dln_m_e` / `dln_m_ne`, `pi_m_e` / `pi_m_ne`. Add weights for aggregating back to total. Add an oil-price exogenous block (separate from `pcom`).
3. **Re-estimation**: separate `b1_m_e` / `b1_m_ne`, `b2_m_e` / `b2_m_ne`, `beta_pm_e` / `beta_pm_ne`, etc.

## Why deferring is defensible for the working paper

The working paper's headline contributions are:
1. PAC framework adapted for AU institutions (RBA, variable-rate mortgages)
2. Three-regime expectation comparison
3. Bayesian posterior identification (gamma_w near-full CPI indexation)
4. Conditional forecasting under RBA scenarios

None of these depends on disaggregated import dynamics. The aggregate import block is sufficient for the policy questions the model addresses. The energy split would only matter for terms-of-trade shocks, which Australia handles through the commodity-price channel that's already in the model.

## When to revisit

- When the model is used for terms-of-trade or oil-price-shock scenarios.
- When ABS 5368 decomposed series are added to `data/abs_rba/`.
- When the working paper extension addresses energy macro questions.
