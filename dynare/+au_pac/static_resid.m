function residual = static_resid(T, y, x, params, T_flag)
% function residual = static_resid(T, y, x, params, T_flag)
%
% File created by Dynare Preprocessor from .mod file
%
% Inputs:
%   T         [#temp variables by 1]  double   vector of temporary terms to be filled by function
%   y         [M_.endo_nbr by 1]      double   vector of endogenous variables in declaration order
%   x         [M_.exo_nbr by 1]       double   vector of exogenous variables in declaration order
%   params    [M_.param_nbr by 1]     double   vector of parameter values in declaration order
%                                              to evaluate the model
%   T_flag    boolean                 boolean  flag saying whether or not to calculate temporary terms
%
% Output:
%   residual
%

if T_flag
    T = au_pac.static_resid_tt(T, y, x, params);
end
residual = zeros(131, 1);
    residual(1) = (y(9)) - (y(2)-y(6));
    residual(2) = (y(10)) - (y(3)-y(7));
    residual(3) = (y(11)) - (y(5)-y(8));
    residual(4) = (y(1)) - (params(1)*y(4)+y(1)*params(2)-params(3)*(y(9)-y(10))+params(18)*y(70)+x(1));
    residual(5) = (y(9)) - (y(9)*params(4)+(1-params(4))*(y(10)*params(5)+y(1)*params(6))+x(2));
    residual(6) = (y(10)) - (y(10)*params(7)+y(1)*params(8)+x(3));
    residual(7) = (y(4)) - (y(4)*params(9)+x(4));
    residual(8) = (y(11)) - (y(11)*params(10)+y(4)*params(11)+x(5));
    residual(9) = (y(6)) - (y(6)*params(12)+(1-params(12))*params(15)+x(6));
    residual(10) = (y(7)) - (y(7)*params(13)+(1-params(13))*params(16)+x(7));
    residual(11) = (y(8)) - (y(8)*params(14)+(1-params(14))*params(17)+x(8));
    residual(12) = (y(92)) - (x(34)+y(77)*params(19)-y(76)+params(20)*y(93));
    residual(13) = (y(77)) - (y(77)+x(35));
    residual(14) = (y(94)) - (x(36)+y(81)*params(45)-y(80)+params(46)*y(95));
    residual(15) = (y(81)) - (y(81)+x(37));
    residual(16) = (y(96)) - (x(38)+y(84)*params(53)-y(83)+params(54)*y(97));
    residual(17) = (y(84)) - (y(84)+x(39));
    residual(18) = (y(98)) - (x(40)+y(87)*params(62)-y(86)+params(63)*y(99));
    residual(19) = (y(87)) - (y(87)+x(41));
    residual(20) = (y(100)) - (x(42)+y(90)*params(37)-y(89)+params(38)*y(101));
    residual(21) = (y(90)) - (y(90)+x(43));
    residual(22) = (y(12)) - (params(16));
    residual(23) = (y(79)) - (y(79)+y(13)-params(16));
residual(24) = y(31);
residual(25) = y(36);
residual(26) = y(41);
residual(27) = y(24);
    residual(28) = (y(16)) - (y(16)*(1-params(61))+y(36)*params(61));
    residual(29) = (y(17)) - (y(16)*params(26)+(1-params(26))*y(26)+y(18));
    residual(30) = (y(18)) - (y(18)*params(27)+x(30));
    residual(31) = (y(20)) - (y(18)/(1-params(26)));
    residual(32) = (y(19)) - (y(21)-y(20));
    residual(33) = (y(13)) - (y(13)*params(23)+y(19)*params(24)+params(25)*y(47)+y(7)*(1-params(23)-params(24)));
    residual(34) = (y(14)) - (y(7));
    residual(35) = (y(15)) - (y(79)-y(78));
    residual(36) = (y(102)) - (x(9)+y(1)*params(21)+params(19)*(y(77)-y(78))+params(20)*y(103)+y(121));
    residual(37) = (y(22)) - (y(22)*params(35)+y(1)*params(34));
    residual(38) = (y(23)) - (y(22)*(1-params(36))+y(23)*params(36));
    residual(39) = (y(21)) - (y(21)*params(31)+y(3)*params(33)+y(23)*params(32)+y(7)*(1-params(31)-params(33))+y(20)*(1-params(31))+x(10));
    residual(40) = (y(25)) - (y(25)*params(44)+y(26)*(1-params(44)));
    residual(41) = (y(26)) - (y(18)/(1-params(26))-params(116)*y(71));
    residual(42) = (y(27)) - (y(25)+y(27)-y(24));
    residual(43) = (y(28)) - (y(24));
    residual(44) = (y(29)) - (y(28));
    residual(45) = (y(30)) - (y(29));
    residual(46) = (y(104)) - (x(11)+y(1)*params(43)+params(37)*(y(90)-y(91))+params(38)*y(105)+params(39)*y(106)+params(40)*y(107)+params(41)*y(108)+y(120));
    residual(47) = (y(32)) - (y(32)*params(50)+(1-params(50))*y(33));
    residual(48) = (y(35)) - (y(1)*(1-params(52))+y(35)*params(52));
residual(49) = y(33);
    residual(50) = (y(34)) - (y(32)+y(34)-y(31));
    residual(51) = (y(109)) - (x(12)+y(1)*params(49)+y(9)*params(48)+params(45)*(y(81)-y(82))+params(46)*y(110)+y(117));
    residual(52) = (y(37)) - (y(37)*params(59)+(1-params(59))*y(38));
    residual(53) = (y(46)) - (params(61)+y(50)-(y(63)-y(12)));
residual(54) = y(47);
    residual(55) = (y(38)) - (y(1)*params(133)-y(47)*params(116));
    residual(56) = (y(39)) - (y(37)+y(39)-y(36));
    residual(57) = (y(40)) - (y(36));
    residual(58) = (y(111)) - (x(13)+y(9)*params(58)+y(1)*params(57)+params(53)*(y(84)-y(85))+params(54)*y(112)+params(55)*y(113)+y(118));
    residual(59) = (y(42)) - (y(42)*params(68)+(1-params(68))*y(43));
    residual(60) = (y(43)) - ((-params(69))*(y(73)-(params(15)+params(71)+params(128)))+params(132)*y(75));
    residual(61) = (y(44)) - (y(42)+y(44)-y(41));
    residual(62) = (y(45)) - (y(41));
    residual(63) = (y(114)) - (x(14)+y(9)*params(67)+y(1)*params(66)+params(62)*(y(87)-y(88))+params(63)*y(115)+params(64)*y(116)+y(119));
    residual(64) = (y(49)) - (y(49)*params(72)+params(71)*(1-params(72))+x(16));
    residual(65) = (y(48)) - (y(48)*params(70)+(1-params(70))*(y(2)+y(49))+x(15));
    residual(66) = (y(54)) - ((1-params(78))*params(81)+y(54)*params(78)+x(17));
    residual(67) = (y(55)) - ((1-params(79))*params(82)+y(55)*params(79)+x(18));
    residual(68) = (y(56)) - ((1-params(80))*params(83)+y(56)*params(80)+x(19));
    residual(69) = (y(51)) - (y(48)+y(54));
    residual(70) = (y(52)) - (y(48)+y(55));
    residual(71) = (y(53)) - (y(48)+y(56));
    residual(72) = (y(50)) - (y(51)*params(75)+y(52)*params(76)+y(53)*params(77));
    residual(73) = (y(57)) - (y(57)*params(84)-y(9)*params(85)+params(85)*(y(10)-y(11))+x(20));
    residual(74) = (y(59)) - (y(59)-y(58));
    residual(75) = (y(58)) - (y(59)*params(86)+y(58)*params(87)+y(4)*params(88)+y(57)*params(89)+params(29)*y(67)+x(21));
    residual(76) = (y(61)) - (y(61)-y(60));
    residual(77) = (y(60)) - (y(61)*params(90)+y(60)*params(91)+params(92)*y(72)+y(57)*params(93)+x(22));
    residual(78) = (y(62)) - (y(62)*params(94)+y(12)*params(95)+params(117)*y(66)+y(67)*params(120)+y(7)*(1-params(94)-params(95)-params(117))+x(23));
    residual(79) = (y(63)) - (y(63)*params(96)+y(12)*params(97)+y(66)*params(118)+y(7)*(1-params(96)-params(97)-params(118))+x(24));
    residual(80) = (y(64)) - (y(64)*params(98)+y(12)*params(99)+y(66)*params(119)+y(7)*(1-params(98)-params(99)-params(119))+x(25));
    residual(81) = (y(65)) - (y(65)*params(100)+y(12)*params(101)+y(7)*(1-params(100)-params(101))+y(57)*params(102)+y(67)*params(30)+x(26));
    residual(82) = (y(66)) - (y(66)*params(103)+y(12)*params(104)+y(7)*(1-params(103)-params(104))+y(57)*params(105)+y(67)*params(121)+x(27));
    residual(83) = (y(67)) - (y(67)*params(28)+y(4)*0.10+x(31));
    residual(84) = (y(68)) - (y(68)*params(106)+y(1)*params(107)+x(28));
    residual(85) = (y(69)) - (y(69)*params(108)+(y(21)-y(20))*params(109)+y(7)*(1-params(108)-params(109))+x(29));
    residual(86) = (y(70)) - (y(31)*params(110)+y(36)*params(111)+y(41)*params(112)+y(68)*params(113)+y(58)*params(114)-y(60)*params(115));
    residual(87) = (y(71)) - (y(21)-y(12)-y(20));
    residual(88) = (y(72)) - (y(31)*params(122)+y(36)*params(123)+y(41)*params(124)+y(68)*params(125)+y(58)*params(126));
    residual(89) = (y(73)) - (y(73)*params(127)+(1-params(127))*(params(128)+y(48))+x(32));
    residual(90) = (y(74)) - (y(74)*params(129)+y(1)*params(130)+y(9)*params(131)+x(33));
    residual(91) = (y(75)) - (y(74)+y(75)*0.98);
residual(92) = y(92);
    residual(93) = (y(93)) - (y(92));
residual(94) = y(94);
    residual(95) = (y(95)) - (y(94));
residual(96) = y(96);
    residual(97) = (y(97)) - (y(96));
residual(98) = y(98);
    residual(99) = (y(99)) - (y(98));
residual(100) = y(100);
    residual(101) = (y(101)) - (y(100));
residual(102) = y(102);
    residual(103) = (y(103)) - (y(102));
residual(104) = y(104);
    residual(105) = (y(105)) - (y(104));
    residual(106) = (y(106)) - (y(105));
    residual(107) = (y(107)) - (y(106));
    residual(108) = (y(108)) - (y(107));
residual(109) = y(109);
    residual(110) = (y(110)) - (y(109));
residual(111) = y(111);
    residual(112) = (y(112)) - (y(111));
    residual(113) = (y(113)) - (y(112));
residual(114) = y(114);
    residual(115) = (y(115)) - (y(114));
    residual(116) = (y(116)) - (y(115));
    residual(117) = (y(117)) - (y(81)*params(135)+y(80)*params(136)+y(81)*params(137)+params(138)*y(122)+params(139)*y(123));
    residual(118) = (y(118)) - (y(84)*params(140)+y(83)*params(141)+y(84)*params(142)+params(143)*y(124)+params(144)*y(125));
    residual(119) = (y(119)) - (y(87)*params(145)+y(86)*params(146)+y(87)*params(147)+params(148)*y(126)+params(149)*y(127));
    residual(120) = (y(120)) - (y(90)*params(150)+y(89)*params(151)+y(90)*params(152)+params(153)*y(128)+params(154)*y(129));
    residual(121) = (y(121)) - (y(77)*params(155)+y(76)*params(156)+y(77)*params(157)+params(158)*y(130)+params(159)*y(131));
    residual(122) = (y(122)) - (y(80));
    residual(123) = (y(123)) - (y(81));
    residual(124) = (y(124)) - (y(83));
    residual(125) = (y(125)) - (y(84));
    residual(126) = (y(126)) - (y(86));
    residual(127) = (y(127)) - (y(87));
    residual(128) = (y(128)) - (y(89));
    residual(129) = (y(129)) - (y(90));
    residual(130) = (y(130)) - (y(76));
    residual(131) = (y(131)) - (y(77));

end
