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
    T = aux_consumption.dynamic_resid_tt(T, y, x, params, steady_state, it_);
end
residual = zeros(20, 1);
    residual(1) = (y(19)) - (params(2)*y(1)-params(3)*(y(3)-y(2))+params(1)*y(5)+x(it_, 1));
    residual(2) = (y(21)) - (y(3)*params(4)+(1-params(4))*(y(2)*params(5)+y(1)*params(6))+x(it_, 2));
    residual(3) = (y(20)) - (y(2)*params(7)+y(1)*params(8)+params(17)*(y(10)-y(8))+params(18)*(y(11)-y(8))+params(19)*y(12)+x(it_, 3));
    residual(4) = (y(22)) - (params(15)*y(4)+y(1)*params(16)+x(it_, 9));
    residual(5) = (y(23)) - (y(5)*params(9)+x(it_, 4));
    residual(6) = (y(24)) - (params(10)*y(6)+y(5)*params(11)+x(it_, 5));
    residual(7) = (y(25)) - (params(12)*y(7)+(1-params(12))*params(20)+x(it_, 6));
    residual(8) = (y(26)) - (y(8)*params(13)+(1-params(13))*params(21)+x(it_, 7));
    residual(9) = (y(27)) - (params(14)*y(9)+(1-params(14))*params(22)+x(it_, 8));
    residual(10) = (y(28)) - (y(10)*params(23)+params(21)*(1-params(23))+x(it_, 10));
    residual(11) = (y(29)) - (y(11)*params(24)+params(21)*(1-params(24))+x(it_, 11));
    residual(12) = (y(30)) - (y(12)*params(25)+x(it_, 12));
    residual(13) = (y(31)) - (params(26)*y(13)+x(it_, 13));
    residual(14) = (y(32)) - (params(28)*y(14)+y(1)*params(29)+y(4)*params(30)+y(13)*params(31)+x(it_, 14));
    residual(15) = (y(33)) - (params(33)*y(15)+y(1)*params(34)+y(4)*params(35)+x(it_, 15));
    residual(16) = (y(34)) - (params(36)*y(16)+y(1)*params(37)+y(3)*params(38)+y(2)*params(39)+y(4)*params(40)+y(15)*params(41)+y(13)*params(27)+x(it_, 16));
    residual(17) = (y(36)) - (x(it_, 17)+y(19)*params(45)+y(3)*params(44)+params(42)*(y(16)-y(17))+params(43)*y(37)+y(38));
    residual(18) = (y(36)) - (y(35)-y(17));
    residual(19) = (y(37)) - (y(18));
    residual(20) = (y(38)) - (params(47)+y(1)*params(48)+y(3)*params(49)+y(2)*params(50)+y(4)*params(51)+y(5)*params(52)+y(6)*params(53)+y(7)*params(54)+y(8)*params(55)+y(9)*params(56)+y(10)*params(57)+y(11)*params(58)+y(12)*params(59)+y(13)*params(60)+y(14)*params(61)+y(15)*params(62)+y(16)*params(63));

end
