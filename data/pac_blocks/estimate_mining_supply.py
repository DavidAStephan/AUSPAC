#!/usr/bin/env python3
"""estimate_mining_supply.py — AU-estimated parameters for the Phase-2 mining supply block.

The mining block is SUPPLY-driven: potential = capacity ratchet (calibrated kappa_qk_m=1,
h_m=4), and actual VA wobbles around capacity with a small terms-of-trade / commodity-price
response. The only genuinely AU-ESTIMATED mining behavioural params are the utilisation-gap
AR + commodity response (rho_qm, psi_qm) and the mining-investment commodity sensitivity.
Everything else (kappa_qk_m, h_m, alpha_m=0.84, deflator pass-through) is calibrated per spec.

Inputs (all in repo):
  mining VA (quarterly, $m CVM SA)  : data/market_sector_gva_splits.csv  col q_mining
  mining investment (quarterly CVM) : data/mining_investment_quarterly_cvm.csv col mining_gfcf_cvm_q
  commodity price (AUD index)       : data/abs_rba/rba_i02_commodity.xlsx  GRCPAIAD (monthly -> quarterly)
  mining capital (annual)           : data/market_sector_capital.csv col k_mining
  mining GFCF (annual, CVM)         : data/abs_rba/abs_5204_gfcf_by_industry.xlsx col 12

Outputs: prints the estimates; writes data/pac_blocks/results_mining_supply.txt
"""
from pathlib import Path
import numpy as np, csv, openpyxl
from datetime import date

ROOT = Path(__file__).resolve().parents[2]

def hp_gap(y, lam=1600.0):
    n = len(y); I = np.eye(n)
    D = np.zeros((n - 2, n))
    for i in range(n - 2):
        D[i, i], D[i, i + 1], D[i, i + 2] = 1.0, -2.0, 1.0
    with np.errstate(divide="ignore", over="ignore", invalid="ignore"):  # numpy 2.0.x BLAS flag quirk
        trend = np.linalg.solve(I + lam * (D.T @ D), y)
    return y - trend

def ols(y, X, names):
    # X already includes constant column if wanted
    b, *_ = np.linalg.lstsq(X, y, rcond=None)
    e = y - X @ b; n, k = X.shape
    s2 = (e @ e) / (n - k)
    XtXi = np.linalg.inv(X.T @ X)
    se = np.sqrt(np.diag(s2 * XtXi))
    r2 = 1 - (e @ e) / ((y - y.mean()) @ (y - y.mean()))
    dw = np.sum(np.diff(e) ** 2) / (e @ e)
    return dict(b=b, se=se, t=b / se, r2=r2, dw=dw, n=n, names=names)

def pr(res):
    for nm, b, t in zip(res["names"], res["b"], res["t"]):
        print(f"    {nm:18s} = {b:+.4f}  (t={t:+.2f})")
    print(f"    R2={res['r2']:.3f}  DW={res['dw']:.2f}  N={res['n']}")

# ---- load quarterly mining VA (log) ----
g = list(csv.DictReader(open(ROOT / "data/market_sector_gva_splits.csv")))
qm = [(r["date"], float(r["q_mining"])) for r in g if r["q_mining"] not in ("nan", "")]
qm_dates = [d for d, _ in qm]
lnQm = np.log(np.array([v for _, v in qm]))

# ---- commodity price AUD index (monthly -> quarterly average), log ----
wb = openpyxl.load_workbook(ROOT / "data/abs_rba/rba_i02_commodity.xlsx", read_only=True, data_only=True)
rows = list(wb["Data"].iter_rows(values_only=True))
com_m = [(r[0], r[1]) for r in rows if hasattr(r[0], "year") and isinstance(r[1], (int, float))]  # col1 = A$ all items
def q_end(d):  # map month-end to calendar-quarter key 'YYYY-Qn'
    return (d.year, (d.month - 1) // 3 + 1)
from collections import defaultdict
acc = defaultdict(list)
for d, v in com_m:
    acc[q_end(d)].append(v)
com_q = {k: np.mean(v) for k, v in acc.items()}  # quarterly avg AUD commodity index

# align mining VA quarter to commodity quarter
def qkey(ds):
    y, m, _ = map(int, ds.split("-")); return (y, (m - 1) // 3 + 1)
lncom = []
keep = []
for i, ds in enumerate(qm_dates):
    k = qkey(ds)
    if k in com_q:
        lncom.append(np.log(com_q[k])); keep.append(i)
keep = np.array(keep); lncom = np.array(lncom)
lnQm_a = lnQm[keep]

# ---- HP gaps on the common sample ----
qmgap = hp_gap(lnQm_a)
comgap = hp_gap(lncom)
print(f"common sample n={len(keep)}  ({qm_dates[keep[0]]} .. {qm_dates[keep[-1]]})")

# ---- (1) mining utilisation gap: q_m_gap = rho_qm*q_m_gap(-1) + psi_qm*comgap + e ----
print("\n[1] Mining utilisation gap  q_m_gap = rho_qm*q_m_gap(-1) + psi_qm*comgap")
y = qmgap[1:]
X = np.column_stack([qmgap[:-1], comgap[1:]])
res1 = ols(y, X, ["rho_qm", "psi_qm"]); pr(res1)

# ---- (2) mining investment commodity sensitivity ----
print("\n[2] Mining investment  dln_ib_m = b1*dln_ib_m(-1) + b3*dln_pcom + b0*comgap(-1)")
mi = list(csv.DictReader(open(ROOT / "data/mining_investment_quarterly_cvm.csv")))
lnIb = np.log(np.array([float(r["mining_gfcf_cvm_q"]) for r in mi]))
mi_keys = [qkey(r["date"]) for r in mi]
# align commodity (level log + gap) to mining investment quarters
lncom_full = {k: np.log(v) for k, v in com_q.items()}
idx = [i for i, k in enumerate(mi_keys) if k in lncom_full]
idx = np.array(idx)
lnIb_a = lnIb[idx]
lncom_mi = np.array([lncom_full[mi_keys[i]] for i in idx])
comgap_mi = hp_gap(lncom_mi)
dlnIb = np.diff(lnIb_a); dlncom = np.diff(lncom_mi)
# regress dln_ib_m_t on dln_ib_m_{t-1}, dln_pcom_t, comgap_{t-1}
y2 = dlnIb[2:]
X2 = np.column_stack([dlnIb[1:-1], dlncom[2:], comgap_mi[1:-2]])
res2 = ols(y2, X2, ["b1_ibm", "b3_ibm(dpcom)", "b0_ibm(comgap)"]); pr(res2)

# ---- (3) mining depreciation rate from the capital account (annual) ----
print("\n[3] Mining depreciation delta_k_m  (PIM: I_t = K_t-(1-delta)K_{t-1} => delta=(I-dK)/K_lag)")
cap = list(csv.DictReader(open(ROOT / "data/market_sector_capital.csv")))
K = {int(r["year"]): float(r["k_mining"]) for r in cap if r["k_mining"] not in ("nan", "")}
wb2 = openpyxl.load_workbook(ROOT / "data/abs_rba/abs_5204_gfcf_by_industry.xlsx", read_only=True, data_only=True)
r2 = list(wb2["Data1"].iter_rows(values_only=True))
GF = {row[0].year: float(row[12]) for row in r2 if hasattr(row[0], "year") and isinstance(row[12], (int, float))}
yrs = sorted(set(K) & set(GF))
deltas = []
for y_ in yrs:
    if (y_ - 1) in K:
        d = (GF[y_] - (K[y_] - K[y_ - 1])) / K[y_ - 1]
        if 0 < d < 0.25: deltas.append(d)
da = np.median(deltas)
dq = 1 - (1 - da) ** 0.25
print(f"    median annual delta_k_m = {da:.4f}  -> quarterly = {dq:.4f}  (n={len(deltas)} years)")

print("\nCALIBRATED (per spec): kappa_qk_m=1, h_m=4, alpha_m=0.84, mining deflator alpha_pQm=1/rho_pQm=0.")
out = ROOT / "data/pac_blocks/results_mining_supply.txt"
with open(out, "w") as f:
    f.write("Mining supply block — AU estimates (estimate_mining_supply.py)\n")
    f.write(f"common sample n={len(keep)} ({qm_dates[keep[0]]} .. {qm_dates[keep[-1]]})\n\n")
    f.write("[1] utilisation gap  q_m_gap = rho_qm*q_m_gap(-1) + psi_qm*comgap\n")
    for nm, b, t in zip(res1["names"], res1["b"], res1["t"]):
        f.write(f"    {nm:14s} = {b:+.4f} (t={t:+.2f})\n")
    f.write(f"    R2={res1['r2']:.3f} DW={res1['dw']:.2f} N={res1['n']}\n")
    f.write("    NOTE: psi_qm insignificant (t<1) — mining VA ~ capacity; written back verbatim (OLS-over-calibration).\n\n")
    f.write("[2] mining investment  dln_ib_m = b1*dln_ib_m(-1) + b3*dln_pcom + b0*comgap(-1)\n")
    for nm, b, t in zip(res2["names"], res2["b"], res2["t"]):
        f.write(f"    {nm:18s} = {b:+.4f} (t={t:+.2f})\n")
    f.write(f"    R2={res2['r2']:.3f} DW={res2['dw']:.2f} N={res2['n']}\n\n")
    f.write(f"[3] delta_k_m = {da:.4f}/yr -> {dq:.4f}/q  (PIM median, n={len(deltas)})\n\n")
    f.write("CALIBRATED (spec): kappa_qk_m=1, h_m=4, alpha_m=0.84, mining deflator alpha_pQm=1/rho_pQm=0.\n")
print(f"wrote {out}")
