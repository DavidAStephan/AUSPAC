#!/usr/bin/env python3
"""build_mining_investment_quarterly.py

Quarterly mining GFCF (chain-volume, $m) for the AU-PAC mining-investment ECM,
by TEMPORAL DISAGGREGATION of the national-accounts annual benchmark using the
quarterly capex survey as the movement indicator (per the standard
benchmark-to-indicator method, IMF Bloem/Dippelsman/Maehle):

  BENCHMARK (low-freq, NA-consistent):  ABS 5204.0 Table 64, "Mining ; Gross fixed
      capital formation: Chain volume measures" (annual, fiscal years ending June).
      File: data/abs_rba/abs_5204_gfcf_by_industry.xlsx, Data1 col 12. id-by-col.
  INDICATOR (high-freq movements):       ABS 5625.0 Table 7, "Mining ; Total (Type of
      Asset) ; Chain Volume Measures ; Seasonally Adjusted" (quarterly). id A3515959C.
      File: data/abs_rba/abs_5625_07_volume_measures_seasonally_adjusted_capex.xlsx, Data1 col 40.

Method: DENTON proportional-first-differences (PFD). Minimise sum_t [ (y_t/x_t) -
  (y_{t-1}/x_{t-1}) ]^2 subject to the four quarters of each fiscal year summing to
  the annual benchmark (GFCF is a FLOW => sum, not average). Solve the linear KKT
  system. The two trailing quarters with no completed-FY benchmark (2025Q3/Q4) are
  extrapolated by the PFD smoothness (ratio held ~constant -> proportional to indicator).

FY mapping (year ending June Y):  Sep(Y-1)+Dec(Y-1)+Mar(Y)+Jun(Y).

Output: data/mining_investment_quarterly_cvm.csv  (date, mining_gfcf_cvm_q, indicator_5625_q, fy).

Run:  python3 data/build_mining_investment_quarterly.py
"""
from pathlib import Path
import numpy as np, openpyxl, csv

ROOT = Path(__file__).resolve().parents[1]
ABS = ROOT / "data" / "abs_rba"
F_BENCH = ABS / "abs_5204_gfcf_by_industry.xlsx"          # Table 64
F_IND   = ABS / "abs_5625_07_volume_measures_seasonally_adjusted_capex.xlsx"  # Table 7
COL_BENCH, COL_IND = 12, 40
OUT = ROOT / "data" / "mining_investment_quarterly_cvm.csv"


def read_series(path, col, want_desc):
    wb = openpyxl.load_workbook(path, read_only=True, data_only=True)
    r = list(wb["Data1"].iter_rows(values_only=True))
    desc = r[0][col]
    assert want_desc in str(desc), f"col {col} is {desc!r}, expected to contain {want_desc!r}"
    out = []
    for row in r:
        d = row[0]
        if hasattr(d, "year") and isinstance(row[col], (int, float)):
            out.append((d, float(row[col])))
    return out, str(desc)


def fy_of(d):
    # fiscal year ending June: Sep/Dec -> next calendar year's FY; Mar/Jun -> this year's FY
    return d.year + 1 if d.month in (9, 12) else d.year


def main():
    bench, bdesc = read_series(F_BENCH, COL_BENCH, "Gross fixed capital formation: Chain volume")
    ind,   idesc = read_series(F_IND,   COL_IND,   "Mining")
    print(f"benchmark: {bdesc.strip()[:70]}  ({bench[0][0].year}..{bench[-1][0].year}, n={len(bench)})")
    print(f"indicator: {idesc.strip()[:70]}  ({ind[0][0]:%Y-%m}..{ind[-1][0]:%Y-%m}, n={len(ind)})")

    bench_fy = {fy_of(d): v for d, v in bench}          # FY -> annual GFCF (June-dated => fy_of==year)
    qdates = [d for d, _ in ind]
    x = np.array([v for _, v in ind], dtype=float)
    n = len(x)
    qfy = [fy_of(d) for d in qdates]

    # complete FYs that (a) have all 4 indicator quarters present and (b) have a benchmark
    from collections import Counter
    cnt = Counter(qfy)
    use_fy = sorted(fy for fy in cnt if cnt[fy] == 4 and fy in bench_fy)
    print(f"complete benchmarked FYs: {use_fy[0]}..{use_fy[-1]} ({len(use_fy)})  "
          f"trailing extrapolated quarters: {[f'{d:%Y-%m}' for d,f in zip(qdates,qfy) if f not in use_fy]}")

    # constraint matrix C (n_a x n): sum of the 4 quarters of each used FY
    C = np.zeros((len(use_fy), n))
    b = np.zeros(len(use_fy))
    for a, fy in enumerate(use_fy):
        for t in range(n):
            if qfy[t] == fy:
                C[a, t] = 1.0
        b[a] = bench_fy[fy]

    # Denton PFD: min r' (D'D) r  s.t.  (C X) r = b ,  y = x*r ,  X=diag(x)
    D = np.zeros((n - 1, n))
    for i in range(n - 1):
        D[i, i], D[i, i + 1] = -1.0, 1.0
    # numpy 2.0.x threaded-BLAS can raise spurious divide/overflow FP flags inside
    # matmul on perfectly finite inputs; ignore the cosmetic flags and assert that the
    # actual result is finite/positive instead.
    with np.errstate(divide="ignore", over="ignore", invalid="ignore"):
        M = D.T @ D
        A = C * x[None, :]                   # C @ diag(x)
        na = A.shape[0]
        KKT = np.block([[2 * M, A.T], [A, np.zeros((na, na))]])
        rhs = np.concatenate([np.zeros(n), b])
        sol = np.linalg.solve(KKT, rhs)
    r = sol[:n]
    y = x * r                                 # quarterly mining GFCF (CVM, $m)
    assert np.all(np.isfinite(y)) and (y > 0).all(), "non-finite/non-positive disaggregated series"

    # ---- diagnostics / validation ----
    ann_y = np.array([y[[t for t in range(n) if qfy[t] == fy]].sum() for fy in use_fy])
    rel_err = np.max(np.abs(ann_y - b) / np.abs(b))
    pos = bool((y > 0).all())
    # indicator quality: OLS of annual benchmark on annualised indicator
    ann_x = np.array([x[[t for t in range(n) if qfy[t] == fy]].sum() for fy in use_fy])
    A_ols = np.vstack([np.ones_like(ann_x), ann_x]).T
    beta, *_ = np.linalg.lstsq(A_ols, b, rcond=None)
    fit = A_ols @ beta
    r2 = 1 - ((b - fit) ** 2).sum() / ((b - b.mean()) ** 2).sum()
    # growth co-movement
    g_y, g_x = np.diff(np.log(y)), np.diff(np.log(x))
    corr = float(np.corrcoef(g_y, g_x)[0, 1])

    print(f"\nVALIDATION")
    print(f"  annual-sum constraint max rel err : {rel_err:.2e}  (want ~0)")
    print(f"  quarterly series strictly positive : {pos}")
    print(f"  indicator->benchmark OLS R^2       : {r2:.3f}  (annualised 5625 explains 5204 GFCF)")
    print(f"  corr(dln y, dln indicator)         : {corr:.3f}")
    print(f"  mean level ratio y/indicator       : {np.mean(y/x):.3f}  (NA GFCF vs survey capex)")
    pk = int(np.argmax(y))
    print(f"  quarterly peak                     : {y[pk]:,.0f} at {qdates[pk]:%Y-%m} (mining-boom)")
    print(f"  latest 3 quarters                  : " +
          ", ".join(f"{qdates[t]:%Y-%m}={y[t]:,.0f}" for t in range(n-3, n)))

    with open(OUT, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["date", "mining_gfcf_cvm_q", "indicator_5625_q", "fy", "extrapolated"])
        for t in range(n):
            w.writerow([f"{qdates[t]:%Y-%m-%d}", round(y[t], 3), round(x[t], 3),
                        qfy[t], int(qfy[t] not in use_fy)])
    print(f"\nwrote {OUT}  ({n} quarters {qdates[0]:%Y-%m}..{qdates[-1]:%Y-%m})")


if __name__ == "__main__":
    main()
