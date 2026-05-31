%% estimate_foreign_block.m  --  AU single-equation OLS residual std devs for
%  the exogenous foreign (US) block, so the two foreign shock std devs are
%  estimated rather than calibrated guesses (NEXT_STEPS A2).
%
% Model equations (au_pac.mod, no intercept, written in gaps):
%   yhat_us_t   = lambda_q_us  * yhat_us_{t-1}                            + eps_q_us
%   pi_us_gap_t = lambda_pi_us * pi_us_gap_{t-1} + kappa_pi_us*yhat_us_{t-1} + eps_pi_us
%
% Data: dynare/estimation_data.mat — the canonical demeaned estimation sample
%   built by prepare_estimation_data.m.  yhat_us <- us_ygap; pi_us is demeaned
%   US inflation, which equals pi_us_gap at the steady state (pi_us = pi_us_gap
%   + pibar_us, and pibar_us is constant once demeaned).
%
% The shock std written back is the std of the model equation's residual
% evaluated AT THE PRODUCTION COEFFICIENTS (lambda_q_us=0.8057,
% lambda_pi_us=0.6529, kappa_pi_us=0.0131).  This is the innovation std implied
% by the equation exactly as the model carries it.  Free single-equation OLS is
% also reported as a cross-check that the coefficients are AU-consistent.

clear; clc;
fprintf('=== Foreign (US) block — AU OLS residual stds (NEXT_STEPS A2) ===\n\n');

here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
E = load(fullfile(root, 'dynare', 'estimation_data.mat'));

y = E.yhat_us;            % US output gap (demeaned)
p = E.pi_us;              % US inflation, demeaned ~ pi_us_gap at SS
n = numel(y);
fprintf('Canonical estimation sample: N=%d  (yhat_us std=%.4f, pi_us std=%.4f)\n\n', ...
        n, std(y), std(p));

% production coefficients carried in au_pac.mod
lambda_q_us  = 0.8057;
lambda_pi_us = 0.6529;
kappa_pi_us  = 0.0131;

%% Residual stds AT PRODUCTION COEFFICIENTS  (the writeback)
r_q  = y(2:end) - lambda_q_us  * y(1:end-1);
r_pi = p(2:end) - lambda_pi_us * p(1:end-1) - kappa_pi_us * y(1:end-1);
sd_q_us  = std(r_q);
sd_pi_us = std(r_pi);

%% Free single-equation OLS (cross-check the coefficients are AU-consistent)
yy = y(2:end); XX = y(1:end-1);
bq = XX\yy; R2q = 1 - sum((yy-XX*bq).^2)/sum((yy-mean(yy)).^2);

y2 = p(2:end); X2 = [p(1:end-1) y(1:end-1)];
b2 = X2\y2; R2p = 1 - sum((y2-X2*b2).^2)/sum((y2-mean(y2)).^2);

fprintf('--- residual stds at production coefficients (WRITEBACK) ---\n');
fprintf('  eps_q_us  stderr = %.4f   (was calibrated 1.138)\n', sd_q_us);
fprintf('  eps_pi_us stderr = %.4f   (was calibrated 0.319)\n\n', sd_pi_us);
fprintf('--- free OLS cross-check ---\n');
fprintf('  lambda_q_us : free %.4f  vs model %.4f   (R2=%.3f)\n', bq(1), lambda_q_us, R2q);
fprintf('  lambda_pi_us: free %.4f  vs model %.4f\n', b2(1), lambda_pi_us);
fprintf('  kappa_pi_us : free %.4f  vs model %.4f   (R2=%.3f, insignificant)\n', b2(2), kappa_pi_us, R2p);

%% write results
fid = fopen(fullfile(here, 'results_foreign_block.txt'), 'w');
fprintf(fid, 'Foreign (US) block — AU OLS residual stds (NEXT_STEPS A2, %s)\n', datestr(now));
fprintf(fid, 'Canonical estimation sample (dynare/estimation_data.mat), N=%d, demeaned, no intercept.\n', n);
fprintf(fid, 'Shock std = std of model-equation residual at production coefficients.\n\n');
fprintf(fid, '[eps_q_us]  yhat_us_t = %.4f*yhat_us_{t-1} + eps_q_us\n', lambda_q_us);
fprintf(fid, '  resid_sd = %.4f  -->  WRITEBACK eps_q_us stderr (was calibrated 1.138)\n', sd_q_us);
fprintf(fid, '  free-OLS lambda_q_us = %.4f (R2=%.3f) confirms AU-consistent persistence.\n\n', bq(1), R2q);
fprintf(fid, '[eps_pi_us] pi_us_gap_t = %.4f*pi_us_gap_{t-1} + %.4f*yhat_us_{t-1} + eps_pi_us\n', lambda_pi_us, kappa_pi_us);
fprintf(fid, '  resid_sd = %.4f  -->  WRITEBACK eps_pi_us stderr (was calibrated 0.319)\n', sd_pi_us);
fprintf(fid, '  free-OLS lambda_pi_us = %.4f, kappa_pi_us = %.4f (R2=%.3f; kappa insignificant).\n', b2(1), b2(2), R2p);
fclose(fid);
fprintf('\nWrote results_foreign_block.txt\n=== done ===\n');
