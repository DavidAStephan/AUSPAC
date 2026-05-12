"""Diagnostic OLS on smoothed shocks vs candidate channels.

Goes deeper than the initial single-regressor test in build_trend_channels.py.
For each flagged residual, this script runs:

  1. Single-regressor OLS on each candidate channel
  2. Joint OLS on all candidates plus a linear trend t and a post-2008 dummy
  3. Reports adjusted R² so we can see which channels actually explain
     the trend signal we previously detected.

The aim is to verify whether the channels we want to add (TOT, population,
real housing prices) actually absorb the trend / break / quadratic structure
in the smoothed residuals — or whether the trend signal is driven by
something else (e.g. mining-boom hump, COVID, regime shifts).
"""

from pathlib import Path
import numpy as np
from scipy.io import loadmat

HERE = Path(__file__).resolve().parent
T = 122
GFC_BREAK = 54  # obs 54 = 2007Q4


def load_data():
    ss = loadmat(HERE / "bayesian_mcmc_results.mat",
                 squeeze_me=True, struct_as_record=False)["oo_"].SmoothedShocks
    shocks = {nm: np.array(getattr(ss, nm)).ravel()[:T] for nm in ss._fieldnames}
    ch = loadmat(HERE / "channel_data.mat", squeeze_me=True)
    return shocks, ch


def ols(y, X, names):
    valid = np.isfinite(y) & np.all(np.isfinite(X), axis=1)
    yv, Xv = y[valid], X[valid]
    n, k = Xv.shape
    Xv = np.column_stack([np.ones(n), Xv])
    beta, *_ = np.linalg.lstsq(Xv, yv, rcond=None)
    resid = yv - Xv @ beta
    rss = resid @ resid
    tss = ((yv - yv.mean()) ** 2).sum()
    r2 = 1 - rss / tss
    adj_r2 = 1 - (1 - r2) * (n - 1) / (n - k - 1)
    sigma2 = rss / (n - k - 1)
    se = np.sqrt(np.diag(sigma2 * np.linalg.inv(Xv.T @ Xv)))
    t_stats = beta / se
    return beta, t_stats, adj_r2, n


def diagnose(label, eps, channels):
    """Print OLS diagnostics for one shock."""
    print(f"\n=== {label} (n={np.isfinite(eps).sum()}, std={np.nanstd(eps):.4f}) ===")
    t_idx = np.arange(1, T + 1, dtype=float)
    d_gfc = (t_idx >= GFC_BREAK).astype(float)

    # 1. Trend + break baseline
    X = np.column_stack([t_idx, d_gfc])
    b, ts, r2, n = ols(eps, X, ["t", "GFC"])
    print(f"  baseline (t, GFC):              "
          f"β_t={b[1]:+.5f} (t={ts[1]:+.2f})  β_gfc={b[2]:+.4f} (t={ts[2]:+.2f})  "
          f"adjR²={r2:+.3f}")

    # 2. Each channel alone
    for nm in ["dln_tot_obs", "dln_pop_obs", "dln_ph_obs"]:
        x = np.array(channels[nm]).ravel()
        b, ts, r2, n = ols(eps, x.reshape(-1, 1), [nm])
        print(f"  {nm:>14}:                "
              f"β={b[1]:+.4f} (t={ts[1]:+.2f})  adjR²={r2:+.3f}")

    # 3. All channels + trend + GFC dummy
    X = np.column_stack([
        np.array(channels["dln_tot_obs"]).ravel(),
        np.array(channels["dln_pop_obs"]).ravel(),
        np.array(channels["dln_ph_obs"]).ravel(),
        t_idx, d_gfc,
    ])
    b, ts, r2, n = ols(eps, X, ["tot", "pop", "ph", "t", "GFC"])
    print(f"  full (tot+pop+ph+t+GFC):        "
          f"β_tot={b[1]:+.4f} ({ts[1]:+.2f})  "
          f"β_pop={b[2]:+.4f} ({ts[2]:+.2f})  "
          f"β_ph={b[3]:+.4f} ({ts[3]:+.2f})")
    print(f"                                  "
          f"β_t={b[4]:+.5f} ({ts[4]:+.2f})  "
          f"β_gfc={b[5]:+.4f} ({ts[5]:+.2f})  "
          f"adjR²={r2:+.3f}")


def main():
    shocks, ch = load_data()
    diagnose("eps_pQ  (VA price PAC, t_lin=+6.40)", shocks["eps_pQ"], ch)
    diagnose("eps_ih  (housing inv PAC, t_lin=+3.05)", shocks["eps_ih"], ch)
    diagnose("eps_q   (output gap IS, t_lin=+2.27)",  shocks["eps_q"],  ch)
    diagnose("eps_ib  (business inv PAC, t_lin=-2.03)", shocks["eps_ib"], ch)
    diagnose("eps_c   (consumption PAC, t_lin=-1.95)", shocks["eps_c"], ch)


if __name__ == "__main__":
    main()
