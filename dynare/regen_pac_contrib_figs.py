"""Historical dynamic-contributions decomposition for the 5 PAC equations.

For each PAC equation
    Δy_t = Σ_k coeff_k · regressor_k(t)  + ε_t,
this script reads the smoothed regressors and shocks from
bayesian_mcmc_results.mat (Phase G run), multiplies them by posterior-mean
coefficients, and plots the stacked time-series contribution of each channel.

Replicates wp736 Figs 4.4.1 (VA price), 4.5.3 / 4.6.1 (consumption),
4.6.3 (business inv.), 4.7.x (housing inv.), and the 4.5.2 employment block.

Output (per equation):
  contrib_pQ.png    — VA price (Section 4.3.4)
  contrib_c.png     — consumption (Section 4.5)
  contrib_ib.png    — business investment (Section 4.6)
  contrib_ih.png    — housing investment (Section 4.7)
  contrib_n.png     — employment (Section 4.4.4)
  contrib_check.txt — residual diagnostics (LHS minus reconstructed)
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
MAT = HERE / "bayesian_mcmc_results.mat"

# --- Sample axis ---
# Estimation: 122 quarters, 1994Q3 .. 2024Q4
START = date(1994, 7, 1)
T = 122


def quarter_dates(start, T):
    months = [(start.year, start.month + 3 * i) for i in range(T)]
    out = []
    for y, m in months:
        while m > 12:
            m -= 12
            y += 1
        out.append(date(y, m, 1))
    return out


def load_bayesian():
    d = loadmat(MAT, squeeze_me=True, struct_as_record=False)
    sv = d["oo_"].SmoothedVariables
    ss = d["oo_"].SmoothedShocks
    pn = list(d["M_"].param_names)
    pv = np.asarray(d["M_"].params).ravel()
    params = {pn[i]: float(pv[i]) for i in range(len(pn))}
    return sv, ss, params


def s(sv, name):
    return np.atleast_1d(np.array(getattr(sv, name))).ravel()


def lag(x, k=1):
    out = np.full_like(x, np.nan, dtype=float)
    if k < len(x):
        out[k:] = x[:-k]
    return out


def stacked_plot(ax, dates_, ydict, lhs, title, ylabel="Δ log y (qpp)"):
    """Plot positive contributions stacked above zero, negative below."""
    keys = list(ydict.keys())
    colors = plt.cm.tab10.colors + plt.cm.tab20.colors
    color_map = {k: colors[i % len(colors)] for i, k in enumerate(keys)}

    pos_stack = np.zeros(len(dates_))
    neg_stack = np.zeros(len(dates_))
    for k in keys:
        y = ydict[k]
        pos = np.maximum(y, 0)
        neg = np.minimum(y, 0)
        ax.fill_between(dates_, pos_stack, pos_stack + pos,
                        color=color_map[k], alpha=0.85, label=k, linewidth=0)
        ax.fill_between(dates_, neg_stack, neg_stack + neg,
                        color=color_map[k], alpha=0.85, linewidth=0)
        pos_stack = pos_stack + pos
        neg_stack = neg_stack + neg

    ax.plot(dates_, lhs, color="black", linewidth=1.3, label="Δ log y (actual)")
    ax.axhline(0, color="black", linewidth=0.4)
    ax.set_title(title, fontsize=12, fontweight="bold")
    ax.set_ylabel(ylabel)
    ax.xaxis.set_major_locator(mdates.YearLocator(5))
    ax.xaxis.set_major_formatter(mdates.DateFormatter("%Y"))
    ax.grid(True, alpha=0.3)
    ax.legend(loc="best", fontsize=8, ncol=2, framealpha=0.85)


def plot_equation(name, title, contributions, lhs, fname,
                  ylabel="Δ log y (qpp)"):
    """Save 2-panel stacked decomposition: full sample + pre-COVID zoom."""
    dates_ = quarter_dates(START, T)
    fig, (ax_full, ax_zoom) = plt.subplots(
        2, 1, figsize=(11, 9), constrained_layout=True
    )

    stacked_plot(ax_full, dates_, contributions, lhs,
                 f"{title} — full sample",
                 ylabel=ylabel)

    cutoff = date(2019, 12, 31)
    mask = np.array([d <= cutoff for d in dates_])
    contributions_z = {k: v[mask] for k, v in contributions.items()}
    lhs_z = lhs[mask]
    dates_z = [d for d, m in zip(dates_, mask) if m]

    keys = list(contributions_z.keys())
    colors = plt.cm.tab10.colors + plt.cm.tab20.colors
    color_map = {k: colors[i % len(colors)] for i, k in enumerate(keys)}
    pos_stack = np.zeros(len(dates_z))
    neg_stack = np.zeros(len(dates_z))
    for k in keys:
        y = contributions_z[k]
        pos = np.maximum(y, 0)
        neg = np.minimum(y, 0)
        ax_zoom.fill_between(dates_z, pos_stack, pos_stack + pos,
                             color=color_map[k], alpha=0.85,
                             label=k, linewidth=0)
        ax_zoom.fill_between(dates_z, neg_stack, neg_stack + neg,
                             color=color_map[k], alpha=0.85, linewidth=0)
        pos_stack = pos_stack + pos
        neg_stack = neg_stack + neg
    ax_zoom.plot(dates_z, lhs_z, color="black", linewidth=1.3,
                 label="Δ log y (actual)")
    ax_zoom.axhline(0, color="black", linewidth=0.4)
    ax_zoom.set_title(f"{title} — pre-COVID zoom (1995–2019)",
                      fontsize=12, fontweight="bold")
    ax_zoom.set_ylabel(ylabel)
    ax_zoom.xaxis.set_major_locator(mdates.YearLocator(5))
    ax_zoom.xaxis.set_major_formatter(mdates.DateFormatter("%Y"))
    ax_zoom.grid(True, alpha=0.3)
    ax_zoom.legend(loc="best", fontsize=8, ncol=2, framealpha=0.85)

    out = HERE / fname
    fig.savefig(out, dpi=200)
    plt.close(fig)
    return out


def main():
    sv, ss, p = load_bayesian()
    dates_ = quarter_dates(START, T)
    diag_lines = []

    # --- VA price (pQ) -----------------------------------------------------
    pQ_level = s(sv, "pQ_level")
    diff_pQ = np.diff(pQ_level, prepend=pQ_level[0])
    diff_pQ[0] = np.nan
    contrib_pQ = {
        "Error correction: b0_pQ·(piQ_hat₋₁ − pQ₋₁)":
            p["b0_pQ"] * (lag(s(sv, "piQ_hat")) - lag(pQ_level)),
        "AR lag: b1_pQ·Δlog pQ₋₁":
            p["b1_pQ"] * lag(diff_pQ),
        "PAC expectation":
            s(sv, "pac_expectation_pac_pQ"),
        "Output gap: b2_pQ·yhat_au":
            p["b2_pQ"] * s(sv, "yhat_au"),
        "PV aux. (pv_piQ_aux)":
            s(sv, "pv_piQ_aux"),
        "Shock: eps_pQ":
            s(ss, "eps_pQ"),
    }
    recon = sum(contrib_pQ.values())
    diag_lines.append(f"pQ: max|LHS-recon| = {np.nanmax(np.abs(diff_pQ - recon)):.2e}")
    plot_equation("pQ",
                  "VA price PAC (Section 4.3.4) — historical decomposition",
                  contrib_pQ, diff_pQ, "contrib_piQ.png",
                  ylabel="Δ log pQ (qpp)")

    # --- Consumption (c) ---------------------------------------------------
    ln_c = s(sv, "ln_c_level")
    diff_c = np.diff(ln_c, prepend=ln_c[0])
    diff_c[0] = np.nan
    contrib_c = {
        "Error correction: b0_c·(c_hat₋₁ − ln_c₋₁)":
            p["b0_c"] * (lag(s(sv, "c_hat")) - lag(ln_c)),
        "AR lag: b1_c·Δlog c₋₁":
            p["b1_c"] * lag(diff_c),
        "PAC expectation":
            s(sv, "pac_expectation_pac_c"),
        "Rate channel: b2_c·i_gap₋₁":
            p["b2_c"] * lag(s(sv, "i_gap")),
        "MP surprise: b_di_c·di_gap":
            p["b_di_c"] * s(sv, "di_gap"),
        "Output gap: b3_c·yhat_au":
            p["b3_c"] * s(sv, "yhat_au"),
        "PV aux. (pv_c_aux)":
            s(sv, "pv_c_aux"),
        "Shock: eps_c":
            s(ss, "eps_c"),
    }
    recon = sum(contrib_c.values())
    diag_lines.append(f"c:  max|LHS-recon| = {np.nanmax(np.abs(diff_c - recon)):.2e}")
    plot_equation("c",
                  "Consumption PAC (Section 4.5) — historical decomposition",
                  contrib_c, diff_c, "contrib_c.png",
                  ylabel="Δ log c (qpp)")

    # --- Business investment (ib) ------------------------------------------
    ln_ib = s(sv, "ln_ib_level")
    diff_ib = np.diff(ln_ib, prepend=ln_ib[0])
    diff_ib[0] = np.nan
    contrib_ib = {
        "Error correction: b0_ib·(ib_hat₋₁ − ln_ib₋₁)":
            p["b0_ib"] * (lag(s(sv, "ib_hat")) - lag(ln_ib)),
        "AR lag 1: b1_ib·Δlog ib₋₁":
            p["b1_ib"] * lag(diff_ib, 1),
        "AR lag 2: b2_ib·Δlog ib₋₂":
            p["b2_ib"] * lag(diff_ib, 2),
        "PAC expectation":
            s(sv, "pac_expectation_pac_ib"),
        "Accelerator: b3_ib·yhat_au":
            p["b3_ib"] * s(sv, "yhat_au"),
        "User cost: −σ·pv_rKB_aux":
            -p["sigma_ces"] * s(sv, "pv_rKB_aux"),
        "PV aux. (pv_ib_aux)":
            s(sv, "pv_ib_aux"),
        "Shock: eps_ib":
            s(ss, "eps_ib"),
    }
    recon = sum(contrib_ib.values())
    diag_lines.append(f"ib: max|LHS-recon| = {np.nanmax(np.abs(diff_ib - recon)):.2e}")
    plot_equation("ib",
                  "Business investment PAC (Section 4.6) — historical decomposition",
                  contrib_ib, diff_ib, "contrib_ib.png",
                  ylabel="Δ log i_b (qpp)")

    # --- Housing investment (ih) -------------------------------------------
    ln_ih = s(sv, "ln_ih_level")
    diff_ih = np.diff(ln_ih, prepend=ln_ih[0])
    diff_ih[0] = np.nan
    contrib_ih = {
        "Error correction: b0_ih·(ih_hat₋₁ − ln_ih₋₁)":
            p["b0_ih"] * (lag(s(sv, "ih_hat")) - lag(ln_ih)),
        "AR lag 1: b1_ih·Δlog ih₋₁":
            p["b1_ih"] * lag(diff_ih, 1),
        "AR lag 2: b2_ih·Δlog ih₋₂":
            p["b2_ih"] * lag(diff_ih, 2),
        "PAC expectation":
            s(sv, "pac_expectation_pac_ih"),
        "Accelerator: b3_ih·yhat_au":
            p["b3_ih"] * s(sv, "yhat_au"),
        "House price gap: b_ph_ih·ph_gap₋₁":
            p["b_ph_ih"] * lag(s(sv, "ph_gap")),
        "PV aux. (pv_ih_aux)":
            s(sv, "pv_ih_aux"),
        "Shock: eps_ih":
            s(ss, "eps_ih"),
    }
    recon = sum(contrib_ih.values())
    diag_lines.append(f"ih: max|LHS-recon| = {np.nanmax(np.abs(diff_ih - recon)):.2e}")
    plot_equation("ih",
                  "Housing investment PAC (Section 4.7) — historical decomposition",
                  contrib_ih, diff_ih, "contrib_ih.png",
                  ylabel="Δ log i_h (qpp)")

    # --- Employment (n) ----------------------------------------------------
    ln_n = s(sv, "ln_n_level")
    diff_n = np.diff(ln_n, prepend=ln_n[0])
    diff_n[0] = np.nan
    contrib_n = {
        "Error correction: b0_n·(n_hat₋₁ − ln_n₋₁)":
            p["b0_n"] * (lag(s(sv, "n_hat")) - lag(ln_n)),
        "AR lag 1: b1_n·Δlog n₋₁":
            p["b1_n"] * lag(diff_n, 1),
        "AR lag 2: b2_n·Δlog n₋₂":
            p["b2_n"] * lag(diff_n, 2),
        "AR lag 3: b3_n·Δlog n₋₃":
            p["b3_n"] * lag(diff_n, 3),
        "AR lag 4: b4_n·Δlog n₋₄":
            p["b4_n"] * lag(diff_n, 4),
        "PAC expectation":
            s(sv, "pac_expectation_pac_n"),
        "Output gap: b5_n·yhat_au":
            p["b5_n"] * s(sv, "yhat_au"),
        "PV aux. (pv_n_aux)":
            s(sv, "pv_n_aux"),
        "Shock: eps_n":
            s(ss, "eps_n"),
    }
    recon = sum(contrib_n.values())
    diag_lines.append(f"n:  max|LHS-recon| = {np.nanmax(np.abs(diff_n - recon)):.2e}")
    plot_equation("n",
                  "Employment PAC (Section 4.4.4) — historical decomposition",
                  contrib_n, diff_n, "contrib_n.png",
                  ylabel="Δ log n (qpp)")

    # --- Diagnostics file --------------------------------------------------
    with (HERE / "contrib_check.txt").open("w") as f:
        f.write("Dynamic-contributions reconstruction diagnostics\n")
        f.write("Each line: max absolute residual between observed Δy and the "
                "sum of decomposition channels (using smoothed variables).\n\n")
        for ln in diag_lines:
            f.write(ln + "\n")

    print("Saved:")
    for stem in ["piQ", "c", "ib", "ih", "n"]:
        print(f"  contrib_{stem}.png")
    print("  contrib_check.txt")
    print()
    for ln in diag_lines:
        print("  " + ln)


if __name__ == "__main__":
    main()
