%% reestimate_pac_clean.m — Re-estimate PAC without b_di_c/b_ph_ih
% These parameters had wrong signs from OLS (reverse causality).
% This script re-estimates all 5 PAC equations with the updated companion
% matrix (Phase 1-3 auxiliary dynamics) but WITHOUT b_di_c and b_ph_ih.
%
% Uses the smoother results from the prior estimate_pac_smooth_driver run.

clear; clc;
addpath('C:\dynare\6.5\matlab');
cd('c:\Users\david\french_model\dynare');

fid_log = fopen('pac_clean_estimation_log.txt', 'w');
log_msg = @(msg) fprintf_both(fid_log, msg);

log_msg('================================================================\n');
log_msg('  PAC RE-ESTIMATION — CLEAN (no b_di_c, no b_ph_ih)\n');
log_msg(sprintf('  Timestamp: %s\n', datestr(now)));
log_msg('================================================================\n\n');

%% Pass 1: Preprocess model
log_msg('--- PASS 1: dynare au_pac json=compute ---\n');
dynare au_pac json=compute noclearall

if ~isstruct(oo_.var)
    oo_.var = struct();
end
get_companion_matrix('esat_enriched', 'var');
CM = oo_.var.esat_enriched.CompanionMatrix;
log_msg(sprintf('  Companion matrix: %dx%d\n', size(CM,1), size(CM,2)));

pac_models = {'pac_pQ', 'pac_c', 'pac_ib', 'pac_ih', 'pac_n'};
for k = 1:length(pac_models)
    pac.initialize(pac_models{k});
    pac.update.expectation(pac_models{k});
end

saved_M_ = M_; saved_oo_ = oo_; saved_options_ = options_;

%% Pass 2: Kalman smoother
log_msg('\n--- PASS 2: Kalman smoother ---\n');
prepare_smoother_data();
generate_smoother_mod();
if exist('smoother_data.m', 'file'), delete('smoother_data.m'); end

try
    dynare au_pac_smooth noclearall
    oo_smooth = oo_;
    log_msg(sprintf('  SmoothedVariables: %d\n', length(fieldnames(oo_.SmoothedVariables))));
catch ME
    log_msg(sprintf('  Smoother failed: %s\n', ME.message));
    oo_smooth = [];
end

%% Restore Pass 1 and build dseries
M_ = saved_M_; oo_ = saved_oo_; options_ = saved_options_;
if ~isstruct(oo_.var), oo_.var = struct(); end
get_companion_matrix('esat_enriched', 'var');
for k = 1:length(pac_models)
    pac.initialize(pac_models{k});
    pac.update.expectation(pac_models{k});
end

if ~isempty(oo_smooth) && isfield(oo_smooth, 'SmoothedVariables')
    db = prepare_pac_dseries_hybrid(oo_smooth);
    log_msg('  Using HYBRID dseries\n');
else
    db = prepare_pac_dseries();
    log_msg('  Using RECURSIVE dseries (fallback)\n');
end

%% Estimation — NO b_di_c, NO b_ph_ih
start_est = dates('1994Q2');
end_est   = dates('2023Q3');
est_range = start_est:end_est;
log_msg(sprintf('\nEstimation range: %s to %s (%d quarters)\n', ...
    char(start_est), char(end_est), length(est_range)));

% VA Price
log_msg('\n--- VA Price ---\n');
params_pQ = struct('b0_pQ', 0.06, 'b1_pQ', 0.50, 'b2_pQ', 0.09, ...
                   'b_covid_crash_pQ', 0, 'b_covid_bounce_pQ', 0);
try
    pac.estimate.iterative_ols('eq_piQ_pac', params_pQ, db, est_range);
    log_pac(fid_log, 'VA Price', params_pQ, M_, oo_, 'pac_pQ');
catch ME, log_msg(sprintf('  FAILED: %s\n', ME.message)); end

% Consumption — WITHOUT b_di_c
log_msg('\n--- Consumption (no b_di_c) ---\n');
params_c = struct('b0_c', 0.06, 'b1_c', 0.149, 'b2_c', -0.02, 'b3_c', 0.139, ...
                  'b_covid_crash_c', 0, 'b_covid_bounce_c', 0);
try
    pac.estimate.iterative_ols('eq_dln_c_pac', params_c, db, est_range);
    log_pac(fid_log, 'Consumption', params_c, M_, oo_, 'pac_c');
catch ME, log_msg(sprintf('  FAILED: %s\n', ME.message)); end

% Business Investment
log_msg('\n--- Business Investment ---\n');
params_ib = struct('b0_ib', 0.030, 'b1_ib', 0.181, 'b2_ib', 0.10, 'b3_ib', 0.191, ...
                   'b_covid_crash_ib', 0, 'b_covid_bounce_ib', 0);
try
    pac.estimate.iterative_ols('eq_dln_ib_pac', params_ib, db, est_range);
    log_pac(fid_log, 'Business Investment', params_ib, M_, oo_, 'pac_ib');
catch ME, log_msg(sprintf('  FAILED: %s\n', ME.message)); end

% Household Investment — WITHOUT b_ph_ih
log_msg('\n--- Household Investment (no b_ph_ih) ---\n');
params_ih = struct('b0_ih', 0.049, 'b1_ih', 0.210, 'b2_ih', 0.08, ...
                   'b3_ih', 0.12, ...
                   'b_covid_crash_ih', 0, 'b_covid_bounce_ih', 0);
try
    pac.estimate.iterative_ols('eq_dln_ih_pac', params_ih, db, est_range);
    log_pac(fid_log, 'Household Investment', params_ih, M_, oo_, 'pac_ih');
catch ME, log_msg(sprintf('  FAILED: %s\n', ME.message)); end

% Employment
log_msg('\n--- Employment ---\n');
params_n = struct('b0_n', 0.040, 'b1_n', 0.30, 'b2_n', 0.10, ...
                  'b3_n', 0.05, 'b4_n', 0.02, 'b5_n', 0.12, ...
                  'b_covid_crash_n', 0, 'b_covid_bounce_n', 0);
try
    pac.estimate.iterative_ols('eq_dln_n_pac', params_n, db, est_range);
    log_pac(fid_log, 'Employment', params_n, M_, oo_, 'pac_n');
catch ME, log_msg(sprintf('  FAILED: %s\n', ME.message)); end

%% Summary
log_msg('\n================================================================\n');
log_msg('  SUMMARY — CLEAN PAC ESTIMATES\n');
log_msg('================================================================\n');
pac_params = {'b0_pQ', 'b1_pQ', 'b2_pQ', ...
              'b0_c', 'b1_c', 'b2_c', 'b3_c', ...
              'b0_ib', 'b1_ib', 'b2_ib', 'b3_ib', ...
              'b0_ih', 'b1_ih', 'b2_ih', 'b3_ih', ...
              'b0_n', 'b1_n', 'b2_n', 'b3_n', 'b4_n', 'b5_n'};
log_msg(sprintf('  %-12s %10s\n', 'Parameter', 'Estimated'));
for k = 1:length(pac_params)
    pname = pac_params{k};
    idx = find(strcmp(pname, M_.param_names));
    if ~isempty(idx)
        log_msg(sprintf('  %-12s %10.4f\n', pname, M_.params(idx)));
    end
end

save('pac_clean_estimation_results.mat', 'M_', 'oo_');
log_msg(sprintf('\n  Saved to pac_clean_estimation_results.mat\n'));
log_msg('================================================================\n');
fclose(fid_log);

%% Helpers
function fprintf_both(fid, msg)
    fprintf(msg);
    if fid > 0, fprintf(fid, msg); end
end

function log_pac(fid, label, params_init, M_, oo_, pacname)
    pnames = fieldnames(params_init);
    if isfield(oo_.pac, pacname) && isfield(oo_.pac.(pacname), 'estimator')
        ssr = oo_.pac.(pacname).ssr;
        T = length(oo_.pac.(pacname).residual);
        fprintf_both(fid, sprintf('  %s: SSR = %.4f, T = %d\n', label, ssr, T));
        fprintf_both(fid, sprintf('  %-15s %10s %10s\n', 'Parameter', 'Initial', 'Estimated'));
        for j = 1:length(pnames)
            init_val = params_init.(pnames{j});
            idx = find(strcmp(pnames{j}, M_.param_names));
            if ~isempty(idx)
                est_val = M_.params(idx);
            else
                est_val = NaN;
            end
            fprintf_both(fid, sprintf('  %-15s %10.4f %10.4f\n', pnames{j}, init_val, est_val));
        end
    else
        fprintf_both(fid, sprintf('  %s: no results\n', label));
    end
end
