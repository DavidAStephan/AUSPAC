%% run_final_wrapper.m
% Re-run full pipeline after b4_ih removal.

logfile = 'c:/Users/david/french_model/dynare/matlab_final_log.txt';
fid = fopen(logfile, 'w');
fprintf(fid, 'Final run started: %s\n', datestr(now));
fclose(fid);

try
    cd('c:/Users/david/french_model/dynare');
    addpath('C:/dynare/6.5/matlab');
    estimate_pac_smooth_driver;

    fid = fopen(logfile, 'a');
    fprintf(fid, '\nFINAL RUN COMPLETED SUCCESSFULLY: %s\n', datestr(now));
    fclose(fid);
catch ME
    fid = fopen(logfile, 'a');
    fprintf(fid, '\nERROR: %s\n', ME.message);
    fprintf(fid, 'Identifier: %s\n', ME.identifier);
    for k = 1:length(ME.stack)
        fprintf(fid, '  File: %s, Line: %d, Function: %s\n', ...
            ME.stack(k).file, ME.stack(k).line, ME.stack(k).name);
    end
    fclose(fid);
end
