"""Splice long-history Australian house-price series (1959Q3+) backward
onto the ABS 6416 RPPI Weighted Average (2003Q3+).

Inputs
------
data/abs_rba/abs_6416_rppi.csv      — official ABS 6416, 74 obs from 2003Q3
data/house_price_history_long.csv    — long index, 235 obs from 1959Q3 to 2018Q2

Method
------
Use ABS RPPI levels at 2003Q3+ unchanged (the official series).
Pre-2003Q3, walk backward using the quarter-over-quarter growth rates of
`ph_long`. This preserves ABS RPPI levels post-overlap and uses `ph_long`
only as a growth-rate scaffold for the historical tail.

Output
------
data/house_price_spliced.csv         — date, ph_spliced (1959Q3 .. 2021Q4)
data/house_price_spliced_diag.png    — visual diagnostic (overlap quality)
"""

from pathlib import Path
import csv
from datetime import date

import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.dates as mdates

ROOT = Path(__file__).resolve().parents[2]   # repo root (was parents[1] when this lived in dynare/)
DATA = ROOT / "data"

LONG_CSV = DATA / "house_price_history_long.csv"
ABS_CSV  = DATA / "abs_rba" / "abs_6416_rppi.csv"
OUT_CSV  = DATA / "house_price_spliced.csv"
OUT_PNG  = DATA / "house_price_spliced_diag.png"


def _parse_long_date(s):
    """Parse 'm/d/yyyy' or 'mm/dd/yyyy'. The 'day' field in the long CSV
    is always 1 — what matters is the month, which encodes the quarter."""
    parts = s.strip().split("/")
    m, _, y = int(parts[0]), int(parts[1]), int(parts[2])
    # Month -> quarter-end date
    # 3 -> Mar (Q1 end), 6 -> Jun (Q2 end), 9 -> Sep (Q3 end), 12 -> Dec (Q4 end)
    return date(y, m, 1)


def _parse_abs_date(s):
    """ABS dates: 'd/m/yyyy' (always day=1)."""
    parts = s.strip().split("/")
    d, m, y = int(parts[0]), int(parts[1]), int(parts[2])
    return date(y, m, d)


def load_long():
    out = []
    with open(LONG_CSV) as f:
        rdr = csv.reader(f)
        next(rdr)  # header
        for row in rdr:
            if not row[0].strip():
                continue
            d = _parse_long_date(row[0])
            v = float(row[1])
            out.append((d, v))
    out.sort()
    return out


def load_abs():
    """Return (date, weighted_avg_index) pairs from ABS 6416 col 10."""
    out = []
    with open(ABS_CSV) as f:
        rdr = csv.reader(f)
        rows = list(rdr)
    # First 10 rows are metadata. Data starts at row 10 (0-indexed).
    for row in rows[10:]:
        if not row or not row[0]:
            continue
        try:
            d = _parse_abs_date(row[0])
        except Exception:
            continue
        # Column 9 (0-indexed) = weighted average of 8 cities
        try:
            v = float(row[9])
        except (ValueError, IndexError):
            continue
        out.append((d, v))
    return out


def to_dict(pairs):
    return {d: v for d, v in pairs}


def quarter_iter(start, end):
    """Yield quarter-end dates from start to end inclusive."""
    months = {3, 6, 9, 12}
    y, m = start.year, start.month
    while date(y, m, 1) <= end:
        if m in months:
            yield date(y, m, 1)
        m += 1
        if m > 12:
            m = 1
            y += 1


def main():
    long_pairs = load_long()
    abs_pairs = load_abs()
    long_d = to_dict(long_pairs)
    abs_d  = to_dict(abs_pairs)

    print(f"  ph_long:     {len(long_pairs):3d} obs, "
          f"{long_pairs[0][0]} → {long_pairs[-1][0]}")
    print(f"  ABS 6416:    {len(abs_pairs):3d} obs, "
          f"{abs_pairs[0][0]} → {abs_pairs[-1][0]}")

    abs_start = abs_pairs[0][0]
    last_obs = max(abs_pairs[-1][0], long_pairs[-1][0])
    first_obs = long_pairs[0][0]
    print(f"  spliced:     {first_obs} → {last_obs}")

    # --- Overlap diagnostic ---
    overlap_dates = sorted(set(long_d.keys()) & set(abs_d.keys()))
    print(f"\n  Overlap: {len(overlap_dates)} quarters "
          f"({overlap_dates[0]} → {overlap_dates[-1]})")
    if len(overlap_dates) > 1:
        g_long = []
        g_abs = []
        for prev, curr in zip(overlap_dates[:-1], overlap_dates[1:]):
            if (curr - prev).days > 95:
                continue
            g_long.append(np.log(long_d[curr] / long_d[prev]) * 100)
            g_abs.append(np.log(abs_d[curr] / abs_d[prev]) * 100)
        g_long = np.array(g_long)
        g_abs = np.array(g_abs)
        corr = float(np.corrcoef(g_long, g_abs)[0, 1])
        rms_diff = float(np.sqrt(np.mean((g_long - g_abs) ** 2)))
        mean_diff = float(np.mean(g_long - g_abs))
        print(f"    qoq-growth corr(long, ABS) = {corr:.3f}")
        print(f"    rms diff (qoq, log %)     = {rms_diff:.3f}")
        print(f"    mean diff (long - ABS)    = {mean_diff:+.3f} pp/qtr")

    # --- Build the spliced series ---
    spliced = {}

    # 1. ABS RPPI from its start onward — unchanged
    for d, v in abs_pairs:
        spliced[d] = v

    # 2. Back-cast pre-ABS-start using ph_long growth rates
    sorted_long = sorted(long_d.keys())
    pre_dates = [d for d in sorted_long if d < abs_start]
    # Need an anchor inside the long series at or near abs_start
    if abs_start not in long_d:
        raise SystemExit(f"abs_start {abs_start} not in long series — "
                         f"can't anchor splice")
    # Walk backwards
    for d in reversed(pre_dates):
        # Find next quarter (= existing dated value in spliced or long)
        # We rebuild the chain: spliced[d] = spliced[d_next] * (long[d] / long[d_next])
        idx = sorted_long.index(d)
        d_next = sorted_long[idx + 1]
        if d_next not in spliced:
            # Should not happen because we walk backwards from anchor
            raise RuntimeError(f"d_next={d_next} not yet spliced")
        ratio = long_d[d] / long_d[d_next]
        spliced[d] = spliced[d_next] * ratio

    # --- Write CSV ---
    out_dates = sorted(spliced.keys())
    with open(OUT_CSV, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["date", "ph_spliced"])
        for d in out_dates:
            w.writerow([d.isoformat(), f"{spliced[d]:.4f}"])

    print(f"\n  Saved: {OUT_CSV.relative_to(ROOT)}  "
          f"({len(out_dates)} quarters: {out_dates[0]} → {out_dates[-1]})")

    # --- Diagnostic plot ---
    fig, axes = plt.subplots(2, 1, figsize=(11, 8), constrained_layout=True)

    ax = axes[0]
    abs_d_sorted = sorted(abs_d.keys())
    long_d_sorted = sorted(long_d.keys())
    spliced_d_sorted = out_dates
    ax.plot(long_d_sorted, [long_d[d] for d in long_d_sorted],
            label="ph_long (rescaled below)", linestyle="--",
            color="gray", linewidth=1)
    # Rescale ph_long to match ABS levels for visualisation
    scale = abs_d[abs_start] / long_d[abs_start]
    ax.plot(long_d_sorted, [long_d[d] * scale for d in long_d_sorted],
            label=f"ph_long × {scale:.2f}", color="tab:orange", linewidth=1.4)
    ax.plot(abs_d_sorted, [abs_d[d] for d in abs_d_sorted],
            label="ABS 6416 weighted avg", color="tab:blue", linewidth=1.8)
    ax.plot(spliced_d_sorted,
            [spliced[d] for d in spliced_d_sorted],
            label="spliced (1959Q3+)", color="black",
            linestyle=":", linewidth=1.2)
    ax.set_yscale("log")
    ax.set_title("Levels (log scale) — splice preserves ABS levels post-2003Q3",
                 fontsize=11, fontweight="bold")
    ax.set_ylabel("Index")
    ax.legend(loc="best", fontsize=9)
    ax.grid(True, alpha=0.3)
    ax.xaxis.set_major_locator(mdates.YearLocator(5))

    ax = axes[1]
    # Q-over-Q growth rates during overlap
    if overlap_dates:
        g_long_arr = []
        g_abs_arr = []
        dates_for_growth = []
        for prev, curr in zip(overlap_dates[:-1], overlap_dates[1:]):
            if (curr - prev).days > 95:
                continue
            g_long_arr.append(np.log(long_d[curr] / long_d[prev]) * 100)
            g_abs_arr.append(np.log(abs_d[curr] / abs_d[prev]) * 100)
            dates_for_growth.append(curr)
        ax.plot(dates_for_growth, g_long_arr, label="ph_long Δlog (%)",
                color="tab:orange", linewidth=1.4)
        ax.plot(dates_for_growth, g_abs_arr, label="ABS 6416 Δlog (%)",
                color="tab:blue", linewidth=1.4)
        ax.axhline(0, color="black", linewidth=0.5)
    ax.set_title("Q-over-Q growth during 2003-2018 overlap "
                 "(diagnostic for splice quality)",
                 fontsize=11, fontweight="bold")
    ax.set_ylabel("Δlog %")
    ax.legend(loc="best", fontsize=9)
    ax.grid(True, alpha=0.3)
    ax.xaxis.set_major_locator(mdates.YearLocator(3))

    fig.savefig(OUT_PNG, dpi=150)
    plt.close(fig)
    print(f"  Saved: {OUT_PNG.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
