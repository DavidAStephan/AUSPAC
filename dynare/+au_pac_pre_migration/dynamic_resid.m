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
    T = au_pac_pre_migration.dynamic_resid_tt(T, y, x, params, steady_state, it_);
end
residual = zeros(53, 1);
    residual(1) = (y(57)) - (y(50)-y(54));
    residual(2) = (y(58)) - (y(51)-y(55));
    residual(3) = (y(59)) - (y(53)-y(56));
    residual(4) = (y(49)) - (params(1)*y(52)+params(2)*y(1)-params(3)*(y(6)-y(7))+params(18)*y(101)+x(it_, 1));
    residual(5) = (y(57)) - (y(6)*params(4)+(1-params(4))*(y(7)*params(5)+y(1)*params(6))+x(it_, 2));
    residual(6) = (y(58)) - (y(7)*params(7)+y(1)*params(8)+x(it_, 3));
    residual(7) = (y(52)) - (params(9)*y(2)+x(it_, 4));
    residual(8) = (y(59)) - (params(10)*y(8)+y(2)*params(11)+x(it_, 5));
    residual(9) = (y(54)) - (params(12)*y(3)+(1-params(12))*params(15)+x(it_, 6));
    residual(10) = (y(55)) - (params(13)*y(4)+(1-params(13))*params(16)+x(it_, 7));
    residual(11) = (y(56)) - (params(14)*y(5)+(1-params(14))*params(17)+x(it_, 8));
    residual(12) = (y(61)) - (params(23)*y(10)+y(55)*(1-params(23)));
    residual(13) = (y(62)) - (y(55));
    residual(14) = (y(63)) - (y(61)+y(12)-y(60));
    residual(15) = (y(60)) - (y(12)*params(19)+params(20)*y(9)+y(61)*params(22)+y(49)*params(21)+(1-params(20)-params(22))*y(11)+x(it_, 9));
    residual(16) = (y(64)) - (params(24)*y(13)+y(51)*params(26)+y(49)*params(25)+y(55)*(1-params(24)-params(26))+x(it_, 10));
    residual(17) = (y(66)) - (params(34)*y(15));
residual(18) = y(67);
    residual(19) = (y(68)) - (y(66)+y(16)-y(65));
    residual(20) = (y(69)) - (y(14));
    residual(21) = (y(70)) - (y(17));
    residual(22) = (y(71)) - (y(18));
    residual(23) = (y(65)) - (y(16)*params(27)+y(14)*params(28)+y(17)*params(29)+y(18)*params(30)+params(31)*y(19)+y(66)*params(32)+y(49)*params(33)+x(it_, 11));
    residual(24) = (y(73)) - (params(40)*y(21)+(1-params(40))*y(74));
    residual(25) = (y(74)) - (y(49)*params(41));
    residual(26) = (y(75)) - (y(73)+y(23)-y(72));
    residual(27) = (y(72)) - (y(23)*params(35)+params(36)*y(20)+y(73)*params(37)+(y(6)-y(7))*params(38)+y(49)*params(39)+(1-params(36)-params(37))*y(22)+x(it_, 12));
    residual(28) = (y(77)) - (params(48)*y(25)+(1-params(48))*y(78));
    residual(29) = (y(78)) - ((-params(49))*(y(88)-(params(15)+params(59)+params(62))));
    residual(30) = (y(79)) - (y(77)+y(27)-y(76));
    residual(31) = (y(80)) - (y(24));
    residual(32) = (y(76)) - (y(27)*params(42)+y(24)*params(43)+params(44)*y(28)+y(77)*params(45)+y(49)*params(46)+(y(6)-y(7))*params(47)+(1-params(43)-params(44)-params(45))*y(26)+x(it_, 13));
    residual(33) = (y(82)) - (params(56)*y(30)+(1-params(56))*y(83));
    residual(34) = (y(83)) - (y(57)*(-params(57)));
    residual(35) = (y(84)) - (y(82)+y(32)-y(81));
    residual(36) = (y(85)) - (y(29));
    residual(37) = (y(81)) - (y(32)*params(50)+y(29)*params(51)+params(52)*y(33)+y(82)*params(53)+y(49)*params(54)+(y(6)-y(7))*params(55)+(1-params(51)-params(52)-params(53))*y(31)+x(it_, 14));
    residual(38) = (y(87)) - (params(60)*y(35)+params(59)*(1-params(60))+x(it_, 16));
    residual(39) = (y(86)) - (params(58)*y(34)+(1-params(58))*(y(50)+y(87))+x(it_, 15));
    residual(40) = (y(88)) - (params(61)*y(36)+(1-params(61))*(params(62)+y(86))+x(it_, 17));
    residual(41) = (y(89)) - (params(63)*y(37)-y(57)*params(64)+x(it_, 18));
    residual(42) = (y(91)) - (y(39)-y(90));
    residual(43) = (y(90)) - (y(39)*params(65)+params(66)*y(38)+y(52)*params(67)+y(89)*params(68)+x(it_, 19));
    residual(44) = (y(93)) - (y(41)-y(92));
    residual(45) = (y(92)) - (y(41)*params(69)+params(70)*y(40)+y(49)*params(71)+y(89)*params(72)+x(it_, 20));
    residual(46) = (y(94)) - (params(73)*y(42)+y(60)*params(74)+y(55)*(1-params(73)-params(74))+x(it_, 21));
    residual(47) = (y(95)) - (params(75)*y(43)+y(60)*params(76)+y(55)*(1-params(75)-params(76))+x(it_, 22));
    residual(48) = (y(96)) - (params(77)*y(44)+y(60)*params(78)+y(55)*(1-params(77)-params(78))+x(it_, 23));
    residual(49) = (y(97)) - (params(79)*y(45)+y(60)*params(80)+y(55)*(1-params(79)-params(80))+y(89)*params(81)+x(it_, 24));
    residual(50) = (y(98)) - (params(82)*y(46)+y(60)*params(83)+y(55)*(1-params(82)-params(83))+y(89)*params(84)+x(it_, 25));
    residual(51) = (y(99)) - (params(85)*y(47)+y(49)*params(86)+x(it_, 26));
    residual(52) = (y(100)) - (params(87)*y(48)+y(60)*params(88)+y(55)*(1-params(87)-params(88))+x(it_, 27));
    residual(53) = (y(101)) - (y(72)*params(89)+y(76)*params(90)+y(81)*params(91)+y(99)*params(92)+y(90)*params(93)-y(92)*params(94));

end
