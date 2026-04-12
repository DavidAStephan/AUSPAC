function ds = dynamic_set_auxiliary_series(ds, params)
%
% Computes auxiliary variables of the dynamic model
%
ds.AUX_DIFF_61=ds.pQ_level-ds.pQ_level(-1);
ds.AUX_DIFF_LAG_62=ds.AUX_DIFF_61(-1);
ds.pac_expectation_pac_piQ=params(17)+ds.y_gap(-1)*params(18)+ds.i_gap(-1)*params(19)+ds.pi_gap(-1)*params(20)+ds.piQ_star_hat(-1)*params(21);
end
