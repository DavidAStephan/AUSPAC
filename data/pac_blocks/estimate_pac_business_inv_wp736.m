%% estimate_pac_business_inv_wp736.m  --  wp736 (2019) Eq 64 on AU data
%
% Phase L2 P1c v5: try wp736's ORIGINAL FR-BDF investment equation
% (simpler, with only 2 PV terms) on AU data.  The wp1044 update has
% 4 PV terms and a new synthetic-df demand proxy; wp736's original is
% simpler and may fit AU better given the data limitations.
%
% wp736 Eq 64:
%   Delta log I_B,t = beta_0 log(I*_B,t-1 / I_B,t-1)        ECM
%                   + beta_1 Delta log I_B,t-1 + beta_2 lag2  depth = 2
%                   + PV(Delta q_hat)_{t|t-1}                  ONE gap PV, coef=+1
%                   - sigma PV(Delta log r_KB_hat)_{t|t-1}      ONE gap PV, coef=-sigma
%                   + (1 - beta_1 - beta_2)(Delta q_hat - sigma Delta log r_KB_bar)_{t-1}
%                                                              SINGLE growth-neutrality
%                                                              (combined market VA + r_KB)
%                   + beta_3 (Delta q_{t-1} - Delta q_bar_{t-1})
%                                                              LAGGED market VA gap (NOT df)
%
% wp736 Table 4.6.9: beta_0=0.085, beta_1=0.29, beta_2=0.20, beta_3=0.58, R^2=0.52.
%
% No COVID dummies in wp736 (pre-pandemic).  Adding them for the AU sample
% per practical necessity, plus the GST 2000Q3/Q4 + GFC dummies.
%
% Key wp736 vs wp1044 simplifications:
%   - 2 PV terms (not 4)
%   - 1 growth-neutrality term (not 2)
%   - omega = 0 (no non-stationary weight added)
%   - lagged Δq gap as demand (not contemp Δdf gap)

clear; clc;
fprintf('=== Phase L2 P1c v5: BI with wp736 (2019) Eq 64 ===\n\n');

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
Delta_q_hat = Delta_q - Delta_q_bar;     % market VA gap growth

% r_KB user cost (wacc-based)
Delta_log_r_KB_hat = L2.Delta_log_r_KB_wacc - L2.Delta_log_r_KB_wacc_bar;
Delta_log_r_KB_bar = L2.Delta_log_r_KB_wacc_bar;

[Phi, state_names, ZL_full, ~, ~] = build_block_var('ib', L2, base, 1:L2.nQ);
idx_rKB = find(strcmp(state_names, 'r_KB_gap'));
idx_qhat = find(strcmp(state_names, 'q_hat'));

% Dummies (AU-specific, retain because wp736 estimated pre-COVID)
year_v = year(L2.dates); q_v = quarter(L2.dates);
mkd = @(yyyy, qq) double(year_v == yyyy & q_v == qq);
dummies = [mkd(2000,3), mkd(2000,4), ...
           mkd(2008,4), mkd(2009,1), mkd(2009,2), mkd(2011,3), ...
           L2.del_20Q1, L2.del_20Q2, L2.del_20Q3, L2.del_20Q4];
dummy_names = {'d_2000Q3','d_2000Q4','d_2008Q4','d_2009Q1','d_2009Q2','d_2011Q3', ...
               'd_20Q1','d_20Q2','d_20Q3','d_20Q4'};

%% Iterative OLS for wp736 Eq 64
omega = 0;    % wp736 has no omega
beta_0 = 0.085; beta_lags = [0.29; 0.20]; beta_3 = 0.58;
max_iter = 30; tol = 1e-4; damping = 0.5; chi_max = 0.85;

for iter = 1:max_iter
    chi = solve_pac_chi_exact(beta_lags, omega, 2);
    chi = max(0, min(chi_max, chi));

    PV_q_hat   = compute_pv_term(Phi, chi, idx_qhat, ZL_full, 1);
    PV_rKB_hat = compute_pv_term(Phi, chi, idx_rKB, ZL_full, 1);

    sum_b = sum(beta_lags);
    derived = 1 - sum_b;   % wp736 has no omega in derived coef

    % wp736 Eq 64: LHS - PV(q_hat) + sigma*PV(r_KB_hat) - derived*(Δq_hat - σ·Δlogr̄_KB)_{t-1}
    LHS = dln_ib - PV_q_hat + sigma * PV_rKB_hat ...
                 - derived * (lag1(Delta_q_hat) - sigma * lag1(Delta_log_r_KB_bar));

    X = [ones(L2.nQ, 1), lag1(ib_target_minus_actual), ...
         lag1(dln_ib), lagn(dln_ib, 2), ...
         lag1(Delta_q - Delta_q_bar), ...       % wp736's β_3 regressor: lagged Δq gap
         dummies];
    names_E = [{'(intercept)', 'b_0 (ECM)', 'b_1 (lag1)', 'b_2 (lag2)', ...
                'b_3 (lag Δq gap, wp736)'}, dummy_names];

    [b, se, t, R2, ~, n_ols] = ols_with_se(X, LHS);
    beta_0_new = max(-0.50, min(1.0, damping*b(2) + (1-damping)*beta_0));
    beta_lags_new = [max(-0.50, min(0.80, damping*b(3) + (1-damping)*beta_lags(1)));
                     max(-0.50, min(0.60, damping*b(4) + (1-damping)*beta_lags(2)))];
    beta_3_new = damping*b(5) + (1-damping)*beta_3;
    delta = norm([beta_0_new - beta_0; beta_lags_new - beta_lags; beta_3_new - beta_3]);
    fprintf('iter %2d: b0=%+.4f, b1=%+.4f, b2=%+.4f, b3=%+.4f, chi=%.4f, R^2adj=%.3f\n', ...
        iter, beta_0_new, beta_lags_new(1), beta_lags_new(2), beta_3_new, chi, R2);
    beta_0=beta_0_new; beta_lags=beta_lags_new; beta_3=beta_3_new;
    if delta < tol, fprintf('Converged at iter %d\n\n', iter); break; end
end

% R^2 on raw dln_ib
y_hat = X * b + PV_q_hat - sigma * PV_rKB_hat + derived * (lag1(Delta_q_hat) - sigma * lag1(Delta_log_r_KB_bar));
valid = ~any(isnan([dln_ib, y_hat]), 2);
ss_total = sum((dln_ib(valid) - mean(dln_ib(valid))).^2);
ss_resid = sum((dln_ib(valid) - y_hat(valid)).^2);
R2_raw = 1 - ss_resid / ss_total;

fprintf('--- wp736 Eq 64 final ---\n');
for j = 1:length(names_E)
    fprintf('  %-25s %8.4f (se %.4f, t %.2f)\n', names_E{j}, b(j), se(j), t(j));
end
fprintf('chi = %.4f, R^2 on RAW dln_ib = %.4f *** headline\n', chi, R2_raw);
fprintf('vs wp736 FR R^2 = 0.52 (1.0 PV terms simpler than wp1044)\n\n');

fprintf('--- vs wp736 Table 4.6.9 ---\n');
fprintf('%-12s %12s %12s\n', 'Param', 'AU L2', 'wp736 FR');
fprintf('%-12s %12.4f %12s\n', 'beta_0', beta_0, '0.085');
fprintf('%-12s %12.4f %12s\n', 'beta_1', beta_lags(1), '0.29');
fprintf('%-12s %12.4f %12s\n', 'beta_2', beta_lags(2), '0.20');
fprintf('%-12s %12.4f %12s\n', 'beta_3', beta_3, '0.58');
fprintf('%-12s %12.4f %12s\n', 'R^2',    R2_raw, '0.52');

%% Save
out.block = 'Business inv (wp736 Eq 64 + AU dummies)';
out.beta_0 = beta_0; out.beta_lags = beta_lags; out.beta_3 = beta_3;
out.omega = omega; out.chi = chi; out.sigma = sigma;
out.coefs = b; out.se = se; out.tstat = t; out.names = {names_E};
out.R2_raw = R2_raw; out.N = n_ols;
out.converged = (delta < tol); out.n_iter = iter;
out.Phi = Phi; out.state_names = {state_names};
out.note = 'wp736 Eq 64 (2019 ORIGINAL) simpler than wp1044 Eq 46; 2 PV terms, no df';
save(fullfile(projectdir, 'data', 'pac_blocks', 'results_business_inv_wp736.mat'), '-struct', 'out');

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
