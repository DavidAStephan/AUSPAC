# NEXT_STEPS.md — consolidated backlog (authoritative)

**As of 2026-05-31, `main` @ de77d5c.** This is the single source of truth for what remains.
[`STATUS.md`](STATUS.md) and [`WAVE3_ROADMAP.md`](WAVE3_ROADMAP.md) point here; WAVE3_ROADMAP holds
the detailed implementation specs for the new-scope (wp1044) blocks.

Project goal (unchanged): *a functioning, close replication of FR-BDF on Australian data that
estimates every behavioural equation — nothing calibrated except the theoretical / steady-state
quantities FR-BDF itself fixes.*

---

## Recently completed (do NOT redo) — PRs #11–#14, 2026-05-30/31

- **Docs truth-up** — STATUS/README/RUNNING rewritten to the OLS reality; working-paper errata +
  dimensions (180/53/351) + Dynare 7.0; reproducible `forecast_eval.m`; fidelity rubric.
- **Model correctness** — potential-output hysteresis fixed toward long-run neutrality
  (`lambda_hyst = 0`); `ln_IH`/`ln_IB` reporting trends fixed; `h_pac` re-verified bit-identical.
- **PAC machinery verified** — `dynare/verify_pac_chi_pv.m`: the `(I−χΦ)⁻¹χΦ` operator is correct
  to machine precision and source-faithful (wp736/wp1044); **employment-χ bug fixed** (was an
  approximate depth-1 solver → exact depth-m; R² 0.82→0.86, b0_n 0.31→0.48).
- **AU estimation** — `rho_tp` 0.98→0.88, `rho_lh` 0.97→0.91, `gamma_oil` (commodity→CPI, AU);
  spread persistences `rho_BBB`/`rho_LB_firms`. BI rejection confirmed **robust** (calibration justified).
- **New wp1044 blocks** — **household credit/DSR** (§3.7.2) and **leverage-based NFC financial
  accelerator** (§3.7.3) implemented and AU-estimated. Finding: AU spreads are *pro-cyclical* via
  the credit cycle (opposite of textbook Bernanke-Gertler).
- **Drift resolved** — consumption/housing SA re-estimates written back (consumption β₀ 0.27→0.23,
  housing b0_ih 0.50→0.60); §6.8/§6.14 caveats closed; PDF regenerated (136pp).

Model state: 182 endo / 55 shocks, BK-stable (5 explosive eig, max|eig|=1.087), all level
accumulators revert at Q200. ~40–45% of behavioural parameters now genuinely AU-estimated.

---

## Remaining work (prioritized)

### A — Quick wins (hours, low risk, no new data)
- **A1. Remove the duplicate `eps_pm_ne` / `eps_pm_e` `varexo` declarations** (`au_pac.mod`, the two
  "Symbol declared twice" preprocessor warnings). Benign (Dynare dedupes) but masks real warnings.
- **A2. Write back the 3 `(not estimated)` shock std devs** (`eps_q_us`, `eps_pi_us`, `eps_pQ`) from
  their OLS residual stds. No effect on the deterministic IRFs; closes the last "nothing calibrated" hygiene gap.
- **A3. Re-tabulate the §4.5 consumption sub-coefficient table** (β₁/α₁/COVID dummies) on the SA layer —
  only β₀ was refreshed in the drift-resolution pass; the rest still mix estimation snapshots (flagged in-paper).

### B — Data-blocked (need a download / a constructed series)
- **B1. Energy oil+gas split + HICP behavioural components** (wp1044 §3.6.4 / Appx E). Needs an AU energy
  price series — the broad RBA I02 commodity index has no oil/gas sub-component. Path: ABS 6457 petroleum
  sub-index (fragile versioned xlsx URL), or Brent-in-AUD (global oil × RBA F11). Then split the
  energy-import block and promote the HICP food/energy reporting variables to behavioural equations.
  *Specs: WAVE3_ROADMAP §3.4–3.5.* Effort ~3–4 days once the series exists.
- **B2. `rho_s` (real-exchange-rate gap)** — the `s_gap` equation carries a forward UIP term (`pv_i_uip`),
  so a bare AR(1) is misspecified; needs joint/IV estimation. TWI is available (RBA F11). *WAVE3_ROADMAP deferred.*
- **B3. Trade long-run elasticities** (`beta_x`/`gamma_x`/`beta_m_ne`/…) — AU OLS gives wrong-signed/insig
  values (mining vs non-mining composition). Either build the resource/non-resource export split
  ([`NEXT_PROJECT_export_resource_split.md`](NEXT_PROJECT_export_resource_split.md)) or accept as a
  documented permanent calibration exception.

### C — Structural (research-grade, higher risk/effort)
- **C1. Quasi-endogenous employment/investment anchors** (wp1044 §3.4.3/§3.5.3). Replaces the exogenous
  trend targets with conjuncture-responsive ones (fixes the Round 4–8 over-dampening). **Lowest ROI**:
  the anchors are already semi-endogenous, the most-affected block (BI) is calibrated anyway, and it
  changes the VAR companion → `h_pac` (needs `pac.print()` regen + careful BK validation). *Specs: WAVE3_ROADMAP §3.1.*
- **C2. Make the DSR/credit block "rationally consistent."** It was added as an exogenous AR(1) feeding
  consumption; the faithful version makes household debt an endogenous stock (ECM on housing wealth/income)
  and adds `DSR_gap` to the consumption aux-VAR + regenerates `h_pac` so agents *anticipate* DSR shocks.
  Also addresses the broader "Round 4–8 not rationally consistent" gap.
- **C3. Hand-to-mouth + PV² consumption operator** (wp1044 §3.5.1). Round 1.2 added the `wt_H_real_gap`
  plumbing; promote `b_HtM` to `estimated_params` (or add the income series to `varobs`) and build the PV² term.

### D — Validation & rigor
- **D1. Extend `forecast_eval.m`** from 1-step to multi-horizon (h=1…8) and to more observables; optionally
  a true recursive re-estimation variant, so the OOS evidence (currently: AU CPI Phillips beats naive
  benchmarks at h=1) is fuller.

---

## Operational notes for the next session
- **RBA downloads work** via `https://www.rba.gov.au/statistics/tables/csv/<table>-data.csv` (e.g. `f5`,
  `e2`, `f3`, `d2`). ABS "latest-release" landing pages return HTML — need the specific versioned xlsx URL.
- **Toolchain**: Dynare **7.0-arm64** (`~/Applications/Dynare/7.0-arm64`) + MATLAB **R2026a** (call by full
  path; not on PATH). Paper build: `pandoc … --include-in-header=paper_header.tex` then `tectonic` (both installed).
- **Diagnostics**: `dynare/check_bk.m` (BK), `dynare/validate_wave1.m` (100bp IRF + Q200 neutrality),
  `dynare/verify_pac_chi_pv.m` (χ/PV operator). Run from `dynare/`.
- **χ solvers**: employment now uses `solve_pac_chi_exact` (exact depth-m); consumption uses `solve_pac_chi`
  with a single `[beta_1]` (genuinely depth-1, correct). `solve_pac_chi` is approximate for depth>1 — don't
  pass it multi-lag vectors.
- **Reproducibility**: `dataset.csv` restore-on-demand (`git show 7995ce7^:dataset.csv > dataset.csv`); the
  L2 data layers regenerate deterministically via `data/prepare_l2_data.m` + `prepare_l2_data_extras.m`.
