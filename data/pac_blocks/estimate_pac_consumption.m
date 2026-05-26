%% estimate_pac_consumption.m  --  wp1044 §3.5.1 Eq 35 faithful rebuild
%
% Phase L2-C3: Consumption PAC equation with full wp1044 functional form.
%
% wp1044 Eq 35:
%   Delta c_t = beta_0 (c*_{t-1} - c_{t-1})                    ECM on c level gap
%             + beta_1 Delta c_{t-1}                            lag
%             + PV^2(y_H - y_bar)_{t|t-1}                       coef=1, structural
%             + alpha_1 [PV(r_LH) - (PV(i_bar) - PV(pi_bar))]   real-rate PV
%             + beta_PAC Delta y_bar_{t-1}                      growth-neutrality
%             + beta_2 [Delta log(W_H + TG_H) - p^VAT_C - y_tilde]  HtM (level-diff)
%             + beta_3 (Delta r_LH - (Delta i_bar - Delta pi_bar))  impact rate
%             + beta_4..beta_7 d_COVID                          4 dummies
%             + epsilon
%
% wp1044 Table 3.5.2: beta_0=0.29, beta_1=0.17, beta_2=0.32, beta_3=-1.07,
% alpha_1=-1.15 (from LR Eq 33), R^2 = 0.95.
%
% AU adaptations:
%   - c* from l2_data_layer (Eq 33 OLS: alpha_0=0.59, alpha_1=-0.16)
%   - PV^2(y_H - y_bar): proxy uses au_wt_H_real_gap (scaled to pp)
%   - PV(r_LH gap): r_LH proxy = i_10y - pi_au*4, gap vs trend
%   - HtM level-differential: Delta(au_wt_H_real_gap)_t - y_tilde
%     (this is approximate: au_wt_H_real_gap is already a gap, not a
%     level, so its diff is the inverse-cumulated form)
%   - Impact rate: Delta r_LH minus its HP-trend Delta r_LH_bar
%   - 4 COVID dummies: d_20Q1, d_20Q2, d_20Q3, d_20Q4
%
% Outputs: data/pac_blocks/results_consumption.{mat,txt}

clear; clc;
fprintf('=== Phase L2-C3: Consumption PAC (wp1044 Eq 35) iterative OLS ===\n\n');

projectdir = fullfile(fileparts(mfilename('fullpath')), '..', '..');
addpath(fullfile(projectdir, 'data', 'pac_helpers'));

%% Load
L2 = load(fullfile(projectdir, 'data', 'l2_data_layer.mat'));
base = readtable(fullfile(projectdir, 'dataset.csv'));
ext = readtable(fullfile(projectdir, 'data', 'extended_dataset.csv'));

% LHS
ext_dates = datetime(ext.date);
ext_c = align_q(ext.au_consumption, ext_dates, L2.dates);
dln_c = [NaN; diff(log(ext_c))] * 100;

% c level (pp) and c_star (already pp from l2 data layer)
log_c_pp = log(ext_c) * 100;
c_star = L2.c_star;

% ECM term: c*_{t-1} - c_{t-1}
ecm_lag = lag1(c_star - log_c_pp);

% Real long rate r_LH = i_10y - pi_au*4 (already in L2)
r_LH = L2.r_LH;
% Trend rates
i_bar = L2.i_au_trend;
pi_bar = L2.pi_au_trend * 4;

% HtM channel: wp1044 has Delta log(W_H + TG_H)/p_C^VAT - y_tilde.
% AU proxy: change in au_wt_H_real_gap (pp scale) minus y_tilde.
y_H_gap_pp = L2.y_H_minus_y_bar;          % already pp
Delta_y_H_gap = [NaN; diff(y_H_gap_pp)];
y_tilde = L2.y_tilde;
HtM_term = Delta_y_H_gap - y_tilde;

% Impact rate: Delta r_LH minus its HP trend
r_LH_trend = hp_trend_local(r_LH, 1600);
Delta_r_LH = [NaN; diff(r_LH)];
Delta_r_LH_trend = [NaN; diff(r_LH_trend)];
impact_rate_gap = Delta_r_LH - Delta_r_LH_trend;

% y_bar growth (Delta y_bar) -- HP trend GDP growth
dy_bar_full = align_q(base.au_ygap, datetime(base.date), L2.dates);   % won't use; use L2.y_tilde
% Actually use Delta y_bar = HP-trend of GDP growth = y_tilde (per wp1044
% notation, ỹ is the HP-trend of OUTPUT GROWTH and Δȳ is also growth-trend-related)
% Both ỹ and Δȳ are essentially the same HP-trend-of-growth object.
Delta_y_bar_lag = lag1(y_tilde);

% Dummies
d20q1 = L2.del_20Q1; d20q2 = L2.del_20Q2; d20q3 = L2.del_20Q3; d20q4 = L2.del_20Q4;

%% Auxiliary VAR
sample_full = 1:L2.nQ;
[Phi, state_names, ZL_full, ~, n_var] = build_block_var('c', L2, base, sample_full);
idx_yH = find(strcmp(state_names, 'yH_gap'));
idx_pi = find(strcmp(state_names, 'pi_gap'));
idx_i  = find(strcmp(state_names, 'i_gap'));
fprintf('Aux VAR: %d obs, state [%s], Phi rho=%.4f\n\n', ...
    n_var, strjoin(state_names, ', '), max(abs(eig(Phi))));

%% Iterative OLS
omega_c = 0.00;
beta_0 = 0.29;     beta_1 = 0.17;
alpha_1 = -1.15;   beta_PAC = 0.85;
beta_2 = 0.32;     beta_3 = -1.07;

max_iter = 50;
tol = 1e-4;
history = [];
depth = 1;
damping = 0.5;       % avg new + old beta to prevent oscillation (wp736 recipe)
chi_max = 0.85;      % safety clamp to keep I - chi*Phi well-conditioned

for iter = 1:max_iter
    chi = solve_pac_chi([beta_1], omega_c, depth);
    chi = min(chi, chi_max);
    chi = max(chi, 0);

    PV2_yH = compute_pv_term(Phi, chi, idx_yH, ZL_full, 2);
    % PV(real long rate gap) = PV(i_10y) - PV(pi_au) -- approximation using
    % state's pi_gap and i_gap.  In wp1044: PV(r_LH) - PV(ibar) + PV(pibar)
    PV_i = compute_pv_term(Phi, chi, idx_i, ZL_full, 1);
    PV_pi = compute_pv_term(Phi, chi, idx_pi, ZL_full, 1);
    PV_rLH_gap = PV_i - PV_pi;

    % LHS - PV^2(y_H - y_bar)  (coef=1 structural)
    LHS = dln_c - PV2_yH;

    X = [ones(L2.nQ, 1), ecm_lag, lag1(dln_c), PV_rLH_gap, ...
         Delta_y_bar_lag, HtM_term, impact_rate_gap, ...
         d20q1, d20q2, d20q3, d20q4];
    names_free = {'(intercept)', 'beta_0 (ECM c*-c lag)', 'beta_1 (Δc lag)', ...
                  'alpha_1 (PV r_LH gap)', 'beta_PAC (Δy_bar lag)', ...
                  'beta_2 (HtM level-diff)', 'beta_3 (impact r_LH)', ...
                  'd_20Q1', 'd_20Q2', 'd_20Q3', 'd_20Q4'};

    [b, se, tstat, R2, ~, n_ols] = ols_with_se(X, LHS);
    % Damped updates + clamps to keep iteration stable.
    % beta_1 must be in [0, 1) for chi to be in [0, 1) when omega = 0.
    b1_proposed = damping * b(3) + (1 - damping) * beta_1;
    beta_1_new = max(0.01, min(0.50, b1_proposed));     % stable range
    beta_0_new = max(0.01, min(0.80, damping * b(2) + (1 - damping) * beta_0));
    alpha_1_new = damping * b(4) + (1 - damping) * alpha_1;
    beta_PAC_new = damping * b(5) + (1 - damping) * beta_PAC;
    beta_2_new = damping * b(6) + (1 - damping) * beta_2;
    beta_3_new = damping * b(7) + (1 - damping) * beta_3;

    delta = norm([beta_0_new-beta_0, beta_1_new-beta_1, alpha_1_new-alpha_1, ...
                  beta_PAC_new-beta_PAC, beta_2_new-beta_2, beta_3_new-beta_3]);
    history(iter, :) = [iter, beta_0_new, beta_1_new, alpha_1_new, ...
                        beta_PAC_new, beta_2_new, beta_3_new, chi, R2, delta];
    fprintf('iter %2d: b0=%.4f b1=%.4f a1=%.4f bPAC=%.4f b2=%.4f b3=%.4f chi=%.4f R^2=%.3f ||d||=%.4f\n', ...
        iter, beta_0_new, beta_1_new, alpha_1_new, beta_PAC_new, beta_2_new, beta_3_new, ...
        chi, R2, delta);
    beta_0 = beta_0_new; beta_1 = beta_1_new; alpha_1 = alpha_1_new;
    beta_PAC = beta_PAC_new; beta_2 = beta_2_new; beta_3 = beta_3_new;
    if delta < tol, fprintf('Converged at iter %d.\n\n', iter); break; end
end

%% Final
fprintf('--- Consumption block final estimates ---\n');
for j = 1:length(names_free)
    fprintf('%-30s %12.4f %12.4f %8.2f\n', names_free{j}, b(j), se(j), tstat(j));
end
fprintf('chi = %.4f, omega = %.2f, R^2 = %.4f, N = %d, iters = %d\n', chi, omega_c, R2, n_ols, iter);

fprintf('\n--- vs wp1044 Table 3.5.2 ---\n');
fprintf('%-12s %12s %12s\n', 'Param', 'AU L2', 'wp1044 FR');
fprintf('%-12s %12.4f %12s\n', 'beta_0',   beta_0, '0.29');
fprintf('%-12s %12.4f %12s\n', 'beta_1',   beta_1, '0.17');
fprintf('%-12s %12.4f %12s\n', 'alpha_1',  alpha_1, '-1.15');
fprintf('%-12s %12.4f %12s\n', 'beta_PAC', beta_PAC, '?');
fprintf('%-12s %12.4f %12s\n', 'beta_2',   beta_2, '0.32');
fprintf('%-12s %12.4f %12s\n', 'beta_3',   beta_3, '-1.07');
fprintf('%-12s %12.4f %12s\n', 'R^2',      R2,     '0.95');

%% Save
out.block = 'Consumption (wp1044 Eq 35)';
out.beta_0 = beta_0; out.beta_1 = beta_1; out.alpha_1 = alpha_1;
out.beta_PAC = beta_PAC; out.beta_2 = beta_2; out.beta_3 = beta_3;
out.omega_c = omega_c; out.chi = chi;
out.coefs = b; out.se = se; out.tstat = tstat; out.names = {names_free};
out.R2 = R2; out.N = n_ols; out.n_iter = iter; out.history = history;
out.state_names = {state_names}; out.Phi = Phi;
out.converged = (delta < tol);
save(fullfile(projectdir, 'data', 'pac_blocks', 'results_consumption.mat'), '-struct', 'out');

fid = fopen(fullfile(projectdir, 'data', 'pac_blocks', 'results_consumption.txt'), 'w');
fprintf(fid, 'Consumption PAC iterative OLS (wp1044 Eq 35)\n');
fprintf(fid, 'Generated %s\n\n', datestr(now));
fprintf(fid, 'Aux VAR state: [%s], rho=%.4f\n\n', strjoin(state_names, ', '), max(abs(eig(Phi))));
for j = 1:length(names_free)
    fprintf(fid, '%-30s %12.4f %12.4f %8.2f\n', names_free{j}, b(j), se(j), tstat(j));
end
fprintf(fid, 'chi=%.4f, omega=%.2f, R^2=%.4f, N=%d, iters=%d\n', chi, omega_c, R2, n_ols, iter);
fprintf(fid, '\nwp1044 FR Table 3.5.2: b0=0.29, b1=0.17, b2=0.32, b3=-1.07, R^2=0.95\n');
fprintf(fid, 'wp1044 alpha_1 (from LR Eq 33): -1.15\n');
fclose(fid);

fprintf('\n=== Phase L2-C3 complete ===\n');

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
