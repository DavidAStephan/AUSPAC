function generate_bayesian_mod(stage)
%% generate_bayesian_mod.m
% Generates au_pac_bayesian.mod from au_pac.mod by:
%   1. Inserting varobs declaration before the model block
%   2. Inserting estimated_params block after the shocks block
%   3. Replacing stoch_simul with estimation() command
%
% Priors are centered on iterative OLS estimates (2026-04-14, hybrid+COVID+AU companion).
% Parameters fixed at calibrated values are not estimated.
%
% Two-stage approach:
%   Stage 1: mode_compute=4 (csminwel) — find posterior mode (~5 min)
%   Stage 2: mode_compute=0, mode_file, mh_replic=20000, mh_nblocks=2 — MCMC (~1-2 hours)
%
% USAGE:
%   generate_bayesian_mod       % Stage 1 (default)
%   generate_bayesian_mod(1)    % Stage 1: mode-finding
%   generate_bayesian_mod(2)    % Stage 2: MCMC from saved mode

if nargin < 1, stage = 1; end
assert(ismember(stage, [1 2]), 'stage must be 1 or 2');

fprintf('=== Generating au_pac_bayesian.mod (Stage %d) ===\n', stage);

moddir = pwd;  % caller cd's to dynare/ before invoking (post-cleanup fix)
infile  = fullfile(moddir, 'au_pac.mod');
outfile = fullfile(moddir, 'au_pac_bayesian.mod');

% Read source
fid = fopen(infile, 'r');
lines = {};
while ~feof(fid)
    lines{end+1} = fgetl(fid); %#ok<AGROW>
end
fclose(fid);

% Process lines
outlines = {};
varobs_inserted = false;
estparams_inserted = false;
stochsim_replaced = false;
varfix_inserted = false;

for k = 1:length(lines)
    ln = lines{k};

    % Fix oo_.var before first pac.initialize (noclearall preserves stoch_simul's double)
    if ~varfix_inserted && ~isempty(strfind(ln, 'pac.initialize('))
        outlines{end+1} = 'if exist(''oo_'', ''var'') && isfield(oo_, ''var'') && ~isstruct(oo_.var), oo_.var = struct(); end';
        varfix_inserted = true;
    end

    % 1. Insert varobs just before 'model;'
    if ~varobs_inserted && strcmp(strtrim(ln), 'model;')
        outlines{end+1} = '';
        outlines{end+1} = '// Observable variables for Bayesian estimation (auto-generated)';
        outlines{end+1} = '// 9 observables matching estimation_data.mat columns';
        outlines{end+1} = 'varobs yhat_au pi_au i_au yhat_us pi_us pi_w dln_c dln_ib i_10y;';
        outlines{end+1} = '';
        varobs_inserted = true;
    end

    % 2. Insert estimated_params after 'end;' of shocks block
    %    Detect the end of shocks by looking for 'end;' after we've seen 'shocks;'
    if ~estparams_inserted && strcmp(strtrim(ln), 'end;')
        % Check if previous non-empty lines contained 'stderr' (shocks block)
        is_shocks_end = false;
        for j = max(1, k-5):k-1
            if contains(lines{j}, 'stderr') && contains(lines{j}, 'eps_')
                is_shocks_end = true;
                break;
            end
        end
        if is_shocks_end
            outlines{end+1} = ln;  % write the 'end;'
            outlines{end+1} = '';
            outlines{end+1} = '// ===================================================================';
            outlines{end+1} = '// ESTIMATED PARAMETERS WITH PRIORS (auto-generated)';
            outlines{end+1} = '// Priors centered on iterative OLS + Bayesian posteriors (2026-04-14)';
            outlines{end+1} = '// ===================================================================';
            outlines{end+1} = 'estimated_params;';
            outlines{end+1} = '    // --- VA Price PAC ---';
            outlines{end+1} = '    b0_pQ,      beta_pdf,       0.03,   0.015;';
            outlines{end+1} = '    b1_pQ,      beta_pdf,       0.29,   0.10;';
            outlines{end+1} = '    b2_pQ,      normal_pdf,     0.00,   0.05;';
            outlines{end+1} = '    // --- Consumption PAC ---';
            outlines{end+1} = '    b0_c,       beta_pdf,       0.07,   0.03;';
            outlines{end+1} = '    b1_c,       beta_pdf,       0.05,   0.03;';
            outlines{end+1} = '    b2_c,       normal_pdf,    -0.55,   0.20;   // OLS=-0.555, prior centered on OLS';
            outlines{end+1} = '    b3_c,       normal_pdf,     0.02,   0.05;';
            outlines{end+1} = '    // --- Business Investment PAC ---';
            outlines{end+1} = '    b0_ib,      beta_pdf,       0.02,   0.01;';
            outlines{end+1} = '    b1_ib,      beta_pdf,       0.09,   0.05;   // OLS=0.093';
            outlines{end+1} = '    b3_ib,      normal_pdf,     0.34,   0.10;   // OLS=0.344, strong accelerator';
            outlines{end+1} = '    // --- Household Investment PAC ---';
            outlines{end+1} = '    b0_ih,      beta_pdf,       0.03,   0.015;';
            outlines{end+1} = '    b1_ih,      beta_pdf,       0.11,   0.05;';
            outlines{end+1} = '    b3_ih,      normal_pdf,     0.23,   0.10;   // OLS=0.231';
            outlines{end+1} = '    // --- Employment PAC ---';
            outlines{end+1} = '    b0_n,       beta_pdf,       0.06,   0.03;   // OLS=0.062';
            outlines{end+1} = '    b1_n,       beta_pdf,       0.31,   0.10;   // OLS=0.315';
            outlines{end+1} = '    b5_n,       normal_pdf,     0.00,   0.05;';
            outlines{end+1} = '    // --- E-SAT / supply block ---';
            outlines{end+1} = '    lambda_w,   beta_pdf,       0.25,   0.10;   // posterior=0.225, away from 0.55 prior';
            outlines{end+1} = '    gamma_w,    beta_pdf,       0.70,   0.15;   // posterior=0.770, very strong AU CPI indexation';
            outlines{end+1} = '    kappa_w,    normal_pdf,     0.08,   0.05;   // posterior=0.080';
            outlines{end+1} = '    // --- Shock standard deviations ---';
            outlines{end+1} = '    stderr eps_q,       inv_gamma_pdf,  0.80,  inf;';
            outlines{end+1} = '    stderr eps_i,       inv_gamma_pdf,  0.10,  inf;';
            outlines{end+1} = '    stderr eps_pi,      inv_gamma_pdf,  0.60,  inf;';
            outlines{end+1} = '    stderr eps_c,       inv_gamma_pdf,  0.50,  inf;';
            outlines{end+1} = '    stderr eps_ib,      inv_gamma_pdf,  1.50,  inf;';
            outlines{end+1} = '    stderr eps_ih,      inv_gamma_pdf,  2.00,  inf;';
            outlines{end+1} = '    stderr eps_n,       inv_gamma_pdf,  0.50,  inf;';
            outlines{end+1} = '    stderr eps_w,       inv_gamma_pdf,  0.30,  inf;';
            outlines{end+1} = '    stderr eps_10y,     inv_gamma_pdf,  0.10,  inf;';
            outlines{end+1} = 'end;';
            outlines{end+1} = '';
            if stage == 1
                outlines{end+1} = '// Use calibrated values as starting point (guarantees BK at initial eval)';
                outlines{end+1} = 'estimated_params_init(use_calibration);';
                outlines{end+1} = 'end;';
            else
                outlines{end+1} = '// Stage 2: estimated_params_init(use_calibration) NOT compatible with mode_file';
                outlines{end+1} = '// Starting values come from mode file instead';
            end
            estparams_inserted = true;
            continue;  % skip the original 'end;' (already written above)
        end
    end

    % 3. Replace stoch_simul with estimation command
    if ~stochsim_replaced && contains(ln, 'stoch_simul(')
        outlines{end+1} = '// stoch_simul replaced by estimation (auto-generated)';
        outlines{end+1} = '// diffuse_filter needed for unit root processes (level accumulators)';
        if stage == 1
            outlines{end+1} = '// Stage 1: posterior mode via csminwel';
            outlines{end+1} = 'estimation(datafile=''estimation_data.mat'',';
            outlines{end+1} = '           first_obs=1,';
            outlines{end+1} = '           mode_compute=4,';
            outlines{end+1} = '           presample=4,';
            outlines{end+1} = '           mh_replic=0,';
            outlines{end+1} = '           diffuse_filter,';
            outlines{end+1} = '           nograph)';
            outlines{end+1} = '           yhat_au pi_au i_au yhat_us pi_us pi_w dln_c dln_ib i_10y;';
        else
            outlines{end+1} = '// Stage 2: MCMC from saved posterior mode';
            outlines{end+1} = 'estimation(datafile=''estimation_data.mat'',';
            outlines{end+1} = '           first_obs=1,';
            outlines{end+1} = '           mode_compute=0,';
            outlines{end+1} = '           mode_file=''au_pac_bayesian/Output/au_pac_bayesian_mode'',';
            outlines{end+1} = '           presample=4,';
            outlines{end+1} = '           mh_replic=20000,';
            outlines{end+1} = '           mh_nblocks=2,';
            outlines{end+1} = '           mh_jscale=0.4,';
            outlines{end+1} = '           diffuse_filter,';
            outlines{end+1} = '           nograph)';
            outlines{end+1} = '           yhat_au pi_au i_au yhat_us pi_us pi_w dln_c dln_ib i_10y;';
        end
        stochsim_replaced = true;
        skip_until_semi = ~contains(ln, ';');  % flag: skip continuation lines
        continue;
    end
    % Skip stoch_simul continuation lines until semicolon found
    if exist('skip_until_semi', 'var') && skip_until_semi
        if contains(ln, ';'), skip_until_semi = false; end
        continue;
    end

    % Skip the commented-out estimation infrastructure (we replaced it above)
    if contains(ln, 'ESTIMATION INFRASTRUCTURE')
        % Skip all remaining commented-out lines
        outlines{end+1} = '// (Estimation infrastructure activated above — original comments removed)';
        break;
    end

    outlines{end+1} = ln;
end

% Write output
fid = fopen(outfile, 'w');
for k = 1:length(outlines)
    fprintf(fid, '%s\n', outlines{k});
end
fclose(fid);

if stage == 1, stage_str = 'mode-finding'; else, stage_str = 'MCMC'; end
fprintf('  Stage: %d (%s)\n', stage, stage_str);
fprintf('  varobs inserted: %d\n', varobs_inserted);
fprintf('  estimated_params inserted: %d\n', estparams_inserted);
fprintf('  stoch_simul replaced: %d\n', stochsim_replaced);
fprintf('  Output: %s\n', outfile);
fprintf('=== au_pac_bayesian.mod generated (Stage %d) ===\n', stage);

end
