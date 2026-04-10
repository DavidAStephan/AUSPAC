# AUSPAC Project Status — 2026-04-10

## What this project is
Replication of the FR-BDF semi-structural macroeconomic model (Banque de France WP #736) adapted for **Australia**, implemented in **MATLAB R2019a** with **Dynare 6.5**.

GitHub repo: https://github.com/DavidAStephan/AUSPAC
Local path: `C:\Users\david\french_model\`
MATLAB: `C:\Program Files\MATLAB\R2019a\bin\matlab.exe`
Dynare: `C:\dynare\6.5\matlab`
Git: `C:\Program Files\Git\cmd\git.exe`

## Reference paper
`wp736.pdf` in the project root — "The FR-BDF Model and an Assessment of Monetary Policy Transmission in France" by Lemoine et al. (2019). The paper is 142 pages. Key sections:
- Section 3.1.1: E-SAT expectation satellite model (structural VAR) — **DONE**
- Section 3.2: PAC (Polynomial Adjustment Costs) framework — theory for behavioral equations
- Section 4.3: Supply block (CES production function)
- Section 4.4: VA price equation (first PAC equation) — **DONE in Dynare**
- Section 4.5: Labor market (wage Phillips curve + employment PAC)
- Section 4.6: Demand block (consumption, business investment, household investment — all PAC)
- Section 4.7: Demand deflators (ECM equations)
- Section 4.8: Financial block (term structure, exchange rates, WACC)
- Section 6: Monetary policy transmission under different expectation assumptions

## What is completed

### Phase 0: E-SAT VAR (pure MATLAB)
- `download_data.m` — Downloads AU/US data from FRED and RBA (or loads from `dataset.csv`)
- `estimate_esat.m` — OLS estimation of 5 core + 3 anchor equations
- `bayesian_estimate.m` — Bayesian MCMC (Metropolis-Hastings, 50k draws) estimation
- `esat_model.m` — Builds A/B structural matrices, computes H=A\B, generates IRFs
- `run_all.m` — Master script (set `USE_LOCAL_CSV = true` for offline mode)
- `dataset.csv` — Pre-downloaded quarterly data (1993Q1-2024Q4, 12 columns)

Key results (Bayesian posterior means):
- delta=0.20, lambda_q=0.45, sigma_q=0.17, lambda_i=0.83, alpha_i=0.28
- kappa_pi=0.058 (Phillips slope, rescued by Bayesian prior from negative OLS)
- Model is stable (max eigenvalue 0.985 excl. intercept)

### Phase 1: Dynare infrastructure
- `dynare/au_esat.mod` — E-SAT as a Dynare model, steady state verified, IRFs match MATLAB
- `dynare/run_dynare.m` — Runner script (adds Dynare to path, loads params)
- Dynare 6.5 confirmed working, all eigenvalues match

### Phase 2: Supply + VA price PAC
- `dynare/au_pac.mod` — Extended model: E-SAT core + VA price PAC equation
  - 15 variables, 9 shocks, 12 state variables
  - VA price PAC with error correction, persistence, expectations proxy, output gap
  - All eigenvalues inside unit circle, steady state verified
- `data/download_extended_data.m` — Downloads AU unemployment, employment, consumption, investment, exports, imports, 10Y bond yield
- `data/extended_dataset.csv` — Saved extended quarterly data
- `data/extended_data.mat` — Same in .mat format

## What is next (Phases 3-6)

### Phase 3: Labor market
- Wage Phillips curve (Section 4.5.1, eq. 52): forward-solved, not PAC
- Employment equation (Section 4.5.2, eq. 56): 4th-order PAC
- Need to add auxiliary E-SAT equations for expected unemployment gap

### Phase 4: Demand block (3 PAC equations)
- Household consumption (Section 4.6.1, eq. 61): 1st-order PAC, β=0.95
- Business investment (Section 4.6.2, eq. 64): 2nd-order PAC
- Household investment (Section 4.6.3, eq. 67): 2nd-order PAC
- These are the heaviest equations — require user cost of capital, permanent income

### Phase 5: Financial + trade
- Term structure (eq. 95), exchange rate UIP (eq. 105), WACC (eq. 98)
- Exports/imports ECM (eqs. 70-77)

### Phase 6: Deflators + accounting
- 8 deflator equations (ECMs)
- GDP identity, sector accounts, fiscal rule

## Key technical notes

### Bash limitations in this environment
- Shell commands often return `[rerun: bN]` with no visible output — use `> file.txt` redirect + `Read` to see results
- `cp`, `mkdir`, `powershell` are NOT available in the bash shell
- Use MATLAB's `websave` or `system('curl -skL ...')` for downloads (MATLAB R2019a has expired SSL certs, so curl fallback is essential)
- Use `Write` tool to create files directly rather than shell copy

### Dynare notes
- Dynare 6.5 at `C:\dynare\6.5\matlab` — add to path before calling `dynare`
- PAC support: `pac_model`, `pac_expectation`, `pac_target_info` all available
- Currently using simplified PAC (manual error correction + expectations proxy)
- Full Dynare PAC machinery (`var_model` + `pac_model` linkage) is the next step
- ECB toolkit: https://gitlab.com/srecko/SemiStructDynareBasics

### Git
- Remote: https://github.com/DavidAStephan/AUSPAC.git (origin, main branch)
- User: David Stephan <david.stephan@gmail.com>
- Git binary: `"/c/Program Files/Git/cmd/git.exe"`
- `.gitignore` excludes *.mat, *.png, fred_*.csv, rba_*.csv, matlab_log*.txt

### Australia vs France adaptations
- Australia has its own central bank → Taylor rule reacts to domestic variables (not foreign)
- US replaces euro area as the foreign bloc
- RBA cash rate (~4.2% mean) replaces Euribor
- π̄_AU = 2.5% (RBA target midpoint) vs π̄_FR = 1.9% (ECB target)
- Floating exchange rate (AUD/USD) vs fixed-within-eurozone
