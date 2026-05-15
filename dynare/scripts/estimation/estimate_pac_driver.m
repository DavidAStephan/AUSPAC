%% estimate_pac_driver.m
% Master script for PAC structural parameter estimation.
%
% Runs the full pipeline:
%   1. Preprocesses au_pac.mod with json=compute (needed for pac.estimate)
%   2. Initializes PAC models (h-vector computation)
%   3. Calls estimate_pac.m for iterative OLS + NLS estimation
%
% USAGE:
%   >> cd(<repo>/dynare); estimate_pac_driver
%
% REQUIREMENTS:
%   - Dynare 6.5 on path
%   - dataset.csv and data/extended_dataset.csv present
%   - au_pac.mod compiles cleanly

clear; clc;

%% Setup paths
cd(fileparts(mfilename('fullpath')));
setup_dynare_path();

fprintf('================================================================\n');
fprintf('  AU_PAC STRUCTURAL ESTIMATION DRIVER\n');
fprintf('  ECB-Base methodology: iterative OLS + NLS\n');
fprintf('================================================================\n');
fprintf('Timestamp: %s\n\n', datestr(now));

%% Step 1: Run Dynare with json=compute
% json=compute enables the JSON model output that pac.estimate.init needs
% to parse equation structure, identify parameters, and build regressors.
%
% noclearall preserves workspace for subsequent estimation calls.
% nograph/noprint suppress stoch_simul output (we only need M_, oo_).

fprintf('--- Step 1: Running dynare au_pac json=compute ---\n');
fprintf('  This preprocesses the model and runs stoch_simul...\n\n');

dynare au_pac json=compute noclearall

fprintf('\n--- Dynare preprocessing complete ---\n');
fprintf('  M_.endo_nbr = %d endogenous variables\n', M_.endo_nbr);
fprintf('  M_.exo_nbr  = %d exogenous variables\n', M_.exo_nbr);
fprintf('  M_.param_nbr = %d parameters\n\n', M_.param_nbr);

%% Step 2: Build companion matrix and initialize PAC models
% After stoch_simul, oo_.var contains the variance-covariance matrix (a double).
% pac.estimate needs oo_.var to be a struct with the companion matrix.
% We fix this by converting oo_.var and calling get_companion_matrix.

fprintf('--- Step 2: Building companion matrix for var_model ---\n');
if ~isstruct(oo_.var)
    fprintf('  Converting oo_.var from %s to struct (was variance-covariance matrix)\n', class(oo_.var));
    oo_.var = struct();
end
get_companion_matrix('esat_enriched', 'var');
CM = oo_.var.esat_enriched.CompanionMatrix;
fprintf('  Companion matrix: %dx%d, all finite: %d\n', size(CM,1), size(CM,2), all(isfinite(CM(:))));

% Initialize all PAC models from the companion matrix
pac_models = {'pac_pQ', 'pac_c', 'pac_ib', 'pac_ih', 'pac_n'};
for k = 1:length(pac_models)
    pm = pac_models{k};
    pac.initialize(pm);
    pac.update.expectation(pm);
    nh = length(M_.pac.(pm).h_param_indices);
    fprintf('  %s: initialized, %d h-vector parameters\n', pm, nh);
end
fprintf('\n');

%% Step 3: Run PAC estimation
fprintf('--- Step 3: Running PAC estimation ---\n\n');
estimate_pac

%% Step 4: Save results
fprintf('\n--- Step 4: Saving results ---\n');
save('pac_estimation_results.mat', 'M_', 'oo_');
fprintf('  Saved M_ and oo_ to pac_estimation_results.mat\n');

% Print parameter values for updating au_pac.mod
fprintf('\n--- Estimated parameter values for au_pac.mod ---\n');
pac_params = {'b0_pQ', 'b1_pQ', 'b2_pQ', ...
              'b0_c', 'b1_c', 'b2_c', 'b3_c', ...
              'b0_ib', 'b1_ib', 'b2_ib', 'b3_ib', ...
              'b0_ih', 'b1_ih', 'b2_ih', 'b3_ih', 'b4_ih', ...
              'b0_n', 'b1_n', 'b2_n', 'b3_n', 'b4_n', 'b5_n'};

fprintf('  // --- Updated PAC parameters (estimated from AU data) ---\n');
for k = 1:length(pac_params)
    pname = pac_params{k};
    idx = find(strcmp(pname, M_.param_names));
    if ~isempty(idx)
        fprintf('  %-16s= %.4f;\n', pname, M_.params(idx));
    end
end

fprintf('\n================================================================\n');
fprintf('  ESTIMATION PIPELINE COMPLETE\n');
fprintf('================================================================\n');
