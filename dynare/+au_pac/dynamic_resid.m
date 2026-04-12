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
residual = zeros(135, 1);
    residual(1) = (y(97)) - (y(90)-y(94));
    residual(2) = (y(98)) - (y(91)-y(95));
    residual(3) = (y(99)) - (y(93)-y(96));
    residual(4) = (y(89)) - (params(1)*y(92)+params(2)*y(1)-params(3)*(y(6)-y(7))+params(18)*y(159)+x(it_, 1));
    residual(5) = (y(97)) - (y(6)*params(4)+(1-params(4))*(y(7)*params(5)+y(1)*params(6))+x(it_, 2));
    residual(6) = (y(98)) - (y(7)*params(7)+y(1)*params(8)+x(it_, 3));
    residual(7) = (y(92)) - (params(9)*y(2)+x(it_, 4));
    residual(8) = (y(99)) - (params(10)*y(8)+y(2)*params(11)+x(it_, 5));
    residual(9) = (y(94)) - (params(12)*y(3)+(1-params(12))*params(15)+x(it_, 6));
    residual(10) = (y(95)) - (params(13)*y(4)+(1-params(13))*params(16)+x(it_, 7));
    residual(11) = (y(96)) - (params(14)*y(5)+(1-params(14))*params(17)+x(it_, 8));
    residual(12) = (y(165)) - (params(2)*y(49)-params(3)*(y(50)-y(51))+x(it_, 34));
    residual(13) = (y(166)) - (params(4)*y(50)+(1-params(4))*(params(5)*y(51)+params(6)*y(49))+x(it_, 35));
    residual(14) = (y(167)) - (params(7)*y(51)+params(8)*y(49)+x(it_, 36));
    residual(15) = (y(168)) - (params(152)*y(52)+y(49)*params(153)+y(50)*params(154)+y(51)*params(155)+x(it_, 37));
    residual(16) = (y(169)) - (params(156)*y(53)+y(49)*params(157)+y(50)*params(158)+y(51)*params(159)+x(it_, 38));
    residual(17) = (y(170)) - (params(160)*y(54)+y(49)*params(161)+y(50)*params(162)+y(51)*params(163)+x(it_, 39));
    residual(18) = (y(171)) - (params(164)*y(55)+y(49)*params(165)+y(50)*params(166)+y(51)*params(167)+x(it_, 40));
    residual(19) = (y(172)) - (params(168)*y(56)+y(49)*params(169)+y(50)*params(170)+y(51)*params(171)+x(it_, 41));
    residual(20) = (y(100)) - (params(16)+y(198)-y(73));
    residual(21) = (y(199)) - (y(74)+y(101)-params(16));
    residual(22) = (y(119)) - (y(200)-y(75));
    residual(23) = (y(124)) - (y(201)-y(76));
    residual(24) = (y(129)) - (y(202)-y(77));
    residual(25) = (y(112)) - (y(203)-y(78));
    residual(26) = (y(104)) - ((1-params(62))*y(10)+y(124)*params(62));
    residual(27) = (y(105)) - (y(104)*params(26)+(1-params(26))*y(114)+y(106));
    residual(28) = (y(106)) - (params(27)*y(11)+x(it_, 30));
    residual(29) = (y(108)) - (y(106)/(1-params(26)));
    residual(30) = (y(107)) - (y(109)-y(108));
    residual(31) = (y(101)) - (params(23)*y(9)+y(107)*params(24)+params(25)*y(135)+y(95)*(1-params(23)-params(24)));
    residual(32) = (y(102)) - (y(95));
    residual(33) = (y(103)) - (y(199)-y(198));
    residual(34) = (y(173)) - (params(152)*y(57)+y(1)*params(153)+y(6)*params(154)+y(7)*params(155));
    residual(35) = (y(174)) - (params(156)*y(58)+y(1)*params(157)+y(6)*params(158)+y(7)*params(159));
    residual(36) = (y(175)) - (params(160)*y(59)+y(1)*params(161)+y(6)*params(162)+y(7)*params(163));
    residual(37) = (y(176)) - (params(164)*y(60)+y(1)*params(165)+y(6)*params(166)+y(7)*params(167));
    residual(38) = (y(177)) - (params(168)*y(61)+y(1)*params(169)+y(6)*params(170)+y(7)*params(171));
    residual(39) = (y(204)) - (x(it_, 9)+y(173)+y(89)*params(21)+params(19)*(y(52)-y(73))+params(20)*y(205)+y(223));
    residual(40) = (y(110)) - (params(35)*y(13)+y(89)*params(34));
    residual(41) = (y(111)) - (y(110)*(1-params(36))+params(36)*y(224));
    residual(42) = (y(109)) - (params(31)*y(12)+y(91)*params(33)+y(111)*params(32)+y(95)*(1-params(31)-params(33))+y(108)*(1-params(31))+x(it_, 10));
    residual(43) = (y(113)) - (params(44)*y(15)+y(114)*(1-params(44)));
    residual(44) = (y(114)) - (y(106)/(1-params(26))-params(118)*y(160));
    residual(45) = (y(115)) - (y(113)+y(16)-y(112));
    residual(46) = (y(116)) - (y(14));
    residual(47) = (y(117)) - (y(17));
    residual(48) = (y(118)) - (y(18));
    residual(49) = (y(206)) - (x(it_, 11)+y(174)+y(89)*params(43)+params(37)*(y(53)-y(78))+params(38)*y(207)+params(39)*y(208)+params(40)*y(209)+params(41)*y(210)+y(222));
    residual(50) = (y(120)) - (params(50)*y(19)+(1-params(50))*y(121));
    residual(51) = (y(123)) - (y(89)*(1-params(52))+params(52)*y(225));
    residual(52) = (y(121)) - (params(51)*(y(123)-y(21))+params(53)*(y(162)-y(151)-(params(15)+params(73)+params(130)-params(16))-(y(46)-y(38)-(params(15)+params(73)+params(130)-params(16)))));
    residual(53) = (y(122)) - (y(120)+y(20)-y(119));
    residual(54) = (y(211)) - (x(it_, 12)+y(175)+y(89)*params(49)+y(6)*params(48)+params(45)*(y(54)-y(75))+params(46)*y(212)+y(219));
    residual(55) = (y(125)) - (params(60)*y(23)+(1-params(60))*y(126));
    residual(56) = (y(134)) - (params(62)+y(139)-(y(152)-y(100)));
    residual(57) = (y(135)) - (y(134)-y(28));
    residual(58) = (y(126)) - (y(89)*params(136)-y(135)*params(118));
    residual(59) = (y(127)) - (y(125)+y(24)-y(124));
    residual(60) = (y(128)) - (y(22));
    residual(61) = (y(213)) - (x(it_, 13)+y(176)+y(6)*params(59)+y(89)*params(58)+params(54)*(y(55)-y(76))+params(55)*y(214)+params(56)*y(215)+y(220));
    residual(62) = (y(130)) - (params(69)*y(26)+(1-params(69))*y(131));
    residual(63) = (y(131)) - ((y(123)-y(21))*params(135)-params(70)*(y(162)-(params(15)+params(73)+params(130)))+params(134)*y(48));
    residual(64) = (y(132)) - (y(130)+y(27)-y(129));
    residual(65) = (y(133)) - (y(25));
    residual(66) = (y(216)) - (x(it_, 14)+y(177)+y(6)*params(68)+y(89)*params(67)+params(63)*(y(56)-y(77))+params(64)*y(217)+params(65)*y(218)+y(221));
    residual(67) = (y(137)) - (params(74)*y(29)+params(73)*(1-params(74))+x(it_, 16));
    residual(68) = (y(138)) - (y(90)*(1-params(72))+params(72)*y(226));
    residual(69) = (y(136)) - (y(137)+y(138)+x(it_, 15));
    residual(70) = (y(143)) - ((1-params(80))*params(83)+params(80)*y(30)+x(it_, 17));
    residual(71) = (y(144)) - ((1-params(81))*params(84)+params(81)*y(31)+x(it_, 18));
    residual(72) = (y(145)) - ((1-params(82))*params(85)+params(82)*y(32)+x(it_, 19));
    residual(73) = (y(140)) - (y(136)+y(143));
    residual(74) = (y(141)) - (y(136)+y(144));
    residual(75) = (y(142)) - (y(136)+y(145));
    residual(76) = (y(139)) - (y(140)*params(77)+y(141)*params(78)+y(142)*params(79));
    residual(77) = (y(146)) - (params(86)*y(33)-y(97)*params(87)+params(87)*(y(98)-y(99))+x(it_, 20));
    residual(78) = (y(148)) - (y(35)-y(147));
    residual(79) = (y(147)) - (y(35)*params(88)+params(89)*y(34)+y(92)*params(90)+y(146)*params(91)+params(29)*y(156)+x(it_, 21));
    residual(80) = (y(150)) - (y(37)-y(149));
    residual(81) = (y(149)) - (y(37)*params(92)+params(93)*y(36)+params(94)*y(161)+y(146)*params(95)+x(it_, 22));
    residual(82) = (y(151)) - (y(38)*params(96)+y(100)*params(97)+params(119)*y(155)+y(156)*params(122)+y(95)*(1-params(96)-params(97)-params(119))+x(it_, 23));
    residual(83) = (y(152)) - (params(98)*y(39)+y(100)*params(99)+y(155)*params(120)+y(95)*(1-params(98)-params(99)-params(120))+x(it_, 24));
    residual(84) = (y(153)) - (params(100)*y(40)+y(100)*params(101)+y(155)*params(121)+y(95)*(1-params(100)-params(101)-params(121))+x(it_, 25));
    residual(85) = (y(154)) - (params(102)*y(41)+y(100)*params(103)+y(95)*(1-params(102)-params(103))+y(146)*params(104)+y(156)*params(30)+x(it_, 26));
    residual(86) = (y(155)) - (params(105)*y(42)+y(100)*params(106)+y(95)*(1-params(105)-params(106))+y(146)*params(107)+y(156)*params(123)+x(it_, 27));
    residual(87) = (y(156)) - (params(28)*y(43)+y(92)*0.10+x(it_, 31));
    residual(88) = (y(157)) - (params(108)*y(44)+y(89)*params(109)+x(it_, 28));
    residual(89) = (y(158)) - (params(110)*y(45)+(y(109)-y(108))*params(111)+y(95)*(1-params(110)-params(111))+x(it_, 29));
    residual(90) = (y(159)) - (y(119)*params(112)+y(124)*params(113)+y(129)*params(114)+y(157)*params(115)+y(147)*params(116)-y(149)*params(117));
    residual(91) = (y(160)) - (y(109)-y(100)-y(108));
    residual(92) = (y(161)) - (y(119)*params(124)+y(124)*params(125)+y(129)*params(126)+y(157)*params(127)+y(147)*params(128));
    residual(93) = (y(162)) - (y(46)*params(129)+(1-params(129))*(params(130)+y(136))+x(it_, 32));
    residual(94) = (y(163)) - (params(131)*y(47)+y(89)*params(132)+y(6)*params(133)+x(it_, 33));
    residual(95) = (y(164)) - (y(163)+y(48)*0.98);
    residual(96) = (y(193)) - (params(146)*(1-params(145))+y(136)*(1-params(145))+params(145)*y(69));
    residual(97) = (y(194)) - (y(136)*(1-params(145))+params(145)*y(70));
    residual(98) = (y(195)) - (y(136)*(1-params(145))+(1-params(145))*params(147)+params(145)*y(71));
    residual(99) = (y(196)) - (y(136)*(1-params(145))+(1-params(145))*params(148)+params(145)*y(72));
    residual(100) = (y(182)) - (y(193)*params(137)-y(190));
    residual(101) = (y(183)) - (y(194)*params(138));
    residual(102) = (y(184)) - (y(190)+y(195)*(-(params(137)+params(138)+params(139)))+y(192));
    residual(103) = (y(185)) - (y(196)*params(139)-y(192));
    residual(104) = (y(190)) - ((1-params(143))*y(66)+params(143)*params(140));
    residual(105) = (y(192)) - ((1-params(143))*y(68)+params(143)*params(142));
    residual(106) = (y(191)) - ((1-params(143))*y(67)+params(143)*params(141)+y(89)*0.05);
    residual(107) = (y(186)) - (y(124)*(-params(113))-(y(190)-params(140))+params(137)*(y(193)-(params(15)+params(73)+params(146))));
    residual(108) = (y(187)) - (y(157)*(-params(115))+y(89)*0.30-(y(191)-params(141))+params(138)*(y(194)-(params(15)+params(73))));
    residual(109) = (y(188)) - (params(112)*(y(89)-y(119))-y(129)*params(114)+(-(params(137)+params(138)+params(139)))*(y(195)-(params(15)+params(73)+params(147))));
    residual(110) = (y(189)) - (params(139)*(y(196)-(params(15)+params(73)+params(148))));
    residual(111) = (y(178)) - (y(186)+0.98*y(62)+params(137)*0.02);
    residual(112) = (y(179)) - (y(187)+0.98*y(63)+params(138)*0.02);
    residual(113) = (y(180)) - (y(188)+0.98*y(64)+(-(params(137)+params(138)+params(139)))*0.02);
    residual(114) = (y(181)) - (y(189)+0.98*y(65)+params(139)*0.02);
    residual(115) = (y(197)) - ((-(y(189)+y(188)+y(186)+y(187))));
    residual(116) = (y(204)) - (y(198)-y(73));
    residual(117) = (y(205)) - (y(79));
    residual(118) = (y(206)) - (y(203)-y(78));
    residual(119) = (y(207)) - (y(80));
    residual(120) = (y(208)) - (y(81));
    residual(121) = (y(209)) - (y(82));
    residual(122) = (y(210)) - (y(83));
    residual(123) = (y(211)) - (y(200)-y(75));
    residual(124) = (y(212)) - (y(84));
    residual(125) = (y(213)) - (y(201)-y(76));
    residual(126) = (y(214)) - (y(85));
    residual(127) = (y(215)) - (y(86));
    residual(128) = (y(216)) - (y(202)-y(77));
    residual(129) = (y(217)) - (y(87));
    residual(130) = (y(218)) - (y(88));
    residual(131) = (y(219)) - (params(172)+y(49)*params(173)+y(50)*params(174)+y(51)*params(175)+y(52)*params(176)+y(53)*params(177)+y(54)*params(178)+y(55)*params(179)+y(56)*params(180));
    residual(132) = (y(220)) - (params(181)+y(49)*params(182)+y(50)*params(183)+y(51)*params(184)+y(52)*params(185)+y(53)*params(186)+y(54)*params(187)+y(55)*params(188)+y(56)*params(189));
    residual(133) = (y(221)) - (params(190)+y(49)*params(191)+y(50)*params(192)+y(51)*params(193)+y(52)*params(194)+y(53)*params(195)+y(54)*params(196)+y(55)*params(197)+y(56)*params(198));
    residual(134) = (y(222)) - (params(199)+y(49)*params(200)+y(50)*params(201)+y(51)*params(202)+y(52)*params(203)+y(53)*params(204)+y(54)*params(205)+y(55)*params(206)+y(56)*params(207));
    residual(135) = (y(223)) - (params(208)+y(49)*params(209)+y(50)*params(210)+y(51)*params(211)+y(52)*params(212)+y(53)*params(213)+y(54)*params(214)+y(55)*params(215)+y(56)*params(216));

end
