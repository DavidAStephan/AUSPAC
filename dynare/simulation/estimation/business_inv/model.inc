[name='pac_expectation_pac_ib']
pac_expectation_pac_ib = h_pac_ib_constant + h_pac_ib_var_yhat_au_lag_1*yhat_au(-1) + h_pac_ib_var_i_gap_lag_1*i_gap(-1) + h_pac_ib_var_pi_au_gap_lag_1*pi_au_gap(-1) + h_pac_ib_var_u_gap_lag_1*u_gap(-1) + h_pac_ib_var_yhat_us_lag_1*yhat_us(-1) + h_pac_ib_var_pi_us_gap_lag_1*pi_us_gap(-1) + h_pac_ib_var_ibar_lag_1*ibar(-1) + h_pac_ib_var_pibar_au_lag_1*pibar_au(-1) + h_pac_ib_var_pibar_us_lag_1*pibar_us(-1) + h_pac_ib_var_piQ_lag_1*piQ(-1) + h_pac_ib_var_pi_m_lag_1*pi_m(-1) + h_pac_ib_var_dln_pcom_lag_1*dln_pcom(-1) + h_pac_ib_var_ib_hat_lag_1*ib_hat(-1) + h_pac_ib_var_rKB_hat_lag_1*rKB_hat(-1);

[name='eq_dln_ib_pac']
diff(ln_ib_level) = b0_ib*(ib_hat(-1)-ln_ib_level(-1))+b1_ib*diff(ln_ib_level(-1))+b2_ib*diff(ln_ib_level(-2))+pac_expectation_pac_ib+yhat_au*b3_ib+eps_ib;

[name='var_ib']
ib_hat = rho_ib_aux*ib_hat(-1)+yhat_au(-1)*a_ib_y+pi_au_gap(-1)*a_ib_pi+u_gap(-1)*a_ib_u+eps_var_ib;

[name='var_rKB']
rKB_hat = rho_rKB_aux*rKB_hat(-1)+i_gap(-1)*a_rKB_i+eps_var_rKB;

