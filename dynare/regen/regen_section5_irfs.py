"""Generate FR-BDF Section 5.2 IRF panels for the seven structural shocks.

Reads saved_irfs_hybrid.mat (final calibration, hybrid expectation regime) and
plots 9-variable IRF panels for each shock, scaled to policy-relevant
magnitudes (not 1-s.d.).

The panel variable lists are SHOCK-SPECIFIC: monetary policy / foreign
demand / government spending / commodity price all generate output-gap and
growth-rate responses (the standard nine-variable demand-block panel).
Cost-push, TFP, and term-premium shocks in the FR-BDF / AU-PAC architecture
are absorbed into the LEVEL (target / permanent-income) trajectory rather
than the short-run gap, so for those shocks we plot level variables
instead. This was learned the hard way 2026-05-11 by generating cost-push
panels for `eps_pQ` that showed gap variables at floating-point noise
(~1e-15) because the model architecture decouples gaps from level shocks.

Shocks and target magnitudes:
  eps_i     100bp annualized policy tightening (= 0.25 qpp; σ = 0.1103)
  eps_tp    100bp annualized term premium     (= 0.25 qpp; σ = 0.05)
  eps_q_us  1 pp US output gap shock           (σ = 1.138)
  eps_g     1% of GDP government spending shock(σ = 0.3)
  eps_pcom  10% commodity price shock          (σ = 3.0)
  eps_pQ    1 pp VA price inflation shock      (σ = 0.571)
  eps_tfp_LR 1% LR-level TFP shock              (σ = 0.01, FR-BDF §5.2.7)

Output: irf_eps_<shock>.png for each shock
"""

from pathlib import Path
import numpy as np
from scipy.io import loadmat
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

HERE = Path(__file__).resolve().parent
DYNARE = HERE.parent  # dynare/ workspace where MATLAB writes .mat/.png artefacts
MAT = DYNARE / "saved_irfs_hybrid.mat"

T_PLOT = 100   # bumped from 40 to track convergence past the ~50q
               # capital-channel half-life; harmless if .mat is shorter
               # (series() trims via min(T_PLOT, len(y)) downstream).

# Default panel: output gap + inflation + growth variables. Earlier versions
# plotted ln_Q (log GDP level) here, but ln_Q is non-stationary by construction
# (ln_Q = ln_QN + yhat_au, ln_QN integrates dln_y_star), so it can show a
# quasi-permanent deviation while every other panel — all stationary growth
# rates — mean-reverts. We plot the output gap (yhat_au) instead, which is
# the model's stationary GDP-deviation measure and what FR-BDF §5/6 use.
VARS_GAP = [
    ("yhat_au",  "Output gap (%)"),
    ("pi_au",    "CPI inflation (qpp)"),
    ("piQ",      "VA price infl. (qpp)"),
    ("dln_c",    "Consumption growth"),
    ("dln_ib",   "Business inv. growth"),
    ("dln_ih",   "Housing inv. growth"),
    ("dln_n",    "Employment growth"),
    ("s_gap",    "Exchange rate gap"),
    ("i_10y",    "10Y yield (qpp)"),
]

# Alternative panel: level variables (for shocks that move the
# permanent-income / target trajectory, not the short-run gap).
VARS_LEVEL = [
    ("piQ",       "VA price infl. (qpp)"),
    ("ln_P",      "Price level (% from SS)"),
    ("ln_Q",      "Output level (% from SS)"),
    ("ln_C",      "Consumption level (% from SS)"),
    ("ln_IB",     "Business inv. level (% from SS)"),
    ("ln_IH",     "Housing inv. level (% from SS)"),
    ("ln_N",      "Employment level (% from SS)"),
    ("ln_C_star", "Consumption permanent income"),
    ("i_10y",     "10Y yield (qpp)"),
]

# TFP-shock panel: trace the FR-BDF wp736 §5.2.7 transmission. The shock
# permanently lifts ln_tfp_LR by 1%; ln_tfp converges to the new LR via
# AR(1) smoothing (rho_tfp=0.95); ln_QN and ln_Q migrate to the new BGP
# (≈ +1% with labor-augmenting form, weighted by labor share). The output
# gap yhat_au stays at zero because both ln_Q and ln_QN move together.
VARS_TFP = [
    ("ln_tfp_LR", "Long-run log-TFP (RW with permanent shock)"),
    ("ln_tfp",    "Smoothed log-TFP (AR(1) toward LR)"),
    ("ln_Q",      "Output level (% from SS)"),
    ("ln_QN",     "Potential output (% from SS)"),
    ("ln_N",      "Employment level (% from SS)"),
    ("pi_w",      "Wage inflation (qpp)"),
    ("piQ",       "VA price infl. (qpp)"),
    ("yhat_au",   "Output gap (%) — ≈0 by construction"),
    ("i_10y",     "10Y yield (qpp)"),
]

# Term-premium-specific panel: financial + level variables.
VARS_TP = [
    ("i_10y",     "10Y yield (qpp)"),
    ("ln_C",      "Consumption level (% from SS)"),
    ("ln_IB",     "Business inv. level (% from SS)"),
    ("ln_IH",     "Housing inv. level (% from SS)"),
    ("ln_C_star", "Consumption permanent income"),
    ("ln_IB_star","Business inv. target (% from SS)"),
    ("ln_IH_star","Housing inv. target (% from SS)"),
    ("yhat_au",   "Output gap (%) — gap-zero by construction"),
    ("piQ",       "VA price infl. (qpp)"),
]

# Per-shock panel variant + auxiliary footer caption noting the model
# transmission channel for that shock.
SHOCKS = [
    ("eps_i", 0.1110, 0.25, VARS_GAP,
     "100bp annualized policy tightening",
     "FR-BDF Fig 5.2.1 — Monetary policy shock (eps_i)",
     ""),
    ("eps_tp", 0.05, 0.25, VARS_TP,
     "100bp annualized term-premium shock",
     "FR-BDF Fig 5.2.2 — Term premium shock (eps_tp)",
     "Note: term-premium shocks in the FR-BDF/AU-PAC PAC architecture work "
     "through level (target / permanent-income) variables rather than "
     "short-run output-gap dynamics. Panel uses level variables accordingly."),
    ("eps_q_us", 1.138, 1.0, VARS_GAP,
     "1pp US output-gap shock",
     "FR-BDF Fig 5.2.3 — Foreign demand shock (eps_q_us)",
     ""),
    ("eps_g", 0.3, 1.0, VARS_GAP,
     "1% of GDP government-spending shock",
     "FR-BDF Fig 5.2.4 — Government spending shock (eps_g)",
     ""),
    ("eps_pcom", 3.0, 10.0, VARS_GAP,
     "10% commodity price shock",
     "FR-BDF Fig 5.2.5 — Commodity price shock (eps_pcom)",
     ""),
    ("eps_pQ", 0.571, 1.0, VARS_LEVEL,
     "1pp VA price inflation cost-push shock",
     "FR-BDF Fig 5.2.6 — Cost-push shock (eps_pQ)",
     "Note: cost-push shocks in AU-PAC's architecture enter the VA price PAC "
     "equation directly. The CPI Phillips curve (eq_au_phillips) is driven "
     "by the output gap only — there is no piQ→pi_au passthrough — so the "
     "cost-push transmission shows up in *level* variables (ln_P, ln_Q, ln_C, "
     "ln_IB, ln_N) via permanent-income / target-level adjustments rather "
     "than short-run gap responses. Gap-variable panels for this shock "
     "would show floating-point noise (~1e-15) — this is structurally "
     "correct, not a bug."),
    ("eps_tfp_LR", 0.01, 0.01, VARS_TFP,
     "Permanent +1% level shock to log trend efficiency",
     "FR-BDF Fig 5.2.7 — Labour efficiency shock (eps_tfp_LR)",
     "FR-BDF wp736 §5.2.7 specifies this as a *permanent* +1% level shock "
     "to trend labour efficiency Ē; the resulting IRFs describe transitory "
     "dynamics toward a new BGP. ln_tfp_LR jumps to +1 immediately; ln_tfp "
     "converges over ~50q via AR(1) smoothing at rho_tfp=0.95; ln_Q settles "
     "at a new permanent level (~+0.6% per FR-BDF abstract, weighted by "
     "labour share). yhat_au stays near zero because actual and potential "
     "output rise together (gap by construction). Pre-2026-05-15 spec was "
     "AR(1) on growth-rate dln_tfp with rho=0.99, which integrated 100x "
     "and produced an exploding ln_Q response — see au_pac.mod commentary."),
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


def plot_shock(ir, shock_id, stderr, target, variables, target_label,
               title, footer_note):
    scale = target / stderr
    fig, axes = plt.subplots(3, 3, figsize=(13, 10), constrained_layout=True)
    for ax, (var, vlabel) in zip(axes.flat, variables):
        y = series(ir, var, shock_id) * scale
        T = min(T_PLOT, len(y))
        ax.plot(range(1, T+1), y[:T], color="black", linewidth=1.6)
        ax.axhline(0, color="gray", linewidth=0.5, linestyle=":")
        ax.set_title(vlabel, fontsize=10)
        ax.set_xlabel("Quarters", fontsize=8)
        ax.grid(True, alpha=0.3)
        ax.tick_params(labelsize=8)
        ax.set_xlim(1, T)
    subtitle = (f"Shock: {target_label} "
                f"(scale = {target}/{stderr} = {scale:.3f}); hybrid regime")
    if footer_note:
        subtitle += f"\n{footer_note}"
    fig.suptitle(f"{title}\n{subtitle}", fontsize=11, fontweight="bold")
    out = DYNARE / f"irf_{shock_id}.png"
    fig.savefig(out, dpi=200)
    plt.close(fig)
    return out


def main():
    ir = load_irfs()
    print("=== Section 5.2 IRF panel regeneration ===")
    for shock_id, stderr, target, variables, lbl, title, _ in SHOCKS:
        path = plot_shock(ir, shock_id, stderr, target, variables, lbl,
                          title,
                          [s[6] for s in SHOCKS if s[0] == shock_id][0])
        print(f"  Saved: {path.name}  (target {lbl})")
    print("=== Done ===")


if __name__ == "__main__":
    main()
