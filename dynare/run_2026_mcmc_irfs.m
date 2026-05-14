%% run_2026_mcmc_irfs.m — Stage 2 MCMC + IRF regen from Stage 1 mode
% Stage 1 (mode finding) already completed at 16:09 with LMD=-803.31.

clear; clc;
cd(fileparts(mfilename('fullpath')));
setup_dynare_path();

logfile = '2026_refresh_log.txt';
fid = fopen(logfile, 'a');
fprintf(fid, '\n--- Resuming pipeline after Stage 1 (mode at LMD=-803.31) ---\n');
fprintf(fid, 'Stage 2 MCMC + Stage 4 IRFs launching at %s\n', datestr(now));
fclose(fid);

t0 = tic;

%% Stage 2: MCMC
fprintf('=== Stage 2: MCMC (20k draws × 2 chains) ===\n');
t_s2 = tic;
try
    run_bayesian_mcmc;
    elapsed = toc(t_s2)/60;
    fid = fopen(logfile, 'a');
    fprintf(fid, 'Stage 2 (MCMC) complete: %.1f min\n', elapsed);
    fclose(fid);
catch ME
    fid = fopen(logfile, 'a');
    fprintf(fid, '!!! Stage 2 FAILED: %s\n', ME.message);
    if ~isempty(ME.stack), fprintf(fid, '  Stack: %s line %d\n', ME.stack(1).name, ME.stack(1).line); end
    fclose(fid);
    rethrow(ME);
end

%% Stage 3: Extract posterior summary
fprintf('\n=== Extracting posterior summary ===\n');
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
fprintf(fid, '\nStage 2 + IRFs complete. Total: %.1f min\n', toc(t0)/60);
fprintf(fid, 'Finished: %s\n', datestr(now));
fclose(fid);
fprintf('\n=== STAGE 2 + IRFS COMPLETE — %.1f min ===\n', toc(t0)/60);
