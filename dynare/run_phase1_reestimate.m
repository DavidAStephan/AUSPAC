%% run_phase1_reestimate.m — Re-run Phase 1 estimation with observable proxies
%
% Uses observed data (HP-filtered gaps) instead of smoother-internal states
% to avoid circularity in auxiliary equation estimation.

clear; clc;
addpath('C:\dynare\6.5\matlab');
cd('c:\Users\david\french_model\dynare');

fid = fopen('log_phase1_reestimate.txt', 'w');
fprintf(fid, '================================================================\n');
fprintf(fid, '  PHASE 1 RE-ESTIMATION (observable proxy approach)\n');
fprintf(fid, '  %s\n', datestr(now));
fprintf(fid, '================================================================\n\n');

%% Step 1: Estimate var_model auxiliaries from observable proxy gaps
fprintf(fid, '--- Step 1: var_model auxiliary equations ---\n');
fclose(fid);

try
    aux_results = estimate_var_auxiliary('smoother_results.mat', 'log_var_auxiliary_estimation.txt');
    fid = fopen('log_phase1_reestimate.txt', 'a');
    fprintf(fid, '  Done. See log_var_auxiliary_estimation.txt\n\n');
catch ME
    fid = fopen('log_phase1_reestimate.txt', 'a');
    fprintf(fid, '  ERROR in estimate_var_auxiliary: %s\n', ME.message);
    for kk = 1:length(ME.stack)
        fprintf(fid, '    %s:%d\n', ME.stack(kk).name, ME.stack(kk).line);
    end
    fprintf(fid, '\n');
    aux_results = struct();
end

%% Step 2: Estimate wage Phillips curve from observed data
fprintf(fid, '--- Step 2: Wage Phillips curve ---\n');
fclose(fid);

try
    wage_results = estimate_wage_phillips('log_wage_phillips_estimation.txt');
    fid = fopen('log_phase1_reestimate.txt', 'a');
    fprintf(fid, '  Done. See log_wage_phillips_estimation.txt\n');
    fprintf(fid, '  Okun: rho_u=%.4f, okun=%.4f\n', wage_results.rho_u_gap, wage_results.okun_coeff);
    fprintf(fid, '  Wage: lw=%.4f, gw=%.4f, kw=%.4f\n\n', ...
        wage_results.lambda_w, wage_results.gamma_w, wage_results.kappa_w);
catch ME
    fid = fopen('log_phase1_reestimate.txt', 'a');
    fprintf(fid, '  ERROR in estimate_wage_phillips: %s\n', ME.message);
    for kk = 1:length(ME.stack)
        fprintf(fid, '    %s:%d\n', ME.stack(kk).name, ME.stack(kk).line);
    end
    fprintf(fid, '\n');
    wage_results = struct();
end

%% Summary
fprintf(fid, '================================================================\n');
fprintf(fid, '  PHASE 1 RE-ESTIMATION COMPLETE: %s\n', datestr(now));
fprintf(fid, '================================================================\n');
fclose(fid);

save('phase1_estimation_results.mat', 'aux_results', 'wage_results');
fprintf('\n=== Phase 1 complete. Results in phase1_estimation_results.mat ===\n');
