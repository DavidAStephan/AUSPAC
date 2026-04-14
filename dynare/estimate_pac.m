%% estimate_pac.m
% PAC structural parameter estimation using Dynare's pac.estimate routines.
%
% Implements the ECB-Base (SemiStructDynareBasics) estimation approach:
%   Stage 1: Iterative OLS for each PAC equation (identifies b0, b1, omega)
%   Stage 2: NLS with simulated annealing as robustness check
%
% This script must be run AFTER `dynare au_pac json=compute` has been
% executed (so that M_, oo_ structures exist with JSON model info).
%
% USAGE:
%   >> cd('c:\Users\david\french_model\dynare')
%   >> addpath('C:\dynare\6.5\matlab');
%   >> dynare au_pac json=compute noclearall
%   >> estimate_pac
%
% Or equivalently, run estimate_pac_driver.m which handles the full pipeline.

global M_ oo_ options_

fprintf('\n');
fprintf('================================================================\n');
fprintf('  PAC STRUCTURAL PARAMETER ESTIMATION\n');
fprintf('  Using Dynare pac.estimate (iterative OLS + NLS)\n');
fprintf('================================================================\n');
fprintf('Timestamp: %s\n\n', datestr(now));

%% 0. Ensure companion matrix exists
% After stoch_simul, oo_.var is the variance-covariance matrix (double).
% pac.estimate needs oo_.var to be a struct with CompanionMatrix.
if ~isstruct(oo_.var)
    fprintf('--- Building companion matrix (oo_.var was %s) ---\n', class(oo_.var));
    oo_.var = struct();
    get_companion_matrix('esat_enriched', 'var');
    pac_names = {'pac_pQ', 'pac_c', 'pac_ib', 'pac_ih', 'pac_n'};
    for k = 1:length(pac_names)
        pac.initialize(pac_names{k});
        pac.update.expectation(pac_names{k});
    end
    fprintf('  Companion matrix: %dx%d\n\n', size(oo_.var.esat_enriched.CompanionMatrix));
end

%% 1. Construct dseries from observed data
fprintf('--- Step 1: Constructing dseries from observed data ---\n');
db = prepare_pac_dseries();

%% 2. Set estimation sample range
% Data starts 1993Q1, need 4 lags, valid from ~1994Q2 onward
% Use the sample range where all variables have valid data
start_est = dates('1994Q2');
end_est   = dates('2023Q3');
est_range = start_est:end_est;
fprintf('\nEstimation range: %s to %s (%d quarters)\n', ...
    char(start_est), char(end_est), length(est_range));

%% 3. Open log file
fid = fopen('pac_structural_estimation_log.txt', 'w');
fprintf(fid, '=== PAC STRUCTURAL ESTIMATION RESULTS ===\n');
fprintf(fid, 'Timestamp: %s\n', datestr(now));
fprintf(fid, 'Method: Dynare pac.estimate (iterative OLS + NLS)\n');
fprintf(fid, 'Sample: %s to %s\n\n', char(start_est), char(end_est));

%% =====================================================================
%  4. ITERATIVE OLS ESTIMATION (ECB-Base Stage 2)
%  =====================================================================
fprintf('\n=== ITERATIVE OLS ESTIMATION ===\n\n');
fprintf(fid, '\n=== ITERATIVE OLS ESTIMATION ===\n\n');

% -----------------------------------------------------------------------
% 4a. VA PRICE PAC (eq_piQ_pac, 1st-order)
% -----------------------------------------------------------------------
% diff(pQ_level) = b0_pQ*(piQ_hat(-1) - pQ_level(-1))
%                + b1_pQ*diff(pQ_level(-1))
%                + pac_expectation(pac_pQ)
%                + b2_pQ*yhat_au + pv_piQ_aux + eps_pQ

fprintf('--- 4a. VA Price PAC (eq_piQ_pac) ---\n');
params_pQ = struct();
params_pQ.b0_pQ = 0.06;    % EC speed (initial guess = calibrated)
params_pQ.b1_pQ = 0.50;    % AR(1)
params_pQ.b2_pQ = 0.09;    % output gap
params_pQ.b_covid_crash_pQ  = 0;
params_pQ.b_covid_bounce_pQ = 0;
try
    pac.estimate.iterative_ols('eq_piQ_pac', params_pQ, db, est_range);
    log_results(fid, 'VA Price PAC (iterative OLS)', params_pQ, M_, oo_, 'pac_pQ');
catch ME
    fprintf('  WARNING: iterative OLS failed for VA Price: %s\n', ME.message);
    fprintf(fid, '  FAILED: %s\n\n', ME.message);
end

% -----------------------------------------------------------------------
% 4b. CONSUMPTION PAC (eq_dln_c_pac, 1st-order)
% -----------------------------------------------------------------------
% diff(ln_c_level) = b0_c*(c_hat(-1) - ln_c_level(-1))
%                  + b1_c*diff(ln_c_level(-1))
%                  + pac_expectation(pac_c)
%                  + b2_c*i_gap(-1) + b3_c*yhat_au + pv_c_aux + eps_c

fprintf('\n--- 4b. Consumption PAC (eq_dln_c_pac) ---\n');
params_c = struct();
params_c.b0_c = 0.06;      % EC speed
params_c.b1_c = 0.149;     % AR(1)
params_c.b2_c = -0.02;     % interest rate gap
params_c.b3_c = 0.139;     % output gap
params_c.b_di_c = 0;       % interest rate CHANGE (FR-BDF eq 61)
params_c.b_covid_crash_c  = 0;
params_c.b_covid_bounce_c = 0;
try
    pac.estimate.iterative_ols('eq_dln_c_pac', params_c, db, est_range);
    log_results(fid, 'Consumption PAC (iterative OLS)', params_c, M_, oo_, 'pac_c');
catch ME
    fprintf('  WARNING: iterative OLS failed for Consumption: %s\n', ME.message);
    fprintf(fid, '  FAILED: %s\n\n', ME.message);
end

% -----------------------------------------------------------------------
% 4c. BUSINESS INVESTMENT PAC (eq_dln_ib_pac, 2nd-order)
% -----------------------------------------------------------------------
% diff(ln_ib_level) = b0_ib*(ib_hat(-1) - ln_ib_level(-1))
%                   + b1_ib*diff(ln_ib_level(-1))
%                   + b2_ib*diff(ln_ib_level(-2))
%                   + pac_expectation(pac_ib)
%                   + b3_ib*yhat_au - sigma_ces*pv_rKB_aux + pv_ib_aux + eps_ib

fprintf('\n--- 4c. Business Investment PAC (eq_dln_ib_pac) ---\n');
params_ib = struct();
params_ib.b0_ib = 0.030;   % EC speed
params_ib.b1_ib = 0.181;   % AR(1)
params_ib.b2_ib = 0.10;    % AR(2)
params_ib.b3_ib = 0.191;   % output gap
params_ib.b_covid_crash_ib  = 0;
params_ib.b_covid_bounce_ib = 0;
try
    pac.estimate.iterative_ols('eq_dln_ib_pac', params_ib, db, est_range);
    log_results(fid, 'Business Investment PAC (iterative OLS)', params_ib, M_, oo_, 'pac_ib');
catch ME
    fprintf('  WARNING: iterative OLS failed for Business Investment: %s\n', ME.message);
    fprintf(fid, '  FAILED: %s\n\n', ME.message);
end

% -----------------------------------------------------------------------
% 4d. HOUSEHOLD INVESTMENT PAC (eq_dln_ih_pac, 2nd-order)
% -----------------------------------------------------------------------
% diff(ln_ih_level) = b0_ih*(ih_hat(-1) - ln_ih_level(-1))
%                   + b1_ih*diff(ln_ih_level(-1))
%                   + b2_ih*diff(ln_ih_level(-2))
%                   + pac_expectation(pac_ih)
%                   + b3_ih*yhat_au + b4_ih*i_gap(-1) + pv_ih_aux + eps_ih

fprintf('\n--- 4d. Household Investment PAC (eq_dln_ih_pac) ---\n');
params_ih = struct();
params_ih.b0_ih = 0.049;   % EC speed
params_ih.b1_ih = 0.210;   % AR(1)
params_ih.b2_ih = 0.08;    % AR(2)
params_ih.b3_ih = 0.12;    % output gap
params_ih.b_ph_ih = 0;     % housing price gap (FR-BDF eq 67)
% b4_ih dropped: rate channel via pv_ih_aux (a_ih_i=-0.15) + pac_expectation (F=0.001)
params_ih.b_covid_crash_ih  = 0;
params_ih.b_covid_bounce_ih = 0;
try
    pac.estimate.iterative_ols('eq_dln_ih_pac', params_ih, db, est_range);
    log_results(fid, 'Household Investment PAC (iterative OLS)', params_ih, M_, oo_, 'pac_ih');
catch ME
    fprintf('  WARNING: iterative OLS failed for Household Investment: %s\n', ME.message);
    fprintf(fid, '  FAILED: %s\n\n', ME.message);
end

% -----------------------------------------------------------------------
% 4e. EMPLOYMENT PAC (eq_dln_n_pac, 4th-order)
% -----------------------------------------------------------------------
% diff(ln_n_level) = b0_n*(n_hat(-1) - ln_n_level(-1))
%                  + b1_n*diff(ln_n_level(-1))
%                  + b2_n*diff(ln_n_level(-2))
%                  + b3_n*diff(ln_n_level(-3))
%                  + b4_n*diff(ln_n_level(-4))
%                  + pac_expectation(pac_n)
%                  + b5_n*yhat_au + pv_n_aux + eps_n

fprintf('\n--- 4e. Employment PAC (eq_dln_n_pac) ---\n');
params_n = struct();
params_n.b0_n = 0.040;     % EC speed
params_n.b1_n = 0.30;      % AR(1)
params_n.b2_n = 0.10;      % AR(2)
params_n.b3_n = 0.05;      % AR(3)
params_n.b4_n = 0.02;      % AR(4)
params_n.b5_n = 0.12;      % output gap
params_n.b_covid_crash_n  = 0;
params_n.b_covid_bounce_n = 0;
try
    pac.estimate.iterative_ols('eq_dln_n_pac', params_n, db, est_range);
    log_results(fid, 'Employment PAC (iterative OLS)', params_n, M_, oo_, 'pac_n');
catch ME
    fprintf('  WARNING: iterative OLS failed for Employment: %s\n', ME.message);
    fprintf(fid, '  FAILED: %s\n\n', ME.message);
end


%% =====================================================================
%  5. NLS ESTIMATION WITH SIMULATED ANNEALING (ECB-Base alternative)
%  =====================================================================
% NLS provides a robustness check:
%   - Uses global optimizer (simulated annealing) to avoid local minima
%   - Directly minimizes sum of squared residuals
%   - Can identify parameters that iterative OLS struggles with

fprintf('\n=== NLS ESTIMATION (simulated annealing) ===\n\n');
fprintf(fid, '\n=== NLS ESTIMATION (simulated annealing) ===\n\n');

% Use csminwel as default (available without optimization toolbox).
% Switch to 'annealing' if you want the ECB-Base global optimizer approach.
optimizer = 'annealing';

% Check if optimization toolbox is available for fmincon/fminunc
has_optim_toolbox = ~isempty(ver('optim'));
if ~has_optim_toolbox
    fprintf('  Note: Optimization Toolbox not detected. Using csminwel.\n');
    optimizer = 'csminwel';
end

% -----------------------------------------------------------------------
% 5a. Consumption PAC by NLS
% -----------------------------------------------------------------------
fprintf('\n--- 5a. Consumption PAC (NLS, %s) ---\n', optimizer);
params_c_nls = struct();
params_c_nls.b0_c = 0.06;
params_c_nls.b1_c = 0.149;
params_c_nls.b2_c = -0.02;
params_c_nls.b3_c = 0.139;
params_c_nls.b_di_c = 0;
params_c_nls.b_covid_crash_c  = 0;
params_c_nls.b_covid_bounce_c = 0;
try
    pac.estimate.nls('eq_dln_c_pac', params_c_nls, db, est_range, optimizer, 'MaxIter', 500);
    log_results(fid, 'Consumption PAC (NLS)', params_c_nls, M_, oo_, 'pac_c');
catch ME
    fprintf('  WARNING: NLS failed for Consumption: %s\n', ME.message);
    fprintf(fid, '  FAILED: %s\n\n', ME.message);
end

% -----------------------------------------------------------------------
% 5b. Business Investment PAC by NLS
% -----------------------------------------------------------------------
fprintf('\n--- 5b. Business Investment PAC (NLS, %s) ---\n', optimizer);
params_ib_nls = struct();
params_ib_nls.b0_ib = 0.030;
params_ib_nls.b1_ib = 0.181;
params_ib_nls.b2_ib = 0.10;
params_ib_nls.b3_ib = 0.191;
params_ib_nls.b_covid_crash_ib  = 0;
params_ib_nls.b_covid_bounce_ib = 0;
try
    pac.estimate.nls('eq_dln_ib_pac', params_ib_nls, db, est_range, optimizer, 'MaxIter', 500);
    log_results(fid, 'Business Investment PAC (NLS)', params_ib_nls, M_, oo_, 'pac_ib');
catch ME
    fprintf('  WARNING: NLS failed for Business Investment: %s\n', ME.message);
    fprintf(fid, '  FAILED: %s\n\n', ME.message);
end

% -----------------------------------------------------------------------
% 5c. Household Investment PAC by NLS
% -----------------------------------------------------------------------
fprintf('\n--- 5c. Household Investment PAC (NLS, %s) ---\n', optimizer);
params_ih_nls = struct();
params_ih_nls.b0_ih = 0.049;
params_ih_nls.b1_ih = 0.210;
params_ih_nls.b2_ih = 0.08;
params_ih_nls.b3_ih = 0.12;
params_ih_nls.b_ph_ih = 0;
% b4_ih dropped: rate channel via pv_ih_aux + pac_expectation (F=0.001)
params_ih_nls.b_covid_crash_ih  = 0;
params_ih_nls.b_covid_bounce_ih = 0;
try
    pac.estimate.nls('eq_dln_ih_pac', params_ih_nls, db, est_range, optimizer, 'MaxIter', 500);
    log_results(fid, 'Household Investment PAC (NLS)', params_ih_nls, M_, oo_, 'pac_ih');
catch ME
    fprintf('  WARNING: NLS failed for Household Investment: %s\n', ME.message);
    fprintf(fid, '  FAILED: %s\n\n', ME.message);
end

%% 6. Summary comparison
fprintf('\n');
fprintf('================================================================\n');
fprintf('  ESTIMATION COMPLETE\n');
fprintf('================================================================\n');
fprintf('Results saved to: pac_structural_estimation_log.txt\n');
fprintf('Updated parameters available in M_.params\n');
fprintf('\nTo update au_pac.mod with estimated values:\n');
fprintf('  >> print_updated_params(M_)\n');

fprintf(fid, '\n=== ESTIMATION COMPLETE ===\n');
fclose(fid);


%% =====================================================================
%  Helper function: log estimation results
%  =====================================================================
function log_results(fid, label, params_init, M_, oo_, pacname)
    fprintf('\n  --- %s ---\n', label);
    fprintf(fid, '%s\n', label);

    pnames = fieldnames(params_init);
    if isfield(oo_.pac, pacname) && isfield(oo_.pac.(pacname), 'estimator')
        est = oo_.pac.(pacname).estimator;
        ssr = oo_.pac.(pacname).ssr;
        T = length(oo_.pac.(pacname).residual);

        fprintf('  SSR = %.6f,  T = %d\n', ssr, T);
        fprintf(fid, '  SSR = %.6f,  T = %d\n', ssr, T);

        fprintf('  %-15s %10s %10s %10s\n', 'Parameter', 'Initial', 'Estimated', 'Change');
        fprintf(fid, '  %-15s %10s %10s %10s\n', 'Parameter', 'Initial', 'Estimated', 'Change');

        for j = 1:length(pnames)
            init_val = params_init.(pnames{j});
            if j <= length(est)
                est_val = est(j);
            else
                % Parameter may be in M_.params
                idx = find(strcmp(pnames{j}, M_.param_names));
                if ~isempty(idx)
                    est_val = M_.params(idx);
                else
                    est_val = NaN;
                end
            end
            chg = est_val - init_val;
            fprintf('  %-15s %10.4f %10.4f %+10.4f\n', pnames{j}, init_val, est_val, chg);
            fprintf(fid, '  %-15s %10.4f %10.4f %+10.4f\n', pnames{j}, init_val, est_val, chg);
        end
    else
        fprintf('  No results stored in oo_.pac.%s\n', pacname);
        fprintf(fid, '  No results stored\n');
    end
    fprintf(fid, '\n');
end
