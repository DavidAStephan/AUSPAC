# AU-PAC — next steps

As of 2026-05-11 (final post-WPI refresh complete).

## What's done

- **Phases A–H** complete in the working paper.
- **Phase I** (forecast evaluation) — run twice; final under WPI calibration.
  Section 5.5 reflects WPI-era RMSEs (pi_w RMSE 0.20 at h=1, vs 2.32 under
  synthetic ULC).
- **Phase J** (identification) — HPD-width-based analysis done; Dynare's
  formal identification command is incompatible with `diffuse_filter` (known
  Dynare 6.5 limitation), documented in Appendix F.
- **Phase K** — three of four residual parameters resolved on 2026-05-11:
  `b_ph_ih` (housing-price spliced 1959+), `b1_m`, `b2_m` (SA volumes + IAD
  demand index). Only `b_di_c` remains, needing external high-frequency RBA
  surprise data.
- **Phase L** (forward guidance) — extended to N=12; AU-PAC ratio 10.47 vs
  linear 12; no forward-guidance puzzle.
- **Phase N** (sectoral asset accounts validation) — all four sectoral
  wealth-to-GDP ratios converge with 2–3 quarter half-lives under 20% off-SS
  perturbation.
- **2026-05-11 data-quality refresh**: 1959+ housing-price splice, ABS SA
  trade volumes, IAD-weighted demand index, ABS Trend → SA audit across the
  supply pipeline, ABS 6345 WPI integration for the wage observable. LMD
  improved from -931.46 to -799.64 (+132 nat).

## What's left

### 1. Phase K final piece — b_di_c (data-dependent)

`b_di_c` (consumption rate-change channel) remains Bayesian-regularised
at -0.701. To resolve, need RBA OIS monetary surprises:

- Bishop–Tulip RDP 2017-08 — anchoring of inflation expectations using OIS surprises
- Beechey–Wright (2009) JME — high-frequency news effects on long-term yields

With either of those datasets in hand, run `estimate_phase_c_lpiv.m` again
(Romer-Romer narrative-instrument path) and refresh MCMC (~55 min).
The first-stage F is already huge (15,000+) — the issue is sign-matching,
not identification strength.

### 2. Phase M — non-linear CES production block (optional)

Replace the linearised CES around the FPF with the full non-linear FR-BDF
eq 24–43 structure as model-internal endogenous variables. 2–3 days of
MATLAB debugging; high risk of steady-state solver issues. Only worth doing
if a referee requests it.

### 3. Phase O — release packaging

- Tag `v1.0` in git: `git tag -a v1.0 -m "AU-PAC paper, final calibration"`
- GitHub release: attach working-paper PDF + replication archive
- Optional: mint Zenodo DOI for academic citation

The replication scaffolding is already in place (`README.md`, `RUNNING.md`,
`regen_*.py` helpers). The remaining release work is git/GitHub mechanics.

### 4. Working paper polish (optional)

- Refresh `mcmc_writeback.txt` periodically (auto-generated; not committed).
- Re-check the §6.2.3 channel-walkthrough wage-spiral discussion under the
  WPI calibration — currently mentions γ_w = 0.136 correctly but the wider
  narrative could be tightened.
- Consider adding a "Methodology lesson" subsection (Appendix or new §) about
  the synthetic-ULC tautology — it's a useful cautionary tale that's worth
  documenting beyond the current §4.4.1 / §5.4 mentions.

## Notes

- `STATUS.md` at the repo root has the final headline numbers and the
  full refresh sequence summary.
- The working paper is the authoritative document for all parameter values,
  equations, and findings.
- This `NEXT_STEPS.md` is just a forward-looking task list.
