"""Regenerate the supplementary figures referenced in the working paper
that aren't covered by the main regen_*.py helpers.

Outputs:
  data_observables.png      — 9-panel time series of the Bayesian observables
  irf_overview_output.png   — output gap response to all major shocks
"""

from pathlib import Path
import numpy as np
from scipy.io import loadmat
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from datetime import date

HERE = Path(__file__).resolve().parent

# Sample axis: 122 quarters from 1994Q3
START = date(1994, 7, 1)
T = 122


def quarter_dates(start, T):
    out = []
    y, m = start.year, start.month
    for _ in range(T):
        out.append(date(y, m, 1))
        m += 3
        if m > 12:
            m -= 12
            y += 1
    return out


def fig_observables():
    d = loadmat(HERE / "estimation_data.mat", squeeze_me=True, struct_as_record=False)
    keys = [k for k in d if not k.startswith("__")]
    dates_ = quarter_dates(START, T)
    fig, axes = plt.subplots(3, 3, figsize=(12, 8), constrained_layout=True)
    for ax, k in zip(axes.flat, keys[:9]):
        y = np.atleast_1d(np.array(d[k])).ravel()
        ax.plot(dates_[:len(y)], y, "b-", linewidth=1.2)
        ax.axhline(np.mean(y), color="gray", linestyle=":", linewidth=0.7)
        ax.set_title(k, fontsize=10)
        ax.grid(True, alpha=0.3)
        ax.xaxis.set_major_locator(mdates.YearLocator(5))
        ax.xaxis.set_major_formatter(mdates.DateFormatter("%Y"))
        ax.tick_params(labelsize=8)
    fig.suptitle("Nine Bayesian observables, 1994Q3–2024Q4 (122 quarters)",
                 fontsize=13, fontweight="bold")
    fig.savefig(HERE / "data_observables.png", dpi=200)
    plt.close(fig)
    print("Saved: data_observables.png")


def fig_irf_overview():
    d = loadmat(HERE / "saved_irfs_hybrid.mat", squeeze_me=True,
                struct_as_record=False)
    ir = d[[k for k in d if not k.startswith("__")][0]]

    shocks = [
        ("eps_i",    0.25 / 0.1102,   "100bp policy tightening", "tab:red"),
        ("eps_q_us", 1.0 / 1.138,     "1pp US output-gap shock", "tab:blue"),
        ("eps_g",    1.0 / 0.3,       "1% govt spending shock",  "tab:green"),
        ("eps_pcom", 10.0 / 3.0,      "10% commodity price",     "tab:orange"),
        ("eps_pQ",   1.0 / 0.571,     "1pp cost-push shock",     "tab:purple"),
        ("eps_tfp",  1.0 / 0.2,       "1% TFP shock",            "tab:brown"),
        ("eps_tp",   0.25 / 0.05,     "100bp term-premium",      "tab:pink"),
    ]
    T_plot = 40
    fig, ax = plt.subplots(figsize=(11, 6), constrained_layout=True)
    for sh, scale, label, color in shocks:
        field = f"yhat_au_{sh}"
        if not hasattr(ir, field):
            continue
        y = np.atleast_1d(np.array(getattr(ir, field))).ravel() * scale
        T_use = min(T_plot, len(y))
        ax.plot(range(1, T_use + 1), y[:T_use], label=label,
                color=color, linewidth=1.6)
    ax.axhline(0, color="black", linewidth=0.4, linestyle=":")
    ax.set_title("Output-gap responses to seven structural shocks "
                 "(hybrid regime, policy-relevant magnitudes)",
                 fontsize=11, fontweight="bold")
    ax.set_xlabel("Quarters")
    ax.set_ylabel("yhat_au deviation (%)")
    ax.legend(loc="best", fontsize=9)
    ax.grid(True, alpha=0.3)
    ax.set_xlim(1, T_plot)
    fig.savefig(HERE / "irf_overview_output.png", dpi=200)
    plt.close(fig)
    print("Saved: irf_overview_output.png")


if __name__ == "__main__":
    fig_observables()
    fig_irf_overview()
