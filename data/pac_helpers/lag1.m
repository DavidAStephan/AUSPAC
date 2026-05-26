function y = lag1(x)
%LAG1 First-lag operator: y(t) = x(t-1), with NaN at the first row.
y = [NaN; x(1:end-1)];
end
