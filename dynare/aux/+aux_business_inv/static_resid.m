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
    T = aux_business_inv.static_resid_tt(T, y, x, params);
end
residual = zeros(20, 1);
    residual(1) = (y(1)) - (y(1)*params(2)-params(3)*(y(3)-y(2))+params(1)*y(5)+x(1));
    residual(2) = (y(3)) - (y(3)*params(4)+(1-params(4))*(y(2)*params(5)+y(1)*params(6))+x(2));
    residual(3) = (y(2)) - (y(2)*params(7)+y(1)*params(8)+params(17)*(y(10)-y(8))+params(18)*(y(11)-y(8))+params(19)*y(12)+x(3));
    residual(4) = (y(4)) - (y(4)*params(15)+y(1)*params(16)+x(9));
    residual(5) = (y(5)) - (y(5)*params(9)+x(4));
    residual(6) = (y(6)) - (y(6)*params(10)+y(5)*params(11)+x(5));
    residual(7) = (y(7)) - (y(7)*params(12)+(1-params(12))*params(20)+x(6));
    residual(8) = (y(8)) - (y(8)*params(13)+(1-params(13))*params(21)+x(7));
    residual(9) = (y(9)) - (y(9)*params(14)+(1-params(14))*params(22)+x(8));
    residual(10) = (y(10)) - (y(10)*params(23)+params(21)*(1-params(23))+x(10));
    residual(11) = (y(11)) - (y(11)*params(24)+params(21)*(1-params(24))+x(11));
    residual(12) = (y(12)) - (y(12)*params(25)+x(12));
    residual(13) = (y(13)) - (y(13)*params(26)+x(13));
    residual(14) = (y(14)) - (y(14)*params(29)+y(1)*params(30)+y(2)*params(31)+y(4)*params(32)+y(13)*params(27)+x(14));
    residual(15) = (y(15)) - (y(15)*params(33)+y(3)*params(34)+y(13)*params(28)+x(15));
    residual(16) = (y(17)) - (x(16)+y(1)*params(38)+params(35)*(y(14)-y(16))+params(36)*y(18)+params(37)*y(19)+y(20));
residual(17) = y(17);
    residual(18) = (y(18)) - (y(17));
    residual(19) = (y(19)) - (y(18));
    residual(20) = (y(20)) - (params(40)+y(1)*params(41)+y(3)*params(42)+y(2)*params(43)+y(4)*params(44)+y(5)*params(45)+y(6)*params(46)+y(7)*params(47)+y(8)*params(48)+y(9)*params(49)+y(10)*params(50)+y(11)*params(51)+y(12)*params(52)+y(13)*params(53)+y(14)*params(54)+y(15)*params(55));

end
