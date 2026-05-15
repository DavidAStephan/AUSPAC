"""Regenerate three-regime monetary policy IRF figures (Phase G).

Reads saved_irfs_{var,hybrid,mce}.mat (1-s.d. responses) and scales to a
100bp annualized = 0.25 qpp monetary tightening using the Phase G posterior
mean of stderr_eps_i = 0.1105.

Output:
  three_regime_monetary_irf.png        (FR-BDF Fig 6.2.2 style: 2 panels)
  three_regime_full_comparison.png     (11-panel grid: all key variables)

This script exists because MATLAB is not always available; the canonical
generator remains generate_three_regime_irfs.m. Both use the same
saved_irfs_*.mat artefacts and produce equivalent figures.
"""

from pathlib import Path
import numpy as np
from scipy.io import loadmat
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

HERE = Path(__file__).resolve().parent
DYNARE = HERE.parent  # dynare/ workspace where MATLAB writes .mat/.png artefacts

STDERR_EPS_I = 0.1110            # Phase Q posterior mean (forward UIP, 2026-05-15)
TARGET = 0.25                    # 100bp annualized
SCALE = TARGET / STDERR_EPS_I    # ≈ 2.262
T_PLOT = 80
SHOCK = "eps_i"

REGIMES = [
    ("var",    "VAR-based",  (0.000, 0.447, 0.741), "--",  1.5),
    ("hybrid", "Hybrid",     (0.000, 0.000, 0.000), "-",   2.0),
    ("mce",    "Full MCE",   (0.850, 0.325, 0.098), "-.",  1.5),
]


def load_irfs():
    out = {}
    for tag, *_ in REGIMES:
        d = loadmat(DYNARE / f"saved_irfs_{tag}.mat",
                    squeeze_me=True, struct_as_record=False)
        key = [k for k in d if not k.startswith("__")][0]
        out[tag] = d[key]
    return out


def series(irf_struct, var):
    field = f"{var}_{SHOCK}"
    if not hasattr(irf_struct, field):
        return np.zeros(T_PLOT)
    arr = np.atleast_1d(np.array(getattr(irf_struct, field))).ravel()
    return arr * SCALE


def fig_two_panel(all_irfs):
    fig, axes = plt.subplots(1, 2, figsize=(10, 4), constrained_layout=True)
    panels = [
        ("ln_Q", "Real GDP",
         "(deviation from baseline, in %)", False),
        ("piQ", "VA price inflation",
         "(annualized, deviation from baseline, in pp)", True),
    ]
    for ax, (var, title, ylabel, annualize) in zip(axes, panels):
        for tag, label, color, ls, lw in REGIMES:
            y = series(all_irfs[tag], var)
            if annualize:
                y = y * 4
            T = min(T_PLOT, len(y))
            ax.plot(range(1, T+1), y[:T],
                    color=color, linestyle=ls, linewidth=lw, label=label)
        ax.axhline(0, color="black", linestyle=":", linewidth=0.5)
        ax.set_xlabel("Quarters")
        ax.set_title(f"{title}\n{ylabel}", fontsize=11)
        ax.grid(True, alpha=0.4)
        ax.set_xlim(1, T_PLOT)
    axes[0].legend(loc="best", fontsize=9)
    fig.suptitle("Monetary policy tightening (100bp annualized) "
                 "under different expectations",
                 fontsize=13, fontweight="bold")
    out = DYNARE / "three_regime_monetary_irf.png"
    fig.savefig(out, dpi=300)
    plt.close(fig)
    print(f"  Saved: {out.name}")


def fig_full_panel(all_irfs):
    vars_ = [
        ("ln_Q",     "Real GDP"),
        ("piQ",      "VA price inflation"),
        ("pi_au",    "CPI inflation"),
        ("dln_c",    "Consumption"),
        ("dln_ib",   "Business inv."),
        ("dln_ih",   "Housing inv."),
        ("dln_n",    "Employment"),
        ("pi_w",     "Wage inflation"),
        ("s_gap",    "Exchange rate"),
        ("i_10y",    "10Y yield"),
        ("i_au",     "Policy rate"),
    ]
    nrows, ncols = 3, 4
    fig, axes = plt.subplots(nrows, ncols, figsize=(14, 9),
                             constrained_layout=True)
    flat = axes.flatten()
    for ax, (var, label) in zip(flat[:len(vars_)], vars_):
        for tag, _, color, ls, lw in REGIMES:
            y = series(all_irfs[tag], var)
            T = min(T_PLOT, len(y))
            ax.plot(range(1, T+1), y[:T],
                    color=color, linestyle=ls, linewidth=lw)
        ax.axhline(0, color="black", linestyle=":", linewidth=0.5)
        ax.set_title(label, fontsize=10)
        ax.set_xlabel("Quarters", fontsize=8)
        ax.set_ylabel("% dev.", fontsize=8)
        ax.set_xlim(1, T_PLOT)
        ax.grid(True, alpha=0.4)
        ax.tick_params(labelsize=8)
    # Legend in trailing empty slot
    leg_ax = flat[len(vars_)]
    leg_ax.axis("off")
    handles = [plt.Line2D([0], [0], color=c, linestyle=ls, linewidth=lw,
                          label=lbl)
               for _, lbl, c, ls, lw in REGIMES]
    leg_ax.legend(handles=handles, loc="center", fontsize=11,
                  frameon=True)
    for extra in flat[len(vars_)+1:]:
        extra.axis("off")
    fig.suptitle("Three-regime comparison: all variables "
                 "(100bp annualized monetary tightening, Phase G)",
                 fontsize=13, fontweight="bold")
    out = DYNARE / "three_regime_full_comparison.png"
    fig.savefig(out, dpi=300)
    plt.close(fig)
    print(f"  Saved: {out.name}")


def main():
    print(f"=== Three-regime IRF figure regeneration (Phase G) ===")
    print(f"  Scale: 0.25 / {STDERR_EPS_I} = {SCALE:.4f}")
    all_irfs = load_irfs()
    fig_two_panel(all_irfs)
    fig_full_panel(all_irfs)
    print("=== Done ===")


if __name__ == "__main__":
    main()
