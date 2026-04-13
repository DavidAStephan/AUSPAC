%% test_smoother_step1.m
% Step-by-step test of the smoother pipeline.
% Logs everything to test_smoother_log.txt for monitoring.

logfile = 'c:/Users/david/french_model/dynare/test_smoother_log.txt';
fid = fopen(logfile, 'w');
fprintf(fid, 'Step 1 test started: %s\n', datestr(now));
fclose(fid);

try
    addpath('C:/dynare/6.5/matlab');
    cd('c:/Users/david/french_model/dynare');

    % Step A: Prepare smoother data
    fid = fopen(logfile, 'a'); fprintf(fid, 'Step A: prepare_smoother_data...\n'); fclose(fid);
    prepare_smoother_data();
    fid = fopen(logfile, 'a'); fprintf(fid, 'Step A done: smoother_data.m created\n'); fclose(fid);

    % Step B: Generate au_pac_smooth.mod (must regenerate to pick up fixes)
    fid = fopen(logfile, 'a'); fprintf(fid, 'Step B: generate_smoother_mod...\n'); fclose(fid);
    generate_smoother_mod();
    fid = fopen(logfile, 'a'); fprintf(fid, 'Step B done: au_pac_smooth.mod created\n'); fclose(fid);

    % Delete smoother_data.m to avoid ambiguity (Dynare will use .mat)
    if exist('smoother_data.m', 'file'), delete('smoother_data.m'); end

    % Step C: Run Dynare Pass 1 (preprocessing + stoch_simul)
    fid = fopen(logfile, 'a'); fprintf(fid, 'Step C: dynare au_pac json=compute noclearall...\n'); fclose(fid);
    dynare au_pac json=compute noclearall
    fid = fopen(logfile, 'a');
    fprintf(fid, 'Step C done: M_.endo_nbr=%d, M_.exo_nbr=%d\n', M_.endo_nbr, M_.exo_nbr);
    fclose(fid);

    % Step D: Build companion matrix
    fid = fopen(logfile, 'a'); fprintf(fid, 'Step D: companion matrix...\n'); fclose(fid);
    if ~isstruct(oo_.var)
        oo_.var = struct();
    end
    get_companion_matrix('esat_enriched', 'var');
    CM = oo_.var.esat_enriched.CompanionMatrix;
    fid = fopen(logfile, 'a');
    fprintf(fid, 'Step D done: CM %dx%d, finite=%d\n', size(CM,1), size(CM,2), all(isfinite(CM(:))));
    fclose(fid);

    % Step E: Initialize PAC models
    fid = fopen(logfile, 'a'); fprintf(fid, 'Step E: PAC initialization...\n'); fclose(fid);
    pac_models = {'pac_pQ', 'pac_c', 'pac_ib', 'pac_ih', 'pac_n'};
    for k = 1:length(pac_models)
        pac.initialize(pac_models{k});
        pac.update.expectation(pac_models{k});
    end
    fid = fopen(logfile, 'a'); fprintf(fid, 'Step E done: all PAC models initialized\n'); fclose(fid);

    % Save Pass 1 state
    save('pass1_results.mat', 'M_', 'oo_', 'options_');
    saved_M_ = M_;
    saved_oo_ = oo_;
    saved_options_ = options_;
    fid = fopen(logfile, 'a'); fprintf(fid, 'Pass 1 state saved\n'); fclose(fid);

    % Step F: Run calib_smoother
    fid = fopen(logfile, 'a'); fprintf(fid, 'Step F: dynare au_pac_smooth noclearall...\n'); fclose(fid);
    dynare au_pac_smooth noclearall
    fid = fopen(logfile, 'a');
    if isfield(oo_, 'SmoothedVariables')
        sv_fields = fieldnames(oo_.SmoothedVariables);
        fprintf(fid, 'Step F done: SmoothedVariables has %d fields\n', length(sv_fields));
        % Print first few field names
        for k = 1:min(10, length(sv_fields))
            fprintf(fid, '  field %d: %s\n', k, sv_fields{k});
        end
    else
        fprintf(fid, 'Step F: WARNING - no SmoothedVariables field in oo_\n');
        oo_fields = fieldnames(oo_);
        fprintf(fid, '  oo_ fields: %s\n', strjoin(oo_fields, ', '));
    end
    fclose(fid);

    % Save smoother results
    oo_smooth = oo_;
    save('smoother_results.mat', 'oo_smooth');

    % Step G: Restore Pass 1 and run estimation
    fid = fopen(logfile, 'a'); fprintf(fid, 'Step G: restoring Pass 1 + estimation...\n'); fclose(fid);
    M_ = saved_M_;
    oo_ = saved_oo_;
    options_ = saved_options_;

    % Rebuild companion matrix
    if ~isstruct(oo_.var)
        oo_.var = struct();
    end
    get_companion_matrix('esat_enriched', 'var');
    for k = 1:length(pac_models)
        pac.initialize(pac_models{k});
        pac.update.expectation(pac_models{k});
    end

    % Build dseries from smoothed variables
    db = prepare_pac_dseries_smooth(oo_smooth);
    fid = fopen(logfile, 'a'); fprintf(fid, 'Step G done: dseries built from smoothed vars\n'); fclose(fid);

    % Step H: Run PAC iterative OLS estimation
    start_est = dates('1994Q2');
    end_est   = dates('2023Q3');
    est_range = start_est:end_est;

    fid = fopen(logfile, 'a'); fprintf(fid, '\nStep H: PAC iterative OLS estimation...\n'); fclose(fid);

    % VA Price — also log auxiliary var stats
    fid = fopen(logfile, 'a');
    pq_vars = {'pQ_level', 'piQ_hat', 'piQ', 'pv_piQ_aux', 'yhat_au', 'eps_pQ'};
    fprintf(fid, '  VA Price dseries check:\n');
    db_varnames = db.name;
    for ev = 1:length(pq_vars)
        vn = pq_vars{ev};
        if any(strcmp(vn, db_varnames))
            vals = db.(vn).data;
            fprintf(fid, '    %s: NaN=%d, zeros=%d, std=%.4f, range=[%.4f, %.4f]\n', ...
                vn, sum(isnan(vals)), sum(vals==0), std(vals, 'omitnan'), min(vals), max(vals));
        else
            fprintf(fid, '    %s: MISSING\n', vn);
        end
    end
    fclose(fid);

    params_pQ = struct('b0_pQ', 0.06, 'b1_pQ', 0.50, 'b2_pQ', 0.09);
    try
        pac.estimate.iterative_ols('eq_piQ_pac', params_pQ, db, est_range);
        fid = fopen(logfile, 'a');
        fprintf(fid, '  VA Price: SSR=%.4f, iters=%d\n', oo_.pac.pac_pQ.ssr, ...
            length(oo_.pac.pac_pQ.estimator));
        log_param(fid, 'b0_pQ', M_);
        log_param(fid, 'b1_pQ', M_);
        log_param(fid, 'b2_pQ', M_);
        fclose(fid);
    catch ME
        fid = fopen(logfile, 'a'); fprintf(fid, '  VA Price FAILED: %s\n', ME.message); fclose(fid);
    end

    % Consumption
    params_c = struct('b0_c', 0.06, 'b1_c', 0.149, 'b2_c', -0.02, 'b3_c', 0.139);
    try
        pac.estimate.iterative_ols('eq_dln_c_pac', params_c, db, est_range);
        fid = fopen(logfile, 'a');
        fprintf(fid, '  Consumption: SSR=%.4f\n', oo_.pac.pac_c.ssr);
        log_param(fid, 'b0_c', M_);
        log_param(fid, 'b1_c', M_);
        log_param(fid, 'b2_c', M_);
        log_param(fid, 'b3_c', M_);
        fclose(fid);
    catch ME
        fid = fopen(logfile, 'a'); fprintf(fid, '  Consumption FAILED: %s\n', ME.message); fclose(fid);
    end

    % Business Investment
    params_ib = struct('b0_ib', 0.030, 'b1_ib', 0.181, 'b2_ib', 0.10, 'b3_ib', 0.191);
    try
        pac.estimate.iterative_ols('eq_dln_ib_pac', params_ib, db, est_range);
        fid = fopen(logfile, 'a');
        fprintf(fid, '  Business Inv: SSR=%.4f\n', oo_.pac.pac_ib.ssr);
        log_param(fid, 'b0_ib', M_);
        log_param(fid, 'b1_ib', M_);
        log_param(fid, 'b2_ib', M_);
        log_param(fid, 'b3_ib', M_);
        fclose(fid);
    catch ME
        fid = fopen(logfile, 'a'); fprintf(fid, '  Business Inv FAILED: %s\n', ME.message); fclose(fid);
    end

    % Household Investment
    params_ih = struct('b0_ih', 0.049, 'b1_ih', 0.210, 'b2_ih', 0.08, ...
                       'b3_ih', 0.12, 'b4_ih', -0.05);
    try
        pac.estimate.iterative_ols('eq_dln_ih_pac', params_ih, db, est_range);
        fid = fopen(logfile, 'a');
        fprintf(fid, '  Household Inv: SSR=%.4f\n', oo_.pac.pac_ih.ssr);
        log_param(fid, 'b0_ih', M_);
        log_param(fid, 'b1_ih', M_);
        log_param(fid, 'b2_ih', M_);
        log_param(fid, 'b3_ih', M_);
        log_param(fid, 'b4_ih', M_);
        fclose(fid);
    catch ME
        fid = fopen(logfile, 'a'); fprintf(fid, '  Household Inv FAILED: %s\n', ME.message); fclose(fid);
    end

    % Employment — diagnose missing variables first
    fid = fopen(logfile, 'a');
    emp_vars = {'ln_n_level', 'n_hat', 'dln_n', 'dln_n_1', 'dln_n_2', 'dln_n_3', ...
                'pv_n_aux', 'yhat_au', 'eps_n'};
    fprintf(fid, '  Employment dseries check:\n');
    db_varnames = db.name;
    for ev = 1:length(emp_vars)
        vn = emp_vars{ev};
        in_db = any(strcmp(vn, db_varnames));
        if in_db
            vals = db.(vn).data;
            n_nan = sum(isnan(vals));
            n_zero = sum(vals == 0);
            fprintf(fid, '    %s: present, NaN=%d, zeros=%d, range=[%.3f, %.3f]\n', ...
                vn, n_nan, n_zero, min(vals), max(vals));
        else
            fprintf(fid, '    %s: MISSING from dseries\n', vn);
        end
    end
    fclose(fid);

    params_n = struct('b0_n', 0.040, 'b1_n', 0.30, 'b2_n', 0.10, ...
                      'b3_n', 0.05, 'b4_n', 0.02, 'b5_n', 0.12);
    try
        pac.estimate.iterative_ols('eq_dln_n_pac', params_n, db, est_range);
        fid = fopen(logfile, 'a');
        fprintf(fid, '  Employment: SSR=%.4f\n', oo_.pac.pac_n.ssr);
        log_param(fid, 'b0_n', M_);
        log_param(fid, 'b1_n', M_);
        log_param(fid, 'b2_n', M_);
        log_param(fid, 'b3_n', M_);
        log_param(fid, 'b4_n', M_);
        log_param(fid, 'b5_n', M_);
        fclose(fid);
    catch ME
        fid = fopen(logfile, 'a');
        fprintf(fid, '  Employment FAILED: %s\n', ME.message);
        fprintf(fid, '  Stack:\n');
        for sk = 1:length(ME.stack)
            fprintf(fid, '    %s (line %d)\n', ME.stack(sk).name, ME.stack(sk).line);
        end
        fclose(fid);
    end

    % Save final results
    save('pac_smooth_estimation_results.mat', 'M_', 'oo_');
    fid = fopen(logfile, 'a');
    fprintf(fid, '\n=== ALL STEPS COMPLETE ===\n');
    fprintf(fid, 'Finished: %s\n', datestr(now));
    fclose(fid);

catch ME
    fid = fopen(logfile, 'a');
    fprintf(fid, '\nFATAL ERROR: %s\n', ME.message);
    fprintf(fid, 'Stack:\n');
    for k = 1:length(ME.stack)
        fprintf(fid, '  %s (line %d)\n', ME.stack(k).name, ME.stack(k).line);
    end
    fclose(fid);
end

function log_param(fid, name, M_)
    idx = find(strcmp(name, M_.param_names));
    if ~isempty(idx)
        fprintf(fid, '    %s = %.6f\n', name, M_.params(idx));
    end
end
