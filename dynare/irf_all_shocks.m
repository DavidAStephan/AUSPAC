%% irf_all_shocks.m — Complete IRF analysis for AU_PAC documentation
%
% Replicates FR-BDF Section 5.2 IRF analysis for all 7 shock types.
% ** Policy-relevant shock sizes (not 1 s.d.) **
% Uses linear scaling (exact at order=1): IRF * (target / stderr)
%
% Shock sizes:
%   1. Monetary policy (eps_i) — 100bp annualized (0.25 qpp)
%   2. Term premium (eps_tp) — 50bp annualized (0.125 qpp)
%   3. Foreign demand (eps_q_us) — 1pp US output gap
%   4. Government spending (eps_g) — 1pp of GDP
%   5. Commodity/oil price (eps_pcom) — 10% increase
%   6. Cost-push / VA price (eps_pQ) — 1 s.d.
%   7. TFP / labor efficiency (eps_tfp) — 1 s.d.

clear; clc;
cd(fileparts(mfilename('fullpath')));
setup_dynare_path();

fprintf('================================================================\n');
fprintf('  AU_PAC Complete IRF Analysis\n');
fprintf('  Policy-Relevant Shock Sizes\n');
fprintf('================================================================\n\n');

%% Run model
fprintf('--- Running AU_PAC model ---\n');
dynare au_pac noclearall nograph;
fprintf('  %d equations, %d forward-looking vars\n\n', ...
    M_.orig_endo_nbr, sum(abs(oo_.dr.eigval) > 1));

%% Define shocks, scaling, and variables
shocks = {'eps_i', 'eps_tp', 'eps_q_us', 'eps_g', 'eps_pcom', 'eps_pQ', 'eps_tfp'};
shock_labels = {'Monetary policy', 'Term premium', 'Foreign demand', ...
                'Government spending', 'Commodity price', 'Cost-push (VA price)', ...
                'TFP / labor efficiency'};
shock_stderrs = [0.027, 0.050, 1.138, 0.300, 3.000, 0.571, 0.200];
shock_targets = [0.250, 0.125, 1.000, 1.000, 10.00, 0.571, 0.200];
shock_descriptions = {'100bp annualized', '50bp annualized', '1pp US output gap', ...
                      '1pp of GDP', '10% increase', '1 s.d.', '1 s.d.'};
scale_factors = shock_targets ./ shock_stderrs;

fprintf('  Shock scaling:\n');
for s = 1:length(shocks)
    fprintf('    %-25s: scale=%.3f (%s)\n', shock_labels{s}, scale_factors(s), shock_descriptions{s});
end
fprintf('\n');

vars = {'yhat_au', 'dln_c', 'dln_ib', 'dln_ih', 'dln_x', 'dln_m', ...
        'pi_au', 'piQ', 'pi_w', 'dln_n', 's_gap', 'i_10y', ...
        'w_G', 'b_ROW'};
var_labels = {'Output gap (%)', 'Consumption (%)', 'Business inv. (%)', ...
              'Housing inv. (%)', 'Exports (%)', 'Imports (%)', ...
              'CPI inflation (pp)', 'VA price infl. (pp)', 'Wage inflation (pp)', ...
              'Employment (%)', 'Exchange rate (%)', '10Y yield (pp)', ...
              'Govt debt ratio', 'Current account'};

%% Extract all IRFs
fprintf('================================================================\n');
fprintf('  IRF Peak Responses (policy-relevant shock sizes)\n');
fprintf('================================================================\n\n');

for s = 1:length(shocks)
    sf = scale_factors(s);
    fprintf('--- %s shock (%s) [%s, scale=%.3f] ---\n', ...
        shock_labels{s}, shocks{s}, shock_descriptions{s}, sf);
    fprintf('  %-22s  %10s  %4s\n', 'Variable', 'Peak', 'Q');

    for v = 1:length(vars)
        field = [vars{v} '_' shocks{s}];
        if isfield(oo_.irfs, field)
            irf_j = oo_.irfs.(field) * sf;
            [pv, pq] = max(abs(irf_j));
            peak = sign(irf_j(pq)) * pv;
            fprintf('  %-22s  %10.4f  Q%-2d\n', var_labels{v}, peak, pq);
        end
    end
    fprintf('\n');
end

%% Generate individual shock plots (FR-BDF Figure 5.2.x style)
plot_vars = {'yhat_au', 'dln_c', 'dln_ib', 'dln_ih', 'dln_x', 'dln_m', ...
             'pi_au', 'piQ', 'pi_w', 'dln_n', 's_gap', 'i_10y'};
plot_labels = {'Real GDP', 'Consumption', 'Business inv.', 'Housing inv.', ...
               'Exports', 'Imports', 'CPI inflation', 'VA price infl.', ...
               'Wage inflation', 'Employment', 'Exchange rate', '10Y yield'};

for s = 1:length(shocks)
    sf = scale_factors(s);
    fig = figure('Position', [30 30 1400 800], 'Visible', 'off');

    for v = 1:length(plot_vars)
        subplot(3, 4, v);
        field = [plot_vars{v} '_' shocks{s}];

        if isfield(oo_.irfs, field)
            irf_j = oo_.irfs.(field) * sf;
            T = length(irf_j);
            plot(1:T, irf_j, 'b-', 'LineWidth', 1.5); hold on;
            plot(1:T, zeros(T,1), 'k:', 'LineWidth', 0.5);
        end

        title(plot_labels{v}, 'FontSize', 9);
        xlabel('Quarters');
        if v <= 6, ylabel('% dev.'); else, ylabel('pp dev.'); end
        grid on;
    end

    sgtitle(sprintf('AU-PAC: %s Shock [%s]', shock_labels{s}, shock_descriptions{s}), 'FontSize', 13);
    fname = sprintf('irf_%s.png', shocks{s});
    saveas(fig, fname);
    fprintf('Saved: %s\n', fname);
    close(fig);
end

%% Detailed table for monetary shock (key shock)
sf_mon = scale_factors(1);  % monetary shock scale factor
fprintf('\n================================================================\n');
fprintf('  Monetary Policy Shock — Detailed Path (100bp annualized)\n');
fprintf('================================================================\n');

key_vars_mon = {'yhat_au', 'dln_c', 'dln_ib', 'dln_ih', 'dln_x', 'dln_m', ...
                'piQ', 'pi_w', 'dln_n', 's_gap', 'i_10y'};
key_labels_mon = {'Output gap', 'Consumption', 'Bus. inv.', 'Housing inv.', ...
                  'Exports', 'Imports', 'VA price', 'Wages', 'Employment', ...
                  'Exch. rate', '10Y yield'};

fprintf('\n  %-14s', 'Quarter');
for v = 1:length(key_vars_mon)
    fprintf('  %10s', key_labels_mon{v});
end
fprintf('\n');

for q = [1 2 4 8 12 16 20 30 40]
    fprintf('  Q%-12d', q);
    for v = 1:length(key_vars_mon)
        field = [key_vars_mon{v} '_eps_i'];
        if isfield(oo_.irfs, field) && q <= length(oo_.irfs.(field))
            fprintf('  %10.4f', oo_.irfs.(field)(q) * sf_mon);
        else
            fprintf('  %10s', 'N/A');
        end
    end
    fprintf('\n');
end

%% Detailed table for TFP shock
sf_tfp = scale_factors(7);  % TFP scale factor (1.0 for 1 s.d.)
fprintf('\n================================================================\n');
fprintf('  TFP Shock — Detailed Path (1 s.d.)\n');
fprintf('================================================================\n');

key_vars_tfp = {'yhat_au', 'dln_c', 'dln_ib', 'dln_n', 'piQ', 'pi_w', ...
                'dln_x', 's_gap'};
key_labels_tfp = {'Output', 'Consump.', 'Bus.inv.', 'Employm.', 'VA price', ...
                  'Wages', 'Exports', 'Exch.rate'};

fprintf('\n  %-14s', 'Quarter');
for v = 1:length(key_vars_tfp)
    fprintf('  %10s', key_labels_tfp{v});
end
fprintf('\n');

for q = [1 2 4 8 12 16 20 30 40]
    fprintf('  Q%-12d', q);
    for v = 1:length(key_vars_tfp)
        field = [key_vars_tfp{v} '_eps_tfp'];
        if isfield(oo_.irfs, field) && q <= length(oo_.irfs.(field))
            fprintf('  %10.4f', oo_.irfs.(field)(q) * sf_tfp);
        else
            fprintf('  %10s', 'N/A');
        end
    end
    fprintf('\n');
end

%% Financial accounts response to monetary shock
fprintf('\n================================================================\n');
fprintf('  Monetary Shock — Financial Accounts Response (100bp annualized)\n');
fprintf('================================================================\n');

fin_vars = {'w_G', 'w_F', 'w_H', 'b_G', 'b_ROW', 'tau_G', 'yf_G'};
fin_labels = {'Govt debt', 'Firms NFA', 'HH NFA', 'Govt balance', ...
              'Current acct', 'Govt transfers', 'Govt prop.inc.'};

fprintf('\n  %-14s', 'Quarter');
for v = 1:length(fin_vars)
    fprintf('  %10s', fin_labels{v});
end
fprintf('\n');

for q = [1 2 4 8 12 20 40]
    fprintf('  Q%-12d', q);
    for v = 1:length(fin_vars)
        field = [fin_vars{v} '_eps_i'];
        if isfield(oo_.irfs, field) && q <= length(oo_.irfs.(field))
            fprintf('  %10.5f', oo_.irfs.(field)(q) * sf_mon);
        else
            fprintf('  %10s', 'N/A');
        end
    end
    fprintf('\n');
end

%% Combined overview plot
fig2 = figure('Position', [30 30 1600 1000], 'Visible', 'off');

overview_idx = [1, 2, 3, 4, 5, 7]; % indices into shocks array
overview_var = 'yhat_au';

for idx = 1:length(overview_idx)
    s = overview_idx(idx);
    sf = scale_factors(s);
    subplot(2, 3, idx);
    field = [overview_var '_' shocks{s}];
    if isfield(oo_.irfs, field)
        irf_j = oo_.irfs.(field) * sf;
        T = length(irf_j);
        plot(1:T, irf_j, 'b-', 'LineWidth', 1.5); hold on;
        plot(1:T, zeros(T,1), 'k:', 'LineWidth', 0.5);
    end
    title(sprintf('%s\n[%s]', shock_labels{s}, shock_descriptions{s}), 'FontSize', 9);
    xlabel('Quarters'); ylabel('Output gap (% dev.)');
    grid on;
end

sgtitle('AU-PAC: Output Gap Response to Policy-Relevant Shocks', 'FontSize', 14);
saveas(fig2, 'irf_overview_output.png');
fprintf('\nSaved: irf_overview_output.png\n');
close(fig2);

fprintf('\n=== Complete IRF analysis finished ===\n');
