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
residual = zeros(137, 1);
    residual(1) = (y(105)) - (y(98)-y(102));
    residual(2) = (y(106)) - (y(99)-y(103));
    residual(3) = (y(107)) - (y(101)-y(104));
    residual(4) = (y(97)) - (params(1)*y(100)+params(2)*y(1)-params(3)*(y(6)-y(7))+params(18)*y(167)+x(it_, 1));
    residual(5) = (y(105)) - (y(6)*params(4)+(1-params(4))*(y(7)*params(5)+y(1)*params(6))+x(it_, 2));
    residual(6) = (y(106)) - (y(7)*params(7)+y(1)*params(8)+x(it_, 3));
    residual(7) = (y(100)) - (params(9)*y(2)+x(it_, 4));
    residual(8) = (y(107)) - (params(10)*y(8)+y(2)*params(11)+x(it_, 5));
    residual(9) = (y(102)) - (params(12)*y(3)+(1-params(12))*params(15)+x(it_, 6));
    residual(10) = (y(103)) - (params(13)*y(4)+(1-params(13))*params(16)+x(it_, 7));
    residual(11) = (y(104)) - (params(14)*y(5)+(1-params(14))*params(17)+x(it_, 8));
    residual(12) = (y(194)) - (x(it_, 34)+y(57)*params(19)-y(56)+params(20)*y(195));
    residual(13) = (y(179)) - (y(57)+x(it_, 35));
    residual(14) = (y(196)) - (x(it_, 36)+y(61)*params(45)-y(60)+params(46)*y(197));
    residual(15) = (y(183)) - (y(61)+x(it_, 37));
    residual(16) = (y(198)) - (x(it_, 38)+y(64)*params(54)-y(63)+params(55)*y(199));
    residual(17) = (y(186)) - (y(64)+x(it_, 39));
    residual(18) = (y(200)) - (x(it_, 40)+y(67)*params(63)-y(66)+params(64)*y(201));
    residual(19) = (y(189)) - (y(67)+x(it_, 41));
    residual(20) = (y(202)) - (x(it_, 42)+y(70)*params(37)-y(69)+params(38)*y(203));
    residual(21) = (y(192)) - (y(70)+x(it_, 43));
    residual(22) = (y(108)) - (params(16)+y(180)-y(58));
    residual(23) = (y(181)) - (y(59)+y(109)-params(16));
    residual(24) = (y(127)) - (y(184)-y(62));
    residual(25) = (y(132)) - (y(187)-y(65));
    residual(26) = (y(137)) - (y(190)-y(68));
    residual(27) = (y(120)) - (y(193)-y(71));
    residual(28) = (y(112)) - ((1-params(62))*y(10)+y(132)*params(62));
    residual(29) = (y(113)) - (y(112)*params(26)+(1-params(26))*y(122)+y(114));
    residual(30) = (y(114)) - (params(27)*y(11)+x(it_, 30));
    residual(31) = (y(116)) - (y(114)/(1-params(26)));
    residual(32) = (y(115)) - (y(117)-y(116));
    residual(33) = (y(109)) - (params(23)*y(9)+y(115)*params(24)+params(25)*y(143)+y(103)*(1-params(23)-params(24)));
    residual(34) = (y(110)) - (y(103));
    residual(35) = (y(111)) - (y(181)-y(180));
    residual(36) = (y(173)) - (params(138)*y(51)+y(1)*params(139)+y(6)*params(140)+params(141)*y(13));
    residual(37) = (y(174)) - (params(142)*y(52)+y(1)*params(143)+y(6)*params(144)+y(7)*params(145));
    residual(38) = (y(175)) - (params(146)*y(53)+y(1)*params(147)+y(6)*params(148)+y(13)*params(149));
    residual(39) = (y(176)) - (params(150)*y(54)+y(1)*params(151)+y(6)*params(152)+y(7)*params(153));
    residual(40) = (y(177)) - (params(154)*y(55)+y(1)*params(155)+y(6)*params(156)+y(7)*params(157));
    residual(41) = (y(204)) - (x(it_, 9)+y(173)+y(97)*params(21)+params(19)*(y(57)-y(58))+params(20)*y(205)+y(223));
    residual(42) = (y(118)) - (y(13)*params(35)+y(97)*params(34));
    residual(43) = (y(119)) - (params(36)*y(14)+y(118)*(1-params(36)));
    residual(44) = (y(117)) - (params(31)*y(12)+y(99)*params(33)+y(119)*params(32)+y(103)*(1-params(31)-params(33))+y(116)*(1-params(31))+x(it_, 10));
    residual(45) = (y(121)) - (params(44)*y(16)+y(122)*(1-params(44)));
    residual(46) = (y(122)) - (y(114)/(1-params(26))-params(118)*y(168));
    residual(47) = (y(123)) - (y(121)+y(17)-y(120));
    residual(48) = (y(124)) - (y(15));
    residual(49) = (y(125)) - (y(18));
    residual(50) = (y(126)) - (y(19));
    residual(51) = (y(206)) - (x(it_, 11)+y(174)+y(97)*params(43)+params(37)*(y(70)-y(71))+params(38)*y(207)+params(39)*y(208)+params(40)*y(209)+params(41)*y(210)+y(222));
    residual(52) = (y(128)) - (params(50)*y(20)+(1-params(50))*y(129));
    residual(53) = (y(131)) - (params(52)*y(22)+y(97)*(1-params(52)));
    residual(54) = (y(129)) - (params(51)*(y(131)-y(22))+params(53)*(y(170)-y(159)-(params(15)+params(73)+params(130)-params(16))-(y(48)-y(40)-(params(15)+params(73)+params(130)-params(16)))));
    residual(55) = (y(130)) - (y(128)+y(21)-y(127));
    residual(56) = (y(211)) - (x(it_, 12)+y(175)+y(97)*params(49)+y(6)*params(48)+params(45)*(y(61)-y(62))+params(46)*y(212)+y(219));
    residual(57) = (y(133)) - (params(60)*y(24)+(1-params(60))*y(134));
    residual(58) = (y(142)) - (params(62)+y(147)-(y(160)-y(108)));
    residual(59) = (y(143)) - (y(142)-y(29));
    residual(60) = (y(134)) - (y(97)*params(136)-y(143)*params(118));
    residual(61) = (y(135)) - (y(133)+y(25)-y(132));
    residual(62) = (y(136)) - (y(23));
    residual(63) = (y(213)) - (x(it_, 13)+y(6)*params(59)+y(97)*params(58)+y(176)+params(54)*(y(64)-y(65))+params(55)*y(214)+params(56)*y(215)+y(220));
    residual(64) = (y(138)) - (params(69)*y(27)+(1-params(69))*y(139));
    residual(65) = (y(139)) - ((y(131)-y(22))*params(135)-params(70)*(y(170)-(params(15)+params(73)+params(130)))+params(134)*y(50));
    residual(66) = (y(140)) - (y(138)+y(28)-y(137));
    residual(67) = (y(141)) - (y(26));
    residual(68) = (y(216)) - (x(it_, 14)+y(6)*params(68)+y(97)*params(67)+y(177)+params(63)*(y(67)-y(68))+params(64)*y(217)+params(65)*y(218)+y(221));
    residual(69) = (y(145)) - (params(74)*y(30)+params(73)*(1-params(74))+x(it_, 16));
    residual(70) = (y(146)) - (params(72)*y(31)+y(98)*(1-params(72)));
    residual(71) = (y(144)) - (y(145)+y(146)+x(it_, 15));
    residual(72) = (y(151)) - ((1-params(80))*params(83)+params(80)*y(32)+x(it_, 17));
    residual(73) = (y(152)) - ((1-params(81))*params(84)+params(81)*y(33)+x(it_, 18));
    residual(74) = (y(153)) - ((1-params(82))*params(85)+params(82)*y(34)+x(it_, 19));
    residual(75) = (y(148)) - (y(144)+y(151));
    residual(76) = (y(149)) - (y(144)+y(152));
    residual(77) = (y(150)) - (y(144)+y(153));
    residual(78) = (y(147)) - (y(148)*params(77)+y(149)*params(78)+y(150)*params(79));
    residual(79) = (y(154)) - (params(86)*y(35)-y(105)*params(87)+params(87)*(y(106)-y(107))+x(it_, 20));
    residual(80) = (y(156)) - (y(37)-y(155));
    residual(81) = (y(155)) - (y(37)*params(88)+params(89)*y(36)+y(100)*params(90)+y(154)*params(91)+params(29)*y(164)+x(it_, 21));
    residual(82) = (y(158)) - (y(39)-y(157));
    residual(83) = (y(157)) - (y(39)*params(92)+params(93)*y(38)+params(94)*y(169)+y(154)*params(95)+x(it_, 22));
    residual(84) = (y(159)) - (y(40)*params(96)+y(108)*params(97)+params(119)*y(163)+y(164)*params(122)+y(103)*(1-params(96)-params(97)-params(119))+x(it_, 23));
    residual(85) = (y(160)) - (params(98)*y(41)+y(108)*params(99)+y(163)*params(120)+y(103)*(1-params(98)-params(99)-params(120))+x(it_, 24));
    residual(86) = (y(161)) - (params(100)*y(42)+y(108)*params(101)+y(163)*params(121)+y(103)*(1-params(100)-params(101)-params(121))+x(it_, 25));
    residual(87) = (y(162)) - (params(102)*y(43)+y(108)*params(103)+y(103)*(1-params(102)-params(103))+y(154)*params(104)+y(164)*params(30)+x(it_, 26));
    residual(88) = (y(163)) - (params(105)*y(44)+y(108)*params(106)+y(103)*(1-params(105)-params(106))+y(154)*params(107)+y(164)*params(123)+x(it_, 27));
    residual(89) = (y(164)) - (params(28)*y(45)+y(100)*0.10+x(it_, 31));
    residual(90) = (y(165)) - (params(108)*y(46)+y(97)*params(109)+x(it_, 28));
    residual(91) = (y(166)) - (params(110)*y(47)+(y(117)-y(116))*params(111)+y(103)*(1-params(110)-params(111))+x(it_, 29));
    residual(92) = (y(167)) - (y(127)*params(112)+y(132)*params(113)+y(137)*params(114)+y(165)*params(115)+y(155)*params(116)-y(157)*params(117));
    residual(93) = (y(168)) - (y(117)-y(108)-y(116));
    residual(94) = (y(169)) - (y(127)*params(124)+y(132)*params(125)+y(137)*params(126)+y(165)*params(127)+y(155)*params(128));
    residual(95) = (y(170)) - (y(48)*params(129)+(1-params(129))*(params(130)+y(144))+x(it_, 32));
    residual(96) = (y(171)) - (params(131)*y(49)+y(97)*params(132)+y(6)*params(133)+x(it_, 33));
    residual(97) = (y(172)) - (y(171)+y(50)*0.98);
    residual(98) = (y(194)) - (y(178)-y(56));
    residual(99) = (y(195)) - (y(72));
    residual(100) = (y(196)) - (y(182)-y(60));
    residual(101) = (y(197)) - (y(73));
    residual(102) = (y(198)) - (y(185)-y(63));
    residual(103) = (y(199)) - (y(74));
    residual(104) = (y(200)) - (y(188)-y(66));
    residual(105) = (y(201)) - (y(75));
    residual(106) = (y(202)) - (y(191)-y(69));
    residual(107) = (y(203)) - (y(76));
    residual(108) = (y(204)) - (y(180)-y(58));
    residual(109) = (y(205)) - (y(77));
    residual(110) = (y(206)) - (y(193)-y(71));
    residual(111) = (y(207)) - (y(78));
    residual(112) = (y(208)) - (y(79));
    residual(113) = (y(209)) - (y(80));
    residual(114) = (y(210)) - (y(81));
    residual(115) = (y(211)) - (y(184)-y(62));
    residual(116) = (y(212)) - (y(82));
    residual(117) = (y(213)) - (y(187)-y(65));
    residual(118) = (y(214)) - (y(83));
    residual(119) = (y(215)) - (y(84));
    residual(120) = (y(216)) - (y(190)-y(68));
    residual(121) = (y(217)) - (y(85));
    residual(122) = (y(218)) - (y(86));
    residual(123) = (y(219)) - (y(61)*params(158)+y(60)*params(159)+y(61)*params(160)+params(161)*y(87)+params(162)*y(88));
    residual(124) = (y(220)) - (y(64)*params(163)+y(63)*params(164)+y(64)*params(165)+params(166)*y(89)+params(167)*y(90));
    residual(125) = (y(221)) - (y(67)*params(168)+y(66)*params(169)+y(67)*params(170)+params(171)*y(91)+params(172)*y(92));
    residual(126) = (y(222)) - (y(70)*params(173)+y(69)*params(174)+y(70)*params(175)+params(176)*y(93)+params(177)*y(94));
    residual(127) = (y(223)) - (y(57)*params(178)+y(56)*params(179)+y(57)*params(180)+params(181)*y(95)+params(182)*y(96));
    residual(128) = (y(224)) - (y(60));
    residual(129) = (y(225)) - (y(61));
    residual(130) = (y(226)) - (y(63));
    residual(131) = (y(227)) - (y(64));
    residual(132) = (y(228)) - (y(66));
    residual(133) = (y(229)) - (y(67));
    residual(134) = (y(230)) - (y(69));
    residual(135) = (y(231)) - (y(70));
    residual(136) = (y(232)) - (y(56));
    residual(137) = (y(233)) - (y(57));

end
