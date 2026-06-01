# PAC design infrastructure: gap-form vs levels+`growth=` (AU-PAC)

*Reference / design-rationale note, written 2026-06-01. Captures why AU-PAC writes its PAC equations in **stationary-gap
space** (no `growth=`) rather than the **trending-levels + `growth=`** form used by FR-BDF/ECB-BASE and Srecko Zimic's
`SemiStructDynareBasics`. Pairs with the **PAC-tooling roadmap** section in [`../next_session.md`](../next_session.md)
and the `project_dynare_pac_upgrades` / `project_industry_split` memory notes. Line anchors are to `dynare/au_pac.mod`
and `dynare/aux/aux_*.mod` as of this date — verify against the live file, the model evolves.*

---

## 1. The two ways to write a PAC equation

A PAC (polynomial/partial adjustment cost) block says: the variable adjusts gradually toward a target, and because
adjustment is costly the agent is forward-looking — it aims at **where the target is going**, not just where it is now.
The forward-looking piece (`pac_expectation`) is a discounted sum of expected **future changes in the target**:

$$\text{pac\_expectation}_t \;\approx\; \sum_{k\ge 0}\chi^k\,\mathbb{E}_t\!\big[\Delta(\text{target})_{t+k}\big],\qquad \chi=\text{PAC discount root},\ \beta_{pac}=0.98$$

There are two ways to specify the target, and they differ **only** in how the trend is handled:

| | **Levels + `growth=`** (FR-BDF/ECB-BASE/Srecko) | **Gap** (AU-PAC) |
|---|---|---|
| PAC equation on | the **level** (e.g. `log C`) | the **detrended gap** (e.g. `ln_c_level`) |
| Target | a **trending** level `c*` | a **mean-zero** stationary gap target (`c_hat`) |
| Trend handled | **inside** the PAC, via the `growth=` term | **outside** the PAC, by a separate `*_star` accumulator |
| Dynare object | `trend_component_model` + `pac_model(..., growth=…)` | `var_model` + `pac_model(..., discount=…)` (no `growth=`) |
| Dynare `kind` | `'dl'` (difference-level) — carries the `lrcp` growth term | `'ll'` (level-level) — `lrcp = NaN`, **no growth term exists** |

**`growth=` is the growth-neutrality correction.** If the target trends up at rate `g` forever, then
`E[Δtarget]≈g` every period and the discounted sum picks up a constant `≈ g/(1−χ)`. `growth=` supplies that `g`. Omit it
on a trending target and the agent behaves as if the target were flat → it under-shoots a rising target → the variable
**drifts persistently below** where it should be. On a **stationary** (mean-zero) target there is no trend to anticipate,
so `growth=` multiplies nothing and is correctly omitted. (FR-BDF, wp1044 §3.5.1: *"the non-stationary component of
expectations is zero for expectations of gap terms."*)

In Dynare 7.0 the `kind` is **auto-inferred** from the target (`+pac/+update/parameters.m:144-152`); a stationary
`var_model` target → `kind='ll'` → `hVectors.m:66` returns `lrcp=NaN` (the growth term is absent by construction).
**Never pass `kind=dd` explicitly on AU-PAC's existing blocks** — it would silently corrupt every h-vector.

## 2. AU-PAC's gap formulation — there IS a level target, it's just decomposed

"Gap form" does **not** mean "no target." Each block carries a level target; it is split into a **trend** plus a
**stationary gap**, reassembled for reporting. Consumption (`dynare/au_pac.mod`):

```
ln_C        = ln_C_star + ln_c_level                                  (:1268)  reported level = trend + gap
ln_C_star   = ln_C_star(-1) + dln_c_star_bar                          (:1265)  the TREND accumulator
ln_c_level  = b0_c·(c_hat(-1) − ln_c_level(-1)) + b1_c·… + pac_expectation_pac_c
              + b_PAC_c·dy_bar_gap(-1) + …                            (:1053)  the GAP, PAC-driven
c_hat       = rho_c_aux·c_hat(-1) + a_c_y·yhat_au(-1) + …             (:1073)  gap target (mean-zero AR(1))
dln_c_star_bar = kappa_inc·(pv_yh − pv_yh(-1)) + …                    (:1391)  trend growth, driven by permanent income
```

So there are two targets: a **trend target** `ln_C_star` (the long-run path) and a **cyclical target** `c_hat` (where
consumption sits relative to trend, given the cycle). The PAC error-corrects the gap `ln_c_level` toward `c_hat`; the
implied full level target is `ln_C* = ln_C_star + c_hat`. It exists — it is just never written as one trending object.

**The forward-trend anticipation is relocated, not dropped.** In a levels+`growth=` block the "expect the target to keep
rising" effect lives in `growth=`. In AU-PAC it lives in **`pv_yh`** (permanent income — itself a forward-looking
discounted sum, one of the model's 5 Blanchard-Kahn jumpers), which drives the trend `dln_c_star_bar`. So future-growth
anticipation runs through the permanent-income channel instead of a PAC growth term — arguably the more structural place
for it (it is literally the permanent-income hypothesis).

**Empirically verified stationary** (the IRF gap check, 2026-06-01): every PAC gap (`ln_c_level`, `ln_ib_level`,
`ln_ih_level`, `ln_n_level`) reverts to ≈0 at Q200 for all shocks — worst `|Q200|/|peak| = 3.9e-04` — and the
decomposition `ln_C = ln_C_star + ln_c_level` holds to ~1e-20. Stationary target ⇒ omitting `growth=` is correct.

## 3. Per-block picture — consumption is aligned, housing is a real departure

FR-BDF itself **mixes** per block: gap-form where the target is a gap, levels+`growth=` where it trends. AU-PAC went
all-gaps. That makes AU-PAC fully **aligned** with FR-BDF on some blocks and a genuine **departure** on others.

| Block | Target trends? | FR-BDF choice | AU-PAC gap form is… | Trend driver in AU-PAC |
|---|---|---|---|---|
| Consumption | no | **gap** (eq 35, §3.5.1) | **aligned** | `pv_yh` (the right driver — PIH) |
| Employment / VA-price | no (gaps) | gap | aligned | — |
| Business inv | gap; FOC rejected on AU data anyway | gap | aligned (calibrated block) | — |
| **Housing inv** | **yes** (volume trends for decades) | **levels + `growth=`** (eq 37, §3.5.2) | **a departure** | `pv_yh` only (a *proxy*) |
| **Mining (planned)** | yes (capacity) | n/a | **not a PAC at all** | backward capacity identity |

**Consumption** = "the same model written differently." FR-BDF also uses gap-form for consumption, and AU-PAC's trend
driver (`pv_yh`) is the economically correct one. No fidelity loss.

**Housing investment** = the sharp case. Same decomposition shape (`ln_IH = ln_IH_star + ln_ih_level`, `:1280`; PAC
error-corrects the gap toward the mean-zero `ih_hat`, `:1095`), but:
- housing investment **volume genuinely trends**, so FR-BDF eq 37 uses the levels+`growth=` form — AU-PAC's gap choice
  here **departs** from FR-BDF;
- AU-PAC's housing trend `dln_ih_star_bar` (`:~1410`) is, with `lambda_hyst=0`, driven by **permanent income alone**
  (`kappa_ih_inc·Δpv_yh`); the mortgage-rate and house-price (Tobin's-Q) channels are **gated off**, and the housing PAC
  has **no growth-neutrality term at all**;
- the whole `ln_IH_star`/`ln_IH` chain is **reporting-only** (`ln_IH` feeds no dynamics; the economic flow is the gap
  change `dln_ih` → `yhat_dom`).

**What that costs:** a levels+`growth=` housing block would let builders **forward-anticipate a changing desired dwelling
stock** (e.g. a migration-driven acceleration in housing demand) inside the investment decision. AU-PAC's gap form
**mutes** that channel — housing investment cyclically mean-reverts around an income trend but does not forward-respond to
a shift in the *trend growth rate*. For Australia (migration / housing-supply policy) that is a non-trivial limitation,
and it is why housing — not consumption — is the prime candidate for an eventual levels+`growth=` migration.

## 4. Why AU-PAC chose gaps, and the cost

**Why gaps (the binding reason): AU data does not cointegrate cleanly in levels.** The same pathology that forced the CES
σ onto a first-difference/Bayesian fallback (labour-FOC level DW=0.32, no cointegration), the flat Phillips curve, the
business-inv FOC robust rejection (R²=0.09), and the mining-boom structural breaks all mean a *trending level target the
data error-corrects toward* is fragile. Detrend-first (HP/structural trend → `ln_*_star`) and run the PAC on a clean
stationary gap is the robust route. Secondary reasons: the E-SAT belief-`var_model` is a stationary gap VAR (the PV
operator `(I−χΦ)⁻¹χΦ` needs a stationary companion Φ); and the `lambda_hyst=0` long-run-neutrality design wants gaps that
revert to 0 with the trend carried separately.

**The cost (honest):** AU-PAC relaxes FR-BDF's **derived** growth-neutrality coefficient into a **freely-estimated**
`b_PAC_c·dy_bar_gap(-1)` stand-in (and in production `dy_bar_gap` is a random walk around 0, so it is near-inert); and it
imposes a two-step trend–cycle split (detrend, then PAC) that is less internally consistent than FR-BDF's endogenous
levels cointegration. For cyclical IRFs / monetary transmission the two are essentially equivalent (gaps revert cleanly);
the difference bites only when trend growth itself shifts and you would want agents to forward-anticipate it inside the
behavioural equation — which is exactly the housing case above.

## 5. Verdict / roadmap

Per the PAC-tooling scoping (see [`../next_session.md`](../next_session.md) → "PAC-tooling roadmap" and the
`project_dynare_pac_upgrades` memory): **keep gap-form for the five existing blocks** (correct, `kind='ll'`, no benefit
to migrating); **mining stays a no-PAC backward capacity identity** (no FOC, no cointegration); **housing levels+`growth=`
is DEFERRED to a synthetic-data pilot only** (economically the right place, but AU's house-price-spread term is
insignificant/wrong-signed, so a live migration would trade a working gap ECM for fragile level cointegration). If the
levels+`growth=` machinery is ever exercised, do it on synthetic data first via `trend_component_model` + `kind='dl'`;
the `hVectors.m` level-equation bug Brayton flagged on the Dynare forum **is** fixed in 7.0 (the `kind` switch,
`hVectors.m:54-72`), so the tooling is safe — the AU **data** is the binding constraint, not Dynare.

### Key anchors
- Consumption: `au_pac.mod:1053` (PAC SR), `:1073` (`c_hat`), `:1265,1268` (`ln_C_star`/`ln_C`), `:1391` (`dln_c_star_bar`).
- Housing: `au_pac.mod` `ln_ih_level` PAC SR, `:1095` (`ih_hat`), `:1277,1280` (`ln_IH_star`/`ln_IH`), `:~1410` (`dln_ih_star_bar`, reporting-only).
- Aux (`var_model` + `pac_model`, no `growth=`): `dynare/aux/aux_{consumption:82,93, housing_inv:69,78, pQ, employment, business_inv}.mod`.
- Dynare 7.0: `kind` inference `+pac/+update/parameters.m:144-152`; `hVectors.m:66` (`lrcp=NaN` for `'ll'`), `:54-72` (the `kind` switch / Brayton fix).
- Verification: `dynare/verify_pac_chi_pv.m` (PV operator); the 2026-06-01 gap-reversion IRF check (gaps → ≈0 at Q200).
- Sources: FR-BDF wp1044 §3.5.1 (eq 35, consumption gap-form) / §3.5.2 (eq 37, housing levels+growth=) in `../references/FR-BDF-update.pdf`; Srecko Zimic `SemiStructDynareBasics` `consumption.mod:48,51` (`trend_component_model` + `growth=`); Dynare forum "Semi-structural models in Dynare" (Brayton/Pfeifer/Adjemian).
