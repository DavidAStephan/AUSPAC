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
residual = zeros(115, 1);
    residual(1) = (y(88)) - (y(81)-y(85));
    residual(2) = (y(89)) - (y(82)-y(86));
    residual(3) = (y(90)) - (y(84)-y(87));
    residual(4) = (y(80)) - (params(1)*y(83)+params(2)*y(1)-params(3)*(y(6)-y(7))+params(18)*y(150)+x(it_, 1));
    residual(5) = (y(88)) - (y(6)*params(4)+(1-params(4))*(y(7)*params(5)+y(1)*params(6))+x(it_, 2));
    residual(6) = (y(89)) - (y(7)*params(7)+y(1)*params(8)+x(it_, 3));
    residual(7) = (y(83)) - (params(9)*y(2)+x(it_, 4));
    residual(8) = (y(90)) - (params(10)*y(8)+y(2)*params(11)+x(it_, 5));
    residual(9) = (y(85)) - (params(12)*y(3)+(1-params(12))*params(15)+x(it_, 6));
    residual(10) = (y(86)) - (params(13)*y(4)+(1-params(13))*params(16)+x(it_, 7));
    residual(11) = (y(87)) - (params(14)*y(5)+(1-params(14))*params(17)+x(it_, 8));
    residual(12) = (y(156)) - (params(2)*y(51)-params(3)*(y(52)-y(53))+x(it_, 34));
    residual(13) = (y(157)) - (params(4)*y(52)+(1-params(4))*(params(5)*y(53)+params(6)*y(51))+x(it_, 35));
    residual(14) = (y(158)) - (params(7)*y(53)+params(8)*y(51)+x(it_, 36));
    residual(15) = (y(159)) - (params(138)*y(54)+y(51)*params(139)+y(52)*params(140)+y(53)*params(141)+x(it_, 37));
    residual(16) = (y(160)) - (params(142)*y(55)+y(51)*params(143)+y(52)*params(144)+y(53)*params(145)+x(it_, 38));
    residual(17) = (y(161)) - (params(146)*y(56)+y(51)*params(147)+y(52)*params(148)+y(53)*params(149)+x(it_, 39));
    residual(18) = (y(162)) - (params(150)*y(57)+y(51)*params(151)+y(52)*params(152)+y(53)*params(153)+x(it_, 40));
    residual(19) = (y(163)) - (params(154)*y(58)+y(51)*params(155)+y(52)*params(156)+y(53)*params(157)+x(it_, 41));
    residual(20) = (y(91)) - (params(16)+y(169)-y(64));
    residual(21) = (y(170)) - (y(65)+y(92)-params(16));
    residual(22) = (y(110)) - (y(171)-y(66));
    residual(23) = (y(115)) - (y(172)-y(67));
    residual(24) = (y(120)) - (y(173)-y(68));
    residual(25) = (y(103)) - (y(174)-y(69));
    residual(26) = (y(95)) - ((1-params(62))*y(10)+y(115)*params(62));
    residual(27) = (y(96)) - (y(95)*params(26)+(1-params(26))*y(105)+y(97));
    residual(28) = (y(97)) - (params(27)*y(11)+x(it_, 30));
    residual(29) = (y(99)) - (y(97)/(1-params(26)));
    residual(30) = (y(98)) - (y(100)-y(99));
    residual(31) = (y(92)) - (params(23)*y(9)+y(98)*params(24)+params(25)*y(126)+y(86)*(1-params(23)-params(24)));
    residual(32) = (y(93)) - (y(86));
    residual(33) = (y(94)) - (y(170)-y(169));
    residual(34) = (y(164)) - (params(138)*y(59)+y(1)*params(139)+y(6)*params(140)+y(7)*params(141));
    residual(35) = (y(165)) - (params(142)*y(60)+y(1)*params(143)+y(6)*params(144)+y(7)*params(145));
    residual(36) = (y(166)) - (params(146)*y(61)+y(1)*params(147)+y(6)*params(148)+y(7)*params(149));
    residual(37) = (y(167)) - (params(150)*y(62)+y(1)*params(151)+y(6)*params(152)+y(7)*params(153));
    residual(38) = (y(168)) - (params(154)*y(63)+y(1)*params(155)+y(6)*params(156)+y(7)*params(157));
    residual(39) = (y(175)) - (x(it_, 9)+y(164)+y(80)*params(21)+params(19)*(y(54)-y(64))+params(20)*y(176)+y(194));
    residual(40) = (y(101)) - (params(35)*y(13)+y(80)*params(34));
    residual(41) = (y(102)) - (params(36)*y(14)+y(101)*(1-params(36)));
    residual(42) = (y(100)) - (params(31)*y(12)+y(82)*params(33)+y(102)*params(32)+y(86)*(1-params(31)-params(33))+y(99)*(1-params(31))+x(it_, 10));
    residual(43) = (y(104)) - (params(44)*y(16)+y(105)*(1-params(44)));
    residual(44) = (y(105)) - (y(97)/(1-params(26))-params(118)*y(151));
    residual(45) = (y(106)) - (y(104)+y(17)-y(103));
    residual(46) = (y(107)) - (y(15));
    residual(47) = (y(108)) - (y(18));
    residual(48) = (y(109)) - (y(19));
    residual(49) = (y(177)) - (x(it_, 11)+y(165)+y(80)*params(43)+params(37)*(y(55)-y(69))+params(38)*y(178)+params(39)*y(179)+params(40)*y(180)+params(41)*y(181)+y(193));
    residual(50) = (y(111)) - (params(50)*y(20)+(1-params(50))*y(112));
    residual(51) = (y(114)) - (params(52)*y(22)+y(80)*(1-params(52)));
    residual(52) = (y(112)) - (params(51)*(y(114)-y(22))+params(53)*(y(153)-y(142)-(params(15)+params(73)+params(130)-params(16))-(y(48)-y(40)-(params(15)+params(73)+params(130)-params(16)))));
    residual(53) = (y(113)) - (y(111)+y(21)-y(110));
    residual(54) = (y(182)) - (x(it_, 12)+y(166)+y(80)*params(49)+y(6)*params(48)+params(45)*(y(56)-y(66))+params(46)*y(183)+y(190));
    residual(55) = (y(116)) - (params(60)*y(24)+(1-params(60))*y(117));
    residual(56) = (y(125)) - (params(62)+y(130)-(y(143)-y(91)));
    residual(57) = (y(126)) - (y(125)-y(29));
    residual(58) = (y(117)) - (y(80)*params(136)-y(126)*params(118));
    residual(59) = (y(118)) - (y(116)+y(25)-y(115));
    residual(60) = (y(119)) - (y(23));
    residual(61) = (y(184)) - (x(it_, 13)+y(6)*params(59)+y(80)*params(58)+y(167)+params(54)*(y(57)-y(67))+params(55)*y(185)+params(56)*y(186)+y(191));
    residual(62) = (y(121)) - (params(69)*y(27)+(1-params(69))*y(122));
    residual(63) = (y(122)) - ((y(114)-y(22))*params(135)-params(70)*(y(153)-(params(15)+params(73)+params(130)))+params(134)*y(50));
    residual(64) = (y(123)) - (y(121)+y(28)-y(120));
    residual(65) = (y(124)) - (y(26));
    residual(66) = (y(187)) - (x(it_, 14)+y(6)*params(68)+y(80)*params(67)+y(168)+params(63)*(y(58)-y(68))+params(64)*y(188)+params(65)*y(189)+y(192));
    residual(67) = (y(128)) - (params(74)*y(30)+params(73)*(1-params(74))+x(it_, 16));
    residual(68) = (y(129)) - (params(72)*y(31)+y(81)*(1-params(72)));
    residual(69) = (y(127)) - (y(128)+y(129)+x(it_, 15));
    residual(70) = (y(134)) - ((1-params(80))*params(83)+params(80)*y(32)+x(it_, 17));
    residual(71) = (y(135)) - ((1-params(81))*params(84)+params(81)*y(33)+x(it_, 18));
    residual(72) = (y(136)) - ((1-params(82))*params(85)+params(82)*y(34)+x(it_, 19));
    residual(73) = (y(131)) - (y(127)+y(134));
    residual(74) = (y(132)) - (y(127)+y(135));
    residual(75) = (y(133)) - (y(127)+y(136));
    residual(76) = (y(130)) - (y(131)*params(77)+y(132)*params(78)+y(133)*params(79));
    residual(77) = (y(137)) - (params(86)*y(35)-y(88)*params(87)+params(87)*(y(89)-y(90))+x(it_, 20));
    residual(78) = (y(139)) - (y(37)-y(138));
    residual(79) = (y(138)) - (y(37)*params(88)+params(89)*y(36)+y(83)*params(90)+y(137)*params(91)+params(29)*y(147)+x(it_, 21));
    residual(80) = (y(141)) - (y(39)-y(140));
    residual(81) = (y(140)) - (y(39)*params(92)+params(93)*y(38)+params(94)*y(152)+y(137)*params(95)+x(it_, 22));
    residual(82) = (y(142)) - (y(40)*params(96)+y(91)*params(97)+params(119)*y(146)+y(147)*params(122)+y(86)*(1-params(96)-params(97)-params(119))+x(it_, 23));
    residual(83) = (y(143)) - (params(98)*y(41)+y(91)*params(99)+y(146)*params(120)+y(86)*(1-params(98)-params(99)-params(120))+x(it_, 24));
    residual(84) = (y(144)) - (params(100)*y(42)+y(91)*params(101)+y(146)*params(121)+y(86)*(1-params(100)-params(101)-params(121))+x(it_, 25));
    residual(85) = (y(145)) - (params(102)*y(43)+y(91)*params(103)+y(86)*(1-params(102)-params(103))+y(137)*params(104)+y(147)*params(30)+x(it_, 26));
    residual(86) = (y(146)) - (params(105)*y(44)+y(91)*params(106)+y(86)*(1-params(105)-params(106))+y(137)*params(107)+y(147)*params(123)+x(it_, 27));
    residual(87) = (y(147)) - (params(28)*y(45)+y(83)*0.10+x(it_, 31));
    residual(88) = (y(148)) - (params(108)*y(46)+y(80)*params(109)+x(it_, 28));
    residual(89) = (y(149)) - (params(110)*y(47)+(y(100)-y(99))*params(111)+y(86)*(1-params(110)-params(111))+x(it_, 29));
    residual(90) = (y(150)) - (y(110)*params(112)+y(115)*params(113)+y(120)*params(114)+y(148)*params(115)+y(138)*params(116)-y(140)*params(117));
    residual(91) = (y(151)) - (y(100)-y(91)-y(99));
    residual(92) = (y(152)) - (y(110)*params(124)+y(115)*params(125)+y(120)*params(126)+y(148)*params(127)+y(138)*params(128));
    residual(93) = (y(153)) - (y(48)*params(129)+(1-params(129))*(params(130)+y(127))+x(it_, 32));
    residual(94) = (y(154)) - (params(131)*y(49)+y(80)*params(132)+y(6)*params(133)+x(it_, 33));
    residual(95) = (y(155)) - (y(154)+y(50)*0.98);
    residual(96) = (y(175)) - (y(169)-y(64));
    residual(97) = (y(176)) - (y(70));
    residual(98) = (y(177)) - (y(174)-y(69));
    residual(99) = (y(178)) - (y(71));
    residual(100) = (y(179)) - (y(72));
    residual(101) = (y(180)) - (y(73));
    residual(102) = (y(181)) - (y(74));
    residual(103) = (y(182)) - (y(171)-y(66));
    residual(104) = (y(183)) - (y(75));
    residual(105) = (y(184)) - (y(172)-y(67));
    residual(106) = (y(185)) - (y(76));
    residual(107) = (y(186)) - (y(77));
    residual(108) = (y(187)) - (y(173)-y(68));
    residual(109) = (y(188)) - (y(78));
    residual(110) = (y(189)) - (y(79));
    residual(111) = (y(190)) - (params(158)+y(51)*params(159)+y(52)*params(160)+y(53)*params(161)+y(54)*params(162)+y(55)*params(163)+y(56)*params(164)+y(57)*params(165)+y(58)*params(166));
    residual(112) = (y(191)) - (params(167)+y(51)*params(168)+y(52)*params(169)+y(53)*params(170)+y(54)*params(171)+y(55)*params(172)+y(56)*params(173)+y(57)*params(174)+y(58)*params(175));
    residual(113) = (y(192)) - (params(176)+y(51)*params(177)+y(52)*params(178)+y(53)*params(179)+y(54)*params(180)+y(55)*params(181)+y(56)*params(182)+y(57)*params(183)+y(58)*params(184));
    residual(114) = (y(193)) - (params(185)+y(51)*params(186)+y(52)*params(187)+y(53)*params(188)+y(54)*params(189)+y(55)*params(190)+y(56)*params(191)+y(57)*params(192)+y(58)*params(193));
    residual(115) = (y(194)) - (params(194)+y(51)*params(195)+y(52)*params(196)+y(53)*params(197)+y(54)*params(198)+y(55)*params(199)+y(56)*params(200)+y(57)*params(201)+y(58)*params(202));

end
