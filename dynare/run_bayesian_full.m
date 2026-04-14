%% run_bayesian_full.m — Regenerate + run both Bayesian stages
%
% After Phase 1-3 parameter updates, regenerate au_pac_bayesian.mod from
% the updated au_pac.mod, then run:
%   Stage 1: Posterior mode via csminwel (mode_compute=4)
%   Stage 2: MCMC (20k draws, 2 chains) from the mode
%
% Now estimates 28 params (was 27): added gamma_w (CPI indexation in wage Phillips)

clear; clc;
addpath('C:\dynare\6.5\matlab');
cd('c:\Users\david\french_model\dynare');

logfile = 'log_bayesian_full.txt';
fid = fopen(logfile, 'w');
fprintf(fid, '================================================================\n');
fprintf(fid, '  BAYESIAN ESTIMATION (Phases 1-3 updated model)\n');
fprintf(fid, '  %s\n', datestr(now));
fprintf(fid, '================================================================\n\n');

%% Step 1: Prepare data
fprintf(fid, '--- Step 1: Preparing estimation data ---\n');
fclose(fid);
prepare_bayesian_data();
fid = fopen(logfile, 'a');
fprintf(fid, '  estimation_data.mat ready\n\n');

%% Step 2: Regenerate au_pac_bayesian.mod (Stage 1 config)
fprintf(fid, '--- Step 2: Regenerating au_pac_bayesian.mod ---\n');
fclose(fid);
generate_bayesian_mod();
fid = fopen(logfile, 'a');
fprintf(fid, '  au_pac_bayesian.mod generated (Stage 1: mode_compute=4, mh_replic=0)\n');
fprintf(fid, '  Now includes gamma_w in estimated_params (28 total)\n\n');

%% Step 3: Run Stage 1 — posterior mode
fprintf(fid, '--- Step 3: Stage 1 — posterior mode (csminwel) ---\n');
fprintf(fid, '  28 params: 19 structural + 9 shock std devs\n');
fprintf(fid, '  Start: %s\n\n', datestr(now));
fclose(fid);

try
    dynare au_pac_bayesian noclearall

    fid = fopen(logfile, 'a');
    fprintf(fid, '  Stage 1 COMPLETE: %s\n', datestr(now));

    if isfield(oo_, 'MarginalDensity') && isfield(oo_.MarginalDensity, 'LaplaceApproximation')
        fprintf(fid, '  Log marginal density (Laplace): %.4f\n', oo_.MarginalDensity.LaplaceApproximation);
    end

    % Log mode values
    if isfield(oo_, 'posterior_mode') && isfield(oo_.posterior_mode, 'parameters')
        pf = fieldnames(oo_.posterior_mode.parameters);
        fprintf(fid, '\n  Posterior modes:\n');
        fprintf(fid, '  %-20s %10s\n', 'Parameter', 'Mode');
        for k = 1:length(pf)
            fprintf(fid, '  %-20s %+10.4f\n', pf{k}, oo_.posterior_mode.parameters.(pf{k}));
        end
    end
    if isfield(oo_, 'posterior_mode') && isfield(oo_.posterior_mode, 'shocks_std')
        sf = fieldnames(oo_.posterior_mode.shocks_std);
        for k = 1:length(sf)
            fprintf(fid, '  %-20s %10.4f (std dev)\n', sf{k}, oo_.posterior_mode.shocks_std.(sf{k}));
        end
    end
    fprintf(fid, '\n');
    fclose(fid);

catch ME
    fid = fopen(logfile, 'a');
    fprintf(fid, '  Stage 1 FAILED: %s\n', ME.message);
    for k = 1:length(ME.stack)
        fprintf(fid, '    %s:%d\n', ME.stack(k).name, ME.stack(k).line);
    end
    fprintf(fid, '\n  ABORTING — fix errors before Stage 2.\n');
    fclose(fid);
    error('Stage 1 failed: %s', ME.message);
end

%% Step 4: Configure for Stage 2 and run MCMC
fid = fopen(logfile, 'a');
fprintf(fid, '--- Step 4: Configuring Stage 2 (MCMC) ---\n');
fclose(fid);

% Read the bayesian .mod file and switch to Stage 2 config
mod_file = 'au_pac_bayesian.mod';
mod_text = fileread(mod_file);

% Replace mode_compute=4 with mode_compute=0
mod_text = strrep(mod_text, 'mode_compute=4,', 'mode_compute=0,');
% Add mode_file
mod_text = strrep(mod_text, 'mode_compute=0,', ...
    ['mode_compute=0,' char(10) '           mode_file=''au_pac_bayesian/Output/au_pac_bayesian_mode'',']);
% Replace mh_replic=0 with mh_replic=20000
mod_text = strrep(mod_text, 'mh_replic=0,', ...
    ['mh_replic=20000,' char(10) '           mh_nblocks=2,' char(10) '           mh_jscale=0.3,']);
% Remove estimated_params_init(use_calibration) + its end; — incompatible with mode_file
mod_text = strrep(mod_text, ...
    ['estimated_params_init(use_calibration);' char(10) 'end;'], ...
    ['// estimated_params_init(use_calibration);  // disabled for Stage 2' char(10) '// end;  // disabled for Stage 2']);

% Write back
fid_mod = fopen(mod_file, 'w');
fprintf(fid_mod, '%s', mod_text);
fclose(fid_mod);

fid = fopen(logfile, 'a');
fprintf(fid, '  Switched to Stage 2: mode_compute=0, mode_file, mh_replic=20000\n');
fprintf(fid, '\n--- Step 5: Stage 2 — MCMC (20k draws, 2 chains) ---\n');
fprintf(fid, '  Start: %s\n\n', datestr(now));
fclose(fid);

% Clear Dynare state for fresh run
clearvars -except logfile;
clearvars -global M_ oo_ options_ estim_params_ bayestopt_ dataset_ dataset_info;

try
    dynare au_pac_bayesian noclearall

    fid = fopen(logfile, 'a');
    fprintf(fid, '  Stage 2 COMPLETE: %s\n\n', datestr(now));

    % Posterior means + HPD intervals
    if isfield(oo_, 'posterior_mean') && isfield(oo_.posterior_mean, 'parameters')
        fprintf(fid, '  %-22s %10s %10s %12s %12s\n', 'Parameter', 'Post.Mean', 'Post.Mode', 'HPD_inf', 'HPD_sup');
        fprintf(fid, '  %s\n', repmat('-', 1, 68));

        pf = fieldnames(oo_.posterior_mean.parameters);
        for k = 1:length(pf)
            pname = pf{k};
            pmean = oo_.posterior_mean.parameters.(pname);
            pmode = NaN;
            if isfield(oo_.posterior_mode, 'parameters') && isfield(oo_.posterior_mode.parameters, pname)
                pmode = oo_.posterior_mode.parameters.(pname);
            end
            hlo = NaN; hhi = NaN;
            if isfield(oo_, 'posterior_hpdinf') && isfield(oo_.posterior_hpdinf, 'parameters')
                if isfield(oo_.posterior_hpdinf.parameters, pname), hlo = oo_.posterior_hpdinf.parameters.(pname); end
            end
            if isfield(oo_, 'posterior_hpdsup') && isfield(oo_.posterior_hpdsup, 'parameters')
                if isfield(oo_.posterior_hpdsup.parameters, pname), hhi = oo_.posterior_hpdsup.parameters.(pname); end
            end
            fprintf(fid, '  %-22s %10.4f %10.4f [%10.4f, %10.4f]\n', pname, pmean, pmode, hlo, hhi);
        end

        % Shocks
        if isfield(oo_.posterior_mean, 'shocks_std')
            sf = fieldnames(oo_.posterior_mean.shocks_std);
            fprintf(fid, '\n  %-22s %10s %10s %12s %12s\n', 'Shock std dev', 'Post.Mean', 'Post.Mode', 'HPD_inf', 'HPD_sup');
            fprintf(fid, '  %s\n', repmat('-', 1, 68));
            for k = 1:length(sf)
                sname = sf{k};
                smean = oo_.posterior_mean.shocks_std.(sname);
                smode = NaN;
                if isfield(oo_.posterior_mode, 'shocks_std') && isfield(oo_.posterior_mode.shocks_std, sname)
                    smode = oo_.posterior_mode.shocks_std.(sname);
                end
                hlo = NaN; hhi = NaN;
                if isfield(oo_, 'posterior_hpdinf') && isfield(oo_.posterior_hpdinf, 'shocks_std')
                    if isfield(oo_.posterior_hpdinf.shocks_std, sname), hlo = oo_.posterior_hpdinf.shocks_std.(sname); end
                end
                if isfield(oo_, 'posterior_hpdsup') && isfield(oo_.posterior_hpdsup, 'shocks_std')
                    if isfield(oo_.posterior_hpdsup.shocks_std, sname), hhi = oo_.posterior_hpdsup.shocks_std.(sname); end
                end
                fprintf(fid, '  %-22s %10.4f %10.4f [%10.4f, %10.4f]\n', sname, smean, smode, hlo, hhi);
            end
        end
    end

    % Marginal density
    if isfield(oo_, 'MarginalDensity')
        fprintf(fid, '\n  Model comparison:\n');
        if isfield(oo_.MarginalDensity, 'LaplaceApproximation')
            fprintf(fid, '    Laplace LMD:           %.4f\n', oo_.MarginalDensity.LaplaceApproximation);
        end
        if isfield(oo_.MarginalDensity, 'ModifiedHarmonicMean')
            fprintf(fid, '    Modified Harmonic Mean: %.4f\n', oo_.MarginalDensity.ModifiedHarmonicMean);
        end
    end

    % Acceptance rates
    if isfield(oo_, 'AcceptanceRate')
        fprintf(fid, '\n  Acceptance rates:\n');
        for b = 1:length(oo_.AcceptanceRate)
            fprintf(fid, '    Chain %d: %.1f%%\n', b, oo_.AcceptanceRate(b)*100);
        end
    end

catch ME
    fid = fopen(logfile, 'a');
    fprintf(fid, '  Stage 2 FAILED: %s\n', ME.message);
    for k = 1:length(ME.stack)
        fprintf(fid, '    %s:%d\n', ME.stack(k).name, ME.stack(k).line);
    end
end

%% Save
save('bayesian_full_results.mat', 'M_', 'oo_', 'options_');
fid = fopen(logfile, 'a');
fprintf(fid, '\n  Results: bayesian_full_results.mat\n');
fprintf(fid, '\n================================================================\n');
fprintf(fid, '  COMPLETE: %s\n', datestr(now));
fprintf(fid, '================================================================\n');
fclose(fid);

fprintf('\n=== Bayesian estimation complete — see log_bayesian_full.txt ===\n');
