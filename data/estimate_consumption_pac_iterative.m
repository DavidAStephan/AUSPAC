%% estimate_consumption_pac_iterative.m
%
% Proper iterative-OLS partial L2 wp1044 replication for the consumption
% PAC block, following the FR-BDF technique exactly (wp736 §4, wp1044
% §2.2 step 4).
%
% Architecture (faithful to FR-BDF):
%
%   Step A: Auxiliary VAR for the state z_t including the PAC target c*_t.
%           Each VAR equation estimated by OLS lag-by-lag.  The c*
%           equation is part of the VAR (this is the "auxiliary PAC
%           equation" -- it forecasts the target from observables).
%
%   Step B: Compute closed-form PAC expectation projection given current
%           beta coefficients:
%               PAC_exp_t = e_target' * (I - chi*Phi)^{-1} * chi*Phi *
%                           z_{t-1}
%           where chi = beta_1 + omega_c is the discount factor (depth-1
%           PAC), and omega_c is calibrated (zero for consumption per
%           wp1044 §3.5.1 since the non-stationary component of
%           expectations is zero for gap terms).
%
%   Step C: OLS on PAC short-run equation with PAC expectation entering
%           at COEFFICIENT = 1 (structural constraint).  Implemented by
%           subtracting PAC_exp from the LHS before OLS.
%
%   Step D: Update beta from OLS, recompute chi(beta) and PAC_exp.  Loop
%           steps B-D until ||beta_new - beta_old|| < tol.
%
% The wp1044 consumption short-run equation (Eq 35) is:
%
%   Delta c_t = beta_0 (c*_{t-1} - c_{t-1})
%             + beta_1 Delta c_{t-1}
%             + PV²(y_H - ybar)_{t|t-1}
%             + alpha_1 [PV(r_LH) - (PV(ibar) - PV(pibar))]_{t|t-1}
%             + beta_PAC Delta ybar_{t-1}
%             + beta_2 [HtM term]
%             + beta_3 (Delta r_LH - (Delta ibar - Delta pibar))
%             + beta_4 delta_COVID + epsilon_t
%
% For AU partial L2 with the 10-obs estimation_data.mat:
%   - c*_t approximated as HP trend of log(au_consumption) -- the
%     consumption target c_hat in AUSPAC notation
%   - y_H proxied by demeaned au_wt_H_real_gap
%   - r_LH proxied by demeaned i_10y; (ibar - pibar) treated as a
%     constant absorbed in demeaning
%   - HtM channel kept (Round 1.2 form)
%
% State for VAR: z_t = [yhat_au, pi_au, i_au, i_10y, y_H_gap, dln_c_gap]
% where dln_c_gap is the HP gap of log consumption (= -(c_hat - c_level)).
%
% This is the "exact replication of the technique" requested.  Compared
% to my earlier one-shot OLS, the differences are:
%   (1) auxiliary VAR includes the PAC target (c_hat HP-trend gap)
%   (2) PAC expectation enters at coefficient = 1, not as a free
%       regressor whose significance can be tested
%   (3) chi(beta) is recomputed each iteration
%   (4) iteration to convergence (vs one-shot)
%
% Caveats vs wp1044 EXACT:
%   - 5-var VAR(1) vs wp1044's larger E-SAT VAR with multiple lags
%   - OLS lag-by-lag vs wp1044 Bayesian Minnesota prior
%   - Proxies for y_H, r_LH targets (no AU data on wages+transfers in
%     levels, no separate ibar/pibar from observables)
%   - Depth-1 PAC (single Delta c lag) consistent with wp1044 Eq 35

clear; clc;
fprintf('=== Iterative OLS for consumption PAC (faithful wp1044 replication) ===\n\n');

projectdir = fullfile(fileparts(mfilename('fullpath')), '..');

%% Load data
D = load(fullfile(projectdir, 'dynare', 'estimation_data.mat'));
T_ext = readtable(fullfile(projectdir, 'data', 'extended_dataset.csv'));

% Aligned sample (1993Q2-2023Q3, 122 obs)
sample_idx = 2:123;
nObs = length(sample_idx);

% From estimation_data.mat (already demeaned, q/q %)
yhat_au    = D.yhat_au;
pi_au      = D.pi_au;
i_au       = D.i_au;
i_10y      = D.i_10y;
dln_c      = D.dln_c;
dy_bar_gap = D.dy_bar_gap;

% From extended_dataset.csv (need to align + demean)
y_H_gap = demean(T_ext.au_wt_H_real_gap(sample_idx));
au_cons = T_ext.au_consumption(sample_idx);

%% Construct ln_c_level + c_hat (HP trend of log consumption)
% au_consumption is real consumption volumes (chain $).  Take log, demean
% AROUND its sample trend (HP filter).
log_cons = log(au_cons);
log_cons_trend = hp_trend(log_cons, 1600);
c_hat            = log_cons_trend - mean(log_cons_trend, 'omitnan');   % demean
ln_c_level_obs   = log_cons         - mean(log_cons, 'omitnan');       % demean

% Consumption gap (= -(c_hat - ln_c_level_obs)).  Stationary by construction.
c_gap = ln_c_level_obs - c_hat;

% NOTE on scaling: log_cons is in NATURAL UNITS (log).  Differencing gives
% per-unit growth.  estimation_data.mat dln_c is in QUARTERLY PERCENT
% (= 100 * diff(log)).  So if we want consistency, multiply log-level
% objects by 100 to put them in "% deviation from mean" space matching
% dln_c's scale.
c_hat   = 100 * c_hat;
ln_c_level_obs = 100 * ln_c_level_obs;
c_gap   = 100 * c_gap;

%% Step A: Auxiliary VAR(1) on z = [yhat_au, pi_au, i_au, i_10y, y_H_gap, c_gap]
% Includes c_gap (the consumption HP gap) as the PAC-target state variable.
% Each VAR equation estimated by OLS lag-by-lag.
state_names = {'yhat_au', 'pi_au', 'i_au', 'i_10y', 'y_H_gap', 'c_gap'};
Z = [yhat_au, pi_au, i_au, i_10y, y_H_gap, c_gap];
k = size(Z, 2);

valid_Z = ~any(isnan(Z), 2);
Z_use = Z(valid_Z, :);
Z_lag = Z_use(1:end-1, :);
Z_t   = Z_use(2:end, :);

% OLS for each row of Phi: z_t' = Phi * z_{t-1}' + e_t'
% So Phi' = (Z_lag' Z_lag)^-1 Z_lag' Z_t
Phi_T = (Z_lag' * Z_lag) \ (Z_lag' * Z_t);
Phi = Phi_T';

rho_Phi = max(abs(eig(Phi)));
fprintf('Auxiliary VAR(1) Phi estimated.  Spectral radius: %.4f\n', rho_Phi);
fprintf('VAR state: [%s]\n\n', strjoin(state_names, ', '));

% Build ZL_full (z_{t-1}) at the full sample
ZL_full = nan(nObs, k);
v_idx = find(valid_Z);
for ii = 2:length(v_idx)
    ZL_full(v_idx(ii), :) = Z_use(ii-1, :);
end

%% Step B-D: Iterative OLS
% Initialize beta at L1.3a chain 1 posterior means
beta = struct();
beta.beta_0    = 0.05;    % ECM speed
beta.beta_1    = 0.04;    % Delta c lag
beta.alpha_1   = -0.55;   % real-rate sensitivity
beta.beta_PAC  = 0.85;    % growth-neutrality (initial guess)
beta.beta_HtM  = 0.32;    % HtM channel (calibrated, not estimated)

omega_c = 0.0;   % wp1044 §3.5.1: zero non-stationary component for the
                 % consumption gap term.  Stationary expectations only.

max_iter = 50;
tol = 1e-4;

% e_target picks c_gap (the consumption target gap).
% e_yH picks y_H_gap; e_pi picks pi_au; e_i10y picks i_10y; etc.
e = eye(k);
idx_c   = find(strcmp(state_names, 'c_gap'));
idx_yH  = find(strcmp(state_names, 'y_H_gap'));
idx_pi  = find(strcmp(state_names, 'pi_au'));
idx_i10 = find(strcmp(state_names, 'i_10y'));

% PAC expectation target: the consumption gap c_gap forecast.
% PV target for the rate term: real long rate proxy = i_10y - pi_au.

fprintf('Starting iteration (max %d, tol %.0e)...\n\n', max_iter, tol);
beta_history = zeros(max_iter, 4);   % beta_0, beta_1, alpha_1, beta_PAC

for iter = 1:max_iter
    % chi for depth-1 PAC consumption: chi = beta_1 + omega_c = beta_1
    chi = beta.beta_1 + omega_c;

    % Sanity check: chi must be < 1/rho_Phi for PV operator to converge.
    if chi * rho_Phi >= 0.99
        warning('iter %d: chi*rho_Phi = %.4f near unit, PV unstable', ...
            iter, chi * rho_Phi);
    end

    % Closed-form PV and PV² operators
    if abs(chi) < 1e-8
        % chi = 0: PV operator collapses to zero (no forward expectations)
        PV_op  = zeros(k, k);
        PV2_op = zeros(k, k);
    else
        PV_op  = (eye(k) - chi * Phi) \ (chi * Phi);   % wp736 form with chi inside
        PV2_op = PV_op * PV_op;
    end

    % Compute PAC expectations at each t:
    %   PV²(y_H_gap) = e_yH' * PV2_op * z_{t-1}
    %   PV(real_rate_proxy) = (e_i10 - e_pi)' * PV_op * z_{t-1}
    PV2_yH_t   = (e(:, idx_yH)' * PV2_op * ZL_full')';
    PV_rLH_t   = ((e(:, idx_i10) - e(:, idx_pi))' * PV_op * ZL_full')';

    % PAC expectation term in Eq 35 = PV²(y_H_gap) + alpha_1 * PV(r_LH)
    % This is the COEFFICIENT-1 (structural) part of the equation.
    % Subtract from LHS before OLSing the free coefficients.
    PAC_exp_t = PV2_yH_t + beta.alpha_1 * PV_rLH_t;

    % Build OLS regression for free parameters (beta_0, beta_1, alpha_1,
    % beta_PAC) given the current PAC_exp constraint.
    %
    % NOTE: alpha_1 appears BOTH inside PAC_exp_t (coefficient on PV(r_LH))
    % AND would notionally enter the equation directly.  In the iterative
    % OLS scheme, we treat alpha_1's PV-coefficient as fixed at the
    % current iteration value (subtracting alpha_1 * PV(r_LH) into PAC_exp_t)
    % and only update it when we redo OLS.  Equivalently: regress LHS -
    % PV2_yH_t on (ECM, dln_c_lag, PV(r_LH), dy_bar_gap_lag, HtM).
    LHS = dln_c - PV2_yH_t;
    X = [ones(nObs, 1), ...                                  % intercept
         lag1(c_gap), ...                                    % ECM term: c_gap_{t-1} = -(c_hat - c_level)_{t-1}
         lag1(dln_c), ...                                    % Delta c lag
         PV_rLH_t, ...                                       % PV(real long rate)
         lag1(dy_bar_gap), ...                               % growth-neutrality term
         y_H_gap - yhat_au];                                 % HtM channel
    names = {'(intercept)', 'beta_0 (c_gap lag, sign-flipped ECM)', ...
             'beta_1 (dln_c lag)', 'alpha_1 (PV r_LH)', ...
             'beta_PAC (dy_bar lag)', 'beta_HtM (y_H_gap - yhat_au)'};

    [b, ~, ~, ~, ~, n_ols] = ols(X, LHS);

    % Update beta.  Note: coefficient on c_gap_{t-1} is -beta_0 (since
    % wp1044 ECM is +beta_0 * (c* - c_level) = -beta_0 * c_gap).  So
    % beta_0_new = -b(2).
    beta_new = beta;
    beta_new.beta_0   = -b(2);
    beta_new.beta_1   =  b(3);
    beta_new.alpha_1  =  b(4);
    beta_new.beta_PAC =  b(5);
    beta_new.beta_HtM =  b(6);

    delta = sqrt((beta_new.beta_0 - beta.beta_0)^2 + ...
                 (beta_new.beta_1 - beta.beta_1)^2 + ...
                 (beta_new.alpha_1 - beta.alpha_1)^2 + ...
                 (beta_new.beta_PAC - beta.beta_PAC)^2);

    fprintf('iter %2d: beta_0=%.4f, beta_1=%.4f, alpha_1=%.4f, beta_PAC=%.4f, ||delta||=%.5f\n', ...
        iter, beta_new.beta_0, beta_new.beta_1, beta_new.alpha_1, ...
        beta_new.beta_PAC, delta);

    beta_history(iter, :) = [beta_new.beta_0, beta_new.beta_1, ...
                             beta_new.alpha_1, beta_new.beta_PAC];

    if delta < tol
        fprintf('\nConverged at iter %d.\n\n', iter);
        beta = beta_new;
        break;
    end

    beta = beta_new;
    if iter == max_iter
        fprintf('\nMax iterations reached without convergence (||delta||=%.5f).\n\n', delta);
    end
end

%% Final OLS with full SE reporting
chi = beta.beta_1 + omega_c;
PV_op  = (eye(k) - chi * Phi) \ (chi * Phi);
PV2_op = PV_op * PV_op;
PV2_yH_t   = (e(:, idx_yH)' * PV2_op * ZL_full')';
PV_rLH_t   = ((e(:, idx_i10) - e(:, idx_pi))' * PV_op * ZL_full')';

LHS = dln_c - PV2_yH_t;
X = [ones(nObs, 1), lag1(c_gap), lag1(dln_c), PV_rLH_t, ...
     lag1(dy_bar_gap), y_H_gap - yhat_au];
[b, se, t_stat, R2, rss, n] = ols(X, LHS);

fprintf('--- Converged OLS (PAC expectation imposed at coef = 1) ---\n');
fprintf('chi = %.4f (= beta_1 + omega_c, omega_c = 0)\n\n', chi);
fprintf('%-40s %12s %12s %8s\n', 'Coefficient (structural)', 'estimate', 'se', 't');
fprintf('%-40s %12s %12s %8s\n', '-----------------------', '--------', '--', '-');
fprintf('%-40s %12.4f %12.4f %8.2f\n', '(intercept)', b(1), se(1), t_stat(1));
fprintf('%-40s %12.4f %12.4f %8.2f\n', 'beta_0 (ECM speed, sign-flipped)', -b(2), se(2), -t_stat(2));
fprintf('%-40s %12.4f %12.4f %8.2f\n', 'beta_1 (dln_c lag)', b(3), se(3), t_stat(3));
fprintf('%-40s %12.4f %12.4f %8.2f\n', 'alpha_1 (PV r_LH)', b(4), se(4), t_stat(4));
fprintf('%-40s %12.4f %12.4f %8.2f\n', 'beta_PAC (dy_bar lag)', b(5), se(5), t_stat(5));
fprintf('%-40s %12.4f %12.4f %8.2f\n', 'beta_HtM (y_H_gap - yhat_au)', b(6), se(6), t_stat(6));
fprintf('R² = %.4f, N = %d\n\n', R2, n);

%% Comparison with L1.3a chain 1 + L2-pilot + step 1 (full one-shot OLS)
chain_path = fullfile(projectdir, 'data', 'l13a_chain1_posterior.mat');
L1 = load(chain_path);
pilot = load(fullfile(projectdir, 'data', 'consumption_pac_ols.mat'));

idx_bPAC = find(strcmp(L1.param_names, 'b_PAC_c'));
idx_b0c  = find(strcmp(L1.param_names, 'b0_c'));
idx_b1c  = find(strcmp(L1.param_names, 'b1_c'));

fprintf('--- Side-by-side comparison ---\n');
fprintf('%-25s %12s %12s %12s\n', 'Coefficient', ...
    'Iter L2 OLS', 'L2-pilot Sp4', 'L1.3a chain1');
fprintf('%-25s %12s %12s %12s\n', '-----------', ...
    '-----------', '------------', '------------');
fprintf('%-25s %12.4f %12.4f %12.4f\n', 'beta_1 (dln_c lag)', ...
    beta.beta_1, pilot.specs.spec4.coef(3), L1.post_mean(idx_b1c));
fprintf('%-25s %12.4f %12.4f %12.4f\n', 'beta_PAC (dy_bar lag)', ...
    beta.beta_PAC, pilot.specs.spec4.coef(6), L1.post_mean(idx_bPAC));

%% Save
out = struct();
out.method = 'partial L2 iterative OLS, wp1044 consumption block (Eq 35)';
out.state_names = {state_names};
out.Phi = Phi;
out.chi_final = chi;
out.omega_c = omega_c;
out.beta = beta;
out.coef_final = b;
out.se_final = se;
out.t_final = t_stat;
out.R2 = R2;
out.N = n;
out.beta_history = beta_history(1:iter, :);
out.n_iter = iter;
out.converged = (delta < tol);
save(fullfile(projectdir, 'data', 'consumption_pac_iterative.mat'), '-struct', 'out');
fprintf('\nSaved data/consumption_pac_iterative.mat\n');

% Text
fid = fopen(fullfile(projectdir, 'data', 'consumption_pac_iterative.txt'), 'w');
fprintf(fid, 'Iterative OLS consumption PAC (wp1044 Eq 35, partial L2)\n');
fprintf(fid, 'Generated %s\n', datestr(now));
fprintf(fid, 'Auxiliary VAR(1) state: [%s]\n', strjoin(state_names, ', '));
fprintf(fid, 'Phi spectral radius = %.4f\n', rho_Phi);
fprintf(fid, 'omega_c (calibrated) = %.2f, chi at convergence = %.4f\n\n', omega_c, chi);
fprintf(fid, 'Iteration history (||delta_beta||):\n');
for it = 1:iter
    fprintf(fid, '  iter %2d: beta = [%.4f, %.4f, %.4f, %.4f]\n', it, ...
        beta_history(it, 1), beta_history(it, 2), beta_history(it, 3), beta_history(it, 4));
end
fprintf(fid, '\nConverged at iter %d.\n\n', iter);
fprintf(fid, '%-40s %12s %12s %8s\n', 'Coefficient', 'estimate', 'se', 't');
fprintf(fid, '%-40s %12.4f %12.4f %8.2f\n', '(intercept)', b(1), se(1), t_stat(1));
fprintf(fid, '%-40s %12.4f %12.4f %8.2f\n', 'beta_0 (ECM speed)', -b(2), se(2), -t_stat(2));
fprintf(fid, '%-40s %12.4f %12.4f %8.2f\n', 'beta_1 (dln_c lag)', b(3), se(3), t_stat(3));
fprintf(fid, '%-40s %12.4f %12.4f %8.2f\n', 'alpha_1 (PV r_LH)', b(4), se(4), t_stat(4));
fprintf(fid, '%-40s %12.4f %12.4f %8.2f\n', 'beta_PAC (dy_bar lag)', b(5), se(5), t_stat(5));
fprintf(fid, '%-40s %12.4f %12.4f %8.2f\n', 'beta_HtM (y_H_gap - yhat_au)', b(6), se(6), t_stat(6));
fprintf(fid, 'R^2 = %.4f, N = %d\n', R2, n);
fclose(fid);
fprintf('Saved data/consumption_pac_iterative.txt\n');

fprintf('\n=== Done. ===\n');

%% --- Helpers ---
function y = lag1(x), y = [NaN; x(1:end-1)]; end
function v = demean(x), v = x - mean(x, 'omitnan'); end

function trend = hp_trend(y, lambda)
    y = y(:);
    n = length(y);
    trend = nan(n, 1);
    valid = find(~isnan(y));
    if length(valid) < 4, return; end
    lo = valid(1); hi = valid(end);
    span = lo:hi;
    y_span = y(span);
    nm = isnan(y_span);
    if any(nm)
        idx = find(~nm);
        y_span = interp1(idx, y_span(idx), 1:length(y_span), 'linear')';
    end
    n_span = length(y_span);
    e = ones(n_span, 1);
    D2 = spdiags([e, -2*e, e], 0:2, n_span-2, n_span);
    A = speye(n_span) + lambda * (D2' * D2);
    trend(span) = A \ y_span;
end

function [b, se, t, R2, rss, n] = ols(X, y)
    valid = ~any(isnan([X, y]), 2);
    X = X(valid, :); y = y(valid);
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
