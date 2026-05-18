"""Does the AU import equation need a linear trend?

The current model has

    dln_m = b0_m * m_gap(-1) + b1_m * dln_m(-1) + b2_m * iad
            + b3_m * s_gap + eps_m

with no deterministic trend. In MARTIN and other AU empirical macro
models the import equation typically needs a positive linear trend to
fit the secular rise in import penetration (imports/GDP).

Our smoothed-residual diagnostic missed this because dln_m is not in
varobs — the Kalman filter does not see import data, so the smoother
can set eps_m to anything that satisfies the equation, hiding any
data-side trend.

This script runs the trend test on the OBSERVED imports series:
  1. Load au_imports, compute dln_m_obs.
  2. Build the model RHS drivers (IAD from observed component growth,
     a simple proxy for s_gap and m_gap).
  3. Regress dln_m_obs on (RHS) and (RHS + t).
  4. Compare R², coefficients, t-stat on the trend.
"""

from pathlib import Path
import numpy as np
import pandas as pd
from scipy.io import loadmat

HERE = Path(__file__).resolve().parent
DYNARE = HERE.parent           # dynare/
ROOT = HERE.parent.parent      # repo root


def load_abs_5206_series(series_id):
    df = pd.read_excel(ROOT / "data" / "abs_rba" / "abs_5206_vol.xlsx",
                       sheet_name="Data1", header=None)
    ids = df.iloc[9].tolist()
    col = ids.index(series_id)
    dates_raw = df.iloc[10:, 0].tolist()
    vals = df.iloc[10:, col].tolist()
    rows = [(d, v) for d, v in zip(dates_raw, vals)
            if isinstance(d, pd.Timestamp) or hasattr(d, "year")]
    s = pd.DataFrame(rows, columns=["date", series_id]).set_index("date")
    return s[series_id].astype(float)


def main():
    # ABS 5206 SA volumes (chain-vol $m, reference 2021–22)
    M = load_abs_5206_series("A2304115J")  # Imports of goods and services (SA)
    X = load_abs_5206_series("A2304114F")  # Exports of goods and services (SA)
    C = load_abs_5206_series("A2304207T")  # Households final consumption (SA)
    IB = load_abs_5206_series("A2716219R") if False else None

    # Use extended_dataset for the remaining components (IB, IH)
    df_ext = pd.read_csv(ROOT / "data" / "extended_dataset.csv")
    df_ext["date"] = pd.to_datetime(df_ext["date"])
    df_ext = df_ext.set_index("date")

    df = pd.DataFrame(index=M.index)
    df["au_imports"] = M
    df["au_exports"] = X
    df["au_consumption"] = C
    # Align IB and IH from extended_dataset
    for col in ("au_gfcf_nondwelling", "au_gfcf_dwelling"):
        df[col] = df_ext[col].reindex(df.index)

    # Compute log-growth (qoq %) for each demand component
    for col in ("au_consumption", "au_gfcf_nondwelling", "au_gfcf_dwelling",
                "au_exports", "au_imports"):
        df[f"dln_{col}"] = np.log(df[col].astype(float)).diff() * 100

    # IAD weights (from model: w_iad_c=0.12, w_iad_ib=0.25, w_iad_ih=0.15, ...)
    w_c, w_ib, w_ih = 0.12, 0.25, 0.15
    w_x = 0.30  # exports re-export channel
    w_g = 0.06  # government (not in dataset — set small constant)

    # Build IAD without government (set g-term to 0 as approximation)
    df["iad"] = (
        w_c * df["dln_au_consumption"].fillna(0)
        + w_ib * df["dln_au_gfcf_nondwelling"].fillna(0)
        + w_ih * df["dln_au_gfcf_dwelling"].fillna(0)
        + w_x * df["dln_au_exports"].fillna(0)
    )

    df["dln_m"] = df["dln_au_imports"]
    df["dln_m_lag"] = df["dln_m"].shift(1)

    # m_gap proxy: cumulated deviation of dln_m from its mean
    df["m_gap"] = (df["dln_m"].fillna(0) - df["dln_m"].mean()).cumsum().shift(1)

    # Sample
    df = df.dropna(subset=["dln_m", "dln_m_lag", "iad", "m_gap"])
    df["t"] = np.arange(len(df), dtype=float)
    df["t"] -= df["t"].mean()

    y = df["dln_m"].values
    n = len(y)

    def ols(name, cols):
        X = np.column_stack([np.ones(n)] + [df[c].values for c in cols])
        beta, *_ = np.linalg.lstsq(X, y, rcond=None)
        r = y - X @ beta
        rss = r @ r
        tss = ((y - y.mean()) ** 2).sum()
        r2 = 1 - rss / tss
        adj_r2 = 1 - (1 - r2) * (n - 1) / (n - X.shape[1])
        sigma2 = rss / (n - X.shape[1])
        se = np.sqrt(np.diag(sigma2 * np.linalg.inv(X.T @ X)))
        ts = beta / se
        print(f"\n[{name}]  n={n}, R²={r2:.3f}, adjR²={adj_r2:.3f}")
        labels = ["const"] + cols
        for lbl, b, t in zip(labels, beta, ts):
            print(f"  {lbl:<10} β = {b:+.4f}  t = {t:+.2f}")
        return beta, ts, r2

    print("=" * 70)
    print("Does AU imports equation need a linear trend?")
    print(f"  Sample: {df.index[0].date()} to {df.index[-1].date()} (n={n})")
    print(f"  Mean qoq import growth: {y.mean():+.3f}%")
    print(f"  Mean qoq GDP growth (proxy via IAD): {df['iad'].mean():+.3f}%")
    print("=" * 70)

    ols("baseline (no trend)", ["dln_m_lag", "iad", "m_gap"])
    ols("with linear trend  ", ["dln_m_lag", "iad", "m_gap", "t"])

    # Also test: imports/GDP ratio trend
    print("\n" + "=" * 70)
    print("Direct test: log(imports / consumption) trend")
    df["lr_m"] = np.log(df["au_imports"] / df["au_consumption"])
    lr = df["lr_m"].dropna()
    tt = np.arange(len(lr), dtype=float)
    X = np.column_stack([np.ones(len(lr)), tt])
    b, *_ = np.linalg.lstsq(X, lr.values, rcond=None)
    r = lr.values - X @ b
    se = np.sqrt(((r @ r) / (len(lr) - 2)) * np.linalg.inv(X.T @ X)[1, 1])
    print(f"  β_t (qoq drift in log(M/C)) = {b[1]:+.5f}  t = {b[1] / se:+.2f}")
    print(f"  ⇒ annualised drift = {b[1] * 4 * 100:+.2f} bp/yr")


if __name__ == "__main__":
    main()
