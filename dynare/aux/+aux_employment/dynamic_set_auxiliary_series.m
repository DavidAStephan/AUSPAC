function ds = dynamic_set_auxiliary_series(ds, params)
%
% Computes auxiliary variables of the dynamic model
%
ds.AUX_DIFF_175=ds.ln_n_level-ds.ln_n_level(-1);
ds.AUX_DIFF_LAG_178=ds.AUX_DIFF_175(-1);
ds.AUX_DIFF_LAG_187=ds.AUX_DIFF_LAG_178(-1);
ds.AUX_DIFF_LAG_193=ds.AUX_DIFF_LAG_187(-1);
ds.AUX_DIFF_LAG_200=ds.AUX_DIFF_LAG_193(-1);
ds.pac_expectation_pac_n=params(40)+ds.yhat_au(-1)*params(41)+ds.i_gap(-1)*params(42)+ds.pi_au_gap(-1)*params(43)+ds.u_gap(-1)*params(44)+ds.yhat_us(-1)*params(45)+ds.pi_us_gap(-1)*params(46)+ds.ibar(-1)*params(47)+ds.pibar_au(-1)*params(48)+ds.pibar_us(-1)*params(49)+ds.piQ(-1)*params(50)+ds.pi_m(-1)*params(51)+ds.dln_pcom(-1)*params(52)+ds.dln_pop_bar(-1)*params(53)+ds.n_hat(-1)*params(54);
end
