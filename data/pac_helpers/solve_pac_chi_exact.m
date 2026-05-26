function chi = solve_pac_chi_exact(beta_lags, omega, depth)
%SOLVE_PAC_CHI_EXACT Smallest stable root of depth-m PAC characteristic
%polynomial (wp736 §3 Eq 7 form).
%
% For depth-m PAC equation Δy = b_0 (y* - y) + Σ_{k=1..m} b_k Δy_{t-k} + ...
% the characteristic polynomial in the lag operator L is
%
%   (1 - b_1 L - b_2 L^2 - ... - b_m L^m)(1 - chi L) - omega·chi·L^(m+1) = 0
%
% Expanding gives a polynomial of degree m+1 in chi (with L=1 substituted
% via the FOC manipulation).  In standard form:
%
%   chi^(m+1) - (1 + Σb + omega) chi^m + α_m chi^(m-1) + ... + α_0 = 0
%
% where the α_k coefficients come from the depth-m structure.
%
% Simpler practical form (per wp736 derivation): the discount factor
% χ satisfies
%
%   χ^(m+1) + sum_{k=0..m-1} c_k χ^k = 0
%
% where the c_k come from the AR-polynomial coefficients.  We construct
% the polynomial coefficients numerically and call MATLAB's roots().
%
% Inputs:
%   beta_lags  - column vector [b_1; b_2; ...; b_m]
%   omega      - calibrated non-stationary expectations weight
%   depth      - m (number of own lags; should equal length(beta_lags))
%
% Output:
%   chi        - smallest stable root in [0, 1)

if nargin < 3, depth = length(beta_lags); end
beta_lags = beta_lags(:);
if depth ~= length(beta_lags)
    error('depth (%d) != length(beta_lags) (%d)', depth, length(beta_lags));
end

% The depth-m PAC characteristic polynomial (from wp736 §3 derivation) is:
%
%   chi^(m+1) - (1 + Σb + omega) chi^m + sum_{k=1..m} (Σ_{j>=k} b_j) chi^(m-k) = 0
%
% Build coefficient vector for MATLAB roots() (highest power first):
%   p = [1, -(1 + Σb + omega), Σ_{j>=1}b_j, Σ_{j>=2}b_j, ..., b_m]
% That's m+2 coefficients for a degree-(m+1) polynomial.

sum_b = sum(beta_lags);
p = zeros(depth + 2, 1);
p(1) = 1;
p(2) = -(1 + sum_b + omega);
for k = 1:depth
    p(2 + k) = sum(beta_lags(k:end));
end

% For depth=1: p = [1; -(1+b1+omega); b_1]  — gives the depth-1 quadratic
%   chi^2 - (1+b1+omega) chi + b1 = 0   ✓ matches solve_pac_chi.m

r = roots(p);

% Pick smallest real positive root in [0, 1).
chi = NaN;
real_roots = r(abs(imag(r)) < 1e-8);
real_roots = real(real_roots);
% Sort by magnitude, take smallest in [0, 1)
real_roots_pos = sort(real_roots(real_roots > 0 & real_roots < 1));
if ~isempty(real_roots_pos)
    chi = real_roots_pos(1);
else
    % Fallback: use the simplified depth-1 form
    a = 1;
    b = -(1 + sum_b + omega);
    c = sum_b;
    disc = b^2 - 4*a*c;
    if disc >= 0
        chi = max(0, min(0.99, (-b - sqrt(disc)) / (2*a)));
    else
        chi = 0;
    end
    warning('solve_pac_chi_exact:fallback', ...
        'No real root in [0,1); using depth-1 fallback chi=%.4f', chi);
end
end
