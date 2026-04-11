function residual = dynamic_resid(T, y, x, params, steady_state, it_, T_flag)
% function residual = dynamic_resid(T, y, x, params, steady_state, it_, T_flag)
%
% File created by Dynare Preprocessor from .mod file
%
% Inputs:
%   T             [#temp variables by 1]     double   vector of temporary terms to be filled by function
%   y             [#dynamic variables by 1]  double   vector of endogenous variables in the order stored
%                                                     in M_.lead_lag_incidence; see the Manual
%   x             [nperiods by M_.exo_nbr]   double   matrix of exogenous variables (in declaration order)
%                                                     for all simulation periods
%   steady_state  [M_.endo_nbr by 1]         double   vector of steady state values
%   params        [M_.param_nbr by 1]        double   vector of parameter values in declaration order
%   it_           scalar                     double   time period for exogenous variables for which
%                                                     to evaluate the model
%   T_flag        boolean                    boolean  flag saying whether or not to calculate temporary terms
%
% Output:
%   residual
%

if T_flag
    T = au_pac.dynamic_resid_tt(T, y, x, params, steady_state, it_);
end
residual = zeros(152, 1);
    residual(1) = (y(109)) - (y(102)-y(106));
    residual(2) = (y(110)) - (y(103)-y(107));
    residual(3) = (y(111)) - (y(105)-y(108));
    residual(4) = (y(101)) - (params(1)*y(104)+params(2)*y(1)-params(3)*(y(6)-y(7))+params(18)*y(171)+x(it_, 1));
    residual(5) = (y(109)) - (y(6)*params(4)+(1-params(4))*(y(7)*params(5)+y(1)*params(6))+x(it_, 2));
    residual(6) = (y(110)) - (y(7)*params(7)+y(1)*params(8)+x(it_, 3));
    residual(7) = (y(104)) - (params(9)*y(2)+x(it_, 4));
    residual(8) = (y(111)) - (params(10)*y(8)+y(2)*params(11)+x(it_, 5));
    residual(9) = (y(106)) - (params(12)*y(3)+(1-params(12))*params(15)+x(it_, 6));
    residual(10) = (y(107)) - (params(13)*y(4)+(1-params(13))*params(16)+x(it_, 7));
    residual(11) = (y(108)) - (params(14)*y(5)+(1-params(14))*params(17)+x(it_, 8));
    residual(12) = (y(213)) - (x(it_, 34)+y(61)*params(19)-y(60)+params(20)*y(214));
    residual(13) = (y(198)) - (y(61)+x(it_, 35));
    residual(14) = (y(215)) - (x(it_, 36)+y(65)*params(45)-y(64)+params(46)*y(216));
    residual(15) = (y(202)) - (y(65)+x(it_, 37));
    residual(16) = (y(217)) - (x(it_, 38)+y(68)*params(54)-y(67)+params(55)*y(218));
    residual(17) = (y(205)) - (y(68)+x(it_, 39));
    residual(18) = (y(219)) - (x(it_, 40)+y(71)*params(63)-y(70)+params(64)*y(220));
    residual(19) = (y(208)) - (y(71)+x(it_, 41));
    residual(20) = (y(221)) - (x(it_, 42)+y(74)*params(37)-y(73)+params(38)*y(222));
    residual(21) = (y(211)) - (y(74)+x(it_, 43));
    residual(22) = (y(112)) - (params(16)+y(199)-y(62));
    residual(23) = (y(200)) - (y(63)+y(113)-params(16));
    residual(24) = (y(131)) - (y(203)-y(66));
    residual(25) = (y(136)) - (y(206)-y(69));
    residual(26) = (y(141)) - (y(209)-y(72));
    residual(27) = (y(124)) - (y(212)-y(75));
    residual(28) = (y(116)) - ((1-params(62))*y(10)+y(136)*params(62));
    residual(29) = (y(117)) - (y(116)*params(26)+(1-params(26))*y(126)+y(118));
    residual(30) = (y(118)) - (params(27)*y(11)+x(it_, 30));
    residual(31) = (y(120)) - (y(118)/(1-params(26)));
    residual(32) = (y(119)) - (y(121)-y(120));
    residual(33) = (y(113)) - (params(23)*y(9)+y(119)*params(24)+params(25)*y(147)+y(107)*(1-params(23)-params(24)));
    residual(34) = (y(114)) - (y(107));
    residual(35) = (y(115)) - (y(200)-y(199));
    residual(36) = (y(223)) - (x(it_, 9)+y(101)*params(21)+params(19)*(y(61)-y(62))+params(20)*y(224)+y(242));
    residual(37) = (y(122)) - (params(35)*y(13)+y(101)*params(34));
    residual(38) = (y(123)) - (y(122)*(1-params(36))+params(36)*y(253));
    residual(39) = (y(121)) - (params(31)*y(12)+y(103)*params(33)+y(123)*params(32)+y(107)*(1-params(31)-params(33))+y(120)*(1-params(31))+x(it_, 10));
    residual(40) = (y(125)) - (params(44)*y(15)+y(126)*(1-params(44)));
    residual(41) = (y(126)) - (y(118)/(1-params(26))-params(118)*y(172));
    residual(42) = (y(127)) - (y(125)+y(16)-y(124));
    residual(43) = (y(128)) - (y(14));
    residual(44) = (y(129)) - (y(17));
    residual(45) = (y(130)) - (y(18));
    residual(46) = (y(225)) - (x(it_, 11)+y(101)*params(43)+params(37)*(y(74)-y(75))+params(38)*y(226)+params(39)*y(227)+params(40)*y(228)+params(41)*y(229)+y(241));
    residual(47) = (y(132)) - (params(50)*y(19)+(1-params(50))*y(133));
    residual(48) = (y(135)) - (y(101)*(1-params(52))+params(52)*y(254));
    residual(49) = (y(133)) - (params(51)*(y(135)-y(21))+params(53)*(y(174)-y(163)-(params(15)+params(73)+params(130)-params(16))-(y(46)-y(38)-(params(15)+params(73)+params(130)-params(16)))));
    residual(50) = (y(134)) - (y(132)+y(20)-y(131));
    residual(51) = (y(230)) - (x(it_, 12)+y(101)*params(49)+y(6)*params(48)+params(45)*(y(65)-y(66))+params(46)*y(231)+y(238));
    residual(52) = (y(137)) - (params(60)*y(23)+(1-params(60))*y(138));
    residual(53) = (y(146)) - (params(62)+y(151)-(y(164)-y(112)));
    residual(54) = (y(147)) - (y(146)-y(28));
    residual(55) = (y(138)) - (y(101)*params(136)-y(147)*params(118));
    residual(56) = (y(139)) - (y(137)+y(24)-y(136));
    residual(57) = (y(140)) - (y(22));
    residual(58) = (y(232)) - (x(it_, 13)+y(6)*params(59)+y(101)*params(58)+params(54)*(y(68)-y(69))+params(55)*y(233)+params(56)*y(234)+y(239));
    residual(59) = (y(142)) - (params(69)*y(26)+(1-params(69))*y(143));
    residual(60) = (y(143)) - ((y(135)-y(21))*params(135)-params(70)*(y(174)-(params(15)+params(73)+params(130)))+params(134)*y(48));
    residual(61) = (y(144)) - (y(142)+y(27)-y(141));
    residual(62) = (y(145)) - (y(25));
    residual(63) = (y(235)) - (x(it_, 14)+y(6)*params(68)+y(101)*params(67)+params(63)*(y(71)-y(72))+params(64)*y(236)+params(65)*y(237)+y(240));
    residual(64) = (y(149)) - (params(74)*y(29)+params(73)*(1-params(74))+x(it_, 16));
    residual(65) = (y(150)) - (y(102)*(1-params(72))+params(72)*y(255));
    residual(66) = (y(148)) - (y(149)+y(150)+x(it_, 15));
    residual(67) = (y(155)) - ((1-params(80))*params(83)+params(80)*y(30)+x(it_, 17));
    residual(68) = (y(156)) - ((1-params(81))*params(84)+params(81)*y(31)+x(it_, 18));
    residual(69) = (y(157)) - ((1-params(82))*params(85)+params(82)*y(32)+x(it_, 19));
    residual(70) = (y(152)) - (y(148)+y(155));
    residual(71) = (y(153)) - (y(148)+y(156));
    residual(72) = (y(154)) - (y(148)+y(157));
    residual(73) = (y(151)) - (y(152)*params(77)+y(153)*params(78)+y(154)*params(79));
    residual(74) = (y(158)) - (params(86)*y(33)-y(109)*params(87)+params(87)*(y(110)-y(111))+x(it_, 20));
    residual(75) = (y(160)) - (y(35)-y(159));
    residual(76) = (y(159)) - (y(35)*params(88)+params(89)*y(34)+y(104)*params(90)+y(158)*params(91)+params(29)*y(168)+x(it_, 21));
    residual(77) = (y(162)) - (y(37)-y(161));
    residual(78) = (y(161)) - (y(37)*params(92)+params(93)*y(36)+params(94)*y(173)+y(158)*params(95)+x(it_, 22));
    residual(79) = (y(163)) - (y(38)*params(96)+y(112)*params(97)+params(119)*y(167)+y(168)*params(122)+y(107)*(1-params(96)-params(97)-params(119))+x(it_, 23));
    residual(80) = (y(164)) - (params(98)*y(39)+y(112)*params(99)+y(167)*params(120)+y(107)*(1-params(98)-params(99)-params(120))+x(it_, 24));
    residual(81) = (y(165)) - (params(100)*y(40)+y(112)*params(101)+y(167)*params(121)+y(107)*(1-params(100)-params(101)-params(121))+x(it_, 25));
    residual(82) = (y(166)) - (params(102)*y(41)+y(112)*params(103)+y(107)*(1-params(102)-params(103))+y(158)*params(104)+y(168)*params(30)+x(it_, 26));
    residual(83) = (y(167)) - (params(105)*y(42)+y(112)*params(106)+y(107)*(1-params(105)-params(106))+y(158)*params(107)+y(168)*params(123)+x(it_, 27));
    residual(84) = (y(168)) - (params(28)*y(43)+y(104)*0.10+x(it_, 31));
    residual(85) = (y(169)) - (params(108)*y(44)+y(101)*params(109)+x(it_, 28));
    residual(86) = (y(170)) - (params(110)*y(45)+(y(121)-y(120))*params(111)+y(107)*(1-params(110)-params(111))+x(it_, 29));
    residual(87) = (y(171)) - (y(131)*params(112)+y(136)*params(113)+y(141)*params(114)+y(169)*params(115)+y(159)*params(116)-y(161)*params(117));
    residual(88) = (y(172)) - (y(121)-y(112)-y(120));
    residual(89) = (y(173)) - (y(131)*params(124)+y(136)*params(125)+y(141)*params(126)+y(169)*params(127)+y(159)*params(128));
    residual(90) = (y(174)) - (y(46)*params(129)+(1-params(129))*(params(130)+y(148))+x(it_, 32));
    residual(91) = (y(175)) - (params(131)*y(47)+y(101)*params(132)+y(6)*params(133)+x(it_, 33));
    residual(92) = (y(176)) - (y(175)+y(48)*0.98);
    residual(93) = (y(192)) - (params(146)*(1-params(145))+y(148)*(1-params(145))+params(145)*y(56));
    residual(94) = (y(193)) - (y(148)*(1-params(145))+params(145)*y(57));
    residual(95) = (y(194)) - (y(148)*(1-params(145))+(1-params(145))*params(147)+params(145)*y(58));
    residual(96) = (y(195)) - (y(148)*(1-params(145))+(1-params(145))*params(148)+params(145)*y(59));
    residual(97) = (y(181)) - (y(192)*params(137)-y(189));
    residual(98) = (y(182)) - (y(193)*params(138));
    residual(99) = (y(183)) - (y(189)+y(194)*(-(params(137)+params(138)+params(139)))+y(191));
    residual(100) = (y(184)) - (y(195)*params(139)-y(191));
    residual(101) = (y(189)) - ((1-params(143))*y(53)+params(143)*params(140));
    residual(102) = (y(191)) - ((1-params(143))*y(55)+params(143)*params(142));
    residual(103) = (y(190)) - ((1-params(143))*y(54)+params(143)*params(141)+y(101)*0.05);
    residual(104) = (y(185)) - (y(136)*(-params(113))-(y(189)-params(140))+params(137)*(y(192)-(params(15)+params(73)+params(146))));
    residual(105) = (y(186)) - (y(169)*(-params(115))+y(101)*0.30-(y(190)-params(141))+params(138)*(y(193)-(params(15)+params(73))));
    residual(106) = (y(187)) - (params(112)*(y(101)-y(131))-y(141)*params(114)+(-(params(137)+params(138)+params(139)))*(y(194)-(params(15)+params(73)+params(147))));
    residual(107) = (y(188)) - (params(139)*(y(195)-(params(15)+params(73)+params(148))));
    residual(108) = (y(177)) - (y(185)+0.98*y(49)+params(137)*0.02);
    residual(109) = (y(178)) - (y(186)+0.98*y(50)+params(138)*0.02);
    residual(110) = (y(179)) - (y(187)+0.98*y(51)+(-(params(137)+params(138)+params(139)))*0.02);
    residual(111) = (y(180)) - (y(188)+0.98*y(52)+params(139)*0.02);
    residual(112) = (y(196)) - ((-(y(188)+y(187)+y(185)+y(186))));
    residual(113) = (y(213)) - (y(197)-y(60));
    residual(114) = (y(214)) - (y(76));
    residual(115) = (y(215)) - (y(201)-y(64));
    residual(116) = (y(216)) - (y(77));
    residual(117) = (y(217)) - (y(204)-y(67));
    residual(118) = (y(218)) - (y(78));
    residual(119) = (y(219)) - (y(207)-y(70));
    residual(120) = (y(220)) - (y(79));
    residual(121) = (y(221)) - (y(210)-y(73));
    residual(122) = (y(222)) - (y(80));
    residual(123) = (y(223)) - (y(199)-y(62));
    residual(124) = (y(224)) - (y(81));
    residual(125) = (y(225)) - (y(212)-y(75));
    residual(126) = (y(226)) - (y(82));
    residual(127) = (y(227)) - (y(83));
    residual(128) = (y(228)) - (y(84));
    residual(129) = (y(229)) - (y(85));
    residual(130) = (y(230)) - (y(203)-y(66));
    residual(131) = (y(231)) - (y(86));
    residual(132) = (y(232)) - (y(206)-y(69));
    residual(133) = (y(233)) - (y(87));
    residual(134) = (y(234)) - (y(88));
    residual(135) = (y(235)) - (y(209)-y(72));
    residual(136) = (y(236)) - (y(89));
    residual(137) = (y(237)) - (y(90));
    residual(138) = (y(238)) - (y(65)*params(152)+y(64)*params(153)+y(65)*params(154)+params(155)*y(91)+params(156)*y(92));
    residual(139) = (y(239)) - (y(68)*params(157)+y(67)*params(158)+y(68)*params(159)+params(160)*y(93)+params(161)*y(94));
    residual(140) = (y(240)) - (y(71)*params(162)+y(70)*params(163)+y(71)*params(164)+params(165)*y(95)+params(166)*y(96));
    residual(141) = (y(241)) - (y(74)*params(167)+y(73)*params(168)+y(74)*params(169)+params(170)*y(97)+params(171)*y(98));
    residual(142) = (y(242)) - (y(61)*params(172)+y(60)*params(173)+y(61)*params(174)+params(175)*y(99)+params(176)*y(100));
    residual(143) = (y(243)) - (y(64));
    residual(144) = (y(244)) - (y(65));
    residual(145) = (y(245)) - (y(67));
    residual(146) = (y(246)) - (y(68));
    residual(147) = (y(247)) - (y(70));
    residual(148) = (y(248)) - (y(71));
    residual(149) = (y(249)) - (y(73));
    residual(150) = (y(250)) - (y(74));
    residual(151) = (y(251)) - (y(60));
    residual(152) = (y(252)) - (y(61));

end
