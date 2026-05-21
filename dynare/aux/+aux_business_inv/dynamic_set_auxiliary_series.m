function ds = dynamic_set_auxiliary_series(ds, params)
%
% Computes auxiliary variables of the dynamic model
%
ds.AUX_DIFF_185=ds.ln_ib_level-ds.ln_ib_level(-1);
ds.AUX_DIFF_LAG_188=ds.AUX_DIFF_185(-1);
ds.AUX_DIFF_LAG_197=ds.AUX_DIFF_LAG_188(-1);
ds.pac_expectation_pac_ib=params(40)+ds.yhat_au(-1)*params(41)+ds.i_gap(-1)*params(42)+ds.pi_au_gap(-1)*params(43)+ds.u_gap(-1)*params(44)+ds.yhat_us(-1)*params(45)+ds.pi_us_gap(-1)*params(46)+ds.ibar(-1)*params(47)+ds.pibar_au(-1)*params(48)+ds.pibar_us(-1)*params(49)+ds.piQ(-1)*params(50)+ds.pi_m(-1)*params(51)+ds.dln_pcom(-1)*params(52)+ds.tau_CIT_gap(-1)*params(53)+ds.ib_hat(-1)*params(54)+ds.rKB_hat(-1)*params(55);
end
