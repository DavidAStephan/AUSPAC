function [lhs, rhs] = dynamic_resid(y, x, params, steady_state)
T = NaN(0, 1);
lhs = NaN(5, 1);
rhs = NaN(5, 1);
lhs(1) = y(6);
rhs(1) = params(3)*y(9)+params(1)*y(1)-params(2)*(y(2)-y(3))+x(1);
lhs(2) = y(7);
rhs(2) = y(2)*params(4)+(1-params(4))*(y(3)*params(5)+y(1)*params(6))+x(2);
lhs(3) = y(8);
rhs(3) = y(3)*params(7)+y(1)*params(8)+x(3);
lhs(4) = y(9);
rhs(4) = params(9)*y(4)+x(4);
lhs(5) = y(10);
rhs(5) = params(10)*y(5)+y(4)*params(11)+x(5);
end
