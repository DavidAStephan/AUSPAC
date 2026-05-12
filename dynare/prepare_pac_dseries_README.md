# Three flavours of `prepare_pac_dseries*`

This directory contains three closely-related dseries builders for the
five PAC equations. They differ only in how unobserved auxiliary
variables (EC targets, backward-correction PV terms, level
accumulators) are constructed.

| Script                            | Method                                                | Used by                                                  | Canonical? |
|-----------------------------------|-------------------------------------------------------|----------------------------------------------------------|-----------|
| `prepare_pac_dseries.m`            | Recursive — uses calibrated params + observed data    | `estimate_pac.m` (legacy iterative-OLS)                  | no         |
| `prepare_pac_dseries_smooth.m`     | Pure Kalman smoother — reads `oo_smooth.SmoothedVariables` for *every* auxiliary | `test_smoother_comparison.m` (Approach C)                | no         |
| `prepare_pac_dseries_hybrid.m`     | Hybrid — Kalman smoother for EC targets + recursive for `pv_*_aux` + cumulated observed growth for levels | `estimate_pac_smooth_driver.m` (Phase A canonical path)  | **YES**   |

## Why three?

Each construction trades off different sources of bias:

- **Recursive** is fast but accumulates calibration-parameter errors in
  the auxiliary variables (since pv_X_aux depends on the calibrated
  `rho_*` and `a_*` coefficients).
- **Pure smoother** removes all calibration bias from the auxiliaries
  but inherits any specification error in the .mod file's state-space
  representation (e.g., omitted variables, mis-specified shock
  variances).
- **Hybrid** uses the smoother where it is robust (EC target gaps —
  these depend on the *observed* dependent variable directly) and the
  recursive construction where the smoother is unreliable
  (pv_X_aux — backward-PV recursion of forecasting variables that the
  smoother can over-fit).

`test_smoother_comparison.m` runs all three and compares the resulting
PAC estimates. The hybrid produces SSRs that are within 1% of the
pure-smoother SSRs and avoids the wrong-signed AR(1) coefficients seen
in the recursive version (PAC equations 4.5 consumption and 4.5.2
employment are the two affected by this).

## Canonical workflow (Phase A onward)

```
estimate_pac_smooth_driver
  └── calls prepare_pac_dseries_hybrid(oo_smooth)
```

This is the script invoked by `make_paper_results.m` and produces the
PAC coefficient values written back to `au_pac{,_var,_mce}.mod` for the
Bayesian refresh.

## Don't delete the other two

They are retained because:
1. `test_smoother_comparison.m` documents the historical comparison.
2. `prepare_pac_dseries.m` is still useful for sanity checks on a
   freshly downloaded dataset before the Kalman smoother has run.
