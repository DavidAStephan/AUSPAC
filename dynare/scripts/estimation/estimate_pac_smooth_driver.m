%% estimate_pac_smooth_driver.m
% Master pipeline for PAC estimation using Kalman-smoothed auxiliary variables.
%
% Two-pass approach:
%   Pass 1: dynare au_pac json=compute
%           -> companion matrix, PAC h-vectors, policy functions
%   Pass 2: dynare au_pac_smooth
%           -> calib_smoother extracts model-consistent SmoothedVariables
%   Estimation: pac.estimate.iterative_ols + NLS using smoothed dseries
%
% This replaces estimate_pac_driver.m when you want model-consistent
% auxiliary variables instead of crude recursive approximations.
%
% USAGE:
%   >> cd(<repo>/dynare); estimate_pac_smooth_driver

clear; clc;

%% Setup
cd(fileparts(mfilename('fullpath')));
setup_dynare_path();

% Open log file
logfile = 'pac_smooth_estimation_log.txt';
fid_log = fopen(logfile, 'w');
log_msg = @(msg) fprintf_both(fid_log, msg);

log_msg('================================================================\n');
log_msg('  AU_PAC STRUCTURAL ESTIMATION — KALMAN SMOOTHER APPROACH\n');
log_msg('================================================================\n');
log_msg(sprintf('Timestamp: %s\n\n', datestr(now)));

%% =====================================================================
%  PASS 1: Preprocess model + build companion matrix
%  =====================================================================
log_msg('--- PASS 1: dynare au_pac json=compute ---\n');
log_msg('  Preprocessing model, running stoch_simul, building companion matrix...\n\n');

dynare au_pac json=compute noclearall

log_msg(sprintf('  M_.endo_nbr = %d, M_.exo_nbr = %d, M_.param_nbr = %d\n', ...
    M_.endo_nbr, M_.exo_nbr, M_.param_nbr));

% Build companion matrix
if ~isstruct(oo_.var)
    log_msg(sprintf('  Converting oo_.var from %s to struct\n', class(oo_.var)));
    oo_.var = struct();
end
get_companion_matrix('esat_enriched', 'var');
CM = oo_.var.esat_enriched.CompanionMatrix;
log_msg(sprintf('  Companion matrix: %dx%d, all finite: %d\n', ...
    size(CM,1), size(CM,2), all(isfinite(CM(:)))));

% Initialize all PAC models
pac_models = {'pac_pQ', 'pac_c', 'pac_ib', 'pac_ih', 'pac_n'};
for k = 1:length(pac_models)
    pm = pac_models{k};
    pac.initialize(pm);
    pac.update.expectation(pm);
    nh = length(M_.pac.(pm).h_param_indices);
    log_msg(sprintf('  %s: initialized, %d h-vector parameters\n', pm, nh));
end

% Save Pass 1 results (companion matrix + PAC setup)
save('pass1_results.mat', 'M_', 'oo_', 'options_');
log_msg('\n  Pass 1 results saved to pass1_results.mat\n');

% Save critical structures that Pass 2 will overwrite
saved_M_ = M_;
saved_oo_ = oo_;
saved_options_ = options_;

%% =====================================================================
%  PASS 2: Kalman smoother to extract model-consistent states
%  =====================================================================
log_msg('\n--- PASS 2: Kalman smoother ---\n');

% Step 2a: Prepare smoother data
log_msg('  Preparing observation data for calib_smoother...\n');
prepare_smoother_data();

% Step 2b: Generate au_pac_smooth.mod
log_msg('  Generating au_pac_smooth.mod...\n');
generate_smoother_mod();

% Delete .m data file to avoid ambiguity (Dynare will use .mat)
if exist('smoother_data.m', 'file'), delete('smoother_data.m'); end

% Step 2c: Run calib_smoother
log_msg('  Running dynare au_pac_smooth (calib_smoother)...\n\n');

try
    dynare au_pac_smooth noclearall

    % Extract SmoothedVariables
    if isfield(oo_, 'SmoothedVariables')
        sv_fields = fieldnames(oo_.SmoothedVariables);
        log_msg(sprintf('\n  SmoothedVariables: %d variables extracted\n', length(sv_fields)));

        % Save smoother results
        oo_smooth = oo_;
        save('smoother_results.mat', 'oo_smooth');
        log_msg('  Smoother results saved to smoother_results.mat\n');
    else
        error('calib_smoother did not produce SmoothedVariables');
    end

catch ME
    log_msg(sprintf('\n  WARNING: calib_smoother failed: %s\n', ME.message));
    log_msg('  Falling back to recursive auxiliary variable construction...\n');

    % Restore Pass 1 state
    M_ = saved_M_;
    oo_ = saved_oo_;
    options_ = saved_options_;

    % Fall back to original approach
    log_msg('  Using prepare_pac_dseries (recursive construction)\n');
    db = prepare_pac_dseries();
    oo_smooth = [];
end

%% =====================================================================
%  BUILD DSERIES FROM SMOOTHED VARIABLES
%  =====================================================================
log_msg('\n--- Building dseries ---\n');

if ~isempty(oo_smooth) && isfield(oo_smooth, 'SmoothedVariables')
    % Restore Pass 1 M_ and oo_ (companion matrix + PAC h-vectors)
    M_ = saved_M_;
    oo_ = saved_oo_;
    options_ = saved_options_;

    % Rebuild companion matrix (was overwritten by Pass 2)
    if ~isstruct(oo_.var)
        oo_.var = struct();
    end
    get_companion_matrix('esat_enriched', 'var');
    for k = 1:length(pac_models)
        pac.initialize(pac_models{k});
        pac.update.expectation(pac_models{k});
    end
    log_msg('  Companion matrix and PAC h-vectors restored from Pass 1\n');

    % Build HYBRID dseries: smoothed auxiliary targets + recursive pv_aux
    % (Pure smoother absorbs too much signal; hybrid is recommended)
    db = prepare_pac_dseries_hybrid(oo_smooth);
    log_msg('  dseries built using HYBRID approach (smoothed targets + recursive corrections)\n');
    estimation_method = 'HYBRID_SMOOTHED';
else
    estimation_method = 'RECURSIVE';
end

%% =====================================================================
%  PAC ESTIMATION — ITERATIVE OLS
%  =====================================================================
log_msg(sprintf('\n--- PAC ESTIMATION (iterative OLS, %s auxiliaries) ---\n\n', estimation_method));

% Estimation sample
start_est = dates('1994Q2');
end_est   = dates('2023Q3');
est_range = start_est:end_est;
log_msg(sprintf('Estimation range: %s to %s (%d quarters)\n', ...
    char(start_est), char(end_est), length(est_range)));

% Store results for comparison
results = struct();

% -----------------------------------------------------------------------
% VA Price PAC
% -----------------------------------------------------------------------
log_msg('\n--- VA Price PAC (eq_piQ_pac) ---\n');
params_pQ = struct('b0_pQ', 0.06, 'b1_pQ', 0.50, 'b2_pQ', 0.09, ...
                   'b_covid_crash_pQ', 0, 'b_covid_bounce_pQ', 0);
try
    pac.estimate.iterative_ols('eq_piQ_pac', params_pQ, db, est_range);
    results.pQ = log_and_store(fid_log, 'VA Price', params_pQ, M_, oo_, 'pac_pQ');
catch ME
    log_msg(sprintf('  FAILED: %s\n', ME.message));
end

% -----------------------------------------------------------------------
% Consumption PAC
% -----------------------------------------------------------------------
log_msg('\n--- Consumption PAC (eq_dln_c_pac) ---\n');
params_c = struct('b0_c', 0.06, 'b1_c', 0.149, 'b2_c', -0.02, 'b3_c', 0.139, ...
                  'b_di_c', 0, ...
                  'b_covid_crash_c', 0, 'b_covid_bounce_c', 0);
try
    pac.estimate.iterative_ols('eq_dln_c_pac', params_c, db, est_range);
    results.c = log_and_store(fid_log, 'Consumption', params_c, M_, oo_, 'pac_c');
catch ME
    log_msg(sprintf('  FAILED: %s\n', ME.message));
end

% -----------------------------------------------------------------------
% Business Investment PAC
% -----------------------------------------------------------------------
log_msg('\n--- Business Investment PAC (eq_dln_ib_pac) ---\n');
params_ib = struct('b0_ib', 0.030, 'b1_ib', 0.181, 'b2_ib', 0.10, 'b3_ib', 0.191, ...
                   'b_covid_crash_ib', 0, 'b_covid_bounce_ib', 0);
try
    pac.estimate.iterative_ols('eq_dln_ib_pac', params_ib, db, est_range);
    results.ib = log_and_store(fid_log, 'Business Investment', params_ib, M_, oo_, 'pac_ib');
catch ME
    log_msg(sprintf('  FAILED: %s\n', ME.message));
end

% -----------------------------------------------------------------------
% Household Investment PAC
% -----------------------------------------------------------------------
log_msg('\n--- Household Investment PAC (eq_dln_ih_pac) ---\n');
params_ih = struct('b0_ih', 0.049, 'b1_ih', 0.210, 'b2_ih', 0.08, ...
                   'b3_ih', 0.12, 'b_ph_ih', 0, ...
                   'b_covid_crash_ih', 0, 'b_covid_bounce_ih', 0);
try
    pac.estimate.iterative_ols('eq_dln_ih_pac', params_ih, db, est_range);
    results.ih = log_and_store(fid_log, 'Household Investment', params_ih, M_, oo_, 'pac_ih');
catch ME
    log_msg(sprintf('  FAILED: %s\n', ME.message));
end

% -----------------------------------------------------------------------
% Employment PAC
% -----------------------------------------------------------------------
log_msg('\n--- Employment PAC (eq_dln_n_pac) ---\n');
params_n = struct('b0_n', 0.040, 'b1_n', 0.30, 'b2_n', 0.10, ...
                  'b3_n', 0.05, 'b4_n', 0.02, 'b5_n', 0.12, ...
                  'b_covid_crash_n', 0, 'b_covid_bounce_n', 0);
try
    pac.estimate.iterative_ols('eq_dln_n_pac', params_n, db, est_range);
    results.n = log_and_store(fid_log, 'Employment', params_n, M_, oo_, 'pac_n');
catch ME
    log_msg(sprintf('  FAILED: %s\n', ME.message));
end

%% =====================================================================
%  NLS ESTIMATION (robustness check)
%  =====================================================================
log_msg('\n--- NLS ESTIMATION (csminwel) ---\n');

% Consumption NLS
log_msg('\n--- Consumption NLS ---\n');
params_c_nls = struct('b0_c', 0.06, 'b1_c', 0.149, 'b2_c', -0.02, 'b3_c', 0.139, ...
                      'b_di_c', 0, ...
                      'b_covid_crash_c', 0, 'b_covid_bounce_c', 0);
try
    pac.estimate.nls('eq_dln_c_pac', params_c_nls, db, est_range, 'csminwel', 'MaxIter', 500);
    results.c_nls = log_and_store(fid_log, 'Consumption NLS', params_c_nls, M_, oo_, 'pac_c');
catch ME
    log_msg(sprintf('  FAILED: %s\n', ME.message));
end

% Business Investment NLS
log_msg('\n--- Business Investment NLS ---\n');
params_ib_nls = struct('b0_ib', 0.030, 'b1_ib', 0.181, 'b2_ib', 0.10, 'b3_ib', 0.191, ...
                       'b_covid_crash_ib', 0, 'b_covid_bounce_ib', 0);
try
    pac.estimate.nls('eq_dln_ib_pac', params_ib_nls, db, est_range, 'csminwel', 'MaxIter', 500);
    results.ib_nls = log_and_store(fid_log, 'Business Investment NLS', params_ib_nls, M_, oo_, 'pac_ib');
catch ME
    log_msg(sprintf('  FAILED: %s\n', ME.message));
end

%% =====================================================================
%  SUMMARY AND COMPARISON
%  =====================================================================
log_msg('\n================================================================\n');
log_msg('  ESTIMATION SUMMARY\n');
log_msg('================================================================\n');
log_msg(sprintf('  Method: %s auxiliaries\n', estimation_method));

% Print all estimated parameter values
log_msg('\n  --- Estimated PAC parameter values ---\n');
pac_params = {'b0_pQ', 'b1_pQ', 'b2_pQ', 'b_covid_crash_pQ', 'b_covid_bounce_pQ', ...
              'b0_c', 'b1_c', 'b2_c', 'b3_c', 'b_di_c', 'b_covid_crash_c', 'b_covid_bounce_c', ...
              'b0_ib', 'b1_ib', 'b2_ib', 'b3_ib', 'b_covid_crash_ib', 'b_covid_bounce_ib', ...
              'b0_ih', 'b1_ih', 'b2_ih', 'b3_ih', 'b_ph_ih', 'b_covid_crash_ih', 'b_covid_bounce_ih', ...
              'b0_n', 'b1_n', 'b2_n', 'b3_n', 'b4_n', 'b5_n', 'b_covid_crash_n', 'b_covid_bounce_n'};

log_msg(sprintf('  %-16s %10s\n', 'Parameter', 'Estimated'));
for k = 1:length(pac_params)
    pname = pac_params{k};
    idx = find(strcmp(pname, M_.param_names));
    if ~isempty(idx)
        log_msg(sprintf('  %-16s %10.4f\n', pname, M_.params(idx)));
    end
end

% Save results
save('pac_smooth_estimation_results.mat', 'M_', 'oo_', 'results', 'estimation_method');
log_msg(sprintf('\n  Results saved to pac_smooth_estimation_results.mat\n'));
log_msg(sprintf('  Log saved to %s\n', logfile));

log_msg('\n================================================================\n');
log_msg('  ESTIMATION PIPELINE COMPLETE\n');
log_msg('================================================================\n');

fclose(fid_log);


%% =====================================================================
%  Helper functions
%  =====================================================================

function fprintf_both(fid, msg)
    fprintf(msg);
    if fid > 0
        fprintf(fid, msg);
    end
end

function res = log_and_store(fid, label, params_init, M_, oo_, pacname)
    res = struct();
    pnames = fieldnames(params_init);

    if isfield(oo_.pac, pacname) && isfield(oo_.pac.(pacname), 'estimator')
        est = oo_.pac.(pacname).estimator;
        ssr = oo_.pac.(pacname).ssr;
        T = length(oo_.pac.(pacname).residual);

        fprintf_both(fid, sprintf('  %s: SSR = %.4f, T = %d\n', label, ssr, T));
        fprintf_both(fid, sprintf('  %-15s %10s %10s %10s\n', 'Parameter', 'Initial', 'Estimated', 'Change'));

        res.ssr = ssr;
        res.T = T;

        for j = 1:length(pnames)
            init_val = params_init.(pnames{j});
            idx = find(strcmp(pnames{j}, M_.param_names));
            if ~isempty(idx)
                est_val = M_.params(idx);
            elseif j <= length(est)
                est_val = est(j);
            else
                est_val = NaN;
            end
            chg = est_val - init_val;
            fprintf_both(fid, sprintf('  %-15s %10.4f %10.4f %+10.4f\n', pnames{j}, init_val, est_val, chg));
            res.(pnames{j}) = est_val;
        end
    else
        fprintf_both(fid, sprintf('  %s: no results in oo_.pac.%s\n', label, pacname));
    end
end
