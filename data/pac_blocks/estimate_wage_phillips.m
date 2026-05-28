%% estimate_wage_phillips.m — single-equation OLS for wage Phillips curve
%
% Model equation (au_pac.mod line 1180):
%   pi_w_t = lambda_w · pi_w_{t-1} + gamma_w · pi_c_t - kappa_w · pv_u_gap_t
%          + (1 - lambda_w - gamma_w) · pibar_au_t
%          + (1 - lambda_w) · dln_prod_t + eps_w
%
% We use u_gap as a static proxy for pv_u_gap (the discounted PV would
% require model-consistent expectation, which OLS doesn't have).
% u_gap = u_rate - HP_trend(u_rate).
%
% Reform:
%   pi_w - pibar - (1-lambda_w)*dln_prod = lambda_w*(pi_w(-1) - pibar) + gamma_w*(pi_c - pibar) - kappa_w*u_gap
% But (1-lambda_w) requires knowing lambda_w. Use linear form:
%   pi_w = a0 + a1*pi_w(-1) + a2*pi_c + a3*pibar + a4*u_gap + a5*dln_prod + eps
% Recover: lambda_w = a1, gamma_w = a2, kappa_w = -a4, and check a3 ≈ 1-a1-a2.
% dln_prod coef should be ≈ 1-a1.

clc;
projectdir = '/Users/davidstephan/Documents/AUSPAC';
addpath(fullfile(projectdir, 'data', 'pac_helpers'));

E = load(fullfile(projectdir, 'dynare', 'estimation_data.mat'));
M = load(fullfile(projectdir, 'dynare', 'estimation_meta.mat'));
S = load(fullfile(projectdir, 'dynare', 'supply_data.mat'));
L = load(fullfile(projectdir, 'data', 'l2_data_layer_v2.mat'));

% Build series aligned to estimation_data sample (122 obs, 1993Q2..2023Q3)
T = numel(E.pi_w);
qkey = @(d) year(d)*10 + ceil(month(d)/3);
est_start = M.meta.sample_start;
est_dates = est_start + calquarters(0:T-1);
ek = qkey(est_dates);

% pi_w from estimation_data (q/q %)
pi_w = E.pi_w(:);

% pi_au as proxy for pi_c (CPI inflation, percent q/q). Already in gap form
% in estimation_data — undo by adding back pibar.
% Build raw pi_au_full = pi_au_gap + pibar_au_trend  (use L2 pi_au_trend)
lk = qkey(L.dates);
pibar = NaN(T,1);
for t=1:T
    ix = find(lk==ek(t),1);
    if ~isempty(ix), pibar(t) = L.pi_au_trend(ix); end
end
pi_au_raw = E.pi_au(:) + pibar;    % approx CPI inflation
pi_c = pi_au_raw;

% u_gap: from L2's u_hat (urate - urate_trend)
u_hat = NaN(T,1);
for t=1:T
    ix = find(lk==ek(t),1);
    if ~isempty(ix), u_hat(t) = L.u_hat(ix); end
end

% dln_prod from supply (q_total / n_total)
prod_lvl = S.q_total_lvl ./ S.n_total_lvl;
if isfield(S,'dates'), sk = qkey(S.dates);
else, sdates = datetime(1990,1,1) + calquarters(0:numel(prod_lvl)-1); sk = qkey(sdates); end
dln_prod_arr = [NaN; diff(log(prod_lvl))*100];
dln_prod = NaN(T,1);
for t=1:T
    ix = find(sk==ek(t),1);
    if ~isempty(ix), dln_prod(t) = dln_prod_arr(ix); end
end

%% OLS
lag1 = @(x) [NaN; x(1:end-1)];
X = [ones(T,1), lag1(pi_w), pi_c, pibar, u_hat, dln_prod];
y = pi_w;

valid = ~any(isnan([X, y]),2);
fprintf('Wage Phillips OLS: %d obs valid out of %d\n', sum(valid), T);

[b,se,tstat,R2,~,N] = ols_with_se(X(valid,:), y(valid));

names = {'(intercept)', 'pi_w(-1)', 'pi_c', 'pibar_au', 'u_hat', 'dln_prod'};
fprintf('\nWage Phillips OLS (wp1044 Eq 24)\n');
fprintf('Generated %s\n\n', datetime('now'));
fprintf('%-15s  %10s  %10s  %8s\n', 'regressor', 'estimate', 'se', 't');
for k=1:numel(names)
    fprintf('%-15s  %10.4f  %10.4f  %8.2f\n', names{k}, b(k), se(k), tstat(k));
end
fprintf('R^2 = %.4f, N = %d\n', R2, N);

lambda_w_hat = b(2);
gamma_w_hat  = b(3);
kappa_w_hat  = -b(5);     % equation has -kappa_w*u_gap

fprintf('\nRecovered structural parameters:\n');
fprintf('  lambda_w = %+8.4f  (wp1044/AU prior 0.20-0.25)\n', lambda_w_hat);
fprintf('  gamma_w  = %+8.4f  (CPI passthrough, prior 0.45-0.66)\n', gamma_w_hat);
fprintf('  kappa_w  = %+8.4f  (unemployment slope, prior +0.05 to +0.06)\n', kappa_w_hat);
fprintf('  pibar coef = %.4f vs implied 1-lambda-gamma = %.4f\n', b(4), 1-lambda_w_hat-gamma_w_hat);
fprintf('  dln_prod coef = %.4f vs implied 1-lambda = %.4f\n', b(6), 1-lambda_w_hat);

%% Save
out.b = b; out.se = se; out.tstat = tstat; out.R2 = R2; out.N = N;
out.names = names;
out.lambda_w = lambda_w_hat; out.gamma_w = gamma_w_hat; out.kappa_w = kappa_w_hat;
save(fullfile(projectdir, 'data', 'pac_blocks', 'results_wage_phillips.mat'), '-struct', 'out');

fid = fopen(fullfile(projectdir, 'data', 'pac_blocks', 'results_wage_phillips.txt'), 'w');
fprintf(fid, 'Wage Phillips OLS (wp1044 Eq 24)\nGenerated %s\n\n', datetime('now'));
fprintf(fid, '%-15s  %10s  %10s  %8s\n', 'regressor', 'estimate', 'se', 't');
for k=1:numel(names)
    fprintf(fid, '%-15s  %10.4f  %10.4f  %8.2f\n', names{k}, b(k), se(k), tstat(k));
end
fprintf(fid, 'R^2 = %.4f, N = %d\n', R2, N);
fprintf(fid, '\nRecovered:\n  lambda_w = %.4f\n  gamma_w = %.4f\n  kappa_w = %.4f\n', ...
        lambda_w_hat, gamma_w_hat, kappa_w_hat);
fclose(fid);
fprintf('\nWrote results_wage_phillips.mat + .txt\n');
