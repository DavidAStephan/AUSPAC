[name='i_au']
i_au = i_gap + ibar;

[name='def_di_gap']
di_gap = i_gap - i_gap(-1);

[name='pi_au']
pi_au = pi_au_gap + pibar_au;

[name='def_pi_w_gap']
pi_w_gap = pi_w - pibar_au;

[name='pi_us']
pi_us = pi_us_gap + pibar_us;

[name='eq_au_is']
yhat_au = delta * yhat_us + lambda_q * yhat_au(-1) - sigma_q * (i_gap(-1) - pi_au_gap(-1)) + lambda_dom * yhat_dom + eps_q;

[name='eq_taylor']
i_gap = lambda_i * i_gap(-1) + (1 - lambda_i) * (alpha_i * pi_au_gap(-1) + beta_i * yhat_au(-1)) + eps_i;

[name='eq_au_phillips']
// Phase V: FR-BDF wp736 eq (80) ECM rewrite. Now combines the original
// Phillips slack term with the FR-BDF structural deflator form:
//   pi_C = (1-β0-β1)·π̄_Q + β0·π_Q + β1·π_Q(-1) + β2·Δ(P_MNRJ/P̄)
//        + β3·(p_C(-1) - p*_C(-1)) + ε
// In AU-PAC gap form this becomes pi_au_gap regressed on lagged gap (lambda_pi),
// slack (kappa_pi · yhat), contemporaneous + lagged VA-price gaps (alpha_pc + alpha_pc_lag),
// contemporaneous import-price gap (beta_pc_m), commodity (gamma_oil), and the
// ECM term anchoring cumulative log CPI to the weighted average of cumulative
// log VA-price + log import-price (target = (1-omega_pc)·pQ_level + omega_pc·p_M_level).
pi_au_gap = lambda_pi * pi_au_gap(-1) + kappa_pi * yhat_au(-1)
          + alpha_pc * (piQ - pibar_au) + alpha_pc_lag * (piQ(-1) - pibar_au(-1))
          + beta_pc_m * (pi_m - pibar_au) + gamma_oil * dln_pcom
          + b_ECM_pc * (p_C_star_level(-1) - p_C_level(-1))
          + eps_pi;

[name='def_p_C_level']
p_C_level = p_C_level(-1) + pi_au_gap;

[name='def_p_M_level']
p_M_level = p_M_level(-1) + (pi_m - pibar_au);

[name='def_p_C_star_level']
p_C_star_level = (1 - omega_pc) * pQ_level + omega_pc * p_M_level;

[name='eq_us_is']
yhat_us = lambda_q_us * yhat_us(-1) + eps_q_us;

[name='eq_us_phillips']
pi_us_gap = lambda_pi_us * pi_us_gap(-1) + kappa_pi_us * yhat_us(-1) + eps_pi_us;

[name='eq_ibar']
ibar = lambda_ibar * ibar(-1) + (1 - lambda_ibar) * i_ss + eps_ibar;

[name='eq_pibar_au']
// Round 1.3 (Cogley-Sbordone time-varying anchor) tested 2026-05-18 and
// REJECTED: Laplace LMD worsened by 1.88 nats (-779.30 → -781.18) on a
// fresh csminwel mode search. delta_pibar posterior mode pulled to 0.024
// (well below prior mean 0.07); the extra parameter cost exceeded the
// tiny likelihood gain. AU data prefers the simple AR(1) anchor.
pibar_au = lambda_pibar * pibar_au(-1) + (1 - lambda_pibar) * pi_ss_au + eps_pibar_au;

[name='eq_pibar_us']
pibar_us = lambda_pibar_us * pibar_us(-1) + (1 - lambda_pibar_us) * pi_ss_us + eps_pibar_us;

[name='eq_piQ_from_level']
piQ = (pQ_level - pQ_level(-1)) + pi_ss_au;

[name='eq_dln_c_from_level']
dln_c = ln_c_level - ln_c_level(-1);

[name='eq_dln_ib_from_level']
dln_ib = ln_ib_level - ln_ib_level(-1);

[name='eq_dln_ih_from_level']
dln_ih = ln_ih_level - ln_ih_level(-1);

[name='eq_dln_n_from_level']
dln_n = ln_n_level - ln_n_level(-1);

[name='eq_dln_k']
dln_k = (1 - delta_k) * dln_k(-1) + delta_k * dln_ib;

[name='eq_ln_QN']
ln_QN = ln_QN(-1) + dln_y_star;

[name='eq_ln_Q']
ln_Q = ln_QN + yhat_au;

[name='eq_ln_C_star']
// Option α (2026-05-23): subtract trend g_bar_C so ln_C_star tracks the
// CYCLICAL deviation of the LR target around the trend (stationary). The
// trend itself is carried by dln_c_star_bar's non-zero SS, and reaches the
// observable via dln_C_obs = dln_c + dln_c_star_bar.
ln_C_star = ln_C_star(-1) + (dln_c_star_bar - g_bar_C);

[name='eq_ln_C']
ln_C = ln_C_star + ln_c_level;

// Option α (2026-05-23): total consumption growth = trend + cycle.
// Defined directly as cycle + trend (rather than diff(ln_C)) to avoid the
// non-stationarity of ln_C interfering with Dynare's SS check.
// SS = g_bar_C; matched directly to (non-demeaned) observed dln_c data.
[name='eq_dln_C_obs']
dln_C_obs = dln_c + dln_c_star_bar;

[name='eq_ln_IB_star']
// Option α (2026-05-23): same treatment as ln_C_star.
ln_IB_star = ln_IB_star(-1) + (dln_ib_star_bar - g_bar_IB);

[name='eq_ln_IB']
ln_IB = ln_IB_star + ln_ib_level;

// Option α (2026-05-23): total investment growth = trend + cycle.
[name='eq_dln_IB_obs']
dln_IB_obs = dln_ib + dln_ib_star_bar;

[name='eq_ln_IH_star']
ln_IH_star = ln_IH_star(-1) + dln_ih_star_bar;

[name='eq_ln_IH']
ln_IH = ln_IH_star + ln_ih_level;

[name='eq_ln_N_star']
ln_N_star = ln_N_star(-1) + dln_n_star_bar;

[name='eq_ln_N']
ln_N = ln_N_star + ln_n_level;

[name='eq_ln_K']
ln_K = ln_K(-1) + dln_k;

[name='eq_ln_P_star']
ln_P_star = ln_P_star(-1) + (pibar_au - pi_ss_au);

[name='eq_ln_P']
ln_P = ln_P_star + pQ_level;

[name='eq_dln_y_star']
dln_y_star = alpha_k * dln_k + (1 - alpha_k) * dln_n_star_bar + dln_tfp;

[name='eq_ln_tfp_LR']
// (Drift was considered here but reverted — gap-form SS pins ln_tfp_LR=0.
// See Option α comments in eq_dln_c_star_bar / eq_dln_ib_star_bar; pi_w
// trend mismatch is a known limitation to fix in Option β.)
ln_tfp_LR = ln_tfp_LR(-1) + eps_tfp_LR;

[name='eq_ln_tfp']
ln_tfp = rho_tfp * ln_tfp(-1) + (1 - rho_tfp) * ln_tfp_LR;

[name='eq_dln_tfp']
dln_tfp = ln_tfp - ln_tfp(-1);

[name='eq_dln_prod']
dln_prod = dln_tfp / (1 - alpha_k);

[name='eq_dln_ulc']
dln_ulc = pi_w - dln_prod;

[name='eq_pv_piQ_aux']
pv_piQ_aux = rho_pQ_aux * pv_piQ_aux(-1) + a_pQ_y * yhat_au(-1) + a_pQ_i * i_gap(-1) + a_pQ_pi * pi_au_gap(-1) + a_pQ_u * u_gap(-1) + a_pQ_w * pi_w_gap(-1);

[name='eq_pv_n_aux']
pv_n_aux = rho_n_aux * pv_n_aux(-1) + a_n_y * yhat_au(-1) + a_n_i * i_gap(-1) + a_n_pi * pi_au_gap(-1) + a_n_u * u_gap(-1);

[name='eq_pv_c_aux']
pv_c_aux = rho_c_aux * pv_c_aux(-1) + a_c_y * yhat_au(-1) + a_c_i * i_gap(-1) + a_c_pi * pi_au_gap(-1) + a_c_u * u_gap(-1);

[name='eq_pv_ib_aux']
pv_ib_aux = rho_ib_aux * pv_ib_aux(-1) + a_ib_y * yhat_au(-1) + a_ib_pi * pi_au_gap(-1) + a_ib_u * u_gap(-1);

[name='eq_pv_rKB_aux']
pv_rKB_aux = rho_rKB_aux * pv_rKB_aux(-1) + a_rKB_i * i_gap(-1);

[name='eq_pv_ih_aux']
pv_ih_aux = rho_ih_aux * pv_ih_aux(-1) + a_ih_y * yhat_au(-1) + a_ih_i * i_gap(-1) + a_ih_pi * pi_au_gap(-1) + a_ih_u * u_gap(-1);

[name='eq_u_gap']
u_gap = rho_u_gap * u_gap(-1) + okun_coeff * yhat_au;

[name='eq_pv_u_gap']
pv_u_gap = (1 - beta_w) * u_gap + beta_w * pv_u_gap(+1);

[name='eq_pi_w']
pi_w = lambda_w * pi_w(-1) + gamma_w * pi_c - kappa_w * pv_u_gap + (1 - lambda_w - gamma_w) * pibar_au + (1 - lambda_w) * dln_prod + eps_w;

[name='eq_dln_n_star']
dln_n_star = rho_n_star * dln_n_star(-1) + (1 - rho_n_star) * dln_n_star_bar;

[name='eq_dln_n_star_bar']
// Round 5 (2026-05-20): + dln_pop_bar shifter — population trend gap feeds
// long-run employment growth one-for-one (constant employment-to-population
// ratio at trend).
dln_n_star_bar = (yhat_au - yhat_au(-1)) - dln_tfp / (1 - alpha_k) - sigma_ces * rw_gap + dln_pop_bar;

[name='eq_n_gap']
n_gap = n_gap(-1) + dln_n_star - dln_n;

[name='eq_dln_n_1']
dln_n_1 = dln_n(-1);

[name='eq_dln_n_2']
dln_n_2 = dln_n_1(-1);

[name='eq_dln_n_3']
dln_n_3 = dln_n_2(-1);

[name='eq_dln_c_star']
dln_c_star = rho_c_star * dln_c_star(-1) + (1 - rho_c_star) * dln_c_star_bar;

[name='eq_pv_yh']
pv_yh = (1 - beta_c) * yhat_au + beta_c * pv_yh(+1);

[name='eq_pv_r_lh_gap']
pv_r_lh_gap = (1 - beta_c) * (i_lh - pi_c - (i_ss + tp_ss + spread_lh - pi_ss_au)) + beta_c * pv_r_lh_gap(+1);

[name='eq_dln_c_star_bar']
// Round 6 (2026-05-20): - alpha_PAYG · Δtau_PAYG_gap — personal income tax change drags consumption growth.
// Option α (2026-05-23): + g_bar_C drift carries the BGP trend in the LR target,
// so ln_C_star grows at the structural BGP rate at SS.
dln_c_star_bar = g_bar_C + kappa_inc * (pv_yh - pv_yh(-1)) + alpha_c_r * ((i_lh - pi_c - (i_ss + tp_ss + spread_lh - pi_ss_au)) - (i_lh(-1) - pi_c(-1) - (i_ss + tp_ss + spread_lh - pi_ss_au))) - alpha_PAYG * (tau_PAYG_gap - tau_PAYG_gap(-1));

[name='eq_c_gap']
// Option α (2026-05-23): subtract trend dln_c_star_bar so c_gap accumulates the
// CYCLICAL deviation only and remains stationary at SS (was drifting upward
// at rate g_bar_C once dln_c_star_bar got non-zero SS).
c_gap = c_gap(-1) + (dln_c_star - dln_c_star_bar) - dln_c;

[name='eq_dln_ib_star']
dln_ib_star = rho_ib_star * dln_ib_star(-1) + (1 - rho_ib_star) * dln_ib_star_bar;

[name='eq_uc_k']
// Round 6 (2026-05-20): + alpha_CIT · tau_CIT_gap — corporate income tax shifts user cost of capital.
uc_k = wacc + delta_k - (pi_ib - piQ) + alpha_CIT * tau_CIT_gap;

[name='eq_dln_uc_k']
dln_uc_k = uc_k - uc_k(-1);

[name='eq_dln_ib_star_bar']
// Option α (2026-05-23): + g_bar_IB drift carries the BGP trend (investment
// grows at output rate on BGP, so g_bar_IB = g_bar_C).
dln_ib_star_bar = g_bar_IB + kappa_ib_y * yhat_au - sigma_ces * dln_uc_k;

[name='eq_ib_gap']
// Option α (2026-05-23): same fix as c_gap — subtract trend.
ib_gap = ib_gap(-1) + (dln_ib_star - dln_ib_star_bar) - dln_ib;

[name='eq_dln_ib_1']
dln_ib_1 = dln_ib(-1);

[name='eq_dln_ih_star']
dln_ih_star = rho_ih_star * dln_ih_star(-1) + (1 - rho_ih_star) * dln_ih_star_bar;

[name='eq_dln_ih_star_bar']
dln_ih_star_bar = kappa_ih_inc * (pv_yh - pv_yh(-1)) - kappa_mort * (i_lh - (i_ss + tp_ss + spread_lh)) + kappa_ph * ph_gap(-1);

[name='eq_ih_gap']
ih_gap = ih_gap(-1) + dln_ih_star - dln_ih;

[name='eq_dln_ih_1']
dln_ih_1 = dln_ih(-1);

[name='eq_term_premium']
tp = rho_tp * tp(-1) + (1 - rho_tp) * tp_ss + eps_tp;

[name='eq_pv_i']
pv_i = (1 - kappa_10) * i_au + kappa_10 * pv_i(+1);

[name='eq_i_10y']
i_10y = pv_i + tp + eps_10y;

[name='eq_s_COE']
s_COE = (1 - rho_COE) * s_COE_ss + rho_COE * s_COE(-1) + eps_COE;

[name='eq_s_LB_firms']
s_LB_firms = (1 - rho_LB_firms) * s_LB_firms_ss + rho_LB_firms * s_LB_firms(-1) + eps_LB_firms;

[name='eq_s_BBB']
s_BBB = (1 - rho_BBB) * s_BBB_ss + rho_BBB * s_BBB(-1) + eps_BBB;

[name='eq_i_COE']
i_COE = i_10y + s_COE;

[name='eq_i_LB_firms']
i_LB_firms = i_10y + s_LB_firms;

[name='eq_i_BBB']
i_BBB = i_10y + s_BBB;

[name='eq_wacc']
wacc = w_COE * i_COE + w_LB_firms * i_LB_firms + w_BBB * i_BBB;

[name='eq_pv_i_uip']
pv_i_uip = (i_au - ibar) + beta_uip * pv_i_uip(+1);

[name='eq_s_gap']
s_gap = rho_s * s_gap(-1) - alpha_s * pv_i_uip + alpha_s * (pi_au_gap - pi_us_gap) + eps_s;

[name='eq_ln_x_level']
ln_x_level = ln_x_level(-1) + dln_x;

[name='eq_ln_m_level']
ln_m_level = ln_m_level(-1) + dln_m;

[name='eq_ln_d_iad']
ln_d_iad = ln_d_iad(-1) + iad;

[name='eq_ln_x_eq']
ln_x_eq = beta_x * yhat_us + gamma_x * s_gap;

[name='eq_x_gap']
x_gap = ln_x_eq - ln_x_level;

[name='eq_dln_x']
dln_x = b0_x * x_gap(-1) + b1_x * dln_x(-1) + b2_x * yhat_us + b3_x * s_gap + b4_x * dln_pcom + eps_x;

[name='eq_ln_m_eq']
ln_m_eq = beta_m * ln_d_iad + gamma_m * s_gap;

[name='eq_m_gap']
m_gap = ln_m_eq - ln_m_level;

[name='eq_dln_m']
dln_m = b0_m * m_gap(-1) + b1_m * dln_m(-1) + b2_m * iad + b3_m * s_gap + eps_m;

[name='eq_pi_c']
// Round 6 (2026-05-20): + alpha_GST · tau_GST_gap — GST rate-change pass-through to CPI.
pi_c = rho_pc * pi_c(-1) + alpha_pc * piQ + beta_pc_m * pi_m + gamma_oil * dln_pcom + (1 - rho_pc - alpha_pc - beta_pc_m) * pibar_au + alpha_GST * tau_GST_gap + eps_pc;

[name='eq_pi_ib']
pi_ib = rho_pib * pi_ib(-1) + alpha_pib * piQ + beta_pib_m * pi_m + (1 - rho_pib - alpha_pib - beta_pib_m) * pibar_au + eps_pib;

[name='eq_pi_ih']
pi_ih = rho_pih * pi_ih(-1) + alpha_pih * piQ + beta_pih_m * pi_m + (1 - rho_pih - alpha_pih - beta_pih_m) * pibar_au + eps_pih;

[name='eq_pi_x']
pi_x = rho_px * pi_x(-1) + alpha_px * piQ + (1 - rho_px - alpha_px) * pibar_au + beta_px * s_gap + alpha_pcom * dln_pcom + eps_px;

[name='eq_pi_m']
pi_m = rho_pm * pi_m(-1) + alpha_pm * piQ + (1 - rho_pm - alpha_pm) * pibar_au + beta_pm * s_gap + beta_pm_com * dln_pcom + eps_pm;

[name='eq_dln_pcom']
dln_pcom = rho_pcom * dln_pcom(-1) + 0.10 * yhat_us + eps_pcom;

[name='eq_dln_g']
dln_g = rho_g * dln_g(-1) + phi_g * yhat_au + eps_g;

[name='eq_pi_g']
pi_g = rho_pg * pi_g(-1) + alpha_pg * (pi_w - dln_prod) + (1 - rho_pg - alpha_pg) * pibar_au + eps_pg;

[name='eq_gdp_identity']
yhat_dom = w_c * dln_c + w_ib * dln_ib + w_ih * dln_ih + w_g * dln_g + w_x * dln_x - w_m * dln_m;

[name='eq_rw_gap']
rw_gap = pi_w - piQ - dln_prod;

[name='eq_iad']
iad = w_iad_c * dln_c + w_iad_ib * dln_ib + w_iad_ih * dln_ih + w_iad_g * dln_g + w_iad_x * dln_x;

[name='eq_i_lh']
i_lh = rho_lh * i_lh(-1) + (1 - rho_lh) * (i_10y + spread_lh) + eps_lh;

[name='eq_dln_ph']
dln_ph = rho_ph * dln_ph(-1) + alpha_ph_y * yhat_au + alpha_ph_r * i_gap(-1) + eps_ph;

[name='eq_ph_gap']
ph_gap = 0.98 * ph_gap(-1) + dln_ph;

[name='eq_i_F']
i_F = i_F_prem * (1 - rho_i_asset) + (1 - rho_i_asset) * i_10y + rho_i_asset * i_F(-1);

[name='eq_i_G']
i_G = (1 - rho_i_asset) * i_10y + rho_i_asset * i_G(-1);

[name='eq_i_H']
i_H = i_H_prem * (1 - rho_i_asset) + (1 - rho_i_asset) * i_10y + rho_i_asset * i_H(-1);

[name='eq_i_N']
i_N = i_N_prem * (1 - rho_i_asset) + (1 - rho_i_asset) * i_10y + rho_i_asset * i_N(-1);

[name='eq_yf_F']
yf_F = i_F * w_F_ss - tau_F;

[name='eq_yf_G']
yf_G = i_G * w_G_ss;

[name='eq_yf_H']
yf_H = i_H * (-(w_F_ss + w_G_ss + w_N_ss)) + tau_F + tau_N;

[name='eq_yf_N']
yf_N = i_N * w_N_ss - tau_N;

[name='eq_tau_F']
tau_F = (1 - rho_stab_1) * tau_F(-1) + rho_stab_1 * tau_F_ss;

[name='eq_tau_N']
tau_N = (1 - rho_stab_1) * tau_N(-1) + rho_stab_1 * tau_N_ss;

[name='eq_tau_G']
tau_G = (1 - rho_stab_1) * tau_G(-1) + rho_stab_1 * tau_G_ss + 0.05 * yhat_au;

[name='eq_b_F']
b_F = -w_ib * dln_ib - (tau_F - tau_F_ss) + (i_F - (i_ss + tp_ss + i_F_prem)) * w_F_ss;

[name='eq_b_G']
b_G = -w_g * dln_g + 0.30 * yhat_au - (tau_G - tau_G_ss) + (i_G - (i_ss + tp_ss)) * w_G_ss;

[name='eq_b_H']
b_H = w_c * (yhat_au - dln_c) - w_ih * dln_ih + (i_H - (i_ss + tp_ss + i_H_prem)) * (-(w_F_ss+w_G_ss+w_N_ss));

[name='eq_b_N']
b_N = (i_N - (i_ss + tp_ss + i_N_prem)) * w_N_ss;

[name='eq_w_F']
w_F = 0.98 * w_F(-1) + 0.02 * w_F_ss + b_F;

[name='eq_w_G']
w_G = 0.98 * w_G(-1) + 0.02 * w_G_ss + b_G;

[name='eq_w_H']
w_H = 0.98 * w_H(-1) + 0.02 * (-(w_F_ss+w_G_ss+w_N_ss)) + b_H;

[name='eq_w_N']
w_N = 0.98 * w_N(-1) + 0.02 * w_N_ss + b_N;

[name='eq_b_ROW']
b_ROW = -(b_F + b_G + b_H + b_N);

// =====================================================================
// Round 1.1 — HICP-style headline-decomposition reporting block
// One-way projections of headline CPI onto core/food/energy and
// tradeables/non-tradeables splits, plus a trimmed-mean smoother.
// Zero feedback into existing dynamics; new endogenous variables only.
// =====================================================================

[name='eq_pi_au_food']
pi_au_food = delta_food_piQ * piQ + (1 - delta_food_piQ) * pibar_au + delta_food_pcom * dln_pcom;

[name='eq_pi_au_energy']
pi_au_energy = delta_energy_pm * pi_m + (1 - delta_energy_pm) * pibar_au + delta_energy_pcom * dln_pcom;

[name='eq_pi_au_core']
pi_au_core = (pi_au - w_cpi_food * pi_au_food - w_cpi_energy * pi_au_energy) / (1 - w_cpi_food - w_cpi_energy);

[name='eq_pi_au_trad']
pi_au_trad = delta_trad_pm * pi_m + (1 - delta_trad_pm) * pibar_au + delta_trad_pcom * dln_pcom + delta_trad_s * s_gap;

[name='eq_pi_au_nontrad']
pi_au_nontrad = (pi_au - w_cpi_trad * pi_au_trad) / (1 - w_cpi_trad);

[name='eq_pi_au_trim']
pi_au_trim = rho_trim * pi_au_trim(-1) + (1 - rho_trim) * (delta_trim_piQ * piQ + (1 - delta_trim_piQ) * pibar_au);

// =====================================================================
// Round 5 (2026-05-20) — Demographic trends (audit #43)
// AR(1) gap variable representing deviations of AU population growth from
// steady-state trend (g_pop_ss ≈ 0.375 qpp = 1.5% annualised; ABS Cat
// 6202.0 average 2015-2024). Enters eq_dln_n_star_bar below as an additive
// shifter so long-run employment tracks population trend.
// =====================================================================

[name='eq_dln_pop_bar']
dln_pop_bar = rho_pop * dln_pop_bar(-1) + eps_pop_bar;

// =====================================================================
// Round 4 (2026-05-20) — Foreign monetary policy (audit #8, #42)
// Add a Fed funds rate `i_us` and a US long-run anchor `ibar_us` to the
// E-SAT layer. The existing model only carries yhat_us, pi_us, pi_us_gap,
// pibar_us; this adds the policy-rate side so foreign monetary shocks
// can transmit through the UIP block (eq_pv_i_uip uses ibar implicitly
// for AU; symmetric US-side process for completeness).
// =====================================================================

[name='eq_ibar_us']
ibar_us = lambda_ibar_us * ibar_us(-1) + (1 - lambda_ibar_us) * i_ss_us + eps_ibar_us;

[name='eq_i_us']
i_us = ibar_us + alpha_i_us * pi_us_gap(-1) + beta_i_us * yhat_us(-1) + eps_i_us;

// =====================================================================
// Round 6 (2026-05-20) — Tax structure decomposition (audit #46)
// AR(1) effective-rate gaps for GST, PAYG (personal income tax), and CIT
// (corporate income tax). Each feeds into one structural channel:
//   tau_GST_gap  →  pi_c       (cost-push to CPI)
//   tau_PAYG_gap →  dln_c_star_bar (consumption income drag)
//   tau_CIT_gap  →  uc_k       (user-cost-of-capital bump)
// AU steady-state effective rates: GST ~7-8% on CPI basket, PAYG ~22%
// average personal-income effective, CIT ~22-25% post-deductions.
// =====================================================================

[name='eq_tau_GST_gap']
tau_GST_gap = rho_tau_GST * tau_GST_gap(-1) + eps_tau_GST;

[name='eq_tau_PAYG_gap']
tau_PAYG_gap = rho_tau_PAYG * tau_PAYG_gap(-1) + eps_tau_PAYG;

[name='eq_tau_CIT_gap']
tau_CIT_gap = rho_tau_CIT * tau_CIT_gap(-1) + eps_tau_CIT;

// =====================================================================
// Round 1.2 (2026-05-21) — Household wage+transfer income channel (FR-BDF
// wp1044 §3.5.1 eq 35). wt_H_real_gap is the HP-gap of log of household
// real labour-plus-transfer income, constructed from ABS 5206 Table 20.
// Reduced-form AR(1) feeds the var_model companion matrix; the structural
// b_HtM channel into consumption growth lives in the cherrypicked PAC
// equation (au_pac.mod ln_c_level), not here.
// =====================================================================

[name='eq_wt_H_real_gap']
wt_H_real_gap = rho_wtH * wt_H_real_gap(-1) + alpha_wtH_y * yhat_au(-1) + alpha_wtH_u * u_gap(-1) + alpha_wtH_tau * tau_PAYG_gap(-1) + eps_wtH;

// =====================================================================
// Round 7 (2026-05-20) — Market vs non-market VA decomposition (audit #45)
// Decompose aggregate output gap into market sector (manufacturing, finance,
// retail, mining, construction; ~85% of AU GDP per ABS Cat 5206) and
// non-market sector (public admin, education, health; ~15%). Non-market
// is smoother; market is more cyclical.
// Identity-preserving: yhat_au ≡ w_market·yhat_market + (1-w_market)·yhat_nonmarket.
// =====================================================================

[name='eq_yhat_nonmarket']
yhat_nonmarket = rho_nonmarket * yhat_nonmarket(-1) + (1 - rho_nonmarket) * gamma_nonmarket * yhat_au;

[name='eq_yhat_market']
yhat_market = (yhat_au - (1 - w_market) * yhat_nonmarket) / w_market;

// =====================================================================
// Round 8 (2026-05-20) — BLR / MAPI / MAPU auxiliary forecasters (audit #48)
// RBA-style nowcasting projections of the key financial outcomes:
//   BLR_hat  — Bank Lending Rate (nowcast of i_lh gap)
//   MAPI_hat — Mortgage Asset Price Indicator (nowcast of ph_gap)
//   MAPU_hat — Mortgage Asset Price Underwriting (nowcast of dln_ih)
// One-way projections; each adds an exogenous nowcast shock that can be
// fed with high-frequency / monthly data outside the quarterly cycle.
// =====================================================================

[name='eq_BLR_hat']
BLR_hat = rho_BLR * BLR_hat(-1) + (1 - rho_BLR) * (i_lh - i_ss - tp_ss - spread_lh) + eps_BLR;

[name='eq_MAPI_hat']
MAPI_hat = rho_MAPI * MAPI_hat(-1) + (1 - rho_MAPI) * ph_gap + eps_MAPI;

[name='eq_MAPU_hat']
MAPU_hat = rho_MAPU * MAPU_hat(-1) + (1 - rho_MAPU) * dln_ih + eps_MAPU;

