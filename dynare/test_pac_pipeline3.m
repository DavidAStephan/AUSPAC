%% test_pac_pipeline3.m — Check oo_ structure after Dynare
clear; clc;
addpath('C:\dynare\6.5\matlab');
cd('c:\Users\david\french_model\dynare');

fid = fopen('test_pac_output3.txt', 'w');
fprintf(fid, 'PAC Pipeline Test 3 - %s\n\n', datestr(now));

%% Step 1: Run Dynare (without json=compute first, to see if that's the issue)
fprintf(fid, '--- Test A: dynare au_pac noclearall (no json) ---\n');
try
    dynare au_pac noclearall
    fprintf(fid, 'Dynare OK\n');
    fprintf(fid, 'oo_ type: %s\n', class(oo_));
    if isfield(oo_, 'var')
        fprintf(fid, 'oo_.var exists, type: %s\n', class(oo_.var));
        if isstruct(oo_.var) && isfield(oo_.var, 'esat_enriched')
            fprintf(fid, 'oo_.var.esat_enriched exists\n');
            if isfield(oo_.var.esat_enriched, 'CompanionMatrix')
                CM = oo_.var.esat_enriched.CompanionMatrix;
                fprintf(fid, 'CompanionMatrix: %dx%d, NaN: %d\n', size(CM,1), size(CM,2), any(isnan(CM(:))));
            else
                fprintf(fid, 'NO CompanionMatrix in oo_.var.esat_enriched\n');
            end
        else
            fprintf(fid, 'NO esat_enriched in oo_.var\n');
        end
    else
        fprintf(fid, 'NO oo_.var field\n');
    end
    % Also check var_model
    if isfield(oo_, 'var_model')
        fprintf(fid, 'oo_.var_model also exists\n');
    end
catch ME
    fprintf(fid, 'FAIL: %s\n', ME.message);
end

%% Step 2: Now try pac.estimate with companion matrix present
fprintf(fid, '\n--- Test B: pac.estimate after successful stoch_simul ---\n');
try
    db = prepare_pac_dseries();
    fprintf(fid, 'dseries OK\n');

    start_est = dates('1994Q2');
    end_est   = dates('2023Q3');
    est_range = start_est:end_est;

    params_c = struct();
    params_c.b0_c = 0.06;
    params_c.b1_c = 0.149;
    params_c.b2_c = -0.02;
    params_c.b3_c = 0.139;

    pac.estimate.iterative_ols('eq_dln_c_pac', params_c, db, est_range);
    fprintf(fid, 'SUCCESS: Consumption PAC estimated!\n');
    if isfield(oo_.pac, 'pac_c') && isfield(oo_.pac.pac_c, 'estimator')
        est = oo_.pac.pac_c.estimator;
        fprintf(fid, 'SSR = %.6f\n', oo_.pac.pac_c.ssr);
        pnames = fieldnames(params_c);
        for j=1:length(pnames)
            fprintf(fid, '  %s: init=%.4f est=%.4f\n', pnames{j}, params_c.(pnames{j}), est(j));
        end
    end
catch ME
    fprintf(fid, 'FAIL: %s\n', ME.message);
    for k=1:min(5,length(ME.stack))
        fprintf(fid, '  at %s line %d\n', ME.stack(k).name, ME.stack(k).line);
    end
end

%% Step 3: If that worked, try json=compute in a fresh run
fprintf(fid, '\n--- Test C: dynare au_pac json=compute noclearall ---\n');
clearvars -except fid
clearvars -global M_ oo_ options_ estim_params_ bayestopt_
try
    dynare au_pac json=compute noclearall
    fprintf(fid, 'Dynare json=compute OK\n');
    if isfield(oo_, 'var')
        fprintf(fid, 'oo_.var exists\n');
    else
        fprintf(fid, 'oo_.var MISSING after json=compute\n');
        fprintf(fid, 'oo_ fields: %s\n', strjoin(fieldnames(oo_), ', '));
    end
catch ME
    fprintf(fid, 'FAIL: %s\n', ME.message);
end

fprintf(fid, '\n--- Test 3 complete ---\n');
fclose(fid);
