[name='pac_expectation_pac_n']
pac_expectation_pac_n = h_pac_n_constant + h_pac_n_var_yhat_au_lag_1*yhat_au(-1) + h_pac_n_var_i_gap_lag_1*i_gap(-1) + h_pac_n_var_pi_au_gap_lag_1*pi_au_gap(-1) + h_pac_n_var_u_gap_lag_1*u_gap(-1) + h_pac_n_var_yhat_us_lag_1*yhat_us(-1) + h_pac_n_var_pi_us_gap_lag_1*pi_us_gap(-1) + h_pac_n_var_ibar_lag_1*ibar(-1) + h_pac_n_var_pibar_au_lag_1*pibar_au(-1) + h_pac_n_var_pibar_us_lag_1*pibar_us(-1) + h_pac_n_var_piQ_lag_1*piQ(-1) + h_pac_n_var_pi_m_lag_1*pi_m(-1) + h_pac_n_var_dln_pcom_lag_1*dln_pcom(-1) + h_pac_n_var_dln_pop_bar_lag_1*dln_pop_bar(-1) + h_pac_n_var_n_hat_lag_1*n_hat(-1);

[name='eq_dln_n_pac']
diff(ln_n_level) = b0_n*(n_hat(-1)-ln_n_level(-1))+b1_n*diff(ln_n_level(-1))+b2_n*diff(ln_n_level(-2))+b3_n*diff(ln_n_level(-3))+b4_n*diff(ln_n_level(-4))+pac_expectation_pac_n+yhat_au*b5_n+eps_n;

[name='var_n']
n_hat = rho_n_aux*n_hat(-1)+yhat_au(-1)*a_n_y+i_gap(-1)*a_n_i+pi_au_gap(-1)*a_n_pi+u_gap(-1)*a_n_u+dln_pop_bar(-1)*a_n_pop+eps_var_n;

