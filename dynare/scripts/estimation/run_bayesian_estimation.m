%% run_bayesian_estimation.m
% Driver for Bayesian estimation of the AU-PAC model.
%
% Two stages:
%   Stage 1: Posterior mode via csminwel (mode_compute=4)
%            Fast (~5 min), produces mode file for Stage 2
%   Stage 2: MCMC (mh_replic=20000, 2 chains)
%            Slow (~1-2 hours), produces posterior distributions
%
% USAGE:
%   >> cd(<repo>/dynare); run_bayesian_estimation
%   (Dynare is auto-located by setup_dynare_path; set DYNARE_PATH env var
%    to override the default install locations.)
%
% OBSERVABLES (9):
%   yhat_au, pi_au, i_au, yhat_us, pi_us, pi_w, dln_c, dln_ib, i_10y
%
% ESTIMATED PARAMETERS (28):
%   16 PAC structural params (5 EC speeds, 5 AR1, 3 output gaps, 2 rate/supply, 1 wage)
%   3 E-SAT params (lambda_w, gamma_w, kappa_w)
%   9 shock std devs

clear; clc;
cd(fullfile(fileparts(mfilename('fullpath')), '..', '..'));  % up to dynare/
setup_dynare_path();

logfile = 'bayesian_estimation_log.txt';
fid = fopen(logfile, 'w');
log_msg = @(msg) fprintf_both(fid, msg);

log_msg('================================================================\n');
log_msg('  AU_PAC BAYESIAN ESTIMATION\n');
log_msg(sprintf('  %s\n', datestr(now)));
log_msg('================================================================\n\n');

%% 1. Prepare estimation data (non-demeaned for Kalman filter SS matching)
log_msg('Preparing Bayesian estimation data (non-demeaned)...\n');
prepare_bayesian_data();

% Verify data contents
d = load('estimation_data.mat');
fnames = fieldnames(d);
log_msg(sprintf('estimation_data.mat: %d variables\n', length(fnames)));
for k = 1:length(fnames)
    v = d.(fnames{k});
    log_msg(sprintf('  %-10s: T=%d, mean=%.4f, std=%.4f\n', ...
        fnames{k}, length(v), mean(v), std(v)));
end

%% 2. Generate au_pac_bayesian.mod
log_msg('\n--- Generating au_pac_bayesian.mod ---\n');
generate_bayesian_mod(1);

%% 3. Run Stage 1: posterior mode
log_msg('\n--- Stage 1: Posterior mode (mode_compute=4, csminwel) ---\n');
log_msg('  This runs dynare au_pac_bayesian with mh_replic=0\n');
log_msg('  Estimated parameters: 19 structural + 9 shock std devs = 28 total\n\n');

try
    dynare au_pac_bayesian noclearall

    log_msg('\n--- Stage 1 COMPLETE ---\n');

    % Extract mode results
    if isfield(oo_, 'posterior_mode')
        pm = oo_.posterior_mode;
        log_msg('\nPosterior mode found:\n');
        if isfield(pm, 'parameters')
            pfields = fieldnames(pm.parameters);
            log_msg(sprintf('  %-20s %10s %10s\n', 'Parameter', 'Mode', 'Prior mean'));
            for k = 1:length(pfields)
                log_msg(sprintf('  %-20s %10.4f\n', pfields{k}, pm.parameters.(pfields{k})));
            end
        end
        if isfield(pm, 'shocks_std')
            sfields = fieldnames(pm.shocks_std);
            for k = 1:length(sfields)
                log_msg(sprintf('  %-20s %10.4f (std dev)\n', sfields{k}, pm.shocks_std.(sfields{k})));
            end
        end
    end

    % Log the mode value
    if isfield(oo_, 'MarginalDensity')
        log_msg(sprintf('\nLog marginal density (Laplace): %.4f\n', oo_.MarginalDensity.LaplaceApproximation));
    end

    log_msg(sprintf('\nMode file: au_pac_bayesian/Output/au_pac_bayesian_mode.mat\n'));
    log_msg('To run MCMC (Stage 2): edit au_pac_bayesian.mod, set mh_replic=20000\n');

catch ME
    log_msg(sprintf('\nERROR: %s\n', ME.message));
    log_msg(sprintf('Identifier: %s\n', ME.identifier));
    for k = 1:length(ME.stack)
        log_msg(sprintf('  %s:%d (%s)\n', ME.stack(k).file, ME.stack(k).line, ME.stack(k).name));
    end
end

%% Save workspace
save('bayesian_estimation_results.mat', 'M_', 'oo_', 'options_');
log_msg(sprintf('\nResults saved to bayesian_estimation_results.mat\n'));

log_msg('\n================================================================\n');
log_msg('  BAYESIAN ESTIMATION COMPLETE\n');
log_msg('================================================================\n');
fclose(fid);

function fprintf_both(fid, msg)
    fprintf(msg);
    if fid > 0
        fprintf(fid, msg);
    end
end
