%% compare_pv_vs_naive.m  --  PV-vs-naive OLS diagnostic across 5 PAC blocks
%
% Phase L2 step 3 (refactor/frbdf-replication-L2 branch).  For each of the
% 5 PAC blocks, runs the OLS twice -- once with the wp1044 closed-form PV
% term for the block's relevant PV target, and once with a "naive" lag-
% only proxy -- and reports whether the wp1044 PV machinery shifts b_PAC.
%
% The headline question: is the wp1044 PV term doing identifiable work
% in AU data, or is it captured by simpler lagged regressors?
%
% For each block:
%   Naive spec:    intercept + yhat_au lag + LHS lag + yhat_au contemp
%                  + i_10y lag + block-specific trend
%   PV spec:       same as naive + PV(block-specific PV target)
%
% PV target by block (wp1044):
%   pQ (Eq 16):  PV target ≈ piQ_hat -- here we use PV(pi_au) as proxy
%   n  (Eq 30):  PV target ≈ n_hat   -- use PV(yhat_au) as proxy
%   c  (Eq 35):  PV target = y_H - ȳ -- use PV(y_H_gap) where y_H_gap
%                                       is au_wt_H_real_gap
%   ib (Eq 46):  PV target ≈ q̄_t    -- use PV(dq_bar_gap) (low varies)
%   ih (Eq 37):  PV target ≈ Ī*_H,t  -- use PV(dlogIH_bar_gap) (low varies)
%
% VAR(1) state for PV computation (same across blocks for comparability):
%   z = [yhat_au, pi_au, i_au, i_10y, y_H_gap]
%
% chi (PV discount factor) = 0.50 -- the wp1044 standard.
%
% Inputs:
%   dynare/estimation_data.mat
%   data/extended_dataset.csv
%   data/trend_series.mat
%   data/consumption_pac_ols.mat       (L2-pilot Spec 4)
%   data/consumption_pac_full.mat      (step 1 PV-augmented OLS)
%   data/pac_blocks_ols.mat            (step 2 OLS for 4 other blocks)
%   data/l13a_chain1_posterior.mat     (L1.3a chain 1 baseline)
% Output:
%   data/pv_vs_naive_summary.txt
%   stdout summary table

clear; clc;
fprintf('=== L2 step 3: PV-vs-naive diagnostic across 5 PAC blocks ===\n\n');

projectdir = fullfile(fileparts(mfilename('fullpath')), '..');

%% Load
D = load(fullfile(projectdir, 'dynare', 'estimation_data.mat'));
T_ext = readtable(fullfile(projectdir, 'data', 'extended_dataset.csv'));
TS = load(fullfile(projectdir, 'data', 'trend_series.mat'));

% Aligned sample
sample_idx = 2:123;
nObs = length(sample_idx);

% From estimation_data.mat
yhat_au    = D.yhat_au;
pi_au      = D.pi_au;
i_au       = D.i_au;
i_10y      = D.i_10y;
dln_c      = D.dln_c;
dln_ib     = D.dln_ib;
dy_bar_gap = D.dy_bar_gap;

% y_H_gap from extended_dataset.csv
y_H_gap = demean(T_ext.au_wt_H_real_gap(sample_idx));

% Trend objects from trend_series.mat (aligned and demeaned in q/q %)
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

% LHS variables
au_employment = T_ext.au_employment(sample_idx);
au_gfcf_dwell = T_ext.au_gfcf_dwelling(sample_idx);
dln_n  = demean([NaN; diff(log(au_employment))] * 100);
dln_ih = demean([NaN; diff(log(au_gfcf_dwell))] * 100);

%% Build VAR(1) Phi on z = [yhat_au, pi_au, i_au, i_10y, y_H_gap]
Z = [yhat_au, pi_au, i_au, i_10y, y_H_gap];
state_names = {'yhat_au', 'pi_au', 'i_au', 'i_10y', 'y_H_gap'};
k = size(Z, 2);

valid_Z = ~any(isnan(Z), 2);
Z_use = Z(valid_Z, :);
Z_lag = Z_use(1:end-1, :);
Z_t   = Z_use(2:end, :);
Phi = ((Z_lag' * Z_lag) \ (Z_lag' * Z_t))';   % 5x5

chi = 0.50;
PV_op = (eye(k) - chi * Phi) \ Phi;
fprintf('VAR(1) Phi spectral radius: %.4f, chi = %.2f\n', max(abs(eig(Phi))), chi);
fprintf('||(I-chi*Phi)||_2 = %.2f (well-conditioned).\n\n', norm(eye(k)-chi*Phi, 2));

% PV(state_var) time series, aligned to full T
ZL_full = nan(nObs, k);
v_idx = find(valid_Z);
for ii = 2:length(v_idx)
    ZL_full(v_idx(ii), :) = Z_use(ii-1, :);
end
PV_z = (PV_op * ZL_full')';   % nObs x k

i_yhat = find(strcmp(state_names, 'yhat_au'));
i_pi   = find(strcmp(state_names, 'pi_au'));
i_yH   = find(strcmp(state_names, 'y_H_gap'));

PV_yhat   = PV_z(:, i_yhat);
PV_pi     = PV_z(:, i_pi);
PV_yH     = PV_z(:, i_yH);

%% Block specifications
% Each block: {block_name, LHS, LHS_lag, trend_lag, PV_target, prior_pacname}
blocks = {};
blocks{end+1} = struct('name','consumption',  'lhs', dln_c,   'lhs_lag', lag1(dln_c),   ...
                       'trend_lag', lag1(dy_bar_gap),   'PV_proxy', PV_yH,  'pac_name', 'b_PAC_c');
blocks{end+1} = struct('name','VA-price',     'lhs', pi_au,   'lhs_lag', lag1(pi_au),   ...
                       'trend_lag', lag1(pi_Q_bar),     'PV_proxy', PV_pi,  'pac_name', 'b_PAC_pQ');
blocks{end+1} = struct('name','employment',   'lhs', dln_n,   'lhs_lag', lag1(dln_n),   ...
                       'trend_lag', lag1(dn_bar),       'PV_proxy', PV_yhat,'pac_name', 'b_PAC_n');
blocks{end+1} = struct('name','business inv', 'lhs', dln_ib,  'lhs_lag', lag1(dln_ib),  ...
                       'trend_lag', lag1(dq_bar),       'PV_proxy', PV_yhat,'pac_name', 'b_PAC_ib');
blocks{end+1} = struct('name','housing inv',  'lhs', dln_ih,  'lhs_lag', lag1(dln_ih),  ...
                       'trend_lag', lag1(dlogIH_bar),   'PV_proxy', PV_yhat,'pac_name', 'b_PAC_ih');

%% Run naive + PV specs for each block
n_blocks = length(blocks);
summary = struct();
summary.block       = cell(n_blocks, 1);
summary.b_PAC_naive = zeros(n_blocks, 1);
summary.se_naive    = zeros(n_blocks, 1);
summary.b_PAC_PV    = zeros(n_blocks, 1);
summary.se_PV       = zeros(n_blocks, 1);
summary.gamma_PV    = zeros(n_blocks, 1);
summary.se_gamma_PV = zeros(n_blocks, 1);
summary.t_gamma_PV  = zeros(n_blocks, 1);
summary.R2_naive    = zeros(n_blocks, 1);
summary.R2_PV       = zeros(n_blocks, 1);
summary.b_PAC_shift = zeros(n_blocks, 1);

for j = 1:n_blocks
    blk = blocks{j};
    fprintf('--- %s ---\n', blk.name);

    % Naive spec (matches step 2 / L2-pilot Spec 4 template)
    X_naive = [ones(nObs,1), lag1(yhat_au), blk.lhs_lag, yhat_au, lag1(i_10y), blk.trend_lag];
    [b_n, se_n, t_n, R2_n, ~, ~] = ols(X_naive, blk.lhs);

    % PV-augmented spec
    X_PV = [X_naive, blk.PV_proxy];
    [b_PV, se_PV, t_PV, R2_PV, ~, ~] = ols(X_PV, blk.lhs);

    fprintf('  Naive:  b_PAC = %7.4f (se %6.4f, t %5.2f), R^2 = %.3f\n', ...
        b_n(end), se_n(end), t_n(end), R2_n);
    fprintf('  PV:     b_PAC = %7.4f (se %6.4f, t %5.2f), R^2 = %.3f\n', ...
        b_PV(end-1), se_PV(end-1), t_PV(end-1), R2_PV);
    fprintf('  gamma_PV = %7.4f (se %6.4f, t %5.2f)\n', ...
        b_PV(end), se_PV(end), t_PV(end));
    delta = b_PV(end-1) - b_n(end);
    delta_pct = 100 * delta / abs(b_n(end));
    fprintf('  b_PAC shift naive -> PV: %+.4f (%.1f%%)\n\n', delta, delta_pct);

    summary.block{j}       = blk.name;
    summary.b_PAC_naive(j) = b_n(end);
    summary.se_naive(j)    = se_n(end);
    summary.b_PAC_PV(j)    = b_PV(end-1);
    summary.se_PV(j)       = se_PV(end-1);
    summary.gamma_PV(j)    = b_PV(end);
    summary.se_gamma_PV(j) = se_PV(end);
    summary.t_gamma_PV(j)  = t_PV(end);
    summary.R2_naive(j)    = R2_n;
    summary.R2_PV(j)       = R2_PV;
    summary.b_PAC_shift(j) = delta;
end

%% Summary table
fprintf('\n\n');
fprintf('=== SUMMARY: PV-vs-naive across 5 PAC blocks ===\n\n');
fprintf('%-15s %12s %12s %10s %10s %8s %8s\n', ...
    'Block', 'b_PAC naive', 'b_PAC + PV', 'shift', 'gamma_PV', 't(PV)', 'ΔR^2');
fprintf('%-15s %12s %12s %10s %10s %8s %8s\n', ...
    '-----', '-----------', '----------', '-----', '--------', '-----', '----');
for j = 1:n_blocks
    fprintf('%-15s %12.4f %12.4f %+10.4f %10.4f %8.2f %+8.3f\n', ...
        summary.block{j}, summary.b_PAC_naive(j), summary.b_PAC_PV(j), ...
        summary.b_PAC_shift(j), summary.gamma_PV(j), summary.t_gamma_PV(j), ...
        summary.R2_PV(j) - summary.R2_naive(j));
end

%% Interpretation
fprintf('\n\nInterpretation:\n');
n_PV_sig = sum(abs(summary.t_gamma_PV) > 1.96);
fprintf('  PV term significant at |t|>1.96 in %d of %d blocks.\n', n_PV_sig, n_blocks);
n_shift_big = sum(abs(summary.b_PAC_shift ./ summary.b_PAC_naive) > 0.25);
fprintf('  b_PAC shifts by >25%% (naive -> PV) in %d of %d blocks.\n', n_shift_big, n_blocks);

if n_PV_sig == 0
    fprintf('  -> wp1044 PV terms are NOT carrying identifiable signal in AU data.\n');
    fprintf('     The block-by-block partial L2 OLS gives the same headline b_PAC\n');
    fprintf('     with or without the PV machinery.  Simplification is justified.\n');
elseif n_PV_sig >= 3
    fprintf('  -> wp1044 PV terms add signal in most blocks.  The full wp1044\n');
    fprintf('     spec is needed for clean inference.\n');
else
    fprintf('  -> Mixed: PV matters in some blocks, not others.  Block-specific\n');
    fprintf('     decision about whether to keep PV terms.\n');
end

%% Save
out = struct('summary', summary, 'chi', chi, 'Phi', Phi, ...
    'state_names', {state_names});
save(fullfile(projectdir, 'data', 'pv_vs_naive.mat'), '-struct', 'out');

fid = fopen(fullfile(projectdir, 'data', 'pv_vs_naive_summary.txt'), 'w');
fprintf(fid, 'L2 step 3: PV-vs-naive OLS diagnostic across 5 PAC blocks\n');
fprintf(fid, 'Generated %s\n\n', datestr(now));
fprintf(fid, 'VAR(1) state for PV computation: [%s]\n', strjoin(state_names, ', '));
fprintf(fid, 'PV discount factor chi = %.2f, Phi spectral radius = %.4f\n\n', ...
    chi, max(abs(eig(Phi))));
fprintf(fid, '%-15s %12s %12s %10s %10s %8s %8s\n', ...
    'Block', 'b_PAC naive', 'b_PAC + PV', 'shift', 'gamma_PV', 't(PV)', 'dR^2');
fprintf(fid, '%-15s %12s %12s %10s %10s %8s %8s\n', ...
    '-----', '-----------', '----------', '-----', '--------', '-----', '----');
for j = 1:n_blocks
    fprintf(fid, '%-15s %12.4f %12.4f %+10.4f %10.4f %8.2f %+8.3f\n', ...
        summary.block{j}, summary.b_PAC_naive(j), summary.b_PAC_PV(j), ...
        summary.b_PAC_shift(j), summary.gamma_PV(j), summary.t_gamma_PV(j), ...
        summary.R2_PV(j) - summary.R2_naive(j));
end
fprintf(fid, '\nInterpretation:\n');
fprintf(fid, '  PV term significant at |t|>1.96 in %d of %d blocks.\n', n_PV_sig, n_blocks);
fprintf(fid, '  b_PAC shifts by >25%% (naive -> PV) in %d of %d blocks.\n\n', n_shift_big, n_blocks);
if n_PV_sig == 0
    fprintf(fid, 'Conclusion: wp1044 PV terms are NOT carrying identifiable signal in AU\n');
    fprintf(fid, 'data.  Block-by-block partial L2 OLS gives the same headline b_PAC\n');
    fprintf(fid, 'with or without the PV machinery.  The simpler lag-only spec is\n');
    fprintf(fid, 'sufficient for inference on the trend coefficients.\n');
end
fclose(fid);
fprintf('\nSaved data/pv_vs_naive.mat + pv_vs_naive_summary.txt\n');
fprintf('\n=== Done. ===\n');

%% --- Helpers ---
function y = lag1(x), y = [NaN; x(1:end-1)]; end
function v = demean(x), v = x - mean(x, 'omitnan'); end
function v = extract_aligned(src, idx)
    v = nan(length(idx), 1);
    ok = ~isnan(idx);
    v(ok) = src(idx(ok));
end
function [b, se, t, R2, rss, n] = ols(X, y)
    valid = ~any(isnan([X, y]), 2);
    X = X(valid, :);
    y = y(valid);
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
