function [residual, T_order, T] = dynamic_resid(y, x, params, steady_state, T_order, T)
if nargin < 6
    T_order = -1;
    T = NaN(0, 1);
end
[T_order, T] = test_var_pac.sparse.dynamic_resid_tt(y, x, params, steady_state, T_order, T);
residual = NaN(9, 1);
    residual(1) = (y(10)) - (params(1)*y(1)-params(2)*(y(2)-y(3))+x(1));
    residual(2) = (y(11)) - (y(2)*params(3)+(1-params(3))*(y(3)*params(4)+y(1)*params(5))+x(2));
    residual(3) = (y(12)) - (y(3)*params(6)+y(1)*params(7)+x(3));
    residual(4) = (y(13)) - (params(8)*y(4)+y(1)*params(9)+y(2)*params(10)+y(3)*params(11)+x(4));
    residual(5) = (y(15)) - (y(6)+y(14));
    residual(6) = (y(16)) - (x(5)+y(10)*params(14)+params(12)*(y(4)-y(6))+params(13)*y(17)+y(18));
    residual(7) = (y(16)) - (y(15)-y(6));
    residual(8) = (y(17)) - (y(7));
    residual(9) = (y(18)) - (params(17)+y(1)*params(18)+y(2)*params(19)+y(3)*params(20)+y(4)*params(21));
end
