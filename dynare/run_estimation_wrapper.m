%% run_estimation_wrapper.m
% Wrapper that captures all output/errors to a log file.
% MATLAB R2019a batch mode doesn't always pipe stdout.

logfile = 'c:/Users/david/french_model/dynare/matlab_run_log.txt';
fid = fopen(logfile, 'w');
fprintf(fid, 'MATLAB started: %s\n', datestr(now));
fprintf(fid, 'Version: %s\n', version);
fprintf(fid, 'Working dir: %s\n\n', pwd);

try
    cd('c:/Users/david/french_model/dynare');
    addpath('C:/dynare/6.5/matlab');
    fprintf(fid, 'Dynare path added. Running estimate_pac_smooth_driver...\n\n');
    fclose(fid);

    % Run the actual pipeline
    estimate_pac_smooth_driver;

    % Re-open log to append success
    fid = fopen(logfile, 'a');
    fprintf(fid, '\n\nPIPELINE COMPLETED SUCCESSFULLY: %s\n', datestr(now));
    fclose(fid);

catch ME
    fid = fopen(logfile, 'a');
    fprintf(fid, '\n\nERROR: %s\n', ME.message);
    fprintf(fid, 'Identifier: %s\n', ME.identifier);
    for k = 1:length(ME.stack)
        fprintf(fid, '  File: %s, Line: %d, Function: %s\n', ...
            ME.stack(k).file, ME.stack(k).line, ME.stack(k).name);
    end
    if ~isempty(ME.cause)
        for c = 1:length(ME.cause)
            fprintf(fid, 'Caused by: %s\n', ME.cause{c}.message);
        end
    end
    fclose(fid);
end
