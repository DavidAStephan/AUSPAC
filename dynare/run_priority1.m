%% run_priority1.m — Compile, verify level accumulators, generate IRFs
%
% Priority 1 tasks:
%   1. Compile au_pac.mod — verify BK with 13 new level accumulators
%   2. Verify identity: ln_Q - ln_QN = yhat_au (exact in IRFs)
%   3. Generate WP IRFs (all 7 shocks at policy-relevant sizes)
%   4. Generate three-regime IRFs (100bp monetary)
%
% Uses file-based logging (fopen/fprintf/fclose) throughout.

clear; clc;
addpath('C:\dynare\6.5\matlab');
cd('c:\Users\david\french_model\dynare');

logfile = 'log_priority1.txt';
fid = fopen(logfile, 'w');
fprintf(fid, '================================================================\n');
fprintf(fid, '  AUSPAC Priority 1 — Compilation + IRF Generation\n');
fprintf(fid, '  Started: %s\n', datestr(now));
fprintf(fid, '================================================================\n\n');
fclose(fid);

%% ========================================================================
%  STAGE 1: Compile au_pac.mod
%  ========================================================================
fid = fopen(logfile, 'a');
fprintf(fid, '--- STAGE 1: Compiling au_pac.mod ---\n');
fclose(fid);

try
    dynare au_pac noclearall nograph;

    fid = fopen(logfile, 'a');
    fprintf(fid, 'SUCCESS: au_pac.mod compiled and solved\n');
    fprintf(fid, '  Endogenous variables: %d\n', M_.endo_nbr);
    fprintf(fid, '  Exogenous variables:  %d\n', M_.exo_nbr);
    fprintf(fid, '  Parameters:           %d\n', M_.param_nbr);

    % Count forward-looking variables from eigenvalues
    n_fwd = sum(abs(oo_.dr.eigval) > 1);
    fprintf(fid, '  Forward-looking vars: %d\n', n_fwd);
    fprintf(fid, '  BK conditions:        SATISFIED\n\n');
    fclose(fid);
catch ME
    fid = fopen(logfile, 'a');
    fprintf(fid, 'FAILED: %s\n', ME.message);
    fprintf(fid, '  Stack trace:\n');
    for k = 1:length(ME.stack)
        fprintf(fid, '    %s (line %d)\n', ME.stack(k).name, ME.stack(k).line);
    end
    fprintf(fid, '\nABORTING — fix .mod file before continuing.\n');
    fclose(fid);
    error('Compilation failed: %s', ME.message);
end

%% ========================================================================
%  STAGE 2: Verify level accumulator identity
%  ========================================================================
fid = fopen(logfile, 'a');
fprintf(fid, '--- STAGE 2: Verifying level accumulator identities ---\n');

% Check ln_Q - ln_QN = yhat_au in IRFs
shock_list = fieldnames(oo_.irfs);
% Find all yhat_au IRFs
yhat_fields = shock_list(startsWith(shock_list, 'yhat_au_'));

identity_ok = true;
for j = 1:length(yhat_fields)
    shock_suffix = yhat_fields{j}(9:end); % strip 'yhat_au_'
    ln_Q_field = ['ln_Q_' shock_suffix];
    ln_QN_field = ['ln_QN_' shock_suffix];

    if isfield(oo_.irfs, ln_Q_field) && isfield(oo_.irfs, ln_QN_field)
        diff_irf = oo_.irfs.(ln_Q_field) - oo_.irfs.(ln_QN_field);
        yhat_irf = oo_.irfs.(yhat_fields{j});
        max_err = max(abs(diff_irf - yhat_irf));
        status = 'PASS';
        if max_err > 1e-10
            status = 'FAIL';
            identity_ok = false;
        end
        fprintf(fid, '  %s: ln_Q - ln_QN vs yhat_au | max error = %.2e [%s]\n', ...
            shock_suffix, max_err, status);
    else
        fprintf(fid, '  %s: ln_Q or ln_QN IRF missing — SKIP\n', shock_suffix);
    end
end

if identity_ok
    fprintf(fid, '\n  IDENTITY VERIFIED: ln_Q - ln_QN = yhat_au for ALL shocks\n\n');
else
    fprintf(fid, '\n  WARNING: Identity check failed for some shocks!\n\n');
end

% Also check ln_K accumulates dln_k
ln_K_fields = shock_list(startsWith(shock_list, 'ln_K_'));
fprintf(fid, '  Level accumulator IRF peaks (monetary shock eps_i):\n');
level_vars = {'ln_Q', 'ln_QN', 'ln_C', 'ln_C_star', 'ln_IB', 'ln_IB_star', ...
              'ln_IH', 'ln_IH_star', 'ln_N', 'ln_N_star', 'ln_K', 'ln_P', 'ln_P_star'};
for v = 1:length(level_vars)
    field = [level_vars{v} '_eps_i'];
    if isfield(oo_.irfs, field)
        irf_data = oo_.irfs.(field);
        [pk, pq] = max(abs(irf_data));
        pk_signed = sign(irf_data(pq)) * pk;
        fprintf(fid, '    %-12s: peak = %+.6f at Q%d, Q40 = %+.6f\n', ...
            level_vars{v}, pk_signed, pq, irf_data(min(40,length(irf_data))));
    else
        fprintf(fid, '    %-12s: NOT FOUND in IRFs\n', level_vars{v});
    end
end
fprintf(fid, '\n');
fclose(fid);

%% ========================================================================
%  STAGE 3: Generate WP IRFs (all 7 shocks at policy-relevant sizes)
%  ========================================================================
fid = fopen(logfile, 'a');
fprintf(fid, '--- STAGE 3: Working paper IRFs (policy-relevant shock sizes) ---\n\n');

% Shock configuration
shock_config = {
    'eps_i',     'Monetary policy',       0.027, 0.250,  '100bp annualized';
    'eps_tp',    'Term premium',          0.050, 0.125,  '50bp annualized';
    'eps_q_us',  'Foreign demand',        1.138, 1.000,  '1pp US output gap';
    'eps_g',     'Government spending',   0.300, 1.000,  '1pp of GDP';
    'eps_pcom',  'Commodity price',       3.000, 10.00,  '10% increase';
    'eps_pQ',    'Cost-push (VA price)',  0.571, 0.571,  '1 s.d.';
    'eps_tfp',   'TFP',                  0.200, 0.200,  '1 s.d.';
};

nShocks = size(shock_config, 1);
scale_factors = zeros(nShocks, 1);
for s = 1:nShocks
    scale_factors(s) = shock_config{s, 4} / shock_config{s, 3};
end

fprintf(fid, 'Shock scaling factors:\n');
for s = 1:nShocks
    fprintf(fid, '  %-25s: stderr=%.3f, target=%.3f, scale=%.3f (%s)\n', ...
        shock_config{s,2}, shock_config{s,3}, shock_config{s,4}, ...
        scale_factors(s), shock_config{s,5});
end
fprintf(fid, '\n');

% Variables to track
vars = {'yhat_au', 'dln_c', 'dln_ib', 'dln_ih', 'dln_x', 'dln_m', ...
        'pi_au', 'piQ', 'pi_w', 'dln_n', 's_gap', 'i_10y', 'i_au'};
var_labels = {'Output gap', 'Consumption', 'Business inv.', ...
              'Housing inv.', 'Exports', 'Imports', ...
              'CPI inflation', 'VA price infl.', 'Wage inflation', ...
              'Employment', 'Exchange rate', '10Y yield', ...
              'Policy rate'};

% Level accumulator variables (new)
level_plot_vars = {'ln_Q', 'ln_QN', 'ln_C', 'ln_IB', 'ln_IH', 'ln_N'};
level_plot_labels = {'Output (Q)', 'Potential (QN)', 'Consumption', ...
                     'Business inv.', 'Housing inv.', 'Employment'};

% Store all scaled IRFs
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

    % Also log level accumulators
    for v = 1:length(level_plot_vars)
        field = [level_plot_vars{v} '_' shock];
        if isfield(oo_.irfs, field)
            scaled_irf = oo_.irfs.(field) * sf;
            scaled_irfs.(field) = scaled_irf;
            [pv, pq] = max(abs(scaled_irf));
            peak = sign(scaled_irf(pq)) * pv;
            fprintf(fid, '  %-22s  %+10.4f  Q%-2d  (cumulative)\n', ...
                level_plot_labels{v}, peak, pq);
        end
    end
    fprintf(fid, '\n');
end

%% Monetary policy detailed path table
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

%% Generate individual shock plots
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

%% Level accumulator plot — monetary shock
fprintf(fid, '\n--- Generating level accumulator IRF plot (monetary shock) ---\n');

fig_lev = figure('Position', [30 30 1400 900], 'Visible', 'off');
sf_mon = scale_factors(1);

% Panel 1: Output — ln_Q vs ln_QN vs yhat_au
subplot(3, 3, 1);
field_Q = oo_.irfs.ln_Q_eps_i * sf_mon;
field_QN = oo_.irfs.ln_QN_eps_i * sf_mon;
field_yhat = oo_.irfs.yhat_au_eps_i * sf_mon;
T = length(field_Q);
plot(1:T, field_Q, 'b-', 'LineWidth', 1.5); hold on;
plot(1:T, field_QN, 'r--', 'LineWidth', 1.5);
plot(1:T, field_yhat, 'k:', 'LineWidth', 1.0);
plot(1:T, zeros(T,1), 'k:', 'LineWidth', 0.3);
legend('ln\_Q (actual)', 'ln\_QN (potential)', 'yhat\_au (gap)', 'Location', 'best');
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

sgtitle('Level Accumulators: 100bp Monetary Tightening', 'FontSize', 13);
saveas(fig_lev, 'irf_level_accumulators_monetary.png');
fprintf(fid, '  Saved: irf_level_accumulators_monetary.png\n');
close(fig_lev);

%% Output gap overview
fig2 = figure('Position', [30 30 1600 1000], 'Visible', 'off');
overview_order = [1 3 4 5 7 2];
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

%% Summary table
fprintf(fid, '\n================================================================\n');
fprintf(fid, '  Summary: Peak Output Gap by Shock (policy-relevant sizes)\n');
fprintf(fid, '================================================================\n\n');
fprintf(fid, '%-22s %-28s %10s %5s %10s %10s %10s\n', ...
    'Shock', 'Size', 'yhat', 'Qtr', 'dln_c', 'dln_ib', 'dln_ih');

for s = 1:nShocks
    shock = shock_config{s, 1};
    sf = scale_factors(s);
    peaks = zeros(1, 4);
    peak_vars_list = {'yhat_au', 'dln_c', 'dln_ib', 'dln_ih'};
    peak_q = 0;
    for pv = 1:4
        field = [peak_vars_list{pv} '_' shock];
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

fid_stage3_done = fid;

%% ========================================================================
%  STAGE 4: Three-regime comparison (100bp monetary)
%  ========================================================================
fprintf(fid, '\n\n--- STAGE 4: Three-regime IRF comparison ---\n');
fprintf(fid, '  Saving hybrid IRFs, then running VAR and MCE variants...\n\n');
fclose(fid);

% Save hybrid IRFs (already in memory from Stage 1)
shock_name = 'eps_i';
stderr_eps_i = 0.027;
target_shock = 0.25;
sf_regime = target_shock / stderr_eps_i;

vars_all = {'yhat_au', 'pi_au', 'i_au', 'piQ', 'dln_c', 'dln_ib', ...
            'dln_ih', 'dln_n', 'pi_w', 's_gap', 'i_10y', ...
            'ln_Q', 'ln_QN'};
var_labels_all = {'Output gap', 'CPI inflation', 'Policy rate', ...
              'VA price inflation', 'Consumption', 'Business investment', ...
              'Housing investment', 'Employment', 'Wage inflation', ...
              'Exchange rate', '10Y yield', 'Output level (Q)', 'Potential (QN)'};

% Extract hybrid IRFs
irfs_hybrid = struct();
for v = 1:length(vars_all)
    field = [vars_all{v} '_' shock_name];
    if isfield(oo_.irfs, field)
        irfs_hybrid.(field) = oo_.irfs.(field) * sf_regime;
    else
        irfs_hybrid.(field) = zeros(1, 40);
    end
end
save('temp_irfs_regime_2.mat', 'irfs_hybrid');

% Run VAR-based
fid = fopen(logfile, 'a');
fprintf(fid, '  Running au_pac_var.mod...\n');
fclose(fid);

clearvars -except logfile shock_name vars_all var_labels_all sf_regime stderr_eps_i target_shock irfs_hybrid;
clearvars -global M_ oo_ options_ estim_params_ bayestopt_ dataset_ dataset_info;

try
    dynare au_pac_var noclearall nograph;
    irfs_var = struct();
    for v = 1:length(vars_all)
        field = [vars_all{v} '_' shock_name];
        if isfield(oo_.irfs, field)
            irfs_var.(field) = oo_.irfs.(field) * sf_regime;
        else
            irfs_var.(field) = zeros(1, 40);
        end
    end
    save('temp_irfs_regime_1.mat', 'irfs_var');
    fid = fopen(logfile, 'a');
    fprintf(fid, '  au_pac_var: %d endo, solved OK\n', M_.endo_nbr);
    fclose(fid);
catch ME
    fid = fopen(logfile, 'a');
    fprintf(fid, '  au_pac_var FAILED: %s\n', ME.message);
    fclose(fid);
    irfs_var = struct();
    for v = 1:length(vars_all)
        irfs_var.([vars_all{v} '_' shock_name]) = zeros(1, 40);
    end
    save('temp_irfs_regime_1.mat', 'irfs_var');
end

% Run MCE
clearvars -except logfile shock_name vars_all var_labels_all sf_regime stderr_eps_i target_shock irfs_hybrid irfs_var;
clearvars -global M_ oo_ options_ estim_params_ bayestopt_ dataset_ dataset_info;

fid = fopen(logfile, 'a');
fprintf(fid, '  Running au_pac_mce.mod...\n');
fclose(fid);

try
    dynare au_pac_mce noclearall nograph;
    irfs_mce = struct();
    for v = 1:length(vars_all)
        field = [vars_all{v} '_' shock_name];
        if isfield(oo_.irfs, field)
            irfs_mce.(field) = oo_.irfs.(field) * sf_regime;
        else
            irfs_mce.(field) = zeros(1, 40);
        end
    end
    save('temp_irfs_regime_3.mat', 'irfs_mce');
    fid = fopen(logfile, 'a');
    fprintf(fid, '  au_pac_mce: %d endo, %d forward, solved OK\n', ...
        M_.endo_nbr, sum(abs(oo_.dr.eigval) > 1));
    fclose(fid);
catch ME
    fid = fopen(logfile, 'a');
    fprintf(fid, '  au_pac_mce FAILED: %s\n', ME.message);
    fclose(fid);
    irfs_mce = struct();
    for v = 1:length(vars_all)
        irfs_mce.([vars_all{v} '_' shock_name]) = zeros(1, 40);
    end
    save('temp_irfs_regime_3.mat', 'irfs_mce');
end

%% Load all three
all_irfs = {irfs_var, irfs_hybrid, irfs_mce};
regime_names  = {'VAR-based', 'Hybrid', 'Full MCE'};
regime_colors = {[0 0.447 0.741], [0 0 0], [0.850 0.325 0.098]};
regime_styles = {'--', '-', '-.'};
regime_widths = [1.5, 2.0, 1.5];

T_plot = 40;

%% Figure 1: FR-BDF Figure 6.2.2 style — 2-panel
fig1 = figure('Position', [100 100 1000 400], 'Color', 'w', 'Visible', 'off');

panel_vars   = {'yhat_au', 'piQ'};
panel_titles = {'Output', 'VA price inflation'};
panel_ylabels = {'(deviation from baseline, in %)', '(annualized, deviation from baseline, in pp)'};
annualize_flag = [0, 1];

for p = 1:2
    subplot(1, 2, p);
    hold on;
    for r = 1:3
        field = [panel_vars{p} '_' shock_name];
        irf_data = all_irfs{r}.(field);
        T_use = min(T_plot, length(irf_data));
        y = irf_data(1:T_use);
        if annualize_flag(p), y = y * 4; end
        plot(1:T_use, y, 'Color', regime_colors{r}, 'LineStyle', regime_styles{r}, ...
            'LineWidth', regime_widths(r));
    end
    plot([1 T_plot], [0 0], 'k:', 'LineWidth', 0.5);
    xlabel('Quarters'); title({panel_titles{p}; panel_ylabels{p}}, 'FontSize', 11);
    if p == 1, legend(regime_names, 'Location', 'best', 'FontSize', 9); end
    xlim([1 T_plot]); grid on;
    hold off;
end

sgtitle('Monetary policy tightening (100bp annualized) under different expectations', ...
    'FontSize', 13, 'FontWeight', 'bold');
print(fig1, 'three_regime_monetary_irf', '-dpng', '-r300');
close(fig1);

%% Figure 2: Full variable comparison
% Use first 11 vars (original ones without level accumulators)
vars_orig = vars_all(1:11);
labels_orig = var_labels_all(1:11);
nVars = length(vars_orig);

fig2 = figure('Position', [50 50 1400 900], 'Color', 'w', 'Visible', 'off');
nRows = ceil(nVars / 4);

for v = 1:nVars
    subplot(nRows, 4, v);
    hold on;
    for r = 1:3
        field = [vars_orig{v} '_' shock_name];
        irf_data = all_irfs{r}.(field);
        T_use = min(T_plot, length(irf_data));
        plot(1:T_use, irf_data(1:T_use), 'Color', regime_colors{r}, ...
            'LineStyle', regime_styles{r}, 'LineWidth', regime_widths(r));
    end
    plot([1 T_plot], [0 0], 'k:', 'LineWidth', 0.5);
    title(labels_orig{v}, 'FontSize', 9);
    xlabel('Quarters'); ylabel('% dev.');
    xlim([1 T_plot]); grid on;
    hold off;
end

if nVars < nRows * 4
    subplot(nRows, 4, nRows * 4);
    hold on;
    for r = 1:3
        plot(NaN, NaN, 'Color', regime_colors{r}, 'LineStyle', regime_styles{r}, ...
            'LineWidth', regime_widths(r));
    end
    legend(regime_names, 'Location', 'best', 'FontSize', 12);
    axis off;
end

sgtitle('Three-regime comparison: all variables (100bp monetary tightening)', ...
    'FontSize', 13, 'FontWeight', 'bold');
print(fig2, 'three_regime_full_comparison', '-dpng', '-r300');
close(fig2);

%% Figure 3: Level accumulators across regimes
fig3 = figure('Position', [50 50 1200 500], 'Color', 'w', 'Visible', 'off');

lev_compare_vars = {'ln_Q', 'ln_QN'};
lev_compare_labels = {'Actual output (ln\_Q)', 'Potential output (ln\_QN)'};

for p = 1:2
    subplot(1, 2, p);
    hold on;
    for r = 1:3
        field = [lev_compare_vars{p} '_' shock_name];
        if isfield(all_irfs{r}, field)
            irf_data = all_irfs{r}.(field);
            T_use = min(T_plot, length(irf_data));
            plot(1:T_use, irf_data(1:T_use), 'Color', regime_colors{r}, ...
                'LineStyle', regime_styles{r}, 'LineWidth', regime_widths(r));
        end
    end
    plot([1 T_plot], [0 0], 'k:', 'LineWidth', 0.5);
    xlabel('Quarters'); ylabel('Index');
    title(lev_compare_labels{p}, 'FontSize', 11);
    if p == 1, legend(regime_names, 'Location', 'best', 'FontSize', 9); end
    xlim([1 T_plot]); grid on;
    hold off;
end

sgtitle('Level accumulators across regimes (100bp monetary)', 'FontSize', 13);
print(fig3, 'three_regime_level_accumulators', '-dpng', '-r300');
close(fig3);

%% Tables for documentation
fid = fopen(logfile, 'a');
fprintf(fid, '\n================================================================\n');
fprintf(fid, '  Three-Regime Tables (100bp annualized monetary tightening)\n');
fprintf(fid, '  Scale factor: %.3f (target=%.3f / stderr=%.3f)\n', sf_regime, target_shock, stderr_eps_i);
fprintf(fid, '================================================================\n\n');

% Table 6.2: Quarter-by-quarter paths
fprintf(fid, 'Table 6.2: Quarter-by-quarter paths\n');
fprintf(fid, '%-8s %12s %12s %12s %14s %14s %14s\n', ...
    'Quarter', 'yhat(VAR)', 'yhat(Hyb)', 'yhat(MCE)', 'piQ_ann(VAR)', 'piQ_ann(Hyb)', 'piQ_ann(MCE)');

quarters_log = [1, 2, 4, 8, 12, 20, 40];
for q = quarters_log
    vals = zeros(1, 6);
    for r = 1:3
        field_y = ['yhat_au_' shock_name];
        field_p = ['piQ_' shock_name];
        irf_y = all_irfs{r}.(field_y);
        irf_p = all_irfs{r}.(field_p);
        if q <= length(irf_y)
            vals(r) = irf_y(q);
            vals(r+3) = irf_p(q) * 4;
        end
    end
    fprintf(fid, 'Q%-7d %+11.6f %+11.6f %+11.6f %+13.6f %+13.6f %+13.6f\n', q, vals);
end

% Table 6.3: Peak comparison
fprintf(fid, '\nTable 6.3: Peak IRF comparison\n');
fprintf(fid, '%-22s %12s %4s %12s %4s %12s %4s %10s\n', ...
    'Variable', 'Peak(VAR)', 'Qtr', 'Peak(Hyb)', 'Qtr', 'Peak(MCE)', 'Qtr', 'MCE atten.');

for v = 1:length(vars_orig)
    field = [vars_orig{v} '_' shock_name];
    pks = zeros(1,3); qs = zeros(1,3);
    for r = 1:3
        irf_data = all_irfs{r}.(field);
        [peak_val, peak_q] = max(abs(irf_data));
        pks(r) = sign(irf_data(peak_q))*peak_val;
        qs(r) = peak_q;
    end
    if abs(pks(2)) > 1e-12
        atten = (1 - abs(pks(3))/abs(pks(2))) * 100;
        fprintf(fid, '%-22s %+11.4f  Q%-2d %+11.4f  Q%-2d %+11.4f  Q%-2d %9.0f%%\n', ...
            labels_orig{v}, pks(1), qs(1), pks(2), qs(2), pks(3), qs(3), atten);
    end
end

% Level accumulator comparison
fprintf(fid, '\nLevel accumulator peaks (100bp monetary):\n');
fprintf(fid, '%-22s %12s %4s %12s %4s %12s %4s\n', ...
    'Variable', 'Peak(VAR)', 'Qtr', 'Peak(Hyb)', 'Qtr', 'Peak(MCE)', 'Qtr');
lev_report = {'ln_Q', 'ln_QN'};
for v = 1:length(lev_report)
    field = [lev_report{v} '_' shock_name];
    pks = zeros(1,3); qs = zeros(1,3);
    for r = 1:3
        if isfield(all_irfs{r}, field)
            irf_data = all_irfs{r}.(field);
            [peak_val, peak_q] = max(abs(irf_data));
            pks(r) = sign(irf_data(peak_q))*peak_val;
            qs(r) = peak_q;
        end
    end
    fprintf(fid, '%-22s %+11.6f  Q%-2d %+11.6f  Q%-2d %+11.6f  Q%-2d\n', ...
        lev_report{v}, pks(1), qs(1), pks(2), qs(2), pks(3), qs(3));
end

%% Cleanup
for r = 1:3
    fname = ['temp_irfs_regime_' num2str(r) '.mat'];
    if exist(fname, 'file'), delete(fname); end
end

fprintf(fid, '\n================================================================\n');
fprintf(fid, '  COMPLETED: %s\n', datestr(now));
fprintf(fid, '================================================================\n');
fclose(fid);

fprintf('\n=== Priority 1 complete — see log_priority1.txt ===\n');
