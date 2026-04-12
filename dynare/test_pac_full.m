%% test_pac_full.m — Full 5-equation PAC estimation test
clear; clc;
addpath('C:\dynare\6.5\matlab');
cd('c:\Users\david\french_model\dynare');

fid = fopen('test_pac_full_output.txt', 'w');
fprintf(fid, 'Full PAC Estimation Test - %s\n\n', datestr(now));

%% Run Dynare
dynare au_pac json=compute noclearall
fprintf(fid, 'Dynare OK: %d endo, %d exo\n', M_.endo_nbr, M_.exo_nbr);

%% Fix oo_.var and build companion matrix
if ~isstruct(oo_.var)
    oo_.var = struct();
end
get_companion_matrix('esat_enriched', 'var');
CM = oo_.var.esat_enriched.CompanionMatrix;
fprintf(fid, 'Companion matrix: %dx%d\n', size(CM,1), size(CM,2));

pac_names = {'pac_pQ', 'pac_c', 'pac_ib', 'pac_ih', 'pac_n'};
for k = 1:length(pac_names)
    pac.initialize(pac_names{k});
    pac.update.expectation(pac_names{k});
end
fprintf(fid, 'All PAC models initialized\n\n');

%% Build dseries
db = prepare_pac_dseries();
fprintf(fid, 'dseries: %d vars x %d obs\n\n', db.vobs, db.nobs);

start_est = dates('1994Q2');
end_est   = dates('2023Q3');
est_range = start_est:end_est;

%% 1. VA Price PAC
fprintf(fid, '=== 1. VA PRICE PAC (eq_piQ_pac) ===\n');
p = struct('b0_pQ', 0.06, 'b1_pQ', 0.50, 'b2_pQ', 0.09);
try
    pac.estimate.iterative_ols('eq_piQ_pac', p, db, est_range);
    est = oo_.pac.pac_pQ.estimator;
    fprintf(fid, 'SSR=%.4f T=%d\n', oo_.pac.pac_pQ.ssr, length(oo_.pac.pac_pQ.residual));
    pn = fieldnames(p);
    for j=1:length(pn), fprintf(fid, '  %s: %.4f -> %.4f\n', pn{j}, p.(pn{j}), est(j)); end
catch ME
    fprintf(fid, 'FAIL: %s\n  at %s:%d\n', ME.message, ME.stack(1).name, ME.stack(1).line);
end

%% 2. Consumption PAC
fprintf(fid, '\n=== 2. CONSUMPTION PAC (eq_dln_c_pac) ===\n');
p = struct('b0_c', 0.06, 'b1_c', 0.149, 'b2_c', -0.02, 'b3_c', 0.139);
try
    pac.estimate.iterative_ols('eq_dln_c_pac', p, db, est_range);
    est = oo_.pac.pac_c.estimator;
    fprintf(fid, 'SSR=%.4f T=%d\n', oo_.pac.pac_c.ssr, length(oo_.pac.pac_c.residual));
    pn = fieldnames(p);
    for j=1:length(pn), fprintf(fid, '  %s: %.4f -> %.4f\n', pn{j}, p.(pn{j}), est(j)); end
catch ME
    fprintf(fid, 'FAIL: %s\n  at %s:%d\n', ME.message, ME.stack(1).name, ME.stack(1).line);
end

%% 3. Business Investment PAC
fprintf(fid, '\n=== 3. BUSINESS INVESTMENT PAC (eq_dln_ib_pac) ===\n');
p = struct('b0_ib', 0.030, 'b1_ib', 0.181, 'b2_ib', 0.10, 'b3_ib', 0.191);
try
    pac.estimate.iterative_ols('eq_dln_ib_pac', p, db, est_range);
    est = oo_.pac.pac_ib.estimator;
    fprintf(fid, 'SSR=%.4f T=%d\n', oo_.pac.pac_ib.ssr, length(oo_.pac.pac_ib.residual));
    pn = fieldnames(p);
    for j=1:length(pn), fprintf(fid, '  %s: %.4f -> %.4f\n', pn{j}, p.(pn{j}), est(j)); end
catch ME
    fprintf(fid, 'FAIL: %s\n  at %s:%d\n', ME.message, ME.stack(1).name, ME.stack(1).line);
end

%% 4. Household Investment PAC
fprintf(fid, '\n=== 4. HOUSEHOLD INVESTMENT PAC (eq_dln_ih_pac) ===\n');
p = struct('b0_ih', 0.049, 'b1_ih', 0.210, 'b2_ih', 0.08, 'b3_ih', 0.12, 'b4_ih', -0.05);
try
    pac.estimate.iterative_ols('eq_dln_ih_pac', p, db, est_range);
    est = oo_.pac.pac_ih.estimator;
    fprintf(fid, 'SSR=%.4f T=%d\n', oo_.pac.pac_ih.ssr, length(oo_.pac.pac_ih.residual));
    pn = fieldnames(p);
    for j=1:length(pn), fprintf(fid, '  %s: %.4f -> %.4f\n', pn{j}, p.(pn{j}), est(j)); end
catch ME
    fprintf(fid, 'FAIL: %s\n  at %s:%d\n', ME.message, ME.stack(1).name, ME.stack(1).line);
end

%% 5. Employment PAC
fprintf(fid, '\n=== 5. EMPLOYMENT PAC (eq_dln_n_pac) ===\n');
p = struct('b0_n', 0.040, 'b1_n', 0.30, 'b2_n', 0.10, 'b3_n', 0.05, 'b4_n', 0.02, 'b5_n', 0.12);
try
    pac.estimate.iterative_ols('eq_dln_n_pac', p, db, est_range);
    est = oo_.pac.pac_n.estimator;
    fprintf(fid, 'SSR=%.4f T=%d\n', oo_.pac.pac_n.ssr, length(oo_.pac.pac_n.residual));
    pn = fieldnames(p);
    for j=1:length(pn), fprintf(fid, '  %s: %.4f -> %.4f\n', pn{j}, p.(pn{j}), est(j)); end
catch ME
    fprintf(fid, 'FAIL: %s\n  at %s:%d\n', ME.message, ME.stack(1).name, ME.stack(1).line);
end

fprintf(fid, '\n=== DONE ===\n');
fclose(fid);
