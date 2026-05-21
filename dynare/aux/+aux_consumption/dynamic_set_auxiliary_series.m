function ds = dynamic_set_auxiliary_series(ds, params)
%
% Computes auxiliary variables of the dynamic model
%
ds.AUX_DIFF_191=ds.ln_c_level-ds.ln_c_level(-1);
ds.AUX_DIFF_LAG_194=ds.AUX_DIFF_191(-1);
ds.pac_expectation_pac_c=params(42)+ds.yhat_au(-1)*params(43)+ds.i_gap(-1)*params(44)+ds.pi_au_gap(-1)*params(45)+ds.u_gap(-1)*params(46)+ds.yhat_us(-1)*params(47)+ds.pi_us_gap(-1)*params(48)+ds.ibar(-1)*params(49)+ds.pibar_au(-1)*params(50)+ds.pibar_us(-1)*params(51)+ds.piQ(-1)*params(52)+ds.pi_m(-1)*params(53)+ds.dln_pcom(-1)*params(54)+ds.tau_PAYG_gap(-1)*params(55)+ds.yh_ratio_hat(-1)*params(56)+ds.c_hat(-1)*params(57);
end
