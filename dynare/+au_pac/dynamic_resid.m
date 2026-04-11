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
residual = zeros(131, 1);
    residual(1) = (y(99)) - (y(92)-y(96));
    residual(2) = (y(100)) - (y(93)-y(97));
    residual(3) = (y(101)) - (y(95)-y(98));
    residual(4) = (y(91)) - (params(1)*y(94)+params(2)*y(1)-params(3)*(y(6)-y(7))+params(18)*y(160)+x(it_, 1));
    residual(5) = (y(99)) - (y(6)*params(4)+(1-params(4))*(y(7)*params(5)+y(1)*params(6))+x(it_, 2));
    residual(6) = (y(100)) - (y(7)*params(7)+y(1)*params(8)+x(it_, 3));
    residual(7) = (y(94)) - (params(9)*y(2)+x(it_, 4));
    residual(8) = (y(101)) - (params(10)*y(8)+y(2)*params(11)+x(it_, 5));
    residual(9) = (y(96)) - (params(12)*y(3)+(1-params(12))*params(15)+x(it_, 6));
    residual(10) = (y(97)) - (params(13)*y(4)+(1-params(13))*params(16)+x(it_, 7));
    residual(11) = (y(98)) - (params(14)*y(5)+(1-params(14))*params(17)+x(it_, 8));
    residual(12) = (y(182)) - (x(it_, 34)+y(51)*params(19)-y(50)+params(20)*y(183));
    residual(13) = (y(167)) - (y(51)+x(it_, 35));
    residual(14) = (y(184)) - (x(it_, 36)+y(55)*params(45)-y(54)+params(46)*y(185));
    residual(15) = (y(171)) - (y(55)+x(it_, 37));
    residual(16) = (y(186)) - (x(it_, 38)+y(58)*params(53)-y(57)+params(54)*y(187));
    residual(17) = (y(174)) - (y(58)+x(it_, 39));
    residual(18) = (y(188)) - (x(it_, 40)+y(61)*params(62)-y(60)+params(63)*y(189));
    residual(19) = (y(177)) - (y(61)+x(it_, 41));
    residual(20) = (y(190)) - (x(it_, 42)+y(64)*params(37)-y(63)+params(38)*y(191));
    residual(21) = (y(180)) - (y(64)+x(it_, 43));
    residual(22) = (y(102)) - (params(16)+y(168)-y(52));
    residual(23) = (y(169)) - (y(53)+y(103)-params(16));
    residual(24) = (y(121)) - (y(172)-y(56));
    residual(25) = (y(126)) - (y(175)-y(59));
    residual(26) = (y(131)) - (y(178)-y(62));
    residual(27) = (y(114)) - (y(181)-y(65));
    residual(28) = (y(106)) - ((1-params(61))*y(10)+y(126)*params(61));
    residual(29) = (y(107)) - (y(106)*params(26)+(1-params(26))*y(116)+y(108));
    residual(30) = (y(108)) - (params(27)*y(11)+x(it_, 30));
    residual(31) = (y(110)) - (y(108)/(1-params(26)));
    residual(32) = (y(109)) - (y(111)-y(110));
    residual(33) = (y(103)) - (params(23)*y(9)+y(109)*params(24)+params(25)*y(137)+y(97)*(1-params(23)-params(24)));
    residual(34) = (y(104)) - (y(97));
    residual(35) = (y(105)) - (y(169)-y(168));
    residual(36) = (y(192)) - (x(it_, 9)+y(91)*params(21)+params(19)*(y(51)-y(52))+params(20)*y(193)+y(211));
    residual(37) = (y(112)) - (params(35)*y(13)+y(91)*params(34));
    residual(38) = (y(113)) - (y(112)*(1-params(36))+params(36)*y(222));
    residual(39) = (y(111)) - (params(31)*y(12)+y(93)*params(33)+y(113)*params(32)+y(97)*(1-params(31)-params(33))+y(110)*(1-params(31))+x(it_, 10));
    residual(40) = (y(115)) - (params(44)*y(15)+y(116)*(1-params(44)));
    residual(41) = (y(116)) - (y(108)/(1-params(26))-params(116)*y(161));
    residual(42) = (y(117)) - (y(115)+y(16)-y(114));
    residual(43) = (y(118)) - (y(14));
    residual(44) = (y(119)) - (y(17));
    residual(45) = (y(120)) - (y(18));
    residual(46) = (y(194)) - (x(it_, 11)+y(91)*params(43)+params(37)*(y(64)-y(65))+params(38)*y(195)+params(39)*y(196)+params(40)*y(197)+params(41)*y(198)+y(210));
    residual(47) = (y(122)) - (params(50)*y(19)+(1-params(50))*y(123));
    residual(48) = (y(125)) - (y(91)*(1-params(52))+params(52)*y(223));
    residual(49) = (y(123)) - (params(51)*(y(125)-y(21)));
    residual(50) = (y(124)) - (y(122)+y(20)-y(121));
    residual(51) = (y(199)) - (x(it_, 12)+y(91)*params(49)+y(6)*params(48)+params(45)*(y(55)-y(56))+params(46)*y(200)+y(207));
    residual(52) = (y(127)) - (params(59)*y(23)+(1-params(59))*y(128));
    residual(53) = (y(136)) - (params(61)+y(140)-(y(153)-y(102)));
    residual(54) = (y(137)) - (y(136)-y(28));
    residual(55) = (y(128)) - (y(91)*params(133)-y(137)*params(116));
    residual(56) = (y(129)) - (y(127)+y(24)-y(126));
    residual(57) = (y(130)) - (y(22));
    residual(58) = (y(201)) - (x(it_, 13)+y(6)*params(58)+y(91)*params(57)+params(53)*(y(58)-y(59))+params(54)*y(202)+params(55)*y(203)+y(208));
    residual(59) = (y(132)) - (params(68)*y(26)+(1-params(68))*y(133));
    residual(60) = (y(133)) - ((-params(69))*(y(163)-(params(15)+params(71)+params(128)))+params(132)*y(49));
    residual(61) = (y(134)) - (y(132)+y(27)-y(131));
    residual(62) = (y(135)) - (y(25));
    residual(63) = (y(204)) - (x(it_, 14)+y(6)*params(67)+y(91)*params(66)+params(62)*(y(61)-y(62))+params(63)*y(205)+params(64)*y(206)+y(209));
    residual(64) = (y(139)) - (params(72)*y(30)+params(71)*(1-params(72))+x(it_, 16));
    residual(65) = (y(138)) - (params(70)*y(29)+(1-params(70))*(y(92)+y(139))+x(it_, 15));
    residual(66) = (y(144)) - ((1-params(78))*params(81)+params(78)*y(31)+x(it_, 17));
    residual(67) = (y(145)) - ((1-params(79))*params(82)+params(79)*y(32)+x(it_, 18));
    residual(68) = (y(146)) - ((1-params(80))*params(83)+params(80)*y(33)+x(it_, 19));
    residual(69) = (y(141)) - (y(138)+y(144));
    residual(70) = (y(142)) - (y(138)+y(145));
    residual(71) = (y(143)) - (y(138)+y(146));
    residual(72) = (y(140)) - (y(141)*params(75)+y(142)*params(76)+y(143)*params(77));
    residual(73) = (y(147)) - (params(84)*y(34)-y(99)*params(85)+params(85)*(y(100)-y(101))+x(it_, 20));
    residual(74) = (y(149)) - (y(36)-y(148));
    residual(75) = (y(148)) - (y(36)*params(86)+params(87)*y(35)+y(94)*params(88)+y(147)*params(89)+params(29)*y(157)+x(it_, 21));
    residual(76) = (y(151)) - (y(38)-y(150));
    residual(77) = (y(150)) - (y(38)*params(90)+params(91)*y(37)+params(92)*y(162)+y(147)*params(93)+x(it_, 22));
    residual(78) = (y(152)) - (params(94)*y(39)+y(102)*params(95)+params(117)*y(156)+y(157)*params(120)+y(97)*(1-params(94)-params(95)-params(117))+x(it_, 23));
    residual(79) = (y(153)) - (params(96)*y(40)+y(102)*params(97)+y(156)*params(118)+y(97)*(1-params(96)-params(97)-params(118))+x(it_, 24));
    residual(80) = (y(154)) - (params(98)*y(41)+y(102)*params(99)+y(156)*params(119)+y(97)*(1-params(98)-params(99)-params(119))+x(it_, 25));
    residual(81) = (y(155)) - (params(100)*y(42)+y(102)*params(101)+y(97)*(1-params(100)-params(101))+y(147)*params(102)+y(157)*params(30)+x(it_, 26));
    residual(82) = (y(156)) - (params(103)*y(43)+y(102)*params(104)+y(97)*(1-params(103)-params(104))+y(147)*params(105)+y(157)*params(121)+x(it_, 27));
    residual(83) = (y(157)) - (params(28)*y(44)+y(94)*0.10+x(it_, 31));
    residual(84) = (y(158)) - (params(106)*y(45)+y(91)*params(107)+x(it_, 28));
    residual(85) = (y(159)) - (params(108)*y(46)+(y(111)-y(110))*params(109)+y(97)*(1-params(108)-params(109))+x(it_, 29));
    residual(86) = (y(160)) - (y(121)*params(110)+y(126)*params(111)+y(131)*params(112)+y(158)*params(113)+y(148)*params(114)-y(150)*params(115));
    residual(87) = (y(161)) - (y(111)-y(102)-y(110));
    residual(88) = (y(162)) - (y(121)*params(122)+y(126)*params(123)+y(131)*params(124)+y(158)*params(125)+y(148)*params(126));
    residual(89) = (y(163)) - (params(127)*y(47)+(1-params(127))*(params(128)+y(138))+x(it_, 32));
    residual(90) = (y(164)) - (params(129)*y(48)+y(91)*params(130)+y(6)*params(131)+x(it_, 33));
    residual(91) = (y(165)) - (y(164)+y(49)*0.98);
    residual(92) = (y(182)) - (y(166)-y(50));
    residual(93) = (y(183)) - (y(66));
    residual(94) = (y(184)) - (y(170)-y(54));
    residual(95) = (y(185)) - (y(67));
    residual(96) = (y(186)) - (y(173)-y(57));
    residual(97) = (y(187)) - (y(68));
    residual(98) = (y(188)) - (y(176)-y(60));
    residual(99) = (y(189)) - (y(69));
    residual(100) = (y(190)) - (y(179)-y(63));
    residual(101) = (y(191)) - (y(70));
    residual(102) = (y(192)) - (y(168)-y(52));
    residual(103) = (y(193)) - (y(71));
    residual(104) = (y(194)) - (y(181)-y(65));
    residual(105) = (y(195)) - (y(72));
    residual(106) = (y(196)) - (y(73));
    residual(107) = (y(197)) - (y(74));
    residual(108) = (y(198)) - (y(75));
    residual(109) = (y(199)) - (y(172)-y(56));
    residual(110) = (y(200)) - (y(76));
    residual(111) = (y(201)) - (y(175)-y(59));
    residual(112) = (y(202)) - (y(77));
    residual(113) = (y(203)) - (y(78));
    residual(114) = (y(204)) - (y(178)-y(62));
    residual(115) = (y(205)) - (y(79));
    residual(116) = (y(206)) - (y(80));
    residual(117) = (y(207)) - (y(55)*params(135)+y(54)*params(136)+y(55)*params(137)+params(138)*y(81)+params(139)*y(82));
    residual(118) = (y(208)) - (y(58)*params(140)+y(57)*params(141)+y(58)*params(142)+params(143)*y(83)+params(144)*y(84));
    residual(119) = (y(209)) - (y(61)*params(145)+y(60)*params(146)+y(61)*params(147)+params(148)*y(85)+params(149)*y(86));
    residual(120) = (y(210)) - (y(64)*params(150)+y(63)*params(151)+y(64)*params(152)+params(153)*y(87)+params(154)*y(88));
    residual(121) = (y(211)) - (y(51)*params(155)+y(50)*params(156)+y(51)*params(157)+params(158)*y(89)+params(159)*y(90));
    residual(122) = (y(212)) - (y(54));
    residual(123) = (y(213)) - (y(55));
    residual(124) = (y(214)) - (y(57));
    residual(125) = (y(215)) - (y(58));
    residual(126) = (y(216)) - (y(60));
    residual(127) = (y(217)) - (y(61));
    residual(128) = (y(218)) - (y(63));
    residual(129) = (y(219)) - (y(64));
    residual(130) = (y(220)) - (y(50));
    residual(131) = (y(221)) - (y(51));

end
