%% estimate_pac_business_inv_au_v3.m  --  PAC structure + dummies, careful spec
%
% Phase L2 P1c v3: one more try at fitting AU business inv with PAC
% structure preserved.  Key insight from v1/v2 failures: the issue
% isn't that dummies don't help, it's that the iterative-OLS clamps +
% PV-term machinery makes identification fragile.
%
% New approach: SINGLE OLS (not iterative) with all wp1044 ingredients
% AS FREE REGRESSORS (not imposed at coef=1), plus dummies.  Don't
% subtract PV terms from LHS -- let them have free coefficients.
% Compare unconstrained coefficient on PV terms to the structural 1.
% If the data says PV terms enter with coefficient near 1, that's a
% validation of the PAC structure.
%
% Then a comparison version with PAC structure IMPOSED (coef=1 PV
% terms) + dummies, single shot (no iteration), to see if the
% structural restriction is what's hurting.

clear; clc;
fprintf('=== Phase L2 P1c v3: BI single-shot PAC + dummies ===\n\n');

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
Delta_q_hat = Delta_q - Delta_q_bar;

Delta_log_r_KB_hat = L2.Delta_log_r_KB_wacc - L2.Delta_log_r_KB_wacc_bar;
Delta_log_r_KB_bar = L2.Delta_log_r_KB_wacc_bar;

Delta_df_gap = L2.Delta_df_full - L2.Delta_df_bar_full;

% Compute PV terms ONCE at calibrated chi (wp1044 calibration values)
chi_calib = 0.5;     % between simplified (0.29) and exact (0.51); wp1044 implied ~0.79
[Phi, state_names, ZL_full, ~, ~] = build_block_var('ib', L2, base, 1:L2.nQ);
idx_rKB = find(strcmp(state_names, 'r_KB_gap'));
idx_qhat = find(strcmp(state_names, 'q_hat'));
PV_q_hat   = compute_pv_term(Phi, chi_calib, idx_qhat, ZL_full, 1);
PV_rKB_hat = compute_pv_term(Phi, chi_calib, idx_rKB, ZL_full, 1);
PV_q_bar   = lag1(Delta_q_bar);
PV_rKB_bar = lag1(Delta_log_r_KB_bar);

% Dummies
year_v = year(L2.dates); q_v = quarter(L2.dates);
mkd = @(yyyy, qq) double(year_v == yyyy & q_v == qq);

d_2000Q3 = mkd(2000, 3);  d_2000Q4 = mkd(2000, 4);
d_2008Q4 = mkd(2008, 4);  d_2009Q1 = mkd(2009, 1);  d_2009Q2 = mkd(2009, 2);
d_2011Q3 = mkd(2011, 3);  % mining peak
d20q1 = L2.del_20Q1; d20q2 = L2.del_20Q2; d20q3 = L2.del_20Q3; d20q4 = L2.del_20Q4;

dummies_block = [d_2000Q3, d_2000Q4, d_2008Q4, d_2009Q1, d_2009Q2, d_2011Q3, ...
                 d20q1, d20q2, d20q3, d20q4];
dummy_names_block = {'d_2000Q3','d_2000Q4','d_2008Q4','d_2009Q1','d_2009Q2','d_2011Q3', ...
                     'd_20Q1','d_20Q2','d_20Q3','d_20Q4'};

%% Variant A: ALL wp1044 elements as FREE regressors + dummies (lets data choose)
fprintf('--- Variant A: PAC ingredients FREE-estimated + dummies ---\n');
X_A = [ones(L2.nQ, 1), lag1(ib_target_minus_actual), ...
       lag1(dln_ib), lagn(dln_ib, 2), ...
       PV_q_hat, PV_q_bar, PV_rKB_hat, PV_rKB_bar, ...
       Delta_df_gap, ...
       dummies_block];
names_A = [{'(intercept)', 'b_0 (ECM)', 'b_1 (lag1)', 'b_2 (lag2)', ...
            'PV(q_hat)', 'PV(q_bar)', 'PV(r_KB_hat)', 'PV(r_KB_bar)', ...
            'b_3 (Δdf gap)'}, dummy_names_block];
[bA, seA, tA, R2_A, ~, nA] = ols_with_se(X_A, dln_ib);
for j=1:length(names_A), fprintf('  %-22s %8.4f (se %.4f, t %.2f)\n', names_A{j}, bA(j), seA(j), tA(j)); end
fprintf('R^2 = %.4f, N = %d\n\n', R2_A, nA);
fprintf('Coefficient on PV(q_hat): %.4f (wp1044 imposes 1)\n', bA(5));
fprintf('Coefficient on PV(r_KB_hat): %.4f (wp1044 imposes -sigma = -%.3f)\n\n', bA(7), sigma);

%% Variant B: PAC structure IMPOSED (PV at coef=1) but SINGLE OLS for the rest
fprintf('--- Variant B: PAC PV-terms imposed at coef=1, single OLS, + dummies ---\n');
% chi at the START (no iteration)
chi_B = chi_calib;
% Use wp1044 implied derived coefficient with placeholder beta values
% This is the "wp1044 spec evaluated at wp1044 calibrated coefficients" baseline
beta_1_implied = 0.33; beta_2_implied = 0.11; omega_B = 0.35;
derived_B = 1 - beta_1_implied - beta_2_implied - omega_B;   % = 0.21

LHS_B = dln_ib - PV_q_hat - PV_q_bar ...
              + sigma * PV_rKB_hat + sigma * PV_rKB_bar ...
              - derived_B * lag1(Delta_log_r_KB_bar) ...
              - derived_B * lag1(Delta_q_bar);
X_B = [ones(L2.nQ, 1), lag1(ib_target_minus_actual), ...
       lag1(dln_ib), lagn(dln_ib, 2), ...
       Delta_df_gap, ...
       dummies_block];
names_B = [{'(intercept)', 'b_0 (ECM)', 'b_1 (lag1)', 'b_2 (lag2)', ...
            'b_3 (Δdf gap)'}, dummy_names_block];
[bB, seB, tB, R2_B, ~, nB] = ols_with_se(X_B, LHS_B);
for j=1:length(names_B), fprintf('  %-22s %8.4f (se %.4f, t %.2f)\n', names_B{j}, bB(j), seB(j), tB(j)); end
fprintf('R^2 on adjusted LHS = %.4f, N = %d, derived_coef = %.4f\n\n', R2_B, nB, derived_B);

% Compute R^2 on RAW dln_ib for Variant B
y_hat_B = X_B * bB + PV_q_hat + PV_q_bar - sigma*PV_rKB_hat - sigma*PV_rKB_bar ...
          + derived_B * lag1(Delta_log_r_KB_bar) + derived_B * lag1(Delta_q_bar);
valid = ~any(isnan([dln_ib, y_hat_B]), 2);
ss_total = sum((dln_ib(valid) - mean(dln_ib(valid))).^2);
ss_resid = sum((dln_ib(valid) - y_hat_B(valid)).^2);
R2_B_raw = 1 - ss_resid / ss_total;
fprintf('Variant B R^2 on RAW dln_ib (with structural PV terms added back): %.4f\n\n', R2_B_raw);

%% Variant C: like Variant B but iterate b_1, b_2 to fixed point (proper PAC iteration)
fprintf('--- Variant C: full wp1044 PAC iterative OLS + dummies (clamps loose) ---\n');
omega_C = 0.35;
beta_0 = 0.10; beta_lags = [0.33; 0.11]; beta_3 = 0.69;
max_iter = 30; tol = 1e-4; damping = 0.5;
% Looser clamps -- let iteration breathe
chi_max_C = 0.85; b0_max = 1.5; b1_max = 1.0; b2_max = 0.8;

for iter = 1:max_iter
    chi = solve_pac_chi_exact(beta_lags, omega_C, 2);
    chi = max(0, min(chi_max_C, chi));

    PV_q_hat   = compute_pv_term(Phi, chi, idx_qhat, ZL_full, 1);
    PV_rKB_hat = compute_pv_term(Phi, chi, idx_rKB, ZL_full, 1);
    sum_b = sum(beta_lags);
    derived = 1 - sum_b - omega_C;

    LHS = dln_ib - PV_q_hat - PV_q_bar ...
                 + sigma * PV_rKB_hat + sigma * PV_rKB_bar ...
                 - derived * lag1(Delta_log_r_KB_bar) ...
                 - derived * lag1(Delta_q_bar);

    X = [ones(L2.nQ, 1), lag1(ib_target_minus_actual), ...
         lag1(dln_ib), lagn(dln_ib, 2), ...
         Delta_df_gap, dummies_block];
    [b, ~, ~, R2, ~, n_ols] = ols_with_se(X, LHS);

    beta_0_new = max(-b0_max, min(b0_max, damping*b(2) + (1-damping)*beta_0));
    beta_lags_new = [max(-b1_max, min(b1_max, damping*b(3) + (1-damping)*beta_lags(1)));
                     max(-b2_max, min(b2_max, damping*b(4) + (1-damping)*beta_lags(2)))];
    beta_3_new = damping*b(5) + (1-damping)*beta_3;
    delta = norm([beta_0_new - beta_0; beta_lags_new - beta_lags; beta_3_new - beta_3]);
    fprintf('iter %2d: b0=%+.4f, b1=%+.4f, b2=%+.4f, b3=%+.4f, chi=%.4f, R^2adj=%.3f\n', ...
        iter, beta_0_new, beta_lags_new(1), beta_lags_new(2), beta_3_new, chi, R2);
    beta_0=beta_0_new; beta_lags=beta_lags_new; beta_3=beta_3_new;
    if delta < tol, fprintf('Converged at iter %d\n', iter); break; end
end
% Final SE
[b, se, t, R2, ~, n_ols] = ols_with_se(X, LHS);
names_C = [{'(intercept)', 'b_0 (ECM)', 'b_1 (lag1)', 'b_2 (lag2)', 'b_3 (Δdf gap)'}, dummy_names_block];
fprintf('\nVariant C final (loose clamps):\n');
for j=1:length(names_C), fprintf('  %-22s %8.4f (se %.4f, t %.2f)\n', names_C{j}, b(j), se(j), t(j)); end
% R^2 on raw
y_hat_C = X * b + PV_q_hat + PV_q_bar - sigma*PV_rKB_hat - sigma*PV_rKB_bar ...
          + derived * lag1(Delta_log_r_KB_bar) + derived * lag1(Delta_q_bar);
valid = ~any(isnan([dln_ib, y_hat_C]), 2);
ss_total = sum((dln_ib(valid) - mean(dln_ib(valid))).^2);
ss_resid = sum((dln_ib(valid) - y_hat_C(valid)).^2);
R2_C_raw = 1 - ss_resid / ss_total;
fprintf('R^2 on RAW dln_ib: %.4f *** headline\n', R2_C_raw);

%% Summary
fprintf('\n========== SUMMARY: which spec works for AU BI? ==========\n');
fprintf('Variant A (PV terms FREE)         R^2 (raw) = %.4f\n', R2_A);
fprintf('Variant B (PV imposed coef=1)     R^2 (raw) = %.4f\n', R2_B_raw);
fprintf('Variant C (iterative + dummies)   R^2 (raw) = %.4f\n', R2_C_raw);
fprintf('wp1044 FR                         R^2       = 0.83\n');

%% Save the best variant
[~, best] = max([R2_A, R2_B_raw, R2_C_raw]);
labels = {'A_free', 'B_imposed', 'C_iterative'};
fprintf('\nBest variant: %s\n', labels{best});

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
