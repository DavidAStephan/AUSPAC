%% test_preprocess.m — Diagnose bayesian .mod preprocessing error
clear; clc;
addpath('C:\dynare\6.5\matlab');
cd('c:\Users\david\french_model\dynare');

fid = fopen('log_preprocess_test.txt', 'w');
fprintf(fid, 'Preprocessing test: %s\n\n', datestr(now));

try
    dynare au_pac_bayesian noclearall
    fprintf(fid, 'SUCCESS\n');
catch ME
    fprintf(fid, 'ERROR: %s\n', ME.message);
    fprintf(fid, 'Identifier: %s\n\n', ME.identifier);
    for k = 1:length(ME.stack)
        fprintf(fid, '  File: %s\n', ME.stack(k).file);
        fprintf(fid, '  Name: %s\n', ME.stack(k).name);
        fprintf(fid, '  Line: %d\n\n', ME.stack(k).line);
    end
    % Check if dynare generated any error log
    if exist('au_pac_bayesian/Output/au_pac_bayesian.log', 'file')
        fprintf(fid, '--- Dynare log ---\n');
        log_fid = fopen('au_pac_bayesian/Output/au_pac_bayesian.log', 'r');
        while ~feof(log_fid)
            line = fgetl(log_fid);
            if ischar(line)
                fprintf(fid, '%s\n', line);
            end
        end
        fclose(log_fid);
    end
end
fclose(fid);
