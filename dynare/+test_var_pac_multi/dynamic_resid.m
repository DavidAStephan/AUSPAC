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
    T = test_var_pac_multi.dynamic_resid_tt(T, y, x, params, steady_state, it_);
end
residual = zeros(15, 1);
    residual(1) = (y(10)) - (params(1)*y(1)-params(2)*(y(2)-y(3))+x(it_, 1));
    residual(2) = (y(11)) - (y(2)*params(3)+(1-params(3))*(y(3)*params(4)+y(1)*params(5))+x(it_, 2));
    residual(3) = (y(12)) - (y(3)*params(6)+y(1)*params(7)+x(it_, 3));
    residual(4) = (y(13)) - (params(8)*y(4)+y(1)*params(9)+y(2)*params(10)+y(3)*params(11)+x(it_, 4));
    residual(5) = (y(14)) - (params(12)*y(5)+y(1)*params(13)+y(2)*params(14)+y(3)*params(15)+x(it_, 5));
    residual(6) = (y(16)) - (y(6)+y(15));
    residual(7) = (y(18)) - (y(7)+y(17));
    residual(8) = (y(19)) - (x(it_, 6)+y(10)*params(18)+params(16)*(y(4)-y(6))+params(17)*y(20)+y(24));
    residual(9) = (y(21)) - (x(it_, 7)+y(10)*params(21)+params(19)*(y(5)-y(7))+params(20)*y(22)+y(23));
    residual(10) = (y(19)) - (y(16)-y(6));
    residual(11) = (y(20)) - (y(8));
    residual(12) = (y(21)) - (y(18)-y(7));
    residual(13) = (y(22)) - (y(9));
    residual(14) = (y(23)) - (params(23)+y(1)*params(24)+y(2)*params(25)+y(3)*params(26)+y(4)*params(27)+y(5)*params(28));
    residual(15) = (y(24)) - (params(29)+y(1)*params(30)+y(2)*params(31)+y(3)*params(32)+y(4)*params(33)+y(5)*params(34));

end
