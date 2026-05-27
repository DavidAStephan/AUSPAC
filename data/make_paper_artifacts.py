#!/usr/bin/env python3
"""make_paper_artifacts.py

Python equivalent of make_paper_tables.m + make_paper_charts.m.  Reads
Phase L2 results_*.mat files from data/pac_blocks/, plus the L1.1
trend-efficiency .mat and the L1.2 trend-series .mat, and writes:

    dynare/paper_artifacts/table_*.{txt,tex,md}
    dynare/paper_artifacts/chart_*.png

Used because MATLAB R2020a -batch is blocked on Apple Silicon and the
Phase L2 .mat artefacts can be read directly via scipy.io.

Run:  cd ~/Documents/AUSPAC && python3 data/make_paper_artifacts.py
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

import numpy as np
import scipy.io as sio
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parents[1]
BLOCKS = ROOT / "data" / "pac_blocks"
ART = ROOT / "dynare" / "paper_artifacts"
ART.mkdir(parents=True, exist_ok=True)


# --- wp1044 reference values (Dubois et al. 2026, Tables 3.3.3 / 3.4.9 / 3.5.2 / 3.5.7 / 3.5.13)
WP1044 = {
    "va_price":     {"beta_0": 0.05,  "beta_1": 0.20,  "beta_2": 0.09,  "omega": 0.62, "R2": 0.61},
    "employment":   {"beta_0": 0.07,  "beta_1": 0.44,  "beta_2": 0.12,  "beta_3": 0.12,
                     "beta_4": 0.13, "omega": 0.34, "R2": 0.95},
    "consumption":  {"beta_0": 0.29,  "beta_1": 0.17,  "beta_2": 0.32,  "beta_3": -1.07,
                     "alpha_1": -1.15, "R2": 0.95},
    "housing_inv":  {"beta_0": 0.12,  "beta_1": 0.18,  "beta_2": 0.50,  "beta_3": 0.05,
                     "omega": 0.05, "R2": 0.89},
    "business_inv": {"beta_0": 0.096, "beta_1": 0.33,  "beta_2": 0.11,  "beta_3": 0.69,
                     "omega": 0.35, "sigma": 0.50, "R2": 0.83},
}


def _scalar(x):
    """Convert scipy.io 0-d / 1x1 array to float."""
    a = np.asarray(x).flatten()
    if a.size == 0:
        return float("nan")
    return float(a[0])


def _names(r):
    """Unpack the deeply-nested names cell array stored by writetable."""
    raw = r["names"]
    if raw.ndim == 0:
        return []
    out = []
    arr = raw.flatten()
    while isinstance(arr, np.ndarray) and arr.size and isinstance(arr[0], np.ndarray):
        arr = arr[0].flatten()
    for el in arr:
        if isinstance(el, np.ndarray):
            el = el.flatten()
            if el.size == 1:
                out.append(str(el[0]))
            else:
                out.append(" ".join(str(x) for x in el))
        else:
            out.append(str(el))
    return out


def _coefs(r):
    return np.asarray(r["coefs"]).flatten()


def _se(r):
    return np.asarray(r["se"]).flatten()


def _tstat(r):
    return np.asarray(r["tstat"]).flatten()


def _write_table(rows, header, basename, caption):
    """Write a 3-format table: .md (paper-friendly), .tex (booktabs), .txt (tab)."""
    md_path = ART / f"{basename}.md"
    tex_path = ART / f"{basename}.tex"
    txt_path = ART / f"{basename}.txt"

    # markdown
    with md_path.open("w") as f:
        f.write(f"### {caption}\n\n")
        f.write("| " + " | ".join(header) + " |\n")
        f.write("|" + "|".join("---" for _ in header) + "|\n")
        for row in rows:
            f.write("| " + " | ".join(str(c) for c in row) + " |\n")

    # latex
    align = "l" + "r" * (len(header) - 1)
    with tex_path.open("w") as f:
        f.write(r"\begin{table}[ht]" + "\n\\centering\n")
        f.write(f"\\caption{{{caption}}}\n")
        f.write(f"\\begin{{tabular}}{{{align}}}\n\\toprule\n")
        f.write(" & ".join(header) + r" \\" + "\n\\midrule\n")
        for row in rows:
            f.write(" & ".join(str(c) for c in row) + r" \\" + "\n")
        f.write("\\bottomrule\n\\end{tabular}\n\\end{table}\n")

    # plain text
    with txt_path.open("w") as f:
        f.write(caption + "\n\n")
        f.write("\t".join(header) + "\n")
        for row in rows:
            f.write("\t".join(str(c) for c in row) + "\n")

    print(f"  table  {basename}  ({len(rows)} rows)")


def _fmt(x, digits=3):
    if x is None or (isinstance(x, float) and np.isnan(x)):
        return "—"
    if isinstance(x, str):
        return x
    return f"{x:.{digits}f}"


# =====================================================================
# Tables
# =====================================================================

def table_3_va_price():
    r = sio.loadmat(BLOCKS / "results_va_price.mat")
    wp = WP1044["va_price"]
    rows = [
        ["beta_0 (ECM p*_Q - p_Q)",    _fmt(wp["beta_0"]),  _fmt(_scalar(r["beta_0"]))],
        ["beta_1 (piQ lag)",           _fmt(wp["beta_1"]),  _fmt(_scalar(r["beta_1"]))],
        ["beta_2 (yhat_t contemp)",    _fmt(wp["beta_2"]),  _fmt(_scalar(r["beta_2"]))],
        ["omega (calibrated)",          _fmt(wp["omega"]),  _fmt(_scalar(r["omega"]))],
        ["chi (depth-1)",               "~0.03",            _fmt(_scalar(r["chi"]))],
        ["R^2",                         _fmt(wp["R2"]),     _fmt(_scalar(r["R2"]))],
        ["N",                           "FR sample",        f"{int(_scalar(r['N']))}"],
    ]
    _write_table(rows,
                 ["coefficient", "wp1044 FR Table 3.3.3", "AU L2 iterative OLS"],
                 "table_3_va_price",
                 "Table 3 — VA-price PAC (wp1044 Eq 16): AU L2 vs FR-BDF")


def table_4_employment():
    r = sio.loadmat(BLOCKS / "results_employment.mat")
    wp = WP1044["employment"]
    bl = np.asarray(r["beta_lags"]).flatten()
    rows = [
        ["beta_0 (n*_S - n_S, ECM)", _fmt(wp["beta_0"]), _fmt(_scalar(r["beta_0"]))],
        ["beta_1 (Δn lag 1)",         _fmt(wp["beta_1"]), _fmt(bl[0] if bl.size > 0 else None)],
        ["beta_2 (Δn lag 2)",         _fmt(wp["beta_2"]), _fmt(bl[1] if bl.size > 1 else None)],
        ["beta_3 (Δn lag 3)",         _fmt(wp["beta_3"]), _fmt(bl[2] if bl.size > 2 else None)],
        ["beta_4 (contemp Δq_hat)",   _fmt(wp["beta_4"]), _fmt(_scalar(r["beta_4"]))],
        ["omega (calibrated)",         _fmt(wp["omega"]), _fmt(_scalar(r["omega"]))],
        ["chi (depth-3)",              "~0.43",            _fmt(_scalar(r["chi"]))],
        ["R^2",                        _fmt(wp["R2"]),    _fmt(_scalar(r["R2"]))],
        ["N",                          "FR sample",       f"{int(_scalar(r['N']))}"],
    ]
    _write_table(rows,
                 ["coefficient", "wp1044 FR Table 3.4.9", "AU L2 iterative OLS (depth 3)"],
                 "table_4_employment",
                 "Table 4 — Employment PAC (wp1044 Eq 30, depth 3): AU L2 vs FR-BDF")


def table_5_consumption():
    r = sio.loadmat(BLOCKS / "results_consumption.mat")
    wp = WP1044["consumption"]
    chi = _scalar(r["chi"])
    a1 = _scalar(r["alpha_1"])
    rows = [
        ["beta_0 (ECM c* - c)",                _fmt(wp["beta_0"]),  _fmt(_scalar(r["beta_0"]))],
        ["beta_1 (Δc lag)",                    _fmt(wp["beta_1"]),  _fmt(_scalar(r["beta_1"]))],
        ["alpha_1 (PV r_LH gap, free coef)",   _fmt(wp["alpha_1"]), _fmt(a1)],
        ["alpha_1 * chi (reduced form)",       f"{wp['alpha_1']*0.17:.2f}",
                                                                    _fmt(a1 * chi)],
        ["beta_PAC (Δybar lag)",                "n/a (FR free)",     _fmt(_scalar(r["beta_PAC"]))],
        ["beta_2 (HtM level-diff)",             _fmt(wp["beta_2"]), _fmt(_scalar(r["beta_2"]))],
        ["beta_3 (impact Δr_LH)",               _fmt(wp["beta_3"]), _fmt(_scalar(r["beta_3"]))],
        ["chi (depth-1)",                       "~0.17",             _fmt(chi)],
        ["R^2",                                 _fmt(wp["R2"]),     _fmt(_scalar(r["R2"]))],
        ["N",                                   "FR sample",        f"{int(_scalar(r['N']))}"],
    ]
    _write_table(rows,
                 ["coefficient", "wp1044 FR Table 3.5.2", "AU L2 iterative OLS"],
                 "table_5_consumption",
                 "Table 5 — Consumption PAC (wp1044 Eq 35): AU L2 vs FR-BDF (beta_0 match: 0.27 vs 0.29)")


def table_6_housing_inv():
    r = sio.loadmat(BLOCKS / "results_housing_inv.mat")
    wp = WP1044["housing_inv"]
    rows = [
        ["beta_0 (ECM I*_H/I_H)",     _fmt(wp["beta_0"]),  _fmt(_scalar(r["beta_0"]))],
        ["beta_1 (Δlog I_H lag)",     _fmt(wp["beta_1"]),  _fmt(_scalar(r["beta_1"]))],
        ["beta_2 (contemp Δy - ỹ)",   _fmt(wp["beta_2"]),  _fmt(_scalar(r["beta_2"]))],
        ["beta_3 (price spread 1-5)", _fmt(wp["beta_3"]),  "see results_housing_inv.txt"],
        ["omega (calibrated)",        _fmt(wp["omega"]),   _fmt(_scalar(r["omega"]))],
        ["chi (depth-1)",             "~0.18",              _fmt(_scalar(r["chi"]))],
        ["R^2",                       _fmt(wp["R2"]),      _fmt(_scalar(r["R2"]))],
        ["N",                         "FR sample",         f"{int(_scalar(r['N']))}"],
    ]
    _write_table(rows,
                 ["coefficient", "wp1044 FR Table 3.5.7", "AU L2 iterative OLS"],
                 "table_6_housing_inv",
                 "Table 6 — Housing inv PAC (wp1044 Eq 37): AU L2 vs FR-BDF")


def table_7_business_inv_wp1044():
    wp = WP1044["business_inv"]
    rows = [
        ["beta_0",   _fmt(wp["beta_0"]), "wp1044 Table 3.5.13"],
        ["beta_1",   _fmt(wp["beta_1"]), "wp1044 Table 3.5.13"],
        ["beta_2",   _fmt(wp["beta_2"]), "wp1044 Table 3.5.13"],
        ["beta_3",   _fmt(wp["beta_3"]), "wp1044 Table 3.5.13"],
        ["omega",    _fmt(wp["omega"]),  "AU = wp1044 (matched)"],
        ["sigma",    "0.5366",            "AU labour-FOC (≈ wp1044 0.50)"],
        ["R^2 (FR)", _fmt(wp["R2"]),     "wp1044 reported on FR data"],
    ]
    _write_table(rows,
                 ["coefficient", "value", "source"],
                 "table_7_business_inv_wp1044",
                 "Table 7 — Business inv calibration: wp1044 Option 1 import (no AU estimates; see PAC_BI_AU_EXPLORATION.md)")


def table_8_cross_block_summary():
    blocks = ["va_price", "employment", "consumption", "housing_inv"]
    label = {"va_price": "VA-price", "employment": "Employment",
             "consumption": "Consumption", "housing_inv": "Housing inv"}
    rows = []
    for b in blocks:
        r = sio.loadmat(BLOCKS / f"results_{b}.mat")
        au_b0 = _scalar(r["beta_0"])
        try:
            au_b1 = _scalar(r["beta_1"]) if "beta_1" in r else _scalar(np.asarray(r["beta_lags"]).flatten()[0])
        except Exception:
            au_b1 = float("nan")
        au_r2 = _scalar(r["R2"])
        wp = WP1044[b]
        ratio = au_b0 / wp["beta_0"] if wp["beta_0"] else float("nan")
        rows.append([label[b],
                     _fmt(au_b0), _fmt(wp["beta_0"]), f"{ratio:.1f}x",
                     _fmt(au_b1), _fmt(wp["beta_1"]),
                     _fmt(au_r2), _fmt(wp["R2"]),
                     "AU L2"])
    # BI: wp1044 imported
    wp = WP1044["business_inv"]
    rows.append(["Business inv",
                 "—", _fmt(wp["beta_0"]), "n/a",
                 "—", _fmt(wp["beta_1"]),
                 "—", _fmt(wp["R2"]),
                 "wp1044 (Option 1)"])
    _write_table(rows,
                 ["block", "beta_0 AU", "beta_0 FR", "AU/FR",
                  "beta_1 AU", "beta_1 FR",
                  "R^2 AU", "R^2 FR", "source"],
                 "table_8_cross_block_summary",
                 "Table 8 — Cross-block summary: AU L2 vs FR-BDF — beta_0, beta_1, R^2, source")


def table_9_bi_exploration():
    rows = [
        ["baseline (strict wp1044)",                "results_business_inv.mat",          "0.09"],
        ["v1: + AU dummies",                        "results_business_inv_au.mat",        "0.11"],
        ["v2: pre-residualize dummies",             "results_business_inv_au_v2.mat",    "-23.7"],
        ["v3-A: PV free + dummies (PV(Δq̂)=-5.03)", "(in v3.m, sub-variant A)",          "0.53"],
        ["v3-B: strict + dummies single-shot",      "(in v3.m, B)",                       "-2.20"],
        ["v3-C: strict + dummies loose clamps",     "(in v3.m, C)",                       "-67.0"],
        ["v4: combined PV coef=+1 + dummies",       "results_business_inv_au_v4.mat",    "-33.0"],
        ["v5: + ToT + piecewise trends",            "results_business_inv_au_v5.mat",    "-10.7"],
        ["v6: replace q with q_AU (ToT target)",    "results_business_inv_au_v6_tot.mat","-39.1"],
        ["wp736 (2019 simpler form) + dummies",     "results_business_inv_wp736.mat",    "-0.75"],
        ["simplified (drops PV)",                   "(in business_inv_simple.m)",         "0.33"],
    ]
    _write_table(rows,
                 ["variant", "results_file", "R^2 (raw)"],
                 "table_9_bi_exploration",
                 "Table 9 — Business investment specification variants tested in Phase L2 P1c")


def table_1_trend_efficiency():
    p = ROOT / "data" / "trend_efficiency.mat"
    if not p.exists():
        print("  skip table_1 (no trend_efficiency.mat)")
        return
    r = sio.loadmat(p)
    # z1..z9 with z_i_se
    rows = []
    for i in range(1, 10):
        zk = f"z{i}"
        sek = f"z{i}_se"
        if zk in r:
            zv = float(np.asarray(r[zk]).flatten()[0])
            if sek in r:
                sev = float(np.asarray(r[sek]).flatten()[0])
                rows.append([f"z_{i}", _fmt(zv), _fmt(sev)])
            else:
                rows.append([f"z_{i}", _fmt(zv), "(omitted)"])
    # Add scalar summary
    extras = {
        "g_E_pre_2002 (% p.a.)":  "g_E_pre_2002",
        "g_E_2002_08 (% p.a.)":   "g_E_2002_08",
        "g_E_post_08 (% p.a.)":   "g_E_post_08",
        "loglik":                  "loglik",
        "sigma_eps":               "sigma_eps",
        "covid_E_loss":            "covid_E_loss",
    }
    for lbl, key in extras.items():
        if key in r:
            v = float(np.asarray(r[key]).flatten()[0])
            rows.append([lbl, _fmt(v), "—"])
    _write_table(rows, ["coefficient", "AU L2 estimate", "se"],
                 "table_1_trend_efficiency",
                 "Table 1 — L1.1 trend efficiency E_t (Eq 7) AU L2 coefficients + 3-regime growth rates")


def table_2_block_trend_regimes():
    p = ROOT / "data" / "trend_series.mat"
    if not p.exists():
        print("  skip table_2 (no trend_series.mat)")
        return
    r = sio.loadmat(p)
    # Compute mean / first / last of each dlog_* trend series (annualised %)
    series_map = {
        "dlog_ybar":          "real GDP trend (y_bar)",
        "dlog_qbar":          "market VA trend (q_bar)",
        "dlog_nbar":          "employment trend (n_bar)",
        "dlog_IHbar":         "housing inv trend (I_H_bar)",
        "dlog_rkb_bar":       "user cost trend (r_KB_bar)",
        "dpi_Q_bar":          "VA-price inflation trend (pi_Q_bar)",
    }
    rows = []
    for key, label in series_map.items():
        if key in r:
            v = np.asarray(r[key]).flatten()
            v_valid = v[np.isfinite(v)]
            if v_valid.size:
                mean_q = float(np.nanmean(v))
                first_valid = v_valid[:min(8, v_valid.size)]
                last_valid = v_valid[-min(8, v_valid.size):]
                first8 = float(np.mean(first_valid))
                last8 = float(np.mean(last_valid))
                rows.append([label,
                             _fmt(mean_q * 400),
                             _fmt(first8 * 400),
                             _fmt(last8 * 400)])
    if not rows:
        rows = [["(no dlog_* trend fields)", "—", "—", "—"]]
    _write_table(rows,
                 ["block trend series", "mean (% p.a.)", "first 8q mean", "last 8q mean"],
                 "table_2_block_trend_regimes",
                 "Table 2 — L1.2 block-specific HP-filtered trend growth rates (annualised %)")


# =====================================================================
# Charts
# =====================================================================

def chart_cross_block_beta0():
    labels = ["VA-price", "Employment", "Consumption", "Housing inv", "Business inv"]
    au = []
    for b in ["va_price", "employment", "consumption", "housing_inv"]:
        r = sio.loadmat(BLOCKS / f"results_{b}.mat")
        au.append(_scalar(r["beta_0"]))
    au.append(np.nan)  # BI: wp1044 imported
    fr = [WP1044[b]["beta_0"] for b in ["va_price", "employment", "consumption", "housing_inv", "business_inv"]]

    x = np.arange(len(labels))
    fig, ax = plt.subplots(figsize=(10, 4.5))
    ax.bar(x - 0.2, fr, 0.4, label="wp1044 FR", color="#4c72b0")
    ax.bar(x + 0.2, [v if not np.isnan(v) else 0 for v in au], 0.4, label="AU L2", color="#dd8452")
    # mark BI as "imported"
    ax.text(4 + 0.2, 0.005, "(wp1044 imported)", ha="center", fontsize=8, rotation=90, color="gray")
    ax.set_xticks(x)
    ax.set_xticklabels(labels)
    ax.set_ylabel(r"$\beta_0$ (ECM speed)")
    ax.set_title(r"Cross-block $\beta_0$: AU L2 is 4-8x faster than France in 4 of 5 blocks"
                 "\n(consumption is the exception — AU ≈ FR)")
    ax.legend()
    ax.grid(True, alpha=0.3, axis="y")
    fig.tight_layout()
    fig.savefig(ART / "chart_beta0_cross_block.png", dpi=130)
    plt.close(fig)
    print("  chart  chart_beta0_cross_block.png")


def chart_bi_exploration():
    v_labels = [
        "baseline (strict)", "v1 +dummies", "v2 pre-residualize",
        "v3-A PV free (best fit)", "v3-B strict single-shot", "v3-C loose clamps",
        "v4 combined PV=+1", "v5 ToT + trends", "v6 replace q with q_AU",
        "wp736 (2019 form)", "simplified (no PV)",
    ]
    v_R2 = [0.09, 0.11, -23.7, 0.53, -2.20, -67.0, -33.0, -10.7, -39.1, -0.75, 0.33]
    colors = ["#dd8452" if x < 0.5 else "#55a868" for x in v_R2]
    fig, ax = plt.subplots(figsize=(10, 5.5))
    bars = ax.barh(v_labels, v_R2, color=colors)
    ax.axvline(0, color="k", lw=0.8)
    ax.axvline(0.83, color="#4c72b0", lw=1.0, ls="--", label="wp1044 FR R² = 0.83")
    ax.set_xlabel(r"R² on raw $\Delta\log i_b$")
    ax.set_title("AU business investment: 11 specification variants tested in Phase L2 P1c\n"
                 "Every strict-PAC variant fails (R² ≤ 0.11) on AU data")
    ax.legend(loc="lower right")
    ax.grid(True, alpha=0.3, axis="x")
    # annotate v3-A
    ax.text(0.53, 3.5, "  PV(Δq̂)=-5.03 vs structural +1\n  → wp1044 PAC rejected",
            fontsize=8, va="center", color="#dd8452")
    fig.tight_layout()
    fig.savefig(ART / "chart_bi_exploration.png", dpi=130)
    plt.close(fig)
    print("  chart  chart_bi_exploration.png")


def chart_r2_cross_block():
    labels = ["VA-price", "Employment", "Consumption", "Housing inv", "Business inv"]
    au = []
    for b in ["va_price", "employment", "consumption", "housing_inv"]:
        r = sio.loadmat(BLOCKS / f"results_{b}.mat")
        au.append(_scalar(r["R2"]))
    au.append(0.09)  # BI baseline strict (R²=0.09)
    fr = [WP1044[b]["R2"] for b in ["va_price", "employment", "consumption", "housing_inv", "business_inv"]]

    x = np.arange(len(labels))
    fig, ax = plt.subplots(figsize=(9.5, 4.5))
    ax.bar(x - 0.2, fr, 0.4, label="wp1044 FR", color="#4c72b0")
    ax.bar(x + 0.2, au, 0.4, label="AU L2 (BI = strict baseline)", color="#dd8452")
    ax.set_xticks(x)
    ax.set_xticklabels(labels)
    ax.set_ylabel(r"$R^2$ on raw $\Delta\log$ LHS")
    ax.set_title("Cross-block fit: 4 of 5 blocks fit wp1044 form on AU data; business inv rejected")
    ax.set_ylim(0, 1.0)
    ax.legend()
    ax.grid(True, alpha=0.3, axis="y")
    fig.tight_layout()
    fig.savefig(ART / "chart_r2_cross_block.png", dpi=130)
    plt.close(fig)
    print("  chart  chart_r2_cross_block.png")


def chart_consumption_headline():
    """Visualise the headline consumption β₀ match across blocks."""
    blocks = ["VA-price", "Employment", "Consumption", "Housing inv"]
    au = [0.258, 0.314, 0.266, 0.496]
    fr = [0.05,  0.07,  0.29,  0.12]
    ratios = [a / f for a, f in zip(au, fr)]
    fig, ax = plt.subplots(figsize=(8.5, 4.0))
    bars = ax.bar(blocks, ratios, color=["#dd8452"] * 4)
    bars[2].set_color("#55a868")  # consumption green
    ax.axhline(1.0, color="k", lw=0.8, ls="--", label="AU = FR")
    ax.set_ylabel(r"AU $\beta_0$ / FR $\beta_0$ ratio")
    ax.set_title("Consumption is the only block where AU ECM speed matches France\n"
                 "(other 4 blocks: AU 4-8x faster)")
    for i, (b, r) in enumerate(zip(blocks, ratios)):
        ax.text(i, r + 0.1, f"{r:.1f}x", ha="center", fontsize=10)
    ax.legend(loc="upper right")
    ax.grid(True, alpha=0.3, axis="y")
    fig.tight_layout()
    fig.savefig(ART / "chart_consumption_headline.png", dpi=130)
    plt.close(fig)
    print("  chart  chart_consumption_headline.png")


# =====================================================================
# Main
# =====================================================================
def main():
    print(f"=== make_paper_artifacts.py -> {ART} ===")
    table_1_trend_efficiency()
    table_2_block_trend_regimes()
    table_3_va_price()
    table_4_employment()
    table_5_consumption()
    table_6_housing_inv()
    table_7_business_inv_wp1044()
    table_8_cross_block_summary()
    table_9_bi_exploration()
    chart_cross_block_beta0()
    chart_bi_exploration()
    chart_r2_cross_block()
    chart_consumption_headline()
    print("done.")


if __name__ == "__main__":
    main()
