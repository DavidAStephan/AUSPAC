function ds = dynamic_set_auxiliary_series(ds, params)
%
% Computes auxiliary variables of the dynamic model
%
ds.AUX_DIFF_181=ds.pQ_level-ds.pQ_level(-1);
ds.AUX_DIFF_LAG_184=ds.AUX_DIFF_181(-1);
ds.pac_expectation_pac_pQ=params(39)+ds.yhat_au(-1)*params(40)+ds.i_gap(-1)*params(41)+ds.pi_au_gap(-1)*params(42)+ds.u_gap(-1)*params(43)+ds.yhat_us(-1)*params(44)+ds.pi_us_gap(-1)*params(45)+ds.ibar(-1)*params(46)+ds.pibar_au(-1)*params(47)+ds.pibar_us(-1)*params(48)+ds.piQ(-1)*params(49)+ds.pi_m(-1)*params(50)+ds.dln_pcom(-1)*params(51)+ds.pi_w_gap(-1)*params(52)+ds.piQ_hat(-1)*params(53);
end
