%% run_estimation.m
% Bayesian estimation of AU-PAC model using Australian data.
% Two-step approach following FR-BDF methodology:
%   Step 1: Estimate E-SAT core + key demand parameters (this script)
%   Step 2: PAC iterative OLS (future — requires simulated data)
%
% Prerequisites: run data/prepare_estimation_data.m first.

clear; clc;
addpath('C:\dynare\6.5\matlab');
cd('c:\Users\david\french_model\dynare');

fprintf('=== AU-PAC Bayesian Estimation ===\n');
fprintf('Timestamp: %s\n\n', datestr(now));

% Check estimation data exists
if ~exist('estimation_data.mat', 'file')
    error('estimation_data.mat not found. Run data/prepare_estimation_data.m first.');
end

% Load and verify
d = load('estimation_data.mat');
fprintf('Estimation data: %d obs x %d vars\n', length(d.yhat_au), 9);
fprintf('Variables: yhat_au, pi_au, i_au, yhat_us, pi_us, pi_w, dln_c, dln_ib, i_10y\n\n');

% Run Dynare estimation
% Note: au_pac_est.mod is au_pac.mod with estimation blocks uncommented
dynare au_pac_est noclearall nograph;

fprintf('\n=== Estimation complete ===\n');
