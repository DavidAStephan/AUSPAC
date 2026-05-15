%% run_bayesian_mcmc.m — Stage 2: MCMC from saved posterior mode
%
% Runs Metropolis-Hastings MCMC (20,000 draws, 2 chains) starting from
% the posterior mode found in Stage 1 (au_pac_bayesian_mode.mat).
%
% Prerequisites:
%   - Stage 1 completed: au_pac_bayesian/Output/au_pac_bayesian_mode.mat exists
%   - estimation_data.mat exists (from prepare_bayesian_data)
%   - au_pac_bayesian.mod configured with mh_replic=20000, mode_compute=0
%
% Output:
%   - Posterior distributions (oo_.posterior_mean, oo_.posterior_hpdinf, oo_.posterior_hpdsup)
%   - Convergence diagnostics (Brooks-Gelman PSRF)
%   - MCMC chain files in au_pac_bayesian/metropolis/
%   - Log: bayesian_mcmc_log.txt

clear; clc;
cd(fileparts(mfilename('fullpath')));
setup_dynare_path();

logfile = 'bayesian_mcmc_log.txt';
fid = fopen(logfile, 'w');

fprintf(fid, '================================================================\n');
fprintf(fid, '  AU_PAC BAYESIAN ESTIMATION — Stage 2: MCMC\n');
fprintf(fid, '  Started: %s\n', datestr(now));
fprintf(fid, '================================================================\n\n');

%% Verify prerequisites
fprintf(fid, '--- Checking prerequisites ---\n');

mode_file = 'au_pac_bayesian/Output/au_pac_bayesian_mode.mat';
if ~exist(mode_file, 'file')
    fprintf(fid, 'ERROR: Mode file not found: %s\n', mode_file);
    fprintf(fid, 'Run Stage 1 first (run_bayesian_estimation.m)\n');
    fclose(fid);
    error('Mode file not found. Run Stage 1 first.');
end
fprintf(fid, '  Mode file: OK (%s)\n', mode_file);

if ~exist('estimation_data.mat', 'file')
    fprintf(fid, '  estimation_data.mat not found — regenerating...\n');
    prepare_bayesian_data();
end
fprintf(fid, '  Estimation data: OK\n');

% Load mode file to log starting point
mode_data = load(mode_file);
if isfield(mode_data, 'xparam1')
    fprintf(fid, '  Mode vector: %d parameters\n', length(mode_data.xparam1));
    fprintf(fid, '  Log posterior at mode: %.4f\n', -mode_data.fval);
end
fprintf(fid, '\n');

%% Generate Stage 2 .mod file
fprintf(fid, '--- Generating au_pac_bayesian.mod (Stage 2) ---\n');
generate_bayesian_mod(2);
fprintf(fid, '  au_pac_bayesian.mod regenerated with mode_compute=0, mh_replic=20000\n\n');

%% Run MCMC
fprintf(fid, '--- Running MCMC (mh_replic=20000, mh_nblocks=2) ---\n');
fprintf(fid, '  Expected runtime: 30-90 min depending on model complexity\n');
fprintf(fid, '  Start: %s\n\n', datestr(now));
fclose(fid);

try
    dynare au_pac_bayesian noclearall

    fid = fopen(logfile, 'a');
    fprintf(fid, '\n--- MCMC COMPLETE ---\n');
    fprintf(fid, '  Finished: %s\n\n', datestr(now));

    %% Extract posterior results
    fprintf(fid, '================================================================\n');
    fprintf(fid, '  Posterior Results (Table 5.7)\n');
    fprintf(fid, '================================================================\n\n');

    % Posterior means and HPD intervals
    if isfield(oo_, 'posterior_mean')
        fprintf(fid, '%-22s %10s %10s %12s %12s\n', ...
            'Parameter', 'Post.Mean', 'Post.Mode', 'HPD_inf', 'HPD_sup');
        fprintf(fid, '%s\n', repmat('-', 1, 68));

        if isfield(oo_.posterior_mean, 'parameters')
            pfields = fieldnames(oo_.posterior_mean.parameters);
            for k = 1:length(pfields)
                pname = pfields{k};
                pmean = oo_.posterior_mean.parameters.(pname);

                % Mode
                pmode = NaN;
                if isfield(oo_, 'posterior_mode') && isfield(oo_.posterior_mode, 'parameters')
                    if isfield(oo_.posterior_mode.parameters, pname)
                        pmode = oo_.posterior_mode.parameters.(pname);
                    end
                end

                % HPD intervals
                hpd_lo = NaN; hpd_hi = NaN;
                if isfield(oo_, 'posterior_hpdinf') && isfield(oo_.posterior_hpdinf, 'parameters')
                    if isfield(oo_.posterior_hpdinf.parameters, pname)
                        hpd_lo = oo_.posterior_hpdinf.parameters.(pname);
                    end
                end
                if isfield(oo_, 'posterior_hpdsup') && isfield(oo_.posterior_hpdsup, 'parameters')
                    if isfield(oo_.posterior_hpdsup.parameters, pname)
                        hpd_hi = oo_.posterior_hpdsup.parameters.(pname);
                    end
                end

                fprintf(fid, '%-22s %10.4f %10.4f [%10.4f, %10.4f]\n', ...
                    pname, pmean, pmode, hpd_lo, hpd_hi);
            end
        end

        % Shock std devs
        if isfield(oo_.posterior_mean, 'shocks_std')
            sfields = fieldnames(oo_.posterior_mean.shocks_std);
            fprintf(fid, '\n%-22s %10s %10s %12s %12s\n', ...
                'Shock std dev', 'Post.Mean', 'Post.Mode', 'HPD_inf', 'HPD_sup');
            fprintf(fid, '%s\n', repmat('-', 1, 68));
            for k = 1:length(sfields)
                sname = sfields{k};
                smean = oo_.posterior_mean.shocks_std.(sname);

                smode = NaN;
                if isfield(oo_, 'posterior_mode') && isfield(oo_.posterior_mode, 'shocks_std')
                    if isfield(oo_.posterior_mode.shocks_std, sname)
                        smode = oo_.posterior_mode.shocks_std.(sname);
                    end
                end

                hpd_lo = NaN; hpd_hi = NaN;
                if isfield(oo_, 'posterior_hpdinf') && isfield(oo_.posterior_hpdinf, 'shocks_std')
                    if isfield(oo_.posterior_hpdinf.shocks_std, sname)
                        hpd_lo = oo_.posterior_hpdinf.shocks_std.(sname);
                    end
                end
                if isfield(oo_, 'posterior_hpdsup') && isfield(oo_.posterior_hpdsup, 'shocks_std')
                    if isfield(oo_.posterior_hpdsup.shocks_std, sname)
                        hpd_hi = oo_.posterior_hpdsup.shocks_std.(sname);
                    end
                end

                fprintf(fid, '%-22s %10.4f %10.4f [%10.4f, %10.4f]\n', ...
                    sname, smean, smode, hpd_lo, hpd_hi);
            end
        end
    end

    %% Log marginal density
    if isfield(oo_, 'MarginalDensity')
        fprintf(fid, '\n--- Model comparison ---\n');
        if isfield(oo_.MarginalDensity, 'LaplaceApproximation')
            fprintf(fid, '  Log marginal density (Laplace):           %.4f\n', ...
                oo_.MarginalDensity.LaplaceApproximation);
        end
        if isfield(oo_.MarginalDensity, 'ModifiedHarmonicMean')
            fprintf(fid, '  Log marginal density (Mod. Harmonic Mean): %.4f\n', ...
                oo_.MarginalDensity.ModifiedHarmonicMean);
        end
    end

    %% Convergence diagnostics
    fprintf(fid, '\n--- Convergence diagnostics ---\n');
    if isfield(oo_, 'convergence') && isfield(oo_.convergence, 'gelman_rubin')
        fprintf(fid, '  Brooks-Gelman multivariate PSRF available\n');
    end

    % Acceptance rates
    if isfield(oo_, 'AcceptanceRate')
        for b = 1:length(oo_.AcceptanceRate)
            fprintf(fid, '  Chain %d acceptance rate: %.1f%%\n', b, oo_.AcceptanceRate(b)*100);
        end
        mean_ar = mean(oo_.AcceptanceRate);
        fprintf(fid, '  Mean acceptance rate: %.1f%%\n', mean_ar*100);
        if mean_ar < 0.20
            fprintf(fid, '  WARNING: Low acceptance rate — consider reducing mh_jscale\n');
        elseif mean_ar > 0.40
            fprintf(fid, '  WARNING: High acceptance rate — consider increasing mh_jscale\n');
        else
            fprintf(fid, '  Acceptance rate in target range (20-40%%)\n');
        end
    end

catch ME
    fid = fopen(logfile, 'a');
    fprintf(fid, '\nERROR: %s\n', ME.message);
    fprintf(fid, 'Identifier: %s\n', ME.identifier);
    for k = 1:length(ME.stack)
        fprintf(fid, '  %s:%d (%s)\n', ME.stack(k).file, ME.stack(k).line, ME.stack(k).name);
    end
end

%% Save results
save('bayesian_mcmc_results.mat', 'M_', 'oo_', 'options_');
fprintf(fid, '\nResults saved to bayesian_mcmc_results.mat\n');

fprintf(fid, '\n================================================================\n');
fprintf(fid, '  MCMC COMPLETE: %s\n', datestr(now));
fprintf(fid, '================================================================\n');
fclose(fid);

fprintf('\n=== Bayesian MCMC complete — see bayesian_mcmc_log.txt ===\n');
