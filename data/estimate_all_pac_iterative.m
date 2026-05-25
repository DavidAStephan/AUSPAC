%% estimate_all_pac_iterative.m
%
% Proper iterative-OLS partial L2 wp1044 replication for ALL 5 PAC blocks
% (consumption, VA-price, employment, business inv, housing inv), following
% the FR-BDF technique (wp736 §4, wp1044 §2.2 step 4).
%
% Architecture (identical to estimate_consumption_pac_iterative.m, extended
% to 5 blocks):
%
%   Step A: Build a single auxiliary VAR(1) state z including the
%           HP-gap of each block's LHS variable plus the standard
%           E-SAT-like observables.  OLS lag-by-lag.
%
%   Step B: For each block, compute PAC expectation projection given
%           current beta:
%               PAC_exp_t = e_target' * (I - chi*Phi)^{-1} * chi*Phi *
%                           z_{t-1}
%           chi = sum(beta_lag_coefs) + omega_block (calibrated).
%
%   Step C: OLS on PAC short-run equation with PAC_exp imposed at
%           coefficient = 1 (subtract from LHS before OLS).
%
%   Step D: Update beta; iterate until ||delta_beta|| < tol.
%
% Block specifications (wp1044 / AUSPAC nomenclature):
%
%   Block       LHS             Depth   omega   Trend regressor
%   --------    ------------    -----   -----   ---------------
%   c           dln_c           1       0.00    dy_bar_gap (Δȳ)
%   pQ          pi_au           1       0.46    pi_Q_bar (π̄*_Q)
%   n           dln_n           4       0.30    dn_bar (Δn̄*_S)
%   ib          dln_ib          2       0.35    dq_bar (Δq̄)
%   ih          dln_ih          2       0.30    dlogIH_bar (Δlog Ī*_H)
%
% Auxiliary VAR state (9 variables):
%   z = [yhat_au, pi_au, i_au, i_10y, y_H_gap, c_gap, n_gap, ib_gap, ih_gap]
%
% Caveats vs wp1044 EXACT:
%   - 9-var VAR(1) vs wp1044's larger E-SAT VAR
%   - OLS lag-by-lag (no Minnesota prior)
%   - chi = Σβ_lags + ω (simplified depth-agnostic; exact form needs
%     numerical solution of characteristic polynomial roots)
%   - Block targets approximated by HP gaps of own LHS series

clear; clc;
fprintf('=== Iterative OLS for ALL 5 PAC blocks (faithful wp1044 replication) ===\n\n');

projectdir = fullfile(fileparts(mfilename('fullpath')), '..');

%% Load
D = load(fullfile(projectdir, 'dynare', 'estimation_data.mat'));
T_ext = readtable(fullfile(projectdir, 'data', 'extended_dataset.csv'));
TS = load(fullfile(projectdir, 'data', 'trend_series.mat'));

sample_idx = 2:123;
nObs = length(sample_idx);

yhat_au    = D.yhat_au;
pi_au      = D.pi_au;
i_au       = D.i_au;
i_10y      = D.i_10y;
dln_c      = D.dln_c;
dln_ib     = D.dln_ib;
dy_bar_gap = D.dy_bar_gap;

% From extended dataset
y_H_gap          = demean(T_ext.au_wt_H_real_gap(sample_idx));
au_cons          = T_ext.au_consumption(sample_idx);
au_emp           = T_ext.au_employment(sample_idx);
au_gfcf_ib_obs   = T_ext.au_gfcf_nondwelling(sample_idx);
au_gfcf_ih_obs   = T_ext.au_gfcf_dwelling(sample_idx);

% LHS variables (Δlog levels, demeaned, q/q %)
dln_n  = demean([NaN; diff(log(au_emp))]            * 100);
dln_ih = demean([NaN; diff(log(au_gfcf_ih_obs))]    * 100);

% HP-gap variables for the PAC targets (q/q % scale, demeaned)
c_gap  = 100 * demean(make_hp_gap(log(au_cons),         1600));
n_gap  = 100 * demean(make_hp_gap(log(au_emp),          1600));
ib_gap = 100 * demean(make_hp_gap(log(au_gfcf_ib_obs),  1600));
ih_gap = 100 * demean(make_hp_gap(log(au_gfcf_ih_obs),  1600));

% Trend regressors from trend_series.mat (aligned, demeaned, q/q %)
supply_dates = TS.dates;
base_dates   = datetime(T_ext.date);
sample_base  = base_dates(sample_idx);

align_idx = nan(nObs, 1);
for i = 1:nObs
    m = find(year(supply_dates) == year(sample_base(i)) & ...
             quarter(supply_dates) == quarter(sample_base(i)), 1);
    if ~isempty(m), align_idx(i) = m; end
end
extr = @(field) demean(extract_aligned(TS.(field), align_idx) * 100);

dq_bar     = extr('dlog_qbar');
dlog_rkb   = extr('dlog_rkb_bar');
dn_bar     = extr('dlog_nbar');
pi_Q_bar   = extr('pi_Q_bar');
dlogIH_bar = extr('dlog_IHbar');

%% Build auxiliary VAR(1) -- single state for all blocks
state_names = {'yhat_au', 'pi_au', 'i_au', 'i_10y', 'y_H_gap', ...
               'c_gap', 'n_gap', 'ib_gap', 'ih_gap'};
Z = [yhat_au, pi_au, i_au, i_10y, y_H_gap, c_gap, n_gap, ib_gap, ih_gap];
k = size(Z, 2);

valid_Z = ~any(isnan(Z), 2);
Z_use = Z(valid_Z, :);
Z_lag = Z_use(1:end-1, :);
Z_t   = Z_use(2:end, :);
Phi = ((Z_lag' * Z_lag) \ (Z_lag' * Z_t))';
rho_Phi = max(abs(eig(Phi)));
fprintf('Auxiliary VAR(1) state: [%s]\n', strjoin(state_names, ', '));
fprintf('Phi spectral radius: %.4f, n_obs in VAR: %d\n\n', rho_Phi, size(Z_use, 1));

% Build ZL_full (z_{t-1}) at the full sample
ZL_full = nan(nObs, k);
v_idx = find(valid_Z);
for ii = 2:length(v_idx)
    ZL_full(v_idx(ii), :) = Z_use(ii-1, :);
end
e = eye(k);

%% Define block specs

% Idx lookups
idx = struct();
idx.yhat = find(strcmp(state_names, 'yhat_au'));
idx.pi   = find(strcmp(state_names, 'pi_au'));
idx.i10  = find(strcmp(state_names, 'i_10y'));
idx.c    = find(strcmp(state_names, 'c_gap'));
idx.n    = find(strcmp(state_names, 'n_gap'));
idx.ib   = find(strcmp(state_names, 'ib_gap'));
idx.ih   = find(strcmp(state_names, 'ih_gap'));

% Each block: target_idx + omega + LHS + LHS lags + trend regressor + label
blocks = {};
blocks{end+1} = struct('name','consumption', 'LHS', dln_c, ...
    'target_idx', idx.c, 'omega', 0.00, 'depth', 1, ...
    'trend_lag', lag1(dy_bar_gap), 'trend_name', 'dy_bar_gap', ...
    'ecm_proxy_lag', lag1(c_gap), 'ecm_name', 'c_gap');
blocks{end+1} = struct('name','VA-price',   'LHS', pi_au, ...
    'target_idx', idx.pi, 'omega', 0.46, 'depth', 1, ...
    'trend_lag', lag1(pi_Q_bar), 'trend_name', 'pi_Q_bar', ...
    'ecm_proxy_lag', lag1(yhat_au), 'ecm_name', 'yhat_au');
blocks{end+1} = struct('name','employment', 'LHS', dln_n, ...
    'target_idx', idx.n, 'omega', 0.30, 'depth', 4, ...
    'trend_lag', lag1(dn_bar), 'trend_name', 'dn_bar', ...
    'ecm_proxy_lag', lag1(n_gap), 'ecm_name', 'n_gap');
blocks{end+1} = struct('name','business inv','LHS', dln_ib, ...
    'target_idx', idx.ib, 'omega', 0.35, 'depth', 2, ...
    'trend_lag', lag1(dq_bar), 'trend_name', 'dq_bar', ...
    'ecm_proxy_lag', lag1(ib_gap), 'ecm_name', 'ib_gap');
blocks{end+1} = struct('name','housing inv','LHS', dln_ih, ...
    'target_idx', idx.ih, 'omega', 0.30, 'depth', 2, ...
    'trend_lag', lag1(dlogIH_bar), 'trend_name', 'dlogIH_bar', ...
    'ecm_proxy_lag', lag1(ih_gap), 'ecm_name', 'ih_gap');

%% Run iterative OLS for each block
max_iter = 50;
tol = 1e-4;

n_blocks = length(blocks);
results = cell(n_blocks, 1);

for j = 1:n_blocks
    blk = blocks{j};
    fprintf('========================================================\n');
    fprintf('Block: %s  (depth=%d, omega=%.2f)\n', blk.name, blk.depth, blk.omega);
    fprintf('  LHS = %s_t,  target = %s,  trend regressor = %s\n', ...
        blk.name, state_names{blk.target_idx}, blk.trend_name);
    fprintf('========================================================\n');

    % Pre-build LHS lags
    LHS_lags = nan(nObs, blk.depth);
    for d = 1:blk.depth
        LHS_lags(:, d) = lagn(blk.LHS, d);
    end

    % Initial beta_lags + beta_trend + beta_0_ECM
    beta_lags  = 0.05 * ones(blk.depth, 1);   % small initial guesses
    beta_trend = 0.50;
    beta_0     = 0.10;

    history = [];
    for iter = 1:max_iter
        % chi = sum(beta_lags) + omega (depth-agnostic simplification)
        chi = sum(beta_lags) + blk.omega;

        if abs(chi) < 1e-8
            PV_op = zeros(k);
        else
            % Closed-form forward expectation operator
            PV_op = (eye(k) - chi * Phi) \ (chi * Phi);
        end

        % PAC expectation: e_target' * PV_op * z_{t-1}
        PAC_exp_t = (e(:, blk.target_idx)' * PV_op * ZL_full')';

        % Imposed at coef=1: subtract from LHS
        LHS_adj = blk.LHS - PAC_exp_t;

        % OLS: intercept + ECM proxy + LHS lags + trend regressor
        X = [ones(nObs, 1), blk.ecm_proxy_lag, LHS_lags, blk.trend_lag];
        [b, ~, ~, ~, ~, ~] = ols(X, LHS_adj);

        % Update
        beta_0_new    = -b(2);                  % ECM coef = -coef on gap_lag
        beta_lags_new = b(3 : 2 + blk.depth);
        beta_trend_new = b(end);

        delta = sqrt((beta_0_new - beta_0)^2 + ...
                     sum((beta_lags_new - beta_lags).^2) + ...
                     (beta_trend_new - beta_trend)^2);

        history = [history; [iter, beta_0_new, beta_lags_new', beta_trend_new, delta]];

        beta_0     = beta_0_new;
        beta_lags  = beta_lags_new;
        beta_trend = beta_trend_new;

        if delta < tol
            fprintf('Converged at iter %d (||delta||=%.5e)\n', iter, delta);
            break;
        end
        if iter == max_iter
            fprintf('Max iterations (||delta||=%.5e)\n', delta);
        end
    end

    % Final OLS with SE reporting
    chi = sum(beta_lags) + blk.omega;
    if abs(chi) < 1e-8
        PV_op = zeros(k);
    else
        PV_op = (eye(k) - chi * Phi) \ (chi * Phi);
    end
    PAC_exp_t = (e(:, blk.target_idx)' * PV_op * ZL_full')';
    LHS_adj = blk.LHS - PAC_exp_t;
    X = [ones(nObs, 1), blk.ecm_proxy_lag, LHS_lags, blk.trend_lag];
    [b, se, t_stat, R2, ~, n_ols] = ols(X, LHS_adj);

    fprintf('Final: chi = %.4f (= Sumβ_lag + ω), Phi*chi spectral radius = %.4f\n', ...
        chi, max(abs(eig(chi * Phi))));
    fprintf('%-30s %12s %12s %8s\n', 'Coefficient', 'estimate', 'se', 't');
    fprintf('%-30s %12.4f %12.4f %8.2f\n', '(intercept)', b(1), se(1), t_stat(1));
    fprintf('%-30s %12.4f %12.4f %8.2f\n', ...
        sprintf('beta_0 (%s lag, ECM)', blk.ecm_name), -b(2), se(2), -t_stat(2));
    for d = 1:blk.depth
        fprintf('%-30s %12.4f %12.4f %8.2f\n', ...
            sprintf('beta_%d (LHS lag %d)', d, d), b(2 + d), se(2 + d), t_stat(2 + d));
    end
    fprintf('%-30s %12.4f %12.4f %8.2f\n', ...
        sprintf('beta_PAC (%s lag)', blk.trend_name), b(end), se(end), t_stat(end));
    fprintf('R² = %.4f, N = %d\n\n', R2, n_ols);

    res = struct();
    res.name = blk.name;
    res.depth = blk.depth;
    res.omega = blk.omega;
    res.beta_0 = -b(2);
    res.beta_lags = b(3 : 2 + blk.depth);
    res.beta_PAC = b(end);
    res.se_beta_0 = se(2);
    res.se_beta_lags = se(3 : 2 + blk.depth);
    res.se_beta_PAC = se(end);
    res.t_beta_PAC = t_stat(end);
    res.chi = chi;
    res.R2 = R2;
    res.N = n_ols;
    res.n_iter = iter;
    res.history = history;
    res.converged = (delta < tol);
    results{j} = res;
end

%% Summary
fprintf('\n\n========== SUMMARY: PROPER iterative OLS across 5 PAC blocks ==========\n\n');
fprintf('%-15s %6s %6s %8s %8s %10s %10s %6s %6s\n', ...
    'Block', 'depth', 'omega', 'beta_0', 'beta_1', 'beta_PAC', 't(beta_PAC)', ...
    'chi', 'R^2');
fprintf('%-15s %6s %6s %8s %8s %10s %10s %6s %6s\n', ...
    '-----', '-----', '-----', '------', '------', '--------', '-----------', '---', '---');
for j = 1:n_blocks
    res = results{j};
    fprintf('%-15s %6d %6.2f %8.4f %8.4f %10.4f %10.2f %6.4f %6.3f\n', ...
        res.name, res.depth, res.omega, res.beta_0, res.beta_lags(1), ...
        res.beta_PAC, res.t_beta_PAC, res.chi, res.R2);
end

%% Cross-spec comparison: beta_PAC across approaches
fprintf('\n\n========== beta_PAC across estimators (consumption + 4 other) ==========\n\n');
L1 = load(fullfile(projectdir, 'data', 'l13a_chain1_posterior.mat'));
pilot = load(fullfile(projectdir, 'data', 'consumption_pac_ols.mat'));
oneshot = load(fullfile(projectdir, 'data', 'pac_blocks_ols.mat'));

fprintf('%-15s %16s %16s %16s %16s\n', ...
    'Block', 'L1.3a (Bayes)', 'L2-pilot OLS', 'one-shot OLS', 'iter OLS (proper)');
fprintf('%-15s %16s %16s %16s %16s\n', ...
    '-----', '-------------', '------------', '------------', '-----------------');

% consumption
idx_bPAC = find(strcmp(L1.param_names, 'b_PAC_c'));
fprintf('%-15s %16.4f %16.4f %16s %16.4f\n', 'consumption', ...
    L1.post_mean(idx_bPAC), pilot.specs.spec4.coef(6), 'n/a', results{1}.beta_PAC);

% Other blocks
block_names_oneshot = {'pQ', 'n', 'ib_sep', 'ih'};
for j = 2:n_blocks
    bn = block_names_oneshot{j-1};
    osr = oneshot.results.(bn);
    fprintf('%-15s %16s %16s %16.4f %16.4f\n', results{j}.name, ...
        'n/a', 'n/a', osr.b_PAC, results{j}.beta_PAC);
end

%% Save
out = struct();
out.method = 'proper iterative OLS, all 5 PAC blocks, wp1044 technique';
out.state_names = {state_names};
out.Phi = Phi;
out.rho_Phi = rho_Phi;
out.results = results;
out.block_names = cellfun(@(c) c.name, results, 'UniformOutput', false);
save(fullfile(projectdir, 'data', 'all_pac_iterative.mat'), '-struct', 'out');
fprintf('\nSaved data/all_pac_iterative.mat\n');

% Text summary
fid = fopen(fullfile(projectdir, 'data', 'all_pac_iterative.txt'), 'w');
fprintf(fid, 'Iterative OLS across 5 PAC blocks -- faithful wp1044 replication\n');
fprintf(fid, 'Generated %s\n\n', datestr(now));
fprintf(fid, 'Auxiliary VAR(1) state: [%s]\n', strjoin(state_names, ', '));
fprintf(fid, 'Phi spectral radius: %.4f\n\n', rho_Phi);
fprintf(fid, '%-15s %6s %6s %8s %8s %10s %10s %6s %6s\n', ...
    'Block', 'depth', 'omega', 'beta_0', 'beta_1', 'beta_PAC', 't(beta_PAC)', ...
    'chi', 'R^2');
fprintf(fid, '%-15s %6s %6s %8s %8s %10s %10s %6s %6s\n', ...
    '-----', '-----', '-----', '------', '------', '--------', '-----------', '---', '---');
for j = 1:n_blocks
    res = results{j};
    fprintf(fid, '%-15s %6d %6.2f %8.4f %8.4f %10.4f %10.2f %6.4f %6.3f\n', ...
        res.name, res.depth, res.omega, res.beta_0, res.beta_lags(1), ...
        res.beta_PAC, res.t_beta_PAC, res.chi, res.R2);
end
fclose(fid);
fprintf('Saved data/all_pac_iterative.txt\n\n');

fprintf('=== Done. ===\n');

%% --- Helpers ---
function y = lag1(x), y = [NaN; x(1:end-1)]; end
function y = lagn(x, n)
    y = [nan(n, 1); x(1:end-n)];
end
function v = demean(x), v = x - mean(x, 'omitnan'); end
function v = extract_aligned(src, idx)
    v = nan(length(idx), 1);
    ok = ~isnan(idx);
    v(ok) = src(idx(ok));
end
function gap = make_hp_gap(y, lambda)
    trend = hp_trend(y, lambda);
    gap = y - trend;
end
function trend = hp_trend(y, lambda)
    y = y(:);
    n = length(y);
    trend = nan(n, 1);
    valid = find(~isnan(y));
    if length(valid) < 4, return; end
    lo = valid(1); hi = valid(end);
    span = lo:hi;
    y_span = y(span);
    nm = isnan(y_span);
    if any(nm)
        idx = find(~nm);
        y_span = interp1(idx, y_span(idx), 1:length(y_span), 'linear')';
    end
    n_span = length(y_span);
    e = ones(n_span, 1);
    D2 = spdiags([e, -2*e, e], 0:2, n_span-2, n_span);
    A = speye(n_span) + lambda * (D2' * D2);
    trend(span) = A \ y_span;
end
function [b, se, t, R2, rss, n] = ols(X, y)
    valid = ~any(isnan([X, y]), 2);
    X = X(valid, :); y = y(valid);
    n = length(y);
    XtX = X' * X;
    b = XtX \ (X' * y);
    e = y - X * b;
    rss = e' * e;
    sigma2 = rss / (n - size(X, 2));
    se = sqrt(diag(sigma2 * inv(XtX)));
    t = b ./ se;
    R2 = 1 - rss / ((y - mean(y))' * (y - mean(y)));
end
