%% run_2026_aux_figs.m — refresh MATLAB-driven figures after the FR-BDF 2026 refresh
%
% Five figures still pre-recalibration; each driver writes its own .png.
%
% Wall time estimate: ~15-25 min total (forecast_eval is the slow one).

clear; clc;
cd(fileparts(mfilename('fullpath')));
setup_dynare_path();

logfile = '2026_refresh_log.txt';
fid = fopen(logfile, 'a');
fprintf(fid, '\n--- Auxiliary figure refresh launched at %s ---\n', datestr(now));
fclose(fid);

t0 = tic;

%% 1. Sectoral validation (~1 min)
fprintf('\n=== Sectoral validation ===\n');
try
    sectoral_validation;
catch ME
    fprintf('WARN sectoral_validation: %s\n', ME.message);
end

%% 2. Forward guidance (Phase L extended to N=12, ~3 min)
fprintf('\n=== Forward guidance (v2, N up to 12) ===\n');
clear; clc;
cd(fileparts(mfilename('fullpath')));
setup_dynare_path();
try
    forward_guidance_v2;
catch ME
    fprintf('WARN forward_guidance_v2: %s\n', ME.message);
end

%% 3. Identification analysis (~1 min)
fprintf('\n=== Identification analysis (prior/posterior) ===\n');
clear; clc;
cd(fileparts(mfilename('fullpath')));
setup_dynare_path();
try
    identification_analysis;
catch ME
    fprintf('WARN identification_analysis: %s\n', ME.message);
end

%% 4. Forecast evaluation (24 origins, slow, ~10-15 min)
fprintf('\n=== Forecast evaluation (24 origins, 2018Q1-2023Q4) ===\n');
clear; clc;
cd(fileparts(mfilename('fullpath')));
setup_dynare_path();
try
    forecast_eval;
catch ME
    fprintf('WARN forecast_eval: %s\n', ME.message);
end

fid = fopen('2026_refresh_log.txt', 'a');
fprintf(fid, 'Auxiliary figure refresh complete. Elapsed: %.1f min\n', toc(t0)/60);
fprintf(fid, 'Finished: %s\n', datestr(now));
fclose(fid);
fprintf('\n=== AUX FIGS COMPLETE — %.1f min ===\n', toc(t0)/60);
