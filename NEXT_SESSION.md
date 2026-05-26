# NEXT_SESSION.md — working paper regeneration plan

**Status**: end of Phase L2 P1c. Hybrid wp1044/AU calibration locked in (Option 1 for BI, AU L2 estimates for other 4 blocks). 23 commits on `refactor/frbdf-replication-L2`, latest `43ed22c`. Both `au_pac.mod` and `au_pac_bayesian.mod` parse cleanly with the new calibration. **The model is ready for IRF generation. The working paper needs to be regenerated to reflect everything L2 / Option 1.**

---

## What's already done (don't redo)

- L1.1 trend efficiency (Eq 7) estimated on AU data
- L1.2 block-specific trend objects (HP-filtered) built
- L2 iterative OLS for 4 PAC blocks (VA-price, employment, consumption, housing inv)
- BI exhaustive spec exploration (7+ variants) — all documented in `PAC_BI_AU_EXPLORATION.md`
- BI block calibrated from wp1044 (Option 1) in `au_pac.mod`, `au_pac_bayesian.mod`, `calibration.inc`
- Hybrid calibration table locked in (PAC_BI_AU_EXPLORATION.md §9)

## Documents to read before starting

In this order:

1. **`PAC_BI_AU_EXPLORATION.md`** — the BI saga and Option 1 decision (10 sections)
2. **`L2_REPLICATION_REPORT.md`** — per-block iterative-OLS results
3. **`PAC_EQUATIONS_AUDIT.md`** — wp1044 vs AUSPAC gap catalogue
4. **`dynare/AUSPAC_WORKING_PAPER.md`** — existing paper (1951 lines, pre-L2)

---

## Mission: regenerate the working paper end-to-end

Update `dynare/AUSPAC_WORKING_PAPER.md` (and via pandoc/latex → `.tex`, `.pdf`, `.html`) to reflect:

1. The Phase L2 wp1044 partial-replication methodology
2. The 4-of-5-blocks-fit-wp1044 finding
3. The BI structural-rejection finding + Option 1 calibration
4. Refreshed coefficient tables with AU vs wp1044 FR side-by-side
5. New IRF charts from the hybrid-calibrated model
6. Cross-block findings (faster AU ECM speeds, etc.)

**Target deliverable**: a clean v2 of the working paper that publishably documents the AUSPAC project's current state.

**Estimated effort**: 3-5 working days.

---

## Phase WP-A: audit + plan refinement (~0.5 day)

| ID | Task |
|---|---|
| A1 | Read current paper section by section; map to current analysis state |
| A2 | List stale sections that need rewriting (any section that references AU MCMC values for BI, any section that pre-dates L2) |
| A3 | List new sections to add (L2 methodology, BI exploration, hybrid calibration rationale) |
| A4 | List sections to remove or condense (over-detailed L1/round-12 content that's been superseded) |
| A5 | Write `WORKING_PAPER_OUTLINE_V2.md` with the refined target structure |

Deliverable: `WORKING_PAPER_OUTLINE_V2.md` — the new structure for the regenerated paper.

---

## Phase WP-B: data/tables/charts generation (~1 day)

All output goes to `dynare/paper_artifacts/` (gitignored .mat artifacts, committed .png/.pdf images for the paper).

### B1: regenerate all per-block coefficient tables

Build `data/make_paper_tables.m` that:
- Loads each block's `results_<block>.mat` from `data/pac_blocks/`
- Loads wp1044 FR values from a hard-coded look-up
- Produces LaTeX-formatted side-by-side tables

Tables needed:
- Table 1: L1.1 trend efficiency Eq 7 coefficients (z_1...z_9, AU vs wp1044 FR)
- Table 2: L1.2 block-specific trend regime growth rates
- Table 3: VA-price PAC coefficients (b_0, b_1, b_2, omega, R^2)
- Table 4: Employment PAC coefficients (depth-3)
- Table 5: Consumption PAC coefficients (β_PAC included)
- Table 6: Housing inv PAC coefficients (price spread included)
- Table 7: Business inv — wp1044 calibration (no AU estimates; Option 1)
- Table 8: Cross-block summary (5 rows × {β_0, β_1, R², source})
- Table 9: BI exploration variants (R² for each of 7+ spec variants)

### B2: regenerate all charts

Build `data/make_paper_charts.m`:
- Per-block fitted vs actual (5 panels)
- Per-block residual histograms (5 panels) 
- Cross-block β_0 comparison bar chart (AU vs wp1044)
- BI exploration spec-variant R² bar chart
- L1.1 Ē_t fitted trend (1 panel)
- L1.2 trend regime growth rates (1 panel, 5 series)

### B3: regenerate IRFs from the hybrid-calibrated Dynare model

```matlab
cd dynare
dynare au_pac
% Outputs all IRFs in au_pac/Output/
```

IRF charts needed (from `oo_.irfs`):
- 100bp monetary tightening: GDP, inflation, unemployment, dln_ib, dln_c
- 1pp foreign demand shock
- 1% commodity price shock (AU-specific)
- 1pp cost-push (eps_pQ)
- 1% TFP shock

Save as `dynare/paper_artifacts/irf_<shock>.png`.

### B4: build comparison-to-wp1044 IRF charts

For consumption + employment + housing inv where AU L2 estimates are close to wp1044 FR: produce side-by-side IRF panels showing AU model response vs wp1044 reported response (from wp1044 Section 5 figures).

For BI: noting that BI uses wp1044 calibration directly, the AU IRF in this block should match wp1044's qualitatively (different shocks drive it but the propagation through PAC is identical).

---

## Phase WP-C: rewrite sections (~1.5-2 days)

Use `dynare/AUSPAC_WORKING_PAPER.md` as the base, edit in place with `Edit` tool.

### C1: Section 1 (Introduction)
- Add Phase L2 context: "this paper presents a wp1044-faithful partial-L2 replication for AU data"
- Add hybrid-calibration disclosure in §1.1 motivation
- Update model dimensions table (Table 1.1) with current state

### C2: Section 3 (PAC framework)
- Add new §3.5: "Iterative OLS estimation pipeline" — the Phase L2 methodology
- Update §3.3 PAC microfoundations with the coef=+1 structural requirement (referencing wp736 FOC derivation)
- Add §3.6: "Hybrid calibration: when local data doesn't identify" — Option 1 rationale

### C3: Sections 4.2 (Supply block) and §4.3 (VA-price)
- §4.2.3: update CES calibration table with current AU values
- §4.3.2: insert new L2 results for VA-price PAC (Table 4.3.2 refresh)
- §4.3.3: add note that aux-equations (Phillips Eq 18 + Okun Eq 19) are not yet in our VAR; flag as a remaining gap

### C4: Section 4.4 (Wages and employment)
- §4.4.2: refresh Table 4.4.4 with L2 employment results (depth-3, AU coefficients)
- Add Δq̂ contemp regressor discussion

### C5: Section 4.5 (Household consumption)
- §4.5.1: target equation with c* from Eq 33
- §4.5.2: refresh Table 4.5.2 with L2 consumption results
- **Highlight the β_0 = 0.27 ≈ wp1044's 0.29 match** as headline finding

### C6: Section 4.6 (Investment)
- §4.6.1 (housing inv): refresh Table 4.6.x with L2 results + price spread term
- §4.6.2 (business inv): MAJOR REWRITE — document the wp1044 structural rejection, the 7+ spec variants tested, the Option 1 decision. Cross-reference `PAC_BI_AU_EXPLORATION.md` for full detail.

### C7: New Section 5 (Cross-block findings)
Pre-existing Section 5 (results) becomes new Section 6. Insert NEW Section 5:
- §5.1: AU ECM speeds 4-8× faster than FR (table + interpretation)
- §5.2: AU PAC structure validates for 4 blocks
- §5.3: BI structural rejection: 3 hypotheses + Option 1 implementation
- §5.4: Implications for IRF analysis

### C8: Section 6 (IRFs) — now displaced from §5 by C7 above
- Refresh all IRF charts with the hybrid-calibrated model
- Add explicit AU-FR IRF comparison panels (where applicable)
- Note BI IRFs are wp1044-calibrated; mining shock IRFs flow through E-SAT

### C9: Section 7 (Conclusion)
- Restructure around the three publishable findings:
  1. AU PAC framework valid for 4 of 5 blocks
  2. Consumption β_0 matches France
  3. AU business inv structurally rejects wp1044 PAC; Option 1 hybrid calibration adopted
- Note open extensions: full wp1044 fidelity (aux equations, exact χ, Minnesota-prior VAR), 5th-block alternative spec

### C10: New Appendix G (BI exploration)
Summarize `PAC_BI_AU_EXPLORATION.md` as an appendix:
- Variants tested (Table G.1 — R² for each spec)
- Why strict PAC fails on AU (Section 2 of the exploration doc)
- Option 1 implementation in Dynare files (cross-ref the commits)

---

## Phase WP-D: compile + commit (~0.5 day)

| ID | Task |
|---|---|
| D1 | Render `.md` → `.tex` via pandoc (existing pipeline) |
| D2 | Compile `.tex` → `.pdf` |
| D3 | Render `.md` → `.html` for online viewing |
| D4 | Verify all tables render correctly + all figures included |
| D5 | Commit final paper |
| D6 | Update STATUS.md if it exists |

---

## File outputs

**New files to create**:
- `WORKING_PAPER_OUTLINE_V2.md` (Phase A deliverable)
- `data/make_paper_tables.m`
- `data/make_paper_charts.m`
- `dynare/paper_artifacts/` directory (charts + IRF .png/.pdf)

**Files to update**:
- `dynare/AUSPAC_WORKING_PAPER.md` (the paper itself)
- `dynare/AUSPAC_WORKING_PAPER.tex` (regenerated from .md)
- `dynare/AUSPAC_WORKING_PAPER.pdf` (compiled from .tex)
- `dynare/AUSPAC_WORKING_PAPER.html` (regenerated from .md)

**Files NOT to touch** (already locked):
- `dynare/au_pac.mod` (hybrid calibration locked)
- `dynare/au_pac_bayesian.mod` (BI removed from estimated_params)
- `dynare/simulation/identities/calibration.inc` (wp1044 BI values)
- `data/pac_blocks/*.m` (L2 estimation scripts)
- `data/pac_helpers/*.m` (helpers)
- `PAC_BI_AU_EXPLORATION.md`, `L2_REPLICATION_REPORT.md`, `PAC_EQUATIONS_AUDIT.md`, `PAC_REBUILD_PLAN.md`, `BLOCK_LIMITATIONS.md`

---

## Working principles for the regeneration

1. **Don't redo analytical work** — all coefficients, R² values, variant lists are already in the various `.mat` and `.md` files. The job is presentation, not re-estimation.

2. **Prefer Edit over Write** for `AUSPAC_WORKING_PAPER.md` — it's 1951 lines and most of it can be reused.

3. **Commit per phase** — A, B, C (one commit per major section group), D (final). Aim for 5-7 commits total.

4. **Numbers must match documents** — every table coefficient in the paper must match a value in either a `results_*.mat` file or wp1044 Tables 3.3.3 / 3.4.9 / 3.5.2 / 3.5.7 / 3.5.13. No invented numbers.

5. **Stop-on-blocker** — if Dynare au_pac fails for any reason at Phase B3, document the error in `WORKING_PAPER_BLOCKERS.md` and proceed with the other phases; pick up Dynare separately.

---

## Branch state at start

```
refactor/frbdf-replication-L2  43ed22c   Option 1 BI calibration in Dynare files
                                c736f93   NEXT_SESSION with BI decision (this commit replaces)
                                85f67db   v6 + PAC_BI_AU_EXPLORATION.md
                                78d7c41   v5 ToT + trends
                                07c8b2e   v3 + v4 BI spec search
                                10e7dfc   docs after P1b
                                ... 17 more L2 commits
```

Branch is clean. Working tree clean. Ready to begin Phase WP-A.

---

## How to pick up next time

1. Read this file.
2. Read `PAC_BI_AU_EXPLORATION.md` (the BI saga).
3. Skim `L2_REPLICATION_REPORT.md` for per-block numbers.
4. Begin Phase WP-A: audit `dynare/AUSPAC_WORKING_PAPER.md` against current state, produce `WORKING_PAPER_OUTLINE_V2.md`.
5. Then Phase WP-B (data/tables/charts), then WP-C (rewrite), then WP-D (compile).
