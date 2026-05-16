[name='pac_expectation_pac_pQ']
pac_expectation_pac_pQ = h_pac_pQ_constant + h_pac_pQ_var_yhat_au_lag_1*yhat_au(-1) + h_pac_pQ_var_i_gap_lag_1*i_gap(-1) + h_pac_pQ_var_pi_au_gap_lag_1*pi_au_gap(-1) + h_pac_pQ_var_u_gap_lag_1*u_gap(-1) + h_pac_pQ_var_yhat_us_lag_1*yhat_us(-1) + h_pac_pQ_var_pi_us_gap_lag_1*pi_us_gap(-1) + h_pac_pQ_var_ibar_lag_1*ibar(-1) + h_pac_pQ_var_pibar_au_lag_1*pibar_au(-1) + h_pac_pQ_var_pibar_us_lag_1*pibar_us(-1) + h_pac_pQ_var_piQ_lag_1*piQ(-1) + h_pac_pQ_var_pi_m_lag_1*pi_m(-1) + h_pac_pQ_var_dln_pcom_lag_1*dln_pcom(-1) + h_pac_pQ_var_piQ_hat_lag_1*piQ_hat(-1);

[name='eq_piQ_pac']
diff(pQ_level) = b0_pQ*(piQ_hat(-1)-pQ_level(-1))+b1_pQ*diff(pQ_level(-1))+pac_expectation_pac_pQ+yhat_au*b2_pQ+eps_pQ;

[name='var_piQ_hat']
piQ_hat = rho_pQ_aux*piQ_hat(-1)+yhat_au(-1)*a_pQ_y+i_gap(-1)*a_pQ_i+pi_au_gap(-1)*a_pQ_pi+u_gap(-1)*a_pQ_u+eps_var_pQ;

