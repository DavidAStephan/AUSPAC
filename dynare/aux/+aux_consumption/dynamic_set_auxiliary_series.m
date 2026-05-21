function ds = dynamic_set_auxiliary_series(ds, params)
%
% Computes auxiliary variables of the dynamic model
%
ds.AUX_DIFF_207=ds.ln_c_level-ds.ln_c_level(-1);
ds.AUX_DIFF_LAG_210=ds.AUX_DIFF_207(-1);
ds.pac_expectation_pac_c=params(47)+ds.yhat_au(-1)*params(48)+ds.i_gap(-1)*params(49)+ds.pi_au_gap(-1)*params(50)+ds.u_gap(-1)*params(51)+ds.yhat_us(-1)*params(52)+ds.pi_us_gap(-1)*params(53)+ds.ibar(-1)*params(54)+ds.pibar_au(-1)*params(55)+ds.pibar_us(-1)*params(56)+ds.piQ(-1)*params(57)+ds.pi_m(-1)*params(58)+ds.dln_pcom(-1)*params(59)+ds.tau_PAYG_gap(-1)*params(60)+ds.wt_H_real_gap(-1)*params(61)+ds.yh_ratio_hat(-1)*params(62)+ds.c_hat(-1)*params(63);
end
