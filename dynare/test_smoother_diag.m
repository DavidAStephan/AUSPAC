%% test_smoother_diag.m — Diagnose smoother preprocessing failure
addpath('C:\dynare\6.5\matlab');
cd('c:\Users\david\french_model\dynare');

fid = fopen('smoother_diag_log.txt', 'w');
fprintf(fid, 'Smoother diagnostics: %s\n\n', datestr(now));

% Step 1: Run Pass 1 first (needed for M_, oo_)
fprintf(fid, '--- Pass 1: dynare au_pac ---\n');
try
    dynare au_pac json=compute noclearall
    fprintf(fid, 'Pass 1 OK: %d endo, %d exo\n', M_.endo_nbr, M_.exo_nbr);
catch ME
    fprintf(fid, 'Pass 1 FAILED: %s\n', ME.message);
    fclose(fid);
    return;
end

% Step 2: Prepare smoother data
fprintf(fid, '\n--- Preparing smoother data ---\n');
try
    prepare_smoother_data();
    fprintf(fid, 'smoother_data prepared OK\n');
catch ME
    fprintf(fid, 'prepare_smoother_data FAILED: %s\n', ME.message);
end

% Step 3: Generate smoother mod
fprintf(fid, '\n--- Generating smoother mod ---\n');
try
    generate_smoother_mod();
    fprintf(fid, 'au_pac_smooth.mod generated OK\n');
catch ME
    fprintf(fid, 'generate_smoother_mod FAILED: %s\n', ME.message);
end

% Delete .m data file to avoid ambiguity
if exist('smoother_data.m', 'file'), delete('smoother_data.m'); end

% Step 4: Try running the smoother
fprintf(fid, '\n--- Running dynare au_pac_smooth ---\n');
try
    dynare au_pac_smooth noclearall
    fprintf(fid, 'Smoother OK: %d SmoothedVariables\n', length(fieldnames(oo_.SmoothedVariables)));
catch ME
    fprintf(fid, 'Smoother FAILED: %s\n', ME.message);
    for k = 1:length(ME.stack)
        fprintf(fid, '  at %s line %d\n', ME.stack(k).name, ME.stack(k).line);
    end
    % Check if there's a Dynare-specific error log
    if exist('au_pac_smooth/output/au_pac_smooth.log', 'file')
        fprintf(fid, '\n--- Dynare log (last 30 lines) ---\n');
        loglines = fileread('au_pac_smooth/output/au_pac_smooth.log');
        fprintf(fid, '%s\n', loglines(max(1,end-2000):end));
    end
end

fclose(fid);
fprintf('Diagnostics written to smoother_diag_log.txt\n');
