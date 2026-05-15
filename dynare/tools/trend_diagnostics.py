"""Trend diagnostics on AU-PAC smoothed shocks.

For each estimated shock series ε_t from the Phase G MCMC smoother, test
whether the residual contains evidence of a missing trending channel in
the structural equation. The diagnostic battery includes:

  1. Linear trend regression:   ε_t = α + β · t + u_t
     t-stat on β > 2 ⇒ residual has a deterministic trend, suggesting
     the structural equation's target X* is misspecified.

  2. Quadratic trend regression: ε_t = α + β₁ · t + β₂ · t² + u_t
     Catches U-shaped or accelerating residuals (e.g. mining-boom
     hump-shaped patterns).

  3. Pre/post-2008 mean-shift test: ε_t = α + δ · D_post2008 + u_t
     Catches structural-break-like patterns around the GFC.

  4. Augmented Dickey–Fuller test for unit root in the residual series.
     Non-stationary residual = strong evidence of missing trend.

  5. Cumulative sum (CUSUM) chart: visual check for drift.

  6. Numerical-noise filter: smoothed residuals with std < 1e-6 are
     flagged as ARTIFACTS because they sit at floating-point precision
     and cannot represent real economic misspecification. The trend
     tests can still pick up systematic structure in such residuals,
     but the structure is numerical drift, not a fit problem.

Output:
  trend_diagnostics_log.txt   — table of t-stats per shock
  trend_diagnostics.png       — 12-panel figure of shock series + trends
"""

from pathlib import Path
import numpy as np
from scipy.io import loadmat
from scipy import stats
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from datetime import date

HERE = Path(__file__).resolve().parent
DYNARE = HERE.parent  # dynare/ workspace where MATLAB writes .mat artefacts
MAT = DYNARE / "bayesian_mcmc_results.mat"

# Smoother sample: 122 quarters from 1994Q3 to 2024Q4
START = date(1994, 7, 1)
T = 122

# Q4-2007 is obs 54 (1994Q3 = obs 1 → 2007Q4 = obs 54)
GFC_BREAK_IDX = 54


def quarter_dates(start, T):
    out = []
    y, m = start.year, start.month
    for _ in range(T):
        out.append(date(y, m, 1))
        m += 3
        if m > 12:
            m -= 12; y += 1
    return out


def load_shocks():
    d = loadmat(MAT, squeeze_me=True, struct_as_record=False)
    ss = d["oo_"].SmoothedShocks
    shocks = {}
    for name in ss._fieldnames:
        arr = np.atleast_1d(np.array(getattr(ss, name))).ravel()
        if len(arr) >= T:
            shocks[name] = arr[:T]
    return shocks


def linear_trend_test(eps):
    """Regress eps_t = a + b*t + u; return (b, se_b, t_stat, p_val)."""
    t = np.arange(1, len(eps) + 1).astype(float)
    valid = np.isfinite(eps)
    eps_v, t_v = eps[valid], t[valid]
    n = len(eps_v)
    if n < 10:
        return np.nan, np.nan, np.nan, np.nan
    X = np.column_stack([np.ones(n), t_v])
    beta, *_ = np.linalg.lstsq(X, eps_v, rcond=None)
    resid = eps_v - X @ beta
    sigma2 = (resid @ resid) / (n - 2)
    XtX_inv = np.linalg.inv(X.T @ X)
    se_b = np.sqrt(sigma2 * XtX_inv[1, 1])
    t_stat = beta[1] / se_b
    p_val = 2 * (1 - stats.t.cdf(abs(t_stat), df=n - 2))
    return float(beta[1]), float(se_b), float(t_stat), float(p_val)


def quadratic_trend_test(eps):
    """Regress eps_t = a + b₁*t + b₂*t²; return F-stat and t-stats."""
    t = np.arange(1, len(eps) + 1).astype(float)
    valid = np.isfinite(eps)
    eps_v, t_v = eps[valid], t[valid]
    n = len(eps_v)
    if n < 10:
        return np.nan, np.nan, np.nan
    t_v_c = t_v - np.mean(t_v)
    X = np.column_stack([np.ones(n), t_v_c, t_v_c ** 2])
    beta, *_ = np.linalg.lstsq(X, eps_v, rcond=None)
    resid = eps_v - X @ beta
    sigma2 = (resid @ resid) / (n - 3)
    XtX_inv = np.linalg.inv(X.T @ X)
    se = np.sqrt(np.diag(sigma2 * XtX_inv))
    t1, t2 = beta[1] / se[1], beta[2] / se[2]
    # Joint F-test for β₁ = β₂ = 0
    X_r = np.ones((n, 1))
    rss_u = resid @ resid
    rss_r = ((eps_v - eps_v.mean()) ** 2).sum()
    F = ((rss_r - rss_u) / 2) / (rss_u / (n - 3))
    return float(t1), float(t2), float(F)


def pre_post_2008_test(eps, break_idx=GFC_BREAK_IDX):
    pre = eps[:break_idx]
    post = eps[break_idx:]
    pre_v = pre[np.isfinite(pre)]
    post_v = post[np.isfinite(post)]
    if len(pre_v) < 5 or len(post_v) < 5:
        return np.nan, np.nan, np.nan
    t_stat, p_val = stats.ttest_ind(pre_v, post_v, equal_var=False)
    diff = np.mean(post_v) - np.mean(pre_v)
    return float(diff), float(t_stat), float(p_val)


def adf_test(eps, max_lag=4):
    """ADF unit-root test via OLS regression of Δε on ε(-1) and lags."""
    eps_v = eps[np.isfinite(eps)]
    n = len(eps_v)
    if n < 20:
        return np.nan, np.nan
    deps = np.diff(eps_v)
    lev = eps_v[:-1]
    # Build lagged-Δε matrix
    nrow = n - 1 - max_lag
    if nrow < 10:
        return np.nan, np.nan
    y = deps[max_lag:]
    X_cols = [np.ones(nrow), lev[max_lag:]]
    for k in range(1, max_lag + 1):
        X_cols.append(deps[max_lag - k : -k])
    X = np.column_stack(X_cols)
    beta, *_ = np.linalg.lstsq(X, y, rcond=None)
    resid = y - X @ beta
    sigma2 = (resid @ resid) / (nrow - X.shape[1])
    se = np.sqrt(np.diag(sigma2 * np.linalg.inv(X.T @ X)))
    adf_stat = beta[1] / se[1]
    # 5% critical values (Dickey-Fuller, constant only)
    # Approximate: -2.86 at n=100
    crit_5 = -2.89
    return float(adf_stat), float(crit_5)


def cusum(eps):
    eps_v = eps[np.isfinite(eps)]
    return np.cumsum(eps_v - np.mean(eps_v))


def main():
    shocks = load_shocks()
    dates_ = quarter_dates(START, T)

    # Focus on the structural shocks that map to behavioural equations
    target = [
        ("eps_q",   "Output gap (IS curve)"),
        ("eps_pi",  "CPI Phillips curve"),
        ("eps_i",   "Taylor rule"),
        ("eps_w",   "Wage Phillips curve"),
        ("eps_pQ",  "VA price PAC"),
        ("eps_c",   "Consumption PAC"),
        ("eps_ib",  "Business inv. PAC"),
        ("eps_ih",  "Housing inv. PAC"),
        ("eps_n",   "Employment PAC"),
        ("eps_q_us","US output gap"),
        ("eps_pi_us","US Phillips curve"),
        ("eps_10y", "10Y yield"),
    ]

    log_lines = []
    log_lines.append("AU-PAC trend diagnostics on smoothed shocks")
    log_lines.append("=" * 70)
    log_lines.append("")
    log_lines.append(f"{'shock':<10} {'eq':<25} {'res_std':>9} {'lin β':>8} {'t_lin':>7} "
                     f"{'F_quad':>7} {'Δ post-08':>10} {'t_break':>7} "
                     f"{'ADF':>6}")
    log_lines.append("-" * 95)

    results = []
    NOISE_STD = 1e-6  # below this, residual is floating-point drift not economic
    for shock_id, eq_label in target:
        if shock_id not in shocks:
            log_lines.append(f"{shock_id:<10} {eq_label:<25} (not in smoother output)")
            continue
        eps = shocks[shock_id]
        res_std = float(np.nanstd(eps))
        b, se_b, t_lin, p_lin = linear_trend_test(eps)
        t1, t2, F = quadratic_trend_test(eps)
        diff, t_break, p_break = pre_post_2008_test(eps)
        adf_stat, adf_crit = adf_test(eps)
        is_artifact = res_std < NOISE_STD
        results.append((shock_id, eq_label, b, t_lin, F, diff, t_break, adf_stat,
                        res_std, is_artifact))
        artifact_tag = "  ARTIFACT" if is_artifact else ""
        log_lines.append(
            f"{shock_id:<10} {eq_label:<25} {res_std:>9.2e} {b:>+8.4f} {t_lin:>+7.2f} "
            f"{F:>7.2f} {diff:>+10.4f} {t_break:>+7.2f} "
            f"{adf_stat:>+6.2f}{artifact_tag}"
        )

    log_lines.append("")
    log_lines.append("Interpretation:")
    log_lines.append("  |t_lin| > 2.0   ⇒ residual has linear trend; target equation")
    log_lines.append("                    likely missing a trending channel.")
    log_lines.append("  F_quad > 3.0    ⇒ residual has quadratic structure (hump or U).")
    log_lines.append("  |t_break| > 2.0 ⇒ pre/post-2008 mean shift; structural break")
    log_lines.append("                    around the GFC.")
    log_lines.append("  ADF > -2.89     ⇒ cannot reject unit root in residual; strong")
    log_lines.append("                    evidence of missing trend (residual not stationary).")
    log_lines.append(f"  res_std < {NOISE_STD:.0e}  ⇒ residual is at floating-point precision;")
    log_lines.append("                    trend tests detect structure in numerical noise,")
    log_lines.append("                    which is not an economic fit problem.")
    log_lines.append("")

    # Rank by abs(t_lin), with ARTIFACT shocks demoted to the end
    real_results = [r for r in results if not np.isnan(r[3]) and not r[9]]
    artifact_results = [r for r in results if not np.isnan(r[3]) and r[9]]
    real_results.sort(key=lambda r: abs(r[3]), reverse=True)
    artifact_results.sort(key=lambda r: abs(r[3]), reverse=True)

    log_lines.append("Ranked by |t_lin| (real residuals first; artifacts at end):")
    log_lines.append("-" * 70)
    for r in real_results + artifact_results:
        sid, eq, b, tlin, F, diff, tbreak, adf, rstd, is_artifact = r
        flag = ""
        if not is_artifact:
            if abs(tlin) > 2.0: flag += " LINEAR"
            if abs(tbreak) > 2.0: flag += " BREAK"
            if F > 3.0: flag += " QUAD"
            if adf > -2.89: flag += " UR"
        else:
            flag = " ARTIFACT (residual at FP precision)"
        log_lines.append(f"  {sid:<10} {eq:<25} std={rstd:.1e} t_lin={tlin:+.2f} {flag}")

    (DYNARE / "trend_diagnostics_log.txt").write_text("\n".join(log_lines))
    print("\n".join(log_lines))

    # Plot
    fig, axes = plt.subplots(4, 3, figsize=(15, 12), constrained_layout=True)
    for ax, (shock_id, eq_label) in zip(axes.flat, target):
        if shock_id not in shocks:
            ax.set_visible(False)
            continue
        eps = shocks[shock_id]
        ax.plot(dates_, eps, color="black", linewidth=0.9)
        # Add linear trend fit
        t = np.arange(1, len(eps) + 1).astype(float)
        valid = np.isfinite(eps)
        if valid.sum() > 10:
            b, se_b, t_lin, _ = linear_trend_test(eps)
            a = np.mean(eps[valid]) - b * np.mean(t[valid])
            trend = a + b * t
            ax.plot(dates_, trend, color="red", linewidth=1.2,
                    linestyle="--", label=f"trend t={t_lin:+.2f}")
        # GFC marker
        ax.axvline(date(2008, 1, 1), color="gray", linewidth=0.5,
                   linestyle=":", alpha=0.7)
        ax.axhline(0, color="black", linewidth=0.4)
        ax.set_title(f"{shock_id} — {eq_label}", fontsize=9)
        ax.legend(loc="best", fontsize=8)
        ax.xaxis.set_major_locator(mdates.YearLocator(5))
        ax.xaxis.set_major_formatter(mdates.DateFormatter("%Y"))
        ax.tick_params(labelsize=7)
        ax.grid(True, alpha=0.3)
    fig.suptitle("AU-PAC smoothed shocks: linear-trend diagnostics",
                 fontsize=13, fontweight="bold")
    fig.savefig(DYNARE / "trend_diagnostics.png", dpi=200)
    plt.close(fig)
    print("\nSaved: trend_diagnostics.png")


if __name__ == "__main__":
    main()
