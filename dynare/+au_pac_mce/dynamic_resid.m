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
    T = au_pac_mce.dynamic_resid_tt(T, y, x, params, steady_state, it_);
end
residual = zeros(154, 1);
    residual(1) = (y(90)) - (y(83)-y(87));
    residual(2) = (y(91)) - (y(84)-y(88));
    residual(3) = (y(92)) - (y(86)-y(89));
    residual(4) = (y(82)) - (params(1)*y(85)+params(2)*y(1)-params(3)*(y(6)-y(7))+params(18)*y(154)+x(it_, 1));
    residual(5) = (y(90)) - (y(6)*params(4)+(1-params(4))*(y(7)*params(5)+y(1)*params(6))+x(it_, 2));
    residual(6) = (y(91)) - (y(7)*params(7)+y(1)*params(8)+x(it_, 3));
    residual(7) = (y(85)) - (params(9)*y(2)+x(it_, 4));
    residual(8) = (y(92)) - (params(10)*y(8)+y(2)*params(11)+x(it_, 5));
    residual(9) = (y(87)) - (params(12)*y(3)+(1-params(12))*params(15)+x(it_, 6));
    residual(10) = (y(88)) - (params(13)*y(4)+(1-params(13))*params(16)+x(it_, 7));
    residual(11) = (y(89)) - (params(14)*y(5)+(1-params(14))*params(17)+x(it_, 8));
    residual(12) = (y(180)) - (y(61)+x(it_, 34));
    residual(13) = (y(183)) - (y(64)+x(it_, 35));
    residual(14) = (y(185)) - (y(66)+x(it_, 36));
    residual(15) = (y(187)) - (y(68)+x(it_, 37));
    residual(16) = (y(189)) - (y(70)+x(it_, 38));
    residual(17) = (y(93)) - (params(16)+y(181)-y(62));
    residual(18) = (y(182)) - (y(63)+y(94)-params(16));
    residual(19) = (y(112)) - (y(184)-y(65));
    residual(20) = (y(118)) - (y(186)-y(67));
    residual(21) = (y(123)) - (y(188)-y(69));
    residual(22) = (y(105)) - (y(190)-y(71));
    residual(23) = (y(97)) - ((1-params(62))*y(10)+y(118)*params(62));
    residual(24) = (y(98)) - (y(97)*params(26)+(1-params(26))*y(107)+y(99));
    residual(25) = (y(99)) - (params(27)*y(11)+x(it_, 30));
    residual(26) = (y(101)) - (y(99)/(1-params(26)));
    residual(27) = (y(100)) - (y(102)-y(101));
    residual(28) = (y(94)) - (params(23)*y(9)+y(100)*params(24)+params(25)*y(129)+y(88)*(1-params(23)-params(24)));
    residual(29) = (y(95)) - (y(88));
    residual(30) = (y(96)) - (y(182)-y(181));
    residual(31) = (y(191)) - (x(it_, 9)+y(82)*params(21)+params(19)*(y(61)-y(62))+params(20)*y(192)+y(61)*params(169)+y(223));
    residual(32) = (y(103)) - (params(35)*y(13)+y(82)*params(34));
    residual(33) = (y(104)) - (y(103)*(1-params(36))+params(36)*y(236));
    residual(34) = (y(102)) - (params(31)*y(12)+y(84)*params(33)+y(104)*params(32)+y(88)*(1-params(31)-params(33))+y(101)*(1-params(31))+x(it_, 10));
    residual(35) = (y(106)) - (params(44)*y(15)+y(107)*(1-params(44)));
    residual(36) = (y(107)) - (y(99)/(1-params(26))-params(118)*y(155));
    residual(37) = (y(108)) - (y(106)+y(16)-y(105));
    residual(38) = (y(109)) - (y(14));
    residual(39) = (y(110)) - (y(17));
    residual(40) = (y(111)) - (y(18));
    residual(41) = (y(193)) - (x(it_, 11)+y(82)*params(43)+params(37)*(y(70)-y(71))+params(38)*y(194)+params(39)*y(195)+params(40)*y(196)+params(41)*y(197)+y(70)*params(163)+y(217));
    residual(42) = (y(113)) - (params(50)*y(19)+(1-params(50))*y(114));
    residual(43) = (y(116)) - (y(82)*(1-params(52))+params(52)*y(237));
    residual(44) = (y(117)) - (y(116)*(1-params(52))+params(52)*y(238));
    residual(45) = (y(114)) - (params(51)*(y(117)-y(22))+params(53)*(y(157)-y(146)-(params(15)+params(73)+params(130)-params(16))-(y(47)-y(39)-(params(15)+params(73)+params(130)-params(16)))));
    residual(46) = (y(115)) - (y(113)+y(20)-y(112));
    residual(47) = (y(198)) - (x(it_, 12)+y(82)*params(49)+y(6)*params(48)+params(45)*(y(64)-y(65))+params(46)*y(199)+y(64)*params(152)+y(206));
    residual(48) = (y(119)) - (params(60)*y(24)+(1-params(60))*y(120));
    residual(49) = (y(128)) - (params(62)+y(134)-(y(147)-y(93)));
    residual(50) = (y(129)) - (y(128)-y(29));
    residual(51) = (y(130)) - (y(129)*(1-params(151))+params(151)*y(239));
    residual(52) = (y(120)) - (y(82)*params(136)-y(129)*params(118));
    residual(53) = (y(121)) - (y(119)+y(25)-y(118));
    residual(54) = (y(122)) - (y(23));
    residual(55) = (y(200)) - (x(it_, 13)+y(82)*params(58)+params(54)*(y(66)-y(67))+params(55)*y(201)+params(56)*y(202)+y(66)*params(155)+y(209)-params(118)*y(130));
    residual(56) = (y(124)) - (params(69)*y(27)+(1-params(69))*y(125));
    residual(57) = (y(125)) - (params(135)*(y(116)-y(21))-params(70)*(y(157)-(params(15)+params(73)+params(130)))+params(134)*y(49));
    residual(58) = (y(126)) - (y(124)+y(28)-y(123));
    residual(59) = (y(127)) - (y(26));
    residual(60) = (y(203)) - (x(it_, 14)+y(6)*params(68)+y(82)*params(67)+params(63)*(y(68)-y(69))+params(64)*y(204)+params(65)*y(205)+y(68)*params(159)+y(213));
    residual(61) = (y(132)) - (params(74)*y(30)+params(73)*(1-params(74))+x(it_, 16));
    residual(62) = (y(133)) - (y(83)*(1-params(72))+params(72)*y(240));
    residual(63) = (y(131)) - (y(132)+y(133)+x(it_, 15));
    residual(64) = (y(138)) - ((1-params(80))*params(83)+params(80)*y(31)+x(it_, 17));
    residual(65) = (y(139)) - ((1-params(81))*params(84)+params(81)*y(32)+x(it_, 18));
    residual(66) = (y(140)) - ((1-params(82))*params(85)+params(82)*y(33)+x(it_, 19));
    residual(67) = (y(135)) - (y(131)+y(138));
    residual(68) = (y(136)) - (y(131)+y(139));
    residual(69) = (y(137)) - (y(131)+y(140));
    residual(70) = (y(134)) - (y(135)*params(77)+y(136)*params(78)+y(137)*params(79));
    residual(71) = (y(141)) - (params(86)*y(34)-y(90)*params(87)+params(87)*(y(91)-y(92))+x(it_, 20));
    residual(72) = (y(143)) - (y(36)-y(142));
    residual(73) = (y(142)) - (y(36)*params(88)+params(89)*y(35)+y(85)*params(90)+y(141)*params(91)+params(29)*y(151)+x(it_, 21));
    residual(74) = (y(145)) - (y(38)-y(144));
    residual(75) = (y(144)) - (y(38)*params(92)+params(93)*y(37)+params(94)*y(156)+y(141)*params(95)+x(it_, 22));
    residual(76) = (y(146)) - (y(39)*params(96)+y(93)*params(97)+params(119)*y(150)+y(151)*params(122)+y(88)*(1-params(96)-params(97)-params(119))+x(it_, 23));
    residual(77) = (y(147)) - (params(98)*y(40)+y(93)*params(99)+y(150)*params(120)+y(88)*(1-params(98)-params(99)-params(120))+x(it_, 24));
    residual(78) = (y(148)) - (params(100)*y(41)+y(93)*params(101)+y(150)*params(121)+y(88)*(1-params(100)-params(101)-params(121))+x(it_, 25));
    residual(79) = (y(149)) - (params(102)*y(42)+y(93)*params(103)+y(88)*(1-params(102)-params(103))+y(141)*params(104)+y(151)*params(30)+x(it_, 26));
    residual(80) = (y(150)) - (params(105)*y(43)+y(93)*params(106)+y(88)*(1-params(105)-params(106))+y(141)*params(107)+y(151)*params(123)+x(it_, 27));
    residual(81) = (y(151)) - (params(28)*y(44)+y(85)*0.10+x(it_, 31));
    residual(82) = (y(152)) - (params(108)*y(45)+y(82)*params(109)+x(it_, 28));
    residual(83) = (y(153)) - (params(110)*y(46)+(y(102)-y(101))*params(111)+y(88)*(1-params(110)-params(111))+x(it_, 29));
    residual(84) = (y(154)) - (y(112)*params(112)+y(118)*params(113)+y(123)*params(114)+y(152)*params(115)+y(142)*params(116)-y(144)*params(117));
    residual(85) = (y(155)) - (y(102)-y(93)-y(101));
    residual(86) = (y(156)) - (y(112)*params(124)+y(118)*params(125)+y(123)*params(126)+y(152)*params(127)+y(142)*params(128));
    residual(87) = (y(157)) - (y(47)*params(129)+(1-params(129))*(params(130)+y(131))+x(it_, 32));
    residual(88) = (y(158)) - (params(131)*y(48)+y(82)*params(132)+y(6)*params(133)+x(it_, 33));
    residual(89) = (y(159)) - (y(158)+y(49)*0.98);
    residual(90) = (y(175)) - (params(146)*(1-params(145))+y(131)*(1-params(145))+params(145)*y(57));
    residual(91) = (y(176)) - (y(131)*(1-params(145))+params(145)*y(58));
    residual(92) = (y(177)) - (y(131)*(1-params(145))+(1-params(145))*params(147)+params(145)*y(59));
    residual(93) = (y(178)) - (y(131)*(1-params(145))+(1-params(145))*params(148)+params(145)*y(60));
    residual(94) = (y(164)) - (y(175)*params(137)-y(172));
    residual(95) = (y(165)) - (y(176)*params(138));
    residual(96) = (y(166)) - (y(172)+y(177)*(-(params(137)+params(138)+params(139)))+y(174));
    residual(97) = (y(167)) - (y(178)*params(139)-y(174));
    residual(98) = (y(172)) - ((1-params(143))*y(54)+params(143)*params(140));
    residual(99) = (y(174)) - ((1-params(143))*y(56)+params(143)*params(142));
    residual(100) = (y(173)) - ((1-params(143))*y(55)+params(143)*params(141)+y(82)*0.05);
    residual(101) = (y(168)) - (y(118)*(-params(113))-(y(172)-params(140))+params(137)*(y(175)-(params(15)+params(73)+params(146))));
    residual(102) = (y(169)) - (y(152)*(-params(115))+y(82)*0.30-(y(173)-params(141))+params(138)*(y(176)-(params(15)+params(73))));
    residual(103) = (y(170)) - (params(112)*(y(82)-y(112))-y(123)*params(114)+(-(params(137)+params(138)+params(139)))*(y(177)-(params(15)+params(73)+params(147))));
    residual(104) = (y(171)) - (params(139)*(y(178)-(params(15)+params(73)+params(148))));
    residual(105) = (y(160)) - (y(168)+0.98*y(50)+params(137)*0.02);
    residual(106) = (y(161)) - (y(169)+0.98*y(51)+params(138)*0.02);
    residual(107) = (y(162)) - (y(170)+0.98*y(52)+(-(params(137)+params(138)+params(139)))*0.02);
    residual(108) = (y(163)) - (y(171)+0.98*y(53)+params(139)*0.02);
    residual(109) = (y(179)) - ((-(y(171)+y(170)+y(168)+y(169))));
    residual(110) = (y(191)) - (y(181)-y(62));
    residual(111) = (y(192)) - (y(72));
    residual(112) = (y(193)) - (y(190)-y(71));
    residual(113) = (y(194)) - (y(73));
    residual(114) = (y(195)) - (y(74));
    residual(115) = (y(196)) - (y(75));
    residual(116) = (y(197)) - (y(76));
    residual(117) = (y(198)) - (y(184)-y(65));
    residual(118) = (y(199)) - (y(77));
    residual(119) = (y(200)) - (y(186)-y(67));
    residual(120) = (y(201)) - (y(78));
    residual(121) = (y(202)) - (y(79));
    residual(122) = (y(203)) - (y(188)-y(69));
    residual(123) = (y(204)) - (y(80));
    residual(124) = (y(205)) - (y(81));
    residual(125) = (y(207)) - (y(183)-y(64));
    residual(126) = (y(208)) - (y(242));
    residual(127) = (y(206)) - ((1+params(153)+params(154))*(y(207)-T(2)*y(208))-(y(241)*params(151)*params(153)+T(2)*y(256)));
    residual(128) = (y(210)) - (y(185)-y(66));
    residual(129) = (y(211)) - (y(244));
    residual(130) = (y(212)) - (y(245));
    residual(131) = (y(209)) - ((1+params(156)+params(157)+params(158))*(y(210)-(y(211)*(T(1)*params(157)+T(4))+T(4)*y(212)))-(y(243)*params(151)*params(156)+T(1)*params(157)*y(257)+T(4)*y(258)));
    residual(132) = (y(214)) - (y(187)-y(68));
    residual(133) = (y(215)) - (y(247));
    residual(134) = (y(216)) - (y(248));
    residual(135) = (y(213)) - ((1+params(160)+params(161)+params(162))*(y(214)-(y(215)*(T(1)*params(161)+T(3)*params(162))+T(3)*params(162)*y(216)))-(y(246)*params(151)*params(160)+T(1)*params(161)*y(259)+T(3)*params(162)*y(260)));
    residual(136) = (y(218)) - (y(189)-y(70));
    residual(137) = (y(219)) - (y(250));
    residual(138) = (y(220)) - (y(251));
    residual(139) = (y(221)) - (y(252));
    residual(140) = (y(222)) - (y(253));
    residual(141) = (y(217)) - ((1+params(164)+params(165)+params(166)+params(167)+params(168))*(y(218)-(y(219)*(T(6)+T(5)+T(1)*params(165)+T(3)*params(166))+y(220)*(T(6)+T(3)*params(166)+T(5))+y(221)*(T(5)+T(6))+T(6)*y(222)))-(y(249)*params(151)*params(164)+T(1)*params(165)*y(261)+T(3)*params(166)*y(262)+T(5)*y(263)+T(6)*y(264)));
    residual(142) = (y(224)) - (y(180)-y(61));
    residual(143) = (y(225)) - (y(255));
    residual(144) = (y(223)) - ((1+params(170)+params(171))*(y(224)-T(1)*params(171)*y(225))-(y(254)*params(151)*params(170)+T(1)*params(171)*y(265)));
    residual(145) = (y(226)) - (y(241));
    residual(146) = (y(227)) - (y(243));
    residual(147) = (y(228)) - (y(257));
    residual(148) = (y(229)) - (y(246));
    residual(149) = (y(230)) - (y(259));
    residual(150) = (y(231)) - (y(249));
    residual(151) = (y(232)) - (y(261));
    residual(152) = (y(233)) - (y(262));
    residual(153) = (y(234)) - (y(263));
    residual(154) = (y(235)) - (y(254));

end
