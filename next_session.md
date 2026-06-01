# next_session.md — AUSPAC single entry point (authoritative)

**As of 2026-06-01 (`main`; branch `industry-split-phase0` merged).** This is the ONE file to read first next
session. The repo was consolidated on 2026-06-01: every standalone status/design/audit markdown was folded into this
file or moved to [`archive/`](archive/) (recover any of it via git — see the Archive index near the end). Everything
you need — current state, how to run, the active multi-industry project (full design + phase status), the base-model
fidelity reference, the backlog, and references — is below.

**Project goal (unchanged):** a functioning, close replication of FR-BDF (Banque de France WP #736, Lemoine et al.
2019; updated WP #1044, Dubois et al. 2026) on Australian data that estimates every behavioural equation — nothing
calibrated except the theoretical / steady-state quantities FR-BDF itself fixes. Estimation philosophy:
equation-by-equation OLS / calibration (wp1044 §2.2). The earlier full-system Bayesian MCMC pipeline was removed in
cleanup `7995ce7`; any LMD / Laplace number in old text is **historical**.

---

## 0. Current state (2026-06-01)

**Model:** [`dynare/au_pac.mod`](dynare/au_pac.mod) — self-contained, BK-stable: **`n_exp=5` explosive eigenvalues,
max|eig|=1.08707**, all level accumulators revert to ≈0 at Q200 (long-run money-neutral, `lambda_hyst=0`). After the
industry-split Phase-1a/1b scaffolding it declares **~210 endogenous / 55 shocks**. The 100bp monetary (`eps_i`)
trough is `ln_Q` −0.144% @Q11 / output-gap −0.086%.

**Toolchain:** Dynare **7.0-arm64** (`~/Applications/Dynare/7.0-arm64`) + MATLAB **R2026a**
(`/Applications/MATLAB_R2026a.app/bin/matlab` — full path, NOT on PATH). No `timeout` command on this shell.

**Active project = the multi-industry (mining vs non-mining) split.** Phases **0, 1a, 1b are DONE, verified, and on
`main`**; the full design + phase-by-phase status is in the ACTIVE PROJECT section below. **Next step = Phase 2** (the
mining supply block — capacity ratchet + world-price deflator; first phase whose IRFs are intentionally NOT
bit-identical).

### How to run / diagnose (from `dynare/`, full MATLAB path)
| Task | Command |
|---|---|
| Solve + IRFs + paper artifacts | `matlab -batch "cd dynare; regen_all_artifacts"` |
| BK + 100bp IRF + Q200 neutrality | `matlab -batch "cd dynare; validate_wave1"` |
| PAC χ/PV operator self-consistency | `matlab -batch "cd dynare; verify_pac_chi_pv"` |
| Industry-split scaffolding (BK-neutral + 4-way reconciliation + bit-identity) | `matlab -batch "cd dynare; verify_phase1a"` |
| Every paper-cited IRF number | `matlab -batch "cd dynare; extract_irf_numbers"` |
| 1-step recursive forecast eval vs RW/AR(1)/mean | `matlab -batch "cd dynare; forecast_eval"` |

### Reproduce the data + estimates
```bash
# (once) restore the base E-SAT dataset if absent:
git show 7995ce7^:dataset.csv > dataset.csv
# 1. Refresh the 5 core PAC-block OLS coefficients (~minutes):
cd data; matlab -batch "run('run_all_l2_ols.m')"
#    standalone: estimate_wage_phillips_constrained, estimate_cpi_phillips, estimate_deflators,
#    estimate_trade_exports / estimate_trade_imports, estimate_foreign_block
# 2. Industry-split data foundation (Phase 0):
python3 data/build_market_sector_capital.py     # mining/non-mining GVA + capital splits (asserts units)
python3 data/build_io_bridge.py                  # I-O VA bridge -> io_bridge_coefficients.csv, closure_shares.csv
matlab -batch "cd data; prepare_supply_data_sector; sector='nonmining'; estimate_ces_2026_sector"
# 3. Write coefficients into dynare/au_pac.mod (per-block writeback), then solve + regenerate:
cd ../dynare; matlab -batch "regen_all_artifacts"
```

### Operational notes
- RBA CSVs download via `https://www.rba.gov.au/statistics/tables/csv/<t>-data.csv` (f5/f6/e2/f3/d2). ABS
  "latest-release" pages return HTML — use the ABS Data Explorer SDMX API (`https://data.api.abs.gov.au/rest/`, follow
  redirects with `curl -sSL`) or a versioned `.xlsx` URL.
- `*.mat` and raw `rba_*.csv` / `fred_*.csv` are **gitignored** (regenerable). CONSTRUCTED series ARE committed.
- The L2 data layers regenerate deterministically via `data/prepare_l2_data.m` + `prepare_l2_data_extras.m`.
- Paper build (from `dynare/`): `pandoc AUSPAC_WORKING_PAPER.md -o AUSPAC_WORKING_PAPER.tex --standalone --mathjax
  --include-in-header=paper_header.tex` then `tectonic AUSPAC_WORKING_PAPER.tex` (pandoc + tectonic installed; no pdflatex).

---

# ⛏️ ACTIVE PROJECT — Multi-industry split (mining vs non-mining)

> The complete current spec follows — design, equations, data recipe, estimation plan, the Dynare surgery, the phased
> rollout with decision gates, and the risk register. The **status blocks at the top reflect what is DONE on `main`**
> (Phases 0, 1a, 1b verified). **Phase 2 (mining supply block) is next.**


*Spec drafted 2026-05-31. Supersedes nothing; integrates and consumes `NEXT_PROJECT_export_resource_split.md` (do not run that separately). House style matches the `next_session.md` appendix specs: Why / Data recipe / Model recipe / Phased rollout with decision gates / Effort / Risks.*

> **READ THIS FIRST — the design has been revised against an adversarial review.** Five blocking accounting/closure errors, five blocking Dynare/PAC-stability errors, and three blocking scope errors in the first-pass design have been *fixed in place* below, not appended as caveats. The most important fixes: (1) the GDP closure is now done on **one valuation basis** with the **0.8% basic-price tax wedge** (not the spurious 6.29%); (2) `yhat_dom` is **never redefined** — the closure is a *reported* residual that defines `sd_gap`, not a second LHS; (3) Option A ("keep `yhat_au`, just re-print") is **rejected** — the belief-VAR must be rewritten and all five h-vectors regenerated; (4) the mining/non-mining split is reconciled with the **existing market/non-market block** (`au_pac.mod:1667-1671`) as a clean three-way partition; (5) the stale `b1_x≈0.78` premise is **dropped** (live SA value is 0.092). Several parameters the first pass called "estimated" are **reclassified as calibrated** because the AU data does not identify them.

> **PHASE-0 IMPLEMENTATION STATUS (2026-06-01, branch `industry-split-phase0`).** ✅ **GATE 0 + the two CES calibrations (GATE 1a) are DONE and independently verified.** Artifacts in the working tree: fixed `data/build_market_sector_capital.py` + regenerated `market_sector_gva_splits.csv`/`market_sector_capital.csv` (the level/growth unit bug is fixed — `q_nonmining_market` now strictly positive, reconciles to total to 0 error); NEW `data/build_io_bridge.py` → `data/io_bridge_coefficients.csv` + `data/closure_shares.csv` (closure independently confirmed: GVA 2,511,352 + 0.8% wedge = GDP-E 2,531,630); ABS Labour Account mining+total employment/hours (SA) + by-industry WPI downloaded; `data/prepare_supply_data_sector.m`, `data/estimate_ces_2026_sector.m`, `dynare/{supply_data_sector,ces_2026_calibration_nm,ces_2026_calibration_m}.mat`. **Key results folded into §1.3 and §4.1:** the three-way partition is **0.118 / 0.604 / 0.278** (NOT 0.117/0.72/0.16); **GATE 1a = FALLBACK** (`sigma_nm`=0.364 < band ⇒ `sigma_nm=0.5366, alpha_nm=0.35`); `alpha_m=0.84` (data GOS share). **Data gap accepted:** no sector VA deflator exists (current-price industry GVA is annual-only); mining deflator uses the RBA i02 commodity proxy off `dln_pcom` per §2.1/GATE-0 fallback.

> **MILESTONE-0 + PHASE 1a DONE (2026-06-01).** **Milestone-0 verified already-closed** (not re-fixed): `validate_wave1.m` shows `lambda_hyst=0`, BK satisfied (`n_exp=5`, max|eig|=1.08707), Q200 levels revert to ≈0 (hysteresis bug gone); `verify_pac_chi_pv.m` shows the PV operator correct to machine precision for all 5 blocks, all convergent (`chi·max|eig|<1`, business_inv binds 0.554), employment χ=0.368 (the old 0.21 bug is fixed). The two Milestone-0 items were resolved by PR #11–15; the 2026-05-30 snapshot was stale. (Cosmetic: the prose footer in `results_chi_pv_verification.txt` still describes the pre-fix χ=0.21 state — harmless doc-debt.) **Phase 1a (approach A, identity-first) implemented in `au_pac.mod`:** added `dln_y_star_{m,nm,nmk}` (placeholders = aggregate `dln_y_star`), the accumulators `ln_QN_{m,nm,nmk}`, the reconciliation identity `ln_QN_recon = w_qn_m·ln_QN_m + w_qn_nm·ln_QN_nm + w_qn_nmk·ln_QN_nmk`, and params `w_qn_m/nm/nmk = 0.1180/0.6043/0.2777`; all pure reporting (in the `stoch_simul` list, feed nothing). `verify_phase1a.m` confirms **GATE 1a (model-side) = PASS**: `n_exp=5` and max|eig| unchanged; `max|ln_QN_recon − ln_QN| = 2.9e-14` over all 48 shocks; every 100bp `eps_i` economic IRF bit-identical to baseline (≤5e-6). endo +7 (declared). 

> **PHASE 1b DONE (2026-06-01).** Refactored the partition to **four-way** (dwellings split out as its own statistical trend per the user's decision: `w_qn_m/nm/nmk/dw = 0.1180/0.6043/0.1849/0.0928`), then **redefined `yhat_au` from a backward accumulator to a contemporaneous weighted identity** `yhat_au = w_qn_m·q_m_gap + w_qn_nm·yhat_nm + w_qn_nmk·yhat_nmk_gap + w_qn_dw·yhat_dw_gap`. The new accumulator `yhat_nm = yhat_nm(-1) + yhat_dom + eps_q` inherits the old aggregate law; the mining/non-market-public/dwellings gaps are Phase-2 PLACEHOLDERS = `yhat_nm`. **GATE 1b = PASS** (`verify_phase1a.m`): `n_exp=5`/max|eig| unchanged; **`yhat_au ≡ yhat_nm` to 1.4e-15**; four-way reconciliation to 1.0e-13; all economic IRFs bit-identical (≤5e-6). **Key confirmation of R1/R3:** the redefinition did NOT corrupt the `h_pac`/belief-VAR — because `yhat_au`'s dynamics are unchanged in this aggregation-only step, the belief-VAR rewrite is genuinely **deferred to Phase 3** (when `yhat_nm` diverges via `yhat_dom→yhat_dom_nm` and the sector gaps get real laws). **NEXT: Phase 2** — replace the placeholder `dln_y_star_m`/`q_m_gap` with the mining capacity ratchet + world-price block, and `dln_y_star_nmk`/`dln_y_star_dw` with trends; unify the resource-export split. Sequential, not swarm.

---

## 1. Executive summary and core modelling thesis

### 1.1 What we are building and why

AUSPAC's single aggregate production function (one CES potential-output trend + three factor-demand PAC blocks) treats *all* GDP as demand-determined: `yhat_au = yhat_au(-1) + yhat_dom + eps_q` (`au_pac.mod:1110`). For Australia this is first-order wrong. Mining is **11.66% of GVA** but only **~2% of employment**, **72.6% of its output is exported directly**, and its output is set by world commodity prices feeding discrete capacity ramps (mining capital grew **9.2%/yr over 2003-2012, peaking +17.6% in 2012**, then collapsed to ~0%/yr post-2015 — the lumpy build-then-produce signature). Mining VA is **not** chosen by a domestic firm minimising cost against a domestic demand schedule; it is a price-taker shipping to the rest of the world.

This project splits the single production function into **two branches** with an **asymmetric** architecture, validated against the RBA's MARTIN model (RDP 2019-07), Bank of Canada ToTEM, Norges Bank NEMO and Banco de Chile XMAS — all of which treat the resource sector as a world-price-taking, capacity-driven supply block:

- **Non-mining (market) = the faithful FR-BDF demand-determined block.** Keeps the entire CES + factor-cost FOCs + VA-price PAC stack, only re-estimated on non-mining data and fed by a non-mining demand driver. This is FR-BDF's "market branch" (wp736 §4.3).
- **Mining = a thin MARTIN-style supply block.** Capacity-driven potential output (`ln_QN_m ∝ lagged mining capital`), commodity-price/Tobin's-q-driven investment, world-price VA deflator, **no** factor-cost FOC, **no** PAC expectation, **no** hysteresis. MARTIN: *"In the long run, resource exports are determined by the supply of mining output… proportional to the capital stock of the resources sector"* (§4.5.2); *"resource exports initially do not respond to the increase in interest rates because the productive capacity of the resources sector is unchanged in the short run"* (`RBA_mon_transmission.pdf`).
- **Non-market (public admin + education + health + dwellings) = the EXISTING `yhat_nonmarket` block, retained unchanged.** This is the reconciliation the first-pass design missed (see §1.3).

The two new branches are reconciled with the expenditure side through an **Input-Output value-added bridge** built from `data/io_tables_australia.xlsx` (ABS 5209.0, 2021-22): of every dollar of domestic final demand (C/I/G) ~80-90c is non-mining VA and essentially zero is mining; only the **export** column carries mining (mining = **46.7% of export VA**, a 35× concentration vs consumption). This is the empirical heart of the partition.

### 1.2 The three-line thesis

1. **Mining output is supply/world-price-determined** (capacity ratchet + commodity price), routed almost entirely to exports.
2. **Non-mining (market) output is demand-determined** (the FR-BDF CES + FOC + PAC logic), fed by the non-mining VA content of domestic final demand + non-resource exports, net of imports.
3. **The two (plus the unchanged non-market branch) are reconciled by an I-O VA bridge** that routes expenditure to producing sectors *without double-counting* and closes GDP(P)=GDP(E) on a single valuation basis with a small, *reported* statistical-discrepancy residual.

### 1.3 The three-way partition (FIX for the market/non-market collision)

The model **already** contains a sectoral partition: `yhat_market`/`yhat_nonmarket` (`au_pac.mod:1667-1671`), where non-market = public admin + education + health + ownership-of-dwellings (the `q_pubadm/q_edu/q_health/q_dwellings` columns in `market_sector_capital.csv`). The mining split is an *orthogonal partition of a different base*. To avoid representing the same dwellings/health/education VA three ways (once in `yhat_nonmarket`, once in a non-mining CES clone, once via the I-O G-routing), the design adopts a **clean three-way partition of GVA**:

$$\underbrace{\text{Mining}}_{w_{qn,m}} \;+\; \underbrace{\text{Non-mining market}}_{w_{qn,nm}} \;+\; \underbrace{\text{Non-market}}_{w_{qn,nmk}} \;=\; 1$$

with (chain-volume base-year shares, all computed by `build_io_bridge.py`, see §3):

| Branch | VA share | Model treatment |
|---|---|---|
| Mining | `w_qn_m = 0.1180` | NEW thin supply block (§2.1) |
| Non-mining **market** | `w_qn_nm = 0.6043` | CES + FOC + PAC clone (§2.2) |
| Non-market public (pubadm+edu+health) | `w_qn_nmk = 0.1849` | `yhat_nonmarket`-style trend (`:1667-1671`) |
| Ownership of dwellings | `w_qn_dw = 0.0928` | SEPARATE statistical trend (FR-BDF convention) |

**FOUR-way partition (decision 2026-06-01).** Per the user, ownership of dwellings is kept as its **own separate statistical trend**, distinct from both the non-mining-market CES and the non-market public-services branch (FR-BDF treats own-dwellings separately — CES doc §1). Shares are chain-volume FY2022-23 from `data/market_sector_gva_splits.csv`; sum to 1.0000.

> **PHASE-0 DATA CORRECTION (2026-06-01, verified from `io_tables_australia.xlsx` + the fixed `market_sector_gva_splits.csv`, independently re-derived).** The partition above was originally drafted as **0.117 / 0.72 / 0.16**; the live data gives **0.118 / 0.604 / 0.278** (sums to 1.0; chain-volume FY2022-23; the I-O nominal basis gives 0.1166 / 0.6022 / 0.2813 — same story). Two fixes: (1) the original "0.72" was actually the *whole market* share `q_market/q_total = 0.722`, which still **includes** mining — non-mining-market is `q_market − q_mining ≈ 0.604`; (2) the original "0.16" **under-counted non-market** — public admin + education + health + **ownership of dwellings** is ~**0.278** of GVA, not 0.16. The existing model's `w_market = 0.85` (⇒ non-market 0.15) uses a narrower non-market definition that **excludes ownership of dwellings** (≈9% of GVA). **Decision required in Phase 1:** route ownership of dwellings to the non-market/statistical-trend branch (FR-BDF treats dwellings separately — CES doc §1), giving the 0.604/0.278 split above; do **not** silently fold dwellings into the non-mining-market CES.

**Decisive correction (retained):** the first-pass design's "non-mining = 88.3% of GVA" conflated non-mining-market with non-mining-including-non-market. The CES clone covers **non-mining MARKET only** (~0.60 of GVA), and the I-O bridge must route the **G (government) expenditure component to the non-market branch** (bridge weight `w_nm_g = 0.886` confirms G is ~89% non-market VA), not to the non-mining-market CES. The existing `w_market = 0.85`, `rho_nonmarket = 0.90`, `gamma_nonmarket = 0.30` (`:2110-2112`) survive but must be **re-derived on the corrected ~0.278 non-market weight**; `yhat_market` is re-interpreted as `w_qn_m·yhat_m + w_qn_nm·yhat_nm`.

### 1.4 What this delivers that the single-sector model cannot

- A **real-GDP vs real-gross-domestic-income wedge** — the terms-of-trade trading gain. Australia's single most important macro quantity; the single-sector model literally cannot represent it.
- A **capacity ratchet**: a commodity boom that builds an LNG train permanently raises mining potential (`ln_QN_m`) — the train keeps running when the price falls — while a pure monetary shock leaves mining potential untouched. Aggregate long-run money neutrality is preserved *through the non-mining channel* (~72% weight) while genuine non-neutrality to *commodity* shocks flows through mining.
- A **falsifiable monetary-transmission result**: the aggregate output response to a 100bp MP shock should shrink by roughly the mining weight, because mining is near-inert to the domestic rate.

---

## 2. Economic architecture: the equations

All new mining variables carry `_m`; non-mining-market clones carry `_nm`; the non-market branch is unchanged. **Everything is in stationary-gap space** (the model's invariant: `max|steady_state| = 0`). No I(1) level enters any forward sum or PAC VAR.

### 2.1 The MINING supply block (thin, no PAC, no FOC)

**Capacity-driven potential output.** Mining potential grows with lagged effective mining capital plus a slow mining productivity trend. There is **no** labour-FOC term and **no** `lambda_hyst·rw_gap` hysteresis (meaningless for a price-taker):

$$\ln QN_m = \ln QN_{m}(-1) + \Delta\ln y^{*}_{m}, \qquad \Delta\ln y^{*}_{m} = \kappa_{qk,m}\,\Delta\ln k_{m}(-h_m) + \Delta\ln tfp_m$$

$$\Delta\ln k_m = (1-\delta_{k,m})\,\Delta\ln k_m(-1) + \delta_{k,m}\,\Delta\ln ib_m, \qquad \ln K_m = \ln K_m(-1) + \Delta\ln k_m$$

with a lag chain `dln_k_m_1..dln_k_m_4` (analogue of `dln_n_1/2/3`, `:1295-1302`). **`kappa_qk_m` is CALIBRATED, not estimated** (see §4.1 — the growth regression returns R²<0.02, t<2, and the DOLS level form is spurious with DW=0.062). Set `kappa_qk_m = 1` (constant returns to mining capital in capacity, a theoretical restriction) and absorb timing into `h_m` (calibrated by annual-frequency grid, default 4).

**Mining utilisation gap.** Actual mining VA wobbles around capacity with a *small* terms-of-trade response (maintenance/weather/demand pulses). **`q_m_gap` is the single mining gap object used everywhere** (resolving the first-pass `q_m_gap`/`u_m_transitory`/`yhat_m` naming collision — `yhat_m ≡ q_m_gap`):

$$q_{m,gap} = \rho_{qm}\,q_{m,gap}(-1) + \psi_{qm}\,tot_{gap} + \varepsilon_{q,m}, \qquad \ln Q_m = \ln QN_m + q_{m,gap}$$

`rho_qm` and `psi_qm` are **estimated** (the only genuinely data-identified mining behavioural parameters; expect `rho_qm≈0.7`, `psi_qm` small — if insignificant, set `psi_qm=0` ⇒ `ln_Q_m = ln_QN_m` exactly, the cleaner MARTIN-faithful fallback). `tot_gap` is the **stationary** terms-of-trade gap (§2.4), never an I(1) level.

**Mining investment — commodity-price/Tobin's-q ECM, stationary-gap form.** No user-cost FOC (which fails on AU data), no PAC expectation, no I(1) `pcom_level`:

$$q^{tobin}_{m,gap} = pcom_{gap} - p_{Q,nm,gap} \quad\text{(both stationary deviations from trend)}$$

$$ib^{*}_{m,hat} = \theta_{ibm}\,q^{tobin}_{m,gap} - \sigma_{ibm}\,(i_{10y}-i_{ss})$$

$$\Delta\ln ib_m^{level} = b0_{ibm}\,(ib^{*}_{m,hat}(-1)-\ln ib_m^{level}(-1)) + b1_{ibm}\,\Delta\ln ib_m^{level}(-1) + b2_{ibm}\,\Delta\ln ib_m^{level}(-2) + b3_{ibm}\,\Delta\ln pcom + \varepsilon_{ib,m}$$

`theta_ibm` and the ECM speeds are **estimate-with-mandatory-calibration-fallback** (§4.4): identified off a single boom, on a capex series that must be assembled (sum states, X-13 SA, deflate) from `abs_5625` or split from national 5625-07. Pre-commit the fallback `b0_ibm=0.07, b1_ibm=0.4, b2_ibm=0.2, b3_ibm=0.2, theta_ibm=0.3, sigma_ibm=0.05` if R²<0.1 or signs wrong. `sigma_ibm` (the *only* monetary channel into mining) is calibrated small.

**Mining-capex import nexus (FIX — was missing).** A large share of mining capex is imported (LNG modules, equipment; I-O import content of investment 16.3%, non-ferrous 18.1 per \$100). Wire it so a mining investment boom does **not** show as pure domestic GDP gain:

$$\Delta\ln m_{ne} \;\mathrel{+}=\; \omega_{m,imp}\cdot w^{ib}_m\cdot \Delta\ln ib_m \quad (\omega_{m,imp}\approx 0.17)$$

i.e. add the import-content of mining capex to the non-energy import volume driver (the live import block at `:1462` already carries `iad`; this adds mining capex to its IAD content).

**Mining employment — thin, output-derived (CALIBRATED, gated on data).** Mining N follows output with capital-deepening; **no employment PAC**:

$$\ln N_m = \ln N_m(-1) + n_{q,m}\,(\ln Q_m - \ln Q_m(-1)) - \Delta\ln prod_m + \varepsilon_{n,m}$$

`n_q_m` (≈0.5) and `dln_prod_m` are **calibrated** (the ABS 6291 mining employment series does not yet exist; gate on its download — §3). `share_n_m≈0.02` from published aggregates.

**Mining VA deflator — world-price taker (CALIBRATED, defined not estimated).** The mining VA deflator *is* the AUD commodity price; it is **not** regressed on `dln_pcom` (that is a tautology returning α≈1 with a fake t-stat). Drive it **directly off the model's existing real commodity driver `dln_pcom`** — do **not** introduce a nominal `dln_s_aud` decomposition (the model has no nominal exchange-rate level; `s_gap` is a stationary RER gap that mean-reverts and cannot supply a persistent AUD translation):

$$\pi_{Q,m} = \rho_{pQm}\,\pi_{Q,m}(-1) + \alpha_{pQm}\,\Delta\ln pcom + (1-\rho_{pQm}-\alpha_{pQm})\,\bar\pi_{au} + \varepsilon_{pQm}$$

with `alpha_pQm = 1, rho_pQm = 0` calibrated (full contemporaneous pass-through). The existing `alpha_pcom=0.5843` channel into `pi_x` (`:1514`) is reused — this plumbing already 60% exists.

### 2.2 The NON-MINING (market) block — faithful FR-BDF clone

The entire A.1-A.6 single-sector stack is cloned `_nm` and re-estimated on non-mining-**market** data. Spine:

$$\Delta\ln y^{*}_{nm} = \alpha_{nm}\,\Delta\ln k_{nm} + (1-\alpha_{nm})\,\Delta\ln n^{*,bar}_{nm} + \Delta\ln tfp_{nm}, \qquad \ln QN_{nm} = \ln QN_{nm}(-1) + \Delta\ln y^{*}_{nm}$$

The **three factor-demand PAC blocks** (VA-price `pQ_nm`, employment `n_nm`, business-inv `ib_nm`) are cloned verbatim in structure, re-estimated on non-mining series, each with its own aux file (`aux/aux_pQ_nm.mod`, `aux/aux_employment_nm.mod`, `aux/aux_business_inv_nm.mod`) regenerated by `pac.print()`. Key clone details:

- **CES dual pass-throughs are algebraically PINNED, not estimated**: `gamma_ulc_nm = (1-alpha_nm)·sigma_nm`, `gamma_uck_nm = alpha_nm·sigma_nm`. With expected `alpha_nm≈0.32, sigma_nm≈0.50` (non-mining is far less capital-intensive than the mining-inflated aggregate `alpha_k=0.45`) these become `gamma_ulc_nm≈0.34, gamma_uck_nm≈0.16` — labour-cost pass-through rises, capital-cost falls.
- **Non-mining investment keys off non-mining activity `yhat_nm`, not aggregate `yhat_au`** (MARTIN §4.4.1: use GNE not GDP, so a mining-driven GDP boom does not spuriously pull up non-mining capex). Add a mining-investment-share **crowding term** `+ lambda_crowd·(ib_share_m − ib_share_m_ss)` to `ib_hat_nm` (Corden-Neary resource-movement proxy).
- **Real-wage gap uses the sector VA price, NOT the composite**: `rw_gap_nm = pi_w − piQ_nm − dln_prod_nm`. The shared `pi_w` interacts with sector-specific marginal products. Keep this strict — no composite-`piQ` leak into the non-mining FOCs (or the `lambda_hyst_nm=0` neutrality test at Q200 is muddied by commodity volatility).
- **Hysteresis gate `lambda_hyst_nm`** appears in `dln_n_star_bar_nm` and `dln_ib_star_bar_nm`, default 0 (matching live `lambda_hyst=0`). Mining has **no** hysteresis term.

**Consumption and housing PAC blocks are NOT cloned** (households consume/build regardless of producing sector); they stay single. Their `pac.print()` h-vectors still regenerate because the shared belief-VAR changes (§5).

**The non-mining gap** (the clone of `:1110`, the *only* place demand pass-through lives):

$$yhat_{nm} = yhat_{nm}(-1) + yhat^{dom}_{nm} + \varepsilon_{q,nm}$$

where `yhat_dom_nm` is the I-O-bridge-weighted demand for non-mining-market VA (§2.3). Bridge coefficient is **unit** — `lambda_dom=0.399` (`:725`) is dead and must NOT be reintroduced.

### 2.3 The I-O bridge and the GDP(P)=GDP(E) closure that actually balances

**One valuation basis, one primary identity.** The first-pass design mixed a basic-price expenditure vector with a purchasers'-price tax wedge, creating a phantom A\$148bn / 6.29% discrepancy. **Fixed:** the IO Table 2 final-demand columns are at **basic prices** and reconcile to **GVA + 20,279 = GDP-E**, i.e. the true taxes-on-products wedge on this basis is **0.8% of GDP, not 6.29%**. All bridge weights, sector potentials `ln_QN_m/ln_QN_nm`, and the tax term are on the **basic-price basis**, asserted: `GDP-E = GVA + wedge` to <0.1%.

**The demand driver (feeds the non-mining-market gap).** `yhat_dom_nm` is the live `yhat_dom` (`:1528`) re-weighted by non-mining-market VA content, with **G routed to the non-market branch, not here**:

$$yhat^{dom}_{nm} = w^{nm}_c\,\Delta\ln c + w^{nm}_{ib}\,\Delta\ln ib_{nm} + w^{nm}_{ih}\,\Delta\ln ih + w^{nm}_{xnr}\,\Delta\ln x_{nonres} - w^{nm}_m\,\Delta\ln m_{nm}$$

Bridge weights (computed from `io_tables_australia.xlsx`, the non-mining-market VA destination shares; `build_io_bridge.py` is the single source of truth — no hand-pasted "verified this session" numbers). The non-mining gap takes **only the non-resource export stream** `dln_x_nonres`; resource exports `dln_x_res` are the expenditure-side image of mining VA (below) and are excluded here to avoid double-counting.

**The resource-export bridge — dimensionally correct (FIX).** The first-pass `dln_x_res = 0.726·dln_Q_m` was dimensionally wrong: it coupled gross-output exports to value-added, and resource exports actually *exceed* mining VA by 13% (330,588 vs 292,712; VA/output = 0.643). **Fixed by choosing one basis:** build `ln_Q_m` as mining **value added**, and map to resource-export *volume* with the VA-to-export elasticity and an explicit domestic-absorption term:

$$\Delta\ln x_{res} = \eta_{xm}\,\Delta\ln Q_m - (1-\phi_{abs})\,\Delta\ln d^{intm}_m + b_{xres}\,s_{gap} + \varepsilon_{x,res}$$

with `eta_xm = 330588/292712 ≈ 1.13` (VA-to-export elasticity, calibrated from I-O), `phi_abs` the domestic-absorption share. Operationally the absorption term moves slowly, so `dln_x_res ≈ 1.13·dln_Q_m + b_xres·s_gap + eps_x_res`. **Build-time assertion** (the double-count guard): resource-export VA must equal mining VA minus domestic mining absorption minus mining's imported intermediate content (`455,366 output − 124,778 domestic use − 19,312 imported inputs`). `b_xres` (RER on resource exports) is **calibrated small** — the live aggregate export RER elasticity `b3_x=-0.36` is already insignificant; splitting into thinner series cannot manufacture identification.

**Mining capex stays out of the production bridge (FIX).** `ln_ib_m` feeds `dln_k_m` (capacity) **only**. A dollar of mining capex generates ~98% *non-mining* VA (construction, machinery, engineering services); its VA content is routed to non-mining via the normal investment bridge weight, **not** peeled off to mining. (Confirmed by the I-O attribution `b_m,I = 0.02`.) This preserves the Corden-Neary logic instead of inverting it.

**Composite exports** (mirrors the live import `w_m_ne/w_m_e` template at `:1432`):

$$\Delta\ln x = w_{x,res}\,\Delta\ln x_{res} + (1-w_{x,res})\,\Delta\ln x_{nonres}, \qquad w_{x,res}\approx 0.51$$

`dln_x` enters `yhat_dom` (`:1528`) unchanged. **Retire** the embryonic `b4_x=0.15` channel (`:1421`, superseded by `dln_x_res ← dln_Q_m`) and the dead aggregate import ECM (`ln_m_eq/m_gap/beta_m/gamma_m`, `:1411-1427`) — in a **separate commit before the split** so their BK-neutrality is verified in isolation. **Confirm `w_iad_ne_x` still sees the new `dln_x`** so imported mining inputs are still subtracted.

**The closure — `yhat_dom` is NEVER redefined; the residual is reported (FIX for the singular-system + free-plug errors).** Keep `:1528` as the sole definition of `yhat_dom`. Build the aggregate gap from the sector gaps, and **define** `sd_gap` as the ex-post residual (diagnostic only, no `(+1)`, no `varexo` feedback into `ln_Q`):

$$yhat_{au} = w_{qn,m}\,q_{m,gap} + w_{qn,nm}\,yhat_{nm} + w_{qn,nmk}\,yhat_{nonmarket}$$

$$\boxed{sd_{gap} \;\equiv\; yhat_{dom} - \big(w_{qn,m}\,q_{m,gap} + w_{qn,nm}\,yhat_{nm} + w_{qn,nmk}\,yhat_{nonmarket} + \tau^{prod}_{gap}\big)}$$

- `yhat_dom` stays the GDP-E definition (`:1528`); `yhat_au` is the production-side aggregate. `sd_gap` is a **reported** identity that does not feed any structural equation — it is the *integration test*, not a free shock.
- **The systematic part of the wedge is carried deterministically.** `tau_prod_gap` carries the **0.8% product-tax wedge** plus the deterministic Törnqvist fixed-weight chain-drift (~30-40 bp/yr during the boom), computed offline. `sd_gap` then contains only the genuinely random ABS statistical discrepancy (<1% of GDP, near-zero mean). **Hard assert:** `var(sd_gap)` stays within the published ABS GDP-P/GDP-E discrepancy band; if it blows up, the resource-export/mining-VA bridge is inconsistent — do not let it silently absorb a double-count.

### 2.4 Terms-of-trade objects (new, shared, stationary)

$$tot = \pi_x - \pi_m, \qquad tot_{gap} = tot - tot_{trend}$$

`tot_gap` is the **stationary** ToT gap that drives mining utilisation (`psi_qm`) and the Tobin's-q investment gap. `tot_trend` is a slow deterministic/exogenous trend so `tot_gap` is mean-reverting. **No I(1) `tot_level` enters any forward sum or PAC VAR.**

**Terms-of-trade income effect on consumption (FIX — was only a "payoff", now wired).** A commodity boom that lifts national income but does not feed consumption under-models Australia's single most important macro channel. Add a stationary real-gross-domestic-income gap term to the consumption LR target:

$$c^{*}_{hat} \;\mathrel{+}=\; \lambda_{toti}\cdot tot_{gap}$$

`lambda_toti` is **estimated** (regress consumption ECM residual on `tot_gap`; expect positive, the trading-gain wealth/income effect). If v1 cannot identify it, state honestly that v1 omits the ToT income effect and flag the limitation — do not silently drop it.

### 2.5 Aggregate VA deflator and the GDP deflator channel

$$\pi_Q = w_{pq,m}\,\pi_{Q,m} + w_{pq,nm}\,\pi_{Q,nm} + w_{pq,nmk}\,\pi_{Q,nmk}$$

This composite is **report-only** — it feeds the GDP deflator so a ToT boom raises the GDP deflator without raising CPI (CPI is ~1.3% mining content). **The composite `piQ` does NOT enter any PAC VAR** (§5, blocking-issue fix): the PAC blocks believe and forecast `piQ_nm` (the smooth markup price), not the commodity-contaminated composite.

---

## 3. Data-construction recipe

**Toolchain reality** (`next_session.md`): RBA CSVs download via `tables/csv/<table>-data.csv`; ABS "latest-release" landing pages return HTML — use the versioned `.xlsx` URL or the ABS Data Explorer SDMX-JSON API. All paths absolute under `/Users/davidstephan/Documents/AUSPAC`.

### 3.1 What EXISTS vs MUST-BUILD

| Series | Status | Source / location |
|---|---|---|
| `K_mining`, `K_nonmining_market` (annual, clean) | **EXISTS** | `data/market_sector_capital.csv`; built by `build_market_sector_capital.py` (K_mining = ABS 5204 T63 col 12; K_nonmining_market = K_market − K_mining) |
| `Q_mining`, sub-industries, `Q_total`, non-market cols (SA, quarterly) | **EXISTS** (raw) | `data/abs_rba/abs_5206_industry_gva.xlsx` Data1 SA \$M levels: mining col **119**; total **161**; pubadm **155**, edu **156**, health **157**, dwellings **160** |
| `market_sector_gva_splits.csv` | **BUG — fix FIRST** | mixes levels and growth across columns; `q_nonmining_market = −73,879` (level minus growth). Fix `build_market_sector_capital.py` (~1 hr, unblocks CES regardless of harder downloads) |
| Commodity price driver | **EXISTS** | `data/abs_rba/rba_i02_commodity.xlsx`, `rba_g02_commodity.csv` → maps to `dln_pcom` |
| Mining capex (for ramps/`theta_ibm`) | **EXISTS but raw** | `data/abs_rba/abs_5625_19_*_mining_*_capex.xlsx` (current-price, ORIGINAL, by state/asset — must sum states, X-13 SA, deflate) |
| I-O tables | **EXISTS** | `data/io_tables_australia.xlsx` (Table 2 USE, Table 7 Leontief ÷100, Table 17 VA/import content; mining = IOIG codes 601/701/801/802/901/1001) |
| **Mining + non-mining employment `N`** (SA, quarterly) | **MUST DOWNLOAD** | ABS 6291.0.55.003 EQ06 (employed by industry division, Mining=B); SDMX API |
| **Hours `H`** | **MUST DOWNLOAD** | ABS 6291.0.55.003 EQ09 |
| **Current-price industry GVA** (for VA deflator) | **MUST DOWNLOAD** | ABS 5206 **Table 5** — confirmed absent from repo file (Data2 has no SA current-price Mining column) |
| **By-industry WPI** | **MUST DOWNLOAD** | ABS 6345.0 by-industry (in-repo 6345 is aggregate-only) |

### 3.2 The `build_market_sector_capital.py` fix (do FIRST)

Pin the six SA \$-million LEVEL columns explicitly and **assert series-type/unit before reading values**:

```python
SA_TOTAL=161; SA_MINING=119; SA_PUBADM=155; SA_EDU=156; SA_HEALTH=157; SA_DWELL=160
for ci in (SA_TOTAL, SA_MINING, SA_PUBADM, SA_EDU, SA_HEALTH, SA_DWELL):
    assert "Seasonally Adjusted" in str(rows_q[2][ci])
    assert "$ Millions"          in str(rows_q[1][ci])
```

Delete the fragile string-matching/fallback block and the unit-blind `read_quarterly_col`. Re-run → six consistent chain-volume levels. **Asserts:** `(q_mining>0).all()`, `(q_nonmining_market>0).all()`, mining VA share of market GVA in 2022-23 ∈ [0.08, 0.16].

### 3.3 `build_io_bridge.py` (NEW — single source of truth for bridge weights)

Reads `io_tables_australia.xlsx`; emits `data/io_bridge_coefficients.csv` + `data/closure_shares.csv`. Algorithm: `B = V̂(I−A)⁻¹` (V̂ = diag VA-ratios from Table 2; (I−A)⁻¹ = Table 7 ÷ 100); for each final-demand column compute induced VA, sum mining product rows → mining VA per component.

**Basis fixes the reviewers required:**
- **Product-vs-industry basis must be explicit.** Table 7 is a **product-by-product** Leontief; the mining aggregation is by **industry** code. For the mining-vs-non-mining cut these coincide to 0.6% (mining product ≈ mining industry in AU), but the script must state the basis and **assert the 6 selected rows have codes exactly {601,701,801,802,901,1001}** (a code-equality assert, not a row-number assert — the first-pass design was internally inconsistent on "rows 7-12" vs "8-13"; the offset is product-row = code-row + 1 because of the header). For the *deferred* finer splits (agriculture, manufacturing) product≠industry diverges and a full supply-use bridge (Table 1) is required.
- **Single valuation basis (basic prices), tax wedge 0.8%.** Assert `GDP-E = GVA + 20,279` to <0.1%.

**Hard asserts in the script** (fail loudly): reconstruction (induced mining VA ≈ direct, <2%); column shares sum to 1; `mining_va_share[X] > 0.40` (guards against a transposed Leontief); bridge-implied final demand reconciles to published GDP-E within the discrepancy band; chain-volume vs nominal `w_qn` shares reported **separately** (they diverge in booms — the real-GDP/real-GDI point).

Pin **one** `w_qn_m`: use the **chain-volume base-year** share for the volume aggregation `ln_QN/yhat_au` and the **nominal** share only for the deflator composite. Reconcile the first-pass 0.117/0.1066/0.1166 spread to a single number per use.

### 3.4 Per-sector CES / supply calibration inputs

Extend `prepare_supply_data.m` to write `q_nm_lvl, k_nm_lvl, q_m_lvl, k_m_lvl, n_nm_lvl, n_m_lvl, h_nm_lvl, h_m_lvl, p_q_nm_lvl` into `supply_data.mat` (non-mining-**market** series = market minus mining minus non-market; mining from col 119 / 5204 col 12 / 6291 Division B). **Mining trend estimated on CHAIN-VOLUME mining GVA only** — the COVID episode for mining was a price collapse-then-spike (iron ore ~\$80→\$230/t), not a volume/capacity loss; handle price in the deflator block, not the capacity trend.

**Build sequence (one pass):**
```
1. python3 data/build_market_sector_capital.py        # fix unit bug FIRST
2. matlab -batch "cd data; download_sector_labour"     # ABS 6291 EQ06/EQ09, 6345-by-industry, 5206-T5
3. python3 data/build_io_bridge.py                      # bridge + closure CSVs (asserted)
4. matlab -batch "cd data; prepare_supply_data"         # extended supply_data.mat
5. matlab -batch "cd data; sector='nonmining'; estimate_ces_2026"   # -> ces_2026_calibration_nm.mat
6. matlab -batch "cd data; estimate_mining_supply"      # rho_qm, psi_qm only; kappa/h calibrated
7. paste calibration numbers + CSV values into au_pac.mod parameter block
```

---

## 4. Estimation / calibration plan (honest est-vs-cal ledger)

The first-pass design over-claimed estimability. Below is the corrected ledger; the rule is the project philosophy **plus** the empirical reality that OLS-over-calibration only applies *when OLS is meaningful*.

### 4.1 Two CES calibrations

Run `estimate_ces_2026.m` twice via a `sector` switch.

- **Non-mining (market): ESTIMATE.** Removing mining removes the labour-cost/productivity wedge the script blames for the aggregate's DW<1 cointegration breakdown (`estimate_ces_2026.m:321-323`), so the level regression should improve. Expected: `sigma_nm≈0.45-0.55`, `alpha_nm≈0.32-0.38` (down from the mining-inflated 0.45), `gamma_nm≈0.06-0.10`. **This is a hypothesis the split tests, not an established result** — GATE 1 stops if `sigma_nm` fails (DW<1.5 and FD wrong-signed), with calibration fallback `sigma_nm=0.5366, alpha_nm=0.35`.
  - **REALIZED (Phase-0 run, 2026-06-01): GATE 1a = FALLBACK.** The hypothesis was **rejected** on AU data. The non-mining labour FOC still does **not** cointegrate in levels (DW=0.32, `sigma_lvl=0.118`); the clean FD spec (DW=1.77, t=3.62) gives `sigma=0.288` and the Bayesian posterior `sigma_nm=0.364` — **below** the [0.4,0.6] band. Per the documented fallback the model proceeds on `sigma_nm=0.5366, alpha_nm=0.35` (⇒ `gamma_ulc_nm=0.349, gamma_uck_nm=0.188`); `gamma_nm=0.106` (data, matches design 0.1064). Lesson: removing mining does **not** repair the AU cointegration breakdown — the labour-FOC instability is broader than the mining wedge (consistent with [[project_au_flat_phillips]]). Artifacts: `data/estimate_ces_2026_sector.m`, `dynare/ces_2026_calibration_nm.mat`.
- **Mining: CALIBRATE (the CES procedure rejects).** The labour-FOC presumes demand-determined output and a cost-minimising relative price; mining is a quantity-setting price-taker whose `P_Q` is the commodity price. The Solow-residual inversion hits the feasibility guard for mining. **Do not estimate `sigma_m`** (no factor-substitution block); calibrate `alpha_m` from the mining GOS share (ABS 5204 T48 / IO P2). `kappa_qk_m=1` (theoretical restriction), `h_m` from annual-frequency grid.
  - **REALIZED (Phase-0 run): mining CES rejected as predicted** (level DW=0.13, t=1.25 insignificant, R²=0.015). `alpha_m = 0.84` calibrated from the **actual** mining GOS share (IO 5209 P2/V1 = 0.841 over mining IOIG cols; mining VA 292,712 ties exactly to the bridge) — **higher than the anticipated 0.60-0.70**, written back per data-over-calibration. `gamma_m=0.068`. `sigma_m` stored for record only, unused. Artifact: `dynare/ces_2026_calibration_m.mat`.

### 4.2 Non-mining PAC blocks: re-fit all three

`pac_pQ_nm` (VA deflator), `pac_n_nm` (employment), `pac_ib_nm` (business inv, keyed off `yhat_nm` + crowding term). Estimable; write back OLS verbatim unless Dynare fails or signs are wrong (then calibration fallback). `b2_pQ_nm` (output-gap pass-through) may again be insignificant (the AU flat-Phillips finding) — accept the OLS estimate.

### 4.3 Mining PAC blocks: NONE

Mining adds **zero** PAC blocks (the key risk-containment decision). Mining VA-price = the calibrated commodity pass-through (§2.1); mining employment = calibrated output-derived; mining investment = a stationary-gap ECM that does **not** enter any PAC expectation.

### 4.4 Reclassified to CALIBRATED (the data does not identify them)

| Parameter | First-pass | Corrected | Reason |
|---|---|---|---|
| `kappa_qk_m` | Estimate 0.85 | **Calibrate = 1** | OLS R²<0.02, t<2; DOLS DW=0.062 spurious; quarterly K is interpolated from annual (mechanical smoothness) |
| `alpha_pQm`, `rho_pQm` | Estimate | **Calibrate (1, 0)** | deflator series absent; regressing it on `dln_pcom` is a tautology |
| `n_q_m`, `dln_prod_m` | Estimate | **Calibrate** | mining employment series absent (gate on 6291 download) |
| `b_xres`, `beta_xnr`, `gamma_xnr` | Estimate | **Calibrate (wp1044)** | live aggregate RER elasticities already insignificant; thinner series worsen it |
| break dates (2002Q2, 2012/2015) | Estimate | **Fix from narrative** | single-episode collinearity with `kappa`/TFP trend |

**Genuinely estimated mining objects:** `rho_qm`, `psi_qm` (AR persistence + small ToT response of the utilisation gap), `theta_ibm` + mining-investment ECM speeds (with mandatory calibration fallback), `lambda_toti` (ToT income effect on consumption).

### 4.5 RER-level prerequisite

**No nominal `dln_s_aud`.** Mining prices/ToT objects are driven directly off `dln_pcom` (already real in the model's logic) and the existing stationary `s_gap`. If a commodity-price level is unavoidable for the capacity ramp, it enters **only** backward-looking identities (like `ln_K`) and is detrended before touching any forward sum or PAC VAR.

---

## 5. Dynare surgery: vars / params / shocks, the PAC regen, BK/IRF revalidation

### 5.1 The PAC self-consistency requirement (the central blocking fix — reject Option A)

The first-pass "keep `yhat_au`, just re-run `pac.print()`" shortcut is **rejected**. Redefining `yhat_au` from the backward accumulator (`:1110`) to a static weighted identity **changes the law of motion of a core state**. Every PAC expectation is `pac_expectation_pac_X = h_pac_X_constant + h_pac_X_var_yhat_au_lag_1·yhat_au(-1) + …`, where the frozen h-vector is the closed-form projection computed **under the agents' belief AR** for `yhat_au` (`aux_pQ.mod:122`, `lambda_q=0.6959`). If `yhat_au` becomes a contemporaneous function of `yhat_nm` and `q_m_gap` (whose laws of motion are entirely different), the frozen h-vectors project onto a belief that no longer matches reality — a **silent IRF corruption BK will not catch**, re-opening the logged "h_pac not self-consistent" wound.

**Required fix:** rewrite the belief-VAR in **every** aux file to be consistent with the new structural `yhat_au`. Concretely, add `var_yhat_nm` (slow-accumulator belief) and `var_q_m_gap` (AR(1) with `tot_gap`) to the E-SAT `var_model` lists, replace `var_yhat_au` with the identity (or drop `yhat_au` from the state and let PACs key directly off `yhat_nm`), then **regenerate all five existing h-vector families** (`h_pac_{pQ,n,ib,c,ih}_*`) **plus the three new `_nm` families**. This is mandatory Phase-3 work.

**Likewise `piQ`:** the composite (commodity-contaminated) `piQ` must **not** enter any PAC VAR. The agents believe and forecast **`piQ_nm`** (smooth AR(1), `rho_piQ=0.85`); the composite `piQ` is report-only. This keeps commodity volatility out of the discounted-sum projection entirely — consistent with mining being a price-taker outside the PAC machinery.

### 5.2 The correct PAC convergence bound

Every "will it diverge" judgement must use the **operative, project-verified** condition `chi_block · max|eig(Φ_block)| < 1` (from `verify_pac_chi_pv.m`), **not** `1/√β_pac ≈ 1.0102` (a phantom threshold). Measured baselines: va_price 0.1725, consumption 0.0094, employment 0.1944 (use `chi=0.40`, **not** the stored 0.21 — it is not a root of the employment characteristic polynomial), housing 0.3085, business_inv **0.554** (the binding block). There is large headroom; the real risk is only the employment block. Load each block's `chi` from `data/pac_blocks/results_*.mat`.

### 5.3 Hard build-time invariants (assert these)

1. **Mining stays out of every PAC VAR.** Grep all 8 aux files: `q_m_gap, tot_gap, ln_K_m, pcom_level, ln_Q_m, dln_x_res` must NEVER appear in any `var` list or `eqtags`. Pre-commit check.
2. **Exact BK determinacy: `n_exp == 5`.** The model has exactly 5 forward `(+1)` jumpers (`pv_u_gap, pv_yh, pv_r_lh_gap, pv_i, pv_i_uip` at `:1280/1308/1311/1365/1400`) = 5 explosive eigenvalues, `max|eig|=1.087`, zero spare roots. Assert `n_exp==5` and `max|steady_state|≈0` in `check_bk.m` at every phase gate. **Trace `yhat_au` through `pv_yh` (β_c=0.95) and `pv_u_gap` (β_w=0.98):** these forward sums now discount the redefined `yhat_au`; confirm `rho_qm` and the `yhat_nm` accumulator introduce no root the discounting cannot tame. If a 6th explosive root appears with no matching jumper, keep `pv_yh` keyed to `yhat_nm` only.
3. **`sd_gap` is diagnostic-only** — no `(+1)`, no `varexo`, computed ex-post, never feeds `ln_Q`.
4. **No I(1) level in any forward sum or PAC VAR.** Everything stationary-gap.

### 5.4 Dimension-count deltas (honest)

- **Endo vars: 182 → ~225-230** (+45-48). Non-mining clone ~26 + mining block ~10 (incl. 4 lag-chain vars the first pass undercounted) + ToT/bridge identities ~6.
- **Shocks: 55 → ~68-72** (+13-17). `eps_q_nm, eps_pQ_nm, eps_var_pQ_nm, eps_n_nm, eps_var_n_nm, eps_ib_nm, eps_var_ib_nm, eps_var_rKB_nm, eps_q_m, eps_ib_m, eps_n_m, eps_x_res, eps_pQm`. **No `eps_sd`** (sd_gap is diagnostic).
- **Params: ~358 → ~480-500** (+120-145), dominated by 3 new `h_pac_*_nm_*` families (~45) + re-printed existing 5.

### 5.5 Equations that CHANGE (not just additions)

| `:line` | Current | Becomes |
|---|---|---|
| 1185-1186 | `ln_QN = ln_QN(-1) + dln_y_star` | `ln_QN = w_qn_m·ln_QN_m + w_qn_nm·ln_QN_nm + w_qn_nmk·ln_QN_nmk` |
| 1110 | `yhat_au = yhat_au(-1) + yhat_dom + eps_q` | `yhat_au = w_qn_m·q_m_gap + w_qn_nm·yhat_nm + w_qn_nmk·yhat_nonmarket`; **`yhat_nm = yhat_nm(-1) + yhat_dom_nm + eps_q_nm`** |
| 1188-1189 | `ln_Q = ln_QN + yhat_au` | keep aggregate; add `ln_Q_nm = ln_QN_nm + yhat_nm`, `ln_Q_m = ln_QN_m + q_m_gap` |
| 1277 | `u_gap = -ln_n_level` | `u_gap = -(share_n_nm·ln_n_level_nm + share_n_m·ln_N_m)` — **gated on 6291**; until then `u_gap = -ln_n_level_nm` (mining 2%, negligible) |
| 1290/1337/1353 | `lambda_hyst·…` | non-mining keeps `lambda_hyst_nm`; mining omits the term entirely |
| 1421, 1411-1427 | `b4_x`; dead import ECM | **retire in a separate pre-split commit** |
| 1667-1671 | `yhat_market/yhat_nonmarket` | **retained**; `yhat_market` re-derived from the three-way partition |

### 5.6 Revalidation sequence

`check_bk.m` (assert `n_exp==5`, `max|steady_state|≈0`) → `validate_wave1.m` (add `ln_Q_m, ln_Q_nm, q_m_gap, yhat_nm, pv_yh, pv_u_gap` to var list; new invariants: a pure MP shock leaves `ln_QN_m≈0` at all horizons; aggregate `ln_QN` reverts only via non-mining) → `extract_irf_numbers.m` (new: a 10% `eps_pcom` shock permanently lifts `ln_QN_m`, ToT income effect lifts consumption) → `regen_all_artifacts.m` (PNGs, peaks, oscillation check — confirm `h_m` lag introduces no spurious oscillation).

---

## 6. Phased rollout with decision gates

**Two milestones.** Milestone 1 (Phases 0-2) delivers the genuinely new economics (real-GDP-vs-real-GDI, capacity ratchet, resource-export unification) **without touching the PAC machinery** — ~all the value at ~half the risk. Milestone 2 (Phase 3) is the separately-gated PAC-clone demand-side integration, contingent on Milestone 1 reproducing single-sector IRFs to <1e-6.

> **Prerequisite gate (Milestone 0):** the current single-sector model's open bugs — "hysteresis backwards at Q200" and "h_pac not self-consistent after SA fix" (`project_current_state_2026_05_30`) — must be **closed first**. Building a two-sector model on an inconsistent base makes split-induced bugs indistinguishable from inherited ones.

### Phase 0 — Data (2-3 sessions)
Fix `market_sector_gva_splits.csv` (~1 hr, do first). Download ABS 6291 EQ06/EQ09, 6345-by-industry, 5206-T5 via SDMX. Build `build_io_bridge.py` (asserted). Extend `prepare_supply_data.m`.
**GATE 0:** `supply_data.mat` has the non-mining-market and mining series (≥120 quarters), `q_mining+q_nonmining_market+q_nonmarket` chain-reconciles to `q_total`, all confirmed SA \$M levels. **Explicit fallback:** if 5206-T5 current-price is unobtainable, the mining VA deflator collapses to the `rba_i02` commodity proxy and the `piQ` composite is redesigned to not need a sector VA deflator. If 6291 returns Original-only (no SA Division-B back-series), the SA assumption in mining-labour is invalid — keep `u_gap` on non-mining only.

### Phase 1 — Three-way accounting split (CES only, BK-neutral) (2-3 sessions)
**Phase 1a:** add `ln_QN_m, ln_QN_nm, ln_QN_nmk` and the partition identities as **pure reporting aggregates** (`ln_QN` and `yhat_au` UNCHANGED as drivers). Run two CES calibrations.
**GATE 1a:** `check_bk.m` passes, `n_exp==5` exactly, `max|eig|~1.087`, IRFs bit-identical to single-sector. Non-mining `sigma_nm` estimable (DW_lvl>1.5, `sigma_nm∈[0.4,0.6]`); mining CES rejected as predicted ⇒ calibrated. *Stop if non-mining `sigma_nm` fails — use the calibration fallback and document.*
**Phase 1b:** redefine `yhat_au`/`ln_QN` to the weighted identities; rewrite the belief-VAR consistently (this is where the law-of-motion change first bites — but with **no behavioural split yet**, only the aggregation).
**GATE 1b:** two-sector `ln_QN` reproduces single-sector `ln_QN` IRF **to <1e-6** (named scalar: peak `ln_Q` response to 100bp `eps_i`, all horizons); `n_exp==5`.

### Phase 2 — Mining supply block + resource-export unification (2-3 sessions)
Capacity ratchet (`ln_QN_m ∝ ln_K_m(-h_m)`), commodity-price/Tobin's-q mining investment (stationary-gap), mining-capex import nexus, ToT objects + ToT income effect on consumption. **Unify** the queued export split: `dln_x_res = 1.13·dln_Q_m + …` (the dimensionally-correct VA-to-export elasticity), reconcile against aggregate `x_vol`. No PAC, no aux regen (mining touches no PAC VAR).
**GATE 2:** `check_bk.m` passes, `n_exp==5`; a 10% `eps_pcom` shock raises `ln_Q_m`/exports persistently and **ratchets `ln_QN_m` up (does not revert)**; a 100bp `eps_i` shock leaves `ln_QN_m≈0` at all horizons; `var(sd_gap)` within the ABS discrepancy band (the double-count guard); no IRF oscillation from `h_m`. *Re-run the resource/non-resource `b1` decomposition on SA data: do NOT carry the stale 0.78 — if SA resource `b1` is low (~0.1-0.3), the split is justified by VA-routing and double-count avoidance, not persistence.*
**→ MILESTONE 1 COMPLETE. Re-gate before Milestone 2.**

### Phase 3 — Non-mining PAC clones + I-O demand bridge (the C1/C2-risk phase, 6-10 sessions)
Clone the 3 PAC blocks to `_nm` (3 new aux files), re-fit on non-mining data, wire `yhat_dom_nm` through the bridge (G→non-market, C/I/IH→non-mining-market, X→split), re-derive `w_iad_*`. Rewrite the belief-VAR (`var_yhat_nm`, `var_q_m_gap`, `piQ_nm`-only state) and **regenerate all 8 h-vector families**, BK-check.
**GATE 3:** all `pac.print()` succeed (`chi·max|eig|<1` per block); `check_bk.m` passes, `n_exp==5`; long-run neutrality holds (MP shock reverts `ln_Q` via non-mining only); **named scalar gate:** non-mining `ln_Q` peak response to 100bp `eps_i` within **15%** of the old aggregate peak (since non-mining is ~72% of GVA, scale accordingly), at horizon = peak quarter, with calibration-fallback if exceeded; `var(sd_gap)` still bounded.

### Phase 4 — Regen / paper (1-2 sessions)
`regen_all_artifacts.m`; refresh paper §7 IRFs; new two-sector + real-GDP-vs-real-GDI section; update memory notes (supersede `project_potential_output_hysteresis.md` with the asymmetric neutrality result).

### Effort (honest, re-baselined)
| Phase | Sessions |
|---|---|
| 0 Data | 2-3 |
| 1 Three-way accounting split | 2-3 |
| 2 Mining supply + export unification | 2-3 |
| **Milestone 1 subtotal** | **6-9** |
| 3 Non-mining PAC + bridge (separately scoped) | 6-10 |
| 4 Regen/paper | 1-2 |
| **Total** | **13-21** |

The first-pass 6-10 was ~2-3× too optimistic against a 7-week-old project that needed multiple PR cycles for far smaller PAC changes. Phase 3 is ~half the effort and ~all the risk.

### Deferred to later rounds (explicit)
- **Finer industry splits** (agriculture, manufacturing): require a full product-vs-industry supply-use bridge (Table 1), not the mining shortcut. Do mining vs non-mining first, validate, then split.
- **Time-varying I-O bridge coefficients**: use **fixed** latest-vintage coefficients (matches MARTIN/ECB-BASE/FR-BDF); RAS-update offline. The one slow trend allowed: `w_x_res` tied to mining capacity. No time-varying coefficients in the `.mod`.
- **Sector-specific wage block**: keep ONE national `pi_w` (AU single national wage-setting). A mining wage *wedge* is a deferrable refinement.
- **Price-elastic mining capacity** (ToTEM/XMAS style): start with MARTIN's `output ∝ capital(-h)`; price-elasticity is a later upgrade.
- **Phase-3b** (existing PAC blocks forecasting `yhat_nm`): defer unless Phase-3 IRFs are materially wrong.

---

## 7. Risks / open-questions register

| # | Risk | Severity | Mitigation / status |
|---|---|---|---|
| R1 | **PAC h-vector self-consistency** under the new `yhat_au` law. Silent IRF corruption BK won't catch. | Blocking | Reject Option A; rewrite belief-VAR + regen all 8 families (§5.1). Gate on `validate_wave1` neutrality. |
| R2 | **`piQ` composite contaminating the PAC VAR** with commodity volatility. | Blocking | PAC VAR believes `piQ_nm` only; composite is report-only (§5.1). |
| R3 | **BK determinacy** — `pv_yh`/`pv_u_gap` forward sums now discount the redefined `yhat_au`; a 6th explosive root with no jumper = solve failure. | Blocking | Assert `n_exp==5` every gate; trace through β_c=0.95/β_w=0.98; keep `pv_yh` on `yhat_nm` if a root crosses (§5.3). |
| R4 | **I(1) levels** (`pcom_level`, `tot_level`, `ln_K_m`) leaking into forward sums / PAC VAR. | Blocking | Stationary-gap only; `q_tobin_m_gap`, `tot_gap` are deviations; levels only in backward identities (§2.1, §4.5). |
| R5 | **GDP(P)=GDP(E) closure** — wrong valuation basis / free-plug residual. | Blocking | One basic-price basis, 0.8% wedge, `yhat_dom` never redefined, `sd_gap` reported-only (§2.3). |
| R6 | **Resource-export double-count** — same iron-ore tonne in mining VA and as an independent export trend. | Blocking | `dln_x_res = 1.13·dln_Q_m` (one VA basis); build-time absorption assertion; `var(sd_gap)` as integration test (§2.3). |
| R7 | **Mining capex vs mining-VA-in-investment conflation** — double-crediting mining, inverting crowding. | Blocking | Capex→`dln_k_m` only; VA content (~98% non-mining) routed via normal bridge; import nexus wired (§2.1, §2.3). |
| R8 | **Market/non-market partition collision** — dwellings/health/edu modeled three ways. | Blocking | Three-way partition; CES clone = non-mining-MARKET (~72%); G→non-market; `yhat_nonmarket` retained (§1.3). |
| R9 | **`kappa_qk_m` not identified** (R²<0.02, spurious DOLS). | Blocking | Calibrate =1; `h_m` on annual frequency (§4.1, §4.4). |
| R10 | **Mining VA deflator / employment / capex series absent.** | Major | Gate on downloads; explicit fallbacks (§3.1, Phase 0). Reclassify dependent params to calibrated (§4.4). |
| R11 | **Stale `b1_x≈0.78`** export-persistence premise (live SA = 0.092). | Major | Dropped; re-run decomposition on SA; justify split by VA-routing not persistence (Phase 2). |
| R12 | **Non-mining CES identification gain unproven** (AU flat Phillips). | Major | GATE 1a stops on failure; calibration fallback `sigma=0.5366, alpha=0.35` (§4.1). |
| R13 | **Single-episode collinearity** (one boom for `kappa`/TFP/breaks). | Major | Fix break dates from narrative; calibrate `kappa`/TFP; estimate only `rho_qm`/`psi_qm` (§4.4). |
| R14 | **ToT income effect on consumption** under-modeled (Australia's key channel). | Major | Wired as `lambda_toti·tot_gap` in `c_hat` (§2.4); estimate, or flag omission honestly. |
| R15 | **Effort/scope realism** — 6-10 sessions too optimistic; building on a buggy base. | Major | Re-baselined 13-21; Milestone 0 prerequisite; two-milestone split (§6). |
| R16 | **Product-vs-industry I-O basis** off-by-one row indexing. | Major | Code-equality assert {601,701,801,802,901,1001}; product-row = code-row+1 (§3.3). |
| R17 | **`w_qn_m` nominal-vs-volume ambiguity** (0.117/0.1066/0.1166). | Minor | Volume share for `ln_QN`/`yhat_au`, nominal for deflator; pin one per use (§3.3). |
| R18 | **Chain-volume non-additivity** away from reference year. | Minor | Non-mining-market defined residually; deterministic drift in `tau_prod_gap`, tolerance documented. |
| R19 | **Mining COVID** — price swing mis-attributed to capacity loss. | Minor | Mining trend on chain-volume only; price in deflator block (§3.4). |

### Open questions to resolve in-flight
1. Does the SA resource-export `b1` collapse to ~0.1-0.3 (validating the SA-fix lesson) or stay high? Determines whether the export split needs any persistence treatment at all.
2. Is `psi_qm` significant? If not, `ln_Q_m = ln_QN_m` exactly (cleaner, strengthens the monetary-dampening result).
3. Is `lambda_toti` identified? If not, v1 ships without the ToT income effect (flag as a known limitation).
4. After GATE 3, do the *existing* (non-cloned) PAC blocks need to forecast `yhat_nm` too (Phase-3b), or is conditioning on the aggregate acceptable?

---

### Key file:line anchors
- Supply spine to clone: `au_pac.mod:1182-1237`; PAC blocks `:1011-1077`; trend FOCs `:1288-1337`; pinned `gamma_ulc/gamma_uck` `:562-563`.
- Gap accumulator `:1110`; `ln_QN` `:1185-1186`; `ln_Q` `:1188-1189`; `u_gap` `:1277`; hysteresis `:1290/1337/1353`; `yhat_dom` `:1528`.
- **Existing market/non-market block (retained): `:1667-1671`**; weights `:2110-2112`.
- Import-split template `:1432-1498`; dead import ECM to retire `:1411-1427`; `b4_x` to retire `:1421`.
- `s_gap`/UIP `:1399-1403`; `dln_pcom` `:1518-1519`; `tau_GST_gap` `:1648`.
- PAC mechanics: `aux/aux_pQ.mod:122` (belief AR), eqtag-ordered Φ `:100-113`; `verify_pac_chi_pv.m` (the correct `chi·max|eig|<1` bound; employment `chi=0.40` not 0.21).
- Validation: `check_bk.m` (assert `n_exp==5`), `validate_wave1.m`, `extract_irf_numbers.m`, `regen_all_artifacts.m`; `check_bk_report.txt` (`n_exp=5, max|eig|=1.087, max|steady_state|=0`).
- Data: `data/market_sector_capital.csv`; `data/build_market_sector_capital.py` (fix unit bug); `data/abs_rba/abs_5206_industry_gva.xlsx` (SA cols 119/155/156/157/160/161); `data/io_tables_australia.xlsx` (mining IOIG 601/701/801/802/901/1001); NEW `data/build_io_bridge.py`, `data/io_bridge_coefficients.csv`, `data/closure_shares.csv`, `data/estimate_mining_supply.m`, `dynare/ces_2026_calibration_nm.mat`.
- Consumed spec: `NEXT_PROJECT_export_resource_split.md` (integrate, do not run separately).


---

# 📚 REFERENCE — base AU-PAC model, backlog, archived docs

## Base AU-PAC model — block-by-block fidelity

| Block | Status | How AUSPAC gets the parameters |
|---|---|---|
| VA-price PAC | **AU-estimated** | iterative OLS (`results_va_price`), N=108, R²=0.41 |
| Wage Phillips | **AU-estimated** | BK-constrained OLS, κ_w=0.343 |
| Employment PAC | **AU-estimated** | OLS depth-3, exact χ=0.368 (`results_employment`), N=124, R²=0.86, b0_n=0.48 |
| Consumption PAC | AU-estimated (short-run) | OLS, β₀=0.23 ≈ wp1044 0.29; PV² operator not built |
| Housing inv PAC | AU-estimated (short-run) | OLS, b0_ih=0.60; price-spread on proxy pSH/pIH |
| **Business inv PAC** | **calibrated from wp1044** | Table 3.5.13 (Option 1 hybrid); AU rejects the PAC FOC (R²≈0.09) |
| Exports / Imports | short-run AU-OLS; LR borrowed | SA-data ECM; LR elasticities + energy-import block reverted to wp1044 (mining-composition issue → the active split) |
| Demand deflators | AU-OLS | per-deflator OLS; **CPI Phillips is flat** (R²=0.06, only persistence identified) |
| Supply / CES | calibrated (legit) | aggregate σ=0.5366, α=0.45, γ=0.0458 from wp1044 method; non-mining σ_nm=0.5366/α_nm=0.35 (fallback), mining α_m=0.84 |
| Financial / WACC / UIP | calibrated SS; AR(1) persistences AU-estimated | `rho_tp`/`rho_lh`/`rho_BBB`/`rho_LB_firms` estimated; `rho_s` still calibrated |
| Household credit / DSR (§3.7.2) | **AU-estimated** (exog AR(1)) | `DSR_gap` from RBA E2×F5; rationally-consistent stock pending |
| NFC accelerator (§3.7.3) | **AU-estimated** (leverage) | `lev_nfc_gap` from RBA D2 → spreads; endogenous stock pending |

**Fidelity rubric.** *AU-estimated* = every behavioural coef is an AU OLS point estimate (insignificant/wrong-signed
written back verbatim per the OLS-over-calibration convention). *AU-estimated (short-run)* = dynamics AU-estimated,
long-run target uses an HP-trend/proxy not a wp1044 FOC object. *calibrated from wp1044* = deep params imported because
AU data rejects (BI) or can't identify the restriction; documented, not a silent carryover. *calibrated (legit)* =
theoretical/SS quantities FR-BDF itself calibrates. ~40–45% of behavioural parameters are genuinely AU-estimated.

## Backlog (non-split work, deferred)
- **B1. Energy oil+gas split + HICP behavioural components** (wp1044 §3.6.4 / Appx E). Needs an AU energy price series
  (ABS 6457 petroleum sub-index, or Brent-in-AUD via RBA F11). Then split the energy-import block and promote the HICP
  food/energy reporting variables to behavioural equations.
- **B2. `rho_s` (real-exchange-rate gap)** — the `s_gap` equation carries a forward UIP term, so a bare AR(1) is
  misspecified; needs joint/IV estimation. TWI available (RBA F11).
- **B3. Trade long-run elasticities** — AU OLS gives wrong-signed/insig values (the mining-vs-non-mining composition
  artefact). **Now subsumed by the active industry split** (resource-export unification, §2 above).
- **C1. Quasi-endogenous employment/investment anchors** (wp1044 §3.4.3/§3.5.3) — replaces exogenous trend targets with
  conjuncture-responsive ones. Changes the VAR companion → `h_pac` regen + careful BK. (Same class of work as split Phase 3.)
- **C2. Rationally-consistent DSR/credit + NFC blocks** — make household debt / NFC leverage endogenous stocks (ECM) and
  add `DSR_gap`/`lev_nfc_gap` to the relevant aux-VARs + regenerate `h_pac` so agents anticipate the shocks.
- **C3. Hand-to-mouth + PV² consumption operator** (wp1044 §3.5.1) — promote `b_HtM` to estimated, build the PV² term.
- **D1. Extend `forecast_eval.m`** from 1-step to multi-horizon (h=1…8); optionally a recursive re-estimation variant.
- **D2. Two flagged model properties to review** — (a) the **large fiscal multiplier** (1%-of-GDP `eps_g` → output-gap
  +0.91%); (b) the **degenerate TFP→output transmission** (`eps_tfp_LR` σ=0.01 → ≈0 output at 1 s.d.).

## PAC-tooling roadmap (Dynare semi-structural techniques — scoped 2026-06-01)

Scoping verdict on adopting techniques from Srecko Zimic's `SemiStructDynareBasics` + the Dynare forum thread
(Brayton/Pfeifer/Adjemian), verified against the **local Dynare 7.0 source**. **Bottom line: mostly *validates* AU-PAC's
existing design** — the all-gaps formulation and monolithic `.mod` are deliberate correct responses to AU's
level-cointegration wall and a Dynare parse limitation, not debt to pay down. One safe win is done; the legitimate
remainder folds into split **Phase 3** (it all touches the belief-VAR Phase 3 rewrites anyway). Two myths corrected: the
"χ=0.21 bug" is **already fixed** in production (employment χ=0.368); AU's blocks are `kind='ll'` (stationary), so the
growth-neutrality term does not exist for them — and one must **never pass `kind=dd`** on them (it would silently corrupt
the h-vectors).

| Item | Verdict | When |
|---|---|---|
| Retire fragile depth-1 `solve_pac_chi.m` → `solve_pac_chi_exact.m` | **DONE 2026-06-01** — χ-preserving (depth-1 grid maxdiff 2e-16; `verify_pac_chi_pv` gate passes) | — |
| `yhat_au` var-model-overlap → **structural** demote/alias (NOT Srecko's rename trick) | ADOPT | Phase 3.1 |
| `pac.estimate.nls` as a χ/h **cross-check** on the channel-stripped canonical core | ADOPT-WITH-CARE | Phase 3.2 |
| `cherrypick`/`aggregate` to **generate** the `_nm`/`_m`/`_dw` sector PAC fragments (gate = h-vectors match `pac.print` to machine precision, **NOT** whole-model bit-identity) | ADOPT-WITH-CARE | Phase 3.3 |
| levels+`growth=` for the 5 existing blocks | **REJECT** (`kind='ll'`, no benefit) | — |
| levels+`growth=` for **mining** | **REJECT** — keep the no-PAC backward capacity identity | — |
| levels+`growth=` for **housing** | **DEFER** — synthetic-data pilot only, never the live block | post-Phase-3 |
| `simul_backward_model` / `solve_algo=14` / full-model residual inversion | **REJECT** — hard-errors on the 5 forward `pv_*` jumpers | — |
| Srecko's `rename=` trick as the overlap fix | **REJECT** — solves a different problem (target naming, not the var_model self-reference) | — |
| `transform_unary_ops` | **DEFER** — renumbers the state vector; only in a clean re-derive | — |

**Why mostly no:** (1) AU's level-cointegration wall (labour FOC DW=0.32; business-inv R²=0.09 robust rejection; mining
DOLS DW=0.062 spurious) defeats *any* levels target equation — the gap form is the *response* to it. (2) `cherrypick`
cannot reproduce the monolith — it omits the 5 forward leads, the `yhat_au` identity, the trade block, and the 4–5
hand-added channels per PAC equation; and `pac.estimate` cannot parse those channels (only `additive`/`optim_additive`/
`non_optimizing_behaviour` are recognised). So `cherrypick` is scoped narrowly to *generate the new sector clones* in
Phase 3, not to migrate the working monolith. Full detail: `project_dynare_pac_upgrades` memory + the `wf_1cf09af6`
workflow transcript.

## Archive index (root decluttered 2026-06-01 → [`archive/`](archive/))
The detailed analyses below were moved to `archive/` to leave this file as the single root entry point. They remain
in the tree (and in git history). Recover the pre-move version of any file with `git show 45d94e3:<name> > <name>`.
- `archive/CES_PRODUCTION_FUNCTION_APPROACH.md` — FR-BDF 2026 CES calibration method (γ→σ→α→μ), AU application.
- `archive/L2_REPLICATION_REPORT.md` — per-block wp1044-vs-AU comparison.
- `archive/PAC_EQUATIONS_AUDIT.md` — equation-by-equation fidelity audit + the χ/PV operator derivation.
- `archive/TRENDS_COMPARISON.md` — trend-object construction and comparison.
- `archive/ESAT_ARCHITECTURE_AUDIT.md` — E-SAT auxiliary-model / belief-VAR architecture.
- `archive/IRF_OSCILLATION_TRADE_AR_FIX.md`, `archive/IRF_TRANSMISSION_DRIFT_INVESTIGATION.md` — the Trend-vs-SA data-bug
  investigation (b1_x 0.78→0.092 on SA data) and transmission-drift diagnosis.
- `archive/BLOCK_LIMITATIONS.md` — AU data gaps per block.
- `archive/NEXT_PROJECT_export_resource_split.md` — the export resource/non-resource split spec (now CONSUMED by the
  active industry split above).

**Folded into this file and removed:** `README.md`, `RUNNING.md` (their content is §0 above) and
`NEXT_PROJECT_industry_split.md` (the full spec is the ACTIVE PROJECT section above). **Kept:**
`dynare/AUSPAC_WORKING_PAPER.{md,tex,pdf}` (the working paper — its internal links to the moved analyses now point into
`archive/`), and the sub-directory data readmes. Memory (cross-session): `project_industry_split`,
`project_current_state_2026_05_30`, etc., in the agent memory store.

## References & citation
| Source | Where |
|---|---|
| FR-BDF wp736 (Lemoine et al., 2019) | `references/wp736.pdf` |
| FR-BDF wp1044 update (Dubois et al., 2026) | `references/FR-BDF-update.pdf` |
| ECB-BASE (Angelini et al., 2019) | `references/ecb-base.pdf` |
| RBA monetary transmission (Mulqueeney, Ballantyne, Hambur 2025) | `references/RBA_mon_transmission.pdf` |

> Stephan, D. (2026). *AU-PAC: A Semi-Structural Macroeconomic Model for Australia.* Working paper, v4.0.
> Lemoine, M., et al. (2019). *The FR-BDF Model…* Banque de France WP No. 736.
> Dubois, U., et al. (2026). *Re-estimated FR-BDF.* Banque de France WP No. 1044.
