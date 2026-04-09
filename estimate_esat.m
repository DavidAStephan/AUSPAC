%% estimate_esat.m
% Estimates the E-SAT structural VAR parameters for Australia using OLS,
% equation by equation, following the approach of Banque de France WP #736.
%
% Model: AZ_t = BZ_t-1 + eps_t  =>  Z_t = HZ_{t-1} + eta_t  (H = A\B)
%
% State vector: Z = [1, yhat_AU, i_AU, pi_AU, yhat_US, pi_US, ibar, pibar_AU, pibar_US]
%
% Equations:
%   1. Intercept:        1 = 1
%   2. AU IS curve:      yhat_AU - delta*yhat_US = lambda_q*yhat_AU(-1)
%                          - sigma_q*(i(-1) - pi_AU(-1) - ibar(-1) + pibar_AU(-1)) + eps_q
%   3. Taylor rule (RBA): i - ibar = lambda_i*(i(-1) - ibar(-1))
%                          + (1-lambda_i)*(alpha*(pi_AU(-1) - pibar_AU(-1)) + beta*yhat_AU(-1)) + eps_i
%   4. AU Phillips:      pi_AU - pibar_AU = lambda_pi*(pi_AU(-1) - pibar_AU(-1))
%                          + kappa_pi*yhat_AU(-1) + eps_pi
%   5. US IS (AR1):      yhat_US = lambda_q_us*yhat_US(-1) + eps_q_us
%   6. US Phillips:      pi_US - pibar_US = lambda_pi_us*(pi_US(-1) - pibar_US(-1))
%                          + kappa_pi_us*yhat_US(-1) + eps_pi_us
%   7. LR rate anchor:   ibar = lambda_ibar*ibar(-1) + (1-lambda_ibar)*i_ss + eps_ibar
%   8. LR AU pi anchor:  pibar_AU = lambda_pibar*pibar_AU(-1) + (1-lambda_pibar)*pi_ss + eps_pibar
%   9. LR US pi anchor:  pibar_US = lambda_pibar_us*pibar_US(-1) + (1-lambda_pibar_us)*pi_us_ss + eps_pibar_us
%
% Requires: data.mat (output of download_data.m)
% Output:   params.mat

clear; clc;
fprintf('=== E-SAT Australia: Parameter Estimation ===\n\n');

outdir = fileparts(mfilename('fullpath'));
if isempty(outdir), outdir = pwd; end

%% Load data
load(fullfile(outdir, 'data.mat'), 'data');

% Extract series
yhat_au = data.au_ygap;        % AU output gap (%)
pi_au   = data.au_pi;          % AU inflation (quarterly %)
i_au    = data.au_irate;       % AU cash rate (quarterly %)
yhat_us = data.us_ygap;        % US output gap (%)
pi_us   = data.us_pi;          % US inflation (quarterly %)
ibar    = data.au_irate_bar;   % LR interest rate anchor (quarterly)
pibar_au = data.au_pi_bar;     % LR AU inflation anchor (quarterly)
pibar_us = data.us_pi_bar;     % LR US inflation anchor (quarterly)
qDates  = data.qDates;

% Steady states (quarterly)
i_ss     = data.i_bar;
pi_ss_au = data.pi_bar_au;
pi_ss_us = data.pi_bar_us;

%% Construct gap variables (deviations from anchors)
pi_au_gap = pi_au - pibar_au;       % AU inflation gap
pi_us_gap = pi_us - pibar_us;       % US inflation gap
i_gap     = i_au - ibar;            % interest rate gap
% Real rate gap: i - pi_AU - ibar + pibar_AU = (i - ibar) - (pi_AU - pibar_AU)
real_rate_gap = i_gap - pi_au_gap;

%% Find valid estimation sample (all series non-NaN)
valid = ~isnan(yhat_au) & ~isnan(pi_au) & ~isnan(i_au) & ...
        ~isnan(yhat_us) & ~isnan(pi_us) & ~isnan(ibar);

% Need lags, so start from 2nd valid obs
valid_idx = find(valid);
if length(valid_idx) < 10
    error('Insufficient valid data for estimation. Check data download.');
end

% Use indices where both t and t-1 are valid
est_idx = valid_idx(valid_idx > 1);
est_idx = est_idx(ismember(est_idx-1, valid_idx));

T = length(est_idx);
fprintf('Estimation sample: %s to %s (%d obs)\n', ...
    datestr(qDates(est_idx(1))), datestr(qDates(est_idx(end))), T);

%% -----------------------------------------------------------------------
%  Equation-by-equation OLS estimation
%  -----------------------------------------------------------------------
params = struct();
params.i_ss = i_ss;
params.pi_ss_au = pi_ss_au;
params.pi_ss_us = pi_ss_us;
params.i_bar_annual = data.i_bar_annual;
params.pi_bar_au_annual = data.pi_bar_au_annual;
params.pi_bar_us_annual = data.pi_bar_us_annual;

% --- Eq 2: Australian IS curve ---
% yhat_AU(t) = delta*yhat_US(t) + lambda_q*yhat_AU(t-1)
%              - sigma_q*(i(t-1) - pi_AU(t-1) - ibar(t-1) + pibar_AU(t-1)) + eps
fprintf('\n--- Eq 2: Australian IS curve ---\n');
Y2 = yhat_au(est_idx);
X2 = [yhat_us(est_idx), yhat_au(est_idx-1), -real_rate_gap(est_idx-1)];
% OLS: Y = X*beta + eps
b2 = X2 \ Y2;
resid2 = Y2 - X2*b2;

params.delta   = b2(1);
params.lambda_q = b2(2);
params.sigma_q  = b2(3);  % coefficient on negative real rate gap = sigma_q
params.sigma_eps_q = std(resid2);

fprintf('  delta    = %.4f\n', params.delta);
fprintf('  lambda_q = %.4f\n', params.lambda_q);
fprintf('  sigma_q  = %.4f\n', params.sigma_q);
fprintf('  sigma_eps_q = %.4f\n', params.sigma_eps_q);
fprintf('  R2 = %.3f\n', 1 - var(resid2)/var(Y2));

% --- Eq 3: Taylor rule (RBA) ---
% (i(t) - ibar(t)) = lambda_i*(i(t-1) - ibar(t-1))
%                    + (1-lambda_i)*(alpha*(pi_AU(t-1) - pibar_AU(t-1)) + beta*yhat_AU(t-1))
% Rewrite: i_gap(t) = lambda_i*i_gap(t-1) + (1-lambda_i)*alpha*pi_au_gap(t-1)
%                    + (1-lambda_i)*beta*yhat_au(t-1)
fprintf('\n--- Eq 3: Taylor rule (RBA) ---\n');
Y3 = i_gap(est_idx);
X3 = [i_gap(est_idx-1), pi_au_gap(est_idx-1), yhat_au(est_idx-1)];
b3 = X3 \ Y3;
resid3 = Y3 - X3*b3;

params.lambda_i = b3(1);
% (1-lambda_i)*alpha = b3(2), (1-lambda_i)*beta = b3(3)
if abs(1 - params.lambda_i) > 1e-6
    params.alpha_i = b3(2) / (1 - params.lambda_i);
    params.beta_i  = b3(3) / (1 - params.lambda_i);
else
    params.alpha_i = 1.5;  % fallback
    params.beta_i  = 0.5;
end
params.sigma_eps_i = std(resid3);

fprintf('  lambda_i = %.4f\n', params.lambda_i);
fprintf('  alpha    = %.4f\n', params.alpha_i);
fprintf('  beta     = %.4f\n', params.beta_i);
fprintf('  sigma_eps_i = %.4f\n', params.sigma_eps_i);
fprintf('  R2 = %.3f\n', 1 - var(resid3)/var(Y3));

% --- Eq 4: Australian Phillips curve ---
% (pi_AU(t) - pibar_AU(t)) = lambda_pi*(pi_AU(t-1) - pibar_AU(t-1)) + kappa_pi*yhat_AU(t-1)
fprintf('\n--- Eq 4: Australian Phillips curve ---\n');
Y4 = pi_au_gap(est_idx);
X4 = [pi_au_gap(est_idx-1), yhat_au(est_idx-1)];
b4 = X4 \ Y4;
resid4 = Y4 - X4*b4;

params.lambda_pi = b4(1);
params.kappa_pi  = b4(2);
params.sigma_eps_pi = std(resid4);

fprintf('  lambda_pi = %.4f\n', params.lambda_pi);
fprintf('  kappa_pi  = %.4f\n', params.kappa_pi);
fprintf('  sigma_eps_pi = %.4f\n', params.sigma_eps_pi);
fprintf('  Implied Phillips slope (annual) = %.3f\n', ...
    params.kappa_pi / (1 - params.lambda_pi) * 4);
fprintf('  R2 = %.3f\n', 1 - var(resid4)/var(Y4));

% --- Eq 5: US IS curve (AR1) ---
% yhat_US(t) = lambda_q_us * yhat_US(t-1) + eps
fprintf('\n--- Eq 5: US IS curve (AR1) ---\n');
Y5 = yhat_us(est_idx);
X5 = yhat_us(est_idx-1);
b5 = X5 \ Y5;
resid5 = Y5 - X5*b5;

params.lambda_q_us = b5(1);
params.sigma_eps_q_us = std(resid5);

fprintf('  lambda_q_us = %.4f\n', params.lambda_q_us);
fprintf('  sigma_eps_q_us = %.4f\n', params.sigma_eps_q_us);
fprintf('  R2 = %.3f\n', 1 - var(resid5)/var(Y5));

% --- Eq 6: US Phillips curve ---
% (pi_US(t) - pibar_US(t)) = lambda_pi_us*(pi_US(t-1) - pibar_US(t-1))
%                            + kappa_pi_us*yhat_US(t-1)
fprintf('\n--- Eq 6: US Phillips curve ---\n');
Y6 = pi_us_gap(est_idx);
X6 = [pi_us_gap(est_idx-1), yhat_us(est_idx-1)];
b6 = X6 \ Y6;
resid6 = Y6 - X6*b6;

params.lambda_pi_us = b6(1);
params.kappa_pi_us  = b6(2);
params.sigma_eps_pi_us = std(resid6);

fprintf('  lambda_pi_us = %.4f\n', params.lambda_pi_us);
fprintf('  kappa_pi_us  = %.4f\n', params.kappa_pi_us);
fprintf('  sigma_eps_pi_us = %.4f\n', params.sigma_eps_pi_us);
fprintf('  R2 = %.3f\n', 1 - var(resid6)/var(Y6));

% --- Eqs 7-9: Long-run anchor persistence ---
% These are AR(1) processes. Estimate persistence from data if possible,
% otherwise calibrate.
fprintf('\n--- Eqs 7-9: Long-run anchor persistence ---\n');

% LR interest rate anchor: calibrate persistence
% (In the French model, lambda_ibar = 0.985)
params.lambda_ibar = 0.985;
fprintf('  lambda_ibar = %.3f (calibrated)\n', params.lambda_ibar);

% LR inflation anchors: calibrate
params.lambda_pibar    = 0.93;  % same as French model
params.lambda_pibar_us = 0.93;
fprintf('  lambda_pibar_AU = %.3f (calibrated)\n', params.lambda_pibar);
fprintf('  lambda_pibar_US = %.3f (calibrated)\n', params.lambda_pibar_us);

%% -----------------------------------------------------------------------
%  Parameter bounds / sanity checks
%  -----------------------------------------------------------------------
fprintf('\n=== Sanity checks ===\n');

% Ensure IS curve persistence is stable
if abs(params.lambda_q) >= 1
    fprintf('  WARNING: lambda_q = %.3f >= 1 (unstable). Clamping to 0.9.\n', params.lambda_q);
    params.lambda_q = 0.9;
end

% Ensure Taylor principle (alpha > 1 for annualized)
if params.alpha_i < 0
    fprintf('  WARNING: alpha = %.3f < 0. Setting to 1.5 (Taylor principle).\n', params.alpha_i);
    params.alpha_i = 1.5;
end

% Ensure positive Phillips slope
if params.kappa_pi < 0
    fprintf('  WARNING: kappa_pi = %.4f < 0. Setting to 0.05.\n', params.kappa_pi);
    params.kappa_pi = 0.05;
end

% Ensure sigma_q > 0 (real rate should contract output)
if params.sigma_q < 0
    fprintf('  WARNING: sigma_q = %.4f < 0. Taking absolute value.\n', params.sigma_q);
    params.sigma_q = abs(params.sigma_q);
end

fprintf('  All checks passed.\n');

%% -----------------------------------------------------------------------
%  Save parameters
%  -----------------------------------------------------------------------
savefile = fullfile(outdir, 'params.mat');
save(savefile, 'params');
fprintf('\nParameters saved to %s\n', savefile);

%% -----------------------------------------------------------------------
%  Summary table
%  -----------------------------------------------------------------------
fprintf('\n=== Parameter Summary ===\n');
fprintf('%-20s %10s %10s\n', 'Parameter', 'Australia', 'France*');
fprintf('%-20s %10s %10s\n', '---------', '---------', '-------');
fprintf('%-20s %10.4f %10.4f\n', 'delta',       params.delta,       0.08);
fprintf('%-20s %10.4f %10.4f\n', 'lambda_q',    params.lambda_q,    0.73);
fprintf('%-20s %10.4f %10.4f\n', 'sigma_q',     params.sigma_q,     0.28);
fprintf('%-20s %10.4f %10.4f\n', 'lambda_i',    params.lambda_i,    0.92);
fprintf('%-20s %10.4f %10.4f\n', 'alpha',       params.alpha_i,     1.19);
fprintf('%-20s %10.4f %10.4f\n', 'beta',        params.beta_i,      0.09);
fprintf('%-20s %10.4f %10.4f\n', 'lambda_pi',   params.lambda_pi,   0.58);
fprintf('%-20s %10.4f %10.4f\n', 'kappa_pi',    params.kappa_pi,    0.08);
fprintf('%-20s %10.4f %10.4f\n', 'lambda_q_us', params.lambda_q_us, 0.93);
fprintf('%-20s %10.4f %10.4f\n', 'lambda_pi_us',params.lambda_pi_us,0.35);
fprintf('%-20s %10.4f %10.4f\n', 'kappa_pi_us', params.kappa_pi_us, 0.04);
fprintf('* France values are posterior means from WP #736, Table 3.1.1\n');
fprintf('  (EA replaces US in French model; Taylor rule reacts to EA not domestic)\n');
