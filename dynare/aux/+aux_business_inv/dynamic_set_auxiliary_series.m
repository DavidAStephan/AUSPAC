function ds = dynamic_set_auxiliary_series(ds, params)
%
% Computes auxiliary variables of the dynamic model
%
ds.AUX_DIFF_172=ds.ln_ib_level-ds.ln_ib_level(-1);
ds.AUX_DIFF_LAG_175=ds.AUX_DIFF_172(-1);
ds.AUX_DIFF_LAG_184=ds.AUX_DIFF_LAG_175(-1);
ds.pac_expectation_pac_ib=params(37)+ds.yhat_au(-1)*params(38)+ds.i_gap(-1)*params(39)+ds.pi_au_gap(-1)*params(40)+ds.u_gap(-1)*params(41)+ds.yhat_us(-1)*params(42)+ds.pi_us_gap(-1)*params(43)+ds.ibar(-1)*params(44)+ds.pibar_au(-1)*params(45)+ds.pibar_us(-1)*params(46)+ds.piQ(-1)*params(47)+ds.pi_m(-1)*params(48)+ds.dln_pcom(-1)*params(49)+ds.ib_hat(-1)*params(50)+ds.rKB_hat(-1)*params(51);
end
