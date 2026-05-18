"""Build channel observables for the augmented AU-PAC targets.

Constructs three new observable growth-rate series for the model:
  - dln_tot_obs    Terms-of-trade growth, (Pxport / Pmport) qoq log-change.
                   Used in VA price target and business-investment target as
                   a commodity-cycle / TOT level channel.
  - dln_pop_obs    Working-age population growth, qoq log-change.
                   Used in housing-investment target.
  - dln_ph_obs     Real housing-price growth (rppi / cpi), qoq log-change.
                   Used in consumption target as a housing-wealth channel.

Each series is demeaned to match the model's growth-neutrality (SS = 0).
The script writes channel_data.mat with date-aligned arrays covering the
same 1994Q3 to 2024Q4 sample as estimation_data.mat.

It then runs OLS of the existing smoothed shocks (bayesian_mcmc_results.mat)
on the candidate channels to produce calibrated coefficients that
prepare_bayesian_data.m will reuse as priors in the next MCMC.
"""

from pathlib import Path
import numpy as np
import pandas as pd
from scipy.io import loadmat, savemat
from datetime import date

HERE = Path(__file__).resolve().parent
DYNARE = HERE.parent  # dynare/ workspace where MATLAB writes .mat artefacts
ROOT = HERE.parent
DATA = ROOT / "data"

T_TARGET = 122
START = date(1994, 7, 1)


def quarter_dates(start, T):
    out = []
    y, m = start.year, start.month
    for _ in range(T):
        out.append(date(y, m, 1))
        m += 3
        if m > 12:
            m -= 12; y += 1
    return out


def load_ipd_series(series_id):
    """Load a single series from abs_5206_ipd.xlsx by Series ID."""
    df = pd.read_excel(DATA / "abs_rba" / "abs_5206_ipd.xlsx",
                       sheet_name="Data1", header=None)
    ids = df.iloc[9].tolist()
    if series_id not in ids:
        raise ValueError(f"Series {series_id} not in IPD file")
    col = ids.index(series_id)
    dates_raw = df.iloc[10:, 0].tolist()
    vals = df.iloc[10:, col].tolist()
    out = []
    for d, v in zip(dates_raw, vals):
        if isinstance(d, (pd.Timestamp,)) or hasattr(d, "year"):
            out.append((d, v))
    return pd.DataFrame(out, columns=["date", series_id]).set_index("date")


def quarterly_align(df_col, target_dates):
    """Pick the quarter beginning closest to each target date."""
    out = np.full(len(target_dates), np.nan)
    for i, td in enumerate(target_dates):
        # Look for matching year+quarter
        for d, v in df_col.iterrows():
            if d.year == td.year and ((d.month - 1) // 3) == ((td.month - 1) // 3):
                out[i] = float(v.iloc[0])
                break
    return out


def load_terms_of_trade():
    print("  Loading export/import deflators from abs_5206_ipd.xlsx...")
    px = load_ipd_series("A2303728F")  # Exports of goods and services
    pm = load_ipd_series("A2303729J")  # Imports of goods and services
    # px and pm are index values (typically 2021-22 = 100)
    px = px.rename(columns={"A2303728F": "px"})
    pm = pm.rename(columns={"A2303729J": "pm"})
    tot = px.join(pm, how="inner")
    tot["tot"] = tot["px"] / tot["pm"]
    tot["ln_tot"] = np.log(tot["tot"])
    tot["dln_tot"] = tot["ln_tot"].diff() * 100
    return tot


def load_population():
    print("  Loading working-age population from supply_data.mat...")
    d = loadmat(DYNARE / "supply_data.mat", squeeze_me=True, struct_as_record=False)
    pop = np.array(d["pop_bar"]).astype(float)
    # supply_data is quarterly starting 1990Q1; length 140 ⇒ 1990Q1 to 2024Q4
    ln_pop = np.log(pop)
    dln_pop = np.diff(ln_pop) * 100
    dln_pop = np.concatenate([[np.nan], dln_pop])
    # supply_data dates: 1990Q1..2024Q4 (140 quarters)
    pop_dates = [date(1990 + (i // 4), 1 + 3 * (i % 4), 1) for i in range(len(pop))]
    return pd.DataFrame({"date": pop_dates, "dln_pop": dln_pop}).set_index("date")


def load_real_housing_price():
    print("  Loading spliced housing prices and CPI...")
    # House price (real terms) — divide by CPI
    hp = pd.read_csv(DATA / "house_price_spliced.csv")
    hp["date"] = pd.to_datetime(hp.iloc[:, 0])
    hp_col = [c for c in hp.columns if "price" in c.lower() or "index" in c.lower()
              or c.lower() in ("au", "rppi", "ph", "value")]
    if not hp_col:
        hp_col = [hp.columns[1]]
    hp = hp.set_index("date")
    print(f"    Housing-price columns: {hp.columns.tolist()}")
    return hp


def load_cpi_quarterly():
    """Load AU CPI quarterly from dataset.csv (au_pi is qoq inflation)."""
    df = pd.read_csv(ROOT / "dataset.csv")
    df["date"] = pd.to_datetime(df["date"])
    # au_pi is q/q % inflation; build a log-CPI index by cumulating /100
    pi = df["au_pi"].fillna(0).values
    ln_cpi = np.cumsum(pi / 100)
    df["ln_cpi"] = ln_cpi
    return df.set_index("date")[["ln_cpi"]]


def build_channels():
    target_dates = quarter_dates(START, T_TARGET)

    # 1) Terms of trade
    tot = load_terms_of_trade()
    dln_tot = quarterly_align(tot[["dln_tot"]], target_dates)

    # 2) Population growth (working-age proxy via supply_data.pop_bar)
    pop = load_population()
    dln_pop = quarterly_align(pop[["dln_pop"]], target_dates)

    # 3) Real housing prices: dlog(spliced HP) - au_pi (CPI inflation qoq)
    hp = load_real_housing_price()
    # The first numeric column is the level
    val_col = [c for c in hp.columns if hp[c].dtype != "O"][0]
    hp = hp[[val_col]].rename(columns={val_col: "ph"})
    hp["ln_ph"] = np.log(hp["ph"].astype(float))
    hp["dln_ph"] = hp["ln_ph"].diff() * 100
    dln_ph_nom = quarterly_align(hp[["dln_ph"]], target_dates)

    cpi = load_cpi_quarterly()
    # au_pi is already a % qoq, so just align it
    df_base = pd.read_csv(ROOT / "dataset.csv")
    df_base["date"] = pd.to_datetime(df_base["date"])
    df_base = df_base.set_index("date")
    pi_au_aligned = quarterly_align(df_base[["au_pi"]], target_dates)

    dln_ph_real = dln_ph_nom - pi_au_aligned

    # Demean to enforce SS = 0
    def demean(x):
        m = np.nanmean(x)
        return x - m, m

    dln_tot_d, mean_tot = demean(dln_tot)
    dln_pop_d, mean_pop = demean(dln_pop)
    dln_ph_d, mean_ph = demean(dln_ph_real)

    print(f"  Demeaned: dln_tot mean removed = {mean_tot:+.4f} %")
    print(f"  Demeaned: dln_pop mean removed = {mean_pop:+.4f} %")
    print(f"  Demeaned: dln_ph  mean removed = {mean_ph:+.4f} %")

    return {
        "dates": target_dates,
        "dln_tot_obs": dln_tot_d,
        "dln_pop_obs": dln_pop_d,
        "dln_ph_obs": dln_ph_d,
        "_means": {"tot": mean_tot, "pop": mean_pop, "ph": mean_ph},
    }


def ols_coef(y, x):
    """Simple OLS y = a + b*x + u; return b, se, t."""
    valid = np.isfinite(y) & np.isfinite(x)
    yv = y[valid]; xv = x[valid]
    n = len(yv)
    X = np.column_stack([np.ones(n), xv])
    beta, *_ = np.linalg.lstsq(X, yv, rcond=None)
    resid = yv - X @ beta
    sigma2 = (resid @ resid) / (n - 2)
    se = np.sqrt(np.diag(sigma2 * np.linalg.inv(X.T @ X)))
    return float(beta[1]), float(se[1]), float(beta[1] / se[1]), n


def calibrate_channels(ch):
    """Regress each flagged smoothed shock on its candidate channel(s)."""
    print("\n=== Calibrating channels via OLS on smoothed shocks ===")
    mat = loadmat(DYNARE / "bayesian_mcmc_results.mat",
                  squeeze_me=True, struct_as_record=False)
    ss = mat["oo_"].SmoothedShocks
    shocks = {}
    for nm in ss._fieldnames:
        arr = np.atleast_1d(np.array(getattr(ss, nm))).ravel()
        shocks[nm] = arr[:T_TARGET]

    rows = []

    # eps_pQ → dln_tot
    b, se, t, n = ols_coef(shocks["eps_pQ"], ch["dln_tot_obs"])
    rows.append(("gamma_tot_pQ", "eps_pQ ~ dln_tot", b, se, t, n))

    # eps_ib → dln_tot (commodity-cycle for business investment)
    b, se, t, n = ols_coef(shocks["eps_ib"], ch["dln_tot_obs"])
    rows.append(("gamma_tot_ib", "eps_ib ~ dln_tot", b, se, t, n))

    # eps_ih → dln_pop
    b, se, t, n = ols_coef(shocks["eps_ih"], ch["dln_pop_obs"])
    rows.append(("gamma_pop_ih", "eps_ih ~ dln_pop", b, se, t, n))

    # eps_c → dln_ph_real
    b, se, t, n = ols_coef(shocks["eps_c"], ch["dln_ph_obs"])
    rows.append(("gamma_ph_c", "eps_c ~ dln_ph_real", b, se, t, n))

    print(f"{'param':<15} {'regression':<25} {'beta':>10} {'se':>8} {'t':>6} {'n':>4}")
    print("-" * 75)
    for name, lbl, b, se, t, n in rows:
        print(f"{name:<15} {lbl:<25} {b:>+10.4f} {se:>8.4f} {t:>+6.2f} {n:>4}")

    return {r[0]: r[2] for r in rows}, rows


def write_mat(ch, calib):
    out = {
        "dln_tot_obs": np.asarray(ch["dln_tot_obs"]),
        "dln_pop_obs": np.asarray(ch["dln_pop_obs"]),
        "dln_ph_obs": np.asarray(ch["dln_ph_obs"]),
        "mean_dln_tot_raw": ch["_means"]["tot"],
        "mean_dln_pop_raw": ch["_means"]["pop"],
        "mean_dln_ph_raw": ch["_means"]["ph"],
    }
    for k, v in calib.items():
        out[k] = float(v)
    savemat(DYNARE / "channel_data.mat", out)
    print(f"\nSaved channel_data.mat (3 obs series + 4 calibrated gammas)")


def main():
    print("=== Build trend channels (TOT, population, real housing prices) ===")
    ch = build_channels()
    print("\n=== Channel summary ===")
    for nm in ("dln_tot_obs", "dln_pop_obs", "dln_ph_obs"):
        a = np.asarray(ch[nm], dtype=float)
        v = a[np.isfinite(a)]
        print(f"  {nm:<14} n={len(v):3d}  mean={v.mean():+.4f}  std={v.std():.4f}")
    calib, _ = calibrate_channels(ch)
    write_mat(ch, calib)
    print("\nNext: edit prepare_bayesian_data.m to load these obs.")


if __name__ == "__main__":
    main()
