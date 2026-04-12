function [residual, T_order, T] = static_resid(y, x, params, T_order, T)
if nargin < 5
    T_order = -1;
    T = NaN(0, 1);
end
[T_order, T] = test_var_pac.sparse.static_resid_tt(y, x, params, T_order, T);
residual = NaN(9, 1);
    residual(1) = (y(1)) - (y(1)*params(1)-params(2)*(y(2)-y(3))+x(1));
    residual(2) = (y(2)) - (y(2)*params(3)+(1-params(3))*(y(3)*params(4)+y(1)*params(5))+x(2));
    residual(3) = (y(3)) - (y(3)*params(6)+y(1)*params(7)+x(3));
    residual(4) = (y(4)) - (y(4)*params(8)+y(1)*params(9)+y(2)*params(10)+y(3)*params(11)+x(4));
    residual(5) = (y(6)) - (y(6)+y(5));
    residual(6) = (y(7)) - (x(5)+y(1)*params(14)+params(12)*(y(4)-y(6))+params(13)*y(8)+y(9));
residual(7) = y(7);
    residual(8) = (y(8)) - (y(7));
    residual(9) = (y(9)) - (params(17)+y(1)*params(18)+y(2)*params(19)+y(3)*params(20)+y(4)*params(21));
end
