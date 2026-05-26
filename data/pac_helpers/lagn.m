function y = lagn(x, n)
%LAGN nth-lag operator: y(t) = x(t-n), with NaN at the first n rows.
y = [nan(n, 1); x(1:end-n)];
end
