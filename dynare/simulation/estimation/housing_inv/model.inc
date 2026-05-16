[name='pac_expectation_pac_ih']
pac_expectation_pac_ih = h_pac_ih_constant + h_pac_ih_var_yhat_au_lag_1*yhat_au(-1) + h_pac_ih_var_i_gap_lag_1*i_gap(-1) + h_pac_ih_var_pi_au_gap_lag_1*pi_au_gap(-1) + h_pac_ih_var_u_gap_lag_1*u_gap(-1) + h_pac_ih_var_yhat_us_lag_1*yhat_us(-1) + h_pac_ih_var_pi_us_gap_lag_1*pi_us_gap(-1) + h_pac_ih_var_ibar_lag_1*ibar(-1) + h_pac_ih_var_pibar_au_lag_1*pibar_au(-1) + h_pac_ih_var_pibar_us_lag_1*pibar_us(-1) + h_pac_ih_var_piQ_lag_1*piQ(-1) + h_pac_ih_var_pi_m_lag_1*pi_m(-1) + h_pac_ih_var_dln_pcom_lag_1*dln_pcom(-1) + h_pac_ih_var_ih_hat_lag_1*ih_hat(-1);

[name='eq_dln_ih_pac']
diff(ln_ih_level) = b0_ih*(ih_hat(-1)-ln_ih_level(-1))+b1_ih*diff(ln_ih_level(-1))+b2_ih*diff(ln_ih_level(-2))+pac_expectation_pac_ih+yhat_au*b3_ih+eps_ih;

[name='var_ih']
ih_hat = rho_ih_aux*ih_hat(-1)+yhat_au(-1)*a_ih_y+i_gap(-1)*a_ih_i+pi_au_gap(-1)*a_ih_pi+u_gap(-1)*a_ih_u+eps_var_ih;

