function [T_order, T] = dynamic_resid_tt(y, x, params, steady_state, T_order, T)
if T_order >= 0
    return
end
T_order = 0;
if size(T, 1) < 6
    T = [T; NaN(6 - size(T, 1), 1)];
end
T(1) = params(134)^2;
T(2) = params(137)*T(1);
T(3) = params(134)^3;
T(4) = params(141)*T(3);
T(5) = params(150)*params(134)^4;
T(6) = params(151)*params(134)^5;
end
