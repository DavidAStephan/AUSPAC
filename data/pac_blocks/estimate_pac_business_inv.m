%% estimate_pac_business_inv.m  --  wp1044 §3.5.3 Eq 46 (partial)
%
% Phase L2-C5: Business investment PAC equation -- the most complex of the
% 5 blocks.
%
% wp1044 Eq 46:
%   Delta log I_B,t = beta_0 log(I*_B,t-1 / I_B,t-1)         ECM
%                   + beta_1 Delta log I_B,t-1 + beta_2 lag2  depth = 2
%                   + PV(Delta q_hat)_{t|t-1}                  gap PV, coef=1
%                   + PV(Delta q_bar)_{t|t-1}                  trend PV, coef=1
%                   - sigma PV(Delta log r_KB_hat)_{t|t-1}     gap PV, coef=-sigma
%                   - sigma PV(Delta log r_KB_bar)_{t|t-1}     trend PV, coef=-sigma
%                   + (1 - b1 - b2 - omega) Delta log r_KB_bar,t-1
%                                                              derived
%                   + (1 - b1 - b2 - omega) Delta q_bar,t-1
%                                                              derived
%                   + beta_3 (Delta df_t - Delta df_bar_t)     contemp synthetic demand gap
%                   + 3 COVID dummies (20Q1, 20Q2, 20Q3)
%
% wp1044 Table 3.5.13: beta_0=0.096, beta_1=0.33, beta_2=0.11, beta_3=0.69,
% R^2 = 0.83.  σ from CES = 0.50.
%
% AU partial L2:
%   - LHS: dln_ib (already in estimation_data)
%   - I*_B target proxy: HP trend of log(au_gfcf_nondwelling)
%   - sigma = ces_2026_calibration.mat sigma_ces (0.5366 for AU)
%   - q_hat, q_bar: market VA gap + trend (have q_market_lvl)
%   - r_KB_hat, r_KB_bar: real user cost gap + trend (proxy: i_10y - pi_Q vs trend)
%   - df = c + ih (EXPORTS MISSING per BLOCK_LIMITATIONS.md)
%   - 3 COVID dummies

clear; clc;
fprintf('=== Phase L2-C5: Business inv PAC (wp1044 Eq 46 partial) ===\n\n');

projectdir = fullfile(fileparts(mfilename('fullpath')), '..', '..');
addpath(fullfile(projectdir, 'data', 'pac_helpers'));

%% Load
L2 = load(fullfile(projectdir, 'data', 'l2_data_layer.mat'));
S = load(fullfile(projectdir, 'dynare', 'supply_data.mat'));
C_ces = load(fullfile(projectdir, 'dynare', 'ces_2026_calibration.mat'));
base = readtable(fullfile(projectdir, 'dataset.csv'));
ext = readtable(fullfile(projectdir, 'data', 'extended_dataset.csv'));

sigma_ces = C_ces.sigma;       % AU = 0.5366
fprintf('sigma_ces (CES capital-labour substitution): %.4f\n', sigma_ces);

% LHS
ext_dates = datetime(ext.date);
au_ib = align_q(ext.au_gfcf_nondwelling, ext_dates, L2.dates);
log_ib = log(au_ib);
dln_ib = [NaN; diff(log_ib)] * 100;

% I*_B target
log_ib_trend = hp_trend_local(log_ib, 1600);
ib_log_gap = (log_ib - log_ib_trend) * 100;
ib_target_minus_actual = -ib_log_gap;

% q_hat (market VA gap, pp), q_bar (trend), Δq decomposition
log_q = S.q_market_lvl;
log_q_trend = hp_trend_local(log_q, 1600);
q_hat_lvl = (log_q - log_q_trend) * 100;
Delta_q = [NaN; diff(log_q)] * 100;
Delta_q_bar = hp_trend_local(Delta_q, 1600);
Delta_q_hat = Delta_q - Delta_q_bar;

% r_KB user cost decomposition
% AU proxy: r_KB,t = i_10y - pi_Q + delta_q
delta_q = S.delta_q;
i_10y_full = align_q(ext.au_i10, ext_dates, L2.dates);
piQ = L2.piQ;
r_KB = (i_10y_full / 4) + delta_q - piQ / 100;   % quarterly decimal
log_r_KB = log(max(r_KB, 1e-6));
log_r_KB_trend = hp_trend_local(log_r_KB, 1600);
Delta_log_r_KB = [NaN; diff(log_r_KB)] * 100;
Delta_log_r_KB_bar = hp_trend_local(Delta_log_r_KB, 1600);
Delta_log_r_KB_hat = Delta_log_r_KB - Delta_log_r_KB_bar;

% Delta df gap (contemp synthetic demand)
Delta_df = L2.Delta_df;
Delta_df_bar = L2.Delta_df_bar;
Delta_df_gap = Delta_df - Delta_df_bar;

% Dummies
d20q1 = L2.del_20Q1; d20q2 = L2.del_20Q2; d20q3 = L2.del_20Q3;

%% Aux VAR
[Phi, state_names, ZL_full, ~, n_var] = build_block_var('ib', L2, base, 1:L2.nQ);
idx_rKB = find(strcmp(state_names, 'r_KB_gap'));
idx_qhat = find(strcmp(state_names, 'q_hat'));
fprintf('Aux VAR: %d obs, state [%s], Phi rho=%.4f\n\n', ...
    n_var, strjoin(state_names, ', '), max(abs(eig(Phi))));

%% Iterative OLS
omega = 0.35;
beta_0 = 0.096;
beta_lags = [0.33; 0.11];
beta_3 = 0.69;
sigma = sigma_ces;

max_iter = 50;
tol = 1e-4;
history = [];
depth = 2;
damping = 0.5;
chi_max = 0.85;

for iter = 1:max_iter
    chi = solve_pac_chi(beta_lags, omega, depth);
    chi = max(0, min(chi_max, chi));

    PV_q_hat   = compute_pv_term(Phi, chi, idx_qhat, ZL_full, 1);
    PV_rKB_hat = compute_pv_term(Phi, chi, idx_rKB, ZL_full, 1);
    PV_q_bar   = lag1(Delta_q_bar);            % trend PV proxy (calibrated unit-root)
    PV_rKB_bar = lag1(Delta_log_r_KB_bar);

    sum_b = sum(beta_lags);
    derived_coef = 1 - sum_b - omega;

    % LHS - PV(q_hat) - PV(q_bar) + sigma*PV(rKB_hat) + sigma*PV(rKB_bar)
    %     - derived * Delta_log_r_KB_bar_lag - derived * Delta_q_bar_lag
    LHS = dln_ib - PV_q_hat - PV_q_bar ...
                 + sigma * PV_rKB_hat + sigma * PV_rKB_bar ...
                 - derived_coef * lag1(Delta_log_r_KB_bar) ...
                 - derived_coef * lag1(Delta_q_bar);

    X = [ones(L2.nQ, 1), lag1(ib_target_minus_actual), ...
         lag1(dln_ib), lagn(dln_ib, 2), ...
         Delta_df_gap, d20q1, d20q2, d20q3];
    names_free = {'(intercept)', 'beta_0 (ECM I*_B-I_B lag)', ...
                  'beta_1 (Δlog I_B lag)', 'beta_2 (Δlog I_B lag2)', ...
                  'beta_3 (Δdf gap)', 'd_20Q1', 'd_20Q2', 'd_20Q3'};

    [b, se, tstat, R2, ~, n_ols] = ols_with_se(X, LHS);
    beta_0_new = max(0.005, min(0.80, damping * b(2) + (1-damping) * beta_0));
    beta_lags_new = [max(0.01, min(0.60, damping * b(3) + (1-damping) * beta_lags(1)));
                     max(-0.20, min(0.50, damping * b(4) + (1-damping) * beta_lags(2)))];
    beta_3_new = damping * b(5) + (1-damping) * beta_3;

    delta = norm([beta_0_new - beta_0; beta_lags_new - beta_lags; beta_3_new - beta_3]);
    history(iter, :) = [iter, beta_0_new, beta_lags_new', beta_3_new, chi, R2, delta];
    fprintf('iter %2d: b0=%.4f, b1=%.4f, b2=%.4f, b3=%.4f, chi=%.4f, R^2=%.3f, ||d||=%.5f\n', ...
        iter, beta_0_new, beta_lags_new(1), beta_lags_new(2), beta_3_new, chi, R2, delta);
    beta_0 = beta_0_new; beta_lags = beta_lags_new; beta_3 = beta_3_new;
    if delta < tol, fprintf('Converged at iter %d.\n\n', iter); break; end
end

%% Final
fprintf('--- Business inv block final ---\n');
for j = 1:length(names_free)
    fprintf('%-30s %12.4f %12.4f %8.2f\n', names_free{j}, b(j), se(j), tstat(j));
end
fprintf('chi = %.4f, omega = %.2f, R^2 = %.4f, N = %d, sigma = %.3f\n', ...
    chi, omega, R2, n_ols, sigma);

fprintf('\nvs wp1044 Table 3.5.13: b0=0.096, b1=0.33, b2=0.11, b3=0.69, R^2=0.83\n');
fprintf('Note: df = c + ih only (exports missing); see BLOCK_LIMITATIONS.md\n');

%% Save
out.block = 'Business inv (wp1044 Eq 46, partial)';
out.beta_0 = beta_0; out.beta_lags = beta_lags; out.beta_3 = beta_3;
out.omega = omega; out.chi = chi; out.sigma = sigma;
out.coefs = b; out.se = se; out.tstat = tstat; out.names = {names_free};
out.R2 = R2; out.N = n_ols; out.n_iter = iter; out.history = history;
out.state_names = {state_names}; out.Phi = Phi;
out.converged = (delta < tol);
out.note = 'df missing exports; partial replication';
save(fullfile(projectdir, 'data', 'pac_blocks', 'results_business_inv.mat'), '-struct', 'out');

fid = fopen(fullfile(projectdir, 'data', 'pac_blocks', 'results_business_inv.txt'), 'w');
fprintf(fid, 'Business inv PAC iterative OLS (wp1044 Eq 46 partial)\n');
fprintf(fid, 'Generated %s\n\n', datestr(now));
for j = 1:length(names_free)
    fprintf(fid, '%-30s %12.4f %12.4f %8.2f\n', names_free{j}, b(j), se(j), tstat(j));
end
fprintf(fid, 'chi=%.4f, R^2=%.4f, N=%d, sigma=%.4f\n', chi, R2, n_ols, sigma);
fprintf(fid, '\nwp1044 FR: b0=0.096, b1=0.33, b2=0.11, b3=0.69, R^2=0.83\n');
fprintf(fid, 'PARTIAL: df = c + ih (exports missing)\n');
fclose(fid);

fprintf('\n=== Phase L2-C5 complete ===\n');

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
