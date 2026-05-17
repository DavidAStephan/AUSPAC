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
    T = aux_pQ.static_resid_tt(T, y, x, params);
end
residual = zeros(18, 1);
    residual(1) = (y(1)) - (y(1)*params(2)-params(3)*(y(3)-y(2))+params(1)*y(5)+x(1));
    residual(2) = (y(3)) - (y(3)*params(4)+(1-params(4))*(y(2)*params(5)+y(1)*params(6))+x(2));
    residual(3) = (y(2)) - (y(2)*params(7)+y(1)*params(8)+params(17)*(y(10)-y(8))+params(18)*(y(11)-y(8))+params(19)*y(12)+x(3));
    residual(4) = (y(4)) - (y(4)*params(15)+y(1)*params(16)+x(9));
    residual(5) = (y(5)) - (y(5)*params(9)+x(4));
    residual(6) = (y(6)) - (y(6)*params(10)+y(5)*params(11)+x(5));
    residual(7) = (y(7)) - (y(7)*params(12)+(1-params(12))*params(20)+x(6));
    residual(8) = (y(8)) - (y(8)*params(13)+(1-params(13))*params(21)+x(7));
    residual(9) = (y(9)) - (y(9)*params(14)+(1-params(14))*params(22)+x(8));
    residual(10) = (y(10)) - (y(10)*params(29)+params(21)*(1-params(29))+x(10));
    residual(11) = (y(11)) - (y(11)*params(30)+params(21)*(1-params(30))+x(11));
    residual(12) = (y(12)) - (y(12)*params(31)+x(12));
    residual(13) = (y(13)) - (y(13)*params(32)+y(2)*params(33)+y(4)*params(34)+x(13));
    residual(14) = (y(14)) - (y(14)*params(23)+y(1)*params(24)+y(3)*params(25)+y(2)*params(26)+y(4)*params(27)+y(13)*params(28)+x(14));
    residual(15) = (y(16)) - (x(15)+y(1)*params(37)+params(35)*(y(14)-y(15))+params(36)*y(17)+y(18));
residual(16) = y(16);
    residual(17) = (y(17)) - (y(16));
    residual(18) = (y(18)) - (params(39)+y(1)*params(40)+y(3)*params(41)+y(2)*params(42)+y(4)*params(43)+y(5)*params(44)+y(6)*params(45)+y(7)*params(46)+y(8)*params(47)+y(9)*params(48)+y(10)*params(49)+y(11)*params(50)+y(12)*params(51)+y(13)*params(52)+y(14)*params(53));

end
