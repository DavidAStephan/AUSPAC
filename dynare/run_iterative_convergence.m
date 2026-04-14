%% run_iterative_convergence.m — Phase 4: Iterative PAC convergence loop
%
% Implements the smoother → aux → PAC → re-smooth convergence cycle:
%   1. Run stoch_simul with current parameters → companion matrix + h-vectors
%   2. Run calib_smoother → extract Kalman-smoothed auxiliary variables
%   3. Build hybrid dseries → estimate PAC equations (iterative OLS)
%   4. Update .mod file parameters with new PAC estimates
%   5. Repeat until SSR convergence (or max iterations)
%
% Convergence criterion: max parameter change < tol across all 5 equations.
%
% OUTPUT:
%   - pac_convergence_log.txt (detailed log)
%   - pac_convergence_results.mat (iteration history)
%
% REQUIRES: estimate_pac_smooth_driver infrastructure (already working)

clear; clc;
addpath('C:\dynare\6.5\matlab');
cd('c:\Users\david\french_model\dynare');

%% Configuration
MAX_ITER = 5;
TOL_SSR = 0.1;     % converge when SSR changes < 0.1 per equation
TOL_PARAM = 0.005;  % converge when max parameter change < 0.005

logfile = 'pac_convergence_log.txt';
fid = fopen(logfile, 'w');
log_msg = @(msg) fprintf_both(fid, msg);

log_msg('================================================================\n');
log_msg('  ITERATIVE PAC CONVERGENCE — Phase 4\n');
log_msg(sprintf('  %s\n', datestr(now)));
log_msg(sprintf('  Max iterations: %d, SSR tol: %.2f, Param tol: %.4f\n', ...
    MAX_ITER, TOL_SSR, TOL_PARAM));
log_msg('================================================================\n\n');

%% Track parameters across iterations
param_names = {'b0_pQ', 'b1_pQ', 'b2_pQ', ...
               'b0_c', 'b1_c', 'b2_c', 'b3_c', ...
               'b0_ib', 'b1_ib', 'b2_ib', 'b3_ib', ...
               'b0_ih', 'b1_ih', 'b2_ih', 'b3_ih', ...
               'b0_n', 'b1_n', 'b2_n', 'b3_n', 'b4_n', 'b5_n'};
eq_names = {'VA Price', 'Consumption', 'Business Inv', 'Household Inv', 'Employment'};
pac_models_list = {'pac_pQ', 'pac_c', 'pac_ib', 'pac_ih', 'pac_n'};

history = struct();
history.ssr = zeros(MAX_ITER, 5);
history.params = zeros(MAX_ITER, length(param_names));

converged = false;

for iter = 1:MAX_ITER
    log_msg(sprintf('\n########################################\n'));
    log_msg(sprintf('  ITERATION %d / %d\n', iter, MAX_ITER));
    log_msg(sprintf('########################################\n\n'));

    %% Step 1: Preprocess model + companion matrix
    log_msg('--- Step 1: dynare au_pac json=compute ---\n');
    dynare au_pac json=compute noclearall

    if ~isstruct(oo_.var), oo_.var = struct(); end
    get_companion_matrix('esat_enriched', 'var');
    CM = oo_.var.esat_enriched.CompanionMatrix;
    log_msg(sprintf('  Companion: %dx%d, spectral radius = %.4f\n', ...
        size(CM,1), size(CM,2), max(abs(eig(CM)))));

    for k = 1:length(pac_models_list)
        pac.initialize(pac_models_list{k});
        pac.update.expectation(pac_models_list{k});
    end

    saved_M_ = M_; saved_oo_ = oo_; saved_options_ = options_;

    %% Step 2: Kalman smoother
    log_msg('--- Step 2: Kalman smoother ---\n');
    prepare_smoother_data();
    generate_smoother_mod();
    if exist('smoother_data.m', 'file'), delete('smoother_data.m'); end

    oo_smooth = [];
    try
        dynare au_pac_smooth noclearall
        oo_smooth = oo_;
        log_msg(sprintf('  SmoothedVariables: %d\n', length(fieldnames(oo_.SmoothedVariables))));
    catch ME
        log_msg(sprintf('  Smoother FAILED: %s — using recursive\n', ME.message));
    end

    %% Step 3: Build dseries + estimate PAC
    M_ = saved_M_; oo_ = saved_oo_; options_ = saved_options_;
    if ~isstruct(oo_.var), oo_.var = struct(); end
    get_companion_matrix('esat_enriched', 'var');
    for k = 1:length(pac_models_list)
        pac.initialize(pac_models_list{k});
        pac.update.expectation(pac_models_list{k});
    end

    if ~isempty(oo_smooth) && isfield(oo_smooth, 'SmoothedVariables')
        db = prepare_pac_dseries_hybrid(oo_smooth);
    else
        db = prepare_pac_dseries();
    end

    start_est = dates('1994Q2');
    end_est = dates('2023Q3');
    est_range = start_est:end_est;

    log_msg('--- Step 3: PAC estimation ---\n');

    % VA Price
    params_pQ = struct('b0_pQ', 0.06, 'b1_pQ', 0.50, 'b2_pQ', 0.09, ...
                       'b_covid_crash_pQ', 0, 'b_covid_bounce_pQ', 0);
    try
        pac.estimate.iterative_ols('eq_piQ_pac', params_pQ, db, est_range);
        history.ssr(iter, 1) = oo_.pac.pac_pQ.ssr;
    catch ME
        log_msg(sprintf('  pQ FAILED: %s\n', ME.message));
        history.ssr(iter, 1) = NaN;
    end

    % Consumption
    params_c = struct('b0_c', 0.06, 'b1_c', 0.149, 'b2_c', -0.02, 'b3_c', 0.139, ...
                      'b_covid_crash_c', 0, 'b_covid_bounce_c', 0);
    try
        pac.estimate.iterative_ols('eq_dln_c_pac', params_c, db, est_range);
        history.ssr(iter, 2) = oo_.pac.pac_c.ssr;
    catch ME
        log_msg(sprintf('  c FAILED: %s\n', ME.message));
        history.ssr(iter, 2) = NaN;
    end

    % Business Investment
    params_ib = struct('b0_ib', 0.030, 'b1_ib', 0.181, 'b2_ib', 0.10, 'b3_ib', 0.191, ...
                       'b_covid_crash_ib', 0, 'b_covid_bounce_ib', 0);
    try
        pac.estimate.iterative_ols('eq_dln_ib_pac', params_ib, db, est_range);
        history.ssr(iter, 3) = oo_.pac.pac_ib.ssr;
    catch ME
        log_msg(sprintf('  ib FAILED: %s\n', ME.message));
        history.ssr(iter, 3) = NaN;
    end

    % Household Investment
    params_ih = struct('b0_ih', 0.049, 'b1_ih', 0.210, 'b2_ih', 0.08, 'b3_ih', 0.12, ...
                       'b_covid_crash_ih', 0, 'b_covid_bounce_ih', 0);
    try
        pac.estimate.iterative_ols('eq_dln_ih_pac', params_ih, db, est_range);
        history.ssr(iter, 4) = oo_.pac.pac_ih.ssr;
    catch ME
        log_msg(sprintf('  ih FAILED: %s\n', ME.message));
        history.ssr(iter, 4) = NaN;
    end

    % Employment
    params_n = struct('b0_n', 0.040, 'b1_n', 0.30, 'b2_n', 0.10, ...
                      'b3_n', 0.05, 'b4_n', 0.02, 'b5_n', 0.12, ...
                      'b_covid_crash_n', 0, 'b_covid_bounce_n', 0);
    try
        pac.estimate.iterative_ols('eq_dln_n_pac', params_n, db, est_range);
        history.ssr(iter, 5) = oo_.pac.pac_n.ssr;
    catch ME
        log_msg(sprintf('  n FAILED: %s\n', ME.message));
        history.ssr(iter, 5) = NaN;
    end

    % Extract current parameter values
    for p = 1:length(param_names)
        idx = find(strcmp(param_names{p}, M_.param_names));
        if ~isempty(idx)
            history.params(iter, p) = M_.params(idx);
        end
    end

    % Log iteration results
    log_msg(sprintf('\n  Iteration %d SSR: ', iter));
    for e = 1:5
        log_msg(sprintf('%s=%.1f  ', eq_names{e}, history.ssr(iter, e)));
    end
    log_msg('\n');

    %% Step 4: Check convergence
    if iter > 1
        dSSR = abs(history.ssr(iter, :) - history.ssr(iter-1, :));
        dParam = abs(history.params(iter, :) - history.params(iter-1, :));
        max_dSSR = max(dSSR);
        max_dParam = max(dParam);
        log_msg(sprintf('  Max SSR change: %.4f (tol=%.1f)\n', max_dSSR, TOL_SSR));
        log_msg(sprintf('  Max param change: %.6f (tol=%.4f)\n', max_dParam, TOL_PARAM));

        if max_dSSR < TOL_SSR && max_dParam < TOL_PARAM
            log_msg(sprintf('\n  *** CONVERGED at iteration %d ***\n', iter));
            converged = true;
            break;
        end
    end

    %% Step 5: Update M_.params for next iteration
    % The pac.estimate.iterative_ols already updated M_.params in-place.
    % When dynare au_pac runs next iteration, it will re-read from the .mod file.
    % So we need to update the .mod file with the new estimates.
    log_msg('\n--- Step 5: Updating au_pac.mod with estimated values ---\n');
    update_mod_params(M_, param_names, logfile);
end

%% Final summary
log_msg('\n================================================================\n');
log_msg('  CONVERGENCE SUMMARY\n');
log_msg('================================================================\n');
log_msg(sprintf('  Converged: %s (after %d iterations)\n', ...
    string(converged), min(iter, MAX_ITER)));

log_msg(sprintf('\n  %-12s', 'Equation'));
for e = 1:5, log_msg(sprintf(' %12s', eq_names{e})); end
log_msg('\n');
for i = 1:min(iter, MAX_ITER)
    log_msg(sprintf('  Iter %-6d', i));
    for e = 1:5, log_msg(sprintf(' %12.1f', history.ssr(i, e))); end
    log_msg('\n');
end

log_msg(sprintf('\n  Final parameters:\n'));
log_msg(sprintf('  %-12s %10s\n', 'Parameter', 'Value'));
for p = 1:length(param_names)
    log_msg(sprintf('  %-12s %10.4f\n', param_names{p}, history.params(min(iter,MAX_ITER), p)));
end

save('pac_convergence_results.mat', 'history', 'param_names', 'eq_names', 'converged');
log_msg(sprintf('\n  Saved to pac_convergence_results.mat\n'));
log_msg('================================================================\n');
fclose(fid);


%% =====================================================================
%  Helper: update au_pac.mod parameter values in-place
%  =====================================================================
function update_mod_params(M_, param_names, logfile)
    fid_log = fopen(logfile, 'a');

    modfile = fullfile(fileparts(mfilename('fullpath')), 'au_pac.mod');
    txt = fileread(modfile);

    for p = 1:length(param_names)
        pname = param_names{p};
        idx = find(strcmp(pname, M_.param_names));
        if isempty(idx), continue; end
        new_val = M_.params(idx);

        % Match pattern: pname followed by spaces, '=', spaces, number
        % e.g., "b0_pQ           = 0.028;"
        pattern = [pname '\s*=\s*[-]?[\d]+\.[\d]+'];
        replacement = sprintf('%s = %.4f', pname, new_val);

        % Only replace first occurrence (parameter declaration, not equation)
        old_txt = txt;
        txt = regexprep(txt, pattern, replacement, 'once');
        if ~strcmp(old_txt, txt)
            fprintf(fid_log, '  Updated %s = %.4f\n', pname, new_val);
        end
    end

    fid_mod = fopen(modfile, 'w');
    fprintf(fid_mod, '%s', txt);
    fclose(fid_mod);

    fclose(fid_log);
end


function fprintf_both(fid, msg)
    fprintf(msg);
    if fid > 0, fprintf(fid, msg); end
end
