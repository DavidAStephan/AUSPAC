function [residual, T_order, T] = static_resid(y, x, params, T_order, T)
if nargin < 5
    T_order = -1;
    T = NaN(0, 1);
end
[T_order, T] = test_var_pac_multi.sparse.static_resid_tt(y, x, params, T_order, T);
residual = NaN(15, 1);
    residual(1) = (y(1)) - (y(1)*params(1)-params(2)*(y(2)-y(3))+x(1));
    residual(2) = (y(2)) - (y(2)*params(3)+(1-params(3))*(y(3)*params(4)+y(1)*params(5))+x(2));
    residual(3) = (y(3)) - (y(3)*params(6)+y(1)*params(7)+x(3));
    residual(4) = (y(4)) - (y(4)*params(8)+y(1)*params(9)+y(2)*params(10)+y(3)*params(11)+x(4));
    residual(5) = (y(5)) - (y(5)*params(12)+y(1)*params(13)+y(2)*params(14)+y(3)*params(15)+x(5));
    residual(6) = (y(7)) - (y(7)+y(6));
    residual(7) = (y(9)) - (y(9)+y(8));
    residual(8) = (y(10)) - (x(6)+y(1)*params(18)+params(16)*(y(4)-y(7))+params(17)*y(11)+y(15));
    residual(9) = (y(12)) - (x(7)+y(1)*params(21)+params(19)*(y(5)-y(9))+params(20)*y(13)+y(14));
residual(10) = y(10);
    residual(11) = (y(11)) - (y(10));
residual(12) = y(12);
    residual(13) = (y(13)) - (y(12));
    residual(14) = (y(14)) - (params(23)+y(1)*params(24)+y(2)*params(25)+y(3)*params(26)+y(4)*params(27)+y(5)*params(28));
    residual(15) = (y(15)) - (params(29)+y(1)*params(30)+y(2)*params(31)+y(3)*params(32)+y(4)*params(33)+y(5)*params(34));
end
