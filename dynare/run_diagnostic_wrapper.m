%% run_diagnostic_wrapper.m
% Wrapper to run diagnostic_ih_nls.m with error capture.

logfile = 'c:/Users/david/french_model/dynare/matlab_diag_log.txt';
fid = fopen(logfile, 'w');
fprintf(fid, 'Diagnostic started: %s\n', datestr(now));
fclose(fid);

try
    cd('c:/Users/david/french_model/dynare');
    addpath('C:/dynare/6.5/matlab');
    diagnostic_ih_nls;

    fid = fopen(logfile, 'a');
    fprintf(fid, '\nDIAGNOSTIC COMPLETED SUCCESSFULLY: %s\n', datestr(now));
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
