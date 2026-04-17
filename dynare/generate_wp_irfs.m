%% generate_wp_irfs.m — Policy-relevant IRFs for AUSPAC working paper
%
% Generates all IRF tables and plots at policy-relevant shock sizes:
%   - Monetary policy: 100bp annualized (0.25 quarterly pp)
%   - Foreign demand: 1pp US output gap
%   - Government spending: 1pp of GDP
%   - Commodity price: 10% increase
%   - Term premium: 50bp annualized (0.125 quarterly pp)
%   - Cost-push (VA price): 1 s.d.
%   - TFP: 1 s.d.
%
% Uses linear scaling (exact at order=1): scaled_IRF = raw_IRF * (target / stderr)
%
% Output:
%   - irf_eps_*.png for each shock (policy-relevant sizes)
%   - irf_level_accumulators_monetary.png (level vs gap decomposition)
%   - irf_overview_output.png (output gap comparison)
%   - log_wp_irfs.txt (file-based log)

clear; clc;
cd(fileparts(mfilename('fullpath')));
setup_dynare_path();

logfile = 'log_wp_irfs.txt';
fid = fopen(logfile, 'w');
fprintf(fid, '================================================================\n');
fprintf(fid, '  AU-PAC Working Paper IRFs — Policy-Relevant Shock Sizes\n');
fprintf(fid, '  Generated: %s\n', datestr(now));
fprintf(fid, '================================================================\n\n');
fclose(fid);

fprintf('================================================================\n');
fprintf('  AU-PAC Working Paper IRFs — Policy-Relevant Shock Sizes\n');
fprintf('  Generated: %s\n', datestr(now));
fprintf('================================================================\n\n');

%% Run hybrid model
fprintf('--- Running AU_PAC hybrid model ---\n');
dynare au_pac noclearall nograph;

fid = fopen(logfile, 'a');
fprintf(fid, 'Model: %d endo, %d exo, %d forward-looking\n\n', ...
    M_.endo_nbr, M_.exo_nbr, sum(abs(oo_.dr.eigval) > 1));
fclose(fid);

fprintf('  %d equations, %d forward-looking vars\n\n', ...
    M_.endo_nbr, sum(abs(oo_.dr.eigval) > 1));

%% Define shock scaling
shock_config = {
    'eps_i',     'Monetary policy',       0.027, 0.250,  '100bp annualized (0.25 qpp)',     '6.3.1';
    'eps_tp',    'Term premium',          0.050, 0.125,  '50bp annualized (0.125 qpp)',     '6.3.7';
    'eps_q_us',  'Foreign demand',        1.138, 1.000,  '1pp US output gap',               '6.3.2';
    'eps_g',     'Government spending',   0.300, 1.000,  '1pp of GDP',                      '6.3.3';
    'eps_pcom',  'Commodity price',       3.000, 10.00,  '10% commodity price increase',    '6.3.4';
    'eps_pQ',    'Cost-push (VA price)',  0.571, 0.571,  '1 s.d.',                          '6.3.5';
    'eps_tfp',   'TFP',                  0.200, 0.200,  '1 s.d.',                          '6.3.6';
};

nShocks = size(shock_config, 1);
scale_factors = zeros(nShocks, 1);
for s = 1:nShocks
    scale_factors(s) = shock_config{s, 4} / shock_config{s, 3};
end

fid = fopen(logfile, 'a');
fprintf(fid, 'Shock scaling factors:\n');
for s = 1:nShocks
    fprintf(fid, '  %-25s: stderr=%.3f, target=%.3f, scale=%.3f (%s)\n', ...
        shock_config{s,2}, shock_config{s,3}, shock_config{s,4}, ...
        scale_factors(s), shock_config{s,5});
    fprintf('    %-25s: stderr=%.3f, target=%.3f, scale=%.3f (%s)\n', ...
        shock_config{s,2}, shock_config{s,3}, shock_config{s,4}, ...
        scale_factors(s), shock_config{s,5});
end
fprintf(fid, '\n');
fclose(fid);

%% Variables to track
vars = {'yhat_au', 'dln_c', 'dln_ib', 'dln_ih', 'dln_x', 'dln_m', ...
        'pi_au', 'piQ', 'pi_w', 'dln_n', 's_gap', 'i_10y', 'i_au'};
var_labels = {'Output gap (%)', 'Consumption (%)', 'Business inv. (%)', ...
              'Housing inv. (%)', 'Exports (%)', 'Imports (%)', ...
              'CPI inflation (pp)', 'VA price infl. (pp)', 'Wage inflation (pp)', ...
              'Employment (%)', 'Exchange rate (%)', '10Y yield (pp)', ...
              'Policy rate (pp)'};

%% Extract and scale all IRFs
fid = fopen(logfile, 'a');
fprintf(fid, '================================================================\n');
fprintf(fid, '  Peak Responses (policy-relevant shock sizes)\n');
fprintf(fid, '================================================================\n\n');

scaled_irfs = struct();

for s = 1:nShocks
    shock = shock_config{s, 1};
    sf = scale_factors(s);

    fprintf(fid, '--- %s (%s) [%s] ---\n', shock_config{s,2}, shock, shock_config{s,5});
    fprintf(fid, '  %-22s  %10s  %4s\n', 'Variable', 'Peak', 'Q');

    for v = 1:length(vars)
        field = [vars{v} '_' shock];
        if isfield(oo_.irfs, field)
            raw_irf = oo_.irfs.(field);
            scaled_irf = raw_irf * sf;
            scaled_irfs.(field) = scaled_irf;

            [pv, pq] = max(abs(scaled_irf));
            peak = sign(scaled_irf(pq)) * pv;
            fprintf(fid, '  %-22s  %+10.4f  Q%-2d\n', var_labels{v}, peak, pq);
        end
    end

    % Level accumulators
    level_vars = {'ln_Q', 'ln_QN', 'ln_C', 'ln_IB', 'ln_IH', 'ln_N'};
    level_labels = {'Output (Q)', 'Potential (QN)', 'Consumption', 'Business inv.', 'Housing inv.', 'Employment'};
    for v = 1:length(level_vars)
        field = [level_vars{v} '_' shock];
        if isfield(oo_.irfs, field)
            scaled_irf = oo_.irfs.(field) * sf;
            scaled_irfs.(field) = scaled_irf;
            [pv, pq] = max(abs(scaled_irf));
            peak = sign(scaled_irf(pq)) * pv;
            fprintf(fid, '  %-22s  %+10.4f  Q%-2d  (cumulative)\n', level_labels{v}, peak, pq);
        end
    end
    fprintf(fid, '\n');
end
fclose(fid);

%% ========================================================================
%  Monetary policy shock — detailed path table
%  ========================================================================
fid = fopen(logfile, 'a');
fprintf(fid, '================================================================\n');
fprintf(fid, '  Table: Monetary Policy Shock — Detailed Path\n');
fprintf(fid, '  (100bp annualized = 0.25 quarterly pp)\n');
fprintf(fid, '================================================================\n');

mon_vars = {'yhat_au', 'dln_c', 'dln_ib', 'dln_ih', 'dln_x', 'dln_m', ...
            'piQ', 'pi_w', 'dln_n', 's_gap', 'i_10y', 'i_au', 'ln_Q', 'ln_QN'};
mon_labels = {'Output', 'Cons.', 'Bus.inv', 'Hh.inv', 'Exports', 'Imports', ...
              'VA price', 'Wages', 'Employ.', 'Exch.rate', '10Y', 'Policy', 'ln_Q', 'ln_QN'};

fprintf(fid, '\n%-8s', 'Quarter');
for v = 1:length(mon_vars)
    fprintf(fid, ' %9s', mon_labels{v});
end
fprintf(fid, '\n');

for q = [1 2 4 8 12 16 20 30 40]
    fprintf(fid, 'Q%-7d', q);
    for v = 1:length(mon_vars)
        field = [mon_vars{v} '_eps_i'];
        if isfield(scaled_irfs, field) && q <= length(scaled_irfs.(field))
            fprintf(fid, ' %+9.4f', scaled_irfs.(field)(q));
        else
            fprintf(fid, ' %9s', 'N/A');
        end
    end
    fprintf(fid, '\n');
end
fprintf(fid, '\n');
fclose(fid);

%% ========================================================================
%  Generate individual shock plots (policy-relevant sizes)
%  ========================================================================
fid = fopen(logfile, 'a');
fprintf(fid, '--- Generating individual shock plots ---\n');

plot_vars = {'yhat_au', 'dln_c', 'dln_ib', 'dln_ih', 'dln_x', 'dln_m', ...
             'pi_au', 'piQ', 'pi_w', 'dln_n', 's_gap', 'i_10y'};
plot_labels = {'Output gap', 'Consumption', 'Business inv.', 'Housing inv.', ...
               'Exports', 'Imports', 'CPI inflation', 'VA price infl.', ...
               'Wage inflation', 'Employment', 'Exchange rate', '10Y yield'};

for s = 1:nShocks
    shock = shock_config{s, 1};
    sf = scale_factors(s);

    fig = figure('Position', [30 30 1400 800], 'Visible', 'off');

    for v = 1:length(plot_vars)
        subplot(3, 4, v);
        field = [plot_vars{v} '_' shock];

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

    sgtitle(sprintf('AU-PAC: %s Shock [%s]', shock_config{s,2}, shock_config{s,5}), 'FontSize', 13);
    fname = sprintf('irf_%s.png', shock);
    saveas(fig, fname);
    fprintf(fid, '  Saved: %s\n', fname);
    close(fig);
end

%% ========================================================================
%  Level accumulator plot — monetary shock (FR-BDF eq 43)
%  ========================================================================
fprintf(fid, '\n--- Generating level accumulator IRF plot ---\n');

fig_lev = figure('Position', [30 30 1400 900], 'Visible', 'off');
sf_mon = scale_factors(1); % monetary shock

% Panel 1: Output — ln_Q vs ln_QN vs yhat_au
subplot(3, 3, 1);
if isfield(oo_.irfs, 'ln_Q_eps_i') && isfield(oo_.irfs, 'ln_QN_eps_i')
    irf_Q = oo_.irfs.ln_Q_eps_i * sf_mon;
    irf_QN = oo_.irfs.ln_QN_eps_i * sf_mon;
    irf_yhat = oo_.irfs.yhat_au_eps_i * sf_mon;
    T = length(irf_Q);
    plot(1:T, irf_Q, 'b-', 'LineWidth', 1.5); hold on;
    plot(1:T, irf_QN, 'r--', 'LineWidth', 1.5);
    plot(1:T, irf_yhat, 'k:', 'LineWidth', 1.0);
    plot(1:T, zeros(T,1), 'k:', 'LineWidth', 0.3);
    legend('ln\_Q (actual)', 'ln\_QN (potential)', 'yhat\_au (gap)', 'Location', 'best');
end
title('Output: Level vs Gap', 'FontSize', 10);
xlabel('Quarters'); ylabel('Index / % dev.'); grid on;

% Panels 2-7: other level accumulators
other_level = {'ln_C', 'ln_IB', 'ln_IH', 'ln_N', 'ln_K', 'ln_P'};
other_star = {'ln_C_star', 'ln_IB_star', 'ln_IH_star', 'ln_N_star', '', 'ln_P_star'};
other_labels = {'Consumption', 'Business Inv.', 'Housing Inv.', 'Employment', 'Capital', 'Price Level'};

for p = 1:6
    subplot(3, 3, 1+p);
    field_act = [other_level{p} '_eps_i'];
    if isfield(oo_.irfs, field_act)
        irf_act = oo_.irfs.(field_act) * sf_mon;
        T = length(irf_act);
        plot(1:T, irf_act, 'b-', 'LineWidth', 1.5); hold on;
        if ~isempty(other_star{p})
            field_star = [other_star{p} '_eps_i'];
            if isfield(oo_.irfs, field_star)
                irf_star = oo_.irfs.(field_star) * sf_mon;
                plot(1:T, irf_star, 'r--', 'LineWidth', 1.5);
                legend('Actual', 'Trend', 'Location', 'best');
            end
        end
        plot(1:T, zeros(T,1), 'k:', 'LineWidth', 0.3);
    end
    title(other_labels{p}, 'FontSize', 10);
    xlabel('Quarters'); ylabel('Index'); grid on;
end

sgtitle('Level Accumulators: 100bp Monetary Tightening (FR-BDF eq 43)', 'FontSize', 13);
saveas(fig_lev, 'irf_level_accumulators_monetary.png');
fprintf(fid, '  Saved: irf_level_accumulators_monetary.png\n');
close(fig_lev);

%% ========================================================================
%  Output gap overview — all shocks at policy-relevant sizes
%  ========================================================================
fig2 = figure('Position', [30 30 1600 1000], 'Visible', 'off');

overview_order = [1 3 4 5 7 2]; % monetary, foreign, govt, commodity, TFP, term premium
overview_var = 'yhat_au';

for idx = 1:length(overview_order)
    s = overview_order(idx);
    shock = shock_config{s, 1};
    sf = scale_factors(s);

    subplot(2, 3, idx);
    field = [overview_var '_' shock];
    if isfield(oo_.irfs, field)
        irf_j = oo_.irfs.(field) * sf;
        T = length(irf_j);
        plot(1:T, irf_j, 'b-', 'LineWidth', 1.5); hold on;
        plot(1:T, zeros(T,1), 'k:', 'LineWidth', 0.5);
    end
    title(sprintf('%s\n[%s]', shock_config{s,2}, shock_config{s,5}), 'FontSize', 9);
    xlabel('Quarters'); ylabel('Output gap (% dev.)');
    grid on;
end

sgtitle('AU-PAC: Output Gap Response to Policy-Relevant Shocks', 'FontSize', 14);
saveas(fig2, 'irf_overview_output.png');
fprintf(fid, '  Saved: irf_overview_output.png\n');
close(fig2);

%% ========================================================================
%  Summary comparison table — peak output gap response
%  ========================================================================
fprintf(fid, '\n================================================================\n');
fprintf(fid, '  Summary: Peak Output Gap by Shock (policy-relevant sizes)\n');
fprintf(fid, '================================================================\n\n');
fprintf(fid, '%-22s %-28s %10s %5s %10s %10s %10s\n', ...
    'Shock', 'Size', 'yhat', 'Qtr', 'dln_c', 'dln_ib', 'dln_ih');

for s = 1:nShocks
    shock = shock_config{s, 1};
    sf = scale_factors(s);

    peaks = zeros(1, 4);
    peak_vars = {'yhat_au', 'dln_c', 'dln_ib', 'dln_ih'};
    peak_q = 0;
    for pv = 1:4
        field = [peak_vars{pv} '_' shock];
        if isfield(oo_.irfs, field)
            irf_j = oo_.irfs.(field) * sf;
            [mv, mq] = max(abs(irf_j));
            peaks(pv) = sign(irf_j(mq)) * mv;
            if pv == 1, peak_q = mq; end
        end
    end

    fprintf(fid, '%-22s %-28s %+10.4f Q%-3d %+10.4f %+10.4f %+10.4f\n', ...
        shock_config{s,2}, shock_config{s,5}, peaks(1), peak_q, peaks(2), peaks(3), peaks(4));
end

fprintf(fid, '\nCompleted: %s\n', datestr(now));
fclose(fid);
fprintf('\n  Log saved: log_wp_irfs.txt\n');
fprintf('\n=== Working paper IRF generation complete ===\n');
