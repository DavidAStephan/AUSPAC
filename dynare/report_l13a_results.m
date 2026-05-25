%% report_l13a_results.m  --  side-by-side posterior comparison
%
% Loads the L1.3a MCMC results (au_pac_bayesian/Output/au_pac_bayesian_results.mat)
% and the cached round12 baseline (au_pac_bayesian.cached_round12_calibrated_2026
% -05-22/Output/au_pac_bayesian_results.mat) and prints a side-by-side
% comparison of posterior summaries for the parameters that matter for
% the consumption block.
%
% Run from MATLAB after the L1.3a MCMC has completed:
%   cd dynare
%   addpath('/Applications/Dynare/6.5-x86_64/matlab')
%   report_l13a_results
%
% Outputs:
%   - stdout: formatted comparison table
%   - dynare/L1_3a_report.txt: same content saved for the record
%
% MHM comparison note: L1.3a has 10 observables vs round12's 9.  Adding an
% observable mechanically shifts the log marginal density by roughly
% -T·log(prior-predictive variance) ~= -112 nats at T=122 quarters when
% the new observable's data is informative.  For cross-spec MHM comparison
% the offset is subtracted from the L1.3a number; within-spec it cancels.

clear; clc;
fprintf('=== L1.3a posterior comparison (vs round12 baseline) ===\n\n');

projectdir = fileparts(mfilename('fullpath'));
if isempty(projectdir), projectdir = pwd; end

f_l13a = fullfile(projectdir, 'au_pac_bayesian', 'Output', ...
    'au_pac_bayesian_results.mat');
f_base = fullfile(projectdir, ...
    'au_pac_bayesian.cached_round12_calibrated_2026-05-22', 'Output', ...
    'au_pac_bayesian_results.mat');

assert(isfile(f_l13a), ...
    sprintf('Missing %s -- run L1.3a MCMC first.', f_l13a));
assert(isfile(f_base), ...
    sprintf('Missing %s -- restore round12 cached chain.', f_base));

L = load(f_l13a);
B = load(f_base);

% Sanity: both should have oo_ struct
assert(isfield(L, 'oo_'), 'L1.3a results.mat does not have oo_');
assert(isfield(B, 'oo_'), 'round12 results.mat does not have oo_');

oo_L = L.oo_;
oo_B = B.oo_;

fprintf('File loaded:\n');
fprintf('  L1.3a:    %s\n', f_l13a);
fprintf('  baseline: %s\n\n', f_base);

%% ---------------------------------------------------------------
%% 1. Marginal density comparison
%% ---------------------------------------------------------------
fprintf('--- Marginal density ---\n');
laplace_L = NaN; mhm_L = NaN;
laplace_B = NaN; mhm_B = NaN;
if isfield(oo_L, 'MarginalDensity')
    if isfield(oo_L.MarginalDensity, 'LaplaceApproximation')
        laplace_L = oo_L.MarginalDensity.LaplaceApproximation;
    end
    if isfield(oo_L.MarginalDensity, 'ModifiedHarmonicMean')
        mhm_L = oo_L.MarginalDensity.ModifiedHarmonicMean;
    end
end
if isfield(oo_B, 'MarginalDensity')
    if isfield(oo_B.MarginalDensity, 'LaplaceApproximation')
        laplace_B = oo_B.MarginalDensity.LaplaceApproximation;
    end
    if isfield(oo_B.MarginalDensity, 'ModifiedHarmonicMean')
        mhm_B = oo_B.MarginalDensity.ModifiedHarmonicMean;
    end
end

mech_penalty_per_obs = 112;       % approximate per NEXT_SESSION.md analysis
penalty_L = 1 * mech_penalty_per_obs;   % L1.3a adds 1 observable vs baseline
penalty_B = 0;

fprintf('%-32s %12s %12s %12s\n', 'Quantity', 'L1.3a', 'baseline', 'L1.3a - base');
fprintf('%-32s %12s %12s %12s\n', '--------', '-----', '--------', '------------');
fprintf('%-32s %12.2f %12.2f %12.2f\n', ...
    'Laplace LMD', laplace_L, laplace_B, laplace_L - laplace_B);
fprintf('%-32s %12.2f %12.2f %12.2f\n', ...
    'ModifiedHarmonicMean LMD', mhm_L, mhm_B, mhm_L - mhm_B);
fprintf('%-32s %12.2f %12.2f %12.2f\n', ...
    '  net of ~112 obs penalty', mhm_L + penalty_L, mhm_B + penalty_B, ...
    (mhm_L + penalty_L) - (mhm_B + penalty_B));
fprintf('\n');

%% ---------------------------------------------------------------
%% 2. Posterior summary table for key parameters
%% ---------------------------------------------------------------
% Pull from oo_.posterior_mean / oo_.posterior_hpdinf / hpdsup.parameters.
% For shocks, use the .shocks_std substruct.
key_params = { ...
    'b0_pQ',       'param', 'VA-price ECM speed';
    'b1_pQ',       'param', 'VA-price lag';
    'b2_pQ',       'param', 'VA-price output gap';
    'alpha_pc',    'param', 'VA -> CPI passthrough';
    'kappa_pi',    'param', 'Phillips slope on yhat';
    'lambda_pi',   'param', 'CPI persistence';
    'a_pQ_w',      'param', 'wage->piQ projection';
    'alpha_pc_lag','param', 'Phillips lagged passthrough';
    'b_ECM_pc',    'param', 'Phillips ECM speed';
    'b0_c',        'param', 'consumption ECM speed';
    'b1_c',        'param', 'consumption lag';
    'b2_c',        'param', 'consumption interest rate';
    'b3_c',        'param', 'consumption output gap';
    'b0_ib',       'param', 'business inv ECM';
    'b1_ib',       'param', 'business inv lag 1';
    'b3_ib',       'param', 'business inv output gap';
    'b0_ih',       'param', 'housing inv ECM';
    'b1_ih',       'param', 'housing inv lag 1';
    'b3_ih',       'param', 'housing inv output gap';
    'b0_n',        'param', 'employment ECM';
    'b1_n',        'param', 'employment lag 1';
    'b5_n',        'param', 'employment output gap';
    'lambda_w',    'param', 'wage backward-look';
    'gamma_w',     'param', 'wage forward-look';
    'kappa_w',     'param', 'wage Phillips slope';
    'b_PAC_c',     'param', '*** L1.3a NEW *** wp1044 growth-neutrality on dy_bar_gap';
};

shock_params = { ...
    'eps_q',  'shock', 'output gap';
    'eps_i',  'shock', 'policy rate';
    'eps_pi', 'shock', 'CPI inflation';
    'eps_c',  'shock', 'consumption';
    'eps_ib', 'shock', 'business inv';
    'eps_ih', 'shock', 'housing inv';
    'eps_n',  'shock', 'employment';
    'eps_w',  'shock', 'wage inflation';
    'eps_10y','shock', '10y bond rate';
};

txtfile = fullfile(projectdir, 'L1_3a_report.txt');
fid = fopen(txtfile, 'w');
fprintf(fid, 'L1.3a posterior comparison (vs round12 baseline)\n');
fprintf(fid, 'Generated %s\n', datestr(now));
fprintf(fid, 'Branch: refactor/frbdf-replication, Phase L1.3a\n\n');
fprintf(fid, 'L1.3a:    %s\n', f_l13a);
fprintf(fid, 'baseline: %s\n\n', f_base);
fprintf(fid, '--- Marginal density ---\n');
fprintf(fid, '%-32s %12.2f %12.2f %12.2f\n', 'Laplace LMD', laplace_L, laplace_B, laplace_L - laplace_B);
fprintf(fid, '%-32s %12.2f %12.2f %12.2f\n', 'MHM LMD', mhm_L, mhm_B, mhm_L - mhm_B);
fprintf(fid, '%-32s %12.2f %12.2f %12.2f\n', '  net of ~112 obs penalty', ...
    mhm_L + penalty_L, mhm_B + penalty_B, (mhm_L + penalty_L) - (mhm_B + penalty_B));
fprintf(fid, '\n');

print_param_table(L, B, key_params,   'estimated_params (deep structural)',  fid);
print_param_table(L, B, shock_params, 'shock standard deviations',          fid);

fclose(fid);
fprintf('\nSaved report to %s\n', txtfile);

%% ---------------------------------------------------------------
%% 3. Convergence diagnostics
%% ---------------------------------------------------------------
fprintf('--- MCMC convergence diagnostics ---\n');
if isfield(oo_L, 'MetropolisHastings')
    mh_L = oo_L.MetropolisHastings;
    if isfield(mh_L, 'mean_acceptance_rate')
        fprintf('L1.3a mean acceptance rate per chain: ');
        fprintf('%.2f%% ', 100 * mh_L.mean_acceptance_rate);
        fprintf('\n');
    end
elseif isfield(oo_L, 'MarkovChain')
    fprintf('L1.3a acceptance rates: (see oo_.MarkovChain)\n');
end

% Number of MH draws
if isfield(oo_L, 'MetropolisHastings') && isfield(oo_L.MetropolisHastings, 'mh_nblocks')
    fprintf('L1.3a chains: %d x %d draws\n', ...
        oo_L.MetropolisHastings.mh_nblocks, ...
        oo_L.MetropolisHastings.mh_replic);
end

fprintf('\n=== Report complete.  See %s for the saved copy. ===\n', txtfile);

%% ---------------------------------------------------------------
%% Helpers
%% ---------------------------------------------------------------
function print_param_table(L, B, specs, header, fid)
    oo_L = L.oo_;
    oo_B = B.oo_;
    fprintf('\n--- %s ---\n', header);
    fprintf(fid, '\n--- %s ---\n', header);

    hdr = sprintf('%-15s  %20s  %20s  %12s  %s', 'Parameter', ...
        'L1.3a [mean (90%HPD)]', 'baseline [mean (90%HPD)]', 'Δ mean', 'Role');
    fprintf('%s\n', hdr);
    fprintf(fid, '%s\n', hdr);
    fprintf('%s\n', repmat('-', 1, length(hdr)));
    fprintf(fid, '%s\n', repmat('-', 1, length(hdr)));

    for i = 1:size(specs, 1)
        pname = specs{i, 1};
        ptype = specs{i, 2};   % 'param' or 'shock'
        prole = specs{i, 3};

        [mL, lL, uL] = get_post(oo_L, pname, ptype);
        [mB, lB, uB] = get_post(oo_B, pname, ptype);

        if ~isnan(mL) && ~isnan(mB)
            dmean = mL - mB;
            dstr = sprintf('%+11.4f', dmean);
        elseif ~isnan(mL) && isnan(mB)
            dstr = '       NEW ';
        elseif isnan(mL) && ~isnan(mB)
            dstr = '   REMOVED ';
        else
            dstr = '       N/A ';
        end

        sL = fmt_summary(mL, lL, uL);
        sB = fmt_summary(mB, lB, uB);
        line = sprintf('%-15s  %20s  %20s  %s  %s', pname, sL, sB, dstr, prole);
        fprintf('%s\n', line);
        fprintf(fid, '%s\n', line);
    end
end

function [m, l, u] = get_post(oo, pname, ptype)
    m = NaN; l = NaN; u = NaN;
    if strcmp(ptype, 'param')
        if isfield(oo, 'posterior_mean') && isfield(oo.posterior_mean, 'parameters') ...
                && isfield(oo.posterior_mean.parameters, pname)
            m = oo.posterior_mean.parameters.(pname);
        end
        if isfield(oo, 'posterior_hpdinf') && isfield(oo.posterior_hpdinf, 'parameters') ...
                && isfield(oo.posterior_hpdinf.parameters, pname)
            l = oo.posterior_hpdinf.parameters.(pname);
        end
        if isfield(oo, 'posterior_hpdsup') && isfield(oo.posterior_hpdsup, 'parameters') ...
                && isfield(oo.posterior_hpdsup.parameters, pname)
            u = oo.posterior_hpdsup.parameters.(pname);
        end
    elseif strcmp(ptype, 'shock')
        % shock stderrs are under .shocks_std
        if isfield(oo, 'posterior_mean') && isfield(oo.posterior_mean, 'shocks_std') ...
                && isfield(oo.posterior_mean.shocks_std, pname)
            m = oo.posterior_mean.shocks_std.(pname);
        end
        if isfield(oo, 'posterior_hpdinf') && isfield(oo.posterior_hpdinf, 'shocks_std') ...
                && isfield(oo.posterior_hpdinf.shocks_std, pname)
            l = oo.posterior_hpdinf.shocks_std.(pname);
        end
        if isfield(oo, 'posterior_hpdsup') && isfield(oo.posterior_hpdsup, 'shocks_std') ...
                && isfield(oo.posterior_hpdsup.shocks_std, pname)
            u = oo.posterior_hpdsup.shocks_std.(pname);
        end
    end
end

function s = fmt_summary(m, l, u)
    if isnan(m)
        s = '            -        ';
    elseif isnan(l) || isnan(u)
        s = sprintf('%8.4f     N/A   ', m);
    else
        s = sprintf('%7.4f [%6.4f,%6.4f]', m, l, u);
    end
end
