%% make_paper_results.m
% End-to-end driver: rebuilds every estimation output and IRF table from a
% clean clone, in the order their results feed each other.
%
% Run from the AUSPAC repo root:
%   >> make_paper_results
%
% Stages (≈ 3-5 minutes total on Apple Silicon under Rosetta + R2020a):
%   1. download_data            (USE_LOCAL_CSV=true; rebuilds data.mat)
%   2. estimate_esat            (16 E-SAT params -> params.mat)
%   3. data/prepare_estimation_data  (122-obs estimation data for Bayesian)
%   4. dynare/estimate_auxiliary_bayesian   (Phase B: 22 auxiliary coefs)
%   5. dynare/estimate_phase_c_lpiv         (Phase C: b_di_c, b_ph_ih)
%   6. dynare/estimate_phase_d_trade        (Phase D: trade volume params)
%   7. dynare au_pac, au_pac_var, au_pac_mce  (compile + IRF + BK check)
%   8. test_full_system         (full regression test, pass/fail report)
%
% Notes:
%   - Stages 4/5/6 produce values that ALREADY live in the .mod files
%     (paste-back was done by hand in conversation 2026-05-09); rerunning
%     them just regenerates auxiliary_bayesian_results.txt etc. and confirms
%     reproducibility.
%   - Phase A (Bayesian posterior writeback for outer PAC + wage params)
%     requires the gitignored mode .mat file in dynare/au_pac_bayesian/Output/
%     so it cannot be re-run from a clean clone without re-running MCMC.
%     Posterior values are baked into the .mod files.
%   - Stage 2 will fail if dataset.csv is missing — Stage 1 must succeed first.

clear; clc;
fprintf('================================================================\n');
fprintf('  AUSPAC — make_paper_results.m\n');
fprintf('  Started: %s\n', datestr(now));
fprintf('================================================================\n\n');

projectdir = fileparts(mfilename('fullpath'));
if isempty(projectdir), projectdir = pwd; end
cd(projectdir);

% Bootstrap MATLAB path: addpath dynare/scripts/* and locate Dynare.
% Setup is at dynare/setup_dynare_path.m; it must be reachable before
% any of Stage 4-8 scripts can be called by name.
addpath(fullfile(projectdir, 'dynare'));
setup_dynare_path();

t_total = tic;

%% Stage 1: data
fprintf('--- Stage 1/8: download_data (local CSV mode) ---\n');
USE_LOCAL_CSV = true;            %#ok<NASGU>
download_data;
fprintf('\n');

%% Stage 2: E-SAT OLS
fprintf('--- Stage 2/8: estimate_esat ---\n');
estimate_esat;
fprintf('\n');

%% Stage 3: Bayesian estimation data prep
fprintf('--- Stage 3/8: prepare_estimation_data ---\n');
cd(fullfile(projectdir, 'data'));
prepare_estimation_data;
cd(projectdir);
fprintf('\n');

%% Stage 4: Phase B auxiliary Bayesian regression
fprintf('--- Stage 4/8: Phase B auxiliary Bayesian ---\n');
cd(fullfile(projectdir, 'dynare'));
estimate_auxiliary_bayesian;
cd(projectdir);
fprintf('\n');

%% Stage 5: Phase C LP-IV
fprintf('--- Stage 5/8: Phase C LP-IV (b_di_c, b_ph_ih) ---\n');
cd(fullfile(projectdir, 'dynare'));
estimate_phase_c_lpiv;
cd(projectdir);
fprintf('\n');

%% Stage 6: Phase D trade re-estimation
fprintf('--- Stage 6/8: Phase D trade volumes ---\n');
cd(fullfile(projectdir, 'dynare'));
estimate_phase_d_trade;
cd(projectdir);
fprintf('\n');

%% Stage 7: compile all three Dynare model variants and produce IRFs
fprintf('--- Stage 7/8: Compile all 3 Dynare variants ---\n');
cd(fullfile(projectdir, 'dynare'));
% noclearall keeps M_/oo_ in workspace; nograph avoids X11 popups in headless mode
for variant = {'au_pac_var', 'au_pac', 'au_pac_mce'}
    name = variant{1};
    fprintf('  Compiling %s ... ', name);
    try
        evalin('base', sprintf('dynare %s noclearall nograph', name));
        fprintf('OK\n');
    catch ME
        fprintf('FAIL: %s\n', ME.message);
    end
end
cd(projectdir);
fprintf('\n');

%% Stage 8: full regression test suite
fprintf('--- Stage 8/8: test_full_system ---\n');
test_full_system;
fprintf('\n');

%% Summary
fprintf('================================================================\n');
fprintf('  Total wall time: %.1f minutes\n', toc(t_total)/60);
fprintf('  Outputs:\n');
fprintf('    data.mat, params.mat, dynare/estimation_data.mat\n');
fprintf('    dynare/auxiliary_bayesian_results.{txt,mat}    (Phase B)\n');
fprintf('    dynare/phase_c_results.{txt,mat}               (Phase C)\n');
fprintf('    dynare/phase_d_results.{txt,mat}               (Phase D)\n');
fprintf('    dynare/full_system_test_results.txt            (Stage 8)\n');
fprintf('================================================================\n');
