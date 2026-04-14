%% run_both_wrapper.m
% Run both Bayesian estimation (mode-finding) and conditional forecast.

logfile = 'c:/Users/david/french_model/dynare/matlab_both_log.txt';
fid = fopen(logfile, 'w');
fprintf(fid, 'Started: %s\n', datestr(now));
fclose(fid);

try
    cd('c:/Users/david/french_model/dynare');
    addpath('C:/dynare/6.5/matlab');

    %% Task 1: Generate Bayesian .mod file and run mode-finding
    fid = fopen(logfile, 'a');
    fprintf(fid, '\n=== TASK 1: BAYESIAN ESTIMATION ===\n');
    fclose(fid);

    run_bayesian_estimation;

    fid = fopen(logfile, 'a');
    fprintf(fid, '\nTask 1 complete: %s\n', datestr(now));
    fclose(fid);

catch ME
    fid = fopen(logfile, 'a');
    fprintf(fid, '\nTask 1 ERROR: %s\n', ME.message);
    for k = 1:length(ME.stack)
        fprintf(fid, '  %s:%d (%s)\n', ME.stack(k).file, ME.stack(k).line, ME.stack(k).name);
    end
    fclose(fid);
end

try
    %% Task 2: Conditional forecast
    fid = fopen(logfile, 'a');
    fprintf(fid, '\n=== TASK 2: CONDITIONAL FORECAST ===\n');
    fclose(fid);

    conditional_forecast_driver;

    fid = fopen(logfile, 'a');
    fprintf(fid, '\nTask 2 complete: %s\n', datestr(now));
    fclose(fid);

catch ME
    fid = fopen(logfile, 'a');
    fprintf(fid, '\nTask 2 ERROR: %s\n', ME.message);
    for k = 1:length(ME.stack)
        fprintf(fid, '  %s:%d (%s)\n', ME.stack(k).file, ME.stack(k).line, ME.stack(k).name);
    end
    fclose(fid);
end

fid = fopen(logfile, 'a');
fprintf(fid, '\nAll tasks finished: %s\n', datestr(now));
fclose(fid);
