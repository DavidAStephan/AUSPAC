%% run_phase_q_uip.m — Phase Q refresh under forward-looking UIP (2026-05-15)
%
% Pipeline:
%   Stage 1: Posterior mode (~5 min, csminwel)
%   Stage 2: MCMC 20k × 2 chains (~50 min)
%   Stage 3: Extract posterior summary
%   Stage 4: Three-regime IRF regeneration (var, hybrid, mce)
%
% Each stage uses a fresh MATLAB workspace via `clear; clc;` to avoid
% dynare's local-variable bleed. Total wall time: ~60 min.

clear; clc;
cd(fileparts(mfilename('fullpath')));
setup_dynare_path();

logfile = 'phase_q_uip_log.txt';
fid = fopen(logfile, 'w');
fprintf(fid, 'Phase Q (forward-looking UIP) refresh started: %s\n', datestr(now));
fclose(fid);

t_total = tic;

%% Stage 1: Posterior mode
fprintf('=== Stage 1: Posterior mode ===\n');
t_s1 = tic;
try
    run_bayesian_estimation;
    elapsed = toc(t_s1)/60;
    fid = fopen(logfile, 'a');
    fprintf(fid, 'Stage 1 (mode) complete: %.1f min\n', elapsed);
    fclose(fid);
catch ME
    fid = fopen(logfile, 'a');
    fprintf(fid, '!!! Stage 1 FAILED: %s\n', ME.message);
    if ~isempty(ME.stack), fprintf(fid, '  at %s:%d\n', ME.stack(1).name, ME.stack(1).line); end
    fclose(fid);
    rethrow(ME);
end

%% Stage 2: MCMC
fprintf('\n=== Stage 2: MCMC (20k × 2 chains) ===\n');
clear; clc;
cd(fileparts(mfilename('fullpath')));
setup_dynare_path();
logfile = 'phase_q_uip_log.txt';
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
    if ~isempty(ME.stack), fprintf(fid, '  at %s:%d\n', ME.stack(1).name, ME.stack(1).line); end
    fclose(fid);
    rethrow(ME);
end

%% Stage 3: Extract posterior
fprintf('\n=== Stage 3: Extract posterior summary ===\n');
clear; clc;
cd(fileparts(mfilename('fullpath')));
setup_dynare_path();
logfile = 'phase_q_uip_log.txt';
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
fprintf(fid, '\nPhase Q refresh complete. Total: %.1f min\n', toc(t_total)/60);
fprintf(fid, 'Finished: %s\n', datestr(now));
fclose(fid);
fprintf('\n=== Phase Q UIP refresh COMPLETE — %.1f min ===\n', toc(t_total)/60);
