#!/usr/bin/env python3
"""extract_2026_results.py — pull all paper-relevant numbers from the
post-MCMC outputs into a single text report, ready for paper integration.

Reads:
  - bayesian_mcmc_results.mat  (or oo_ in au_pac_bayesian/Output)
  - saved_irfs_{var,hybrid,mce}.mat
  - 2026_refresh_log.txt

Writes:
  - 2026_paper_inputs.md  (structured findings for paper update)
"""

from __future__ import annotations
import os
import sys
from pathlib import Path
import numpy as np
import scipy.io as sio

HERE = Path(__file__).resolve().parent
DYNARE = HERE.parent  # dynare/ workspace where MATLAB writes .mat artefacts
os.chdir(HERE)

def fmt(x, decimals=4):
    if x is None or (isinstance(x, float) and np.isnan(x)):
        return "n/a"
    return f"{x:.{decimals}f}"

def load_mat(p):
    try:
        return sio.loadmat(p, squeeze_me=True, struct_as_record=False)
    except FileNotFoundError:
        print(f"[WARN] {p} not found")
        return None
    except Exception as e:
        print(f"[WARN] failed to load {p}: {e}")
        return None

# ---------------------------------------------------------------- posteriors
out_lines = ["# AUSPAC 2026 paper inputs — auto-generated\n"]

# 1. Try bayesian_mcmc_results.mat (post-extract_mcmc_results)
mcmc_path = DYNARE / "bayesian_mcmc_results.mat"
mcmc = load_mat(mcmc_path)
if mcmc is None:
    out_lines.append("## Posteriors\n\nbayesian_mcmc_results.mat not yet available.\n")
else:
    out_lines.append("## Posteriors from `bayesian_mcmc_results.mat`\n")

    # Try common Dynare oo_.posterior structures
    pm = None
    hpdinf = None
    hpdsup = None
    if "posterior_mean" in mcmc:
        pm = mcmc["posterior_mean"]
    if "posterior_hpdinf" in mcmc:
        hpdinf = mcmc["posterior_hpdinf"]
    if "posterior_hpdsup" in mcmc:
        hpdsup = mcmc["posterior_hpdsup"]
    if "oo_" in mcmc and pm is None:
        oo = mcmc["oo_"]
        if hasattr(oo, "posterior_mean"): pm = oo.posterior_mean
        if hasattr(oo, "posterior_hpdinf"): hpdinf = oo.posterior_hpdinf
        if hasattr(oo, "posterior_hpdsup"): hpdsup = oo.posterior_hpdsup

    out_lines.append("\n### Parameter posteriors\n")
    out_lines.append("| Parameter | Posterior mean | 90% HPD low | 90% HPD high |")
    out_lines.append("|-----------|---------------:|------------:|-------------:|")

    def emit_struct(s, label):
        if s is None: return
        if hasattr(s, "_fieldnames"):
            for f in s._fieldnames:
                m = getattr(pm.parameters if pm else s, f, None) if pm else None
                # Skip; handled below
        else:
            try:
                for k, v in s.items():
                    print(k, v)
            except Exception:
                pass

    if pm is not None and hasattr(pm, "parameters"):
        names = pm.parameters._fieldnames
        for n in names:
            mu = getattr(pm.parameters, n, np.nan)
            lo = getattr(hpdinf.parameters, n, np.nan) if hpdinf is not None and hasattr(hpdinf, "parameters") else np.nan
            hi = getattr(hpdsup.parameters, n, np.nan) if hpdsup is not None and hasattr(hpdsup, "parameters") else np.nan
            out_lines.append(f"| {n} | {fmt(float(mu))} | {fmt(float(lo))} | {fmt(float(hi))} |")
    elif pm is not None:
        out_lines.append(f"| (raw) | {pm} | | |")

    # LMD
    if "MarginalDensity" in mcmc:
        md = mcmc["MarginalDensity"]
        out_lines.append("\n### Log marginal density\n")
        for attr in ["LaplaceApproximation", "ModifiedHarmonicMean"]:
            try:
                v = getattr(md, attr, None)
                if v is not None:
                    out_lines.append(f"- {attr}: {fmt(float(v), 4)}")
            except Exception:
                pass

# ---------------------------------------------------------------- IRFs
out_lines.append("\n## IRF peaks (saved_irfs_*.mat)\n")

irf_files = {
    "var":    DYNARE / "saved_irfs_var.mat",
    "hybrid": DYNARE / "saved_irfs_hybrid.mat",
    "mce":    DYNARE / "saved_irfs_mce.mat",
}

# Variables to report at peak for the monetary shock (eps_i)
mon_vars = [
    "yhat_au", "pi_au", "piQ", "dln_c", "dln_ib", "dln_ih",
    "dln_n", "pi_w", "i_10y", "i_au", "s_gap", "dln_x", "dln_m",
]

regime_data = {}
for tag, p in irf_files.items():
    d = load_mat(p)
    if d is None:
        regime_data[tag] = None
        continue
    irf_struct = d.get(f"irfs_{tag}", None)
    if irf_struct is None:
        out_lines.append(f"- {tag}: file present but `irfs_{tag}` struct not found.")
        regime_data[tag] = None
        continue
    regime_data[tag] = irf_struct

# Peak table for 100 bp monetary shock (eps_i)
out_lines.append("\n### Peak responses to monetary policy shock (`eps_i`, 100 bp annualized)\n")
out_lines.append("Sign / magnitude / quarter of peak across the three regimes.\n")
out_lines.append("| Variable | VAR peak | Q | Hybrid peak | Q | MCE peak | Q | MCE attenuation (%) |")
out_lines.append("|----------|---------:|--:|------------:|--:|---------:|--:|--------------------:|")

for v in mon_vars:
    row_vals = []
    for tag in ("var", "hybrid", "mce"):
        st = regime_data.get(tag)
        if st is None: row_vals.extend([np.nan, np.nan]); continue
        key = f"{v}_eps_i"
        try:
            arr = getattr(st, key, None)
        except Exception:
            arr = None
        if arr is None:
            row_vals.extend([np.nan, np.nan]); continue
        arr = np.asarray(arr).ravel()
        if arr.size == 0:
            row_vals.extend([np.nan, np.nan]); continue
        # find peak by absolute value
        idx_peak = int(np.argmax(np.abs(arr)))
        row_vals.extend([float(arr[idx_peak]), idx_peak + 1])
    var_p, var_q, hyb_p, hyb_q, mce_p, mce_q = row_vals
    # Attenuation: |hybrid - mce| / |hybrid| in pct
    if hyb_p != 0 and not np.isnan(hyb_p) and not np.isnan(mce_p):
        attn = 100 * (abs(hyb_p) - abs(mce_p)) / abs(hyb_p)
    else:
        attn = np.nan
    out_lines.append(
        f"| {v} | {fmt(var_p,4)} | {var_q if not np.isnan(var_q) else '?'} "
        f"| {fmt(hyb_p,4)} | {hyb_q if not np.isnan(hyb_q) else '?'} "
        f"| {fmt(mce_p,4)} | {mce_q if not np.isnan(mce_q) else '?'} "
        f"| {fmt(attn,1)} |"
    )

# Write
out_path = DYNARE / "2026_paper_inputs.md"
with open(out_path, "w") as f:
    f.write("\n".join(out_lines))
print(f"\nWrote {out_path}")
print(f"Lines: {len(out_lines)}")
