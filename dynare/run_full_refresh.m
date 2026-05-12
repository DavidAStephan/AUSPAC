%% run_full_refresh.m — Full Bayesian + IRF + table refresh pipeline
%
% Chained execution of Stage 2 MCMC, posterior extraction, and IRF
% regeneration. Run AFTER Stage 1 mode-finding (run_bayesian_estimation.m).
%
% Wall time: ~90 min MCMC + ~2 min IRF generation + post-processing.

clear; clc;
cd(fileparts(mfilename('fullpath')));
setup_dynare_path();

logfile = 'full_refresh_log.txt';
fid = fopen(logfile, 'w');
fprintf(fid, 'Full refresh started: %s\n\n', datestr(now));
fclose(fid);

%% 1. Stage 2 MCMC
fprintf('=== Stage 2: MCMC (20k draws × 2 chains, ~90 min) ===\n');
t_start = tic;
try
    run_bayesian_mcmc;
catch ME
    fprintf('MCMC ERROR: %s\n', ME.message);
    return;
end
fprintf('MCMC elapsed: %.0f min\n', toc(t_start)/60);

%% 2. Extract posterior table
fprintf('\n=== Extracting posterior summary ===\n');
clear; clc;
cd(fileparts(mfilename('fullpath')));
setup_dynare_path();
try
    extract_mcmc_results;
catch ME
    fprintf('Extract ERROR: %s\n', ME.message);
end

%% 3. Regenerate three-regime IRFs
fprintf('\n=== Regenerating IRFs (var, hybrid, mce) ===\n');
clear; clc;
cd(fileparts(mfilename('fullpath')));
setup_dynare_path();

regimes = {'au_pac_var', 'au_pac', 'au_pac_mce'};
tags = {'var', 'hybrid', 'mce'};
for r = 1:3
    fprintf('\n--- [%d/3] %s ---\n', r, regimes{r});
    try
        evalin('base', 'clear M_ oo_ options_');
        eval(['dynare ' regimes{r} ' noclearall nograph']);
        irfs_struct = oo_.irfs;
        % Wrap in correctly-named variable for compatibility with regen_*.py
        switch tags{r}
            case 'var',    irfs_var = irfs_struct;    save('saved_irfs_var.mat', 'irfs_var');
            case 'hybrid', irfs_hybrid = irfs_struct; save('saved_irfs_hybrid.mat', 'irfs_hybrid');
            case 'mce',    irfs_mce = irfs_struct;    save('saved_irfs_mce.mat', 'irfs_mce');
        end
        fprintf('  saved_irfs_%s.mat written\n', tags{r});
    catch ME
        fprintf('  ERROR: %s\n', ME.message);
    end
end

fprintf('\n=== Full refresh complete: %s ===\n', datestr(now));
