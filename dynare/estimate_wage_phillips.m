function results = estimate_wage_phillips(logfile)
%% estimate_wage_phillips.m — OLS estimation of Okun's law + Wage Phillips curve
%
% Estimates the remaining wage-price spiral parameters that are currently
% calibrated from FR-BDF:
%   1. Okun's law: u_gap = rho_u_gap * u_gap(-1) + okun_coeff * yhat_au
%   2. Wage Phillips: pi_w = lambda_w*pi_w(-1) + gamma_w*pi_au + kappa_w*pv_u_gap
%                            + (1-lambda_w-gamma_w)*pibar_au + (1-lambda_w)*dln_prod + eps_w
%
% FR-BDF estimates (Table 4.5.3): rho_u=0.946, okun=-0.246, gamma_w=0.24
% AU-PAC current calibration: rho_u=0.94, okun=-0.33, gamma_w=0.15
%
% USAGE:
%   results = estimate_wage_phillips()
%   results = estimate_wage_phillips('my_log.txt')
%
% DATA:
%   dataset.csv: yhat_au, pi_au (quarterly %)
%   extended_dataset.csv: au_urate (%), au_pi_w (quarterly %)

if nargin < 1 || isempty(logfile)
    logfile = 'log_wage_phillips_estimation.txt';
end

fid = fopen(logfile, 'w');
fprintf(fid, '================================================================\n');
fprintf(fid, '  WAGE-PRICE SPIRAL ESTIMATION (OLS)\n');
fprintf(fid, '  %s\n', datestr(now));
fprintf(fid, '================================================================\n\n');

%% Load data
% Core dataset (yhat_au, pi_au)
core = readtable('c:\Users\david\french_model\dataset.csv');
% Extended dataset (unemployment, wages)
ext = readtable('c:\Users\david\french_model\data\extended_dataset.csv');

% Align samples
% Core: 1993Q1-2024Q4. Extended: 1993Q1-2023Q3
% Use overlapping period
T_core = height(core);
T_ext = height(ext);
T = min(T_core, T_ext);

yhat_au = core.au_ygap(1:T);
pi_au = core.au_pi(1:T);
i_au = core.au_irate(1:T);
urate = ext.au_urate(1:T);
pi_w = ext.au_pi_w(1:T);  % quarterly wage inflation (ULC growth)

% Check for NaN
valid = ~isnan(yhat_au) & ~isnan(pi_au) & ~isnan(urate) & ~isnan(pi_w);
first_valid = find(valid, 1, 'first');
last_valid = find(valid, 1, 'last');

fprintf(fid, '--- Data loaded ---\n');
fprintf(fid, '  Core dataset: %d obs\n', T_core);
fprintf(fid, '  Extended dataset: %d obs\n', T_ext);
fprintf(fid, '  Valid sample: obs %d to %d (%d observations)\n\n', ...
    first_valid, last_valid, sum(valid(first_valid:last_valid)));

%% ========================================================================
%  PART 1: Okun's Law
%  u_gap(t) = rho_u * u_gap(t-1) + okun * yhat_au(t) + epsilon
%  ========================================================================
fprintf(fid, '--- PART 1: Okun''s Law ---\n\n');

% Construct unemployment gap: demean unemployment rate
u_mean = mean(urate(~isnan(urate)));
u_gap = urate - u_mean;

fprintf(fid, '  Mean unemployment rate: %.2f%%\n', u_mean);
fprintf(fid, '  Unemployment gap range: [%.2f, %.2f]\n\n', min(u_gap), max(u_gap));

% OLS: u_gap(t) = rho * u_gap(t-1) + okun * yhat_au(t)
% Use valid sample
idx = (first_valid+1):last_valid;  % need one lag
Y_okun = u_gap(idx);
X_okun = [u_gap(idx-1), yhat_au(idx)];

% Remove any remaining NaN rows
ok = ~any(isnan([Y_okun, X_okun]), 2);
Y_okun = Y_okun(ok);
X_okun = X_okun(ok, :);

beta_okun = X_okun \ Y_okun;
resid_okun = Y_okun - X_okun * beta_okun;
T_okun = length(Y_okun);
SSR_okun = resid_okun' * resid_okun;
SST_okun = (Y_okun - mean(Y_okun))' * (Y_okun - mean(Y_okun));
R2_okun = 1 - SSR_okun / SST_okun;
sigma2_okun = SSR_okun / (T_okun - 2);
se_okun = sqrt(diag(sigma2_okun * inv(X_okun' * X_okun)));
dw_okun = sum(diff(resid_okun).^2) / SSR_okun;

rho_u_est = beta_okun(1);
okun_est = beta_okun(2);

fprintf(fid, '  Okun''s Law: u_gap(t) = rho * u_gap(t-1) + okun * yhat_au(t)\n\n');
fprintf(fid, '  %-18s %10s %10s %8s %10s\n', 'Parameter', 'Estimate', 'Std.Err', 't-stat', 'FR-BDF');
fprintf(fid, '  %s\n', repmat('-', 1, 58));
fprintf(fid, '  %-18s %+10.4f %10.4f %8.2f %+10.4f\n', ...
    'rho_u_gap', rho_u_est, se_okun(1), rho_u_est/se_okun(1), 0.946);
fprintf(fid, '  %-18s %+10.4f %10.4f %8.2f %+10.4f\n', ...
    'okun_coeff', okun_est, se_okun(2), okun_est/se_okun(2), -0.246);
fprintf(fid, '\n  R2 = %.4f, DW = %.2f, T = %d\n\n', R2_okun, dw_okun, T_okun);

%% ========================================================================
%  PART 2: Wage Phillips Curve
%  pi_w = lambda_w*pi_w(-1) + gamma_w*pi_au + kappa_w*pv_u_gap
%          + (1-lambda_w-gamma_w)*pibar_au + (1-lambda_w)*dln_prod + eps_w
%
%  Growth neutrality: coefficient on pibar_au = 1-lambda_w-gamma_w
%  Also: coefficient on dln_prod = 1-lambda_w
%  These constraints make the long-run wage growth = pibar + productivity growth
%
%  Reparameterize: subtract pibar_au from both sides:
%  (pi_w - pibar_au) = lambda_w*(pi_w(-1) - pibar_au)
%                     + gamma_w*(pi_au - pibar_au)
%                     + kappa_w*pv_u_gap
%                     + (1-lambda_w)*(dln_prod)
%  ========================================================================
fprintf(fid, '--- PART 2: Wage Phillips Curve ---\n\n');

% Construct pibar_au (inflation anchor) — use HP trend of pi_au
% For estimation, use sample mean as proxy for constant inflation target
tmp = pi_au(first_valid:last_valid); pibar_est = mean(tmp(~isnan(tmp)));
fprintf(fid, '  pibar_au proxy (sample mean): %.4f quarterly (%.2f%% annualized)\n\n', ...
    pibar_est, pibar_est * 4);

% dln_prod: labor productivity growth
% In the model, dln_prod = dln_tfp / (1-alpha_k). Since we don't directly
% observe TFP growth, use output growth - employment growth as proxy.
% For this estimation, set dln_prod = 0 (detrended, consistent with gap model)
% The (1-lambda_w)*dln_prod term drops out in the gap form.

% Construct pv_u_gap recursively:
% pv_u_gap(t) = (1-beta_w)*u_gap(t) + beta_w*pv_u_gap(t+1)
% => solve backward from terminal: pv_u_gap(T) = u_gap(T)
beta_w = 0.98;
pv_u = zeros(T, 1);
pv_u(last_valid) = u_gap(last_valid);
for t = (last_valid-1):-1:first_valid
    pv_u(t) = (1-beta_w) * u_gap(t) + beta_w * pv_u(t+1);
end

% Reparameterized form (gap version):
% (pi_w - pibar) = lambda_w*(pi_w(-1)-pibar) + gamma_w*(pi_au-pibar) + kappa_w*pv_u_gap
%
% Y = lambda_w * X1 + gamma_w * X2 + kappa_w * X3

idx_w = (first_valid+1):last_valid;

Y_wage = pi_w(idx_w) - pibar_est;
X1 = pi_w(idx_w-1) - pibar_est;     % lagged wage inflation gap
X2 = pi_au(idx_w) - pibar_est;       % CPI inflation gap
X3 = pv_u(idx_w);                    % PV unemployment gap

X_wage = [X1, X2, X3];

% Remove NaN
ok_w = ~any(isnan([Y_wage, X_wage]), 2);
Y_wage = Y_wage(ok_w);
X_wage = X_wage(ok_w, :);

beta_wage = X_wage \ Y_wage;
resid_wage = Y_wage - X_wage * beta_wage;
T_wage = length(Y_wage);
SSR_wage = resid_wage' * resid_wage;
SST_wage = (Y_wage - mean(Y_wage))' * (Y_wage - mean(Y_wage));
R2_wage = 1 - SSR_wage / SST_wage;
sigma2_wage = SSR_wage / (T_wage - 3);
se_wage = sqrt(diag(sigma2_wage * inv(X_wage' * X_wage)));
dw_wage = sum(diff(resid_wage).^2) / SSR_wage;

lambda_w_est = beta_wage(1);
gamma_w_est = beta_wage(2);
kappa_w_est = beta_wage(3);

% Implied pibar coefficient
pibar_coeff = 1 - lambda_w_est - gamma_w_est;

fprintf(fid, '  Wage Phillips (gap form):\n');
fprintf(fid, '  (pi_w - pibar) = lambda_w*(pi_w(-1)-pibar) + gamma_w*(pi_au-pibar) + kappa_w*pv_u_gap\n\n');
fprintf(fid, '  %-18s %10s %10s %8s %10s %10s\n', ...
    'Parameter', 'Estimate', 'Std.Err', 't-stat', 'Calibrated', 'Bayesian');
fprintf(fid, '  %s\n', repmat('-', 1, 68));
fprintf(fid, '  %-18s %+10.4f %10.4f %8.2f %+10.4f %+10.4f\n', ...
    'lambda_w', lambda_w_est, se_wage(1), lambda_w_est/se_wage(1), 0.247, 0.305);
fprintf(fid, '  %-18s %+10.4f %10.4f %8.2f %+10.4f %10s\n', ...
    'gamma_w', gamma_w_est, se_wage(2), gamma_w_est/se_wage(2), 0.15, '—');
fprintf(fid, '  %-18s %+10.4f %10.4f %8.2f %+10.4f %+10.4f\n', ...
    'kappa_w', kappa_w_est, se_wage(3), kappa_w_est/se_wage(3), 0.238, 0.062);
fprintf(fid, '  %-18s %+10.4f %10s %8s %+10.4f %10s\n', ...
    '1-lw-gw (pibar)', pibar_coeff, '—', '—', 1-0.247-0.15, '—');
fprintf(fid, '\n  R2 = %.4f, DW = %.2f, T = %d\n', R2_wage, dw_wage, T_wage);
fprintf(fid, '  Growth neutrality: pibar coeff = %.4f (should be > 0)\n\n', pibar_coeff);

if pibar_coeff < 0
    fprintf(fid, '  WARNING: Growth neutrality violated (pibar coeff < 0)\n');
    fprintf(fid, '  Consider constraining lambda_w + gamma_w < 1\n\n');
end

%% Store all results
results = struct();
results.rho_u_gap = rho_u_est;
results.okun_coeff = okun_est;
results.rho_u_gap_se = se_okun(1);
results.okun_coeff_se = se_okun(2);
results.R2_okun = R2_okun;
results.lambda_w = lambda_w_est;
results.gamma_w = gamma_w_est;
results.kappa_w = kappa_w_est;
results.lambda_w_se = se_wage(1);
results.gamma_w_se = se_wage(2);
results.kappa_w_se = se_wage(3);
results.R2_wage = R2_wage;
results.pibar_coeff = pibar_coeff;

%% Print parameter update block
fprintf(fid, '================================================================\n');
fprintf(fid, '  PARAMETER UPDATE BLOCK (copy to .mod files)\n');
fprintf(fid, '================================================================\n\n');

fprintf(fid, '%% Estimated from AU data (%s)\n', datestr(now, 'yyyy-mm-dd'));
fprintf(fid, '%% Okun''s law (R2=%.3f, T=%d)\n', R2_okun, T_okun);
fprintf(fid, 'rho_u_gap       = %.6f;  %% (s.e. %.4f)  FR-BDF: 0.946\n', rho_u_est, se_okun(1));
fprintf(fid, 'okun_coeff      = %.6f;  %% (s.e. %.4f)  FR-BDF: -0.246\n', okun_est, se_okun(2));
fprintf(fid, '\n');
fprintf(fid, '%% Wage Phillips curve (R2=%.3f, T=%d)\n', R2_wage, T_wage);
fprintf(fid, 'lambda_w        = %.6f;  %% (s.e. %.4f)  Bayesian post mean: 0.305\n', lambda_w_est, se_wage(1));
fprintf(fid, 'gamma_w         = %.6f;  %% (s.e. %.4f)  FR-BDF: 0.24, was calibrated 0.15\n', gamma_w_est, se_wage(2));
fprintf(fid, 'kappa_w         = %.6f;  %% (s.e. %.4f)  Bayesian post mean: 0.062\n', kappa_w_est, se_wage(3));

fprintf(fid, '\n================================================================\n');
fprintf(fid, '  COMPLETED: %s\n', datestr(now));
fprintf(fid, '================================================================\n');
fclose(fid);

fprintf('\n=== Wage Phillips estimation complete ===\n');
fprintf('  Results: %s\n', logfile);
end
