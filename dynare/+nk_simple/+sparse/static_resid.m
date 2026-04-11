function [residual, T_order, T] = static_resid(y, x, params, T_order, T)
if nargin < 5
    T_order = -1;
    T = NaN(0, 1);
end
[T_order, T] = nk_simple.sparse.static_resid_tt(y, x, params, T_order, T);
residual = NaN(3, 1);
    residual(1) = (y(1)) - (y(1)-params(1)*(y(3)-y(2)));
    residual(2) = (y(2)) - (y(2)*params(3)+y(1)*params(2));
    residual(3) = (y(3)) - (y(3)*params(4)+(1-params(4))*(y(2)*params(5)+y(1)*params(6))+x(1));
end
