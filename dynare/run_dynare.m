%% run_dynare.m
% Master script for running the AU E-SAT model in Dynare.
% Adds Dynare to path, loads estimated parameters, runs the .mod file.

clear; clc; close all;

%% Setup paths
scriptdir = fileparts(mfilename('fullpath'));
if isempty(scriptdir), scriptdir = pwd; end
cd(scriptdir);

% Add Dynare to MATLAB path
dynare_path = 'C:\dynare\6.5\matlab';
if exist(dynare_path, 'dir')
    addpath(dynare_path);
    fprintf('Dynare 6.5 added to path: %s\n', dynare_path);
else
    error('Dynare not found at %s. Please update the path.', dynare_path);
end

%% Load estimated parameters (from Bayesian estimation)
paramfile = fullfile(scriptdir, '..', 'params.mat');
if exist(paramfile, 'file')
    load(paramfile, 'params');
    fprintf('Loaded Bayesian posterior mean parameters\n');

    % Override .mod file defaults with estimated values
    % (Dynare reads parameter values from the workspace after set_param_value)
    fprintf('\nParameter values to be used:\n');
    fprintf('  delta       = %.4f\n', params.delta);
    fprintf('  lambda_q    = %.4f\n', params.lambda_q);
    fprintf('  sigma_q     = %.4f\n', params.sigma_q);
    fprintf('  lambda_i    = %.4f\n', params.lambda_i);
    fprintf('  alpha_i     = %.4f\n', params.alpha_i);
    fprintf('  beta_i      = %.4f\n', params.beta_i);
    fprintf('  lambda_pi   = %.4f\n', params.lambda_pi);
    fprintf('  kappa_pi    = %.4f\n', params.kappa_pi);
    fprintf('  lambda_q_us = %.4f\n', params.lambda_q_us);
    fprintf('  lambda_pi_us = %.4f\n', params.lambda_pi_us);
    fprintf('  kappa_pi_us = %.4f\n', params.kappa_pi_us);
else
    fprintf('params.mat not found; using defaults from .mod file\n');
end

%% Run Dynare
fprintf('\n=== Running Dynare on au_esat.mod ===\n\n');
dynare au_esat noclearall;

% Note: Parameters are set directly in the .mod file from Bayesian posteriors.
% To update parameters dynamically, edit the .mod file defaults or use
% set_param_value() followed by a new stoch_simul call.

%% Display key results
fprintf('\n=== Dynare E-SAT Results ===\n');
fprintf('Eigenvalues (modulus):\n');
eigvals = oo_.dr.eigval;
for k = 1:length(eigvals)
    fprintf('  %2d: |%.4f|\n', k, abs(eigvals(k)));
end

fprintf('\nAll eigenvalues inside unit circle: %s\n', ...
    iif(all(abs(eigvals) < 1 + 1e-6), 'YES (stable)', 'NO (check model)'));

fprintf('\n=== Dynare run complete ===\n');

function s = iif(cond, a, b)
    if cond, s = a; else, s = b; end
end
