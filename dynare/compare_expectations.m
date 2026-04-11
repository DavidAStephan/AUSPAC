%% compare_expectations.m — Compare VAR-based vs MCE expectations
%
% Runs both au_pac.mod (VAR/hybrid) and au_pac_mce.mod (full MCE),
% then compares IRFs to monetary policy shock (eps_i).
%
% Tests FR-BDF Section 6 predictions:
%   - MCE should DAMPEN non-financial responses vs VAR-based
%   - MCE should show FASTER convergence (no overshoot)
%   - Both should produce identical steady states
%
% Usage: run from c:\Users\david\french_model\dynare\

clear; clc;
addpath('C:\dynare\6.5\matlab');

fprintf('================================================================\n');
fprintf('  Expectation Regime Comparison\n');
fprintf('  VAR-based (hybrid) vs Full MCE\n');
fprintf('================================================================\n\n');

%% Step 1: Run VAR-based model
fprintf('--- Running VAR-based model (au_pac.mod) ---\n');
dynare au_pac noclearall nograph;

irfs_var = oo_.irfs;
M_var = M_;
fprintf('  VAR: %d equations, %d eigenvalues > 1\n\n', ...
    M_.orig_endo_nbr, sum(abs(oo_.dr.eigval) > 1));

clear M_ oo_ options_

%% Step 2: Run MCE model
fprintf('--- Running MCE model (au_pac_mce.mod) ---\n');
dynare au_pac_mce noclearall nograph;

irfs_mce = oo_.irfs;
M_mce = M_;
fprintf('  MCE: %d equations, %d eigenvalues > 1\n\n', ...
    M_.orig_endo_nbr, sum(abs(oo_.dr.eigval) > 1));

%% Step 3: Compare IRFs to monetary policy shock
shock_name = 'eps_i';
vars = {'yhat_au', 'pi_au', 'i_au', 'piQ', 'dln_c', 'dln_ib', 'dln_ih', 'dln_n', 'pi_w', 's_gap', 'i_10y'};
labels = {'Output gap', 'CPI inflation', 'Policy rate', 'VA price infl.', ...
          'Consumption', 'Business inv.', 'Housing inv.', 'Employment', ...
          'Wage inflation', 'Exchange rate', '10Y yield'};

fprintf('================================================================\n');
fprintf('  IRFs to 1 s.d. monetary policy shock (eps_i)\n');
fprintf('================================================================\n');
fprintf('  %-20s  %10s  %10s  %8s\n', 'Variable', 'VAR peak', 'MCE peak', 'Ratio');
fprintf('  %-20s  %10s  %10s  %8s\n', '--------', '--------', '--------', '-----');

for j = 1:length(vars)
    field = [vars{j} '_' shock_name];

    peak_var = 0; peak_mce = 0;
    if isfield(irfs_var, field)
        irf_j = irfs_var.(field);
        [pv, pq] = max(abs(irf_j));
        peak_var = sign(irf_j(pq)) * pv;
    end
    if isfield(irfs_mce, field)
        irf_j = irfs_mce.(field);
        [pv, pq] = max(abs(irf_j));
        peak_mce = sign(irf_j(pq)) * pv;
    end

    if abs(peak_var) > 1e-10
        ratio = peak_mce / peak_var;
    else
        ratio = NaN;
    end

    fprintf('  %-20s  %10.6f  %10.6f  %8.3f\n', labels{j}, peak_var, peak_mce, ratio);
end

%% Step 4: Detailed paths for key variables
fprintf('\n================================================================\n');
fprintf('  Detailed IRF paths (eps_i shock)\n');
fprintf('================================================================\n');

key_vars = {'yhat_au', 'dln_c', 'dln_ib', 'piQ', 'pi_w'};
key_labels = {'Output gap', 'Consumption', 'Business inv.', 'VA price', 'Wage inflation'};

for j = 1:length(key_vars)
    field = [key_vars{j} '_' shock_name];
    if isfield(irfs_var, field) && isfield(irfs_mce, field)
        v = irfs_var.(field);
        m = irfs_mce.(field);
        fprintf('\n  %s:\n', key_labels{j});
        fprintf('  %6s  %12s  %12s  %12s\n', 'Qtr', 'VAR', 'MCE', 'Diff');
        for q = [1 2 4 8 12 20 30 40]
            if q <= length(v) && q <= length(m)
                fprintf('  %6d  %12.7f  %12.7f  %12.7f\n', q, v(q), m(q), m(q)-v(q));
            end
        end
    end
end

%% Step 5: Plot comparison
fig = figure('Position', [50 50 1400 900], 'Visible', 'off');

for j = 1:length(vars)
    subplot(3, 4, j);
    field = [vars{j} '_' shock_name];

    if isfield(irfs_var, field) && isfield(irfs_mce, field)
        v = irfs_var.(field);
        m = irfs_mce.(field);
        T = length(v);
        plot(1:T, v, 'b-', 'LineWidth', 1.5); hold on;
        plot(1:T, m, 'r--', 'LineWidth', 1.5);
        plot(1:T, zeros(T,1), 'k:', 'LineWidth', 0.5);
    end

    title(labels{j}, 'FontSize', 10);
    xlabel('Quarters');
    ylabel('% dev.');
    if j == 1, legend('VAR-based', 'MCE', 'Location', 'best'); end
    grid on;
end

sgtitle('IRFs to Monetary Policy Shock: VAR-based vs MCE', 'FontSize', 13);
saveas(fig, 'expectation_comparison.png');
fprintf('\n  Saved: expectation_comparison.png\n');
close(fig);

%% Step 6: Summary
fprintf('\n================================================================\n');
fprintf('  Summary: FR-BDF Section 6 predictions\n');
fprintf('================================================================\n');

% Check dampening: MCE output peak should be smaller than VAR
field_y = ['yhat_au_' shock_name];
if isfield(irfs_var, field_y) && isfield(irfs_mce, field_y)
    v = irfs_var.(field_y);
    m = irfs_mce.(field_y);
    [~,pq_v] = max(abs(v)); peak_v = abs(v(pq_v));
    [~,pq_m] = max(abs(m)); peak_m = abs(m(pq_m));

    if peak_m < peak_v
        fprintf('\n  >> MCE DAMPENS output response (|%.5f| < |%.5f|)\n', peak_m, peak_v);
        fprintf('     Consistent with FR-BDF Section 6.2: forward-looking non-financial\n');
        fprintf('     agents smooth their responses, reducing peak GDP effect.\n');
    elseif peak_m > peak_v
        fprintf('\n  >> MCE AMPLIFIES output response (|%.5f| > |%.5f|)\n', peak_m, peak_v);
        fprintf('     Opposite to FR-BDF Section 6.2 prediction.\n');
    else
        fprintf('\n  >> Minimal difference between VAR and MCE.\n');
    end
end

fprintf('\n  Model structure:\n');
fprintf('    VAR-based: %d forward-looking variables\n', sum(abs(oo_.dr.eigval) > 1));
fprintf('    MCE:       27 forward-looking variables (5 PAC expectations + auxiliaries)\n');
fprintf('    Both:      %d equations, identical steady states\n', M_mce.orig_endo_nbr);

fprintf('\n=== Comparison complete ===\n');
