%% generate_three_regime_irfs.m
% Replicates FR-BDF Figure 6.2.2: Three-regime monetary policy IRF comparison
% Creates 2-panel figure: (a) Output gap, (b) VA price inflation
%
% ** 100bp annualized monetary tightening (0.25 quarterly pp) **
% Uses linear scaling: IRFs from stoch_simul (1 s.d.) * (0.25 / stderr_eps_i)
%
% Runs au_pac_var.mod, au_pac.mod (hybrid), au_pac_mce.mod sequentially,
% saves IRFs to temp .mat files between runs, then overlays.
%
% Usage: cd to c:\Users\david\french_model\dynare\ and run in MATLAB.
%
% Output:
%   - three_regime_monetary_irf.png (2-panel FR-BDF Figure 6.2.2 style)
%   - three_regime_full_comparison.png (15-panel all variables)
%   - log_three_regime_tables.txt (archived tables)
%   - Markdown tables printed to console for documentation

clear; clc;
addpath('C:\dynare\6.5\matlab');
cd('c:\Users\david\french_model\dynare');

fprintf('=== Three-Regime IRF Comparison ===\n');
fprintf('Replicating FR-BDF Figure 6.2.2\n\n');

%% Configuration
shock_name = 'eps_i';
T_plot = 80;  % quarters to plot (FR-BDF uses 80)
stderr_eps_i = 0.027;        % current calibrated stderr
target_shock = 0.25;         % 100bp annualized = 0.25 quarterly pp
scale_factor = target_shock / stderr_eps_i;  % ~9.26
fprintf('  Shock scaling: 100bp annualized = %.3f qpp, scale = %.3f\n\n', ...
    target_shock, scale_factor);

% Variables to extract (must match stoch_simul var_list in all .mod files)
vars_all = {'yhat_au', 'pi_au', 'i_au', 'piQ', 'dln_c', 'dln_ib', ...
            'dln_ih', 'dln_n', 'pi_w', 's_gap', 'i_10y', ...
            'ln_Q', 'ln_QN'};
var_labels = {'Output gap', 'CPI inflation', 'Policy rate', ...
              'VA price inflation', 'Consumption', 'Business investment', ...
              'Housing investment', 'Employment', 'Wage inflation', ...
              'Exchange rate', '10Y yield', ...
              'Output level (Q)', 'Potential (QN)'};

% Regime names, files, plot styles
regime_names  = {'VAR-based', 'Hybrid', 'Full MCE'};
regime_files  = {'au_pac_var', 'au_pac', 'au_pac_mce'};
regime_colors = {[0 0.447 0.741], [0 0 0], [0.850 0.325 0.098]};
regime_styles = {'--', '-', '-.'};
regime_widths = [1.5, 2.0, 1.5];
regime_markers = {'.', 'none', 'none'};

%% Run each regime
for r = 1:3
    fprintf('--- Running regime %d/3: %s (%s.mod) ---\n', r, regime_names{r}, regime_files{r});
    try
        eval(['dynare ' regime_files{r} ' noclearall nograph']);

        % Extract IRFs for this regime, scaled to 100bp
        irfs_regime = struct();
        for v = 1:length(vars_all)
            field = [vars_all{v} '_' shock_name];
            if isfield(oo_.irfs, field)
                irfs_regime.(field) = oo_.irfs.(field) * scale_factor;
            else
                fprintf('  WARNING: %s not found in %s\n', field, regime_files{r});
                irfs_regime.(field) = zeros(1, 40);
            end
        end

        % Save to temp file
        save(['temp_irfs_regime_' num2str(r) '.mat'], 'irfs_regime');
        fprintf('  Saved IRFs for %s\n', regime_names{r});

    catch ME
        fprintf('  ERROR running %s: %s\n', regime_files{r}, ME.message);
        % Create empty IRFs so plotting doesn't fail
        irfs_regime = struct();
        for v = 1:length(vars_all)
            irfs_regime.([vars_all{v} '_' shock_name]) = zeros(1, 40);
        end
        save(['temp_irfs_regime_' num2str(r) '.mat'], 'irfs_regime');
    end

    % Thorough cleanup: clear everything except loop/config variables
    clearvars -except shock_name T_plot vars_all var_labels regime_names regime_files regime_colors regime_styles regime_widths regime_markers r scale_factor stderr_eps_i target_shock;
    clearvars -global M_ oo_ options_ estim_params_ bayestopt_ dataset_ dataset_info;
end

%% Load all three regime IRFs
all_irfs = cell(1, 3);
for r = 1:3
    tmp = load(['temp_irfs_regime_' num2str(r) '.mat']);
    all_irfs{r} = tmp.irfs_regime;
end

%% ========================================================================
%  FIGURE 1: FR-BDF Figure 6.2.2 style — 2-panel (Output + VA price)
%  ========================================================================
fprintf('\n--- Generating FR-BDF Figure 6.2.2 style plot ---\n');

fig1 = figure('Position', [100 100 1000 400], 'Color', 'w', 'Visible', 'off');

panel_vars   = {'yhat_au', 'piQ'};
panel_titles = {'Output', 'VA price inflation'};
panel_ylabels = {'(deviation from baseline, in %)', '(annualized, deviation from baseline, in pp)'};
annualize    = [0, 1];  % multiply piQ by 4 for annualized

for p = 1:2
    subplot(1, 2, p);
    hold on;

    for r = 1:3
        field = [panel_vars{p} '_' shock_name];
        irf_data = all_irfs{r}.(field);
        T_avail = length(irf_data);
        T_use = min(T_plot, T_avail);

        y = irf_data(1:T_use);
        if annualize(p)
            y = y * 4;  % quarterly rate -> annualized
        end

        plot(1:T_use, y, ...
            'Color', regime_colors{r}, ...
            'LineStyle', regime_styles{r}, ...
            'LineWidth', regime_widths(r), ...
            'Marker', regime_markers{r}, ...
            'MarkerSize', 4);
    end

    plot([1 T_plot], [0 0], 'k:', 'LineWidth', 0.5);
    xlabel('Quarters', 'FontSize', 10);
    title({panel_titles{p}; panel_ylabels{p}}, 'FontSize', 11);

    if p == 1
        legend(regime_names, 'Location', 'best', 'FontSize', 9);
    end

    xlim([1 min(T_plot, T_avail)]);
    grid on;
    set(gca, 'FontSize', 10);
    hold off;
end

sgtitle('Monetary policy tightening (100bp annualized) under different expectations', ...
    'FontSize', 13, 'FontWeight', 'bold');

print(fig1, 'three_regime_monetary_irf', '-dpng', '-r300');
fprintf('  Saved: three_regime_monetary_irf.png\n');
close(fig1);

%% ========================================================================
%  FIGURE 2: Full 15-panel comparison (all variables)
%  ========================================================================
fprintf('--- Generating full variable comparison plot ---\n');

fig2 = figure('Position', [50 50 1400 900], 'Color', 'w', 'Visible', 'off');

nVars = length(vars_all);
nRows = ceil(nVars / 4);

for v = 1:nVars
    subplot(nRows, 4, v);
    hold on;

    for r = 1:3
        field = [vars_all{v} '_' shock_name];
        irf_data = all_irfs{r}.(field);
        T_avail = length(irf_data);
        T_use = min(T_plot, T_avail);

        plot(1:T_use, irf_data(1:T_use), ...
            'Color', regime_colors{r}, ...
            'LineStyle', regime_styles{r}, ...
            'LineWidth', regime_widths(r));
    end

    plot([1 min(T_plot, T_avail)], [0 0], 'k:', 'LineWidth', 0.5);
    title(var_labels{v}, 'FontSize', 9);
    xlabel('Quarters', 'FontSize', 8);
    ylabel('% dev.', 'FontSize', 8);
    xlim([1 min(T_plot, T_avail)]);
    grid on;
    set(gca, 'FontSize', 8);
    hold off;
end

% Add legend in empty subplot
if nVars < nRows * 4
    subplot(nRows, 4, nRows * 4);
    hold on;
    for r = 1:3
        plot(NaN, NaN, 'Color', regime_colors{r}, ...
            'LineStyle', regime_styles{r}, 'LineWidth', regime_widths(r));
    end
    legend(regime_names, 'Location', 'best', 'FontSize', 12);
    axis off;
end

sgtitle('Three-regime comparison: all variables (100bp monetary tightening)', ...
    'FontSize', 13, 'FontWeight', 'bold');

print(fig2, 'three_regime_full_comparison', '-dpng', '-r300');
fprintf('  Saved: three_regime_full_comparison.png\n');
close(fig2);

%% ========================================================================
%  Print markdown tables for documentation
%  ========================================================================
fprintf('\n\n=== MARKDOWN TABLES FOR DOCUMENTATION ===\n\n');

% Table 1: Output gap and VA price inflation across regimes
fprintf('#### Table 6.2: Three-regime IRF comparison (100bp annualized monetary tightening)\n\n');
fprintf('| Quarter | Output (VAR) | Output (Hyb) | Output (MCE) | piQ ann. (VAR) | piQ ann. (Hyb) | piQ ann. (MCE) |\n');
fprintf('|---------|-------------|-------------|-------------|---------------|---------------|---------------|\n');

quarters_table = [1, 2, 4, 8, 12, 20, 40];
for q = quarters_table
    vals = zeros(1, 6);
    for r = 1:3
        field_y = ['yhat_au_' shock_name];
        field_p = ['piQ_' shock_name];
        irf_y = all_irfs{r}.(field_y);
        irf_p = all_irfs{r}.(field_p);
        if q <= length(irf_y)
            vals(r) = irf_y(q);
            vals(r+3) = irf_p(q) * 4;  % annualized
        end
    end
    fprintf('| Q%d | %.4f | %.4f | %.4f | %.4f | %.4f | %.4f |\n', q, vals);
end

% Table 2: Peak responses for all variables
fprintf('\n#### Table 6.3: Peak IRF comparison across regimes (100bp annualized)\n\n');
fprintf('| Variable | Peak (VAR) | Qtr | Peak (Hyb) | Qtr | Peak (MCE) | Qtr |\n');
fprintf('|----------|-----------|-----|-----------|-----|-----------|-----|\n');

for v = 1:nVars
    field = [vars_all{v} '_' shock_name];
    fprintf('| %s ', var_labels{v});
    for r = 1:3
        irf_data = all_irfs{r}.(field);
        [peak_val, peak_q] = max(abs(irf_data));
        peak_sign = sign(irf_data(peak_q));
        fprintf('| %+.4f | Q%d ', peak_sign*peak_val, peak_q);
    end
    fprintf('|\n');
end

%% Archive tables to log file
fid = fopen('log_three_regime_tables.txt', 'w');
fprintf(fid, 'Three-regime IRF tables — 100bp annualized monetary tightening\n');
fprintf(fid, 'Generated: %s\n', datestr(now));
fprintf(fid, 'Scale factor: %.3f (target=%.3f qpp / stderr=%.3f)\n\n', ...
    scale_factor, target_shock, stderr_eps_i);

fprintf(fid, 'Table 6.2: Quarter-by-quarter paths\n');
fprintf(fid, '%-8s %-12s %-12s %-12s %-14s %-14s %-14s\n', ...
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

fprintf(fid, '\nTable 6.3: Peak IRF comparison\n');
fprintf(fid, '%-22s %-12s %-4s %-12s %-4s %-12s %-4s %-12s\n', ...
    'Variable', 'Peak(VAR)', 'Qtr', 'Peak(Hyb)', 'Qtr', 'Peak(MCE)', 'Qtr', 'MCE atten.');
for v = 1:nVars
    field = [vars_all{v} '_' shock_name];
    pks = zeros(1,3); qs = zeros(1,3);
    for r = 1:3
        irf_data = all_irfs{r}.(field);
        [peak_val, peak_q] = max(abs(irf_data));
        pks(r) = sign(irf_data(peak_q))*peak_val;
        qs(r) = peak_q;
    end
    if abs(pks(2)) > 1e-12
        atten = (1 - abs(pks(3))/abs(pks(2))) * 100;
        fprintf(fid, '%-22s %+11.4f  Q%-2d %+11.4f  Q%-2d %+11.4f  Q%-2d %10.0f%%\n', ...
            var_labels{v}, pks(1), qs(1), pks(2), qs(2), pks(3), qs(3), atten);
    else
        fprintf(fid, '%-22s %+11.4f  Q%-2d %+11.4f  Q%-2d %+11.4f  Q%-2d %10s\n', ...
            var_labels{v}, pks(1), qs(1), pks(2), qs(2), pks(3), qs(3), '—');
    end
end
fclose(fid);
fprintf('\n  Saved: log_three_regime_tables.txt\n');

%% Cleanup temp files
for r = 1:3
    fname = ['temp_irfs_regime_' num2str(r) '.mat'];
    if exist(fname, 'file')
        delete(fname);
    end
end

fprintf('\n=== Three-regime IRF comparison complete (100bp annualized) ===\n');
