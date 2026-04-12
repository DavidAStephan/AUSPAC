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
ds.AUX_DIFF_LAG_571=ds.AUX_DIFF_LAG_238(-1);
ds.AUX_DIFF_242=ds.ln_ih_level-ds.ln_ih_level(-1);
ds.AUX_DIFF_LAG_243=ds.AUX_DIFF_242(-1);
ds.AUX_DIFF_LAG_624=ds.AUX_DIFF_LAG_243(-1);
ds.pac_expectation_pac_c=params(172)+ds.y_gap_var(-1)*params(173)+ds.i_gap_var(-1)*params(174)+ds.pi_gap_var(-1)*params(175)+ds.piQ_hat(-1)*params(176)+ds.n_hat(-1)*params(177)+ds.c_hat(-1)*params(178)+ds.ib_hat(-1)*params(179)+ds.ih_hat(-1)*params(180);
ds.pac_expectation_pac_ib=params(181)+ds.y_gap_var(-1)*params(182)+ds.i_gap_var(-1)*params(183)+ds.pi_gap_var(-1)*params(184)+ds.piQ_hat(-1)*params(185)+ds.n_hat(-1)*params(186)+ds.c_hat(-1)*params(187)+ds.ib_hat(-1)*params(188)+ds.ih_hat(-1)*params(189);
ds.pac_expectation_pac_ih=params(190)+ds.y_gap_var(-1)*params(191)+ds.i_gap_var(-1)*params(192)+ds.pi_gap_var(-1)*params(193)+ds.piQ_hat(-1)*params(194)+ds.n_hat(-1)*params(195)+ds.c_hat(-1)*params(196)+ds.ib_hat(-1)*params(197)+ds.ih_hat(-1)*params(198);
ds.pac_expectation_pac_n=params(199)+ds.y_gap_var(-1)*params(200)+ds.i_gap_var(-1)*params(201)+ds.pi_gap_var(-1)*params(202)+ds.piQ_hat(-1)*params(203)+ds.n_hat(-1)*params(204)+ds.c_hat(-1)*params(205)+ds.ib_hat(-1)*params(206)+ds.ih_hat(-1)*params(207);
ds.pac_expectation_pac_pQ=params(208)+ds.y_gap_var(-1)*params(209)+ds.i_gap_var(-1)*params(210)+ds.pi_gap_var(-1)*params(211)+ds.piQ_hat(-1)*params(212)+ds.n_hat(-1)*params(213)+ds.c_hat(-1)*params(214)+ds.ib_hat(-1)*params(215)+ds.ih_hat(-1)*params(216);
end
