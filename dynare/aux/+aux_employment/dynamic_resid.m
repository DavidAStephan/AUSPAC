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
    T = aux_employment.dynamic_resid_tt(T, y, x, params, steady_state, it_);
end
residual = zeros(21, 1);
    residual(1) = (y(20)) - (params(2)*y(1)-params(3)*(y(3)-y(2))+params(1)*y(5)+x(it_, 1));
    residual(2) = (y(22)) - (y(3)*params(4)+(1-params(4))*(y(2)*params(5)+y(1)*params(6))+x(it_, 2));
    residual(3) = (y(21)) - (y(2)*params(7)+y(1)*params(8)+params(17)*(y(10)-y(8))+params(18)*(y(11)-y(8))+params(19)*y(12)+x(it_, 3));
    residual(4) = (y(23)) - (params(15)*y(4)+y(1)*params(16)+x(it_, 9));
    residual(5) = (y(24)) - (y(5)*params(9)+x(it_, 4));
    residual(6) = (y(25)) - (params(10)*y(6)+y(5)*params(11)+x(it_, 5));
    residual(7) = (y(26)) - (params(12)*y(7)+(1-params(12))*params(20)+x(it_, 6));
    residual(8) = (y(27)) - (y(8)*params(13)+(1-params(13))*params(21)+x(it_, 7));
    residual(9) = (y(28)) - (params(14)*y(9)+(1-params(14))*params(22)+x(it_, 8));
    residual(10) = (y(29)) - (y(10)*params(23)+params(21)*(1-params(23))+x(it_, 10));
    residual(11) = (y(30)) - (y(11)*params(24)+params(21)*(1-params(24))+x(it_, 11));
    residual(12) = (y(31)) - (y(12)*params(25)+x(it_, 12));
    residual(13) = (y(32)) - (params(26)*y(13)+x(it_, 13));
    residual(14) = (y(33)) - (params(28)*y(14)+y(1)*params(29)+y(3)*params(30)+y(2)*params(31)+y(4)*params(32)+y(13)*params(27)+x(it_, 14));
    residual(15) = (y(35)) - (x(it_, 15)+y(20)*params(38)+params(33)*(y(14)-y(15))+params(34)*y(36)+params(35)*y(37)+params(36)*y(38)+params(37)*y(39)+y(40));
    residual(16) = (y(35)) - (y(34)-y(15));
    residual(17) = (y(36)) - (y(16));
    residual(18) = (y(37)) - (y(17));
    residual(19) = (y(38)) - (y(18));
    residual(20) = (y(39)) - (y(19));
    residual(21) = (y(40)) - (params(40)+y(1)*params(41)+y(3)*params(42)+y(2)*params(43)+y(4)*params(44)+y(5)*params(45)+y(6)*params(46)+y(7)*params(47)+y(8)*params(48)+y(9)*params(49)+y(10)*params(50)+y(11)*params(51)+y(12)*params(52)+y(13)*params(53)+y(14)*params(54));

end
