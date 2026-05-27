%% estimate_pac_business_inv_au_v4.m  --  COMBINED PV term at coef=1 + dummies
%
% Phase L2 P1c v4.  Last attempt at preserving PAC structure for AU BI.
%
% wp1044 Eq 46 PV terms sum as:
%   PV_combined = PV(Δq̂) + PV(Δq̄) - sigma·PV(Δlog r̂_KB) - sigma·PV(Δlog r̄_KB)
%
% Variant B (v3) imposed each PV term at its individual coef (+1 for q,
% -sigma for r_KB), which broke on AU data.  This variant imposes the
% SUM at coef=1 -- a weaker but still PAC-faithful restriction.  The
% individual terms can re-balance internally.
%
% Then iterative OLS for the remaining β coefficients + dummies.

clear; clc;
fprintf('=== Phase L2 P1c v4: BI combined-PV at coef=1 + dummies ===\n\n');

projectdir = fullfile(fileparts(mfilename('fullpath')), '..', '..');
addpath(fullfile(projectdir, 'data', 'pac_helpers'));

L2 = load(fullfile(projectdir, 'data', 'l2_data_layer_v2.mat'));
S = load(fullfile(projectdir, 'dynare', 'supply_data.mat'));
C_ces = load(fullfile(projectdir, 'dynare', 'ces_2026_calibration.mat'));
base = readtable(fullfile(projectdir, 'dataset.csv'));
ext = readtable(fullfile(projectdir, 'data', 'extended_dataset.csv'));
sigma = C_ces.sigma;

ext_dates = datetime(ext.date);
au_ib = align_q(ext.au_gfcf_nondwelling, ext_dates, L2.dates);
log_ib = log(au_ib);
dln_ib = [NaN; diff(log_ib)] * 100;
log_ib_trend = hp_trend_local(log_ib, 1600);
ib_target_minus_actual = -((log_ib - log_ib_trend) * 100);

log_q = S.q_market_lvl;
log_q_trend = hp_trend_local(log_q, 1600);
Delta_q = [NaN; diff(log_q)] * 100;
Delta_q_bar = hp_trend_local(Delta_q, 1600);

Delta_log_r_KB_bar = L2.Delta_log_r_KB_wacc_bar;
Delta_df_gap = L2.Delta_df_full - L2.Delta_df_bar_full;

[Phi, state_names, ZL_full, ~, ~] = build_block_var('ib', L2, base, 1:L2.nQ);
idx_rKB = find(strcmp(state_names, 'r_KB_gap'));
idx_qhat = find(strcmp(state_names, 'q_hat'));

year_v = year(L2.dates); q_v = quarter(L2.dates);
mkd = @(yyyy, qq) double(year_v == yyyy & q_v == qq);

dummies = [mkd(2000,3), mkd(2000,4), ...
           mkd(2008,4), mkd(2009,1), mkd(2009,2), mkd(2011,3), ...
           L2.del_20Q1, L2.del_20Q2, L2.del_20Q3, L2.del_20Q4];
dummy_names = {'d_2000Q3','d_2000Q4','d_2008Q4','d_2009Q1','d_2009Q2','d_2011Q3', ...
               'd_20Q1','d_20Q2','d_20Q3','d_20Q4'};

%% Variant D: combined PV at coef=1 + dummies, iterative
omega = 0.35;
beta_0 = 0.10; beta_lags = [0.33; 0.11]; beta_3 = 0.69;
max_iter = 30; tol = 1e-4; damping = 0.5; chi_max = 0.85;

for iter = 1:max_iter
    chi = solve_pac_chi_exact(beta_lags, omega, 2);
    chi = max(0, min(chi_max, chi));

    PV_q_hat   = compute_pv_term(Phi, chi, idx_qhat, ZL_full, 1);
    PV_rKB_hat = compute_pv_term(Phi, chi, idx_rKB, ZL_full, 1);
    PV_q_bar   = lag1(Delta_q_bar);
    PV_rKB_bar = lag1(Delta_log_r_KB_bar);

    sum_b = sum(beta_lags);
    derived = 1 - sum_b - omega;

    % wp1044 PAC: SUM of 4 PV terms at coef=1
    PV_combined = PV_q_hat + PV_q_bar - sigma * PV_rKB_hat - sigma * PV_rKB_bar;

    LHS = dln_ib - PV_combined ...
                 - derived * lag1(Delta_log_r_KB_bar) ...
                 - derived * lag1(Delta_q_bar);

    X = [ones(L2.nQ, 1), lag1(ib_target_minus_actual), ...
         lag1(dln_ib), lagn(dln_ib, 2), ...
         Delta_df_gap, dummies];
    names_D = [{'(intercept)', 'b_0 (ECM)', 'b_1 (lag1)', 'b_2 (lag2)', 'b_3 (Δdf gap)'}, dummy_names];

    [b, se, t, R2, ~, n_ols] = ols_with_se(X, LHS);
    beta_0_new = max(-0.50, min(1.0, damping*b(2) + (1-damping)*beta_0));
    beta_lags_new = [max(-0.50, min(0.80, damping*b(3) + (1-damping)*beta_lags(1)));
                     max(-0.50, min(0.50, damping*b(4) + (1-damping)*beta_lags(2)))];
    beta_3_new = damping*b(5) + (1-damping)*beta_3;
    delta = norm([beta_0_new - beta_0; beta_lags_new - beta_lags; beta_3_new - beta_3]);
    fprintf('iter %2d: b0=%+.4f, b1=%+.4f, b2=%+.4f, b3=%+.4f, chi=%.4f, R^2adj=%.3f, ||d||=%.5f\n', ...
        iter, beta_0_new, beta_lags_new(1), beta_lags_new(2), beta_3_new, chi, R2, delta);
    beta_0=beta_0_new; beta_lags=beta_lags_new; beta_3=beta_3_new;
    if delta < tol, fprintf('Converged at iter %d\n\n', iter); break; end
end

%% Final + raw R^2
fprintf('--- Final estimates ---\n');
for j = 1:length(names_D)
    fprintf('  %-22s %8.4f (se %.4f, t %.2f)\n', names_D{j}, b(j), se(j), t(j));
end
% R^2 on raw dln_ib
y_hat = X * b + PV_combined + derived * lag1(Delta_log_r_KB_bar) + derived * lag1(Delta_q_bar);
valid = ~any(isnan([dln_ib, y_hat]), 2);
ss_total = sum((dln_ib(valid) - mean(dln_ib(valid))).^2);
ss_resid = sum((dln_ib(valid) - y_hat(valid)).^2);
R2_raw = 1 - ss_resid / ss_total;
fprintf('chi = %.4f, R^2 on RAW dln_ib = %.4f *** headline\n', chi, R2_raw);
fprintf('vs wp1044 R^2 = 0.83\n\n');

%% Save
out.block = 'Business inv (wp1044 Eq 46 combined PV coef=1) + AU dummies';
out.beta_0 = beta_0; out.beta_lags = beta_lags; out.beta_3 = beta_3;
out.omega = omega; out.chi = chi; out.sigma = sigma;
out.coefs = b; out.se = se; out.tstat = t; out.names = {names_D};
out.R2_raw = R2_raw; out.N = n_ols;
out.converged = (delta < tol); out.n_iter = iter;
out.Phi = Phi; out.state_names = {state_names};
save(fullfile(projectdir, 'data', 'pac_blocks', 'results_business_inv_au_v4.mat'), '-struct', 'out');
fprintf('Saved results_business_inv_au_v4.mat\n');

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
