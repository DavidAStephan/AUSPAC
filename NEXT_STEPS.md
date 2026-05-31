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
- **Quick wins A1–A3 done (2026-05-31)** — (A1) removed the duplicate `eps_pm_ne`/`eps_pm_e`
  `varexo` declarations (no more "Symbol declared twice" warnings); (A2) the three formerly
  `(not estimated)` shock std devs are now AU OLS residual stds — `eps_q_us` 1.138→**1.1118**,
  `eps_pi_us` 0.319→**0.2625** (`data/pac_blocks/estimate_foreign_block.m`), `eps_pQ` 0.571→**0.6975**
  (`estimate_pac_va_price.m`, now reports `resid_sd`); (A3) Table 4.5.2 fully re-tabulated on the SA
  layer (β₁ −0.182, α₁ −126.7, β_PAC +1.56, β₂/β₃, COVID dummies, R² 0.82; reduced-form α₁·χ −1.27
  now ≈ France's −1.15). BK re-confirmed (5 explosive eig, max|eig|=1.087, Q200 neutrality holds);
  paper .tex/.pdf rebuilt (136pp).
- **Paper IRF results refreshed to the current model (2026-05-31)** — the §7 IRF numbers (abstract,
  errata box, §7.2 Table 6.3 + six-channel walkthrough + Table 6.4 RBA comparison + verdict, all
  §7.3 captions, conclusions) had lagged the model by the employment-χ / housing / consumption-SA
  ECM-speed writebacks and were mutually inconsistent across snapshots. Re-extracted every cited
  quantity from the current model (`dynare/extract_irf_numbers.m`) and updated the text: 100bp
  monetary real-GDP trough −0.073%/−0.098% → **−0.144% @Q11**, output-gap → **−0.086%**. Two
  model-property findings surfaced and are **flagged for review**: (a) the **fiscal multiplier is now
  large** — a 1%-of-GDP `eps_g` shock gives output-gap +0.91% / real-GDP +1.56% (was +0.18%),
  driven by the amplified real-side blocks + λ_dom=0.40 — worth a sensitivity check; (b) the
  **TFP→output-level transmission is degenerate** under the current calibration (`eps_tfp_LR` σ=0.01
  + §6.8 structural-identity refactor → ≈0 output response at 1 s.d.; the old "+13% ln_Q" Fig 6.8 was
  a pre-refactor σ=0.2 illustration). `stoch_simul` reporting set extended with `dln_x dln_m ln_QN`.

Model state: 182 endo / 55 shocks, BK-stable (5 explosive eig, max|eig|=1.087), all level
accumulators revert at Q200. ~40–45% of behavioural parameters now genuinely AU-estimated.

---

## Remaining work (prioritized)

### A — Quick wins ✓ ALL DONE 2026-05-31 (see "Recently completed" above)
- ~~**A1. Remove the duplicate `eps_pm_ne` / `eps_pm_e` `varexo` declarations.**~~ Done — single
  declaration each, no more "Symbol declared twice" warnings.
- ~~**A2. Write back the 3 `(not estimated)` shock std devs** (`eps_q_us`, `eps_pi_us`, `eps_pQ`).~~
  Done — `eps_q_us` 1.1118, `eps_pi_us` 0.2625 (`estimate_foreign_block.m`), `eps_pQ` 0.6975
  (`estimate_pac_va_price.m`). IRFs (scaled to fixed targets) unchanged.
- ~~**A3. Re-tabulate the §4.5 consumption sub-coefficient table** (β₁/α₁/COVID dummies) on the SA layer.~~
  Done — Table 4.5.2 + `paper_artifacts/table_5,8` + β₀/R² charts regenerated from the SA
  `results_consumption.mat`; α₁·χ reduced form −1.27 (now ≈ France's −1.15, was ~70%).

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
