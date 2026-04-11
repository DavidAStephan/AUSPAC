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
residual = zeros(132, 1);
    residual(1) = (y(78)) - (y(71)-y(75));
    residual(2) = (y(79)) - (y(72)-y(76));
    residual(3) = (y(80)) - (y(74)-y(77));
    residual(4) = (y(70)) - (params(1)*y(73)+params(2)*y(1)-params(3)*(y(6)-y(7))+params(18)*y(140)+x(it_, 1));
    residual(5) = (y(78)) - (y(6)*params(4)+(1-params(4))*(y(7)*params(5)+y(1)*params(6))+x(it_, 2));
    residual(6) = (y(79)) - (y(7)*params(7)+y(1)*params(8)+x(it_, 3));
    residual(7) = (y(73)) - (params(9)*y(2)+x(it_, 4));
    residual(8) = (y(80)) - (params(10)*y(8)+y(2)*params(11)+x(it_, 5));
    residual(9) = (y(75)) - (params(12)*y(3)+(1-params(12))*params(15)+x(it_, 6));
    residual(10) = (y(76)) - (params(13)*y(4)+(1-params(13))*params(16)+x(it_, 7));
    residual(11) = (y(77)) - (params(14)*y(5)+(1-params(14))*params(17)+x(it_, 8));
    residual(12) = (y(146)) - (y(49)+x(it_, 34));
    residual(13) = (y(149)) - (y(52)+x(it_, 35));
    residual(14) = (y(151)) - (y(54)+x(it_, 36));
    residual(15) = (y(153)) - (y(56)+x(it_, 37));
    residual(16) = (y(155)) - (y(58)+x(it_, 38));
    residual(17) = (y(81)) - (params(16)+y(147)-y(50));
    residual(18) = (y(148)) - (y(51)+y(82)-params(16));
    residual(19) = (y(100)) - (y(150)-y(53));
    residual(20) = (y(105)) - (y(152)-y(55));
    residual(21) = (y(110)) - (y(154)-y(57));
    residual(22) = (y(93)) - (y(156)-y(59));
    residual(23) = (y(85)) - ((1-params(62))*y(10)+y(105)*params(62));
    residual(24) = (y(86)) - (y(85)*params(26)+(1-params(26))*y(95)+y(87));
    residual(25) = (y(87)) - (params(27)*y(11)+x(it_, 30));
    residual(26) = (y(89)) - (y(87)/(1-params(26)));
    residual(27) = (y(88)) - (y(90)-y(89));
    residual(28) = (y(82)) - (params(23)*y(9)+y(88)*params(24)+params(25)*y(116)+y(76)*(1-params(23)-params(24)));
    residual(29) = (y(83)) - (y(76));
    residual(30) = (y(84)) - (y(148)-y(147));
    residual(31) = (y(157)) - (x(it_, 9)+y(70)*params(21)+params(19)*(y(49)-y(50))+params(20)*y(158)+y(49)*params(155)+y(189));
    residual(32) = (y(91)) - (params(35)*y(13)+y(70)*params(34));
    residual(33) = (y(92)) - (y(91)*(1-params(36))+params(36)*y(202));
    residual(34) = (y(90)) - (params(31)*y(12)+y(72)*params(33)+y(92)*params(32)+y(76)*(1-params(31)-params(33))+y(89)*(1-params(31))+x(it_, 10));
    residual(35) = (y(94)) - (params(44)*y(15)+y(95)*(1-params(44)));
    residual(36) = (y(95)) - (y(87)/(1-params(26))-params(118)*y(141));
    residual(37) = (y(96)) - (y(94)+y(16)-y(93));
    residual(38) = (y(97)) - (y(14));
    residual(39) = (y(98)) - (y(17));
    residual(40) = (y(99)) - (y(18));
    residual(41) = (y(159)) - (x(it_, 11)+y(70)*params(43)+params(37)*(y(58)-y(59))+params(38)*y(160)+params(39)*y(161)+params(40)*y(162)+params(41)*y(163)+y(58)*params(149)+y(183));
    residual(42) = (y(101)) - (params(50)*y(19)+(1-params(50))*y(102));
    residual(43) = (y(104)) - (y(70)*(1-params(52))+params(52)*y(203));
    residual(44) = (y(102)) - (params(51)*(y(104)-y(21))+params(53)*(y(143)-y(132)-(params(15)+params(73)+params(130)-params(16))-(y(46)-y(38)-(params(15)+params(73)+params(130)-params(16)))));
    residual(45) = (y(103)) - (y(101)+y(20)-y(100));
    residual(46) = (y(164)) - (x(it_, 12)+y(70)*params(49)+y(6)*params(48)+params(45)*(y(52)-y(53))+params(46)*y(165)+y(52)*params(138)+y(172));
    residual(47) = (y(106)) - (params(60)*y(23)+(1-params(60))*y(107));
    residual(48) = (y(115)) - (params(62)+y(120)-(y(133)-y(81)));
    residual(49) = (y(116)) - (y(115)-y(28));
    residual(50) = (y(107)) - (y(70)*params(136)-y(116)*params(118));
    residual(51) = (y(108)) - (y(106)+y(24)-y(105));
    residual(52) = (y(109)) - (y(22));
    residual(53) = (y(166)) - (x(it_, 13)+y(6)*params(59)+y(70)*params(58)+params(54)*(y(54)-y(55))+params(55)*y(167)+params(56)*y(168)+y(54)*params(141)+y(175));
    residual(54) = (y(111)) - (params(69)*y(26)+(1-params(69))*y(112));
    residual(55) = (y(112)) - ((y(104)-y(21))*params(135)-params(70)*(y(143)-(params(15)+params(73)+params(130)))+params(134)*y(48));
    residual(56) = (y(113)) - (y(111)+y(27)-y(110));
    residual(57) = (y(114)) - (y(25));
    residual(58) = (y(169)) - (x(it_, 14)+y(6)*params(68)+y(70)*params(67)+params(63)*(y(56)-y(57))+params(64)*y(170)+params(65)*y(171)+y(56)*params(145)+y(179));
    residual(59) = (y(118)) - (params(74)*y(29)+params(73)*(1-params(74))+x(it_, 16));
    residual(60) = (y(119)) - (y(71)*(1-params(72))+params(72)*y(204));
    residual(61) = (y(117)) - (y(118)+y(119)+x(it_, 15));
    residual(62) = (y(124)) - ((1-params(80))*params(83)+params(80)*y(30)+x(it_, 17));
    residual(63) = (y(125)) - ((1-params(81))*params(84)+params(81)*y(31)+x(it_, 18));
    residual(64) = (y(126)) - ((1-params(82))*params(85)+params(82)*y(32)+x(it_, 19));
    residual(65) = (y(121)) - (y(117)+y(124));
    residual(66) = (y(122)) - (y(117)+y(125));
    residual(67) = (y(123)) - (y(117)+y(126));
    residual(68) = (y(120)) - (y(121)*params(77)+y(122)*params(78)+y(123)*params(79));
    residual(69) = (y(127)) - (params(86)*y(33)-y(78)*params(87)+params(87)*(y(79)-y(80))+x(it_, 20));
    residual(70) = (y(129)) - (y(35)-y(128));
    residual(71) = (y(128)) - (y(35)*params(88)+params(89)*y(34)+y(73)*params(90)+y(127)*params(91)+params(29)*y(137)+x(it_, 21));
    residual(72) = (y(131)) - (y(37)-y(130));
    residual(73) = (y(130)) - (y(37)*params(92)+params(93)*y(36)+params(94)*y(142)+y(127)*params(95)+x(it_, 22));
    residual(74) = (y(132)) - (y(38)*params(96)+y(81)*params(97)+params(119)*y(136)+y(137)*params(122)+y(76)*(1-params(96)-params(97)-params(119))+x(it_, 23));
    residual(75) = (y(133)) - (params(98)*y(39)+y(81)*params(99)+y(136)*params(120)+y(76)*(1-params(98)-params(99)-params(120))+x(it_, 24));
    residual(76) = (y(134)) - (params(100)*y(40)+y(81)*params(101)+y(136)*params(121)+y(76)*(1-params(100)-params(101)-params(121))+x(it_, 25));
    residual(77) = (y(135)) - (params(102)*y(41)+y(81)*params(103)+y(76)*(1-params(102)-params(103))+y(127)*params(104)+y(137)*params(30)+x(it_, 26));
    residual(78) = (y(136)) - (params(105)*y(42)+y(81)*params(106)+y(76)*(1-params(105)-params(106))+y(127)*params(107)+y(137)*params(123)+x(it_, 27));
    residual(79) = (y(137)) - (params(28)*y(43)+y(73)*0.10+x(it_, 31));
    residual(80) = (y(138)) - (params(108)*y(44)+y(70)*params(109)+x(it_, 28));
    residual(81) = (y(139)) - (params(110)*y(45)+(y(90)-y(89))*params(111)+y(76)*(1-params(110)-params(111))+x(it_, 29));
    residual(82) = (y(140)) - (y(100)*params(112)+y(105)*params(113)+y(110)*params(114)+y(138)*params(115)+y(128)*params(116)-y(130)*params(117));
    residual(83) = (y(141)) - (y(90)-y(81)-y(89));
    residual(84) = (y(142)) - (y(100)*params(124)+y(105)*params(125)+y(110)*params(126)+y(138)*params(127)+y(128)*params(128));
    residual(85) = (y(143)) - (y(46)*params(129)+(1-params(129))*(params(130)+y(117))+x(it_, 32));
    residual(86) = (y(144)) - (params(131)*y(47)+y(70)*params(132)+y(6)*params(133)+x(it_, 33));
    residual(87) = (y(145)) - (y(144)+y(48)*0.98);
    residual(88) = (y(157)) - (y(147)-y(50));
    residual(89) = (y(158)) - (y(60));
    residual(90) = (y(159)) - (y(156)-y(59));
    residual(91) = (y(160)) - (y(61));
    residual(92) = (y(161)) - (y(62));
    residual(93) = (y(162)) - (y(63));
    residual(94) = (y(163)) - (y(64));
    residual(95) = (y(164)) - (y(150)-y(53));
    residual(96) = (y(165)) - (y(65));
    residual(97) = (y(166)) - (y(152)-y(55));
    residual(98) = (y(167)) - (y(66));
    residual(99) = (y(168)) - (y(67));
    residual(100) = (y(169)) - (y(154)-y(57));
    residual(101) = (y(170)) - (y(68));
    residual(102) = (y(171)) - (y(69));
    residual(103) = (y(173)) - (y(149)-y(52));
    residual(104) = (y(174)) - (y(206));
    residual(105) = (y(172)) - ((1+params(139)+params(140))*(y(173)-T(2)*y(174))-(y(205)*params(137)*params(139)+T(2)*y(220)));
    residual(106) = (y(176)) - (y(151)-y(54));
    residual(107) = (y(177)) - (y(208));
    residual(108) = (y(178)) - (y(209));
    residual(109) = (y(175)) - ((1+params(142)+params(143)+params(144))*(y(176)-(y(177)*(T(1)*params(143)+T(4))+T(4)*y(178)))-(y(207)*params(137)*params(142)+T(1)*params(143)*y(221)+T(4)*y(222)));
    residual(110) = (y(180)) - (y(153)-y(56));
    residual(111) = (y(181)) - (y(211));
    residual(112) = (y(182)) - (y(212));
    residual(113) = (y(179)) - ((1+params(146)+params(147)+params(148))*(y(180)-(y(181)*(T(1)*params(147)+T(3)*params(148))+T(3)*params(148)*y(182)))-(y(210)*params(137)*params(146)+T(1)*params(147)*y(223)+T(3)*params(148)*y(224)));
    residual(114) = (y(184)) - (y(155)-y(58));
    residual(115) = (y(185)) - (y(214));
    residual(116) = (y(186)) - (y(215));
    residual(117) = (y(187)) - (y(216));
    residual(118) = (y(188)) - (y(217));
    residual(119) = (y(183)) - ((1+params(150)+params(151)+params(152)+params(153)+params(154))*(y(184)-(y(185)*(T(6)+T(5)+T(1)*params(151)+T(3)*params(152))+y(186)*(T(6)+T(3)*params(152)+T(5))+y(187)*(T(5)+T(6))+T(6)*y(188)))-(y(213)*params(137)*params(150)+T(1)*params(151)*y(225)+T(3)*params(152)*y(226)+T(5)*y(227)+T(6)*y(228)));
    residual(120) = (y(190)) - (y(146)-y(49));
    residual(121) = (y(191)) - (y(219));
    residual(122) = (y(189)) - ((1+params(156)+params(157))*(y(190)-T(1)*params(157)*y(191))-(y(218)*params(137)*params(156)+T(1)*params(157)*y(229)));
    residual(123) = (y(192)) - (y(205));
    residual(124) = (y(193)) - (y(207));
    residual(125) = (y(194)) - (y(221));
    residual(126) = (y(195)) - (y(210));
    residual(127) = (y(196)) - (y(223));
    residual(128) = (y(197)) - (y(213));
    residual(129) = (y(198)) - (y(225));
    residual(130) = (y(199)) - (y(226));
    residual(131) = (y(200)) - (y(227));
    residual(132) = (y(201)) - (y(218));

end
