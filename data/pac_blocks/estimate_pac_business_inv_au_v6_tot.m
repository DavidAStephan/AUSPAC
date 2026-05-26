%% estimate_pac_business_inv_au_v6_tot.m  --  wp1044 PAC with q REPLACED by ToT
%
% Phase L2 P1c Option 2: replace the wp1044 q (market value-added gap)
% with AU terms-of-trade (commodity-augmented target).  This tests
% whether the wp1044 PAC structural restriction (PV at coef=+1, -sigma)
% holds when the relevant target for AU business inv is mining-driven
% terms of trade rather than aggregate market VA.
%
% Hypothesis: AU business inv is driven by COMMODITY EXPORT PRICES
% relative to domestic costs.  If we replace q with ToT in the PAC
% machinery and the structural restriction holds, this validates the
% "wp1044 framework with AU-relevant target" interpretation.
%
% Structural changes vs the failing strict-PAC variants:
%   - Replace q_market with q_AU = log(p_export / p_GNE) (ToT)
%   - Re-build auxiliary VAR with ToT-based state
%   - PV(Δq_AU_hat) and PV(Δq_AU_bar) entering at coef=+1 (structural)
%   - Other PAC structure unchanged: r_KB user cost terms, ECM on
%     business inv target, depth-2 lags, derived growth-neutrality, df
%     gap as ad-hoc demand, COVID dummies.
%
% If R^2 (raw) is positive and coef=+1 restrictions hold without
% breakage, this is the answer: AU BI has same PAC structure as France
% but with a different target variable.

clear; clc;
fprintf('=== Phase L2 P1c v6: BI with ToT-augmented q target (Option 2) ===\n\n');

projectdir = fullfile(fileparts(mfilename('fullpath')), '..', '..');
addpath(fullfile(projectdir, 'data', 'pac_helpers'));

L2 = load(fullfile(projectdir, 'data', 'l2_data_layer_v2.mat'));
S = load(fullfile(projectdir, 'dynare', 'supply_data.mat'));
C_ces = load(fullfile(projectdir, 'dynare', 'ces_2026_calibration.mat'));
base = readtable(fullfile(projectdir, 'dataset.csv'));
ext = readtable(fullfile(projectdir, 'data', 'extended_dataset.csv'));
sigma = C_ces.sigma;

%% Build q_AU = log(p_export / p_GNE) as the new commodity-augmented target
ipd_xlsx = fullfile(projectdir, 'data', 'abs_rba', 'abs_5206_ipd.xlsx');
[~, ~, raw_ipd] = xlsread(ipd_xlsx, 'Data1');
ipd_ids = string(raw_ipd(10, 2:end));
ipd_rows_raw = raw_ipd(11:end, 1);
n_ipd = length(ipd_rows_raw);
ipd_dates = nan(n_ipd, 1);
for i = 1:n_ipd
    d = ipd_rows_raw{i};
    if ischar(d) || isstring(d), try ipd_dates(i) = datenum(d); catch, end
    elseif isnumeric(d) && ~isempty(d), ipd_dates(i) = d + datenum('1900-01-01') - 2; end
end
ipd_dates_dt = datetime(ipd_dates, 'ConvertFrom', 'datenum');

col_pX = find(ipd_ids == 'A2303728F', 1) + 1;
col_pGNE = find(ipd_ids == 'A2303727C', 1) + 1;
p_X_raw = cell2mat(raw_ipd(11:end, col_pX));
p_GNE_raw = cell2mat(raw_ipd(11:end, col_pGNE));
q_AU_raw = 100 * log(p_X_raw ./ p_GNE_raw);

q_AU_lvl = nan(L2.nQ, 1);
for i = 1:L2.nQ
    m = find(year(ipd_dates_dt) == year(L2.dates(i)) & quarter(ipd_dates_dt) == quarter(L2.dates(i)), 1);
    if ~isempty(m), q_AU_lvl(i) = q_AU_raw(m); end
end
fprintf('q_AU = log(p_X/p_GNE) constructed: %d valid obs, mean=%.2f, sd=%.2f\n', ...
    sum(~isnan(q_AU_lvl)), mean(q_AU_lvl, 'omitnan'), std(q_AU_lvl, 'omitnan'));

% HP-trend and gap for q_AU
q_AU_trend = hp_trend_local(q_AU_lvl, 1600);
q_AU_gap = q_AU_lvl - q_AU_trend;            % cyclical component
Delta_q_AU = [NaN; diff(q_AU_lvl)];           % q/q change in ToT
Delta_q_AU_bar = hp_trend_local(Delta_q_AU, 1600);   % trend growth of ToT
Delta_q_AU_hat = Delta_q_AU - Delta_q_AU_bar;        % gap growth of ToT
fprintf('q_AU_gap: sd=%.2f, Delta_q_AU_hat: sd=%.2f\n\n', ...
    std(q_AU_gap, 'omitnan'), std(Delta_q_AU_hat, 'omitnan'));

%% LHS and PAC ingredients
ext_dates = datetime(ext.date);
au_ib = align_q(ext.au_gfcf_nondwelling, ext_dates, L2.dates);
log_ib = log(au_ib);
dln_ib = [NaN; diff(log_ib)] * 100;
log_ib_trend = hp_trend_local(log_ib, 1600);
ib_target_minus_actual = -((log_ib - log_ib_trend) * 100);

% r_KB unchanged
Delta_log_r_KB_hat = L2.Delta_log_r_KB_wacc - L2.Delta_log_r_KB_wacc_bar;
Delta_log_r_KB_bar = L2.Delta_log_r_KB_wacc_bar;

Delta_df_gap = L2.Delta_df_full - L2.Delta_df_bar_full;

%% Custom auxiliary VAR with ToT-state (8-dim)
%   State: [yhat_au, i_gap, pi_gap, yhat_us, pi_us, r_KB_gap, q_AU_hat]
%   where q_AU_hat = Δq_AU_hat (change in gap of ToT, pp scale)
yhat_au_full = align_q(base.au_ygap, datetime(base.date), L2.dates);
i_au_full = align_q(base.au_irate, datetime(base.date), L2.dates);
i_bar = L2.i_au_trend;
i_gap = i_au_full - i_bar;
pi_au_full = align_q(base.au_pi, datetime(base.date), L2.dates);
pi_bar = L2.pi_au_trend;
pi_gap = pi_au_full - pi_bar;
yhat_us = align_q(base.us_ygap, datetime(base.date), L2.dates);
pi_us = align_q(base.us_pi, datetime(base.date), L2.dates);

i_10y = nan(L2.nQ, 1);
for i = 1:L2.nQ
    m = find(year(ext_dates) == year(L2.dates(i)) & quarter(ext_dates) == quarter(L2.dates(i)), 1);
    if ~isempty(m), i_10y(i) = ext.au_i10(m); end
end
r_KB = i_10y - L2.pi_au_trend * 4;
r_KB_trend = hp_trend_local(r_KB, 1600);
r_KB_gap = r_KB - r_KB_trend;

state_data = [yhat_au_full, i_gap, pi_gap, yhat_us, pi_us, r_KB_gap, Delta_q_AU_hat];
state_names = {'yhat_au', 'i_gap', 'pi_gap', 'yhat_us', 'pi_us', 'r_KB_gap', 'Delta_q_AU_hat'};
fprintf('Custom aux VAR state: [%s]\n', strjoin(state_names, ', '));

% OLS VAR(1)
valid_v = ~any(isnan(state_data), 2);
Z = state_data(valid_v, :);
n_var = size(Z, 1);
Z_lag = Z(1:end-1, :);
Z_t   = Z(2:end, :);
Phi = ((Z_lag' * Z_lag) \ (Z_lag' * Z_t))';
fprintf('VAR fit: %d obs, Phi spectral radius = %.4f\n', n_var, max(abs(eig(Phi))));

k = size(state_data, 2);
nObs = L2.nQ;
ZL_full = nan(nObs, k);
v_idx = find(valid_v);
for ii = 2:length(v_idx)
    ZL_full(v_idx(ii), :) = state_data(v_idx(ii-1), :);
end

idx_q_AU = find(strcmp(state_names, 'Delta_q_AU_hat'));
idx_rKB = find(strcmp(state_names, 'r_KB_gap'));

%% Dummies
year_v = year(L2.dates); q_v = quarter(L2.dates);
mkd = @(yyyy, qq) double(year_v == yyyy & q_v == qq);
dummies = [mkd(2000,3), mkd(2000,4), ...
           mkd(2008,4), mkd(2009,1), mkd(2009,2), mkd(2011,3), ...
           L2.del_20Q1, L2.del_20Q2, L2.del_20Q3, L2.del_20Q4];
dummy_names = {'d_2000Q3','d_2000Q4','d_2008Q4','d_2009Q1','d_2009Q2','d_2011Q3', ...
               'd_20Q1','d_20Q2','d_20Q3','d_20Q4'};

%% Iterative OLS: wp1044 PAC strict with q_AU as target
omega = 0.35;
beta_0 = 0.096; beta_lags = [0.33; 0.11]; beta_3 = 0.69;
max_iter = 50; tol = 1e-4; damping = 0.5; chi_max = 0.85;

for iter = 1:max_iter
    chi = solve_pac_chi_exact(beta_lags, omega, 2);
    chi = max(0, min(chi_max, chi));

    PV_q_AU_hat = compute_pv_term(Phi, chi, idx_q_AU, ZL_full, 1);
    PV_rKB_hat  = compute_pv_term(Phi, chi, idx_rKB, ZL_full, 1);
    PV_q_AU_bar = lag1(Delta_q_AU_bar);
    PV_rKB_bar  = lag1(Delta_log_r_KB_bar);

    sum_b = sum(beta_lags);
    derived = 1 - sum_b - omega;

    % wp1044 PAC strict: PV at coef=+1 / -sigma -- target is q_AU now
    LHS = dln_ib - PV_q_AU_hat - PV_q_AU_bar ...
                 + sigma * PV_rKB_hat + sigma * PV_rKB_bar ...
                 - derived * lag1(Delta_log_r_KB_bar) ...
                 - derived * lag1(Delta_q_AU_bar);

    X = [ones(L2.nQ, 1), lag1(ib_target_minus_actual), ...
         lag1(dln_ib), lagn(dln_ib, 2), ...
         Delta_df_gap, dummies];
    names = [{'(intercept)', 'b_0 (ECM)', 'b_1 (lag1)', 'b_2 (lag2)', 'b_3 (Δdf gap)'}, dummy_names];

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

%% R^2 on raw dln_ib
y_hat = X * b + PV_q_AU_hat + PV_q_AU_bar - sigma*PV_rKB_hat - sigma*PV_rKB_bar ...
        + derived * lag1(Delta_log_r_KB_bar) + derived * lag1(Delta_q_AU_bar);
valid = ~any(isnan([dln_ib, y_hat]), 2);
ss_total = sum((dln_ib(valid) - mean(dln_ib(valid))).^2);
ss_resid = sum((dln_ib(valid) - y_hat(valid)).^2);
R2_raw = 1 - ss_resid / ss_total;

fprintf('--- v6 (q replaced by q_AU = log(p_X/p_GNE)) final ---\n');
for j = 1:length(names)
    fprintf('  %-25s %8.4f (se %.4f, t %.2f)\n', names{j}, b(j), se(j), t(j));
end
fprintf('chi = %.4f, R^2 on RAW dln_ib = %.4f *** headline\n', chi, R2_raw);
fprintf('vs wp1044 FR (with q = market VA) R^2 = 0.83\n\n');

%% Also test: PV terms as FREE regressors (Variant A-style) with q_AU
%   Check if the coef=+1 assumption holds when free-estimated.
fprintf('--- Diagnostic: PV coefficients when free-estimated (q_AU target) ---\n');
X_diag = [ones(L2.nQ, 1), lag1(ib_target_minus_actual), ...
          lag1(dln_ib), lagn(dln_ib, 2), ...
          PV_q_AU_hat, PV_q_AU_bar, PV_rKB_hat, PV_rKB_bar, ...
          Delta_df_gap, dummies];
names_diag = [{'(intercept)', 'b_0 (ECM)', 'b_1', 'b_2', ...
               'PV(Δq_AU_hat)', 'PV(Δq_AU_bar)', 'PV(Δr_KB_hat)', 'PV(Δr_KB_bar)', ...
               'b_3 (Δdf gap)'}, dummy_names];
[b_diag, se_diag, t_diag, R2_diag, ~, n_diag] = ols_with_se(X_diag, dln_ib);
fprintf('R^2 (free PV coefs) = %.4f\n', R2_diag);
fprintf('Coefficients on the PV regressors (should be +1, +1, -sigma=%.3f, -sigma):\n', sigma);
for j = 5:8
    fprintf('  %-22s %8.4f (se %.4f, t %.2f)\n', names_diag{j}, b_diag(j), se_diag(j), t_diag(j));
end

%% Save
out.block = 'BI Option 2: wp1044 PAC with q replaced by AU ToT';
out.beta_0 = beta_0; out.beta_lags = beta_lags; out.beta_3 = beta_3;
out.omega = omega; out.chi = chi; out.sigma = sigma;
out.coefs = b; out.se = se; out.tstat = t; out.names = {names};
out.R2_raw = R2_raw; out.R2_free_PV = R2_diag;
out.free_PV_coefs = b_diag(5:8); out.free_PV_t = t_diag(5:8);
out.N = n_ols; out.n_iter = iter;
out.Phi = Phi; out.state_names = {state_names};
out.converged = (delta < tol);
out.note = 'Option 2: replace q (market VA) with q_AU (ToT = log(p_X/p_GNE)) in PAC machinery';
save(fullfile(projectdir, 'data', 'pac_blocks', 'results_business_inv_au_v6_tot.mat'), '-struct', 'out');
fprintf('\nSaved results_business_inv_au_v6_tot.mat\n');

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
