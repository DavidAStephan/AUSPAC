%% run_phase_q_resume.m — resume Phase Q pipeline from Stage 2
% Stage 1 mode-finding completed (LMD Laplace = -801.71). This script runs:
%   Stage 2: MCMC (~50 min)
%   Stage 3: extract posterior
%   Stage 4: three-regime IRFs

clear; clc;
cd(fullfile(fileparts(mfilename('fullpath')), '..', '..'));  % up to dynare/
setup_dynare_path();

logfile = 'phase_q_uip_log.txt';
fid = fopen(logfile, 'a');
fprintf(fid, '\nPhase Q resume (Stage 2+3+4) started: %s\n', datestr(now));
fclose(fid);

t_total = tic;

%% Stage 2: MCMC
fprintf('=== Stage 2: MCMC (20k × 2 chains) ===\n');
try
    run_bayesian_mcmc;
    fid = fopen(logfile, 'a');
    fprintf(fid, 'Stage 2 (MCMC) complete at %s\n', datestr(now));
    fclose(fid);
catch ME
    fid = fopen(logfile, 'a');
    fprintf(fid, '!!! Stage 2 FAILED: %s\n', ME.message);
    if ~isempty(ME.stack), fprintf(fid, '  at %s:%d\n', ME.stack(1).name, ME.stack(1).line); end
    fclose(fid);
    rethrow(ME);
end

%% Stage 3: extract posterior summary
fprintf('\n=== Stage 3: Extract posterior ===\n');
clear; clc;
cd(fullfile(fileparts(mfilename('fullpath')), '..', '..'));  % up to dynare/
setup_dynare_path();
logfile = 'phase_q_uip_log.txt';
try
    extract_mcmc_results;
catch ME
    fid = fopen(logfile, 'a');
    fprintf(fid, 'WARN: extract_mcmc_results failed: %s\n', ME.message);
    fclose(fid);
end

%% Stage 4: three-regime IRFs
fprintf('\n=== Stage 4: Three-regime IRFs ===\n');
clear; clc;
cd(fullfile(fileparts(mfilename('fullpath')), '..', '..'));  % up to dynare/
setup_dynare_path();
logfile = 'phase_q_uip_log.txt';

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
fprintf(fid, '\nPhase Q resume complete. Stages 2+3+4: %.1f min\n', toc(t_total)/60);
fprintf(fid, 'Finished: %s\n', datestr(now));
fclose(fid);
fprintf('\n=== Phase Q resume COMPLETE — %.1f min ===\n', toc(t_total)/60);
