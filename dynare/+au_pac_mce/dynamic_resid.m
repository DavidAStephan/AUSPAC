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
residual = zeros(131, 1);
    residual(1) = (y(79)) - (y(72)-y(76));
    residual(2) = (y(80)) - (y(73)-y(77));
    residual(3) = (y(81)) - (y(75)-y(78));
    residual(4) = (y(71)) - (params(1)*y(74)+params(2)*y(1)-params(3)*(y(6)-y(7))+params(18)*y(140)+x(it_, 1));
    residual(5) = (y(79)) - (y(6)*params(4)+(1-params(4))*(y(7)*params(5)+y(1)*params(6))+x(it_, 2));
    residual(6) = (y(80)) - (y(7)*params(7)+y(1)*params(8)+x(it_, 3));
    residual(7) = (y(74)) - (params(9)*y(2)+x(it_, 4));
    residual(8) = (y(81)) - (params(10)*y(8)+y(2)*params(11)+x(it_, 5));
    residual(9) = (y(76)) - (params(12)*y(3)+(1-params(12))*params(15)+x(it_, 6));
    residual(10) = (y(77)) - (params(13)*y(4)+(1-params(13))*params(16)+x(it_, 7));
    residual(11) = (y(78)) - (params(14)*y(5)+(1-params(14))*params(17)+x(it_, 8));
    residual(12) = (y(146)) - (y(50)+x(it_, 34));
    residual(13) = (y(149)) - (y(53)+x(it_, 35));
    residual(14) = (y(151)) - (y(55)+x(it_, 36));
    residual(15) = (y(153)) - (y(57)+x(it_, 37));
    residual(16) = (y(155)) - (y(59)+x(it_, 38));
    residual(17) = (y(82)) - (params(16)+y(147)-y(51));
    residual(18) = (y(148)) - (y(52)+y(83)-params(16));
    residual(19) = (y(101)) - (y(150)-y(54));
    residual(20) = (y(106)) - (y(152)-y(56));
    residual(21) = (y(111)) - (y(154)-y(58));
    residual(22) = (y(94)) - (y(156)-y(60));
    residual(23) = (y(86)) - ((1-params(61))*y(10)+y(106)*params(61));
    residual(24) = (y(87)) - (y(86)*params(26)+(1-params(26))*y(96)+y(88));
    residual(25) = (y(88)) - (params(27)*y(11)+x(it_, 30));
    residual(26) = (y(90)) - (y(88)/(1-params(26)));
    residual(27) = (y(89)) - (y(91)-y(90));
    residual(28) = (y(83)) - (params(23)*y(9)+y(89)*params(24)+params(25)*y(117)+y(77)*(1-params(23)-params(24)));
    residual(29) = (y(84)) - (y(77));
    residual(30) = (y(85)) - (y(148)-y(147));
    residual(31) = (y(157)) - (x(it_, 9)+y(71)*params(21)+params(19)*(y(50)-y(51))+params(20)*y(158)+y(50)*params(152)+y(189));
    residual(32) = (y(92)) - (params(35)*y(13)+y(71)*params(34));
    residual(33) = (y(93)) - (y(92)*(1-params(36))+params(36)*y(202));
    residual(34) = (y(91)) - (params(31)*y(12)+y(73)*params(33)+y(93)*params(32)+y(77)*(1-params(31)-params(33))+y(90)*(1-params(31))+x(it_, 10));
    residual(35) = (y(95)) - (params(44)*y(15)+y(96)*(1-params(44)));
    residual(36) = (y(96)) - (y(88)/(1-params(26))-params(116)*y(141));
    residual(37) = (y(97)) - (y(95)+y(16)-y(94));
    residual(38) = (y(98)) - (y(14));
    residual(39) = (y(99)) - (y(17));
    residual(40) = (y(100)) - (y(18));
    residual(41) = (y(159)) - (x(it_, 11)+y(71)*params(43)+params(37)*(y(59)-y(60))+params(38)*y(160)+params(39)*y(161)+params(40)*y(162)+params(41)*y(163)+y(59)*params(146)+y(183));
    residual(42) = (y(102)) - (params(50)*y(19)+(1-params(50))*y(103));
    residual(43) = (y(105)) - (y(71)*(1-params(52))+params(52)*y(203));
    residual(44) = (y(103)) - (params(51)*(y(105)-y(21)));
    residual(45) = (y(104)) - (y(102)+y(20)-y(101));
    residual(46) = (y(164)) - (x(it_, 12)+y(71)*params(49)+y(6)*params(48)+params(45)*(y(53)-y(54))+params(46)*y(165)+y(53)*params(135)+y(172));
    residual(47) = (y(107)) - (params(59)*y(23)+(1-params(59))*y(108));
    residual(48) = (y(116)) - (params(61)+y(120)-(y(133)-y(82)));
    residual(49) = (y(117)) - (y(116)-y(28));
    residual(50) = (y(108)) - (y(71)*params(133)-y(117)*params(116));
    residual(51) = (y(109)) - (y(107)+y(24)-y(106));
    residual(52) = (y(110)) - (y(22));
    residual(53) = (y(166)) - (x(it_, 13)+y(6)*params(58)+y(71)*params(57)+params(53)*(y(55)-y(56))+params(54)*y(167)+params(55)*y(168)+y(55)*params(138)+y(175));
    residual(54) = (y(112)) - (params(68)*y(26)+(1-params(68))*y(113));
    residual(55) = (y(113)) - ((-params(69))*(y(143)-(params(15)+params(71)+params(128)))+params(132)*y(49));
    residual(56) = (y(114)) - (y(112)+y(27)-y(111));
    residual(57) = (y(115)) - (y(25));
    residual(58) = (y(169)) - (x(it_, 14)+y(6)*params(67)+y(71)*params(66)+params(62)*(y(57)-y(58))+params(63)*y(170)+params(64)*y(171)+y(57)*params(142)+y(179));
    residual(59) = (y(119)) - (params(72)*y(30)+params(71)*(1-params(72))+x(it_, 16));
    residual(60) = (y(118)) - (params(70)*y(29)+(1-params(70))*(y(72)+y(119))+x(it_, 15));
    residual(61) = (y(124)) - ((1-params(78))*params(81)+params(78)*y(31)+x(it_, 17));
    residual(62) = (y(125)) - ((1-params(79))*params(82)+params(79)*y(32)+x(it_, 18));
    residual(63) = (y(126)) - ((1-params(80))*params(83)+params(80)*y(33)+x(it_, 19));
    residual(64) = (y(121)) - (y(118)+y(124));
    residual(65) = (y(122)) - (y(118)+y(125));
    residual(66) = (y(123)) - (y(118)+y(126));
    residual(67) = (y(120)) - (y(121)*params(75)+y(122)*params(76)+y(123)*params(77));
    residual(68) = (y(127)) - (params(84)*y(34)-y(79)*params(85)+params(85)*(y(80)-y(81))+x(it_, 20));
    residual(69) = (y(129)) - (y(36)-y(128));
    residual(70) = (y(128)) - (y(36)*params(86)+params(87)*y(35)+y(74)*params(88)+y(127)*params(89)+params(29)*y(137)+x(it_, 21));
    residual(71) = (y(131)) - (y(38)-y(130));
    residual(72) = (y(130)) - (y(38)*params(90)+params(91)*y(37)+params(92)*y(142)+y(127)*params(93)+x(it_, 22));
    residual(73) = (y(132)) - (params(94)*y(39)+y(82)*params(95)+params(117)*y(136)+y(137)*params(120)+y(77)*(1-params(94)-params(95)-params(117))+x(it_, 23));
    residual(74) = (y(133)) - (params(96)*y(40)+y(82)*params(97)+y(136)*params(118)+y(77)*(1-params(96)-params(97)-params(118))+x(it_, 24));
    residual(75) = (y(134)) - (params(98)*y(41)+y(82)*params(99)+y(136)*params(119)+y(77)*(1-params(98)-params(99)-params(119))+x(it_, 25));
    residual(76) = (y(135)) - (params(100)*y(42)+y(82)*params(101)+y(77)*(1-params(100)-params(101))+y(127)*params(102)+y(137)*params(30)+x(it_, 26));
    residual(77) = (y(136)) - (params(103)*y(43)+y(82)*params(104)+y(77)*(1-params(103)-params(104))+y(127)*params(105)+y(137)*params(121)+x(it_, 27));
    residual(78) = (y(137)) - (params(28)*y(44)+y(74)*0.10+x(it_, 31));
    residual(79) = (y(138)) - (params(106)*y(45)+y(71)*params(107)+x(it_, 28));
    residual(80) = (y(139)) - (params(108)*y(46)+(y(91)-y(90))*params(109)+y(77)*(1-params(108)-params(109))+x(it_, 29));
    residual(81) = (y(140)) - (y(101)*params(110)+y(106)*params(111)+y(111)*params(112)+y(138)*params(113)+y(128)*params(114)-y(130)*params(115));
    residual(82) = (y(141)) - (y(91)-y(82)-y(90));
    residual(83) = (y(142)) - (y(101)*params(122)+y(106)*params(123)+y(111)*params(124)+y(138)*params(125)+y(128)*params(126));
    residual(84) = (y(143)) - (params(127)*y(47)+(1-params(127))*(params(128)+y(118))+x(it_, 32));
    residual(85) = (y(144)) - (params(129)*y(48)+y(71)*params(130)+y(6)*params(131)+x(it_, 33));
    residual(86) = (y(145)) - (y(144)+y(49)*0.98);
    residual(87) = (y(157)) - (y(147)-y(51));
    residual(88) = (y(158)) - (y(61));
    residual(89) = (y(159)) - (y(156)-y(60));
    residual(90) = (y(160)) - (y(62));
    residual(91) = (y(161)) - (y(63));
    residual(92) = (y(162)) - (y(64));
    residual(93) = (y(163)) - (y(65));
    residual(94) = (y(164)) - (y(150)-y(54));
    residual(95) = (y(165)) - (y(66));
    residual(96) = (y(166)) - (y(152)-y(56));
    residual(97) = (y(167)) - (y(67));
    residual(98) = (y(168)) - (y(68));
    residual(99) = (y(169)) - (y(154)-y(58));
    residual(100) = (y(170)) - (y(69));
    residual(101) = (y(171)) - (y(70));
    residual(102) = (y(173)) - (y(149)-y(53));
    residual(103) = (y(174)) - (y(205));
    residual(104) = (y(172)) - ((1+params(136)+params(137))*(y(173)-T(2)*y(174))-(y(204)*params(134)*params(136)+T(2)*y(219)));
    residual(105) = (y(176)) - (y(151)-y(55));
    residual(106) = (y(177)) - (y(207));
    residual(107) = (y(178)) - (y(208));
    residual(108) = (y(175)) - ((1+params(139)+params(140)+params(141))*(y(176)-(y(177)*(T(1)*params(140)+T(4))+T(4)*y(178)))-(y(206)*params(134)*params(139)+T(1)*params(140)*y(220)+T(4)*y(221)));
    residual(109) = (y(180)) - (y(153)-y(57));
    residual(110) = (y(181)) - (y(210));
    residual(111) = (y(182)) - (y(211));
    residual(112) = (y(179)) - ((1+params(143)+params(144)+params(145))*(y(180)-(y(181)*(T(1)*params(144)+T(3)*params(145))+T(3)*params(145)*y(182)))-(y(209)*params(134)*params(143)+T(1)*params(144)*y(222)+T(3)*params(145)*y(223)));
    residual(113) = (y(184)) - (y(155)-y(59));
    residual(114) = (y(185)) - (y(213));
    residual(115) = (y(186)) - (y(214));
    residual(116) = (y(187)) - (y(215));
    residual(117) = (y(188)) - (y(216));
    residual(118) = (y(183)) - ((1+params(147)+params(148)+params(149)+params(150)+params(151))*(y(184)-(y(185)*(T(6)+T(5)+T(1)*params(148)+T(3)*params(149))+y(186)*(T(6)+T(3)*params(149)+T(5))+y(187)*(T(5)+T(6))+T(6)*y(188)))-(y(212)*params(134)*params(147)+T(1)*params(148)*y(224)+T(3)*params(149)*y(225)+T(5)*y(226)+T(6)*y(227)));
    residual(119) = (y(190)) - (y(146)-y(50));
    residual(120) = (y(191)) - (y(218));
    residual(121) = (y(189)) - ((1+params(153)+params(154))*(y(190)-T(1)*params(154)*y(191))-(y(217)*params(134)*params(153)+T(1)*params(154)*y(228)));
    residual(122) = (y(192)) - (y(204));
    residual(123) = (y(193)) - (y(206));
    residual(124) = (y(194)) - (y(220));
    residual(125) = (y(195)) - (y(209));
    residual(126) = (y(196)) - (y(222));
    residual(127) = (y(197)) - (y(212));
    residual(128) = (y(198)) - (y(224));
    residual(129) = (y(199)) - (y(225));
    residual(130) = (y(200)) - (y(226));
    residual(131) = (y(201)) - (y(217));

end
