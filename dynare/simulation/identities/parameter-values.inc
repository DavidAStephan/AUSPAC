delta = 0.1989;
lambda_q = 0.6959;
sigma_q = 0.0648;
lambda_i = 0.9576;
alpha_i = 0.3001;
beta_i = 0.0837;
lambda_pi = 0.2902;
kappa_pi = 0.0374;
lambda_q_us = 0.8057;
lambda_pi_us = 0.6529;
kappa_pi_us = 0.0131;
lambda_ibar = 0.985;
lambda_pibar = 0.93;
lambda_pibar_us = 0.93;
i_ss = 1.0491;
pi_ss_au = 0.625;
pi_ss_us = 0.5;
lambda_dom = 0.399;
omega_pQ = 0.46;
alpha_k = 0.45;
rho_tfp = 0.95;
rho_pcom = 0.42;
b4_x = 0.15;
alpha_pcom = 0.1;
lambda_w = 0.2017;
kappa_w = 0.0544;
gamma_w = 0.4579;
okun_coeff = -0.13;
rho_u_gap = 0.946;
beta_w = 0.98;
omega_n = 0.3;
rho_n_star = 0.95;
omega_c = 0.369;
b_di_c = -0.701;
rho_c_star = 0.95;
kappa_inc = 0.05;
beta_c = 0.95;
alpha_c_r = -0.95;
omega_ib = 0.35;
b4_ib = -0.03;
rho_ib_star = 0.95;
kappa_wacc = 0.038;
delta_k = 0.0134;
omega_ih = 0.3;
b4_ih = 0;
b_ph_ih = 0.0099;
rho_ih_star = 0.95;
kappa_mort = 0.048;
rho_L = 0.9;
kappa_10 = 0.97;
tp_ss = 0.3;
rho_tp = 0.98;
rho_wacc = 0.9;
spread_ss = 0.5;
w_COE = 0.5;
w_LB_firms = 0.3;
w_BBB = 0.2;
rho_COE = 0.92;
rho_LB_firms = 0.77;
rho_BBB = 0.94;
s_COE_ss = 0.8;
s_LB_firms_ss = 0.25;
s_BBB_ss = 0.05;
rho_s = 0.775;
alpha_s = 0.15;
beta_uip = 0.92;
b0_x = 0.05;
b1_x = 0.3;
b2_x = 0.25;
b3_x = 0.1;
beta_x = 1.2;
gamma_x = 0.4;
b0_m = 0.06;
b1_m = 0.2316;
b2_m = 0.3591;
b3_m = -0.08;
beta_m = 1.5;
gamma_m = -0.4;
rho_pc = 0.67;
alpha_pc = 0.17;
rho_pib = 0.7;
alpha_pib = 0.19;
rho_pih = 0.49;
alpha_pih = 0.4;
rho_px = 0.21;
alpha_px = 0.2;
beta_px = -0.05;
rho_pm = 0.28;
alpha_pm = 0.38;
beta_pm = 0.09;
rho_g = 0.85;
phi_g = -0.1;
rho_pg = 0.13;
alpha_pg = 0.37;
w_c = 0.55;
w_ib = 0.13;
w_ih = 0.06;
w_g = 0.24;
w_x = 0.25;
w_m = 0.23;
sigma_ces = 0.5366;
beta_pc_m = 0.1;
beta_pib_m = 0.12;
beta_pih_m = 0.08;
gamma_oil = 0.03;
beta_pm_com = 0.42;
w_iad_c = 0.12;
w_iad_ib = 0.25;
w_iad_ih = 0.15;
w_iad_g = 0.08;
w_iad_x = 0.3;
rho_lh = 0.97;
spread_lh = 0.4;
rho_ph = 0.6;
alpha_ph_y = 0.15;
alpha_ph_r = -0.7;
kappa_ph = 0.03;
kappa_ih_inc = 0.03;
kappa_ib_y = 0.06;
w_F_ss = -2.8;
w_G_ss = -1.6;
w_N_ss = 0.08;
tau_F_ss = 0.026;
tau_G_ss = 0.16;
tau_N_ss = 0.00026;
rho_stab_1 = 0.1;
rho_stab_2 = 0.25;
rho_i_asset = 0.983;
i_F_prem = -0.0037;
i_H_prem = -0.0007;
i_N_prem = -0.001;
gamma_reval = -0.018;
g_nom = 0.002625;
beta_pac = 0.98;
b_covid_crash_pQ = 0;
b_covid_crash_c = 0;
b_covid_crash_ib = 0;
b_covid_crash_ih = 0;
b_covid_crash_n = 0;
b_covid_bounce_pQ = 0;
b_covid_bounce_c = 0;
b_covid_bounce_ib = 0;
b_covid_bounce_ih = 0;
b_covid_bounce_n = 0;
// Phase U: wage->piQ_hat regression coefficient.
// FR-BDF wp736 eq (45) regresses the long-run VA-price target on
// efficient wage inflation with coefficient 0.59. AU-PAC adopts the
// same value (the projection of the LR VA-price target onto the E-SAT
// state previously had no wage regressor, breaking the wage-price
// spiral; see dynare/PRICE_RESPONSE_DIAGNOSIS.md).
a_pQ_w = 0.59;
// Phase V: FR-BDF wp736 eq (80) ECM rewrite of the consumer price equation.
// omega_pc      - LR import-price weight in CPI target (FR-BDF eq 79 β0_LR = 0.23;
//                 AU IAD weight w_iad_c = 0.20 — same neighbourhood, calibrate to 0.23).
// alpha_pc_lag  - lagged VA-price passthrough (FR-BDF eq 80 β1 = 0.16).
// b_ECM_pc      - error-correction speed of pi_au_gap toward (p_C_star - p_C) gap
//                 (FR-BDF eq 80 |β3| = 0.05; the FR-BDF sign convention has
//                 β3 = -0.05 on (p_C - p*_C); we adopt b_ECM_pc = +0.05 on
//                 (p_C_star_level - p_C_level), same direction).
omega_pc       = 0.23;
alpha_pc_lag   = 0.16;
b_ECM_pc       = 0.05;
// Round 1.1 (2026-05-18): HICP-style headline-decomposition reporting block.
// Weights from ABS Cat. 6401.0 (CPI weights, 2025 reweight) and RBA Bulletin
// (tradeables share). The decomposition is identity-preserving:
//   pi_au ≡ w_cpi_food·pi_au_food + w_cpi_energy·pi_au_energy
//         + (1 - w_cpi_food - w_cpi_energy)·pi_au_core
//   pi_au ≡ w_cpi_trad·pi_au_trad + (1 - w_cpi_trad)·pi_au_nontrad
// pi_au_food, pi_au_energy, pi_au_trad are reduced-form projections onto
// existing drivers (piQ, pi_m, pibar_au, dln_pcom, s_gap); pi_au_core and
// pi_au_nontrad are residuals that close each identity. pi_au_trim is an
// AR(1) smoother around the underlying VA-price trend (RBA trimmed-mean
// proxy). Zero feedback into the rest of the model (reporting only).
w_cpi_food        = 0.17;    // Food + non-alc bev (ABS 6401)
w_cpi_energy      = 0.07;    // Auto fuel + electricity + gas
w_cpi_trad        = 0.35;    // RBA tradeables share
delta_food_piQ    = 0.65;    // Food ← domestic VA price (meat, dairy, fresh produce)
delta_food_pcom   = 0.20;    // Food ← global agricultural commodity passthrough
delta_energy_pm   = 0.50;    // Energy ← imported fuel
delta_energy_pcom = 0.60;    // Energy ← global oil/gas passthrough
delta_trad_pm     = 0.85;    // Tradeables ← imports (dominant)
delta_trad_pcom   = 0.15;    // Tradeables ← commodity passthrough
delta_trad_s      = -0.10;   // Tradeables ← FX (AUD appreciation lowers prices)
rho_trim          = 0.85;    // Trimmed-mean persistence
delta_trim_piQ    = 0.70;    // Trimmed mean ← underlying VA-price trend
// =====================================================================
// Round 4-8 (2026-05-20): foreign monetary policy, demographic trend,
// tax decomposition, branch (market/non-market) decomposition, BLR/MAPI/MAPU
// auxiliary forecasters. All parameters calibrated to AU-relevant central
// values; can be promoted to estimated_params if needed.
// =====================================================================
// Round 5 — demographic trends (audit #43): AU pop growth ~1.5%/yr trend
rho_pop           = 0.95;    // Pop-growth gap persistence
// Round 4 — foreign monetary policy (audit #8, #42)
lambda_ibar_us    = 0.985;   // US LR anchor persistence (mirror AU)
i_ss_us           = 0.625;   // US neutral rate ~2.5% annualised
alpha_i_us        = 0.5;     // US Taylor: pi response
beta_i_us         = 0.5;     // US Taylor: yhat response
// Round 6 — tax structure decomposition (audit #46)
rho_tau_GST       = 0.90;    // GST effective-rate persistence
rho_tau_PAYG      = 0.92;    // PAYG effective-rate persistence
rho_tau_CIT       = 0.94;    // CIT effective-rate persistence
alpha_GST         = 0.05;    // GST → CPI passthrough
alpha_PAYG        = 0.10;    // PAYG → consumption growth drag
alpha_CIT         = 0.02;    // CIT → user-cost-of-capital bump
// Round 7 — branch decomposition (audit #45): AU market vs non-market VA
w_market          = 0.85;    // Market share of GDP (ABS Cat 5206)
rho_nonmarket     = 0.90;    // Non-market sector persistence
gamma_nonmarket   = 0.30;    // Non-market cyclical sensitivity to aggregate
// Round 8 — BLR/MAPI/MAPU auxiliary forecasters (audit #48)
rho_BLR           = 0.90;    // Bank lending rate nowcast persistence
rho_MAPI          = 0.85;    // Housing price indicator persistence
rho_MAPU          = 0.80;    // Housing investment underwriting persistence
// Round 1.2 (2026-05-21) — household wage+transfer income channel for
// rule-of-thumb consumers (FR-BDF wp1044 §3.5.1 eq 35). wt_H_real_gap is the
// HP-filter gap of log[(compensation_of_employees + social_assistance)/p_C]
// from ABS 5206 Table 20 (cf. data/prepare_household_income.m). Reduced-form
// AR(1) loads on output gap (procyclical wages) and unemployment gap (counter-
// cyclical transfer support — JobKeeper-style fiscal stimulus dominates). b_HtM
// from FR-BDF wp1044 posterior 0.32 (s.e. 0.10).
rho_wtH           = 0.50;    // wt_H gap persistence
alpha_wtH_y       = 0.50;    // procyclical wages
alpha_wtH_u       = 0.30;    // countercyclical transfer support
alpha_wtH_tau     = -0.40;   // PAYG raise drags real wages
b_HtM             = 0.32;    // rule-of-thumb consumer response (FR-BDF wp1044)
