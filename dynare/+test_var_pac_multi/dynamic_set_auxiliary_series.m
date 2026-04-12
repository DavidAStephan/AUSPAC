function ds = dynamic_set_auxiliary_series(ds, params)
%
% Computes auxiliary variables of the dynamic model
%
ds.AUX_DIFF_77=ds.pQ_level-ds.pQ_level(-1);
ds.AUX_DIFF_LAG_78=ds.AUX_DIFF_77(-1);
ds.AUX_DIFF_82=ds.ln_n_level-ds.ln_n_level(-1);
ds.AUX_DIFF_LAG_83=ds.AUX_DIFF_82(-1);
ds.pac_expectation_pac_n=params(23)+ds.y_gap(-1)*params(24)+ds.i_gap(-1)*params(25)+ds.pi_gap(-1)*params(26)+ds.piQ_hat(-1)*params(27)+ds.n_hat(-1)*params(28);
ds.pac_expectation_pac_piQ=params(29)+ds.y_gap(-1)*params(30)+ds.i_gap(-1)*params(31)+ds.pi_gap(-1)*params(32)+ds.piQ_hat(-1)*params(33)+ds.n_hat(-1)*params(34);
end
