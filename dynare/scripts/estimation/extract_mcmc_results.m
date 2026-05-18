%% extract_mcmc_results.m
% Dumps the posterior summary after Stage 2 MCMC completes, in a format
% ready to paste into AUSPAC_WORKING_PAPER.md Table 5.6 and STATUS.md.
%
% USAGE: run after `dynare au_pac_bayesian` (Stage 2):
%   >> load bayesian_mcmc_results.mat
%   >> extract_mcmc_results
%
% Or standalone:
%   >> extract_mcmc_results

clear; clc;
% Post-cleanup fix: this script is at dynare/scripts/estimation/ but
% bayesian_mcmc_results.mat is written to dynare/ by run_bayesian_mcmc.
this_dir = fileparts(mfilename('fullpath'));
if isempty(this_dir), this_dir = pwd; end
dynare_dir = fullfile(this_dir, '..', '..');     % up to dynare/

mcmc_file = fullfile(dynare_dir, 'bayesian_mcmc_results.mat');
if ~exist(mcmc_file, 'file')
    % fallback: maybe already at dynare/
    mcmc_file = fullfile(pwd, 'bayesian_mcmc_results.mat');
end
if ~exist(mcmc_file, 'file')
    error('bayesian_mcmc_results.mat not found. Run run_bayesian_mcmc.m first.');
end
load(mcmc_file, 'oo_', 'M_');
% Now cd to dynare/ for output writes
cd(dynare_dir);

fprintf('=== AU-PAC Bayesian MCMC results extractor ===\n\n');

%% Collect parameters and shock std devs into a single table
rows = {};

% Parameters
if isfield(oo_, 'posterior_mean') && isfield(oo_.posterior_mean, 'parameters')
    pmean = oo_.posterior_mean.parameters;
    fns = fieldnames(pmean);
    for k = 1:length(fns)
        nm = fns{k};
        m  = pmean.(nm);
        mode_v = NaN; lo = NaN; hi = NaN;
        if isfield(oo_, 'posterior_mode') && isfield(oo_.posterior_mode, 'parameters') ...
                && isfield(oo_.posterior_mode.parameters, nm)
            mode_v = oo_.posterior_mode.parameters.(nm);
        end
        if isfield(oo_, 'posterior_hpdinf') && isfield(oo_.posterior_hpdinf, 'parameters') ...
                && isfield(oo_.posterior_hpdinf.parameters, nm)
            lo = oo_.posterior_hpdinf.parameters.(nm);
        end
        if isfield(oo_, 'posterior_hpdsup') && isfield(oo_.posterior_hpdsup, 'parameters') ...
                && isfield(oo_.posterior_hpdsup.parameters, nm)
            hi = oo_.posterior_hpdsup.parameters.(nm);
        end
        rows{end+1, 1} = nm;
        rows{end,   2} = m;
        rows{end,   3} = mode_v;
        rows{end,   4} = lo;
        rows{end,   5} = hi;
    end
end

% Shock std devs
if isfield(oo_, 'posterior_mean') && isfield(oo_.posterior_mean, 'shocks_std')
    smean = oo_.posterior_mean.shocks_std;
    fns = fieldnames(smean);
    for k = 1:length(fns)
        nm = fns{k};
        m  = smean.(nm);
        mode_v = NaN; lo = NaN; hi = NaN;
        if isfield(oo_, 'posterior_mode') && isfield(oo_.posterior_mode, 'shocks_std') ...
                && isfield(oo_.posterior_mode.shocks_std, nm)
            mode_v = oo_.posterior_mode.shocks_std.(nm);
        end
        if isfield(oo_, 'posterior_hpdinf') && isfield(oo_.posterior_hpdinf, 'shocks_std') ...
                && isfield(oo_.posterior_hpdinf.shocks_std, nm)
            lo = oo_.posterior_hpdinf.shocks_std.(nm);
        end
        if isfield(oo_, 'posterior_hpdsup') && isfield(oo_.posterior_hpdsup, 'shocks_std') ...
                && isfield(oo_.posterior_hpdsup.shocks_std, nm)
            hi = oo_.posterior_hpdsup.shocks_std.(nm);
        end
        rows{end+1, 1} = ['stderr_' nm];
        rows{end,   2} = m;
        rows{end,   3} = mode_v;
        rows{end,   4} = lo;
        rows{end,   5} = hi;
    end
end

%% Print and save
out_md = fullfile(this_dir, 'mcmc_posterior_table.md');
fid = fopen(out_md, 'w');
fprintf(fid, '# Bayesian MCMC posterior — Phase A-D refresh\n\n');
fprintf(fid, 'Generated %s\n\n', datestr(now));

% LMD
if isfield(oo_, 'MarginalDensity')
    if isfield(oo_.MarginalDensity, 'LaplaceApproximation')
        lmd_l = oo_.MarginalDensity.LaplaceApproximation;
        fprintf(fid, '**Log marginal density (Laplace):** %.4f\n\n', lmd_l);
        fprintf('  LMD (Laplace): %.4f (baseline 2026-04-14: -933.41)\n', lmd_l);
    end
    if isfield(oo_.MarginalDensity, 'ModifiedHarmonicMean')
        lmd_m = oo_.MarginalDensity.ModifiedHarmonicMean;
        fprintf(fid, '**Log marginal density (Modified Harmonic Mean):** %.4f\n\n', lmd_m);
        fprintf('  LMD (MHM):     %.4f (baseline 2026-04-14: -933.33)\n', lmd_m);
    end
end

% Acceptance rates
if isfield(oo_, 'AcceptanceRate')
    fprintf(fid, '**Acceptance rates:** ');
    for b = 1:length(oo_.AcceptanceRate)
        fprintf(fid, 'chain %d = %.1f%%; ', b, oo_.AcceptanceRate(b)*100);
    end
    fprintf(fid, '\n\n');
end

fprintf(fid, '## Posterior summary\n\n');
fprintf(fid, '| Parameter | Post. mean | Post. mode | 90%% HPD low | 90%% HPD high |\n');
fprintf(fid, '|-----------|-----------|-----------|------------|-------------|\n');
fprintf('\n%-22s %10s %10s %10s %10s\n', 'Parameter', 'mean', 'mode', 'HPD_lo', 'HPD_hi');
fprintf('%s\n', repmat('-', 1, 65));
for k = 1:size(rows, 1)
    nm   = rows{k,1};
    m    = rows{k,2};
    mode = rows{k,3};
    lo   = rows{k,4};
    hi   = rows{k,5};
    fprintf(fid, '| %s | %.4f | %.4f | %.4f | %.4f |\n', nm, m, mode, lo, hi);
    fprintf('%-22s %10.4f %10.4f %10.4f %10.4f\n', nm, m, mode, lo, hi);
end
fclose(fid);

fprintf('\nWrote %s\n', out_md);

%% Generate paste-ready .mod parameter lines for the writeback
out_mod = fullfile(this_dir, 'mcmc_writeback.txt');
fid = fopen(out_mod, 'w');
fprintf(fid, '// === Refreshed Bayesian posteriors (Phase A-D conditioning, %s) ===\n', datestr(now, 'yyyy-mm-dd'));
fprintf(fid, '// Paste these values into au_pac.mod, au_pac_var.mod, au_pac_mce.mod\n\n');
fprintf(fid, '// --- Outer PAC + wage block ---\n');
for k = 1:size(rows, 1)
    nm = rows{k, 1};
    if startsWith(nm, 'stderr_'), continue; end
    fprintf(fid, '%-15s = %7.4f;    // posterior mean, 90%% HPD [%.4f, %.4f]\n', ...
        nm, rows{k, 2}, rows{k, 4}, rows{k, 5});
end
fprintf(fid, '\n// --- Shock std devs (paste inside `shocks; ... end;` block) ---\n');
for k = 1:size(rows, 1)
    nm = rows{k, 1};
    if ~startsWith(nm, 'stderr_'), continue; end
    eps_nm = nm(8:end);
    fprintf(fid, '    var %-12s stderr %.4f;   // posterior mean, 90%% HPD [%.4f, %.4f]\n', ...
        [eps_nm ';'], rows{k, 2}, rows{k, 4}, rows{k, 5});
end
fclose(fid);

fprintf('Wrote %s\n', out_mod);
fprintf('=== Done ===\n');
