#!/usr/bin/env python3
"""estimate_coupling1_toti.py — Coupling 1: terms-of-trade INCOME effect on consumption.

Spec: c_hat += lambda_toti * tot_gap, where tot_gap = pcom_gap = HP-detrended log of the
RBA i02 AUD commodity index GRCPAIAD (quarterly-averaged). Mirror estimate_mining_supply.py.

LHS candidates:
  (A) consumption GAP  = HP-detrended log real household consumption (au_consumption)
  (B) consumption GROWTH = 100*dln(au_consumption)
Control: output gap au_ygap (from dataset.csv) — a demand control.

Reports lambda_toti (the tot_gap coefficient), t-stat, R2, sample for several specs.
"""
from pathlib import Path
import numpy as np, csv, openpyxl
from collections import defaultdict

ROOT = Path(__file__).resolve().parents[2]

def hp_trend(y, lam=1600.0):
    n = len(y); I = np.eye(n)
    D = np.zeros((n - 2, n))
    for i in range(n - 2):
        D[i, i], D[i, i + 1], D[i, i + 2] = 1.0, -2.0, 1.0
    with np.errstate(divide="ignore", over="ignore", invalid="ignore"):
        trend = np.linalg.solve(I + lam * (D.T @ D), y)
    return trend

def hp_gap(y, lam=1600.0):
    return y - hp_trend(y, lam)

def ols(y, X, names):
    with np.errstate(divide="ignore", over="ignore", invalid="ignore"):
        b, *_ = np.linalg.lstsq(X, y, rcond=None)
        e = y - X @ b; n, k = X.shape
        s2 = (e @ e) / (n - k)
        XtXi = np.linalg.inv(X.T @ X)
        se = np.sqrt(np.diag(s2 * XtXi))
    assert np.all(np.isfinite(b)) and np.all(np.isfinite(se))
    t = b / se
    r2 = 1 - (e @ e) / ((y - y.mean()) @ (y - y.mean()))
    dw = np.sum(np.diff(e) ** 2) / (e @ e)
    return dict(b=b, se=se, t=t, r2=r2, dw=dw, n=n, names=names)

def pr(res):
    for nm, b, t, se in zip(res["names"], res["b"], res["t"], res["se"]):
        print(f"    {nm:22s} = {b:+.5f}  (se={se:.5f}, t={t:+.2f})")
    print(f"    R2={res['r2']:.3f}  DW={res['dw']:.2f}  N={res['n']}")

def qkey(ds):
    # date strings like '1993-01-01'
    y, m, _ = map(int, ds.split("-"))
    return (y, (m - 1) // 3 + 1)

# ---------- commodity / ToT gap (mirror estimate_mining_supply.py) ----------
wb = openpyxl.load_workbook(ROOT / "data/abs_rba/rba_i02_commodity.xlsx", read_only=True, data_only=True)
rows = list(wb["Data"].iter_rows(values_only=True))
com_m = [(r[0], r[1]) for r in rows if hasattr(r[0], "year") and isinstance(r[1], (int, float))]
def q_end(d):
    return (d.year, (d.month - 1) // 3 + 1)
acc = defaultdict(list)
for d, v in com_m:
    acc[q_end(d)].append(v)
com_q = {k: float(np.mean(v)) for k, v in acc.items()}  # quarterly avg AUD commodity index

# ---------- consumption + output gap ----------
ext = list(csv.DictReader(open(ROOT / "data/extended_dataset.csv")))
base = list(csv.DictReader(open(ROOT / "dataset.csv")))
ygap_by_date = {}
for r in base:
    try:
        v = float(r["au_ygap"])
        if np.isfinite(v):
            ygap_by_date[r["date"]] = v
    except Exception:
        pass

def _f(x):
    try:
        v = float(x)
        return v if np.isfinite(v) else None
    except Exception:
        return None
c_rows = [(r["date"], _f(r["au_consumption"])) for r in ext]
c_rows = [(d, v) for d, v in c_rows if v is not None and v > 0]
c_dates = [d for d, _ in c_rows]
lnC = np.log(np.array([v for _, v in c_rows]))

# align commodity log to consumption quarters
keep = []
lncom = []
for i, ds in enumerate(c_dates):
    k = qkey(ds)
    if k in com_q:
        keep.append(i); lncom.append(np.log(com_q[k]))
keep = np.array(keep); lncom = np.array(lncom)
lnC_a = lnC[keep]
dates_a = [c_dates[i] for i in keep]
ygap_a = np.array([ygap_by_date.get(d, np.nan) for d in dates_a])

print(f"common sample n={len(keep)}  ({dates_a[0]} .. {dates_a[-1]})")
print(f"output-gap non-null: {np.sum(np.isfinite(ygap_a))}")

# HP gaps on common sample
cgap = hp_gap(lnC_a) * 100.0          # consumption gap in pp (log*100)
comgap = hp_gap(lncom) * 100.0        # ToT/commodity gap in pp (log*100)  == pcom_gap*100
tot_gap = comgap                       # spec: tot_gap = pcom_gap
dlnC = np.diff(lnC_a) * 100.0          # consumption growth in pp

print(f"\nstd(cgap)={cgap.std():.3f}pp  std(tot_gap)={tot_gap.std():.3f}pp  "
      f"corr(cgap,tot_gap)={np.corrcoef(cgap,tot_gap)[0,1]:+.3f}")

# ================= SPEC A: consumption GAP on tot_gap (+ output gap) =================
print("\n[A1] cgap = a + lambda_toti*tot_gap        (no control)")
y = cgap; X = np.column_stack([np.ones_like(y), tot_gap])
resA1 = ols(y, X, ["const", "lambda_toti"]); pr(resA1)

print("\n[A2] cgap = a + lambda_toti*tot_gap + g*ygap   (output-gap control)")
m = np.isfinite(ygap_a)
y = cgap[m]; X = np.column_stack([np.ones(m.sum()), tot_gap[m], ygap_a[m]])
resA2 = ols(y, X, ["const", "lambda_toti", "ygap"]); pr(resA2)

print("\n[A3] cgap = a + lambda_toti*tot_gap + rho*cgap(-1) + g*ygap   (+ persistence)")
m = np.isfinite(ygap_a)
y = cgap[1:][m[1:]]
X = np.column_stack([np.ones_like(y), tot_gap[1:][m[1:]], cgap[:-1][m[1:]], ygap_a[1:][m[1:]]])
resA3 = ols(y, X, ["const", "lambda_toti", "cgap(-1)", "ygap"]); pr(resA3)

# ================= SPEC B: consumption GROWTH on tot_gap =================
print("\n[B1] dlnC = a + lambda_toti*tot_gap(-1)      (growth on lagged ToT gap)")
y = dlnC; X = np.column_stack([np.ones_like(y), tot_gap[:-1]])
resB1 = ols(y, X, ["const", "lambda_toti"]); pr(resB1)

print("\n[B2] dlnC = a + lambda_toti*tot_gap + g*ygap   (growth, contemp ToT gap + ygap)")
m = np.isfinite(ygap_a[1:])
y = dlnC[m]; X = np.column_stack([np.ones(m.sum()), tot_gap[1:][m], ygap_a[1:][m]])
resB2 = ols(y, X, ["const", "lambda_toti", "ygap"]); pr(resB2)

print("\nDONE")
out = ROOT / "data/pac_blocks/results_coupling1_toti.txt"
with open(out, "w") as f:
    f.write("Coupling 1: ToT income effect on consumption (estimate_coupling1_toti.py)\n")
    f.write(f"common sample n={len(keep)} ({dates_a[0]} .. {dates_a[-1]})\n")
    f.write(f"tot_gap = pcom_gap = HP-gap(log RBA i02 GRCPAIAD AUD, q-avg), lam=1600, *100 (pp)\n")
    f.write(f"cgap = HP-gap(log au_consumption)*100 (pp); dlnC = 100*dln(au_consumption)\n")
    f.write(f"corr(cgap,tot_gap)={np.corrcoef(cgap,tot_gap)[0,1]:+.3f}\n\n")
    for tag, res in [("A1 cgap~tot_gap", resA1), ("A2 cgap~tot_gap+ygap", resA2),
                     ("A3 cgap~tot_gap+cgap(-1)+ygap", resA3),
                     ("B1 dlnC~tot_gap(-1)", resB1), ("B2 dlnC~tot_gap+ygap", resB2)]:
        f.write(f"[{tag}]\n")
        for nm, b, t, se in zip(res["names"], res["b"], res["t"], res["se"]):
            f.write(f"    {nm:22s} = {b:+.5f} (se={se:.5f}, t={t:+.2f})\n")
        f.write(f"    R2={res['r2']:.3f} DW={res['dw']:.2f} N={res['n']}\n\n")
print(f"wrote {out}")
