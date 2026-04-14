%% run_phase1_estimation.m — Phase 1: Estimate auxiliaries + wage Phillips
%
% Steps:
%   1. Run Kalman smoother to get smoothed endogenous variables
%   2. Estimate 7 var_model auxiliary equations from smoothed data
%   3. Estimate Okun's law + wage Phillips curve from observed data
%   4. Log comparison: calibrated (FR-BDF) vs estimated (AU)
%
% Prerequisites: au_pac.mod compiles, smoother data exists.

clear; clc;
addpath('C:\dynare\6.5\matlab');
cd('c:\Users\david\french_model\dynare');

logfile = 'log_phase1_estimation.txt';
fid = fopen(logfile, 'w');
fprintf(fid, '================================================================\n');
fprintf(fid, '  PHASE 1: AUXILIARY + WAGE ESTIMATION\n');
fprintf(fid, '  %s\n', datestr(now));
fprintf(fid, '================================================================\n\n');

%% ========================================================================
%  STEP 1: Run Kalman smoother (if smoother_results.mat is stale or missing)
%  ========================================================================
fprintf(fid, '--- Step 1: Kalman smoother ---\n');

need_smoother = true;
if exist('smoother_results.mat', 'file')
    d = dir('smoother_results.mat');
    age_hours = (now - d.datenum) * 24;
    if age_hours < 2
        fprintf(fid, '  smoother_results.mat is fresh (%.1f hours old), skipping.\n\n', age_hours);
        need_smoother = false;
    end
end

if need_smoother
    fprintf(fid, '  Running Pass 1: dynare au_pac json=compute...\n');
    dynare au_pac json=compute noclearall nograph

    % Build companion matrix
    if ~isstruct(oo_.var), oo_.var = struct(); end
    get_companion_matrix('esat_enriched', 'var');

    % Initialize PAC
    pac_models = {'pac_pQ', 'pac_c', 'pac_ib', 'pac_ih', 'pac_n'};
    for k = 1:length(pac_models)
        pac.initialize(pac_models{k});
        pac.update.expectation(pac_models{k});
    end

    fprintf(fid, '  Pass 1 complete: %d endo, %d exo\n', M_.endo_nbr, M_.exo_nbr);

    % Save Pass 1 state
    M_pass1 = M_; oo_pass1 = oo_; options_pass1 = options_;

    % Run Pass 2: smoother
    fprintf(fid, '  Running Pass 2: Kalman smoother...\n');

    % Prepare smoother data
    prepare_smoother_data();

    % Generate smoother mod if needed
    if ~exist('au_pac_smooth.mod', 'file')
        generate_smoother_mod();
    end

    % Clear and run smoother
    clearvars -global M_ oo_ options_ estim_params_ bayestopt_ dataset_ dataset_info;
    dynare au_pac_smooth noclearall nograph

    % Extract results
    oo_smooth = struct();
    oo_smooth.SmoothedVariables = oo_.SmoothedVariables;
    save('smoother_results.mat', 'oo_smooth');
    fprintf(fid, '  Smoother complete: %d smoothed variables\n\n', ...
        length(fieldnames(oo_.SmoothedVariables)));

    % Restore Pass 1 state for subsequent PAC estimation
    M_ = M_pass1; oo_ = oo_pass1; options_ = options_pass1;
end

fclose(fid);

%% ========================================================================
%  STEP 2: Estimate var_model auxiliary equations
%  ========================================================================
fprintf('\n=== Step 2: Estimating var_model auxiliary equations ===\n');
aux_results = estimate_var_auxiliary('smoother_results.mat', 'log_var_auxiliary_estimation.txt');

% Append summary to main log
fid = fopen(logfile, 'a');
fprintf(fid, '--- Step 2: var_model auxiliary estimation ---\n');
fprintf(fid, '  See log_var_auxiliary_estimation.txt for details\n');
fprintf(fid, '  Key results (AR persistence):\n');
ar_params = {'rho_pQ_aux', 'rho_n_aux', 'rho_yh_aux', 'rho_c_aux', ...
             'rho_ib_aux', 'rho_rKB_aux', 'rho_ih_aux'};
cal_vals = [0.70, 0.67, 0.92, 0.60, 0.59, 0.30, 0.71];
for k = 1:length(ar_params)
    if isfield(aux_results, ar_params{k})
        fprintf(fid, '    %-18s: FR-BDF %.2f -> AU est %.4f\n', ...
            ar_params{k}, cal_vals(k), aux_results.(ar_params{k}));
    end
end
fprintf(fid, '\n');
fclose(fid);

%% ========================================================================
%  STEP 3: Estimate wage Phillips curve
%  ========================================================================
fprintf('\n=== Step 3: Estimating wage Phillips curve ===\n');
wage_results = estimate_wage_phillips('log_wage_phillips_estimation.txt');

% Append summary to main log
fid = fopen(logfile, 'a');
fprintf(fid, '--- Step 3: Wage Phillips estimation ---\n');
fprintf(fid, '  See log_wage_phillips_estimation.txt for details\n');
fprintf(fid, '  Okun: rho_u=%.4f (cal: 0.94), okun=%.4f (cal: -0.33)\n', ...
    wage_results.rho_u_gap, wage_results.okun_coeff);
fprintf(fid, '  Wage: lambda_w=%.4f (cal: 0.247), gamma_w=%.4f (cal: 0.15), kappa_w=%.4f (cal: 0.238)\n', ...
    wage_results.lambda_w, wage_results.gamma_w, wage_results.kappa_w);
fprintf(fid, '\n');

%% ========================================================================
%  SUMMARY
%  ========================================================================
fprintf(fid, '================================================================\n');
fprintf(fid, '  PHASE 1 ESTIMATION COMPLETE\n');
fprintf(fid, '  %s\n', datestr(now));
fprintf(fid, '================================================================\n\n');
fprintf(fid, '  33 parameters estimated from AU data:\n');
fprintf(fid, '    - 30 var_model auxiliary coefficients (7 equations)\n');
fprintf(fid, '    - 3 wage-price spiral parameters (Okun + wage Phillips)\n\n');
fprintf(fid, '  NEXT STEPS:\n');
fprintf(fid, '    1. Review log_var_auxiliary_estimation.txt for stability\n');
fprintf(fid, '    2. Update au_pac.mod parameter values with AU estimates\n');
fprintf(fid, '    3. Add missing PAC drivers (Step 1.3)\n');
fprintf(fid, '    4. Re-run full pipeline: compile -> smooth -> PAC estimate\n');
fprintf(fid, '    5. Compare IRFs before/after\n');
fclose(fid);

% Save combined results
save('phase1_estimation_results.mat', 'aux_results', 'wage_results');

fprintf('\n=== Phase 1 estimation complete ===\n');
fprintf('  Main log: %s\n', logfile);
fprintf('  Auxiliary: log_var_auxiliary_estimation.txt\n');
fprintf('  Wage: log_wage_phillips_estimation.txt\n');
fprintf('  Results: phase1_estimation_results.mat\n');
