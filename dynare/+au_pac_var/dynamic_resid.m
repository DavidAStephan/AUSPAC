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
    T = au_pac_var.dynamic_resid_tt(T, y, x, params, steady_state, it_);
end
residual = zeros(140, 1);
    residual(1) = (y(104)) - (y(97)-y(101));
    residual(2) = (y(105)) - (y(98)-y(102));
    residual(3) = (y(106)) - (y(100)-y(103));
    residual(4) = (y(96)) - (params(1)*y(99)+params(2)*y(1)-params(3)*(y(6)-y(7))+params(18)*y(166)+x(it_, 1));
    residual(5) = (y(104)) - (y(6)*params(4)+(1-params(4))*(y(7)*params(5)+y(1)*params(6))+x(it_, 2));
    residual(6) = (y(105)) - (y(7)*params(7)+y(1)*params(8)+x(it_, 3));
    residual(7) = (y(99)) - (params(9)*y(2)+x(it_, 4));
    residual(8) = (y(106)) - (params(10)*y(8)+y(2)*params(11)+x(it_, 5));
    residual(9) = (y(101)) - (params(12)*y(3)+(1-params(12))*params(15)+x(it_, 6));
    residual(10) = (y(102)) - (params(13)*y(4)+(1-params(13))*params(16)+x(it_, 7));
    residual(11) = (y(103)) - (params(14)*y(5)+(1-params(14))*params(17)+x(it_, 8));
    residual(12) = (y(172)) - (params(2)*y(51)-params(3)*(y(52)-y(53))+x(it_, 34));
    residual(13) = (y(173)) - (params(4)*y(52)+(1-params(4))*(params(5)*y(53)+params(6)*y(51))+x(it_, 35));
    residual(14) = (y(174)) - (params(7)*y(53)+params(8)*y(51)+x(it_, 36));
    residual(15) = (y(175)) - (params(35)*y(54)+y(51)*params(34)+x(it_, 42));
    residual(16) = (y(176)) - (params(9)*y(55)+x(it_, 43));
    residual(17) = (y(177)) - (params(138)*y(56)+y(51)*params(139)+y(52)*params(140)+y(53)*params(141)+y(54)*params(142)+x(it_, 37));
    residual(18) = (y(178)) - (params(143)*y(57)+y(51)*params(144)+y(52)*params(145)+y(53)*params(146)+y(54)*params(147)+x(it_, 38));
    residual(19) = (y(179)) - (params(148)*y(58)+y(51)*params(149)+y(54)*params(150)+x(it_, 44));
    residual(20) = (y(180)) - (params(151)*y(59)+y(51)*params(152)+y(52)*params(153)+y(53)*params(154)+y(54)*params(155)+y(58)*params(156)+x(it_, 39));
    residual(21) = (y(181)) - (params(157)*y(60)+y(51)*params(158)+y(53)*params(159)+y(54)*params(160)+x(it_, 40));
    residual(22) = (y(182)) - (params(161)*y(61)+y(52)*params(162)+x(it_, 45));
    residual(23) = (y(183)) - (params(163)*y(62)+y(51)*params(164)+y(52)*params(165)+y(53)*params(166)+y(54)*params(167)+x(it_, 41));
    residual(24) = (y(107)) - (params(16)+y(210)-y(80));
    residual(25) = (y(211)) - (y(81)+y(108)-params(16));
    residual(26) = (y(126)) - (y(212)-y(82));
    residual(27) = (y(131)) - (y(213)-y(83));
    residual(28) = (y(136)) - (y(214)-y(84));
    residual(29) = (y(119)) - (y(215)-y(85));
    residual(30) = (y(111)) - ((1-params(62))*y(10)+y(131)*params(62));
    residual(31) = (y(112)) - (y(111)*params(26)+(1-params(26))*y(121)+y(113));
    residual(32) = (y(113)) - (params(27)*y(11)+x(it_, 30));
    residual(33) = (y(115)) - (y(113)/(1-params(26)));
    residual(34) = (y(114)) - (y(116)-y(115));
    residual(35) = (y(108)) - (params(23)*y(9)+y(114)*params(24)+params(25)*y(142)+y(102)*(1-params(23)-params(24)));
    residual(36) = (y(109)) - (y(102));
    residual(37) = (y(110)) - (y(211)-y(210));
    residual(38) = (y(184)) - (params(138)*y(63)+y(1)*params(139)+y(6)*params(140)+y(7)*params(141)+params(142)*y(13));
    residual(39) = (y(185)) - (params(143)*y(64)+y(1)*params(144)+y(6)*params(145)+y(7)*params(146)+params(147)*y(13));
    residual(40) = (y(186)) - (params(151)*y(65)+y(1)*params(152)+y(6)*params(153)+y(7)*params(154)+params(155)*y(13));
    residual(41) = (y(187)) - (params(157)*y(66)+y(1)*params(158)+y(7)*params(159)+params(160)*y(13));
    residual(42) = (y(188)) - (params(161)*y(67)+y(6)*params(162));
    residual(43) = (y(189)) - (params(163)*y(68)+y(1)*params(164)+y(6)*params(165)+y(7)*params(166)+params(167)*y(13));
    residual(44) = (y(216)) - (x(it_, 9)+y(184)+y(96)*params(21)+params(19)*(y(56)-y(80))+params(20)*y(217)+y(235));
    residual(45) = (y(117)) - (params(35)*y(13)+y(96)*params(34));
    residual(46) = (y(118)) - (params(36)*y(14)+y(117)*(1-params(36)));
    residual(47) = (y(116)) - (params(31)*y(12)+y(98)*params(33)+y(118)*params(32)+y(102)*(1-params(31)-params(33))+y(115)*(1-params(31))+x(it_, 10));
    residual(48) = (y(120)) - (params(44)*y(16)+y(121)*(1-params(44)));
    residual(49) = (y(121)) - (y(113)/(1-params(26))-params(118)*y(167));
    residual(50) = (y(122)) - (y(120)+y(17)-y(119));
    residual(51) = (y(123)) - (y(15));
    residual(52) = (y(124)) - (y(18));
    residual(53) = (y(125)) - (y(19));
    residual(54) = (y(218)) - (x(it_, 11)+y(185)+y(96)*params(43)+params(37)*(y(57)-y(85))+params(38)*y(219)+params(39)*y(220)+params(40)*y(221)+params(41)*y(222)+y(234));
    residual(55) = (y(127)) - (params(50)*y(20)+(1-params(50))*y(128));
    residual(56) = (y(130)) - (params(52)*y(22)+y(96)*(1-params(52)));
    residual(57) = (y(128)) - (params(51)*(y(130)-y(22))+params(53)*(y(169)-y(158)-(params(15)+params(73)+params(130)-params(16))-(y(48)-y(40)-(params(15)+params(73)+params(130)-params(16)))));
    residual(58) = (y(129)) - (y(127)+y(21)-y(126));
    residual(59) = (y(223)) - (x(it_, 12)+y(186)+y(96)*params(49)+y(6)*params(48)+params(45)*(y(59)-y(82))+params(46)*y(224)+y(231));
    residual(60) = (y(132)) - (params(60)*y(24)+(1-params(60))*y(133));
    residual(61) = (y(141)) - (params(62)+y(146)-(y(159)-y(107)));
    residual(62) = (y(142)) - (y(141)-y(29));
    residual(63) = (y(133)) - (y(96)*params(136)-y(142)*params(118));
    residual(64) = (y(134)) - (y(132)+y(25)-y(131));
    residual(65) = (y(135)) - (y(23));
    residual(66) = (y(225)) - (x(it_, 13)+y(187)+y(96)*params(58)+params(54)*(y(60)-y(83))+params(55)*y(226)+params(56)*y(227)+y(232)-y(188)*params(118));
    residual(67) = (y(137)) - (params(69)*y(27)+(1-params(69))*y(138));
    residual(68) = (y(138)) - ((y(130)-y(22))*params(135)-params(70)*(y(169)-(params(15)+params(73)+params(130)))+params(134)*y(50));
    residual(69) = (y(139)) - (y(137)+y(28)-y(136));
    residual(70) = (y(140)) - (y(26));
    residual(71) = (y(228)) - (x(it_, 14)+y(6)*params(68)+y(96)*params(67)+y(189)+params(63)*(y(62)-y(84))+params(64)*y(229)+params(65)*y(230)+y(233));
    residual(72) = (y(144)) - (params(74)*y(30)+params(73)*(1-params(74))+x(it_, 16));
    residual(73) = (y(145)) - (params(72)*y(31)+y(97)*(1-params(72)));
    residual(74) = (y(143)) - (y(144)+y(145)+x(it_, 15));
    residual(75) = (y(150)) - ((1-params(80))*params(83)+params(80)*y(32)+x(it_, 17));
    residual(76) = (y(151)) - ((1-params(81))*params(84)+params(81)*y(33)+x(it_, 18));
    residual(77) = (y(152)) - ((1-params(82))*params(85)+params(82)*y(34)+x(it_, 19));
    residual(78) = (y(147)) - (y(143)+y(150));
    residual(79) = (y(148)) - (y(143)+y(151));
    residual(80) = (y(149)) - (y(143)+y(152));
    residual(81) = (y(146)) - (y(147)*params(77)+y(148)*params(78)+y(149)*params(79));
    residual(82) = (y(153)) - (params(86)*y(35)-y(104)*params(87)+params(87)*(y(105)-y(106))+x(it_, 20));
    residual(83) = (y(155)) - (y(37)-y(154));
    residual(84) = (y(154)) - (y(37)*params(88)+params(89)*y(36)+y(99)*params(90)+y(153)*params(91)+params(29)*y(163)+x(it_, 21));
    residual(85) = (y(157)) - (y(39)-y(156));
    residual(86) = (y(156)) - (y(39)*params(92)+params(93)*y(38)+params(94)*y(168)+y(153)*params(95)+x(it_, 22));
    residual(87) = (y(158)) - (y(40)*params(96)+y(107)*params(97)+params(119)*y(162)+y(163)*params(122)+y(102)*(1-params(96)-params(97)-params(119))+x(it_, 23));
    residual(88) = (y(159)) - (params(98)*y(41)+y(107)*params(99)+y(162)*params(120)+y(102)*(1-params(98)-params(99)-params(120))+x(it_, 24));
    residual(89) = (y(160)) - (params(100)*y(42)+y(107)*params(101)+y(162)*params(121)+y(102)*(1-params(100)-params(101)-params(121))+x(it_, 25));
    residual(90) = (y(161)) - (params(102)*y(43)+y(107)*params(103)+y(102)*(1-params(102)-params(103))+y(153)*params(104)+y(163)*params(30)+x(it_, 26));
    residual(91) = (y(162)) - (params(105)*y(44)+y(107)*params(106)+y(102)*(1-params(105)-params(106))+y(153)*params(107)+y(163)*params(123)+x(it_, 27));
    residual(92) = (y(163)) - (params(28)*y(45)+y(99)*0.10+x(it_, 31));
    residual(93) = (y(164)) - (params(108)*y(46)+y(96)*params(109)+x(it_, 28));
    residual(94) = (y(165)) - (params(110)*y(47)+(y(116)-y(115))*params(111)+y(102)*(1-params(110)-params(111))+x(it_, 29));
    residual(95) = (y(166)) - (y(126)*params(112)+y(131)*params(113)+y(136)*params(114)+y(164)*params(115)+y(154)*params(116)-y(156)*params(117));
    residual(96) = (y(167)) - (y(116)-y(107)-y(115));
    residual(97) = (y(168)) - (y(126)*params(124)+y(131)*params(125)+y(136)*params(126)+y(164)*params(127)+y(154)*params(128));
    residual(98) = (y(169)) - (y(48)*params(129)+(1-params(129))*(params(130)+y(143))+x(it_, 32));
    residual(99) = (y(170)) - (params(131)*y(49)+y(96)*params(132)+y(6)*params(133)+x(it_, 33));
    residual(100) = (y(171)) - (y(170)+y(50)*0.98);
    residual(101) = (y(205)) - (params(177)*(1-params(176))+y(143)*(1-params(176))+params(176)*y(76));
    residual(102) = (y(206)) - (y(143)*(1-params(176))+params(176)*y(77));
    residual(103) = (y(207)) - (y(143)*(1-params(176))+(1-params(176))*params(178)+params(176)*y(78));
    residual(104) = (y(208)) - (y(143)*(1-params(176))+(1-params(176))*params(179)+params(176)*y(79));
    residual(105) = (y(194)) - (y(205)*params(168)-y(202));
    residual(106) = (y(195)) - (y(206)*params(169));
    residual(107) = (y(196)) - (y(202)+y(207)*(-(params(168)+params(169)+params(170)))+y(204));
    residual(108) = (y(197)) - (y(208)*params(170)-y(204));
    residual(109) = (y(202)) - ((1-params(174))*y(73)+params(174)*params(171));
    residual(110) = (y(204)) - ((1-params(174))*y(75)+params(174)*params(173));
    residual(111) = (y(203)) - ((1-params(174))*y(74)+params(174)*params(172)+y(96)*0.05);
    residual(112) = (y(198)) - (y(131)*(-params(113))-(y(202)-params(171))+params(168)*(y(205)-(params(15)+params(73)+params(177))));
    residual(113) = (y(199)) - (y(164)*(-params(115))+y(96)*0.30-(y(203)-params(172))+params(169)*(y(206)-(params(15)+params(73))));
    residual(114) = (y(200)) - (params(112)*(y(96)-y(126))-y(136)*params(114)+(-(params(168)+params(169)+params(170)))*(y(207)-(params(15)+params(73)+params(178))));
    residual(115) = (y(201)) - (params(170)*(y(208)-(params(15)+params(73)+params(179))));
    residual(116) = (y(190)) - (y(198)+0.98*y(69)+params(168)*0.02);
    residual(117) = (y(191)) - (y(199)+0.98*y(70)+params(169)*0.02);
    residual(118) = (y(192)) - (y(200)+0.98*y(71)+(-(params(168)+params(169)+params(170)))*0.02);
    residual(119) = (y(193)) - (y(201)+0.98*y(72)+params(170)*0.02);
    residual(120) = (y(209)) - ((-(y(201)+y(200)+y(198)+y(199))));
    residual(121) = (y(216)) - (y(210)-y(80));
    residual(122) = (y(217)) - (y(86));
    residual(123) = (y(218)) - (y(215)-y(85));
    residual(124) = (y(219)) - (y(87));
    residual(125) = (y(220)) - (y(88));
    residual(126) = (y(221)) - (y(89));
    residual(127) = (y(222)) - (y(90));
    residual(128) = (y(223)) - (y(212)-y(82));
    residual(129) = (y(224)) - (y(91));
    residual(130) = (y(225)) - (y(213)-y(83));
    residual(131) = (y(226)) - (y(92));
    residual(132) = (y(227)) - (y(93));
    residual(133) = (y(228)) - (y(214)-y(84));
    residual(134) = (y(229)) - (y(94));
    residual(135) = (y(230)) - (y(95));
    residual(136) = (y(231)) - (params(182)+y(51)*params(183)+y(52)*params(184)+y(53)*params(185)+y(54)*params(186)+y(55)*params(187)+y(56)*params(188)+y(57)*params(189)+y(58)*params(190)+y(59)*params(191)+y(60)*params(192)+y(61)*params(193)+y(62)*params(194));
    residual(137) = (y(232)) - (params(195)+y(51)*params(196)+y(52)*params(197)+y(53)*params(198)+y(54)*params(199)+y(55)*params(200)+y(56)*params(201)+y(57)*params(202)+y(58)*params(203)+y(59)*params(204)+y(60)*params(205)+y(61)*params(206)+y(62)*params(207));
    residual(138) = (y(233)) - (params(208)+y(51)*params(209)+y(52)*params(210)+y(53)*params(211)+y(54)*params(212)+y(55)*params(213)+y(56)*params(214)+y(57)*params(215)+y(58)*params(216)+y(59)*params(217)+y(60)*params(218)+y(61)*params(219)+y(62)*params(220));
    residual(139) = (y(234)) - (params(221)+y(51)*params(222)+y(52)*params(223)+y(53)*params(224)+y(54)*params(225)+y(55)*params(226)+y(56)*params(227)+y(57)*params(228)+y(58)*params(229)+y(59)*params(230)+y(60)*params(231)+y(61)*params(232)+y(62)*params(233));
    residual(140) = (y(235)) - (params(234)+y(51)*params(235)+y(52)*params(236)+y(53)*params(237)+y(54)*params(238)+y(55)*params(239)+y(56)*params(240)+y(57)*params(241)+y(58)*params(242)+y(59)*params(243)+y(60)*params(244)+y(61)*params(245)+y(62)*params(246));

end
