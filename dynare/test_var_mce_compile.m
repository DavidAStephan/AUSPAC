%% test_var_mce_compile.m — Quick check if all 3 variants compile
clear; clc;
addpath('C:\dynare\6.5\matlab');
cd('c:\Users\david\french_model\dynare');

fid = fopen('test_compile_log.txt', 'w');
models = {'au_pac_var', 'au_pac', 'au_pac_mce'};
for k = 1:length(models)
    fprintf(fid, '--- %s ---\n', models{k});
    try
        eval(['dynare ' models{k} ' noclearall nograph']);
        fprintf(fid, 'OK: %d endo, %d exo\n', M_.endo_nbr, M_.exo_nbr);
        % Check if eps_i IRF exists
        if isfield(oo_.irfs, 'yhat_au_eps_i')
            peak = min(oo_.irfs.yhat_au_eps_i);
            fprintf(fid, '  yhat_au_eps_i peak = %.6f\n', peak);
        else
            fprintf(fid, '  WARNING: yhat_au_eps_i not in oo_.irfs\n');
            fprintf(fid, '  Fields: %s\n', strjoin(fieldnames(oo_.irfs), ', '));
        end
    catch ME
        fprintf(fid, 'FAILED: %s\n', ME.message);
        for j = 1:min(5, length(ME.stack))
            fprintf(fid, '  at %s line %d\n', ME.stack(j).name, ME.stack(j).line);
        end
    end
    fprintf(fid, '\n');
end
fclose(fid);
