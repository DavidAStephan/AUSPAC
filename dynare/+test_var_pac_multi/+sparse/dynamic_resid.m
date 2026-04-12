function [residual, T_order, T] = dynamic_resid(y, x, params, steady_state, T_order, T)
if nargin < 6
    T_order = -1;
    T = NaN(0, 1);
end
[T_order, T] = test_var_pac_multi.sparse.dynamic_resid_tt(y, x, params, steady_state, T_order, T);
residual = NaN(15, 1);
    residual(1) = (y(16)) - (params(1)*y(1)-params(2)*(y(2)-y(3))+x(1));
    residual(2) = (y(17)) - (y(2)*params(3)+(1-params(3))*(y(3)*params(4)+y(1)*params(5))+x(2));
    residual(3) = (y(18)) - (y(3)*params(6)+y(1)*params(7)+x(3));
    residual(4) = (y(19)) - (params(8)*y(4)+y(1)*params(9)+y(2)*params(10)+y(3)*params(11)+x(4));
    residual(5) = (y(20)) - (params(12)*y(5)+y(1)*params(13)+y(2)*params(14)+y(3)*params(15)+x(5));
    residual(6) = (y(22)) - (y(7)+y(21));
    residual(7) = (y(24)) - (y(9)+y(23));
    residual(8) = (y(25)) - (x(6)+y(16)*params(18)+params(16)*(y(4)-y(7))+params(17)*y(26)+y(30));
    residual(9) = (y(27)) - (x(7)+y(16)*params(21)+params(19)*(y(5)-y(9))+params(20)*y(28)+y(29));
    residual(10) = (y(25)) - (y(22)-y(7));
    residual(11) = (y(26)) - (y(10));
    residual(12) = (y(27)) - (y(24)-y(9));
    residual(13) = (y(28)) - (y(12));
    residual(14) = (y(29)) - (params(23)+y(1)*params(24)+y(2)*params(25)+y(3)*params(26)+y(4)*params(27)+y(5)*params(28));
    residual(15) = (y(30)) - (params(29)+y(1)*params(30)+y(2)*params(31)+y(3)*params(32)+y(4)*params(33)+y(5)*params(34));
end
