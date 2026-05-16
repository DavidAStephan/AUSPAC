%% run_phase_r_refit.m — Phase R refit driver (audit-driven structural fixes)
%
% Phase R refit (2026-05-15):
%   1.B  Improved pv_X_aux documentation (no functional change)
%   1.C  Fixed eq_dln_n_star_bar: added Δq channel + sign on dln_tfp (#17, #21)
%   1.D  Fixed wage Phillips: sign on κ_w + indexation pi_au→pi_c (#22, #23)
%   1.E  Added pv_r_lh_gap forward real-rate PV channel (#26)
%
% Sub-scripts (estimate_pac_smooth_driver, run_bayesian_estimation,
% run_bayesian_mcmc) all call `clear` which wipes our workspace. We use
% a global t_phase_r_start for total wall time and rely on each sub-script's
% own timing for stage durations.

clear; clc; close all;
global t_phase_r_start;
t_phase_r_start = tic;

cd(fullfile(fileparts(mfilename('fullpath')), '..', '..'));  % up to dynare/
setup_dynare_path();

fprintf('================================================================\n');
fprintf('  Phase R refit driver — %s\n', datestr(now));
fprintf('================================================================\n\n');

%% Stage 1: smoke test all 3 main variants compile under new specs
fprintf('=== Stage 1/4: Smoke test (compile + BK rank check) ===\n');
for variant = {'au_pac_var', 'au_pac', 'au_pac_mce'}
    name = variant{1};
    fprintf('  Compiling %s ... ', name);
    try
        evalin('base', sprintf('dynare %s noclearall nograph', name));
        eig_count = sum(abs(oo_.dr.eigval) > 1);
        fprintf('OK (forward eigvals: %d)\n', eig_count);
    catch ME
        fprintf('FAIL: %s\n', ME.message);
        fprintf('\nABORTING — Phase R fixes broke BK rank for %s\n', name);
        rethrow(ME);
    end
    clearvars -global M_ oo_ options_ estim_params_ bayestopt_ dataset_ dataset_info;
end

%% Stage 2: Refresh smoothed series for Bayesian estimation
fprintf('\n=== Stage 2/4: Refresh smoothed series ===\n');
try
    estimate_pac_smooth_driver;
    fprintf('  Stage 2/4: smoother run completed\n');
catch ME
    fprintf('  Smoother FAIL: %s\n', ME.message);
    rethrow(ME);
end

%% Stage 3: Bayesian Stage 1 — csminwel mode finding
fprintf('\n=== Stage 3/4: Bayesian Stage 1 (csminwel mode) ===\n');
try
    run_bayesian_estimation;
    fprintf('  Stage 3/4: csminwel mode finding completed\n');
catch ME
    fprintf('  csminwel FAIL: %s\n', ME.message);
    rethrow(ME);
end

%% Stage 4: Bayesian Stage 2 — MH MCMC
fprintf('\n=== Stage 4/4: Bayesian Stage 2 (MH 20k×2 chains) ===\n');
try
    run_bayesian_mcmc;
    fprintf('  Stage 4/4: MH MCMC completed\n');
catch ME
    fprintf('  MCMC FAIL: %s\n', ME.message);
    rethrow(ME);
end

%% Stage 5: Extract results and compare to Phase Q baseline
fprintf('\n=== Stage 5/4: Extract results + compare to Phase Q ===\n');
extract_mcmc_results;

% Phase Q baseline LMDs for comparison
fprintf('\n  Phase R refit results vs Phase Q baseline:\n');
try
    R = load('bayesian_mcmc_results.mat');
    if isfield(R, 'oo_') && isfield(R.oo_, 'MarginalDensity')
        laplace_R = R.oo_.MarginalDensity.LaplaceApproximation;
        mhm_R     = R.oo_.MarginalDensity.ModifiedHarmonicMean;
        fprintf('    LMD Laplace:  Phase Q = -801.71  ->  Phase R = %.2f  (delta = %+.2f)\n', ...
            laplace_R, laplace_R - (-801.71));
        fprintf('    LMD MHM:      Phase Q = -802.27  ->  Phase R = %.2f  (delta = %+.2f)\n', ...
            mhm_R, mhm_R - (-802.27));
        if mhm_R - (-802.27) < -5
            warning('phase_r:lmd_drop', ...
                'Phase R MHM dropped by >5 nats. Investigate before accepting refit.');
        end
    else
        fprintf('    LMD comparison unavailable (no MarginalDensity field)\n');
    end
catch ME
    fprintf('    Could not load LMD comparison: %s\n', ME.message);
end

%% Wrap-up
global t_phase_r_start;
fprintf('\n================================================================\n');
if ~isempty(t_phase_r_start)
    fprintf('  Phase R refit complete. Total wall time: %.1f min\n', toc(t_phase_r_start)/60);
else
    fprintf('  Phase R refit complete.\n');
end
fprintf('================================================================\n');

fprintf('\nNext steps:\n');
fprintf('  1. Review mcmc_posterior_table.md for parameter shifts vs Phase Q\n');
fprintf('  2. Apply posteriors via tools/apply_mcmc_writeback.py\n');
fprintf('  3. Re-run IRFs (irf=200) and regenerate paper figures\n');
fprintf('  4. Run forward_guidance to verify no-puzzle property (Phase L)\n');
