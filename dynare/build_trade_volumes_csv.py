"""Extract ABS 5206 SA imports/exports volumes to a CSV consumed by
prepare_bayesian_data.m.

Series IDs (chain-volume measures, seasonally adjusted, $m):
  A2304115J  Imports of goods and services
  A2304114F  Exports of goods and services

These are the same SA chain-vol series used in Phase D's OLS calibration
of b1_m and b2_m, so the new long-run trade ECM (FR-BDF Section 4.7
proper specification) reads the same observable for dln_m and dln_x.

Output: dynare/trade_volumes_sa.csv with columns
        date, imports_sa, exports_sa
"""

from pathlib import Path
import pandas as pd

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent


def load_5206(series_id):
    df = pd.read_excel(ROOT / "data" / "abs_rba" / "abs_5206_vol.xlsx",
                       sheet_name="Data1", header=None)
    ids = df.iloc[9].tolist()
    if series_id not in ids:
        raise ValueError(f"Series {series_id} not in 5206")
    col = ids.index(series_id)
    dates = df.iloc[10:, 0].tolist()
    vals = df.iloc[10:, col].tolist()
    rows = [(d, v) for d, v in zip(dates, vals)
            if isinstance(d, pd.Timestamp) or hasattr(d, "year")]
    return pd.DataFrame(rows, columns=["date", series_id]).set_index("date")[series_id]


def main():
    M = load_5206("A2304115J").rename("imports_sa")
    X = load_5206("A2304114F").rename("exports_sa")
    df = pd.concat([M, X], axis=1).dropna()
    df.index.name = "date"
    df = df.reset_index()
    df["date"] = df["date"].dt.strftime("%Y-%m-%d")
    out = HERE / "trade_volumes_sa.csv"
    df.to_csv(out, index=False)
    print(f"Saved {len(df)} rows ({df['date'].iloc[0]} to {df['date'].iloc[-1]}) -> {out}")


if __name__ == "__main__":
    main()
