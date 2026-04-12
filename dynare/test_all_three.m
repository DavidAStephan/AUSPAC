%% test_all_three.m
% Compile-test all 3 model variants and report BK conditions.
% Saves results to temp .mat files between runs to avoid workspace conflicts.
cd('c:\Users\david\french_model\dynare');
addpath('C:\dynare\6.5\matlab');

models = {'au_pac_var', 'au_pac', 'au_pac_mce'};
labels = {'VAR-based', 'Hybrid', 'Full MCE'};

%% Run each model and save results
for m = 1:3
    fprintf('--- Running %s (%s.mod) ---\n', labels{m}, models{m});
    try
        eval(['dynare ' models{m} ' noclearall nograph']);
        result = struct();
        result.status = 'SUCCESS';
        result.nsfwrd = M_.nsfwrd;
        result.npred = M_.npred;
        result.endo_nbr = M_.endo_nbr;
        result.irfs = oo_.irfs;
    catch ME
        result = struct();
        result.status = 'ERROR';
        result.message = ME.message;
        result.irfs = struct();
    end
    save(['temp_test_regime_' num2str(m) '.mat'], 'result');
    % Thorough cleanup: clear everything except loop variables
    clearvars -except models labels m;
    clearvars -global M_ oo_ options_ estim_params_ bayestopt_ dataset_ dataset_info;
end

%% Collect results and write log
fid = fopen('log_test_all_three.txt', 'w');
fprintf(fid, '=== COMPILE TEST: ALL THREE REGIMES ===\n');
fprintf(fid, 'Timestamp: %s\n\n', datestr(now));

for m = 1:3
    tmp = load(['temp_test_regime_' num2str(m) '.mat']);
    r = tmp.result;
    fprintf(fid, '--- %s (%s.mod) ---\n', labels{m}, models{m});
    fprintf(fid, 'STATUS: %s\n', r.status);
    if strcmp(r.status, 'SUCCESS')
        fprintf(fid, 'Forward-looking vars: %d\n', r.nsfwrd);
        fprintf(fid, 'Predetermined vars: %d\n', r.npred);
        fprintf(fid, 'Endogenous vars: %d\n', r.endo_nbr);
        if isfield(r.irfs, 'yhat_au_eps_i')
            [pk, pq] = min(r.irfs.yhat_au_eps_i);
            fprintf(fid, 'Output gap peak: %.6f at Q%d\n', pk, pq);
        end
        if isfield(r.irfs, 'piQ_eps_i')
            [pk, pq] = min(r.irfs.piQ_eps_i);
            fprintf(fid, 'VA price peak: %.6f at Q%d\n', pk, pq);
        end
    else
        fprintf(fid, 'Message: %s\n', r.message);
    end
    fprintf(fid, '\n');
    delete(['temp_test_regime_' num2str(m) '.mat']);
end

fclose(fid);
fprintf('Saved: log_test_all_three.txt\n');
