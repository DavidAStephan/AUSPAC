%% test_pac_pipeline2.m — Diagnose companion matrix issue
clear; clc;
addpath('C:\dynare\6.5\matlab');
cd('c:\Users\david\french_model\dynare');

fid = fopen('test_pac_output2.txt', 'w');
fprintf(fid, 'PAC Pipeline Test 2 - %s\n\n', datestr(now));

%% Step 1: Run Dynare
try
    dynare au_pac json=compute noclearall
    fprintf(fid, 'Dynare OK: %d endo, %d exo\n', M_.endo_nbr, M_.exo_nbr);
catch ME
    fprintf(fid, 'FAIL Dynare: %s\n', ME.message);
    fclose(fid); return;
end

%% Step 2: Check oo_ structure for var_model companion matrix
fprintf(fid, '\n--- Checking oo_ for var_model ---\n');
if isfield(oo_, 'var_model')
    fprintf(fid, 'oo_.var_model exists\n');
    vm_names = fieldnames(oo_.var_model);
    for k=1:length(vm_names)
        fprintf(fid, '  field: %s\n', vm_names{k});
    end
    if isfield(oo_.var_model, 'esat_enriched')
        fprintf(fid, '  esat_enriched exists\n');
        ee_names = fieldnames(oo_.var_model.esat_enriched);
        for k=1:length(ee_names)
            fprintf(fid, '    sub-field: %s\n', ee_names{k});
        end
        if isfield(oo_.var_model.esat_enriched, 'CompanionMatrix')
            CM = oo_.var_model.esat_enriched.CompanionMatrix;
            fprintf(fid, '    CompanionMatrix: %dx%d, any NaN: %d\n', size(CM,1), size(CM,2), any(isnan(CM(:))));
        else
            fprintf(fid, '    NO CompanionMatrix!\n');
        end
    else
        fprintf(fid, '  NO esat_enriched!\n');
    end
else
    fprintf(fid, 'oo_.var_model DOES NOT EXIST\n');
end

%% Step 3: Check M_.pac structure
fprintf(fid, '\n--- Checking M_.pac ---\n');
fprintf(fid, 'pac_c auxiliary_model_type: %s\n', M_.pac.pac_c.auxiliary_model_type);
fprintf(fid, 'pac_c auxiliary_model_name: %s\n', M_.pac.pac_c.auxiliary_model_name);

%% Step 4: Try manually building companion matrix
fprintf(fid, '\n--- Attempting manual companion matrix build ---\n');
try
    % pac.initialize should build the companion matrix
    pac.initialize('pac_c');
    pac.update.expectation('pac_c');
    fprintf(fid, 'pac.initialize + pac.update.expectation OK\n');

    % Check again
    if isfield(oo_.var_model, 'esat_enriched') && isfield(oo_.var_model.esat_enriched, 'CompanionMatrix')
        CM = oo_.var_model.esat_enriched.CompanionMatrix;
        fprintf(fid, 'CompanionMatrix NOW exists: %dx%d\n', size(CM,1), size(CM,2));
    end
catch ME
    fprintf(fid, 'FAIL: %s\n', ME.message);
    for k=1:min(3,length(ME.stack))
        fprintf(fid, '  at %s line %d\n', ME.stack(k).name, ME.stack(k).line);
    end
end

%% Step 5: Now try iterative OLS
fprintf(fid, '\n--- Retrying pac.estimate.iterative_ols ---\n');
try
    db = prepare_pac_dseries();
    fprintf(fid, 'dseries OK: %d vars x %d obs\n', db.vobs, db.nobs);

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

fprintf(fid, '\n--- Test 2 complete ---\n');
fclose(fid);
