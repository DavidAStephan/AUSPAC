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
    T = au_pac_var.static_resid_tt(T, y, x, params);
end
residual = zeros(132, 1);
    residual(1) = (y(9)) - (y(2)-y(6));
    residual(2) = (y(10)) - (y(3)-y(7));
    residual(3) = (y(11)) - (y(5)-y(8));
    residual(4) = (y(1)) - (params(1)*y(4)+y(1)*params(2)-params(3)*(y(9)-y(10))+params(18)*y(71)+x(1));
    residual(5) = (y(9)) - (y(9)*params(4)+(1-params(4))*(y(10)*params(5)+y(1)*params(6))+x(2));
    residual(6) = (y(10)) - (y(10)*params(7)+y(1)*params(8)+x(3));
    residual(7) = (y(4)) - (y(4)*params(9)+x(4));
    residual(8) = (y(11)) - (y(11)*params(10)+y(4)*params(11)+x(5));
    residual(9) = (y(6)) - (y(6)*params(12)+(1-params(12))*params(15)+x(6));
    residual(10) = (y(7)) - (y(7)*params(13)+(1-params(13))*params(16)+x(7));
    residual(11) = (y(8)) - (y(8)*params(14)+(1-params(14))*params(17)+x(8));
    residual(12) = (y(93)) - (x(34)+y(78)*params(19)-y(77)+params(20)*y(94));
    residual(13) = (y(78)) - (y(78)+x(35));
    residual(14) = (y(95)) - (x(36)+y(82)*params(45)-y(81)+params(46)*y(96));
    residual(15) = (y(82)) - (y(82)+x(37));
    residual(16) = (y(97)) - (x(38)+y(85)*params(54)-y(84)+params(55)*y(98));
    residual(17) = (y(85)) - (y(85)+x(39));
    residual(18) = (y(99)) - (x(40)+y(88)*params(63)-y(87)+params(64)*y(100));
    residual(19) = (y(88)) - (y(88)+x(41));
    residual(20) = (y(101)) - (x(42)+y(91)*params(37)-y(90)+params(38)*y(102));
    residual(21) = (y(91)) - (y(91)+x(43));
    residual(22) = (y(12)) - (params(16));
    residual(23) = (y(80)) - (y(80)+y(13)-params(16));
residual(24) = y(31);
residual(25) = y(36);
residual(26) = y(41);
residual(27) = y(24);
    residual(28) = (y(16)) - (y(16)*(1-params(62))+y(36)*params(62));
    residual(29) = (y(17)) - (y(16)*params(26)+(1-params(26))*y(26)+y(18));
    residual(30) = (y(18)) - (y(18)*params(27)+x(30));
    residual(31) = (y(20)) - (y(18)/(1-params(26)));
    residual(32) = (y(19)) - (y(21)-y(20));
    residual(33) = (y(13)) - (y(13)*params(23)+y(19)*params(24)+params(25)*y(47)+y(7)*(1-params(23)-params(24)));
    residual(34) = (y(14)) - (y(7));
    residual(35) = (y(15)) - (y(80)-y(79));
    residual(36) = (y(103)) - (x(9)+y(1)*params(21)+params(19)*(y(78)-y(79))+params(20)*y(104)+y(122));
    residual(37) = (y(22)) - (y(22)*params(35)+y(1)*params(34));
    residual(38) = (y(23)) - (y(23)*params(36)+y(22)*(1-params(36)));
    residual(39) = (y(21)) - (y(21)*params(31)+y(3)*params(33)+y(23)*params(32)+y(7)*(1-params(31)-params(33))+y(20)*(1-params(31))+x(10));
    residual(40) = (y(25)) - (y(25)*params(44)+y(26)*(1-params(44)));
    residual(41) = (y(26)) - (y(18)/(1-params(26))-params(118)*y(72));
    residual(42) = (y(27)) - (y(25)+y(27)-y(24));
    residual(43) = (y(28)) - (y(24));
    residual(44) = (y(29)) - (y(28));
    residual(45) = (y(30)) - (y(29));
    residual(46) = (y(105)) - (x(11)+y(1)*params(43)+params(37)*(y(91)-y(92))+params(38)*y(106)+params(39)*y(107)+params(40)*y(108)+params(41)*y(109)+y(121));
    residual(47) = (y(32)) - (y(32)*params(50)+(1-params(50))*y(33));
    residual(48) = (y(35)) - (y(35)*params(52)+y(1)*(1-params(52)));
residual(49) = y(33);
    residual(50) = (y(34)) - (y(32)+y(34)-y(31));
    residual(51) = (y(110)) - (x(12)+y(1)*params(49)+y(9)*params(48)+params(45)*(y(82)-y(83))+params(46)*y(111)+y(118));
    residual(52) = (y(37)) - (y(37)*params(60)+(1-params(60))*y(38));
    residual(53) = (y(46)) - (params(62)+y(51)-(y(64)-y(12)));
residual(54) = y(47);
    residual(55) = (y(38)) - (y(1)*params(136)-y(47)*params(118));
    residual(56) = (y(39)) - (y(37)+y(39)-y(36));
    residual(57) = (y(40)) - (y(36));
    residual(58) = (y(112)) - (x(13)+y(9)*params(59)+y(1)*params(58)+params(54)*(y(85)-y(86))+params(55)*y(113)+params(56)*y(114)+y(119));
    residual(59) = (y(42)) - (y(42)*params(69)+(1-params(69))*y(43));
    residual(60) = (y(43)) - (params(134)*y(76)-params(70)*(y(74)-(params(15)+params(73)+params(130))));
    residual(61) = (y(44)) - (y(42)+y(44)-y(41));
    residual(62) = (y(45)) - (y(41));
    residual(63) = (y(115)) - (x(14)+y(9)*params(68)+y(1)*params(67)+params(63)*(y(88)-y(89))+params(64)*y(116)+params(65)*y(117)+y(120));
    residual(64) = (y(49)) - (y(49)*params(74)+params(73)*(1-params(74))+x(16));
    residual(65) = (y(50)) - (y(50)*params(72)+y(2)*(1-params(72)));
    residual(66) = (y(48)) - (y(49)+y(50)+x(15));
    residual(67) = (y(55)) - ((1-params(80))*params(83)+y(55)*params(80)+x(17));
    residual(68) = (y(56)) - ((1-params(81))*params(84)+y(56)*params(81)+x(18));
    residual(69) = (y(57)) - ((1-params(82))*params(85)+y(57)*params(82)+x(19));
    residual(70) = (y(52)) - (y(48)+y(55));
    residual(71) = (y(53)) - (y(48)+y(56));
    residual(72) = (y(54)) - (y(48)+y(57));
    residual(73) = (y(51)) - (y(52)*params(77)+y(53)*params(78)+y(54)*params(79));
    residual(74) = (y(58)) - (y(58)*params(86)-y(9)*params(87)+params(87)*(y(10)-y(11))+x(20));
    residual(75) = (y(60)) - (y(60)-y(59));
    residual(76) = (y(59)) - (y(60)*params(88)+y(59)*params(89)+y(4)*params(90)+y(58)*params(91)+params(29)*y(68)+x(21));
    residual(77) = (y(62)) - (y(62)-y(61));
    residual(78) = (y(61)) - (y(62)*params(92)+y(61)*params(93)+params(94)*y(73)+y(58)*params(95)+x(22));
    residual(79) = (y(63)) - (y(63)*params(96)+y(12)*params(97)+params(119)*y(67)+y(68)*params(122)+y(7)*(1-params(96)-params(97)-params(119))+x(23));
    residual(80) = (y(64)) - (y(64)*params(98)+y(12)*params(99)+y(67)*params(120)+y(7)*(1-params(98)-params(99)-params(120))+x(24));
    residual(81) = (y(65)) - (y(65)*params(100)+y(12)*params(101)+y(67)*params(121)+y(7)*(1-params(100)-params(101)-params(121))+x(25));
    residual(82) = (y(66)) - (y(66)*params(102)+y(12)*params(103)+y(7)*(1-params(102)-params(103))+y(58)*params(104)+y(68)*params(30)+x(26));
    residual(83) = (y(67)) - (y(67)*params(105)+y(12)*params(106)+y(7)*(1-params(105)-params(106))+y(58)*params(107)+y(68)*params(123)+x(27));
    residual(84) = (y(68)) - (y(68)*params(28)+y(4)*0.10+x(31));
    residual(85) = (y(69)) - (y(69)*params(108)+y(1)*params(109)+x(28));
    residual(86) = (y(70)) - (y(70)*params(110)+(y(21)-y(20))*params(111)+y(7)*(1-params(110)-params(111))+x(29));
    residual(87) = (y(71)) - (y(31)*params(112)+y(36)*params(113)+y(41)*params(114)+y(69)*params(115)+y(59)*params(116)-y(61)*params(117));
    residual(88) = (y(72)) - (y(21)-y(12)-y(20));
    residual(89) = (y(73)) - (y(31)*params(124)+y(36)*params(125)+y(41)*params(126)+y(69)*params(127)+y(59)*params(128));
    residual(90) = (y(74)) - (y(74)*params(129)+(1-params(129))*(params(130)+y(48))+x(32));
    residual(91) = (y(75)) - (y(75)*params(131)+y(1)*params(132)+y(9)*params(133)+x(33));
    residual(92) = (y(76)) - (y(75)+y(76)*0.98);
residual(93) = y(93);
    residual(94) = (y(94)) - (y(93));
residual(95) = y(95);
    residual(96) = (y(96)) - (y(95));
residual(97) = y(97);
    residual(98) = (y(98)) - (y(97));
residual(99) = y(99);
    residual(100) = (y(100)) - (y(99));
residual(101) = y(101);
    residual(102) = (y(102)) - (y(101));
residual(103) = y(103);
    residual(104) = (y(104)) - (y(103));
residual(105) = y(105);
    residual(106) = (y(106)) - (y(105));
    residual(107) = (y(107)) - (y(106));
    residual(108) = (y(108)) - (y(107));
    residual(109) = (y(109)) - (y(108));
residual(110) = y(110);
    residual(111) = (y(111)) - (y(110));
residual(112) = y(112);
    residual(113) = (y(113)) - (y(112));
    residual(114) = (y(114)) - (y(113));
residual(115) = y(115);
    residual(116) = (y(116)) - (y(115));
    residual(117) = (y(117)) - (y(116));
    residual(118) = (y(118)) - (y(82)*params(138)+y(81)*params(139)+y(82)*params(140)+params(141)*y(123)+params(142)*y(124));
    residual(119) = (y(119)) - (y(85)*params(143)+y(84)*params(144)+y(85)*params(145)+params(146)*y(125)+params(147)*y(126));
    residual(120) = (y(120)) - (y(88)*params(148)+y(87)*params(149)+y(88)*params(150)+params(151)*y(127)+params(152)*y(128));
    residual(121) = (y(121)) - (y(91)*params(153)+y(90)*params(154)+y(91)*params(155)+params(156)*y(129)+params(157)*y(130));
    residual(122) = (y(122)) - (y(78)*params(158)+y(77)*params(159)+y(78)*params(160)+params(161)*y(131)+params(162)*y(132));
    residual(123) = (y(123)) - (y(81));
    residual(124) = (y(124)) - (y(82));
    residual(125) = (y(125)) - (y(84));
    residual(126) = (y(126)) - (y(85));
    residual(127) = (y(127)) - (y(87));
    residual(128) = (y(128)) - (y(88));
    residual(129) = (y(129)) - (y(90));
    residual(130) = (y(130)) - (y(91));
    residual(131) = (y(131)) - (y(77));
    residual(132) = (y(132)) - (y(78));

end
