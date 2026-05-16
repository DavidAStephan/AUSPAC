function [residual, T_order, T] = dynamic_resid(y, x, params, steady_state, T_order, T)
if nargin < 6
    T_order = -1;
    T = NaN(0, 1);
end
[T_order, T] = aux_pQ.sparse.dynamic_resid_tt(y, x, params, steady_state, T_order, T);
residual = NaN(17, 1);
    residual(1) = (y(18)) - (params(2)*y(1)-params(3)*(y(3)-y(2))+params(1)*y(5)+x(1));
    residual(2) = (y(20)) - (y(3)*params(4)+(1-params(4))*(y(2)*params(5)+y(1)*params(6))+x(2));
    residual(3) = (y(19)) - (y(2)*params(7)+y(1)*params(8)+params(17)*(y(10)-y(8))+params(18)*(y(11)-y(8))+params(19)*y(12)+x(3));
    residual(4) = (y(21)) - (params(15)*y(4)+y(1)*params(16)+x(9));
    residual(5) = (y(22)) - (y(5)*params(9)+x(4));
    residual(6) = (y(23)) - (params(10)*y(6)+y(5)*params(11)+x(5));
    residual(7) = (y(24)) - (params(12)*y(7)+(1-params(12))*params(20)+x(6));
    residual(8) = (y(25)) - (y(8)*params(13)+(1-params(13))*params(21)+x(7));
    residual(9) = (y(26)) - (params(14)*y(9)+(1-params(14))*params(22)+x(8));
    residual(10) = (y(27)) - (y(10)*params(28)+params(21)*(1-params(28))+x(10));
    residual(11) = (y(28)) - (y(11)*params(29)+params(21)*(1-params(29))+x(11));
    residual(12) = (y(29)) - (y(12)*params(30)+x(12));
    residual(13) = (y(30)) - (params(23)*y(13)+y(1)*params(24)+y(3)*params(25)+y(2)*params(26)+y(4)*params(27)+x(13));
    residual(14) = (y(32)) - (x(14)+y(18)*params(33)+params(31)*(y(13)-y(14))+params(32)*y(33)+y(34));
    residual(15) = (y(32)) - (y(31)-y(14));
    residual(16) = (y(33)) - (y(15));
    residual(17) = (y(34)) - (params(35)+y(1)*params(36)+y(3)*params(37)+y(2)*params(38)+y(4)*params(39)+y(5)*params(40)+y(6)*params(41)+y(7)*params(42)+y(8)*params(43)+y(9)*params(44)+y(10)*params(45)+y(11)*params(46)+y(12)*params(47)+y(13)*params(48));
end
