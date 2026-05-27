%% estimate_pac_va_price.m  --  wp1044 §3.3 Eq 16 faithful rebuild
%
% Phase L2-C1: VA-price PAC equation with full wp1044 functional form.
%
% wp1044 Eq 16:
%   pi_Q,t = PV(pi*_Q)_{t|t-1}                  (coef = 1, structural)
%          + beta_0 (p*_Q,t-1 - p_Q,t-1)         (ECM on price LEVEL gap)
%          + beta_1 pi_Q,t-1                     (lag, depth = 1)
%          + beta_2 yhat_t                       (output gap CONTEMP)
%          + (1 - beta_1 - omega) pi_Q_bar,t-1   (growth-neutrality, derived)
%          + dummies (8: 03Q2, 06Q3, 08Q1, 10Q4, 20Q1, 20Q2, 20Q3, 21Q1)
%          + epsilon
%
% wp1044 Table 3.3.3: beta_0=0.05, beta_1=0.20, beta_2=0.09, omega=0.62,
% R^2 = 0.61.
%
% Estimation procedure (iterative OLS):
%   Step A: auxiliary VAR for the state [yhat, i_gap, piQ_gap, yhat_us,
%           pi_us, u_hat, pi_w_eff, pi_Q_bar] -- 8 variables.
%   Step B: PV(pi*_Q) = e_target' (I - chi*Phi)^{-1} chi*Phi z_{t-1}
%           where target_idx is for pi_Q_bar (the closest analogue in our
%           state to the wp1044 pi*_Q -- target ITSELF is the projection).
%   Step C: subtract PV term from LHS, OLS for the free coefficients.
%   Step D: derived (1 - beta_1 - omega) coefficient on pi_Q_bar_lag is
%           imposed (not free), so we ALSO subtract that contribution
%           after each beta_1 update.
%   Step E: iterate until ||beta_new - beta_old|| < tol.
%
% AU adaptations vs wp1044:
%   - LHS = piQ (VA quarterly inflation from supply_data, 139 obs)
%   - p*_Q - p_Q constructed by cumulating (pi*_Q - piQ) (l2_data_layer)
%   - omega calibrated at 0.62 (wp1044) -- sensitivity at 0.46 (AUSPAC)
%   - 8 dummies all included
%
% Outputs:
%   data/pac_blocks/results_va_price.{mat,txt}

clear; clc;
fprintf('=== Phase L2-C1: VA-price PAC (wp1044 Eq 16) iterative OLS ===\n\n');

projectdir = fullfile(fileparts(mfilename('fullpath')), '..', '..');
addpath(fullfile(projectdir, 'data', 'pac_helpers'));

%% Load data
L2 = load(fullfile(projectdir, 'data', 'l2_data_layer.mat'));
base = readtable(fullfile(projectdir, 'dataset.csv'));

% Sample: where piQ + p*_Q + piW are all valid.  piW starts ~1997.
sample_full = 1:L2.nQ;
piQ = L2.piQ;
p_Q_gap = L2.p_Q_star_minus_p_Q;     % p*_Q - p_Q (ECM)
pi_Q_bar = L2.pi_Q_bar;

% Output gap, dummies
base_dates = datetime(base.date);
yhat_au_full = align_q(base.au_ygap, base_dates, L2.dates);

% Required dummies (from L2)
dums = [L2.del_03Q2, L2.del_06Q3, L2.del_08Q1, L2.del_10Q4, ...
        L2.del_20Q1, L2.del_20Q2, L2.del_20Q3, L2.del_21Q1];
dum_names = {'d_03Q2', 'd_06Q3', 'd_08Q1', 'd_10Q4', 'd_20Q1', 'd_20Q2', 'd_20Q3', 'd_21Q1'};

%% Build the auxiliary VAR via build_block_var
% Use a wider sample for the VAR; restrict to common-NaN later.
[Phi, state_names, ZL_full, ~, n_var] = build_block_var('pQ', L2, base, sample_full);
fprintf('Auxiliary VAR(1) on %d obs.  State: [%s]\n', n_var, strjoin(state_names, ', '));
fprintf('Phi spectral radius: %.4f\n\n', max(abs(eig(Phi))));

% Identify state indices
idx_pi_Q_bar = find(strcmp(state_names, 'pi_Q_bar'));

%% Iterative OLS
omega = 0.62;                % wp1044 calibration (sensitivity later)
beta_0 = 0.05;               % initial guess (wp1044 mean)
beta_1 = 0.20;
beta_2 = 0.09;

max_iter = 50;
tol = 1e-4;
history = [];

for iter = 1:max_iter
    chi = solve_pac_chi([beta_1], omega, 1);

    % PV(pi*_Q) -- proxy uses pi_Q_bar from state (the trend, closest to wp1044
    % target pi*_Q).  This is an AU adaptation since constructing a separate
    % pi*_Q via Eq 17 was unstable (beta_0_eq17 = 0.024, see l2_data_layer.txt).
    PV_piQ_star = compute_pv_term(Phi, chi, idx_pi_Q_bar, ZL_full, 1);

    % Derived growth-neutrality coefficient
    derived_coef = 1 - beta_1 - omega;

    % LHS adjusted: pi_Q minus the structural-coef-1 PV term and the
    % derived-coef growth-neutrality term
    LHS = piQ - PV_piQ_star - derived_coef * lag1(pi_Q_bar);

    % Free regressors: intercept, beta_0 * lag1(p*_Q - p_Q), beta_1 * lag1(piQ),
    % beta_2 * yhat_au_t, dummies
    X = [ones(L2.nQ, 1), lag1(p_Q_gap), lag1(piQ), yhat_au_full, dums];
    names_free = {'(intercept)', 'beta_0 (ECM p*_Q-p_Q lag)', 'beta_1 (piQ lag)', ...
                  'beta_2 (yhat_t contemp)', dum_names{:}};

    [b, se, tstat, R2, rss, n_ols] = ols_with_se(X, LHS);
    beta_0_new = b(2);
    beta_1_new = b(3);
    beta_2_new = b(4);

    delta = norm([beta_0_new - beta_0, beta_1_new - beta_1, beta_2_new - beta_2]);
    history(iter, :) = [iter, beta_0_new, beta_1_new, beta_2_new, chi, R2, delta];
    fprintf('iter %2d: b0=%.4f, b1=%.4f, b2=%.4f, chi=%.4f, R^2=%.3f, ||d||=%.5f\n', ...
        iter, beta_0_new, beta_1_new, beta_2_new, chi, R2, delta);
    beta_0 = beta_0_new; beta_1 = beta_1_new; beta_2 = beta_2_new;
    if delta < tol, fprintf('Converged at iter %d.\n\n', iter); break; end
end

%% Final OLS with full SE
fprintf('--- VA-price block final estimates ---\n');
fprintf('%-30s %12s %12s %8s\n', 'Coefficient', 'estimate', 'se', 't');
fprintf('%-30s %12s %12s %8s\n', '-----------', '--------', '--', '-');
for j = 1:length(names_free)
    fprintf('%-30s %12.4f %12.4f %8.2f\n', names_free{j}, b(j), se(j), tstat(j));
end
fprintf('chi (derived from beta_1=%.4f, omega=%.2f) = %.4f\n', beta_1, omega, chi);
fprintf('Derived growth-neutrality coef on pi_Q_bar(-1): (1-b1-omega) = %.4f\n', 1 - beta_1 - omega);
fprintf('R^2 = %.4f, N = %d, iters = %d\n', R2, n_ols, iter);

fprintf('\n--- Comparison to wp1044 Table 3.3.3 ---\n');
fprintf('%-12s %12s %12s\n', 'Param', 'AU L2', 'wp1044 FR');
fprintf('%-12s %12.4f %12s\n', 'beta_0', beta_0, '0.05');
fprintf('%-12s %12.4f %12s\n', 'beta_1', beta_1, '0.20');
fprintf('%-12s %12.4f %12s\n', 'beta_2', beta_2, '0.09');
fprintf('%-12s %12.4f %12s\n', 'omega',  omega, '0.62 (calib)');
fprintf('%-12s %12.4f %12s\n', 'R^2',    R2,    '0.61');

%% Save
out = struct();
out.block = 'VA-price (wp1044 Eq 16)';
out.beta_0 = beta_0;
out.beta_1 = beta_1;
out.beta_2 = beta_2;
out.omega = omega;
out.chi = chi;
out.derived_coef = 1 - beta_1 - omega;
out.coefs = b;
out.se = se;
out.tstat = tstat;
out.names = {names_free};
out.R2 = R2;
out.N = n_ols;
out.n_iter = iter;
out.history = history;
out.state_names = {state_names};
out.Phi = Phi;
out.converged = (delta < tol);

save(fullfile(projectdir, 'data', 'pac_blocks', 'results_va_price.mat'), '-struct', 'out');
fprintf('\nSaved results_va_price.mat\n');

fid = fopen(fullfile(projectdir, 'data', 'pac_blocks', 'results_va_price.txt'), 'w');
fprintf(fid, 'VA-price PAC iterative OLS (wp1044 Eq 16)\n');
fprintf(fid, 'Generated %s\n\n', datestr(now));
fprintf(fid, 'Auxiliary VAR(1) state: [%s]\n', strjoin(state_names, ', '));
fprintf(fid, 'Phi spectral radius: %.4f\n\n', max(abs(eig(Phi))));
fprintf(fid, '%-30s %12s %12s %8s\n', 'Coefficient', 'estimate', 'se', 't');
for j = 1:length(names_free)
    fprintf(fid, '%-30s %12.4f %12.4f %8.2f\n', names_free{j}, b(j), se(j), tstat(j));
end
fprintf(fid, 'chi = %.4f (derived from beta_1=%.4f, omega=%.2f)\n', chi, beta_1, omega);
fprintf(fid, 'Derived growth-neutrality coef = (1-b1-omega) = %.4f\n', 1-beta_1-omega);
fprintf(fid, 'R^2 = %.4f, N = %d\n', R2, n_ols);
fprintf(fid, '\nwp1044 FR Table 3.3.3: b0=0.05, b1=0.20, b2=0.09, omega=0.62, R^2=0.61\n');
fclose(fid);
fprintf('Saved results_va_price.txt\n');

fprintf('\n=== Phase L2-C1 complete ===\n');

%% --- Local helper ---
function vq = align_q(src_col, src_dates, target_dates)
    nq = length(target_dates);
    vq = nan(nq, 1);
    for i = 1:nq
        m = find(year(src_dates) == year(target_dates(i)) & ...
                 quarter(src_dates) == quarter(target_dates(i)), 1);
        if ~isempty(m), vq(i) = src_col(m); end
    end
end
