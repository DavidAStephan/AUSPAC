%% estimate_pac_housing_inv.m  --  wp1044 §3.5.2 Eq 37 faithful (partial) rebuild
%
% Phase L2-C4: Housing investment PAC equation.
%
% wp1044 Eq 37:
%   Delta log I_H,t = beta_0 log(I*_H,t-1 / I_H,t-1)         ECM
%                   + beta_1 Delta log I_H,t-1                 lag (depth=1)
%                   + PV(Delta log I_hat*_H)_{t|t-1}            gap PV, coef=1
%                   - PV(Delta log I_bar*_H)_{t|t-1}            trend PV, coef=-1
%                   + (1 - beta_1 - omega) Delta log I_bar*_H,t  derived,
%                                                                 CONTEMPORANEOUS
%                   + beta_2 (Delta y_t - y_tilde_t)              contemp output growth
%                                                                 gap
%                   + beta_3 [(pSH-pIH)_{t-1} - (pSH-pIH)_{t-5}]  price spread
%                                                                 (SKIPPED -- no AU data)
%                   + 4 COVID dummies (20Q1, 20Q2, 20Q3, 21Q2)
%
% wp1044 Table 3.5.7: beta_0=0.12, beta_1=0.18, beta_2=0.50, beta_3=0.05,
% omega=0.05 (implied), R^2 = 0.89.
%
% AU adaptations:
%   - LHS = dlog(au_gfcf_dwelling) * 100
%   - I*_H proxy: HP trend of log(au_gfcf_dwelling) (no LR target equation
%     since wp1044 Eq 36 needs price terms we don't have)
%   - Price spread term DROPPED (BLOCK_LIMITATIONS.md)
%   - Damping + clamps from consumption block

clear; clc;
fprintf('=== Phase L2-C4: Housing inv PAC (wp1044 Eq 37 partial) ===\n\n');

projectdir = fullfile(fileparts(mfilename('fullpath')), '..', '..');
addpath(fullfile(projectdir, 'data', 'pac_helpers'));

%% Load
v2_path = fullfile(projectdir, 'data', 'l2_data_layer_v2.mat');
if isfile(v2_path)
    L2 = load(v2_path);
    fprintf('Using l2_data_layer_v2.mat (with p_IH from ABS 5206 IPD)\n');
else
    L2 = load(fullfile(projectdir, 'data', 'l2_data_layer.mat'));
end
base = readtable(fullfile(projectdir, 'dataset.csv'));
ext = readtable(fullfile(projectdir, 'data', 'extended_dataset.csv'));

% LHS + variables
ext_dates = datetime(ext.date);
au_ih = align_q(ext.au_gfcf_dwelling, ext_dates, L2.dates);
log_ih = log(au_ih);
dln_ih = [NaN; diff(log_ih)] * 100;

% I_H target proxy: HP trend of log_ih (× 100 for pp scale)
log_ih_trend = hp_trend_local(log_ih, 1600);
ih_log_gap = (log_ih - log_ih_trend) * 100;     % positive when above trend
ih_target_minus_actual = -ih_log_gap;            % wp1044's log(I*/I)

% Delta log I_bar*_H = HP trend of dln_ih
Delta_log_IH_bar = hp_trend_local(dln_ih, 1600);

% Delta y - y_tilde (output growth gap above trend)
base_dates = datetime(base.date);
yhat_au_full = align_q(base.au_ygap, base_dates, L2.dates);
% Delta y = diff of log GDP volume.  We have q_total_lvl in supply data.
S = load(fullfile(projectdir, 'dynare', 'supply_data.mat'));
dlog_y = [NaN; diff(S.q_total_lvl)] * 100;
y_tilde = L2.y_tilde;
Delta_y_minus_tilde = dlog_y - y_tilde;

% Dummies (wp1044 uses 20Q1, 20Q2, 20Q3, 21Q2)
d20q1 = L2.del_20Q1; d20q2 = L2.del_20Q2; d20q3 = L2.del_20Q3;
d21q2 = L2.del_21Q2;

%% Aux VAR for the block
[Phi, state_names, ZL_full, ~, n_var] = build_block_var('ih', L2, base, 1:L2.nQ);
idx_IH = find(strcmp(state_names, 'IH_gap'));
fprintf('Aux VAR: %d obs, state [%s], Phi rho=%.4f\n\n', ...
    n_var, strjoin(state_names, ', '), max(abs(eig(Phi))));

%% Iterative OLS
omega = 0.05;     % wp1044 implied
beta_0 = 0.12;
beta_1 = 0.18;
beta_2 = 0.50;

max_iter = 50;
tol = 1e-4;
history = [];
depth = 1;
damping = 0.5;
chi_max = 0.85;

for iter = 1:max_iter
    chi = solve_pac_chi_exact([beta_1], omega, depth);
    chi = max(0, min(chi_max, chi));

    PV_IH_gap = compute_pv_term(Phi, chi, idx_IH, ZL_full, 1);
    % Approximate trend PV with HP_trend of Delta_log_IH_bar projection
    % (wp1044 has separate gap-vs-trend decomposition; AU proxy uses just
    %  the HP-trend object directly as the "trend PV")
    PV_IH_trend = lag1(Delta_log_IH_bar);

    derived_coef = 1 - beta_1 - omega;

    % LHS - PV_gap (coef=+1) + PV_trend (coef=-1) - derived * Delta_log_IH_bar_t
    LHS = dln_ih - PV_IH_gap + PV_IH_trend - derived_coef * Delta_log_IH_bar;

    X = [ones(L2.nQ, 1), lag1(ih_target_minus_actual), lag1(dln_ih), ...
         Delta_y_minus_tilde, d20q1, d20q2, d20q3, d21q2];
    names_free = {'(intercept)', 'beta_0 (ECM I*_H-I_H lag)', 'beta_1 (Δlog I_H lag)', ...
                  'beta_2 (Δy - y_tilde contemp)', 'd_20Q1', 'd_20Q2', 'd_20Q3', 'd_21Q2'};

    [b, se, tstat, R2, ~, n_ols] = ols_with_se(X, LHS);
    beta_0_new = max(0.01, min(0.80, damping * b(2) + (1-damping) * beta_0));
    beta_1_new = max(0.01, min(0.50, damping * b(3) + (1-damping) * beta_1));
    beta_2_new = damping * b(4) + (1-damping) * beta_2;

    delta = norm([beta_0_new - beta_0, beta_1_new - beta_1, beta_2_new - beta_2]);
    history(iter, :) = [iter, beta_0_new, beta_1_new, beta_2_new, chi, R2, delta];
    fprintf('iter %2d: b0=%.4f, b1=%.4f, b2=%.4f, chi=%.4f, R^2=%.3f, ||d||=%.5f\n', ...
        iter, beta_0_new, beta_1_new, beta_2_new, chi, R2, delta);
    beta_0 = beta_0_new; beta_1 = beta_1_new; beta_2 = beta_2_new;
    if delta < tol, fprintf('Converged at iter %d.\n\n', iter); break; end
end

%% Final
fprintf('--- Housing inv block final ---\n');
for j = 1:length(names_free)
    fprintf('%-30s %12.4f %12.4f %8.2f\n', names_free{j}, b(j), se(j), tstat(j));
end
fprintf('chi = %.4f, omega = %.2f, derived_coef = %.4f, R^2 = %.4f, N = %d\n', ...
    chi, omega, 1 - beta_1 - omega, R2, n_ols);

fprintf('\nvs wp1044 Table 3.5.7: b0=0.12, b1=0.18, b2=0.50, R^2=0.89\n');
fprintf('Note: beta_3 price-spread term SKIPPED (no AU pSH/pIH data; see BLOCK_LIMITATIONS.md)\n');

%% Save
out.block = 'Housing inv (wp1044 Eq 37, partial)';
out.beta_0 = beta_0; out.beta_1 = beta_1; out.beta_2 = beta_2;
out.omega = omega; out.chi = chi;
out.coefs = b; out.se = se; out.tstat = tstat; out.names = {names_free};
out.R2 = R2; out.N = n_ols; out.n_iter = iter; out.history = history;
out.state_names = {state_names}; out.Phi = Phi;
out.converged = (delta < tol);
out.note = 'price-spread (pSH-pIH) term skipped; no AU data';
save(fullfile(projectdir, 'data', 'pac_blocks', 'results_housing_inv.mat'), '-struct', 'out');

fid = fopen(fullfile(projectdir, 'data', 'pac_blocks', 'results_housing_inv.txt'), 'w');
fprintf(fid, 'Housing inv PAC iterative OLS (wp1044 Eq 37 partial)\n');
fprintf(fid, 'Generated %s\n\n', datestr(now));
for j = 1:length(names_free)
    fprintf(fid, '%-30s %12.4f %12.4f %8.2f\n', names_free{j}, b(j), se(j), tstat(j));
end
fprintf(fid, 'chi=%.4f, R^2=%.4f, N=%d\n', chi, R2, n_ols);
fprintf(fid, '\nwp1044 FR: b0=0.12, b1=0.18, b2=0.50, R^2=0.89\n');
fprintf(fid, 'PARTIAL: beta_3 price spread skipped (no AU pSH/pIH data)\n');
fclose(fid);

fprintf('\n=== Phase L2-C4 complete ===\n');

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
