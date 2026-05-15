%% run_2026_irfs_only.m — Regenerate three-regime IRFs + extract MCMC summary
% Stage 2 completed at 16:58 with MHM = -803.23.  Stage 4 needs re-running
% because run_2026_mcmc_irfs.m had a clear/scoping bug.

clear; clc;
cd(fileparts(mfilename('fullpath')));
setup_dynare_path();

logfile = '2026_refresh_log.txt';
fid = fopen(logfile, 'a');
fprintf(fid, '\n--- Stage 4: IRFs (after Stage 2 success, MHM=-803.23) ---\n');
fprintf(fid, 'Launching at %s\n', datestr(now));
fclose(fid);

t0 = tic;

%% Extract MCMC results
try
    extract_mcmc_results;
catch ME
    fid = fopen(logfile, 'a');
    fprintf(fid, 'WARN: extract_mcmc_results failed: %s\n', ME.message);
    fclose(fid);
end

%% Three-regime IRFs
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
fprintf(fid, '\nStage 4 complete. Elapsed: %.1f min\n', toc(t0)/60);
fprintf(fid, 'Finished: %s\n', datestr(now));
fclose(fid);
fprintf('\n=== IRFS COMPLETE — %.1f min ===\n', toc(t0)/60);
