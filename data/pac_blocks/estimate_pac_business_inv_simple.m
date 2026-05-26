%% estimate_pac_business_inv_simple.m
%
% Simplified business inv spec.  The full wp1044 Eq 46 has 11 free
% parameters on a 120-obs sample where AU data has commodity-cycle
% effects not in wp1044's structure.  This script tries minimum-spec
% variants to find what AU business inv DOES respond to.
%
% Spec variants (run in sequence, increasingly simple):
%   S1: full wp1044 Eq 46 (baseline; what we've been running)
%   S2: drop trend PV terms (PV(Δq̄) and PV(Δlog r̄_KB))
%   S3: drop ALL PV terms; just lags + df + dummies
%   S4: depth-1 PAC (drop b_2 lag)
%   S5: drop ECM term

clear; clc;
fprintf('=== Phase L2 P1b: business inv simplified spec search ===\n\n');

projectdir = fullfile(fileparts(mfilename('fullpath')), '..', '..');
addpath(fullfile(projectdir, 'data', 'pac_helpers'));

%% Load
L2 = load(fullfile(projectdir, 'data', 'l2_data_layer_v2.mat'));
S = load(fullfile(projectdir, 'dynare', 'supply_data.mat'));
base = readtable(fullfile(projectdir, 'dataset.csv'));
ext = readtable(fullfile(projectdir, 'data', 'extended_dataset.csv'));

ext_dates = datetime(ext.date);
au_ib = align_q(ext.au_gfcf_nondwelling, ext_dates, L2.dates);
log_ib = log(au_ib);
dln_ib = [NaN; diff(log_ib)] * 100;
log_ib_trend = hp_trend_local(log_ib, 1600);
ib_target_minus_actual = -((log_ib - log_ib_trend) * 100);

Delta_df_gap = L2.Delta_df_full - L2.Delta_df_bar_full;

d20q1 = L2.del_20Q1; d20q2 = L2.del_20Q2; d20q3 = L2.del_20Q3;

%% S3: simplest spec -- LHS = dln_ib, regressors: lags + df + dummies
fprintf('--- Spec S3: no PV, no ECM, just lags + df + dummies ---\n');
X = [ones(L2.nQ, 1), lag1(dln_ib), lagn(dln_ib, 2), ...
     Delta_df_gap, d20q1, d20q2, d20q3];
names = {'(intercept)', 'b1', 'b2', 'b3 (Δdf gap)', 'd20q1', 'd20q2', 'd20q3'};
[b, se, t, R2, ~, n] = ols_with_se(X, dln_ib);
for j=1:length(names), fprintf('  %-22s %8.4f (se %.4f, t %.2f)\n', names{j}, b(j), se(j), t(j)); end
fprintf('  R^2 = %.4f, N = %d\n\n', R2, n);

%% S3b: + ECM
fprintf('--- Spec S3b: + ECM term ---\n');
X = [ones(L2.nQ, 1), lag1(ib_target_minus_actual), lag1(dln_ib), lagn(dln_ib, 2), ...
     Delta_df_gap, d20q1, d20q2, d20q3];
names = {'(intercept)', 'b0 (ECM)', 'b1', 'b2', 'b3 (Δdf gap)', 'd20q1', 'd20q2', 'd20q3'};
[b, se, t, R2, ~, n] = ols_with_se(X, dln_ib);
for j=1:length(names), fprintf('  %-22s %8.4f (se %.4f, t %.2f)\n', names{j}, b(j), se(j), t(j)); end
fprintf('  R^2 = %.4f, N = %d\n\n', R2, n);

%% S4: depth-1 (drop lag 2)
fprintf('--- Spec S4: depth-1 PAC ---\n');
X = [ones(L2.nQ, 1), lag1(ib_target_minus_actual), lag1(dln_ib), ...
     Delta_df_gap, d20q1, d20q2, d20q3];
names = {'(intercept)', 'b0 (ECM)', 'b1', 'b3 (Δdf gap)', 'd20q1', 'd20q2', 'd20q3'};
[b, se, t, R2, ~, n] = ols_with_se(X, dln_ib);
for j=1:length(names), fprintf('  %-22s %8.4f (se %.4f, t %.2f)\n', names{j}, b(j), se(j), t(j)); end
fprintf('  R^2 = %.4f, N = %d\n\n', R2, n);

%% S5: + commodity price proxy (AU mining cycle hypothesis)
% AU commodities not in our data; use yhat_us as a foreign demand proxy
fprintf('--- Spec S5: + yhat_us as foreign demand proxy ---\n');
yhat_us = align_q(base.us_ygap, datetime(base.date), L2.dates);
X = [ones(L2.nQ, 1), lag1(ib_target_minus_actual), lag1(dln_ib), ...
     Delta_df_gap, yhat_us, lag1(yhat_us), d20q1, d20q2, d20q3];
names = {'(intercept)', 'b0 (ECM)', 'b1', 'b3 (Δdf gap)', 'yhat_us', 'yhat_us lag', 'd20q1', 'd20q2', 'd20q3'};
[b, se, t, R2, ~, n] = ols_with_se(X, dln_ib);
for j=1:length(names), fprintf('  %-22s %8.4f (se %.4f, t %.2f)\n', names{j}, b(j), se(j), t(j)); end
fprintf('  R^2 = %.4f, N = %d\n\n', R2, n);

%% S6: + i_10y (long rate; capital cost)
fprintf('--- Spec S6: + i_10y as cost-of-capital proxy ---\n');
i_10y = align_q(ext.au_i10, ext_dates, L2.dates);
X = [ones(L2.nQ, 1), lag1(ib_target_minus_actual), lag1(dln_ib), ...
     Delta_df_gap, lag1(i_10y), d20q1, d20q2, d20q3];
names = {'(intercept)', 'b0 (ECM)', 'b1', 'b3 (Δdf gap)', 'i_10y_lag', 'd20q1', 'd20q2', 'd20q3'};
[b, se, t, R2, ~, n] = ols_with_se(X, dln_ib);
for j=1:length(names), fprintf('  %-22s %8.4f (se %.4f, t %.2f)\n', names{j}, b(j), se(j), t(j)); end
fprintf('  R^2 = %.4f, N = %d\n\n', R2, n);

fprintf('=== Done ===\n');

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
