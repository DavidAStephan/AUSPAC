"""Generate wp736-style 15-panel monetary policy IRF chart matching FR-BDF
Figure 6.2.2 (three-regime: VAR / Hybrid / MCE).

Layout: 5 rows x 3 cols (15 panels). All responses scaled to 100bp annualized
monetary tightening (= 0.25 qpp; scale = 0.25 / stderr_eps_i).

Mapping from wp736 to AU-PAC variables:
  GDP (% dev)              -> ln_Q
  Real consumption (% dev) -> ln_C
  Real business inv        -> ln_IB
  Real household inv       -> ln_IH
  Real exports             -> ln_x_level
  Real imports             -> ln_m_level
  Trade balance / GDP      -> 0.23*(ln_x_level - ln_m_level) (AU export share)
  Unemployment rate (pp)   -> u_gap
  CPI inflation y/y (pp)   -> pi_au * 4  (annualized)
  VA price inflation y/y   -> piQ * 4
  Wage inflation y/y       -> pi_w * 4
  Short rate y/y (pp)      -> i_au * 4
  Long rate y/y (pp)       -> i_10y * 4
  Real effective FX        -> s_gap  (already in % terms; sign +=AUD deprec)
  UIP forward NPV (pp ann) -> pv_i_uip * 4  (Phase Q diagnostic, replaces wp736 nominal FX)
"""

from pathlib import Path
import numpy as np
from scipy.io import loadmat
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

HERE = Path(__file__).resolve().parent

STDERR_EPS_I = 0.1110            # Phase Q (2026-05-15) posterior mean
TARGET = 0.25                    # 100bp annualized
SCALE = TARGET / STDERR_EPS_I    # ~2.252
T_PLOT = 40
SHOCK = "eps_i"

REGIMES = [
    ("var",    "VAR-based",  (0.000, 0.447, 0.741), "--",  1.5),
    ("hybrid", "Hybrid",     (0.000, 0.000, 0.000), "-",   2.0),
    ("mce",    "Full MCE",   (0.850, 0.325, 0.098), "-.",  1.5),
]

# AU export share of GDP (ABS 2023): ~23%
X_SHARE = 0.23

# Panel definitions: (variables list to combine + coeffs, label, y-label)
# Each entry: (combos, title, ylabel) where combos = [(var, coeff, annualize)]
PANELS = [
    # Row 1
    ([("ln_Q", 1.0, False)],      "Real GDP",
     "% deviation"),
    ([("ln_C", 1.0, False)],      "Real consumption",
     "% deviation"),
    ([("ln_IB", 1.0, False)],     "Real business investment",
     "% deviation"),
    # Row 2
    ([("ln_IH", 1.0, False)],     "Real household investment",
     "% deviation"),
    ([("ln_x_level", 1.0, False)],"Real exports",
     "% deviation"),
    ([("ln_m_level", 1.0, False)],"Real imports",
     "% deviation"),
    # Row 3
    ([("ln_x_level", X_SHARE, False), ("ln_m_level", -X_SHARE, False)],
     "Trade balance / GDP (proxy)",  "pp of GDP"),
    ([("u_gap", 1.0, False)],     "Unemployment gap",
     "pp deviation"),
    ([("pi_au", 1.0, True)],      "CPI inflation (y-o-y)",
     "pp deviation"),
    # Row 4
    ([("piQ", 1.0, True)],        "VA price inflation (y-o-y)",
     "pp deviation"),
    ([("pi_w", 1.0, True)],       "Wage inflation (y-o-y)",
     "pp deviation"),
    ([("i_au", 1.0, True)],       "Short-term rate (y-o-y)",
     "pp deviation"),
    # Row 5
    ([("i_10y", 1.0, True)],      "10Y nominal rate (y-o-y)",
     "pp deviation"),
    ([("s_gap", 1.0, False)],     "Real exchange rate (+=AUD depreciation)",
     "% deviation"),
    ([("pv_i_uip", 1.0, True)],   "UIP forward NPV (Phase Q)",
     "pp deviation, annualised"),
]


def series_for_panel(irfs, combos):
    """Return T-vector for one panel: linear combination of fields, scaled."""
    y = None
    for var, coeff, annualize in combos:
        field = f"{var}_{SHOCK}"
        if not hasattr(irfs, field):
            v = np.zeros(T_PLOT)
        else:
            v = np.atleast_1d(np.array(getattr(irfs, field))).ravel()
        v = v * SCALE * coeff
        if annualize:
            v = v * 4.0
        if y is None:
            y = v.copy()
        else:
            T = min(len(y), len(v))
            y = y[:T] + v[:T]
    return y


def load_irfs():
    out = {}
    for tag, *_ in REGIMES:
        d = loadmat(HERE / f"saved_irfs_{tag}.mat",
                    squeeze_me=True, struct_as_record=False)
        key = [k for k in d if not k.startswith("__")][0]
        out[tag] = d[key]
    return out


def main():
    all_irfs = load_irfs()
    fig, axes = plt.subplots(5, 3, figsize=(15, 16), constrained_layout=True)
    flat = axes.flatten()

    for ax, (combos, title, ylabel) in zip(flat, PANELS):
        for tag, lbl, color, ls, lw in REGIMES:
            y = series_for_panel(all_irfs[tag], combos)
            T = min(T_PLOT, len(y))
            ax.plot(range(1, T+1), y[:T],
                    color=color, linestyle=ls, linewidth=lw, label=lbl)
        ax.axhline(0, color="black", linewidth=0.4, linestyle=":")
        ax.set_title(title, fontsize=10, fontweight="bold")
        ax.set_xlabel("Quarters after shock", fontsize=8)
        ax.set_ylabel(ylabel, fontsize=8)
        ax.set_xlim(1, T_PLOT)
        ax.grid(True, alpha=0.35)
        ax.tick_params(labelsize=8)

    # Shared legend at the top
    handles, labels = axes[0, 0].get_legend_handles_labels()
    fig.legend(handles, labels, loc="upper center",
               bbox_to_anchor=(0.5, 1.01), ncol=3, fontsize=11,
               frameon=True, fancybox=True)

    fig.suptitle(
        "AU-PAC monetary policy tightening (100bp annualised) — "
        "three-regime IRFs (wp736 Fig 6.2.2 layout, Phase Q forward UIP)",
        fontsize=13, fontweight="bold", y=1.04)

    out = HERE / "three_regime_wp736_style.png"
    fig.savefig(out, dpi=200, bbox_inches="tight")
    plt.close(fig)
    print(f"Saved: {out.name}")


if __name__ == "__main__":
    main()
