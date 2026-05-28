%% estimate_trade_exports.m — single-equation OLS for AU exports
%
% Model equation (au_pac.mod line 1303):
%   dln_x_t = b0_x · x_gap_{t-1}
%           + b1_x · dln_x_{t-1}
%           + b2_x · yhat_us_t
%           + b3_x · s_gap_t
%           + b4_x · dln_pcom_t
%           + eps_x
% where x_gap = beta_x · yhat_us + gamma_x · s_gap - ln_x_centered.
%
% ECM-form OLS:
%   dln_x = const + a1·ln_x_centered(-1) + a2·yhat_us(-1) + a3·s_gap(-1)
%         + a4·dln_x(-1) + a5·yhat_us + a6·s_gap + a7·dln_pcom + eps
% Recover:
%   b0_x  = -a1
%   beta_x  = a2 / b0_x
%   gamma_x = a3 / b0_x
%   b1_x = a4, b2_x = a5, b3_x = a6, b4_x = a7

clc;
projectdir = '/Users/davidstephan/Documents/AUSPAC';
addpath(fullfile(projectdir, 'data', 'pac_helpers'));

D = load(fullfile(projectdir, 'data', 'trade_price_data.mat'));
E = load(fullfile(projectdir, 'dynare', 'estimation_data.mat'));
M = load(fullfile(projectdir, 'dynare', 'estimation_meta.mat'));

% Align by quarter key (yyyy*10+q) since different sources use different
% within-quarter datetime conventions.
qkey = @(d) year(d)*10 + ceil(month(d)/3);

master_dates = D.vol_dates;
T = numel(master_dates);
mk = qkey(master_dates);

% dln_x from D.dln_x (vol-aligned)
dln_x   = D.dln_x;
ln_x    = log(D.x_vol);

% yhat_us from estimation_data — align by sample_start
est_start = M.meta.sample_start;
n_est     = numel(E.yhat_us);
est_dates = est_start + calquarters(0:n_est-1);
ek = qkey(est_dates);
yhat_us_full = NaN(T,1);
for t=1:T
    ix = find(ek==mk(t), 1);
    if ~isempty(ix), yhat_us_full(t) = E.yhat_us(ix); end
end

% s_gap
twi_k = qkey(D.q_twi_dates);
s_gap_full = NaN(T,1);
for t=1:T
    ix = find(twi_k==mk(t), 1);
    if ~isempty(ix), s_gap_full(t) = D.s_gap_proxy(ix); end
end

% dln_pcom
pcom_k = qkey(D.q_pcom_dates);
dln_pcom_full = NaN(T,1);
for t=1:T
    ix = find(pcom_k==mk(t), 1);
    if ~isempty(ix), dln_pcom_full(t) = D.dln_pcom(ix); end
end

% Center ln_x by HP-trend (lambda=1600 quarterly). Scale by 100 so units
% match dln_x (which is in q/q %, i.e. 100*log-diff).
ln_x_trend = hp_filter(ln_x, 1600);
ln_x_centered = (ln_x - ln_x_trend) * 100;

%% Lags
lag1 = @(x) [NaN; x(1:end-1)];

X = [ones(T,1), ...
     lag1(ln_x_centered), ...
     lag1(yhat_us_full), ...
     lag1(s_gap_full), ...
     lag1(dln_x), ...
     yhat_us_full, ...
     s_gap_full, ...
     dln_pcom_full];

y = dln_x;
valid = ~any(isnan([X, y]), 2);
fprintf('Exports OLS: %d obs valid out of %d (sample %s..%s)\n', sum(valid), T, ...
        datestr(master_dates(find(valid,1)),'yyyy-Qq'), ...
        datestr(master_dates(find(valid,1,'last')),'yyyy-Qq'));

[b, se, tstat, R2, ~, N] = ols_with_se(X(valid,:), y(valid));

names = {'(intercept)', 'ln_x_centered(-1)', 'yhat_us(-1)', 's_gap(-1)', ...
         'dln_x(-1)', 'yhat_us', 's_gap', 'dln_pcom'};

fprintf('\nExports OLS (wp1044 export equation)\n');
fprintf('Generated %s\n\n', datetime('now'));
fprintf('%-25s  %10s  %10s  %8s\n', 'regressor', 'estimate', 'se', 't');
for k=1:numel(names)
    fprintf('%-25s  %10.4f  %10.4f  %8.2f\n', names{k}, b(k), se(k), tstat(k));
end
fprintf('R^2 = %.4f, N = %d\n', R2, N);

% Recover structural parameters
b0_x_hat    = -b(2);
beta_x_hat  =  b(3) / b0_x_hat;
gamma_x_hat =  b(4) / b0_x_hat;
b1_x_hat    =  b(5);
b2_x_hat    =  b(6);
b3_x_hat    =  b(7);
b4_x_hat    =  b(8);

fprintf('\nRecovered structural parameters:\n');
fprintf('  b0_x    = %+8.4f  (ECM speed)\n', b0_x_hat);
fprintf('  beta_x  = %+8.4f  (LR yhat_us coef, wp1044 calib 1.2)\n', beta_x_hat);
fprintf('  gamma_x = %+8.4f  (LR s_gap coef, wp1044 calib 0.4)\n', gamma_x_hat);
fprintf('  b1_x    = %+8.4f  (dln_x lag, wp1044 0.3)\n', b1_x_hat);
fprintf('  b2_x    = %+8.4f  (yhat_us contemp, wp1044 0.25)\n', b2_x_hat);
fprintf('  b3_x    = %+8.4f  (s_gap contemp, wp1044 0.1)\n', b3_x_hat);
fprintf('  b4_x    = %+8.4f  (dln_pcom, wp1044 0.15)\n', b4_x_hat);

%% Save
out.b = b; out.se = se; out.tstat = tstat; out.R2 = R2; out.N = N;
out.names = names;
out.b0_x = b0_x_hat; out.beta_x = beta_x_hat; out.gamma_x = gamma_x_hat;
out.b1_x = b1_x_hat; out.b2_x = b2_x_hat; out.b3_x = b3_x_hat; out.b4_x = b4_x_hat;
save(fullfile(projectdir, 'data', 'pac_blocks', 'results_exports.mat'), '-struct', 'out');

fid = fopen(fullfile(projectdir, 'data', 'pac_blocks', 'results_exports.txt'), 'w');
fprintf(fid, 'Exports OLS (wp1044 export equation)\n');
fprintf(fid, 'Generated %s\n\n', datetime('now'));
fprintf(fid, '%-25s  %10s  %10s  %8s\n', 'regressor', 'estimate', 'se', 't');
for k=1:numel(names)
    fprintf(fid, '%-25s  %10.4f  %10.4f  %8.2f\n', names{k}, b(k), se(k), tstat(k));
end
fprintf(fid, 'R^2 = %.4f, N = %d\n\n', R2, N);
fprintf(fid, 'Recovered structural parameters:\n');
fprintf(fid, '  b0_x    = %+8.4f\n  beta_x  = %+8.4f\n  gamma_x = %+8.4f\n', b0_x_hat, beta_x_hat, gamma_x_hat);
fprintf(fid, '  b1_x    = %+8.4f\n  b2_x    = %+8.4f\n  b3_x    = %+8.4f\n  b4_x    = %+8.4f\n', b1_x_hat, b2_x_hat, b3_x_hat, b4_x_hat);
fclose(fid);

fprintf('\nWrote results_exports.mat + .txt\n');

function trend = hp_filter(y, lambda)
    n = numel(y); valid = ~isnan(y);
    if sum(valid) < 4, trend = NaN(n,1); return; end
    yv = y(valid); m = numel(yv);
    I = speye(m);
    D = spdiags([ones(m,1), -2*ones(m,1), ones(m,1)], 0:2, m-2, m);
    A = I + lambda * (D' * D);
    tv = A \ yv;
    trend = NaN(n,1); trend(valid) = tv;
end
