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
    T = au_esat.dynamic_resid_tt(T, y, x, params, steady_state, it_);
end
residual = zeros(11, 1);
    residual(1) = (y(17)) - (y(10)-y(14));
    residual(2) = (y(18)) - (y(11)-y(15));
    residual(3) = (y(19)) - (y(13)-y(16));
    residual(4) = (y(9)) - (params(1)*y(12)+params(2)*y(1)-params(3)*(y(6)-y(7))+x(it_, 1));
    residual(5) = (y(17)) - (y(6)*params(4)+(1-params(4))*(y(7)*params(5)+y(1)*params(6))+x(it_, 2));
    residual(6) = (y(18)) - (y(7)*params(7)+y(1)*params(8)+x(it_, 3));
    residual(7) = (y(12)) - (params(9)*y(2)+x(it_, 4));
    residual(8) = (y(19)) - (params(10)*y(8)+y(2)*params(11)+x(it_, 5));
    residual(9) = (y(14)) - (params(12)*y(3)+(1-params(12))*params(15)+x(it_, 6));
    residual(10) = (y(15)) - (params(13)*y(4)+(1-params(13))*params(16)+x(it_, 7));
    residual(11) = (y(16)) - (params(14)*y(5)+(1-params(14))*params(17)+x(it_, 8));

end
