# Prompt for next Claude Code session

Paste everything below the line into a new Claude Code session.

---

Read STATUS.md and the plan at .claude/plans/next-stages-8-11.md. We're building a semi-structural macro model for Australia based on WP #736 (wp736.pdf in the project root). Phases 0-7 are done — the full 53-variable Dynare model is built with all feedback loops closed, but all structural parameters are hand-calibrated.

Continue with Stage 8 (data & estimation pipeline). The goal is to move from calibrated to Bayesian-estimated parameters. Steps:

1. Fix data gaps in `data/download_extended_data.m`:
   - Download actual ULC series (currently NaN) — try FRED series `ULQELTT01AUQ661S`
   - Split GFCF into dwelling vs non-dwelling investment (currently combined)
   - Re-run the download script to regenerate extended_dataset.csv

2. Create `data/prepare_estimation_data.m` — transforms raw CSV data into Dynare-compatible format (demeaned, quarterly %, aligned sample, saved as .m file)

3. Activate the commented-out estimation blocks in `dynare/au_pac.mod` (varobs, estimated_params, estimation command) and run Bayesian estimation

4. Evaluate results — check convergence, compare posteriors to calibrated values

Work step by step. After each sub-step, verify by running MATLAB/Dynare. If FRED download fails for ULC or GFCF split, use reasonable alternatives (OECD series, ABS direct, or synthetic split based on historical dwelling share ~30%). Update STATUS.md when done.
