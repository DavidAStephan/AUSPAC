function [y, T] = dynamic_4(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
  y(220)=params(35)*y(80)+y(77)*params(34)+x(42);
  y(222)=params(152)*y(82)+y(77)*params(153)+y(78)*params(154)+y(79)*params(155)+y(80)*params(156)+x(37);
  y(228)=params(177)*y(88)+y(77)*params(178)+y(78)*params(179)+y(79)*params(180)+y(80)*params(181)+x(41);
  y(227)=params(175)*y(87)+y(78)*params(176)+x(45);
  y(226)=params(171)*y(86)+y(77)*params(172)+y(79)*params(173)+y(80)*params(174)+x(40);
  y(224)=params(162)*y(84)+y(77)*params(163)+y(80)*params(164)+x(44);
  y(225)=params(165)*y(85)+y(77)*params(166)+y(78)*params(167)+y(79)*params(168)+y(80)*params(169)+y(84)*params(170)+x(39);
  y(223)=params(157)*y(83)+y(77)*params(158)+y(78)*params(159)+y(79)*params(160)+y(80)*params(161)+x(38);
  y(280)=params(234)+y(77)*params(235)+y(78)*params(236)+y(79)*params(237)+y(80)*params(238)+y(81)*params(239)+y(82)*params(240)+y(83)*params(241)+y(84)*params(242)+y(85)*params(243)+y(86)*params(244)+y(87)*params(245)+y(88)*params(246);
  y(279)=params(221)+y(77)*params(222)+y(78)*params(223)+y(79)*params(224)+y(80)*params(225)+y(81)*params(226)+y(82)*params(227)+y(83)*params(228)+y(84)*params(229)+y(85)*params(230)+y(86)*params(231)+y(87)*params(232)+y(88)*params(233);
  y(278)=params(208)+y(77)*params(209)+y(78)*params(210)+y(79)*params(211)+y(80)*params(212)+y(81)*params(213)+y(82)*params(214)+y(83)*params(215)+y(84)*params(216)+y(85)*params(217)+y(86)*params(218)+y(87)*params(219)+y(88)*params(220);
  y(277)=params(195)+y(77)*params(196)+y(78)*params(197)+y(79)*params(198)+y(80)*params(199)+y(81)*params(200)+y(82)*params(201)+y(83)*params(202)+y(84)*params(203)+y(85)*params(204)+y(86)*params(205)+y(87)*params(206)+y(88)*params(207);
  y(276)=params(182)+y(77)*params(183)+y(78)*params(184)+y(79)*params(185)+y(80)*params(186)+y(81)*params(187)+y(82)*params(188)+y(83)*params(189)+y(84)*params(190)+y(85)*params(191)+y(86)*params(192)+y(87)*params(193)+y(88)*params(194);
end
