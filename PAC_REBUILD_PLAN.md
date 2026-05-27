# PAC_REBUILD_PLAN.md — full wp1044 partial-L2 replication execution plan

Status: active execution plan, generated 2026-05-26.  
Branch: `refactor/frbdf-replication-L2`.  
Prior commits to read first: `4447241` (PAC_EQUATIONS_AUDIT.md — the gap catalogue this plan addresses) and `abd8953` (current approximate iterative OLS — superseded by this rebuild).

## 0. Mission

Bring the AUSPAC partial-L2 implementation up to wp1044 fidelity for all 5 PAC blocks. End state: each block's iterative-OLS regression matches the wp1044 functional form exactly (within AU-data limitations), with block-specific auxiliary VAR states, contemporaneous regressors, COVID dummies, and characteristic-polynomial-derived χ. Coefficient estimates should land in the same ballpark as wp1044 Tables 3.3.3 / 3.4.9 / 3.5.2 / 3.5.7 / 3.5.13 (allowing for AU-vs-FR differences), and R² should approach the wp1044 values where data quality is comparable.

Estimated effort: ~2 weeks focused work (~12-13 working days). Per the audit. The user has authorized unsupervised execution; this document is the execution roadmap.

## 1. Working principles for unsupervised execution

- **Commit per logical unit**: each phase deliverable becomes its own commit. Aim for 1-3 commits per phase.
- **Validate incrementally**: each block's iterative-OLS coefficients should be checked against wp1044 Tables before moving to the next. Sanity threshold: same sign, same order of magnitude.
- **Document inline**: write each block's findings to a per-block `.txt` report (gitignored) and link to it in the commit message.
- **Stop-on-missing-data**: if a block requires AU data that doesn't exist in the repo and can't be plausibly proxied (e.g., separate housing-new and housing-existing deflators for housing inv), document the limitation in a `BLOCK_LIMITATIONS.md` note and skip the block. Don't get stuck.
- **Reuse over rewrite**: existing scripts (`estimate_consumption_pac_iterative.m`, `estimate_all_pac_iterative.m`) contain working OLS scaffolding. Extract helpers into a shared `pac_helpers/` module; per-block scripts then call those helpers.
- **No pause for review** until either (a) all 5 blocks complete + Phase D done, OR (b) hit a hard data blocker. The user has explicitly said don't stop for review.

## 2. Phases

### Phase L2-A — Data layer foundations (~2 days)

Goal: construct every observable / target that wp1044 references but AUSPAC doesn't yet have. After this phase, `estimation_data.mat` and `data/extended_dataset.csv` should contain everything needed for the five PAC equations.

Sub-tasks:

| ID | Task | Source | Effort |
|---|---|---|---|
| A1 | Build `piQ` = 100·Δlog `p_q_total_lvl` (VA-price quarterly inflation, %) | `dynare/supply_data.mat` | 1h |
| A2 | Build `piW` = 100·Δlog `wpi_lvl` (wage growth, %) | `dynare/supply_data.mat` | 1h |
| A3 | Construct `π*_Q` via wp1044 Eq 17 OLS: π*_Q = β_0(π_W - Δē) + (1-β_0)π̄*_Q | A1, A2 + `trend_efficiency` Ē | 2h |
| A4 | Build `df` = chain-linked synthetic final demand = consumption + housing inv + non-dwelling inv (proxy, AU doesn't have separate government inv split) + exports | `extended_dataset.csv` | 1h |
| A5 | Build `n̂*_S` (employment gap target) via Eq 31 OLS: n̂*_S = β_0·ŷ_{t-1} + β_3·n̂*_S_{t-1} + ε | `extended_dataset.csv` au_employment + yhat_au | 1h |
| A6 | Build `c*` (consumption target) via Eq 33 form on AU data: c* = α_0 + PV(y_H) + α_1·(r_LH - (ī-π̄)) — using r_10y as proxy for r_LH, π_au mean as π̄ | Multiple inputs | 3h |
| A7 | Estimate auxiliary equations for `(y_H - ȳ)`, Δw_eff, û via Eq A.0.2 OLS forms | `extended_dataset.csv` + supply data | 3h |
| A8 | Estimate `r_LH` aux equation Eq A.1 OLS on AU bond rate | i_10y + π_au | 1h |
| A9 | Check housing-block deflator availability (pSH, pIH). If absent: document in BLOCK_LIMITATIONS.md and plan to skip housing inv | n/a | 1h |
| A10 | Build `ỹ_t` = HP-trend of GDP GROWTH (already in trend_series.mat from L1.2; verify) | `data/trend_series.mat` | 30min |
| A11 | Construct `Δq̂_t` (market VA gap growth, contemp) | `dynare/supply_data.mat` `q_market_lvl` + HP filter | 1h |
| A12 | Update `prepare_estimation_data.m` to emit new columns + COVID dummy columns (20Q1, 20Q2, 20Q3, 20Q4, 21Q1, 21Q2, 03Q2, 06Q3, 08Q1, 10Q4) | Code update | 2h |
| A13 | Run prep, verify all columns present, commit | n/a | 30min |

Deliverable: `data/prepare_estimation_data_l2.m` (new file, alongside existing); `data/aux_equations_estimates.mat` (calibrated coefficients of auxiliary equations).

### Phase L2-B — Cross-cutting helpers (~1 day)

Goal: extract reusable helpers so per-block scripts are short. Living under `data/pac_helpers/`.

Sub-tasks:

| ID | Task | Effort |
|---|---|---|
| B1 | `solve_pac_chi.m(beta_lags, omega, depth)`: returns the smallest positive root of the depth-m PAC characteristic polynomial λ^(m+1) - (1+Σβ)λ^m + ... = 0. Uses MATLAB `roots()`. | 2h |
| B2 | `build_block_var.m(block_name, data_struct)`: returns Φ matrix + state names for a block-specific VAR matching the relevant wp1044 policy-function table. Five block-specific variants. | 4h |
| B3 | `compute_pv_term.m(Phi, chi, target_idx, k_order)`: returns PV (or PV²) of the target variable as a time series.  | 1h |
| B4 | `compute_trend_pv.m(omega, trend_lag)`: returns the calibrated unit-root PV trend term `ω·Δx̄_{t-1}` (wp1044 Eq 32 form). | 30min |
| B5 | `ols_with_se.m(X, y)`: refactor existing OLS helper into a single shared file. | 30min |
| B6 | `pac_iterate.m(block_spec, max_iter, tol)`: generic iterative-OLS loop. Takes a block_spec struct, runs the χ → PV → OLS → β-update loop. | 4h |
| B7 | Commit | 30min |

Deliverable: `data/pac_helpers/` directory with 6 files.

### Phase L2-C — Block-by-block rebuilds

Each block gets its own script `data/pac_blocks/estimate_pac_<block>.m` that calls the helpers from Phase B and produces:
- Posterior coefficient estimates with standard errors
- Convergence diagnostics
- Side-by-side comparison vs wp1044 Tables
- R² and residual diagnostics

Block order (priority high → low based on tractability + value):

#### C1 — VA-price Phillips (~2 days)

Per audit §1.4, the main work:
- LHS: `piQ` from Phase A1 (NOT pi_au)
- ECM: `(p*_Q - p_Q)` level gap, lagged 1
- Build π*_Q target from Eq 17
- Add Phillips + Okun + long-term-efficiency aux equations to the block VAR
- Output gap regressor: contemporaneous (`yhat_au_t`)
- Add 8 COVID/period dummies (03Q2, 06Q3, 08Q1, 10Q4, 20Q1, 20Q2, 20Q3, 21Q1)
- Calibrated ω: try 0.62 (wp1044) and 0.46 (current AUSPAC) for sensitivity

Validation: target wp1044 Table 3.3.3 estimates (β_0=0.05, β_1=0.20, β_2=0.09, R²=0.61). AU values may differ but signs should match and R² should be > 0.30 (well above current 0.04).

#### C2 — Employment (~1 day)

Per audit §2.4:
- Depth = 3 (not 4)
- TWO PV terms: PV(Δn̄*_S) trend + PV(Δn̂*_S) gap — decomposed expectations
- Add `Δq̂_t` contemporaneous regressor (market VA gap growth from Phase A11)
- Add growth-neutrality term `(1-Σβ-ω)·Δn̄*_{S,t-1}` (derived coef)
- ECM uses `(n*_S - n_S)` proxy where n*_S = HP trend of log employment (best AU approximation)
- 2 COVID dummies (20Q2, 20Q3)
- Sample: 1997Q1-2021Q4 per wp1044 (but use AU sample 1993Q2-2023Q3 since data extends)

Validation: target wp1044 Table 3.4.9 (β_0=0.07, β_1=0.44, β_2=0.12, β_3=0.12, β_4=0.13, R²=0.95). Should converge cleanly now that depth=3.

#### C3 — Consumption (~3 days)

Per audit §3.4, the heavy work:
- Build `c*` via Eq 33 with α_0, α_1 as estimated coefficients in the LR equation
- PV²(y_H - ȳ) imposed at coefficient = 1
- α_1·[PV(r_LH) - (PV(ī) - PV(π̄))] with α_1 free
- β_PAC·Δȳ_{t-1} free (matches L1.3a)
- HtM channel in wp1044 LEVEL-DIFFERENTIAL form: `β_2·[Δlog(W_H + TG_H)/p^VAT_C - ỹ_t]`. Requires constructing log(W_H + TG_H)/p^VAT_C growth. AU has W_H + TG_H components in extended_dataset (via `prepare_household_income.m`); p^VAT_C ≈ p_C from CPI level.
- Impact rate term: β_3·(Δr_LH - (Δī - Δπ̄))
- 4 COVID dummies (20Q1, 20Q2, 20Q3, 20Q4)
- Aux equations from App A.0.2 in the VAR state: y_H_t - ȳ_t, Δw_eff,t, û_t
- Aux equation A.1 for r_LH dynamics

Validation: target wp1044 Table 3.5.2 (β_0=0.29, β_1=0.17, β_2=0.32, β_3=-1.07, R²=0.95).

#### C4 — Housing investment (~3 days, may abort)

Per audit §4.4. **Pre-check**: are pSH and pIH (existing-housing and new-housing deflators) available in AU data?

If yes (Phase A9 result):
- Build I*_H via Eq 36 (long-run target)
- TWO PV terms: PV(Δlog Î*_H) - PV(Δlog Ī*_H) at coef=1
- Growth-neutrality `(1-β_1-ω)·Δlog Ī*_H,t` contemp (not lagged!)
- β_2·(Δy_t - ỹ_t) contemp output growth gap
- β_3·[(pSH - pIH)_{t-1} - (pSH - pIH)_{t-5}] price spread
- 4 COVID dummies

If no: write BLOCK_LIMITATIONS.md note; skip housing inv; still record the missing-data structurally so future work has a clear path.

Validation: wp1044 Table 3.5.7 (β_0=0.12, β_1=0.18, β_2=0.50, β_3=0.05, R²=0.89).

#### C5 — Business investment (~3 days)

Per audit §5.4:
- Build synthetic `df` from Phase A4
- FOUR PV terms: PV(Δq̂) + PV(Δq̄) - σ·PV(Δlog r̂_KB) - σ·PV(Δlog r̄_KB) — all at coef=1, σ from CES (=0.50 in wp1044; AU value 0.54 from ces_2026_calibration.mat)
- TWO derived growth-neutrality: (1-β_1-β_2-ω)·Δlog r̄_KB,t-1 + (1-β_1-β_2-ω)·Δq̄_t-1
- β_3·(Δdf_t - Δd̄f_t) contemp synthetic-demand growth gap
- depth = 2
- 3 COVID dummies (20Q1, 20Q2, 20Q3)

Validation: wp1044 Table 3.5.13 (β_0=0.096, β_1=0.33, β_2=0.11, β_3=0.69, R²=0.83).

### Phase L2-D — Cross-block validation + report (~1 day)

Sub-tasks:

| ID | Task | Effort |
|---|---|---|
| D1 | Write `compare_l2_to_wp1044.m`: loads each block's results, builds a side-by-side coefficient + R² + chi + omega comparison table | 2h |
| D2 | Sanity check residual autocorrelation per block (should be small if PAC structure fits) | 1h |
| D3 | Write `L2_REPLICATION_REPORT.md`: final per-block result tables, R² gaps, signs match wp1044?, chi values, residual diagnostics. Identify which blocks succeeded and which need further work. | 3h |
| D4 | Update NEXT_SESSION.md with the L2 final state, recommendations for the dynare au_pac.mod model layer | 1h |
| D5 | Commit | 30min |

## 3. Risk register + mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Housing inv pSH/pIH not in AU data | High | Skip block | Document in BLOCK_LIMITATIONS.md; deliver 4-of-5-blocks; the L2 result is still valuable |
| Synthetic `df` doesn't match AU national-accounts conventions | Medium | Bad business-inv fit | Document the construction; report sensitivity to df definition |
| Eq 17 OLS for π*_Q doesn't converge or gives weird coefs | Medium | VA-price block fragile | Fall back to HP-trend of piQ as π*_Q proxy; document |
| Iterative OLS doesn't converge for some block (like employment last time) | Medium | Block partial | Cap at 50 iter; report non-convergent block as "diagnostic only"; don't block on it |
| Block-specific VARs over-parameterized for 122-obs sample | Medium | Inflated SEs | Use 6-8 var states max per block; document |
| Aux equation OLS (A.0.2 etc.) has insufficient AU coverage | Medium | Missing aux inputs | Use HP-gap proxies; document substitutions |
| Coefficient signs differ from wp1044 across-the-board | Low | Replication "fails" | This IS a real result — AU is not FR; report honestly |
| Multi-day commit chain breaks (file conflicts, etc.) | Low | Slow recovery | Each phase is independent; commit early commit often |

## 4. Definition of done

The replication is complete when:
1. Each block's iterative-OLS converges (or is documented as non-convergent with reason)
2. Each block's coefficient table has columns: AU L2 estimate, AU L2 s.e., wp1044 FR estimate, sign-match flag
3. Block R² values reported alongside wp1044 R² values
4. χ values, ω values, and depth match wp1044 exactly for each block
5. `L2_REPLICATION_REPORT.md` written summarizing where AU data + framework agree with wp1044 and where they diverge
6. NEXT_SESSION.md updated with implications for the AUSPAC dynare model layer

## 5. Files I'll create / modify

New files:
- `data/prepare_estimation_data_l2.m` — augmented data prep (Phase A)
- `data/aux_equations_estimates.m` — OLS for the auxiliary equations (Phase A)
- `data/pac_helpers/solve_pac_chi.m`
- `data/pac_helpers/build_block_var.m`
- `data/pac_helpers/compute_pv_term.m`
- `data/pac_helpers/compute_trend_pv.m`
- `data/pac_helpers/ols_with_se.m`
- `data/pac_helpers/pac_iterate.m`
- `data/pac_blocks/estimate_pac_va_price.m` (Phase C1)
- `data/pac_blocks/estimate_pac_employment.m` (C2)
- `data/pac_blocks/estimate_pac_consumption.m` (C3)
- `data/pac_blocks/estimate_pac_housing_inv.m` (C4)
- `data/pac_blocks/estimate_pac_business_inv.m` (C5)
- `data/compare_l2_to_wp1044.m` (Phase D)
- `L2_REPLICATION_REPORT.md` (Phase D)
- `BLOCK_LIMITATIONS.md` (if any block aborts)

Files modified:
- `NEXT_SESSION.md` (Phase D)

Existing files that won't change in this rebuild:
- `data/estimate_*.m` (the legacy scripts, kept for comparison)
- `data/compute_trend_objects.m` (Phase L1.2 outputs reused)
- `data/estimate_trend_efficiency.m` (Phase L1.1 Ē used as input)
- All Dynare .mod files (this rebuild is OLS-only; doesn't touch Dynare)

## 6. Commit cadence

Target one commit per sub-section: ~A13, then B7, then per-block C1-C5, then D5. ~10 commits across the rebuild.

## 7. Out of scope

- Re-running the Dynare model with new estimates (model-layer integration is a separate phase)
- Bayesian Minnesota prior for the VARs (sticking with OLS lag-by-lag for tractability)
- Per-block Brooks-Gelman convergence diagnostics (single-chain OLS, no chains)
- Updating the working paper writeup

## 8. Start

Beginning Phase L2-A now.
