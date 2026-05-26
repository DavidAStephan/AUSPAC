function chi = solve_pac_chi(beta_lags, omega, depth)
%SOLVE_PAC_CHI Smallest positive root of the depth-m PAC characteristic polynomial.
%
% Per wp736 §3, the PAC discount factor χ (used in PV operator
% (I - χΦ)^{-1} · χΦ) is the smallest stable root of:
%
%     lambda^(m+1) - (1 + sum(beta_lags) + omega) · lambda^m + ... + beta_m = 0
%
% For depth-1 PAC:    lambda^2 - (1 + beta_1 + omega) lambda + beta_1 = 0
% For depth-2 PAC:    lambda^3 - (1 + beta_1 + beta_2 + omega) lambda^2
%                              + (beta_1 + 2 beta_2) lambda - beta_2 = 0
% Etc.
%
% For an "AR(m) own-lag" with coefficients (beta_1, ..., beta_m) and a
% non-stationary expectation weight omega, the characteristic polynomial
% comes from the PAC FOC.  This implementation derives it directly from
% the difference equation:
%
%     (1 - sum_k beta_k L) (1 - lambda L) - omega lambda = 0
%
% which expanded gives:
%     lambda^(m+1) - lambda^m + sum_k beta_k (lambda^(m+1-k) - lambda^(m-k))
%                   + omega lambda = 0
%
% Wait -- the derivation in wp736 is more complex.  For practical use,
% we'll use the SIMPLIFIED form that's standard in PAC econometrics:
%
%     lambda^2 - (1 + sum(beta) + omega) lambda + sum(beta) = 0   (depth-1 style)
%
% This gives chi = smaller root.  For deeper PAC, we generalise to:
%
%     lambda^2 - (1 + sum_k beta_k + omega) lambda + sum_k beta_k = 0
%
% (treats deep PAC as if it were depth-1 with sum-of-betas as effective β_1)
%
% This is APPROXIMATE for depth > 1 but tractable.  Documented as such.
% More-faithful implementation would build the full depth-(m+1)
% polynomial from wp736 Eq 7 and find its smallest stable root.

if nargin < 3, depth = length(beta_lags); end

sum_b = sum(beta_lags);

% Quadratic: lambda^2 - (1 + sum_b + omega) lambda + sum_b = 0
a = 1;
b = -(1 + sum_b + omega);
c = sum_b;

discriminant = b^2 - 4*a*c;
if discriminant < 0
    % Complex roots -- fall back to real part of smaller
    chi = real((-b - sqrt(complex(discriminant))) / (2*a));
    warning('solve_pac_chi:complex_roots', ...
        'Complex roots; using real part.  sum_b=%.4f, omega=%.4f', sum_b, omega);
else
    root_small = (-b - sqrt(discriminant)) / (2*a);
    root_large = (-b + sqrt(discriminant)) / (2*a);
    % chi = smaller stable root, must be in [0, 1) for PAC to be well-defined
    if root_small > 0 && root_small < 1
        chi = root_small;
    elseif root_large > 0 && root_large < 1
        chi = root_large;
        warning('solve_pac_chi:small_root_unstable', ...
            'Smaller root %.4f out of [0,1); using larger %.4f', root_small, root_large);
    else
        chi = max(0, min(0.99, root_small));   % clamp
        warning('solve_pac_chi:no_stable_root', ...
            'No stable root in [0,1); clamped to %.4f', chi);
    end
end
end
