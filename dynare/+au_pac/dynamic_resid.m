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
residual = zeros(140, 1);
    residual(1) = (y(102)) - (y(95)-y(99));
    residual(2) = (y(103)) - (y(96)-y(100));
    residual(3) = (y(104)) - (y(98)-y(101));
    residual(4) = (y(94)) - (params(1)*y(97)+params(2)*y(1)-params(3)*(y(6)-y(7))+params(18)*y(164)+x(it_, 1));
    residual(5) = (y(102)) - (y(6)*params(4)+(1-params(4))*(y(7)*params(5)+y(1)*params(6))+x(it_, 2));
    residual(6) = (y(103)) - (y(7)*params(7)+y(1)*params(8)+x(it_, 3));
    residual(7) = (y(97)) - (params(9)*y(2)+x(it_, 4));
    residual(8) = (y(104)) - (params(10)*y(8)+y(2)*params(11)+x(it_, 5));
    residual(9) = (y(99)) - (params(12)*y(3)+(1-params(12))*params(15)+x(it_, 6));
    residual(10) = (y(100)) - (params(13)*y(4)+(1-params(13))*params(16)+x(it_, 7));
    residual(11) = (y(101)) - (params(14)*y(5)+(1-params(14))*params(17)+x(it_, 8));
    residual(12) = (y(170)) - (params(2)*y(49)-params(3)*(y(50)-y(51))+x(it_, 34));
    residual(13) = (y(171)) - (params(4)*y(50)+(1-params(4))*(params(5)*y(51)+params(6)*y(49))+x(it_, 35));
    residual(14) = (y(172)) - (params(7)*y(51)+params(8)*y(49)+x(it_, 36));
    residual(15) = (y(173)) - (params(35)*y(52)+y(49)*params(34)+x(it_, 42));
    residual(16) = (y(174)) - (params(9)*y(53)+x(it_, 43));
    residual(17) = (y(175)) - (params(152)*y(54)+y(49)*params(153)+y(50)*params(154)+y(51)*params(155)+y(52)*params(156)+x(it_, 37));
    residual(18) = (y(176)) - (params(157)*y(55)+y(49)*params(158)+y(50)*params(159)+y(51)*params(160)+y(52)*params(161)+x(it_, 38));
    residual(19) = (y(177)) - (params(162)*y(56)+y(49)*params(163)+y(52)*params(164)+x(it_, 44));
    residual(20) = (y(178)) - (params(165)*y(57)+y(49)*params(166)+y(50)*params(167)+y(51)*params(168)+y(52)*params(169)+y(56)*params(170)+x(it_, 39));
    residual(21) = (y(179)) - (params(171)*y(58)+y(49)*params(172)+y(51)*params(173)+y(52)*params(174)+x(it_, 40));
    residual(22) = (y(180)) - (params(175)*y(59)+y(50)*params(176)+x(it_, 45));
    residual(23) = (y(181)) - (params(177)*y(60)+y(49)*params(178)+y(50)*params(179)+y(51)*params(180)+y(52)*params(181)+x(it_, 41));
    residual(24) = (y(105)) - (params(16)+y(208)-y(78));
    residual(25) = (y(209)) - (y(79)+y(106)-params(16));
    residual(26) = (y(124)) - (y(210)-y(80));
    residual(27) = (y(129)) - (y(211)-y(81));
    residual(28) = (y(134)) - (y(212)-y(82));
    residual(29) = (y(117)) - (y(213)-y(83));
    residual(30) = (y(109)) - ((1-params(62))*y(10)+y(129)*params(62));
    residual(31) = (y(110)) - (y(109)*params(26)+(1-params(26))*y(119)+y(111));
    residual(32) = (y(111)) - (params(27)*y(11)+x(it_, 30));
    residual(33) = (y(113)) - (y(111)/(1-params(26)));
    residual(34) = (y(112)) - (y(114)-y(113));
    residual(35) = (y(106)) - (params(23)*y(9)+y(112)*params(24)+params(25)*y(140)+y(100)*(1-params(23)-params(24)));
    residual(36) = (y(107)) - (y(100));
    residual(37) = (y(108)) - (y(209)-y(208));
    residual(38) = (y(182)) - (params(152)*y(61)+y(1)*params(153)+y(6)*params(154)+y(7)*params(155)+params(156)*y(13));
    residual(39) = (y(183)) - (params(157)*y(62)+y(1)*params(158)+y(6)*params(159)+y(7)*params(160)+params(161)*y(13));
    residual(40) = (y(184)) - (params(165)*y(63)+y(1)*params(166)+y(6)*params(167)+y(7)*params(168)+params(169)*y(13));
    residual(41) = (y(185)) - (params(171)*y(64)+y(1)*params(172)+y(7)*params(173)+params(174)*y(13));
    residual(42) = (y(186)) - (params(175)*y(65)+y(6)*params(176));
    residual(43) = (y(187)) - (params(177)*y(66)+y(1)*params(178)+y(6)*params(179)+y(7)*params(180)+params(181)*y(13));
    residual(44) = (y(214)) - (x(it_, 9)+y(182)+y(94)*params(21)+params(19)*(y(54)-y(78))+params(20)*y(215)+y(233));
    residual(45) = (y(115)) - (params(35)*y(13)+y(94)*params(34));
    residual(46) = (y(116)) - (y(115)*(1-params(36))+params(36)*y(234));
    residual(47) = (y(114)) - (params(31)*y(12)+y(96)*params(33)+y(116)*params(32)+y(100)*(1-params(31)-params(33))+y(113)*(1-params(31))+x(it_, 10));
    residual(48) = (y(118)) - (params(44)*y(15)+y(119)*(1-params(44)));
    residual(49) = (y(119)) - (y(111)/(1-params(26))-params(118)*y(165));
    residual(50) = (y(120)) - (y(118)+y(16)-y(117));
    residual(51) = (y(121)) - (y(14));
    residual(52) = (y(122)) - (y(17));
    residual(53) = (y(123)) - (y(18));
    residual(54) = (y(216)) - (x(it_, 11)+y(183)+y(94)*params(43)+params(37)*(y(55)-y(83))+params(38)*y(217)+params(39)*y(218)+params(40)*y(219)+params(41)*y(220)+y(232));
    residual(55) = (y(125)) - (params(50)*y(19)+(1-params(50))*y(126));
    residual(56) = (y(128)) - (y(94)*(1-params(52))+params(52)*y(235));
    residual(57) = (y(126)) - (params(51)*(y(128)-y(21))+params(53)*(y(167)-y(156)-(params(15)+params(73)+params(130)-params(16))-(y(46)-y(38)-(params(15)+params(73)+params(130)-params(16)))));
    residual(58) = (y(127)) - (y(125)+y(20)-y(124));
    residual(59) = (y(221)) - (x(it_, 12)+y(184)+y(94)*params(49)+y(6)*params(48)+params(45)*(y(57)-y(80))+params(46)*y(222)+y(229));
    residual(60) = (y(130)) - (params(60)*y(23)+(1-params(60))*y(131));
    residual(61) = (y(139)) - (params(62)+y(144)-(y(157)-y(105)));
    residual(62) = (y(140)) - (y(139)-y(28));
    residual(63) = (y(131)) - (y(94)*params(136)-y(140)*params(118));
    residual(64) = (y(132)) - (y(130)+y(24)-y(129));
    residual(65) = (y(133)) - (y(22));
    residual(66) = (y(223)) - (x(it_, 13)+y(185)+y(94)*params(58)+params(54)*(y(58)-y(81))+params(55)*y(224)+params(56)*y(225)+y(230)-y(186)*params(118));
    residual(67) = (y(135)) - (params(69)*y(26)+(1-params(69))*y(136));
    residual(68) = (y(136)) - ((y(128)-y(21))*params(135)-params(70)*(y(167)-(params(15)+params(73)+params(130)))+params(134)*y(48));
    residual(69) = (y(137)) - (y(135)+y(27)-y(134));
    residual(70) = (y(138)) - (y(25));
    residual(71) = (y(226)) - (x(it_, 14)+y(187)+y(6)*params(68)+y(94)*params(67)+params(63)*(y(60)-y(82))+params(64)*y(227)+params(65)*y(228)+y(231));
    residual(72) = (y(142)) - (params(74)*y(29)+params(73)*(1-params(74))+x(it_, 16));
    residual(73) = (y(143)) - (y(95)*(1-params(72))+params(72)*y(236));
    residual(74) = (y(141)) - (y(142)+y(143)+x(it_, 15));
    residual(75) = (y(148)) - ((1-params(80))*params(83)+params(80)*y(30)+x(it_, 17));
    residual(76) = (y(149)) - ((1-params(81))*params(84)+params(81)*y(31)+x(it_, 18));
    residual(77) = (y(150)) - ((1-params(82))*params(85)+params(82)*y(32)+x(it_, 19));
    residual(78) = (y(145)) - (y(141)+y(148));
    residual(79) = (y(146)) - (y(141)+y(149));
    residual(80) = (y(147)) - (y(141)+y(150));
    residual(81) = (y(144)) - (y(145)*params(77)+y(146)*params(78)+y(147)*params(79));
    residual(82) = (y(151)) - (params(86)*y(33)-y(102)*params(87)+params(87)*(y(103)-y(104))+x(it_, 20));
    residual(83) = (y(153)) - (y(35)-y(152));
    residual(84) = (y(152)) - (y(35)*params(88)+params(89)*y(34)+y(97)*params(90)+y(151)*params(91)+params(29)*y(161)+x(it_, 21));
    residual(85) = (y(155)) - (y(37)-y(154));
    residual(86) = (y(154)) - (y(37)*params(92)+params(93)*y(36)+params(94)*y(166)+y(151)*params(95)+x(it_, 22));
    residual(87) = (y(156)) - (y(38)*params(96)+y(105)*params(97)+params(119)*y(160)+y(161)*params(122)+y(100)*(1-params(96)-params(97)-params(119))+x(it_, 23));
    residual(88) = (y(157)) - (params(98)*y(39)+y(105)*params(99)+y(160)*params(120)+y(100)*(1-params(98)-params(99)-params(120))+x(it_, 24));
    residual(89) = (y(158)) - (params(100)*y(40)+y(105)*params(101)+y(160)*params(121)+y(100)*(1-params(100)-params(101)-params(121))+x(it_, 25));
    residual(90) = (y(159)) - (params(102)*y(41)+y(105)*params(103)+y(100)*(1-params(102)-params(103))+y(151)*params(104)+y(161)*params(30)+x(it_, 26));
    residual(91) = (y(160)) - (params(105)*y(42)+y(105)*params(106)+y(100)*(1-params(105)-params(106))+y(151)*params(107)+y(161)*params(123)+x(it_, 27));
    residual(92) = (y(161)) - (params(28)*y(43)+y(97)*0.10+x(it_, 31));
    residual(93) = (y(162)) - (params(108)*y(44)+y(94)*params(109)+x(it_, 28));
    residual(94) = (y(163)) - (params(110)*y(45)+(y(114)-y(113))*params(111)+y(100)*(1-params(110)-params(111))+x(it_, 29));
    residual(95) = (y(164)) - (y(124)*params(112)+y(129)*params(113)+y(134)*params(114)+y(162)*params(115)+y(152)*params(116)-y(154)*params(117));
    residual(96) = (y(165)) - (y(114)-y(105)-y(113));
    residual(97) = (y(166)) - (y(124)*params(124)+y(129)*params(125)+y(134)*params(126)+y(162)*params(127)+y(152)*params(128));
    residual(98) = (y(167)) - (y(46)*params(129)+(1-params(129))*(params(130)+y(141))+x(it_, 32));
    residual(99) = (y(168)) - (params(131)*y(47)+y(94)*params(132)+y(6)*params(133)+x(it_, 33));
    residual(100) = (y(169)) - (y(168)+y(48)*0.98);
    residual(101) = (y(203)) - (params(146)*(1-params(145))+y(141)*(1-params(145))+params(145)*y(74));
    residual(102) = (y(204)) - (y(141)*(1-params(145))+params(145)*y(75));
    residual(103) = (y(205)) - (y(141)*(1-params(145))+(1-params(145))*params(147)+params(145)*y(76));
    residual(104) = (y(206)) - (y(141)*(1-params(145))+(1-params(145))*params(148)+params(145)*y(77));
    residual(105) = (y(192)) - (y(203)*params(137)-y(200));
    residual(106) = (y(193)) - (y(204)*params(138));
    residual(107) = (y(194)) - (y(200)+y(205)*(-(params(137)+params(138)+params(139)))+y(202));
    residual(108) = (y(195)) - (y(206)*params(139)-y(202));
    residual(109) = (y(200)) - ((1-params(143))*y(71)+params(143)*params(140));
    residual(110) = (y(202)) - ((1-params(143))*y(73)+params(143)*params(142));
    residual(111) = (y(201)) - ((1-params(143))*y(72)+params(143)*params(141)+y(94)*0.05);
    residual(112) = (y(196)) - (y(129)*(-params(113))-(y(200)-params(140))+params(137)*(y(203)-(params(15)+params(73)+params(146))));
    residual(113) = (y(197)) - (y(162)*(-params(115))+y(94)*0.30-(y(201)-params(141))+params(138)*(y(204)-(params(15)+params(73))));
    residual(114) = (y(198)) - (params(112)*(y(94)-y(124))-y(134)*params(114)+(-(params(137)+params(138)+params(139)))*(y(205)-(params(15)+params(73)+params(147))));
    residual(115) = (y(199)) - (params(139)*(y(206)-(params(15)+params(73)+params(148))));
    residual(116) = (y(188)) - (y(196)+0.98*y(67)+params(137)*0.02);
    residual(117) = (y(189)) - (y(197)+0.98*y(68)+params(138)*0.02);
    residual(118) = (y(190)) - (y(198)+0.98*y(69)+(-(params(137)+params(138)+params(139)))*0.02);
    residual(119) = (y(191)) - (y(199)+0.98*y(70)+params(139)*0.02);
    residual(120) = (y(207)) - ((-(y(199)+y(198)+y(196)+y(197))));
    residual(121) = (y(214)) - (y(208)-y(78));
    residual(122) = (y(215)) - (y(84));
    residual(123) = (y(216)) - (y(213)-y(83));
    residual(124) = (y(217)) - (y(85));
    residual(125) = (y(218)) - (y(86));
    residual(126) = (y(219)) - (y(87));
    residual(127) = (y(220)) - (y(88));
    residual(128) = (y(221)) - (y(210)-y(80));
    residual(129) = (y(222)) - (y(89));
    residual(130) = (y(223)) - (y(211)-y(81));
    residual(131) = (y(224)) - (y(90));
    residual(132) = (y(225)) - (y(91));
    residual(133) = (y(226)) - (y(212)-y(82));
    residual(134) = (y(227)) - (y(92));
    residual(135) = (y(228)) - (y(93));
    residual(136) = (y(229)) - (params(182)+y(49)*params(183)+y(50)*params(184)+y(51)*params(185)+y(52)*params(186)+y(53)*params(187)+y(54)*params(188)+y(55)*params(189)+y(56)*params(190)+y(57)*params(191)+y(58)*params(192)+y(59)*params(193)+y(60)*params(194));
    residual(137) = (y(230)) - (params(195)+y(49)*params(196)+y(50)*params(197)+y(51)*params(198)+y(52)*params(199)+y(53)*params(200)+y(54)*params(201)+y(55)*params(202)+y(56)*params(203)+y(57)*params(204)+y(58)*params(205)+y(59)*params(206)+y(60)*params(207));
    residual(138) = (y(231)) - (params(208)+y(49)*params(209)+y(50)*params(210)+y(51)*params(211)+y(52)*params(212)+y(53)*params(213)+y(54)*params(214)+y(55)*params(215)+y(56)*params(216)+y(57)*params(217)+y(58)*params(218)+y(59)*params(219)+y(60)*params(220));
    residual(139) = (y(232)) - (params(221)+y(49)*params(222)+y(50)*params(223)+y(51)*params(224)+y(52)*params(225)+y(53)*params(226)+y(54)*params(227)+y(55)*params(228)+y(56)*params(229)+y(57)*params(230)+y(58)*params(231)+y(59)*params(232)+y(60)*params(233));
    residual(140) = (y(233)) - (params(234)+y(49)*params(235)+y(50)*params(236)+y(51)*params(237)+y(52)*params(238)+y(53)*params(239)+y(54)*params(240)+y(55)*params(241)+y(56)*params(242)+y(57)*params(243)+y(58)*params(244)+y(59)*params(245)+y(60)*params(246));

end
