function [b, se, tstat, R2, rss, n] = ols_with_se(X, y)
%OLS_WITH_SE Plain OLS with classical Gaussian standard errors.
%
% Inputs:
%   X    - (T x k) regressor matrix (caller includes intercept if desired)
%   y    - (T x 1) dependent variable
%
% Output:
%   b    - coefficient vector (k x 1)
%   se   - classical standard errors (k x 1)
%   tstat - t-stats (k x 1)
%   R2   - R-squared (centred)
%   rss  - residual sum of squares
%   n    - number of obs after dropping NaN
valid = ~any(isnan([X, y]), 2);
X = X(valid, :);
y = y(valid);
n = length(y);
XtX = X' * X;
b = XtX \ (X' * y);
e = y - X * b;
rss = e' * e;
sigma2 = rss / (n - size(X, 2));
se = sqrt(diag(sigma2 * inv(XtX)));
tstat = b ./ se;
ybar = mean(y);
tss = (y - ybar)' * (y - ybar);
R2 = 1 - rss / tss;
end
