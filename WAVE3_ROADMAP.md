# WAVE3_ROADMAP.md — new-scope blocks vs the updated (wp1044) goal

Status as of 2026-05-31. Waves 0/1/2/4 executed; Wave 3 partially executed after RBA data
became downloadable (RBA CSV `tables/csv/<t>-data.csv` pattern works; ABS landing pages do not).

**DONE (2026-05-31, this branch):**
- **§3.2 Household credit/DSR block — IMPLEMENTED.** DSR built from RBA E2 (BHFDDIT) × RBA F5
  mortgage rate; new `DSR_gap` AR(1) state + Δ-form drag into `eq_dln_c_star_bar`. rho_DSR=0.864
  (t=21), alpha_DSR=−0.10 (insig, right-signed). BK-stable. (commit "wave3: ... DSR block")
- **§3.3 NFC accelerator — spread persistences estimated.** rho_LB_firms=0.80, rho_BBB=0.76 from
  RBA F3 corporate spreads, written back. kappa_spread NOT written (AU sign wrong/insig — spreads
  globally driven; documented). Leverage-based version still the follow-up below.
- **Deferred §rho_lh — DONE.** 0.97→0.9133 from RBA F5 FILRHLBVS (constrained model form).

**REMAINING (genuinely blocked):**
- **§3.4 energy split / §3.5 HICP behavioural** — blocked on an AU oil/gas price series: RBA I02 has
  only rural/non-rural/base-metals (no energy sub-index) and ABS 6457 needs a fragile versioned xlsx
  URL (the landing page returns HTML). Path: ABS 6457 petroleum sub-index, or Brent-in-AUD (global
  oil × RBA F11 USD). No energy-split import volume/price data to estimate the block either.
- **§3.1 quasi-endogenous anchors** — research-grade structural change that alters the VAR companion
  matrix (hence `h_pac`); must not be implemented blind against BK. Needs the precise wp1044 §3.4.3/
  §3.5.3 spec + careful h_pac regen + BK validation.

The items below are specified enough to execute directly.

---

## 3.1 Quasi-endogenous employment / investment anchors (wp1044 §3.4.3, §3.5.3)

**Why.** wp1044 diagnoses the same over-dampening AUSPAC's [[project-rounds-4-to-8]] note
flags ("firms neutral to the conjuncture; Round 4–8 blocks not yet rationally consistent
under the PAC policy function"). Its fix replaces the *exogenous* trend targets `n*_S`,
`I*_B` with **quasi-endogenous** anchors that respond partially to the output/profit gap.

**Current state.** The trend equations already carry partial conjuncture terms:
`dln_n_star_bar` has `(yhat_au − yhat_au(−1))`; `dln_ib_star_bar` had `kappa_ib_y·yhat_au`
(now gated by `lambda_hyst=0` for the reporting trend, Wave 1). The aux-VAR target
projections (`n_hat`, `ib_hat`) are the objects the PAC expectation actually uses.

**No new data needed** — this is structural. **Implementation:**
1. In `aux/aux_employment.mod` / `aux/aux_business_inv.mod`, add a quasi-endogenous loading
   of the target's *trend* component on a slow-moving conjuncture state (per wp1044 §3.4.3:
   the long-run employment target loads on the capital/activity trend, not a fixed line).
2. Expand the block `var_model` state vector accordingly and re-run `pac.print()` (the
   workflow is proven — see `dynare/check_bk.m` / the Wave-1 h_pac re-verification; aux runs
   from `dynare/aux/` via `dynare aux_<block>.mod`).
3. Write the regenerated `h_pac_<block>_*` vectors into `au_pac.mod`, re-solve, confirm BK
   with `check_bk.m`, and check the IRFs aren't over/under-amplified.

**Risk.** Medium-high: changes the VAR companion matrix → changes `h_pac` (unlike the
b0/b1 ECM speeds, which Wave 1 proved leave `h_pac` invariant). Validate BK + IRFs carefully.

---

## 3.2 Household credit + Debt-Service-Ratio block (wp1044 §3.7.2) — NEW vs wp736

**Why.** The largest omission vs the *updated* goal: AUSPAC has no household-credit stock,
no DSR, and no credit→consumption/housing channel. This is the macro-financial core of the
wp1044 update.

**Equations (wp1044 §3.7.2):** mortgage-debt stock ECM toward a target driven by housing
wealth and income; DSR = debt·interest / disposable income; DSR feeds the consumption and
housing-investment PAC equations as an additional drag.

**AU data (downloadable, not yet in repo):**
- Household debt / credit: **RBA D2** (credit aggregates) or **RBA E2** (household finances —
  debt, assets, DSR is published directly as the *household debt-servicing ratio*).
- Disposable income: ABS 5206 Table 20 (already used for `wt_H_real_gap`).
- Mortgage rate `i_lh`: model already has it (needs `rho_lh` from RBA F6 — see Wave 2 deferred).

**Implementation:** add `debt_h`, `DSR` endogenous + their ECM/identity equations; wire
`−κ_DSR·DSR_gap` into `eq_dln_c_star_bar` and `eq_dln_ih_star_bar`; add `eps_debt`. Calibrate
κ from wp1044 then re-estimate the consumption/housing PAC with the DSR regressor.

**Effort:** ~1 week incl. data build. **Blocker:** download + quarterly-align RBA E2/D2.

---

## 3.3 NFC financial accelerator (wp1044 §3.7.3) — PARTIALLY present

**Why.** Firm leverage → credit spread → user cost → investment. wp1044 makes the corporate
spread respond to leverage.

**Current state.** Already partly implemented: `s_LB_firms` and `s_BBB` respond to the output
gap as a *leverage proxy* (`kappa_spread_LB·yhat_au`, `kappa_spread_BBB·yhat_au`,
au_pac.mod ~1357–1363). So the accelerator *direction* is in the model; what's missing is a
genuine **leverage state** (debt/equity) driving the spread instead of the output-gap proxy.

**AU data:** RBA business credit (D2), ABS 5204 corporate balance sheets, or RBA corporate
bond spread series (RBA F3). **Implementation:** add `lev_nfc` state (AR or ECM on
business-credit/GVA), replace `kappa_spread_*·yhat_au` with `kappa_spread_*·lev_nfc_gap`,
estimate `kappa_spread` on the AU spread series. **Effort:** ~3–4 days. **Blocker:** corporate
spread series.

---

## 3.4 Energy split — oil + gas synthetic index (wp1044 §3.6.4 / Appx E) — PARTIALLY present

**Why.** wp1044 separates an oil+gas energy price index feeding CPI and the import deflator.

**Current state.** AUSPAC already has (i) `dln_pcom` (RBA I02 commodity index) feeding CPI via
`gamma_oil` (now AU-estimated, Wave 2: −0.0147, insig), and (ii) an energy/non-energy import
split (`pi_m_e`/`pi_m_ne`, `eps_pm_e`) with the energy block kept at wp1044 calibration. What's
missing is a *separate AU oil/gas index* (vs the broad commodity index) and AU estimation of
the energy-import block.

**AU data:** ABS 6427 (import price index by SITC — includes petroleum) or global Brent/TTF
priced in AUD via RBA F11. **Implementation:** build `dln_penergy` from ABS 6427 petroleum +
gas sub-indices; replace the broad `dln_pcom` in the energy-import block with it; estimate
`beta_m_e`/`gamma_m_e`. **Effort:** ~2–3 days. **Blocker:** ABS 6427 download + SITC parse.

---

## 3.5 HICP behavioural component equations (wp1044 §3.6.4)

**Current state.** AUSPAC's HICP-style decomposition (`pi_au_food`, `_energy`, `_core`, …) is a
one-way *reporting* identity (zero feedback). wp1044 models the food/energy components
behaviourally (food → ag prices; energy → the energy index above).

**Implementation:** promote the food/energy reporting variables to behavioural equations
(food on ABS food CPI + ag prices; energy on `dln_penergy` from §3.4); let them feed back into
`pi_au` via the existing aggregation weights. **Effort:** ~2 days, gated on §3.4 energy index.

---

## Deferred Wave-2 items (data-blocked single parameters)

- **`rho_lh`** (mortgage smoothing): needs an AU housing-lending-rate series (RBA F6; the repo's
  F16 is stale govt-bond mid-rates). Then AR(1) on `i_lh = ρ_lh·i_lh(−1) + (1−ρ_lh)·(i_10y+spread)`.
- **`rho_s`** (real-exchange-rate gap): the `s_gap` equation has a forward UIP term (`pv_i_uip`),
  so a bare AR(1) is misspecified; needs joint/IV estimation. TWI is available (RBA F11).
- **Trade long-run elasticities** (`beta_x/gamma_x/beta_m_ne/...`): AU OLS gives wrong-signed /
  insignificant values (composition: mining vs non-mining). Either the resource/non-resource
  export split (`NEXT_PROJECT_export_resource_split.md`) or accept as a documented permanent
  calibration exception.
- **3 shock std devs** (`eps_q_us`, `eps_pi_us`, `eps_pQ`, marked "(not estimated)"): foreign-VAR /
  VA residuals; no effect on the deterministic IRFs. Replace with OLS residual stds when convenient.
