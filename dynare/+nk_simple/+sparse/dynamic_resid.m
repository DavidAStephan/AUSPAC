function [residual, T_order, T] = dynamic_resid(y, x, params, steady_state, T_order, T)
if nargin < 6
    T_order = -1;
    T = NaN(0, 1);
end
[T_order, T] = nk_simple.sparse.dynamic_resid_tt(y, x, params, steady_state, T_order, T);
residual = NaN(3, 1);
    residual(1) = (y(4)) - (y(7)-params(1)*(y(6)-y(8)));
    residual(2) = (y(5)) - (y(8)*params(3)+y(4)*params(2));
    residual(3) = (y(6)) - (params(4)*y(3)+(1-params(4))*(y(5)*params(5)+y(4)*params(6))+x(1));
end
