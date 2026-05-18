function ds = dynamic_set_auxiliary_series(ds, params)
%
% Computes auxiliary variables of the dynamic model
%
ds.AUX_DIFF_165=ds.ln_ih_level-ds.ln_ih_level(-1);
ds.AUX_DIFF_LAG_168=ds.AUX_DIFF_165(-1);
ds.AUX_DIFF_LAG_177=ds.AUX_DIFF_LAG_168(-1);
ds.pac_expectation_pac_ih=params(36)+ds.yhat_au(-1)*params(37)+ds.i_gap(-1)*params(38)+ds.pi_au_gap(-1)*params(39)+ds.u_gap(-1)*params(40)+ds.yhat_us(-1)*params(41)+ds.pi_us_gap(-1)*params(42)+ds.ibar(-1)*params(43)+ds.pibar_au(-1)*params(44)+ds.pibar_us(-1)*params(45)+ds.piQ(-1)*params(46)+ds.pi_m(-1)*params(47)+ds.dln_pcom(-1)*params(48)+ds.ih_hat(-1)*params(49);
end
