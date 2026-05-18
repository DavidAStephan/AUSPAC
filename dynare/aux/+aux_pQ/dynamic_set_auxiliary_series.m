function ds = dynamic_set_auxiliary_series(ds, params)
%
% Computes auxiliary variables of the dynamic model
%
ds.AUX_DIFF_161=ds.pQ_level-ds.pQ_level(-1);
ds.AUX_DIFF_LAG_164=ds.AUX_DIFF_161(-1);
ds.pac_expectation_pac_pQ=params(31)+ds.yhat_au(-1)*params(32)+ds.i_gap(-1)*params(33)+ds.pi_au_gap(-1)*params(34)+ds.u_gap(-1)*params(35)+ds.yhat_us(-1)*params(36)+ds.pi_us_gap(-1)*params(37)+ds.ibar(-1)*params(38)+ds.pibar_au(-1)*params(39)+ds.pibar_us(-1)*params(40)+ds.piQ(-1)*params(41)+ds.pi_m(-1)*params(42)+ds.dln_pcom(-1)*params(43)+ds.piQ_star(-1)*params(44);
end
