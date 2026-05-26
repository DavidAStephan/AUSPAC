%% estimate_pac_business_inv_au_v2.m  --  pre-residualize dummies, then PAC
%
% Phase L2 P1c v2: keep wp1044 PAC structure but PRE-RESIDUALIZE
% the AU-specific outlier shocks before applying PAC iterative OLS.
%
% Reasoning: the wp1044 PAC structure with all 4 PV terms is so
% over-parameterized that adding dummies inside the OLS doesn't help
% (P1c v1 R^2 0.09 -> 0.11).  Better approach: clean the dln_ib series
% of known AU-specific shocks (GST, GFC, mining era, COVID) via a
% pre-regression, then apply the wp1044 PAC iterative OLS to the
% residuals.  This isolates the wp1044 economic dynamics from
% AU-specific outlier shocks while keeping the PAC framework
% structurally intact.
%
% Procedure:
%   Step 1: OLS dln_ib on constant + dummies, get residuals dln_ib_clean
%   Step 2: Run wp1044 PAC iterative OLS on dln_ib_clean (no dummies in
%           the iterative spec; PV terms + ECM + lags + Δdf gap only)
%
% This is a "two-stage" approach: dummies pre-handle outliers; PAC
% identifies underlying dynamics.

clear; clc;
fprintf('=== Phase L2 P1c v2: pre-residualize dummies, then wp1044 PAC ===\n\n');

projectdir = fullfile(fileparts(mfilename('fullpath')), '..', '..');
addpath(fullfile(projectdir, 'data', 'pac_helpers'));

L2 = load(fullfile(projectdir, 'data', 'l2_data_layer_v2.mat'));
S = load(fullfile(projectdir, 'dynare', 'supply_data.mat'));
C_ces = load(fullfile(projectdir, 'dynare', 'ces_2026_calibration.mat'));
base = readtable(fullfile(projectdir, 'dataset.csv'));
ext = readtable(fullfile(projectdir, 'data', 'extended_dataset.csv'));
sigma_ces = C_ces.sigma;

ext_dates = datetime(ext.date);
au_ib = align_q(ext.au_gfcf_nondwelling, ext_dates, L2.dates);
log_ib = log(au_ib);
dln_ib = [NaN; diff(log_ib)] * 100;

%% Step 1: pre-residualize on dummies
year_v = year(L2.dates); q_v = quarter(L2.dates);
mkd = @(yyyy, qq) double(year_v == yyyy & q_v == qq);

dummies = [mkd(2000,3), mkd(2000,4), ...
           mkd(2008,4), mkd(2009,1), mkd(2009,2), ...
           L2.del_20Q1, L2.del_20Q2, L2.del_20Q3, L2.del_20Q4];
dummy_names = {'d_2000Q3','d_2000Q4','d_2008Q4','d_2009Q1','d_2009Q2', ...
               'd_20Q1','d_20Q2','d_20Q3','d_20Q4'};

X0 = [ones(L2.nQ, 1), dummies];
valid = ~any(isnan([X0, dln_ib]), 2);
b0 = (X0(valid,:)' * X0(valid,:)) \ (X0(valid,:)' * dln_ib(valid));
dln_ib_clean = dln_ib - X0 * b0;   % residuals; same length as dln_ib
fprintf('Step 1: dummy pre-regression\n');
fprintf('  Constant:    %+.4f\n', b0(1));
for k = 1:length(dummy_names)
    fprintf('  %-12s %+.4f\n', dummy_names{k}, b0(1+k));
end
ss_total = sum((dln_ib(valid) - mean(dln_ib(valid))).^2);
ss_resid = sum(dln_ib_clean(valid).^2);
fprintf('  R^2 (dummies alone): %.4f\n', 1 - ss_resid/ss_total);
fprintf('  sd(dln_ib_clean): %.4f (was %.4f for raw dln_ib)\n\n', ...
    std(dln_ib_clean, 'omitnan'), std(dln_ib, 'omitnan'));

%% Step 2: wp1044 PAC iterative OLS on dln_ib_clean
log_ib_trend = hp_trend_local(log_ib, 1600);
ib_target_minus_actual = -((log_ib - log_ib_trend) * 100);

log_q = S.q_market_lvl;
log_q_trend = hp_trend_local(log_q, 1600);
Delta_q = [NaN; diff(log_q)] * 100;
Delta_q_bar = hp_trend_local(Delta_q, 1600);
Delta_q_hat = Delta_q - Delta_q_bar;

Delta_log_r_KB = L2.Delta_log_r_KB_wacc;
Delta_log_r_KB_bar = L2.Delta_log_r_KB_wacc_bar;
Delta_log_r_KB_hat = Delta_log_r_KB - Delta_log_r_KB_bar;

Delta_df = L2.Delta_df_full;
Delta_df_bar = L2.Delta_df_bar_full;
Delta_df_gap = Delta_df - Delta_df_bar;

[Phi, state_names, ZL_full, ~, n_var] = build_block_var('ib', L2, base, 1:L2.nQ);
idx_rKB = find(strcmp(state_names, 'r_KB_gap'));
idx_qhat = find(strcmp(state_names, 'q_hat'));

omega = 0.35;
beta_0 = 0.096; beta_lags = [0.33; 0.11]; beta_3 = 0.69;
sigma = sigma_ces;
max_iter = 50; tol = 1e-4; damping = 0.5; chi_max = 0.85;
history = []; depth = 2;

fprintf('Step 2: wp1044 PAC iterative OLS on cleaned dln_ib\n');
for iter = 1:max_iter
    chi = solve_pac_chi_exact(beta_lags, omega, depth);
    chi = max(0, min(chi_max, chi));
    PV_q_hat   = compute_pv_term(Phi, chi, idx_qhat, ZL_full, 1);
    PV_rKB_hat = compute_pv_term(Phi, chi, idx_rKB, ZL_full, 1);
    PV_q_bar   = lag1(Delta_q_bar);
    PV_rKB_bar = lag1(Delta_log_r_KB_bar);
    sum_b = sum(beta_lags);
    derived_coef = 1 - sum_b - omega;

    LHS = dln_ib_clean - PV_q_hat - PV_q_bar ...
                       + sigma * PV_rKB_hat + sigma * PV_rKB_bar ...
                       - derived_coef * lag1(Delta_log_r_KB_bar) ...
                       - derived_coef * lag1(Delta_q_bar);

    X = [ones(L2.nQ, 1), lag1(ib_target_minus_actual), ...
         lag1(dln_ib_clean), lagn(dln_ib_clean, 2), ...
         Delta_df_gap];
    names = {'(intercept)', 'b_0 (ECM)', 'b_1 (lag1)', 'b_2 (lag2)', 'b_3 (Δdf gap)'};

    [b, se, t, R2, ~, n_ols] = ols_with_se(X, LHS);
    beta_0_new = max(0.005, min(0.80, damping * b(2) + (1-damping) * beta_0));
    beta_lags_new = [max(-0.20, min(0.60, damping * b(3) + (1-damping) * beta_lags(1)));
                     max(-0.30, min(0.50, damping * b(4) + (1-damping) * beta_lags(2)))];
    beta_3_new = damping * b(5) + (1-damping) * beta_3;
    delta = norm([beta_0_new - beta_0; beta_lags_new - beta_lags; beta_3_new - beta_3]);
    history(iter, :) = [iter, beta_0_new, beta_lags_new', beta_3_new, chi, R2, delta];
    fprintf('iter %2d: b0=%.4f, b1=%.4f, b2=%.4f, b3=%.4f, chi=%.4f, R^2=%.3f, ||d||=%.4f\n', ...
        iter, beta_0_new, beta_lags_new(1), beta_lags_new(2), beta_3_new, chi, R2, delta);
    beta_0 = beta_0_new; beta_lags = beta_lags_new; beta_3 = beta_3_new;
    if delta < tol, fprintf('Converged at iter %d.\n\n', iter); break; end
end

fprintf('--- BI block final (wp1044 PAC on dummy-cleaned dln_ib) ---\n');
for j = 1:length(names)
    fprintf('%-25s %12.4f %12.4f %8.2f\n', names{j}, b(j), se(j), t(j));
end
fprintf('chi = %.4f, omega = %.2f, R^2 (on cleaned LHS) = %.4f, N = %d, sigma = %.3f\n', chi, omega, R2, n_ols, sigma);

% Compare R^2 against raw dln_ib (combined dummy + PAC explanatory power)
% Get fitted from PAC: y_hat_PAC = LHS - residuals = X*b - epsilon
y_hat_PAC = X * b + (dln_ib_clean - LHS);   % full implied: PAC part + structural PV part
% Total fitted: y_hat_total = X0*b0 + y_hat_PAC
y_hat_total = X0 * b0 + y_hat_PAC;
valid_full = ~isnan(y_hat_total) & ~isnan(dln_ib);
ss_total_full = sum((dln_ib(valid_full) - mean(dln_ib(valid_full))).^2);
ss_resid_full = sum((dln_ib(valid_full) - y_hat_total(valid_full)).^2);
R2_total = 1 - ss_resid_full / ss_total_full;
fprintf('R^2 (combined dummy + PAC on raw dln_ib): %.4f  *** headline\n', R2_total);

fprintf('\n--- vs wp1044 Table 3.5.13 ---\n');
fprintf('%-12s %12s %12s\n', 'Param', 'AU L2', 'wp1044 FR');
fprintf('%-12s %12.4f %12s\n', 'beta_0', beta_0, '0.096');
fprintf('%-12s %12.4f %12s\n', 'beta_1', beta_lags(1), '0.33');
fprintf('%-12s %12.4f %12s\n', 'beta_2', beta_lags(2), '0.11');
fprintf('%-12s %12.4f %12s\n', 'beta_3', beta_3, '0.69');
fprintf('%-12s %12.4f %12s\n', 'R^2',    R2_total, '0.83');

%% Save
out.block = 'Business inv (wp1044 Eq 46, dummies pre-residualized)';
out.beta_0 = beta_0; out.beta_lags = beta_lags; out.beta_3 = beta_3;
out.omega = omega; out.chi = chi; out.sigma = sigma;
out.coefs = b; out.se = se; out.tstat = t; out.names = {names};
out.R2_on_cleaned = R2; out.R2_total = R2_total;
out.dummy_coefs = b0; out.dummy_names = {dummy_names};
out.N = n_ols; out.n_iter = iter; out.history = history;
out.state_names = {state_names}; out.Phi = Phi;
out.converged = (delta < tol);
out.note = 'wp1044 PAC preserved; AU dummies handled via pre-regression';
save(fullfile(projectdir, 'data', 'pac_blocks', 'results_business_inv_au_v2.mat'), '-struct', 'out');
fprintf('\nSaved results_business_inv_au_v2.mat\n');

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
