function [lhs, rhs] = dynamic_resid(y, x, params, steady_state)
T = NaN(0, 1);
lhs = NaN(3, 1);
rhs = NaN(3, 1);
lhs(1) = y(4);
rhs(1) = y(7)-params(1)*(y(6)-y(8));
lhs(2) = y(5);
rhs(2) = y(8)*params(3)+y(4)*params(2);
lhs(3) = y(6);
rhs(3) = params(4)*y(3)+(1-params(4))*(y(5)*params(5)+y(4)*params(6))+x(1);
end
