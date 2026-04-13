%% test_smoother_comparison.m
% Compares PAC estimation with 3 dseries approaches:
%   A. RECURSIVE: original prepare_pac_dseries (crude recursive auxiliaries)
%   B. HYBRID: smoothed auxiliary targets + recursive pv_aux corrections
%   C. PURE SMOOTHER: all variables from Kalman smoother
%
% Logs results to test_comparison_log.txt for analysis.

logfile = 'c:/Users/david/french_model/dynare/test_comparison_log.txt';
fid = fopen(logfile, 'w');
fprintf(fid, '=== PAC ESTIMATION: 3-WAY COMPARISON ===\n');
fprintf(fid, 'Timestamp: %s\n\n', datestr(now));
fclose(fid);

try
    addpath('C:/dynare/6.5/matlab');
    cd('c:/Users/david/french_model/dynare');

    %% Pass 1: Dynare preprocessing + companion matrix
    appendlog(logfile, 'Pass 1: dynare au_pac json=compute noclearall...');
    dynare au_pac json=compute noclearall
    appendlog(logfile, sprintf('Pass 1 done: %d endo, %d exo', M_.endo_nbr, M_.exo_nbr));

    if ~isstruct(oo_.var), oo_.var = struct(); end
    get_companion_matrix('esat_enriched', 'var');
    pac_models = {'pac_pQ', 'pac_c', 'pac_ib', 'pac_ih', 'pac_n'};
    for k = 1:length(pac_models)
        pac.initialize(pac_models{k});
        pac.update.expectation(pac_models{k});
    end
    appendlog(logfile, 'Companion matrix + PAC h-vectors built');

    saved_M_ = M_; saved_oo_ = oo_; saved_options_ = options_;

    %% Pass 2: Kalman smoother
    appendlog(logfile, 'Pass 2: Kalman smoother...');
    prepare_smoother_data();
    generate_smoother_mod();
    if exist('smoother_data.m', 'file'), delete('smoother_data.m'); end
    dynare au_pac_smooth noclearall
    oo_smooth = oo_;
    appendlog(logfile, sprintf('Smoother done: %d SmoothedVariables', ...
        length(fieldnames(oo_.SmoothedVariables))));

    % Restore Pass 1 state
    M_ = saved_M_; oo_ = saved_oo_; options_ = saved_options_;
    if ~isstruct(oo_.var), oo_.var = struct(); end
    get_companion_matrix('esat_enriched', 'var');
    for k = 1:length(pac_models)
        pac.initialize(pac_models{k});
        pac.update.expectation(pac_models{k});
    end

    %% Build 3 dseries variants
    appendlog(logfile, '\n--- Building 3 dseries variants ---');

    % A. Recursive (original)
    db_recursive = prepare_pac_dseries();
    appendlog(logfile, 'A. Recursive dseries built');

    % B. Hybrid (smoothed targets + recursive corrections)
    db_hybrid = prepare_pac_dseries_hybrid(oo_smooth);
    appendlog(logfile, 'B. Hybrid dseries built');

    % C. Pure smoother
    db_smooth = prepare_pac_dseries_smooth(oo_smooth);
    appendlog(logfile, 'C. Pure smoother dseries built');

    %% Estimation setup
    start_est = dates('1994Q2');
    end_est   = dates('2023Q3');
    est_range = start_est:end_est;

    %% Run estimation for each approach
    eqs = { ...
        'eq_piQ_pac', struct('b0_pQ',0.06,'b1_pQ',0.50,'b2_pQ',0.09,'b_covid_crash_pQ',0,'b_covid_bounce_pQ',0), 'pac_pQ', 'VA Price'; ...
        'eq_dln_c_pac', struct('b0_c',0.06,'b1_c',0.149,'b2_c',-0.02,'b3_c',0.139,'b_covid_crash_c',0,'b_covid_bounce_c',0), 'pac_c', 'Consumption'; ...
        'eq_dln_ib_pac', struct('b0_ib',0.030,'b1_ib',0.181,'b2_ib',0.10,'b3_ib',0.191,'b_covid_crash_ib',0,'b_covid_bounce_ib',0), 'pac_ib', 'Business Inv'; ...
        'eq_dln_ih_pac', struct('b0_ih',0.049,'b1_ih',0.210,'b2_ih',0.08,'b3_ih',0.12,'b4_ih',-0.05,'b_covid_crash_ih',0,'b_covid_bounce_ih',0), 'pac_ih', 'Household Inv'; ...
        'eq_dln_n_pac', struct('b0_n',0.040,'b1_n',0.30,'b2_n',0.10,'b3_n',0.05,'b4_n',0.02,'b5_n',0.12,'b_covid_crash_n',0,'b_covid_bounce_n',0), 'pac_n', 'Employment'};

    approaches = {'A_Recursive', 'B_Hybrid', 'C_PureSmoother'};
    dbs = {db_recursive, db_hybrid, db_smooth};

    fid = fopen(logfile, 'a');
    fprintf(fid, '\n================================================================\n');
    fprintf(fid, '  ESTIMATION RESULTS — 3-WAY COMPARISON\n');
    fprintf(fid, '================================================================\n');
    fprintf(fid, '%-15s %-12s %10s ', 'Equation', 'Approach', 'SSR');

    % Print parameter column headers from the first equation
    fprintf(fid, '\n');
    fclose(fid);

    for eq_idx = 1:size(eqs, 1)
        eq_name    = eqs{eq_idx, 1};
        params_init = eqs{eq_idx, 2};
        pac_name   = eqs{eq_idx, 3};
        label      = eqs{eq_idx, 4};
        pnames     = fieldnames(params_init);

        fid = fopen(logfile, 'a');
        fprintf(fid, '\n--- %s (%s) ---\n', label, eq_name);
        fprintf(fid, '%-15s %10s', 'Approach', 'SSR');
        for p = 1:length(pnames), fprintf(fid, ' %12s', pnames{p}); end
        fprintf(fid, '\n');
        fclose(fid);

        for a = 1:length(approaches)
            % Reset parameters to initial values before each estimation
            for p = 1:length(pnames)
                pidx = find(strcmp(pnames{p}, M_.param_names));
                if ~isempty(pidx)
                    M_.params(pidx) = params_init.(pnames{p});
                end
            end

            try
                pac.estimate.iterative_ols(eq_name, params_init, dbs{a}, est_range);
                ssr = oo_.pac.(pac_name).ssr;

                fid = fopen(logfile, 'a');
                fprintf(fid, '%-15s %10.2f', approaches{a}, ssr);
                for p = 1:length(pnames)
                    pidx = find(strcmp(pnames{p}, M_.param_names));
                    fprintf(fid, ' %12.6f', M_.params(pidx));
                end
                fprintf(fid, '\n');
                fclose(fid);
            catch ME
                fid = fopen(logfile, 'a');
                fprintf(fid, '%-15s %10s  FAILED: %s\n', approaches{a}, '---', ME.message);
                fclose(fid);
            end
        end
    end

    % Save all results
    save('pac_comparison_results.mat', 'M_', 'oo_');

    fid = fopen(logfile, 'a');
    fprintf(fid, '\n================================================================\n');
    fprintf(fid, '  COMPARISON COMPLETE: %s\n', datestr(now));
    fprintf(fid, '================================================================\n');
    fclose(fid);

catch ME
    fid = fopen(logfile, 'a');
    fprintf(fid, '\nFATAL ERROR: %s\n', ME.message);
    for k = 1:length(ME.stack)
        fprintf(fid, '  %s (line %d)\n', ME.stack(k).name, ME.stack(k).line);
    end
    fclose(fid);
end

function appendlog(logfile, msg)
    fid = fopen(logfile, 'a');
    fprintf(fid, '%s\n', msg);
    fclose(fid);
end
