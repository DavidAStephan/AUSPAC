%% run_all.m
% Master script for the E-SAT Australia structural VAR.
% Runs all steps in sequence: data download, estimation, model & IRFs.
%
% Usage: Open MATLAB, cd to this folder, then run:
%   >> run_all
%
% Based on: Banque de France WP #736 (Lemoine et al., 2019), Section 3.1.1
% Adapted for Australia (replacing France) with US (replacing euro area).

clear; clc; close all;

scriptdir = fileparts(mfilename('fullpath'));
if isempty(scriptdir), scriptdir = pwd; end
cd(scriptdir);

fprintf('========================================\n');
fprintf(' E-SAT Structural VAR for Australia\n');
fprintf(' (adapted from Banque de France WP #736)\n');
fprintf('========================================\n\n');

%% Configuration
% Set to true to load data from dataset.csv instead of downloading.
% Useful for offline work or reproducibility.
USE_LOCAL_CSV = false;

%% Step 1: Download and process data
if USE_LOCAL_CSV
    fprintf('>>> STEP 1: Loading data from dataset.csv...\n\n');
else
    fprintf('>>> STEP 1: Downloading and processing data...\n');
    fprintf('    (requires internet connection)\n\n');
end
try
    download_data;
    fprintf('\n>>> Step 1 COMPLETE\n\n');
catch ME
    fprintf('\n>>> Step 1 FAILED: %s\n', ME.message);
    fprintf('    You may need to check internet connectivity or data URLs.\n');
    fprintf('    The model can still run with calibrated defaults (Step 3).\n\n');
end

%% Step 2a: OLS estimation (initial values for Bayesian)
fprintf('>>> STEP 2a: OLS estimation (initial values)...\n\n');
try
    estimate_esat;
    fprintf('\n>>> Step 2a COMPLETE\n\n');
catch ME
    fprintf('\n>>> Step 2a FAILED: %s\n', ME.message);
    fprintf('    Bayesian estimation will use default starting values.\n\n');
end

%% Step 2b: Bayesian estimation (MCMC)
fprintf('>>> STEP 2b: Bayesian estimation (MCMC)...\n\n');
try
    bayesian_estimate;
    fprintf('\n>>> Step 2b COMPLETE\n\n');
catch ME
    fprintf('\n>>> Step 2b FAILED: %s\n', ME.message);
    fprintf('    Step 3 will use OLS or calibrated defaults instead.\n\n');
end

%% Step 3: Build model, compute IRFs, generate plots
fprintf('>>> STEP 3: Building model and computing IRFs...\n\n');
try
    esat_model;
    fprintf('\n>>> Step 3 COMPLETE\n\n');
catch ME
    fprintf('\n>>> Step 3 FAILED: %s\n', ME.message);
    rethrow(ME);
end

fprintf('========================================\n');
fprintf(' All steps complete.\n');
fprintf(' Output files:\n');
fprintf('   data.mat   - Processed quarterly data\n');
fprintf('   params.mat - Estimated parameters (Bayesian posterior means)\n');
fprintf('   mcmc_output.mat - Full MCMC chain and diagnostics\n');
fprintf('   irf_interest_rate.png  - IRF plot\n');
fprintf('   irf_us_output_gap.png  - IRF plot\n');
fprintf('   mcmc_traces.png        - MCMC trace plots\n');
fprintf('   prior_vs_posterior.png  - Prior vs posterior comparison\n');
fprintf('========================================\n');
