"""APP-style experiment (Phase L4): 200bp persistent term-premium shock.

A QE-style asset purchase programme typically shows up in this model as a
persistent negative term-premium shock — APP buys long-dated bonds,
compressing the term premium. We simulate a 200bp annualised compression
(= -0.50 qpp) via the eps_tp shock in the Hybrid regime.

The roadmap notes that AU has not run an APP-equivalent programme, so this
is a hypothetical scenario; the result quantifies what the AU-PAC model
predicts the response *would* be if the RBA had run a balance-sheet
programme during 2015-18.

Output: app_experiment_200bp.png
"""

from pathlib import Path
import numpy as np
from scipy.io import loadmat
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

HERE = Path(__file__).resolve().parent
MAT = HERE / "saved_irfs_hybrid.mat"

STDERR_EPS_TP = 0.05            # model calibration
TARGET = -0.50                  # -200bp annualised (negative because term premium falls)
SCALE = TARGET / STDERR_EPS_TP  # -10.0 (sign included)
T_PLOT = 40
SHOCK = "eps_tp"

VARS = [
    ("i_10y",       "10Y yield (qpp)"),
    ("ln_C",        "Consumption level (% from SS)"),
    ("ln_IB",       "Business inv. level (% from SS)"),
    ("ln_IH",       "Housing inv. level (% from SS)"),
    ("ln_C_star",   "Consumption permanent income (% from SS)"),
    ("ln_IB_star",  "Business inv. target (% from SS)"),
    ("ln_IH_star",  "Housing inv. target (% from SS)"),
    ("yhat_au",     "Output gap (%) — note: short-run gap mostly nil"),
    ("piQ",         "VA price infl. (qpp)"),
]


def main():
    d = loadmat(MAT, squeeze_me=True, struct_as_record=False)
    key = [k for k in d if not k.startswith("__")][0]
    ir = d[key]

    fig, axes = plt.subplots(3, 3, figsize=(13, 9), constrained_layout=True)
    for ax, (var, vlabel) in zip(axes.flat, VARS):
        field = f"{var}_{SHOCK}"
        if not hasattr(ir, field):
            ax.set_title(f"NOT FOUND: {var}")
            continue
        y = np.atleast_1d(np.array(getattr(ir, field))).ravel() * SCALE
        T = min(T_PLOT, len(y))
        ax.plot(range(1, T + 1), y[:T], color="black", linewidth=1.6)
        ax.axhline(0, color="gray", linewidth=0.5, linestyle=":")
        ax.set_title(vlabel, fontsize=10)
        ax.set_xlabel("Quarters", fontsize=8)
        ax.grid(True, alpha=0.3)
        ax.tick_params(labelsize=8)
        ax.set_xlim(1, T_PLOT)
    fig.suptitle(
        "APP-style experiment: 200bp annualised term-premium compression "
        f"(scale = {TARGET}/σ_tp = {TARGET}/{STDERR_EPS_TP} = {SCALE:+.1f}); "
        "hybrid regime",
        fontsize=12, fontweight="bold")
    out = HERE / "app_experiment_200bp.png"
    fig.savefig(out, dpi=200)
    plt.close(fig)
    print(f"Saved: {out.name}")


if __name__ == "__main__":
    main()
