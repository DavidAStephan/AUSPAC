%% run_bayesian_wrapper.m
logfile = 'c:/Users/david/french_model/dynare/matlab_bayesian_log.txt';
fid = fopen(logfile, 'w');
fprintf(fid, 'Started: %s\n', datestr(now));
fclose(fid);

try
    cd('c:/Users/david/french_model/dynare');
    addpath('C:/dynare/6.5/matlab');
    run_bayesian_estimation;

    fid = fopen(logfile, 'a');
    fprintf(fid, '\nCOMPLETED: %s\n', datestr(now));
    fclose(fid);
catch ME
    fid = fopen(logfile, 'a');
    fprintf(fid, '\nERROR: %s\n', ME.message);
    for k = 1:length(ME.stack)
        fprintf(fid, '  %s:%d (%s)\n', ME.stack(k).file, ME.stack(k).line, ME.stack(k).name);
    end
    fclose(fid);
end
