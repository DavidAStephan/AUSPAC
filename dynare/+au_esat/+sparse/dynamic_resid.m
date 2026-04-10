function [residual, T_order, T] = dynamic_resid(y, x, params, steady_state, T_order, T)
if nargin < 6
    T_order = -1;
    T = NaN(0, 1);
end
[T_order, T] = au_esat.sparse.dynamic_resid_tt(y, x, params, steady_state, T_order, T);
residual = NaN(11, 1);
    residual(1) = (y(20)) - (y(13)-y(17));
    residual(2) = (y(21)) - (y(14)-y(18));
    residual(3) = (y(22)) - (y(16)-y(19));
    residual(4) = (y(12)) - (params(1)*y(15)+params(2)*y(1)-params(3)*(y(9)-y(10))+x(1));
    residual(5) = (y(20)) - (y(9)*params(4)+(1-params(4))*(y(10)*params(5)+y(1)*params(6))+x(2));
    residual(6) = (y(21)) - (y(10)*params(7)+y(1)*params(8)+x(3));
    residual(7) = (y(15)) - (params(9)*y(4)+x(4));
    residual(8) = (y(22)) - (params(10)*y(11)+y(4)*params(11)+x(5));
    residual(9) = (y(17)) - (params(12)*y(6)+(1-params(12))*params(15)+x(6));
    residual(10) = (y(18)) - (params(13)*y(7)+(1-params(13))*params(16)+x(7));
    residual(11) = (y(19)) - (params(14)*y(8)+(1-params(14))*params(17)+x(8));
end
