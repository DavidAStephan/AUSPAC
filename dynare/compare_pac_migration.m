%% compare_pac_migration.m — Analyze PAC migration: h-vectors vs manual omega
%
% Runs post-migration model (native pac_expectation), then:
%   1. Extracts h-vectors computed by pac_expectation from TCM companion matrix
%   2. Compares effective expectations weights to manual omega parameters
%   3. Prints IRFs to monetary policy shock (eps_i)
%   4. Compares to pre-migration baseline (STATUS.md Stage 11a values)
%
% Key question: Do the h-vectors from pac_expectation() produce different
% expectations weights than the simple omega*target approximation?
% FR-BDF Section 6: forward expectations should amplify monetary transmission.

clear; clc;
addpath('C:\dynare\6.5\matlab');

fprintf('================================================================\n');
fprintf('  PAC Migration Analysis\n');
fprintf('  h-vectors vs manual omega weights\n');
fprintf('================================================================\n\n');

%% Run post-migration model
fprintf('--- Running post-migration model (native pac_expectation) ---\n');
dynare au_pac noclearall nograph;
fprintf('  Model: %d equations (orig), %d variables\n', M_.orig_endo_nbr, M_.endo_nbr);
fprintf('  Preprocessing: OK, BK conditions: verified\n\n');

%% Extract h-vectors from PAC models
fprintf('================================================================\n');
fprintf('  PAC h-vector analysis\n');
fprintf('================================================================\n\n');

pac_names = {'pac_pQ', 'pac_c', 'pac_ib', 'pac_ih', 'pac_n'};
pac_desc  = {'VA price', 'Consumption', 'Business inv.', 'Household inv.', 'Employment'};
omega_manual = [NaN, 0.369, 0.35, 0.30, 0.30];  % manual omega values (post-estimation)

for j = 1:length(pac_names)
    pname = pac_names{j};
    fprintf('  --- %s (%s) ---\n', pname, pac_desc{j});

    if isfield(M_.pac, pname)
        pac_info = M_.pac.(pname);

        % Print key PAC model info
        fn = fieldnames(pac_info);
        fprintf('    Fields: %s\n', strjoin(fn', ', '));

        % Try to find h0 and h1 vectors
        % In Dynare 6.5, h-vectors are stored as parameter values
        % pac_info.h_param_indices points to the parameters
        if isfield(pac_info, 'h_param_indices')
            h_idx = pac_info.h_param_indices;
            h_vals = M_.params(h_idx);
            fprintf('    h-vector (%d elements): [', length(h_vals));
            for k = 1:min(8, length(h_vals))
                fprintf('%.6f ', h_vals(k));
            end
            if length(h_vals) > 8, fprintf('...'); end
            fprintf(']\n');
            fprintf('    Sum of |h|: %.6f\n', sum(abs(h_vals)));

            % The sum of h-vector elements represents the total forward
            % expectations weight (analogous to omega in manual PAC)
            h_sum = sum(h_vals);
            fprintf('    Sum of h:   %.6f', h_sum);
            if ~isnan(omega_manual(j))
                fprintf('  (manual omega was %.3f, ratio: %.3f)', omega_manual(j), h_sum/omega_manual(j));
            end
            fprintf('\n');
        end

        % Check for separate h0/h1 vectors
        if isfield(pac_info, 'h0_param_indices')
            h0_vals = M_.params(pac_info.h0_param_indices);
            fprintf('    h0 (level weights, %d elements): [', length(h0_vals));
            for k = 1:min(5, length(h0_vals))
                fprintf('%.6f ', h0_vals(k));
            end
            if length(h0_vals) > 5, fprintf('...'); end
            fprintf('] sum=%.6f\n', sum(h0_vals));
        end
        if isfield(pac_info, 'h1_param_indices')
            h1_vals = M_.params(pac_info.h1_param_indices);
            fprintf('    h1 (growth weights, %d elements): [', length(h1_vals));
            for k = 1:min(5, length(h1_vals))
                fprintf('%.6f ', h1_vals(k));
            end
            if length(h1_vals) > 5, fprintf('...'); end
            fprintf('] sum=%.6f\n', sum(h1_vals));
        end

        % Print discount factor
        if isfield(pac_info, 'discount')
            fprintf('    Discount: beta = %.4f\n', M_.params(pac_info.discount));
        end
    else
        fprintf('    NOT FOUND in M_.pac\n');
    end
    fprintf('\n');
end

%% Extract IRFs to monetary policy shock
fprintf('================================================================\n');
fprintf('  IRFs to monetary policy shock (eps_i, 1 s.d.)\n');
fprintf('================================================================\n\n');

shock_name = 'eps_i';
vars = {'yhat_au', 'pi_au', 'i_au', 'piQ', 'dln_c', 'dln_ib', 'dln_ih', 'dln_n', 'pi_w', 's_gap', 'i_10y'};
labels = {'Output gap', 'CPI inflation', 'Policy rate', 'VA price infl.', ...
          'Consumption', 'Business inv.', 'Housing inv.', 'Employment', ...
          'Wage inflation', 'Exchange rate', '10Y yield'};

% Pre-migration baseline from STATUS.md Stage 11a
% (original model with manual PAC + calibrated params)
% Note: these used different parameters so comparison is approximate
pre_baseline = struct();
pre_baseline.yhat_au  = struct('peak', -0.019, 'peak_q', 3);
pre_baseline.dln_c    = struct('peak', -0.0045, 'peak_q', 4);
pre_baseline.dln_ih   = struct('peak', -0.0083, 'peak_q', 3);
pre_baseline.piQ      = struct('peak', -0.0015, 'peak_q', 5);

fprintf('  %-20s  %8s  %4s  %8s  %12s\n', 'Variable', 'Peak', 'Q', 'Impact', 'Pre-baseline');
fprintf('  %-20s  %8s  %4s  %8s  %12s\n', '--------', '----', '-', '------', '------------');

for j = 1:length(vars)
    field = [vars{j} '_' shock_name];
    pre_str = '';
    if isfield(pre_baseline, vars{j})
        pre_str = sprintf('%.5f (Q%d)', pre_baseline.(vars{j}).peak, pre_baseline.(vars{j}).peak_q);
    end

    if isfield(oo_.irfs, field)
        irf_j = oo_.irfs.(field);
        [pv, pq] = max(abs(irf_j));
        peak = sign(irf_j(pq)) * pv;
        fprintf('  %-20s  %8.5f  Q%-3d  %8.5f  %s\n', ...
            labels{j}, peak, pq, irf_j(1), pre_str);
    else
        fprintf('  %-20s  --- IRF not found ---\n', labels{j});
    end
end

%% Detailed IRF paths for PAC variables
fprintf('\n================================================================\n');
fprintf('  Detailed IRF paths: PAC variables (eps_i shock)\n');
fprintf('================================================================\n');

pac_vars = {'dln_c', 'dln_ib', 'dln_ih', 'dln_n', 'piQ'};
pac_labels = {'Consumption', 'Business inv.', 'Housing inv.', 'Employment', 'VA price'};

for j = 1:length(pac_vars)
    field = [pac_vars{j} '_' shock_name];
    if isfield(oo_.irfs, field)
        irf_j = oo_.irfs.(field);
        fprintf('\n  %s:\n', pac_labels{j});
        fprintf('  %6s  %12s\n', 'Qtr', 'Response');
        for q = [1 2 3 4 6 8 12 16 20 30 40]
            if q <= length(irf_j)
                fprintf('  %6d  %12.6f\n', q, irf_j(q));
            end
        end
    end
end

%% TFP shock IRFs (supply-side validation)
fprintf('\n================================================================\n');
fprintf('  IRFs to TFP shock (eps_tfp, supply-side validation)\n');
fprintf('================================================================\n\n');

shock_name2 = 'eps_tfp';
vars_supply = {'dln_y_star', 'dln_tfp', 'dln_prod', 'dln_ulc', 'piQ', 'pi_w', 'yhat_au', 'dln_n'};
labels_supply = {'Potential output', 'TFP growth', 'Productivity', ...
                 'ULC growth', 'VA price infl.', 'Wage inflation', 'Output gap', 'Employment'};

fprintf('  %-20s  %8s  %4s  %8s\n', 'Variable', 'Peak', 'Q', 'Impact');
fprintf('  %-20s  %8s  %4s  %8s\n', '--------', '----', '-', '------');
for j = 1:length(vars_supply)
    field = [vars_supply{j} '_' shock_name2];
    if isfield(oo_.irfs, field)
        irf_j = oo_.irfs.(field);
        [pv, pq] = max(abs(irf_j));
        peak = sign(irf_j(pq)) * pv;
        fprintf('  %-20s  %8.5f  Q%-3d  %8.5f\n', labels_supply{j}, peak, pq, irf_j(1));
    end
end

%% Plot IRFs
fig = figure('Position', [50 50 1400 900], 'Visible', 'off');

shock_name = 'eps_i';
for j = 1:length(vars)
    subplot(3, 4, j);
    field = [vars{j} '_' shock_name];

    if isfield(oo_.irfs, field)
        irf_j = oo_.irfs.(field);
        T = length(irf_j);
        plot(1:T, irf_j, 'b-', 'LineWidth', 1.5); hold on;
        plot(1:T, zeros(T,1), 'k:', 'LineWidth', 0.5);
    end

    title(labels{j}, 'FontSize', 10);
    xlabel('Quarters');
    ylabel('% dev.');
    grid on;
end

sgtitle('AUSPAC: IRFs to Monetary Policy Shock (native pac\_expectation)', 'FontSize', 13);
saveas(fig, 'pac_migration_irfs.png');
fprintf('\n  Saved: pac_migration_irfs.png\n');
close(fig);

%% Summary
fprintf('\n================================================================\n');
fprintf('  Summary\n');
fprintf('================================================================\n');
fprintf('\n  Model uses native Dynare pac_expectation() for all 5 PAC equations.\n');
fprintf('  h-vectors computed from TCM companion matrices weight future targets.\n');
fprintf('  The h-vectors replace the manual omega*target + neutrality terms.\n');
fprintf('  Compare h-vector sums to manual omega values above to assess\n');
fprintf('  whether the TCM-based expectations are stronger or weaker.\n');

fprintf('\n=== Analysis complete ===\n');
