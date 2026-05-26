%% estimate_pac_business_inv_au.m  --  wp1044 Eq 46 PAC-preserved with AU controls
%
% Phase L2 P1c: keep the full wp1044 PAC structure for business inv
% (4 PV terms imposed at coef=1, derived growth-neutrality, full Eq 46
% form) but add AU-specific in-sample controls to lift R^2 above the
% catastrophic 0.09 baseline.
%
% AU-specific events identified from top |dln_ib| outliers:
%   - 2000Q3 (+) and 2000Q4 (-): GST introduction July 2000 caused forward-
%     buying then collapse.  Largest single shock in the sample.
%   - 2008Q4-2009Q2: Global Financial Crisis sharp investment retreat.
%   - 2011-2013: Mining boom peak investment surge.
%   - 2020Q1-Q3 (and 2021Q1): COVID-19 collapse + rebound.
%
% Strategy: add these as period/regime dummies + a mining-era indicator
% on top of the wp1044 spec.
%
% Final spec compared to the failing baseline:
%   ALL wp1044 elements retained: 4 PV terms at coef=1, depth=2 PAC,
%   sigma-scaled user cost, derived (1-Σβ-ω) growth-neutrality on
%   q_bar and r_KB_bar, β_3 Δdf gap.
%   Added: d_2000Q3, d_2000Q4, d_GFC (08Q4-09Q2), d_mining (04Q1-13Q4 = 1).
%   Original 20Q1-Q3 dummies retained.

clear; clc;
fprintf('=== Phase L2 P1c: BI PAC-preserved with AU dummies/trends ===\n\n');

projectdir = fullfile(fileparts(mfilename('fullpath')), '..', '..');
addpath(fullfile(projectdir, 'data', 'pac_helpers'));

%% Load
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

log_ib_trend = hp_trend_local(log_ib, 1600);
ib_target_minus_actual = -((log_ib - log_ib_trend) * 100);

% wp1044 PV ingredients
log_q = S.q_market_lvl;
log_q_trend = hp_trend_local(log_q, 1600);
log_q_gap = (log_q - log_q_trend) * 100;
Delta_q = [NaN; diff(log_q)] * 100;
Delta_q_bar = hp_trend_local(Delta_q, 1600);
Delta_q_hat = Delta_q - Delta_q_bar;

r_KB = L2.r_KB_wacc;
Delta_log_r_KB = L2.Delta_log_r_KB_wacc;
Delta_log_r_KB_bar = L2.Delta_log_r_KB_wacc_bar;
Delta_log_r_KB_hat = Delta_log_r_KB - Delta_log_r_KB_bar;

Delta_df = L2.Delta_df_full;
Delta_df_bar = L2.Delta_df_bar_full;
Delta_df_gap = Delta_df - Delta_df_bar;

% AU-specific dummies
year_v = year(L2.dates);
q_v = quarter(L2.dates);
mkd = @(yyyy, qq) double(year_v == yyyy & q_v == qq);

% GST forward-buying then collapse
d_2000Q3 = mkd(2000, 3);
d_2000Q4 = mkd(2000, 4);

% GFC quarters (Lehman 2008-09)
d_2008Q4 = mkd(2008, 4);
d_2009Q1 = mkd(2009, 1);
d_2009Q2 = mkd(2009, 2);

% Existing 20Q1, 20Q2, 20Q3 dummies
d20q1 = L2.del_20Q1; d20q2 = L2.del_20Q2; d20q3 = L2.del_20Q3;

% Mining era indicator (regime dummy)
d_mining = double(year_v >= 2004 & year_v <= 2013);

%% Aux VAR (same as baseline)
[Phi, state_names, ZL_full, ~, n_var] = build_block_var('ib', L2, base, 1:L2.nQ);
idx_rKB = find(strcmp(state_names, 'r_KB_gap'));
idx_qhat = find(strcmp(state_names, 'q_hat'));

%% Iterative OLS -- full wp1044 PAC + AU controls
omega = 0.35;
beta_0 = 0.096;
beta_lags = [0.33; 0.11];
beta_3 = 0.69;
sigma = sigma_ces;

max_iter = 50; tol = 1e-4; damping = 0.5; chi_max = 0.85;
history = []; depth = 2;

for iter = 1:max_iter
    chi = solve_pac_chi_exact(beta_lags, omega, depth);
    chi = max(0, min(chi_max, chi));

    PV_q_hat   = compute_pv_term(Phi, chi, idx_qhat, ZL_full, 1);
    PV_rKB_hat = compute_pv_term(Phi, chi, idx_rKB, ZL_full, 1);
    PV_q_bar   = lag1(Delta_q_bar);
    PV_rKB_bar = lag1(Delta_log_r_KB_bar);

    sum_b = sum(beta_lags);
    derived_coef = 1 - sum_b - omega;

    % wp1044 PAC LHS adjustment (all 4 PV terms + 2 derived growth-neutrality)
    LHS = dln_ib - PV_q_hat - PV_q_bar ...
                 + sigma * PV_rKB_hat + sigma * PV_rKB_bar ...
                 - derived_coef * lag1(Delta_log_r_KB_bar) ...
                 - derived_coef * lag1(Delta_q_bar);

    % Free regressors: ECM, 2 lags, Δdf gap + AU-specific controls
    X = [ones(L2.nQ, 1), lag1(ib_target_minus_actual), ...
         lag1(dln_ib), lagn(dln_ib, 2), ...
         Delta_df_gap, ...
         d_2000Q3, d_2000Q4, ...
         d_2008Q4, d_2009Q1, d_2009Q2, ...
         d_mining, ...
         d20q1, d20q2, d20q3];
    names = {'(intercept)', 'b_0 (ECM)', ...
             'b_1 (lag1)', 'b_2 (lag2)', ...
             'b_3 (Δdf gap)', ...
             'd_2000Q3 (GST forward)', 'd_2000Q4 (GST collapse)', ...
             'd_2008Q4 (GFC)', 'd_2009Q1 (GFC)', 'd_2009Q2 (GFC)', ...
             'd_mining (04-13)', ...
             'd_20Q1', 'd_20Q2', 'd_20Q3'};

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

%% Final
fprintf('--- BI block final estimates (wp1044 PAC + AU controls) ---\n');
fprintf('%-35s %12s %12s %8s\n', 'Coefficient', 'estimate', 'se', 't');
for j = 1:length(names)
    fprintf('%-35s %12.4f %12.4f %8.2f\n', names{j}, b(j), se(j), t(j));
end
fprintf('chi = %.4f, omega = %.2f, R^2 = %.4f, N = %d, sigma = %.3f\n', chi, omega, R2, n_ols, sigma);

fprintf('\n--- Comparison to wp1044 Table 3.5.13 ---\n');
fprintf('%-12s %12s %12s\n', 'Param', 'AU L2', 'wp1044 FR');
fprintf('%-12s %12.4f %12s\n', 'beta_0', beta_0, '0.096');
fprintf('%-12s %12.4f %12s\n', 'beta_1', beta_lags(1), '0.33');
fprintf('%-12s %12.4f %12s\n', 'beta_2', beta_lags(2), '0.11');
fprintf('%-12s %12.4f %12s\n', 'beta_3', beta_3, '0.69');
fprintf('%-12s %12.4f %12s\n', 'R^2',    R2,     '0.83');

%% Save
out.block = 'Business inv (wp1044 Eq 46 + AU dummies)';
out.beta_0 = beta_0; out.beta_lags = beta_lags; out.beta_3 = beta_3;
out.omega = omega; out.chi = chi; out.sigma = sigma;
out.coefs = b; out.se = se; out.tstat = t; out.names = {names};
out.R2 = R2; out.N = n_ols; out.n_iter = iter; out.history = history;
out.state_names = {state_names}; out.Phi = Phi;
out.converged = (delta < tol);
out.note = 'PAC structure preserved (4 PV terms at coef=1); AU dummies added';

save(fullfile(projectdir, 'data', 'pac_blocks', 'results_business_inv_au.mat'), '-struct', 'out');
fprintf('\nSaved results_business_inv_au.mat\n');

fprintf('\n=== Phase L2 P1c done ===\n');

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
