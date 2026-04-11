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
residual = zeros(121, 1);
    residual(1) = (y(94)) - (y(87)-y(91));
    residual(2) = (y(95)) - (y(88)-y(92));
    residual(3) = (y(96)) - (y(90)-y(93));
    residual(4) = (y(86)) - (params(1)*y(89)+params(2)*y(1)-params(3)*(y(6)-y(7))+params(18)*y(144)+x(it_, 1));
    residual(5) = (y(94)) - (y(6)*params(4)+(1-params(4))*(y(7)*params(5)+y(1)*params(6))+x(it_, 2));
    residual(6) = (y(95)) - (y(7)*params(7)+y(1)*params(8)+x(it_, 3));
    residual(7) = (y(89)) - (params(9)*y(2)+x(it_, 4));
    residual(8) = (y(96)) - (params(10)*y(8)+y(2)*params(11)+x(it_, 5));
    residual(9) = (y(91)) - (params(12)*y(3)+(1-params(12))*params(15)+x(it_, 6));
    residual(10) = (y(92)) - (params(13)*y(4)+(1-params(13))*params(16)+x(it_, 7));
    residual(11) = (y(93)) - (params(14)*y(5)+(1-params(14))*params(17)+x(it_, 8));
    residual(12) = (y(166)) - (x(it_, 32)+y(45)*params(19)-y(44)+params(20)*y(167));
    residual(13) = (y(151)) - (y(45)+x(it_, 33));
    residual(14) = (y(168)) - (x(it_, 34)+y(49)*params(41)-y(48)+params(42)*y(169));
    residual(15) = (y(155)) - (y(49)+x(it_, 35));
    residual(16) = (y(170)) - (x(it_, 36)+y(52)*params(48)-y(51)+params(49)*y(171));
    residual(17) = (y(158)) - (y(52)+x(it_, 37));
    residual(18) = (y(172)) - (x(it_, 38)+y(55)*params(58)-y(54)+params(59)*y(173));
    residual(19) = (y(161)) - (y(55)+x(it_, 39));
    residual(20) = (y(174)) - (x(it_, 40)+y(58)*params(33)-y(57)+params(34)*y(175));
    residual(21) = (y(164)) - (y(58)+x(it_, 41));
    residual(22) = (y(97)) - (params(16)+y(152)-y(46));
    residual(23) = (y(153)) - (y(47)+y(98)-params(16));
    residual(24) = (y(113)) - (y(156)-y(50));
    residual(25) = (y(117)) - (y(159)-y(53));
    residual(26) = (y(122)) - (y(162)-y(56));
    residual(27) = (y(106)) - (y(165)-y(59));
    residual(28) = (y(101)) - (y(117)*params(25)*params(57)+(1-params(25))*y(108)+y(102));
    residual(29) = (y(102)) - (params(26)*y(10)+x(it_, 28));
    residual(30) = (y(104)) - (y(102)/(1-params(25)));
    residual(31) = (y(103)) - (y(105)-y(104));
    residual(32) = (y(98)) - (params(23)*y(9)+y(103)*params(24)+y(92)*(1-params(23)-params(24)));
    residual(33) = (y(99)) - (y(92));
    residual(34) = (y(100)) - (y(153)-y(152));
    residual(35) = (y(176)) - (x(it_, 9)+y(86)*params(21)+params(19)*(y(45)-y(46))+params(20)*y(177)+y(195));
    residual(36) = (y(105)) - (params(30)*y(11)+y(88)*params(32)+y(86)*params(31)+y(92)*(1-params(30)-params(32))+y(104)*(1-params(30))+x(it_, 10));
    residual(37) = (y(107)) - (params(40)*y(13)+y(108)*(1-params(40)));
    residual(38) = (y(108)) - (y(102)/(1-params(25))-params(103)*y(145));
    residual(39) = (y(109)) - (y(107)+y(14)-y(106));
    residual(40) = (y(110)) - (y(12));
    residual(41) = (y(111)) - (y(15));
    residual(42) = (y(112)) - (y(16));
    residual(43) = (y(178)) - (x(it_, 11)+y(86)*params(39)+params(33)*(y(58)-y(59))+params(34)*y(179)+params(35)*y(180)+params(36)*y(181)+params(37)*y(182)+y(194));
    residual(44) = (y(114)) - (params(46)*y(17)+(1-params(46))*y(115));
    residual(45) = (y(115)) - (params(47)*(y(86)*0.5+y(1)*0.3+0.2*y(75)));
    residual(46) = (y(116)) - (y(114)+y(18)-y(113));
    residual(47) = (y(183)) - (x(it_, 12)+y(86)*params(45)+y(6)*params(44)+params(41)*(y(49)-y(50))+params(42)*y(184)+y(191));
    residual(48) = (y(118)) - (params(54)*y(20)+(1-params(54))*y(119));
    residual(49) = (y(127)) - (params(57)+y(130)-(y(137)-y(97)));
    residual(50) = (y(119)) - ((-params(56))*(y(127)-(params(57)+params(15)+params(67)+params(70)))+y(86)*params(120));
    residual(51) = (y(120)) - (y(118)+y(21)-y(117));
    residual(52) = (y(121)) - (y(19));
    residual(53) = (y(185)) - (x(it_, 13)+y(6)*params(53)+y(86)*params(52)+params(48)*(y(52)-y(53))+params(49)*y(186)+params(50)*y(187)+y(192));
    residual(54) = (y(123)) - (params(64)*y(23)+(1-params(64))*y(124));
    residual(55) = (y(124)) - ((-params(65))*(y(147)-(params(15)+params(67)+params(115)))+params(119)*y(43));
    residual(56) = (y(125)) - (y(123)+y(24)-y(122));
    residual(57) = (y(126)) - (y(22));
    residual(58) = (y(188)) - (x(it_, 14)+y(6)*params(63)+y(86)*params(62)+params(58)*(y(55)-y(56))+params(59)*y(189)+params(60)*y(190)+y(193));
    residual(59) = (y(129)) - (params(68)*y(26)+params(67)*(1-params(68))+x(it_, 16));
    residual(60) = (y(128)) - (params(66)*y(25)+(1-params(66))*(y(87)+y(129))+x(it_, 15));
    residual(61) = (y(130)) - (params(69)*y(27)+(1-params(69))*(params(70)+y(128))+x(it_, 17));
    residual(62) = (y(131)) - (params(71)*y(28)-y(94)*params(72)+params(72)*(y(95)-y(96))+x(it_, 18));
    residual(63) = (y(133)) - (y(30)-y(132));
    residual(64) = (y(132)) - (y(30)*params(73)+params(74)*y(29)+y(89)*params(75)+y(131)*params(76)+params(28)*y(141)+x(it_, 19));
    residual(65) = (y(135)) - (y(32)-y(134));
    residual(66) = (y(134)) - (y(32)*params(77)+params(78)*y(31)+params(79)*y(146)+y(131)*params(80)+x(it_, 20));
    residual(67) = (y(136)) - (params(81)*y(33)+y(97)*params(82)+params(104)*y(140)+y(141)*params(107)+y(92)*(1-params(81)-params(82)-params(104))+x(it_, 21));
    residual(68) = (y(137)) - (params(83)*y(34)+y(97)*params(84)+y(140)*params(105)+y(92)*(1-params(83)-params(84)-params(105))+x(it_, 22));
    residual(69) = (y(138)) - (params(85)*y(35)+y(97)*params(86)+y(140)*params(106)+y(92)*(1-params(85)-params(86)-params(106))+x(it_, 23));
    residual(70) = (y(139)) - (params(87)*y(36)+y(97)*params(88)+y(92)*(1-params(87)-params(88))+y(131)*params(89)+y(141)*params(29)+x(it_, 24));
    residual(71) = (y(140)) - (params(90)*y(37)+y(97)*params(91)+y(92)*(1-params(90)-params(91))+y(131)*params(92)+y(141)*params(108)+x(it_, 25));
    residual(72) = (y(141)) - (params(27)*y(38)+y(89)*0.10+x(it_, 29));
    residual(73) = (y(142)) - (params(93)*y(39)+y(86)*params(94)+x(it_, 26));
    residual(74) = (y(143)) - (params(95)*y(40)+(y(105)-y(104))*params(96)+y(92)*(1-params(95)-params(96))+x(it_, 27));
    residual(75) = (y(144)) - (y(113)*params(97)+y(117)*params(98)+y(122)*params(99)+y(142)*params(100)+y(132)*params(101)-y(134)*params(102));
    residual(76) = (y(145)) - (y(105)-y(97)-y(104));
    residual(77) = (y(146)) - (y(113)*params(109)+y(117)*params(110)+y(122)*params(111)+y(142)*params(112)+y(132)*params(113));
    residual(78) = (y(147)) - (params(114)*y(41)+(1-params(114))*(params(115)+y(128))+x(it_, 30));
    residual(79) = (y(148)) - (params(116)*y(42)+y(86)*params(117)+y(6)*params(118)+x(it_, 31));
    residual(80) = (y(149)) - (y(148)+y(43)*0.98);
    residual(81) = (y(166)) - (y(150)-y(44));
    residual(82) = (y(167)) - (y(60));
    residual(83) = (y(168)) - (y(154)-y(48));
    residual(84) = (y(169)) - (y(61));
    residual(85) = (y(170)) - (y(157)-y(51));
    residual(86) = (y(171)) - (y(62));
    residual(87) = (y(172)) - (y(160)-y(54));
    residual(88) = (y(173)) - (y(63));
    residual(89) = (y(174)) - (y(163)-y(57));
    residual(90) = (y(175)) - (y(64));
    residual(91) = (y(176)) - (y(152)-y(46));
    residual(92) = (y(177)) - (y(65));
    residual(93) = (y(178)) - (y(165)-y(59));
    residual(94) = (y(179)) - (y(66));
    residual(95) = (y(180)) - (y(67));
    residual(96) = (y(181)) - (y(68));
    residual(97) = (y(182)) - (y(69));
    residual(98) = (y(183)) - (y(156)-y(50));
    residual(99) = (y(184)) - (y(70));
    residual(100) = (y(185)) - (y(159)-y(53));
    residual(101) = (y(186)) - (y(71));
    residual(102) = (y(187)) - (y(72));
    residual(103) = (y(188)) - (y(162)-y(56));
    residual(104) = (y(189)) - (y(73));
    residual(105) = (y(190)) - (y(74));
    residual(106) = (y(191)) - (y(49)*params(122)+y(48)*params(123)+y(49)*params(124)+params(125)*y(76)+params(126)*y(77));
    residual(107) = (y(192)) - (y(52)*params(127)+y(51)*params(128)+y(52)*params(129)+params(130)*y(78)+params(131)*y(79));
    residual(108) = (y(193)) - (y(55)*params(132)+y(54)*params(133)+y(55)*params(134)+params(135)*y(80)+params(136)*y(81));
    residual(109) = (y(194)) - (y(58)*params(137)+y(57)*params(138)+y(58)*params(139)+params(140)*y(82)+params(141)*y(83));
    residual(110) = (y(195)) - (y(45)*params(142)+y(44)*params(143)+y(45)*params(144)+params(145)*y(84)+params(146)*y(85));
    residual(111) = (y(196)) - (y(1));
    residual(112) = (y(197)) - (y(48));
    residual(113) = (y(198)) - (y(49));
    residual(114) = (y(199)) - (y(51));
    residual(115) = (y(200)) - (y(52));
    residual(116) = (y(201)) - (y(54));
    residual(117) = (y(202)) - (y(55));
    residual(118) = (y(203)) - (y(57));
    residual(119) = (y(204)) - (y(58));
    residual(120) = (y(205)) - (y(44));
    residual(121) = (y(206)) - (y(45));

end
