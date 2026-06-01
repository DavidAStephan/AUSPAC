%% estimate_pac_employment.m  --  wp1044 §3.4.3 Eq 30 faithful rebuild
%
% Phase L2-C2: Employment PAC equation with full wp1044 functional form.
%
% wp1044 Eq 30:
%   Delta n_S,t = beta_0 (n*_S,t-1 - n_S,t-1)        ECM on emp level gap
%               + PV(Delta n_bar*_S)_{t|t-1}          coef = 1, trend PV
%               + PV(Delta n_hat*_S)_{t|t-1}          coef = 1, gap PV
%               + beta_1 Delta n_S,t-1 + beta_2 lag2 + beta_3 lag3      depth = 3
%               + (1 - beta_1 - beta_2 - beta_3 - omega) Delta n_bar*_S,t-1
%                                                    derived growth-neutrality
%               + beta_4 Delta q_hat,t                contemp market-VA gap growth
%               + beta_5 d_20Q2 + beta_6 d_20Q3       2 COVID dummies
%               + epsilon
%
% wp1044 Table 3.4.9: beta_0=0.07, beta_1=0.44, beta_2=0.12, beta_3=0.12,
% beta_4=0.13, omega=0.34, R^2 = 0.95.
%
% Aux equation Eq 31:  n_hat*_S,t = beta_0 yhat_{t-1} + beta_3 n_hat*_S,t-1
%   wp1044 Table 3.4.10: beta_0=0.29, beta_3=0.60.  AU L2 data layer:
%   beta_0=-0.0007, beta_3=0.71 (AU labor market less reactive to output).
%
% PV(Delta n_bar*_S) per Eq 32: omega · Delta n_bar*_S,t-1 (calibrated
% unit-root form).
%
% Estimation:
%   chi for PV(gap) = solve_pac_chi_exact([b1, b2, b3], omega, 3)
%   PV(gap)_t = e_{n_hat}' · (I - chi*Phi)^{-1} chi*Phi · z_{t-1}
%   PV(trend)_t = omega · Delta_n_bar_S(t-1)
%   LHS_adj = Delta n_S - PV(gap) - PV(trend) - derived_coef * Delta_n_bar_S(t-1)
%   Free regressors: intercept, ECM, 3 Delta n lags, Delta q_hat, 2 dummies
%
% Outputs:
%   data/pac_blocks/results_employment.{mat,txt}

clear; clc;
fprintf('=== Phase L2-C2: Employment PAC (wp1044 Eq 30) iterative OLS ===\n\n');

projectdir = fullfile(fileparts(mfilename('fullpath')), '..', '..');
addpath(fullfile(projectdir, 'data', 'pac_helpers'));

%% Load data
L2 = load(fullfile(projectdir, 'data', 'l2_data_layer.mat'));
base = readtable(fullfile(projectdir, 'dataset.csv'));
ext = readtable(fullfile(projectdir, 'data', 'extended_dataset.csv'));

% Construct Delta n_S from extended_dataset au_employment
ext_dates = datetime(ext.date);
au_emp_full = align_q(ext.au_employment, ext_dates, L2.dates);
log_emp = log(au_emp_full);
dlog_emp = [NaN; diff(log_emp)] * 100;       % q/q %
Delta_n_S = dlog_emp;
fprintf('Delta n_S: %d valid obs, mean=%.3f%%, sd=%.3f%%\n', ...
    sum(~isnan(Delta_n_S)), mean(Delta_n_S, 'omitnan'), std(Delta_n_S, 'omitnan'));

% n_S target gap = HP gap of log_emp (pp scale) (proxy for wp1044 n*_S - n_S)
emp_trend = hp_trend_local(log_emp, 1600);
n_S_minus_target = (log_emp - emp_trend) * 100;   % positive when emp above trend
n_S_target_gap = -n_S_minus_target;               % wp1044's (n* - n)

% Delta n_bar*_S trend (HP trend of Delta n_S)
Delta_n_bar = hp_trend_local(Delta_n_S, 1600);

% Delta q_hat (contemporaneous market VA gap growth) -- in L2 data layer
Delta_q_hat = L2.Delta_q_hat;

% Dummies
d_20Q2 = L2.del_20Q2;
d_20Q3 = L2.del_20Q3;

%% Auxiliary VAR
sample_full = 1:L2.nQ;
[Phi, state_names, ZL_full, ~, n_var] = build_block_var('n', L2, base, sample_full);
idx_n_hat = find(strcmp(state_names, 'n_hat_S'));
fprintf('Aux VAR: %d obs, state [%s], Phi rho=%.4f\n\n', ...
    n_var, strjoin(state_names, ', '), max(abs(eig(Phi))));

%% Iterative OLS
omega = 0.34;
beta_0 = 0.07;
beta_lags = [0.44; 0.12; 0.12];     % b1, b2, b3
beta_4 = 0.13;

max_iter = 50;
tol = 1e-4;
history = [];
depth = 3;

for iter = 1:max_iter
    % FIX 2026-05-31: was solve_pac_chi (approximate depth-1 quadratic on sum-of-betas),
    % which gave chi=0.21 for this depth-3 block vs the exact root 0.40 — inconsistent
    % with the abstract's "exact chi from depth-m characteristic polynomial". Use the
    % exact depth-m solver (as housing/business already do). See verify_pac_chi_pv.m.
    chi = solve_pac_chi_exact(beta_lags, omega, depth);

    PV_gap = compute_pv_term(Phi, chi, idx_n_hat, ZL_full, 1);
    % PV(Delta n_bar*_S) = omega * Delta_n_bar lag (Eq 32, calibrated unit-root)
    PV_trend = omega * lag1(Delta_n_bar);

    sum_b = sum(beta_lags);
    derived_coef = 1 - sum_b - omega;

    LHS = Delta_n_S - PV_gap - PV_trend - derived_coef * lag1(Delta_n_bar);

    X = [ones(L2.nQ, 1), lag1(n_S_target_gap), ...
         lag1(Delta_n_S), lagn(Delta_n_S, 2), lagn(Delta_n_S, 3), ...
         Delta_q_hat, d_20Q2, d_20Q3];
    names_free = {'(intercept)', 'beta_0 (n*_S-n_S lag, ECM)', ...
                  'beta_1 (Δn lag1)', 'beta_2 (Δn lag2)', 'beta_3 (Δn lag3)', ...
                  'beta_4 (Δq_hat contemp)', 'd_20Q2', 'd_20Q3'};

    [b, se, tstat, R2, ~, n_ols] = ols_with_se(X, LHS);
    beta_0_new = b(2);
    beta_lags_new = b(3:5);
    beta_4_new = b(6);

    delta = norm([beta_0_new - beta_0; beta_lags_new - beta_lags; beta_4_new - beta_4]);
    history(iter, :) = [iter, beta_0_new, beta_lags_new', beta_4_new, chi, R2, delta];
    fprintf('iter %2d: b0=%.4f, b1=%.4f, b2=%.4f, b3=%.4f, b4=%.4f, chi=%.4f, R^2=%.3f, ||d||=%.5f\n', ...
        iter, beta_0_new, beta_lags_new(1), beta_lags_new(2), beta_lags_new(3), ...
        beta_4_new, chi, R2, delta);
    beta_0 = beta_0_new; beta_lags = beta_lags_new; beta_4 = beta_4_new;
    if delta < tol, fprintf('Converged at iter %d.\n\n', iter); break; end
end

%% Final
fprintf('--- Employment block final estimates ---\n');
fprintf('%-30s %12s %12s %8s\n', 'Coefficient', 'estimate', 'se', 't');
for j = 1:length(names_free)
    fprintf('%-30s %12.4f %12.4f %8.2f\n', names_free{j}, b(j), se(j), tstat(j));
end
fprintf('chi = %.4f, omega = %.2f, derived_coef = %.4f\n', chi, omega, 1 - sum(beta_lags) - omega);
fprintf('R^2 = %.4f, N = %d, iters = %d\n', R2, n_ols, iter);

fprintf('\n--- Comparison to wp1044 Table 3.4.9 ---\n');
fprintf('%-12s %12s %12s\n', 'Param', 'AU L2', 'wp1044 FR');
fprintf('%-12s %12.4f %12s\n', 'beta_0', beta_0, '0.07');
fprintf('%-12s %12.4f %12s\n', 'beta_1', beta_lags(1), '0.44');
fprintf('%-12s %12.4f %12s\n', 'beta_2', beta_lags(2), '0.12');
fprintf('%-12s %12.4f %12s\n', 'beta_3', beta_lags(3), '0.12');
fprintf('%-12s %12.4f %12s\n', 'beta_4', beta_4, '0.13');
fprintf('%-12s %12.4f %12s\n', 'omega',  omega, '0.34');
fprintf('%-12s %12.4f %12s\n', 'R^2',    R2,    '0.95');

%% Save
out.block = 'Employment (wp1044 Eq 30)';
out.beta_0 = beta_0;
out.beta_lags = beta_lags;
out.beta_4 = beta_4;
out.omega = omega;
out.chi = chi;
out.derived_coef = 1 - sum(beta_lags) - omega;
out.coefs = b;
out.se = se;
out.tstat = tstat;
out.names = {names_free};
out.R2 = R2;
out.N = n_ols;
out.n_iter = iter;
out.history = history;
out.state_names = {state_names};
out.Phi = Phi;
out.converged = (delta < tol);

save(fullfile(projectdir, 'data', 'pac_blocks', 'results_employment.mat'), '-struct', 'out');

fid = fopen(fullfile(projectdir, 'data', 'pac_blocks', 'results_employment.txt'), 'w');
fprintf(fid, 'Employment PAC iterative OLS (wp1044 Eq 30)\n');
fprintf(fid, 'Generated %s\n\n', datestr(now));
fprintf(fid, 'Aux VAR state: [%s], rho=%.4f\n\n', strjoin(state_names, ', '), max(abs(eig(Phi))));
for j = 1:length(names_free)
    fprintf(fid, '%-30s %12.4f %12.4f %8.2f\n', names_free{j}, b(j), se(j), tstat(j));
end
fprintf(fid, 'chi=%.4f, omega=%.2f, derived_coef=%.4f, R^2=%.4f, N=%d\n', chi, omega, 1-sum(beta_lags)-omega, R2, n_ols);
fprintf(fid, '\nwp1044 FR: b0=0.07, b1=0.44, b2=0.12, b3=0.12, b4=0.13, omega=0.34, R^2=0.95\n');
fclose(fid);

fprintf('\n=== Phase L2-C2 complete ===\n');

%% Helpers
function vq = align_q(src_col, src_dates, target_dates)
    nq = length(target_dates);
    vq = nan(nq, 1);
    for i = 1:nq
        m = find(year(src_dates) == year(target_dates(i)) & quarter(src_dates) == quarter(target_dates(i)), 1);
        if ~isempty(m), vq(i) = src_col(m); end
    end
end
function trend = hp_trend_local(y, lambda)
    y = y(:); n = length(y); trend = nan(n, 1);
    valid = find(~isnan(y)); if length(valid) < 4, return; end
    lo = valid(1); hi = valid(end); span = lo:hi; y_span = y(span);
    nm = isnan(y_span);
    if any(nm), idx = find(~nm); y_span = interp1(idx, y_span(idx), 1:length(y_span), 'linear')'; end
    n_span = length(y_span); e = ones(n_span, 1);
    D2 = spdiags([e, -2*e, e], 0:2, n_span-2, n_span);
    A = speye(n_span) + lambda * (D2' * D2);
    trend(span) = A \ y_span;
end
