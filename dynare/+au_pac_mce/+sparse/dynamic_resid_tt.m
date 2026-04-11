function [T_order, T] = dynamic_resid_tt(y, x, params, steady_state, T_order, T)
if T_order >= 0
    return
end
T_order = 0;
if size(T, 1) < 6
    T = [T; NaN(6 - size(T, 1), 1)];
end
T(1) = params(137)^2;
T(2) = params(140)*T(1);
T(3) = params(137)^3;
T(4) = params(144)*T(3);
T(5) = params(153)*params(137)^4;
T(6) = params(154)*params(137)^5;
end
