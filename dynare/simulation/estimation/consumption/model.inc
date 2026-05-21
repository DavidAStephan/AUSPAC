[name='pac_expectation_pac_c']
pac_expectation_pac_c = h_pac_c_constant + h_pac_c_var_yhat_au_lag_1*yhat_au(-1) + h_pac_c_var_i_gap_lag_1*i_gap(-1) + h_pac_c_var_pi_au_gap_lag_1*pi_au_gap(-1) + h_pac_c_var_u_gap_lag_1*u_gap(-1) + h_pac_c_var_yhat_us_lag_1*yhat_us(-1) + h_pac_c_var_pi_us_gap_lag_1*pi_us_gap(-1) + h_pac_c_var_ibar_lag_1*ibar(-1) + h_pac_c_var_pibar_au_lag_1*pibar_au(-1) + h_pac_c_var_pibar_us_lag_1*pibar_us(-1) + h_pac_c_var_piQ_lag_1*piQ(-1) + h_pac_c_var_pi_m_lag_1*pi_m(-1) + h_pac_c_var_dln_pcom_lag_1*dln_pcom(-1) + h_pac_c_var_tau_PAYG_gap_lag_1*tau_PAYG_gap(-1) + h_pac_c_var_wt_H_real_gap_lag_1*wt_H_real_gap(-1) + h_pac_c_var_yh_ratio_hat_lag_1*yh_ratio_hat(-1) + h_pac_c_var_c_hat_lag_1*c_hat(-1);

[name='eq_dln_c_pac']
diff(ln_c_level) = b0_c*(c_hat(-1)-ln_c_level(-1))+b1_c*diff(ln_c_level(-1))+pac_expectation_pac_c+i_gap(-1)*b2_c+yhat_au*b3_c+eps_c;

[name='var_yh']
yh_ratio_hat = rho_yh_aux*yh_ratio_hat(-1)+yhat_au(-1)*a_yh_y+u_gap(-1)*a_yh_u+eps_var_yh;

[name='var_c']
c_hat = rho_c_aux*c_hat(-1)+yhat_au(-1)*a_c_y+i_gap(-1)*a_c_i+pi_au_gap(-1)*a_c_pi+u_gap(-1)*a_c_u+yh_ratio_hat(-1)*a_c_yh+tau_PAYG_gap(-1)*a_c_PAYG+eps_var_c;

