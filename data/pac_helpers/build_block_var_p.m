function [Phi_comp, state_names_comp, ZL_full_comp, n_valid] = build_block_var_p(block_name, L2, base, sample_idx, p_lags)
%BUILD_BLOCK_VAR_P Block-specific VAR(p) Phi in companion form.
%
% Same as build_block_var but allows VAR(p) for p >= 1.  Returns the
% companion-form (k*p)x(k*p) Phi matrix and a (k*p)-dimensional state
% [z_t; z_{t-1}; ...; z_{t-p+1}].
%
% For p=1: same result as build_block_var.m.
% For p=2: doubles the state dimension; estimates z_t = A_1 z_{t-1} + A_2 z_{t-2} + e
%          and arranges as Phi_comp = [A_1 A_2; I 0].
%
% Used by compute_pv_term: the PV operator (I - chi*Phi_comp)^{-1} * chi*Phi_comp
% is applied to z_lag_companion = [z_{t-1}; z_{t-2}] etc.

if nargin < 5, p_lags = 1; end

% Call original build_block_var to get the SINGLE-LAG state and Phi
[Phi_1, state_names, ZL_full_1, state_data, n_valid_1] = build_block_var(block_name, L2, base, sample_idx);

if p_lags == 1
    Phi_comp = Phi_1;
    state_names_comp = state_names;
    ZL_full_comp = ZL_full_1;
    n_valid = n_valid_1;
    return
end

% For VAR(p>1): re-estimate using p lags
k = size(state_data, 2);
valid = ~any(isnan(state_data), 2);
Z = state_data(valid, :);

% Need at least p+1 valid obs to estimate.
if size(Z, 1) <= p_lags
    error('Not enough valid obs (%d) for VAR(%d)', size(Z, 1), p_lags);
end

% Build X_p = [Z_{t-1}, Z_{t-2}, ..., Z_{t-p}] (n-p) x (k*p)
n_eff = size(Z, 1) - p_lags;
X_p = zeros(n_eff, k * p_lags);
for ll = 1:p_lags
    X_p(:, (ll-1)*k+1 : ll*k) = Z((p_lags - ll + 1) : (p_lags - ll + n_eff), :);
end
Z_t = Z(p_lags + 1 : end, :);    % LHS

% OLS lag-by-lag (each equation in z_t)
A_all = ((X_p' * X_p) \ (X_p' * Z_t))';   % k x (k*p) -- rows are equations

% Companion form: Phi_comp = [A_1 A_2 ... A_p;
%                              I   0  ...  0;
%                              0   I  ...  0;
%                              ...;
%                              0   0  ...  I  0]
% Top row: A_1, A_2, ..., A_p (each k x k)
% Below: identity shifts for the lagged state
n_state = k * p_lags;
Phi_comp = zeros(n_state, n_state);
Phi_comp(1:k, :) = A_all;     % top row block
for jj = 1:(p_lags - 1)
    Phi_comp(jj*k + 1 : (jj+1)*k, (jj-1)*k + 1 : jj*k) = eye(k);
end

% State names: z_t names, then z_{t-1} (suffix _l1), z_{t-2} (_l2), etc.
state_names_comp = state_names;
for jj = 1:(p_lags - 1)
    state_names_comp = [state_names_comp, ...
        cellfun(@(s) sprintf('%s_l%d', s, jj), state_names, 'UniformOutput', false)];
end

% Build companion-form ZL_full: at time t, the companion state is
% [z_{t-1}; z_{t-2}; ...; z_{t-p}].  So for each row of the full sample,
% we collect p prior values of the original state.
nObs = size(state_data, 1);
ZL_full_comp = nan(nObs, n_state);
for ii = (p_lags + 1) : nObs
    if any(isnan(state_data(ii - p_lags : ii - 1, :)), 'all')
        continue
    end
    block = [];
    for ll = 1:p_lags
        block = [block, state_data(ii - ll, :)];   % z_{t-ll}
    end
    ZL_full_comp(ii, :) = block;
end

n_valid = sum(~any(isnan(ZL_full_comp), 2));
end
