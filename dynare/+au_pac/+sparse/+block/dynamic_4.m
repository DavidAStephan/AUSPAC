function [y, T] = dynamic_4(y, x, params, steady_state, sparse_rowval, sparse_colval, sparse_colptr, T)
  y(216)=params(156)*y(81)+y(77)*params(157)+y(78)*params(158)+y(79)*params(159)+x(38);
  y(215)=params(152)*y(80)+y(77)*params(153)+y(78)*params(154)+y(79)*params(155)+x(37);
  y(219)=params(168)*y(84)+y(77)*params(169)+y(78)*params(170)+y(79)*params(171)+x(41);
  y(218)=params(164)*y(83)+y(77)*params(165)+y(78)*params(166)+y(79)*params(167)+x(40);
  y(217)=params(160)*y(82)+y(77)*params(161)+y(78)*params(162)+y(79)*params(163)+x(39);
  y(270)=params(208)+y(77)*params(209)+y(78)*params(210)+y(79)*params(211)+y(80)*params(212)+y(81)*params(213)+y(82)*params(214)+y(83)*params(215)+y(84)*params(216);
  y(269)=params(199)+y(77)*params(200)+y(78)*params(201)+y(79)*params(202)+y(80)*params(203)+y(81)*params(204)+y(82)*params(205)+y(83)*params(206)+y(84)*params(207);
  y(268)=params(190)+y(77)*params(191)+y(78)*params(192)+y(79)*params(193)+y(80)*params(194)+y(81)*params(195)+y(82)*params(196)+y(83)*params(197)+y(84)*params(198);
  y(267)=params(181)+y(77)*params(182)+y(78)*params(183)+y(79)*params(184)+y(80)*params(185)+y(81)*params(186)+y(82)*params(187)+y(83)*params(188)+y(84)*params(189);
  y(266)=params(172)+y(77)*params(173)+y(78)*params(174)+y(79)*params(175)+y(80)*params(176)+y(81)*params(177)+y(82)*params(178)+y(83)*params(179)+y(84)*params(180);
end
