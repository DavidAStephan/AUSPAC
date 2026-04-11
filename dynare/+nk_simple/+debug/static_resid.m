function [lhs, rhs] = static_resid(y, x, params)
T = NaN(0, 1);
lhs = NaN(3, 1);
rhs = NaN(3, 1);
lhs(1) = y(1);
rhs(1) = y(1)-params(1)*(y(3)-y(2));
lhs(2) = y(2);
rhs(2) = y(2)*params(3)+y(1)*params(2);
lhs(3) = y(3);
rhs(3) = y(3)*params(4)+(1-params(4))*(y(2)*params(5)+y(1)*params(6))+x(1);
end
