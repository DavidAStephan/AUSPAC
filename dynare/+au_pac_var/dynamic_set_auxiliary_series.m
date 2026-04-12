function ds = dynamic_set_auxiliary_series(ds, params)
%
% Computes auxiliary variables of the dynamic model
%
ds.AUX_DIFF_220=ds.pQ_level-ds.pQ_level(-1);
ds.AUX_DIFF_LAG_221=ds.AUX_DIFF_220(-1);
ds.AUX_DIFF_247=ds.ln_n_level-ds.ln_n_level(-1);
ds.AUX_DIFF_LAG_248=ds.AUX_DIFF_247(-1);
ds.AUX_DIFF_LAG_440=ds.AUX_DIFF_LAG_248(-1);
ds.AUX_DIFF_LAG_446=ds.AUX_DIFF_LAG_440(-1);
ds.AUX_DIFF_LAG_453=ds.AUX_DIFF_LAG_446(-1);
ds.AUX_DIFF_232=ds.ln_c_level-ds.ln_c_level(-1);
ds.AUX_DIFF_LAG_233=ds.AUX_DIFF_232(-1);
ds.AUX_DIFF_237=ds.ln_ib_level-ds.ln_ib_level(-1);
ds.AUX_DIFF_LAG_238=ds.AUX_DIFF_237(-1);
ds.AUX_DIFF_LAG_570=ds.AUX_DIFF_LAG_238(-1);
ds.AUX_DIFF_242=ds.ln_ih_level-ds.ln_ih_level(-1);
ds.AUX_DIFF_LAG_243=ds.AUX_DIFF_242(-1);
ds.AUX_DIFF_LAG_623=ds.AUX_DIFF_LAG_243(-1);
ds.pac_expectation_pac_c=params(158)+ds.y_gap_var(-1)*params(159)+ds.i_gap_var(-1)*params(160)+ds.pi_gap_var(-1)*params(161)+ds.piQ_hat(-1)*params(162)+ds.n_hat(-1)*params(163)+ds.c_hat(-1)*params(164)+ds.ib_hat(-1)*params(165)+ds.ih_hat(-1)*params(166);
ds.pac_expectation_pac_ib=params(167)+ds.y_gap_var(-1)*params(168)+ds.i_gap_var(-1)*params(169)+ds.pi_gap_var(-1)*params(170)+ds.piQ_hat(-1)*params(171)+ds.n_hat(-1)*params(172)+ds.c_hat(-1)*params(173)+ds.ib_hat(-1)*params(174)+ds.ih_hat(-1)*params(175);
ds.pac_expectation_pac_ih=params(176)+ds.y_gap_var(-1)*params(177)+ds.i_gap_var(-1)*params(178)+ds.pi_gap_var(-1)*params(179)+ds.piQ_hat(-1)*params(180)+ds.n_hat(-1)*params(181)+ds.c_hat(-1)*params(182)+ds.ib_hat(-1)*params(183)+ds.ih_hat(-1)*params(184);
ds.pac_expectation_pac_n=params(185)+ds.y_gap_var(-1)*params(186)+ds.i_gap_var(-1)*params(187)+ds.pi_gap_var(-1)*params(188)+ds.piQ_hat(-1)*params(189)+ds.n_hat(-1)*params(190)+ds.c_hat(-1)*params(191)+ds.ib_hat(-1)*params(192)+ds.ih_hat(-1)*params(193);
ds.pac_expectation_pac_pQ=params(194)+ds.y_gap_var(-1)*params(195)+ds.i_gap_var(-1)*params(196)+ds.pi_gap_var(-1)*params(197)+ds.piQ_hat(-1)*params(198)+ds.n_hat(-1)*params(199)+ds.c_hat(-1)*params(200)+ds.ib_hat(-1)*params(201)+ds.ih_hat(-1)*params(202);
end
