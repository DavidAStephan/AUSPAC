# Prompt for next Claude Code session

Paste everything below the line into a new Claude Code session.

---

Read STATUS.md and RUNNING.md. We're building AUSPAC — an Australian adaptation of FR-BDF (wp736.pdf). Dynare 6.5 at C:\dynare\6.5\matlab, MATLAB R2019a.

## Current state (2026-04-14)

All 3 model variants compile, solve, and produce correct IRFs:
- `au_pac.mod` (Hybrid) — 154 endo, 47 exo, var_model architecture
- `au_pac_var.mod` (VAR-based) — 153 endo, 45 exo
- `au_pac_mce.mod` (Full MCE) — 167 endo, 38 exo, 30 forward vars

67 parameters estimated from AU data (Phases 1-4). Iterative convergence achieved in 2 iterations. Full system test: 61 PASS, 4 FAIL (BK cosmetic only).

### Key results
- PAC estimation (hybrid smoother + COVID dummies): SSR = 40.6 / 413.3 / 929.8 / 957.2 / 76.4
- Bayesian Stage 1: 28 params, LMD(Laplace) = **-956.46** (16-point improvement from original)
- Key finding: **gamma_w = 0.770** (very strong AU CPI indexation in wages)
- IRFs: Peak output gap -0.14% for 100bp monetary (matches FR-BDF's -0.15%). MCE attenuation 23-95%.
- Phase 4 (ABS/RBA): 21 params estimated, 14 applied — deflators, trade, housing prices, mortgage rate

### Phase 4 highlights (just completed)
- **Housing prices**: rho_ph = 0.60 (was 0.90), alpha_ph_r = -0.70 (was -0.10). Less persistent but 7x more rate-sensitive.
- **Mortgage rate**: rho_lh = 0.97 (was 0.88). Banks adjust extremely slowly.
- **Deflators**: consumption rho=0.67, business inv rho=0.70, housing inv alpha=0.40 — all estimated from ABS 5206 IPDs.
- **Trade**: b1_x=0.89, b1_m=0.87 — very persistent export/import growth. Demand elasticities had wrong signs (proxy data).
- **b_ph_ih**: Still insignificant with observed RPPI (t=0.59). Confirms need for IV estimation.

## What needs doing now

### Priority 1: PAC re-estimation with Phase 4 parameters

The Phase 4 deflator/trade/housing params change the model's steady-state dynamics. Need to:
1. Regenerate `au_pac_smooth.mod` (run `generate_smoother_mod.m` — it reads from `au_pac.mod`)
2. Re-run `estimate_pac_smooth_driver` to get updated PAC coefficients with new companion matrix
3. Check if SSR improves or parameter signs change

```matlab
cd('c:\Users\david\french_model\dynare')
addpath('C:\dynare\6.5\matlab')
generate_smoother_mod          % regenerates au_pac_smooth.mod from au_pac.mod
estimate_pac_smooth_driver     % ~3 min, Kalman smoother + iterative OLS
```

### Priority 2: Bayesian re-estimation

The Bayesian mod file (`au_pac_bayesian.mod`) still has old Phase 4 parameters. Need to:
1. Regenerate `au_pac_bayesian.mod` (run `generate_bayesian_mod.m`)
2. Run Stage 1 mode-finding with updated params (`run_bayesian_estimation`)
3. Run Stage 2 MCMC from new mode (`run_bayesian_mcmc`)

```matlab
generate_bayesian_mod          % regenerates from au_pac.mod with Phase 4 params
run_bayesian_estimation        % Stage 1: ~5 min, posterior mode
run_bayesian_mcmc              % Stage 2: ~1-2 hours, 20k draws x 2 chains
```

### Priority 3: IV estimation for b_di_c and b_ph_ih

Both were rejected from OLS (wrong signs — reverse causality). Need:
- b_di_c (FR-BDF eq 61, beta_3 = -0.71): interest rate change in consumption. Needs external instruments or simultaneous equations.
- b_ph_ih (FR-BDF eq 67, beta_3 = +0.32): housing price gap in housing investment. Confirmed insignificant even with observed ABS RPPI (t=0.59). May need TSLS with construction approvals or population growth as instruments.

### Priority 4: Working paper update

Update `AUSPAC_WORKING_PAPER.md` with:
- Phase 4 estimation results (new Table 4.7.x for deflators, Table 4.8.x for trade/housing)
- Updated parameter comparison tables
- Refreshed IRF tables if they change after PAC re-estimation

## Key scripts

```matlab
cd('c:\Users\david\french_model\dynare')
addpath('C:\dynare\6.5\matlab')

% Phase 4 estimation (DONE — results in phase4_estimation_results.mat):
estimate_phase4_abs

% Smoother mod regeneration (needed after Phase 4 param changes):
generate_smoother_mod

% Full PAC estimation pipeline:
estimate_pac_smooth_driver    % ~3 min, Kalman smoother + iterative OLS

% Bayesian:
generate_bayesian_mod         % regenerate from au_pac.mod
run_bayesian_estimation       % Stage 1: ~5 min, posterior mode
run_bayesian_mcmc             % Stage 2: ~1-2 hours, MCMC

% IRFs:
generate_wp_irfs              % all 7 shocks at policy-relevant sizes
generate_three_regime_irfs    % 3-regime comparison at 100bp

% Iterative convergence:
run_iterative_convergence     % already converged in 2 iterations
```

## Known Dynare 6.5 bugs (IMPORTANT)

1. **oo_.var double->struct**: After `stoch_simul`, must do `if ~isstruct(oo_.var), oo_.var = struct(); end; get_companion_matrix(...)` before `pac.initialize`.
2. **Inline diff crashes preprocessor**: `b_di_c * (i_gap - i_gap(-1))` inside PAC equations causes assertion failure. Use auxiliary variable `di_gap` instead.
3. **noclearall stale state**: Running `dynare X noclearall` after `dynare Y` preserves `oo_.var` as double. Auto-generated .mod files include fix.
4. **pac.estimate.nls broken**: `hVectors` MEX "Too many output arguments". Use iterative OLS only.

## R2019a compatibility notes

- Use `datenum` not `datetime` for fast date parsing (datetime is 100x slower in R2019a)
- `xlsread` COM hangs on xlsx > ~200KB. Use `actxserver` with chunked reads, or pre-convert to CSV
- ABS xlsx dates in `d/MM/yyyy` format get misinterpreted as `MM/dd/yyyy` by MATLAB. Fix: detect `all(month==1)` and swap day→month
- `nanmean`/`nanstd` require Statistics Toolbox. Use inline: `mean(x(~isnan(x)))`
- `legend('center')` not valid — use `'best'`
- No `contains()` for strings before R2016b — but R2019a has it

Work step by step. Use file-based logging (fopen/fprintf/fclose) since diary doesn't work with Dynare.
