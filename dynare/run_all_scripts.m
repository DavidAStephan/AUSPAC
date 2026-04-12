%% run_all_scripts.m
% Master script: runs all documentation generation scripts and saves
% all console output to log files that can be read back.
%
% Output files:
%   log_three_regime_irfs.txt
%   log_extract_hvectors.txt
%   log_dynamic_contributions.txt
%   log_estimation_tables.txt

cd('c:\Users\david\french_model\dynare');
addpath('C:\dynare\6.5\matlab');

%% Step 1: Three-regime IRF comparison
diary('log_three_regime_irfs.txt');
diary on;
fprintf('=== LOG START: generate_three_regime_irfs.m ===\n');
fprintf('Timestamp: %s\n\n', datestr(now));
try
    run('generate_three_regime_irfs.m');
    fprintf('\n=== COMPLETED SUCCESSFULLY ===\n');
catch ME
    fprintf('\n=== ERROR: %s ===\n', ME.message);
    fprintf('Stack:\n');
    for k = 1:length(ME.stack)
        fprintf('  %s (line %d)\n', ME.stack(k).name, ME.stack(k).line);
    end
end
diary off;

%% Step 2: h-vector extraction (needs au_pac loaded)
% Run au_pac first to populate oo_ and M_
fprintf('Running au_pac.mod for h-vector extraction...\n');
dynare au_pac noclearall nograph;

diary('log_extract_hvectors.txt');
diary on;
fprintf('=== LOG START: extract_pac_hvectors.m ===\n');
fprintf('Timestamp: %s\n\n', datestr(now));
try
    run('extract_pac_hvectors.m');
    fprintf('\n=== COMPLETED SUCCESSFULLY ===\n');
catch ME
    fprintf('\n=== ERROR: %s ===\n', ME.message);
    for k = 1:length(ME.stack)
        fprintf('  %s (line %d)\n', ME.stack(k).name, ME.stack(k).line);
    end
end
diary off;

%% Step 3: Dynamic contributions (needs au_pac loaded — already is)
diary('log_dynamic_contributions.txt');
diary on;
fprintf('=== LOG START: generate_dynamic_contributions.m ===\n');
fprintf('Timestamp: %s\n\n', datestr(now));
try
    run('generate_dynamic_contributions.m');
    fprintf('\n=== COMPLETED SUCCESSFULLY ===\n');
catch ME
    fprintf('\n=== ERROR: %s ===\n', ME.message);
    for k = 1:length(ME.stack)
        fprintf('  %s (line %d)\n', ME.stack(k).name, ME.stack(k).line);
    end
end
diary off;

%% Step 4: Estimation tables (needs au_pac loaded — already is)
diary('log_estimation_tables.txt');
diary on;
fprintf('=== LOG START: generate_estimation_tables.m ===\n');
fprintf('Timestamp: %s\n\n', datestr(now));
try
    run('generate_estimation_tables.m');
    fprintf('\n=== COMPLETED SUCCESSFULLY ===\n');
catch ME
    fprintf('\n=== ERROR: %s ===\n', ME.message);
    for k = 1:length(ME.stack)
        fprintf('  %s (line %d)\n', ME.stack(k).name, ME.stack(k).line);
    end
end
diary off;

fprintf('\n\n=== ALL SCRIPTS COMPLETE ===\n');
fprintf('Log files saved:\n');
fprintf('  log_three_regime_irfs.txt\n');
fprintf('  log_extract_hvectors.txt\n');
fprintf('  log_dynamic_contributions.txt\n');
fprintf('  log_estimation_tables.txt\n');
