function ds = dynamic_set_auxiliary_series(ds, params)
%
% Computes auxiliary variables of the dynamic model
%
ds.AUX_DIFF_274=ds.pQ_level-ds.pQ_level(-1);
ds.AUX_DIFF_LAG_275=ds.AUX_DIFF_274(-1);
ds.AUX_DIFF_301=ds.ln_n_level-ds.ln_n_level(-1);
ds.AUX_DIFF_LAG_302=ds.AUX_DIFF_301(-1);
ds.AUX_DIFF_LAG_506=ds.AUX_DIFF_LAG_302(-1);
ds.AUX_DIFF_LAG_512=ds.AUX_DIFF_LAG_506(-1);
ds.AUX_DIFF_LAG_519=ds.AUX_DIFF_LAG_512(-1);
ds.AUX_DIFF_286=ds.ln_c_level-ds.ln_c_level(-1);
ds.AUX_DIFF_LAG_287=ds.AUX_DIFF_286(-1);
ds.AUX_DIFF_291=ds.ln_ib_level-ds.ln_ib_level(-1);
ds.AUX_DIFF_LAG_292=ds.AUX_DIFF_291(-1);
ds.AUX_DIFF_LAG_636=ds.AUX_DIFF_LAG_292(-1);
ds.AUX_DIFF_296=ds.ln_ih_level-ds.ln_ih_level(-1);
ds.AUX_DIFF_LAG_297=ds.AUX_DIFF_296(-1);
ds.AUX_DIFF_LAG_688=ds.AUX_DIFF_LAG_297(-1);
ds.pac_expectation_pac_c=params(182)+ds.y_gap_var(-1)*params(183)+ds.i_gap_var(-1)*params(184)+ds.pi_gap_var(-1)*params(185)+ds.u_gap_var(-1)*params(186)+ds.yhat_us_var(-1)*params(187)+ds.piQ_hat(-1)*params(188)+ds.n_hat(-1)*params(189)+ds.yh_ratio_hat(-1)*params(190)+ds.c_hat(-1)*params(191)+ds.ib_hat(-1)*params(192)+ds.rKB_hat(-1)*params(193)+ds.ih_hat(-1)*params(194);
ds.pac_expectation_pac_ib=params(195)+ds.y_gap_var(-1)*params(196)+ds.i_gap_var(-1)*params(197)+ds.pi_gap_var(-1)*params(198)+ds.u_gap_var(-1)*params(199)+ds.yhat_us_var(-1)*params(200)+ds.piQ_hat(-1)*params(201)+ds.n_hat(-1)*params(202)+ds.yh_ratio_hat(-1)*params(203)+ds.c_hat(-1)*params(204)+ds.ib_hat(-1)*params(205)+ds.rKB_hat(-1)*params(206)+ds.ih_hat(-1)*params(207);
ds.pac_expectation_pac_ih=params(208)+ds.y_gap_var(-1)*params(209)+ds.i_gap_var(-1)*params(210)+ds.pi_gap_var(-1)*params(211)+ds.u_gap_var(-1)*params(212)+ds.yhat_us_var(-1)*params(213)+ds.piQ_hat(-1)*params(214)+ds.n_hat(-1)*params(215)+ds.yh_ratio_hat(-1)*params(216)+ds.c_hat(-1)*params(217)+ds.ib_hat(-1)*params(218)+ds.rKB_hat(-1)*params(219)+ds.ih_hat(-1)*params(220);
ds.pac_expectation_pac_n=params(221)+ds.y_gap_var(-1)*params(222)+ds.i_gap_var(-1)*params(223)+ds.pi_gap_var(-1)*params(224)+ds.u_gap_var(-1)*params(225)+ds.yhat_us_var(-1)*params(226)+ds.piQ_hat(-1)*params(227)+ds.n_hat(-1)*params(228)+ds.yh_ratio_hat(-1)*params(229)+ds.c_hat(-1)*params(230)+ds.ib_hat(-1)*params(231)+ds.rKB_hat(-1)*params(232)+ds.ih_hat(-1)*params(233);
ds.pac_expectation_pac_pQ=params(234)+ds.y_gap_var(-1)*params(235)+ds.i_gap_var(-1)*params(236)+ds.pi_gap_var(-1)*params(237)+ds.u_gap_var(-1)*params(238)+ds.yhat_us_var(-1)*params(239)+ds.piQ_hat(-1)*params(240)+ds.n_hat(-1)*params(241)+ds.yh_ratio_hat(-1)*params(242)+ds.c_hat(-1)*params(243)+ds.ib_hat(-1)*params(244)+ds.rKB_hat(-1)*params(245)+ds.ih_hat(-1)*params(246);
end
