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
residual = zeros(132, 1);
    residual(1) = (y(100)) - (y(93)-y(97));
    residual(2) = (y(101)) - (y(94)-y(98));
    residual(3) = (y(102)) - (y(96)-y(99));
    residual(4) = (y(92)) - (params(1)*y(95)+params(2)*y(1)-params(3)*(y(6)-y(7))+params(18)*y(162)+x(it_, 1));
    residual(5) = (y(100)) - (y(6)*params(4)+(1-params(4))*(y(7)*params(5)+y(1)*params(6))+x(it_, 2));
    residual(6) = (y(101)) - (y(7)*params(7)+y(1)*params(8)+x(it_, 3));
    residual(7) = (y(95)) - (params(9)*y(2)+x(it_, 4));
    residual(8) = (y(102)) - (params(10)*y(8)+y(2)*params(11)+x(it_, 5));
    residual(9) = (y(97)) - (params(12)*y(3)+(1-params(12))*params(15)+x(it_, 6));
    residual(10) = (y(98)) - (params(13)*y(4)+(1-params(13))*params(16)+x(it_, 7));
    residual(11) = (y(99)) - (params(14)*y(5)+(1-params(14))*params(17)+x(it_, 8));
    residual(12) = (y(184)) - (x(it_, 34)+y(52)*params(19)-y(51)+params(20)*y(185));
    residual(13) = (y(169)) - (y(52)+x(it_, 35));
    residual(14) = (y(186)) - (x(it_, 36)+y(56)*params(45)-y(55)+params(46)*y(187));
    residual(15) = (y(173)) - (y(56)+x(it_, 37));
    residual(16) = (y(188)) - (x(it_, 38)+y(59)*params(54)-y(58)+params(55)*y(189));
    residual(17) = (y(176)) - (y(59)+x(it_, 39));
    residual(18) = (y(190)) - (x(it_, 40)+y(62)*params(63)-y(61)+params(64)*y(191));
    residual(19) = (y(179)) - (y(62)+x(it_, 41));
    residual(20) = (y(192)) - (x(it_, 42)+y(65)*params(37)-y(64)+params(38)*y(193));
    residual(21) = (y(182)) - (y(65)+x(it_, 43));
    residual(22) = (y(103)) - (params(16)+y(170)-y(53));
    residual(23) = (y(171)) - (y(54)+y(104)-params(16));
    residual(24) = (y(122)) - (y(174)-y(57));
    residual(25) = (y(127)) - (y(177)-y(60));
    residual(26) = (y(132)) - (y(180)-y(63));
    residual(27) = (y(115)) - (y(183)-y(66));
    residual(28) = (y(107)) - ((1-params(62))*y(10)+y(127)*params(62));
    residual(29) = (y(108)) - (y(107)*params(26)+(1-params(26))*y(117)+y(109));
    residual(30) = (y(109)) - (params(27)*y(11)+x(it_, 30));
    residual(31) = (y(111)) - (y(109)/(1-params(26)));
    residual(32) = (y(110)) - (y(112)-y(111));
    residual(33) = (y(104)) - (params(23)*y(9)+y(110)*params(24)+params(25)*y(138)+y(98)*(1-params(23)-params(24)));
    residual(34) = (y(105)) - (y(98));
    residual(35) = (y(106)) - (y(171)-y(170));
    residual(36) = (y(194)) - (x(it_, 9)+y(92)*params(21)+params(19)*(y(52)-y(53))+params(20)*y(195)+y(213));
    residual(37) = (y(113)) - (params(35)*y(13)+y(92)*params(34));
    residual(38) = (y(114)) - (params(36)*y(14)+y(113)*(1-params(36)));
    residual(39) = (y(112)) - (params(31)*y(12)+y(94)*params(33)+y(114)*params(32)+y(98)*(1-params(31)-params(33))+y(111)*(1-params(31))+x(it_, 10));
    residual(40) = (y(116)) - (params(44)*y(16)+y(117)*(1-params(44)));
    residual(41) = (y(117)) - (y(109)/(1-params(26))-params(118)*y(163));
    residual(42) = (y(118)) - (y(116)+y(17)-y(115));
    residual(43) = (y(119)) - (y(15));
    residual(44) = (y(120)) - (y(18));
    residual(45) = (y(121)) - (y(19));
    residual(46) = (y(196)) - (x(it_, 11)+y(92)*params(43)+params(37)*(y(65)-y(66))+params(38)*y(197)+params(39)*y(198)+params(40)*y(199)+params(41)*y(200)+y(212));
    residual(47) = (y(123)) - (params(50)*y(20)+(1-params(50))*y(124));
    residual(48) = (y(126)) - (params(52)*y(22)+y(92)*(1-params(52)));
    residual(49) = (y(124)) - (params(51)*(y(126)-y(22))+params(53)*(y(165)-y(154)-(params(15)+params(73)+params(130)-params(16))-(y(48)-y(40)-(params(15)+params(73)+params(130)-params(16)))));
    residual(50) = (y(125)) - (y(123)+y(21)-y(122));
    residual(51) = (y(201)) - (x(it_, 12)+y(92)*params(49)+y(6)*params(48)+params(45)*(y(56)-y(57))+params(46)*y(202)+y(209));
    residual(52) = (y(128)) - (params(60)*y(24)+(1-params(60))*y(129));
    residual(53) = (y(137)) - (params(62)+y(142)-(y(155)-y(103)));
    residual(54) = (y(138)) - (y(137)-y(29));
    residual(55) = (y(129)) - (y(92)*params(136)-y(138)*params(118));
    residual(56) = (y(130)) - (y(128)+y(25)-y(127));
    residual(57) = (y(131)) - (y(23));
    residual(58) = (y(203)) - (x(it_, 13)+y(6)*params(59)+y(92)*params(58)+params(54)*(y(59)-y(60))+params(55)*y(204)+params(56)*y(205)+y(210));
    residual(59) = (y(133)) - (params(69)*y(27)+(1-params(69))*y(134));
    residual(60) = (y(134)) - ((y(126)-y(22))*params(135)-params(70)*(y(165)-(params(15)+params(73)+params(130)))+params(134)*y(50));
    residual(61) = (y(135)) - (y(133)+y(28)-y(132));
    residual(62) = (y(136)) - (y(26));
    residual(63) = (y(206)) - (x(it_, 14)+y(6)*params(68)+y(92)*params(67)+params(63)*(y(62)-y(63))+params(64)*y(207)+params(65)*y(208)+y(211));
    residual(64) = (y(140)) - (params(74)*y(30)+params(73)*(1-params(74))+x(it_, 16));
    residual(65) = (y(141)) - (params(72)*y(31)+y(93)*(1-params(72)));
    residual(66) = (y(139)) - (y(140)+y(141)+x(it_, 15));
    residual(67) = (y(146)) - ((1-params(80))*params(83)+params(80)*y(32)+x(it_, 17));
    residual(68) = (y(147)) - ((1-params(81))*params(84)+params(81)*y(33)+x(it_, 18));
    residual(69) = (y(148)) - ((1-params(82))*params(85)+params(82)*y(34)+x(it_, 19));
    residual(70) = (y(143)) - (y(139)+y(146));
    residual(71) = (y(144)) - (y(139)+y(147));
    residual(72) = (y(145)) - (y(139)+y(148));
    residual(73) = (y(142)) - (y(143)*params(77)+y(144)*params(78)+y(145)*params(79));
    residual(74) = (y(149)) - (params(86)*y(35)-y(100)*params(87)+params(87)*(y(101)-y(102))+x(it_, 20));
    residual(75) = (y(151)) - (y(37)-y(150));
    residual(76) = (y(150)) - (y(37)*params(88)+params(89)*y(36)+y(95)*params(90)+y(149)*params(91)+params(29)*y(159)+x(it_, 21));
    residual(77) = (y(153)) - (y(39)-y(152));
    residual(78) = (y(152)) - (y(39)*params(92)+params(93)*y(38)+params(94)*y(164)+y(149)*params(95)+x(it_, 22));
    residual(79) = (y(154)) - (y(40)*params(96)+y(103)*params(97)+params(119)*y(158)+y(159)*params(122)+y(98)*(1-params(96)-params(97)-params(119))+x(it_, 23));
    residual(80) = (y(155)) - (params(98)*y(41)+y(103)*params(99)+y(158)*params(120)+y(98)*(1-params(98)-params(99)-params(120))+x(it_, 24));
    residual(81) = (y(156)) - (params(100)*y(42)+y(103)*params(101)+y(158)*params(121)+y(98)*(1-params(100)-params(101)-params(121))+x(it_, 25));
    residual(82) = (y(157)) - (params(102)*y(43)+y(103)*params(103)+y(98)*(1-params(102)-params(103))+y(149)*params(104)+y(159)*params(30)+x(it_, 26));
    residual(83) = (y(158)) - (params(105)*y(44)+y(103)*params(106)+y(98)*(1-params(105)-params(106))+y(149)*params(107)+y(159)*params(123)+x(it_, 27));
    residual(84) = (y(159)) - (params(28)*y(45)+y(95)*0.10+x(it_, 31));
    residual(85) = (y(160)) - (params(108)*y(46)+y(92)*params(109)+x(it_, 28));
    residual(86) = (y(161)) - (params(110)*y(47)+(y(112)-y(111))*params(111)+y(98)*(1-params(110)-params(111))+x(it_, 29));
    residual(87) = (y(162)) - (y(122)*params(112)+y(127)*params(113)+y(132)*params(114)+y(160)*params(115)+y(150)*params(116)-y(152)*params(117));
    residual(88) = (y(163)) - (y(112)-y(103)-y(111));
    residual(89) = (y(164)) - (y(122)*params(124)+y(127)*params(125)+y(132)*params(126)+y(160)*params(127)+y(150)*params(128));
    residual(90) = (y(165)) - (y(48)*params(129)+(1-params(129))*(params(130)+y(139))+x(it_, 32));
    residual(91) = (y(166)) - (params(131)*y(49)+y(92)*params(132)+y(6)*params(133)+x(it_, 33));
    residual(92) = (y(167)) - (y(166)+y(50)*0.98);
    residual(93) = (y(184)) - (y(168)-y(51));
    residual(94) = (y(185)) - (y(67));
    residual(95) = (y(186)) - (y(172)-y(55));
    residual(96) = (y(187)) - (y(68));
    residual(97) = (y(188)) - (y(175)-y(58));
    residual(98) = (y(189)) - (y(69));
    residual(99) = (y(190)) - (y(178)-y(61));
    residual(100) = (y(191)) - (y(70));
    residual(101) = (y(192)) - (y(181)-y(64));
    residual(102) = (y(193)) - (y(71));
    residual(103) = (y(194)) - (y(170)-y(53));
    residual(104) = (y(195)) - (y(72));
    residual(105) = (y(196)) - (y(183)-y(66));
    residual(106) = (y(197)) - (y(73));
    residual(107) = (y(198)) - (y(74));
    residual(108) = (y(199)) - (y(75));
    residual(109) = (y(200)) - (y(76));
    residual(110) = (y(201)) - (y(174)-y(57));
    residual(111) = (y(202)) - (y(77));
    residual(112) = (y(203)) - (y(177)-y(60));
    residual(113) = (y(204)) - (y(78));
    residual(114) = (y(205)) - (y(79));
    residual(115) = (y(206)) - (y(180)-y(63));
    residual(116) = (y(207)) - (y(80));
    residual(117) = (y(208)) - (y(81));
    residual(118) = (y(209)) - (y(56)*params(138)+y(55)*params(139)+y(56)*params(140)+params(141)*y(82)+params(142)*y(83));
    residual(119) = (y(210)) - (y(59)*params(143)+y(58)*params(144)+y(59)*params(145)+params(146)*y(84)+params(147)*y(85));
    residual(120) = (y(211)) - (y(62)*params(148)+y(61)*params(149)+y(62)*params(150)+params(151)*y(86)+params(152)*y(87));
    residual(121) = (y(212)) - (y(65)*params(153)+y(64)*params(154)+y(65)*params(155)+params(156)*y(88)+params(157)*y(89));
    residual(122) = (y(213)) - (y(52)*params(158)+y(51)*params(159)+y(52)*params(160)+params(161)*y(90)+params(162)*y(91));
    residual(123) = (y(214)) - (y(55));
    residual(124) = (y(215)) - (y(56));
    residual(125) = (y(216)) - (y(58));
    residual(126) = (y(217)) - (y(59));
    residual(127) = (y(218)) - (y(61));
    residual(128) = (y(219)) - (y(62));
    residual(129) = (y(220)) - (y(64));
    residual(130) = (y(221)) - (y(65));
    residual(131) = (y(222)) - (y(51));
    residual(132) = (y(223)) - (y(52));

end
