%% test_pac_pipeline4.m — json=compute + manual companion matrix build
clear; clc;
addpath('C:\dynare\6.5\matlab');
cd('c:\Users\david\french_model\dynare');

fid = fopen('test_pac_output4.txt', 'w');
fprintf(fid, 'PAC Pipeline Test 4 - %s\n\n', datestr(now));

%% Step 1: Run Dynare with json=compute
try
    dynare au_pac json=compute noclearall
    fprintf(fid, 'Dynare OK: %d endo\n', M_.endo_nbr);
catch ME
    fprintf(fid, 'FAIL Dynare: %s\n', ME.message);
    fclose(fid); return;
end

%% Step 2: Check oo_.var type
fprintf(fid, 'oo_.var type: %s\n', class(oo_.var));
if isstruct(oo_.var)
    fprintf(fid, 'oo_.var fields: %s\n', strjoin(fieldnames(oo_.var), ', '));
    if isfield(oo_.var, 'esat_enriched')
        ee_fields = fieldnames(oo_.var.esat_enriched);
        fprintf(fid, 'oo_.var.esat_enriched fields: %s\n', strjoin(ee_fields, ', '));
    end
else
    fprintf(fid, 'oo_.var is NOT a struct (value: %s)\n', mat2str(oo_.var));
end

%% Step 3: Force oo_.var to be a struct and build companion matrix
fprintf(fid, '\n--- Forcing oo_.var to struct and building companion matrix ---\n');
try
    if ~isstruct(oo_.var)
        fprintf(fid, 'Converting oo_.var from %s to struct\n', class(oo_.var));
        oo_.var = struct();
    end
    get_companion_matrix('esat_enriched', 'var');
    fprintf(fid, 'get_companion_matrix OK\n');
    if isfield(oo_.var, 'esat_enriched') && isfield(oo_.var.esat_enriched, 'CompanionMatrix')
        CM = oo_.var.esat_enriched.CompanionMatrix;
        fprintf(fid, 'CompanionMatrix: %dx%d, NaN: %d\n', size(CM,1), size(CM,2), any(isnan(CM(:))));
        fprintf(fid, 'First 5x5 of CompanionMatrix:\n');
        for i=1:min(5,size(CM,1))
            fprintf(fid, '  ');
            for j=1:min(5,size(CM,2))
                fprintf(fid, '%8.4f ', CM(i,j));
            end
            fprintf(fid, '\n');
        end
    end
catch ME
    fprintf(fid, 'FAIL get_companion_matrix: %s\n', ME.message);
    for k=1:min(3,length(ME.stack))
        fprintf(fid, '  at %s line %d\n', ME.stack(k).name, ME.stack(k).line);
    end
end

%% Step 4: Now initialize PAC and update expectations
fprintf(fid, '\n--- PAC initialize + update ---\n');
try
    pac.initialize('pac_c');
    pac.update.expectation('pac_c');
    fprintf(fid, 'pac_c init+update OK\n');
catch ME
    fprintf(fid, 'FAIL: %s\n', ME.message);
end

%% Step 5: Try iterative OLS
fprintf(fid, '\n--- pac.estimate.iterative_ols ---\n');
try
    db = prepare_pac_dseries();
    fprintf(fid, 'dseries: %d vars x %d obs\n', db.vobs, db.nobs);

    start_est = dates('1994Q2');
    end_est   = dates('2023Q3');
    est_range = start_est:end_est;

    params_c = struct();
    params_c.b0_c = 0.06;
    params_c.b1_c = 0.149;
    params_c.b2_c = -0.02;
    params_c.b3_c = 0.139;

    pac.estimate.iterative_ols('eq_dln_c_pac', params_c, db, est_range);
    fprintf(fid, 'SUCCESS!\n');
    if isfield(oo_.pac, 'pac_c') && isfield(oo_.pac.pac_c, 'estimator')
        est = oo_.pac.pac_c.estimator;
        fprintf(fid, 'SSR = %.6f, T = %d\n', oo_.pac.pac_c.ssr, length(oo_.pac.pac_c.residual));
        pnames = fieldnames(params_c);
        for j=1:length(pnames)
            fprintf(fid, '  %s: init=%.4f est=%.4f chg=%+.4f\n', pnames{j}, ...
                params_c.(pnames{j}), est(j), est(j)-params_c.(pnames{j}));
        end
    end
catch ME
    fprintf(fid, 'FAIL: %s\n', ME.message);
    for k=1:min(5,length(ME.stack))
        fprintf(fid, '  at %s line %d\n', ME.stack(k).name, ME.stack(k).line);
    end
end

fprintf(fid, '\n--- Test 4 complete ---\n');
fclose(fid);
