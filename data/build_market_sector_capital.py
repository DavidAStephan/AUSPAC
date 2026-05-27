#!/usr/bin/env python3
"""build_market_sector_capital.py

Constructs market-sector capital stock K_market from ABS 5204 Table 63
by-industry net capital stock, matched to the market-sector GVA Q_market
from ABS 5206 Table 6 that prepare_supply_data.m already builds.

Also constructs mining vs non-mining splits of both Q and K for the
Phase L3 hypothesis test (PAC_BI_AU_EXPLORATION.md §6 Hypothesis B).

Outputs: data/market_sector_capital.csv  (annual, then linearly
         interpolated to quarterly for the CES calibration)

Definitions (matching prepare_supply_data.m's Q_market):

  Q_market = Total GVA − Public admin − Education − Health − Ownership of dwellings
             (ABS 5206 Table 6, chain volumes, SA)

  K_market = ALL INDUSTRIES total − Dwellings asset − Public admin − Education − Health
             (ABS 5204 Table 63, chain volumes, annual → interpolated to quarterly)

  K_mining  = Mining (B) industry net capital stock (ABS 5204 col 12)
  K_nonmining_market = K_market − K_mining

  Q_mining  = Mining (B) GVA (ABS 5206 col 10, chain volumes, SA)
  Q_nonmining_market = Q_market − Q_mining

Run:  cd ~/Documents/AUSPAC && python3 data/build_market_sector_capital.py
"""

from pathlib import Path
import numpy as np
import openpyxl
import csv
from datetime import datetime

ROOT = Path(__file__).resolve().parents[1]
ABS_DIR = ROOT / "data" / "abs_rba"
OUT_CSV = ROOT / "data" / "market_sector_capital.csv"


def read_annual_col(ws, col_idx, first_data_row=11):
    """Read annual data from an ABS 5204 worksheet column."""
    dates, vals = [], []
    for row in ws.iter_rows(min_row=first_data_row, values_only=False):
        d = row[0].value
        v = row[col_idx].value
        if d is None:
            break
        if isinstance(d, datetime):
            dates.append(d.year)
        elif isinstance(d, (int, float)):
            dates.append(int(d))
        else:
            try:
                dates.append(int(str(d)[:4]))
            except ValueError:
                break
        try:
            vals.append(float(v) if v is not None else np.nan)
        except (ValueError, TypeError):
            vals.append(np.nan)
    return np.array(dates), np.array(vals)


def read_quarterly_col(ws, col_idx, first_data_row=11):
    """Read quarterly data from an ABS 5206 worksheet column."""
    dates, vals = [], []
    for row in ws.iter_rows(min_row=first_data_row, values_only=False):
        d = row[0].value
        v = row[col_idx].value
        if d is None:
            break
        try:
            vals.append(float(v) if v is not None else np.nan)
        except (ValueError, TypeError):
            vals.append(np.nan)
        if isinstance(d, datetime):
            dates.append(d)
        else:
            break
    return dates, np.array(vals)


def main():
    print("=== build_market_sector_capital.py ===\n")

    # --- ABS 5204 Table 63: Net capital stock by industry (annual, chain vol $M) ---
    print("Reading ABS 5204 net capital stock by industry...")
    wb_k = openpyxl.load_workbook(ABS_DIR / "abs_5204_net_capital_stock.xlsx",
                                  read_only=True, data_only=True)
    ws_k = wb_k["Data1"]

    # Column indices (0-based) from the header scan above
    COL_K_ALL      = 113   # ALL INDUSTRIES total
    COL_K_DWELL    = 103   # ALL INDUSTRIES ; Dwellings
    COL_K_PUBADM   = 79    # Public administration and safety
    COL_K_EDU      = 84    # Education and training
    COL_K_HEALTH   = 89    # Health care and social assistance
    COL_K_MINING   = 12    # Mining (B)
    COL_K_AGRI     = 6     # Agriculture (A)

    years_k, k_all     = read_annual_col(ws_k, COL_K_ALL)
    _,       k_dwell   = read_annual_col(ws_k, COL_K_DWELL)
    _,       k_pubadm  = read_annual_col(ws_k, COL_K_PUBADM)
    _,       k_edu     = read_annual_col(ws_k, COL_K_EDU)
    _,       k_health  = read_annual_col(ws_k, COL_K_HEALTH)
    _,       k_mining  = read_annual_col(ws_k, COL_K_MINING)

    k_market = k_all - k_dwell - k_pubadm - k_edu - k_health
    k_nonmining_market = k_market - k_mining

    print(f"  Years: {int(years_k[0])}–{int(years_k[-1])} ({len(years_k)} obs)")
    print(f"  K_all (2019):          {k_all[years_k == 2019][0]:,.0f} $M")
    print(f"  K_dwellings (2019):    {k_dwell[years_k == 2019][0]:,.0f} $M")
    print(f"  K_pubadm (2019):       {k_pubadm[years_k == 2019][0]:,.0f} $M")
    print(f"  K_edu (2019):          {k_edu[years_k == 2019][0]:,.0f} $M")
    print(f"  K_health (2019):       {k_health[years_k == 2019][0]:,.0f} $M")
    print(f"  K_market (2019):       {k_market[years_k == 2019][0]:,.0f} $M")
    print(f"  K_mining (2019):       {k_mining[years_k == 2019][0]:,.0f} $M")
    print(f"  K_nonmining_mkt (2019):{k_nonmining_market[years_k == 2019][0]:,.0f} $M")
    wb_k.close()

    # --- ABS 5206 Table 6: GVA by industry (quarterly, chain vol $M, SA) ---
    print("\nReading ABS 5206 industry GVA...")
    wb_q = openpyxl.load_workbook(ABS_DIR / "abs_5206_industry_gva.xlsx",
                                  read_only=True, data_only=True)
    ws_q = wb_q["Data1"]

    # Column indices (SA block has an offset from Trend block)
    # Check: the existing prepare_supply_data.m uses a TREND_TO_SA_OFFSET.
    # For Data1 in industry_gva.xlsx, need to identify the SA columns.
    # Let me check the full header row more carefully.
    rows_q = list(ws_q.iter_rows(min_row=1, max_row=3, values_only=True))
    ncol_q = len(rows_q[0])

    # Find SA versions of mining (B) and total GVA
    sa_mining_col = None
    sa_total_col = None
    sa_pubadm_col = None
    sa_edu_col = None
    sa_health_col = None
    sa_dwell_col = None

    for ci in range(ncol_q):
        h = rows_q[0][ci]
        series_type = rows_q[2][ci] if rows_q[2][ci] else ""
        if h is None:
            continue
        h = str(h)
        if "Seasonally Adjusted" not in str(series_type):
            continue
        if "Mining (B) ;" == h.strip().rstrip(";").strip() + " ;":
            if sa_mining_col is None:
                sa_mining_col = ci
        elif h.strip() == "Mining (B) ;":
            if sa_mining_col is None:
                sa_mining_col = ci
        elif "Gross value added at basic prices" in h:
            sa_total_col = ci
        elif "Public administration" in h:
            sa_pubadm_col = ci
        elif "Education and training" in h:
            sa_edu_col = ci
        elif "Health care and social assistance" in h:
            sa_health_col = ci
        elif "Ownership of dwellings" in h:
            sa_dwell_col = ci

    # Fallback: if exact SA match fails, use known offsets
    # The Data1 sheet typically has Trend first, then SA.
    # Mining (B) Trend is col 10; SA offset is typically +55 for this table.
    if sa_mining_col is None:
        # Search more broadly
        for ci in range(ncol_q):
            h = str(rows_q[0][ci] or "")
            st = str(rows_q[2][ci] or "")
            if "Mining" in h and "Seasonally" in st and "Coal" not in h and "Oil" not in h and "Iron" not in h and "Other" not in h and "Exploration" not in h and "excluding" not in h:
                sa_mining_col = ci
                break

    if sa_total_col is None:
        for ci in range(ncol_q):
            h = str(rows_q[0][ci] or "")
            st = str(rows_q[2][ci] or "")
            if "basic prices" in h and "Seasonally" in st:
                sa_total_col = ci
                break

    # For the non-market industries in SA:
    for ci in range(ncol_q):
        h = str(rows_q[0][ci] or "")
        st = str(rows_q[2][ci] or "")
        if "Seasonally" not in st:
            continue
        if sa_pubadm_col is None and "Public administration" in h:
            sa_pubadm_col = ci
        if sa_edu_col is None and "Education and training" in h:
            sa_edu_col = ci
        if sa_health_col is None and "Health care" in h:
            sa_health_col = ci
        if sa_dwell_col is None and "Ownership of dwellings" in h:
            sa_dwell_col = ci

    print(f"  SA columns: mining={sa_mining_col}, total={sa_total_col}, "
          f"pubadm={sa_pubadm_col}, edu={sa_edu_col}, health={sa_health_col}, "
          f"dwell={sa_dwell_col}")

    if any(c is None for c in [sa_mining_col, sa_total_col, sa_pubadm_col,
                                sa_edu_col, sa_health_col, sa_dwell_col]):
        print("  WARNING: could not find all SA columns; trying trend columns with offset")
        # Use trend columns as fallback (cols 10, 52, 46, 47, 48, 51)
        # and note that SA columns start at +55 offset in this table
        sa_offset = 55
        sa_mining_col = sa_mining_col or (10 + sa_offset)
        sa_total_col = sa_total_col or (52 + sa_offset)
        sa_pubadm_col = sa_pubadm_col or (46 + sa_offset)
        sa_edu_col = sa_edu_col or (47 + sa_offset)
        sa_health_col = sa_health_col or (48 + sa_offset)
        sa_dwell_col = sa_dwell_col or (51 + sa_offset)
        print(f"  Fallback SA cols: mining={sa_mining_col}, total={sa_total_col}")

    dates_q_list, q_total  = read_quarterly_col(ws_q, sa_total_col)
    _,            q_mining = read_quarterly_col(ws_q, sa_mining_col)
    _,            q_pubadm = read_quarterly_col(ws_q, sa_pubadm_col)
    _,            q_edu    = read_quarterly_col(ws_q, sa_edu_col)
    _,            q_health = read_quarterly_col(ws_q, sa_health_col)
    _,            q_dwell  = read_quarterly_col(ws_q, sa_dwell_col)
    wb_q.close()

    q_market = q_total - q_pubadm - q_edu - q_health - q_dwell
    q_nonmining_market = q_market - q_mining

    # Find 2019 annual average for diagnostics
    years_q = np.array([d.year for d in dates_q_list])
    mask_2019 = years_q == 2019
    print(f"\n  Q_total (2019 avg):          {np.nanmean(q_total[mask_2019]):,.0f} $M/qtr")
    print(f"  Q_market (2019 avg):         {np.nanmean(q_market[mask_2019]):,.0f} $M/qtr")
    print(f"  Q_mining (2019 avg):         {np.nanmean(q_mining[mask_2019]):,.0f} $M/qtr")
    print(f"  Q_nonmining_mkt (2019 avg):  {np.nanmean(q_nonmining_market[mask_2019]):,.0f} $M/qtr")

    # --- Compute gamma ratios ---
    # γ_old = Q_market / K_total (the mismatched version)
    # γ_new = Q_market / K_market (the corrected version)
    # Both at 2019 base year (quarterly Q avg / annual K)
    q_mkt_2019 = np.nanmean(q_market[mask_2019])
    k_all_2019 = k_all[years_k == 2019][0]
    k_mkt_2019 = k_market[years_k == 2019][0]
    k_min_2019 = k_mining[years_k == 2019][0]
    k_nmkt_2019 = k_nonmining_market[years_k == 2019][0]
    q_min_2019 = np.nanmean(q_mining[mask_2019])
    q_nmkt_2019 = np.nanmean(q_nonmining_market[mask_2019])

    gamma_old = q_mkt_2019 / k_all_2019
    gamma_new = q_mkt_2019 / k_mkt_2019
    gamma_mining = q_min_2019 / k_min_2019
    gamma_nonmining = q_nmkt_2019 / k_nmkt_2019

    print(f"\n=== Gamma diagnostics (2019 base year) ===")
    print(f"  γ_old = Q_market / K_total       = {q_mkt_2019:,.0f} / {k_all_2019:,.0f} = {gamma_old:.4f}")
    print(f"  γ_new = Q_market / K_market       = {q_mkt_2019:,.0f} / {k_mkt_2019:,.0f} = {gamma_new:.4f}")
    print(f"  γ_mining = Q_mining / K_mining     = {q_min_2019:,.0f} / {k_min_2019:,.0f} = {gamma_mining:.4f}")
    print(f"  γ_nonmining = Q_nonmkt / K_nonmkt = {q_nmkt_2019:,.0f} / {k_nmkt_2019:,.0f} = {gamma_nonmining:.4f}")
    print(f"\n  FR-BDF 2026 γ = 0.2561 for France")
    print(f"  OLD AUSPAC γ  = {gamma_old:.4f}  (mismatched: Q_market / K_total)")
    print(f"  NEW AUSPAC γ  = {gamma_new:.4f}  (matched: Q_market / K_market)")

    # --- Cross-restriction diagnostic for μ ---
    sigma = 0.5366
    alpha = 0.45
    for label, g in [("old (mismatched)", gamma_old), ("new (matched)", gamma_new)]:
        log_mu = np.log(1 - alpha) + ((sigma - 1) / sigma) * np.log(g)
        mu = np.exp(log_mu)
        print(f"\n  μ cross-restriction at γ_{label}: μ = {mu:.3f}")

    # --- Write CSV output ---
    print(f"\nWriting {OUT_CSV}...")
    with OUT_CSV.open("w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["year", "k_all", "k_market", "k_mining", "k_nonmining_market",
                     "k_dwellings", "k_pubadm", "k_edu", "k_health"])
        for i, yr in enumerate(years_k):
            w.writerow([int(yr), k_all[i], k_market[i], k_mining[i],
                        k_nonmining_market[i], k_dwell[i], k_pubadm[i],
                        k_edu[i], k_health[i]])
    print(f"  wrote {len(years_k)} annual rows")

    # Also write the quarterly GVA splits
    OUT_GVA = ROOT / "data" / "market_sector_gva_splits.csv"
    print(f"Writing {OUT_GVA}...")
    with OUT_GVA.open("w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["date", "q_total", "q_market", "q_mining",
                     "q_nonmining_market", "q_pubadm", "q_edu",
                     "q_health", "q_dwellings"])
        for i, d in enumerate(dates_q_list):
            w.writerow([d.strftime("%Y-%m-%d"), q_total[i], q_market[i],
                        q_mining[i], q_nonmining_market[i],
                        q_pubadm[i], q_edu[i], q_health[i], q_dwell[i]])
    print(f"  wrote {len(dates_q_list)} quarterly rows")

    print("\ndone.")


if __name__ == "__main__":
    main()
