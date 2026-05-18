function ds = dynamic_set_auxiliary_series(ds, params)
%
% Computes auxiliary variables of the dynamic model
%
ds.AUX_DIFF_165=ds.ln_n_level-ds.ln_n_level(-1);
ds.AUX_DIFF_LAG_168=ds.AUX_DIFF_165(-1);
ds.AUX_DIFF_LAG_177=ds.AUX_DIFF_LAG_168(-1);
ds.AUX_DIFF_LAG_183=ds.AUX_DIFF_LAG_177(-1);
ds.AUX_DIFF_LAG_190=ds.AUX_DIFF_LAG_183(-1);
ds.pac_expectation_pac_n=params(38)+ds.yhat_au(-1)*params(39)+ds.i_gap(-1)*params(40)+ds.pi_au_gap(-1)*params(41)+ds.u_gap(-1)*params(42)+ds.yhat_us(-1)*params(43)+ds.pi_us_gap(-1)*params(44)+ds.ibar(-1)*params(45)+ds.pibar_au(-1)*params(46)+ds.pibar_us(-1)*params(47)+ds.piQ(-1)*params(48)+ds.pi_m(-1)*params(49)+ds.dln_pcom(-1)*params(50)+ds.n_hat(-1)*params(51);
end
