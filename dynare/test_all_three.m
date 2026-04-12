%% test_all_three.m
% Compile-test all 3 model variants and report BK conditions.
cd('c:\Users\david\french_model\dynare');
addpath('C:\dynare\6.5\matlab');

fid = fopen('log_test_all_three.txt', 'w');
fprintf(fid, '=== COMPILE TEST: ALL THREE REGIMES ===\n');
fprintf(fid, 'Timestamp: %s\n\n', datestr(now));

models = {'au_pac_var', 'au_pac', 'au_pac_mce'};
labels = {'VAR-based', 'Hybrid', 'Full MCE'};

for m = 1:3
    fprintf(fid, '--- %s (%s.mod) ---\n', labels{m}, models{m});
    try
        eval(['dynare ' models{m} ' noclearall nograph']);
        fprintf(fid, 'STATUS: SUCCESS\n');
        fprintf(fid, 'Forward-looking vars: %d\n', M_.nsfwrd);
        fprintf(fid, 'Predetermined vars: %d\n', M_.npred);
        fprintf(fid, 'Endogenous vars: %d\n', M_.endo_nbr);

        % Extract peak monetary policy IRF
        if isfield(oo_.irfs, 'yhat_au_eps_i')
            irf_y = oo_.irfs.yhat_au_eps_i;
            [pk, pq] = min(irf_y);
            fprintf(fid, 'Output gap peak: %.6f at Q%d\n', pk, pq);
        end
        if isfield(oo_.irfs, 'piQ_eps_i')
            irf_p = oo_.irfs.piQ_eps_i;
            [pk, pq] = min(irf_p);
            fprintf(fid, 'VA price peak: %.6f at Q%d\n', pk, pq);
        end
        fprintf(fid, '\n');
    catch ME
        fprintf(fid, 'STATUS: ERROR\n');
        fprintf(fid, 'Message: %s\n\n', ME.message);
    end
    clear M_ oo_ options_ estim_params_ bayestopt_ dataset_ dataset_info;
end

fclose(fid);
fprintf('Saved: log_test_all_three.txt\n');
