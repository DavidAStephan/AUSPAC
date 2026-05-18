% Phase W (2026-05-17): re-run dynare + cherrypick on each aux file with
% calibration.inc-posterior aux-regression coefficients, to refresh the
% h_pac_* policy-function coefficients written into
% simulation/estimation/<block>/parameter-values.inc.
%
% After this script: patch h_pac_* lines in au_pac.mod and
% au_pac_bayesian.mod from the regenerated parameter-values.inc files.

setup_dynare_path;
addpath(genpath('/Applications/Dynare/6.5-x86_64/matlab/missing'));

cwd = pwd;

% Block specs: name, dirname-under-simulation/estimation, eqtags-cell
% NOTE: pac_expectation_pac_X is auto-emitted by cherrypick when it processes
% the eq_X_pac equation (which calls pac_expectation(pac_X)). Don't list
% pac_expectation_pac_X in eqtags — those tags don't exist in the aux source.
blocks = {
    'pQ',           'pQ',            {'eq_piQ_pac'};
    'consumption',  'consumption',   {'eq_dln_c_pac', 'var_yh', 'var_c'};
    'business_inv', 'business_inv',  {'eq_dln_ib_pac','var_ib', 'var_rKB'};
    'housing_inv',  'housing_inv',   {'eq_dln_ih_pac','var_ih'};
    'employment',   'employment',    {'eq_dln_n_pac', 'var_n'};
};

for k = 1:size(blocks, 1)
    name = blocks{k,1};
    outdir_abs = fullfile(cwd, 'simulation', 'estimation', blocks{k,2});
    tags = blocks{k,3};

    fprintf('\n=== Phase W: block %s ===\n', name);

    % Both dynare and cherrypick must run from the aux/ directory because
    % cherrypick looks for M_.dname/model/json/modfile-original.json relative
    % to cwd, and M_.dname is just the basename ('aux_<name>') with no prefix.
    cd(fullfile(cwd, 'aux'));
    eval(sprintf('dynare aux_%s noclearall', name));
    cherrypick(sprintf('aux_%s', name), outdir_abs, tags, true);

    fprintf('=== Block %s done ===\n', name);
end
cd(cwd);

fprintf('\nALL_BLOCKS_RECHERRYPICK_OK\n');
