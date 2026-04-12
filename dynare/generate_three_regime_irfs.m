%% generate_three_regime_irfs.m
% Replicates FR-BDF Figure 6.2.2: Three-regime monetary policy IRF comparison
% Creates 2-panel figure: (a) Output gap, (b) VA price inflation
%
% Runs au_pac_var.mod, au_pac.mod (hybrid), au_pac_mce.mod sequentially,
% saves IRFs to temp .mat files between runs, then overlays.
%
% Usage: cd to c:\Users\david\french_model\dynare\ and run in MATLAB.
%
% Output:
%   - three_regime_monetary_irf.png (2-panel FR-BDF Figure 6.2.2 style)
%   - three_regime_full_comparison.png (15-panel all variables)
%   - Markdown tables printed to console for documentation

clear; clc;
addpath('C:\dynare\6.5\matlab');
cd('c:\Users\david\french_model\dynare');

fprintf('=== Three-Regime IRF Comparison ===\n');
fprintf('Replicating FR-BDF Figure 6.2.2\n\n');

%% Configuration
shock_name = 'eps_i';
T_plot = 80;  % quarters to plot (FR-BDF uses 80)

% Variables to extract (must match stoch_simul var_list in all .mod files)
vars_all = {'yhat_au', 'pi_au', 'i_au', 'piQ', 'dln_c', 'dln_ib', ...
            'dln_ih', 'dln_n', 'pi_w', 's_gap', 'i_10y'};
var_labels = {'Output gap', 'CPI inflation', 'Policy rate', ...
              'VA price inflation', 'Consumption', 'Business investment', ...
              'Housing investment', 'Employment', 'Wage inflation', ...
              'Exchange rate', '10Y yield'};

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

        % Extract IRFs for this regime
        irfs_regime = struct();
        for v = 1:length(vars_all)
            field = [vars_all{v} '_' shock_name];
            if isfield(oo_.irfs, field)
                irfs_regime.(field) = oo_.irfs.(field);
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

    % Clear Dynare globals for next run
    clear M_ oo_ options_ estim_params_ bayestopt_ dataset_ dataset_info;
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

sgtitle('Monetary policy responses under different types of expectations', ...
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

sgtitle('Three-regime comparison: all variables (monetary policy shock)', ...
    'FontSize', 13, 'FontWeight', 'bold');

print(fig2, 'three_regime_full_comparison', '-dpng', '-r300');
fprintf('  Saved: three_regime_full_comparison.png\n');
close(fig2);

%% ========================================================================
%  Print markdown tables for documentation
%  ========================================================================
fprintf('\n\n=== MARKDOWN TABLES FOR DOCUMENTATION ===\n\n');

% Table 1: Output gap and VA price inflation across regimes
fprintf('#### Table 6.2.1: Three-regime IRF comparison (monetary policy shock)\n\n');
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
fprintf('\n#### Table 6.2.2: Peak IRF comparison across regimes\n\n');
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

%% Cleanup temp files
for r = 1:3
    fname = ['temp_irfs_regime_' num2str(r) '.mat'];
    if exist(fname, 'file')
        delete(fname);
    end
end

fprintf('\n=== Three-regime IRF comparison complete ===\n');
