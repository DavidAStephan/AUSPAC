function pv_series = compute_pv_term(Phi, chi, target_idx, ZL_full, k_order)
%COMPUTE_PV_TERM Closed-form PV operator applied to a state variable.
%
% Returns the time series of PV (or PV^k_order) of the variable at
% position target_idx in the state vector:
%
%   PV(x)_{t|t-1}   = e_target' · (I - chi*Phi)^{-1} · chi*Phi · z_{t-1}
%   PV^2(x)_{t|t-1} = e_target' · ((I - chi*Phi)^{-1} · chi*Phi)^2 · z_{t-1}
%
% Inputs:
%   Phi          - k x k VAR(1) transition matrix
%   chi          - scalar discount factor in [0, 1)
%   target_idx   - integer position of target variable in z
%   ZL_full      - nObs x k matrix of z_{t-1} aligned to sample
%   k_order      - 1 for PV, 2 for PV^2 (default 1)
%
% Output:
%   pv_series    - nObs x 1 column vector of PV term at each t

if nargin < 5, k_order = 1; end

k = size(Phi, 1);
e_target = zeros(k, 1);
e_target(target_idx) = 1;

if abs(chi) < 1e-10
    pv_series = zeros(size(ZL_full, 1), 1);
    return
end

% chi might be slightly out of stable range -- guard
M = eye(k) - chi * Phi;
if rcond(M) < 1e-10
    warning('compute_pv_term:near_singular', ...
        'I - chi*Phi nearly singular (chi=%.4f, rho=%.4f)', chi, max(abs(eig(Phi))));
    % Fall back to truncated PV
    pv_series = compute_pv_truncated(Phi, chi, target_idx, ZL_full, k_order, 50);
    return
end

PV_op = M \ (chi * Phi);
operator = PV_op^k_order;

% pv_series(t) = e_target' * operator * z_{t-1}
% Broadcast: (operator * z_{t-1}')' gives nObs x k, then pick column target_idx
projected = (operator * ZL_full')';
pv_series = projected(:, target_idx);
end

function pv = compute_pv_truncated(Phi, chi, target_idx, ZL_full, k_order, n_terms)
% Fallback: truncated sum sum_{h=1..n_terms} (chi Phi)^h
k = size(Phi, 1);
e_target = zeros(k, 1);
e_target(target_idx) = 1;
op = zeros(k);
M = chi * Phi;
M_pow = eye(k);
for h = 1:n_terms
    M_pow = M_pow * M;
    op = op + M_pow;
end
operator = op ^ k_order;
projected = (operator * ZL_full')';
pv = projected(:, target_idx);
end
