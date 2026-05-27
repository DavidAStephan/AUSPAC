# NEXT_SESSION.md — post-Phase-L2 / post-paper-v2 plan

**Status at end of last session**: branch `refactor/frbdf-replication-L2`, latest commit `4a61002` (paper-polish: cross-refs, artefact figures, Greek glyph fix, L1.2 trends, ABS 5625 download, bibliography). Working paper v2 published at `dynare/AUSPAC_WORKING_PAPER.{md,tex,pdf,html}` — 175 endog vars, 49 shocks, 5 PAC blocks (4 AU-estimated + 1 wp1044-imported via Option 1 hybrid calibration).

**Headline locked in**: AU consumption β₀ = 0.27 ≈ wp1044's 0.29; AU BI structurally rejects wp1044 PAC (PV(Δq̂)=−5.03 across 11 variants); Option 1 hybrid calibration adopted; Octave mode-search Laplace LMD = −694.78 (+84 nats vs Round 1.2 baseline). Full MCMC pending native-ARM MATLAB.

---

## Primary track — finish items 3+4 from post-WP-D once new MATLAB arrives

### A1. Set up new MATLAB + native-ARM Dynare

1. Install MATLAB R2024b (or R2023b+) with **Statistics & Machine Learning Toolbox** required and **Parallel Computing Toolbox** recommended (halves MCMC wall-clock).
2. Install native-ARM Dynare. Either:
   - Download `dynare-6.5-arm64.pkg` from dynare.org/download (preferred), OR
   - Re-use the existing `/opt/homebrew/opt/dynare/` from brew (already installed in last session, octave-targeted but MATLAB-compatible).
3. Verify with a one-liner:
   ```bash
   /Applications/MATLAB_R2024b.app/bin/matlab -batch \
     "addpath('/Applications/Dynare-6.5-arm64/matlab'); dynare_version"
   ```
   (No `arch -x86_64` needed on R2024b native ARM.)

### A2. Run hybrid MCMC

```bash
cd ~/Documents/AUSPAC/dynare
/Applications/MATLAB_R2024b.app/bin/matlab -batch \
  "addpath('/Applications/Dynare-6.5-arm64/matlab'); dynare au_pac_bayesian.mod" \
  2>&1 | tee mcmc_hybrid_v2.log
```

Expected wall time **~30–60 min** on R2024b native ARM (vs ~50 min historical baseline on Intel hardware; the Octave attempt projected 4 hours, MATLAB-Rosetta 6+ hours). Outputs:
- `dynare/au_pac_bayesian/metropolis/au_pac_bayesian_mean.mat` — posterior means + HPDs
- `dynare/au_pac_bayesian/Output/au_pac_bayesian_results.mat` — full results struct
- New Laplace LMD + **MHM LMD** in the log (the Octave mode-only run gave Laplace = −694.78; MHM not computed because MH never finished)

### A3. Item 4 — populate Bayesian-posterior columns in §4 tables

Read posterior means + 90% HPDs from `au_pac_bayesian_results.mat`. The five tables to update in `dynare/AUSPAC_WORKING_PAPER.md`:

| Section | Table | Block | Parameters to populate |
|---|---|---|---|
| §4.3.2 | Table 4.3.2 | VA-price | `b0_pQ`, `b1_pQ`, `b2_pQ` + std_eps_pQ |
| §4.4.4 | Table 4.4.4 | Employment | `b0_n`, `b1_n`, `b5_n` + std_eps_n |
| §4.5.2 | Table 4.5.2 | Consumption | `b0_c`, `b1_c`, `b2_c`, `b3_c` + std_eps_c |
| §4.7.2 | Table 4.7.2 | Housing inv | `b0_ih`, `b1_ih`, `b3_ih` + std_eps_ih |
| §6.4 (Bayesian) | Table 5.6 | full 25-param posterior | All non-BI estimated params |

**Important**: Table 4.6.2 (Business inv) does *not* need a Bayesian column — BI is removed from `estimated_params` (calibrated from wp1044 Table 3.5.13 via Option 1, §3.6 + §4.6.2). Note this explicitly in the Table 4.6.2 caption.

### A4. Re-render and commit

```bash
cd dynare
pandoc AUSPAC_WORKING_PAPER.md -o AUSPAC_WORKING_PAPER.tex \
  --standalone --mathjax --include-in-header=paper_header.tex
tectonic AUSPAC_WORKING_PAPER.tex          # → PDF
pandoc AUSPAC_WORKING_PAPER.md -o AUSPAC_WORKING_PAPER.html \
  --standalone --mathjax --toc --toc-depth=3
```

Commit with the headline: "MCMC under hybrid calibration: Laplace LMD = X, MHM = Y (+Z nats vs Round 1.2)."

### A5. Compare new MHM to STATUS.md baselines and update STATUS.md

Phase trajectory baselines from STATUS.md:
- Phase Y pre-L2: Laplace = −779.30, MHM = −780.36
- Round 1.2 (current cache): Laplace = −784.47, MHM = −785.80
- **Phase L2 P1c hybrid mode-search-only (Octave)**: Laplace = −694.78

If MATLAB MHM confirms the +84 nats Laplace gain, that's the largest single-phase improvement in the project's history (prior max was Phase R at +11.55). Worth a §6.4 paragraph + STATUS.md bump to v3.3.

---

## Parallel track — Phase L3 mining-vs-non-mining BI hypothesis test (no MATLAB needed initially)

ABS Cat. 5625 Dec-2025 release downloaded to `data/abs_rba/abs_5625_*.xlsx` in the last session (see `data/abs_rba/abs_5625_README.md`). The Phase L3 BI test plan:

### L3.1 Build mining vs non-mining `dln_ib` series

In MATLAB GUI or Python:
1. Read `data/abs_rba/abs_5625_07_volume_measures_seasonally_adjusted_capex.xlsx` sheet `Data1`.
2. Series IDs:
   - `A3515875V` (Mining: Buildings & Structures)
   - `A124798315W` (Non-Mining: Buildings & Structures, incl. Education + Health)
   - + equivalent for Equipment, Plant & Machinery (cols 21 + 22)
3. `dln_ib_mining = 100 * Δlog(mining_buildings + mining_E&P)`
4. `dln_ib_nonmining = 100 * Δlog(nonmining_buildings + nonmining_E&P)`
5. Quarterly, SA, 1987Q3–2025Q4 (T=154). Note: AUSPAC base sample starts 1993Q2 — consider extending back to 1987Q3 for sub-sample identification.

### L3.2 Re-estimate wp1044 Eq 46 on each sub-series

Copy `data/pac_blocks/estimate_pac_business_inv.m` and `estimate_pac_business_inv_au_v3.m` (variant A, free-PV diagnostic) to `_mining.m` and `_nonmining.m` variants. Same wp1044 functional form, same block-specific VAR (Table 3.6 in the paper), same iterative-OLS pipeline.

### L3.3 Read off the diagnostic and update §5.3 + Appendix G

Decision tree (per §5.3 hypotheses A, B, C):

| `dln_ib_nonmining` PV(Δq̂) | `dln_ib_mining` PV(Δq̂) | Interpretation |
|---|---|---|
| ≈ +1 (structural) | ≈ −5 (or worse) | **Hypothesis B confirmed**: mining drives the aggregate rejection. Consider two-block BI in production model. |
| ≈ −5 | ≈ −5 | **Hypothesis A** (different agent objective globally) likely. Option 1 hybrid remains correct path. |
| Both intermediate | — | **Hypothesis C** (sample-period contamination) possible; try splitting at 2003Q1 / 2015Q1. |

Update `PAC_BI_AU_EXPLORATION.md` §6 with the L3 results; refresh Appendix G of the paper.

---

## Lower-priority research extensions (multi-day each, deferred)

| ID | Item | Effort | Notes |
|---|---|---|---|
| EXT-1 | Add wp1044 Phillips Eq 18 + Okun Eq 19 as explicit AR(1) aux equations in VA-price block VAR; lift §4.3 R² from 0.41 toward wp1044's 0.61 | ~1 week | Source: `PAC_EQUATIONS_AUDIT.md` §1.3 gap #7 |
| EXT-2 | Replace AU L2 VAR(1) with Bayesian Minnesota-prior VAR(p) per wp1044 §3.2 | ~1 week | Affects all 4 fitting blocks' R² |
| EXT-3 | RBA OIS-surprise IV for `b_di_c` consumption rate-change coefficient | ~3 days | Bishop & Tulip 2017 methodology; replaces the Bayesian-regularised current value |
| EXT-4 | Channel-decomposition exercise à la Mulqueeney et al. 2025 (turn off each channel in turn) | ~3 days | Quantifies exchange-rate vs asset-price vs savings vs cash-flow contributions to monetary IRF |
| EXT-5 | Adopt FR-BDF 2026 financial-block extensions: Dees et al. 2022 NFC accelerator + Bové et al. 2020 household DSR block | ~2 weeks | Natural v3.0 direction noted in §8 conclusion |
| EXT-6 | Bernanke-Gertler-Gilchrist financial-friction extension to BI block (Phase L3 follow-up) | ~1 week | Only if Hypothesis B from §L3.3 confirms |

None of these is currently scheduled.

---

## Branch state at start

```
refactor/frbdf-replication-L2
   4a61002   docs: paper-polish — items 1-5 + 8-9 (TODAY's latest)
   c5586e9   docs: items 1+2 — paper_artifacts/ tables and charts, PDF re-rendered
   703a2ee   docs: working paper v2 regeneration end-to-end (Phase WP-A..D)
   43ed22c   Phase L2 P1c Option 1: import wp1044 BI calibration into Dynare model
   c736f93   docs: update NEXT_SESSION with BI exploration decision
   85f67db   Phase L2 P1c v6 + exhaustive documentation: Option 2 (ToT target) also fails
   78d7c41   Phase L2 P1c v5: BI with ToT + piecewise trends + dummies; still fails strict PAC
   ... 23 earlier L2 commits
```

Branch is clean. Working tree clean. Ready to merge to `main` once Item 3+4 (MCMC under hybrid + Bayesian column update) lands, or to begin Phase L3 mining-vs-non-mining BI test in parallel.

---

## How to pick up next time

1. Read this file.
2. If new MATLAB ready: run **Primary track A2** (~30–60 min wall-clock), then **A3 + A4 + A5**.
3. If new MATLAB not yet ready: run **Parallel track L3** (mining-vs-non-mining BI; no MATLAB needed for the data prep + Python sketch).
4. Either way, ping me with the result.

**Workarounds documented in `WORKING_PAPER_BLOCKERS.md`** (R2020a + Rosetta `arch -x86_64` fix; tectonic LaTeX; Python `make_paper_artifacts.py` for table/chart generation) — kept as reference for future sessions on different hardware.
