function [residual, T_order, T] = dynamic_resid(y, x, params, steady_state, T_order, T)
if nargin < 6
    T_order = -1;
    T = NaN(0, 1);
end
[T_order, T] = au_esat_est.sparse.dynamic_resid_tt(y, x, params, steady_state, T_order, T);
residual = NaN(5, 1);
    residual(1) = (y(6)) - (params(3)*y(9)+params(1)*y(1)-params(2)*(y(2)-y(3))+x(1));
    residual(2) = (y(7)) - (y(2)*params(4)+(1-params(4))*(y(3)*params(5)+y(1)*params(6))+x(2));
    residual(3) = (y(8)) - (y(3)*params(7)+y(1)*params(8)+x(3));
    residual(4) = (y(9)) - (params(9)*y(4)+x(4));
    residual(5) = (y(10)) - (params(10)*y(5)+y(4)*params(11)+x(5));
end
