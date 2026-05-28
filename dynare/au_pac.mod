// --+ options: stochastic,json=compute +--

var
	b_F
	b_G
	b_H
	b_N
	b_ROW
	c_gap
	c_hat
	di_gap
	dln_c
	dln_c_star
	dln_c_star_bar
	dln_g
	dln_ib
	dln_ib_1
	dln_ib_star
	dln_ib_star_bar
	dln_ih
	dln_ih_1
	dln_ih_star
	dln_ih_star_bar
	dln_k
	dln_m
	dln_n
	dln_n_1
	dln_n_2
	dln_n_3
	dln_n_star
	dln_n_star_bar
	dln_pcom
	dln_ph
	dln_prod
	dln_tfp
	dln_uc_k
	dln_ulc
	dln_x
	dln_y_star
	dy_bar_gap
	i_10y
	i_BBB
	i_COE
	i_F
	i_G
	i_H
	i_LB_firms
	i_N
	i_au
	i_gap
	i_lh
	iad
	ib_gap
	ib_hat
	ibar
	ih_gap
	ih_hat
	ln_C
	ln_C_star
	ln_IB
	ln_IB_star
	ln_IH
	ln_IH_star
	ln_K
	ln_N
	ln_N_star
	ln_P
	ln_P_star
	ln_Q
	ln_QN
	ln_c_level
	ln_d_iad
	ln_ib_level
	ln_ih_level
	ln_m_eq
	ln_m_level
	ln_n_level
	ln_tfp
	ln_tfp_LR
	ln_x_eq
	ln_x_level
	m_gap
	n_gap
	n_hat
	pQ_level
	pac_expectation_pac_c
	pac_expectation_pac_ib
	pac_expectation_pac_ih
	pac_expectation_pac_n
	pac_expectation_pac_pQ
	ph_gap
	piQ
	piQ_hat
	pi_au
	pi_au_gap
	pi_au_food
	pi_au_energy
	pi_au_core
	pi_au_trad
	pi_au_nontrad
	pi_au_trim
	dln_pop_bar
	i_us
	ibar_us
	tau_GST_gap
	tau_PAYG_gap
	tau_CIT_gap
	wt_H_real_gap
	yhat_market
	yhat_nonmarket
	BLR_hat
	MAPI_hat
	MAPU_hat
	pi_c
	pi_g
	pi_ib
	pi_ih
	pi_m
	pi_us
	pi_us_gap
	pi_w
	pi_w_gap
	p_C_level
	p_M_level
	p_C_star_level
	p_IB_level
	p_IB_star_level
	p_IH_level
	p_IH_star_level
	pi_x
	pibar_au
	pibar_us
	pv_c_aux
	pv_i
	pv_i_uip
	pv_ib_aux
	pv_ih_aux
	pv_n_aux
	pv_piQ_aux
	pv_rKB_aux
	pv_r_lh_gap
	pv_u_gap
	pv_yh
	rKB_hat
	rw_gap
	s_BBB
	s_COE
	s_LB_firms
	s_gap
	tau_F
	tau_G
	tau_N
	tp
	u_gap
	uc_k
	w_F
	w_G
	w_H
	w_N
	wacc
	x_gap
	yf_F
	yf_G
	yf_H
	yf_N
	yh_ratio_hat
	yhat_au
	yhat_dom
	yhat_us
;

parameters
	a_c_i
	a_c_PAYG
	a_c_pi
	a_c_u
	a_c_y
	a_c_yh
	a_ib_CIT
	a_ib_pi
	a_ib_u
	a_ib_y
	a_ih_i
	a_ih_pi
	a_ih_u
	a_ih_y
	a_n_i
	a_n_pi
	a_n_pop
	a_n_u
	a_n_y
	a_pQ_GST
	a_pQ_i
	a_pQ_pi
	a_pQ_u
	a_pQ_w
	a_pQ_y
	a_rKB_CIT
	a_rKB_i
	a_yh_u
	a_yh_y
	alpha_c_r
	alpha_i
	alpha_k
	alpha_pc
	alpha_pc_lag
	alpha_pcom
	alpha_pg
	alpha_ph_r
	alpha_ph_y
	alpha_pib
	alpha_pih
	alpha_pm
	alpha_px
	alpha_s
	b0_c
	b0_ib
	b0_ih
	b0_m
	b0_n
	b0_pQ
	b0_x
	b1_c
	b1_ib
	b1_ih
	b1_m
	b1_n
	b1_pQ
	b1_x
	b2_c
	b2_ib
	b2_ih
	b2_m
	b2_n
	b2_pQ
	b2_x
	gamma_ulc
	gamma_uck
	b3_c
	b3_ib
	b3_ih
	b3_m
	b3_n
	b3_x
	b4_ib
	b4_ih
	b4_n
	b4_x
	b5_n
	b_covid_bounce_c
	b_covid_bounce_ib
	b_covid_bounce_ih
	b_covid_bounce_n
	b_covid_bounce_pQ
	b_covid_crash_c
	b_covid_crash_ib
	b_covid_crash_ih
	b_covid_crash_n
	b_covid_crash_pQ
	b_ECM_pc
	b_ECM_pib
	b_ECM_pih
	omega_pib
	omega_pih
	kappa_spread_LB
	kappa_spread_BBB
	b_di_c
	b_ph_ih
	beta_c
	beta_i
	beta_m
	beta_pac
	beta_pc_m
	beta_pib_m
	beta_pih_m
	beta_pm
	beta_pm_com
	beta_px
	beta_uip
	beta_w
	beta_x
	delta
	delta_k
	g_nom
	gamma_m
	gamma_oil
	gamma_reval
	gamma_w
	gamma_x
	h_pac_c_constant
	h_pac_c_var_c_hat_lag_1
	h_pac_c_var_dln_pcom_lag_1
	h_pac_c_var_i_gap_lag_1
	h_pac_c_var_ibar_lag_1
	h_pac_c_var_piQ_lag_1
	h_pac_c_var_pi_au_gap_lag_1
	h_pac_c_var_pi_m_lag_1
	h_pac_c_var_pi_us_gap_lag_1
	h_pac_c_var_pibar_au_lag_1
	h_pac_c_var_pibar_us_lag_1
	h_pac_c_var_tau_PAYG_gap_lag_1
	h_pac_c_var_u_gap_lag_1
	h_pac_c_var_wt_H_real_gap_lag_1
	h_pac_c_var_yh_ratio_hat_lag_1
	h_pac_c_var_yhat_au_lag_1
	h_pac_c_var_yhat_us_lag_1
	h_pac_ib_constant
	h_pac_ib_var_dln_pcom_lag_1
	h_pac_ib_var_i_gap_lag_1
	h_pac_ib_var_ib_hat_lag_1
	h_pac_ib_var_ibar_lag_1
	h_pac_ib_var_piQ_lag_1
	h_pac_ib_var_pi_au_gap_lag_1
	h_pac_ib_var_pi_m_lag_1
	h_pac_ib_var_pi_us_gap_lag_1
	h_pac_ib_var_pibar_au_lag_1
	h_pac_ib_var_pibar_us_lag_1
	h_pac_ib_var_rKB_hat_lag_1
	h_pac_ib_var_tau_CIT_gap_lag_1
	h_pac_ib_var_u_gap_lag_1
	h_pac_ib_var_yhat_au_lag_1
	h_pac_ib_var_yhat_us_lag_1
	h_pac_ih_constant
	h_pac_ih_var_dln_pcom_lag_1
	h_pac_ih_var_i_gap_lag_1
	h_pac_ih_var_ibar_lag_1
	h_pac_ih_var_ih_hat_lag_1
	h_pac_ih_var_piQ_lag_1
	h_pac_ih_var_pi_au_gap_lag_1
	h_pac_ih_var_pi_m_lag_1
	h_pac_ih_var_pi_us_gap_lag_1
	h_pac_ih_var_pibar_au_lag_1
	h_pac_ih_var_pibar_us_lag_1
	h_pac_ih_var_u_gap_lag_1
	h_pac_ih_var_yhat_au_lag_1
	h_pac_ih_var_yhat_us_lag_1
	h_pac_n_constant
	h_pac_n_var_dln_pcom_lag_1
	h_pac_n_var_dln_pop_bar_lag_1
	h_pac_n_var_i_gap_lag_1
	h_pac_n_var_ibar_lag_1
	h_pac_n_var_n_hat_lag_1
	h_pac_n_var_piQ_lag_1
	h_pac_n_var_pi_au_gap_lag_1
	h_pac_n_var_pi_m_lag_1
	h_pac_n_var_pi_us_gap_lag_1
	h_pac_n_var_pibar_au_lag_1
	h_pac_n_var_pibar_us_lag_1
	h_pac_n_var_u_gap_lag_1
	h_pac_n_var_yhat_au_lag_1
	h_pac_n_var_yhat_us_lag_1
	h_pac_pQ_constant
	h_pac_pQ_var_dln_pcom_lag_1
	h_pac_pQ_var_i_gap_lag_1
	h_pac_pQ_var_ibar_lag_1
	h_pac_pQ_var_piQ_hat_lag_1
	h_pac_pQ_var_piQ_lag_1
	h_pac_pQ_var_pi_au_gap_lag_1
	h_pac_pQ_var_pi_m_lag_1
	h_pac_pQ_var_pi_us_gap_lag_1
	h_pac_pQ_var_pi_w_gap_lag_1
	h_pac_pQ_var_pibar_au_lag_1
	h_pac_pQ_var_pibar_us_lag_1
	h_pac_pQ_var_tau_GST_gap_lag_1
	h_pac_pQ_var_u_gap_lag_1
	h_pac_pQ_var_yhat_au_lag_1
	h_pac_pQ_var_yhat_us_lag_1
	i_F_prem
	i_H_prem
	i_N_prem
	i_ss
	kappa_10
	kappa_ib_y
	kappa_ih_inc
	kappa_inc
	kappa_mort
	kappa_ph
	kappa_pi
	kappa_pi_us
	kappa_w
	kappa_wacc
	lambda_dom
	lambda_i
	lambda_ibar
	lambda_pi
	lambda_pi_us
	lambda_pibar
	lambda_pibar_us
	lambda_q
	lambda_q_us
	lambda_w
	okun_coeff
	omega_c
	omega_ib
	omega_ih
	omega_n
	omega_pQ
	omega_pc
	phi_g
	pi_ss_au
	pi_ss_us
	rho_BBB
	rho_COE
	rho_L
	rho_LB_firms
	rho_c_aux
	rho_c_star
	rho_g
	rho_i_asset
	rho_ib_aux
	rho_ib_star
	rho_ih_aux
	rho_ih_star
	rho_lh
	rho_n_aux
	rho_n_star
	rho_pQ_aux
	rho_pc
	rho_pcom
	rho_pg
	rho_ph
	rho_pib
	rho_pih
	rho_pm
	rho_px
	rho_rKB_aux
	rho_s
	rho_stab_1
	rho_stab_2
	rho_tfp
	rho_tp
	rho_u_gap
	rho_wacc
	rho_yh_aux
	s_BBB_ss
	s_COE_ss
	s_LB_firms_ss
	sigma_ces
	sigma_q
	spread_lh
	spread_ss
	tau_F_ss
	tau_G_ss
	tau_N_ss
	tp_ss
	w_BBB
	w_COE
	w_F_ss
	w_G_ss
	w_LB_firms
	w_N_ss
	w_c
	w_g
	w_iad_c
	w_iad_g
	w_iad_ib
	w_iad_ih
	w_iad_x
	w_ib
	w_ih
	w_m
	w_x
	w_cpi_food
	w_cpi_energy
	w_cpi_trad
	delta_food_piQ
	delta_food_pcom
	delta_energy_pm
	delta_energy_pcom
	delta_trad_pm
	delta_trad_pcom
	delta_trad_s
	rho_trim
	delta_trim_piQ
	rho_pop
	lambda_ibar_us
	i_ss_us
	alpha_i_us
	beta_i_us
	rho_tau_GST
	rho_tau_PAYG
	rho_tau_CIT
	alpha_GST
	alpha_PAYG
	alpha_CIT
	w_market
	rho_nonmarket
	gamma_nonmarket
	rho_BLR
	rho_MAPI
	rho_MAPU
	rho_wtH
	alpha_wtH_y
	alpha_wtH_u
	alpha_wtH_tau
	b_HtM
	b_PAC_c
;

a_pQ_GST = 0.05;
a_pQ_i = 0;
a_pQ_pi = 0;
a_pQ_u = 0;
a_pQ_w = 0.59;
a_pQ_y = 0.05;
b0_pQ = 0.0294;
b1_pQ = 0.2784;
b2_pQ = 0.0022;
// CES dual cost-function structural coefficients (§4.3.1):
//   γ_ULC = (1-α)σ = (1-0.45)*0.5366 = 0.295
//   γ_UCK = ασ     = 0.45*0.5366      = 0.241
// These are NOT free parameters — they're pinned by the CES calibration.
gamma_ulc = 0.2951;   // (1-alpha_k)*sigma_ces: ULC passthrough into VA price
gamma_uck = 0.2415;   // alpha_k*sigma_ces: user-cost passthrough into VA price
h_pac_pQ_constant = 0.0005236870666278106;
h_pac_pQ_var_dln_pcom_lag_1 = 3.553534636190619e-05;
h_pac_pQ_var_i_gap_lag_1 = -0.001354039809492274;
h_pac_pQ_var_ibar_lag_1 = 0;
h_pac_pQ_var_piQ_hat_lag_1 = 0.0006855541194920155;
h_pac_pQ_var_piQ_lag_1 = 0.0006086782909132557;
h_pac_pQ_var_pi_au_gap_lag_1 = 0.00073477552040113;
h_pac_pQ_var_pi_m_lag_1 = 9.715487155303405e-05;
h_pac_pQ_var_pi_us_gap_lag_1 = 0;
h_pac_pQ_var_pi_w_gap_lag_1 = 0.001165346490302144;
h_pac_pQ_var_pibar_au_lag_1 = -0.001543732469070786;
h_pac_pQ_var_pibar_us_lag_1 = 0;
h_pac_pQ_var_tau_GST_gap_lag_1 = 0.0008210038229253343;
h_pac_pQ_var_u_gap_lag_1 = -0.001037504482199218;
h_pac_pQ_var_yhat_au_lag_1 = 0.001309415581591862;
h_pac_pQ_var_yhat_us_lag_1 = 0.001031305130438237;
rho_pQ_aux = 0.85;
a_c_PAYG = -0.1;
a_c_i = -0.04;
a_c_pi = 0.005;
a_c_u = -0.03;
a_c_y = 0.06;
a_c_yh = 0.39;
a_yh_u = -0.2;
a_yh_y = 0.4;
b0_c = 0.0736;
b1_c = 0.0375;
b2_c = -0.333;
b3_c = 0.022;
h_pac_c_constant = 0.0003458937173372549;
h_pac_c_var_c_hat_lag_1 = 0.01053776568397507;
h_pac_c_var_dln_pcom_lag_1 = 3.955325021801383e-05;
h_pac_c_var_i_gap_lag_1 = -0.008845224594859128;
h_pac_c_var_ibar_lag_1 = 0;
h_pac_c_var_piQ_lag_1 = 0.000556405469182104;
h_pac_c_var_pi_au_gap_lag_1 = 0.0009453289296049802;
h_pac_c_var_pi_m_lag_1 = 0.000110380946501119;
h_pac_c_var_pi_us_gap_lag_1 = 0;
h_pac_c_var_pibar_au_lag_1 = -0.001220216363422831;
h_pac_c_var_pibar_us_lag_1 = 0;
h_pac_c_var_tau_PAYG_gap_lag_1 = -0.009564712502815697;
h_pac_c_var_u_gap_lag_1 = -0.007309734434297452;
// Round 1.2 (2026-05-22): wt_H_real_gap is in the var_model state but c_hat
// doesn't load on it, so the discounted-sum projection is exactly zero. The
// b_HtM contemporaneous channel into consumption growth is applied directly
// to the ln_c_level equation, NOT through pac_expectation.
h_pac_c_var_wt_H_real_gap_lag_1 = 0;
h_pac_c_var_yh_ratio_hat_lag_1 = 0.01002197187779131;
h_pac_c_var_yhat_au_lag_1 = 0.01090617676217883;
h_pac_c_var_yhat_us_lag_1 = 0.006501609785602032;
rho_c_aux = 0.6;
rho_yh_aux = 0.6;
a_ib_CIT = -0.011;
a_ib_pi = 0.04;
a_ib_u = -0.02;
a_ib_y = 0.15;
a_rKB_CIT = 0.02;
a_rKB_i = 0.24;
b0_ib = 0.018;
b1_ib = 0.0818;
b2_ib = 0;
b3_ib = 0.3144;
h_pac_ib_constant = 7.573080503659149e-05;
h_pac_ib_var_dln_pcom_lag_1 = 4.138196594744458e-06;
h_pac_ib_var_i_gap_lag_1 = -0.0001901434807020625;
h_pac_ib_var_ib_hat_lag_1 = 0.001432177690824942;
h_pac_ib_var_ibar_lag_1 = 0;
h_pac_ib_var_piQ_lag_1 = 7.633289925954891e-05;
h_pac_ib_var_pi_au_gap_lag_1 = 8.419450803018518e-05;
h_pac_ib_var_pi_m_lag_1 = 1.125360052393662e-05;
h_pac_ib_var_pi_us_gap_lag_1 = 0;
h_pac_ib_var_pibar_au_lag_1 = -0.0002087557878420321;
h_pac_ib_var_pibar_us_lag_1 = 0;
h_pac_ib_var_rKB_hat_lag_1 = 0;
h_pac_ib_var_tau_CIT_gap_lag_1 = -0.0002407865635043806;
h_pac_ib_var_u_gap_lag_1 = 8.755875036522933e-05;
h_pac_ib_var_yhat_au_lag_1 = 0.0002409149502218592;
h_pac_ib_var_yhat_us_lag_1 = 0.0002065844286071973;
rho_ib_aux = 0.6;
rho_rKB_aux = 0.55;
a_ih_i = -0.08;
a_ih_pi = 0.05;
a_ih_u = -0.03;
a_ih_y = 0.08;
b0_ih = 0.0309;
b1_ih = 0.108;
b2_ih = 0;
b3_ih = 0.2322;
h_pac_ih_constant = 0.0001774926117370777;
h_pac_ih_var_dln_pcom_lag_1 = 1.13610208085596e-05;
h_pac_ih_var_i_gap_lag_1 = -0.00875225154469619;
h_pac_ih_var_ibar_lag_1 = 0;
h_pac_ih_var_ih_hat_lag_1 = 0.003325377021469034;
h_pac_ih_var_piQ_lag_1 = 0.0001983570643411463;
h_pac_ih_var_pi_au_gap_lag_1 = 0.0002327047507059199;
h_pac_ih_var_pi_m_lag_1 = 3.103078600160914e-05;
h_pac_ih_var_pi_us_gap_lag_1 = 0;
h_pac_ih_var_pibar_au_lag_1 = -0.0005133760291220796;
h_pac_ih_var_pibar_us_lag_1 = 0;
h_pac_ih_var_u_gap_lag_1 = 0.0001783494219255467;
h_pac_ih_var_yhat_au_lag_1 = 0.001163071255682311;
h_pac_ih_var_yhat_us_lag_1 = 0.0009368676540363051;
rho_ih_aux = 0.71;
a_n_i = -0.03;
a_n_pi = 0.05;
a_n_pop = 1;
a_n_u = -0.04;
a_n_y = 0.12;
b0_n = 0.0578;
b1_n = 0.3118;
b2_n = 0;
b3_n = 0;
b4_n = 0;
b5_n = -0.0007;
h_pac_n_constant = 0.0008405020359839308;
h_pac_n_var_dln_pcom_lag_1 = 8.270836000520397e-05;
h_pac_n_var_dln_pop_bar_lag_1 = 0.1240186277865285;
h_pac_n_var_i_gap_lag_1 = -0.007115738670505818;
h_pac_n_var_ibar_lag_1 = 0;
h_pac_n_var_n_hat_lag_1 = 0.01200933966843916;
h_pac_n_var_piQ_lag_1 = 0.001238776935157444;
h_pac_n_var_pi_au_gap_lag_1 = 0.001769861660252333;
h_pac_n_var_pi_m_lag_1 = 0.0002287069179193933;
h_pac_n_var_pi_us_gap_lag_1 = 0;
h_pac_n_var_pibar_au_lag_1 = -0.002812287110651132;
h_pac_n_var_pibar_us_lag_1 = 0;
h_pac_n_var_u_gap_lag_1 = -0.00338814814623208;
h_pac_n_var_yhat_au_lag_1 = 0.007274501999296703;
h_pac_n_var_yhat_us_lag_1 = 0.004853092324333788;
rho_n_aux = 0.67;
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
b_ph_ih = 0.009900000000000001;
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
rho_BBB = 0.9399999999999999;
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
// Phase V: FR-BDF eq (80) ECM-style additions to eq_au_phillips
alpha_pc_lag = 0.16;   // FR-BDF eq (80) β1 lagged-VA-price passthrough
b_ECM_pc     = 0.05;   // FR-BDF eq (80) |β3| error-correction speed
omega_pc     = 0.23;   // FR-BDF eq (79) β0_LR import weight in CPI target
rho_pib = 0.7;
alpha_pib = 0.19;
beta_pib_m = 0.12;   // import-price passthrough into BI deflator
// Deflator ECM parameters (wp1044 §3.6 structural deflator targets):
b_ECM_pib    = 0.07;    // ECM speed for BI deflator (wp1044 eq 55: β₃ ≈ -0.13)
omega_pib    = 0.72;    // VA-price weight in BI deflator LR target (wp1044: d₁=0.72)
b_ECM_pih    = 0.07;    // ECM speed for housing-inv deflator
omega_pih    = 0.17;    // VA-price weight in housing-inv deflator LR target (wp1044: d₀=0.17)
// Endogenous spread widening (wp1044 §3.5.3 Eq 50, simplified):
//   s_{j,t} responds to the output gap as a proxy for leverage/credit risk.
//   In wp1044 the channel runs through D/E (debt leverage); here we proxy
//   with yhat_au since (a) falling output → rising defaults/leverage →
//   wider spreads, and (b) we don't have the full NFC balance-sheet block.
kappa_spread_LB  = -0.05;   // BLR spread sensitivity to output gap
kappa_spread_BBB = -0.03;   // BBB spread sensitivity to output gap
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


varexo
	eps_10y
	eps_BBB
	eps_COE
	eps_LB_firms
	eps_c
	eps_g
	eps_i
	eps_ib
	eps_ibar
	eps_ih
	eps_lh
	eps_m
	eps_n
	eps_pQ
	eps_pc
	eps_pcom
	eps_pg
	eps_ph
	eps_pi
	eps_pi_us
	eps_pib
	eps_pibar_au
	eps_pibar_us
	eps_pih
	eps_pm
	eps_px
	eps_q
	eps_q_us
	eps_s
	eps_tfp_LR
	eps_tp
	eps_var_c
	eps_var_ib
	eps_var_ih
	eps_var_n
	eps_var_pQ
	eps_var_rKB
	eps_var_yh
	eps_w
	eps_x
	eps_pop_bar
	eps_ibar_us
	eps_i_us
	eps_tau_GST
	eps_tau_PAYG
	eps_tau_CIT
	eps_BLR
	eps_MAPI
	eps_MAPU
	eps_wtH
	eps_dy_bar
;

@#ifdef InvertModel
    @#if InvertModel
        @#include "model-inversion-setup.inc"
    @#endif
@#endif

model;

	[blockname='',name='pac_expectation_pac_pQ']
	pac_expectation_pac_pQ =  h_pac_pQ_constant + h_pac_pQ_var_yhat_au_lag_1*yhat_au(-1) + h_pac_pQ_var_i_gap_lag_1*i_gap(-1) + h_pac_pQ_var_pi_au_gap_lag_1*pi_au_gap(-1) + h_pac_pQ_var_u_gap_lag_1*u_gap(-1) + h_pac_pQ_var_yhat_us_lag_1*yhat_us(-1) + h_pac_pQ_var_pi_us_gap_lag_1*pi_us_gap(-1) + h_pac_pQ_var_ibar_lag_1*ibar(-1) + h_pac_pQ_var_pibar_au_lag_1*pibar_au(-1) + h_pac_pQ_var_pibar_us_lag_1*pibar_us(-1) + h_pac_pQ_var_piQ_lag_1*piQ(-1) + h_pac_pQ_var_pi_m_lag_1*pi_m(-1) + h_pac_pQ_var_dln_pcom_lag_1*dln_pcom(-1) + h_pac_pQ_var_pi_w_gap_lag_1*pi_w_gap(-1) + h_pac_pQ_var_tau_GST_gap_lag_1*tau_GST_gap(-1) + h_pac_pQ_var_piQ_hat_lag_1*piQ_hat(-1);

	[blockname='',name='pQ_level']
	// CES dual cost-function channels: γ_ULC·(dln_ulc - π̄) + γ_UCK·dln_uc_k
	// Gap forms ensure SS neutrality: dln_ulc = π̄ and dln_uc_k = 0 at SS.
	// wp1044 §4.3.1 factor-price-frontier; γ_ULC=(1-α)σ=0.295, γ_UCK=ασ=0.241.
	diff(pQ_level) =  b0_pQ*(piQ_hat(-1)-pQ_level(-1))+b1_pQ*diff(pQ_level(-1))+pac_expectation_pac_pQ+yhat_au*b2_pQ+gamma_ulc*(dln_ulc-pibar_au)+gamma_uck*dln_uc_k+eps_pQ;

	[blockname='',name='piQ_hat']
	piQ_hat =  rho_pQ_aux*piQ_hat(-1)+yhat_au(-1)*a_pQ_y+i_gap(-1)*a_pQ_i+pi_au_gap(-1)*a_pQ_pi+u_gap(-1)*a_pQ_u+pi_w_gap(-1)*a_pQ_w+tau_GST_gap(-1)*a_pQ_GST+eps_var_pQ;

	[blockname='',name='pac_expectation_pac_c']
	pac_expectation_pac_c =  h_pac_c_constant + h_pac_c_var_yhat_au_lag_1*yhat_au(-1) + h_pac_c_var_i_gap_lag_1*i_gap(-1) + h_pac_c_var_pi_au_gap_lag_1*pi_au_gap(-1) + h_pac_c_var_u_gap_lag_1*u_gap(-1) + h_pac_c_var_yhat_us_lag_1*yhat_us(-1) + h_pac_c_var_pi_us_gap_lag_1*pi_us_gap(-1) + h_pac_c_var_ibar_lag_1*ibar(-1) + h_pac_c_var_pibar_au_lag_1*pibar_au(-1) + h_pac_c_var_pibar_us_lag_1*pibar_us(-1) + h_pac_c_var_piQ_lag_1*piQ(-1) + h_pac_c_var_pi_m_lag_1*pi_m(-1) + h_pac_c_var_dln_pcom_lag_1*dln_pcom(-1) + h_pac_c_var_tau_PAYG_gap_lag_1*tau_PAYG_gap(-1) + h_pac_c_var_wt_H_real_gap_lag_1*wt_H_real_gap(-1) + h_pac_c_var_yh_ratio_hat_lag_1*yh_ratio_hat(-1) + h_pac_c_var_c_hat_lag_1*c_hat(-1);

	[blockname='',name='ln_c_level']
	// Round 1.2 (2026-05-22): + b_HtM*(wt_H_real_gap - yhat_au) = hand-to-mouth
	// (rule-of-thumb) consumer response to wage+transfer income relative to
	// per-capita output (FR-BDF wp1044 §3.5.1 eq 35). Contemporaneous channel,
	// applied here in production model rather than aux file because Dynare 6.5
	// pac.print() crashes when a var_model state appears on the RHS of the PAC
	// equation. wt_H_real_gap is itself a var_model state (companion matrix is
	// extended), so the AR(1)-side feedback to expectations is preserved.
	// Phase L1.3a (2026-05-25): + b_PAC_c*dy_bar_gap(-1) growth-neutrality
	// term tying consumption growth to HP-filtered trend GDP growth (wp1044
	// Eq 35).  Production-model dy_bar_gap evolves as a RW around 0 (data
	// path is loaded only by au_pac_bayesian.mod via varobs).
	diff(ln_c_level) =  b0_c*(c_hat(-1)-ln_c_level(-1))+b1_c*diff(ln_c_level(-1))+pac_expectation_pac_c+i_gap(-1)*b2_c+yhat_au*b3_c+b_HtM*(wt_H_real_gap-yhat_au)+b_PAC_c*dy_bar_gap(-1)+eps_c;

	[blockname='',name='yh_ratio_hat']
	yh_ratio_hat =  rho_yh_aux*yh_ratio_hat(-1)+yhat_au(-1)*a_yh_y+u_gap(-1)*a_yh_u+eps_var_yh;

	[blockname='',name='c_hat']
	c_hat =  rho_c_aux*c_hat(-1)+yhat_au(-1)*a_c_y+i_gap(-1)*a_c_i+pi_au_gap(-1)*a_c_pi+u_gap(-1)*a_c_u+yh_ratio_hat(-1)*a_c_yh+tau_PAYG_gap(-1)*a_c_PAYG+eps_var_c;

	[blockname='',name='pac_expectation_pac_ib']
	pac_expectation_pac_ib =  h_pac_ib_constant + h_pac_ib_var_yhat_au_lag_1*yhat_au(-1) + h_pac_ib_var_i_gap_lag_1*i_gap(-1) + h_pac_ib_var_pi_au_gap_lag_1*pi_au_gap(-1) + h_pac_ib_var_u_gap_lag_1*u_gap(-1) + h_pac_ib_var_yhat_us_lag_1*yhat_us(-1) + h_pac_ib_var_pi_us_gap_lag_1*pi_us_gap(-1) + h_pac_ib_var_ibar_lag_1*ibar(-1) + h_pac_ib_var_pibar_au_lag_1*pibar_au(-1) + h_pac_ib_var_pibar_us_lag_1*pibar_us(-1) + h_pac_ib_var_piQ_lag_1*piQ(-1) + h_pac_ib_var_pi_m_lag_1*pi_m(-1) + h_pac_ib_var_dln_pcom_lag_1*dln_pcom(-1) + h_pac_ib_var_tau_CIT_gap_lag_1*tau_CIT_gap(-1) + h_pac_ib_var_ib_hat_lag_1*ib_hat(-1) + h_pac_ib_var_rKB_hat_lag_1*rKB_hat(-1);

	[blockname='',name='ln_ib_level']
	diff(ln_ib_level) =  b0_ib*(ib_hat(-1)-ln_ib_level(-1))+b1_ib*diff(ln_ib_level(-1))+b2_ib*diff(ln_ib_level(-2))+pac_expectation_pac_ib+yhat_au*b3_ib+eps_ib;

	[blockname='',name='ib_hat']
	ib_hat =  rho_ib_aux*ib_hat(-1)+yhat_au(-1)*a_ib_y+pi_au_gap(-1)*a_ib_pi+u_gap(-1)*a_ib_u+tau_CIT_gap(-1)*a_ib_CIT+eps_var_ib;

	[blockname='',name='rKB_hat']
	rKB_hat =  rho_rKB_aux*rKB_hat(-1)+i_gap(-1)*a_rKB_i+tau_CIT_gap(-1)*a_rKB_CIT+eps_var_rKB;

	[blockname='',name='pac_expectation_pac_ih']
	pac_expectation_pac_ih =  h_pac_ih_constant + h_pac_ih_var_yhat_au_lag_1*yhat_au(-1) + h_pac_ih_var_i_gap_lag_1*i_gap(-1) + h_pac_ih_var_pi_au_gap_lag_1*pi_au_gap(-1) + h_pac_ih_var_u_gap_lag_1*u_gap(-1) + h_pac_ih_var_yhat_us_lag_1*yhat_us(-1) + h_pac_ih_var_pi_us_gap_lag_1*pi_us_gap(-1) + h_pac_ih_var_ibar_lag_1*ibar(-1) + h_pac_ih_var_pibar_au_lag_1*pibar_au(-1) + h_pac_ih_var_pibar_us_lag_1*pibar_us(-1) + h_pac_ih_var_piQ_lag_1*piQ(-1) + h_pac_ih_var_pi_m_lag_1*pi_m(-1) + h_pac_ih_var_dln_pcom_lag_1*dln_pcom(-1) + h_pac_ih_var_ih_hat_lag_1*ih_hat(-1);

	[blockname='',name='ln_ih_level']
	diff(ln_ih_level) =  b0_ih*(ih_hat(-1)-ln_ih_level(-1))+b1_ih*diff(ln_ih_level(-1))+b2_ih*diff(ln_ih_level(-2))+pac_expectation_pac_ih+yhat_au*b3_ih+eps_ih;

	[blockname='',name='ih_hat']
	ih_hat =  rho_ih_aux*ih_hat(-1)+yhat_au(-1)*a_ih_y+i_gap(-1)*a_ih_i+pi_au_gap(-1)*a_ih_pi+u_gap(-1)*a_ih_u+eps_var_ih;

	[blockname='',name='pac_expectation_pac_n']
	pac_expectation_pac_n =  h_pac_n_constant + h_pac_n_var_yhat_au_lag_1*yhat_au(-1) + h_pac_n_var_i_gap_lag_1*i_gap(-1) + h_pac_n_var_pi_au_gap_lag_1*pi_au_gap(-1) + h_pac_n_var_u_gap_lag_1*u_gap(-1) + h_pac_n_var_yhat_us_lag_1*yhat_us(-1) + h_pac_n_var_pi_us_gap_lag_1*pi_us_gap(-1) + h_pac_n_var_ibar_lag_1*ibar(-1) + h_pac_n_var_pibar_au_lag_1*pibar_au(-1) + h_pac_n_var_pibar_us_lag_1*pibar_us(-1) + h_pac_n_var_piQ_lag_1*piQ(-1) + h_pac_n_var_pi_m_lag_1*pi_m(-1) + h_pac_n_var_dln_pcom_lag_1*dln_pcom(-1) + h_pac_n_var_dln_pop_bar_lag_1*dln_pop_bar(-1) + h_pac_n_var_n_hat_lag_1*n_hat(-1);

	[blockname='',name='ln_n_level']
	diff(ln_n_level) =  b0_n*(n_hat(-1)-ln_n_level(-1))+b1_n*diff(ln_n_level(-1))+b2_n*diff(ln_n_level(-2))+b3_n*diff(ln_n_level(-3))+b4_n*diff(ln_n_level(-4))+pac_expectation_pac_n+yhat_au*b5_n+eps_n;

	[blockname='',name='n_hat']
	n_hat =  rho_n_aux*n_hat(-1)+yhat_au(-1)*a_n_y+i_gap(-1)*a_n_i+pi_au_gap(-1)*a_n_pi+u_gap(-1)*a_n_u+dln_pop_bar(-1)*a_n_pop+eps_var_n;

	[blockname='',name='i_au']
	i_au =  i_gap + ibar;

	[blockname='',name='di_gap']
	di_gap =  i_gap - i_gap(-1);

	[blockname='',name='pi_au']
	pi_au =  pi_au_gap + pibar_au;

[name='def_pi_w_gap']
	pi_w_gap = pi_w - pibar_au;

	[blockname='',name='pi_us']
	pi_us =  pi_us_gap + pibar_us;

	[blockname='',name='yhat_au']
	yhat_au =  delta * yhat_us + lambda_q * yhat_au(-1) - sigma_q * (i_gap(-1) - pi_au_gap(-1)) + lambda_dom * yhat_dom + eps_q;

	[blockname='',name='i_gap']
	i_gap =  lambda_i * i_gap(-1) + (1 - lambda_i) * (alpha_i * pi_au_gap(-1) + beta_i * yhat_au(-1)) + eps_i;

	[blockname='',name='pi_au_gap']
// Phase V: FR-BDF eq (80) ECM rewrite — see PRICE_RESPONSE_DIAGNOSIS.md
	pi_au_gap =  lambda_pi * pi_au_gap(-1) + kappa_pi * yhat_au(-1) + alpha_pc * (piQ - pibar_au) + alpha_pc_lag * (piQ(-1) - pibar_au(-1)) + beta_pc_m * (pi_m - pibar_au) + gamma_oil * dln_pcom + b_ECM_pc * (p_C_star_level(-1) - p_C_level(-1)) + eps_pi;

[blockname='',name='def_p_C_level']
	p_C_level = p_C_level(-1) + pi_au_gap;

[blockname='',name='def_p_M_level']
	p_M_level = p_M_level(-1) + (pi_m - pibar_au);

[blockname='',name='def_p_C_star_level']
	p_C_star_level = (1 - omega_pc) * pQ_level + omega_pc * p_M_level;

	// BI deflator level accumulator + LR target (wp1044 §3.6.3 Eq 55)
	[blockname='',name='def_p_IB_level']
	p_IB_level = p_IB_level(-1) + (pi_ib - pibar_au);

	[blockname='',name='def_p_IB_star_level']
	p_IB_star_level = omega_pib * pQ_level + (1 - omega_pib) * p_M_level;

	// Housing-inv deflator level accumulator + LR target (wp1044 §3.6.2 Eq 54)
	[blockname='',name='def_p_IH_level']
	p_IH_level = p_IH_level(-1) + (pi_ih - pibar_au);

	[blockname='',name='def_p_IH_star_level']
	p_IH_star_level = omega_pih * pQ_level + (1 - omega_pih) * p_M_level;

	[blockname='',name='yhat_us']
	yhat_us =  lambda_q_us * yhat_us(-1) + eps_q_us;

	[blockname='',name='pi_us_gap']
	pi_us_gap =  lambda_pi_us * pi_us_gap(-1) + kappa_pi_us * yhat_us(-1) + eps_pi_us;

	[blockname='',name='ibar']
	ibar =  lambda_ibar * ibar(-1) + (1 - lambda_ibar) * i_ss + eps_ibar;

	[blockname='',name='pibar_au']
	pibar_au =  lambda_pibar * pibar_au(-1) + (1 - lambda_pibar) * pi_ss_au + eps_pibar_au;

	[blockname='',name='pibar_us']
	pibar_us =  lambda_pibar_us * pibar_us(-1) + (1 - lambda_pibar_us) * pi_ss_us + eps_pibar_us;

	[blockname='',name='piQ']
	piQ =  (pQ_level - pQ_level(-1)) + pi_ss_au;

	[blockname='',name='dln_c']
	dln_c =  ln_c_level - ln_c_level(-1);

	[blockname='',name='dln_ib']
	dln_ib =  ln_ib_level - ln_ib_level(-1);

	[blockname='',name='dln_ih']
	dln_ih =  ln_ih_level - ln_ih_level(-1);

	[blockname='',name='dln_n']
	dln_n =  ln_n_level - ln_n_level(-1);

	[blockname='',name='dln_k']
	dln_k =  (1 - delta_k) * dln_k(-1) + delta_k * dln_ib;

	[blockname='',name='ln_QN']
	ln_QN =  ln_QN(-1) + dln_y_star;

	[blockname='',name='ln_Q']
	ln_Q =  ln_QN + yhat_au;

	[blockname='',name='ln_C_star']
	ln_C_star =  ln_C_star(-1) + dln_c_star_bar;

	[blockname='',name='ln_C']
	ln_C =  ln_C_star + ln_c_level;

	[blockname='',name='ln_IB_star']
	ln_IB_star =  ln_IB_star(-1) + dln_ib_star_bar;

	[blockname='',name='ln_IB']
	ln_IB =  ln_IB_star + ln_ib_level;

	[blockname='',name='ln_IH_star']
	ln_IH_star =  ln_IH_star(-1) + dln_ih_star_bar;

	[blockname='',name='ln_IH']
	ln_IH =  ln_IH_star + ln_ih_level;

	[blockname='',name='ln_N_star']
	ln_N_star =  ln_N_star(-1) + dln_n_star_bar;

	[blockname='',name='ln_N']
	ln_N =  ln_N_star + ln_n_level;

	[blockname='',name='ln_K']
	ln_K =  ln_K(-1) + dln_k;

	[blockname='',name='ln_P_star']
	ln_P_star =  ln_P_star(-1) + (pibar_au - pi_ss_au);

	[blockname='',name='ln_P']
	ln_P =  ln_P_star + pQ_level;

	[blockname='',name='dln_y_star']
	dln_y_star =  alpha_k * dln_k + (1 - alpha_k) * dln_n_star_bar + dln_tfp;

	[blockname='',name='ln_tfp_LR']
	ln_tfp_LR =  ln_tfp_LR(-1) + eps_tfp_LR;

	[blockname='',name='ln_tfp']
	ln_tfp =  rho_tfp * ln_tfp(-1) + (1 - rho_tfp) * ln_tfp_LR;

	[blockname='',name='dln_tfp']
	dln_tfp =  ln_tfp - ln_tfp(-1);

	[blockname='',name='dln_prod']
	dln_prod =  dln_tfp / (1 - alpha_k);

	[blockname='',name='dln_ulc']
	dln_ulc =  pi_w - dln_prod;

	[blockname='',name='pv_piQ_aux']
	pv_piQ_aux =  rho_pQ_aux * pv_piQ_aux(-1) + a_pQ_y * yhat_au(-1) + a_pQ_i * i_gap(-1) + a_pQ_pi * pi_au_gap(-1) + a_pQ_u * u_gap(-1) + a_pQ_w * pi_w_gap(-1);

	[blockname='',name='pv_n_aux']
	pv_n_aux =  rho_n_aux * pv_n_aux(-1) + a_n_y * yhat_au(-1) + a_n_i * i_gap(-1) + a_n_pi * pi_au_gap(-1) + a_n_u * u_gap(-1);

	[blockname='',name='pv_c_aux']
	pv_c_aux =  rho_c_aux * pv_c_aux(-1) + a_c_y * yhat_au(-1) + a_c_i * i_gap(-1) + a_c_pi * pi_au_gap(-1) + a_c_u * u_gap(-1);

	[blockname='',name='pv_ib_aux']
	pv_ib_aux =  rho_ib_aux * pv_ib_aux(-1) + a_ib_y * yhat_au(-1) + a_ib_pi * pi_au_gap(-1) + a_ib_u * u_gap(-1);

	[blockname='',name='pv_rKB_aux']
	pv_rKB_aux =  rho_rKB_aux * pv_rKB_aux(-1) + a_rKB_i * i_gap(-1);

	[blockname='',name='pv_ih_aux']
	pv_ih_aux =  rho_ih_aux * pv_ih_aux(-1) + a_ih_y * yhat_au(-1) + a_ih_i * i_gap(-1) + a_ih_pi * pi_au_gap(-1) + a_ih_u * u_gap(-1);

	[blockname='',name='u_gap']
	u_gap =  rho_u_gap * u_gap(-1) + okun_coeff * yhat_au;

	[blockname='',name='pv_u_gap']
	pv_u_gap =  (1 - beta_w) * u_gap + beta_w * pv_u_gap(+1);

	[blockname='',name='pi_w']
	pi_w =  lambda_w * pi_w(-1) + gamma_w * pi_c - kappa_w * pv_u_gap + (1 - lambda_w - gamma_w) * pibar_au + (1 - lambda_w) * dln_prod + eps_w;

	[blockname='',name='dln_n_star']
	dln_n_star =  rho_n_star * dln_n_star(-1) + (1 - rho_n_star) * dln_n_star_bar;

	[blockname='',name='dln_n_star_bar']
	// Round 5 (2026-05-20): + dln_pop_bar — demographic trend shifter.
	dln_n_star_bar =  (yhat_au - yhat_au(-1)) - dln_tfp / (1 - alpha_k) - sigma_ces * rw_gap + dln_pop_bar;

	[blockname='',name='n_gap']
	n_gap =  n_gap(-1) + dln_n_star - dln_n;

	[blockname='',name='dln_n_1']
	dln_n_1 =  dln_n(-1);

	[blockname='',name='dln_n_2']
	dln_n_2 =  dln_n_1(-1);

	[blockname='',name='dln_n_3']
	dln_n_3 =  dln_n_2(-1);

	[blockname='',name='dln_c_star']
	dln_c_star =  rho_c_star * dln_c_star(-1) + (1 - rho_c_star) * dln_c_star_bar;

	[blockname='',name='pv_yh']
	pv_yh =  (1 - beta_c) * yhat_au + beta_c * pv_yh(+1);

	[blockname='',name='pv_r_lh_gap']
	pv_r_lh_gap =  (1 - beta_c) * (i_lh - pi_c - (i_ss + tp_ss + spread_lh - pi_ss_au)) + beta_c * pv_r_lh_gap(+1);

	[blockname='',name='dln_c_star_bar']
	// Round 6 (2026-05-20): - alpha_PAYG · Δtau_PAYG_gap — income-tax drag.
	dln_c_star_bar =  kappa_inc * (pv_yh - pv_yh(-1)) + alpha_c_r * ((i_lh - pi_c - (i_ss + tp_ss + spread_lh - pi_ss_au)) - (i_lh(-1) - pi_c(-1) - (i_ss + tp_ss + spread_lh - pi_ss_au))) - alpha_PAYG * (tau_PAYG_gap - tau_PAYG_gap(-1));

	[blockname='',name='c_gap']
	c_gap =  c_gap(-1) + dln_c_star - dln_c;

	[blockname='',name='dln_ib_star']
	dln_ib_star =  rho_ib_star * dln_ib_star(-1) + (1 - rho_ib_star) * dln_ib_star_bar;

	[blockname='',name='uc_k']
	// Round 6 (2026-05-20): + alpha_CIT · tau_CIT_gap — corporate income tax bump.
	uc_k =  wacc + delta_k - (pi_ib - piQ) + alpha_CIT * tau_CIT_gap;

	[blockname='',name='dln_uc_k']
	dln_uc_k =  uc_k - uc_k(-1);

	[blockname='',name='dln_ib_star_bar']
	dln_ib_star_bar =  kappa_ib_y * yhat_au - sigma_ces * dln_uc_k;

	[blockname='',name='ib_gap']
	ib_gap =  ib_gap(-1) + dln_ib_star - dln_ib;

	[blockname='',name='dln_ib_1']
	dln_ib_1 =  dln_ib(-1);

	[blockname='',name='dln_ih_star']
	dln_ih_star =  rho_ih_star * dln_ih_star(-1) + (1 - rho_ih_star) * dln_ih_star_bar;

	[blockname='',name='dln_ih_star_bar']
	dln_ih_star_bar =  kappa_ih_inc * (pv_yh - pv_yh(-1)) - kappa_mort * (i_lh - (i_ss + tp_ss + spread_lh)) + kappa_ph * ph_gap(-1);

	[blockname='',name='ih_gap']
	ih_gap =  ih_gap(-1) + dln_ih_star - dln_ih;

	[blockname='',name='dln_ih_1']
	dln_ih_1 =  dln_ih(-1);

	[blockname='',name='tp']
	tp =  rho_tp * tp(-1) + (1 - rho_tp) * tp_ss + eps_tp;

	[blockname='',name='pv_i']
	pv_i =  (1 - kappa_10) * i_au + kappa_10 * pv_i(+1);

	[blockname='',name='i_10y']
	i_10y =  pv_i + tp + eps_10y;

	[blockname='',name='s_COE']
	s_COE =  (1 - rho_COE) * s_COE_ss + rho_COE * s_COE(-1) + eps_COE;

	[blockname='',name='s_LB_firms']
	// wp1044 §3.5.3 Eq 50: spread responds to leverage (proxied by output gap).
	// Negative kappa_spread: falling output gap → wider spread (higher credit risk).
	s_LB_firms =  (1 - rho_LB_firms) * s_LB_firms_ss + rho_LB_firms * s_LB_firms(-1) + kappa_spread_LB * yhat_au + eps_LB_firms;

	[blockname='',name='s_BBB']
	s_BBB =  (1 - rho_BBB) * s_BBB_ss + rho_BBB * s_BBB(-1) + kappa_spread_BBB * yhat_au + eps_BBB;

	[blockname='',name='i_COE']
	i_COE =  i_10y + s_COE;

	[blockname='',name='i_LB_firms']
	i_LB_firms =  i_10y + s_LB_firms;

	[blockname='',name='i_BBB']
	i_BBB =  i_10y + s_BBB;

	[blockname='',name='wacc']
	wacc =  w_COE * i_COE + w_LB_firms * i_LB_firms + w_BBB * i_BBB;

	[blockname='',name='pv_i_uip']
	pv_i_uip =  (i_au - ibar) + beta_uip * pv_i_uip(+1);

	[blockname='',name='s_gap']
	s_gap =  rho_s * s_gap(-1) - alpha_s * pv_i_uip + alpha_s * (pi_au_gap - pi_us_gap) + eps_s;

	[blockname='',name='ln_x_level']
	ln_x_level =  ln_x_level(-1) + dln_x;

	[blockname='',name='ln_m_level']
	ln_m_level =  ln_m_level(-1) + dln_m;

	[blockname='',name='ln_d_iad']
	ln_d_iad =  ln_d_iad(-1) + iad;

	[blockname='',name='ln_x_eq']
	ln_x_eq =  beta_x * yhat_us + gamma_x * s_gap;

	[blockname='',name='x_gap']
	x_gap =  ln_x_eq - ln_x_level;

	[blockname='',name='dln_x']
	dln_x =  b0_x * x_gap(-1) + b1_x * dln_x(-1) + b2_x * yhat_us + b3_x * s_gap + b4_x * dln_pcom + eps_x;

	[blockname='',name='ln_m_eq']
	ln_m_eq =  beta_m * ln_d_iad + gamma_m * s_gap;

	[blockname='',name='m_gap']
	m_gap =  ln_m_eq - ln_m_level;

	[blockname='',name='dln_m']
	dln_m =  b0_m * m_gap(-1) + b1_m * dln_m(-1) + b2_m * iad + b3_m * s_gap + eps_m;

	[blockname='',name='pi_c']
	// Round 6 (2026-05-20): + alpha_GST · tau_GST_gap — GST passthrough.
	pi_c =  rho_pc * pi_c(-1) + alpha_pc * piQ + beta_pc_m * pi_m + gamma_oil * dln_pcom + (1 - rho_pc - alpha_pc - beta_pc_m) * pibar_au + alpha_GST * tau_GST_gap + eps_pc;

	[blockname='',name='pi_ib']
	// wp1044 §3.6.3: BI deflator with ECM term pulling toward LR target p*_IB
	pi_ib =  rho_pib * pi_ib(-1) + alpha_pib * piQ + beta_pib_m * pi_m + (1 - rho_pib - alpha_pib - beta_pib_m) * pibar_au + b_ECM_pib * (p_IB_star_level(-1) - p_IB_level(-1)) + eps_pib;

	[blockname='',name='pi_ih']
	// wp1044 §3.6.2: housing-inv deflator with ECM term pulling toward LR target p*_IH
	pi_ih =  rho_pih * pi_ih(-1) + alpha_pih * piQ + beta_pih_m * pi_m + (1 - rho_pih - alpha_pih - beta_pih_m) * pibar_au + b_ECM_pih * (p_IH_star_level(-1) - p_IH_level(-1)) + eps_pih;

	[blockname='',name='pi_x']
	pi_x =  rho_px * pi_x(-1) + alpha_px * piQ + (1 - rho_px - alpha_px) * pibar_au + beta_px * s_gap + alpha_pcom * dln_pcom + eps_px;

	[blockname='',name='pi_m']
	pi_m =  rho_pm * pi_m(-1) + alpha_pm * piQ + (1 - rho_pm - alpha_pm) * pibar_au + beta_pm * s_gap + beta_pm_com * dln_pcom + eps_pm;

	[blockname='',name='dln_pcom']
	dln_pcom =  rho_pcom * dln_pcom(-1) + 0.10 * yhat_us + eps_pcom;

	[blockname='',name='dln_g']
	dln_g =  rho_g * dln_g(-1) + phi_g * yhat_au + eps_g;

	[blockname='',name='pi_g']
	pi_g =  rho_pg * pi_g(-1) + alpha_pg * (pi_w - dln_prod) + (1 - rho_pg - alpha_pg) * pibar_au + eps_pg;

	[blockname='',name='yhat_dom']
	yhat_dom =  w_c * dln_c + w_ib * dln_ib + w_ih * dln_ih + w_g * dln_g + w_x * dln_x - w_m * dln_m;

	[blockname='',name='rw_gap']
	rw_gap =  pi_w - piQ - dln_prod;

	[blockname='',name='iad']
	iad =  w_iad_c * dln_c + w_iad_ib * dln_ib + w_iad_ih * dln_ih + w_iad_g * dln_g + w_iad_x * dln_x;

	[blockname='',name='i_lh']
	i_lh =  rho_lh * i_lh(-1) + (1 - rho_lh) * (i_10y + spread_lh) + eps_lh;

	[blockname='',name='dln_ph']
	dln_ph =  rho_ph * dln_ph(-1) + alpha_ph_y * yhat_au + alpha_ph_r * i_gap(-1) + eps_ph;

	[blockname='',name='ph_gap']
	ph_gap =  0.98 * ph_gap(-1) + dln_ph;

	[blockname='',name='i_F']
	i_F =  i_F_prem * (1 - rho_i_asset) + (1 - rho_i_asset) * i_10y + rho_i_asset * i_F(-1);

	[blockname='',name='i_G']
	i_G =  (1 - rho_i_asset) * i_10y + rho_i_asset * i_G(-1);

	[blockname='',name='i_H']
	i_H =  i_H_prem * (1 - rho_i_asset) + (1 - rho_i_asset) * i_10y + rho_i_asset * i_H(-1);

	[blockname='',name='i_N']
	i_N =  i_N_prem * (1 - rho_i_asset) + (1 - rho_i_asset) * i_10y + rho_i_asset * i_N(-1);

	[blockname='',name='yf_F']
	yf_F =  i_F * w_F_ss - tau_F;

	[blockname='',name='yf_G']
	yf_G =  i_G * w_G_ss;

	[blockname='',name='yf_H']
	yf_H =  i_H * (-(w_F_ss + w_G_ss + w_N_ss)) + tau_F + tau_N;

	[blockname='',name='yf_N']
	yf_N =  i_N * w_N_ss - tau_N;

	[blockname='',name='tau_F']
	tau_F =  (1 - rho_stab_1) * tau_F(-1) + rho_stab_1 * tau_F_ss;

	[blockname='',name='tau_N']
	tau_N =  (1 - rho_stab_1) * tau_N(-1) + rho_stab_1 * tau_N_ss;

	[blockname='',name='tau_G']
	tau_G =  (1 - rho_stab_1) * tau_G(-1) + rho_stab_1 * tau_G_ss + 0.05 * yhat_au;

	[blockname='',name='b_F']
	b_F =  -w_ib * dln_ib - (tau_F - tau_F_ss) + (i_F - (i_ss + tp_ss + i_F_prem)) * w_F_ss;

	[blockname='',name='b_G']
	b_G =  -w_g * dln_g + 0.30 * yhat_au - (tau_G - tau_G_ss) + (i_G - (i_ss + tp_ss)) * w_G_ss;

	[blockname='',name='b_H']
	b_H =  w_c * (yhat_au - dln_c) - w_ih * dln_ih + (i_H - (i_ss + tp_ss + i_H_prem)) * (-(w_F_ss+w_G_ss+w_N_ss));

	[blockname='',name='b_N']
	b_N =  (i_N - (i_ss + tp_ss + i_N_prem)) * w_N_ss;

	[blockname='',name='w_F']
	w_F =  0.98 * w_F(-1) + 0.02 * w_F_ss + b_F;

	[blockname='',name='w_G']
	w_G =  0.98 * w_G(-1) + 0.02 * w_G_ss + b_G;

	[blockname='',name='w_H']
	w_H =  0.98 * w_H(-1) + 0.02 * (-(w_F_ss+w_G_ss+w_N_ss)) + b_H;

	[blockname='',name='w_N']
	w_N =  0.98 * w_N(-1) + 0.02 * w_N_ss + b_N;

	[blockname='',name='b_ROW']
	b_ROW =  -(b_F + b_G + b_H + b_N);

	// Round 1.1: HICP-style headline-decomposition reporting block.
	// One-way projections of headline CPI onto core/food/energy and
	// tradeables/non-tradeables splits, plus a trimmed-mean smoother.
	// Zero feedback into existing dynamics.

	[blockname='',name='pi_au_food']
	pi_au_food = delta_food_piQ * piQ + (1 - delta_food_piQ) * pibar_au + delta_food_pcom * dln_pcom;

	[blockname='',name='pi_au_energy']
	pi_au_energy = delta_energy_pm * pi_m + (1 - delta_energy_pm) * pibar_au + delta_energy_pcom * dln_pcom;

	[blockname='',name='pi_au_core']
	pi_au_core = (pi_au - w_cpi_food * pi_au_food - w_cpi_energy * pi_au_energy) / (1 - w_cpi_food - w_cpi_energy);

	[blockname='',name='pi_au_trad']
	pi_au_trad = delta_trad_pm * pi_m + (1 - delta_trad_pm) * pibar_au + delta_trad_pcom * dln_pcom + delta_trad_s * s_gap;

	[blockname='',name='pi_au_nontrad']
	pi_au_nontrad = (pi_au - w_cpi_trad * pi_au_trad) / (1 - w_cpi_trad);

	[blockname='',name='pi_au_trim']
	pi_au_trim = rho_trim * pi_au_trim(-1) + (1 - rho_trim) * (delta_trim_piQ * piQ + (1 - delta_trim_piQ) * pibar_au);

	// =====================================================================
	// Round 4-8 (2026-05-20) — new model blocks
	// =====================================================================

	[blockname='',name='dln_pop_bar']
	dln_pop_bar = rho_pop * dln_pop_bar(-1) + eps_pop_bar;

	[blockname='',name='ibar_us']
	ibar_us = lambda_ibar_us * ibar_us(-1) + (1 - lambda_ibar_us) * i_ss_us + eps_ibar_us;

	[blockname='',name='i_us']
	i_us = ibar_us + alpha_i_us * pi_us_gap(-1) + beta_i_us * yhat_us(-1) + eps_i_us;

	[blockname='',name='tau_GST_gap']
	tau_GST_gap = rho_tau_GST * tau_GST_gap(-1) + eps_tau_GST;

	[blockname='',name='tau_PAYG_gap']
	tau_PAYG_gap = rho_tau_PAYG * tau_PAYG_gap(-1) + eps_tau_PAYG;

	[blockname='',name='tau_CIT_gap']
	tau_CIT_gap = rho_tau_CIT * tau_CIT_gap(-1) + eps_tau_CIT;

	// Round 1.2 (2026-05-22): household wage+transfer real-income gap, reduced-form
	// AR(1) matching aux_consumption.mod var_wt_H_real_gap (so companion matrix used
	// by pac_expectation_pac_c is consistent with the structural simulation).
	[blockname='',name='wt_H_real_gap']
	wt_H_real_gap = rho_wtH * wt_H_real_gap(-1) + alpha_wtH_y * yhat_au(-1) + alpha_wtH_u * u_gap(-1) + alpha_wtH_tau * tau_PAYG_gap(-1) + eps_wtH;

	[blockname='',name='yhat_nonmarket']
	yhat_nonmarket = rho_nonmarket * yhat_nonmarket(-1) + (1 - rho_nonmarket) * gamma_nonmarket * yhat_au;

	[blockname='',name='yhat_market']
	yhat_market = (yhat_au - (1 - w_market) * yhat_nonmarket) / w_market;

	[blockname='',name='BLR_hat']
	BLR_hat = rho_BLR * BLR_hat(-1) + (1 - rho_BLR) * (i_lh - i_ss - tp_ss - spread_lh) + eps_BLR;

	[blockname='',name='MAPI_hat']
	MAPI_hat = rho_MAPI * MAPI_hat(-1) + (1 - rho_MAPI) * ph_gap + eps_MAPI;

	[blockname='',name='MAPU_hat']
	MAPU_hat = rho_MAPU * MAPU_hat(-1) + (1 - rho_MAPU) * dln_ih + eps_MAPU;

	// Phase L1.3a (2026-05-25): wp1044 Eq 35 growth-neutrality trend.
	// In the production model dy_bar_gap follows a RW around zero with
	// eps_dy_bar innovations; in au_pac_bayesian.mod the same variable is
	// declared as varobs so the Kalman filter pulls it onto the HP-trend
	// data path.
	[blockname='',name='dy_bar_gap']
	dy_bar_gap = dy_bar_gap(-1) + eps_dy_bar;

end;

steady_state_model;

    // E-SAT
    ibar     = i_ss;
    pibar_au = pi_ss_au;
    pibar_us = pi_ss_us;
    yhat_au  = 0;
    yhat_us  = 0;
    i_au     = i_ss;
    pi_au    = pi_ss_au;
    pi_us    = pi_ss_us;
    i_gap    = 0;
    di_gap   = 0;
    pi_au_gap = 0;
    pi_us_gap = 0;

    // Production function (Section 4.3)
    dln_k        = 0;         // zero capital growth at SS (gap model)
    dln_y_star   = 0;         // zero potential output growth at SS (gap model)
    dln_tfp      = 0;         // zero TFP growth at SS
    ln_tfp_LR    = 0;         // FR-BDF Ē_t residual at baseline (gap model)
    ln_tfp       = 0;         // smoothed TFP level converges to ln_tfp_LR = 0 at SS

    // Wage-price spiral (Stage 9c)
    dln_prod     = 0;         // zero productivity growth at SS
    dln_ulc      = pi_ss_au;  // ULC grows at inflation rate at SS

    // VA price block
    piQ          = pi_ss_au;

    // Wage Phillips curve
    u_gap        = 0;         // unemployment at equilibrium at SS
    pv_u_gap     = 0;         // PV of future unemployment gaps = 0 at SS
    pi_w         = pi_ss_au;  // wages grow at LR inflation rate at SS
    pi_w_gap     = 0;         // Phase U: SS deviation of pi_w from pibar_au

    // Employment PAC
    dln_n          = 0;       // zero employment growth in stationary model
    dln_n_star     = 0;
    dln_n_star_bar = 0;
    n_gap          = 0;
    dln_n_1        = 0;
    dln_n_2        = 0;
    dln_n_3        = 0;

    // Household consumption PAC
    pv_yh          = 0;       // permanent income PV = 0 at SS (gap model)
    pv_r_lh_gap    = 0;       // real lending rate PV = 0 at SS (audit #26, FR-BDF eq 61)
    dln_c          = 0;       // zero consumption growth in stationary model
    dln_c_star     = 0;
    dln_c_star_bar = 0;
    c_gap          = 0;

    // User cost of capital: uc_k = wacc + delta_k at SS (pi_ib = piQ at SS)
    uc_k           = w_COE*(i_ss+tp_ss+s_COE_ss) + w_LB_firms*(i_ss+tp_ss+s_LB_firms_ss) + w_BBB*(i_ss+tp_ss+s_BBB_ss) + delta_k;
    dln_uc_k       = 0;            // user cost constant at SS

    // Business investment PAC
    dln_ib         = 0;       // zero investment growth in stationary model
    dln_ib_star    = 0;
    dln_ib_star_bar = 0;
    ib_gap         = 0;
    dln_ib_1       = 0;

    // Household investment PAC
    dln_ih         = 0;       // zero housing investment growth in stationary model
    dln_ih_star    = 0;
    dln_ih_star_bar = 0;
    ih_gap         = 0;
    dln_ih_1       = 0;

    // Financial block
    tp             = tp_ss;                         // term premium at SS
    pv_i           = i_ss;                          // PV of future short rates = current rate at SS
    i_10y          = i_ss + tp_ss;                  // 10Y yield = short rate + term premium
    s_COE          = s_COE_ss;                      // equity spread at SS
    s_LB_firms     = s_LB_firms_ss;                 // bank lending spread at SS
    s_BBB          = s_BBB_ss;                      // BBB bond spread at SS
    i_COE          = i_ss + tp_ss + s_COE_ss;       // cost of equity at SS
    i_LB_firms     = i_ss + tp_ss + s_LB_firms_ss;  // bank lending rate firms at SS
    i_BBB          = i_ss + tp_ss + s_BBB_ss;        // BBB bond rate at SS
    wacc           = w_COE*(i_ss+tp_ss+s_COE_ss) + w_LB_firms*(i_ss+tp_ss+s_LB_firms_ss) + w_BBB*(i_ss+tp_ss+s_BBB_ss);
    s_gap          = 0;                             // PPP holds at SS
    pv_i_uip       = 0;                             // forward UIP PV = 0 at SS (i_au = ibar)

    // Trade block (proper ECM, all level deviations zero at SS)
    dln_x          = 0;       // zero export growth in stationary model
    ln_x_level     = 0;
    ln_x_eq        = 0;       // = beta_x*0 + gamma_x*0 = 0
    x_gap          = 0;
    dln_m          = 0;       // zero import growth in stationary model
    ln_m_level     = 0;
    ln_m_eq        = 0;       // = beta_m*0 + gamma_m*0 = 0
    m_gap          = 0;
    ln_d_iad       = 0;       // cumulated iad = 0 at SS (iad SS = 0)

    // Demand deflators: all converge to pi_ss_au at SS
    pi_c           = pi_ss_au;
    pi_ib          = pi_ss_au;
    pi_ih          = pi_ss_au;
    pi_x           = pi_ss_au;
    pi_m           = pi_ss_au;

    // Commodity prices (Stage 11b)
    dln_pcom       = 0;       // zero commodity price growth at SS

    // Government
    dln_g          = 0;       // zero government spending growth in stationary model
    pi_g           = pi_ss_au;

    // GDP identity
    yhat_dom       = 0;       // zero at SS (all components zero)

    // Stage 12: new variables
    rw_gap         = 0;                            // pi_w - piQ - dln_prod = pi_ss - pi_ss - 0 = 0
    iad            = 0;                            // all dln_j = 0 => iad = 0
    i_lh           = i_ss + tp_ss + spread_lh;     // bank lending rate at SS
    dln_ph         = 0;                            // zero real housing price growth at SS
    ph_gap         = 0;                            // housing prices at trend at SS

    // Sector financial accounts
    w_F            = w_F_ss;                       // firms at SS net asset ratio
    w_G            = w_G_ss;                       // government at SS debt ratio
    w_N            = w_N_ss;                       // NPISH at SS
    w_H            = -(w_F_ss + w_G_ss + w_N_ss); // households = residual (closed economy)
    i_F            = i_ss + tp_ss + i_F_prem;      // firms effective return at SS
    i_G            = i_ss + tp_ss;                  // government return = i_10y at SS
    i_H            = i_ss + tp_ss + i_H_prem;      // households effective return at SS
    i_N            = i_ss + tp_ss + i_N_prem;      // NPISH effective return at SS
    tau_F          = tau_F_ss;
    tau_G          = tau_G_ss;
    tau_N          = tau_N_ss;
    yf_F           = i_F * w_F_ss - tau_F_ss;      // firms property income at SS
    yf_G           = i_G * w_G_ss;                  // government property income at SS
    yf_H           = i_H * (-(w_F_ss+w_G_ss+w_N_ss)) + tau_F_ss + tau_N_ss;
    yf_N           = i_N * w_N_ss - tau_N_ss;
    b_F            = 0;                             // firms balanced at SS (deviations = 0)
    b_G            = 0;                             // government balanced at SS
    b_H            = 0;                             // households balanced at SS
    b_N            = 0;                             // NPISH balanced at SS
    b_ROW          = 0;                             // ROW balanced at SS

    // PAC TCM variables (zero at SS)
    piQ_aux_l      = 0;
    piQ_star_l     = 0;

    // Log-level variables for PAC (zero at SS — gap model, everything demeaned)
    pQ_level       = 0;

    // Phase V: ECM consumer price level accumulators (zero at SS — gap form)
    p_C_level       = 0;
    p_M_level       = 0;
    p_C_star_level  = 0;
    p_IB_level      = 0;
    p_IB_star_level = 0;
    p_IH_level      = 0;
    p_IH_star_level = 0;

    // Consumption PAC TCM + level variables
    c_aux_l        = 0;
    c_star_l       = 0;
    ln_c_level     = 0;

    // Business investment PAC TCM + level variables
    ib_aux_l       = 0;
    ib_star_l      = 0;
    ln_ib_level    = 0;

    // Household investment PAC TCM + level variables
    ih_aux_l       = 0;
    ih_star_l      = 0;
    ln_ih_level    = 0;

    // Employment PAC TCM + level variables
    n_aux_l        = 0;
    n_star_l       = 0;
    ln_n_level     = 0;

    // Trend level accumulators (all zero at SS)
    ln_QN          = 0;
    ln_Q           = 0;
    ln_C_star      = 0;
    ln_C           = 0;
    ln_IB_star     = 0;
    ln_IB          = 0;
    ln_IH_star     = 0;
    ln_IH          = 0;
    ln_N_star      = 0;
    ln_N           = 0;
    ln_K           = 0;
    ln_P_star      = 0;
    ln_P           = 0;

    // Round 1.1: HICP reporting block — all components at SS = pi_ss_au
    // (identity-preserving: weighted averages of pi_ss_au equal pi_ss_au)
    pi_au_food     = pi_ss_au;
    pi_au_energy   = pi_ss_au;
    pi_au_core     = pi_ss_au;
    pi_au_trad     = pi_ss_au;
    pi_au_nontrad  = pi_ss_au;
    pi_au_trim     = pi_ss_au;

    // Round 5 (demographic trend gap, zero at SS)
    dln_pop_bar    = 0;

    // Round 4 (US monetary policy block)
    ibar_us        = i_ss_us;
    i_us           = i_ss_us;

    // Round 6 (tax gaps, zero at SS)
    tau_GST_gap    = 0;
    tau_PAYG_gap   = 0;
    tau_CIT_gap    = 0;

    // Round 1.2 (2026-05-22): household wage+transfer income gap, zero at SS
    wt_H_real_gap  = 0;

    // Round 7 (branch decomposition, both = 0 at SS)
    yhat_market    = 0;
    yhat_nonmarket = 0;

    // Round 8 (auxiliary forecasters, zero at SS)
    BLR_hat        = 0;
    MAPI_hat       = 0;
    MAPU_hat       = 0;

    // Phase L1.3a (HP-filtered trend GDP growth, demeaned)
    dy_bar_gap     = 0;
end;


// ===================================================================
// Phase L2 P1c hybrid MCMC posterior writeback (2026-05-27)
// Laplace LMD = -696.06, MHM = -697.36 (+88.4 nats vs Round 1.2)
// 25 estimated params (BI calibrated from wp1044 Table 3.5.13)
// ===================================================================
b0_pQ       = 0.0098;   // posterior [0.001, 0.022]
b1_pQ       = 0.1115;   // posterior [0.036, 0.177]
b2_pQ       = 0.0212;   // posterior [-0.042, 0.099]
b0_c        = 0.0519;   // posterior [0.022, 0.081]
b1_c        = 0.0397;   // posterior [0.005, 0.073]
b2_c        = -0.5796;  // posterior [-0.885, -0.287]
b3_c        = 0.0285;   // posterior [-0.054, 0.113]
b0_ib       = 0.0181;   // (Phase V; BI not re-estimated — see line 1766)
b1_ib       = 0.0809;   // (Phase V; overridden by wp1044 at line 1767)
b3_ib       = 0.3120;   // (Phase V; overridden by wp1044 at line 1769)
b0_ih       = 0.0290;   // posterior [0.008, 0.049]
b1_ih       = 0.1074;   // posterior [0.034, 0.182]
b3_ih       = 0.2104;   // posterior [0.041, 0.363]
b0_n        = 0.0537;   // posterior [0.014, 0.088]
b1_n        = 0.2890;   // posterior [0.118, 0.441]
b5_n        = -0.0050;  // posterior [-0.089, 0.078]
lambda_w    = 0.0801;    // hybrid MCMC posterior mean (was 0.2112)
gamma_w     = 0.8090;    // hybrid MCMC posterior mean (was 0.3476)
kappa_w     = -0.0622;   // hybrid MCMC posterior mean (was -0.1111)
// Phase L2 P1c hybrid MCMC writeback (2026-05-27, mcmc_hybrid_r2026a.log):
alpha_pc     = 0.8558;   // VA -> CPI passthrough; posterior [0.786, 0.933] (was 0.2013; FR-BDF 0.71)
kappa_pi     = 0.0258;   // Phillips slope; posterior [-0.024, 0.084] (was 0.0057)
lambda_pi    = 0.5913;   // CPI persistence; posterior [0.470, 0.716] (was 0.1744)
a_pQ_w       = 0.4310;   // wage -> piQ_hat; posterior [0.091, 0.798] (was 0.4367)
alpha_pc_lag = -0.0640;  // lagged VA passthrough; posterior [-0.203, 0.071] (was 0.1135; now ≈ 0)
b_ECM_pc     = 0.0018;   // ECM speed; posterior [0.0004, 0.003] (was 0.0601; now ≈ 0)

// ====================================================================
// Phase W: calibration.inc Bayesian-posterior overrides for the
// aux-regression parameters (inserted 2026-05-17).
//
// The auto-generated parameter block above (≈ lines 431-555) inherits
// PLACEHOLDER values from dynare/aux/aux_*.mod (Phase S OLS starting
// points). The Bayesian posteriors live in
// simulation/identities/calibration.inc but that file is not @#included
// by any .mod — without this block the production model runs the *_hat
// variable processes with stale dynamics.
//
// Effect: these overrides change piQ_hat / c_hat / ib_hat / ih_hat /
// n_hat / yh_ratio_hat / rKB_hat at runtime (see model equations
// around au_pac.mod:767-809), which feeds into PAC equations via
// (i) the b0_*·(*_hat(-1) - level(-1)) ECM term and (ii) the
// h_pac_*_var_*_hat_lag_1 policy-function coefficient.
//
// Caveat: the h_pac_*_var_*_lag_1 coefficients themselves were
// generated by pac.print() against the placeholder VAR, so the
// policy-function projection is no longer fully self-consistent with
// the runtime *_hat process. Full consistency requires re-templating
// the aux .mod files from these posteriors and re-running
// cherrypick + aggregate.
// ====================================================================

// VA-price PAC auxiliary (calibration.inc:310-315)
rho_pQ_aux   =  0.334;   // posterior 90% CI [0.191, 0.476]; was 0.85
a_pQ_y       =  0.043;   // posterior 90% CI [-0.000, 0.087]; was 0.05
a_pQ_i       = -0.021;   // posterior 90% CI [-0.070, 0.029]; was 0
a_pQ_pi      =  0.007;   // posterior 90% CI [-0.042, 0.057]; was 0
a_pQ_u       = -0.021;   // posterior 90% CI [-0.069, 0.027]; was 0
// a_pQ_w already overridden at line 1425 to AU posterior 0.4367.

// Employment PAC auxiliary (calibration.inc:317-322)
rho_n_aux    =  0.743;   // posterior 90% CI [0.669, 0.817]; was 0.67
a_n_y        =  0.094;   // posterior 90% CI [0.036, 0.152]; was 0.12
a_n_i        = -0.031;   // posterior 90% CI [-0.080, 0.018]; was -0.03
a_n_pi       =  0.057;   // posterior 90% CI [0.013, 0.100]; was 0.05
a_n_u        = -0.029;   // posterior 90% CI [-0.076, 0.019]; was -0.04

// Household income-output ratio auxiliary (calibration.inc:324-328)
rho_yh_aux   =  0.93;    // AU smoother (s.e. 0.002); was 0.6
a_yh_y       =  0.12;    // AU smoother (s.e. 0.006); was 0.4
a_yh_u       = -0.07;    // AU smoother (s.e. 0.003); was -0.2

// Consumption PAC auxiliary (calibration.inc:330-336)
rho_c_aux    =  0.581;   // posterior 90% CI [0.484, 0.679]; was 0.6
a_c_y        =  0.058;   // posterior 90% CI [0.010, 0.107]; was 0.06
a_c_i        = -0.043;   // posterior 90% CI [-0.092, 0.006]; was -0.04
a_c_pi       =  0.010;   // posterior 90% CI [-0.038, 0.059]; was 0.005
a_c_u        = -0.036;   // posterior 90% CI [-0.085, 0.013]; was -0.03
a_c_yh       =  0.10;    // AU smoother (YH/Y data unavailable); was 0.39

// Business-investment PAC auxiliary (calibration.inc:338-342)
rho_ib_aux   =  0.694;   // posterior 90% CI [0.598, 0.791]; was 0.6
a_ib_y       =  0.050;   // posterior 90% CI [0.001, 0.099]; was 0.15
a_ib_pi      =  0.023;   // posterior 90% CI [-0.027, 0.072]; was 0.04
a_ib_u       =  0.004;   // posterior 90% CI [-0.046, 0.053]; was -0.02

// Business-investment USER COST gap auxiliary (calibration.inc:344-346)
rho_rKB_aux  =  0.162;   // posterior 90% CI [0.036, 0.287]; was 0.55
a_rKB_i      =  0.242;   // posterior 90% CI [0.057, 0.428]; was 0.24

// Housing-investment PAC auxiliary (calibration.inc:348-353)
rho_ih_aux   =  0.699;   // posterior 90% CI [0.600, 0.797]; was 0.71
a_ih_y       =  0.097;   // posterior 90% CI [0.016, 0.178]; was 0.08
a_ih_i       = -0.152;   // posterior 90% CI [-0.276, -0.029]; was -0.08
a_ih_pi      =  0.042;   // posterior 90% CI [-0.007, 0.092]; was 0.05
a_ih_u       =  0.004;   // posterior 90% CI [-0.045, 0.053]; was -0.03

// ====================================================================
// Round 1.1 (2026-05-18): HICP-style headline-decomposition reporting
// block. Weights from ABS Cat. 6401.0 (CPI weights, 2025 reweight) and
// RBA Bulletin (tradeables share). Identity-preserving:
//   pi_au ≡ w_food·pi_au_food + w_energy·pi_au_energy
//         + (1 - w_food - w_energy)·pi_au_core
//   pi_au ≡ w_trad·pi_au_trad + (1 - w_trad)·pi_au_nontrad
// One-way reporting; zero feedback into the rest of the model.
// ====================================================================
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

// ====================================================================
// Round 4-8 (2026-05-20) — foreign monetary policy, demographic trends,
// tax decomposition, market/non-market branch decomposition, BLR/MAPI/MAPU
// auxiliary forecasters. AU-relevant central calibration.
// ====================================================================
rho_pop           = 0.95;    // Round 5
lambda_ibar_us    = 0.985;   // Round 4
i_ss_us           = 0.625;
alpha_i_us        = 0.5;
beta_i_us         = 0.5;
rho_tau_GST       = 0.90;    // Round 6
rho_tau_PAYG      = 0.92;
rho_tau_CIT       = 0.94;
alpha_GST         = 0.05;
alpha_PAYG        = 0.10;
alpha_CIT         = 0.02;
w_market          = 0.85;    // Round 7
rho_nonmarket     = 0.90;
gamma_nonmarket   = 0.30;
rho_BLR           = 0.90;    // Round 8
rho_MAPI          = 0.85;
rho_MAPU          = 0.80;
// Round 1.2 (2026-05-22): wage+transfer income channel for rule-of-thumb consumers
// (FR-BDF wp1044 §3.5.1 eq 35). wt_H_real_gap data prepared from ABS 5206 Table 20
// via data/prepare_household_income.m (column au_wt_H_real_gap in extended_dataset.csv).
rho_wtH           = 0.50;
alpha_wtH_y       = 0.50;
alpha_wtH_u       = 0.30;
alpha_wtH_tau     = -0.40;
b_HtM             = 0.32;
// Phase L1.3a (2026-05-25): wp1044 Eq 35 growth-neutrality coefficient on
// HP-filtered trend GDP growth.  Initial value (1 - b1_c) at the round12
// posterior mean.  Will be overwritten by the Bayesian posterior once
// the L1.3a MCMC completes.
b_PAC_c           = 0.8263;  // hybrid MCMC posterior [0.332, 1.360] (was 0.95)

// ====================================================================
// Phase L2 P1c Option 1 (2026-05-26): wp1044 BI calibration import
// ====================================================================
// AU business investment data structurally rejects the wp1044 PAC
// restriction (PV terms at coef=+1).  After ~7 spec variants tested in
// Phase L2 P1c (commits 78d7c41, 85f67db, etc.), every strict-PAC
// configuration on AU data gives R^2 < 0 on raw dln_ib.  Free-estimated
// PV(Δq̂) coefficient comes out negative (~ -5) instead of structural +1.
//
// DECISION (see PAC_BI_AU_EXPLORATION.md §7): import wp1044 Table 3.5.13
// French calibration for the BI block.  Other 4 PAC blocks remain on
// AU-estimated values from Phase L2.  This is a standard small-open-
// economy modelling approach where local data identification fails:
// borrow deep parameters from a larger / better-identified economy
// and let the AU-specific channels (E-SAT VAR, other blocks, AU shocks)
// inject AU-specific dynamics through the simulation.
//
// IRFs through the BI expectations channel will then be structurally
// correct (PAC FOC satisfied with coef=+1 on PV).  AU mining-cycle
// dynamics enter through the E-SAT VAR's response to commodity-driven
// trade shocks rather than through the BI block's own parameters.
b0_ib       = 0.096;   // wp1044 Table 3.5.13 (overrides Phase V writeback 0.0181)
b1_ib       = 0.33;    // wp1044 Table 3.5.13 (overrides 0.0809)
b2_ib       = 0.11;    // wp1044 Table 3.5.13 (overrides 0; depth-2 PAC)
b3_ib       = 0.69;    // wp1044 Table 3.5.13 (overrides 0.3120; coef on Δdf gap)
// omega_ib already 0.35 (matches wp1044)
// sigma_ces already 0.5366 (matches wp1044's 0.50 within calibration tolerance)

// Phase L2 P1c hybrid MCMC posterior shock stds (2026-05-27)
shocks;
    var eps_q;          stderr 0.5397;    // posterior [0.480, 0.597]
    var eps_i;          stderr 0.0377;    // posterior [0.033, 0.042]
    var eps_pi;         stderr 0.2195;    // posterior [0.135, 0.305]
    var eps_q_us;       stderr 1.138;     // (not estimated)
    var eps_pi_us;      stderr 0.319;     // (not estimated)
    var eps_ibar;       stderr 0.01;
    var eps_pibar_au;   stderr 0.01;
    var eps_pibar_us;   stderr 0.01;
    var eps_pQ;         stderr 0.571;     // (not estimated)
    var eps_w;          stderr 0.7674;    // posterior [0.628, 0.890]
    var eps_n;          stderr 0.3262;    // posterior [0.119, 0.525]
    var eps_c;          stderr 2.0145;    // posterior [1.811, 2.252]
    var eps_ib;         stderr 2.9177;    // posterior [2.611, 3.196]
    var eps_ih;         stderr 1.8938;    // posterior [0.523, 3.365]
    var eps_10y;        stderr 0.0745;    // posterior [0.061, 0.088]
    var eps_tp;         stderr 0.05;
    var eps_COE;        stderr 0.1;
    var eps_LB_firms;   stderr 0.1;
    var eps_BBB;        stderr 0.1;
    var eps_s;          stderr 0.1;
    var eps_x;          stderr 1.0;
    var eps_m;          stderr 1.0;
    var eps_pc;         stderr 0.5;
    var eps_pib;        stderr 0.5;
    var eps_pih;        stderr 0.5;
    var eps_px;         stderr 0.5;
    var eps_pm;         stderr 0.5;
    var eps_g;          stderr 0.3;
    var eps_pg;         stderr 0.5;
    var eps_tfp_LR;     stderr 0.01;
    var eps_pcom;       stderr 3.0;
    var eps_lh;         stderr 0.1;
    var eps_ph;         stderr 0.5;
    // Round 4-8 (2026-05-20):
    var eps_pop_bar;    stderr 0.05;
    var eps_ibar_us;    stderr 0.01;
    var eps_i_us;       stderr 0.15;
    var eps_tau_GST;    stderr 0.10;
    var eps_tau_PAYG;   stderr 0.20;
    var eps_tau_CIT;    stderr 0.30;
    var eps_BLR;        stderr 0.05;
    var eps_MAPI;       stderr 0.50;
    var eps_MAPU;       stderr 0.30;
    var eps_wtH;        stderr 0.012;  // Round 1.2: household wage+transfer income shock
    // Phase L1.3a: random-walk innovation for HP-filtered trend GDP growth.
    var eps_dy_bar;     stderr 0.05;
end;

stoch_simul(order=1, irf=200, nograph, noprint) yhat_au pi_au i_au piQ dln_c dln_ib dln_ih dln_n pi_w s_gap i_10y ln_Q ln_C ln_IB ln_IH ln_N pi_au_food pi_au_energy pi_au_core pi_au_trad pi_au_nontrad pi_au_trim dln_pop_bar i_us ibar_us tau_GST_gap tau_PAYG_gap tau_CIT_gap yhat_market yhat_nonmarket BLR_hat MAPI_hat MAPU_hat uc_k pi_c wt_H_real_gap;
