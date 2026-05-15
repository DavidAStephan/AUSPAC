"""Long-run convergence figure (placeholder for FR-BDF Fig 5.1.1).

Without a full simult_-style simulation (which requires MATLAB/Dynare),
we approximate the model's convergence from off-steady-state initial
conditions by visualising the long-horizon decay of IRFs to three
representative shocks. In a linear model these IRFs ARE the convergence
paths from a particular initial perturbation, so the qualitative shape
of the decay matches what the canonical unconditional simulation would
produce.

Output: long_run_convergence_proxy.png

For the full MATLAB-based simulation (true off-SS initial state), see
long_run_convergence.m.
"""

from pathlib import Path
import numpy as np
from scipy.io import loadmat
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

HERE = Path(__file__).resolve().parent
MAT = HERE / "saved_irfs_hybrid.mat"

T_PLOT = 80   # long horizon

# (shock_id, label, color, lineweight)
SCENARIOS = [
    ("eps_q",    "+1 s.d. AU output-gap impulse (boom-start)",
     (0.000, 0.447, 0.741), "-",  1.6),
    ("eps_pcom", "+1 s.d. commodity price impulse (terms-of-trade start)",
     (0.466, 0.674, 0.188), "--", 1.6),
    ("eps_i",    "+1 s.d. policy tightening impulse (tight-start)",
     (0.850, 0.325, 0.098), "-.", 1.6),
]

VARS = [
    ("yhat_au",  "Output gap (%)"),
    ("pi_au",    "CPI inflation (qpp)"),
    ("piQ",      "VA price infl. (qpp)"),
    ("dln_c",    "Consumption growth"),
    ("dln_ib",   "Business inv. growth"),
    ("dln_ih",   "Housing inv. growth"),
    ("dln_n",    "Employment growth"),
    ("pi_w",     "Wage inflation (qpp)"),
    ("s_gap",    "Exchange rate gap"),
    ("i_au",     "Policy rate gap"),
    ("i_10y",    "10Y yield (qpp)"),
    ("u_gap",    "Unemployment gap (pp)"),
]


def load_irfs():
    d = loadmat(MAT, squeeze_me=True, struct_as_record=False)
    key = [k for k in d if not k.startswith("__")][0]
    return d[key]


def series(irf_struct, var, shock):
    field = f"{var}_{shock}"
    if not hasattr(irf_struct, field):
        return np.zeros(T_PLOT)
    arr = np.atleast_1d(np.array(getattr(irf_struct, field))).ravel()
    return arr


def main():
    ir = load_irfs()
    fig, axes = plt.subplots(3, 4, figsize=(14, 9), constrained_layout=True)
    flat = axes.flatten()
    for ax, (var, vlabel) in zip(flat, VARS):
        for shock, label, color, ls, lw in SCENARIOS:
            y = series(ir, var, shock)
            T = min(T_PLOT, len(y))
            ax.plot(range(1, T + 1), y[:T],
                    color=color, linestyle=ls, linewidth=lw, label=label)
        ax.axhline(0, color="black", linewidth=0.4, linestyle=":")
        ax.set_title(vlabel, fontsize=10)
        ax.set_xlabel("Quarters", fontsize=8)
        ax.grid(True, alpha=0.3)
        ax.tick_params(labelsize=8)
        ax.set_xlim(1, T_PLOT)
    flat[0].legend(loc="best", fontsize=7, framealpha=0.85)
    fig.suptitle("AU-PAC convergence to balanced growth path "
                 "(proxy via long-horizon IRFs, hybrid regime)",
                 fontsize=13, fontweight="bold")
    out = HERE / "long_run_convergence_proxy.png"
    fig.savefig(out, dpi=200)
    plt.close(fig)
    print(f"Saved: {out.name}")


if __name__ == "__main__":
    main()
