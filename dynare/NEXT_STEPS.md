# AU-PAC — next steps

As of 2026-05-16 (Phase T srecko/FR-BDF aggregate refactor — ARCHITECTURAL MILESTONE: Laplace LMD = −781.05, +7.9 nats over Phase S; au_pac_v2.mod compiles via cherrypick+aggregate workflow; shadow-VAR disconnect eliminated).

## What's done

- **Phase T** (2026-05-16) — srecko/FR-BDF wp1044 aggregate-workflow refactor:
  - 5 aux .mod files (one per PAC block) compute closed-form expectation formulas via `pac.print()`
  - 7 normalized identity .inc files for non-PAC structural equations
  - `cherrypick()` + `aggregate()` combine into au_pac_v2.mod (1206 lines, 158/40/270 vars/shocks/params, BK rank passes with 9 forward-looking eigvals)
  - Bayesian estimation under v2: **Laplace LMD = -781.05**, +7.9 nats over Phase S (-788.95), +20.66 nats over Phase Q baseline (-801.71)
  - Shadow-VAR architectural disconnect eliminated; PAC expectations now use lagged structural variables (yhat_au, piQ, pi_m, dln_pcom)
  - Pattern matches FR-BDF wp1044's "policy function from inverted core E-SAT" architecture
- **Phases A–H** in the working paper (Bayesian estimation, supply CES,
  trend efficiency, sectoral validation, etc.)
- **Phase I** forecast evaluation under WPI calibration
- **Phase J** identification (HPD-width-based; Dynare 6.5 limitation noted)
- **Phase K** — three of four residual params resolved 2026-05-11
  (b_ph_ih, b1_m, b2_m). Only b_di_c remains.
- **Phase L** forward guidance test extended to N=12; AU-PAC ratio
  10.06 vs linear 12; **no forward-guidance puzzle** ✓ (verified post Phase R)
- **Phase N** sectoral asset accounts validated (2-3q wealth half-lives)
- **Phase Q** (2026-05-15) — forward-looking NPV UIP (`pv_i_uip`); fixed
  Hyb < VAR ordering; LMD MHM −802.27
- **Phase R** (2026-05-15/16) — audit-driven structural refit:
  - 4 structural fixes (sign on `dln_tfp` in eq_dln_n_star_bar; Δq channel;
    wage Phillips κ_w sign + pi_au→pi_c indexation; new `pv_r_lh_gap`
    forward real-rate PV)
  - MCMC re-run: **+11.55 nat improvement** (LMD MHM −790.72)
  - Monetary IRF peak shifted from Q40 to Q9-10 (matching FR-BDF Q12)
  - Forward-guidance puzzle absence preserved
  - All 3 main variants pass BK rank
- **Repository cleanup** + **post-cleanup path regression fixes** (8 scripts)
- **FR-BDF wp736 audit**: 15-section comparison, 58 action items,
  documented in [`audit.md`](../audit.md) and [`plan.md`](../plan.md)

## What's left

### A. Open flags from Phase R benchmark comparison (priority: medium)

The [`phase_r_benchmark_table.md`](phase_r_benchmark_table.md) IRF comparison
vs FR-BDF wp736 §5.2 originally surfaced 4 issues. One is now FIXED:

1. ✅ **`eps_pQ` (cost-push) FR-BDF replication** — FIXED 2026-05-16 (Phase S).
   Added structural deflator channels `α_pc·(piQ−pibar_au) +
   β_pc_m·(pi_m−pibar_au) + γ_oil·dln_pcom` to `eq_au_phillips`,
   replicating FR-BDF wp736 §3.1.1 where π_Q is the E-SAT Phillips LHS.
   MCMC re-run: MHM +1.62 nats (−790.72 → −789.10). pi_au now responds
   structurally to cost-push (+0.119 qpp impact), Taylor rule tightens,
   output gap turns negative Q8. ln_Q stays modestly positive due to AU
   institutional features (λ_i=0.96 high policy smoothing, α_pc=0.17 weak
   passthrough) — documented as substantive AU finding in WP §4.4.0/§6.3.5.
2. **`eps_g` (gov spending) impact multiplier weak**: AUSPAC 0.086 at Q4 vs
   FR-BDF 1.20 at Q1. AU fiscal multiplier substantially smaller. May
   warrant rethink of `b_yh_c` HtM channel or government-spending
   transmission.
3. **`eps_q_us` (foreign demand) spillover too large**: AUSPAC +0.75 vs
   FR-BDF +0.14 (5x). Consistent with audit §3.1 finding (AU `δ=0.20` vs
   FR-BDF 0.08, due to AU-China commodity exposure). Likely a real AU
   property, but verify magnitude.
4. **`eps_tfp_LR` IRF small at Q16**: consistent with permanent level shock
   building over 50+ quarters per audit §5 finding (slow capital channel,
   `δ_k = 5.4%/yr` vs FR-BDF 15%/yr).

### B. Phase 5 deferred research backlog ([`plan.md`](../plan.md))

Multi-week extensions deferred during Phase R:

- **Foreign rate `i_us`** (audit #8/#42): would enable proper US IS real-rate
  channel and UIP foreign-rate term. Requires new variable across 8 .mod
  files + FRED fed funds rate data + MCMC re-run. ~1 week.
- **Branch decomposition** (market vs non-market, audit #45): requires ABS
  Cat. 5204 industry-level VA + employment data; introduces `Q^nm`, `N_OQ`
  variables. ~2 weeks.
- **Energy import split** (Phase E, audit #33/#37): substantively important
  for AU as commodity exporter+importer. ~1 week.
- **Demographic trends** (`POP̄_t` from ABS 6202, audit #43): for
  demographic-driven labor-demand trend separation.
- **Tax structure** (audit #46): exogenous effective tax rate × endogenous
  tax basis decomposition. Enables tax-policy analysis.
- **BLR / MAPI / MAPU auxiliary models** (audit #48): for real RBA-style
  forecasting use (vs current academic-replication scope).
- **APP experiment expansion** (audit #58): match FR-BDF Table 6.4.2
  decomposition (TP vs ER channels, VAR vs MCE). Relevant for RBA QE.

### C. Phase K final piece — `b_di_c` (data-dependent, unchanged)

Still Bayesian-regularised at -0.701 (now -0.701 per Phase R MCMC). To resolve:
- RBA OIS surprises: Bishop–Tulip RDP 2017-08
- Beechey–Wright (2009) JME high-frequency news effects

With those datasets, re-run `estimate_phase_c_lpiv.m` then refresh MCMC.

### D. Phase M — non-linear CES (optional, unchanged)

Replace linearised log-FPF with full non-linear FR-BDF eq 24-43 structure.
2-3 days, high SS solver risk. Only worth doing if a referee requests it.

### E. Phase O — release packaging (unchanged)

- Tag `v2.0` (post Phase Q + R): `git tag -a v2.0 -m "AU-PAC paper, Phase R refit"`
- GitHub release: working-paper PDF + replication archive
- Optional: Zenodo DOI

### F. Working paper updates — DONE 2026-05-16

The working paper [`AUSPAC_WORKING_PAPER.md`](AUSPAC_WORKING_PAPER.md) now
reflects Phase R + Phase 4 documentation pass:
- ✅ Table 5.6 posterior values refreshed (LMD MHM -790.72)
- ✅ §4.4.1 wage Phillips updated (− κ_w · pv_u_gap sign + γ_w · π_c indexation)
- ✅ §4.5.2 consumption PAC updated (added α_c_r · pv_r_lh_gap term)
- ✅ §4.4.2 employment target updated (Δq channel + dln_tfp sign flip)
- ✅ §6.2 monetary IRF Table 6.3 refreshed from `saved_irfs_*.mat`
- ✅ §6.5 forward-guidance puzzle (10.06 ratio at N=12 under Phase R)
- ✅ NEW §4.13 "AU adaptations vs FR-BDF design" — six subsections
  (4.13.1 AU empirical findings; 4.13.2 structural simplifications;
   4.13.3 local-market adaptations; 4.13.4 calibration imports from FR-BDF;
   4.13.5 fiscal-block differences; 4.13.6 methodological choices)
  Closes ~30 audit ⚠ items per [`audit.md`](../audit.md) line 37.

### G. Audit follow-up: outstanding pending items — DONE 2026-05-16

Both verification runs completed under Phase S model:
- ✅ **#54 LR BGP convergence**: 1100-quarter simulation under Phase S +
  1 s.d. eps_i shock. All gap variables converge to |x| < 1e-7 at Q1100
  (yhat_au 8.3e-9, pi_au_gap 5.8e-11, s_gap 7.9e-9, dln_c 1.6e-8). ln_Q
  settles at finite +2.76 (permanent capital-level effect of temporary
  shock, expected under PAC).
- ✅ **#14/#53 δ_k sensitivity**: swept δ_k across 0.0134 (AU 5.4%/yr),
  0.020, 0.025, 0.030. ln_Q peak unchanged (-0.289% to -0.304%), but Q40
  capital-channel tail grows 10× (−0.015% AU → −0.160% at 12%/yr).
  AU's slow ln_K recovery is **part calibration** (low ABS-measured AU δ_k)
  and **part specification** (PAC adjustment costs). AU value retained as
  empirically grounded; FR-BDF audit value 0.0375 broke SS without
  recalibrating dependent params (KH ratio, user cost).

## Notes

- [`STATUS.md`](../STATUS.md) at repo root has full Phase R results table
- [`audit.md`](../audit.md) has the FR-BDF wp736 section-by-section audit
  with all 58 action items and their resolution status
- [`plan.md`](../plan.md) has the implementation plan structure and Phase 5
  deferred backlog rationale
- [`dynare/phase_r_benchmark_table.md`](phase_r_benchmark_table.md) has the
  quantitative IRF comparison vs FR-BDF wp736 §5.2 for all 7 shocks
