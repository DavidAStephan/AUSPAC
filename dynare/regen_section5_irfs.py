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
  eps_tfp   1% TFP shock                       (σ = 0.2)

Output: irf_eps_<shock>.png for each shock
"""

from pathlib import Path
import numpy as np
from scipy.io import loadmat
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

HERE = Path(__file__).resolve().parent
MAT = HERE / "saved_irfs_hybrid.mat"

T_PLOT = 40

# Default panel: GDP level + inflation + growth variables (used for shocks
# that generate output-gap responses; follows FR-BDF convention of plotting
# real GDP level rather than the output gap).
VARS_GAP = [
    ("ln_Q",     "Real GDP (% from SS)"),
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

# TFP-shock panel: only variables that actually move under a TFP shock
# (the gap model has TFP raise both ln_Q and ln_QN equally, so most
# variables stay at floating-point-noise level).
VARS_TFP = [
    ("ln_Q",   "Output level (% from SS)"),
    ("ln_QN",  "Potential output (% from SS)"),
    ("ln_N",   "Employment level (% from SS)"),
    ("ln_N_star", "Employment target (% from SS)"),
    ("pi_w",   "Wage inflation (qpp)"),
    ("piQ",    "VA price infl. (qpp) — no transmission, ≈0"),
    ("yhat_au","Output gap (%) — gap by construction ≈0"),
    ("dln_n",  "Employment growth (qpp) — gap ≈0"),
    ("i_10y",  "10Y yield (qpp) — no transmission, ≈0"),
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
    ("eps_i", 0.1103, 0.25, VARS_GAP,
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
    ("eps_tfp", 0.2, 0.2, VARS_TFP,
     "1 s.d. TFP shock (σ=0.2)",
     "FR-BDF Fig 5.2.7 — TFP / labour efficiency shock (eps_tfp)",
     "Note: TFP shocks raise both actual output (ln_Q) and potential output "
     "(ln_QN) by the same amount in the AU-PAC gap model — so the output "
     "gap yhat_au = ln_Q − ln_QN stays at zero by construction. With "
     "rho_tfp = 0.99 (near unit root) the level response is near-permanent "
     "and grows linearly over the IRF window; we therefore plot at 1 s.d. "
     "(scale = 1) rather than the 1% normalisation used for other shocks. "
     "The wage Phillips curve picks up TFP via the productivity term "
     "(1-lambda_w)·Δln(Prod), which is the only structural channel from "
     "supply-side TFP into inflation/wage dynamics in this model."),
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
    out = HERE / f"irf_{shock_id}.png"
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
