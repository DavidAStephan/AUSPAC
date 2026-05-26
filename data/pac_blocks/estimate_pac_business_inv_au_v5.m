%% estimate_pac_business_inv_au_v5.m  --  wp1044 PAC + ToT + piecewise trends
%
% Phase L2 P1c v5: keep wp1044 PAC strict (PV at coef=1, -sigma) and try
% adding everything that might capture AU-specific dynamics:
%   1. Terms of trade: log(p_exports / p_GNE) -- commodity cycle proxy
%   2. Δ(ToT) in level and lag
%   3. Piecewise linear trends with breaks at 2003Q1 (mining era start)
%      and 2014Q1 (mining bust)
%   4. All AU dummies retained (GST, GFC, mining peak, COVID)
%
% wp1044 PAC structure preserved -- PV terms at coef=+1 / -sigma.
% Iterative OLS for β_0, β_1, β_2, β_3 with damping + clamps.

clear; clc;
fprintf('=== Phase L2 P1c v5: BI wp1044 PAC + ToT + piecewise trends ===\n\n');

projectdir = fullfile(fileparts(mfilename('fullpath')), '..', '..');
addpath(fullfile(projectdir, 'data', 'pac_helpers'));

L2 = load(fullfile(projectdir, 'data', 'l2_data_layer_v2.mat'));
S = load(fullfile(projectdir, 'dynare', 'supply_data.mat'));
C_ces = load(fullfile(projectdir, 'dynare', 'ces_2026_calibration.mat'));
base = readtable(fullfile(projectdir, 'dataset.csv'));
ext = readtable(fullfile(projectdir, 'data', 'extended_dataset.csv'));
sigma = C_ces.sigma;

%% Construct terms-of-trade proxy: log(p_exports / p_GNE)
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

col_pX = find(ipd_ids == 'A2303728F', 1) + 1;       % +1 because raw has date col
col_pGNE = find(ipd_ids == 'A2303727C', 1) + 1;
p_X_raw = cell2mat(raw_ipd(11:end, col_pX));
p_GNE_raw = cell2mat(raw_ipd(11:end, col_pGNE));
ToT_raw = 100 * log(p_X_raw ./ p_GNE_raw);          % log ratio, pp scale

ToT = nan(L2.nQ, 1);
for i = 1:L2.nQ
    m = find(year(ipd_dates_dt) == year(L2.dates(i)) & ...
             quarter(ipd_dates_dt) == quarter(L2.dates(i)), 1);
    if ~isempty(m), ToT(i) = ToT_raw(m); end
end
ToT_demeaned = ToT - mean(ToT, 'omitnan');
dToT = [NaN; diff(ToT)];     % q/q change in log ToT
fprintf('Terms of trade (pX/pGNE) constructed: %d valid obs\n', sum(~isnan(ToT)));
fprintf('  ToT mean: %.2f, sd: %.2f\n', mean(ToT, 'omitnan'), std(ToT, 'omitnan'));

%% Construct piecewise linear trends with breakpoints
%   break1 = 2003Q1 (mining era start)
%   break2 = 2014Q1 (mining bust)
year_v = year(L2.dates); q_v = quarter(L2.dates);
t_full = (1:L2.nQ)' / 4;       % time in years from sample start

t_pre2003 = max(0, min(t_full, t_full(find(year_v >= 2003 & q_v == 1, 1))));
t_post2003 = max(0, t_full - t_full(find(year_v >= 2003 & q_v == 1, 1)));
t_post2014 = max(0, t_full - t_full(find(year_v >= 2014 & q_v == 1, 1)));

% Trend in pre-2003 = early; mid (2003-2013) = mining boom slope; post-2014 = bust slope
% Use the SECOND segment slope as a regressor (peak mining era)
trend_pre = double(t_pre2003 > 0) .* t_pre2003;
trend_mining = double(t_post2003 > 0 & t_post2014 == 0) .* t_post2003;
trend_post = double(t_post2014 > 0) .* t_post2014;

fprintf('Piecewise trends:\n');
fprintf('  trend_pre   (1990-2002Q4): max %.2f years\n', max(trend_pre));
fprintf('  trend_mining (2003Q1-2013Q4): max %.2f years\n', max(trend_mining));
fprintf('  trend_post  (2014Q1+): max %.2f years\n', max(trend_post));

%% LHS and PAC ingredients
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
Delta_q_hat = Delta_q - Delta_q_bar;

Delta_log_r_KB_hat = L2.Delta_log_r_KB_wacc - L2.Delta_log_r_KB_wacc_bar;
Delta_log_r_KB_bar = L2.Delta_log_r_KB_wacc_bar;

Delta_df = L2.Delta_df_full;
Delta_df_bar = L2.Delta_df_bar_full;
Delta_df_gap = Delta_df - Delta_df_bar;

[Phi, state_names, ZL_full, ~, ~] = build_block_var('ib', L2, base, 1:L2.nQ);
idx_rKB = find(strcmp(state_names, 'r_KB_gap'));
idx_qhat = find(strcmp(state_names, 'q_hat'));

mkd = @(yyyy, qq) double(year_v == yyyy & q_v == qq);
dummies = [mkd(2000,3), mkd(2000,4), ...
           mkd(2008,4), mkd(2009,1), mkd(2009,2), mkd(2011,3), ...
           L2.del_20Q1, L2.del_20Q2, L2.del_20Q3, L2.del_20Q4];
dummy_names = {'d_2000Q3','d_2000Q4','d_2008Q4','d_2009Q1','d_2009Q2','d_2011Q3', ...
               'd_20Q1','d_20Q2','d_20Q3','d_20Q4'};

%% Iterative OLS with all wp1044 PAC structure preserved + ToT + trends + dummies
omega = 0.35;
beta_0 = 0.096; beta_lags = [0.33; 0.11]; beta_3 = 0.69;
max_iter = 50; tol = 1e-4; damping = 0.5; chi_max = 0.85;

for iter = 1:max_iter
    chi = solve_pac_chi_exact(beta_lags, omega, 2);
    chi = max(0, min(chi_max, chi));

    PV_q_hat   = compute_pv_term(Phi, chi, idx_qhat, ZL_full, 1);
    PV_rKB_hat = compute_pv_term(Phi, chi, idx_rKB, ZL_full, 1);
    PV_q_bar   = lag1(Delta_q_bar);
    PV_rKB_bar = lag1(Delta_log_r_KB_bar);

    sum_b = sum(beta_lags);
    derived = 1 - sum_b - omega;

    % FULL wp1044 PAC LHS adjustment (PV at coef=1, -sigma)
    LHS = dln_ib - PV_q_hat - PV_q_bar ...
                 + sigma * PV_rKB_hat + sigma * PV_rKB_bar ...
                 - derived * lag1(Delta_log_r_KB_bar) ...
                 - derived * lag1(Delta_q_bar);

    % Free regressors: PAC β's + Δdf gap + ToT (level, change, lag) + piecewise trends + dummies
    X = [ones(L2.nQ, 1), lag1(ib_target_minus_actual), ...
         lag1(dln_ib), lagn(dln_ib, 2), ...
         Delta_df_gap, ...
         ToT_demeaned, lag1(ToT_demeaned), dToT, ...           % ToT regressors
         trend_pre, trend_mining, trend_post, ...               % piecewise trends
         dummies];
    names = [{'(intercept)', 'b_0 (ECM)', 'b_1 (lag1)', 'b_2 (lag2)', 'b_3 (Δdf gap)', ...
              'ToT (level, demeaned)', 'ToT lag', 'ΔToT', ...
              'trend_pre (pre-2003)', 'trend_mining (03-13)', 'trend_post (post-14)'}, ...
             dummy_names];

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

%% Final + R^2 on raw
fprintf('--- Variant v5 final (full PAC + ToT + piecewise trends + dummies) ---\n');
for j = 1:length(names)
    fprintf('  %-30s %8.4f (se %.4f, t %.2f)\n', names{j}, b(j), se(j), t(j));
end

y_hat = X * b + PV_q_hat + PV_q_bar - sigma*PV_rKB_hat - sigma*PV_rKB_bar ...
          + derived * lag1(Delta_log_r_KB_bar) + derived * lag1(Delta_q_bar);
valid = ~any(isnan([dln_ib, y_hat]), 2);
ss_total = sum((dln_ib(valid) - mean(dln_ib(valid))).^2);
ss_resid = sum((dln_ib(valid) - y_hat(valid)).^2);
R2_raw = 1 - ss_resid / ss_total;
fprintf('chi = %.4f, R^2 on RAW dln_ib = %.4f *** headline\n', chi, R2_raw);
fprintf('vs wp1044 FR R^2 = 0.83\n');

%% Save
out.block = 'BI (wp1044 PAC + ToT + piecewise trends + dummies)';
out.beta_0 = beta_0; out.beta_lags = beta_lags; out.beta_3 = beta_3;
out.omega = omega; out.chi = chi; out.sigma = sigma;
out.coefs = b; out.se = se; out.tstat = t; out.names = {names};
out.R2_raw = R2_raw; out.N = n_ols; out.n_iter = iter;
out.Phi = Phi; out.state_names = {state_names};
out.converged = (delta < tol);
out.note = 'wp1044 PAC STRICT (PV at coef=1/-sigma) + ToT + piecewise trends + 10 dummies';
save(fullfile(projectdir, 'data', 'pac_blocks', 'results_business_inv_au_v5.mat'), '-struct', 'out');

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
