function [residual, T_order, T] = static_resid(y, x, params, T_order, T)
if nargin < 5
    T_order = -1;
    T = NaN(0, 1);
end
[T_order, T] = aux_business_inv.sparse.static_resid_tt(y, x, params, T_order, T);
residual = NaN(19, 1);
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
    residual(13) = (y(13)) - (y(13)*params(26)+y(1)*params(27)+y(2)*params(28)+y(4)*params(29)+x(13));
    residual(14) = (y(14)) - (y(14)*params(30)+y(3)*params(31)+x(14));
    residual(15) = (y(16)) - (x(15)+y(1)*params(35)+params(32)*(y(13)-y(15))+params(33)*y(17)+params(34)*y(18)+y(19));
residual(16) = y(16);
    residual(17) = (y(17)) - (y(16));
    residual(18) = (y(18)) - (y(17));
    residual(19) = (y(19)) - (params(37)+y(1)*params(38)+y(3)*params(39)+y(2)*params(40)+y(4)*params(41)+y(5)*params(42)+y(6)*params(43)+y(7)*params(44)+y(8)*params(45)+y(9)*params(46)+y(10)*params(47)+y(11)*params(48)+y(12)*params(49)+y(13)*params(50)+y(14)*params(51));
end
