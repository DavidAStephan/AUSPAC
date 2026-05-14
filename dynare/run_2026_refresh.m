%% run_2026_refresh.m  —  Full refresh under FR-BDF 2026 CES calibration
%
% Chains the three stages required after a parameter-set change to the
% supply block:
%   1. Stage 1: posterior-mode finding via csminwel (~5 min)
%   2. Stage 2: MCMC (20k draws × 2 chains, ~55 min)
%   3. Three-regime IRF regeneration (~3 min)
%
% Designed to run unattended in the background.

clear; clc;
cd(fileparts(mfilename('fullpath')));
setup_dynare_path();

logfile = '2026_refresh_log.txt';
fid = fopen(logfile, 'w');
fprintf(fid, '================================================================\n');
fprintf(fid, '  AUSPAC FULL REFRESH UNDER FR-BDF 2026 CES CALIBRATION\n');
fprintf(fid, '  Started: %s\n', datestr(now));
fprintf(fid, '  Parameters: alpha_k = 0.45, sigma_ces = 0.5366\n');
fprintf(fid, '              gamma_ulc = 0.2951, gamma_uck = 0.2415\n');
fprintf(fid, '================================================================\n\n');
fclose(fid);

t0 = tic;

%% Stage 1: posterior mode
fprintf('\n=== Stage 1: Posterior mode (mode_compute=4, csminwel) ===\n');
t_s1 = tic;
try
    run_bayesian_estimation;
    fid = fopen(logfile, 'a');
    fprintf(fid, 'Stage 1 (mode) complete: %.0f sec\n', toc(t_s1));
    fclose(fid);
catch ME
    fid = fopen(logfile, 'a');
    fprintf(fid, '!!! Stage 1 FAILED at %s\n', datestr(now));
    fprintf(fid, '  Error: %s\n', ME.message);
    if ~isempty(ME.stack), fprintf(fid, '  Stack: %s line %d\n', ME.stack(1).name, ME.stack(1).line); end
    fclose(fid);
    rethrow(ME);
end

%% Stage 2: MCMC
fprintf('\n=== Stage 2: MCMC (20k draws × 2 chains) ===\n');
clear; clc;
cd(fileparts(mfilename('fullpath')));
setup_dynare_path();
logfile = '2026_refresh_log.txt';

t_s2 = tic;
try
    run_bayesian_mcmc;
    fid = fopen(logfile, 'a');
    fprintf(fid, 'Stage 2 (MCMC) complete: %.0f min\n', toc(t_s2)/60);
    fclose(fid);
catch ME
    fid = fopen(logfile, 'a');
    fprintf(fid, '!!! Stage 2 FAILED at %s\n', datestr(now));
    fprintf(fid, '  Error: %s\n', ME.message);
    if ~isempty(ME.stack), fprintf(fid, '  Stack: %s line %d\n', ME.stack(1).name, ME.stack(1).line); end
    fclose(fid);
    rethrow(ME);
end

%% Stage 3: Extract MCMC posterior summary
fprintf('\n=== Extracting MCMC posterior summary ===\n');
clear; clc;
cd(fileparts(mfilename('fullpath')));
setup_dynare_path();
logfile = '2026_refresh_log.txt';
try
    extract_mcmc_results;
catch ME
    fid = fopen(logfile, 'a');
    fprintf(fid, 'WARN: extract_mcmc_results failed: %s\n', ME.message);
    fclose(fid);
end

%% Stage 4: Three-regime IRFs
fprintf('\n=== Stage 4: Three-regime IRFs (var, hybrid, mce) ===\n');
clear; clc;
cd(fileparts(mfilename('fullpath')));
setup_dynare_path();
logfile = '2026_refresh_log.txt';

regimes = {'au_pac_var', 'au_pac', 'au_pac_mce'};
tags    = {'var',         'hybrid', 'mce'};
t_s3 = tic;
for r = 1:3
    fprintf('\n--- [%d/3] %s ---\n', r, regimes{r});
    try
        evalin('base', 'clear M_ oo_ options_');
        eval(['dynare ' regimes{r} ' noclearall nograph']);
        irfs_struct = oo_.irfs;
        switch tags{r}
            case 'var',    irfs_var = irfs_struct;    save('saved_irfs_var.mat', 'irfs_var');
            case 'hybrid', irfs_hybrid = irfs_struct; save('saved_irfs_hybrid.mat', 'irfs_hybrid');
            case 'mce',    irfs_mce = irfs_struct;    save('saved_irfs_mce.mat', 'irfs_mce');
        end
        fprintf('  saved_irfs_%s.mat written\n', tags{r});
    catch ME
        fid = fopen(logfile, 'a');
        fprintf(fid, 'WARN: IRF regen for %s failed: %s\n', regimes{r}, ME.message);
        fclose(fid);
    end
end

fid = fopen(logfile, 'a');
fprintf(fid, '\nAll stages complete: %.1f min total\n', toc(t0)/60);
fprintf(fid, 'Finished: %s\n', datestr(now));
fclose(fid);
fprintf('\n=== ALL STAGES COMPLETE — %.1f min ===\n', toc(t0)/60);
