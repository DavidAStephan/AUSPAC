# Prompt for next Claude Code session

Paste everything below the line into a new Claude Code session.

---

Read STATUS.md and RUNNING.md. We're building a semi-structural macro model for Australia based on WP #736 (wp736.pdf in the project root). The model is in `dynare/au_pac.mod` — Dynare 6.5 at `C:\dynare\6.5\matlab`, MATLAB R2019a at `C:\Program Files\MATLAB\R2019a\bin\matlab.exe`.

## Current state (2026-04-13)

All 3 model variants compile, solve, and produce correct IRFs:
- `au_pac.mod` (Hybrid) — 140 endo, 47 exo (incl. 2 COVID dummies), var_model architecture
- `au_pac_var.mod` (VAR-based) — 140 endo, 45 exo
- `au_pac_mce.mod` (Full MCE) — 154 endo, 30 forward vars

PAC estimation infrastructure:
- 3 dseries approaches: recursive / hybrid (Kalman smoother) / pure smoother
- COVID pulse dummies (`d_covid_crash` 2020Q2, `d_covid_bounce` 2020Q3) in all 5 PAC equations
- Full system test passes 62/62 across 10 stages

## Latest estimation results (with COVID dummies)

| Equation | SSR | b0 (EC) | b1 (AR1) | COVID crash | Key |
|----------|-----|---------|----------|-------------|-----|
| VA Price | 40.6 | 0.026 | +0.287 | -2.88 | Good |
| Consumption | 416.9 | 0.063 | **+0.056** | -15.01 | AR1 fixed (was -0.25) |
| Business Inv | 973.0 | 0.017 | +0.107 | -5.51 | Good |
| Household Inv | 964.5 | 0.025 | +0.111 | -5.67 | b4_ih still +0.08 |
| Employment | 83.0 | 0.044 | **+0.345** | -6.81 | AR1 fixed (was -0.26) |

## Remaining work

| Priority | Task |
|----------|------|
| 1 | Run hybrid smoother + COVID dummies together (combine approaches) |
| 2 | Housing investment rate channel: b4_ih still positive — may need mortgage spread variable |
| 3 | Activate Bayesian estimation block (au_pac.mod lines 2055-2100, with priors) |
| 4 | Conditional forecasting via residual inversion (ECB-Base pattern) |
| 5 | SUR estimation for auxiliary gap equations |

## Running

```matlab
cd('c:\Users\david\french_model\dynare')
addpath('C:\dynare\6.5\matlab')
estimate_pac_smooth_driver   % full pipeline (recommended)
```

See `RUNNING.md` for complete execution guide.

Work step by step. Use file-based logging (fopen/fprintf/fclose) since diary doesn't work well with Dynare.
