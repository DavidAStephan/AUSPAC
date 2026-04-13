%% test_pac_pipeline.m — Quick test of PAC estimation pipeline
% Saves diagnostic output to test_pac_output.txt
clear; clc;
addpath('C:\dynare\6.5\matlab');
cd('c:\Users\david\french_model\dynare');

fid = fopen('test_pac_output.txt', 'w');
fprintf(fid, 'PAC Pipeline Test - %s\n\n', datestr(now));

%% Step 1: Run Dynare
fprintf(fid, '--- Step 1: Dynare preprocessing ---\n');
try
    dynare au_pac json=compute noclearall
    fprintf(fid, 'OK: M_.endo_nbr = %d\n', M_.endo_nbr);
    fprintf(fid, 'OK: M_.exo_nbr = %d\n', M_.exo_nbr);
    % Check PAC models
    pm_names = fieldnames(M_.pac);
    for k=1:length(pm_names)
        pm = pm_names{k};
        if isfield(M_.pac.(pm), 'h_param_indices')
            fprintf(fid, 'OK: %s has %d h-params\n', pm, length(M_.pac.(pm).h_param_indices));
        end
    end
catch ME
    fprintf(fid, 'FAIL Dynare: %s\n', ME.message);
    fclose(fid);
    return;
end

%% Step 2: Construct dseries
fprintf(fid, '\n--- Step 2: dseries construction ---\n');
try
    db = prepare_pac_dseries();
    fprintf(fid, 'OK: dseries has %d variables x %d obs\n', db.vobs, db.nobs);
    fprintf(fid, 'Variables: %s\n', strjoin(db.name(1:min(10,db.vobs)), ', '));
catch ME
    fprintf(fid, 'FAIL dseries: %s\n', ME.message);
    for k=1:min(5,length(ME.stack))
        fprintf(fid, '  at %s line %d\n', ME.stack(k).name, ME.stack(k).line);
    end
    fclose(fid);
    return;
end

%% Step 3: Test one iterative OLS call
fprintf(fid, '\n--- Step 3: Test pac.estimate.iterative_ols ---\n');
start_est = dates('1994Q2');
end_est   = dates('2023Q3');
est_range = start_est:end_est;
fprintf(fid, 'Range: %s to %s\n', char(start_est), char(end_est));

params_c = struct();
params_c.b0_c = 0.06;
params_c.b1_c = 0.149;
params_c.b2_c = -0.02;
params_c.b3_c = 0.139;

try
    pac.estimate.iterative_ols('eq_dln_c_pac', params_c, db, est_range);
    fprintf(fid, 'OK: Consumption PAC estimated\n');
    if isfield(oo_.pac, 'pac_c') && isfield(oo_.pac.pac_c, 'estimator')
        est = oo_.pac.pac_c.estimator;
        fprintf(fid, 'SSR = %.6f\n', oo_.pac.pac_c.ssr);
        pnames = fieldnames(params_c);
        for j=1:length(pnames)
            fprintf(fid, '  %s: init=%.4f est=%.4f\n', pnames{j}, params_c.(pnames{j}), est(j));
        end
    end
catch ME
    fprintf(fid, 'FAIL iterative_ols: %s\n', ME.message);
    for k=1:min(5,length(ME.stack))
        fprintf(fid, '  at %s line %d\n', ME.stack(k).name, ME.stack(k).line);
    end
end

fprintf(fid, '\n--- Test complete ---\n');
fclose(fid);
