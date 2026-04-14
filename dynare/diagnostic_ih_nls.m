%% diagnostic_ih_nls.m
% Diagnostic script for two issues:
%   1. Household investment b4_ih sign (with/without rate channel)
%   2. NLS estimation using fminsearch (workaround for csminwel bug)
%
% Loads Pass 1 + smoother results from the main pipeline,
% then re-estimates targeted equations.
%
% REQUIRES: estimate_pac_smooth_driver must have been run first
%   (produces pass1_results.mat + smoother_results.mat)

clear; clc;
addpath('C:\dynare\6.5\matlab');
cd('c:\Users\david\french_model\dynare');

logfile = 'diagnostic_ih_nls_log.txt';
fid = fopen(logfile, 'w');
log_msg = @(msg) fprintf_both(fid, msg);

log_msg('================================================================\n');
log_msg('  DIAGNOSTIC: HOUSEHOLD INVESTMENT RATE CHANNEL + NLS FIX\n');
log_msg(sprintf('  %s\n', datestr(now)));
log_msg('================================================================\n\n');

%% 1. Re-run Pass 1 (needed for pac.update.expectation — can't just reload mat)
log_msg('--- Pass 1: dynare au_pac json=compute ---\n');

dynare au_pac json=compute noclearall

log_msg(sprintf('  M_.endo_nbr = %d, M_.exo_nbr = %d\n', M_.endo_nbr, M_.exo_nbr));

% Build companion matrix
if ~isstruct(oo_.var), oo_.var = struct(); end
get_companion_matrix('esat_enriched', 'var');

pac_models = {'pac_pQ', 'pac_c', 'pac_ib', 'pac_ih', 'pac_n'};
for k = 1:length(pac_models)
    pac.initialize(pac_models{k});
    pac.update.expectation(pac_models{k});
end
log_msg('  Companion matrix and PAC h-vectors built\n');

% Load smoother results from main pipeline (avoid re-running calib_smoother)
if exist('smoother_results.mat', 'file')
    load('smoother_results.mat', 'oo_smooth');
    log_msg('  Smoother results loaded from smoother_results.mat\n');
else
    error('smoother_results.mat not found — run estimate_pac_smooth_driver first');
end

% Build hybrid dseries
db = prepare_pac_dseries_hybrid(oo_smooth);
log_msg('  Hybrid dseries built\n\n');

start_est = dates('1994Q2');
end_est   = dates('2023Q3');
est_range = start_est:end_est;

%% =====================================================================
%  DIAGNOSTIC 1: HOUSEHOLD INVESTMENT — WITH vs WITHOUT b4_ih
%  =====================================================================
log_msg('================================================================\n');
log_msg('  DIAGNOSTIC 1: HOUSEHOLD INVESTMENT RATE CHANNEL\n');
log_msg('================================================================\n\n');

log_msg('The rate channel enters household investment through 3 paths:\n');
log_msg('  1. Target equation: kappa_mort*(i_lh - SS) -> pac_expectation\n');
log_msg('  2. Auxiliary equation: a_ih_i*i_gap(-1) = -0.15*i_gap(-1) -> pv_ih_aux\n');
log_msg('  3. Ad hoc PAC term: b4_ih*i_gap(-1)  <-- this one is redundant\n\n');

% Test A: WITH b4_ih (baseline — same as main pipeline)
log_msg('--- Test A: WITH b4_ih (baseline) ---\n');
params_ih_A = struct('b0_ih', 0.049, 'b1_ih', 0.210, 'b2_ih', 0.08, ...
                     'b3_ih', 0.12, 'b4_ih', -0.05, ...
                     'b_covid_crash_ih', 0, 'b_covid_bounce_ih', 0);
try
    pac.estimate.iterative_ols('eq_dln_ih_pac', params_ih_A, db, est_range);
    res_A = extract_results(M_, oo_, 'pac_ih', params_ih_A);
    log_msg(sprintf('  SSR = %.4f, T = %d\n', res_A.ssr, res_A.T));
    pnames = fieldnames(params_ih_A);
    for j = 1:length(pnames)
        log_msg(sprintf('  %-20s = %+.4f\n', pnames{j}, res_A.(pnames{j})));
    end
catch ME
    log_msg(sprintf('  FAILED: %s\n', ME.message));
end

% Test B: WITHOUT b4_ih (remove from estimation — fixed at 0)
log_msg('\n--- Test B: WITHOUT b4_ih (fixed at 0) ---\n');

% Set b4_ih = 0 in M_.params before estimation
idx_b4_ih = find(strcmp('b4_ih', M_.param_names));
M_.params(idx_b4_ih) = 0;

params_ih_B = struct('b0_ih', 0.049, 'b1_ih', 0.210, 'b2_ih', 0.08, ...
                     'b3_ih', 0.12, ...
                     'b_covid_crash_ih', 0, 'b_covid_bounce_ih', 0);
try
    pac.estimate.iterative_ols('eq_dln_ih_pac', params_ih_B, db, est_range);
    res_B = extract_results(M_, oo_, 'pac_ih', params_ih_B);
    log_msg(sprintf('  SSR = %.4f, T = %d\n', res_B.ssr, res_B.T));
    pnames = fieldnames(params_ih_B);
    for j = 1:length(pnames)
        log_msg(sprintf('  %-20s = %+.4f\n', pnames{j}, res_B.(pnames{j})));
    end
catch ME
    log_msg(sprintf('  FAILED: %s\n', ME.message));
end

% Restore b4_ih calibrated value
M_.params(idx_b4_ih) = -0.05;

% Comparison
log_msg('\n--- Comparison: WITH vs WITHOUT b4_ih ---\n');
if exist('res_A', 'var') && exist('res_B', 'var')
    log_msg(sprintf('  SSR with b4_ih:    %.4f (b4_ih = %+.4f)\n', res_A.ssr, res_A.b4_ih));
    log_msg(sprintf('  SSR without b4_ih: %.4f\n', res_B.ssr));
    delta_ssr = res_A.ssr - res_B.ssr;
    log_msg(sprintf('  Delta SSR: %.4f (%s)\n', abs(delta_ssr), ...
        ternary(delta_ssr > 0, 'WITHOUT is better', 'WITH is better')));

    % F-test for nested model (1 restriction)
    k_A = length(fieldnames(params_ih_A));
    k_B = length(fieldnames(params_ih_B));
    T = res_A.T;
    F_stat = ((res_B.ssr - res_A.ssr) / (k_A - k_B)) / (res_A.ssr / (T - k_A));
    log_msg(sprintf('  F-statistic: %.3f (df1=%d, df2=%d)\n', F_stat, k_A - k_B, T - k_A));
    log_msg(sprintf('  Critical F(1,%d) at 5%%: ~3.92\n', T - k_A));
    if F_stat < 3.92
        log_msg('  => b4_ih is NOT statistically significant — RECOMMEND DROPPING\n');
    else
        log_msg('  => b4_ih IS statistically significant\n');
    end
end

%% =====================================================================
%  DIAGNOSTIC 2: NLS WITH fminsearch (workaround for csminwel bug)
%  =====================================================================
log_msg('\n================================================================\n');
log_msg('  DIAGNOSTIC 2: NLS ESTIMATION (fminsearch workaround)\n');
log_msg('================================================================\n\n');

log_msg('csminwel fails with "Too many output arguments" (Dynare 6.5 bug).\n');
log_msg('Testing fminsearch as alternative optimizer.\n\n');

% Consumption NLS with fminsearch
log_msg('--- Consumption NLS (fminsearch) ---\n');
params_c_nls = struct('b0_c', 0.06, 'b1_c', 0.149, 'b2_c', -0.02, 'b3_c', 0.139, ...
                      'b_covid_crash_c', 0, 'b_covid_bounce_c', 0);
try
    pac.estimate.nls('eq_dln_c_pac', params_c_nls, db, est_range, 'fminsearch', 'MaxIter', 500);
    res_c_nls = extract_results(M_, oo_, 'pac_c', params_c_nls);
    log_msg(sprintf('  SSR = %.4f, T = %d\n', res_c_nls.ssr, res_c_nls.T));
    pnames = fieldnames(params_c_nls);
    for j = 1:length(pnames)
        log_msg(sprintf('  %-20s = %+.4f\n', pnames{j}, res_c_nls.(pnames{j})));
    end
catch ME
    log_msg(sprintf('  FAILED: %s\n', ME.message));
    log_msg('  Trying simplex optimizer...\n');
    try
        pac.estimate.nls('eq_dln_c_pac', params_c_nls, db, est_range, 'simplex', 'MaxIter', 500);
        res_c_nls = extract_results(M_, oo_, 'pac_c', params_c_nls);
        log_msg(sprintf('  SSR = %.4f (simplex), T = %d\n', res_c_nls.ssr, res_c_nls.T));
    catch ME2
        log_msg(sprintf('  simplex also failed: %s\n', ME2.message));
    end
end

% Business Investment NLS with fminsearch
log_msg('\n--- Business Investment NLS (fminsearch) ---\n');
params_ib_nls = struct('b0_ib', 0.030, 'b1_ib', 0.181, 'b2_ib', 0.10, 'b3_ib', 0.191, ...
                       'b_covid_crash_ib', 0, 'b_covid_bounce_ib', 0);
try
    pac.estimate.nls('eq_dln_ib_pac', params_ib_nls, db, est_range, 'fminsearch', 'MaxIter', 500);
    res_ib_nls = extract_results(M_, oo_, 'pac_ib', params_ib_nls);
    log_msg(sprintf('  SSR = %.4f, T = %d\n', res_ib_nls.ssr, res_ib_nls.T));
    pnames = fieldnames(params_ib_nls);
    for j = 1:length(pnames)
        log_msg(sprintf('  %-20s = %+.4f\n', pnames{j}, res_ib_nls.(pnames{j})));
    end
catch ME
    log_msg(sprintf('  FAILED: %s\n', ME.message));
end

% Household Investment NLS (without b4_ih)
log_msg('\n--- Household Investment NLS (fminsearch, WITHOUT b4_ih) ---\n');
M_.params(idx_b4_ih) = 0;
params_ih_nls = struct('b0_ih', 0.049, 'b1_ih', 0.210, 'b2_ih', 0.08, ...
                       'b3_ih', 0.12, ...
                       'b_covid_crash_ih', 0, 'b_covid_bounce_ih', 0);
try
    pac.estimate.nls('eq_dln_ih_pac', params_ih_nls, db, est_range, 'fminsearch', 'MaxIter', 500);
    res_ih_nls = extract_results(M_, oo_, 'pac_ih', params_ih_nls);
    log_msg(sprintf('  SSR = %.4f, T = %d\n', res_ih_nls.ssr, res_ih_nls.T));
    pnames = fieldnames(params_ih_nls);
    for j = 1:length(pnames)
        log_msg(sprintf('  %-20s = %+.4f\n', pnames{j}, res_ih_nls.(pnames{j})));
    end
catch ME
    log_msg(sprintf('  FAILED: %s\n', ME.message));
end

% Employment NLS
log_msg('\n--- Employment NLS (fminsearch) ---\n');
params_n_nls = struct('b0_n', 0.040, 'b1_n', 0.30, 'b2_n', 0.10, ...
                      'b3_n', 0.05, 'b4_n', 0.02, 'b5_n', 0.12, ...
                      'b_covid_crash_n', 0, 'b_covid_bounce_n', 0);
try
    pac.estimate.nls('eq_dln_n_pac', params_n_nls, db, est_range, 'fminsearch', 'MaxIter', 500);
    res_n_nls = extract_results(M_, oo_, 'pac_n', params_n_nls);
    log_msg(sprintf('  SSR = %.4f, T = %d\n', res_n_nls.ssr, res_n_nls.T));
    pnames = fieldnames(params_n_nls);
    for j = 1:length(pnames)
        log_msg(sprintf('  %-20s = %+.4f\n', pnames{j}, res_n_nls.(pnames{j})));
    end
catch ME
    log_msg(sprintf('  FAILED: %s\n', ME.message));
end

%% Summary
log_msg('\n================================================================\n');
log_msg('  DIAGNOSTIC COMPLETE\n');
log_msg('================================================================\n');
fclose(fid);

fprintf('Results saved to %s\n', logfile);

%% =====================================================================
%  Helper functions
%  =====================================================================

function fprintf_both(fid, msg)
    fprintf(msg);
    if fid > 0
        fprintf(fid, msg);
    end
end

function res = extract_results(M_, oo_, pacname, params_init)
    res = struct();
    pnames = fieldnames(params_init);
    if isfield(oo_.pac, pacname) && isfield(oo_.pac.(pacname), 'estimator')
        res.ssr = oo_.pac.(pacname).ssr;
        res.T = length(oo_.pac.(pacname).residual);
        for j = 1:length(pnames)
            idx = find(strcmp(pnames{j}, M_.param_names));
            if ~isempty(idx)
                res.(pnames{j}) = M_.params(idx);
            else
                res.(pnames{j}) = NaN;
            end
        end
    else
        res.ssr = NaN;
        res.T = 0;
    end
end

function s = ternary(cond, a, b)
    if cond, s = a; else, s = b; end
end
